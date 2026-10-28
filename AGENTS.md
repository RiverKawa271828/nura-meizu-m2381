# nura-meizu-m2381 — 项目指南与状态（本仓单一事实源）

> ★**接续卡（2026-10-13 起：会话根 = 本仓，用户拍板「只在 nura 推进适配」）**。
> 在本仓目录开的**新会话首跑必做三件**：
> 1. **记忆搬家**：本会话的记忆目录是空的（记忆按会话根绑定 key）。把旧库全量拷入：
>    `cp -a <旧记忆库目录>/. <本会话记忆目录>/`（两个目录的绝对路径 =
>    系统提示中的 memories 路径，**勿写进公开文档**），拷完复核 MEMORY.md 条目数
>    ≥40 才继续干活；**旧目录保留勿删（底档）**。
> 2. **主档必读**：pmos_linux 私有仓 `AGENTS.md` = 硬定律/硬性禁令/交互通道
>    与操作纪律/坑册的单一事实源（本文不复制）；取证叙事 = 同仓
>    `docs/meizu20/experiment-log.md`（最新 =（九十）（九十·乙），10-19）。
> 3. **任务链**（自包含两份计划）：①工作区内聚迁移 =
>    pmos_linux 私有仓 `docs/meizu20/workspace-migration-plan-20261013.md`
>    —— **10-13 已收官 = 零 mv**（源树全独立原地不动，nura = 控制面钉子表）。
>    ②云端构建 = **✅全链收官（10-14）**：#21 首绿+三层对比 → **硬件验收全过**
>    （CI 三件实机点亮 #87，读回逐字节；plasma 玩具态被覆盖，回滚件全在）→
>    用户拍板新版 → **#22 = r87 首发轮全绿（20m28s）→ Release r87 上线 Latest**
>    （waydroid 预装 + phosh 商店 flatpak + 摘 discover；8 件制含 device apk；
>    被取代的 r86 草稿已删，r85/r86 未发布在案）；台账/蓝本 =
>    docs/CLOUD-BUILD-CI-REVIEW-20261013.md。
>    ③设备日 = ✅**已收官（10-13）**：手动升级首验过（#87 + failed 0）+ waydroid
>    网络三层全闭（v4 策略路由/v6 补全/MTU clamp，酷安眼判 ✓）；**10-14 续 =
>    #88/v68/r62 双腿升级 + waydroid 复活✅酷安眼判 ✓**（离线恢复镜像 + Session/
>    Container RUNNING + v4 互联网/DNS 通；52_waydroid.nft 装包后首 boot 手工 `nft -f`
>    补应用一次，后续 boot 由 nftables.service 正常加载）。
>    ③·乙 plasma 玩具机 = ✅（10-14）：本地构建 plasma-mobile rootfs 刷机一次点亮
>    + waydroid 复活全链；**10-14 晚该态已被 r87 CI rootfs 覆盖**（回滚件照旧全在档）。
>    ④下轮 = **等 7.3 stable（rc7 已出（10-19 核，tag ec8bf828）→ stable ~10-25；
>    出 rc8 则顺延 ~11-01）→ rebase 专项**（用户点名开工）。**窗口期纯宿主预备 =
>    ✅四件全收官（10-19（九十·乙））+ ✅rc7 rebase 演练（10-19：98 提交零冲突重放到 v7.3-rc7
>    + 语义 sanity 四件全绿 + r89 编译验证[sha8 d8918256]；tag `archive/rc7-dryrun-20261019`@
>    `87ca59a3afac`；v7.3-rc7 对象已入本地仓；报告/正式轮清单 = docs/rebase-dryrun-rc7-20261019.md；
>    ⚠新坑：pmbootstrap-meizu.sh wrapper 无沙箱守卫，直调必须显式 systemd-run）**：carry-list 两查定谳 = **printk 上游未修
>    → `no_console_suspend` 留**（修复提案押后死寂，v7.3-rc6 代码原样）+
>    **ath12k 0012 不摘**（上游 Shenghan 件未合入；★定性修正：`0d777aa2ca77` = freq
>    range 域非睡眠回归；睡眠轴上游 Saikiran mhi.c 件压 review 八个月未合 → carry
>    三件全留；qrtr 悬案闭环：`544d85de4dc2` 确为真回归但修复 `6a5719cc3ef2` 已在
>    rc6 基线内）；**0xC4 旋钮预写+预构建** = fork `c1d84dcf80ec`
>    （`msm.zero_clkout_timing` 0644 运行时可写，默认现行为）→ apk r88（cc1ecc44）/
>    ESP v69（daf03fea）verify 走通（[4] 红=口径错位非真红，MANIFEST 工作态在册，
>    验证件不上机不发布）；ath12k 21s 三路候选 = A 关闭（无可吃件）/B 预案不预写/
>    C·D 判负（pmos_linux docs/meizu20/ath12k-resume-21s-options-20261019.md）；
>    printk 流程卡 = docs/printk-regression-2min-card.md（runtime 开关 rc6 树实锤）。
>    rebase 本体 = carry-list 重放 + 0xC4 拼车 + printk 复核 + ath12k
>    21s；7.4 前瞻雷随车（binder Rust 化 / kalama SDE catalog 收割 / `drivers/virt`
>    gunyah 复查点在册——7.3 全周期无 gunyah，驱动只进 merge window）。
>    **▶窗口期剩余任务（下会话照做）= docs/window-round-card-20261020.md**
>    （**✅10-19 晚已收官三项**：第 0 项窗口检查 = **stable 未出**[ls-remote 只到
>    v7.3-rc7 `ec8bf828`，rc8 未出，下会话开工仍须重跑本检查]；**1 蒸馏③ =
>    docs/AUDIO-METHOD.md 成文**[nura `782f3d1`，出声必需清单可平移 + probe 竞态
>    四层 + 工作点/响度封卷 + UCM 三坑 + 录音腿边界；pmos 队列卡 ③ 打勾 `f1b2d5d`；
>    带话素材 = §10 尾句「已公开成文」，用户转告 steamos 线]；**3 wrapper 守卫 =
>    pmbootstrap-meizu.sh 落 NURA_INSIDE_UNIT→systemd-run 守卫**[nura `0f3a3e4`，
>    沙箱 checksum 冒烟 exit 0]。**✅10-19 深夜（九十二）第 2 段收官三项**：
>    **4 花屏 S2 对拍表**[nura `8cbb1cc` 落 PANEL-CORRUPTION §6 条 3 余面 =
>    15 行对拍表：内容差 = flbo 13↔12 根因族 + initial_lines 3↔2 + DSC_CFG
>    bit17 + PPS 载体 0xA0↔0x0A，其余全等；自洽两侧成立 → 只记档，0xC4 仍首发；
>    stock debugfs 活读 DSC 1.2 机制性不可达 = F4 只得 evtlog 的深层原因]；
>    **7 upgrade.sh**[nura `e640683` 已点头件固化 + UPGRADE.md 一键脚本节；
>    设备腿首跑随下轮升级实机验证]；**2 相机卡**[pmos `1692ace` =
>    s5k3p9-driver-round-card.md：i2c 0x5a→0x2d 真值 + PHY 形态 + stock 节点
>    全属性 + DT 草案 + 首 ACK 判据 0x3109]。**▶0xC4 设备日 ✅ 收官（10-19 晨，
>    上排面全执行；定谳 = 0xC4 洗清）**：stable 复核仍未出（rc7 `ec8bf828` 止）；
>    备料 r88（cc1ecc44）/v69（daf03fea）全对钉（「APK_DIR 现无 linux apk」旧备注
>    作废——备料轮已补）；**upgrade.sh 设备腿首跑全绿**（apk r88 + ESP v69 → 实测
>    #89 + 读回 daf03fea 对 ✓）抓两坑根治入脚本（CI rootfs 烤 CI 临时钥
>    pmos@local-6acea657 = 本地钥 6aaed2ab 签的包必 UNTRUSTED 假绿 → 照 flash-batch
>    配方 --allow-untrusted 排雷 + apk add 超读窗假完成 → RC 标记回读；nura
>    `28fe8d6`，UPGRADE.md 勘误随件）；**两阶段定谳（用户在场眼判）**：默认态 12 次
>    s2idle 全净（含 C0 对照）=「真睡不受 bloff 影响」前提证伪（bloff 分支在
>    unprepare，suspend 的 DRM off 同走 ⇒ DDIC 全程不睡、毒源结构性不可达，§5④
>    入册）→ `knob default` 可达态修正实验：P1 阳性对照全花（历史 5/5 复现 ✓，
>    dsi_err status=4 每轮一条 = 链路真断 marker）+ 归零臂 5/5 全花零效应 ⇒
>    **0xC4 洗清 = 排雷表 #13 终审（最后一个寄存器级单变量负结果）**；病根维持
>    §4.4（DDIC sleep-out 自重初始化）；条 4 残余位（RBUF/INSERT_DCS bit16/仪式位
>    族）可达态可测但日用 bloff 结构性免疫 → 只记档不开工；附带实锤 = **r88 默认态
>    真睡日用干净**（nura `f3c7d33`/`8f82d06`/`d019040`）。收尾旋钮/bloff 复值 +
>    重启回日常复核绿。**设备现态 = 在机 #89 + v69 + r88 apk + CI r86-phosh rootfs
>    （device r60 + fw r3，用户 10-18 深夜刷回；非 r87 发布面 = waydroid/flatpak
>    缺位——日用完整态 = 择时重刷 r87 rootfs 或 apk 腿补 device r62，不急）**。
>    **▶下会话排面三钉（10-19 晨用户拍板「下个会话逆向试试，我要根治」）**：
>    花屏根治专项 = **docs/s5-rootcure-card-20261020.md**——主线 = S5 XBL/vendor
>    逆向（素材全在库，卡内有地图）+ **强烈建议的廉价首枪 = stock-DSC-content
>    旋钮 A/B**（H1 只测过包形态从未测过内容值；S2 表 #9-#15 四处内容差 = 现成
>    靶，Novatek demura 专利「重载按会话参数自选档案」直指它；r90/v70 → upgrade.sh
>    磨合链路半天内出判词）；判据钉死 = knob default 真睡×5 全干净 + 零回归。
>    rebase 仍等 stable（rc7 止）；窗口 5/6 调研件顺延不变。
>    每项独立可停，commit 不 push。已关闭：rc7 演练[勿重做]、路线 D[勿再提]、
>    NCM 漂移修[无需]、ath12k B 路[挂起待点名]、stock 唤醒 DCS 抓取[窗口已关]）。
>    ⑤**窗口期取证+小工作（10-19 用户拍板「下会话开始」）**：⚠**设备现役 = Flyme**
>    （用户备 root = adb+su；取证全只读，刷写红线不破；**回 pmOS 后这些窗口全失效，宜先做**）。
>    **取证四件（叙事落 pmos_linux experiment-log）**：
>    F1 stock FDT 全量回收（/sys/firmware/fdt→dtc，fallback /proc/device-tree 归档）+
>    stock 相机 open 内核日志 → **喂相机驱动轮**（s5k3p9 supply/MCLK/RST 映射，战役挂起件）；
>    F2 SWR 麦会话取证（tinymix 全量 idle vs VA 录音 vs B3/B4 源 + soundwire debugfs +
>    wcd938x dmesg）→ **喂麦克风复燃**（stock=SWR 域在册，= rebase 后下一里程碑）；
>    F3 modem EFS dd 存档 = modemst1/modemst2/fsc/fsg 四分区（只读；「内部 NV/EFS 贵路」
>    素材，蜂窝复燃）；F4 stock DPU/DSC 侧动态 dump → 喂花屏 S2 对拍（DSI ctrl 三态
>    10-06 已收勿重收）。**✅ 10-19（九十）四件全落袋**（素材 = meizu20-m1/
>    flyme-forensics-20261019/ 25 件，只读红线零破，mixer 拨动已回拨）：F1 fdt 791KB
>    （★旧判读修正「stock FDT 无 soundwire」作废 = 有 va_swr_master+swr-dmic×4）+
>    bootargs 全量（allow_mismatched_32bit_el0/irqaffinity=0-2/dis_id=4DB501）+
>    **相机 ACK 真值 s5k3p9sx id 0x3109 @0x5a ACQUIRE Success**（gn5sp START）；
>    F2 tinymix 418 控件全景（B3/B4=stock RXTX-TX3/4 与 VA-TX0/1/2 并存）+ 手拨通路
>    不通判词（Invalid DMIC Selection = stock SWR 路径要 HAL AFE 会话，0x3404:10→90
>    已回拨）；F3 EFS 四分区双侧哈希全 MATCH（「内部 NV/EFS 贵路」物证首落盘）；
>    F4 rm_status **DSC allocated:2** + evtlog 2000 行（dce_dsc_setup 每帧双块 =
>    花屏 S2 对拍真值）。小工作：蒸馏③④**未动**（大件写作留专注会话，③ steamos 在等
>    建议下轮首项）；花屏 §6 #2/#3 **✅双判负（无漏组/无缺位，PANEL-CORRUPTION §6 已更，
>    反强 r22 档案假说）**；hexagonrtc(hexagonrpcd) r7/r8 **✅收敛**（pmaports `69360d4`，
>    pkgrel 7→8 合法化包仓现态）。
>    取证毕设备去向留用户拍板（留 Flyme / 重刷现役三件回 pmOS，回滚件全在档）。
>    ★本轮四仓全部只 commit 未 push（推送窗口 = 用户拍板）；nura tip = 本 commit +
>    MANIFEST 工作态更钉（r88/v69 预构建验证件段）。
> 注：私有面（pmos_linux docs、meizu20-m1 取证）原地不动，路径照旧有效；旧文档里
> 「pmbootstrap work dir 与 K30 共享须串行」已过时（K30 退役即失效；10-13 布局 v3
> 零 mv 确认树不搬，只防本机并发）。

> 新会话入口顺序：先读 pmos_linux 仓 `AGENTS.md` 现态一句话（战役级）→ 再读本文
> （本项目操作规则）。两档分工：**硬定律/操作纪律/战役叙事 = pmos_linux 主档**，
> 本文不复制；**本仓管：控制面脚本怎么用、版本钉在哪、发布轮怎么走**。

## 这是什么 / 不是什么（边界，2026-10-06 定）

- **是**：魅族 20（m2381）跑 Nura/pmOS 的**控制面聚合仓**——构建/验证/刷写
  的脚本 + 版本钉 + 产物清单 + 教程文档。
- **不是**：源码仓。★布局 v3（2026-10-13 用户拍板；10-06 边界再确认升级）：源码树
  全部**独立仓库零内聚**、原地不动——fork 内核 `linux-mobile-ports`（多设备分支制）/
  Mu `meizu20/mu-uefi/Mu-Silicium-new` / pmaports（K30+魅族多设备包源）/
  pmbootstrap + `.pmbootstrap`（通用基建），路径全钉在 `config.sh`；本仓的价值 =
  钉子表 + `setup.sh --clone` 远端复刻（每树皆有公共 GitHub 远端，CI = 新机器）。
  ｜ 知识库（叙事在 experiment-log，硬定律在主 AGENTS）。

## 目录地图

```
config.sh        唯一定位点：三树路径 + 现役版本(REL_*) + 设备通道（回滚锚已删 10-13）
script/          build-kernel / build-device / build-esp / build-mu / build-rootfs
                 verify（交付链对拍）/ flash-batch / readback / setup（体检）
                 + build-rootfs-min.sh（nura-min 定长根镜像，iOS 尾环配套）
                 + pmbootstrap-meizu.sh（wrapper，官方工具组合器）+ 配套 cfg
tools/           make-esp-recovery.sh + devsh/devpush/devpull（设备通道三件，收编自私有工作区）
                 + abl-re/（启动链逆向复现脚本，2026-10-12 收编；配套 docs/BOOT-CHAIN-RE.md）
docs/FLASHING.md 刷机教程（每步带验证点）——动手前必读
docs/PIPELINE.md 构建管线 + Phase-2 发布清单
MANIFEST.md      现役产物表 + 回滚锚表 + 已知非回归失败（首 boot 看到别慌的三件）
artifacts/       本仓自产产物：mu 现役/次级锚裸镜像 + esp .img.gz（100MiB 裸镜像不入 git）
```

## 现态（2026-10-29 更；新会话从这里接）

- **▶ 2026-10-29 追记：队列① ABL fastboot 命令表逆向 ✅ 收官**（用户「开始逆向 1」
  点名；零设备纯宿主；iOS 委托三件判词全部定谳）：
  **①命令表 = 42 注册**（标准表静态数组 0x71dd8×19 + super 门控条件注册 3
  [reboot-recovery/reboot-fastboot/snapshot-update，本机在册] + OEM 表 0x4eab0×18
  [= §6.1 逐字复核通过]），全部真实现零残桩；**②boot 死因 = 编译期删除（表中无）
  非残桩**——FastbootRegister(0x1123c) 22 处调用点全镜像普查无一注册 "boot"，
  分发器(0xf744)唯一 fallback = "unknown command"(0x676c7@0xfb08) = iOS r70 实测
  原文；**③读回通道 = 无**（fetch/get_staged/upload 全镜像字符串零命中；read_psn=
  序列号、logfs=环读均非通用读回）⇒ **iOS「绕过 ABL 限制」调研线正式关门，分区
  读回维持启动后 reader**；**④附带定谳：§5.3/5.4 装载行为无 fastboot 旋钮**——
  UEFI 变量 "K"(GUID 882F8C2B) 全镜像无写点（SetVariable 仅 2 处写 "R"/"F"，均
  fastboot 不可达），gunzip 窗/ramdisk 忽略/DTB 校验全硬编码。机制新档 = 命令面
  运行时单链表（表头 0x83340 头插、前缀匹配）+ parallel-download-flash 异步机制
  （download: 完成事件回调 0x114cc 重入分发器派发排队的 flash:）。getvar 全集 =
  39 处 PublishVar 普查归并（kernel="uefi"/is-userspace="no"/per-partition
  partition-size:/partition-type: 循环发布/snapshot-update-status 五态/slot 族
  multislot 门控）。落档 = **BOOT-CHAIN-RE.md §6.5**（全表+地址证据）+ §6.1 指针
  + 委托卡收官标记；工作目录（解包件/反编译/REA 快照，私有面不进公开仓）=
  meizu20-m1/abl-fastboot-re-20261029/（PE sha 2f5b7335 与 09-25 轮件同源，abl_a
  两源 026d673c 同源互换均实测）。工具链实锤 = REA CLI PE 车道二连跑通（快照
  abl-fastboot）+ tools/abl-re xref/disfunc 配套。**推送 = 本件授权窗已执行**
  （nura 公开仓 push，§8 政策：结论+地址公开、派生物留私有面）。队列 = ②XBL
  会话语境 RE（docs/XBL-SESSION-RE-CARD-20261028.md，等点名）→ ③S2IDLE 二段
  （需设备回 nura 链）。

- **▶ 2026-10-28 追记（排面钉）：iOS 侧委托 = m2381 ABL fastboot 命令表逆向 →
  **列第一待办**（用户「不着急做，加入第一待办」+「记得用 REA 逆向工具」点名；
  **执行等用户点名**；卡 = docs/ABL-FASTBOOT-TABLE-CARD-20261028.md；零设备纯宿主
  ——设备现役 iOS 链 + 单通道红线全程不碰）**：iOS r70 实测 `fastboot boot`
  下载 OKAY(98MB) + `Booting FAILED(remote:'unknown command')`，要把「ABL 裁
  CmdBoot」做实成全命令表。**素材已核 = 委托给的固件 tarball 不含 abl**（userspace
  固件包非分区镜像包，勿白挖）；真取件 = 私有仓 meizu20-m1/artifacts-uefi/
  uefi-partition-dig-20260930/abl_a.bin+abl_b.bin（dd 件现成）。工具 = **REA CLI
  主刀**（s5-rea PE 车道 10-21 已跑通）+ tools/abl-re 配套。底账 = BOOT-CHAIN-RE
  §6.1 OEM 表半成品（注册点 0x4eab0，09-25 轮）扩全表；五项 = ①"unknown command"
  串反查分发器→命令表 ②三档定性（正常/残桩/表无；**boot=表无 or 残桩定谳**）
  ③oem/flashing/getvar 全普查（**fetch/oem read 内存读回通道有无定谳**——无 =
  iOS 分区读回 reader 路维持、「绕过 ABL 限制」调研线正式关门；防误判：read_psn
  =序列号读写、logfs=分区环，非通用读回）④§5.3/5.4 行为约束复核（gunzip 窗
  83.5MB=DtLoad−K/忽略 ramdisk/DTB 校验，有无 fastboot 变量可改；顺看 UEFI 变量
  "K" 写入路径）⑤BOOT-CHAIN-RE.md 加节（§8 红线：只进结论与原创脚本，派生物留
  私有面）。交付 = 命令表+boot 死因+通道定谳，经用户转告 iOS；素材第二源 =
  meizu20-m1/backups/flyme-ota-b-20261002/images/abl_a.img（**与 dig 件 sha256
  同源 `026d673c` 两源互换**，10-28 实测）；**收尾 = 文档整理好后推远端仓库供
  外部参考（用户 10-28 对本件开推送窗，§8 政策照旧：结论+原创脚本公开、派生物
  留私有面）**。**XBL 会话语境 RE（花屏根治 S5 下一手）排程本件之后**（用户
  10-28 拍板「我还以为弄完了……同配方同完整逆向文档，推送届时看情况」；卡 =
  docs/XBL-SESSION-RE-CARD-20261028.md；素材 xbl_a/b.img 两源在库 + REA 冒烟
  已过 + 输入配方根治卡 §4 在案[ELF32 e_machine=1 占位头须 dd 切段喂 raw-binary]）。
  **队列终序 = ①ABL fastboot 表 → ②XBL 会话语境 RE → ③S2IDLE 二段**（该轮需
  设备回 nura 链）。
- **▶ 2026-10-24 追记（九十七·排面钉）：S2IDLE 根治轮·二段排面已排（用户 10-24 晨拍板「安排下
  个会话，现在弄 iOS，这边暂停」）——⚠设备去向随 iOS 轮（可能被刷走/换系统），nura 排面恢复时
  首项 = 设备现态探测（devsh 连通+uname+wowlan/cpuidle 实读），设备不可用则排面顺延勿等**：
  ①开工惯例 stable 检查 30s（v7.3.1 出没出）；
  ②设备现态探测（见上⚠）；
  ③**E 长跑过夜（首项实验，零人力）** = (wowlan 开+cpuidle 开) ×50-100 轮无人值守——复用
  s2test 基建（设备 /root/s2test/run.sh+resume unit 都在，mask=all/state 清零即跑）；
  ★每轮 pre 须**实读 iw phy0 info wowlan 武装态**写日志（10-23 那次 1 挂的 service-active≠
  武装成功疑点，本轮拿统计清账）；顺带 UPower 记录 = (开,开) 睡眠功耗定量（10-23 被阻断的
  wowlan 代价测量补齐）；若 100 轮零挂 ⇒ 拆 meizu-wfi 吃簇睡收益的底气；挂 ⇒ (开,开) 真实
  概率入册，E 路线出局；
  ④**段 4 悖论 kprobe 实证（主攻）** = (关,开) 触发挂死轮 + kprobe/ftrace 钉
  cpuidle_find_deepest_state/call_cpuidle_s2idle/psci_cpu_suspend_enter 调用计数与实参
  （QoS=10us 时这些函数到底选了什么）→ 深塌真入口定谳 → A/C/D 选路自动浮出；
  ⑤修复轮（视③④）：A idle.c 限深 knob（治本向）/ C ath12k 域修（skill wireless.md 先例 =
  补电源域标志+复用 awake 路径）/ D 照 v7.3 shikra.dtsi 给 sm8550 补 mpm 节点探测（AOP 若
  不认 vMPM mailbox，probe 日志直说，一次内核轮成本）/ E 直接拆 meizu-wfi（③零挂时）；
  ⑥拼车池 = tuned 删包 / meizu-wowlan 默认态拍板 / TECH-DEBT 清账；
  ⑦风险预案 = 治本超窗维持 meizu-wfi 现状（不会比现状差）。
  设备现态快照（10-24 晨暂停时）= pmOS #92/v71/r91 出厂组合（cpuidle 锁+wowlan 重武装+QoS 清
  n/a），s2test unit disabled 无自启残留，宿主侧 watcher/digger/listener 全清。
- **▶ 2026-10-24（九十七）：S2IDLE 挂死根治轮·一段收官（用户「开工」点名；设备全程
  在线；全量叙事+数据 = pmos experiment-log（九十七）+ docs/meizu20/s2idle-hang-data-20261024/）**：
  ①**观测基建** = netconsole 全链路通（宿主 python UDP:6666 + 设备 configfs → usb0；
  **★cmdline 烤死 loglevel=3 = console 层滤 <4 级 = 历次证据蒸发又一层根因**，实验期
  抬 7；覆盖窗 = 入睡段至 freeze 完成，dwc3 gadget 挂起即断）；无 panic 流（oops=panic
  在）⇒ 静死。②**定量** = 段1（未关联）10/10 净 + 段2（关联 LZ-5G 同 BSSID）10/10 净；
  **★方法论坑 = sched_clock 深睡停走**（300s 睡眠 uptime 只 +26s，累计漂移 ~40min ⇒
  三次「没醒=挂死」全误判；可靠判据 = >350s 无新 freeze 段 / boot_id 变；顺带实证深塌
  真发生）。③**复现 4/4 铁案 = (wowlan 关+cpuidle 开) 确定性挂死**（段3b/3c 今日 2/2
  + 10-23 2/2），对照 (开,开) 今日 18 轮全净 ⇒ **wowlan 判词翻案：关 = ath12k
  full-suspend（mhi 深关+电源域释放）强放大通道，开 = lite 保留链路避开竞态——10-23
  「wowlan 无关」推翻**（(开,开) 低概率通道当年掩盖了 (关,开) 确定性通道）；段5
  (关,锁) 净 = 定罪矩阵封卷。④**QoS 双悖论**：/dev/cpu_dma_latency=10us（清醒态实证
  锁死）+ per-CPU resume_latency=100 **都挡不住挂死**，唯 sysfs disable 有效——源码面
  = v7.3 idle.c 的 s2idle 分支**绕过 governor 直选 deepest available**
  （cpu_wakeup_latency_qos_limit → cpuidle_find_deepest_state）；段6 悖论已解（读层
  不对），**段4 悖论遗留**（全局 10us 理论应排除 750us+ 深态但实测挂）——下会话首查
  call_cpuidle_s2idle 实现链 + kprobe 实证。⑤**机制链** = freeze 直选深塌（rail-pc
  + OSI 簇塌，参数与 stock FDT 全等 = fw 无罪）× ath12k full-suspend 竞态 → AOP/
  RPMH 静死 → 看门狗复位。⑥**日用结论（即刻生效）**：meizu-wowlan 升格 = (关,开)
  挂死通道保险丝（**wowlan runtime disable 自此列禁手**，除非 cpuidle 锁着）；
  meizu-wfi = 第二道；功耗路线（拆 meizu-wfi 吃簇睡收益）被 (开,开) 1 挂史阻塞，
  待治本解锁。⑦**r92 排面三选留拍板**：A 内核 knob（idle.c s2idle 分支尊重 QoS/
  限深——治本方向，段4 悖论先解）/ B device 包 wowlan 防呆加固+禁手文档化 /
  C ath12k 域修（深水区）；拼车池不变。设备收尾 = 出厂组合回位（cpuidle 锁+wowlan
  重武装+QoS 清 n/a）。commit 不 push。
- **▶ 2026-10-23（续）：待机功耗定谳首轮（devsh 在线只读+两枚低风险动作）**：用户报
  「满电待机一天不到」→ UPower 历史 + suspend_stats 白嫖定量：**12h11m s2idle 掉电
  98%→23%（≈1.15W）≈ 清醒屏灭态 0.95W = 睡眠几乎没省电**（journal 单次 entry/exit
  一觉到底 + wakeup_sources 睡期 wakeup_count 全零 = 非"没睡"非"唤醒风暴"）。
  已动手：①`iw phy0 wowlan disable`（runtime；meizu-wowlan.service 仍 enabled，重启
  自动恢复 = 天然 A/B 回退；device 包默认态待 r92 拍板）；②补 journald/resolved
  `WatchdogSec=0` drop-in（每次唤醒被 SIGABRT+coredump 实锤；**覆盖 r58 刻意 30min
  折衷**，保持与否留用户拍板）。**▶夜 A/B 协议**：wowlan 已关态跑一夜（拔线/断 ssh/
  灭屏，晨起记 %，数据可事后从 UPower history 挖）→ 仍 ~6%/h 则 A/B knob default
  （bloff=0，DDIC 睡；唤醒花屏风险须用户在场）→ 再查清醒 idle 轴（0.95W 偏高）。
  基线全录 = 记忆 `meizu20-standby-drain-baseline`。
- **▶ 2026-10-23（续·二）：待机功耗全案定谳 = `meizu-wfi.service`（TD-10）**：skill
  方法论剥层（qcom_stats apss 计数→cpuidle disable 旗标→正反对照）——CPU 26h 仅
  204/57/31 次簇睡、APSS 仅 7 次/0.19s；disable 清零后 120s 进 1122 次簇睡 = 机制
  全好；写手 = 设备包 r5 时代 unit（boot 禁全部深 idle 态，K30 r24 同款 workaround，
  当年未登记债表）。已动手：disable 全清 0（本 boot 生效）+ tuned 停服（红鲱鱼，
  持 /dev/cpu_dma_latency 但非因）。**退役验证 = 今晚 disable=0+wowlan 关整夜 →
  下设备日 rtcwake 多轮+花屏眼判 → 全净则 r92 删 unit**。TECH-DEBT TD-10 已立。
  **▶ 同日续·三：退役验证 rtcwake 矩阵——(wowlan 关+cpuidle 开) 2/2 确定性挂死**：
  16:02 挂死→外部看门狗 ~1min 自复位；16:21 复试挂死→~7min 迟到复位（用户见「黑屏
  无反应」）；其余三组合全干净[(开,关)=12h 昨晚/(开,开)/(关,关)=302s 各一]。**当年
  "s2idle flakiness"=此交互实锤（差异轴=ath12k 全挂起路径），meizu-wfi 锁的是真
  问题**；与 skill wireless.md「PCIe s2idle 保留链路×驱动关电源域」线索吻合，kprobe
  法现成。r92 修复路线三选留拍板：①治本内核轮（ath12k×cpuidle）②夜用折衷 (开,开)
  定量 wowlan 代价 ③维持 (关,关) 无收益。★实验乌龙入册：devsh 命令 echo 带未引号
  括号=整行 sh 语法错静默不执行（journal `syntax error` 抓现形），devsh 命令一律
  全引号。**16:29 已按 (开,开) 发射 4h 定量睡眠（T0=16:29:44/18363mWh/100%，
  rtcwake 20:29 自醒）→ 下会话挖 UPower 出 wowlan 代价判词**。
  **▶ 同日续·四（矩阵终版）：(开,开) 4h 也挂死**——T0 后 ~3min 挂死→16:32:37
  看门狗自复位。**定罪收窄 = cpuidle 单轴**：cpuidle 开 = 4 尝试 3 挂
  （302s 干净=运气），cpuidle 关 = 全干净（12h+302s+出厂史），**与 wowlan 无关**；
  (开,开) drain 定量被挂死阻断。设备自愈回出厂组合 (开,关)。**TD-10 退役取消**
  ——meizu-wfi 是活的保险丝，s2idle 挂死根治前不能拆。
  **▶下会话排面 = S2IDLE 挂死根治轮（内核轮；用户 10-23 拍板「直接开始修 s2idle」
  +「安排下个会话」）**：
  ①开工惯例 stable 检查 30s；
  ②**挂死率定量** = cpuidle 使能态 rtcwake 300s ×5-10 轮脚本自动循环（挂死自复位
  续跑），出挂死率；**状态粒度二分** = 只 enable 单簇 cpu-sleep（A510/A710/X3 分开
  试）找「安全子集」——挂死若跟特定簇走，日用先开安全子集吃部分功耗收益；
  ③**抓现场 = AER 大杀器组合拳（用户 10-23 点名）**：★`CONFIG_PCIEAER=y` 已在
  r91 config（PORTBUS/RAS/ASPM 全 y，AER_INJECT 未开），不用重编——缺的是出口：
  a)**netconsole**（no_console_suspend 已在 cmdline ⇒ console 含 netconsole 走过
  挂起不静音 ⇒ 挂死窗口 kmsg+AER 报文直接推到宿主，此前三次挂死证据蒸发 = 少了
  这件）；b)**AER 统计读取** = 每轮醒来读 `/sys/bus/pci/devices/*/aer_dev_*`
  （CE 累计 = 链路问题软证据）；c)**pcie_aspm=off 单变量试一轮**（挂死消失 = 病根
  收敛到 ASPM 链路低功耗态×簇塌缩竞态，一行 cmdline 就能当日用折衷）；d) ftrace /
  查 ramoops 为何空（看门狗复位不经内核 dump 通道）；
  ※逆向表态：二进制 RE（REA/Ghidra）非首选——病灶在上游可读源码（psci cpuidle +
  ath12k/PCIe），首选源码互证 lane（CodeLinaro vendor wlan 源码，display §5a 同
  法）；二进制 RE 只在 vendor 源码无果后升级；
  **★REA CLI = 条件触发第二梯队（用户 10-23 点名「大杀器 REA CLI」）**：触发条件
  = ②③④定位出挂死层在**二进制域**（EL3 PSCI secure monitor / AOP-MPM / wlan 固
  件）——那三层无源码，REA 是唯一路；素材现成 = 9008 全分区备份（xbl_a/b.img 在
  库 + sbl/aop/QSEE 分区可取）+ §4 raw-binary 配方（ELF32 e_machine=1 → dd 切段
  → rea analyze arm64，xbl 已跑通同法）；素材不足处 = meizu20-m1 私有仓备份目录。
  若挂死层定位在 Linux 源码域（ath12k/mac80211/PCIe dwc/psci 驱动），源码互证即
  修，REA 不上——别为顺手的锤子找钉子；
  ④**源码面（纯宿主）** = psci cpuidle 簇塌缩 × mac80211/ath12k/PCIe suspend 竞态
  检索；上游/社区修复搜索（lore/CodeLinaro）；skill kprobe 法（电源域+PCIe 挂起
  回调）现成；
  ⑤修复落地 = fork 提交 + r92 内核轮 + verify + 设备日（rtcwake ≥10 轮零挂死 +
  4h drain 定量 + 唤醒链眼判用户在场）；
  ⑥拼车池 = tuned 删包（红鲱鱼已停服）/ meizu-wowlan 默认态 / TECH-DEBT 清账；
  ⑦**风险预案** = 治本超窗则维持 meizu-wfi 现状（功耗问题挂起，勿硬上）。
  完成判据 = cpuidle 使能态 ≥10 轮 rtcwake 零挂死 + 4h 睡眠 drain ≤~0.5%/h +
  唤醒链眼判全绿。
- **▶ 2026-10-23：android-mainline-port skill 审计轮（零设备纯宿主）**：用户提名
  `github.com/yzddmr6/android-mainline-port`（高通主线移植经验 skill，~3000 行），
  已装 `~/.agents/skills/android-mainline-port/`（ZCode 不自动触发，相关任务 Read
  直读）。全文对拍本仓 = **主线达标**（skill 0-8 步全走完，方法论同构）；查漏产出：
  ①**docs/TECH-DEBT.md 建档 = 技术债唯一出处**（9 条债带去掉条件 + 交叉印证线索 +
  NO-GO 集中地 + 候补小件池——此前散三处，后只更此表）；②**S5 根治卡 §5 B-list 扩
  两轴** = VBIF AXI halt 握手（彼库已确认根因例，dsi_err status=4 同 marker）+ 双
  INTF 关闭顺序/DSI PHY 状态保存恢复，「下一手候选」菜单扩为三族留拍板；③ath12k
  21s 新线索 = PCIe s2idle 保留链路×驱动关电源域 + kprobe 排查法（⚠运行中重载
  ath12k 属禁手）；④廉价检查两枚待设备日（systemd-detect-virt / RebootWatchdogSec）。
  commit 不 push。
- **▶ 2026-10-21 深夜（续·二）：iOS 急件首项收官 + 上机验收全绿（用户在场两轮刷写）= nura-min 定长根镜像交付完成，iOS 侧无需重测**：
  iOS 内核把 SWEETLOG 控制台日志环写在 userdata **尾部**（末 4MiB+4KiB），旧 nura 根全分区恢复必毁尾部 →
  **用户拍板「官方最小，不拆来拆去」路线** = **script/build-rootfs-min.sh**：pmbootstrap `ui=none`
  （wrapper NURA_UI=none 临时 cfg）+ `--add` python3/openssh/**networkmanager(+cli)**/unudhcpd/usb-moded(developer
  profile)，内核/设备/固件自动取本地包仓 **r91/r63/r3**（断言钉死版本，UI 零混入）→ 定长化（v3 install 无
  `--image-size`[实锤=qemu 旗标看串行]→ truncate+resize2fs **离线一次性**扩到精确 2G，拒绝收缩）→
  唯二镜像内手术（debugfs 宿主侧零挂载）：①**mask `meizu-grow-rootfs.service`**（device 包 preset
  自启的首启扩容器=官方最小镜像同样带它，resize2fs 打 464G 整分区，不 mask 必毁尾环；wants 自启
  链接同摘）②写 `/etc/nura-min` 溯源标记。**上机验收（两轮，全绿）**：pass1 刷入起机 48s 到
  devsh:23、uname #92、usb0=172.16.42.1/16、fs Block count=524288（2GiB 整）、grow masked、
  工具/python3/sshd 全在 → 尾部 8200 扇区（4MiB+4KiB 环位）写整段随机 pattern（基准 sha
  `2b78a9f0…`）+头/末 ASCII 标记 → pass2 重刷同镜像+重启 → **整段 sha 与标记逐字节原样** = 「刷
  min+起 min」零扰尾证实，iOS 侧 ③④腿免测。**★USB 网络坑定谳**：官方 `usb-signaller-developer-mode
  up()` 用 **nmcli 配设备侧 172.16.42.1**、unudhcpd 只发 DHCP 不配 IP——无 UI 世界缺 NetworkManager
  即 gadget 在而网死（首版上机实锤，NM 补入即通；90-base.preset 对 NM/wpa_supplicant 等的 enable
  行在无包时自动 no-op）。**交付 = artifacts/meizu-meizu20-nura-min-r91-2G.img（sha256
  `c841f6455d02ad5d6cb8bf7b0fdda5800bd9df0aacba4bbf4de37e5ad43519df`，实占 1.2G）+ 同名 .simg
  （sha `a84d9212…`，fastboot 直刷）**。登录 = devsh nc:23 root 直达 / tty1 getty user/1234 /
  openssh:22 备腿。设备现态 = 停在 nura-min（尾部带我方测试标记），iOS 侧可直接执行原协议。
  坑四枚入册：①systemd --user 单元里 chroot/产物 root 属主——rm/chown/debugfs -w 必须 sudo；
  ②debugfs 短 `ls` 一行多目带尾随空格，断言必须用 `ls -l`；③v3 无 install --image-size；
  ④USB 网络 IP=NM 管（见上）。文档 = **docs/NURA-MIN-ROOTFS.md + docs/NURA-MIN-ACCEPTANCE-20261021.md
  （验收报告，转 iOS）**。commit 不 push。
- **▶ 2026-10-21 深夜（收尾段，用户中途令「开始构建就行不用管了，收尾」）：rebase 正式轮全项收官 + device r63 + 三树推送 + CI 发布轮点火（无人值守）——下会话排面 = iOS 取证急件优先**：
  ①**device r63** = device-meizu-meizu20 depends +iio-sensor-proxy（用户拍板「本轮补传感器」；pmaports `a637249`；apk r63 出件 `.PKGINFO` 闭合实锤 + 装机 RC=0；在机 = **#92 + v71 + r91 + device r63** + fw r3）。②**三树推送落地**（★新坑：本网络 **22 口对 github 全断**，沙箱+宿主双双 ssh 拒 ⇒ `gh auth setup-git` + 一次性 `url.https://github.com/.insteadOf=git@github.com:` 重写走 https+token；pmos_linux 无远端不在推送面）：fork `meizu20-t4b` 强推 `140e5a8e308a→665230b58a29` + 双锚 tag、pmaports `5da0578..a637249`、nura `6014b8c..2b3e861`。③**✅ CI 绿 + Release r91 已上线 Latest（用户令「只做 release」，直发）**：run `39511226412` success → 草稿 8 件制补 device r63 apk[本地 2013b691 补传件，在机实装] → `--draft=false --latest`；发布件 sha8 = mu `350386e0`/ESP v71 CI gz `f08139e3`[同号异字节，本地 6fe7811a=#92 在机件]/rootfs `29490177`/linux apk `d2f0c51b`/固件 `29c1ee88`[r72 原串未变]/zip `a05d57f1`；**验收口径 = 全量下载回读豁免**[CI 内建字节数对拍 ✓+gzip -t+CI verify [1][4][5] 全绿 + CI 日志顺序链证据 iio 预编→device r63→rootfs]；发布面文档四件已对齐 r91（config PIN_RELEASE_BASE/MANIFEST 发布面表/README 中英/FLASHING/PIPELINE）。④**下会话排面（用户中途令）**：**首项 = iOS 线加急取证配合**——做**取证用最小镜像，读 userdata 尾部日志环**（iOS 急件、nura 亦受益；⚠iOS 工作区文件一律不碰，传话 = 用户转告双向）；~~次项 = Release r91 收尾~~✅ 已办结（用户中途令「只做 release」直发，见顶部 ③）；然后 = **S5 全力逆向**（XBL 平台域逆向 or 首帧杀 vblank 旋钮，用户前令）。CI watch 坑：gh 须 `-R`（systemd-run cwd 非仓）+ 流式 watch 遇 TLS 抖动即死 ⇒ 轮询+重试式。
- **▶ 2026-10-21 深夜（本轮，用户「开干」）：7.3 stable rebase 正式轮全项收官（宿主段 + 设备日）= 99 提交零冲突重放 + r91/v71 verify 全绿 + 上机 #92 回归清单全绿**：
  ①**重放** = v7.3 stable（tag `091b0638` → commit `c03c1a14507d`）fetch 入本地；`meizu20-t4b` `git rebase --onto v7.3 a90ee4305c4a`（合流点 = rc6 基线）**99/99 零冲突一次通过**（演练 98 + 首枪旋钮 `26ab9bf3e442` 1）；新 tip `665230b58a29`；锚双钉 = `archive/t4b-rc6-final` + `archive/pre-73-meizu20-t4b`（同指旧 tip `26ab9bf3e442`）；临时分支已删（分支规范：只留现役+上游镜像）。sanity 四件全绿（panic 吸收 0 / ath12k 挂点 186/205/213/250 原行号 / 双旋钮在位 / diff 面 106 文件逐文件全等）。②**printk 定谳**：rc7→stable 唯一 printk.c 变更 `5f339c46f153` = nbcon kthread 早启 SMP 启动挂死修复，**与 9e70a5e109a4 挂起回归无关 ⇒ 上游未修 ⇒ `no_console_suspend` 留**；**设备日实机第一测反证 = Y 态 3/3 全活**（基线 N 发 PASS + 判别发 resume 0.216-0.228s 全环，success 0→5 failed 0）——按卡判据 = 「上游已修」候选，**摘 CONFIG_CMDLINE 件另开内核轮留用户拍板**（在册注：rc6 亦 3/3 未死 = 回归时序依赖，保险件零成本建议留）。③**ath12k 定谳**：rc7→stable ath12k 零提交 + Shenghan freq-range 修复全史不在 v7.3 ⇒ **0012 三件 carry 全留**。④**交付 + 设备日** = pmaports `972412f`（pkgrel 91，pkgver 照演练 recipe 不动）→ **apk r91**（sha8 `df13faa6`，内核 release = **7.3.0**、模块目录 7.3.0/——Mu 链无 initrd 零牵连）+ **ESP v71**（裸 `0a102220` / gz `6fe7811a`）；构建 26min；verify 全绿（[4] 曾红 = 钉子口径假红，v71↔r91 手工对拍 `4aad92b3` 同源）；**upgrade.sh 显式双腿全绿（用户在场）= 实测 uname #92-meizu-meizu20 + 读回 0a102220 对 ✓ + 回归清单全绿**（rtcwake resume 0.228s/电源键秒醒眼判/音频出声眼判/GPU 钳零件 busy_delta_us 真空闲 5 连读恒 0/传感器 proxy+QS 开关在/WiFi 5G 扫描见 LZ-5G[实连无凭据记档]/failed=0；waydroid 现底无预装跳过记档）；收尾 console_suspend 复 N + bloff_default=Y 日用态确认。⑤**新坑** = pmaports pre-commit 钩子要求 source= 全件入 index，fork tarball（270MB）属 gitignore ⇒ APKBUILD-only 提交必被拦 ⇒ 历轮同款都是 `--no-verify`（checksum 由构建实证）。⑥钉子面三写 = config REL_*（r91/v71/#92 实测钉）+ MANIFEST 工作态（在机 #92+v71+r91）+ 本卡。**剩余 = 推送窗口（= 用户；fork push = CI 前置）+ S5 下一手单开拍板（XBL 平台域逆向 or 首帧杀 vblank 旋钮）+ device r63 不拼车**。
- **▶ 2026-10-21 深夜：S5 RE 本体第一段收官（零设备纯宿主，REA/Ghidra lane）——DisplayDxe 键表后半场六面全落定 = 标准域扫描清零**：
  ①**键表结构定谳**：151 键 @0x3e998/46B，qword@32 = `len<<32|slot<<16` 打包描述符**非指针**；slot = 运行时 config 结构体偏移（.data 0x4c000 区，文件态 BSS 零 = XML 解析回填、缺省 = 0；DSI/EDP 槽位 union）；第二 schema 表 @0x404ba×10 = SPR 锐化族（惰性）。②**冷 init/term 序列明文全文解码**（就在 XML 里）≈ fork init 表同源（微差仅 `15 35 00` 形态/亮度 0x0FFF/我方独有 E2-E7 尾 6 条）⇒ init 内容轴再排除。③**demura 定谳**：`DSIDemuraPanelIDReadCMD = 06 00 DA`（0xDA=GET_ID1）+ `DSIDemuraPanelID = {0x471, 缓冲 0x122e7000}`（vtdr demura 实例）；**本机 BOE XML 两键全无（39 XML 仅 2 demura 面板有）⇒ stock 冷会话 demura 全惰性 = 主机侧档案选择不存在**（r22 档案假说主机读 ID 变体在 DisplayDxe 域除名，与 0xB 特类互证）。④**TE 对拍**：全库 39 面板只设 4 键（Enable/DedicatedPin/StartPos=InitVal=VActive）且我方 fork tearcheck 全等（2400/2400），8 键全库零先例 = 零默认（ABL 轮询态不消费中断域）⇒ **TE pacing 候补无 stock 旋钮，记档不开工**。⑤**dis_id 勘误** = GETPANELID 平台调用（XBL 域），DisplayDxe 只打印六 nibble（0x4DB501 印证 bootargs）+写 UEFI 变量 0x358cc——「id→XML 映射表在 DisplayDxe 代码内」旧注（dig FINDINGS）作废；附带 `#override:` = DisplayPanelOverride UEFI 变量覆盖路径坐实。⑥残面 = PPS 内容填充函数未逐指令定位（首枪后内容值轴已死不追）+ **B-list 首帧杀 vblank 族 = 唯一剩余候补**。**下一手候选（留用户拍板）= XBL 平台域逆向（GETPANELID/GETPANELCONFIG 的会话语境）or 首帧杀 vblank kernel 旋钮**。工具资产 = **REA/Ghidra PE 车道首战跑通**（`rea analyze/decompile <path> <addr> --snapshot displaydxe`，PE 直吃免 xbl raw-binary 配方；MDPDetectPanel/SetupDSC/编码器/SetMode/dis_id 六函数反编译 + capstone 锚点前置）；素材 = `s5-rea/out/displaydxe/`（dec-*.md + parse_keys.py/dxe.py/scan.py 可重放 + snapshot）。落档 = PANEL §6 条 7 + 根治卡 §6 后半场打勾 + experiment-log（九十五）+ pmos AGENTS 现态一句。commit 不 push。
  **▶下会话排面（用户 10-21 深夜点名「安排下个会话」）= `docs/rebase-stable-card-20261021.md`（7.3 stable rebase 正式轮）~~已执行宿主段（10-21 深夜本轮，见顶部新条）~~**：~~宿主段先行（fetch `091b0638` → carry ~99 提交重放[演练 98 + 首枪旋钮件 1]→ printk/ath12k 两实质复核 → r91/v71 + verify）~~✅；设备日双腿升 #92 + 回归清单**需用户在场另约窗**；**花屏 S5 下一手与 device r63 默认不拼车**（rebase = 干净版本基线，收官后单开拍板）。
- **▶ 2026-10-21 晨：首枪 A/B 设备日收官——判负（内容值轴清零，用户在场眼判）+ CI fork 包根治落地**：
  ①**旋钮** = fork `26ab9bf3e442`（`msm.msm_dsc_stock_content`，0644 运行时可写
  默认 0；一次钉 S2 表 #9/#13/#14 三靶到 stock 值 = flbo 12→13 全家族[idd 549/sii
  469/nfl 1402，slice_bpg 1302 不变=flbo 无关项自洽]+initial_lines 2→3+DSC_CFG
  bit17 cmd 清位；populate 挂每轮 host power-on = 下次睡眠即生效）+ pmaports
  `acc037b` → r90（`167fe3ab`）/v70（裸 `dca69c1d`）→ upgrade.sh 双腿全绿（#91 +
  读回对 ✓）。②**A/B 定谳**：控臂（knob default+旋钮 0）花屏 6/6；治疗臂（旋钮 1）
  机制面全绿[ctx PPS 三字段精确翻转 + **DDIC `0x91` 读回镜像同步** = decoder 档案
  同值实锤]→ 真睡 ×2 **2/2 全花 = 判负**（×5 协议按判负提前锁死）。**判词 = H1
  （包形态）+ 本轮（内容值 #9-#14 全集）双判负 ⇒ 标准命令域主机可达维度全部排除
  ⇒ 病根在 vendor 专有域/非命令维度 → S5 RE 本体升主线（根治卡 §6 后半场触发
  条件达成）**。③副产品 = **DDIC `0x91` = PPS 镜像读回侧通道**（Meizu22 的 0x0A
  →0x9C marker 不可平移——本 DDIC 0x0A 机制性不可读；0x91 给 decoder 档案 ground
  truth）+ 恢复姿势 = 重启（旋钮 runtime-only，boot 默认零行为差）。④**CI fork 包
  根治** = build-device.sh 加 iio-sensor-proxy 预编（nura `574a021`；根因定谳 =
  包从未进 device depends 闭合 + 官方仓 r2 可解析 ⇒ pmbootstrap 不构建 + CI 冷仓
  无本地件存续；非撞号）。⑤在机 = **#91+v70+r90 apk+CI r86-phosh rootfs（device
  r60+fw r3+iio fork r3 热修）**，boot 默认态 failed=0 零行为差。⑥**7.3 stable
  已出**（tag `091b0638`，10-21 复核）= rebase 专项解锁，开工等用户点名。
  落档 = PANEL §6 条 4 + 根治卡 §1 打勾 + MANIFEST 工作态 + experiment-log（九十四）。
  commit 不 push（推送窗口 = 用户）。
- **▶ 2026-10-21 深夜追记：传感器 QS 开关消失定谳+修复（用户眼判过）+ CI rootfs 发布面 bug 入册**：
  设备回 nura 后自动旋转/自动亮度开关消失——排查 = 数据面全活（ADSP/fastrpc/sensorspd 会话/
  SensorProxy 三属性 true+lux 活值）⇒ 断点在 claim 层；对钉 = 设备装 Alpine 裸包
  **iio-sensor-proxy-3.9-r2**（无 10-03 轮 SSC 四补丁）非本机 fork **3.9-r3**（0003
  load-bearing，APKBUILD 注释同症状）。成因 = **CI r86/r87 rootfs 构建 pmbootstrap 择了
  pmOS 官方二进制，fork r3 没进 rootfs**（10-03 验证态=本地 rootfs）——**凡刷 r86/r87 者皆中**。
  修复 = devpush r3 三件（主+systemd+udev）→ `apk add --no-network --allow-untrusted`
  （★--no-network 必须，NCM 无外网 DNS 卡死 apk）→ restart iio-sensor-proxy → phosh 0.57
  自动重 claim 开关即回。**下会话排面 = CI 侧根治**（查为何 fork 包未选中：疑官方仓版本撞号/
  pmbootstrap 择包逻辑；把 fork 包固化进 CI rootfs 构建）。详 = 记忆
  `meizu20-sensors-userspace`。
- **▶ 2026-10-21 纯宿主轮：S5 卡三段落盘（用户提供魅族22 移植仓素材 → 交叉印证 +
  vendor 源码互证 + DisplayDxe 键表前半场）**：素材 = github `14185638/Linux-MEIZU_22`
  （M2582/SM8735 第三方主线移植，10-17 显示修复批；评估存记忆
  `meizu22-port-corruption-fixes-reference`）。①**S5 卡 §5 = 首枪两靶获独立实证**：
  flbo=15 实测案例（他修的就是真花屏：13=画面下六分之五噪点/15=整幅正确 ⇒ PPS 内容值
  =承重墙、DDIC=ground truth 可推翻规范表与厂商推导；stock 重放仍是对的第一枪，残余
  花则单字段迭代）+ initial_lines vendor 公式（upstream 简化给 2/vendor 给 3，我方
  fork 同款简化式）+ DSC_CFG BIT(17) video 位（我方 fork `dpu_hw_dsc_1_2.c:235` 同款
  cmd 反置位 0x23001 vs stock 0x3001）——「90Hz 修好」勘定 = both scan rates 非花屏
  条目。②**§5a vendor 源码互证三靶全中**（sparse 克隆落
  `meizu20/s5-rea/vendor-display-drivers/`，branch `display-kernel.lnx.5.15.r10-rel`，
  techpack 布局 = 驱动在顶层 `msm/`）：initial_lines Hardent 公式原文
  （`sde_encoder_dce.c`，pipeline_latency28/rtl_w64）+ flbo 档位表
  （`sde_dsc_helper.c` `_get_dsc_v1_2_bpg_offset`：slice_h≤30→13 = stock 出处）+
  **kalama VBIF factory 真值 = 本机 stock FDT**（vendor 为 DT 驱动
  `qcom,sde-vbif-*`：rt-remap 16 项/ot 0x28·0x20/dynamic-ot 三对/vbif-size 0x1074）；
  **B-list① VBIF 降级**（我方 fork 已 per-plane remap 且 XIN0-7 与 factory 等值）；
  **B-list② 首帧杀 vblank 族**（RDPTR 首超时注销 + 5/vrefresh 超时，我方 fork 两处
  同款）= 候补解释冷启 restart 双遍。③**§6 DisplayDxe 151 键表前半场**（表
  @0x3e998/46B = **XML schema 键表非补丁表**：内联键名+len u16@+28+type u16@+30+值域
  指针）：DSC 族 9 键**无 flbo/initial_lines** ⇒ 冷会话 PPS = 代码内硬编码 13 族
  算法 →「12 族只有我方内核喂过」强化落档面（置信中高）；TE 族 12 键 +
  DSIDemuraPanelIDReadCMD/ID（r22 档案假说相邻）后半场挂起（~~触发 = 首枪负结果~~
  **✅ 10-21 晨触发达成，升下会话主件**）；
  负结果 = 0x1801011 不迁移（DPU 代差）+ VirtioDSI 诱饵块。commits nura
  `eb8e3fa`/`db8dc18`/`f6f8041`（commit 不 push）。**~~下会话 = 首枪 A/B 开工~~
  ✅ 10-21 晨已收官 = 判负（内容值轴清零，详见顶部追记条）——下会话 = S5 RE
  本体（DisplayDxe 键表后半场 = TE 键值对读/demura ID 键语义/值域解码）+
  B-list 候补旋钮（首帧杀 vblank 族/TE pacing）**；7.3 stable 已出（`091b0638`）
  = rebase 专项解锁待用户点名。
- **▶ 2026-10-19 晨 0xC4 设备日收官（定谳 = 0xC4 洗清，排雷表 #13 终审；upgrade.sh 首跑全绿 + 两坑根治）**：
  ①**upgrade.sh 设备腿首跑全绿**（apk r88 + ESP v69 → #89 + 读回对 ✓；首跑抓 apk 腿
  UNTRUSTED 假绿 = CI rootfs 烤 CI 临时钥 `pmos@local-6acea657`，本地钥 `6aaed2ab` 包必拒——
  照 flash-batch 配方 `--allow-untrusted` 根治 + apk add RC 标记回读治长命令假完成，`28fe8d6`；
  **rebase 轮 r90+ 本地包同墙已预排雷**）。②**两阶段花屏定谳**（用户在场眼判）：默认态 12 次
  s2idle 全净 = 「真睡不受 bloff 影响」前提证伪（suspend 同走 unprepare bloff 分支 ⇒ DDIC 全程
  不睡，毒源结构性不可达，§5④）→ `knob default` 可达态修正实验：P1 阳性对照全花（dsi_err
  status=4 每轮一条 = 链路真断 marker）+ `zero_clkout_timing=1` 归零臂 5/5 全花零效应 ⇒
  **0xC4 洗清**；病根维持 §4.4；条 4 残余位只记档（日用 bloff 结构性免疫）；**附带实锤 =
  r88 默认态真睡日用干净**（`f3c7d33`/`8f82d06`/`d019040`）。③在机 = #89 + v69 + r88 apk +
  CI r86-phosh rootfs（device r60；非 r87 发布面，waydroid/flatpak 缺位不急补）。commit 不 push。
- **▶ 2026-10-19 深夜 窗口期轮第 2 段（（九十二）；零设备纯宿主；排面 4/7/2 三件收官，stable 复核仍未出[rc7 `ec8bf828` 止]）**：
  ①**主件 4 花屏 S2 内容值对拍表** = PANEL-CORRUPTION §6 条 3 追加「条 3·余面对拍」
  （commit `8cbb1cc`）：evtlog 解码（CodeLinaro display-drivers sparse 克隆绕限流 +
  evtlog 行号反查 11 个 r-分支钉族 = Flyme ≈ r1/r15+ ± 厂家移行）= topology 9
  DUALPIPE_DSCMERGE / common_mode 3 双块 merge cmd / **stock DSC 重编程 ROI 变更
  触发**（主线每 kickoff 幂等 = 时序差）；15 行对拍表 = 等价 8 项（slice-per-pkt 2
  两侧同值 / 链路速率 1094000000 FDT 四档同值 ↔ hs_rate pin 同值 / RC spec 表逐值
  全等）+ **内容差 = flbo 13↔12 根因族**（downstream `_get_dsc_v1_2_bpg_offset`
  slice_h≤30 档 vs VESA 1.2 444 表 → idd 549↔526 / nfl 1402↔1294 / sii 469↔488，
  PPS 128 字节仅 4 处差）+ **initial_lines 3↔2**（★1.2 寄存器路径无 cmd +1，旧判
  「3=3」作废）+ **DSC_CFG bit17**；**自洽两侧成立 → 只记档不排实验，0xC4 仍是首发
  实验**；新机制发现 = stock debugfs 活读 DSC 1.2 不可达（dsc_init_1_2 不注册 dump
  子范围 → is_valid_range 拒）= F4 只得 evtlog 流的深层原因。②**插空 7 upgrade.sh
  固化**（commit `e640683`；用户点头件）：apk 腿 + ESP 腿 + 双验收全脚本化，守卫
  systemd-run --pipe 交互形态，devsh/devpush 补 --host，UPGRADE.md 对齐；设备腿首跑
  随下轮升级实机验证。③**次选 2 相机驱动轮预备卡**（pmos_linux `1692ace` =
  docs/meizu20/s5k3p9-driver-round-card.md）：i2c 真值 0x5a→7bit 0x2d + 3P9=csiphy2
  DPHY/GN5=csiphy3 CPHY 5.66G + stock sensor 节点本体在 boot FDT（dtbo 仅供给
  phandle 补丁，判读精确化）+ DT 草案（pm8008j L5/L2/L4 供给 fork R1 现成）+
  首 ACK 判据 probe 读 0x3109。**余项 = 5 SDE catalog / 6 binder 调研**。commit
  不 push（推送窗口 = 用户）。
- **▶ 2026-10-19 晚 窗口期轮第 1 段（（九十一）；零设备纯宿主；执行卡 0/1/3 项收官）**：
  ①**窗口检查 = stable 未出**（ls-remote 只到 v7.3-rc7 `ec8bf828`，rc8 未出 → 不转正式
  rebase 轮，下会话开工须重跑检查）；②**蒸馏③ = [docs/AUDIO-METHOD.md](docs/AUDIO-METHOD.md)
  成文**（~460 行：硬件地图/路线判别[CLASH 挂起史]/**§2 出声必需清单可平移**[DTS→config→固件→服务串→tplg→UCM→pulse 七层，按包内实文件点名]/§3 probe 竞态四层[r48 机制无关重试环现形]/§4 ADSP 域要/不要[audiopd B2 判负入册]/§5 工作点与响度封卷[409/457/251 域+r46 校准+四维回退纪律+fast-switch 判负]/§6 UCM 三坑/§7 录音腿边界[断在 DMIC 物理域，复燃=WCD/SWR bring-up]/§8 五层排查序；stock 提取件零入仓；蒸馏不改判词[S2 四维改判/r63 勘正形态照写]）；
  ③**wrapper 守卫固化**（pmbootstrap-meizu.sh 加 build-kernel.sh 同款 NURA_INSIDE_UNIT
  →systemd-run 守卫 + 三坑注释 + NURA_*/PMB_* 钉子 --setenv 透传；沙箱 checksum 冒烟
  exit 0——10-19 演练轮「直调 wrapper 沙箱 sudo mknod EPERM」坑根治）。commit：nura
  `782f3d1`+`0f3a3e4`+窗口卡/接续卡更钉、pmos_linux `f1b2d5d`+experiment-log（九十一）；
  **全部未 push（推送窗口 = 用户）**。余项 = 2/4/5/6/7（见执行卡）。
- **▶ 2026-10-19 窗口期轮：Flyme 取证四件全落袋 + rebase 预备四件收官（（九十）（九十·乙）；设备现役 = Flyme 未动）**：①**取证四件**（素材 = meizu20-m1/flyme-forensics-20261019/，只读红线零破）= F1 stock FDT 791KB + bootargs 全量（★旧判读修正「stock FDT 无 soundwire」作废）+ 相机 ACK 真值 s5k3p9sx 0x3109@0x5a；F2 SWR 麦域 418 控件全景（手拨不通 = stock 要 HAL AFE 会话）；F3 modem EFS 四分区双侧哈希 MATCH；F4 DSC allocated:2 + evtlog 每帧 dce_dsc_setup。②**预备四件** = printk 上游未修（`no_console_suspend` 留）+ ath12k 0012 不摘（carry 三件全留，qrtr 悬案闭环）+ 0xC4 旋钮预写预构建（fork `c1d84dcf80ec` → r88/v69 verify 走通，验证件不上机）+ printk 流程卡。③**花屏 §6 #2/#3 双判负**（无漏组/无缺位 → 强化 r22 判词，0xC4 = 唯一漏测项地位再确认）+ hexagonrpcd r7/r8 收敛。④蒸馏③④未动（留专注会话）。**四仓只 commit 未 push（推送窗口 = 用户）**；取证毕设备去向留用户拍板。

- **▶ 2026-10-14 晚轮：CI 硬件验收 + r87 发布轮（一轮双事，Release r87 = Latest）**：
  ①**硬件验收全过**：CI #21 三件（mu-r86/esp-v67/r86-phosh rootfs）刷入实机一次点亮——
  三件 sha 对拍 SUMS 全等、recovery_a 整分区逐字节、boot_b 分段对头部（**新坑：boot_b 整
  分区 sha 永远≠镜像 sha，填充区 = stock boot 遗留非零，惰性**）；CI vmlinuz 双证实锤
  （uname #87 + CI 构建时间戳）；**首 boot 三 unit 竞态入册**（meizu-dsp-mount/qbootctl×2
  跑早于块设备枚举，boot-2 自愈 failed=0；OSK Stevia 同型收敛；已入 MANIFEST 已知非回归
  表）。②**r87 发布轮（用户拍板「做新版再发布，预装 waydroid，phosh 移除 discover」+ 追加
  拍板「加 flatpak 支持」）**：device **r62** = 摘 discover-backend-apk + flatpak/
  gnome-software-plugin-flatpak（r61 waydroid 五件保持）；内核 **r87** 纯版本 bump（保
  「release tag=内核 pkgrel」律，TAG 由 pmaports pkgrel 推导）；ESP **v68** 本地先建先钉
  （「pin>release→取 pin」公式前置）；本地 verify 全绿 + 设备 apk+ESP 双腿升级 **#88** 读回
  对 ✓ → CI **#22 全绿 20m28s** → 草稿三层对拍全过（DTB CI≡本地 c061acd9 / CI ESP↔CI apk
  901ebc15 / rootfs debugfs = r87+r62+r3+waydroid+flatpak 插件零 discover）→ **Release r87
  上线 Latest**（8 件制含 device r62 apk + upgrade zip；release notes 带升级路径与首 boot
  说明）；被取代的 r86 草稿删除。③**设备查缺补漏**：r62+flatpak 上机（gnome-software 的
  fwupd/flatpak-libs 属合法依赖树保留，discover 系清零）、waydroid 离线镜像恢复 + 容器
  RUNNING + v4 互联网/DNS 通 + **酷安眼判 ✓**（v6 侧无上游=环境态，应用回退 v4 同 10-13 态）。④文档四件对齐
  r87（README 中英/FLASHING/MANIFEST）+ config PIN_RELEASE_BASE→r87；pmaports `5da0578`、
  nura 已推；**回退配对 = r86/v67/r60（两轮实机绿）**。

- **▶ 2026-10-13 晚轮：布局 v3 零 mv + 云端构建上线 + 设备日 r86/waydroid 收官（一轮四事）**：
  ①**零 mv 拍板落地**（用户三连：源树全部独立仓库——内核多设备分支制/pmaports 多设备包/
  Mu fork/pmbootstrap+.pmbootstrap 通用基建；nura = 控制面钉子表 + clone 远端复刻；物理
  嵌套不做）。②**build-release.yml 全量落地**（草稿制发布/字节逐件对拍/ccache/固件自
  Release 拉进包目录/Mu=linuxbrew+venv+--no-sync）——**首跑两败三修**：一败 = CI 无
  pmbootstrap work dir（修 = init 步）+ ESP 推导钉+1 误推 67（修 = 查已发布 Release 资产）；
  二败 = init 校验 pmaports remote 须指官方 gitlab（修 = 补 remote）；三修 = ESP 推导改
  max(release, pin)+1 防重号本地超前腿。三跑待验证。**CI 新增坑册**：systemd 无 →
  NURA_INSIDE_UNIT；init 非交互 = yes 空行；树位 = NURA_*_DIR 重定向 /mnt。③**本地构建
  全链通**：r85/v66 + rootfs r85（ec2acbb2）+ upgrade zip + verify 全绿；推送前隐私清扫
  （接续卡 /home/ri 三处中性化 + 旧泄漏行删除）。④**设备日 = r86 手动升级首验全过**：
  r85（#86）刷入后 waydroid netd addInterface 仍 EAFNOSUPPORT(97)——**v6 规则缺位实锤**
  （（八十八·乙）只修了 v4 半层）→ **r86 = IPV6_MULTIPLE_TABLES/SUBTREES**（config-only）
  两腿升级 → **#87 一次点亮 failed 0 + waydroid 联网四连技术面全通**（v4/v6 rule 各 15 +
  default 路由表 + gw/外网 ping 0% loss + DNS 解析；CS validation failed = gstatic 探测
  地域不可达，非栈缺陷）。升级口径实测 = apk 腿+ESP 腿原地
  升级零重刷 ✓（UPGRADE.md 流程首验）。在机 = #87/r86 + v67（读回 2ad63003 逐字对拍）。
  **钉子 = r86/v67/#87**；回退 = r84/v65/#85（Release r84）。⑤**waydroid MTU 黑洞层
  收官（用户酷安图片实证）**：路由通后应用仍「文字通图片死」= 上游 PPPoE 级路径
  MTU<1500（DF 1452 通/1472 死）+ frag-needed 在 NAT 路径回不来 ⇒ 未钳位 TCP 大段
  黑洞；修复 = **MSS clamp 1400**（`table ip waydroid_mss` 自持 postrouting/mangle 链，
  运行态+持久入 52_waydroid.nft；ping 类 ICMP 不受 clamp 影响属预期）。⚠设备重启后
  NCM 网段会漂（172.16.42.x→10.42.0.x），devsh 硬编码地址失效时绑接口直连新网段 :23。
  ⑥**云构建十跑战役（深夜收官 = 审计转入档）**：#1-#10 逐败因全定谳修净（十跑绿到
  第 10 步 = deps/浅clone/种子/固件/推导/Mu 工具链全过），死于 work dir 缺 version
  标记 + 暴露 ESP 公式三态 bug——**批量修正已入 + 全审计落
  docs/CLOUD-BUILD-CI-REVIEW-20261013.md（= 下会话蓝本：§四一次点火 → 首绿 →
  §三一致性对比 → 草稿 r86 → 发布留用户）**。CI 坑册新增：pmbootstrap 无 GitHub
  镜像/不在 PyPI（唯一正源=gitlab 有界 clone×3）、shell timeout 包 bash 孙进程
  孤儿化握死管道（必须 step 级 timeout-minutes）、init 向导不可脚本化（work dir +
  version=8 种子替代）、ESP 版本=轮生命周期三态。本会话未触发 #11（用户令：停止
  逐跑试错，下会话按蓝本走）。

- **▶ 2026-10-13 三连（全量 = pmos_linux AGENTS 现态一句话 + experiment-log（八十八）（八十八·乙））**：
  ①**Waydroid 复活定谳（八十八）**= waydroid 1.6.3 自拉官方 `waydroid_arm64_only`
  纯 64 位镜像原生跑通零补丁；10-12 复燃四路/探针三件/旧补丁配方全作废。
  ②**网络两层断因（八十八·乙）**= pmOS inet filter 无 waydroid0 放行（已修在机，
  `/etc/nftables.d/52_waydroid.nft` + 四条运行态规则；⚠勿 restart nftables）×内核缺
  `IP_ADVANCED_ROUTER/IP_MULTIPLE_TABLES`（netd 装不了 netId 规则）→ **r85 config-only
  已建待刷**（pmaports 1d54efd/247be65，apk sha8 c1d22119），交付 = 手动升级路径首验。
  ③**云端构建研究收官**（`docs/CLOUD-BUILD-RESEARCH.md`，c9abb63）+ **工作区迁移拍板**
  （只在 nura 推进适配；接续卡见顶；蓝本在 pmos_linux 侧）。waydroid 深化适配 =
  等 7.3 stable 再推（用户 10-13 拍板）。

- **▶ 公开蒸馏队列进行中（10-12 用户拍板；执行卡 = pmos_linux docs/meizu20/public-distill-queue-20261012.md）**：
  先例 [docs/BOOT-CHAIN-RE.md](docs/BOOT-CHAIN-RE.md)（启动链逆向全集）+ [tools/abl-re/](tools/abl-re/)
  五脚本已推（`39df1a0`）；**队列① [docs/SUSPEND-S2IDLE.md](docs/SUSPEND-S2IDLE.md)（睡眠/s2idle
  破案全集）+ ② [docs/PANEL-CORRUPTION.md](docs/PANEL-CORRUPTION.md)（面板花屏 case 包）已推（10-12）**；
  待续：③音频方法论 ④GPU/IFPC——纯宿主写作零设备，格式标准与 stock 件不外发政策红线见执行卡。
- **✅ phosh 回归轮 + 发布面切换（10-12（八十七），用户在场验收全过）**：steamos「起不来」
  = **竞争刷写污染**定谳（彼线并行 fastboot 互踩；新操作律 = **fastboot 单通道，两侧刷写
  必须互斥**），boot 链无罪——nura 重刷三件（boot_b mu-r69 + recovery_a v65 + 新建
  phosh rootfs[r84 apk+device r60+fw r3]）**#85 一次点亮回归全绿**（boot ~50s / failed 0 /
  音频 T4c 直驱自动钉 / GPU 钳零件 busy_delta 恒 0 / 睡眠 rtcwake 51s resume 0.240s /
  wowlan 武装 / 看门狗件全生效；带话回信见文末 2026-10-12 段）。**用户拍板「以后专注
  phosh」**：**Release r84 上线**（7 件制，rootfs gz a2fdcd33 自回归通过 local.img 生成；
  草稿上传字节数逐件对拍后发布）+ r66 已删 + r80 = plasma 末版存档；build-rootfs.sh
  固化条件改 NURA_NO_RELEASE 开关（phosh 默认进发布面）；config/MANIFEST/README 中英/
  FLASHING/setup 全对齐 r84+phosh；三树已推（fork `140e5a8e308a`/pmaports `b4e5147`/
  nura `c06aa72`）。**升级口径入册：内核/设备包/固件 = apk 腿（rootfs 内 apk add）+ ESP
  腿（recovery_a）原地升级，不重刷 userdata（数据保留）**；rootfs 全量重刷仅换 UI/换
  发行版/从零装机。在机 = pmOS phosh #85（本地件）。

- **✅ GPU/IFPC 轮收官更钉（10-12（八十六））**：r84/v65/#85 彼线点火回执判过
  （payload[0]=SUCCESS 但 ifpc 恒零 =「ack 不执行」[FW 行为态]，内核线收官；钳零会计件
  根治 busy 地板：真空闲 busy_delta 恒 0 + 静态 UI 220 单档 94.8% + GPU 温 39-41°C +
  七条回归绿）→ **config.sh 现役钉 = r84 / ESP v65 / 期望 #85**（回滚配对 r82/v63/#83；
  r83/v64 冻结留档）；MANIFEST 工作态表已同步（含 v62 裸 sha 再勘对齐）。全量判词 =
  pmos_linux `docs/meizu20/gpu-idle-devfreq-round-20261011.md` §13。
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
- 出事 = 重刷现役三件（flash-batch.sh 单腿/三件 + r84 rootfs，FLASHING §6 阶梯；
  回滚锚与 rollback.sh 已删 10-13，旧版不再回滚）。

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
| 启动链逆向深档 / ABL RE / 复现脚本 | docs/BOOT-CHAIN-RE.md + tools/abl-re/（公开面；原始 dump 与 9008 备份私有仓保留，二进制不外发政策见该文 §8） |
| 睡眠/s2idle 破案（printk 挂死 / 取证通道 / 唤醒链 / WoWLAN） | docs/SUSPEND-S2IDLE.md（公开蒸馏队列①，2026-10-12） |
| 面板花屏 case 包（掉电唤醒马赛克 / 排雷表 / bloff 工程解 / 档案假说） | docs/PANEL-CORRUPTION.md（公开蒸馏队列②，2026-10-12） |
| 音频 bring-up 方法论（直驱路线 / probe 竞态 / 出声必需清单 / 工作点与响度 / UCM 坑 / 录音边界） | docs/AUDIO-METHOD.md（公开蒸馏队列③，2026-10-19） |
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

### 回信（2026-10-12 竞争刷写事故定谳 + r84/v65/#85 phosh 回归全绿）

**一、事故定谳（彼线「起不来」）**：根因 = **竞争刷写污染**（用户确认：彼侧与 nura
侧并行对同一台设备发 fastboot，分区内容互踩）。nura 侧已全量重刷三件（boot_b
mu-r69 + recovery_a v65 + userdata 全新 phosh rootfs）**一次点亮** ⇒ **boot 链无罪**
（mu-r69 / ESP v65 / 内核 r84 在 pmOS rootfs 上全绿，见下）。彼侧恢复 = 重刷 boot_b
+ recovery_a v65 两件即回同一 boot 链（「只刷 userdata」边界照旧）；彼 rootfs 按彼侧
流程重刷。
**★新增操作律（本轮实证，建议入彼侧坑册）**：fastboot 单通道独占设备——两侧任何
刷写必须互斥（约定窗口或用户在场串行），并行下发会互相污染分区且无报错。

**二、r84 回归数据共享（同内核对照基线，pmOS phosh rootfs）**：#85 一次点亮 /
boot ~50s 内 NCM 通 / failed 0 / 音频链全自动（audio-route 钉 T4c 直驱
RCV=ASP_RX1 251/1 + SPK=ASP_RX2 409/3 + stream=12740；UCM+tplg 随 device r60 自带，
无需手工件）/ GPU 钳零件真空闲 busy_delta_us 恒 0（5 连读；220 档 boot 初期驻留
87%，稳态口径 94.8%）/ 睡眠 rtcwake 51s → resume devices **0.240s** / wowlan
magic-packet 武装保持 / udevd+logind WatchdogUSec=0 + journald sync drop-in 全生效 /
rootfs 自动扩容 449G。**ifpc 恒 0 = （八十六）FW 行为态收官判读，勿当异常追**。
boot 早期 DPU「no encoder found for crtc 0」3 条 = 窗口性噪音（面板 cold-enable
restart 自愈窗口撞上合成器 vblank 请求），运行期零刷，勿追。

**三、同步动作**：零内核变化（彼侧 BUILD.env 已同钉 r84/v65/#85）——本轮彼侧唯一
新律 = 上面第一条的刷写互斥。nura 侧 phosh 本地刷写件 = artifacts/
meizu-meizu20-phosh-local.img（r84 apk + device r60 + fw r3，3.2G；非发布面件，
artifacts gz 忽略政策照旧，sha sidecar 已入库）。
