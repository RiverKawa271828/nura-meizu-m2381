#!/usr/bin/env python3
"""m2468 modem bringup daemon.

Key design: ONE QRTR socket, ONE set of QMI clients, held for the whole run.
No repeated qmicli spawning (each qmicli call creates a new QRTR client and
dozens of them destabilise the modem).
"""
import ctypes, select, struct, subprocess, sys, time

AF_QIPCRTR = 42
SOCK_DGRAM = 2


class SA(ctypes.Structure):
    _fields_ = [("f", ctypes.c_uint16), ("n", ctypes.c_uint32), ("p", ctypes.c_uint32)]


libc = ctypes.CDLL("libc.so.6", use_errno=True)


class Modem:
    def __init__(self):
        self.fd = libc.socket(AF_QIPCRTR, SOCK_DGRAM, 0)
        if self.fd < 0:
            raise OSError("socket")
        sa = SA()
        ln = ctypes.c_uint(12)
        libc.getsockname(self.fd, ctypes.byref(sa), ctypes.byref(ln))
        sa.p = 0
        if libc.bind(self.fd, ctypes.byref(sa), 12) < 0:
            raise OSError("bind")
        self.tid = 0x2000
        self.ports = {}
        self.refresh_ports()

    def refresh_ports(self):
        out = subprocess.run(["qrtr-lookup"], capture_output=True, text=True, timeout=10).stdout
        d = {}
        for line in out.splitlines()[1:]:
            f = line.split()
            if len(f) >= 5 and f[3] == "0":
                try:
                    d.setdefault(int(f[0]), int(f[4]))
                except ValueError:
                    pass
        if d:
            self.ports = d

    def call(self, svc, mid, tlvs=b"", timeout=6.0):
        port = self.ports.get(svc)
        if port is None:
            self.refresh_ports()
            port = self.ports.get(svc)
        if port is None:
            return None, "no port for service %d" % svc
        self.tid += 1
        pkt = struct.pack("<BHHH", 0, self.tid, mid, len(tlvs)) + tlvs
        d = SA(AF_QIPCRTR, 0, port)
        if libc.sendto(self.fd, pkt, len(pkt), 0, ctypes.byref(d), ctypes.sizeof(d)) < 0:
            return None, "sendto failed"
        deadline = time.time() + timeout
        while time.time() < deadline:
            r, _, _ = select.select([self.fd], [], [], max(0.1, deadline - time.time()))
            if not r:
                break
            b = ctypes.create_string_buffer(16384)
            s = SA()
            l = ctypes.c_uint(12)
            n = libc.recvfrom(self.fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
            if n < 0:
                continue
            data = b.raw[:n]
            if len(data) < 7:
                continue
            typ, tid, rmid, hl = struct.unpack("<BHHH", data[:7])
            if tid != self.tid:
                continue
            body = data[7:7 + hl]
            i = 0
            while i + 3 <= len(body):
                t, ll = struct.unpack("<BH", body[i:i + 3])
                v = body[i + 3:i + 3 + ll]
                if t == 2 and len(v) >= 4:
                    r_, e = struct.unpack("<HH", v[:4])
                    return (r_, e), None
                i += 3 + ll
            return (-1, -1), "no result TLV"
        return None, "timeout"


def tlv8(t, v):
    return struct.pack("<BH", t, 1) + bytes([v])


def tlv32(t, v):
    return struct.pack("<BH", t, 4) + struct.pack("<I", v)


def tlv(t, val):
    return struct.pack("<BH", t, len(val)) + val


def ok(res):
    return res is not None and res[0] == 0


def main():
    m = Modem()
    print("[init] qrtr socket bound, %d services visible" % len(m.ports), flush=True)

    # 0) 等 modem 就绪（冷启动后 remoteproc 起来还需要时间）
    print("[0] waiting for modem to answer...", flush=True)
    for i in range(60):
        res, err = m.call(2, 0x002D, b"", timeout=3.0)
        if res is not None:
            print("    modem answered after ~%ds: %s" % (i * 3, res), flush=True)
            break
        time.sleep(3)
    else:
        print("    modem never answered, giving up", flush=True)
        return 1
    time.sleep(5)

    # 1) 一次性的 SIM 会话激活（用 qmicli，因为 TLV 是嵌套 sequence）
    print("[1] activating SIM provisioning session (one-shot qmicli)", flush=True)
    r = subprocess.run(
        ["qmicli", "-d", "qrtr://0", "--uim-change-provisioning-session="
         "slot=1,activate=yes,session-type=primary-gw-provisioning,"
         "aid=a0000000871002ff86ffff89ffffffff"],
        capture_output=True, text=True, timeout=40)
    print("    ", (r.stdout or r.stderr).strip().splitlines()[-1:], flush=True)
    time.sleep(4)

    # 2) Bind subscriptions exactly like qcril
    print("[2] binding subscriptions", flush=True)
    binds = [
        ("NAS",   3,  0x0045, tlv8(0x01, 0)),
        ("VOICE", 9,  0x0044, tlv8(0x01, 0)),
        ("WMS",   5,  0x004C, tlv8(0x01, 0)),
        ("DMS",   2,  0x0054, tlv32(0x01, 1)),
        ("DSD",   42, 0x0027, tlv32(0x01, 1)),
        ("WDS",   1,  0x00AF, tlv32(0x01, 1)),
    ]
    for name, svc, mid, t in binds:
        res, err = m.call(svc, mid, t)
        print("    %-6s 0x%04x -> %s %s" % (name, mid, res, err or ""), flush=True)
        time.sleep(0.5)

    # 3) online  (DMS Set Operating Mode = 0x002E, TLV 0x01 = mode, online = 1)
    print("[3] setting operating mode = online", flush=True)
    for attempt in range(3):
        res, err = m.call(2, 0x002E, tlv8(0x01, 1))
        print("    attempt %d -> %s %s" % (attempt + 1, res, err or ""), flush=True)
        if ok(res):
            break
        time.sleep(3)

    # 4) monitor at LOW frequency — no client churn
    print("[4] monitoring (30 s interval, single long-lived socket)", flush=True)
    for i in range(2000):
        time.sleep(30)
        # 无条件补发 online（幂等）：modem 会自己掉回 low-power，只查返回码不够
        m.call(2, 0x002E, tlv8(0x01, 1), timeout=6)
        mode = m.call(2, 0x002D, b"")          # DMS GET_OPERATING_MODE
        serv = m.call(3, 0x0024, b"")          # NAS GET_SERVING_SYSTEM
        print("  [%5ds] mode=%s serving=%s" % (i * 30, mode[0], serv[0]), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
