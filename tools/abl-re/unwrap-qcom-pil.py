#!/usr/bin/env python3
"""unwrap-qcom-pil.py — QCOM PIL 包装（xbl/abl 这类）的两级解包 + 全段导出
链路：ELF(PT_LOAD) → [FV 或 LZMA 流] → FV → FFS → section（含 LZMA GUIDed）→ 全导出
用法：python3 unwrap-qcom-pil.py <image.img|elf> <outdir>
"""
import os, struct, lzma, sys, uuid, zlib, gzip, bz2

IN, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
raw = open(IN, "rb").read()
LZMA_GUIDS = {uuid.UUID("ee4e5898-3914-4259-9d6e-dc7bd79403cf"),
              uuid.UUID("d42ae6bd-1352-4bfb-909a-ca72a6eae889")}
s3 = lambda b: b[0] | (b[1] << 8) | (b[2] << 16)
nsec, seen = 0, set()

def dump(b, tag):
    global nsec
    if len(b) < 24 or b[:32] in seen:
        return
    seen.add(b[:32])
    nsec += 1
    open(os.path.join(OUT, f"d{nsec:04d}_{tag}.bin"), "wb").write(b)

def try_lzma(b, tag, depth=0):
    """尝试把 b 当成裸 LZMA 流（可能带 4/8/16 字节小头）解出来；成功则递归处理"""
    if depth > 4:
        return
    for skip in (0, 4, 8, 16, 12):
        try:
            dec = lzma.LZMADecompressor(format=lzma.FORMAT_ALONE).decompress(b[skip:])
        except Exception:
            continue
        if not dec:
            continue
        dump(dec, f"{tag}_lzma{skip}")
        handle(dec, f"{tag}_lz{depth}", depth+1)
        return

def try_wrappers(b, tag, depth=0):
    """gzip/bz2/zlib 也试（XBL 常用别的压缩）"""
    if depth > 4:
        return
    for name, fn in (("gzip", lambda x: gzip.decompress(x)),
                     ("zlib", lambda x: zlib.decompress(x)),
                     ("bz2", lambda x: bz2.decompress(x))):
        try:
            dec = fn(b)
        except Exception:
            continue
        if len(dec) > 64:
            dump(dec, f"{tag}_{name}")
            handle(dec, f"{tag}_{name}", depth+1)
            return

def parse_sections(buf, tag, depth=0):
    off, si = 0, 0
    while off + 4 <= len(buf) and depth < 8:
        size, stype = s3(buf[off:off+3]), buf[off+3]
        if size < 4 or off + size > len(buf):
            break
        sec = buf[off:off+size]
        if stype == 0x02:
            guid = uuid.UUID(bytes_le=sec[4:20])
            dataoff, _ = struct.unpack("<HH", sec[20:24])
            payload = sec[dataoff:]
            if guid in LZMA_GUIDS:
                try_lzma(payload, f"{tag}_secLZMA", depth+1)
            else:
                parse_sections(payload, f"{tag}_g{si}", depth+1)
        else:
            dump(sec[4:], f"{tag}_t{stype:02x}{si}")
        off += (size + 3) & ~3
        si += 1

def parse_fv(buf, tag, depth=0):
    if len(buf) < 0x48 or buf[0x28:0x2C] != b"_FVH":
        return
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
        parse_sections(buf[off+24:off+fsize], f"{tag}_f{fi}", depth+1)
        off = (off + fsize + 7) & ~7
        fi += 1

def handle(b, tag, depth=0):
    """统一入口：FV / LZMA / 裸段 都试"""
    if b[0x28:0x2C] == b"_FVH":
        dump(b, f"{tag}_FV")
        parse_fv(b, tag, depth)
        return
    try_wrappers(b, tag, depth)
    try_lzma(b, tag, depth)

# 1) ELF PT_LOAD 段（ELF32/ELF64 都认）
if raw[:4] == b"\x7fELF":
    is64 = raw[4] == 2
    if is64:
        e_phoff, = struct.unpack_from("<Q", raw, 0x20)
        e_phentsize, e_phnum = struct.unpack_from("<HH", raw, 0x36)
    else:
        e_phoff, = struct.unpack_from("<I", raw, 0x1C)
        e_phentsize, e_phnum = struct.unpack_from("<HH", raw, 0x2C)
    print(f"ELF{'64' if is64 else '32'}: phoff={e_phoff:#x} phnum={e_phnum}")
    for i in range(e_phnum):
        ph = raw[e_phoff + i*e_phentsize:][:e_phentsize]
        p_type, = struct.unpack_from("<I", ph, 0)
        if is64:
            p_offset, = struct.unpack_from("<Q", ph, 8); p_filesz, = struct.unpack_from("<Q", ph, 0x20)
        else:
            p_offset, = struct.unpack_from("<I", ph, 4); p_filesz, = struct.unpack_from("<I", ph, 0x10)
        if p_type == 1 and p_filesz:                     # PT_LOAD
            print(f"  PT_LOAD off={p_offset:#x} size={p_filesz:#x}")
            handle(raw[p_offset:p_offset+p_filesz], f"seg{i}", 0)

# 2) 兜底：整镜像再扫一遍（对齐 + 非对齐）
for off in range(0, min(len(raw), 0x40000), 0x1000):
    handle(raw[off:off+0x400000], f"raw{off:#x}", 0)
pos = 0
while True:
    i = raw.find(b"_FVH", pos)
    if i < 0 or i < 0x28:
        break
    handle(raw[i-0x28:], f"fv@{i-0x28:#x}", 0)
    pos = i + 4

print(f"导出 {nsec} 段 → {OUT}")
