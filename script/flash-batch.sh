#!/usr/bin/env bash
# flash-batch.sh — 一车刷（boot_b + recovery_a），用户在场专用
#
# 用法: flash-batch.sh --i-am-present [--boot-b IMG] [--recovery-a IMG]
#
# 红线:
#   - 必须 --i-am-present（刷机 = 用户在场，禁令不改）
#   - 只碰 boot_b / recovery_a；绝不碰 xbl/dtbo_b/super/modemst/persist
#   - 刷写时长不算证据：系统起来后必须跑 script/readback.sh 对 sha
set -euo pipefail
. "$(dirname "$0")/../config.sh"

PRESENT=0; BOOTIMG="$REL_MU_IMG"; ESPIMG="$REL_ESP_IMG"
while [ $# -gt 0 ]; do
	case "$1" in
		--i-am-present) PRESENT=1 ;;
		--boot-b) shift; BOOTIMG="$1" ;;
		--recovery-a) shift; ESPIMG="$1" ;;
		*) echo "unknown arg: $1"; exit 2 ;;
	esac
	shift
done

[ "$PRESENT" = 1 ] || nura_die "刷机需用户在场：加 --i-am-present（AGENTS 禁令）"
[ -e "$BOOTIMG" ] || nura_die "boot_b 镜像不存在: $BOOTIMG"
[ -e "$ESPIMG" ]  || nura_die "recovery_a 镜像不存在: $ESPIMG"
fastboot devices | grep -q . || nura_die "fastboot 无设备（软进 = 机上 systemctl reboot --reboot-argument=bootloader；硬进 = 电源+音量减，18d1:d00d）"

BOOT_SHA=$(sha256sum "$BOOTIMG" | cut -d' ' -f1)
ESP_SHA=$(sha256sum "$ESPIMG" | cut -d' ' -f1)
echo "======== 刷写计划 ========"
echo "  boot_b     ← $BOOTIMG  (${BOOT_SHA:0:8})"
echo "  recovery_a ← $ESPIMG   (${ESP_SHA:0:8})"
echo "  apk 双包   ← 系统起来后装（见末尾提示）"
echo "=========================="
read -r -p "继续？(yes/no) " ANS
[ "$ANS" = "yes" ] || nura_die "用户取消"

echo "[1/2] flash boot_b"
fastboot flash boot_b "$BOOTIMG"
echo "[2/2] flash recovery_a"
fastboot flash recovery_a "$ESPIMG"

PKGREL=$(grep -m1 '^pkgrel=' "$PIN_PMAPORTS/device/downstream/$PKG_LINUX/APKBUILD" | cut -d= -f2)
cat <<EOF

[✓] 刷写完成。接下来（详见 docs/FLASHING.md §3）：
  1) fastboot reboot
  2) 系统起来后（NCM/WiFi 通道）装 apk 双包：
     apk add --allow-untrusted ./linux-…-r${PKGREL}.apk ./device-…apk（主包+子包同装）
  3) script/readback.sh <boot_b 的 sha> <recovery_a 的 sha>   ← 设备侧 dd 读回对 sha
     （本机两个 sha: boot_b=${BOOT_SHA:0:8}… recovery_a=${ESP_SHA:0:8}…）
  4) FLASHING.md §5 首 boot 验收清单
  出事 → script/rollback.sh（30 秒回滚锚）
EOF
