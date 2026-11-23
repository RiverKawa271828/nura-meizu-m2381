# 技术债表（唯一一份，2026-10-23 收拢建档）

> 本表 = 全项目临时做法/绕行/已知欠账的**唯一**集中地（此前散在接续卡、MANIFEST、
> 记忆库三处，现收拢于此，原处只留指针）。格式与去留规则照 android-mainline-port
> skill 的纪律 §2：每条写清做了什么、放哪、为什么、影响、**去掉的条件**。
> 规则：加临时做法与登记本表同一提交完成；"还没做的功能"不进本表（进接续卡排面）；
> 定期按影响排序挑下一批还债。
> 状态词：在册 / 已还 / 转永久。

## 一、技术债

| # | 债 | 在哪 | 为什么暂时需要 | 影响/风险 | 去掉的条件 | 状态 |
|---|---|---|---|---|---|---|
| TD-01 | `no_console_suspend` 保险件（内核 cmdline） | 内核包 cmdline，r72 起随包 | printk console 挂起路径上游回归（9e70a5e109a4），挂死=s2idle 睡死时代真凶；上游未修（7.3 复核） | 零成本保险件；副作用≈无 | **上游修复合入 stable + 本机连续多轮 Y 态实机验证稳定**。10-21 设备日 Y 态 3/3 全活 = 摘除候选（rc6 亦 3/3 未死 = 回归时序依赖，保险件零成本建议留），r92 轮留用户拍板 | 在册 |
| TD-02 | ath12k 0012 三件 carry（5G 频段修复族） | 内核 fork meizu20-t4b | 单 pdev freq range 回归（0d777aa2ca77）上游未修（v7.3 复核：Shenghan 系列全不在），不 carry 则 5G 塌缩 | 每次重放随车；语义 sanity 负担 | 上游合入 Shenghan 系列即摘 | 在册 |
| TD-03 | bloff=1 工程解（灭屏不让 DDIC 睡） | ~~device 包 preset / 设备日用态~~ 已摘：驱动 `bloff_default=false`（fork `2da7ac419574`，r95 起日用默认 = 真睡路径） | 唤醒花屏病根未根治前的日用绕行；**2026-11-19 D4-1 冷启等价化判过 + 科学解验收属实**（三形态×两时长×灭屏面全净）⇒ 工程解失必需性，用户拍板「摘除，现在做」 | 灭屏功耗面微变（AMOLED 真睡 sleep-mode 电流 vs 黑帧近零）；module_param 保留 = 运行时逃生门（`boe_meizu20.bloff_default=1` / `knob bloff`） | **已还**（r95/v75 上机 #96，新默认态 bloff=0 抽查全净） | **已还（2026-11-19）** |
| TD-04 | 在机 rootfs = CI r86-phosh（非发布面） | 设备现态 | 10-18 深夜刷回取证用；非 r91 发布面 | waydroid/flatpak 缺位、device r60（无 iio fork r3 闭合时曾热修）、fw r3 | 择时重刷 r91 rootfs（发布面 8 件制）即清账；不急 | **已还（11-19 回位直刷 r91-phosh rootfs，首 boot 验收全绿）** |
| TD-05 | apk 腿 `--allow-untrusted` 配方 | upgrade.sh / flash-batch 配方 | CI rootfs 烤 CI 临时钥（pmos@local-6acea657），本地钥（6aaed2ab）签的包必 UNTRUSTED 假绿（RC=99 零输出） | 绕过签名校验=信任链降级（仅本地升级腿）；换钥路径无人审计 | CI rootfs 改烤发布面本地钥，或包目录统一钥源后撤旗子 | 在册 |
| TD-06 | ~~NCM 网段漂移（172.16.42.x→10.42.0.x）~~ | ~~设备重启后；devsh 硬编码 172.16.42.1~~ | ~~NM 双系统残留行为~~ **2026-11-19 用户定谳：非 NM 漂移，是用户手动更改 USB 模式所致，设备行为正常** | 无（正常态） | 无需去债 | **关闭（根因 = 人工操作）** |
| TD-07 | ESP v71 同号异字节（CI gz `f08139e3` vs 本地 gz `6fe7811a`=#92 在机件） | Release r91 发布面 vs 在机 | CI ESP 推导撞号（v71 已被本地先建先钉占用，CI 又生成一份同号件） | 发布面 ESP 与在机 ESP 字节不同但同源同版本；读回验收口径已按"CI 件对 CI 件"记档 | 下次发布轮验证「max(release, pin)+1」推导防撞号后转记档 | 在册 |
| TD-08 | 内核 fork tarball（270MB）gitignore + pmaports 提交 `--no-verify` | pmaports APKBUILD 提交流程 | pre-commit 钩子要求 source= 全件入 index，但 tarball 不进仓 | 校验被绕过（checksum 由构建实证兜底）；新人不知情会困惑 | 无干净解（上游化已终判弃用）；保留惯例，靠本文档知会 | 转永久 |
| TD-09 | Mu 链无 initramfs（root=/dev/sda22 烤死在 cmdline） | 内核包 cmdline + Mu | Mu 不传 initrd，结构如此非权宜 | 换根分区/UUID 即废；救援必须走 9008 或 apk 腿 | 非债——结构性设计（见 DESIGN.md），列此防误判 | 转永久 |
| TD-10 | **meizu-wfi.service = 开机 disable 全部深度 cpuidle 态**（K30 r24 同款 WFI workaround，设备包 r5 时代入包，当时未登记本表——本表建档后追认的首条） | device 包 `meizu-wfi.service`，boot 时 `echo 1 > …/cpuidle/state[1-9]*/disable` | 当年治「s2idle flakiness」——**10-23 证实 flake 是真的**：cpuidle 使能态 4 次挂起尝试 3 次挂死（看门狗复位），cpuidle 关全干净，与 wowlan 无关 | **待机功耗全案真凶**：CPU 永不簇塌缩→APSS 26h 仅 7 次/0.19s→清醒 idle 0.95W、s2idle 睡眠 1.15W（≈清醒功耗）→12h 掉电 75%。disable 清零后 120s 进 1122 次簇睡 = 机制全好，但挂起随机挂死 | **退役被阻断，转内核根治轮依赖**：修好「cpuidle 使能×s2idle 挂死」即退役（下会话排面 = S2IDLE 挂死根治轮，见接续卡）；治本超窗则维持现状，功耗问题挂起 | 退役取消，根治中 |
| TD-11 | **数据面 IPA init 握手死窗**（r69 官方化轮发现，2026-11-20） | 内核域（drivers/net/ipa × modem IPA 固件握手）+ 设备包 keeper 延时 start 配套 | modem 内核期自起早于握手窗 → modem 侧 IPA assert（「Init message from A7 not yet received」）+ 硬件 FATAL IRQ crash 泥潭；AP 侧 ipa 驱动 -110 永不重试 → rmnet_ipa0 永不建。r101 = pas DT 开关 qcom,autostart-off + keeper 延时 start ~boot+35s（103 时序复刻）仍 5/5 boot 败；恢复通道全试死（ipa 重载/stop/crash 注入/DMS） | **数据面断**（rmnet0/IPA 通道）；短信/注册面/双卡切换不受影响（QMI 域全通）；dataup -I 硬判 FAIL 诚实呈现 | **内核域专项**：ipa 驱动 init retry 补丁（SSR 事件链健康 = retry 有落点）/ modem IPA 固件域取证（105「MM bearer dial = IPA fatal 炸弹」语境考古：105 轮 fatal 或已把通路炸进慢性态，109 终验 PASS 高度存疑[dataup 旧判据 WiFi 共存语境 = 假绿，r70 已诚实化]）。**已排程（2026-11-20 用户拍板「以后修」，相机主线段收官后顶上）** | 已排程 |


## 二、交叉印证线索（非债，待排程；2026-10-23 skill 审计产出入册）

来源 = `~/.agents/skills/android-mainline-port/`（高通主线移植经验库，~3000 行，
2026-10-23 全文审计）。**通用配方不可照搬（Mu 链/无 initramfs/Alpine 底），只取
交叉印证与新靶**；与硬定律冲突时以本仓 AGENTS 为准。

1. **S5 花屏 B-list 扩充（已落根治卡 §5）**：①VBIF AXI halt 握手（显示电源域掉电
   前缺失 ⇒ CTL 软复位永不完成——彼库已确认根因一例，`dsi_err status=4` 同
   marker）；②双 INTF 关闭顺序（先停 INTF 再清 CTL）+ DSI PHY 状态保存/恢复；
   ③恢复时序（先投票再开时钟；OPP -ERANGE 投票永久丢失 family）。
2. **ath12k 21s resume 线索**：彼库同症状案例根因 = **PCIe 在 s2idle 保留链路但
   驱动关掉了对应电源域**；确认手段 = kprobe 跟踪电源域/PCIe 挂起回调；修法 =
   社区 awake 路径 + 该 SoC 电源域标志。⚠彼库明令**运行中 rmmod/insmod ath12k
   属禁手**（固件二次上电失败可 panic）——我方"WiFi 睡后死重载模块"救急姿势有
   风险，记档勿当正式方案。
3. **廉价只读检查两枚（下个设备日顺手，各一条命令）**：①`systemd-detect-virt` +
   `hostnamectl`——Gunyah `/hypervisor` 节点若泄漏，systemd 判 vm（电源键行为、
   `ConditionVirtualization=no` 服务跳过；7.4 前瞻 gunyah 复查点相关读数应入档）；
   ②`wdctl` + systemd `RebootWatchdogSec`——systemd 默认 10min 会去开 Gunyah
   看门狗（上限 ~32s），普通重启可意外复位（硬定律 #10 只封了 qcom_wdt 内核腿，
   systemd 腿从未核过）。
4. **录音复燃（SWR）方法论互证**：彼库"穷举全失败 ⇒ 必有一个共同固定参数错"
   （他们那边 = DMA 通道掩码）与我方（六十九）BE intf 破案同构；复燃时先列共同
   固定参数再逐个验。wm_adsp 设备树设备只请求通用调参文件坑——我方直驱绕 DSP
   不受影响，记档。
5. **相机驱动轮纪律三条（抄入 s5k3p9 卡复燃时遵守）**：CCI 7/8 位地址换算（我方
   0x5a→0x2d 已互证）；执行器/传感器电压无本机寄存器证据不启用不猜档；新时钟
   控制器/相机驱动首上机必编模块、调试通道建立后手动加载。

## 三、放弃方案（NO-GO）集中地（带复燃条件）

| 方案 | 判词 | 复燃条件 |
|---|---|---|
| 上游化（主线贡献） | 用户 10-14 终判弃用（Nura AI 政策 + boot 链非标结构性冲突）；fork=终态 | 无（用户终判） |
| 0xC4 旋钮（zero_clkout_timing） | 10-19 排雷表 #13 终审洗清 | 无（单变量终审） |
| DSC 内容值轴（flbo/initial_lines/bit17 旋钮） | 10-21 首枪 A/B 判负 | 新证据 = DDIC 要第三种值的实测（参考魅族 22 flbo=15 单字段迭代法） |
| 标准命令域全部主机可达维度 | H1+内容值双判负清零 | 无；病根收缩到 vendor 专有域/非命令维度 |
| rc7 rebase 演练 | 10-19 收官勿重做 | 无（正式轮 10-21 已收官） |
| 路线 D（花屏） | 早期判负勿再提 | 无 |
| NCM 漂移修 | 无需（TD-06 记配方即可） | devsh 动态发现成本降为零时 |
| ath12k B 路（睡眠 hook rmmod） | 挂起待点名；⚠skill 禁手（运行中重载可 panic） | 上游/社区 awake 路径补齐后再议 |
| stock 唤醒 DCS 抓取 | 窗口已关（设备回 pmOS 后失效） | 设备再回 Flyme 且用户点名 |
| 蜂窝复燃贵路（modem_dtb / 内部 NV/EFS） | S3 终判挂起止损；EFS 四分区已双侧哈希存档 | 用户点名 + 大后期预算 |
| DP 外接输出 | 10-06 判负终审（fsa4480 未焊，硬件断） | 换机 |
| Sailfish OS 移植 | 纯调研挂起（高通主线零先例 + Mesa×A740 未验证） | 用户点名 |
| Arch 线（alarm） | 10-09 放弃全删 | 从零评估，勿引旧路径 |
| KVM/虚拟化 | Gunyah 占 EL2，⛔ | gunyah 摘除成功后 |

## 四、候补小件（低优拼车池）

1. **用户第一小时审计清单**：发布面加一节固定清单（语言/键盘/时区/联网/浏览器/
   音量/亮度/电源键/主机名/apk 可用）——并 FLASHING.md 或 README。
2. ~~设备侧自检脚本~~ **✅ 已落地（11-06 离线轮主件 A）= `script/devselfcheck.sh`**：
   自动七项只读（uname 对期望/wowlan show 直读/cpuidle 锁/failed 分型/GPU busy_deltas
   钳零/iio/WiFi 5G）+ 人工眼判四项 + rtcwake 显式门（红线 `-d /dev/rtc1`）；
   结果落 `/var/lib/nura-selfcheck/` 自动与上一份对比。✅ **真机首跑 11-19**（--light：
   4 过/2 警/1 败；判读器两坑记档见条 6）。
6. **devselfcheck 判读器 iw 6.17 格式适配**（11-19 首跑发现，小件）：新版 iw 频点行
   `5180.0 MHz` 带小数点 + wowlan show 输出格式变 ⇒ A7 假阴性 FAIL（5G 实测频点全在
   位）+ A2 WARN。适配后 A2/A7 应双绿。
3. **干净机首航**：发布面成立判据（第二台机器/容器从零 setup→build→flash）——
   项目自 10-07 起在册的遗留，恰 = skill 第 7 步完成标准；排队等条件（第二台机器
   或容器）。
7. **Gunyah VM 通道移植**（11-19 评估轮，用户拍板「以后再说」）：硬件/固件面全通
   （stock FDT 自带 gunyah-hypervisor-1.0 全套节点）；缺口 = 主线驱动已删需旧版
   （6.8 时代 v1.0 语义，SM8550 = 原参考平台）树外移植 + DT 节点（⚠主线
   sm8550.dtsi 无 gunyah_hyp_mem 保留区不补会雷）+ crosvm 打包 + librevm quirks
   平移。中型战役，评估全文 = 记忆 meizu20-gunyah-vm-feasibility。
8. **s2idle 睡中拔线 = 硬复位 3/3**（11-19 设备窗实锤，面板路径无关）：候选域 =
   typec/ucsi/pmic-glink wake IRQ 深 suspend 语境崩溃；复现配方 = rtcwake 长睡中
   拔线；判别 = RTC 唤醒同态全净。独立小战役，与 D4-1/花屏无涉。
9. **s2idle freeze 活锁 waker 识别**（11-19 kprobe 判词续）：活锁期系统仍响应但
10. **temp.json 刷屏根治 = hexagonrpcd 文件服务语义取证**（11-20 r70 还债改判）：persist 未挂载 → PD 字面路径写开失败刷 ~980 行/boot；tmpfiles 可写路径已造**但刷屏未止** = 白名单/alias 层另有乾坤；无害留机，根治需读 hexagonrpcd 源码 open-for-writing 语义。
   dwc3 掉总线 ⇒ netconsole 唯一通道；配方 = livelock 轮 + /proc/interrupts 差分
   （或 irq trace）→ 定名 waker → 定向修复。A1 疗效存疑（实测全 WFI）——挂 fd
   一发判生死，同窗拼车。
11. **camss 上电 → RPMH 平台死锁（GUI 相机路径阻断）**（2026-11-22 一百二十一实锤，取证 =
   私有仓 `cam-rpmh-hang-20261122/`）：plasma-camera 真正上电 3P9 链（csiphy2 power-on
   @uptime10714）→ 246s 后 `camss_runtime_resume→csiphy_set_power→rpmh_write_batch`
   报 `Error sending AMC RPMH requests (-110)`（任务 = CameraManager 实锤）→ 157s 后
   icc 互斥锁雪崩（GPU gmu suspend 卡 icc_set_bw / sugov 卡 RPMH 发送 / **jbd2/sda22 卡
   __bio_queue_enter = UFS 队列冻结磁盘半瘫**）→ 仅 sysrq-b 可救。属 108「camss 流挂
   D 态」家族的 RPMH 级变体。**风险纪律 = GUI 相机根治前勿点**（直驱 cam-shot.sh 参照件
   不受影响）。复燃轴 = csiphy2 950MHz link-freq 上电组合 / RPM AMC 语义 / ICC 带宽路径。
12. **libcamera SimplePipeline 冷启首开 `csiphy2→csid0` EBUSY 谜**（11-22 同轮）：首轮
   init 两连 `Failed to setup link ... Resource busy`，pkill 后次轮 disable→enable 仲裁
   全绿（链路/格式/管线 matched 均通）。当前影响 = 冷启首开相机可能失败一次；复燃 =
   DEBUG 级冷启复现 + `media_pad_remote_pad_first` 前态残留取证。
