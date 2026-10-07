#!/usr/bin/env bash
# build-rootfs.sh — pmbootstrap install → userdata rootfs 镜像
#
# 用法: build-rootfs.sh
#
# 产物 = .pmbootstrap/chroot_native/home/pmos/rootfs/meizu-meizu20.img
# （L2 快照锚复原路线见 experiment-log（六十二），那是另一条已验证路径。）
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

echo "[i] pmbootstrap install（plasma-mobile / 密码 1234；~10-20 分钟）"
"$PIN_PMB_WRAPPER" install --password 1234

OUT="$PMB_WORK/chroot_native/home/pmos/rootfs/meizu-meizu20.img"
[ -e "$OUT" ] || nura_die "找不到 rootfs 产物: $OUT"
echo "[✓] 产物: $OUT"
echo "    刷写: fastboot flash userdata $OUT（⚠ 全量重刷 = 机上手工补装件清零，"
echo "          四件套/rmtfs drop-in/uim 补丁/discover-backend 重装清单见指纹表）"

# ---- Release 件固化：gz（<2GiB = GitHub Release 单件上限）+ SHA256SUMS 行刷新 ----
# rN 后缀从本地内核 apk 包名推导（linux-meizu-meizu20-7.3.0_rc3-r66.apk → r66）
KN="$(basename "$(ls "$APK_DIR/$PKG_LINUX-"*.apk | sort -V | tail -1)")"
REL_TAG="r${KN##*-r}"; REL_TAG="${REL_TAG%.apk}"
REL_DIR="$NURA_ROOT/artifacts"
OUT_GZ="$REL_DIR/meizu-meizu20-$REL_TAG.img.gz"
gzip -c "$OUT" > "$OUT_GZ"
SZ="$(stat -c%s "$OUT_GZ")"
[ "$SZ" -lt 2147483648 ] || nura_die "$OUT_GZ = $SZ 字节 ≥ 2GiB（GitHub Release 单件上限，需 sparse/分卷再议）"
SUMS="$REL_DIR/SHA256SUMS"
touch "$SUMS"
grep -vF "  $(basename "$OUT_GZ")" "$SUMS" > "$SUMS.tmp" || true
( cd "$REL_DIR" && sha256sum "$(basename "$OUT_GZ")" ) >> "$SUMS.tmp"
mv "$SUMS.tmp" "$SUMS"
echo "[✓] Release 件: $OUT_GZ（$(du -h "$OUT_GZ" | cut -f1)）+ SHA256SUMS 已刷新"
