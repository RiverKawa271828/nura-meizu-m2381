#!/system/bin/sh
# 40-gnss-probe.sh — GNSS 会话切片（Android/mksh；root 下跑）
# 用法: sh 40-gnss-probe.sh   （执行前用户开定位 + 打开地图类 app；本脚本挂 5 分钟）
# 取证卡: docs/flyme-forensics-card-20261127.md §2.4
OUT=/data/local/tmp/forensics
D="$OUT/gnss"
mkdir -p "$D"
date > "$D/meta.txt"

logcat -c 2>/dev/null
# 5 分钟全量切片（toybox timeout 兜底；无 timeout 则靠 Ctrl-C）
timeout 300 logcat -b all -v time > "$D/logcat-all.txt" 2>/dev/null
dumpsys location > "$D/location.txt" 2>/dev/null
dumpsys hardware.location 2>/dev/null >> "$D/location.txt"
grep -iE 'gnss|gps|loc |agps' "$D/logcat-all.txt" > "$D/logcat-gnss.txt" 2>/dev/null
dmesg > "$D/dmesg.txt" 2>/dev/null
echo "done: $D"
