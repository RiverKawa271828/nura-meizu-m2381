#!/usr/bin/env bash
# build-esp.sh — linux apk 里的 vmlinuz-efi → ESP 镜像（recovery_a 腿）
#
# 用法: build-esp.sh [vNN]      （版本号缺省 = 现役 REL_ESP 版本 +1）
#
# 配方 = make-esp-recovery.sh（meizu20-m1/tools，v4d/v6 血统）：
# 100MiB FAT32 512B，内核必须落 \EFI\BOOT\BOOTAA64.EFI。
# ⚠ 刷 ESP ≠ 换模块：只刷 recovery_a 不装 apk = 模块腿没跟上（两腿铁律）。
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck

REL="${1:-}"
if [ -z "$REL" ]; then
	CUR=$(basename "$REL_ESP_IMG" | sed -E 's/.*v([0-9]+)\.img/\1/')
	REL=$((CUR + 1))
fi

PKGREL=$(grep -m1 '^pkgrel=' "$PIN_PMAPORTS/device/downstream/$PKG_LINUX/APKBUILD" | cut -d= -f2)
APK="$APK_DIR/${PKG_LINUX}-${PKGVER}-r${PKGREL}.apk"
[ -e "$APK" ] || nura_die "apk 不存在: $APK（先 build-kernel.sh）"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
echo "[1/2] 从 apk 抽 boot/vmlinuz-efi"
tar -xzf "$APK" -C "$WORK" boot/vmlinuz-efi 2>/dev/null

OUT="$NURA_ROOT/artifacts/esp-recovery-v${REL}.img"
mkdir -p "$NURA_ROOT/artifacts"
echo "[2/2] 造 ESP v${REL}"
"$PIN_TOOLS/make-esp-recovery.sh" "$WORK/boot/vmlinuz-efi" "$OUT"

echo "[✓] 产物: $OUT"
echo "    sha256: $(sha256sum "$OUT" | cut -c1-8)…（记入 MANIFEST.md）"
echo "    ⚠ 两腿铁律：刷这个 ESP 必须同轮装同 pkgrel 的 apk（模块腿）"
