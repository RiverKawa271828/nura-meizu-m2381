#!/bin/sh
# cell-keeper.sh — 蜂窝注册面自愈守卫（rf_keeper 落地，2026-11-19 双卡轮）
# 逻辑（101/103/一百零四 经验固化）：
#   每 45s 检查一轮：
#   a) DMS mode = offline/shutting-down 死锁态 → 舞步（low-power→8s→online）
#   b) Primary GW session 没了 → re-provision slot1 → 舞步
#   c) searching = 正常搜网不干预；registered = 稳态不干预
# 取证落 /var/log/cell-keeper.log（环形 500 行截断）。
Q="qmicli -d qrtr://0"
AID=A0000000871002FF86FFFF89FFFFFFFF
LOG=/var/log/cell-keeper.log
MAX=500

log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; [ "$(wc -l < $LOG)" -gt "$MAX" ] && tail -n $MAX "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"; }

dance() {
  $Q --dms-set-operating-mode=low-power >/dev/null 2>&1
  sleep 8
  $Q --dms-set-operating-mode=online >/dev/null 2>&1
}

# 等 QMI 活（未解封 boot 时 mpss 不在 = NAS 查询超时 = 静默跳过）
qmi_alive() { timeout 12 $Q --dms-get-operating-mode 2>/dev/null | grep -q "Mode:"; }

# boot 首步：槽 2 归位 power-off（运行态非持久，reboot 后双 active 会触发 MM 双卡
# 漂移循环；boot 后只做一次，不干预 cell-switch 的后续切换）
slot2_off_once() {
  for i in $(seq 1 12); do qmi_alive && break; sleep 5; done
  qmicli -d qrtr://0 --uim-sim-power-off=2 >/dev/null 2>&1 && log "slot2 power-off (boot reposition)" || true
}
slot2_off_once

while :; do
  if qmi_alive; then
    MODE=$(timeout 12 $Q --dms-get-operating-mode 2>/dev/null | grep -o "'[a-z-]*'" | tr -d "'")
    case "$MODE" in
      offline|shutting-down)
        log "MODE=$MODE -> dance"
        dance; sleep 20 ;;
    esac
    REG=$(timeout 12 $Q --nas-get-serving-system 2>/dev/null | grep -o "'[a-z-]*'" | head -1 | tr -d "'")
    if [ "$REG" != "registered" ]; then
      SESSION=$(timeout 12 $Q --uim-get-card-status 2>/dev/null | grep "Primary GW" -A1 | head -1)
      case "$SESSION" in
        *"doesn't exist"*)
          log "REG=$REG session lost -> re-provision + dance"
          timeout 12 $Q --uim-change-provisioning-session="session-type=primary-gw-provisioning,activate=yes,slot=1,aid=$AID" >/dev/null 2>&1
          dance; sleep 20 ;;
        *)
          log "REG=$REG (session ok) -> dance once"
          dance; sleep 20 ;;
      esac
    fi
  fi
  sleep 45
done
