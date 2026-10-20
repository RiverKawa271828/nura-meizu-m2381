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
PIN_RELEASE_BASE="https://github.com/RiverKawa271828/nura-meizu-m2381/releases/download/r87"  # 发布面（2026-10-14 r87 上线 = waydroid 预装 + phosh 商店 flatpak + 摘 discover，CI 云构建 #22 产物；r84 = 上一个 phosh 发布面，r80 = plasma 末版存档；r72 半截流教训在册：大件上传验收 = 本地 gzip -t + 资产字节数逐件对拍，完整下载回读闭环可选）

# ---- 包身份 ----
PKGVER="7.3.0_rc6"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="${NURA_APK_DIR:-$PMB_WORK/packages/edge/aarch64}"   # 随 PMB_WORK 推导（CI 重定向 /mnt 时自动跟随）

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="91"      # r91 = 7.3 stable rebase 正式轮（10-21：99 提交零冲突重放到 v7.3 `091b0638`，apk 内核 release=7.3.0[模块目录 /usr/lib/modules/7.3.0/]；printk 复核=上游未修 no_console_suspend 留 + ath12k 0012 三件 carry 全留；**待上机 #92**）；r90 = 首枪 stock-content 旋钮（A/B 判负，debug 设施默认 0 随车）；r87 = 发布面（Release r87 Latest 不变）；r86 = waydroid 双族策略路由（#87 验过）
REL_DEVICE_PKGREL="62"     # r62 = 摘 discover-backend-apk（10-14 用户拍板「phosh 移除 discover」——KDE 商店+flatpak/fwupd 后端=plasma-mobile 伴生件，新装 rootfs 不再带入，已装设备 apk del 清理）；r61 = waydroid 固化：depends +waydroid/waydroid-pyc/waydroid-systemd/gbinder-python/libgbinder 五件 + 52_waydroid.nft（放行+MSS clamp）入包 /etc/nftables.d/ + preset disable waydroid-container；r60 = modules-load.d 补 uhid；r59 = uinput 用户态胶水；r58 = s2idle×systemd 看门狗修复
REL_FW_PKGREL="3"
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r69-97cdea20.img"
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v71.img.gz"  # v71 = r91 内核（裸 0a102220 / gz 6fe7811a；10-21 本地构建，verify[4] 手工对拍 v71↔r91 vmlinuz 4aad92b3 逐字节同源；**待上机**）；v70 = r90（裸 dca69c1d / gz 374c4595，#91 在机验过）；v68 = r87 发布面（裸 e7a044a8 / gz 086a4eef）；v67 = r86（裸 2ad63003，#87 验过）
REL_KERNEL_VER="#92"       # r91 期望（#N=pkgrel+1 定律；**待设备日实机确认**；在机现值 = #91/r90/v70）

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
