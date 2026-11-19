#!/usr/bin/env python3
"""m2468 data daemon — keeps a WDS call alive and configures rmnet_ipa0.

The WDS client must stay alive: when the process exits the call is torn down.
Runs the sequence fuxi's 81voltd does, then holds the socket open and
re-applies the address if the call drops.
"""
import ctypes, os, select, struct, subprocess, sys, time

AF_QIPCRTR = 42
IF = "rmnet_ipa0"
APN = os.environ.get("M2468_APN", "cmnet")
MUX = int(os.environ.get("M2468_MUX", "0xF8"), 0)
RETRY_S = 20


class SA(ctypes.Structure):
    _fields_ = [("f", ctypes.c_uint16), ("n", ctypes.c_uint32), ("p", ctypes.c_uint32)]


libc = ctypes.CDLL("libc.so.6", use_errno=True)


def sh(*a):
    r = subprocess.run(a, capture_output=True, text=True)
    return (r.stdout + r.stderr).strip()


def log(msg):
    print(time.strftime("[%H:%M:%S] ") + msg, flush=True)


def ports():
    out = sh("qrtr-lookup")
    d = {}
    for line in out.splitlines()[1:]:
        f = line.split()
        if len(f) >= 5 and f[3] == "0":
            try:
                d.setdefault(int(f[0]), int(f[4]))
            except ValueError:
                pass
    return d


def open_sock():
    fd = libc.socket(AF_QIPCRTR, 2, 0)
    sa = SA()
    ln = ctypes.c_uint(12)
    libc.getsockname(fd, ctypes.byref(sa), ctypes.byref(ln))
    sa.p = 0
    libc.bind(fd, ctypes.byref(sa), 12)
    return fd


fd = open_sock()
P = ports()
tid = 0x8000


def call(svc, mid, tlvs, timeout=10):
    global tid
    if svc not in P:
        return None
    tid += 1
    pkt = struct.pack("<BHHH", 0, tid, mid, len(tlvs)) + tlvs
    d = SA(AF_QIPCRTR, 0, P[svc])
    libc.sendto(fd, pkt, len(pkt), 0, ctypes.byref(d), ctypes.sizeof(d))
    dl = time.time() + timeout
    while time.time() < dl:
        r, _, _ = select.select([fd], [], [], max(0.1, dl - time.time()))
        if not r:
            break
        b = ctypes.create_string_buffer(16384)
        s = SA()
        l = ctypes.c_uint(12)
        n = libc.recvfrom(fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
        if n < 7:
            continue
        data = b.raw[:n]
        _, rtid, rmid, hl = struct.unpack("<BHHH", data[:7])
        if rtid != tid:
            continue
        body = data[7:7 + hl]
        out = []
        i = 0
        while i + 3 <= len(body):
            t, ll = struct.unpack("<BH", body[i:i + 3])
            out.append((t, body[i + 3:i + 3 + ll]))
            i += 3 + ll
        return out
    return None


def tlv(t, v):
    return struct.pack("<BH", t, len(v)) + v


def u32(v):
    return struct.pack("<I", v)


def result(res):
    if not res:
        return None
    for t, v in res:
        if t == 0x02 and len(v) >= 4:
            return struct.unpack("<HH", v[:4])
    return None


def ip_of(res, tag):
    if not res:
        return None
    for t, v in res:
        if t == tag and len(v) == 4:
            return ".".join(str(x) for x in reversed(v))
    return None


def teardown_addr():
    sh("ip", "addr", "flush", "dev", IF, "scope", "global")
    sh("ip", "route", "del", "default", "dev", IF)


_mux_counter = [MUX]


def connect():
    """Returns (addr, dns1, dns2) or None."""
    global P
    # modem 重启后旧的 mux 绑定会失效，每次换一个新的，冲突(INTERNAL=3)时也换
    _mux_counter[0] = _mux_counter[0] + 1 if _mux_counter[0] < 0xFE else 0xF0
    mux = _mux_counter[0]
    P = ports()
    if 1 not in P:
        log("WDS service not present yet")
        return None
    sh("ip", "link", "set", IF, "up")

    r = call(1, 0x00A2, tlv(0x10, u32(4) + u32(1)) + tlv(0x11, bytes([mux])) + tlv(0x13, u32(1)))
    log("bind mux 0x%02X -> %s" % (mux, result(r)))
    if result(r) != (0, 0):
        return None
    r = call(1, 0x00AF, tlv(0x01, u32(1)))
    log("bind sub -> %s" % (result(r),))
    r = call(1, 0x0020, tlv(0x14, APN.encode()) + tlv(0x19, bytes([4])), timeout=45)
    log("start network -> %s" % (result(r),))
    if result(r) != (0, 0):
        return None
    r = call(1, 0x002D, b"", timeout=15)
    addr, d1, d2 = ip_of(r, 0x1E), ip_of(r, 0x15), ip_of(r, 0x16)
    log("settings addr=%s dns=%s,%s" % (addr, d1, d2))
    if not addr:
        return None
    teardown_addr()
    sh("ip", "addr", "add", "%s/32" % addr, "dev", IF)
    sh("ip", "link", "set", IF, "up")
    sh("ip", "route", "add", "default", "dev", IF, "metric", "50")
    if d1:
        with open("/etc/resolv.conf.m2468", "w") as f:
            f.write("nameserver %s\n" % d1)
            if d2:
                f.write("nameserver %s\n" % d2)
    return (addr, d1, d2)


def main():
    log("m2468 data daemon starting (apn=%s mux=0x%02X)" % (APN, MUX))
    cur = None
    while True:
        if cur is None:
            res = connect()
            if res:
                cur = res
                log("data up: %s" % (res[0],))
                time.sleep(30)
                continue
            log("connect failed, retry in %ds" % RETRY_S)
            time.sleep(RETRY_S)
            continue
        # 已连接：不主动查 QMI（Get Current Settings 在空闲时会超时，
        # 误判成掉线会每分钟换一次地址，导致传输永远起不来）。
        # 只检查接口地址是否还在，丢了才重连。
        addr_now = ""
        for line in sh("ip", "-br", "addr", "show", IF).splitlines():
            for tok in line.split():
                if tok.startswith(cur[0] + "/"):
                    addr_now = tok
        if not addr_now:
            log("address gone from %s, reconnecting" % IF)
            cur = None
            continue
        time.sleep(30)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        teardown_addr()
