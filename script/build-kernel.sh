#!/usr/bin/env bash
# build-kernel.sh — fork 内核树 → linux apk（模块腿）
#
# 用法: build-kernel.sh [--bump] [--no-tarball]
#   --bump       APKBUILD pkgrel +1（源码变了必须 bump，同 pkgrel 设备端拒装）
#   --no-tarball 跳过 tarball 重打（只改 APKBUILD 时复用）
#
# 配方出处: AGENTS「内核升级（fork 时代）」+ APKBUILD 注释。
# pmbootstrap 必须宿主跑（沙箱 sudo/losetup 必死）→ 未在宿主 user 单元内时
# 自动经 systemd-run 重入。
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck

BUMP=0; TARBALL=1
for a in "$@"; do
	case "$a" in
		--bump) BUMP=1 ;;
		--no-tarball) TARBALL=0 ;;
		*) echo "unknown arg: $a"; exit 2 ;;
	esac
done

# 已在 systemd user 单元内（INVOCATION_ID 有值）= 宿主环境，直接跑；
# 否则一律 systemd-run 重入（宿主 shell 里跑也安全，只是多一层单元）。
if [ -z "${NURA_INSIDE_UNIT:-}" ]; then
	echo "[i] 经 systemd-run 在宿主执行"
	export NURA_INSIDE_UNIT=1
	exec systemd-run --user --collect --quiet \
		--unit="pmx-nura-$(basename "$0" .sh)-$(date +%H%M%S)" \
		--working-directory="$NURA_ROOT" bash "$0" "$@"
fi

PKGDIR="$PIN_PMAPORTS/device/downstream/$PKG_LINUX"
TARBALL_NAME="${PKG_LINUX}-fork-v${PKGVER}.tar.gz"

if [ "$TARBALL" = 1 ]; then
	echo "[1/4] 重打 tarball（fork $PIN_LINUX_BRANCH @ $(git -C "$PIN_LINUX_DIR" rev-parse --short HEAD)）"
	git -C "$PIN_LINUX_DIR" archive --format=tar.gz \
		--prefix="${PKG_LINUX}-fork-v${PKGVER}/" "$PIN_LINUX_BRANCH" \
		> "$PKGDIR/$TARBALL_NAME"
else
	echo "[1/4] 跳过 tarball 重打"
fi

if [ "$BUMP" = 1 ]; then
	echo "[2/4] pkgrel bump"
	python3 - "$PKGDIR/APKBUILD" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
s2 = re.sub(r'(?m)^pkgrel=(\d+)$', lambda m: f'pkgrel={int(m.group(1))+1}', s, count=1)
assert s2 != s, "pkgrel not found"
open(p, 'w').write(s2)
EOF
else
	echo "[2/4] pkgrel 不动"
fi

echo "[3/4] checksum（pmbootstrap）"
"$PIN_PMB_WRAPPER" checksum "$PKG_LINUX"

echo "[4/4] build --force（长构建 ~25min；实时日志: tail .pmbootstrap/log.txt）"
"$PIN_PMB_WRAPPER" build "$PKG_LINUX" --force

PKGREL=$(grep -m1 '^pkgrel=' "$PKGDIR/APKBUILD" | cut -d= -f2)
APK="$APK_DIR/${PKG_LINUX}-${PKGVER}-r${PKGREL}.apk"
echo "[✓] 产物: $APK"
echo "    提交: pmaports 内 APKBUILD 变更需 git commit（包状态随改随提交）"
echo "    后续: script/build-esp.sh（ESP 腿）+ script/build-mu.sh（DT 变了才需）"
echo "    验证: script/verify.sh"
