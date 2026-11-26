#!/system/bin/sh
# 99-collect.sh — 杂项收尾 + 打包（Android/mksh；root 下跑）
# 用法: sh 99-collect.sh   （全部探针跑完后最后执行）
# 取证卡: docs/flyme-forensics-card-20261127.md §2.5
OUT=/data/local/tmp/forensics
mkdir -p "$OUT/misc"

getprop > "$OUT/misc/getprop.txt" 2>/dev/null
cat /proc/config.gz > "$OUT/misc/config.gz" 2>/dev/null
dmesg > "$OUT/misc/dmesg-full.txt" 2>/dev/null
cat /proc/cmdline > "$OUT/misc/cmdline.txt" 2>/dev/null
cat /proc/version > "$OUT/misc/kernel-version.txt" 2>/dev/null
uname -a > "$OUT/misc/uname.txt" 2>/dev/null
ls /vendor/lib64/ > "$OUT/misc/vendor-libs.txt" 2>/dev/null
ls /vendor/firmware/ > "$OUT/misc/vendor-firmware.txt" 2>/dev/null
cat /proc/partitions > "$OUT/misc/partitions.txt" 2>/dev/null
ls -la /dev/block/by-name/ > "$OUT/misc/by-name.txt" 2>/dev/null

cd /data/local/tmp
tar czf forensics-bundle.tar.gz forensics/ 2>/dev/null
ls -la /data/local/tmp/forensics-bundle.tar.gz
echo "宿主侧: adb pull /data/local/tmp/forensics-bundle.tar.gz"
