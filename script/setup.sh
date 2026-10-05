#!/usr/bin/env bash
# setup.sh — 工作区检查/摆位（本机体检 + Phase-2 他机复刻入口）
#
# 用法: setup.sh [--doctor]
#   --doctor  只做依赖与钉子体检（默认行为）
#   （Phase-2：PIN_*_GIT 填公共 URL 后，本脚本补 clone 四仓到规范相对布局）
set -euo pipefail
. "$(dirname "$0")/../config.sh"

echo "== nura-meizu-m2381 setup doctor =="
ok=0; bad=0
try() { if eval "$2" >/dev/null 2>&1; then echo "  ✓ $1"; else echo "  ✗ $1"; bad=1; fi }

echo "[钉子/源码树]"
try "fork 内核树 $PIN_LINUX_DIR"          "[ -d '$PIN_LINUX_DIR/.git' ]"
try "  分支 $PIN_LINUX_BRANCH 在位"        "git -C '$PIN_LINUX_DIR' rev-parse --verify '$PIN_LINUX_BRANCH'"
try "Mu 树 $PIN_MU_DIR"                   "[ -d '$PIN_MU_DIR/.git' ]"
try "  分支 $PIN_MU_BRANCH 在位"           "git -C '$PIN_MU_DIR' rev-parse --verify '$PIN_MU_BRANCH'"
try "pmaports $PIN_PMAPORTS"              "[ -d '$PIN_PMAPORTS/.git' ]"
try "pmbootstrap wrapper"                  "[ -x '$PIN_PMB_WRAPPER' ]"
try "tools（ESP/devsh）"                   "[ -e '$PIN_TOOLS/make-esp-recovery.sh' ]"

echo "[工具链]"
try "pmbootstrap（wrapper 可执行）"        "bash -n '$PIN_PMB_WRAPPER'"
try "clang（内核 LLVM=1 / Mu）"            "command -v clang"
try "mformat/mcopy（ESP 制作）"            "command -v mformat"
try "fastboot（刷写）"                     "command -v fastboot"
try "python3（bump/对拍）"                 "command -v python3"

echo "[回滚锚]"
for f in "$ANCHOR_TB2" "$ANCHOR_ESP_V4D" "$ANCHOR_MU_R57"; do
	[ -e "$f" ] && echo "  ✓ $(basename "$f")" || { echo "  ✗ $(basename "$f")"; bad=1; }
done

echo "[宿主环境]"
try "systemd user manager（systemd-run 长构建）" "systemctl is-system-running --user"
try "K30 wrapper 并发检查（共享 work dir 须串行）" "! pgrep -f pmbootstrap-phoenix >/dev/null"

[ "$bad" = 0 ] && { echo "== 环境就绪 =="; exit 0; } || { echo "== 有缺项，见上 =="; exit 1; }
