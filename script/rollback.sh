#!/usr/bin/env bash
# rollback.sh — 30 秒回滚（救砖配方，非交互三连）
#
# 用法: rollback.sh --i-am-present
#
# 配方出处: AGENTS「30 秒回滚」。链 = ABL→boot_b t-b2 UEFI→recovery_a v4d
# ESP→内核→userdata。回滚锚 sha 见 config.sh（变动必须同步）。
set -euo pipefail
. "$(dirname "$0")/../config.sh"

[ "${1:-}" = "--i-am-present" ] || nura_die "回滚也动分区：加 --i-am-present"
for f in "$ANCHOR_TB2" "$ANCHOR_ESP_V4D"; do [ -e "$f" ] || nura_die "锚缺失: $f"; done
fastboot devices | grep -q . || nura_die "fastboot 无设备（黑屏死机 = 长按 电源+音量减；EDL/9008 双通道兜底）"

echo "======== 回滚计划 ========"
echo "  boot_b     ← $ANCHOR_TB2 (${ANCHOR_TB2_SHA})"
echo "  recovery_a ← $ANCHOR_ESP_V4D (${ANCHOR_ESP_V4D_SHA})"
echo "  set_active b + reboot"
echo "=========================="
read -r -p "继续？(yes/no) " ANS
[ "$ANS" = "yes" ] || nura_die "用户取消"

fastboot flash boot_b "$ANCHOR_TB2"
fastboot flash recovery_a "$ANCHOR_ESP_V4D"
fastboot set_active b
fastboot reboot
echo "[✓] 已回滚。若循环进 fastboot：fastboot flash misc misc-zero.img（清 bootonce）"
echo "    （misc-zero.img 自备/见 meizu20-m1/tools；ABL 重试计数每 ~7 次开机耗尽会落 fastboot）"
