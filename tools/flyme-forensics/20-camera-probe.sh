#!/system/bin/sh
# 20-camera-probe.sh — 相机工作流运行态快照（Android/mksh；root 下跑）
# 用法: sh 20-camera-probe.sh <front|rear>
#   用户先在 stock 相机把对应摄切好并保持取景，再执行本脚本。
# 取证卡: docs/flyme-forensics-card-20261127.md §2.2
TAG="${1:-front}"
OUT=/data/local/tmp/forensics
BIN="$OUT/bin"
D="$OUT/camera-$TAG"
mkdir -p "$D"
date > "$D/meta.txt"

# 1) camx debugfs 路径摸底 + 可读文件全 dump
find /sys/kernel/debug -maxdepth 3 -iname '*cam*' > "$D/debugfs-cam-paths.txt" 2>/dev/null
while IFS= read -r p; do
	case "$p" in
		*/camx*|*/camera*)
			sub="$D/camxdump$(echo "$p" | tr '/' '_')"
			mkdir -p "$sub"
			for f in "$p"/*; do
				[ -f "$f" ] && cat "$f" > "$sub/$(basename "$f")" 2>/dev/null
			done
			;;
	esac
done < "$D/debugfs-cam-paths.txt"

# 2) media graph + v4l 实况（自研静态工具；不在位则记缺失）
: > "$D/media-topology.txt"
for m in /dev/media*; do
	[ -e "$m" ] || continue
	if [ -x "$BIN/media-dump" ]; then
		"$BIN/media-dump" "$m" >> "$D/media-topology.txt" 2>&1
	else
		echo "media-dump 缺失（00-prep 未跑）" >> "$D/media-topology.txt"
		break
	fi
done
: > "$D/v4l-formats.txt"
for v in /dev/video*; do
	[ -e "$v" ] || continue
	[ -x "$BIN/v4l-fmt" ] && "$BIN/v4l-fmt" "$v" >> "$D/v4l-formats.txt" 2>&1
done
ls -la /dev/video* /dev/media* /dev/v4l-subdev* > "$D/dev-nodes.txt" 2>/dev/null

# 3) 内核 + 日志切片
dmesg > "$D/dmesg.txt" 2>/dev/null
logcat -d -t 4000 > "$D/logcat.txt" 2>/dev/null
logcat -d -t 2000 -b radio > "$D/logcat-radio.txt" 2>/dev/null

# 4) vendor 相机件清单（对照已归档 EROFS 提取物）
ls /vendor/lib64/camera/ > "$D/vendor-camera-libs.txt" 2>/dev/null
ls /vendor/etc/camera/ > "$D/vendor-camera-etc.txt" 2>/dev/null
echo "done: $D"
