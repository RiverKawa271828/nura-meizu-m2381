#!/system/bin/sh
# 30-call-audio-probe.sh — 通话音频态快照（Android/mksh；root 下跑）
# 用法: sh 30-call-audio-probe.sh <idle|incall|post>
#   incall 态 = 真实通话进行中执行（对方已接、保持通话）。
# 取证卡: docs/flyme-forensics-card-20261127.md §2.3
TAG="${1:-idle}"
OUT=/data/local/tmp/forensics
BIN="$OUT/bin"
D="$OUT/audio-$TAG"
mkdir -p "$D"
date > "$D/meta.txt"

# 1) 全卡全控件 dump（tiny-mix 自研静态件；这是施工图本体）
if [ -x "$BIN/tiny-mix" ]; then
	for c in /dev/snd/controlC*; do
		"$BIN/tiny-mix" "$c" > "$D/mix-$(basename "$c").txt" 2>&1
	done
else
	echo "tiny-mix 缺失（00-prep 未跑）" > "$D/mix-MISSING.txt"
fi

# 2) ALSA 拓扑/PCM 实况
cat /proc/asound/pcm > "$D/pcm.txt" 2>/dev/null
cat /proc/asound/cards > "$D/cards.txt" 2>/dev/null
cat /proc/asound/devices > "$D/devices.txt" 2>/dev/null
ls -la /dev/snd/ > "$D/dev-snd.txt" 2>/dev/null

# 3) Android 音频栈实况
dumpsys media.audio_flinger > "$D/audioflinger.txt" 2>/dev/null
dumpsys audio > "$D/audio.txt" 2>/dev/null
logcat -d -t 4000 > "$D/logcat.txt" 2>/dev/null

# 4) modem/IMS 面切片（注册态与 IMS attach 参考）
dumpsys telephony.registry > "$D/telephony.txt" 2>/dev/null
echo "done: $D"
