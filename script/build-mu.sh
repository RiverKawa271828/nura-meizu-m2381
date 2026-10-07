#!/usr/bin/env bash
# build-mu.sh — apk 里的 DTB → Mu FdtBlob → build_uefi.py → mu-rXX.img（boot_b 腿）
#
# 用法: build-mu.sh [--no-sync]    （--no-sync = 只重编不同步 DTB）
#
# 铁律（（四十九）教训）：**仅 DTS 变了才需要重编 Mu**；但只要重编，
# FdtBlob 必须来自**同一个 apk 的 dtb**（verify.sh 会做 sha 对拍）。
# 我方 BootShim 代码一律 movz/movk 构造常量（硬定律 #2 双面律）。
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck

SYNC=1
[ "${1:-}" = "--no-sync" ] || [ "${1:-}" = "" ] || { echo "unknown arg: $1"; exit 2; }
[ "${1:-}" = "--no-sync" ] && SYNC=0

PKGREL=$(grep -m1 '^pkgrel=' "$PIN_PMAPORTS/device/downstream/$PKG_LINUX/APKBUILD" | cut -d= -f2)
APK="$APK_DIR/${PKG_LINUX}-${PKGVER}-r${PKGREL}.apk"
[ -e "$APK" ] || nura_die "apk 不存在: $APK（先 build-kernel.sh）"

FDTBLOB="$PIN_MU_DIR/Platforms/Meizu/m2381Pkg/FdtBlob/sm8550-meizu-20.dtb"

if [ "$SYNC" = 1 ]; then
	WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
	echo "[1/3] 从 apk r${PKGREL} 抽 DTB → Mu FdtBlob"
	tar -xzf "$APK" -C "$WORK" boot/dtbs/qcom/sm8550-meizu-20.dtb 2>/dev/null
	cp "$WORK/boot/dtbs/qcom/sm8550-meizu-20.dtb" "$FDTBLOB"
	echo "    新 FdtBlob sha256: $(sha256sum "$FDTBLOB" | cut -c1-8)…"
	echo "    ⚠ 记得更新 Source.txt + Mu 树 git commit（交付链纪律）"
else
	echo "[1/3] 跳过 DTB 同步（沿用现 FdtBlob $(sha256sum "$FDTBLOB" | cut -c1-8)…）"
fi

echo "[2/3] build_uefi.py -d m2381（clang 需 linuxbrew PATH；约 1-7 分钟增量）"
cd "$PIN_MU_DIR"
export PATH="${NURA_LINUXBREW:-$HOME/ubuntu/.linuxbrew/bin:$HOME/.linuxbrew/bin}:$PATH"
# build_uefi.py 依赖 coloredlogs 等 = 只在树内 .venv 有（系统 python3 缺）
[ -x .venv/bin/python ] || nura_die ".venv/bin/python 不存在（Mu 树 venv 未建）"
.venv/bin/python build_uefi.py -d m2381 -r RELEASE

RAWIMG=$(ls -t Mu-m2381*.img 2>/dev/null | head -1)
[ -n "$RAWIMG" ] || nura_die "找不到 build_uefi.py 产物 Mu-m2381*.img"

OUT="$NURA_ROOT/artifacts/mu-r${PKGREL}-$(sha256sum "$RAWIMG" | cut -c1-8).img"
mkdir -p "$NURA_ROOT/artifacts"
mv "$RAWIMG" "$OUT"
echo "[3/3] ✓ 产物: $OUT"
echo "    ⚠ 提醒：若 T2 统一命名改了 SMBIOS/model，本镜像作废须重编"
