#!/bin/sh
# cell-keeper.sh — 蜂窝注册面自愈守卫（rf_keeper 落地，2026-11-19 双卡轮；
# r66 = 2026-11-20 多档轮顺手修三缺口：①在役槽参数化[/var/lib/cell-keeper/active-slot
# 由 cell-switch.sh 写；缺省 1 = 一百零四原语义] ②boot 归位 QMI 等待 60s→300s
# [modem 慢启 boot 双静默跳过实锤] ③轮询环双 active 守卫[slot-1 供给型 uim-selection
# 每次 boot 唤醒非在役卡 → MM hot-swap 漂移循环，轮询环兜底单卡化]）
# 逻辑（101/103/一百零四 经验固化）：
#   每 45s 检查一轮：
#   a) DMS mode = offline/shutting-down 死锁态 → 舞步（low-power→8s→online）
#   b) Primary GW session 没了 → re-provision 在役槽 → 舞步
#   c) 非 in 役槽 active+present → power off（双 active 守卫）
#   d) searching = 正常搜网不干预；registered = 稳态不干预
# 取证落 /var/log/cell-keeper.log（环形 500 行截断）。
Q="qmicli -d qrtr://0"
AID=A0000000871002FF86FFFF89FFFFFFFF
LOG=/var/log/cell-keeper.log
MAX=500
STATE=/var/lib/cell-keeper/active-slot

log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; [ "$(wc -l < $LOG)" -gt "$MAX" ] && tail -n $MAX "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"; }

dance() {
  $Q --dms-set-operating-mode=low-power >/dev/null 2>&1
  sleep 8
  $Q --dms-set-operating-mode=online >/dev/null 2>&1
}

# 等 QMI 活（未解封 boot 时 mpss 不在 = NAS 查询超时 = 静默跳过）
qmi_alive() { timeout 12 $Q --dms-get-operating-mode 2>/dev/null | grep -q "Mode:"; }

# 在役槽参数化：cell-switch.sh 每次 switch 写状态文件；无文件 = 槽 1 主卡（原语义）
ACTIVE=$(cat "$STATE" 2>/dev/null)
case "$ACTIVE" in 1|2) ;; *) ACTIVE=1 ;; esac
OTHER=$((3 - ACTIVE))

# 槽状态解析：qmicli --uim-get-slot-status 按槽分块
slot_active() { # slot_active <N> -> 0 = 该槽卡在位且 active
  timeout 12 $Q --uim-get-slot-status 2>/dev/null \
    | awk '/^  Physical slot /{cur=$3+0} cur=='"$1"' && /Card status: present/{p=1} cur=='"$1"' && /Slot status: active/{a=1} END{exit !(p && a)}'
}

# r69/r101: modem start 延时化——内核期 autostart 撞 IPA init 握手死窗（modem
# 侧 ~14s 无 A7 init 即断言 crash、AP 侧 -110 永不重试 → rmnet_ipa0 永不建，
# 两 boot 实证；内核 pas 驱动 DT qcom,autostart-off 关 4080000 自启）。此处一条
# start = 官方 autostart 语义的时序等价物（等系统稳定 ~30s = 103 实证好窗），
# 无 blacklist/override/bind 链。rmtfs -s 已在位会等 rprocfd。
sleep 30
for r in /sys/class/remoteproc/remoteproc*/; do
  [ "$(cat "$r/name" 2>/dev/null)" = modem ] && echo start > "$r/state" 2>/dev/null && log "mpss started (delayed, autostart-off)"
done

# boot 首步：非在役槽归位 power-off（运行态非持久，reboot 后双 active 会触发 MM
# 双卡漂移循环；QMI 等待 60s→300s——一百零八~一零九 boot 实锤 modem 慢启[IPA fatal
# 恢复窗]可达 4min+，60s 双轮静默跳过 = slot2 时代双 active 每现）
for i in $(seq 1 60); do qmi_alive && break; sleep 5; done
if qmicli -d qrtr://0 --uim-sim-power-off=$OTHER >/dev/null 2>&1; then
  log "slot$OTHER power-off (boot reposition, active=$ACTIVE)"
fi

while :; do
  if qmi_alive; then
    # 双 active 守卫：uim-selection（官方形态）每次 boot provision slot1 会唤醒
    # 非在役卡；slot-2 主卡时代每 boot 双 active → MM disable 循环。轮询环兜底单卡化。
    if slot_active $OTHER; then
      log "dual-active guard: slot$OTHER active -> power off"
      $Q --uim-sim-power-off=$OTHER >/dev/null 2>&1
      sleep 3
    fi
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
          log "REG=$REG session lost -> re-provision slot$ACTIVE + dance"
          timeout 12 $Q --uim-change-provisioning-session="session-type=primary-gw-provisioning,activate=yes,slot=$ACTIVE,aid=$AID" >/dev/null 2>&1
          dance; sleep 20 ;;
        *)
          log "REG=$REG (session ok) -> dance once"
          dance; sleep 20 ;;
      esac
    fi
    # r75（2026-11-22 数据面自动化轮）：数据面看门改 qmapmux0.0 形态——MM 拨号
    # （mm-dial）取代手工 DPM 链（d1_dataup 判负退役），数据面接口 = MM 自建
    # qmapmux0.0@rmnet_ipa0。mm-dial PASS 铺的默认路由（metric 700 = WiFi 优先
    # 策略）若中途数据面静默死（TX 出 RX 0 无 fatal，一百二十 boot 实证），死路
    # 由残留 = 黑洞；WiFi 在时它只是备胎无害，WiFi 掉时却独占默认路由吃掉全部
    # 流量。路由在位时每轮 -I 硬判一发，两连败 = 撤路由（复活 = systemctl
    # restart mm-dial；撤路由本身不碰 MM 连接/注册面）。
    if ip route show 2>/dev/null | grep -q "default dev qmapmux0.0"; then
      if ! ping -c 1 -W 5 -I qmapmux0.0 223.5.5.5 >/dev/null 2>&1; then
        sleep 10
        if ! ping -c 1 -W 5 -I qmapmux0.0 223.5.5.5 >/dev/null 2>&1; then
          ip route del default dev qmapmux0.0 metric 700 2>/dev/null
          log "data face dead (2x ping fail) -> qmapmux0.0 default route withdrawn (revive: systemctl restart mm-dial)"
        fi
      fi
    fi
  fi
  sleep 45
done
