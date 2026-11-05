#!/bin/sh
# devselfcheck.sh — B1 设备侧自检（回归清单一条命令出结果 + 与上一份结果对比）
#
# ★设备侧脚本：devpush 上去、root shell（devsh:23 或 sudo）里跑——宿主没有设备 sysfs。
#   推送: tools/devpush.py script/devselfcheck.sh
#   运行: sh devselfcheck.sh              # 默认档（自动项 + 人工眼判项）
#
# 档位（红线：rtcwake/真睡类必须显式 --with-rtcwake；rtcwake 一律 -d /dev/rtc1）:
#   --light            只跑只读自动项（零交互零真睡 = 无人值守/快速体检档）
#   (默认)             自动项 + 人工引导项 M1-M3（用户眼判后 y/n 记录）
#   --with-rtcwake     默认档 + M4 rtcwake resume 真睡项（-s 30，眼判窗 ≥25s）
#   --expect-uname #N  覆盖期望内核代号（默认 #92 = 在机现态；上 r92 后传 #93）
#   --no-save          不落结果文件（本机调试用）
#
# 自动项（只读）:
#   [A1] uname 期望对拍   #N=pkgrel+1 定律（uname -v = #N-meizu-meizu20）
#   [A2] wowlan 武装态    iw phy0 wowlan show 直读（★勿用 info 段=能力表易混，(九十九)坑）
#   [A3] cpuidle 深度锁   cpu0 各 state sysfs disable 计数（现态=锁在；全开=WARN 提醒复锁）
#   [A4] systemctl --failed  期望 0；已知非回归（dsp-mount/qbootctl*/rmtfs/uim/zram）=WARN
#   [A5] GPU 钳零读数     /sys/kernel/debug/dri/<N>/devfreq/busy_deltas 5 连读恒 0（1s 间隔）
#   [A6] 传感器就绪       iio-sensor-proxy active + /sys/bus/iio/devices 非空（ADSP boot+75s 才全就绪）
#   [A7] WiFi 5G 频段     iw phy0 wiphy 层 5G 频点计数（freq_range 塌缩判据 = TD-02 域）
# 人工引导项（脚本提示、用户眼判后 y/n）:
#   [M1] 电源键响应   [M2] 出声（工作点配方 = docs/AUDIO-METHOD §2）   [M3] 触屏跟手
#   [M4] rtcwake resume（仅 --with-rtcwake；ssh 会话 sleep-blocker 不挡此路 = 直写 /sys/power/state）
#
# 结果: /var/lib/nura-selfcheck/selfcheck-<ts>.txt（不可写退 ~/.nura-selfcheck）；
#       每次自动与上一份结果逐项对比，状态变化逐条打印。
# 退出码: 0 = 无 FAIL；1 = 有 FAIL；2 = 用法错误
# 坑册对齐: bringup-traps（rtc1 + ≥25s 眼判）｜MANIFEST 已知非回归表｜TD-01/TD-02
# 时耗: --light 约 6s（A5 占 5s）；全档看人工项速度。

set -u

MODE_LIGHT=0; WITH_RTCWAKE=0; SAVE=1
EXPECT="${NURA_EXPECT_UNAME:-#92}"

usage() { sed -n '2,34p' "$0" | sed 's/^#\{1,\} \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
	case "$1" in
		--light) MODE_LIGHT=1 ;;
		--with-rtcwake) WITH_RTCWAKE=1 ;;
		--expect-uname) [ $# -ge 2 ] || { echo "缺参数: $1" >&2; exit 2; }; shift; EXPECT="$1" ;;
		--expect-uname=*) EXPECT="${1#*=}" ;;
		--no-save) SAVE=0 ;;
		-h|--help) usage ;;
		*) echo "未知参数: $1（--help 看用法）" >&2; exit 2 ;;
	esac
	shift
done
case "$EXPECT" in \#*) ;; *) EXPECT="#$EXPECT" ;; esac
case "$EXPECT" in
	\#[0-9]*) : ;;
	*) echo "期望代号格式应为 '#92'，收到 '$EXPECT'" >&2; exit 2 ;;
esac

# ---- 输出通道：stdout + 结果文件双写（无 tee/管道子壳，计数器全程存活）----
PASS_N=0; FAIL_N=0; WARN_N=0; SKIP_N=0
OUTFILE=""
out() { printf '%s\n' "$*"; [ -n "$OUTFILE" ] && printf '%s\n' "$*" >>"$OUTFILE"; return 0; }

OUTDIR=""
if [ "$SAVE" = 1 ]; then
	OUTDIR="/var/lib/nura-selfcheck"
	if ! mkdir -p "$OUTDIR" 2>/dev/null; then
		OUTDIR="${HOME:-/tmp}/.nura-selfcheck"
		mkdir -p "$OUTDIR" 2>/dev/null || { OUTDIR="/tmp/nura-selfcheck-$$"; mkdir -p "$OUTDIR" 2>/dev/null; }
		echo "(注: /var/lib 不可写，结果退落 $OUTDIR)"
	fi
	OUTFILE="$OUTDIR/selfcheck-$(date '+%Y%m%d-%H%M%S').txt"
	_n=1
	while [ -e "$OUTFILE" ]; do  # 同秒重跑防撞名（截断上一份 = 对比基线丢失）
		OUTFILE="$OUTDIR/selfcheck-$(date '+%Y%m%d-%H%M%S')-$_n.txt"
		_n=$((_n + 1))
	done
	: >"$OUTFILE" 2>/dev/null || { echo "(注: 结果文件建不了，仅打印不落盘)"; OUTFILE=""; }
else
	OUTFILE="$(mktemp "${TMPDIR:-/tmp}/devselfcheck.XXXXXX")"
	trap 'rm -f "$OUTFILE"' EXIT INT TERM
fi

PREV=""
if [ -n "$OUTDIR" ]; then
	for f in "$OUTDIR"/selfcheck-*.txt; do
		[ -f "$f" ] || continue
		[ "$f" = "$OUTFILE" ] && continue
		{ [ -z "$PREV" ] || [ "$f" -nt "$PREV" ]; } && PREV="$f"
	done
fi

emit() { # emit <id> <PASS|FAIL|WARN|SKIP> <detail...>
	case "$2" in
		PASS) PASS_N=$((PASS_N + 1)) ;;
		FAIL) FAIL_N=$((FAIL_N + 1)) ;;
		WARN) WARN_N=$((WARN_N + 1)) ;;
		*)    SKIP_N=$((SKIP_N + 1)) ;;
	esac
	out "[$1] $2 ${3:-}"
}
ask_yn() { printf '  %s [y/N] ' "$1"; read -r _ans; case "${_ans:-}" in y|Y|yes|Yes|YES) return 0 ;; *) return 1 ;; esac; }

# ---- 头 ----
MODE=""
[ "$MODE_LIGHT" = 1 ] && MODE="$MODE --light"
[ "$WITH_RTCWAKE" = 1 ] && MODE="$MODE --with-rtcwake"
out "== devselfcheck @ $(date '+%Y-%m-%d %H:%M:%S') 档位${MODE:- 默认} 期望=${EXPECT} =="
if [ "$(id -u 2>/dev/null)" != "0" ]; then
	out "⚠ 非 root：A5 debugfs / M4 rtcwake 会降级；建议 root devshell 或 sudo 重跑"
fi

# ---- 自动项（只读）----

# [A1] uname 期望对拍（#N=pkgrel+1 定律）
uv="$(uname -v 2>/dev/null)"
act=""
case "$uv" in
	"#"*"meizu-meizu20"*) act="${uv%%-*}"; act="${act#\#}" ;;
esac
exp="${EXPECT#\#}"
if [ -z "$act" ]; then
	emit A1 FAIL "uname -v='$uv' 不含 meizu-meizu20 代号（非本仓内核？）"
elif [ "$act" = "$exp" ]; then
	emit A1 PASS "uname #${act}-meizu-meizu20 = 期望"
else
	emit A1 WARN "uname #${act} ≠ 期望 #${exp}（换版本后记得带 --expect-uname）"
fi

# [A2] wowlan 武装态（show 直读，勿用 info 段）
if ! command -v iw >/dev/null 2>&1; then
	emit A2 SKIP "iw 不在（apk add iw）——wowlan 未验"
else
	w="$(iw phy0 wowlan show 2>&1)"
	if [ -z "$w" ]; then
		emit A2 SKIP "wowlan show 空输出（root？phy0 在？）"
	elif printf '%s' "$w" | grep -q 'disabled'; then
		emit A2 FAIL "wowlan 未武装（meizu-wowlan.service 没跑？）"
	elif printf '%s' "$w" | grep -q 'magic-packet'; then
		emit A2 PASS "wowlan 武装（magic-packet）"
	else
		emit A2 WARN "输出不识别: $(printf '%s' "$w" | head -n1)"
	fi
fi

# [A3] cpuidle 深度锁（cpu0 视角；现态 = 深度态 disable）
CID="/sys/devices/system/cpu/cpu0/cpuidle"
if [ ! -d "$CID" ]; then
	emit A3 SKIP "无 cpuidle sysfs"
else
	dis=0; tot=0; det=""
	for st in "$CID"/state*; do
		[ -d "$st" ] || continue
		tot=$((tot + 1))
		d="$(cat "$st/disable" 2>/dev/null)"
		nm="$(cat "$st/name" 2>/dev/null)"
		det="$det ${nm}=${d:-?}"
		[ "$d" = "1" ] && dis=$((dis + 1))
	done
	if [ "$tot" = 0 ]; then
		emit A3 SKIP "cpuidle 无 state 条目"
	elif [ "$dis" -gt 0 ]; then
		emit A3 PASS "锁在: ${dis}/${tot} 态 disable（$det）"
	else
		emit A3 WARN "锁未在: 0/${tot} disable（$det）——E 长跑后记得复锁"
	fi
fi

# [A4] systemctl --failed（期望 0；已知非回归 = WARN，见 MANIFEST 表）
fl="$(systemctl --failed --no-legend --plain 2>/dev/null)"
cnt="$(printf '%s\n' "$fl" | grep -c .)"
if [ "$cnt" = "0" ]; then
	emit A4 PASS "failed = 0"
else
	printf '%s\n' "$fl" | grep . | while IFS= read -r line; do out "      · $line"; done
	unk="$(printf '%s\n' "$fl" | grep -vcE '^(meizu-dsp-mount|qbootctl|qbootctl-meizu|rmtfs|uim-selection)\.service[[:space:]]|zram.*\.service[[:space:]]')"
	if [ "$unk" -gt 0 ]; then
		emit A4 FAIL "failed=$cnt，含未知 unit（journal 查）"
	else
		emit A4 WARN "failed=$cnt，全为已知非回归（首 boot 竞态类，boot-2 自愈；MANIFEST 表）"
	fi
fi

# [A5] GPU 钳零读数（真空闲 5 连读 busy_delta_us 恒 0；静态屏口径）
BZ=""
for cand in /sys/kernel/debug/dri/*/devfreq/busy_deltas; do
	[ -e "$cand" ] && BZ="$cand"
done
if [ -z "$BZ" ]; then
	emit A5 SKIP "busy_deltas 不在（debugfs 未挂/非 root/无 devfreq）"
else
	vals=""; nz=0; i=0
	while [ "$i" -lt 5 ]; do
		v="$(sed -n 's/^busy_delta_us[^0-9]*\([0-9][0-9]*\).*/\1/p' "$BZ" 2>/dev/null)"
		[ -z "$v" ] && v="?"
		vals="$vals $v"
		[ "$v" != "0" ] && nz=$((nz + 1))
		i=$((i + 1))
		[ "$i" -lt 5 ] && sleep 1
	done
	if [ "$nz" = 0 ]; then
		emit A5 PASS "真空闲钳零（5 连读全 0）"
	else
		emit A5 WARN "busy_delta_us 非零 ×${nz}:${vals}（有 UI 活动属正常；静态屏下非零 = 钳零件回归）"
	fi
fi

# [A6] 传感器就绪
sa="$(systemctl is-active iio-sensor-proxy 2>/dev/null)"
nd=0
for _d in /sys/bus/iio/devices/*; do [ -e "$_d" ] && nd=$((nd + 1)); done
if [ "$sa" = "active" ] && [ "$nd" -gt 0 ]; then
	emit A6 PASS "iio-sensor-proxy active + iio 设备 ${nd} 个"
elif [ "$sa" = "active" ]; then
	emit A6 WARN "proxy active 但 iio 设备 0（ADSP boot+75s 才就绪？刚开机稍等重跑）"
else
	emit A6 FAIL "iio-sensor-proxy 状态=${sa:-未知}（sensorspd/PD 链查）"
fi

# [A7] WiFi 5G 频段（wiphy 层频点计数 = freq_range 塌缩判据）
if ! command -v iw >/dev/null 2>&1; then
	emit A7 SKIP "iw 不在——5G 频段未验"
else
	f5="$(iw phy0 2>/dev/null | grep -cE '[[:space:]]\* 5[0-9][0-9][0-9]\.[0-9] MHz')"
	if [ "$f5" -gt 0 ]; then
		emit A7 PASS "wiphy 5G 频点 ${f5} 个在表"
	else
		emit A7 FAIL "wiphy 层 5G 频段零频点（freq_range 塌缩型回归，TD-02 域）"
	fi
fi

# ---- 人工引导项（用户眼判后 y/n 记录）----
out ""
if [ "$MODE_LIGHT" = 1 ]; then
	emit M1 SKIP "light 档"
	emit M2 SKIP "light 档"
	emit M3 SKIP "light 档"
	emit M4 SKIP "light 档"
elif [ ! -t 0 ]; then
	emit M1 SKIP "非交互 stdin（人工项需 tty：ssh -t 或设备本地终端）"
	emit M2 SKIP "非交互 stdin"
	emit M3 SKIP "非交互 stdin"
	if [ "$WITH_RTCWAKE" = 1 ]; then
		emit M4 SKIP "非交互 stdin（真睡需用户在场眼判）"
	else
		emit M4 SKIP "需 --with-rtcwake（红线）"
	fi
else
	if ask_yn "M1 电源键：按一下灭屏 → 再按点亮，响应正常？"; then
		emit M1 PASS "电源键眼判通过"
	else
		emit M1 FAIL "电源键响应异常（眼判）"
	fi
	if ask_yn "M2 出声：放一段音频（工作点配方 = docs/AUDIO-METHOD §2），双扬声器正常？"; then
		emit M2 PASS "出声眼判通过"
	else
		emit M2 FAIL "出声异常（眼判）"
	fi
	if ask_yn "M3 触屏：滑动 + 点按跟手正常？"; then
		emit M3 PASS "触屏眼判通过"
	else
		emit M3 FAIL "触屏异常（眼判）"
	fi
	if [ "$WITH_RTCWAKE" != 1 ]; then
		emit M4 SKIP "真睡项需显式 --with-rtcwake（红线）"
	elif ! command -v rtcwake >/dev/null 2>&1; then
		emit M4 SKIP "rtcwake 不在（apk add util-linux）"
	elif [ ! -e /dev/rtc1 ]; then
		emit M4 FAIL "/dev/rtc1 不在（rtc0 = rtc-efi 废件域，rtc1 = PMIC 真钟）"
	else
		out "  ⚠ 真睡判据发：rtcwake -d /dev/rtc1 -m mem -s 30（眼判窗 ≥25s）"
		out "    盯屏：入睡黑屏 → ~30s 自动唤醒。Enter 开始 / Ctrl-C 放弃。"
		read -r _go
		if rtcwake -d /dev/rtc1 -m mem -s 30; then
			if ask_yn "M4 醒回来了且屏/触控正常？"; then
				emit M4 PASS "rtcwake resume 眼判通过"
			else
				emit M4 FAIL "唤醒后状态异常（眼判）"
			fi
		else
			emit M4 FAIL "rtcwake 命令失败（rc=$?；root？rtc1 可用？）"
		fi
	fi
fi

# ---- 汇总 + 与上一份对比 ----
out "[SUM] pass=${PASS_N} fail=${FAIL_N} warn=${WARN_N} skip=${SKIP_N} @ $(date '+%Y-%m-%d %H:%M:%S')"

if [ -n "$PREV" ] && [ -f "$PREV" ]; then
	echo ""
	echo "== 与上一份对比: $PREV =="
	chg=0
	for id in A1 A2 A3 A4 A5 A6 A7 M1 M2 M3 M4; do
		p="$(grep "^\[$id\]" "$PREV" 2>/dev/null | head -n1)"
		c="$(grep "^\[$id\]" "$OUTFILE" 2>/dev/null | head -n1)"
		if [ -n "$c" ] && [ -z "$p" ]; then echo "  + $c"; chg=1; continue; fi
		[ -z "$p" ] && continue
		ps="$(printf '%s' "$p" | awk '{print $2}')"
		cs="$(printf '%s' "$c" | awk '{print $2}')"
		if [ "$ps" != "$cs" ]; then
			echo "  ~ $p"
			echo "   → $c"
			chg=1
		fi
	done
	[ "$chg" = 0 ] && echo "  （状态与上一份零变化）"
fi

[ "$SAVE" = 1 ] && [ -n "$OUTFILE" ] && echo "结果: $OUTFILE"

[ "$FAIL_N" -gt 0 ] && exit 1
exit 0
