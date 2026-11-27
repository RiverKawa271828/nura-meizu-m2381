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
PIN_PMAPORTS_BRANCH="meizu20"   # 11-27 由 phoenix 改名（phoenix = K30 代号化石，K30 已退役；远端默认已切+旧名已删）
PIN_PMB_WRAPPER="${NURA_PMB_WRAPPER:-$NURA_ROOT/script/pmbootstrap-meizu.sh}"  # 已收编本仓
PMB_CHECKOUT="${NURA_PMB_CHECKOUT:-$NURA_WORK/pmos_linux/pmos/pmbootstrap}"    # 官方 pmbootstrap（setup.sh --clone 补齐；通用工具独立树）
PMB_WORK="${NURA_PMB_WORK:-$NURA_WORK/pmos_linux/pmos/.pmbootstrap}"           # work dir（K30 已退役 10-09；单设备线独占，防本机并发即可）
PIN_TOOLS="${NURA_TOOLS_DIR:-$NURA_ROOT/tools}"                                # make-esp-recovery.sh / devsh 三件（已收编本仓）

# ---- 公共仓 URL（Phase-2；setup.sh --clone 按此摆位，空 = 不启用）----
PIN_LINUX_GIT="https://github.com/RiverKawa271828/linux-mobile-ports"        # fork torvalds/linux → 推分支 meizu20-t4b（基点 58785836 = 主线 7.3 merge window，只传 79 个增量 commit）
PIN_MU_GIT="https://github.com/RiverKawa271828/Mu-Silicium"                  # fork Project-Silicium/Mu-Silicium → 推分支 meizu20-mars-port
PIN_MU_BINARIES_GIT="https://github.com/RiverKawa271828/Device-Binaries"     # 已建 fork；main 已强推至钉住的 036ba9f7（= silime「mars: Initial support」，10-07 推送窗口）
PIN_PMAPORTS_GIT="https://github.com/RiverKawa271828/pmaports"               # 已建独立仓（10-07 推送窗口；pmOS 官方在 GitLab，GitHub 无镜像 fork 可用）；分支 11-27 phoenix→meizu20

# ---- Release（Phase-2；setup.sh --fetch-release 按此拉现役件/锚三件）----
PIN_RELEASE_BASE="https://github.com/RiverKawa271828/nura-meizu-m2381/releases/download/r131"  # 发布面（2026-11-24 r131 上线 = 8 件制含**双 UI rootfs**（plasma-mobile b18a6be1 / phosh fcd6c662，11-22 用户拍板「两个都传，以后默认 plasma」）+ mu f51b3b09 + ESP v90 gz 037c8dfb（CI 同号异字节，在机本地件 = 3de0b018 裸 6efc31e0）+ fw r4 tarball 97d7b489 + linux r131 apk 7156e527 + upgrade-r131.zip 2ee9d1d7；CI run 45225314330；r91 = 上一个发布面（phosh 单 UI），r87/r84 再前，r80 = plasma 末版存档；r72 半截流教训在册：大件上传验收 = gzip -t + 资产字节数逐件对拍[CI 内建]，本地抽验 mu/ESP sha256 实过]）

# ---- 包身份 ----
PKGVER="7.3.0_rc6"
PKG_LINUX="linux-meizu-meizu20"
PKG_DEVICE="device-meizu-meizu20"
PKG_FIRMWARE="firmware-meizu-meizu20"
APK_DIR="${NURA_APK_DIR:-$PMB_WORK/packages/edge/aarch64}"   # 随 PMB_WORK 推导（CI 重定向 /mnt 时自动跟随）

# ---- 现役版本（随每个发布轮更新）----
REL_LINUX_PKGREL="138"     # r138 = 相机残面轮·二段（11-27）：DT rotation 90→270（眼判回执 = 90 修好侧转但上下颠倒，真安装角 270；fork df96b0421841）；r137 = 相机残面轮·一段留档（s5k3p9sx 暴露 V4L2_CID_CAMERA_ORIENTATION/_SENSOR_ROTATION 只读控制 + DT orientation/rotation 属性，fork 04d52720bf7f；libcamera 0.8.0 CameraSensorLegacy 无 fwnode 回退实证）；r136 = CMA 回滚轮留档
REL_DEVICE_PKGREL="89"     # r89 = 机上直装件收编（11-27 取证轮回程镜像前置：koko/gwenview/kalk/qrca + gnss-share 两件 + ofono + megapixels + i2c-tools/v4l-utils/strace + libcamera/libcamera-ipa 显式化；world 差分法，详见 APKBUILD r89 注记；注：MP 收尾轮原计划占 r89，顺延为 r90+）；r88 = +xwayland depends（11-27 图标挂死全案根修：pmOS plasma-minimal 不带 xwayland，kwin 握监听 fd + 会话发 DISPLAY=:0 无人 accept → 碰 DISPLAY 的应用 connect 永久挂死[图标启动静默死]）；r87 = dma_heap udev 规则（video 0660，用户会话 libcamera 全灭真凶）+ touch retrigger glob 化+exit 0（cci i2c 编号跨 boot 漂移）；r86 = TD-10 去债留档；r85 = 启动序修复留档
REL_FW_PKGREL="4"          # r4 = 11-19 蜂窝复燃轮上机（+modem_pr mcfg/so 158 件，pmaports f2885ef；已随 r131 发布）
REL_MU_IMG="$NURA_ROOT/artifacts/mu-r138-3f909a93.img"     # mu-r138 = 相机残面轮·二段（FdtBlob 自 r138 apk 同源 dbbbcfc6；rotation 270 定谳）；mu-r137-26462574 = 一段留档
REL_ESP_IMG="$NURA_ROOT/artifacts/esp-recovery-v96.img.gz"  # v96 = r138 ESP（gz 14402949B）；v95 = r137 件留档；⚠构建坑：build-esp 必须等 build-kernel 单元真完 + 定版三写在 verify 前
REL_KERNEL_VER="#139"      # 期望值（#N = pkgrel+1；上机后 uname -v 实测回填）

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
