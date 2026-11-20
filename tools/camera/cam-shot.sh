#!/bin/sh
# cam-shot.sh [idx] [count] — 3P9 wide-camera reference capture (one command).
#
# Contract (round-108/112 discipline): caller wraps in
#   systemd-run --unit=camshot-$$ --collect /root/bin/cam-shot.sh <idx> <count>
# never kill a D-state stream process; timeout -s KILL inside is the only gate.
#
# Proven route = csid0/vfe0_rdi0 (round-111 first light; sweep2 csid2 route
# delivered nothing). Idempotent: tears all known routes, enables csid0, then
# sets the sensor fmt FIRST and READS BACK the code the driver actually stored
# — every other pad + the video node follow that read-back. This is the
# round-114 lesson: the sensor driver clamps the mbus code to its own const
# (r104 = SRGGB10, r107+ compliance = SGBRG10) and camss-video's
# video_check_format compares the video pixelformat against the propagated
# RDI source pad SILENTLY (-EPIPE, zero kernel print). A script that hardcodes
# pads to one code and the video node to another fails STREAMON with
# "Broken pipe" and nothing in dmesg (round-113/114 -32 wall root cause).
#
# Stride authority: read bytesperline/sizeimage back from the video node —
# VFE RDI pads rows to 16B alignment: 4640px -> 5808B pitch (8B pad tail per
# row, no information). Decoders that assume tight 5800 pack = torn frames
# (round-111/112 verdict; decode-raw10.py is stride-aware).
IDX=${1:-7}
N=${2:-1}
TO=${3:-30}
W=4640
H=3488
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
# FULL tear: boot-time libcamera reconfigures the graph for ITS chosen
# camera (two-camera era) — every csiphy->csid and csid->rdi link must go
# before we enable exactly one chain, else media_pipeline_start walks an
# ambiguous graph (round-113 loud -EPIPE signature).
for P in 0 1 2 3 4; do
	for C in 0 1 2 3 4; do
		$M -l "'msm_csiphy$P':1 -> 'msm_csid$C':0[0]" >/dev/null 2>&1
		$M -l "'msm_csid$C':1 -> 'msm_vfe0_rdi$C':0[0]" >/dev/null 2>&1
	done
done
$M -l "'msm_csiphy2':1 -> 'msm_csid0':0[1]" >/dev/null 2>&1 && echo ok-link-phy-csid || echo LINK-BUSY-OR-FAIL-phy-csid0
$M -l "'msm_csid0':1 -> 'msm_vfe0_rdi0':0[1]" >/dev/null 2>&1 && echo ok-link-csid-rdi || echo LINK-BUSY-OR-FAIL-csid-rdi0
# fmt authority = whatever the sensor driver actually stores after clamping.
# Read-back anchors on the entity HEADER line ("entity N: name") — a bare name
# grep also matches other entities' link lines and grabs the wrong pad.
$M -V "'$ENT':0[fmt:SGBRG10_1X10/${W}x${H}]" >/dev/null && echo ok-sensor
CODE=$($M -p 2>/dev/null | grep -A4 "entity.*$ENT " | grep "stream:0" | head -1 | grep -o "fmt:[A-Z0-9_]*" | cut -d: -f2)
case "$CODE" in
	SRGGB10_1X10) PFMT=pRAA ;;
	SGBRG10_1X10) PFMT=pGAA ;;
	SGRBG10_1X10) PFMT=pgAA ;;
	SBGGR10_1X10) PFMT=pBAA ;;
	*) CODE=SRGGB10_1X10; PFMT=pRAA ;;
esac
echo "sensor-code=$CODE video-pixelformat=$PFMT"
$M -V "'msm_csiphy2':0[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csiphy0
$M -V "'msm_csiphy2':1[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csiphy1
$M -V "'msm_csid0':0[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csid0
$M -V "'msm_csid0':1[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csid1
$M -V "'msm_vfe0_rdi0':0[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-rdi0
v4l2-ctl -d $SD --set-ctrl=link_frequency=$IDX >/dev/null && echo ok-lfset
v4l2-ctl -d $VID --set-fmt-video=width=$W,height=$H,pixelformat=$PFMT >/dev/null && echo ok-vfmt
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
# both blocked by the wedged session — setsid sysrq-b is the only exit).
# Discipline: single-shot spacing >= 10s; never re-shoot right after a burst.
