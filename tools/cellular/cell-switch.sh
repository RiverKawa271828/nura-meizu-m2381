#!/bin/sh
# cell-switch.sh — 双卡 active 槽切换（cell 1|2），双卡轮 2026-11-19
# 用法: cell-switch.sh <1|2>
# 动作: 另一槽 power off → 目标槽 power on → provision 目标槽 → DMS 舞步 → MM 重扫
# EFS 快照四份在案（20261119-sms-round 等）；slot power off/on = UIM 层动作，零 EFS 写入。
Q="qmicli -d qrtr://0"
AID=A0000000871002FF86FFFF89FFFFFFFF   # 两卡同 AID（UICC 模板），区分靠 slot 参数
LOG=/var/log/cell-keeper.log

log() { echo "$(date '+%m-%d %H:%M:%S') [switch] $*" >> "$LOG"; }

[ -z "$1" ] && { echo "usage: cell-switch.sh <1|2>"; exit 1; }
T="$1"
[ "$T" = "1" ] && O=2 || { [ "$T" = "2" ] && O=1 || { echo "slot must be 1 or 2"; exit 1; }; }

echo "== switch to slot $T (power off slot $O) =="
$Q --uim-sim-power-off=$O >/dev/null 2>&1
sleep 3
$Q --uim-sim-power-on=$T >/dev/null 2>&1
sleep 3

echo "== provision slot $T =="
$Q --uim-change-provisioning-session="session-type=primary-gw-provisioning,activate=yes,slot=$T,aid=$AID" 2>&1 | tail -1
sleep 2

# r66: 写在役槽状态文件（cell-keeper 的 boot 归位/双 active 守卫/恢复路径都按它定向）
mkdir -p /var/lib/cell-keeper
echo "$T" > /var/lib/cell-keeper/active-slot

echo "== dance =="
$Q --dms-set-operating-mode=low-power >/dev/null 2>&1
sleep 8
$Q --dms-set-operating-mode=online >/dev/null 2>&1
echo "waiting registration (30s)..."
sleep 30

REG=$($Q --nas-get-serving-system 2>/dev/null | grep "Registration state" -A1 | grep -o "'[a-z-]*'" | head -1 | tr -d "'")
PLMN=$($Q --nas-get-serving-system 2>/dev/null | grep -E "MCC|MNC" | head -2 | grep -o "'[0-9]*'" | tr -d "'" | tr -d '\n')
echo "== serving: $REG PLMN=$PLMN =="
log "switch->slot$T: $REG PLMN=$PLMN"

echo "== MM rescan =="
systemctl restart ModemManager
echo "done. (MM rescan ~15s; d1_dataup.sh 数据面切换后需重跑)"
