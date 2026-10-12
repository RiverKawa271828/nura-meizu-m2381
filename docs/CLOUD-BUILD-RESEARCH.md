# CLOUD-BUILD-RESEARCH — nura 云端构建研究（2026-10-13，纯宿主零设备轮）

> 目标（用户拍板 10-13）：在 `RiverKawa271828/nura-meizu-m2381` 建云端构建，
> 产出**三个镜像 + 手动升级包**，并**尝试云端构建 r85**；r85 交付 =
> **手动升级路径首验**（apk 腿 + ESP 腿，不重刷 userdata）。本段收官后告一段落，
> 等 7.3 stable 再推进适配（麦克风/相机等）。
> 参照范式 = `steamos-meizu20/.github/workflows/build-release.yml`（已跑通）。

## 结论先行

- **完全可行**：nura 的 config.sh / setup.sh 本来就为「新机器复刻」设计
  （四源树全有公共 GitHub 钉子；`setup.sh --clone` 即一键复刻布局）——
  **CI runner 就是一台新机器**，这层是现成的。
- 唯一结构性新增 = **Mu 构建段**（steamos 只刷 userdata 不编 Mu）。
- **目录转移不是云端前置**（见 §四），但建议随本专项顺手内聚（半小时级）。
- 本地未推送提交是**真前置**（§五）：pmaports r85 两提交 + nura 文档/工作流提交，
  推送窗口 = 用户拍板。

## 一、现有链路盘点（CI 视角逐段）

| 段 | 脚本 | 输入（云端可得性） | 产物 | CI 时长预估 |
|---|---|---|---|---|
| 复刻 | `setup.sh --clone` | 四仓全在 GitHub（PIN_LINUX/MU/BINARIES/PMAPORTS_GIT）✓ | 源树布局 | ~3min |
| 内核 | `build-kernel.sh` | fork 树（浅 clone 即可满足 git archive 重打 tarball）✓ | linux apk | 30-60min（无 ccache 冷编） |
| 设备+固件包 | `build-device.sh` | pmaports ✓；**固件 tarball 不在 pmaports git**（81MB，gitignore）→ 须先自 Release 拉（见 §二.3） | device+firmware apk | ~3min |
| ESP | `build-esp.sh` | 上一步 apk ✓ | esp-recovery-vN.gz | ~1min |
| Mu | `build-mu.sh` | apk DTB + Mu 树（github + Binaries submodule 钉 036ba9f7）✓；**依赖 linuxbrew clang + .venv**（见 §二.4） | mu-rN.img | 5-15min |
| rootfs | `build-rootfs.sh`（NURA_UI=phosh） | pmbootstrap（官方 gitlab）+ 边缘仓网络 ✓ | rootfs gz（<2GiB 门禁内建） | 15-25min |
| 验收 | `verify.sh` | 全部产物 ✓ | 对拍报告 | ~2min |

- 铁律已固化进脚本：`--single-partition`（rootfs）、ESP 版本号取「artifacts 最大
  vN+1」、FdtBlob 必须出自同一个 apk（verify 对拍）。
- 7 件制发布面（r84 口径）= mu img + esp gz + rootfs gz + 固件 tarball + apk 两件
  + SHA256SUMS；**新增第 8 件 = 手动升级包** `upgrade-<tag>.zip`
  （= linux apk + esp gz（+本轮有变的 device/fw apk）+ UPGRADE.md 抄本），
  内容与 Release 散件逐字节一致、仅打包。

## 二、CI 适配点（与本地机的关键差异）

1. **无 systemd**：五个 build 脚本的 `systemd-run 重入` 分支在 CI 必死。
   适配 = workflow 里 `export NURA_INSIDE_UNIT=1`（脚本语义 =「已在宿主环境」，
   恰好直跑）。零代码改动。
2. **磁盘布局**：GH ubuntu runner 根分区可用 ~14GB；chroot + ccache + 镜像会紧。
   `export NURA_WORK=/mnt/work`（/mnt ~65GB）+ `PMB_WORK` 随 NURA_WORK 推导。
3. **固件 tarball 取源**：本地靠 pmaports 包目录里的 untracked 件；CI clone 后没有。
   方案 = workflow 里从 Release（`PIN_RELEASE_BASE` 同 URL）curl 拉 tarball →
   `cp` 进 `pmaports/device/downstream/firmware-meizu-meizu20/`（与本地同构，
   sha512 由 APKBUILD 自验）。setup.sh `--fetch-release` 拉的是 Release→artifacts，
   位置不合 pmbootstrap source 解析，**CI 直接拉到包目录**更简。
4. **Mu 段（新活，steamos 没有）**：
   - clang：build-mu.sh 取 `$HOME/{ubuntu/}.linuxbrew/bin` 的 clang。
     CI 装 linuxbrew（官方一行）最省事；备选 = apt clang 版本兼容性验证
     （**验证点**：build_uefi.py = CLANGPDB 模式）。
   - venv：Mu 树有 `pip-requirements.txt` → `python3 -m venv .venv &&
     .venv/bin/pip install -r pip-requirements.txt`。
   - DTS 未变的轮次用 `build-mu.sh --no-sync`（r85 = config-only ⇒ 走此路径，
     只重编不换 FdtBlob；产物与本地 mu-r69 sha8 97cdea20 做参照——Mu 构建可能
     非字节确定，判据用 verify 语义对拍不逐字节）。
   - 「Source.txt 记得 commit」提醒在 CI = 一次性 clone 丢弃无妨；本地 Mu 树
     跟进照旧人工。
5. **内核 tarball**：`build-kernel.sh` 默认重打（git archive fork 树）→ CI 用
   `--depth 1 --branch meizu20-t4b` 浅 clone 即满足；**不要在 CI 里 --bump**
   （pkgrel 属于 pmaports 提交，发版流程 = 本地 bump + 推送，CI 只构建 HEAD）。
6. **ccache**：runner 冷缓存每轮全量内核编译。建议 `actions/cache` 缓存
   `.pmbootstrap/ccache`（GB 级，收益 30-60min → ~10min）。
7. **权限/密钥**：runner 免密 sudo ✓、gh 预装 ✓；`permissions: contents: write`；
   **零 secrets**（全公共仓 + github.token）。
8. **触发**：`workflow_dispatch` 手动（steamos 范式）；不挂自动触发（发版窗口 =
   用户拍板，保持人为）。

## 三、工作流草案（build-release.yml 骨架，下会话落地）

```yaml
name: build-release
on: { workflow_dispatch: {} }
permissions: { contents: write }
env: { NURA_INSIDE_UNIT: "1", NURA_WORK: /mnt/nura-work, NURA_UI: phosh }
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4                      # nura 本仓
      - name: Deps                                     # git/python3/sudo/mtools 按需
        run: sudo apt-get update -qq && sudo apt-get install -y git python3
      - name: Clone source trees                       # setup.sh --clone（四仓）
        run: bash script/setup.sh --clone
      - name: Firmware tarball from Release            # §二.3
        run: curl -fsSL -o pmaports/device/downstream/firmware-meizu-meizu20/firmware-meizu-meizu20.tar.gz \
             ${PIN_RELEASE_BASE}/firmware-meizu-meizu20.tar.gz
      - name: Kernel + device + ESP                    # 顺序铁律
        run: bash script/build-kernel.sh && bash script/build-device.sh && bash script/build-esp.sh
      - name: Mu                                       # linuxbrew + venv，config-only 轮 --no-sync
        run: ...
      - name: Rootfs                                   # NURA_UI=phosh（env 已给）
        run: bash script/build-rootfs.sh
      - name: Verify                                   # verify.sh 全对拍
        run: bash script/verify.sh
      - name: Assemble upgrade zip                     # 手动升级包 = apk+esp+UPGRADE.md
        run: ...
      - name: Release upload                           # gh release create/upload + SHA256SUMS
        env: { GH_TOKEN: "${{ github.token }}" }
        run: ...
```

- 产物校验口径：**发布真值 = CI 自己产的 SHA256SUMS**（apk/rootfs/Mu 均非字节
  确定构建）；本地件只做功能对照（r85 apk sha8 c1d22119 之类的引用不外推）。
- 大件上传沿用 r72 教训：`gzip -t`（脚本内建）+ 上传后资产字节数逐件对拍
  （steamos 工作流尾步同款）。

## 四、工作目录/构建目录转移（用户问：应该转移吗？）

现状：NURA_ROOT（项目仓）在 `~/work/nura-meizu-m2381`，构建基建
（pmaports / pmbootstrap / .pmbootstrap）在 `~/work/pmos_linux/pmos/`——
后者是 K30 时代共享遗存（wrapper cfg 注释自己写着「与 K30 共享…须串行」，
K30 已退役）。

- **云端不依赖本地转移**：CI 上没有 pmos_linux，`setup.sh --clone` 按
  NURA_WORK 全新摆位，config.sh 全路径推导自洽——转移与否云端都能跑。
- **建议 = 随本专项顺手内聚（做）**，收益：①本地与云端布局同构（排障对称，
  文档/命令可互换）②杀掉「共享 PMB_WORK 须串行」死纪律 ③pmos_linux 回归
  纯文档基建。做法 = config.sh 默认钉子改为 NURA_ROOT 内聚
  （`$NURA_ROOT/{pmaports,pmbootstrap,.pmbootstrap}`），本地 `mv` 三目录
  （pmaports 的 git remote 不受目录影响；.pmbootstrap 可 mv 或冷重建——
  冷重建代价 = 首轮全量内核编译 ~12 分钟）+ wrapper cfg 注释更新。半小时级。
- 顺序建议：下会话第一步先定稿 CI 布局默认值，本地照抄同构，再写 workflow。

## 五、前置清单（云端构建 r85 之前）

1. **pmaports r85 两提交未推**（1d54efd config + 247be65 checksum，本地
   phoenix 领先 github/phoenix = 2）——推送窗口 = 用户拍板。
2. **nura 本地未推**（1d4ab52 / 7d790f9 + 届时的工作流/文档提交）——同上。
3. 内核 fork 树无新提交（r85 = config-only，tip 不动 140e5a8e308a）→ 云端
   clone 即得 ✓；Mu 树同理（FdtBlob 未变）。
4. Release r85 的固件 tarball 资产已存在（r84 附带件，同 URL 语义）✓；
   CI 按 §二.3 拉取。
5. 云构建 r85 产物到手后的**手动升级首验** = 设备日在场：apk 腿
   （`apk add ./linux-…-r85.apk`，验签 pubkey 已烤 rootfs）+ ESP 腿
   （esp-recovery-v66 → fastboot flash recovery_a），两腿之间不重启；
   验收 = `uname -v` 显示 **#86**（rN → #N+1 定律）+ `systemctl --failed`=0
   + **waydroid 容器联网四连**（gw/IP/DNS/应用内加载）——即（八十八·乙）
   netd 路由修复的最终闭环。

## 六、风险与回退

| 风险 | 判 | 缓解 |
|---|---|---|
| binfmt/qemu（x86_64 编 aarch64 rootfs） | 低：pmOS 官方 CI 同款 | 首跑即验 |
| linuxbrew clang 版本漂移 | 中 | BUILD 时钉版本 / 失败退 apt clang 对照 |
| runner 磁盘 | 中 | NURA_WORK → /mnt（§二.2） |
| 非确定构建逐字节对不上 | — | 发布真值 = CI SHA256SUMS（§三） |
| 上传中断半截件（r72 教训） | 低 | 脚本内 gzip -t + 尾步字节数对拍 |
| CI 失败阻塞发版 | 低 | 回退 = 本地构建照旧（链路未动） |
