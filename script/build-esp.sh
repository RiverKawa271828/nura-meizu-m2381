#!/usr/bin/env bash
# build-esp.sh — linux apk 里的 vmlinuz-efi → ESP 镜像（recovery_a 腿）
#
# 用法: build-esp.sh [NN]      （版本号纯数字；缺省 = artifacts 已有最大 vN + 1）
#
# 配方 = make-esp-recovery.sh（meizu20-m1/tools，v4d/v6 血统）：
# 100MiB FAT32 512B，内核必须落 \EFI\BOOT\BOOTAA64.EFI。
# ⚠ 刷 ESP ≠ 换模块：只刷 recovery_a 不装 apk = 模块腿没跟上（两腿铁律）。
# ⚠ 覆盖雷（2026-10-11 r83 轮事故）：缺省版本号原取「现役钉子+1」，但钉子按流程
#   滞后于最新候选（等彼线点火 PASS 才更）⇒ 撞回最新候选号把 v63 覆盖。
#   现改为「artifacts 已有最大 vN + 1」，并对入参做纯数字校验。
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck

REL="${1:-}"
if [ -z "$REL" ]; then
	CUR=$(ls "$NURA_ROOT"/artifacts/esp-recovery-v*.img* 2>/dev/null \
		| sed -E 's/.*esp-recovery-v([0-9]+)\.img(\.gz)?$/\1/' | sort -n | tail -1)
	[ -n "$CUR" ] || nura_die "artifacts 无既有 ESP 可推版本号，请显式传参"
	REL=$((CUR + 1))
elif ! [[ "$REL" =~ ^[0-9]+$ ]]; then
	nura_die "版本号须为纯数字（build-esp.sh 64，不带 v），收到: $REL"
fi

PKGREL=$(grep -m1 '^pkgrel=' "$PIN_PMAPORTS/device/downstream/$PKG_LINUX/APKBUILD" | cut -d= -f2)
APK="$APK_DIR/${PKG_LINUX}-${PKGVER}-r${PKGREL}.apk"
[ -e "$APK" ] || nura_die "apk 不存在: $APK（先 build-kernel.sh）"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
echo "[1/2] 从 apk 抽 boot/vmlinuz-efi"
tar -xzf "$APK" -C "$WORK" boot/vmlinuz-efi 2>/dev/null

OUT="$NURA_ROOT/artifacts/esp-recovery-v${REL}.img.gz"
RAW="$WORK/esp-recovery-v${REL}.img"
mkdir -p "$NURA_ROOT/artifacts"
echo "[2/2] 造 ESP v${REL}（裸镜像 100MiB，gz 入库——GitHub 单文件上限规避）"
"$PIN_TOOLS/make-esp-recovery.sh" "$WORK/boot/vmlinuz-efi" "$RAW"
gzip -9 -c "$RAW" > "$OUT"

echo "[✓] 产物: $OUT"
echo "    裸镜像 sha256: $(gunzip -c "$OUT" | sha256sum | cut -c1-8)…（=出货 gz 解压反推真值，readback/MANIFEST 用这个）"
echo "    gz sha256: $(sha256sum "$OUT" | cut -c1-8)…"
echo "    ⚠ 两腿铁律：刷这个 ESP 必须同轮装同 pkgrel 的 apk（模块腿）"
