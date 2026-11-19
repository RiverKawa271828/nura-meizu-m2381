import ctypes, select, struct, time, subprocess
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
tid = 0x3000
def call(svc, mid, tlvs, timeout=10):
    global tid
    if svc not in P: return None
    tid += 1
    pkt = struct.pack("<BHHH", 0, tid, mid, len(tlvs)) + tlvs
    d = SA(42, 0, P[svc])
    libc.sendto(fd, pkt, len(pkt), 0, ctypes.byref(d), ctypes.sizeof(d))
    dl = time.time() + timeout
    while time.time() < dl:
        r, _, _ = select.select([fd], [], [], max(0.1, dl - time.time()))
        if not r: break
        b = ctypes.create_string_buffer(16384)
        s = SA(); l = ctypes.c_uint(12)
        n = libc.recvfrom(fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
        if n < 7: continue
        data = b.raw[:n]
        _, rtid, rmid, hl = struct.unpack("<BHHH", data[:7])
        if rtid != tid or rmid != mid: continue
        body = data[7:7+hl]
        out = []
        i = 0
        while i + 3 <= len(body):
            t, ll = struct.unpack("<BH", body[i:i+3])
            out.append((t, body[i+3:i+3+ll]))
            i += 3 + ll
        return out
    return None
def tlv(t, v): return struct.pack("<BH", t, len(v)) + v
def u32(v): return struct.pack("<I", v)
def result(res):
    if not res: return None
    for t, v in res:
        if t == 0x02 and len(v) >= 4: return struct.unpack("<HH", v[:4])
    return None

# Step A: bind mux 彼仓三 TLV 形态，mux 0xF1 起逐个换
bound = None
for mux in (0xF1, 0xF2, 0xF3):
    r = call(1, 0x00A2, tlv(0x10, u32(4) + u32(1)) + tlv(0x11, bytes([mux])) + tlv(0x13, u32(1)))
    print("bind mux 0x%02X -> %s" % (mux, result(r)), flush=True)
    if result(r) == (0, 0):
        bound = mux
        break
    time.sleep(0.8)
if not bound:
    print("ALL-MUX-REJECTED", flush=True)
    raise SystemExit(1)
# Step B: bind subscription
r = call(1, 0x00AF, tlv(0x01, u32(1)))
print("bind sub ->", result(r), flush=True)
# Step C: start network (彼仓形态: TLV0x14=APN + TLV0x19=ip family 4)
r = call(1, 0x0020, tlv(0x14, b"cbnet") + tlv(0x19, bytes([4])), timeout=45)
print("start network ->", result(r), flush=True)
if result(r) != (0, 0):
    raise SystemExit(2)
# Step D: get current settings
r = call(1, 0x002D, b"", timeout=15)
def ip_of(res, tag):
    if not res: return None
    for t, v in res:
        if t == tag and len(v) == 4:
            return ".".join(str(x) for x in reversed(v))
    return None
addr, d1, d2 = ip_of(r, 0x1E), ip_of(r, 0x15), ip_of(r, 0x16)
print("mux=0x%02X addr=%s dns=%s,%s" % (bound, addr, d1, d2), flush=True)
if addr:
    open("/root/.d1-mux", "w").write(str(bound))
    open("/root/.d1-addr", "w").write(addr)
    print("SAVED", flush=True)
