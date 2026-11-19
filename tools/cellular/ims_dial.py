#!/usr/bin/env python3
"""ims_dial.py — IMS PDN 拨号（D 件①步 / 短信 over IMS 前置）
DPM open 已由 d1_dataup 完成；本脚本 = bind mux 0xF2 → bind sub → start(APN ims, v4v6, IM CN flag) → get settings
"""
import ctypes, select, struct, subprocess, sys, time

libc = ctypes.CDLL("libc.so.6", use_errno=True)
class SA(ctypes.Structure):
    _fields_ = [("f", ctypes.c_uint16), ("n", ctypes.c_uint32), ("p", ctypes.c_uint32)]
fd = libc.socket(42, 2, 0)
sa = SA(); ln = ctypes.c_uint(12)
libc.getsockname(fd, ctypes.byref(sa), ctypes.byref(ln))
sa.p = 0
assert libc.bind(fd, ctypes.byref(sa), 12) == 0

def ports():
    out = subprocess.run(["qrtr-lookup"], capture_output=True, text=True, timeout=10).stdout
    d = {}
    for line in out.splitlines()[1:]:
        f = line.split()
        if len(f) >= 5 and f[3] == "0":
            try: d.setdefault(int(f[0]), int(f[4]))
            except ValueError: pass
    return d

P = ports()
tid = 0x6000

def tlv(t, v): return struct.pack("<BH", t, len(v)) + v
def u32(v): return struct.pack("<I", v)

def call(svc, mid, tlvs=b"", timeout=10):
    global tid
    if svc not in P:
        print("svc %d not on qrtr (have: %s)" % (svc, sorted(P)))
        return None
    tid += 1
    mytid = tid
    pkt = struct.pack("<BHHH", 0, mytid, mid, len(tlvs)) + tlvs
    d = SA(42, 0, P[svc])
    libc.sendto(fd, pkt, len(pkt), 0, ctypes.byref(d), ctypes.sizeof(d))
    dl = time.time() + timeout
    while time.time() < dl:
        r, _, _ = select.select([fd], [], [], max(0.05, dl - time.time()))
        if not r: break
        b = ctypes.create_string_buffer(16384)
        s = SA(); l = ctypes.c_uint(12)
        n = libc.recvfrom(fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
        if n < 7: continue
        data = b.raw[:n]
        flg, rtid, rmid, hl = struct.unpack("<BHHH", data[:7])
        if flg == 2 and rtid == 0: continue
        if rtid != mytid or rmid != mid: continue
        body = data[7:7+hl]
        out = []
        i = 0
        while i + 3 <= len(body):
            t, ll = struct.unpack("<BH", body[i:i+3])
            out.append((t, body[i+3:i+3+ll]))
            i += 3 + ll
        return out
    return None

def result(res):
    if not res: return None
    for t, v in res:
        if t == 0x02 and len(v) >= 4: return struct.unpack("<HH", v[:4])
    return None

def get(res, tag):
    for t, v in res or []:
        if t == tag: return v
    return None

print("qrtr services:", {k: v for k, v in sorted(P.items()) if k in (1, 2, 5, 11, 12)})
r = call(1, 0x00A2, tlv(0x10, u32(4) + u32(1)) + tlv(0x11, bytes([0xF2])) + tlv(0x13, u32(1)), timeout=10)
print("bind mux 0xF2 ->", result(r))
r = call(1, 0x00AF, tlv(0x01, u32(1)), timeout=10)
print("bind sub ->", result(r))
r = call(1, 0x0020, tlv(0x14, b"ims") + tlv(0x19, bytes([4])) + tlv(0x20, bytes([1])), timeout=45)
print("start ims ->", result(r))
for t, v in r or []:
    if t not in (2,): print("  out TLV 0x%02x: %s" % (t, v.hex()))
r = call(1, 0x002D, b"", timeout=15)
print("get settings ->", result(r))
for t, v in r or []:
    if t == 0x1E: print("  addr 0x1E:", ".".join(str(x) for x in v[:4]))
    if t in (0x15, 0x16): print("  dns TLV 0x%02x: %s" % (t, ".".join(str(x) for x in v[:4])))
