# CLOUD-BUILD-CI-REVIEW — 云端构建十跑全审计（2026-10-13 深夜收官；下会话按 §四一次点火）

> 用户令：「认真检查一遍流程，每次都修代价太大」——本文 = 十跑逐败因台账 + 全流程
> 分级审计（已验证绿 / 已修未验 / 风险挂观察）+ 下会话执行蓝本。配套 = workflow
> 本体（.github/workflows/build-release.yml，批量修正已入 04dca63 之后的收尾提交）。

## 一、十跑逐败因台账（每败皆已定谳 + 修法入 workflow）

| 跑 | 步 | 死因（证据原文关键词） | 修法 | 状态 |
|---|---|---|---|---|
| #1 | checksum | `Work path not found, please run 'pmbootstrap init'`（CI 无 work dir） | +init 步 | 后被十修取代 |
| #1 | derive | `ESP_VER: 67`（钉 66 +1 = 撞当轮） | 推导改查已发布 Release | 后被十修三态取代 |
| #2 | init | `could not find remote name for URL gitlab...`（fork 无官方 remote） | 补 remote add pmos | ✅已验 |
| #3 | init | `Failed to read channels.cfg from 'pmos/main' branch`（fork 无 main 分支） | fork main = channels.cfg 孤儿快照（dd2fa470）+ update-ref | ✅已验（十跑过此关） |
| #4 | init-fetch | gitlab fetch 挂死 30min（活日志不可见→盲等） | 砍跑；fetch 降 30s 超时首选 + 快照兜底 | ✅已验 |
| #5 | clone | clone 挂 25min+（gitlab 拉 pmbootstrap 坏窗口） | 砍跑；pmbootstrap 改 PyPI（→错） | #6 秒败见下 |
| #6 | deps | `pmbootstrap (from versions: none)`——**不在 PyPI** | 改 GitHub 镜像（→错） | #7 秒败见下 |
| #7 | deps | `could not read Username for 'https://github.com'`——**postmarketOS org 无镜像仓 404**（第三方 LibrePhone=2019/pasyn=2025-11 均不可用） | 唯一正源=gitlab，有界 clone 240s×3 重试快速失败 | ✅已验（#8/#10 deps 绿） |
| #8 | clone | 卡 50min：`timeout 900` 包 bash 时孙进程 git **孤儿化握死日志管道，timeout 形同虚设** | 全部步骤改 GitHub 原生 step 级 `timeout-minutes`（runner 管进程树）；内核树改 **--depth 1 浅 clone**（全史 ~2GB=慢根源；git archive 不受影响） | ✅已验（#9/#10 clone 绿且快） |
| #9 | init | 卡 25min 被 step 界处决：init 向导走深后，**ask_for_device 尾部下游确认 `confirm()` 空 Enter=拒绝 → 136 万次重问循环**（日志 1080 万行） | 十修：弃 init 向导 | 见 #10 |
| #10 | checksum | `work folder version needs to be migrated (from '' to 8)`——**纯 mkdir 缺 version 标记**，pmbootstrap 拒迁移 | 种子步补 `echo 8 > $WORK/version`（pmb/config work_version=8，本地 work dir 实证） | ✅已验（#11 绿） |
| #11 | build-device | `apk add crossdirect g++-x86_64 gcc-x86_64 …` 退出码 2——**pmbootstrap 依赖队列给依赖排队只传 cross 不传 arch**（_package.py queue_build），`arch="all"` 依赖（temp/hexagonrpcd，CI 冷包仓必现编）被 autodetect 成宿主原生 arch ⇒ CROSSDIRECT 组合装 gcc-x86_64（native 仓索引无此包）；本地有现成 apk 走 is_cached 跳过从不踩。旁证：同轮显式目标路径的固件/内核全绿 | build-device 加 hexagonrpcd 显式 `build --arch aarch64` 预编（[2/4] 步；有 apk 自动跳过）；**ccache 改 restore+save(always)**——败轮也落袋（#11 内核冷链 2h23m 白烧教训） | ✅已验（#12 预编走 aarch64 buildroot 正路，设备包全绿） |
| #12 | Mu toolchain | `make: llvm-objcopy: No such file or directory`——**fresh Homebrew bin 只有 brew 本体**，clang/llvm-objcopy 需显式 `brew install llvm`（本机能过 = 本地 brew 早年装过 llvm）；工具链步「验证」**假绿**：`x --version | head -1` 管道早退假阴性（工程规则#2），clang 退出 127 被 head 的 0 吞掉，日志留有 `No such file or directory` 铁证。另 ccache save 报「路径不存在」= **路径写错**（真实 = `$WORK/cache_ccache_<arch>`，非 `.pmbootstrap/ccache`） | workflow 工具链步补 `brew install llvm` + 验证去管道（裸 `clang --version`）+ 步界 30min；ccache restore/save 路径改 `cache_ccache_aarch64`+`cache_ccache_x86_64` | ✅已验（#13：brew llvm 23.1.3 装上、验证真过、ccache `Cache saved` 落袋） |
| #13 | Mu build | EDK2 CLANGPDB 构建 14 秒连败 5 模块：`/Cellar/llvm/23.1.3_1/bin/lld-link: not found`——**新 brew llvm 不再带 lld-link 符号链接**（EDK2 CLANGPDB 的 LLINK 恰是它；本地旧版 brew llvm 在 `$HOME/ubuntu/.linuxbrew` 自带 lld-link，故本地从未踩）。clang 本体本轮已验证真过（Cellar 全路径编译成功） | 工具链步补 `ln -s ld.lld lld-link`（lld 按 argv0 多路分派）+ 裸 `lld-link --version` 验证 | 🔶已修未验（#14 首验；**#13 ccache 已落袋 ⇒ #14 内核热起**） |

另：#10 暴露 **ESP_VER 公式 bug**：`max(release,pin)+1` 在「设备日已定版」阶段算出 68
（正确 = 钉子 67）。修 = 三态生命周期公式（见 workflow Derive 步注释）：
`pin > release → 取 pin（同号异字节，各自真值）；pin ≤ release → release+1`。

## 二、全流程分级审计（run #10 时的绿基线 + 剩余链路逐段）

### ✅ 已实测定绿（#11，绿到内核 apk 产出）
checkout / /mnt 摆位 / ccache 挂载 / deps（apt + gitlab 有界 clone×3）/ **浅 clone**
（depth-1 五树 + setup.sh --clone 收尾[submodule/pmbootstrap 跳过]）/ **work dir 种子
version=8**（#10 修法 #11 实测过 checksum 门）/ 固件 tarball 自 Release 拉进包目录 /
**Derive**（TAG=r86 ✓）/ **Mu 工具链（linuxbrew + venv 全绿）**/ **checksum +
build-kernel 冷链**（native chroot bootstrap + cross aarch64 工具链 + 全量冷编
**2h23m** 产出 r86 apk，远在 180min 步界内）/ 固件包构建。

### 🔶 已修未验（#12 跑首验清单）
1. **hexagonrpcd 显式预编**（本文 §一 #11 修法）→ 设备包构建不再撞依赖队列 arch 病。
2. **build-esp**：mtools 造 ESP（宿主态秒级）。
3. **Mu --no-sync 构建**：edk2 BaseTools 宿主 gcc 原生 + brew clang cross aarch64
   （非模拟）+ BootShim make；上游 CI 同款 ✓。
4. **rootfs**：pmbootstrap install --single-partition（aarch64 rootfs chroot = qemu
   模拟包安装，慢段）+ losetup 镜像组装（runner 允许 loop，社区先例多）。
5. **verify**：ESP 对拍走「钉子缺席→artifacts 最新」回落（v65 钉不在 CI，回落当轮
   v67）——此路径已本地验证过同款逻辑。
6. **staging + 升级包**：device r60==钉60 / fw r3==钉3 → 升级包只含 linux apk+ESP+
   UPGRADE.md（与本地 upgrade-r86 同配方）。
7. **草稿发布 + 字节对拍**：gh release create r86 --draft + 资产逐件字节数对拍
   （r72 教训闭环）。

### ⚠️ 风险挂观察（不阻塞点火，失败时按此排障）
1. **首轮冷编时长** = 最大变数。x86 runner + cross aarch64 内核全量（无 ccache）
   估 40-120 分钟；步界已放大 180min / job 界 360min（6h 上限）。ccache 只在
   **job 成功后**保存 → 首绿前每轮都冷。若超时：方案 A = 降内核 config debug 件
   （不推荐）；方案 B = 接受 2-3 轮失败换 ccache 不现实（失败不落缓存）→ 方案
   C = 手动 `actions/cache` 预热（本地 ccache 12G 打包上传作初始种子，一次性）。
2. **losetup/binfmt**：pmOS 官方 CI 先例背书；若 rootfs 步败于 loop → 查 runner
   内核 `max_loop`。
3. **gitlab 坏窗口复发**：deps 的 240s×3 重试形态下最坏 = 分钟级失败，重触发即
   重掷；长期解 = 把 pmbootstrap 源码 tarball 挂进 nura 自有 Release 作兜底源
   （固件 tarball 先例；**挂用户拍板**——涉及发新 infra tag）。
4. **Mu 构建非字节确定**：产物 mu-r86-*.img 与本地 mu-r69（FdtBlob 未变）语义对拍
   （verify 只查 DTB 同源 ✓），不逐字节（政策已有：发布真值=CI SHA256SUMS）。

## 三、一致性对比规程（#11 出草稿后执行）
1. 下载 CI 草稿资产清单（`gh release view r86 --json assets`）。
2. 对照本地 `artifacts/`（apk r86 `6e5dd1b8` / esp v67 裸 `2ad63003` gz `444dec3f`）：
   - **结构层**：资产清单一致（8 件制）+ SHA256SUMS 自洽（`sha256sum -c`）；
   - **语义层**：CI apk 解包 vmlinuz-efi/dtb sha vs 本地同源件（同源码+config 应
     同 dtb；vmlinuz 允许异[构建时间戳]）；ESP v67 CI 版 vs 本地版：mcopy 抽
     BOOTAA64.EFI 对 sha（同 vmlinuz 即等价）；
   - **版本层**：uname 期望同为 #87；升级包清单同构。
3. 字节差异 = 预期（非确定构建），记录入 MANIFEST 备注（CI 真值口径）。

## 四、下会话执行蓝本
> **执行进度（2026-10-13）**：步骤 1-2 已执行 = #11 点火（run 38391060584）——
> version 种子/checksum/内核冷链全验绿，败于 §一 #11 新败因（hexagonrpcd），修正已入
> （build-device 预编 + ccache save-always），重触发 = #12；冷编 #12 仍需 ~2.5h（#11
> 败轮 ccache 未落袋），此后败轮不再丢。
1. `git pull`（本审查 + workflow 批量修正已提交推送）。
2. `gh workflow run build-release`（一次点火）→ 盯 §二.🔶 清单顺序过关。
3. 过关 → §三 一致性对比 → **草稿 r86 验收 → 公网发布 = 用户拍板**。
4. 收官三写：config/MANIFEST 发布面切 r86 + AGENTS 现态 + experiment-log 叙事
   （十跑战役全量）。
5. 若 checksum/build-kernel 超时：§三.1 方案 C（本地 ccache 种子）后重触发
   （save-always 入列后此预案降级为观察项：正常败轮也会留下 ccache）。
