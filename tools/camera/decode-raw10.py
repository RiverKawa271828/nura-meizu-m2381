#!/usr/bin/env python3
"""decode-raw10.py — MIPI RAW10 (pRAA, VFE packed) stats + grayscale PNG.

Usage: decode-raw10.py <frame.raw> <width> <height> [out.png] [step]
Pure stdlib (no numpy/PIL on this host). VFE RDI pRAA packing: 4 pixels in
5 bytes; byte4 carries the two low bits of each pixel. step=4 decodes every
4th pixel group (fast verify); step=1 = full decode (slow).
"""
import struct
import sys
import zlib

raw_path, W, H = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
out_png = sys.argv[4] if len(sys.argv) > 4 else None
step = int(sys.argv[5]) if len(sys.argv) > 5 else 4

data = open(raw_path, "rb").read()
NGRP = W * H // 4
need = NGRP * 5
if len(data) < need:
    sys.exit(f"frame short: {len(data)} < {need}")

groups = range(0, NGRP, step)
px = []
un = struct.Struct("<5B").unpack_from
for g in groups:
    b0, b1, b2, b3, b4 = un(data, g * 5)
    px.append(b0 | ((b4 & 0x03) << 8))
    px.append(b1 | ((b4 & 0x0C) << 6))
    px.append(b2 | ((b4 & 0x30) << 4))
    px.append(b3 | ((b4 & 0xC0) << 2))

n = len(px)
mn, mx = min(px), max(px)
mean = sum(px) / n
distinct = len(set(px))
nz = sum(1 for v in px if v)
print(f"frame {W}x{H} raw10 decode step={step}: px={n} "
      f"min={mn} max={mx} mean={mean:.1f} nonzero={nz} distinct={distinct}")

if out_png:
    # build image rows from px (which is strided W/step wide), 2x2 downsample
    iw = W // step
    ih = H // step
    iw -= iw % 2
    ih -= ih % 2
    gray = bytearray(iw * ih)
    for y in range(ih):
        base = y * 2 * iw  # take every other row and pair-column average
        src1 = base
        src2 = base + iw
        off = y * iw
        for x in range(iw):
            a1 = px[src1 + 2 * x]
            a2 = px[src1 + 2 * x + 1]
            b1 = px[src2 + 2 * x]
            b2 = px[src2 + 2 * x + 1]
            gray[off + x] = (a1 + a2 + b1 + b2) >> 4  # avg of 10-bit -> 8-bit
    raw = bytearray()
    for y in range(ih):
        raw.append(0)
        raw += gray[y * iw:(y + 1) * iw]

    def chunk(tag, payload):
        c = struct.pack(">I", len(payload)) + tag + payload
        return c + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", iw, ih, 8, 0, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
           + chunk(b"IEND", b""))
    open(out_png, "wb").write(png)
    print(f"png {iw}x{ih} -> {out_png}")
