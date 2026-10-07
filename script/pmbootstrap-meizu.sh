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
set -euo pipefail
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$NURA_ROOT/config.sh"
CFG="$NURA_ROOT/script/pmbootstrap-meizu.cfg"

if [ -f "$PMB_CHECKOUT/pmbootstrap.py" ]; then
	exec python3 "$PMB_CHECKOUT/pmbootstrap.py" \
		-c "$CFG" -p "$PIN_PMAPORTS" -w "$PMB_WORK" "$@"
fi
exec pmbootstrap -c "$CFG" -p "$PIN_PMAPORTS" -w "$PMB_WORK" "$@"
