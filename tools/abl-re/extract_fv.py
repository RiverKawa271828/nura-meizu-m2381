#!/usr/bin/env python3
"""递归解析 UEFI FV → FFS 文件 → section（含 LZMA GUIDed、嵌套 FV），导出 PE32 模块"""
import os, struct, lzma, sys, uuid

IN = sys.argv[1] if len(sys.argv) > 1 else "abl_a.img"
OUT = sys.argv[2] if len(sys.argv) > 2 else "out"
os.makedirs(OUT, exist_ok=True)
d = open(IN, "rb").read()

LZMA_GUID = uuid.UUID("ee4e5898-3914-4259-9d6e-dc7bd79403cf")
LZMAF86_GUID = uuid.UUID("d42ae6bd-1352-4bfb-909a-ca72a6eae889")
BRO_GUID = uuid.UUID("3d532050-5cda-4fd0-879e-0f7f630d5afb")

def s3(b):  # FFS 3-byte size
    return b[0] | (b[1] << 8) | (b[2] << 16)

n_module = 0

def parse_fv(buf, base_name, depth=0):
    ind = "  " * depth
    if len(buf) < 0x48 or buf[0x28:0x2C] != b"_FVH":
        print(f"{ind}[!] not an FV @ {base_name}")
        return
    fvlen, = struct.unpack("<Q", buf[0x20:0x28])
    hdrlen, = struct.unpack("<H", buf[0x30:0x32])
    exthdr, = struct.unpack("<H", buf[0x34:0x36])
    print(f"{ind}FV {base_name}: len={fvlen:#x} hdrlen={hdrlen:#x} guid={uuid.UUID(bytes_le=buf[16:32])}")
    off = hdrlen
    if exthdr:
        extsize, = struct.unpack("<H", buf[exthdr+16:exthdr+18])
        off = exthdr + extsize
        off = (off + 7) & ~7
    fi = 0
    while off + 24 <= min(fvlen, len(buf)):
        hdr = buf[off:off+24]
        name = uuid.UUID(bytes_le=hdr[0:16])
        ftype = hdr[18]
        size = s3(hdr[20:23])
        state = hdr[23]
        if size in (0, 0xFFFFFF) or state & 0x44 == 0:  # 空闲/无效
            break
        print(f"{ind} FILE[{fi}] {name} type={ftype:#x} size={size:#x} state={state:#x}")
        data = buf[off+24:off+size]
        parse_sections(data, f"{base_name}/f{fi}_{name.hex[:8]}", depth+1)
        off += size
        off = (off + 7) & ~7
        fi += 1

def parse_sections(buf, name, depth=0):
    global n_module
    ind = "  " * depth
    off = 0
    si = 0
    while off + 4 <= len(buf):
        size = s3(buf[off:off+3])
        stype = buf[off+3]
        if size < 4:
            break
        sec = buf[off:off+size]
        if stype == 0x02:  # GUID_DEFINED
            guid = uuid.UUID(bytes_le=sec[4:20])
            dataoff, attr = struct.unpack("<HH", sec[20:24])
            payload = sec[dataoff:]
            if guid == LZMA_GUID or guid == LZMAF86_GUID:
                try:
                    dec = lzma.decompress(payload, format=lzma.FORMAT_ALONE)
                except Exception:
                    dec = lzma.LZMADecompressor(format=lzma.FORMAT_ALONE).decompress(payload)
                print(f"{ind}SEC[{si}] LZMA {len(payload):#x}->{len(dec):#x} @{name}")
                fn = os.path.join(OUT, f"lzma_{name.replace('/','_')}.bin")
                open(fn, "wb").write(dec)
                # 解压结果可能是 FV 或裸 section 流，两种都试
                if dec[0x28:0x2C] == b"_FVH":
                    parse_fv(dec, name + "/lzma", depth+1)
                else:
                    parse_sections(dec, name + "/lzma", depth+1)
            else:
                print(f"{ind}SEC[{si}] GUIDed {guid} @{name}")
                parse_sections(payload, name + f"/g{si}", depth+1)
        elif stype == 0x10:  # PE32
            n_module += 1
            fn = os.path.join(OUT, f"mod{n_module:03d}_{name.replace('/','_')}.efi")
            open(fn, "wb").write(sec[4:])
            nt = sec[4:4+2]
            print(f"{ind}SEC[{si}] PE32 {len(sec)-4:#x} -> {fn}")
        elif stype == 0x17:  # 嵌套 FV
            parse_fv(sec[4:], name + f"/fv{si}", depth+1)
        elif stype == 0x15:  # UI name
            try:
                print(f"{ind}SEC[{si}] NAME: {sec[4:].decode('utf-16-le').rstrip(chr(0))}")
            except Exception:
                pass
        else:
            pass  # RAW 等
        off += size
        off = (off + 3) & ~3
        si += 1

parse_fv(d[0x1000:0x1000+0x32000], "abl")
print(f"\n共导出 {n_module} 个 PE 模块")
