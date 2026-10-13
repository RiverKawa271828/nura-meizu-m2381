#!/usr/bin/env bash
# nura-meizu-m2381 — 全局钉子（唯一定位点）
#
# 东西搬家只改这里。Phase-2（公开发布）时把 PIN_*_GIT 换成公共 URL，
# setup.sh 即可在任何机器复刻本布局；本机阶段 PIN_*_GIT 留空 = 用本地路径。
#
# 本文件只被 source，不直接执行。

# ---- 工作区 ----
# ★布局 v3（2026-10-13 用户拍板）：源码树全部保持独立仓库（多设备共享/通用基建），
#   零物理内聚——nura = 控制面（本钉子表 + script/ + docs/ + artifacts/），
#   他机/CI 复刻 = setup.sh --clone 按 PIN_*_GIT 远端重建（每树皆有公共远端）。
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 源树工作区根（export NURA_WORK=/path 或改下行默认）；默认 = ~/work。
# 沙箱注意：沙箱 HOME ≠ 宿主 HOME，沙箱里跑依赖源树钉子的脚本须 export
# NURA_WORK=<宿主工作区根>（systemd-run 重入单元内 HOME 正确，自愈）。
NURA_WORK="${NURA_WORK:-$HOME/work}"

# ---- 源码树（独立仓库，本地现役路径；公共 clone URL 见下方 PIN_*_GIT）----
PIN_LINUX_DIR="${NURA_LINUX_DIR:-$NURA_WORK/linux-mobile-ports}"          # fork 内核树（★独立多设备树，勿搬进本仓）
PIN_LINUX_BRANCH="meizu20-t4b"
PIN_MU_DIR="${NURA_MU_DIR:-$NURA_WORK/meizu20/mu-uefi/Mu-Silicium-new}"   # Mu 树（独立多设备树）
PIN_MU_BRANCH="meizu20-mars-port"
PIN_PMAPORTS="${NURA_PMAPORTS_DIR:-$NURA_WORK/pmos_linux/pmos/pmaports}"  # pmaports fork（K30+魅族多设备包源）
PIN_PMAPORTS_BRANCH="phoenix"
PIN_PMB_WRAPPER="${NURA_PMB_WRAPPER:-$NURA_ROOT/script/pmbootstrap-meizu.sh}"  # 已收编本仓
PMB_CHECKOUT="${NURA_PMB_CHECKOUT:-$NURA_WORK/pmos_linux/pmos/pmbootstrap}"    # 官方 pmbootstrap（setup.sh --clone 补齐；通用工具独立树）
PMB_WORK="${NURA_PMB_WORK:-$NURA_WORK/pmos_linux/pmos/.pmbootstrap}"           # work dir（K30 已退役 10-09；单设备线独占，防本机并发即可）
PIN_TOOLS="${NURA_TOOLS_DIR:-$NURA_ROOT/tools}"                                # make-esp-recovery.sh / devsh 三件（已收编本仓）

# ---- 公共仓 URL（Phase-2；setup.sh --clone 按此摆位，空 = 不启用）----
PIN_LINUX_GIT="https://github.com/RiverKawa271828/linux-mobile-ports"        # fork torvalds/linux → 推分支 meizu20-t4b（基点 58785836 = 主线 7.3 merge window，只传 79 个增量 commit）
PIN_MU_GIT="https://github.com/RiverKawa271828/Mu-Silicium"                  # fork Project-Silicium/Mu-Silicium → 推分支 meizu20-mars-port
PIN_MU_BINARIES_GIT="https://github.com/RiverKawa271828/Device-Binaries"     # 已建 fork；main 已强推至钉住的 036ba9f7（= silime「mars: Initial support」，10-07 推送窗口）
PIN_PMAPORTS_GIT="https://github.com/RiverKawa271828/pmaports"               # 已建独立仓；phoenix 整条已推（10-07 推送窗口；pmOS 官方在 GitLab，GitHub 无镜像 fork 可用）

# ---- Release（Phase-2；setup.sh --fetch-release 按此拉现役件/锚三件）----
PIN_RELEASE_BASE="https://github.com/RiverKawa271828/nura-meizu-m2381/releases/download/r84"  # 发布面（2026-10-12 r84 上线 = 首个 phosh 发布面，用户拍板「以后专注 phosh」；r80 = plasma 末版存档，r66 已删；r72 半截流教训在册：大件上传验收 = 本地 gzip -t + 资产字节数逐件对拍，完整下载回读闭环可选）

# ---- 包身份 ----
PKGVER="7.3.0_rc6"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="${NURA_APK_DIR:-$PMB_WORK/packages/edge/aarch64}"   # 随 PMB_WORK 推导（CI 重定向 /mnt 时自动跟随）

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="86"      # r86 = waydroid netd 策略路由补全（（八十八·乙）续：r85 开 v4 [IP_ADVANCED_ROUTER/IP_MULTIPLE_TABLES] 后 netd addInterface 走 v6 规则仍 EAFNOSUPPORT(97) 级联 → r86 补 IPV6_MULTIPLE_TABLES+SUBTREES；上机实测 = #87 一次点亮 failed 0 + waydroid rule×15/default 路由/gw·外网 0% loss/DNS 解析全通；config-only，fork tip 不动 140e5a8e308a；apk sha8 6e5dd1b8）；r85（apk c1d22119）= 同案 v4 半层，被 r86 取代；r84 = GPU/IFPC 收官（（八十六））回退件
REL_DEVICE_PKGREL="61"     # r61 = waydroid 固化（10-14 用户拍板「以后构建带上 waydroid 和其修复」）：depends +waydroid/waydroid-pyc/waydroid-systemd/gbinder-python/libgbinder 五件 + 52_waydroid.nft（放行+MSS clamp）入包 /etc/nftables.d/ + preset disable waydroid-container（按需启动对齐玩具轮）；镜像不入包（waydroid init 在线自拉 arm64_only 或离线恢复）；r60 = modules-load.d 补 uhid 自载（BLE HID 无 open-time autoload）；r59 = uinput 用户态胶水（60-meizu20-uinput.rules uaccess+static_node / modules-load.d）；r58 = s2idle×systemd 看门狗修复（udevd/logind WatchdogSec=0 + 14 内部服务放宽 30min + journald sync 30s）
REL_FW_PKGREL="3"
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r69-97cdea20.img"
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v67.img.gz"  # v67 = r86 内核（裸 2ad63003 / gz 444dec3f；10-13 本地构建+上机读回逐字对拍）；v66 = r85（裸 6ba496f5 / gz 327805aa）；v65 = r84 回退件（裸 463efc45 / gz 00d2d5f9）；v64 = r83 冻结留档未发货（裸 68b32cec / gz c617b083）；v63 = r82（彼侧重压版 gz 425ecd37，裸 533f40d0）；v62 = r81（裸 b41b8888，全量 b41b88889cadf6060e35…）；v61 = r80（裸 cb7f1e5a）；v60 = r79（裸 0ccfcf72）
REL_KERNEL_VER="#87"       # 在机实测 ✓（10-13 #87 一次点亮 failed 0；#N=pkgrel+1 定律）；回退配对 = r84/v65/#85（=Release r84）

# ---- 回滚锚 ----
# 已删（2026-10-13 用户拍板：T 时代旧版 bug 多，不再回滚）；rollback.sh 一并删除。
# 救砖路径唯一 = flash-batch.sh 重刷现役三件（boot_b mu-r69 + recovery_a v65 + r84 rootfs）。

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
