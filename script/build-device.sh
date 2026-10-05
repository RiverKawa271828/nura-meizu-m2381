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

echo "[1/3] checksum device + firmware"
"$PIN_PMB_WRAPPER" checksum "$PKG_DEVICE"
"$PIN_PMB_WRAPPER" checksum "$PKG_FIRMWARE"

echo "[2/3] build device"
"$PIN_PMB_WRAPPER" build "$PKG_DEVICE" --force

echo "[3/3] build firmware"
"$PIN_PMB_WRAPPER" build "$PKG_FIRMWARE" --force

echo "[✓] 产物: $APK_DIR/${PKG_DEVICE}-1-r$(grep -m1 '^pkgrel=' "$DPKGDIR/APKBUILD" | cut -d= -f2).apk"
echo "         $APK_DIR/${PKG_FIRMWARE}-1-r$(grep -m1 '^pkgrel=' "$FPKGDIR/APKBUILD" | cut -d= -f2).apk"
echo "    装包: FLASHING.md §3（主包+子包同装纪律）"
