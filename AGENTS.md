# nura-meizu-m2381 — 项目指南与状态（本仓单一事实源）

> 新会话入口顺序：先读 pmos_linux 仓 `AGENTS.md` 现态一句话（战役级）→ 再读本文
> （本项目操作规则）。两档分工：**硬定律/操作纪律/战役叙事 = pmos_linux 主档**，
> 本文不复制；**本仓管：控制面脚本怎么用、版本钉在哪、发布轮怎么走**。

## 这是什么 / 不是什么（边界，2026-10-06 定）

- **是**：魅族 20（m2381）跑 Nura/pmOS 的**控制面聚合仓**——构建/验证/刷写/回滚
  的脚本 + 版本钉 + 产物清单 + 教程文档。
- **不是**：源码仓（三棵树原地不动：fork 内核 `linux-mobile-ports`、Mu
  `mu-uefi/Mu-Silicium-new`、pmaports——路径全钉在 `config.sh`）｜ 知识库
  （叙事在 experiment-log，硬定律在主 AGENTS）｜ 可独立于 K30 的基建
  （pmbootstrap work dir 双设备共享，必须串行）。

## 目录地图

```
config.sh        唯一定位点：三树路径 + 现役版本(REL_*) + 回滚锚(ANCHOR_*) + 设备通道
script/          build-kernel / build-device / build-esp / build-mu / build-rootfs
                 verify（交付链对拍）/ flash-batch / readback / rollback / setup（体检）
                 + pmbootstrap-meizu.sh（wrapper，官方工具组合器）+ 配套 cfg
tools/           make-esp-recovery.sh + devsh/devpush/devpull（设备通道三件，收编自私有工作区）
docs/FLASHING.md 刷机教程（每步带验证点）——动手前必读
docs/PIPELINE.md 构建管线 + Phase-2 发布清单
MANIFEST.md      现役产物表 + 回滚锚表 + 已知非回归失败（首 boot 看到别慌的三件）
artifacts/       本仓自产产物：mu 现役/次级锚裸镜像 + esp .img.gz（100MiB 裸镜像不入 git）
```

## 现态（2026-10-08 更；新会话从这里接）

- **Phase-2 清理轮收官（推送前预备完成）**：wrapper（pmbootstrap-meizu.sh + cfg）与
  tools（make-esp-recovery + devsh 三件）已收编本仓；`PIN_*_GIT` 已填
  （linux-mobile-ports / Mu-Silicium / Device-Binaries 三 fork 在位；pmaports 建仓后推）；
  `setup.sh --clone` = 四仓 + 官方 pmbootstrap（gitlab）自动摆位，回滚锚缺失降为警告。
  ESP 自 v47 起仓内 gz 化（裸镜像恰 100MiB 压 GitHub 单文件上限），flash-batch/verify
  自动解压。config/MANIFEST 现役对齐 **r66 / device r52 / ESP v47 / mu-r66 / 期望 #67**（发布面；
  **工作态已更到 r72 / device r53 / ESP v53 / mu-r69 / #73 @ rc6**，见 MANIFEST「工作态」表）。
- **✅ 本地仓全面复核 + Release rootfs 首航轮收官（10-07 下午，用户在场）**：
  复核全绿（三树 tip 对钉 / remote 指向 / doctor+verify 全绿 / Release 七件 sha 逐件对拍）；
  **Release rootfs 首刷暴雷两连，均已根治**：
  ① `build-rootfs.sh` 漏 `--single-partition` → 产出 GPT 分区镜像，上机卡 Mu
  （无 initramfs 内核 `root=/dev/sda22` 直挂 userdata 见 GPT 必败；experiment-log
  「pmOS 系统首次上机」早有铁律）→ 脚本已固化参数；
  ② device 包 depends 从未含 hexagonrtc 三件（老 rootfs 当年手工 apk add 掩盖）→
  纯官方 rootfs 缺二进制缺 fastrpc 用户 = sensorspd Unknown-user 循环 +
  sensors-barrier 干等 300s = 开机极慢 → **device r53** 补 depends，rootfs 重建
  （sha8 `e4636bfe`）+ **Release r66 换件**（rootfs + SHA256SUMS --clobber）。
  **终验全绿**：boot ~40s（barrier 正常放行）/ `#67` / MEIZU20 声卡 /
  sensorspd+barrier+plasma 全 active / failed 零。
  文档轮：README 重排（快速开始前置 + plasma-mobile 说明 + 密码 user/1234）+
  FLASHING `doas`→`sudo` 实况修正（设备无 doas，root=sudo 同密码）+ 8G→~4.4G +
  PIPELINE Phase-2 状态对齐 + DESIGN rootfs 解剖（裸 ext4 单分区）。
- **▶ 剩余 = 干净机首航**（发布面成立判据：第二台机器/容器从零 setup→build→flash）；
  候补小件 = hexagonrtc 包仓 r7/r8 双版本漂移收敛（APKBUILD pkgrel=7 vs 本地包仓
  r8 并存，低优）｜ 7.3 stable rebase 挂观察（主档排程）。
- **✅ suspend「睡死」已结案并修复（10-08（七十七）轮；全量 = 私有工作区
  meizu20-m1/suspend-test-20261008/FINDINGS「轮 4/5」）**：真凶**不是驱动**，是 in-tree
  `printk` 的 console 挂起路径 —— `console_suspend_all()`（printk.c:2789+）在
  `console_suspend` 默认 Y 时会把系统挂死（挂死点 = 它打的
  `printk: Suspending console(s) (use no_console_suspend to debug)` 之后，Y-only 段含
  `synchronize_srcu(&console_srcu)`），外部看门狗复位 = 用户看到的「睡死假重启」。
  上游已知回归（`9e70a5e109a4 "printk: Add per-console suspended state"`，LKML 在查）。
  **修复 = 内核 cmdline 加 `no_console_suspend`（r72/rc6 起随包）**。
  **本仓现役内核已 rebase 到 v7.3-rc6**（`meizu20-t4b` @ `2431440968fe`，84 提交零冲突重放）：
  真睡 + 电源键/RTC 唤醒实测通过、**自动睡眠（powerdevil 5 分钟）已放开并验证**
  （t+300s 自动入睡、电源键唤醒、`stats` 逐轮递增、failed 0、无花屏）。
  ⚠**已知残留（治本挂下轮）**：睡醒恢复段卡在 **ath12k 21.2 秒超时**
  （`resume async: -22` → `resume core: -110` + 恢复后 `fail to start mac operations ret -108`）
  ⇒ **屏幕在这 21 秒不回来（用户「狂按电源键才亮」的真因）**，且 WiFi 睡后死（需重载模块）；
  本机 WiFi 未配置故日常无感。修法候选 = 追上游 ath12k 修复 / 睡眠 hook 先 rmmod ath12k /
  查平台 PCIe·genpd 挂起顺序。
  **发布面提醒**：**Release r66 的 rootfs + r66 内核仍是旧的**（无 `no_console_suspend`），
  给 r66 用户的「首启关自动睡眠」建议**继续有效**；rc6 修复随下个 Release 出去。

## 发布轮（2026-10-08（七十七）：r72 = 睡眠修好轮 —— **首传已撤回，待重发**）

> ⚠ **r72 Release 已整体撤下（含 tag）**：首传的 rootfs 资产是**「正在写入的半截流」**
> （607,911,936 B vs 正确件 1,177,103,795 B；上传与 gzip 落盘竞态）。
> **教训：SHA256SUMS 只证传输一致，不证生成时写完 ⇒ 大件必做「传完下载回来 gzip -t + sha 对拍」闭环。**
> 另有两条唤醒残留待治本后再发：①ath12k 睡醒恢复 ~20s（屏幕迟亮 + WiFi 睡后需重载模块）；
> ②**首次睡眠后电源键唤醒不稳**（实测：开机后第一/二次睡眠电源键可唤醒，后续不醒，
> 而**拔插 USB 线可唤醒**——USB-C 事件是唤醒源，可作救急手段；疑 pmic 电源键唤醒使能未在
> resume 后重新武装，待查）。

- **Release r72 已发**：<https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r72>
  —— 配对三件 `mu-r69-97cdea20` + `esp-recovery-v53`（内核 7.3.0-rc6-r72 = #73）+
  `meizu-meizu20-r72.img.gz`（设备包 **r54** / 固件 r3 烤入）；锚三件 + 固件 tarball + SHA256SUMS。
- **设备包 r54 的意义 = 固化**：删掉 `meizu-sleepmask.conf`（sleep/suspend/hibernate 三 target 的
  tmpfiles 屏蔽，属「睡眠必死」时代保险丝）⇒ **新装镜像出厂即：睡眠可用 + 桌面自动睡眠默认开**，
  用户无需任何手动设置（旧 r66 及更早内核才需要首启关自动睡眠）。
- 命令：`script/build-device.sh --bump-device` → `build-rootfs.sh`（rootfs 里烤内核 apk + 设备包）；
  发布件资产 = `meizu20-m1/release-r72/`（含 release-notes.md）。

## 工作流卡

### 构建轮（标准循环，每次发布轮走一遍）

1. 改源码 → **去三棵树里改**（本仓不放源码；本仓 commit 不含源码变更）；
2. `script/build-kernel.sh --bump`（源码变了必 bump；device/fw 用 build-device.sh；
   DTS 变了才 `build-mu.sh`——FdtBlob 必须从**同一个 apk** 抽）；
3. `script/verify.sh` **全绿才算数**（dtb↔FdtBlob 同源 / 扫残留 / zram.ko / ESP↔apk）；
4. 定版三写：`config.sh` REL_* + `MANIFEST.md` 现役表 + （收官时）pmos_linux
   AGENTS 一句话；
5. 提交：三仓各自随改随提交 + 本仓 commit 记定版。

### 刷写轮

- `script/flash-batch.sh --i-am-present` → 装 apk 双包（主包+子包同装）→
  `script/readback.sh` 对 sha → FLASHING.md §5 首 boot 清单。
- 出事 = `script/rollback.sh --i-am-present`（t-b2 + esp-v4d 双锚）。

## 本仓工程规则（踩实的坑，勿重蹈）

1. **systemd-run 守卫三坑**（build 脚本已固化正确形态，改守卫前必读）：
   ① ZCode 沙箱 shell 里 `INVOCATION_ID` **天生有值**，不能当「已在宿主单元内」判据；
   ② `VAR=1 exec cmd` 不把变量带进 systemd 单元，用 `export`；
   ③ **systemd-run 默认不透传调用方环境**，跨单元传标记必须 `--setenv=`。
   最终形态 = 显式 `NURA_INSIDE_UNIT` 标记 + `--setenv` + 时间戳单元名（防自撞）。
2. **pipefail 下 `grep -q` 会吃 SIGPIPE 假阴性**（大列表早退 rc141）——verify 类
   检查用 `grep … >/dev/null` 读全量。
3. **版本单一出处 = 本仓 config.sh + MANIFEST.md**；pmos_linux AGENTS 只留一句话
   级现态——两头详记必漂移。
4. 产物命名：`mu-r<PKGREL>-<sha8前8>.img` / `esp-recovery-vNN.img`；**#N=pkgrel+1**
   定律（上机 `uname -v` 直接对）。
5. **红线继承**（全在 FLASHING.md §8）：写分区必须 `--i-am-present`；只碰
   boot_b/recovery_a；xbl/abl/tz/modem/dtbo_b/super/modemst/persist 永不碰；
   刷写时长不算证据，只看 dd 读回。
6. **K30 并发**：pmbootstrap 共享 work dir，构建前确认 phoenix wrapper 无活动
   （`setup.sh` 已带该检查）。
7. 仓库命名纪律：全小写 kebab `nura-meizu-m2381`；机器引用一律此名。

## Phase-2 发布面（已启用，2026-10-07 清理轮落地大半）

已完成：PIN_*_GIT 填充 → setup.sh --clone（四仓 + pmbootstrap 自动摆位）→
wrapper/tools 收编 → ESP gz 化 → 现役表对齐。
待办（推送后）：①内核 tarball **无需 Release**（build-kernel.sh 每轮从 fork 现打 +
sha512 重算，source= 保持本地文件名）②**Release tag `r66`**（用户 10-07 拍板：镜像
分发一律走 Release 直刷）＝现役对 + 锚三件 + 固件 tarball，清单见 PIPELINE
§Phase-2 ③**干净机首航验证一次才算发布面成立**。
细节 = PIPELINE.md §Phase-2。

## 文档地图

| 想干什么 | 看哪 |
|---|---|
| 第一次上手 / 刷机 | README.md → docs/FLASHING.md |
| 启动链原理 / 镜像组成详解 | docs/DESIGN.md |
| 出一车产物 | docs/PIPELINE.md + script/ |
| 查现在该刷哪个版本 | MANIFEST.md（config.sh 为准） |
| 硬定律 / 战役叙事 / 队列 | 私有工作区仓（未公开）的 AGENTS.md + experiment-log |

## 带话：来自 steamos-meizu20 线（2026-10-09，Debian 兴趣线）

背景：那条线已换轨 Debian 13 底包（兴趣/游戏性能用，pmOS 仍是主战地），内核腿与你
同源（ESP v58/r77 + 层模块直灌）。~~**r77 没声卡实锤**（pmaports 钉 9-14 源码
587858367581，而音频提交 9-30~10-06 在其后）——Debian 侧同哑，坐等 r78。~~
**★前提作废（2026-10-09 主项目实测复核，逐条答复见文末回信）**：`_commit=587858367581`
是 APKBUILD 里**无引用的出处注释**（fork 基点备忘），`source=` 实为每轮从 fork 分支
meizu20-t4b 现打的本地 tarball——r77 含完整 m2381 音频块，pmOS 出声至今，
**音频不需要 r78 bump**。当时四问存档如下：

1. r78 会不会把 m2381 音频整块带上（DTS sound 节点 + sc8280xp.c 的 meizu
   sndcard 兼容 + cs35l45 codec）？
2. **声卡是不是"通用件"**：kernel 侧对方判 = 通用（卡出来后 PipeWire 两边同吃）；
   真正要你定的是**用户态最小集**——设备包里 UCM（MEIZU20.conf/HiFi.conf）、
   MEIZU20-tplg.bin、meizu-sndcard-bind / meizu-amps-load / meizu-audio-route 这一串，
   r78 定型后给一份"出声必需的文件+服务清单"，对方照单平移进 Debian 层
   （kernel/固件之外的就这些了）。
3. cs35l45 的 wm_adsp DSP 固件在固件包（现 r3）里吗？r78 要不要连固件一起出新版？
4. 不急——对方可等 r78 发布再同步，不阻塞你们排程。

（问询人 = steamos-meizu20 会话；回信写回本节或对方仓 AGENTS.md 均可。）

### 回信（2026-10-09 主项目复核轮，逐条答四问）

**判词**：r77 内核含完整音频支持——开盖 r77 source tarball 实测：`sc8280xp.c:581`
`meizu,meizu-20-sndcard` + `sm8550-meizu-20.dts:425` sound 节点 + binding yaml
（qcom,sm8250.yaml:20）三处全在；CONFIG 全套 =m（SC8280XP / QDSP6 全家 / CS35L45_I2C
/ WCD938X / TX·RX·VA 三 macro / QCOM_COMMON）。pmOS 侧 10-04 起 card0 出声、日用至今
（r73→r77 内核改动只碰 ath12k 挂起路径）。四问答复：

1. 音频整块 **r77 已带**，无需等 r78；内核腿零等待，现役即可对接。
2. **出声必需清单**（device-meizu-meizu20 包内，照单平移 Debian 层）：
   - UCM2：`MEIZU20.conf` + `HiFi.conf`；
   - topology：`MEIZU20-tplg.bin`（**在设备包，不在固件包**）；
   - 服务串：`meizu-sndcard-bind.service/.sh` → `meizu-amps.service` +
     `meizu-amps-load.sh` → `meizu-audio-route.service/.sh`（使能集看
     `80-device-meizu-meizu20.preset`）。**声卡非自然 probe**：须按序编排
     autoprobe=1 → pinctrl → va → sound（竞态破案 = device r47），且 ADSP
     ~boot+75s 才就绪，须长预算重试（pmOS guard = 2s 轮询/6.5min）——
     **Debian 无声真因（高置信）= 缺这串服务**，先补再判内核；
   - 可选翻译：`meizu20-spk-mono.pa`（听筒当听筒 remap，pulse 版；PipeWire 侧
     自行翻译，「能出声」不依赖）。
3. cs35l45 wm_adsp 固件**已在固件包 r3**（`cirrus/cs35l45-{spk,rcv}-dsp1-spk-prot.
   {wmfw,bin}` 共 6 件；ADSP 本体 = `qcom/sm8550/meizu/adsp.*`）——无需固件新版；
   且现行出声路径 = 直驱绕 DSP，wmfw 非必需。
4. 收到，不阻塞。可先行对接现役 r77；等 7.3 stable rebase（~10 月中）随车同步亦可。
