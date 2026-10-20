#!/usr/bin/env bash
# build-rootfs-min.sh — nura-min 定长根镜像（iOS userdata 尾部日志通道配套，2026-10-21）
#
# 交付物 = 固定尺寸 raw ext4 根镜像（非分区镜像、非 tar；默认 2G，≤4GiB 上限）。
# 用途：与 iOS 根（分区头部 16GiB sparse）在 userdata 上轮回共存——iOS 的
# SWEETLOG 日志环驻分区末尾（末 4MiB+4KiB），本镜像永不写到位。
#
# 路线 = 官方最小（用户 2026-10-21 拍板「不拆来拆去」）：
#   pmbootstrap ui=none（NURA_UI=none 经 wrapper 临时 cfg）+ --add
#   python3/openssh/usb-moded(developer profile)。内核/设备/固件包自动取
#   本地包仓现役（r91/r63/r3），包名版本由断言把关。devshell(:23 nc shell,
#   device 包自带+preset 自启)、USB 网络(usb-signaller+unudhcpd@usb0,
#   postmarketos-base 90-base.preset 使能 + developer profile 自选)、
#   getty@tty1(systemd preset)全部走官方件。
#
# 唯二镜像内手术（均 debugfs 后处理，不拆包不改包）：
#   ① mask meizu-grow-rootfs.service —— device 包 preset 自启的首启扩容器
#     （resize2fs 打到 userdata 整分区 464G）。官方最小镜像同样带它，
#     不 mask 必毁 iOS 尾部日志环 = 本镜像存在的意义。
#   ② 写 /etc/nura-min 溯源标记（版本钉 + 用途一行）。
#
# iOS 侧三条禁令 → 本脚本逐条断言（失败即 die，不出件）：
#   1. 构建零全分区写：本脚本只产独立定长文件；对 userdata 的唯一写入 =
#      iOS 侧 img2simg → fastboot sparse（物理上只碰镜像自身范围）。
#   2. 零首启扩容：grow 单元 mask + wants 摘除 + fstab 无 growfs（断言）。
#   3. fstab 无 resize/扩容语义（断言）。
#
# 用法: build-rootfs-min.sh
#   NURA_MIN_SIZE=2G   镜像定长（pmbootstrap --image-size 口径；≤4G 硬上限）
set -euo pipefail
. "$(dirname "$0")/../config.sh"
nura_precheck

NURA_MIN_SIZE="${NURA_MIN_SIZE:-2G}"
NURA_MIN_SIZE="${NURA_MIN_SIZE^^}"
case "$NURA_MIN_SIZE" in
	*G) NURA_MIN_BYTES=$(( ${NURA_MIN_SIZE%G} * 1073741824 )) ;;
	*M) NURA_MIN_BYTES=$(( ${NURA_MIN_SIZE%M} * 1048576 )) ;;
	*) nura_die "NURA_MIN_SIZE 非法（需 <N>G/<N>M）: $NURA_MIN_SIZE" ;;
esac
[ "$NURA_MIN_BYTES" -le $((4*1073741824)) ] || nura_die "镜像 $NURA_MIN_SIZE 超 4GiB 硬上限"

if [ -z "${NURA_INSIDE_UNIT:-}" ]; then
	echo "[i] 经 systemd-run 在宿主执行（size=$NURA_MIN_SIZE）"
	export NURA_INSIDE_UNIT=1
	exec systemd-run --user --collect --quiet \
		--unit="pmx-nura-rootfs-min-$(date +%H%M%S)" \
		--setenv=NURA_INSIDE_UNIT=1 \
		--setenv=NURA_MIN_SIZE="$NURA_MIN_SIZE" \
		--working-directory="$NURA_ROOT" bash "$0" "$@"
fi

CHROOT="$PMB_WORK/chroot_rootfs_meizu-meizu20"

# rootfs chroot 残留旧 UI world → 只清 rootfs chroot（包缓存/native chroot 不动）。
# ⚠ 必须 sudo：chroot 内含 pmbootstrap 经 sudo 写入的 root 属主文件，用户态 rm 必
#   Permission denied（2026-10-21 首跑实锤）；pmbootstrap 同款 passwordless sudo。
if [ -e "$CHROOT/etc/apk/world" ] && grep -q '^postmarketos-ui-' "$CHROOT/etc/apk/world" 2>/dev/null; then
	echo "[i] rootfs chroot 残留旧 UI world（r87 时代 plasma）→ sudo 清除，pmbootstrap 自动重建"
	sudo rm -rf "$CHROOT"
fi

echo "[i] pmbootstrap install（ui=none / 密码 1234；~10-20 分钟）"
# ⚠ --single-partition 铁律（同 build-rootfs.sh）：裸 ext4 直出，无 GPT——
#   本机无 initramfs，内核 root=/dev/sda22 直挂 userdata，分区镜像必挂死。
# ⚠ v3 install 无 --image-size（那是 qemu 的旗标，2026-10-21 实锤）；定长化 =
#   官方默认出镜像后，宿主侧 truncate + 离线 resize2fs 一次性扩到精确尺寸。
NURA_UI=none "$PIN_PMB_WRAPPER" install --password 1234 --single-partition \
	--add python3,openssh,unudhcpd,postmarketos-usb-moded,postmarketos-usb-moded-default-profile-developer

OUT="$PMB_WORK/chroot_native/home/pmos/rootfs/meizu-meizu20.img"
[ -e "$OUT" ] || nura_die "找不到 rootfs 产物: $OUT"

# 镜像必须已脱离 loop（pmbootstrap 正常 umount；挂着就动 = 自毁）
if losetup -a 2>/dev/null | grep -F "$OUT" >/dev/null; then
	nura_die "产物仍在 loop 挂载上（losetup -a），先解除再继续"
fi
# pmbootstrap 以 root 落镜像（2026-10-21 实锤：用户态 truncate/resize2fs/debugfs -w
# 全写不动）→ 收归用户，后续手术/断言全用户态
sudo chown "$(id -u):$(id -g)" "$OUT"

# ---------- 定长化（宿主侧一次性；设备侧 grow 已 mask，此后永不 resize） ----------
CUR_BLOCKS="$(dumpe2fs -h "$OUT" 2>/dev/null | sed -n 's/^Block count: *//p')"
[ -n "$CUR_BLOCKS" ] || nura_die "读不到镜像 fs Block count（非裸 ext4?）"
TARGET_BLOCKS=$(( NURA_MIN_BYTES / 4096 ))
if [ "$CUR_BLOCKS" -gt "$TARGET_BLOCKS" ]; then
	nura_die "镜像内容(fs $(( CUR_BLOCKS * 4096 / 1048576 ))MiB)已超 $NURA_MIN_SIZE——拒绝收缩，调大 NURA_MIN_SIZE 重跑"
fi
echo "[i] 定长化：fs $(( CUR_BLOCKS * 4096 / 1048576 ))MiB → $NURA_MIN_SIZE（truncate + resize2fs 离线）"
truncate -s "$NURA_MIN_BYTES" "$OUT"
resize2fs "$OUT" "$NURA_MIN_SIZE" >/dev/null
NEW_BLOCKS="$(dumpe2fs -h "$OUT" 2>/dev/null | sed -n 's/^Block count: *//p')"
[ "$NEW_BLOCKS" -eq "$TARGET_BLOCKS" ] || nura_die "resize 后 Block count $NEW_BLOCKS ≠ $TARGET_BLOCKS"

# ---------- 镜像内手术（debugfs，宿主侧，零挂载） ----------
echo "[i] 手术① mask meizu-grow-rootfs.service（+摘 multi-user.wants 自启）"
debugfs -w -R "rm /etc/systemd/system/multi-user.target.wants/meizu-grow-rootfs.service" "$OUT" >/dev/null 2>&1 || \
	echo "    （wants 原本就无此链接，跳过 rm）"
debugfs -w -R "symlink /etc/systemd/system/meizu-grow-rootfs.service /dev/null" "$OUT" >/dev/null

echo "[i] 手术② 写 /etc/nura-min 溯源标记"
MARKER="$(mktemp)"
{
	echo "nura-min rootfs (special-purpose, FIXED-SIZE — never grows into userdata tail)"
	echo "built: $(date +%F)"
	echo "kernel: linux-meizu-meizu20 r${REL_LINUX_PKGREL} (modules 7.3.0, expect uname: #92-meizu-meizu20)"
	echo "device: device-meizu-meizu20 1-r${REL_DEVICE_PKGREL}   firmware: 1-r${REL_FW_PKGREL}"
	echo "image: ${NURA_MIN_SIZE} raw ext4, root=/dev/sda22, meizu-grow-rootfs MASKED"
	echo "purpose: iOS userdata tail log ring co-existence (SWEETLOG @ partition tail, last 4MiB+4KiB)"
} > "$MARKER"
debugfs -w -R "write $MARKER /etc/nura-min" "$OUT" >/dev/null
debugfs -w -R "sif /etc/nura-min mode 0100644" "$OUT" >/dev/null
rm -f "$MARKER"

# ---------- 验收断言（失败即死，不出件） ----------
echo "[i] 验收断言…"

SZ="$(stat -c%s "$OUT")"
[ "$SZ" -eq "$NURA_MIN_BYTES" ] || nura_die "镜像尺寸 $SZ ≠ 定长 $NURA_MIN_BYTES"

# 1) fstab：形状 = 注释头 + UUID defaults 0 0；禁 growfs/resize/x-systemd 扩容语义
FSTAB="$(debugfs -R "cat /etc/fstab" "$OUT" 2>/dev/null)"
echo "$FSTAB" | grep -qE 'growfs|resize|x-systemd\.grow|repart' \
	&& nura_die "fstab 出现扩容语义：$FSTAB"
echo "$FSTAB" | grep -qE '^UUID=[0-9a-f-]+ / ext4 defaults 0 0$' \
	|| nura_die "fstab 形状非预期：$FSTAB"

# 2) grow 单元：mask 在位 + wants 无自启（debugfs 出错也 exit 0，断言必须吃输出）
debugfs -R "stat /etc/systemd/system/meizu-grow-rootfs.service" "$OUT" 2>/dev/null \
	| grep -q 'Type: symlink' || nura_die "grow mask 缺失（非 symlink）"
debugfs -R "stat /etc/systemd/system/meizu-grow-rootfs.service" "$OUT" 2>/dev/null \
	| grep -q 'Fast link dest: "/dev/null"' || nura_die "grow mask 指向非 /dev/null"
debugfs -R "ls -l /etc/systemd/system/multi-user.target.wants" "$OUT" 2>/dev/null \
	| grep -q 'meizu-grow-rootfs' && nura_die "multi-user.wants 仍有 grow 自启链接"

# 3) fsck 全绿（-f 强查、-n 只读）
fsck.ext4 -fn "$OUT" >/dev/null || nura_die "fsck 报错（见上）"

# 4) 包版本钉 + 内容清单（installed db）
DB="$(mktemp)"
debugfs -R "cat /lib/apk/db/installed" "$OUT" 2>/dev/null > "$DB"
python3 - "$DB" "$REL_LINUX_PKGREL" "$REL_DEVICE_PKGREL" "$REL_FW_PKGREL" <<'PYEOF' || nura_die "包版本/内容断言失败（详见上）"
import re, sys
db = open(sys.argv[1]).read()
rl, rd, rf = sys.argv[2:5]
entries = {}
for e in re.split(r'\nP:', '\n'+db):
    lines = e.splitlines()
    if lines and lines[0]:
        entries[lines[0].strip()] = lines
def ver(p):
    for l in entries.get(p, []):
        if l.startswith('V:'): return l[2:]
    return None
fails = []
if ver('linux-meizu-meizu20') != f'7.3.0_rc6-r{rl}': fails.append(f"linux={ver('linux-meizu-meizu20')}")
if ver('device-meizu-meizu20') != f'1-r{rd}': fails.append(f"device={ver('device-meizu-meizu20')}")
if ver('firmware-meizu-meizu20') != f'1-r{rf}': fails.append(f"firmware={ver('firmware-meizu-meizu20')}")
for need in ('python3','openssh-server','openssh-client-default','postmarketos-usb-moded',
             'postmarketos-usb-moded-default-profile-developer','unudhcpd','usb-signaller','busybox'):
    if need not in entries: fails.append(f'缺包 {need}')
for bad in (p for p in entries if p.startswith('postmarketos-ui-')):
    fails.append(f'混入 UI 包 {bad}')
print('\n'.join(fails) if fails else f'[ok] 包钉 linux={ver("linux-meizu-meizu20")} device={ver("device-meizu-meizu20")} fw={ver("firmware-meizu-meizu20")}, UI 零混入')
sys.exit(1 if fails else 0)
PYEOF
rm -f "$DB"

# 5) 关键文件在位：模块目录 / devshell(:23) / USB 栈 / 登录壳（ls -l 输出行尾=名字）
debugfs -R "ls -l /usr/lib/modules" "$OUT" 2>/dev/null | grep -q ' 7\.3\.0$' \
	|| nura_die "缺 /usr/lib/modules/7.3.0（与在跑内核 release 不符）"
debugfs -R "ls -l /usr/lib/systemd/system" "$OUT" 2>/dev/null | grep -q ' devshell\.service$' \
	|| nura_die "缺 devshell.service（:23 通道）"
debugfs -R "ls -l /etc/systemd/system/multi-user.target.wants" "$OUT" 2>/dev/null | grep -q ' devshell\.service$' \
	|| nura_die "devshell 未被 preset 自启"
debugfs -R "cat /usr/lib/usb-signaller/usb-signaller.toml" "$OUT" 2>/dev/null | grep -q 'developer_mode' \
	|| nura_die "缺 developer profile（usb 默认 profile 非 developer_mode）"
debugfs -R "ls -l /etc/systemd/system/multi-user.target.wants" "$OUT" 2>/dev/null | grep -q 'unudhcpd@usb0\.service$' \
	|| nura_die "unudhcpd@usb0 未自启（USB 网络腿断）"
debugfs -R "ls -l /usr/bin" "$OUT" 2>/dev/null | grep -qE ' python3($| ->)' \
	|| nura_die "缺 python3"

echo "[✓] 断言全绿：定长 $NURA_MIN_SIZE / fstab 净 / grow 已 mask / 模块 7.3.0 / devshell:23 / USB 栈 developer / python3"

# ---------- 出件 ----------
REL_TAG="r${REL_LINUX_PKGREL}"
DEST="$NURA_ROOT/artifacts/meizu-meizu20-nura-min-${REL_TAG}-${NURA_MIN_SIZE}.img"
cp "$OUT" "$DEST"
( cd "$NURA_ROOT/artifacts" && sha256sum "$(basename "$DEST")" ) | tee "$DEST.sha256"
echo "[✓] 交付: $DEST（$(du -h "$DEST" | cut -f1) 实占；定长 $(du --apparent-size -h "$DEST" | cut -f1)）"

if command -v img2simg >/dev/null 2>&1; then
	img2simg "$DEST" "${DEST%.img}.simg"
	( cd "$NURA_ROOT/artifacts" && sha256sum "$(basename "${DEST%.img}.simg")" ) | tee "${DEST%.img}.simg.sha256"
	echo "[✓] sparse 件: ${DEST%.img}.simg（fastboot flash userdata 直刷；只写镜像自身范围）"
else
	echo "[i] 宿主无 img2simg：iOS 侧自转 sparse（其协议内已含）"
fi

echo "----------------------------------------------------------------------
[交付协议（iOS 侧执行）] ①尾部预写标记块（环头位+末块）→ ②刷 iOS 根（头部16G sparse）
→ ③fastboot flash userdata <本镜像 sparse> → ④起本镜像，devsh dd 读回标记原样=通过。
[nura 侧取环] devsh 'dd if=/dev/sda22 bs=512 skip=\$((972326040-8200)) count=8200' 尾部 4MiB+4KiB。
[日常登录] devsh（busybox nc :23，root 直达）；面板 tty1 getty user/1234；openssh 备腿。"
