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
REL_LINUX_PKGREL="126"     # r126 = 在机现役目标（11-22 一百一十九：S2 闪光灯轮 = pm8550 flash led 板级启用[stock dtbo_b 反编译真值，双通道单白 LED]；r125 = 118 GD2 收官态；r121 = settle-gap 实验件 + r122 = patch 挪位事故 void + r123/r124 = 探针基建；六连矩阵全负）
REL_DEVICE_PKGREL="72"     # r72 = pm8008i 细胞显式等待环 + hub_2(988000) bind（GD2 供电 blocker 修复；上机 #108 boot 双细胞即绑实证）；⚠touch-load 里 3P9 补绑仍硬编码 0-002d（cci 适配器改数后 = 2-002d，服务标 failed 但 udev 兜底已绑——r73 顺手件）；r71 = 相机开机即通轮
REL_FW_PKGREL="4"          # r4 = 11-19 蜂窝复燃轮上机（+modem_pr mcfg/so 158 件，pmaports f2885ef；发布面 tarball 仍 r3/29c1ee88）
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r126-0709afbe.img"     # mu-r126 = 11-22 S2 轮（FdtBlob 自 r126 apk 同源）；mu-r112 = 118 件留档；mu-r108 = r108 件留档
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v87.img.gz"  # v87 = r126 ESP（11-22：裸 b34f2965 / gz e7031780）；v85 = 118 件留档（裸 44f25038）；⚠v86 = 半写 apk 竞态废件已 void[build-esp 必须等 build-kernel 单元真完，坑⑤再实证]；构建坑：沙箱后台发射 systemd-run 提交通道竞态，前台发射+落稳确认
REL_KERNEL_VER="#127"      # 期望值（#N = pkgrel+1；上机后 uname -v 实测回填）

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
