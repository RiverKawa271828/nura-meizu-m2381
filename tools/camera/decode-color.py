#!/usr/bin/env python3
"""decode-color.py — Bayer RAW10 (pRAA, VFE RDI) -> color PNG, pure stdlib.

Usage: decode-color.py <frame.raw> <width> <height> <out.png> [stride] [step]

True CFA = GBRG (2026-11-20 round-112: red-box eye test — the driver's
SRGGB10 mbus label does NOT match the actual wire line order; grayscale is
unaffected, color needs gbrg). Each 2x2 Bayer
block maps to one RGB pixel directly (R + mean of two G + B) — no
demosaicing interpolation, so zero interpolation artifacts. Pixel[9:2]
high bytes only (the pRAA LSB nibble-pack byte injects salt-and-pepper
if treated as high bits — see decode-raw10.py). Pipeline: black-level
subtract -> gray-world white balance -> gamma 2.2 -> PNG RGB.
stride: row pitch; default = width*10/8 (tight), pass 5808 for VFE RDI
frames (16-byte aligned rows, 8B pad tail — cam-shot.sh logs bpl).
step: group sampling stride for preview speed (2 = quarter resolution).
"""
import struct
import sys
import zlib

raw_path, W, H, out_png = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
stride = int(sys.argv[5]) if len(sys.argv) > 5 else W * 10 // 8
step = int(sys.argv[6]) if len(sys.argv) > 6 else 2
cfa = sys.argv[7] if len(sys.argv) > 7 else "gbrg"
# class map per pattern over A=(evenRow,evenPx) B=(evenRow,oddPx)
# C=(oddRow,evenPx) D=(oddRow,oddPx); entry = (R, G1, G2, B) class indexes
CFA_MAP = {"srggb": (0, 1, 2, 3), "grbg": (1, 0, 3, 2),
           "gbrg": (2, 0, 3, 1), "bggr": (3, 1, 2, 0)}
ir, ig1, ig2, ib = CFA_MAP[cfa]

BLACK = 16          # ~64/4 in the 8-bit (pixel[9:2]) domain
GAMMA = 0.45

data = open(raw_path, "rb").read()
NGRP_ROW = W // 4
need = (H - 1) * stride + NGRP_ROW * 5
if len(data) < need:
    sys.exit(f"frame short: {len(data)} < {need}")

un = struct.Struct("<5B").unpack_from
ow = NGRP_ROW // step * 2
oh = (H // 2) // step
R = bytearray(ow * oh)
G = bytearray(ow * oh)
B = bytearray(ow * oh)

def get(y, g):
    b0, b1, b2, b3, _ = un(data, y * stride + g * 5)
    return b0, b1, b2, b3   # px0..3 high bytes; 5th = LSB/nibble column (skip)

sr = sg = sb = sn = 0
o = 0
for j in range(oh):
    y = j * step * 2          # even row of the Bayer block
    for i in range(0, NGRP_ROW, step):
        r0, g0, r1, g1_ = get(y, i)          # even row px0..3 (class A,B,A',B')
        gA, bA, gB, bB = get(y + 1, i)       # odd row  px0..3 (class C,D,C',D')
        # block1 from px0/px1, block2 from px2/px3
        cl = (r0, g0, gA, bA, r1, g1_, gB, bB)  # A,B,C,D then A',B',C',D'
        for base in (0, 4):
            v_r = max(0, cl[base + ir] - BLACK)
            v_g = max(0, (cl[base + ig1] + cl[base + ig2]) // 2 - BLACK)
            v_b = max(0, cl[base + ib] - BLACK)
            R[o], G[o], B[o] = v_r, v_g, v_b
            sr += v_r; sg += v_g; sb += v_b; sn += 1
            o += 1

# WB from high percentile per channel (robust vs black-level noise floor;
# bright surfaces are whitish). Then ONE global stretch (preserves WB), then gamma.
def pct(arr, q):
    s = sorted(arr[::16])
    return s[max(0, int(len(s) * q / 100) - 1)]

p90r, p90g, p90b = pct(R, 90), pct(G, 90), pct(B, 90)
gr = max(0.5, min(2.5, p90g / max(1, p90r)))
gb = max(0.5, min(2.5, p90g / max(1, p90b)))
allv = [v for v in R[::16]] + [v for v in G[::16]] + [v for v in B[::16]]
scale = 255.0 / max(1, pct(allv, 99))
print(f"p90 r={p90r} g={p90g} b={p90b} -> gains r=x{gr:.2f} b=x{gb:.2f}, "
      f"global stretch x{scale:.2f}")

lut = [min(255, int(255 * (v / 255) ** GAMMA)) for v in range(256)]
raw = bytearray()
for j in range(oh):
    raw.append(0)
    for i in range(ow):
        o = j * ow + i
        raw.append(lut[min(255, int(R[o] * gr * scale))])
        raw.append(lut[min(255, int(G[o] * scale))])
        raw.append(lut[min(255, int(B[o] * gb * scale))])

def chunk(tag, payload):
    c = struct.pack(">I", len(payload)) + tag + payload
    return c + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", ow, oh, 8, 2, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
       + chunk(b"IEND", b""))
open(out_png, "wb").write(png)
print(f"png {ow}x{oh} rgb -> {out_png}")
