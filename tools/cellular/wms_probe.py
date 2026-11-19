#!/usr/bin/env python3
"""wms_probe.py — QMI WMS 短信探针（sms card 轮 2026-11-19）
用法：
  wms_probe.py info                 # Get Message Protocol + List Messages 全域扫描（只读）
  wms_probe.py listen [秒]          # 注册 new-MT event report + 监听 indication，收到即 Raw Read 打印
  wms_probe.py send <号码> <文本>   # Raw Send (TPDU GSM7)（外发 = 用户授权面）
基于 d1_bindmux.py qrtr 骨架（WDS svc=1 -> WMS svc=5）。
"""
import ctypes, select, struct, subprocess, sys, time

libc = ctypes.CDLL("libc.so.6", use_errno=True)
class SA(ctypes.Structure):
    _fields_ = [("f", ctypes.c_uint16), ("n", ctypes.c_uint32), ("p", ctypes.c_uint32)]
fd = libc.socket(42, 2, 0)  # AF_QIPC
sa = SA(); ln = ctypes.c_uint(12)
libc.getsockname(fd, ctypes.byref(sa), ctypes.byref(ln))
sa.p = 0
assert libc.bind(fd, ctypes.byref(sa), 12) == 0

WMS = 5
tid = 0x4000

def wms_port():
    out = subprocess.run(["qrtr-lookup"], capture_output=True, text=True, timeout=10).stdout
    for line in out.splitlines()[1:]:
        f = line.split()
        if len(f) >= 5 and f[0] == "5":  # Service 列 = WMS(5)
            try: return int(f[4])
            except ValueError: pass
    return None

P = wms_port()

def tlv(t, v): return struct.pack("<BH", t, len(v)) + v
def u32(v): return struct.pack("<I", v)
def u16(v): return struct.pack("<H", v)

def call(mid, tlvs=b"", timeout=10):
    """发请求收响应；同时把路过的 indication 塞回 ind_box。"""
    global tid
    if P is None: return None
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
        if flg == 2 and rtid == 0:  # 真指示（本 modem WMS 响应也标 flg=2，但 tid 回显非零）
            if s.p == P and data[7:7+hl]:
                ind_box.append((rmid, data[7:7+hl]))
            continue
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

ind_box = []

def result(res):
    if not res: return None
    for t, v in res:
        if t == 0x02 and len(v) >= 4: return struct.unpack("<HH", v[:4])
    return None

def get(res, tag):
    for t, v in res or []:
        if t == tag: return v
    return None

# ---- SMS 编解码（3GPP 23.040/23.038 minimal）----
def gsm7_encode(txt):
    """ASCII -> GSM 7-bit packed。GSM7 字母表外的字符不处理（探针用 ASCII）。"""
    special = {"\n": 10, "\r": 13}
    septs = []
    for ch in txt:
        if ch in special: septs.append(special[ch])
        elif 32 <= ord(ch) < 127: septs.append(ord(ch))
        elif ch == "@": septs.append(0)
        elif ch == "£": septs.append(1)
        elif ch == "$": septs.append(2)
        elif ch == "€": septs.append(0x1B << 3 | 0x35 & 7)
        else: septs.append(ord("?") & 0x7F)
    out = bytearray(); cur = 0; nbits = 0
    for c in septs:
        cur |= (c & 0x7F) << nbits
        nbits += 7
        while nbits >= 8:
            out.append(cur & 0xFF)
            cur >>= 8; nbits -= 8
    if nbits: out.append(cur & 0xFF)
    return bytes(out)

def gsm7_decode(data, count=None):
    n = count if count is not None else len(data) * 8 // 7
    out = []; cur = 0; nbits = 0
    for byte in data:
        cur |= byte << nbits
        nbits += 8
        while nbits >= 7 and len(out) < n:
            out.append(cur & 0x7F)
            cur >>= 7; nbits -= 7
    rev = {10: "\n", 13: "\r", 0: "@", 1: "£", 2: "$"}
    return "".join(rev.get(c, chr(c)) if c < 128 else "?" for c in out)

def parse_addr(octets):
    """SMSC/TP-DA 地址字段：len(半字节) + TON/NPI + BCD 数字。"""
    if not octets: return None, None
    ln = octets[0]
    ton = (octets[1] >> 4) & 0x07
    digits = ""
    for b in octets[2:2 + (ln + 1) // 2]:
        digits += str(b & 0xF) if (b & 0xF) <= 9 else ""
        if (b >> 4) <= 9: digits += str(b >> 4)
    if ton == 1: digits = "+" + digits
    return digits, ton

def parse_sms_deliver(tpdu, is_r=False):
    """SMS-DELIVER（含开头 SMSC 长度字节）-> (sender, text)。"""
    p = 0
    smsc_len = tpdu[p]; p += 1 + smsc_len
    if p >= len(tpdu): return None
    first = tpdu[p]; p += 1
    mti = first & 0x03
    if mti != 0:  # 非 SMS-DELIVER
        return ("MTI-%d" % mti, None)
    oa_len = tpdu[p]; p += 1
    oa = tpdu[p:p + 1 + (oa_len + 1) // 2]
    p += 1 + (oa_len + 1) // 2
    sender, _ = parse_addr(bytes([oa_len]) + oa if False else oa) if False else (None, None)
    # oa[0] 已是长度字节
    sender, ton = parse_addr(oa)
    p += 1  # TP-PID
    dcs = tpdu[p]; p += 1
    p += 7  # TP-SCTS
    udl = tpdu[p]; p += 1
    ud = tpdu[p:]
    text = None
    if dcs in (0x00, 0x08):
        pass
    if (dcs & 0xF0) in (0x00, 0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70) and not (dcs & 0x0C):
        text = gsm7_decode(ud, udl)   # GSM 7-bit
    elif dcs in (0x08,) or (dcs >> 2) & 3 == 2:
        text = ud[:udl].decode("utf-16-be", errors="replace")  # UCS2
    else:
        text = repr(ud[:udl])
    return (sender, text)

def build_submit(number, text):
    """SMS-SUBMIT TPDU（无 SMSC = 用默认）。GSM7 编码。"""
    def addr_field(num):
        ton = 1 if num.startswith("+") else 0  # 1= international
        digits = num.lstrip("+")
        if len(digits) % 2: digits += "F"
        bcd = bytearray()
        for i in range(0, len(digits), 2):
            hi = digits[i+1]
            bcd.append(int(digits[i]) | ((0xF if hi == "F" else int(hi)) << 4))
        return bytes([len(num.lstrip("+")), (ton << 4) | 1]) + bytes(bcd)
    ud = gsm7_encode(text)
    tp_da = addr_field(number)
    body = bytes([0x11])          # TP-MTI=SUBMIT + VPF=relative
    body += bytes([0x01])         # TP-MR
    body += tp_da
    body += bytes([0x00])         # TP-PID
    body += bytes([0x00])         # TP-DCS = GSM7
    body += bytes([0xAA])         # TP-VP (relative, ~24h)
    body += bytes([len(text)])    # TP-UDL (7-bit char count)
    body += ud
    return bytes([0x00]) + body   # SMSC len = 0 (用 modem 默认)

# ---- 子命令 ----
def cmd_debug():
    """一发请求 + 3 秒全包 dump（调试响应通道）。"""
    global tid
    print("wms port:", P)
    tid += 1
    pkt = struct.pack("<BHHH", 0, tid, 0x0033, 0)  # Get Routes
    d = SA(42, 0, P)
    libc.sendto(fd, pkt, len(pkt), 0, ctypes.byref(d), ctypes.sizeof(d))
    print("sent get-routes tid=0x%04x" % tid)
    dl = time.time() + 3
    while time.time() < dl:
        r, _, _ = select.select([fd], [], [], max(0.05, dl - time.time()))
        if not r: continue
        b = ctypes.create_string_buffer(16384)
        s = SA(); l = ctypes.c_uint(12)
        n = libc.recvfrom(fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
        if n < 7: continue
        data = b.raw[:n]
        flg, rtid, rmid, hl = struct.unpack("<BHHH", data[:7])
        print(f"  pkt from node={s.n} port={s.p} flg={flg} tid=0x{rtid:04x} msg=0x{rmid:04x} len={hl} head={data[7:20].hex()}")

def cmd_info():
    print("wms port:", P)
    r = call(0x0033)  # Get Routes（已知 qmicli 能答的命令，对照）
    print("get-routes ->", result(r), "nTLV:", len(r or []))
    print("get-protocol ->", result(r), "TLVs:", [(hex(t), v.hex()) for t, v in (r or []) if t != 2])
    for st in (0x00, 0x01, 0x02):
        r = call(0x0031, tlv(0x01, bytes([st])))
        res = result(r)
        lst = get(r, 0x01)
        n = u32(lst[:4])[0] if lst and len(lst) >= 4 else None
        print(f"list storage=0x{st:02x} -> {res} entries={n}")
        if lst:
            i = 4
            for _ in range(n):
                if i + 9 > len(lst): break
                stt, idx = struct.unpack("<BI", lst[i:i+5])
                tag, mode = struct.unpack("<BB", lst[i+5:i+7])
                print(f"   storage=0x{stt:02x} idx={idx} tag=0x{tag:02x} mode=0x{mode:02x}")
                i += 9

def read_raw(st, idx):
    r = call(0x0022, tlv(0x01, bytes([st]) + u32(idx)), timeout=10)
    if result(r) != (0, 0):
        print(f"raw-read st={st} idx={idx} -> {result(r)}")
        return None
    raw = get(r, 0x01)
    tag = raw[0]; fmt = raw[1]
    ln = struct.unpack("<H", raw[2:4])[0]
    data = raw[4:4+ln]
    print(f"raw-read st={st} idx={idx} tag=0x{tag:02x} fmt=0x{fmt:02x} len={ln}")
    print("  hex:", data.hex())
    if fmt in (0x01, 0x02):
        parsed = parse_sms_deliver(data)
        print("  parsed:", parsed)
    return data

def cmd_listen(seconds=600):
    r = call(0x0001, tlv(0x10, bytes([0x01])))  # Set Event Report: new MT indicator on
    print("event-report ->", result(r), flush=True)
    if result(r) not in ((0, 0), (0, 1)):
        print("event report 拒绝，继续监听 raw indications")
    print(f"listening {seconds}s ...", flush=True)
    dl = time.time() + seconds
    while time.time() < dl:
        r, _, _ = select.select([fd], [], [], 2)
        if not r:
            print(".", end="", flush=True)
            continue
        b = ctypes.create_string_buffer(16384)
        s = SA(); l = ctypes.c_uint(12)
        n = libc.recvfrom(fd, b, 16384, 0, ctypes.byref(s), ctypes.byref(l))
        if n < 7: continue
        data = b.raw[:n]
        flg, rtid, rmid, hl = struct.unpack("<BHHH", data[:7])
        if flg == 2 and rtid == 0 and s.p == P:
            body = data[7:7+hl]
            print(f"\nIND msg=0x{rmid:04x} len={hl} {body.hex()}", flush=True)
            # event report indication TLV 0x01? 找 storage/index 对
            i = 0
            while i + 3 <= len(body):
                t, ll = struct.unpack("<BH", body[i:i+3])
                v = body[i+3:i+3+ll]
                if t == 0x01 and ll >= 5:  # MT: storage type + index
                    stt, idx = struct.unpack("<BI", v[:5])
                    print(f"  -> new MT storage=0x{stt:02x} idx={idx}, reading...", flush=True)
                    read_raw(stt, idx)
                i += 3 + ll
    print("\nlisten done")

def cmd_send(number, text):
    tpdu = build_submit(number, text)
    print("TPDU hex:", tpdu.hex(), flush=True)
    r = call(0x0020, tlv(0x01, bytes([0x06]) + u16(len(tpdu)) + tpdu), timeout=30)
    print("raw-send ->", result(r))
    for t, v in r or []:
        if t != 0x02: print("  out TLV 0x%02x: %s" % (t, v.hex()))

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "info"
    if cmd == "debug": cmd_debug()
    elif cmd == "info": cmd_info()
    elif cmd == "listen": cmd_listen(int(sys.argv[2]) if len(sys.argv) > 2 else 600)
    elif cmd == "read": read_raw(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd == "send": cmd_send(sys.argv[2], sys.argv[3])
    else: print("unknown cmd")
