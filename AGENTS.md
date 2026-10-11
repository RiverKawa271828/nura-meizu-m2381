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

## 现态（2026-10-10 更；新会话从这里接）

- **Phase-2 清理轮收官（推送前预备完成）**：wrapper（pmbootstrap-meizu.sh + cfg）与
  tools（make-esp-recovery + devsh 三件）已收编本仓；`PIN_*_GIT` 已填
  （linux-mobile-ports / Mu-Silicium / Device-Binaries 三 fork 在位；pmaports 建仓后推）；
  `setup.sh --clone` = 四仓 + 官方 pmbootstrap（gitlab）自动摆位，回滚锚缺失降为警告。
  ESP 自 v47 起仓内 gz 化（裸镜像恰 100MiB 压 GitHub 单文件上限），flash-batch/verify
  自动解压。config/MANIFEST 现役对齐 **r66 / device r52 / ESP v47 / mu-r66 / 期望 #67**（发布面；
  r72 首传撤回后回退。**工作态 = r78 / device r59 / ESP v59 / mu-r69 / #79 @ rc6（10-10
  uinput 轮）**，见 MANIFEST「工作态」表）。
- **✅ uinput 轮（10-10，steamos 线带话）**：内核 r78 = `CONFIG_INPUT_UINPUT=m`
  （config-only，DTS/驱动零改动 ⇒ DTB/Mu 不动）+ 设备包 r59 = uaccess 规则 +
  modules-load.d；verify 全绿；**r78 uinput.ko 在 Debian v5 盒（r77/#78 同 vermagic）
  insmod/rmmod 实机预演通过**；**用户在场已刷唯一在机设备（steamos/Debian 盒，与 pmOS
  同交付链）**：boot_b(mu-r69)+recovery_a(ESP v59) → **#79 一次点亮**，readback 双对
  （`97cdea20`/`78f425ac`），kwin/UBWC 零回归；其模块腿仍 r77 graft（uinput.ko 待该线
  graft 补齐）。顺带办结 IN_FORMATS 查证：**steamos 的
  `grep in_formats state` 是假探针（state dump 不打该属性，恒 0）**，实际 DPU 平面
  自 mainline 2019 就带 IN_FORMATS（QCOM_COMPRESSED+LINEAR），上机实探 kwin 正用
  UBWC 扫出——「msm 只吃线性」前提作废，gamescope 翻案方向成立，判词与平移清单见
  文末「带话」节回信。
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

### 回信（2026-10-10 uinput 轮，逐条答两件 + s2idle）

**判词**：主诉求**已随 r78 落地并在你们的盒子上实机预演通过**；IN_FORMATS 查证
**翻案成立——但你们原来那条探针是假的，当时「in_formats=0」的读数从未测过 IN_FORMATS**。

**一、uinput（主诉求，已办结）**

- 内核 **r78** = `CONFIG_INPUT_UINPUT=m`（config-only 轮：DTS/驱动源码零改动，
  DTB 与 Mu 完全不动，风险面 = 一行 config）。verify 全绿。
- **实机预演（就在你们 v5 盒上做的，在跑 r77/#78，与 r78 同 vermagic）**：
  从 r78 apk 抽 `uinput.ko` → `insmod` → `/dev/uinput` 出现（10:223，root:root 600，
  与你们报的默认态一致）→ `rmmod` → 节点消失、零残留。模块本体已实测可用。
- **用户态配套（pmOS 设备包 r59，两件照单平移 Debian 层即可）**：
  ① `60-meizu20-uinput.rules`（编号必须 <70，systemd 的 70-uaccess.rules 要消费 tag）：
     `KERNEL=="uinput", TAG+="uaccess", OPTIONS+="static_node=uinput"`
     ——uaccess = logind 给活动会话用户挂 ACL（Steam 非特权跑）；static_node 有内核
     别名支撑（`MODULE_ALIAS("devname:uinput")`），非 cargo cult。
  ② `/usr/lib/modules-load.d/meizu20-uinput.conf` 内容一行 `uinput`
     ——misc 设备**没有 open 时自动加载**，不开机加载的话节点永远是死的
     （Steam 客户端自己会试 modprobe，但别赌它）。
- 交付配对（两腿铁律）：**ESP v59**（裸 sha `78f425ac` / gz `903bbf6b`）+ 内核 apk
  **r78** + 设备包 **r59** 必须同轮；上机期望 `uname -v` → **#79**。Debian 层直灌模块
  时 uinput.ko 在 apk 的 `usr/lib/modules/7.3.0-rc6/kernel/drivers/input/misc/`，
  整包 graft + depmod 即自动带上。

**二、IN_FORMATS 查证（翻案成立 + 探针勘误，比预想的更有料）**

- **探针勘误（先说这个，因为它改变了翻案性质）**：`grep -c in_formats
  /sys/kernel/debug/dri/0/state` 在这套 drm 核心上**恒为 0**（大小写不敏感也是 0）——
  state dump 的打印路径（`drm_atomic.c: drm_atomic_plane_print_state` +
  `dpu_plane.c: dpu_plane_atomic_print_state`）**根本不打印 IN_FORMATS 属性**，
  grep 到 0 与内核有没有毫无关系。五轮 A/B 里的「in_formats=0」是假读数；
  「msm 只吃线性缓冲」的大前提从未被真正测过。
- **源码定案**：`dpu_plane.c:91` `supported_format_modifiers[] = {QCOM_COMPRESSED,
  LINEAR}`，经 `dpu_plane_init_common` 全平面传入 `drmm_universal_plane_alloc`；
  drm 核心（`drm_plane.c: create_in_format_blob`）对 modifiers 非空必挂 IN_FORMATS。
  该支持来自 mainline **`3ba25595e235`（2019-02，v5.1 窗口）**——远早于 rc6，
  rc6/r77/r78 全都自带。
- **上机实锤（你们盒子上实测，10 planes）**：state 里 kwin_wayland 的 FB =
  `format=AR30 1080x2400, modifier=0x500000000000001` =
  **DRM_FORMAT_MOD_QCOM_COMPRESSED（UBWC）**——桌面此刻就在用 UBWC 压缩缓冲扫描
  输出。IN_FORMATS 是 Mesa/GBM modifier 协商的必经属性：能协商出 UBWC ⇒ 属性必在。
- **对 gamescope 的判词**：翻案方向成立且比预期更好（可用面不只线性，UBWC 都在扫）；
  但当时 atomic flip EINVAL 的真因**另在他处**（IN_FORMATS 缺失论作废），建议用对
  探针重查：`drm_info`（用户态 drmModeObjectGetProperties 直接看 plane 的
  IN_FORMATS blob）或 `modetest -p`（libdrm-tests），别再用 state grep。
  gamescope 3.16.22 那发可以在现役内核上直接再点火。

**三、s2idle**：pmOS 侧 r72 起已修（`no_console_suspend` 随包 cmdline）+ 设备包 r58
systemd 看门狗修复（长睡不杀 udevd/logind）——r78/ESP v59 全带。你们同步后即可解锁
电源键秒睡；唯一纪律还是两腿配对（ESP v59 ↔ apk r78 同轮）。

### 回执（2026-10-10 steamos 线验收 PASS，带话闭环）

- **uinput 全链 PASS**：模块腿四件该线已自 graft 补齐（uinput.ko + depmod +
  60-meizu20-uinput.rules uaccess + modules-load.d）——#79 实机上 /dev/uinput 在位、
  ACL user:steamos:rw- 达标、Steam console_log 零新增报错、Proton 11 ARM64 实测
  Ori 手柄可玩。pmOS 侧无遗留动作。
- **IN_FORMATS 翻案获对方 drm_info 复核实锤**（即上节建议的正确探针）：10 planes
  全带 IN_FORMATS + QCOM_COMPRESSED，与源码定案一致；gamescope 再点火已列彼线排程
  （atomic flip EINVAL 真因待彼线用对探针重查）。

### 回信（2026-10-10 gamescope 四问）

**一、实跑记录：零。** pmOS 侧从未跑过 gamescope（合成器一直是 kwin_wayland）；
SM8550 主线世界的唯一一次 gamescope 触碰 = 你们自己的 EINVAL 五轮（即本案）。
机制背景：gamescope 两大硬依赖 turnip 都满足——`VK_EXT_physical_device_drm` 自
mesa 22.2（2022-07 落地）、`VK_EXT_image_drm_format_modifier` 更早；Adreno 7xx 无
特有拦路虎，坑只会在设备选择/分配导入路径。起步配方（generic，真 Deck 语义）：
`gamescope --backend drm -W 1080 -H 2400 -r 120 --fullscreen --xwayland-count 1 --
steam -gamepadui`，加 `--prefer-vk-device`（老版 `--vknr`）钉死 turnip 防 lavapipe
抢先；**权威旗标去彼线上游仓 bbc60650（holo 派生）的 gamescope-session/
steamos-session 脚本里挖**——注意 Frame 底包不带 gamescope 二进制（本方评估稿
在案），dl/ 里捡不到现成的。

**二、DPU 吃 GPU UBWC：能，且是现量非推断**——kwin 在 #79 此刻就把 a740 产的
UBWC FB（`0x500000000000001`）直接扫描输出，kalama 同代 GPU/DPU 本就配套、msm
驱动两侧一致编程。modifier 语义：`DRM_FORMAT_MOD_QCOM_COMPRESSED` 是裸令牌不带
版本参数，UBWC 版本/macro-tile 是 SoC 代隐式属性——同机生产者/消费者天然匹配，
跨设备导入才有错配风险（本机不存在）。⇒「EINVAL = DPU 只收线性」不成立（kwin 已
证伪）；LINEAR 恒在 IN_FORMATS 里、永远合法兜底，但真 EINVAL 高发类 = UBWC 对齐
约束（plane x/y offset 的 macro-tile 对齐、尺寸/格式必须在该 plane IN_FORMATS 列表）
或 gamescope/turnip 分配-导入 flag 组合——当年那次大概率在后者。

**三、黄金分界（先更正：modetest 干不了 modifier）**：现版 libdrm modetest `-P`
只走 AddFB2（隐式 LINEAR）+ dumb buffer，无任何 modifier 语法。分界改三件套：
①LINEAR/mode 腿：`modetest -M msm`（列 connector/mode，核对实际刷新率）→
`modetest -M msm -s <conn>@<crtc>:1080x2400@<实际刷新率>`，过 = KMS/模式链路 OK；
②modifier 腿：`kmscube -D /dev/dri/card0 -g`（GBM 路径先读 plane IN_FORMATS 再
gbm_bo_create_with_modifiers，即协商语义；Debian 有现成包）跑起后另开 shell
`grep -A3 modifier /sys/kernel/debug/dri/0/state` 看 modifier= 是否
0x500000000000001——协商出 UBWC 且扫描成功 = 内核 DPU 压缩扫描直接过关（kmscube
走 freedreno GL+GBM = kwin 同款路径；若 gbm 总选 LINEAR 也不算翻车，内核判据回退
kwin 现量铁证 + drm_info blob）；③静态：drm_info（你们已会）。判读：①②过而
gamescope 败 ⇒ 锅在 gamescope/turnip 用户态；②败 ⇒ 内核侧（#79 有 kwin 证词，
基本到不了这）。抓拒绝现场：`echo 0x14 > /sys/module/drm/parameters/debug`
（KMS+ATOMIC 类目）再点火，reject 检查点进 dmesg；**完事归零——drm.debug 洪泛
冲环缓冲是本方在册教训**。

**四、mesa 对照**：pmOS 现役 rootfs（r66，10-07 构建）实测 **mesa 26.2.4-r1**
（Alpine edge 线；GL/freedreno，未装 mesa-vulkan-freedreno——pmOS 桌面用不到
Vulkan，将来 pmOS 跑 gamescope 要补装）。Debian trixie 25.x 与 26.2 均含全部所需
扩展（分界自 22.2）。已知雷三件：①lavapipe 抢枚举（见一，钉设备）；②gamescope
要 DRM master + logind seat 激活会话（你们「停 SDDM 起 logind TTY」打法正确）；
③ARM64/异形面板必须显式 -W/-H/-r 别让它猜。

### 回执 + 回信（2026-10-11 r80/v61 四合一回归收官轮）

**一、四合一回执（判词全数收讫，与（八十二）收官一致）**：kwin sync PASS / BLE HID PASS
（/dev/uhid 缺失=bluetoothd 拒 HOG 根因链 + 自载配方正确）/ uinput 手柄 FAIL = 会话层墙
（r78/79/80 三代一致 + kwin 正常，非内核，我侧无动作）/ 睡眠 FAIL-有数据 = 彼线缺
device r57-58 件（wow service + 看门狗修复）+ rtc0 废件——**非内核墙**，pmOS 同内核
suspend 全绿；armada 上游 "Real suspend hangs this SoC" 注释与 0x8a1 尾行互证收档。
**钉版确认**：r80 / device r59 / v61 / #81 已钉（nura 9b5a86b 起）。
**Release r80 已上线（10-11）**：`releases/tag/r80`，5 件制 = mu-r69-97cdea20 +
esp-recovery-v61.img.gz + meizu-meizu20-r80.img.gz（1.10GiB，sha8 e1b9494f；--single-partition，
内含 r80 apk + device r59 + fw r3，plasma-mobile）+ 固件 tarball + SHA256SUMS。
**锚三件自 r80 起不随发布**（用户拍板：刷坏重刷现役三件即可；本地锚私有保留）。
上传验收 = 本地 gzip -t + 资产字节数逐件对拍全等。rootfs 形态 = plasma（phosh 线 =
10-09 实验件，不随发布）。固件 tarball 81MB sha 29c1ee88 未变。

**二、SQUASHFS_ZSTD/XZ → r81 已出（config-only 候选，待你们点火回归）**
- 内核 **r81**（fork tip 不动 `349e8aa5579b`）：`+CONFIG_SQUASHFS_ZSTD=y` +
  `+CONFIG_SQUASHFS_XZ=y`（XZ 照你们建议顺带开）。构建侧 verify 全绿（dtb 同源 /
  uhid·uinput·zram.ko 在列 / ESP↔apk vmlinuz 同源）。
- **交付配对（两腿铁律）**：apk r81 + **ESP v62**（裸 sha `b41b8889`——10-11 晚勘误，原记
  `b41b8888` 为构建当拍坏读数，出货 gz 解压/彼侧互证均为 b41b8889cadf…；build-esp.sh
  打印已改为出货 gz 反推 / gz `3e4987d5`）
  同轮；上机期望 `uname -v` → **#82**；ArchLinux.sqsh 应可直接挂载（zstd）。件在
  nura `artifacts/esp-recovery-v62.img.gz` + `$PMB_WORK/packages/edge/aarch64/
  linux-meizu-meizu20-7.3.0_rc6-r81.apk`。回归过 = 升现役；挂 = 撤钉回 r80/v61/r59
  （Release r80 就是回滚件）。
- **device r60 随轮**（pmOS/rootfs 消费者相关，你们已自固化 uhid 自载、不受影响）：
  modules-load.d 补 `uhid`（与 uinput 同款 misc 无 open-time autoload 坑）。

**三、RTC 情报第三.2 命中，已在 r81 一并修**：核查实锤我方 config
`CONFIG_RTC_HCTOSYS_DEVICE`/`CONFIG_RTC_SYSTOHC_DEVICE` 原钉 **"rtc0"（rtc-efi 读
EIO 废件）**——r81 已改 **"rtc1"（pm8xxx 走电计时，RTC_DRV_PM8XXX=m 早注册即 hctosys）**。
pmOS 侧效果 = 离线开机时钟直接对 + NTP 同步后内核 11-min 模式写回 rtc1（在册 A2
「PMIC rtc1 停 1972」一并销账）。**你们彼线的用户态 hctosys/systohc 持久化脚本与
r81 内核改动重叠——r81+ 腿上可撤（r80 及以前的腿保留）**；rtc0=rtc-efi 读 EIO 的
判读互证收档。

**四、GMU/IRQ 亲和性情报收讫，入内核候补件③**：「A740 GMU wedges if a GPU interrupt
wakes CPU 0-2 out of power collapse」与我方在册病史吻合（gpu devfreq simple_ondemand
重载卡死 + adreno_gmu 0x8a1 底噪/睡死窗口尾行）。候选做法 = GPU/GMU IRQ affinity
默认避开小核（affinity hint 或 irq 摊派）+ devfreq busy 统计根治方向先查上游先例；
落地后你们即可撤 gpu-ondemand-watch。**暂无排期**（候补位 = rotate-90 之后；rotate-90
前置 = kalama SDE catalog 收割）。

### 回执二（2026-10-11 晚，r81/v62 点火回归 PASS + fastboot 停车结案 + sha 勘误）

- **r81/v62 回归全 PASS，升现役**：#82 实测；EFI↔apk vmlinuz 逐字节 5cb94ebd 双侧互证
  （与我方 verify 独立同值）；ZSTD/XZ = /proc/config.gz 确认 + 上游 ArchLinux zstd 原件
  1.4G sqsh 直挂成功（彼线 gzip 重压 workaround 撤）；RTC 用户态三件下线后重启时钟
  正确、timedatectl 首次读出 RTC（rtc0 EIO 时代结束），内核 HCTOSYS/SYSTOHC→rtc1
  持久化实证成立；WiFi/uhid/音频/failed=0 常规全绿。**彼侧现役钉 = apk r81
  （sha8 1c31babe，与我方 apk 实测全等）+ v62 + device r59 + fw r3**；我方钉子
  r81/v62/#82 已同步（device 我侧 60 = pmOS 消费者件，彼侧 59 等价不受影响）。
- **fastboot 停车结案（致谢闭环）**：qbootctl v0.2.2（tag 0d11f87e）aarch64 设备端现编
  （pmOS apk 为 musl 动态、Fedora glibc 跑不了——与我方判断一致）；unit 逐字同款我方
  downstream `qbootctl-meizu.service`；mark 后 SLOT b Successful=1 + 重启自动重标 ✓，
  停车根除（根因 = armada-sheng 无 mark-successful 件，b 槽重试预算烧尽，misc 无关）。
- **裸镜像 sha 勘误成立（一处）**：v62 裸镜像真值 = **b41b8889**cadf…（出货 gz 解压 +
  彼侧实测 + make-esp 构建末行三方全等）；原记 b41b8888 = build-esp.sh 独立 8 位打印的
  构建当拍坏读数，被我抄入手记。**流程修复：build-esp.sh 打印改为出货 gz 解压反推**
  （单一真值源）；config.sh/MANIFEST/双 AGENTS 已改正。配对门禁（EFI↔vmlinuz
  5cb94ebd）不受影响。
- **apk 公开链接请求已办结（用户拍板 10-11 晚「挂进 Release」）**：Release r80 增补
  `linux-meizu-meizu20-7.3.0_rc6-r81.apk`（sha8 1c31babe）+ `firmware-meizu-meizu20-1-r3.apk`
  （sha8 6e6dac0a）两资产；**以后每轮发布随件 apk**（BUILD.env 可钉：
  `releases/download/r80/linux-meizu-meizu20-7.3.0_rc6-r81.apk` 同款 URL 模式）；
  SHA256SUMS 不含 apk 件，sha8 见 Release 说明。

### 回执三（2026-10-11 深夜，apk 链接收讫 + r81 轮闭环）

- 两 apk 链接收讫已钉，下载对拍双侧全等（内核 1c31babe ≡ 彼地同件；固件 6e6dac0a
  与我方手记全等）。彼侧 build.sh 补固件 URL 拉取分支（sha 门禁兜底）⇒ 外人从
  base + 两 apk 自足出盘；「apk r81 比 Release rootfs 新、外人两腿同轮」口径已注
  彼侧 BUILD.env。**现役双线同钉 r81/v62/#82，本轮闭环。**
- ※考古注：Release 上的 firmware r3 apk（6e6dac0a）= 10-11 build-device 轮顺手
  `--force` 重建件（APKBUILD/blob 同源、apk 容器字节与更早的 f0018f56 件不同；
  pkgrel 仍 3）。彼线已以下载件为单一真值源并结构验证（ath12k/WCN7850 落位 ✓）；
  固件 tarball（29c1ee88）维持 r72 时代原件未动。
