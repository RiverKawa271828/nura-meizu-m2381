#!/bin/sh
# csi-sweep.sh <idx> [to] — one CSI link-freq sweep attempt on Meizu 20 3P9.
#
# Contract (round-108 discipline):
#   - caller wraps in systemd-run --unit=csi-idx<N> --collect (per-attempt isolation)
#   - never kill a D-state stream process; if the unit doesn't finish, capture
#     /proc/<pid>/stack from the host side, then recover (see cam-recover.sh)
#   - link_freq ctrl is read by csiphy at streamon (camss-csiphy.c:275), so
#     set-ctrl immediately before streamon is what the PHY uses that attempt
#
# Evidence: /root/sweep/idx<N>.log (+ .done marker; f<N>.raw size = packets judgement)
IDX=$1
TO=${2:-15}
D=/root/sweep
mkdir -p $D
LOG=$D/idx$IDX.log
M="media-ctl -d /dev/media0"
ENT=$($M -p 2>/dev/null | grep -o "s5k3p9sx [0-9]-002d" | head -1)
SD=$($M -p 2>/dev/null | grep -A3 "$ENT" | grep "device node" | awk '{print $4}')
VID=$($M -p 2>/dev/null | grep -A3 "msm_vfe0_video0 " | grep "device node" | awk '{print $4}')
{
echo "== idx=$IDX to=$TO start $(date +%T) sd=$SD vid=$VID ent=$ENT"
# links: sensor->csiphy2 is ENABLED,IMMUTABLE; csid/vfe hops are OFF by default.
# Idempotent: tear down ALL known routes first (earlier experiments leave links on).
for C in 0 1 2 3 4; do
	$M -l "'msm_csiphy2':1 -> 'msm_csid$C':0[0]" >/dev/null 2>&1
	$M -l "'msm_csid$C':1 -> 'msm_vfe0_rdi$C':0[0]" >/dev/null 2>&1
done
$M -l "'msm_csiphy2':1 -> 'msm_csid0':0[1]" && echo ok-link-phy-csid
$M -l "'msm_csid0':1 -> 'msm_vfe0_rdi0':0[1]" && echo ok-link-csid-rdi
$M -V "'$ENT':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-sensor
$M -V "'msm_csiphy2':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csiphy0
$M -V "'msm_csiphy2':1[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csiphy1
$M -V "'msm_csid0':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csid0
$M -V "'msm_csid0':1[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csid1
$M -V "'msm_vfe0_rdi0':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-rdi0
v4l2-ctl -d $SD --set-ctrl=link_frequency=$IDX && echo ok-lfset
v4l2-ctl -d $SD --get-ctrl=link_frequency
v4l2-ctl -d $VID --set-fmt-video=width=4640,height=3488,pixelformat=pRAA && echo ok-vfmt
sync
echo "== streamon $(date +%T)"
timeout -s KILL $TO v4l2-ctl -d $VID --stream-mmap=4 --stream-count=1 --stream-to=$D/f$IDX.raw
echo "== rc=$? $(date +%T)"
ls -la $D/f$IDX.raw 2>/dev/null
dmesg | tail -4
} > $LOG 2>&1
echo done > $D/idx$IDX.done
