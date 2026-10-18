#!/usr/bin/env bash
# upgrade.sh — 原地升级双腿脚本化（apk 腿 + ESP 腿；不刷 userdata，数据全保留）
#
# 用法:
#   upgrade.sh --i-am-present [--apk FILE]... [--esp IMG] [--skip-apk] [--skip-esp]
#              [--host IP]
# 默认件 = config.sh 现役钉（REL_ESP_IMG + APK_DIR 内最新三包）。
# 流程 = docs/UPGRADE.md 两步的首验路径固化（2026-10-14 r88/v68 设备日同款）：
#   apk 腿: devpush → 设备侧 sha256 对拍 → apk add（主包+子包同装）
#   ESP 腿: 软进 fastboot → fastboot flash recovery_a → fastboot reboot
#   验收:   uname -v = #N(pkgrel+1) + recovery_a dd 读回对 sha
#
# 红线（继承 AGENTS / FLASHING.md §8）:
#   - 刷写必须 --i-am-present（用户在场，禁令不改）
#   - 只碰 recovery_a；boot_b 仅当 Release 说明标注「Mu 更新」才手动刷（本脚本不刷）
#   - 两腿之间不重启；中断了 = 补完另一条腿再重启
#   - 刷写时长不算证据：只认读回 sha 与 uname
#   - fastboot 单通道：其它线不得并行刷写（10-12 竞争刷写事故律）
set -euo pipefail
NURA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$NURA_ROOT/config.sh"

# ---- 沙箱守卫（pmbootstrap-meizu.sh 同款三坑；devsh SO_BINDTODEVICE 须宿主）----
# 与 build 脚本守卫的差异：本脚本在场交互盯进度，用 --pipe 把单元 stdio 接回调用方
# （build 类进 journal 无妨，这里要实时可见）。
if [ -z "${NURA_INSIDE_UNIT:-}" ]; then
	echo "[i] 经 systemd-run 在宿主执行"
	setenv_args=(--setenv=NURA_INSIDE_UNIT=1)
	for v in NURA_WORK NURA_APK_DIR NURA_LINUX_DIR NURA_PMAPORTS_DIR NURA_PMB_WORK; do
		[ -n "${!v:-}" ] && setenv_args+=(--setenv="$v=${!v}")
	done
	exec systemd-run --user --pipe --collect --quiet \
		--unit="pmx-nura-upgrade-$(date +%H%M%S)" \
		"${setenv_args[@]}" \
		--working-directory="$NURA_ROOT" bash "$0" "$@"
fi

die() { echo "FATAL: $*" >&2; exit 1; }

# ---- 参数 ----
PRESENT=0; SKIP_APK=0; SKIP_ESP=0; DEV_HOST=""
APKS=(); ESPIMG="$REL_ESP_IMG"
while [ $# -gt 0 ]; do
	case "$1" in
		--i-am-present) PRESENT=1 ;;
		--apk) shift; APKS+=("$1") ;;
		--esp) shift; ESPIMG="$1" ;;
		--skip-apk) SKIP_APK=1 ;;
		--skip-esp) SKIP_ESP=1 ;;
		--host) shift; DEV_HOST="$1" ;;
		*) echo "unknown arg: $1"; exit 2 ;;
	esac
	shift
done

# 默认 apk = 本地包仓最新三包（linux 必选；device/fw 在位则带上——10-14 首验形态）
if [ ${#APKS[@]} = 0 ] && [ "$SKIP_APK" = 0 ]; then
	LINUX_APK=$(ls -t "$APK_DIR"/$PKG_LINUX-*-r*.apk 2>/dev/null | head -1) || true
	[ -n "${LINUX_APK:-}" ] || die "APK_DIR 里找不到 $PKG_LINUX apk（--apk 指定或先 build-device.sh）"
	APKS+=("$LINUX_APK")
	for pat in "$PKG_DEVICE"-*-r*.apk "$PKG_FIRMWARE"-*-r*.apk; do
		f=$(ls -t "$APK_DIR"/$pat 2>/dev/null | head -1)
		if [ -n "$f" ]; then APKS+=("$f"); fi
	done
fi
if [ "$SKIP_APK" = 0 ] && [ ${#APKS[@]} = 0 ]; then
	die "没有 apk 可装（--apk 指定或 --skip-apk）"
fi
if [ "$SKIP_ESP" = 0 ]; then
	[ -e "$ESPIMG" ] || die "ESP 镜像不存在: $ESPIMG（--esp 指定）"
fi

# 期望 uname：linux apk 文件名里的 rNN → #(NN+1)
EXPECT_UNAME=""
for f in "${APKS[@]:-}"; do
	case "${f##*/}" in
		$PKG_LINUX-*-r*) v="${f##*-r}"; EXPECT_UNAME="#$((10#${v%.apk}+1))"; break ;;
	esac
done

# ---- 设备通道（devsh = root devshell，绑接口绕 TUN；NCM 网段重启后会漂）----
find_dev_host() {
	if [ -n "$DEV_HOST" ]; then echo "$DEV_HOST"; return; fi
	local out
	out=$(ip -o -4 addr show 2>/dev/null) || true
	case "$out" in
		*172.16.42.*) echo "172.16.42.1" ;;
		*10.42.0.*)   echo "10.42.0.1" ;;
		*) die "找不到设备 NCM 网段（172.16.42.x / 10.42.0.x 都没有）：USB 网络没起来或又漂了——ip addr 看一眼后用 --host 指定" ;;
	esac
}
dev_cmd() {
	python3 "$PIN_TOOLS/devsh.py" --host "$(find_dev_host)" "$@"
}
dev_grep() { # dev_grep <命令> <期望子串> <失败语>——校验读全量（仓规 #2：grep -q 会吃 SIGPIPE）
	local out
	out=$(dev_cmd "$1") || true
	if ! printf '%s\n' "$out" | grep "$2" >/dev/null; then
		echo "---- devshell 输出 ----"; printf '%s\n' "$out"
		die "$3"
	fi
}

echo "======== 升级计划 ========"
if [ "$SKIP_APK" = 0 ]; then for f in "${APKS[@]}"; do echo "  apk 腿 ← ${f##*/}"; done; fi
if [ "$SKIP_ESP" = 0 ]; then echo "  ESP 腿 ← $ESPIMG（recovery_a）"; fi
if [ -n "$EXPECT_UNAME" ]; then echo "  期望 uname -v = $EXPECT_UNAME"; fi
echo "=========================="

# =============================================================
# apk 腿（先装，装完不重启——两腿纪律）
# =============================================================
if [ "$SKIP_APK" = 0 ]; then
	echo "[apk 1/3] 通道探测"
	dev_grep "echo DEVSH-OK" "DEVSH-OK" "devshell 不通（设备开机进系统了吗？NCM 通了吗？）"

	echo "[apk 2/3] 推包 + 设备侧 sha 对拍"
	for f in "${APKS[@]}"; do
		b="${f##*/}"
		dev_grep "setsid sh -c 'nc -l -p 9 > /tmp/$b' >/dev/null 2>&1 & sleep 0.3; echo LISTENER-UP" \
			"LISTENER-UP" "设备侧 nc 监听没起来（$b）"
		python3 "$PIN_TOOLS/devpush.py" --host "$(find_dev_host)" "$f"
		local_sha=$(sha256sum "$f" | cut -d' ' -f1)
		dev_grep "sha256sum /tmp/$b" "$local_sha" "推送后 sha 不对（$b）——重推或换通道（scp）"
		echo "  ✓ $b（sha ${local_sha:0:8}）"
	done

	echo "[apk 3/3] apk add（主包+子包同装；公钥已烤 rootfs，直接验签）"
	pkgs=""
	for f in "${APKS[@]}"; do pkgs="$pkgs /tmp/${f##*/}"; done
	dev_cmd "apk add$pkgs" || die "apk add 失败——看输出；修复后重跑（别重启，先补完这腿）"
	echo "  ✓ apk 腿完成（先别重启）"
fi

# =============================================================
# ESP 腿（刷写 = 用户在场门禁）
# =============================================================
if [ "$SKIP_ESP" = 0 ]; then
	if [ "$PRESENT" != 1 ]; then
		die "刷 recovery_a 需用户在场：加 --i-am-present（AGENTS 禁令）"
	fi

	if [ "${ESPIMG##*.}" = "gz" ]; then
		ESPDIR=$(mktemp -d); trap 'rm -rf "$ESPDIR"' EXIT
		gunzip -c "$ESPIMG" > "$ESPDIR/esp.img"
		FLASH_ESP="$ESPDIR/esp.img"
	else
		FLASH_ESP="$ESPIMG"
	fi
	ESP_SHA=$(sha256sum "$FLASH_ESP" | cut -d' ' -f1)

	echo "[esp 1/4] 软进 fastboot"
	dev_cmd "systemctl reboot --reboot-argument=bootloader" >/dev/null || \
		die "软进 fastboot 失败——设备上手动: sudo systemctl reboot --reboot-argument=bootloader"
	for i in $(seq 1 30); do
		if fastboot devices | grep . >/dev/null; then break; fi
		if [ "$i" = 30 ]; then die "fastboot 无设备（硬进 = 电源+音量减，18d1:d00d）"; fi
		sleep 2
	done
	echo "  ✓ fastboot 在线"

	echo "[esp 2/4] fastboot flash recovery_a（只碰 recovery_a）"
	fastboot flash recovery_a "$FLASH_ESP"

	echo "[esp 3/4] fastboot reboot"
	fastboot reboot

	echo "[esp 4/4] 等系统回来（NCM 重枚举，~2.5min 预算；网段漂移自动重探）"
	UP=0
	for i in $(seq 1 50); do
		sleep 3
		if dev_cmd "echo BOOT-OK" 2>/dev/null | grep "BOOT-OK" >/dev/null; then UP=1; break; fi
	done
	if [ "$UP" != 1 ]; then
		die "重启后 devshell 未回（常见 = NCM 网段漂移）。两腿已完整，无半截态风险；手工验收：
  python3 tools/devsh.py --host <新设备IP> 'uname -v'   # 期望 $EXPECT_UNAME
  读回对 sha = script/readback.sh 或本脚本 --skip-apk 重跑（--host 指定新址）"
	fi
fi

# =============================================================
# 验收（uname + recovery_a 读回）
# =============================================================
echo "[验收] uname -v"
UNAME_V=$(dev_cmd "uname -v") || true
UNAME_LINE=$(printf '%s\n' "$UNAME_V" | grep -m1 '#' || true)
echo "  实测: ${UNAME_LINE:-<空>}"
if [ -n "$EXPECT_UNAME" ]; then
	case "$UNAME_LINE" in
		*"$EXPECT_UNAME"*) echo "  ✓ #N 对上（$EXPECT_UNAME = pkgrel+1 定律）" ;;
		*) die "uname 不符：期望 $EXPECT_UNAME。两腿是否都完成了？（docs/UPGRADE.md FAQ）" ;;
	esac
fi

if [ "$SKIP_ESP" = 0 ]; then
	echo "[验收] recovery_a dd 读回对 sha（刷写时长不算证据，只看读回）"
	dev_grep 'dd if=$(readlink -f /dev/disk/by-partlabel/recovery_a) bs=4096 | sha256sum' \
		"$ESP_SHA" "recovery_a 读回 sha 不对（期望 ${ESP_SHA:0:8}）→ 重刷该腿：--skip-apk --i-am-present"
	echo "  ✓ 读回 sha ${ESP_SHA:0:8} 对上"
fi

echo
echo "[✓] 升级完成。冒烟建议（tools/devsh.py 或 ssh）：systemctl --failed 应为 0 + 音频/触控眼判。"
echo "    出事回滚 = 上一轮 Release 的 apk+ESP 同法两腿刷回（docs/UPGRADE.md 回滚节）。"
