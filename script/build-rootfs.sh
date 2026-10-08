#!/usr/bin/env bash
# build-rootfs.sh — pmbootstrap install → userdata rootfs 镜像
#
# 用法: build-rootfs.sh
#   NURA_UI=phosh   可选桌面环境（默认 plasma-mobile；phosh=pmOS 官方包集，
#                   2026-10-09 构建上机验证；换 UI 构建前脚本会要求 chroot 已
#                   zap——见下方检查）
#   NURA_NO_RELEASE=1  跳过 Release 件固化（非 plasma UI 自动跳过，不污染发布面）
#
# 产物 = .pmbootstrap/chroot_native/home/pmos/rootfs/meizu-meizu20.img
#        非 plasma UI 另存 artifacts/meizu-meizu20-<ui>-local.img（本地刷写件）
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck
NURA_UI="${NURA_UI:-plasma-mobile}"

if [ -z "${NURA_INSIDE_UNIT:-}" ]; then
	echo "[i] 经 systemd-run 在宿主执行（ui=$NURA_UI）"
	export NURA_INSIDE_UNIT=1
	exec systemd-run --user --collect --quiet \
		--unit="pmx-nura-$(basename "$0" .sh)-$(date +%H%M%S)" \
		--setenv=NURA_INSIDE_UNIT=1 \
		--setenv=NURA_NO_RELEASE="${NURA_NO_RELEASE:-}" \
		--setenv=NURA_UI="$NURA_UI" \
		--working-directory="$NURA_ROOT" bash "$0" "$@"
fi

# ⚠ 换 UI 必须先 zap：rootfs chroot 复用会保留旧 UI 的 world（2026-10-09 实锤：
#   phosh 构建混入整套 plasma）。本地包仓（packages/，含 base-ui-gnome 等本地
#   构建件）不在 zap 范围，无需重建。
CHROOT="$PMB_WORK/chroot_rootfs_meizu-meizu20"
if [ -e "$CHROOT/etc/apk/world" ] && ! grep -q "^postmarketos-ui-$NURA_UI$" "$CHROOT/etc/apk/world" 2>/dev/null; then
	nura_die "rootfs chroot 的 world 与 NURA_UI=$NURA_UI 不符（残留旧 UI）。先跑: $PIN_PMB_WRAPPER zap"
fi

echo "[i] pmbootstrap install（ui=$NURA_UI / 密码 1234；~10-20 分钟）"
# ⚠ --single-partition 是铁律（experiment-log「pmOS 系统首次上机」）：默认 split 布局
# 产出 GPT 分区镜像 + fstab 假 /boot 条目；本机无 initramfs、内核 root=/dev/sda22
# 直挂 userdata 整块，GPT 镜像必挂载失败（kernel panic 停 Mu 画面）。
# 2026-10-07 实锤：Release r66 rootfs 漏此参数上机暴雷，本行即为修复。
"$PIN_PMB_WRAPPER" install --password 1234 --single-partition

OUT="$PMB_WORK/chroot_native/home/pmos/rootfs/meizu-meizu20.img"
[ -e "$OUT" ] || nura_die "找不到 rootfs 产物: $OUT"
echo "[✓] 产物: $OUT"
echo "    刷写: fastboot flash userdata $OUT（⚠ 全量重刷 = 机上手工补装件清零，"
echo "          四件套/rmtfs drop-in/uim 补丁/discover-backend 重装清单见指纹表）"

# ---- 非 plasma UI：本地刷写件 + 不进发布面 ----
if [ "$NURA_UI" != "plasma-mobile" ]; then
	LOCAL_IMG="$NURA_ROOT/artifacts/meizu-meizu20-$NURA_UI-local.img"
	cp "$OUT" "$LOCAL_IMG"
	echo "[✓] 本地刷写件: $LOCAL_IMG（$(du -h "$LOCAL_IMG" | cut -f1)）"
	echo "[i] 非 plasma UI 自动跳过 Release 件固化（不污染 artifacts/SHA256SUMS）"
	exit 0
fi

# ---- Release 件固化：gz（<2GiB = GitHub Release 单件上限）+ SHA256SUMS 行刷新 ----
# NURA_NO_RELEASE=1 跳过本段（本地实验件，不污染 artifacts/SHA256SUMS）
if [ -n "${NURA_NO_RELEASE:-}" ]; then
	echo "[i] NURA_NO_RELEASE=1：跳过 Release 件固化（仅本地产物 $OUT）"
	exit 0
fi
# rN 后缀从本地内核 apk 包名推导（linux-meizu-meizu20-7.3.0_rc3-r66.apk → r66）
KN="$(basename "$(ls "$APK_DIR/$PKG_LINUX-"*.apk | sort -V | tail -1)")"
REL_TAG="r${KN##*-r}"; REL_TAG="${REL_TAG%.apk}"
REL_DIR="$NURA_ROOT/artifacts"
OUT_GZ="$REL_DIR/meizu-meizu20-$REL_TAG.img.gz"
gzip -c "$OUT" > "$OUT_GZ"
SZ="$(stat -c%s "$OUT_GZ")"
[ "$SZ" -lt 2147483648 ] || nura_die "$OUT_GZ = $SZ 字节 ≥ 2GiB（GitHub Release 单件上限，需 sparse/分卷再议）"
SUMS="$REL_DIR/SHA256SUMS"
touch "$SUMS"
grep -vF "  $(basename "$OUT_GZ")" "$SUMS" > "$SUMS.tmp" || true
( cd "$REL_DIR" && sha256sum "$(basename "$OUT_GZ")" ) >> "$SUMS.tmp"
mv "$SUMS.tmp" "$SUMS"
echo "[✓] Release 件: $OUT_GZ（$(du -h "$OUT_GZ" | cut -f1)）+ SHA256SUMS 已刷新"
