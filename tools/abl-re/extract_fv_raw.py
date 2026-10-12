#!/usr/bin/env python3
"""extract_fv_raw.py — 在任意分区镜像里扫所有 UEFI FV，把**每一段（含 RAW）**都导出。
用途：找回原厂面板 XML（RAW freeform 段，原 extract_fv.py 只导 PE 会漏掉）。
用法：python3 extract_fv_raw.py <image.img> <outdir>
"""
import os, struct, lzma, sys, uuid

IN = sys.argv[1]
OUT = sys.argv[2]
os.makedirs(OUT, exist_ok=True)
d = open(IN, "rb").read()

LZMA_GUIDS = {uuid.UUID("ee4e5898-3914-4259-9d6e-dc7bd79403cf"),
              uuid.UUID("d42ae6bd-1352-4bfb-909a-ca72a6eae889")}
s3 = lambda b: b[0] | (b[1] << 8) | (b[2] << 16)
seen, n, nsec = set(), 0, 0

def dump(payload, tag):
    global nsec
    if len(payload) < 16 or payload in seen:
        return
    seen.add(payload)
    nsec += 1
    fn = os.path.join(OUT, f"s{nsec:04d}_{tag}.bin")
    open(fn, "wb").write(payload)

def parse_sections(buf, tag, depth=0):
    off, si = 0, 0
    while off + 4 <= len(buf) and depth < 6:
        size, stype = s3(buf[off:off+3]), buf[off+3]
        if size < 4 or off + size > len(buf):
            break
        sec = buf[off:off+size]
        if stype == 0x02:                                    # GUID_DEFINED
            guid = uuid.UUID(bytes_le=sec[4:20])
            dataoff, _ = struct.unpack("<HH", sec[20:24])
            payload = sec[dataoff:]
            if guid in LZMA_GUIDS:
                for fmt in (lzma.FORMAT_ALONE,):
                    try:
                        dec = lzma.LZMADecompressor(format=fmt).decompress(payload)
                        if dec[:4] not in (b"",):
                            dump(dec, f"{tag}_lzma")
                            if dec[0x28:0x2C] == b"_FVH":
                                parse_fv(dec, f"{tag}_lzmaFV", depth+1)
                            else:
                                parse_sections(dec, f"{tag}_lzma", depth+1)
                        break
                    except Exception:
                        pass
            else:
                parse_sections(payload, f"{tag}_g{si}", depth+1)
        else:
            dump(sec[4:], f"{tag}_t{stype:02x}{si}")          # 所有类型都导（含 RAW 0x19/UI）
        off += (size + 3) & ~3
        si += 1

def parse_fv(buf, tag, depth=0):
    global n
    if buf[0x28:0x2C] != b"_FVH":
        return
    n += 1
    fvlen, = struct.unpack("<Q", buf[0x20:0x28])
    hdrlen, = struct.unpack("<H", buf[0x30:0x32])
    exthdr, = struct.unpack("<H", buf[0x34:0x36])
    off = hdrlen
    if exthdr:
        extsize, = struct.unpack("<H", buf[exthdr+16:exthdr+18])
        off = (exthdr + extsize + 7) & ~7
    fi = 0
    while off + 24 <= min(fvlen, len(buf)):
        hdr = buf[off:off+24]
        fsize, state = s3(hdr[20:23]), hdr[23]
        if fsize in (0, 0xFFFFFF) or state & 0x44 == 0:
            break
        parse_sections(buf[off+24:off+fsize], f"fv{n}_f{fi}", depth+1)
        off = (off + fsize + 7) & ~7
        fi += 1

# 全镜像扫 "_FVH"（FV 头标识在 +0x28）
pos = 0
while True:
    i = d.find(b"_FVH", pos)
    if i < 0 or i < 0x28:
        break
    parse_fv(d[i-0x28:], f"@{i-0x28:#x}")
    pos = i + 4

print(f"发现 {n} 个 FV，导出 {nsec} 段 → {OUT}")
