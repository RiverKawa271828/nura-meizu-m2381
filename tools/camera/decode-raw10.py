#!/usr/bin/env python3
"""decode-raw10.py — MIPI RAW10 (pRAA, VFE packed) stats + grayscale PNG.

Usage: decode-raw10.py <frame.raw> <width> <height> [out.png] [step] [stride]
Pure stdlib (no numpy/PIL on this host). VFE RDI pRAA packing: 4 pixels in
5 bytes; byte4 carries the two low bits of each pixel. step=4 decodes every
4th pixel group (fast verify); step=1 = full decode (slow).

stride: bytes per row pitch in the buffer. Default = width*10/8 (tight pack,
legacy sweep files). VFE RDI pads rows to 16-byte alignment: 4640px -> 5800B
data + 8B pad tail = 5808 pitch (cam-shot.sh frames; tail = pad junk at black
level + LSB fragments, no information — round-112 forensics). Pass 5808 (or
read bpl from v4l2-ctl --get-fmt, cam-shot.sh logs it) or rows drift by 8B
per line and the scene dissolves into aliasing artifacts — the round-111
"tearing" was exactly this, a decoder assumption, not bad data.
"""
import struct
import sys
import zlib

raw_path, W, H = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
out_png = sys.argv[4] if len(sys.argv) > 4 else None
step = int(sys.argv[5]) if len(sys.argv) > 5 else 4
stride = int(sys.argv[6]) if len(sys.argv) > 6 else W * 10 // 8

data = open(raw_path, "rb").read()
NGRP_ROW = W // 4
need = (H - 1) * stride + NGRP_ROW * 5
if len(data) < need:
    sys.exit(f"frame short: {len(data)} < {need}")

un = struct.Struct("<5B").unpack_from
px = []      # full 10-bit values (stats)
hi = []      # pixel[9:2] high bytes only — smooth render source (the LSB
             # nibble-pack byte injected as high bits is salt-and-pepper noise)
for y in range(0, H, step):
    base = y * stride
    for g in range(0, NGRP_ROW, step):
        b0, b1, b2, b3, b4 = un(data, base + g * 5)
        px.append(b0 | ((b4 & 0x03) << 8))
        px.append(b1 | ((b4 & 0x0C) << 6))
        px.append(b2 | ((b4 & 0x30) << 4))
        px.append(b3 | ((b4 & 0xC0) << 2))
        hi.extend((b0, b1, b2, b3))

n = len(px)
mn, mx = min(px), max(px)
mean = sum(px) / n
distinct = len(set(px))
nz = sum(1 for v in px if v)
print(f"frame {W}x{H} raw10 stride={stride} step={step}: px={n} "
      f"min={mn} max={mx} mean={mean:.1f} nonzero={nz} distinct={distinct}")

if out_png:
    # hi holds H/step sampled rows of W/step high bytes (row-major,
    # stride-aware decode above); 2x2 box-downsample -> grayscale PNG
    iw = W // step
    sh = len(hi) // iw
    ow, oh = iw // 2, sh // 2
    # min-max stretch so any capture renders viewable (dark-room shots stay dark otherwise)
    lo, hi_v = min(hi), max(hi)
    span = max(1, hi_v - lo)
    gray = bytearray(ow * oh)
    for yy in range(oh):
        r1 = hi[(2 * yy) * iw: (2 * yy) * iw + iw]
        r2 = hi[(2 * yy + 1) * iw: (2 * yy + 1) * iw + iw]
        off = yy * ow
        for xx in range(ow):
            x2 = 2 * xx
            v = (r1[x2] + r1[x2 + 1] + r2[x2] + r2[x2 + 1]) >> 2
            gray[off + xx] = (v - lo) * 255 // span
    raw = bytearray()
    for yy in range(oh):
        raw.append(0)  # PNG filter: none
        raw += gray[yy * ow:(yy + 1) * ow]

    def chunk(tag, payload):
        c = struct.pack(">I", len(payload)) + tag + payload
        return c + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", ow, oh, 8, 0, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
           + chunk(b"IEND", b""))
    open(out_png, "wb").write(png)
    print(f"png {ow}x{oh} -> {out_png}")
