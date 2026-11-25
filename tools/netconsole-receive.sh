#!/usr/bin/env bash
# netconsole-receive.sh — 深睡线（TD-9 waker 识别）宿主侧 UDP 接收器
# 用法: netconsole-receive.sh [端口]   （默认 6666；输出落 /tmp/netconsole-<时间戳>.log）
#
# 设备侧武装（见 docs/SUSPEND-S2IDLE.md §TD9 预武装节）:
#   modprobe netconsole netconsole="@<设备wlan0 IP>/wlan0,6666@<宿主IP>/<宿主MAC>"
# 通道选 wlan0（LAN）——livelock 期 dwc3 掉总线 usb0 必死，WiFi 关联常驻。
# 宿主 IP 以 `ip -4 addr show wlan0` 实测为准（当前 192.168.10.194）。
set -euo pipefail
PORT="${1:-6666}"
OUT="/tmp/netconsole-$(date +%Y%m%d-%H%M%S).log"
command -v socat >/dev/null 2>&1 && HAVE_SOCAT=1 || HAVE_SOCAT=0

echo "[i] 接收器落盘: $OUT  (Ctrl-C 停)"
if [ "$HAVE_SOCAT" = 1 ]; then
	exec socat -u UDP-RECV:"$PORT",bind=0.0.0.0 OPEN:"$OUT",creat,append
else
	# openbsd nc: -k 保持监听多包；busybox nc 无 -k（落一条断一条，不推荐）
	exec nc -k -u -l "$PORT" >> "$OUT"
fi
