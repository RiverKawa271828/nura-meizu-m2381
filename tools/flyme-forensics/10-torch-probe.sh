#!/system/bin/sh
# 10-torch-probe.sh — 闪光灯态快照（Android/mksh；root 下跑）
# 用法: sh 10-torch-probe.sh <A|B|C>   A=灭灯基线 B=点亮态 C=熄灭态
# 取证卡: docs/flyme-forensics-card-20261127.md §2.1
TAG="${1:-X}"
OUT=/data/local/tmp/forensics
D="$OUT/torch-$TAG"
mkdir -p "$D/regmap"
date > "$D/meta.txt"
id >> "$D/meta.txt" 2>&1

# 1) LEDs 全节点全属性
: > "$D/leds.txt"
for l in /sys/class/leds/*; do
	[ -e "$l" ] || continue
	n=$(basename "$l")
	echo "== $n ==" >> "$D/leds.txt"
	for f in "$l"/*; do
		[ -f "$f" ] || continue
		echo "$(basename "$f"): $(cat "$f" 2>/dev/null | head -c 200)" >> "$D/leds.txt"
	done
done

# 2) regmap 寄存器全量（目标 flash PMIC + 保险全 dump）
for r in /sys/kernel/debug/regmap/*; do
	n=$(basename "$r")
	cat "$r/registers" > "$D/regmap/$n.txt" 2>/dev/null
done

# 3) pinctrl / GPIO 实况
cat /sys/kernel/debug/pinctrl/*/pinmux-pins > "$D/pinmux.txt" 2>/dev/null

# 4) 电源/轨实况
for p in /sys/class/power_supply/*; do
	n=$(basename "$p")
	echo "== $n ==" >> "$D/powersupply.txt"
	for f in "$p"/*; do
		[ -f "$f" ] && echo "$(basename "$f"): $(cat "$f" 2>/dev/null | head -c 100)" >> "$D/powersupply.txt"
	done
done

dmesg > "$D/dmesg.txt" 2>/dev/null
echo "done: $D"
