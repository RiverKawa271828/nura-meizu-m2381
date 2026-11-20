#!/bin/sh
# cam-recover.sh — camera chain recovery after boot (idempotent, safe to re-run).
#
# Root cause (2026-11-20, round-110 boot): r69 meizu-touch-load.sh closes the
# drivers_autoprobe window while geni_i2c/98c000 (hub_3) is being bound; the
# pm8008 mfd regulator cells (pm8008-regulator.*.auto) created in/around that
# window are never probed -> no camera rails -> s5k3p9sx deferred forever.
# Fix = force-bind the cells, then force-bind the sensor (deferred probes do
# NOT auto-retry on regulator_register, manual bind is the reliable retrigger).
for C in /sys/bus/platform/devices/pm8008-regulator.*.auto; do
	[ -e "$C/driver" ] || \
		echo "$(basename "$C")" > /sys/bus/platform/drivers/qcom-pm8008-regulator/bind 2>/dev/null
done
sleep 1
[ -e /sys/bus/i2c/devices/0-002d/driver ] || \
	echo 0-002d > /sys/bus/i2c/drivers/s5k3p9sx/bind 2>/dev/null
sleep 1
echo "pm8008 rails: $(cat /sys/class/regulator/*/name | grep -c pm8008)"
echo "sensor driver: $(readlink /sys/bus/i2c/devices/0-002d/driver)"
