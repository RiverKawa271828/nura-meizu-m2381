#!/bin/sh
# d1_dataup.sh — 蜂窝数据面一键判生死（2026-11-19 C 轮配方固化；一百零三）
# 前提：解封 + provision + DMS 舞步已完成（registered 态）、MM 已 mask、qrtr-lookup 有 WDS/DPM
# 配方 = DPM open → d1_bindmux（dial）→ rmnet0(QMAP mux_id 1) → rmnet_ipa0 bounce（重铺
#        RX buffer）→ 默认路由 → ping 判据
# 判词（11-19 实证）：
#   - AP_MODEM_TX 端点 .qmap=true（主线 ipa_data-v5.5.c）：裸 IP 包撞 xmit 静默丢弃分支
#     （TX dropped 涨 / RX 0 / 零 error）——rmnet0 上层件是必需品非可选；
#   - SSR 后驱动只发 modem running 事件不重配通道：RX 无 buffer 可回 → rmnet_ipa0
#     down/up 一发重铺（PDP 不受影响）；
#   - dial 非 idempotent：重跑 start 可能拿新地址（也可能回现值，11-19 两见）——脚本
#     addr replace 兜住；dial/DPM reopen 都会拉长回程落定窗（实测 25s 不够），判据用
#     bounce+ping 收敛环硬兜（≤3 轮，全部实测态均收敛）；
#   - DPM open 重发可报错 = 已开，忽略。
# 用法：d1_dataup.sh [判据目标 IP]（默认 223.5.5.5）

TGT="${1:-223.5.5.5}"

echo "== [1/5] DPM open port"
qmicli -d qrtr://0 --dpm-open-port="hw-data-ep-type=embedded,hw-data-ep-iface-number=1,hw-data-rx-id=2,hw-data-tx-id=24" 2>&1 | tail -1

echo "== [2/5] WDS dial (bind mux -> bind sub -> start network)"
OUT=$(python3 /usr/lib/meizu20/d1_bindmux.py 2>&1)
echo "$OUT" | tail -2
ADDR=$(echo "$OUT" | sed -n 's/.*addr=\([0-9.]*\) .*/\1/p')
[ -z "$ADDR" ] && ADDR=$(cat /root/.d1-addr 2>/dev/null)
[ -z "$ADDR" ] && { echo "FAIL: 无地址（dial 未通，查 registered 态）"; exit 1; }
sleep 25  # ★modem 上下文落定窗：dial 后 ~25s 内 bounce 无效（11-19 三连实测钉死：5s 败/裸 bounce 通/25s 通）

echo "== [3/5] rmnet0 (QMAP mux_id 1)"
ip link show rmnet0 >/dev/null 2>&1 || ip link add link rmnet_ipa0 name rmnet0 type rmnet mux_id 1
# r70: 先 flush 再 replace——dial 回现值/旧地址并存时 -I rmnet0 的源选择会踩
# modem 已不路由的旧 context = 硬判假阴性（11-20 两 boot 实证双地址并存）。
ip addr flush dev rmnet0 2>/dev/null
ip addr replace "$ADDR/32" dev rmnet0
ip link set rmnet0 up

echo "== [4/5] bounce + 判据收敛环"
# ★实测（11-19 三连）：dial/DPM reopen 后回程落定窗不定（25s 不够、裸 bounce 后
# 一发即活）——不猜 T，收敛环硬兜：bounce → ping，败则 sleep 20 再来，≤3 轮。
ip route replace default dev rmnet0 metric 50
sysctl -w net.ipv6.conf.rmnet_ipa0.disable_ipv6=1 >/dev/null 2>&1
bounce_ping() {
	ip link set rmnet0 down
	ip link set rmnet_ipa0 down
	sleep 2
	ip link set rmnet_ipa0 up
	ip link set rmnet0 up
	# r70: 接口 down 时内核顺带删掉挂在它上面的默认路由，up 后必须重铺
	# （11-20 实证：bounce 后 rmnet0 默认路由消失 = 数据面塌点之一）。
	ip route replace default dev rmnet0 metric 50 2>/dev/null
	sleep 3
	# r70: 判据硬判 = -I rmnet0——不带 -I 会走 wlan0/usb0 默认路由恒通
	# （WiFi 共存语境 = 判据假绿，11-20 两 boot 实锤）。
	ping -c 3 -W 3 -I rmnet0 "$TGT" 2>/dev/null | grep -q "0% packet loss"
}
i=1
while [ "$i" -le 3 ]; do
	if bounce_ping; then
		echo "PASS（第 $i 轮 bounce 判活）"
		exit 0
	fi
	echo "  第 $i 轮未通，等落定窗后重试…"
	i=$((i + 1))
	[ "$i" -le 3 ] && sleep 20
done
echo "FAIL: 3 轮未通（查 registered / TX-RX 计数 / 新崩）"
# 死路不抢默认路由（2026-11-21 网络诊断轮）：dial 层成功≠IPA 数据面通，
# TD-11 死窗语境下 metric 50 的 rmnet0 default 压过 wlan0(m600) 吃掉全部
# 流量（WiFi 有网也"没网"）→ FAIL 时删掉，让 WiFi 接管日用；PASS 则保留。
ip route del default dev rmnet0 metric 50 2>/dev/null
exit 1
