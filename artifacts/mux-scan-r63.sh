#!/bin/sh
# mux-scan-r63 — VA DMIC MUX0 逐值(item1-4=DMIC0-3) 录音对拍 + micb 判据
# 用法（设备 root shell）: sh /tmp/mux-scan-r63.sh
# 判读: 某值 nonzero_bytes 非零 = DMIC 物理映射实锤；全零 + micb 已上电 → 断点转 AFE/ADSP 域
C=0
echo "== micb 静态 =="
grep -E 'audio_va_micbias' /sys/kernel/debug/regulator/regulator_summary || echo "(regulator_summary 无该行)"

echo "== MUX0 逐值扫描 (48k S16_LE mono 3s) =="
for v in 1 2 3 4; do
	amixer -c $C cset name='VA DMIC MUX0' $v >/dev/null 2>&1 \
		|| { echo "item$v: cset FAIL"; continue; }
	# 录音中段采样 micb 状态
	( sleep 1.5
	  grep -E 'audio_va_micbias' /sys/kernel/debug/regulator/regulator_summary \
		> /tmp/micb.item$v.txt 2>&1 ) &
	sampler=$!
	arecord -D plughw:$C,2 -f S16_LE -r 48000 -c 1 -d 3 /tmp/mux-item$v.wav >/dev/null 2>&1
	wait $sampler 2>/dev/null
	nz=$(tr -d '\000' < /tmp/mux-item$v.wav | wc -c)
	micb=$(cat /tmp/micb.item$v.txt 2>/dev/null | tr -s ' ' | cut -d' ' -f3-5)
	echo "item$v (=DMIC$((v-1))): nonzero_bytes=$nz  micb_during=[$micb]"
done
# 恢复 r39 钉值
amixer -c $C cset name='VA DMIC MUX0' 1 >/dev/null 2>&1
echo "== 扫描毕（已恢复 MUX0=DMIC0）=="
