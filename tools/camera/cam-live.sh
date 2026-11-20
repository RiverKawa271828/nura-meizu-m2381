#!/bin/sh
# cam-live.sh [idx] — start a stream, sample csiphy2 registers mid-stream.
# Registers (base 0xace8000, common block +0x1000):
#   0x1014 CTRL5 lane-enable (expect 0xF7 w/ lanes 0-3), 0x1018 CTRL6 PWRDN_B,
#   0x101C CTRL7, 0x10B0.. status block (common_status_offset 0xb0)
IDX=${1:-7}
M="media-ctl -d /dev/media0"
ENT=$($M -p 2>/dev/null | grep -o "s5k3p9sx [0-9]-002d" | head -1)
SD=$($M -p 2>/dev/null | grep -A3 "$ENT" | grep "device node" | awk '{print $4}')
VID=$($M -p 2>/dev/null | grep -A3 "msm_vfe0_video0 " | grep "device node" | awk '{print $4}')
{
$M -V "'$ENT':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null
$M -V "'msm_csiphy2':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null
$M -V "'msm_csiphy2':1[fmt:SRGGB10_1X10/4640x3488]" >/dev/null
$M -V "'msm_csid0':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null
$M -V "'msm_csid0':1[fmt:SRGGB10_1X10/4640x3488]" >/dev/null
$M -V "'msm_vfe0_rdi0':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null
v4l2-ctl -d $SD --set-ctrl=link_frequency=$IDX
v4l2-ctl -d $VID --set-fmt-video=width=4640,height=3488,pixelformat=pRAA >/dev/null
echo "== stream up $(date +%T)"
timeout -s KILL 18 v4l2-ctl -d $VID --stream-mmap=4 --stream-count=1 >/dev/null 2>&1 &
SLEEP_PID=$!
sleep 4
echo "== mid-stream regs (idx=$IDX)"
for R in 0x1014 0x1018 0x101c 0x10b0 0x10b4 0x10b8 0x10bc 0x10c0 0x10c4 0x10c8; do
	A=$((0xace8000 + R))
	V=$(dd if=/dev/mem bs=1 skip=$A count=4 2>/dev/null | od -An -tx1 | tr -d ' \n')
	echo "  $R = $V"
done
wait $SLEEP_PID
echo "== done $(date +%T)"
} > /root/sweep/live-idx$IDX.log 2>&1
