#!/usr/bin/env bash
# readback.sh — 刷写后分区级读回对 sha（生成在设备 root shell 里跑的命令）
#
# 用法: readback.sh <boot_b_sha> <recovery_a_sha>
# 本脚本不直接连设备（通道形态多变），打印可在设备侧 root shell（nc :23
# devshell / ssh+sudo）原样粘贴的命令，dd 分区级读回 | sha256sum 对拍。
# 铁律：刷写时长不算证据，只看读回。
set -euo pipefail
[ $# = 2 ] || { echo "用法: readback.sh <boot_b_sha256> <recovery_a_sha256>"; exit 2; }
B="$1"; R="$2"
cat <<EOF
# —— 在设备 root shell 执行（busybox ash 兼容）——
# 分区名 → 设备节点映射每次启动可能漂移，先探明再 dd：
ls -l /dev/disk/by-partlabel/boot_b /dev/disk/by-partlabel/recovery_a

BB=\$(readlink -f /dev/disk/by-partlabel/boot_b)
RA=\$(readlink -f /dev/disk/by-partlabel/recovery_a)
SZ=\$(blockdev --getsize64 \$BB)

dd if=\$BB bs=4096 | sha256sum
# 期望前 8 位: ${B:0:8}

dd if=\$RA bs=4096 | sha256sum
# 期望前 8 位: ${R:0:8}

# 坑：ssh user 身份读 /dev 会得空 sha（权限）——必须 root shell。
EOF
echo "[i] 对上了 = 刷写成功；对不上 = 重刷该分区（FLASHING.md §3.6）"
