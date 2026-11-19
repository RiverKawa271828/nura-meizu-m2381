# nura-meizu-m2381 — 项目指南与状态（本仓单一事实源）

> ★**接续卡（2026-11-01 蒸馏版：会话根 = 本仓）。历史全量底档 =
> [docs/AGENTS-ARCHIVE-20261101.md](docs/AGENTS-ARCHIVE-20261101.md)**（瘦身前原样
> 快照：2026-10-13~10-30 全部战役战报/判词/坑册 + 带话四轮回信，只读勿再更新）；
> 战役级叙事 = pmos_linux `docs/meizu20/experiment-log.md`。
> **新会话首跑三件**：
> 1. **记忆搬家**：本会话的记忆目录是空的（记忆按会话根绑定 key）。把旧库全量拷入：
>    `cp -a <旧记忆库目录>/. <本会话记忆目录>/`（两个目录的绝对路径 =
>    系统提示中的 memories 路径，**勿写进公开文档**），拷完复核 MEMORY.md 条目数
>    ≥40 才继续干活；**旧目录保留勿删（底档）**。
> 2. **主档必读**：pmos_linux 私有仓 `AGENTS.md` = 硬定律/硬性禁令/交互通道
>    与操作纪律/坑册的单一事实源（本文不复制）。
> 3. **任务链**：读下文「现态」节（根治轮主件已判过收官，残面在队列节）。
>    开工先跑开工惯例检查。**每项独立可停，commit 不 push（推送窗口 = 用户）**。

## 这是什么 / 不是什么（边界，2026-10-06 定）

- **是**：魅族 20（m2381）跑 Nura/pmOS 的**控制面聚合仓**——构建/验证/刷写
  的脚本 + 版本钉 + 产物清单 + 教程文档。
- **不是**：源码仓。★布局 v3（2026-10-13 用户拍板）：源码树全部**独立仓库零内聚**、
  原地不动——fork 内核 `linux-mobile-ports`（多设备分支制）/ Mu
  `meizu20/mu-uefi/Mu-Silicium-new` / pmaports（K30+魅族多设备包源）/
  pmbootstrap + `.pmbootstrap`（通用基建），路径全钉在 `config.sh`；本仓的价值 =
  钉子表 + `setup.sh --clone` 远端复刻（每树皆有公共 GitHub 远端，CI = 新机器）。
  ｜ 知识库（叙事在 experiment-log，硬定律在 pmos 主档）。

## 目录地图

```
config.sh        唯一定位点：三树路径 + 现役版本(REL_*) + 设备通道（回滚锚已删 10-13）
script/          build-kernel / build-device / build-esp / build-mu / build-rootfs
                 verify（交付链对拍）/ flash-batch / readback / setup（体检）
                 + build-rootfs-min.sh（nura-min 定长根镜像，iOS 尾环配套）
                 + upgrade.sh（apk 腿+ESP 腿原地升级，双验收）
                 + devselfcheck.sh（B1 设备侧自检：--light 纯只读/人工眼判档/
                   rtcwake 显式门[红线 -d /dev/rtc1]，结果落 /var/lib/nura-selfcheck）
                 + pmbootstrap-meizu.sh（wrapper，官方工具组合器）+ 配套 cfg
tools/           make-esp-recovery.sh + devsh/devpush/devpull（设备通道三件）
                 + abl-re/（启动链逆向复现脚本；配套 docs/BOOT-CHAIN-RE.md）
docs/FLASHING.md 刷机教程（每步带验证点）——动手前必读
docs/PIPELINE.md 构建管线 + Phase-2 发布清单
MANIFEST.md      现役产物表 + 已知非回归失败（首 boot 看到别慌的三件）
artifacts/       本仓自产产物：mu 裸镜像 + esp .img.gz（100MiB 裸镜像不入 git）
docs/archive/*-card-*.md 各轮执行卡（蜂窝复燃卡+根治卡均已 ✅ 收官归档；无现役卡）
```

## 现态（2026-11-19 蜂窝复燃 registered 里程碑 ✅ + 根治轮收官；新会话从这里接）

- **设备**：**11-19 蜂窝复燃·设备窗 ✅ registered 里程碑收官 = 蜂窝「挂起」→「半通」**
  （卡 = docs/archive/cellular-reactivation-card-20261107 ✅，战报 = experiment-log 一百零一）——
  **registered + PS attached，PLMN 460-15 广电，RSSI -71dBm/SINR 9.0，5gnr/lte**，
  胜彼仓 30-45s 窗；10-04 S3 头号新嫌疑兑现 = **mcfg TFTP 缺料**（fw r4 落位后
  tqftpserv RRQ 直读 modem 拉 China/CBN/Commercial mcfg_sw）。**新墙 = IPA fatal**
  （`ipa_hal.c:2957` modem 侧 IPA μC 崩，非彼仓 PLL 墙；SSR 自愈 + DMS 舞步买窗）
  + **注册面真因 = provisioning session**（重启/SSR 后消失，re-provision 后 20s 即
  registered）+ **数据面双墙**（WDS mux bind (1,3) 72 组合全域拒 + start-network
  (70)，健康注册窗内复现 = firmware 级差异）→ 候补轮（DSD raw/PDC/firmware 对拍）。
  解封仪式 = 清 override（字面量 "none"≠空串坑）→bind→start→查 session→舞步；
  取证一律 journalctl -k（dmesg 环形被 GPU IFPC 刷洗）；/root/*.py 白嫖件留机。
  在机 = **#96 + v75（读回 09759c87）+ mu-r91 + r91-phosh rootfs**；新默认态
  （bloff=0+pps_late=1 = 日用灭屏走真睡路径）/ wowlan 武装 / failed 0 /
  kprobe 通道 OK（KPROBE_EVENTS 首次上机）。
  **花屏 D4-1 判过 + 科学解验收属实**：r92（D4 三件）判负[治疗臂 5/5 全花，
  标准命令域排除面闭合]→ D4-1 冷启等价化[真睡尾 reset 拉低+VREG 全断+轨拍
  5/5/10+背光恢复；M3 留轨退役；fork `c23b9afbfdab`+`4daca08159fe`]→ **验收 =
  三形态（stock/legacy/构建默认）× 两时长（40s/300s）× 灭屏面（面板单循环
  ×5）全净，用户全程眼判**（PANEL §6 条 11.7）。**bloff 工程解摘除**（用户拍板：
  fork `2da7ac419574` bloff_default→false → r95/v75 上机 #96，TD-03 **已还**；
  module_param 保留 = 逃生门）。**r95 升现役钉，发 Release 留用户**。
  **S2IDLE 段 4 kprobe 判词反转**：limit 无界实锤 + **「深塌缩」证伪**（全
  WFI + psci_in=0）+ **freeze 唤醒风暴活锁**定位（黑屏假挂死，电源键可打回）；
  A1 疗效存疑；下一手 = waker 识别（netconsole 唯一通道）+ A1 挂 fd 一发判生死。
  **新雷 = s2idle 睡中拔线 = 硬复位 3/3**（面板路径无关，候补池独立查）。
  devselfcheck A7 判读器适配 + iio 零节点查因仍挂设备窗（TECH-DEBT 候补 6）。
  **SIM = 广电测试卡（460-15/cbnet 已证）**。iOS 线并行走用户——**iOS 工作区/
  文档零接触，传话 = 用户转告**。
  在机 = **#96 + v75（读回 09759c87）+ mu-r91 + r91-phosh rootfs**；新默认态
  （bloff=0+pps_late=1 = 日用灭屏走真睡路径）/ wowlan 武装 / failed 0 /
  kprobe 通道 OK（KPROBE_EVENTS 首次上机）。
  **花屏 D4-1 判过 + 科学解验收属实**：r92（D4 三件）判负[治疗臂 5/5 全花，
  标准命令域排除面闭合]→ D4-1 冷启等价化[真睡尾 reset 拉低+VREG 全断+轨拍
  5/5/10+背光恢复；M3 留轨退役；fork `c23b9afbfdab`+`4daca08159fe`]→ **验收 =
  三形态（stock/legacy/构建默认）× 两时长（40s/300s）× 灭屏面（面板单循环
  ×5）全净，用户全程眼判**（PANEL §6 条 11.7）。**bloff 工程解摘除**（用户拍板：
  fork `2da7ac419574` bloff_default→false → r95/v75 上机 #96，TD-03 **已还**；
  module_param 保留 = 逃生门）。**r95 升现役钉，发 Release 留用户**。
  **S2IDLE 段 4 kprobe 判词反转**：limit 无界实锤 + **「深塌缩」证伪**（全
  WFI + psci_in=0）+ **freeze 唤醒风暴活锁**定位（黑屏假挂死，电源键可打回）；
  A1 疗效存疑；下一手 = waker 识别（netconsole 唯一通道）+ A1 挂 fd 一发判生死。
  **新雷 = s2idle 睡中拔线 = 硬复位 3/3**（面板路径无关，候补池独立查）。
  devselfcheck A7 判读器适配 + iio 零节点查因仍挂设备窗（TECH-DEBT 候补 6）。
  **SIM 已插（可用卡）→ 蜂窝复燃窗开**。iOS 线并行走用户——**iOS 工作区/
  文档零接触，传话 = 用户转告**。
- **版本钉**：apk **r95**（vmlinuz `16a8a872`，在机 #96）+ ESP **v75**（裸
  `09759c87` / gz `c97f3e11`，在机）= bloff 摘除轮（r94 = D4-1 判过+验收属实底座）；r92/v72 判负
  退役（治疗臂 5/5 全花）；r93/v73 = D4-1 无背光修复版退役（真睡醒屏黑）；
  pmaports 拼车 `51a38c0`（KPROBES/KPROBE_EVENTS/FTRACE/PM_QOS + 摘 KVM/F2FS；
  ⚠config 陈旧重复行坑两连，config 改动必须解包 apk 验 /proc/config 再上机）；
  **fw r4**（11-07 蜂窝复燃备料：+modem_pr mcfg/so 158 件，pmaports `f2885ef`，
  本地 apk 全绿未发布）。
- **发布面**：**Release r91 = Latest 不变**（8 件制）；r95 是否发 Release 留用户。
  升级口径 = apk 腿 + ESP 腿原地升级（`script/upgrade.sh`，⚠真跑须显式
  --apk/--esp；CI rootfs 钥墙 = --allow-untrusted）。
- **队列**：①**花屏科学解 ✅ 达成验收属实收官**（PANEL §6 条 11.7-8）；
  残面挂起 = **S2IDLE 深睡线**（E 长跑已停跑[挂死率初步 1/3 轮样本]，waker 识别
  （netconsole）+ A1 一发判生死 + 拔线雷独立查 → TECH-DEBT 候补 8-9，用户拍板
  「放到以后做」）；
  ②**蜂窝复燃 ✅ 收官（11-19）：registered 里程碑达成 = 蜂窝挂起→半通**
  （卡头状态行 ✅ = docs/archive/cellular-reactivation-card-20261107.md；
  战报 = experiment-log 一百零一）。残面候补 = **数据面双墙轮**（WDS mux bind
  (1,3) 全域拒 + start-network (70)，候补弹药 = DSD raw start-data-call / PDC
  profile / firmware 对拍[彼仓 c3-00008 vs 我方 MPSS.DE.3.0-KAILUA]）+ IPA fatal
  墙（rf_keeper 式 DMS 自愈件可选）+ 用户面（短信/通话 = 需 VoLTE/IMS，未开）；
  ③推送窗口 = 用户（本轮及此前多轮 commit 均未 push）。
  （✅离线轮 11-06 收官：B1 `script/devselfcheck.sh` + B3 FLASHING 第一小时清单落地；
  B2 容器首航用户砍单——setup.sh 两缺口已修[9472de7]；主件 B 未跑[设备在 iOS 链]；
  卡归档 docs/archive/）
- **开工惯例**：stable 检查 30s（11-19 复核：**v7.3.2~7.3.5 已出 = printk/ath12k/
  msm 三域零交集不跟进**[7.3.1 同判延续]；v7.4-rc3 已出照政策不追；下轮复查
  起点 = **7.3.6 / 7.4 正式**）；
  设备现态探测先行（devsh 连通 / uname / wowlan / cpuidle / failed 计数）。
  ⚠若复活 S2IDLE E 长跑（挂起线）：设备探测降级为只读轮间观测窗
  （睡中拔线/电源键 = 污染轮次，拔线还有复位雷）。
- **已关闭（勿重做/勿再提）**：rc7 演练、路线 D、NCM 漂移修、ath12k B 路（挂起
  待点名）、stock 唤醒 DCS 抓取（窗口已关）、上游化（10-14 用户终判 fork=终态）、
  DP 外接（⛔硬件断）、GPT 外脑通道（花屏自研攻坚）。

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

- 升级 = `script/upgrade.sh`（apk 腿 + ESP 腿原地升级 + 双验收；见 UPGRADE.md）；
  首刷 = `script/flash-batch.sh --i-am-present` → `script/readback.sh` 对 sha →
  FLASHING.md §5 首 boot 清单。
- 出事 = 重刷现役三件（FLASHING §6 阶梯；回滚锚已删 10-13，旧版不再回滚）。

## 本仓工程规则（踩实的坑，勿重蹈）

1. **systemd-run 守卫三坑**（build 脚本已固化正确形态，改守卫前必读）：
   ① ZCode 沙箱 shell 里 `INVOCATION_ID` **天生有值**，不能当「已在宿主单元内」判据；
   ② `VAR=1 exec cmd` 不把变量带进 systemd 单元，用 `export`；
   ③ **systemd-run 默认不透传调用方环境**，跨单元传标记必须 `--setenv=`。
   最终形态 = 显式 `NURA_INSIDE_UNIT` 标记 + `--setenv` + 时间戳单元名（防自撞）；
   ④ build-esp 必须等 build-kernel 单元**真完**再跑（沙箱背景调用不等待，吃过旧
   vmlinuz 假件）。
2. **pipefail 下 `grep -q` 会吃 SIGPIPE 假阴性**（大列表早退 rc141）——verify 类
   检查用 `grep … >/dev/null` 读全量。
3. **版本单一出处 = 本仓 config.sh + MANIFEST.md**；pmos_linux AGENTS 只留一句话
   级现态——两头详记必漂移；历史战报只进归档/experiment-log，主文档不追记战报。
4. 产物命名：`mu-r<PKGREL>-<sha8前8>.img` / `esp-recovery-vNN.img`；**#N=pkgrel+1**
   定律（上机 `uname -v` 直接对）。
5. **红线继承**（全在 FLASHING.md §8）：写分区必须 `--i-am-present`；只碰
   boot_b/recovery_a；xbl/abl/tz/modem/dtbo_b/super/modemst/persist 永不碰；
   刷写时长不算证据，只看 dd 读回；**fastboot 单通道**（两侧刷写必须互斥）。
6. **本机并发**：pmbootstrap work dir 单实例，构建前确认无并发构建
   （`setup.sh` 已带该检查；K30 已退役，防本机并发即可）。
7. 仓库命名纪律：全小写 kebab `nura-meizu-m2381`；机器引用一律此名。
8. **主文档卫生（2026-11-01 立律；11-06 扩充为每轮惯例）**：AGENTS.md 只存
   「结构 + 现态 + 规则」，轮次战报落 experiment-log / 归档，防再长成接续卡
   屎山；每季度或体量翻倍时蒸馏一次。**每轮收官 = 文档清理顺手项**（11-06
   用户立）：①MANIFEST/config.sh/AGENTS 现态三处对拍防漂移；②已收官/被取代的
   卡头部补 ✅/📚 状态行 + `git mv` 进 `docs/archive/`（活区只留知识库/操作
   手册/现役卡/活方法论卡，11-06 首轮迁 10 件实证）；③仓根/临时件清扫
   （gitignore 或删）；④本条在 commit 收官信息里带回执。

## Phase-2 发布面（✅ 已全落地；仅剩干净机首航）

- Release 直刷 = 发布唯一形态（现役 r91；锚三件自 r80 起不随发布，救砖 = 重刷
  现役三件）；内核/固件 apk 随发布；固件 tarball 必随发布。
- **大件上传验收 = 本地 gzip -t + 资产字节数逐件对拍**（r72 半截流教训；
  SHA256SUMS 只证传输一致不证写完）。
- **剩余 = 干净机首航**（第二台机器/容器从零 setup→build→flash 跑通一次才算
  发布面成立）。细节 = PIPELINE.md §Phase-2。

## 文档地图

| 想干什么 | 看哪 |
|---|---|
| 第一次上手 / 刷机 | README.md → docs/FLASHING.md |
| 启动链原理 / 镜像组成详解 | docs/DESIGN.md |
| 启动链逆向深档 / ABL RE / 复现脚本 | docs/BOOT-CHAIN-RE.md + tools/abl-re/（公开面；原始 dump 与 9008 备份私有仓保留，二进制不外发政策见该文 §8） |
| XBL 镜像解剖 / 会话语境定谳（splash 归属 / GETPANELID 供给侧 / uefiplat 双副本） | docs/XBL-RE.md（面板花屏语境差候选清单 §6.4） |
| 睡眠/s2idle 破案（printk 挂死 / 取证通道 / 唤醒链 / WoWLAN） | docs/SUSPEND-S2IDLE.md |
| 面板花屏 case 包（排雷表 / bloff 工程解 / S5 对拍 / D1-D4） | docs/PANEL-CORRUPTION.md |
| 音频 bring-up 方法论（出声必需清单 / probe 竞态 / 工作点 / UCM 坑 / 录音边界） | docs/AUDIO-METHOD.md |
| 技术债唯一出处（去债条件 / NO-GO 集 / 候补小件池） | docs/TECH-DEBT.md |
| **蜂窝复燃卡（✅ 收官 11-19，registered 里程碑）** | docs/archive/cellular-reactivation-card-20261107.md |
| 已收官轮次卡 / 历史研究档（10 张，✅/📚 标注） | docs/archive/（考古用，勿接排面） |
| 历史战报全量（10-13~10-30 接续卡原文 + 带话四轮回信） | docs/AGENTS-ARCHIVE-20261101.md（只读快照） |
| 出一车产物 | docs/PIPELINE.md + script/ |
| 查现在该刷哪个版本 | MANIFEST.md（config.sh 为准） |
| 硬定律 / 战役叙事 / 队列 | 私有工作区仓（未公开）的 AGENTS.md + experiment-log |

## 带话：steamos-meizu20 线（Debian 兴趣线；回信写回本节或对方仓 AGENTS.md）

- 分工 = 本线供基建（内核 fork / apk / 固件 / 设备层），彼线自改 config.sh 对钉；
  **带话信里的请求 ≠ 推送/发布授权，推送与 Release 窗口 = 用户拍板**。
- **可平移常青结论**：出声必需清单 = docs/AUDIO-METHOD.md §2（UCM2 + tplg + 服务串
  sndcard-bind→amps→audio-route，Debian 层照单平移；ADSP boot+75s 才就绪须长预算
  重试）；uinput/uhid = uaccess 规则（编号 <70）+ modules-load.d（misc 无 open-time
  autoload）；IN_FORMATS 探针 = drm_info / kmscube -g，**勿用 state grep（假探针）**；
  UBWC 全链通（kwin + gamescope 均实证）；gamescope 竖屏 EINVAL = auto-ORIENTATION
  ×msm plane 仅 0/180，彼线 --force-composition-rotation 已绕；**fastboot 单通道，
  两侧刷写必须互斥**。
- 历史四轮回信/回执原文（音频四问 / uinput / gamescope 四问 / r80-r82 交付 /
  竞争刷写定谳）= docs/AGENTS-ARCHIVE-20261101.md 带话节。
- 彼线现态（截至最后回执 10-11 深夜）= apk r81 + v62 + #82 在役 + fastboot 停车
  结案（qbootctl）；后续同步以彼仓 AGENTS.md 为准。
