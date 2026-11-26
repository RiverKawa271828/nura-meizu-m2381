#!/usr/bin/env bash
# 00-prep-static-bins.sh — 宿主侧：pmbootstrap chroot 内 -static 自建取证小工具
# （pmOS apk 二进制 = musl 动态，Android 跑不起来；必须 -static。禁外来二进制。）
# 用法：script/pmbootstrap-meizu.sh 已带守卫；本脚本在宿主跑：
#   tools/flyme-forensics/00-prep-static-bins.sh
# 产物：tools/flyme-forensics/out/{media-dump,v4l-fmt,tiny-mix,i2c-scan}（aarch64 静态）
# ⚠chroot 内属主/路径坑照坑册处理；遇 pmbootstrap 三坑（守卫/--pipe 竞速）现场修。
set -euo pipefail
NURA_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$NURA_ROOT/tools/flyme-forensics/src"
OUT="$NURA_ROOT/tools/flyme-forensics/out"
PMB="$NURA_WORK/pmos_linux/pmos/pmbootstrap/pmbootstrap.py"
CFG=/tmp/pmx-forensics.ini
PMB_WORK="$NURA_WORK/pmos_linux/pmos/.pmbootstrap"

mkdir -p "$OUT"
# 首跑：init 建 aarch64 构建舱（复用既有 work dir 则跳过）
python3 "$PMB" -c "$CFG" --pmb-work "$PMB_WORK" init || true
python3 "$PMB" -c "$CFG" --pmb-work "$PMB_WORK" --arch aarch64 build_init

# 工具链进舱（qemu 仿真 aarch64 原生 gcc，四件小源分钟级）
python3 "$PMB" -c "$CFG" --pmb-work "$PMB_WORK" --arch aarch64 \
	chroot --user -- apk add gcc musl-dev linux-headers

# 源码挂进舱编译（-static；--bind 宿主:舱内）
for t in media-dump v4l-fmt tiny-mix i2c-scan; do
	python3 "$PMB" -c "$CFG" --pmb-work "$PMB_WORK" --arch aarch64 \
		chroot --user --bind "$SRC" /mnt-src -- \
		sh -c "gcc -static -O2 -s -o /mnt-src/$t.aarch64 /mnt-src/$t.c"
	echo "built: $t"
done

# aarch64 ELF 校验
for t in media-dump v4l-fmt tiny-mix i2c-scan; do
	file "$SRC/$t.aarch64" | grep -q "ARM aarch64.*static" \
		|| { echo "FATAL: $t 非静态 aarch64"; exit 1; }
	cp "$SRC/$t.aarch64" "$OUT/$t"
done
echo "产物就绪：$OUT/"
echo "上机：adb push out/* /data/local/tmp/forensics/bin/"
