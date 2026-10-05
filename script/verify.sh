#!/usr/bin/env bash
# verify.sh — 交付链对拍全家桶（只读，零风险，随时可跑）
#
# 用法: verify.sh
# 检查项:
#   1. apk 内 DTB ↔ Mu FdtBlob sha256 同源（（四十九）头号坑）
#   2. tarball 内 DTS 零 -inf 残留 + 关键新串在位
#   3. apk 内 zram.ko/zsmalloc.ko 在列（zram 销账）
#   4. ESP 内 BOOTAA64.EFI ↔ apk vmlinuz-efi sha 一致
#   5. 打印期望 uname（#N=pkgrel+1 定律）
set -euo pipefail
. "$(dirname "$0")/../config.sh"

PKGDIR="$PIN_PMAPORTS/device/downstream/$PKG_LINUX"
PKGREL=$(grep -m1 '^pkgrel=' "$PKGDIR/APKBUILD" | cut -d= -f2)
APK="$APK_DIR/${PKG_LINUX}-${PKGVER}-r${PKGREL}.apk"
FDTBLOB="$PIN_MU_DIR/Platforms/Meizu/m2381Pkg/FdtBlob/sm8550-meizu-20.dtb"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
FAIL=0

chk() { # chk <名> <ok与否 0/1> <详情>
	if [ "$2" = 0 ]; then echo "  ✓ $1"; else echo "  ✗ $1 —— $3"; FAIL=1; fi
}

echo "== verify @ $(date '+%F %T')  pkgrel=$PKGREL =="

echo "[1] apk ↔ Mu FdtBlob 同源"
if [ -e "$APK" ]; then
	tar -xzf "$APK" -C "$WORK" boot/dtbs/qcom/sm8550-meizu-20.dtb 2>/dev/null
	A=$(sha256sum "$WORK/boot/dtbs/qcom/sm8550-meizu-20.dtb" | cut -d' ' -f1)
	B=$(sha256sum "$FDTBLOB" | cut -d' ' -f1)
	[ "$A" = "$B" ] && echo "  ✓ dtb 同源 ${A:0:8}" || { echo "  ✗ dtb 不同源 apk=${A:0:8} mu=${B:0:8} —— 跑 build-mu.sh 同步"; FAIL=1; }
else
	echo "  ⚠ apk r${PKGREL} 不存在（跳过 1/2/3）"
fi

echo "[2] tarball DTS 残留扫描"
TB="$PKGDIR/${PKG_LINUX}-fork-v${PKGVER}.tar.gz"
if [ -e "$TB" ]; then
	INF=$(tar -xzOf "$TB" "${PKG_LINUX}-fork-v${PKGVER}/arch/arm64/boot/dts/qcom/sm8550-meizu-20.dts" | grep -cE "MEIZU20Inf|meizu-20-inf" || true)
	chk "DTS 零 -inf 残留" $([ "$INF" = 0 ]; echo $?)
	NEW=$(tar -xzOf "$TB" "${PKG_LINUX}-fork-v${PKGVER}/arch/arm64/boot/dts/qcom/sm8550-meizu-20.dts" | grep -c 'model = "MEIZU20"' || true)
	chk "model=MEIZU20 在位" $([ "$NEW" -ge 1 ]; echo $?)
	tar -xzOf "$TB" "${PKG_LINUX}-fork-v${PKGVER}/Documentation/devicetree/bindings/sound/qcom,sm8250.yaml" | grep -q "meizu,meizu-20-sndcard" \
		&& echo "  ✓ binding yaml 新名" || { echo "  ✗ binding yaml 未同步"; FAIL=1; }
else
	echo "  ⚠ tarball 不存在（跳过）"
fi

echo "[3] apk 内容抽查"
if [ -e "$APK" ]; then
	tar -tzf "$APK" 2>/dev/null | grep -q "zram.ko" && echo "  ✓ zram.ko 在列" || { echo "  ✗ zram.ko 缺失"; FAIL=1; }
	tar -tzf "$APK" 2>/dev/null | grep -q "zsmalloc.ko" && echo "  ✓ zsmalloc.ko 在列" || { echo "  ✗ zsmalloc.ko 缺失"; FAIL=1; }
	tar -tzf "$APK" 2>/dev/null | grep -q "boot/vmlinuz-efi" && echo "  ✓ vmlinuz-efi 在列" || { echo "  ✗ vmlinuz-efi 缺失"; FAIL=1; }
fi

echo "[4] ESP ↔ apk vmlinuz 同源（如 ESP 存在）"
if [ -e "$REL_ESP_IMG" ] && [ -e "$APK" ]; then
	tar -xzf "$APK" -C "$WORK" boot/vmlinuz-efi 2>/dev/null || true
	if [ -e "$WORK/boot/vmlinuz-efi" ]; then
		mcopy -i "$REL_ESP_IMG" ::/EFI/BOOT/BOOTAA64.EFI "$WORK/BOOTAA64.EFI" 2>/dev/null
		K=$(sha256sum "$WORK/boot/vmlinuz-efi" | cut -d' ' -f1)
		E=$(sha256sum "$WORK/BOOTAA64.EFI" | cut -d' ' -f1)
		[ "$K" = "$E" ] && echo "  ✓ ESP 内核 = apk vmlinuz-efi (${K:0:8})" || { echo "  ✗ ESP 与 apk 不同源（ESP 旧了？重跑 build-esp.sh）"; FAIL=1; }
	fi
else
	echo "  ⚠ ESP 或 apk 缺席（跳过）"
fi

echo "[5] 期望 uname: $(grep -m1 '^pkgver=' "$PKGDIR/APKBUILD" | cut -d= -f2)-r${PKGREL} → #$((${PKGREL} + 1))"
echo "    （上机后 uname -v 应含 -meizu-meizu20 且 #N = pkgrel+1）"

[ "$FAIL" = 0 ] && { echo "== 全绿 =="; exit 0; } || { echo "== 有红，见上 =="; exit 1; }
