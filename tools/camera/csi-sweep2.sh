#!/bin/sh
# csi-sweep2.sh <idx> [to] [cid] — sweep via csid<cid>/vfe0_rdi<cid> route.
# Default csid0 route showed zero packets with PHY streaming (2026-11-20);
# same-number route csiphy2->csid2 tests the PHY_n<->CSID_n hypothesis.
IDX=$1
TO=${2:-15}
CID=${3:-2}
D=/root/sweep
mkdir -p $D
LOG=$D/s2-idx$IDX.log
M="media-ctl -d /dev/media0"
ENT=$($M -p 2>/dev/null | grep -o "s5k3p9sx [0-9]-002d" | head -1)
SD=$($M -p 2>/dev/null | grep -A3 "$ENT" | grep "device node" | awk '{print $4}')
VID=$($M -p 2>/dev/null | grep -A3 "msm_vfe0_video$CID " | grep "device node" | awk '{print $4}')
{
echo "== s2 idx=$IDX cid=$CID to=$TO start $(date +%T) sd=$SD vid=$VID"
$M -l "'msm_csiphy2':1 -> 'msm_csid0':0[0]" && echo ok-unlink-csid0
$M -l "'msm_csid0':1 -> 'msm_vfe0_rdi0':0[0]" && echo ok-unlink-rdi0
$M -l "'msm_csiphy2':1 -> 'msm_csid$CID':0[1]" && echo ok-link-phy-csid
$M -l "'msm_csid$CID':1 -> 'msm_vfe0_rdi$CID':0[1]" && echo ok-link-csid-rdi
$M -V "'$ENT':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-sensor
$M -V "'msm_csiphy2':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csiphy0
$M -V "'msm_csiphy2':1[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csiphy1
$M -V "'msm_csid$CID':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csid0
$M -V "'msm_csid$CID':1[fmt:SRGGB10_1X10/4640x3488]" && echo ok-csid1
$M -V "'msm_vfe0_rdi$CID':0[fmt:SRGGB10_1X10/4640x3488]" && echo ok-rdi0
v4l2-ctl -d $SD --set-ctrl=link_frequency=$IDX && echo ok-lfset
v4l2-ctl -d $VID --set-fmt-video=width=4640,height=3488,pixelformat=pRAA && echo ok-vfmt
sync
echo "== streamon $(date +%T)"
timeout -s KILL $TO v4l2-ctl -d $VID --stream-mmap=4 --stream-count=1 --stream-to=$D/f2-$IDX.raw
echo "== rc=$? $(date +%T)"
ls -la $D/f2-$IDX.raw 2>/dev/null
dmesg | tail -3
} > $LOG 2>&1
echo done > $D/s2-idx$IDX.done
