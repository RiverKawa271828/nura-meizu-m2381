#!/system/bin/sh
# 10-torch-probe.sh — 闪光灯态快照（Android/mksh；root 下跑）
# 用法: sh 10-torch-probe.sh <A|B|C>   A=灭灯基线 B=点亮态 C=熄灭态
# 取证卡: docs/flyme-forensics-card-20261127.md §2.1
TAG="${1:-X}"
OUT=/data/local/tmp/forensics
D="$OUT/torch-$TAG"
# debugfs 自挂载（stock 默认不挂；已挂则报错被吞；regmap/pinctrl 依赖）
mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null
mkdir -p "$D/regmap"
date > "$D/meta.txt"
id >> "$D/meta.txt" 2>&1

# 1) LEDs 全节点全属性
# ⚠aw_vibrator 白名单制：haptic_hv 驱动 ram_*/reg 等节点读取必炸
# （2026-11-27 实锤：ram_update_show list_add corruption → BUG → panic 自动重启，
#  pstore console-ramoops 归档私有区 panic1）
: > "$D/leds.txt"
for l in /sys/class/leds/*; do
	[ -e "$l" ] || continue
	n=$(basename "$l")
	echo "== $n ==" >> "$D/leds.txt"
	case "$n" in
	aw_vibrator|*vibrator*|*haptic*)
		for f in brightness max_brightness trigger shutdown_timeout; do
			[ -f "$l/$f" ] && echo "$f: $(cat "$l/$f" 2>/dev/null | head -c 200)" >> "$D/leds.txt"
		done
		continue
		;;
	esac
	for f in "$l"/*; do
		[ -f "$f" ] || continue
		echo "$(basename "$f"): $(cat "$f" 2>/dev/null | head -c 200)" >> "$D/leds.txt"
	done
done

# 2) regmap 寄存器（只 SPMI PMIC + I2C 总线型）
# ⚠黑名单 MMIO 域（clock-controller/gdsc/interconnect 等）：关电域读 registers
# = synchronous external abort → panic 自动重启（2026-11-27 实锤，死点
# 1000000.clock-controller，pstore panic2 归档）。闪光灯案目标 = 0-01 pm8550。
for r in /sys/kernel/debug/regmap/*; do
	n=$(basename "$r")
	case "$n" in
	[0-9]-[0-9a-f][0-9a-f]|[0-9]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
	*) continue ;;
	esac
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
