#!/usr/bin/env bash
# 00-prep-static-bins.sh — 宿主侧：pmbootstrap chroot 内 -static 自建取证小工具
# （pmOS apk 二进制 = musl 动态，Android 跑不起来；必须 -static。禁外来二进制。）
# 用法：在宿主跑（沙箱 = systemd-run --user 重入，同 wrapper 守卫形态）：
#   export NURA_WORK=/home/ri/work
#   systemd-run --user --collect --wait --setenv=NURA_WORK=$NURA_WORK \
#     --working-directory=<repo> bash tools/flyme-forensics/00-prep-static-bins.sh
# 产物：tools/flyme-forensics/out/{media-dump,v4l-fmt,tiny-mix,i2c-scan}（aarch64 静态）
# 2026-11-27 取证轮实测修正：全局参数 = -c/-p/-w（--pmb-work 不存在）；
# aarch64 舱 = build_init -b + chroot -b（--arch/--bind 该版均不存在 → 源码 cp 进出）。
set -euo pipefail
NURA_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$NURA_ROOT/tools/flyme-forensics/src"
OUT="$NURA_ROOT/tools/flyme-forensics/out"
PMB="${NURA_WORK:-/home/ri/work}/pmos_linux/pmos/pmbootstrap/pmbootstrap.py"
CFG=/tmp/pmx-forensics.ini
PMB_WORK="${NURA_WORK:-/home/ri/work}/pmos_linux/pmos/.pmbootstrap"
APORTS="${NURA_WORK:-/home/ri/work}/pmos_linux/pmos/pmaports"
TOOLS="media-dump v4l-fmt tiny-mix i2c-scan"

mkdir -p "$OUT"
[ -f "$CFG" ] || cp "$NURA_ROOT/script/pmbootstrap-meizu.cfg" "$CFG"

PMBARGS=(-c "$CFG" -p "$APORTS" -w "$PMB_WORK")

# aarch64 buildroot 舱（幂等；qemu-user 仿真原生 gcc）
python3 "$PMB" "${PMBARGS[@]}" build_init -b aarch64

# 工具链进舱（--add 一步装机；已装则秒过）
python3 "$PMB" "${PMBARGS[@]}" chroot -b aarch64 --add gcc,musl-dev,linux-headers -- true

# 源码 cp 进舱编译（-static），产物 cp 回（chroot 内 root 属主，回宿主即 chown）
CHROOT="$PMB_WORK/chroot_buildroot_aarch64"
for t in $TOOLS; do
	sudo cp "$SRC/$t.c" "$CHROOT/tmp/$t.c"
	python3 "$PMB" "${PMBARGS[@]}" chroot -b aarch64 -- \
		sh -c "gcc -static -O2 -s -o /tmp/$t.aarch64 /tmp/$t.c"
	sudo cp "$CHROOT/tmp/$t.aarch64" "$OUT/$t"
	sudo chown "$(id -u):$(id -g)" "$OUT/$t"
	echo "built: $t"
done

# aarch64 ELF 校验
for t in $TOOLS; do
	file "$OUT/$t" | grep -q "ARM aarch64.*static" \
		|| { echo "FATAL: $t 非静态 aarch64"; exit 1; }
done
echo "产物就绪：$OUT/"
echo "上机：adb push out/* /data/local/tmp/forensics/bin/"
