#!/usr/bin/env python3
"""uim_read.py — ctypes QMI UIM Read Transparent（读 EF_MSISDN / EF-SMSC）
用法: uim_read.py 0x7F10 0x6F40   # path...,file-id 最后一个 = 文件
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

AID = bytes.fromhex("A0000000871002FF86FFFF89FFFFFFFF")

def uim_port():
    out = subprocess.run(["qrtr-lookup"], capture_output=True, text=True, timeout=10).stdout
    for line in out.splitlines()[1:]:
        f = line.split()
        if len(f) >= 5 and f[0] == "2":  # Service 列 = UIM(2)
            return int(f[4])
    return None

P = uim_port()
tid = 0x5000

def tlv(t, v): return struct.pack("<BH", t, len(v)) + v
def call(mid, tlvs, timeout=10):
    global tid
    tid += 1
    mytid = tid
    pkt = struct.pack("<BHHH", 0, mytid, mid, len(tlvs)) + tlvs
    d = SA(42, 0, P)
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
    for t, v in res or []:
        if t == 0x02 and len(v) >= 4: return struct.unpack("<HH", v[:4])
    return None

def read_file(path_ids, file_id, nbytes=64):
    """path_ids: [0x3F00, 0x7F10...]；试 LE 字节序 path。"""
    sess = bytes([0x00, len(AID)]) + AID     # session_type=0 primary-gw + u8-prefix aid
    path = b"".join(struct.pack("<H", x) for x in path_ids)
    f = struct.pack("<H", file_id) + bytes([len(path)]) + path
    r = call(0x0020, tlv(0x01, sess) + tlv(0x02, f) + tlv(0x03, struct.pack("<HH", 0, nbytes)), timeout=15)
    print("read %s ->" % (["0x%04X" % x for x in path_ids + [file_id]],), result(r))
    for t, v in r or []:
        if t not in (0x02,):
            print("  TLV 0x%02x (%dB): %s" % (t, len(v), v.hex()))
    return r

if __name__ == "__main__":
    print("uim port:", P)
    nums = [int(x, 16) for x in sys.argv[1:]]
    if len(nums) >= 2:
        read_file(nums[:-1], nums[-1])
    else:
        read_file([0x3F00, 0x7F10], 0x6F40)
