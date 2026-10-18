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
# 本机注记：布局 v3（2026-10-13）= 源树全部独立仓库零内聚，路径经 config.sh
# 钉子表推导；K30 已退役，work dir 独占纪律只剩本机并发互斥。
# 他机/CI 复刻 = NURA_WORK（或 NURA_*_DIR 各钉）指到任意可写根即可。
#
# 可选桌面环境：NURA_UI=<ui> 覆盖 cfg 的 ui= 行（默认 plasma-mobile；
# NURA_UI=phosh = pmOS 官方 phosh 包集，2026-10-09 构建上机验证）。pmbootstrap
# 的 ui 只能来自 cfg 文件，故按 UI 生成临时 cfg（/tmp，pmbootstrap 自读）。
# ⚠ 换 UI 后构建前须 `pmbootstrap zap` 清 rootfs chroot——chroot 复用会把
#   旧 UI 的 world 原样保留（2026-10-09 实锤：phosh 构建混入整套 plasma）。
#
# 沙箱守卫（2026-10-19 落地；build-kernel.sh 同款）：pmbootstrap 必须宿主跑
# （沙箱 sudo/losetup 必死）→ 未带 NURA_INSIDE_UNIT 标记时自动经 systemd-run
# 重入。守卫三坑（改守卫前必读，本仓 AGENTS 工程规则 #1）：
#   ① ZCode 沙箱 shell 里 INVOCATION_ID 天生有值，不能当「已在宿主单元内」
#     判据——只认显式 NURA_INSIDE_UNIT；
#   ② VAR=1 exec cmd 不把变量带进 systemd 单元，必须 export；
#   ③ systemd-run 默认不透传调用方环境，跨单元传标记/钉子必须 --setenv=。
# 最终形态 = 显式 NURA_INSIDE_UNIT 标记 + --setenv + 时间戳单元名（防自撞）；
# NURA_*/PMB_* 已设钉子逐个透传（config.sh 全按 ${VAR:-默认} 消费，未设不传）。
# ⚠ 直调本 wrapper 而无守卫 = 沙箱 sudo mknod EPERM（2026-10-19 rc7 演练轮新坑，
#   本守卫根治；CI 无 systemd，workflow 侧已显式 export NURA_INSIDE_UNIT=1）。
set -euo pipefail
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$NURA_ROOT/config.sh"

# ---- 沙箱守卫：无 NURA_INSIDE_UNIT = 不在宿主单元内 → systemd-run 重入 ----
# 置于 cfg 生成之前：外层不产生临时 cfg，内层自会按（透传的）NURA_UI 重生成。
if [ -z "${NURA_INSIDE_UNIT:-}" ]; then
	echo "[i] 经 systemd-run 在宿主执行"
	setenv_args=(--setenv=NURA_INSIDE_UNIT=1)
	for v in NURA_WORK NURA_UI NURA_LINUX_DIR NURA_MU_DIR NURA_PMAPORTS_DIR \
		NURA_PMB_WRAPPER NURA_PMB_CHECKOUT NURA_PMB_WORK NURA_APK_DIR; do
		[ -n "${!v:-}" ] && setenv_args+=(--setenv="$v=${!v}")
	done
	exec systemd-run --user --collect --quiet \
		--unit="pmx-nura-meizu-wrapper-$(date +%H%M%S)" \
		"${setenv_args[@]}" \
		--working-directory="$NURA_ROOT" bash "$0" "$@"
fi

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
