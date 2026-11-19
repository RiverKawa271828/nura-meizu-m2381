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
PIN_RELEASE_BASE="https://github.com/RiverKawa271828/nura-meizu-m2381/releases/download/r91"  # 发布面（2026-10-21 r91 上线 Latest = 7.3 stable rebase 首发 + device r63 传感器依赖闭合，CI run 39511226412 产物；r87 = 上一个 phosh+waydroid 发布面，r84 再前，r80 = plasma 末版存档；r72 半截流教训在册：大件上传验收 = 本地 gzip -t + 资产字节数逐件对拍，完整下载回读闭环可选[本轮用户令跳过全量下载，工作流内建字节数对拍+gzip -t 已跑]）

# ---- 包身份 ----
PKGVER="7.3.0_rc6"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="${NURA_APK_DIR:-$PMB_WORK/packages/edge/aarch64}"   # 随 PMB_WORK 推导（CI 重定向 /mnt 时自动跟随）

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="101"     # r101 = modem autostart-off 轮（11-20，fork 12dcde3033c8：pas 驱动 DT 开关 qcom,autostart-off 一行 + DTS 4080000 关自启 = IPA init 握手死窗修复[r69 上机两 boot 实证：内核期 modem 早启 → modem 侧 IPA assert crash ×3 + AP 侧 -110 永不重试 → rmnet_ipa0 永不建]；r100 = 多档刷新率轮；r99 = 相机轮·第一段；r95 = bloff 摘除轮；r91 = 7.3 stable rebase 正式轮）
REL_DEVICE_PKGREL="70"     # r70 = 数据面判据诚实化 + keeper 延时 start（11-20：d1_dataup 三处[;-I rmnet0 硬判/bounce 后重铺默认路由/addr flush 防双地址] + keeper start 延时化 ~boot+35s[复刻 103 实证好窗]）；r69 = 开机顺序官方化轮（摘 PAS/MSS blacklist + meizu-pas 退役 + keeper 解封段撤 + dataup ExecStartPre 移入本体 + tmpfiles 三件[TFTP 根/retire-pas/tempjson] + touch-load +98c000）；r68 = 开机提速轮；r67 = 摘 uim-selection；r66 = keeper 参数化
REL_FW_PKGREL="4"          # r4 = 11-19 蜂窝复燃轮上机（+modem_pr mcfg/so 158 件，pmaports f2885ef；发布面 tarball 仍 r3/29c1ee88）
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r101-a6fb2158.img"     # mu-r101 = 11-20 modem autostart-off 轮（DTS 4080000 qcom,autostart-off，fork 12dcde3033c8 同源 r101 apk）；mu-r97 = 相机轮件留档（11-20）
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v79.img.gz"  # v79 = modem autostart-off 轮 ESP（r101 vmlinuz，11-20：裸 11f67de8 / gz a442e509）；v78 = 多档轮件留档（r100 vmlinuz，裸 b57f8605）；v77 号位留白未落盘；构建坑：build-esp 必须等 build-kernel 的 systemd-run 单元真完再跑（另记：沙箱后台发射 systemd-run 有提交通道竞态秒死坑，须前台发射+落稳确认）
REL_KERNEL_VER="#102"      # 期望（r101 内核 = pkgrel+1；上机实测后核对）

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
