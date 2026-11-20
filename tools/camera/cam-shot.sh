#!/bin/sh
# cam-shot.sh [idx] [count] — 3P9 wide-camera reference capture (one command).
#
# Contract (round-108/112 discipline): caller wraps in
#   systemd-run --unit=camshot-$$ --collect /root/bin/cam-shot.sh <idx> <count>
# never kill a D-state stream process; timeout -s KILL inside is the only gate.
#
# Proven route = csid0/vfe0_rdi0 (round-111 first light; sweep2 csid2 route
# delivered nothing). Idempotent: tears all known routes, enables csid0, sets
# 4640x3488 SRGGB10 across the chain, then reads back the video node's real
# bytesperline/sizeimage (stride authority — round-112: V4L2 reports 5808
# = HW RDI stride, rows carry 8B pad tail; 5800-stride decoders are the bug).
IDX=${1:-7}
N=${2:-1}
TO=${3:-30}
D=/root/sweep
mkdir -p $D
RUN=$(date +%H%M%S)
OUT=$D/shot-$RUN.raw
LOG=$D/shot-$RUN.log
M="media-ctl -d /dev/media0"
ENT=$($M -p 2>/dev/null | grep -o "s5k3p9sx [0-9]-002d" | head -1)
SD=$($M -p 2>/dev/null | grep -A3 "$ENT" | grep "device node" | awk '{print $4}')
VID=$($M -p 2>/dev/null | grep -A3 "msm_vfe0_video0 " | grep "device node" | awk '{print $4}')
{
echo "== cam-shot idx=$IDX n=$N start $(date +%T) sd=$SD vid=$VID ent=$ENT"
for C in 0 1 2 3 4; do
	$M -l "'msm_csiphy2':1 -> 'msm_csid$C':0[0]" >/dev/null 2>&1
	$M -l "'msm_csid$C':1 -> 'msm_vfe0_rdi$C':0[0]" >/dev/null 2>&1
done
$M -l "'msm_csiphy2':1 -> 'msm_csid0':0[1]" >/dev/null 2>&1 && echo ok-link-phy-csid || echo LINK-BUSY-OR-FAIL-phy-csid0
$M -l "'msm_csid0':1 -> 'msm_vfe0_rdi0':0[1]" >/dev/null 2>&1 && echo ok-link-csid-rdi || echo LINK-BUSY-OR-FAIL-csid-rdi0
$M -V "'$ENT':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null && echo ok-sensor
$M -V "'msm_csiphy2':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null && echo ok-csiphy0
$M -V "'msm_csiphy2':1[fmt:SRGGB10_1X10/4640x3488]" >/dev/null && echo ok-csiphy1
$M -V "'msm_csid0':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null && echo ok-csid0
$M -V "'msm_csid0':1[fmt:SRGGB10_1X10/4640x3488]" >/dev/null && echo ok-csid1
$M -V "'msm_vfe0_rdi0':0[fmt:SRGGB10_1X10/4640x3488]" >/dev/null && echo ok-rdi0
v4l2-ctl -d $SD --set-ctrl=link_frequency=$IDX >/dev/null && echo ok-lfset
v4l2-ctl -d $VID --set-fmt-video=width=4640,height=3488,pixelformat=pRAA >/dev/null && echo ok-vfmt
# stride authority: what the kernel reports is what the write master programs
GET=$(v4l2-ctl -d $VID --get-fmt-video)
BPL=$(echo "$GET" | grep "Bytes per Line" | tr -dc '0-9')
SZI=$(echo "$GET" | grep "Size Image" | tr -dc '0-9')
echo "bpl=$BPL sizeimage=$SZI"
sync
echo "== streamon x$N $(date +%T)"
timeout -s KILL $TO v4l2-ctl -d $VID --stream-mmap=4 --stream-count=$N --stream-to=$OUT
echo "== rc=$? $(date +%T) bytes=$(ls -la $OUT 2>/dev/null | awk '{print $5}')"
dmesg | tail -3
} > $LOG 2>&1
echo done > $D/shot-$RUN.done
# ⚠ back-to-back invocations after a long-exposure burst wedge csiphy power-on
# (async_synchronize_full_domain D-hang, 2026-11-20 round-112; reboot -f/sysrq-b
# needed). Space runs ≥10s and avoid burst+instant-reshot.
