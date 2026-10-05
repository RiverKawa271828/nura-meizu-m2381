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

OUT="~/work/pmos_linux/pmos/.pmbootstrap/chroot_native/home/pmos/rootfs/meizu-meizu20.img"
[ -e "$OUT" ] || nura_die "找不到 rootfs 产物: $OUT"
echo "[✓] 产物: $OUT"
echo "    刷写: fastboot flash userdata $OUT（⚠ 全量重刷 = 机上手工补装件清零，"
echo "          四件套/rmtfs drop-in/uim 补丁/discover-backend 重装清单见指纹表）"
