#!/usr/bin/env bash
# setup.sh — 工作区检查/摆位（本机体检 + Phase-2 他机复刻入口）
#
# 用法: setup.sh [--doctor] | [--clone]
#   --doctor  只做依赖与钉子体检（默认行为）
#   --clone   先按 config.sh 的 PIN_*_GIT 复刻四仓，再跑体检
#             新机器第一步：clone 本仓拿到 script/ → 跑本脚本 --clone
#             （URL 留空的仓跳过；已存在的目录不动；Mu 的 Binaries
#             submodule 会按 PIN_MU_BINARIES_GIT 改指并拉全）
set -euo pipefail
. "$(dirname "$0")/../config.sh"

if [ "${1:-}" = "--clone" ]; then
	echo "== Phase-2 复刻：按 PIN_*_GIT 拉取源码树 =="
	clone_repo() { # <名> <URL> <目录> <分支>
		local name="$1" url="$2" dir="$3" branch="$4"
		if [ -z "$url" ]; then echo "  - $name：PIN URL 未填，跳过"; return 0; fi
		if [ -e "$dir/.git" ]; then echo "  ✓ $name 已在位：$dir"; return 0; fi
		mkdir -p "$(dirname "$dir")"
		git clone -q --branch "$branch" "$url" "$dir" || nura_die "$name clone 失败：$url"
		echo "  ✓ $name → $dir（$branch）"
	}
	clone_repo "fork 内核" "$PIN_LINUX_GIT"   "$PIN_LINUX_DIR" "$PIN_LINUX_BRANCH"
	clone_repo "pmaports"  "$PIN_PMAPORTS_GIT" "$PIN_PMAPORTS"  "$PIN_PMAPORTS_BRANCH"
	clone_repo "Mu"        "$PIN_MU_GIT"       "$PIN_MU_DIR"    "$PIN_MU_BRANCH"
	if [ -n "$PIN_MU_GIT" ] && [ ! -e "$PIN_MU_DIR/Binaries/.git" ]; then
		[ -n "$PIN_MU_BINARIES_GIT" ] || nura_die "Mu Binaries：PIN_MU_BINARIES_GIT 未填（钉住的 036ba9f7 不在上游 Device-Binaries main）"
		git -C "$PIN_MU_DIR" submodule set-url Binaries "$PIN_MU_BINARIES_GIT"
		git -C "$PIN_MU_DIR" submodule update --init --recursive
		echo "  ✓ Mu submodules（Binaries → $PIN_MU_BINARIES_GIT）"
	fi
	# wrapper/tools/回滚锚不在 clone 面：wrapper 待收编本仓 script/；
	# tools 与锚为 Phase-2 Release 资产（见 AGENTS.md / PIPELINE.md）。
	echo
fi

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
try "systemd user manager（systemd-run 长构建）" "systemd-run --user --quiet --collect --unit=pmx-doctor-probe true"
try "K30 wrapper 并发检查（共享 work dir 须串行）" "! pgrep -f pmbootstrap-phoenix >/dev/null"

[ "$bad" = 0 ] && { echo "== 环境就绪 =="; exit 0; } || { echo "== 有缺项，见上 =="; exit 1; }
