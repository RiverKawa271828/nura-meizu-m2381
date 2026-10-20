#!/usr/bin/env bash
# build-device.sh — 设备包 + 固件包 apk（用户态胶水 + blob）
#
# 用法: build-device.sh [--bump-device] [--bump-fw]
#   改了设备包/固件包内容后必须对应 bump（同 pkgrel 设备端拒装）。
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck

if [ -z "${NURA_INSIDE_UNIT:-}" ]; then
	echo "[i] 经 systemd-run 在宿主执行"
	export NURA_INSIDE_UNIT=1
	exec systemd-run --user --collect --quiet \
		--unit="pmx-nura-$(basename "$0" .sh)-$(date +%H%M%S)" \
		--setenv=NURA_INSIDE_UNIT=1 \
		--working-directory="$NURA_ROOT" bash "$0" "$@"
fi

DPKGDIR="$PIN_PMAPORTS/device/downstream/$PKG_DEVICE"
FPKGDIR="$PIN_PMAPORTS/device/downstream/$PKG_FIRMWARE"

bump() { python3 - "$1" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
s2 = re.sub(r'(?m)^pkgrel=(\d+)$', lambda m: f'pkgrel={int(m.group(1))+1}', s, count=1)
assert s2 != s, "pkgrel not found"
open(p, 'w').write(s2)
EOF
}

for a in "$@"; do
	case "$a" in
		--bump-device) bump "$DPKGDIR/APKBUILD"; echo "[i] device pkgrel bump" ;;
		--bump-fw)     bump "$FPKGDIR/APKBUILD"; echo "[i] firmware pkgrel bump" ;;
		*) echo "unknown arg: $a"; exit 2 ;;
	esac
done

echo "[1/4] checksum device + firmware"
"$PIN_PMB_WRAPPER" checksum "$PKG_DEVICE"
"$PIN_PMB_WRAPPER" checksum "$PKG_FIRMWARE"

echo "[2/4] hexagonrpcd 预编（CI 冷包仓）"
# pmbootstrap 依赖队列给依赖排队不传 arch（queue_build 只传 cross），
# arch="all" 的依赖被 autodetect 成宿主原生 arch ⇒ CROSSDIRECT 组合去装
# gcc-<native arch>（native 仓索引无此包 ⇒ apk 退出码 2，#11 定谳）。显式
# --arch 走目标包路径无此病。本地包仓有 apk 时 is_cached 同款跳过。
if compgen -G "$APK_DIR/hexagonrpcd-*" > /dev/null; then
	echo "    已有 apk，跳过"
else
	"$PIN_PMB_WRAPPER" build --arch aarch64 hexagonrpcd
fi

echo "[2b/4] iio-sensor-proxy fork 预编（同 #11 坑 + 官方仓二进制遮蔽）"
# fork（temp/iio-sensor-proxy，SSC 四补丁，0003 load-bearing）从未进 device
# depends，官方 edge 仓有 3.9-r2 裸包可解析 ⇒ pmbootstrap 不构建它；CI 冷包仓
# 没有本地 10-03 手工件的存续 ⇒ rootfs 择官方 r2 = 传感器 QS 开关消失
# （2026-10-21 定谳，凡刷 CI r86/r87 rootfs 者皆中）。显式预编后本地包仓
# r3 > 官方 r2，apk install/升级闭合一律取 fork。已装设备不受影响（世界
# 锁名不锁源；后续官方 r4 才会盖回，届时再 bump fork pkgrel）。
if compgen -G "$APK_DIR/iio-sensor-proxy-3.9-r*.apk" > /dev/null; then
	echo "    已有 apk，跳过"
else
	"$PIN_PMB_WRAPPER" build --arch aarch64 iio-sensor-proxy
fi

echo "[3/4] build device"
"$PIN_PMB_WRAPPER" build "$PKG_DEVICE" --force

echo "[4/4] build firmware"
"$PIN_PMB_WRAPPER" build "$PKG_FIRMWARE" --force

echo "[✓] 产物: $APK_DIR/${PKG_DEVICE}-1-r$(grep -m1 '^pkgrel=' "$DPKGDIR/APKBUILD" | cut -d= -f2).apk"
echo "         $APK_DIR/${PKG_FIRMWARE}-1-r$(grep -m1 '^pkgrel=' "$FPKGDIR/APKBUILD" | cut -d= -f2).apk"
echo "    装包: FLASHING.md §3（主包+子包同装纪律）"
