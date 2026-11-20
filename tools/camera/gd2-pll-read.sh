#!/bin/sh
# GD2 PLL/MIPI 寄存器读回（一百一十五审计定路径：0x6028←0x4000 页选后直接读）
# 用法: gd2-pll-read.sh [i2c_bus]  （默认自动发现 3-0010 客户端所在总线）
# ⚠ 须在流中执行（pm autosuspend 会断 CCI 供电窗）；cam-shot-front.sh 后台跑中时用。
BUS="${1:-}"
ADDR=0x10   # GD2 7-bit（bin slaveAddr 0x20/8bit）

if [ -z "$BUS" ]; then
	for d in /sys/bus/i2c/devices/*-0010; do
		[ -e "$d" ] && BUS=${d##*/devices/} && BUS=${BUS%-0010} && break
	done
	[ -z "$BUS" ] && { echo "no i2c client 0x10 found"; exit 1; }
fi
echo "bus=$BUS addr=$ADDR"

# 页选: 0x6028 <- 0x4000 (CIS/PLL 页)
i2ctransfer -f -y "$BUS" w4@$ADDR 0x60 0x28 0x40 0x00 || { echo "page select failed"; exit 1; }

rdreg() {  # rdreg <hi> <lo>  -> 16-bit BE 值
	v=$(i2ctransfer -f -y "$BUS" w2@$ADDR $1 $2 r2@$ADDR 2>/dev/null)
	echo "0x$1$2 <- 0x$v"
}

echo "-- PLL block (bin g0 真值参照: 0300=0x0007 0302=0x0001 0304=0x0002 0306=0x0091"
echo "   0308=0x000b 030a=0x0001 030c=0x0000 030e=0x0002 0310=0x00bc 0312=0x0001)"
rdreg 03 00
rdreg 03 02
rdreg 03 04
rdreg 03 06
rdreg 03 08
rdreg 03 0a
rdreg 03 0c
rdreg 03 0e
rdreg 03 10
rdreg 03 12
echo "-- frame timing (bin g0: 0340=0x1408/0342=0x5070；g1 bin: 0340=0x0b74/0342=0x4650)"
rdreg 03 40
rdreg 03 42
echo "-- mipi/lane (bin: 0114=0x0300 0116=0x3000)"
rdreg 01 14
rdreg 01 16
echo "-- mclk encoding (bin: 0136=0x1300) / stream (0x0100, 流中应=0x0001)"
rdreg 01 36
rdreg 01 00
echo "-- exposure/gain (0x0202/0x0204)"
rdreg 02 02
rdreg 02 04
