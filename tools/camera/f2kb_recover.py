#!/usr/bin/env python3
"""Decode and enhance the supplied headerless camera dump as an 8-bit plane.

This reproduces the exploratory rendering used for f2kb.raw. It does NOT
perform row-by-row geometric registration, Bayer demosaicing, or RAW unpacking.
"""
from pathlib import Path
import argparse
import numpy as np
import cv2


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", nargs="?", default="f2kb.raw")
    ap.add_argument("--width", type=int, default=5808)
    ap.add_argument("--height", type=int, default=3488)
    ap.add_argument("--gamma", type=float, default=0.55)
    ap.add_argument("--clip-limit", type=float, default=2.5)
    ap.add_argument("--tiles-x", type=int, default=12)
    ap.add_argument("--tiles-y", type=int, default=8)
    ap.add_argument("--output", default="f2kb_recovered.png")
    ap.add_argument("--stages", default="f2kb_stages.png")
    args = ap.parse_args()

    raw_path = Path(args.input)
    b = np.fromfile(raw_path, dtype=np.uint8)
    expected = args.width * args.height
    if b.size != expected:
        raise SystemExit(
            f"Size mismatch: {b.size:,} bytes, but {args.width}x{args.height} "
            f"requires {expected:,} bytes. Check width/height/format."
        )

    # Interpret each byte as one grayscale sample, row-major.
    img = b.reshape((args.height, args.width))

    # Robust contrast stretch: ignore the darkest 1% and brightest 0.2% tails.
    lo, hi = np.percentile(img, [1, 99.8])
    if hi <= lo:
        raise SystemExit(f"Invalid contrast range: low={lo}, high={hi}")
    linear = np.clip((img.astype(np.float32) - lo) / (hi - lo), 0, 1)

    # Gamma < 1 lifts midtones / shadows.
    gamma = np.clip(linear ** args.gamma * 255, 0, 255).astype(np.uint8)

    # Local contrast enhancement (CLAHE), not geometric de-warping.
    clahe = cv2.createCLAHE(
        clipLimit=args.clip_limit,
        tileGridSize=(args.tiles_x, args.tiles_y),
    )
    enhanced = clahe.apply(gamma)

    cv2.imwrite(args.output, enhanced)

    # Make a compact 3-panel comparison for inspection.
    def shrink(x):
        return cv2.resize(x, (args.width // 4, args.height // 4),
                          interpolation=cv2.INTER_AREA)
    panel = cv2.hconcat([shrink(img), shrink(gamma), shrink(enhanced)])
    cv2.imwrite(args.stages, panel)

    print(f"Input: {raw_path} ({b.size:,} bytes)")
    print(f"Interpretation: uint8 grayscale plane, {args.width}x{args.height}")
    print(f"Percentile range: p1={lo:.2f}, p99.8={hi:.2f}")
    print(f"Gamma: {args.gamma}")
    print(f"CLAHE: clipLimit={args.clip_limit}, tiles=({args.tiles_x},{args.tiles_y})")
    print(f"Saved enhanced image: {args.output}")
    print(f"Saved stage comparison: {args.stages}")


if __name__ == "__main__":
    main()
