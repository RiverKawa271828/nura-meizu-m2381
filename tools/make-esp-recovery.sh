#!/usr/bin/env bash
# make-esp-recovery.sh <vmlinuz-efi> <out-esp.img>
#
# ESP for the m2381Pkg UEFI chain (recovery_a).  Recipe lineage = v4d/v6:
# 100MiB FAT32, 512B sectors, geometry 16 heads / 63 spt (matches the BPB of
# the known-good esp-recovery-v6-m3.img).  The kernel MUST land at
# \EFI\BOOT\BOOTAA64.EFI - MsBootPolicy only tries the standard path;
# mkfs.vfat or root-directory placement both fail (experiment-log T-B2).
set -euo pipefail

kern=$1
out=$2

rm -f "$out"
truncate -s 100M "$out"
mformat -i "$out" -C -T 204800 -h 16 -s 63 -F ::
mmd -i "$out" ::/EFI ::/EFI/BOOT
mcopy -i "$out" "$kern" ::/EFI/BOOT/BOOTAA64.EFI
mdir -i "$out" ::/EFI/BOOT/
sha256sum "$out"
