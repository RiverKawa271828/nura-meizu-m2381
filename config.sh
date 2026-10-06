#!/usr/bin/env bash
# nura-meizu-m2381 — 全局钉子（唯一定位点）
#
# 东西搬家只改这里。Phase-2（公开发布）时把 PIN_*_GIT 换成公共 URL，
# setup.sh 即可在任何机器复刻本布局；本机阶段 PIN_*_GIT 留空 = 用本地路径。
#
# 本文件只被 source，不直接执行。

# ---- 工作区 ----
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- 源码树（本地现役；Phase-2 填公共 clone URL）----
PIN_LINUX_DIR="${NURA_LINUX_DIR:-~/work/linux-mobile-ports}"          # fork 内核树
PIN_LINUX_BRANCH="meizu20-t4b"
PIN_MU_DIR="${NURA_MU_DIR:-~/work/meizu20/mu-uefi/Mu-Silicium-new}"   # Mu 树
PIN_MU_BRANCH="meizu20-mars-port"
PIN_PMAPORTS="${NURA_PMAPORTS_DIR:-~/work/pmos_linux/pmos/pmaports}"
PIN_PMB_WRAPPER="${NURA_PMB_WRAPPER:-~/work/pmos_linux/pmos/pmbootstrap-meizu.sh}"
PIN_TOOLS="${NURA_TOOLS_DIR:-~/work/meizu20/meizu20-m1/tools}"        # make-esp-recovery.sh / devsh.py

PIN_LINUX_GIT=""   # Phase-2: https://github.com/<you>/linux-mobile-ports
PIN_MU_GIT=""      # Phase-2: https://github.com/<you>/Mu-Silicium (branch meizu20-mars-port)
PIN_PMAPORTS_GIT="" # Phase-2: https://github.com/<you>/pmaports (branch: m2381)

# ---- 包身份 ----
PKGVER="7.3.0_rc3"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="~/work/pmos_linux/pmos/.pmbootstrap/packages/edge/aarch64"

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="63"      # 已构建 apk 的 pkgrel（r63 构建后更新）
REL_DEVICE_PKGREL="40"
REL_FW_PKGREL="3"
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r62-9f1e8f8d.img"
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v45.img"
REL_KERNEL_VER="#64"       # 期望 uname = pkgrel+1（#N=pkgrel+1 定律）

# ---- 回滚锚（刷坏救命的三个文件；路径变动必须同步 FLASHING.md）----
ANCHOR_TB2="~/work/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/t-b2-m2381Pkg-RELEASE-d4928661.img"
ANCHOR_TB2_SHA="d4928661"
ANCHOR_ESP_V4D="~/work/meizu20/meizu20-m1/m1-work/arch-a/esp-recovery-v4d.img"
ANCHOR_ESP_V4D_SHA="3b106f07"
ANCHOR_MU_R57="~/work/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/mu-r57-4640ebb5.img"
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
