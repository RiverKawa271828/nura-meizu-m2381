#!/usr/bin/env python3
"""Bind subscriptions exactly like qcril does, then dual-standby + online.
Values from the fuxi (SM8550) research doc:
  NAS/VOICE/WMS: TLV 0x01, 1 byte, 0=primary
  WDS/DMS/DSD:   TLV 0x01, 4 bytes LE, 1=primary
"""
import ctypes, select, struct, time, subprocess

libc = ctypes.CDLL("libc.so.6", use_errno=True)


class SA(ctypes.Structure):
    _fields_ = [("f", ctypes.c_uint16), ("n", ctypes.c_uint32), ("p", ctypes.c_uint32)]


fd = libc.socket(42, 2, 0)
sa = SA()
ln = ctypes.c_uint(12)
libc.getsockname(fd, ctypes.byref(sa), ctypes.byref(ln))
sa.p = 0
assert libc.bind(fd, ctypes.byref(sa), 12) == 0


def ports():
    out = subprocess.run(["qrtr-lookup"], capture_output=True, text=True, timeout=10).stdout
    d = {}
    for line in out.splitlines()[1:]:
        f = line.split()
        if len(f) >= 5 and f[3] == "0":
            try:
                d.setdefault(int(f[0]), int(f[4]))
            except ValueError:
                pass
    return d


P = ports()


def talk(svc, mid, tlvs, tid, tmo=6.0):
    port = P.get(svc)
    if port is None:
        return None, "no port"
    pkt = struct.pack("<BHHH", 0, tid, mid, len(tlvs)) + tlvs
    d = SA(42, 0, port)
    libc.sendto(fd, pkt, len(pkt), 0, ctypes.byref(d), ctypes.sizeof(d))
    r, _, _ = select.select([fd], [], [], tmo)
    if not r:
        return None, "NO REPLY"
    b = ctypes.create_string_buffer(16384)
    s = SA()
    l = ctypes.c_uint(12)
    n = libc.recvfrom(fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
    data = b.raw[:n]
    hl = struct.unpack("<BHHH", data[:7])[3]
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


def tlv1_8(t, v):
    return struct.pack("<BH", t, 1) + bytes([v])


def tlv1_32(t, v):
    return struct.pack("<BH", t, 4) + struct.pack("<I", v)


tid = 0x1100
SKIP_TAIL = True

# 1) Bind subscription — qcril order: NAS, VOICE, WMS, DMS (8-bit starts at 0, 32-bit starts at 1)
binds = [
    ("NAS   Bind 0x0045 val=0(1B)", 3, 0x0045, tlv1_8(0x01, 0)),
    ("VOICE Bind 0x0044 val=0(1B)", 9, 0x0044, tlv1_8(0x01, 0)),
    ("WMS   Bind 0x004C val=0(1B)", 5, 0x004C, tlv1_8(0x01, 0)),
    ("DMS   Bind 0x0054 val=1(4B)", 2, 0x0054, tlv1_32(0x01, 1)),
    ("DSD   Bind 0x0027 val=1(4B)", 42, 0x0027, tlv1_32(0x01, 1)),
    ("WDS   Bind 0x00AF val=1(4B)", 1, 0x00AF, tlv1_32(0x01, 1)),
]
print("=== 1) Bind Subscription (按 qcril 顺序) ===")
for name, svc, mid, tlv in binds:
    tid += 1
    res, err = talk(svc, mid, tlv, tid)
    print("  %-30s -> %s %s" % (name, res, err or ""))
    time.sleep(0.9)

# 2) NAS Set Dual Standby Pref: TLV 0x10 = 5 (auto w/ tune-away) + TLV 0x14 = 8-byte mask
print("=== 2) NAS Set Dual Standby Pref (0x4B) ===")
mask = struct.pack("<BH", 0x14, 8) + b"\x01" + b"\x00" * 7
for name, extra in [
    ("pref=5 + mask bit0", tlv1_8(0x10, 5) + mask),
    ("pref=6 + mask bit0", tlv1_8(0x10, 6) + mask),
    ("mask bit0 only", mask),
]:
    tid += 1
    res, err = talk(3, 0x004B, extra, tid)
    print("  %-22s -> %s %s" % (name, res, err or ""))
    time.sleep(0.9)

# 3) 复查
print("=== 3) 复查 Get Dual Standby Pref (0x5C) ===")
tid += 1
res, err = talk(3, 0x005C, b"", tid)
print("  ", res, err or "")

