#!/bin/sh
# cam-shot-front.sh [count] — GD2 front-camera capture (one command).
#
# Companion to cam-shot.sh (3P9 wide). Same contract: caller wraps in
#   systemd-run --unit=camshotf-$$ --collect /root/bin/cam-shot-front.sh <n>
# never kill a D-state stream process; timeout -s KILL inside is the only gate.
# Discipline: space runs ≥10s; no burst+instant-reshot (csiphy power-on
# async_synchronize_full_domain D-hang, 2026-11-20 round-112).
#
# Route = csiphy4 → csid0 → vfe0_rdi0 (stock csiphy-sd-index 4; csid/rdi0
# proven-good route shape from the 3P9 chain, torn-down first — one camera
# at a time on this driver). Mode = binned 3264x2448 (g1, 30fps, bin truth
# = HW-binned Gr-first Bayer → SGRBG10 requested; real line order validated
# on first frame). Stride authority = kernel-reported bytesperline.
#
# fmt authority = the sensor driver's stored code after clamping (read back
# from the pad), ALL pads + the video node follow it — hardcoded pad/video
# mismatch = silent -EPIPE in video_check_format (round-114 lesson, same as
# cam-shot.sh: pRAA video vs SGBRG10 pads killed every r113-era streamon).
N=${1:-1}
TO=${2:-30}
W=3264
H=2448
D=/root/sweep
mkdir -p $D
RUN=$(date +%H%M%S)
OUT=$D/front-$RUN.raw
LOG=$D/front-$RUN.log
M="media-ctl -d /dev/media0"
ENT=$($M -p 2>/dev/null | grep -o "s5kgd2sp03 [0-9]-00[0-9a-f]*" | head -1)
SD=$($M -p 2>/dev/null | grep -A3 "$ENT" | grep "device node" | awk '{print $4}')
VID=$($M -p 2>/dev/null | grep -A3 "msm_vfe0_video0 " | grep "device node" | awk '{print $4}')
{
echo "== cam-shot-front n=$N start $(date +%T) sd=$SD vid=$VID ent=$ENT"
# FULL tear (see cam-shot.sh): libcamera boot reconfig fights scripts.
for P in 0 1 2 3 4; do
	for C in 0 1 2 3 4; do
		$M -l "'msm_csiphy$P':1 -> 'msm_csid$C':0[0]" >/dev/null 2>&1
		$M -l "'msm_csid$C':1 -> 'msm_vfe0_rdi$C':0[0]" >/dev/null 2>&1
	done
done
$M -l "'msm_csiphy4':1 -> 'msm_csid0':0[1]" >/dev/null 2>&1 && echo ok-link-phy4-csid0 || echo LINK-BUSY-OR-FAIL-phy4-csid0
$M -l "'msm_csid0':1 -> 'msm_vfe0_rdi0':0[1]" >/dev/null 2>&1 && echo ok-link-csid0-rdi0 || echo LINK-BUSY-OR-FAIL-csid0-rdi0
$M -V "'$ENT':0[fmt:SGRBG10_1X10/${W}x${H}]" >/dev/null && echo ok-sensor
# read-back anchors on the entity HEADER line — a bare name grep also matches
# other entities' link lines and grabs the wrong pad (same lesson as cam-shot).
CODE=$($M -p 2>/dev/null | grep -A4 "entity.*$ENT " | grep "stream:0" | head -1 | grep -o "fmt:[A-Z0-9_]*" | cut -d: -f2)
case "$CODE" in
	SRGGB10_1X10) PFMT=pRAA ;;
	SGBRG10_1X10) PFMT=pGAA ;;
	SGRBG10_1X10) PFMT=pgAA ;;
	SBGGR10_1X10) PFMT=pBAA ;;
	*) CODE=SGRBG10_1X10; PFMT=pgAA ;;
esac
echo "sensor-code=$CODE video-pixelformat=$PFMT"
$M -V "'msm_csiphy4':0[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csiphy0
$M -V "'msm_csiphy4':1[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csiphy1
$M -V "'msm_csid0':0[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csid0
$M -V "'msm_csid0':1[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-csid1
$M -V "'msm_vfe0_rdi0':0[fmt:$CODE/${W}x${H}]" >/dev/null && echo ok-rdi0
v4l2-ctl -d $VID --set-fmt-video=width=${W},height=${H},pixelformat=$PFMT >/dev/null && echo ok-vfmt
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
echo done > $D/front-$RUN.done
