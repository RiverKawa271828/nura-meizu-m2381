#!/usr/bin/env bash
# nura-meizu-m2381 — 全局钉子（唯一定位点）
#
# 东西搬家只改这里。Phase-2（公开发布）时把 PIN_*_GIT 换成公共 URL，
# setup.sh 即可在任何机器复刻本布局；本机阶段 PIN_*_GIT 留空 = 用本地路径。
#
# 本文件只被 source，不直接执行。

# ---- 工作区 ----
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 他机复刻只改这一个根（export NURA_WORK=/path 或改下行默认）；本机 = ~/work
NURA_WORK="${NURA_WORK:-~/work}"

# ---- 源码树（本地现役；公共 clone URL 见下方 PIN_*_GIT）----
PIN_LINUX_DIR="${NURA_LINUX_DIR:-$NURA_WORK/linux-mobile-ports}"          # fork 内核树
PIN_LINUX_BRANCH="meizu20-t4b"
PIN_MU_DIR="${NURA_MU_DIR:-$NURA_WORK/meizu20/mu-uefi/Mu-Silicium-new}"   # Mu 树
PIN_MU_BRANCH="meizu20-mars-port"
PIN_PMAPORTS="${NURA_PMAPORTS_DIR:-$NURA_WORK/pmos_linux/pmos/pmaports}"
PIN_PMAPORTS_BRANCH="phoenix"
PIN_PMB_WRAPPER="${NURA_PMB_WRAPPER:-$NURA_WORK/pmos_linux/pmos/pmbootstrap-meizu.sh}"
PIN_TOOLS="${NURA_TOOLS_DIR:-$NURA_WORK/meizu20/meizu20-m1/tools}"        # make-esp-recovery.sh / devsh.py

# ---- 公共仓 URL（Phase-2；setup.sh --clone 按此摆位，空 = 不启用）----
PIN_LINUX_GIT=""       # fork torvalds/linux → 推分支 meizu20-t4b（基点 58785836 = 主线 7.3 merge window，只传 78 个增量 commit）
PIN_MU_GIT=""          # fork Project-Silicium/Mu-Silicium → 推分支 meizu20-mars-port（= 1 silime 中间件 + 23 我方 commit）
PIN_MU_BINARIES_GIT="" # fork Project-Silicium/Device-Binaries → 推 Binaries 钉住的 036ba9f7（"mars: Initial support"，不在上游 main）
PIN_PMAPORTS_GIT=""    # 新建独立仓整条推 phoenix（.git 仅 69MB）；或 fork GitHub postmarketOS 镜像再推分支

# ---- 包身份 ----
PKGVER="7.3.0_rc3"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="${NURA_APK_DIR:-$NURA_WORK/pmos_linux/pmos/.pmbootstrap/packages/edge/aarch64}"

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="66"      # 已构建 apk 的 pkgrel（r66 = fsa4480 摘除+PSI=y 载体，10-07）
REL_DEVICE_PKGREL="47"     # r47 = sndcard-bind guard autoprobe 修复，10-06
REL_FW_PKGREL="3"
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r66-9033a734.img"
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v47.img"
REL_KERNEL_VER="#67"       # 下次上机 uname 期望（r66 内核 + #N=pkgrel+1 定律）

# ---- 回滚锚（刷坏救命的三个文件；路径变动必须同步 FLASHING.md）----
ANCHOR_TB2="$NURA_WORK/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/t-b2-m2381Pkg-RELEASE-d4928661.img"
ANCHOR_TB2_SHA="d4928661"
ANCHOR_ESP_V4D="$NURA_WORK/meizu20/meizu20-m1/m1-work/arch-a/esp-recovery-v4d.img"
ANCHOR_ESP_V4D_SHA="3b106f07"
ANCHOR_MU_R57="$NURA_WORK/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/mu-r57-4640ebb5.img"
ANCHOR_MU_R57_SHA="4640ebb5"

# ---- 设备通道 ----
DEV_IP="172.16.42.1"
DEV_USER="user"
DEV_PASS="1234"

nura_die() { echo "FATAL: $*" >&2; exit 1; }
nura_require() { [ -e "$1" ] || nura_die "钉子失效：$1 不存在（改 config.sh）"; }
nura_precheck() {
	nura_require "$PIN_LINUX_DIR"; nura_require "$PIN_MU_DIR"
	nura_require "$PIN_PMAPORTS";  nura_require "$PIN_PMB_WRAPPER"
	nura_require "$PIN_TOOLS"
}
