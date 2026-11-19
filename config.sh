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
REL_LINUX_PKGREL="100"     # r100 = 多档刷新率轮（11-20 插队：面板 modes 表 +3 条 60/90/144 stock verbatim，fork ac949b2fd8ef；profile 机制半成品早已在位[0x91/0x2F 表+vrefresh 选档]，当年 r22g 回退[boot 竞态 2/2]解封 = D4-1+设备包排序已落地；r99 = 相机轮·第一段[一百零八]；r95 = bloff 摘除轮；r91 = 7.3 stable rebase 正式轮）
REL_DEVICE_PKGREL="67"     # r67 = 一百零九事故修复（11-20：摘 msm-modem-uim-selection 两件 depends 照官方单卡形态[FP5/FP6 实测零 uim-selection]；r66 无限重试 drop-in 是 boot 死锁钥匙已撤；keeper slot 参数化+双 active 守卫；sensorspd 冲突件 mask）；r66 = keeper/switch 状态文件+双 active 守卫+sensor mask+boot 竞态三缺口修（其一引发事故）；r65 = 蜂窝链腿包化；r64 = 蜂窝四件包化；r63 = depends +iio-sensor-proxy（10-21）
REL_FW_PKGREL="4"          # r4 = 11-19 蜂窝复燃轮上机（+modem_pr mcfg/so 158 件，pmaports f2885ef；发布面 tarball 仍 r3/29c1ee88）
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r97-2fa98a12.img"      # mu-r97 = 11-20 相机轮 boot_b 腿在机（dtb 同源 7f9737f1 = r97/r98/r99 apk 共同 dtb [DTS 自 r97 后零改]；Mu 树 commit dc70f810）；mu-r91 = 11-19 前役件留档
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v78.img.gz"  # v78 = 多档刷新率轮 ESP（r100 vmlinuz，11-20：裸 b57f8605 / gz ea1fbc97）；v76 = 相机轮件（r97 vmlinuz，裸 730fd782 / gz 22176505）；v77 号位留白未落盘（原排 r99 vmlinuz，被 r100 顺位吸收）；构建坑：build-esp 必须等 build-kernel 的 systemd-run 单元真完再跑（另记：沙箱后台发射 systemd-run 有提交通道竞态秒死坑，须前台发射+落稳确认）
REL_KERNEL_VER="#101"      # 期望（r100 内核 = pkgrel+1；上机实测后核对）

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
