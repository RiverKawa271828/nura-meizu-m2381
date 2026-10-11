#!/usr/bin/env bash
# nura-meizu-m2381 — 全局钉子（唯一定位点）
#
# 东西搬家只改这里。Phase-2（公开发布）时把 PIN_*_GIT 换成公共 URL，
# setup.sh 即可在任何机器复刻本布局；本机阶段 PIN_*_GIT 留空 = 用本地路径。
#
# 本文件只被 source，不直接执行。

# ---- 工作区 ----
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 他机复刻只改这一个根（export NURA_WORK=/path 或改下行默认）；默认 = ~/work
NURA_WORK="${NURA_WORK:-$HOME/work}"

# ---- 源码树（本地现役；公共 clone URL 见下方 PIN_*_GIT）----
PIN_LINUX_DIR="${NURA_LINUX_DIR:-$NURA_WORK/linux-mobile-ports}"          # fork 内核树
PIN_LINUX_BRANCH="meizu20-t4b"
PIN_MU_DIR="${NURA_MU_DIR:-$NURA_WORK/meizu20/mu-uefi/Mu-Silicium-new}"   # Mu 树
PIN_MU_BRANCH="meizu20-mars-port"
PIN_PMAPORTS="${NURA_PMAPORTS_DIR:-$NURA_WORK/pmos_linux/pmos/pmaports}"
PIN_PMAPORTS_BRANCH="phoenix"
PIN_PMB_WRAPPER="${NURA_PMB_WRAPPER:-$NURA_ROOT/script/pmbootstrap-meizu.sh}"  # 已收编本仓
PMB_CHECKOUT="${NURA_PMB_CHECKOUT:-$NURA_WORK/pmos_linux/pmos/pmbootstrap}"    # 官方 pmbootstrap（setup.sh --clone 补齐）
PMB_WORK="${NURA_PMB_WORK:-$NURA_WORK/pmos_linux/pmos/.pmbootstrap}"           # work dir（本机与 K30 wrapper 共享，须串行）
PIN_TOOLS="${NURA_TOOLS_DIR:-$NURA_ROOT/tools}"                                # make-esp-recovery.sh / devsh 三件（已收编本仓）

# ---- 公共仓 URL（Phase-2；setup.sh --clone 按此摆位，空 = 不启用）----
PIN_LINUX_GIT="https://github.com/RiverKawa271828/linux-mobile-ports"        # fork torvalds/linux → 推分支 meizu20-t4b（基点 58785836 = 主线 7.3 merge window，只传 79 个增量 commit）
PIN_MU_GIT="https://github.com/RiverKawa271828/Mu-Silicium"                  # fork Project-Silicium/Mu-Silicium → 推分支 meizu20-mars-port
PIN_MU_BINARIES_GIT="https://github.com/RiverKawa271828/Device-Binaries"     # 已建 fork；main 已强推至钉住的 036ba9f7（= silime「mars: Initial support」，10-07 推送窗口）
PIN_PMAPORTS_GIT="https://github.com/RiverKawa271828/pmaports"               # 已建独立仓；phoenix 整条已推（10-07 推送窗口；pmOS 官方在 GitLab，GitHub 无镜像 fork 可用）

# ---- Release（Phase-2；setup.sh --fetch-release 按此拉现役件/锚三件）----
PIN_RELEASE_BASE="https://github.com/RiverKawa271828/nura-meizu-m2381/releases/download/r80"  # 发布面（2026-10-11 r80 上线；r72 半截流教训在册：大件上传验收 = 本地 gzip -t + 资产字节数逐件对拍，完整下载回读闭环可选）

# ---- 包身份 ----
PKGVER="7.3.0_rc6"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="${NURA_APK_DIR:-$NURA_WORK/pmos_linux/pmos/.pmbootstrap/packages/edge/aarch64}"

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="81"      # r81 = SQUASHFS_ZSTD/XZ=y + RTC hctosys/systohc→rtc1（config-only 候选轮：steamos 线点名 FEX squashfs 腿 + 其 RTC 情报命中 rtc0 废件；tip 不动 349e8aa5579b，**待彼线点火回归**）；r80 = Release 轮（10-11 上线，async flip r79 + UHID=m r80）
REL_DEVICE_PKGREL="60"     # r60 = modules-load.d 补 uhid 自载（BLE HID 无 open-time autoload）；r59 = uinput 用户态胶水（60-meizu20-uinput.rules uaccess+static_node / modules-load.d）；r58 = s2idle×systemd 看门狗修复（udevd/logind WatchdogSec=0 + 14 内部服务放宽 30min + journald sync 30s）
REL_FW_PKGREL="3"
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r69-97cdea20.img"
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v62.img.gz"  # v62 = r81 内核（裸 sha b41b8888）；v61=r80 裸 cb7f1e5a（Release 轮）；v60=r79 裸 0ccfcf72
REL_KERNEL_VER="#82"       # 下次上机 uname 期望（r81/rc6 内核 + #N=pkgrel+1 定律）；回滚配对 = r80/v61/#81/r59

# ---- 回滚锚（仅私有工作区本地保留；2026-10-11 起不随 Release 上传——用户拍板：
#      现役件可信，刷坏重刷现役三件即可；rollback.sh 自用）----
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
