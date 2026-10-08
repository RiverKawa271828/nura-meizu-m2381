#!/usr/bin/env bash
# pmbootstrap wrapper — Meizu 20 port（公开收编版；源头 = 私有工作区同名脚本）
#
# 组合三件东西跑官方 pmbootstrap（gitlab.postmarketos.org/postmarketOS/pmbootstrap）：
#   -c script/pmbootstrap-meizu.cfg   设备/桌面选择（本仓收编）
#   -p $PIN_PMAPORTS                  我们的 pmaports（device/downstream 三包）
#   -w $PMB_WORK                      work dir（chroot/缓存/本地包仓）
# pmbootstrap 本体：PMB_CHECKOUT 有树内 checkout 就用（setup.sh --clone 会拉），
# 否则回落 PATH（pipx/pip 安装均可）。宿主专用（沙箱会死于 sudo/losetup）。
#
# 本机注记：默认路径经 NURA_WORK 推导后与私有工作区原布局重合（work dir 与
# K30 wrapper 共享，须串行）；他机复刻 = NURA_WORK 指到任意可写根即可。
#
# 可选桌面环境：NURA_UI=<ui> 覆盖 cfg 的 ui= 行（默认 plasma-mobile；
# NURA_UI=phosh = pmOS 官方 phosh 包集，2026-10-09 构建上机验证）。pmbootstrap
# 的 ui 只能来自 cfg 文件，故按 UI 生成临时 cfg（/tmp，pmbootstrap 自读）。
# ⚠ 换 UI 后构建前须 `pmbootstrap zap` 清 rootfs chroot——chroot 复用会把
#   旧 UI 的 world 原样保留（2026-10-09 实锤：phosh 构建混入整套 plasma）。
set -euo pipefail
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$NURA_ROOT/config.sh"
CFG_SRC="$NURA_ROOT/script/pmbootstrap-meizu.cfg"
NURA_UI="${NURA_UI:-plasma-mobile}"
case "$NURA_UI" in
	*[!a-z0-9_-]*) echo "FATAL: NURA_UI 非法: $NURA_UI" >&2; exit 1 ;;
esac
CFG="$(mktemp /tmp/pmx-meizu-cfg-${NURA_UI}.XXXXXX.ini)"
sed "s/^ui = .*/ui = ${NURA_UI}/" "$CFG_SRC" > "$CFG"

if [ -f "$PMB_CHECKOUT/pmbootstrap.py" ]; then
	exec python3 "$PMB_CHECKOUT/pmbootstrap.py" \
		-c "$CFG" -p "$PIN_PMAPORTS" -w "$PMB_WORK" "$@"
fi
exec pmbootstrap -c "$CFG" -p "$PIN_PMAPORTS" -w "$PMB_WORK" "$@"
