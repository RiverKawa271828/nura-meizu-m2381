#!/bin/sh
# mm-dial.sh — 蜂窝数据面自动化（MM 拨号形态 = 一百二十·终验正解，r75 固化）。
# 手工 DPM+WDS 链（d1_dataup/d1_bindmux）判负退役：dial 通但 modem 侧 IPA 通道
# 语义缺，bounce 一发 RX 秒死两 boot 复现（一百二十·终验①）。
# 配方 = 一百二十·终验全通链：MM failed 死锁 -> restart 重扫 -> simple-connect
#   apn=cbnet -> MM 自建 qmapmux0.0@rmnet_ipa0 -> bearer 活体取 IP/prefix/gw/DNS
#   -> 铺 addr/route（metric 700 = WiFi 优先策略）-> -I qmapmux0.0 硬判。
# 判据律：dial 硬败不走缓存——bearer 配置只从 MM 活体取（MM 形态无缓存地址可走），
#   无卡/未注册/判活 3 轮败 = FAIL + 撤默认路由诚实退出（r74 死路由坑在案）。
# NM 不认 qmapmux0.0（unmanaged 名单 r75 起含 qmapmux*）→ addr/route/DNS 本脚本
#   自理；NM×qmapmux 集成挂候补不挡发布（排面 A）。
# DNS：resolvectl 给 qmapmux0.0 挂 bearer DNS + default-route false——WiFi 在
#   （NM default-route 链）= WiFi DNS 优先；WiFi 掉 = qmapmux 成唯一 DNS 链自动
#   兜底。resolvectl 缺席 = 跳过（judge 用 IP 不吃 DNS）。
LOG=/var/log/cell-keeper.log
TGT="${1:-223.5.5.5}"

log() { echo "$(date '+%m-%d %H:%M:%S') [mm-dial] $*" >> "$LOG"; }
mm() { timeout 15 mmcli -m any 2>/dev/null; }
mm_state() { mm | grep "state:" | tail -1 | grep -o "'[a-z-]*'" | tr -d "'"; }

wait_modem() { # wait_modem <轮数> -> 0 = MM 有 modem 对象（10s/轮）
	i=1
	while [ "$i" -le "$1" ]; do
		timeout 10 mmcli -L 2>/dev/null | grep -q "Modem/" && return 0
		sleep 10
		i=$((i + 1))
	done
	return 1
}

fail() { # fail <原因> — 撤默认路由诚实退出（死路不抢路由，2026-11-21 律）
	echo "FAIL: $*"
	log "FAIL $*"
	ip route del default dev qmapmux0.0 metric 700 2>/dev/null
	exit 1
}

# [1/6] 等 MM modem 对象（keeper 延时 start mpss[boot+30s 起] + MM 扫描窗）
wait_modem 18 || fail "MM 无 modem 对象（mpss 未起/MM 未扫到；查 keeper journal）"

# [2/6] failed 死锁 -> restart 重扫（一百二十配方；重启 MM 搅注册[104 在册]，
# 但 failed 态本就无注册可保，restart 只在此分支发生一次）
ST=$(mm_state)
if [ "$ST" = "failed" ]; then
	log "MM state=failed -> restart rescan"
	systemctl restart ModemManager
	wait_modem 12 || fail "MM restart 后仍无 modem 对象"
	ST=$(mm_state)
	[ "$ST" = "failed" ] && fail "MM failed（$(mm | grep 'failed reason' | sed 's/^ *| *//')）——查卡在位"
fi

# [3/6] simple-connect apn=cbnet（connected 复跑 = 跳过，幂等）
if [ "$ST" != "connected" ]; then
	echo "== simple-connect apn=cbnet =="
	OUT=$(timeout 90 mmcli -m any --simple-connect="apn=cbnet,ip-type=ipv4" 2>&1) ||
		fail "dial 拒（$OUT）"
fi

# [4/6] 等 MM 自建 qmapmux0.0@rmnet_ipa0（mux 子接口，终验实测秒级~分钟级）
i=1
while [ "$i" -le 12 ]; do
	ip link show qmapmux0.0 >/dev/null 2>&1 && break
	sleep 5
	i=$((i + 1))
done
ip link show qmapmux0.0 >/dev/null 2>&1 || fail "qmapmux0.0 未建（bearer 无 mux 面，查 MM bearer）"

# [5/6] bearer 活体取 IPv4 配置 + 铺 addr/route（metric 700）
BP=$(mm | grep -o "Bearer/[0-9]*" | head -1)
[ -n "$BP" ] || fail "modem 无 bearer（connect 未落）"
CONF=$(timeout 15 mmcli -m any -b "${BP##*/}" 2>/dev/null)
ADDR=$(echo "$CONF" | awk '/^  IPv4 /{s=1;next} /^  [A-Z]/{s=0} s && /address:/{print $NF}' | head -1)
PFX=$(echo "$CONF" | awk '/^  IPv4 /{s=1;next} /^  [A-Z]/{s=0} s && /prefix:/{print $NF}' | head -1)
GW=$(echo "$CONF" | awk '/^  IPv4 /{s=1;next} /^  [A-Z]/{s=0} s && /gateway:/{print $NF}' | head -1)
DNS=$(echo "$CONF" | awk '/^  IPv4 /{s=1;next} /^  [A-Z]/{s=0} s && /dns:/{sub(/.*dns: */,""); print}' | head -1)
[ -n "$ADDR" ] || fail "bearer 无 IPv4 地址（查 MM bearer 详情）"
[ -n "$PFX" ] || PFX=32
sysctl -w net.ipv6.conf.rmnet_ipa0.disable_ipv6=1 >/dev/null 2>&1
# r70 律：先 flush 再 replace——回现值/旧地址并存时 -I 源选择踩旧 context = 假阴性
ip addr flush dev qmapmux0.0 2>/dev/null
ip addr replace "$ADDR/$PFX" dev qmapmux0.0
ip link set qmapmux0.0 up
if [ -n "$GW" ]; then
	ip route replace default dev qmapmux0.0 via "$GW" metric 700
else
	ip route replace default dev qmapmux0.0 metric 700
fi
if [ -n "$DNS" ] && command -v resolvectl >/dev/null 2>&1; then
	resolvectl dns qmapmux0.0 $(echo "$DNS" | tr ',' ' ') >/dev/null 2>&1
	resolvectl default-route qmapmux0.0 false >/dev/null 2>&1
fi

# [6/6] 判活收敛环（-I qmapmux0.0 硬判——裸 ping 走 wlan0 = 假绿，r70 律）
i=1
while [ "$i" -le 3 ]; do
	if ping -c 3 -W 3 -I qmapmux0.0 "$TGT" 2>/dev/null | grep -q "0% packet loss"; then
		echo "PASS（第 $i 轮判活）addr=$ADDR/$PFX gw=${GW:-on-link} dns=${DNS:-none}"
		log "PASS addr=$ADDR/$PFX gw=${GW:-on-link} dns=${DNS:-none}"
		exit 0
	fi
	echo "  第 $i 轮未通，等落定窗后重试…"
	i=$((i + 1))
	[ "$i" -le 3 ] && sleep 15
done
fail "3 轮判活未通（查 registered / rmnet_ipa0 RX 计数 / IPA 域新崩）"
