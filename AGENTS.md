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
docs/*-card-*.md 各轮执行卡（现役 = plasma-mobile-cellular-card-20261119.md；蜂窝复燃卡+根治卡已 ✅ 归档 docs/archive/）
```

## 现态（2026-11-27 一百二十八轮收官 = 相机残面轮 ✅（④dma_heap 权限破案[用户会话相机全灭真凶] + ①旋转 270 定谳[plasma-camera 应用实证] + touch 假 failed 消音 → failed=0 全清；②「CFA 一行修」判词作废 = 命名撞车零码改；koko+KDE 移动端应用顺手入机）；在机 **#139 + v96 + mu-r138-3f909a93 + r138 模块 + device r87 修订版 + libcamera r2** ✅ 读回双对；**下会话 = Flyme 取证轮（用户拍板；前置 ✅ = 设备包 r89 直装收编 + 仓内回程镜像 r138-plasma[sha 040e6437]，卡 docs/flyme-forensics-card-20261127.md，触发协议 = 用户说「取证轮」，回程零再构建）**；新会话从这里接）

- **一百二十八（11-27 相机残面轮：④①②③五瑕疵清单大清算，用户全程在场，双轮刷写两 reboot）✅**：**④「图标打不开/转圈自杀」破案 = `/dev/dma_heap/*` 0600 root:root 且 systemd 262 上游零 udev 规则** → 用户会话（uid 10000）libcamera「Could not open any dma-buf provider」→ SoftwareIsp 禁 → 相机起不来（**127「预览出画」全是 devsh root 拉起 = 权限失败被系统性掩盖一整天；GUI 相机验证必须真实用户身份**）→ 修 = device **r87** `73-meizu20-dma-heap.rules`（video 0660 镜像 video4linux 惯例；即时落机免 reboot 生效）→ 用户侧预览出画 30 帧实证。**①旋转全案** = s5k3p9sx 暴露 V4L2_CID_CAMERA_ORIENTATION/_SENSOR_ROTATION 只读控制（libcamera 0.8.0 CameraSensorLegacy 只认控制 default、无 fwnode 回退 = 源码级钉死；fork `04d52720bf7f`）+ DT rotation <90>（r137/v95/#138）→ 眼判「侧转修好但上下颠倒」→ **270 定谳**（fork `df96b0421841`，r138/v96/mu-r138）→ libcamera Rotation=270 + plasma-camera「Camera offset orientation: 270」应用实证。**②「CFA 一行修 GBRG10」127 判词作废 = 命名撞车误判**（4 字符 GBRG ≡ V4L2 SGBRG10，驱动标签本来就对；主线无 GBRG10 常量，硬改反引入真对调；复古/暗淡主嫌 = 无调参 yaml AE/AWB 默认）。**touch 假 failed 消音** = cci 子总线 i2c 编号跨 boot 漂移实证（同日两 boot 0-002d/2-002d 各一；deferred 在 vdda 注册后自愈 = 主机制）→ r87 修订 = glob 全 `*-002d` 补枪 + 段尾 exit 0 → **failed=0 全清**（modem-gnss 本 boot 亦过）。**拍照查看链** = 设备零图片查看器 + portal 选择器桌面尺寸（Plasma 上游 UX 缺陷非移植债，屏幕 1080×2400@120 健康）→ 装 **koko** 设 mime 默认 + gwenview 备胎 + 用户选装 kalk/krecorder/qrca/calindori/alligator（kongress 判无用卸）。**终验（用户）= plasma-camera 图标正常打开 ✅**（DISPLAY 拆雷管 + r88 端到端实证；相机日用链 = 图标→预览→快门→落盘→koko 查看全通）。**⑤图标启动挂死全案破（二段新雷）**：清场后图标仍两次失败 → 取证 = 进程活着零 CPU 无窗口无崩溃 → 环境二分复现（图标全环境含 **DISPLAY=:0** 卡死 / 去 DISPLAY 完美 / 强制 QT_QPA_PLATFORM=wayland 仍卡 = 卡点非 QPA）→ strace 死点 = `connect(@/tmp/.X11-unix/X0)` 永不返回 → 终局 = **Xwayland 二进制没装**（pmOS plasma-minimal 不带），kwin "Xwayland process failed to start" 但保留监听 fd + 会话照发 DISPLAY → backlog=0 无人 accept 任何碰 DISPLAY 的应用永久阻塞（devsh/su 直拉无 DISPLAY = 纯 wayland 结构性不触雷 = 第二个掩盖面）→ 修 = **device r88 depends +xwayland**（根修组件）+ 本会话拆雷管（`systemctl --user unset-environment DISPLAY` + restart plasma-plasmashell）。**⑥色彩眼判回执 = 发灰**（实图复核：黑位抬升+饱和压制灰纱感）= soft ISP uncalibrated.yaml 兜底 → **s5k3p9sx.yaml 调参轮正式立项**（下轮相机线主件）。**③落盘回执 ✅**：四张实拍全落 ~/Pictures（127「不落盘」= dma_heap 综合症）+ EXIF Orientation 四张全缺 = 姿态跟随缺口定案 plasma-camera 上游 App 层（D4 动态半边），非移植债。**坑册四连**：boot_b readback 整分区≠镜像 sha（分区 96MB≫镜像 1.1MB，限长 count 对拍）/ devpush nc 监听竞态（devsh 会话关 → nc 吃 stdin EOF 早死，60MB 进死套接字；**确定性形态 = FIFO 持握手** `mkfifo+sleep 300>fifo & exec nc -l < fifo`）/ pmbootstrap 单实例互撞（后台 build 与前台 checksum 并发 = 构建单元静默死）/ watcher newermt 阈值勿写未来时刻。残面余件 = 色彩 yaml 候补 + 拍照落盘复测（眼判回执待）+ GL upload 回退小损 + 视频编码面独立线。详录 = experiment-log（一百二十八）。
- **一百二十七（11-27 相机轮：③camss→RPMH 死锁 + 用户所见 GUI 报错，用户在场，三构建两 reboot）✅**：**主件全胜 = RPMH 死锁防御落地 + GUI 相机缓冲双修 → plasma-camera 预览出画**（SoftwareIsp debayer 8445µs/frame 30 帧实证 + RPMH 全窗零雷）。①**RPMH 全案闭合**（死锁链源码级：bcm-voter AMC 提交超时留 TCS 永久占用 + `rpmh_rsc_send_data` 无限等 + icc_lock 饥荒；案发 = 11-22 boot -15 journal 尾段尽失[/run 未刷盘]，栈面源码重建五要素全对上）→ fork `79a4a228c09d` 收兵补丁（超时后按地址回收卡死 TCS，req[] 先 NULL 防迟 IRQ UAF）→ r133 上机 #134。②**GUI 报错「configuration not valid」真凶** = libcamera 0.8.0 堆序首开独占零回退（reserved = CMA 32MB 池 < SoftwareIp 输出缓冲 61.7MB；系统堆实测健康）；CMA 512 尝试轮（r134/v93 → #135）实锤**平台早期分配窗放不下**（`cma: Failed to reserve 512 MiB`，32MB = 0xf0800000 缝隙天然上限，大 CMA 只能走 DT）→ 回滚 32（r136/v94）+ **pmaports temp/libcamera 刷上游 99990.8.0 + 0003 堆序补丁**（system 队首，pkgrel r2）→ #137 预览出画。**坑册五连**（--pipe 五五开秒退 2 / pkill 自咬+apk.static 孤儿 ETXTBSY / pmbootstrap 默认 native 要 --arch aarch64 / journal --grep 不可靠 / apk add 主包 purge 子包须补装 libcamera-ipa）。**眼判待回执**（画面/色彩/方向）；候补 = GL import upload 回退（效率小损）。详录 = experiment-log（一百二十七）。
- **一百二十六（11-27 深睡线解锁轮，用户全程在场，零构建零刷写）✅**：**主件全胜 =
  屏灭底噪 0.9-1.1W → 0.58W 档（中位 0.555W / min 0.523W，排面目标 0.5-0.6W 命中，
  ≈砍半）+ s2idle 7/7 全净**。①**E1 解禁**：meizu-wfi 三簇深态 sysfs 可逆翻转
  （cpu-sleep-0/1/2-0 = silver×3/gold×4/prime×1），90s 窗每核深态 220-6299 次 ≈
  **近 100% 深态驻留**（cpu0 state1 use 201→153k）；②**E2 tuned 翻案**：只持
  `/dev/cpu_dma_latency` fd **未写限制**（QoS 停止前后恒默认 2e9ns），**非禁睡锁**，
  已还原不动——125 判词「三重禁睡锁」改判 = **真锁只有 meizu-wfi 一把**；
  ③**E3 rtcwake 阶梯 30/60/120/300/600/600s = 7/7 全净**（succ=7 fail=0，Freezing
  0.002-0.003s，resume 恒 0.428-0.452s，**freeze+EBUSY 零复现**，wowlan 开 = 日用形态；
  中断差分全为醒后噪声，waker 猎捕没上桌）；**功耗窗** = 拔电+灭屏 140 样×5s
  （WiFi ssh 收数，采样器设备侧脱会话）。**处置（用户三拍板）**：meizu-wfi
  disable+**mask 落机**（恢复门 = unmask+reboot 或 sysfs 回写）+ **入包摘除挂下一版
  device 包**（含 mask 死链清理，TD-10 去债）｜s2idle 加码 600s×2（已跑完）｜
  TD-8 拔线雷延后候补。**★坑册 = netconsole 双通道结构性全废**（usb0 = NCM gadget
  原子发送死[宿主 tcpdump 0 包] / wlan0 = mac80211 原子发送死[tx.c:3928 WARN]，裸
  UDP 通 = 链路无墙）→ TD-9 取证改道 = 事后 dmesg + suspend_stats 指纹 + 中断差分；
  **sleep 探针必须设备侧 systemd-run 脱会话**（宿主会话把睡窗打醒，r1 早醒 1.2s 实证）；
  dmesg 跨睡停走只认墙钟；mem_sleep 本机 `[s2idle] deep` 双档在册（deep = PSCI
  SYSTEM_SUSPEND 未测另案，§TD9「主线无 deep」记勘误候选）；未证线索 WLAN timeout
  本 boot 零命中注销；busybox fuser 无 -v；电池供给名 = qcom-battmgr-bat。
  取证 runner 留机 = /var/tmp/deepsleep/{sleeprun.sh,powsamp.sh}。
  **钉子不变**（#133+v91+mu-r131+device r85+hexagonrpcd r8）；failed=1（modem-gnss
  在册）；详录 = experiment-log（一百二十六）。

- **一百二十六·补段（同日 TD-10 去债 + s2idle 功耗判定）✅**：**TD-10 已还** =
  device **r86**（pmaports 40d7b1e 补录 r85 五件 + 9cb9128 摘 meizu-wfi：APKBUILD
  摘 source/preset-enable + pkgrel 86 + tmpfiles `meizu20-retire-wfi.conf` 清机上
  mask 残链；verify 全绿；sha 737ce0ca 对拍后 apk 腿 WiFi 通道上机）→ **reboot 全验
  绿**：wfi 三处消失（unit/mask/systemd not-found）+ **fresh boot 深态即开**（8 核
  dis=0 use 即爬）+ wowlan 保持 + keeper/MM/connected + plasma active（r85 排序晚亮
  预期内）+ failed=0 + 60s s2idle 复认干净（62s 墙钟 succ=1）。★顺手账 = r85 五件
  曾漏 pmaports commit（树态=在机真值），本笔补登。**s2idle 睡态功耗首测 =
  ≈0.45W**（±0.05；22min 拔电库仑计窗 39mAh×4.40V，5×240s 真睡 + 5×25s 醒隙解耦，
  采样器空档=睡相对齐）→ **睡比醒省**（0.45 < 0.58W 清醒屏灭；锁死时代 1.15W 反
  修订史）→ **AutoSuspend 建议 = 电池档开 600s / AC 档保持关**（过夜 10h 32%→25%；
  用户自选档，未代操作）。坑册 = ssh 会话 systemd-run 需权（sudo -S 包装；devsh
  root 会话免）+ USB 通道全程不可用 = 用户窗口超时未插线（用户勘误，非老 usb0
  雷复现，历史雷未涉仅备查）。
  设备现态 = **#133 + v91 + mu-r131 + device r86 + hexagonrpcd r8**。
  **推送窗 ✅ 清零（同日用户令）**：nura master 8 笔（125 轮 3 + 本日 5）+ pmaports
  phoenix 13 笔（含 r85 补录/r86）全推，ls-remote 双实证齐（31133ba / 9cb9128）；
  fork 零改动无涉；pmos 私有无远端照旧。
  **pmaports 分支改名（同日用户拍板）**：`phoenix`→**`meizu20`**（phoenix = K30 代号
  化石[K30 已退役 10-09]；远端推新名 + gh 切默认 + 删旧名，本地 rename + tracking
  修正 + config.sh 钉子/CI build-release.yml/六份活文档全对齐；ls-remote 实证唯一
  分支 meizu20 @9cb9128 默认 HEAD；历史叙述中的 phoenix 保留原样 = 当时事实；
  坑册 = gh 在沙箱直通[走代理路径]，systemd-run 包装 gh 反而全静默；443 间歇断
  照旧 ls-remote/删除等操作带退避重试）。

- **一百二十五（11-27 功耗核查轮，拔电夜取证，用户在场）**：**屏灭整夜 0.9-1.1W
  定谳 = 三重禁睡锁**（①`meizu-wfi.service` multi-user oneshot 禁三簇深 cpuidle
  [自述 s2idle flakiness 规避 = K30 r24 WFI 同族；本 boot power collapse 仅 43 次/
  186ms] ②`tuned` 2.28 balanced 握 `/dev/cpu_dma_latency`[PM QoS 禁深 idle；停掉
  即释放实证，已重启还原；与①独立] ③用户 AutoSuspend=0[保留]）；组件面全净（无
  流氓中断/wake 锁/WiFi PS/BT 封）；**屏灭 = 真断电**（bl_power=4 + DSI disabled +
  msm/dsi/gpu IRQ 零跳）；「灰屏」判词 = AC 档无 Display 节永不自动灭屏 + 电池档
  5min 调暗阶段（用户拍板不改，手动关屏即可）；**坑册** = /proc/interrupts pmic_arb
  行 NF-2 是 SPMI 外设 ID 非计数（曾误判 temp-alarm 风暴 1850/s 后撤案）。窗口账 =
  11-26 17:45→01:15 共 7.7h 掉 43% 平均 1.05W（亮屏段 2.1-2.5W×~0.5h = 差额大头）。
  **钉子不变**（#133+v91+mu-r131+device r85+hexagonrpcd r8；零构建零刷写）；
  详录 = experiment-log（一百二十五）。

- **一百二十四（11-26 无人值守轮，用户授权刷写）**：①**carrier DNS 上链定谳+修复** = NM
  resolved 插件对「无 search domain 且未赢得 ~ 默认路由竞选」的条目**整条丢弃**
  （`nm-dns-systemd-resolved.c update_add_ip_config` 早退门；TRACE 实录
  `default-route=0, search=`；MM bearer→NM 全程带 DNS 无涉；wlan0 持 ~ 故蜂窝条目被
  shadow）→ 修 = profiles `dns-search=cellular` 过门，**实弹 211.139.5.27/28 上链
  qmapmux0.0**（r82 FallbackDNS 改冗余保险；NM upstream「Generic push」候补**关闭**）。
  ②**temp.json 判负回滚** = 语义取证结案（apps_std 无条件拒写开、先拒再解析、上游同态）
  → 0006 写通道补丁部署**前半程全绿**（刷屏 981→0 + 0x190 + 传感器活）随后引爆：PD 后续
  **>256B 输入缓冲 RPC 撞解码器上限**（`Large (>256B) input buffers aren't implemented`）
  → sensorspd Restart=always 重启环（16 次/boot）→ ADSP 风暴 → **整机自动重启 ×4**（用户
  目击）→ **设备回滚 hexagonrpcd r8**（pmaports 回退 d810d39）；根治前置 = iobuffer 解码器
  >256B 支持（TD-10 改判挂候补）。③upstream MM 复燃判据核查 = qcom-soc 快照 20261005 后
  零提交，真 DSDS/NM×MM 判据不变。④**device r83 留役**（dsp-mount 有界重试 + tempjson
  conf 根-路径版 + dns-search profiles；全被动零险；实机 dns-search 冷 boot 即上链）。
  ⑤「触屏/音频桌面后才起」定谳非 r83 = touch/amps/sndcard 挂 After=multi-user（r78 设计）
  vs plasma accel-barrier 链并行赛跑，本 boot cell-mm-rescue 拖 multi-user 50s > barrier
  24s → 桌面先亮（P3 已知形态）。**坑册**：①wrapper 即发即返竞速（checksum 单元未完即发
  build → 双 pmbootstrap rm/cp APKINDEX 互杀；判完成只认产物落盘）②pmbootstrap x86_64
  宿主 crossdirect 死锁（gcc-x86_64 同宿主 flavor 无仓可解 + chroot 记录被竞态半重置；
  解 = 包加 `!pmb:crossdirect` 转 QEMU 路 ∥ gcc-aarch64 原生链自举）③本地仓 sha512 手工
  补算（checksum 单元被打死未落）。**在机 = #133 + v91 + mu-r131 + device r85 +
  hexagonrpcd r8**；详录 = experiment-log（一百二十四）。
- **一百二十四·补段（同日晚，用户定谳「触屏/音频/传感器应早于桌面」）= device r85 启动序修复**：touch/amps/sndcard-bind/audio + sensors-barrier 五件加 `Before=plasma-mobile.service`（r84 的 `Before=graphical.target` 对兄弟单位无 pairwise 边不生效 = systemd 排序语义实证留档）；实机 reboot 验序 barrier→touch→amps→sndcard→**plasma 最后亮**，failed=0（modem-gnss 首次全过），传感器/蜂窝/数据/DNS 全绿。非标残余备注：cell-mm-rescue（r81）仍占 multi-user 事务 ~50s = 桌面整体晚亮的下一段优化空间（候补：rescue 挪出 multi-user 事务，动 r81 合同须用户拍板）。

- **设备**：**11-19 双卡轮 ✅（一百零四）= 蜂窝自动化 + 双卡（用户令「插卡即用/
  随意切换/设置状态栏显示」，离场授权捣鼓；战报 = experiment-log 一百零四；
  承接一百零三数据面全通）——**
  **registered/PS attached 5gnr 460-15 广电；rmnet0 活（ping 2/2 26ms）；
  MM enabled 稳态+信号读出（41-48%）；failed 0**。
  **插卡即用全自动链（reboot 全验×2 通过）** = meizu-pas **drop-in 解封**
  （`unseal.conf`：封印流程保留+尾接清 override+bind mpss+start；⚠勿另立 unit
  挂 meizu-pas 依赖——其 After=multi-user+WantedBy 自环拖死 ordering cycle，
  systemd 会砍新件）→ mpss up → rmtfs → msm-modem-uim-selection（**pmOS 官方
  形态 enable**：RequiredBy=MM+multi-user；单 active 槽下与 MM 零冲突）→
  MM enabled → **cell-keeper**（rf_keeper 落地：45s 轮询，session 丢失→自动
  re-provision slot1+舞步，DMS offline 死锁→舞步；受控复验通过：deactivate 后
  75s 自动回 registered）+ **cell-dataup**（boot 自动 d1_dataup，PASS 实证
  = 队列⑥ rmnet0 持久化落地形态）。全部件收编 tools/cellular/。
  **双卡形态 = 单 active 槽 + 切换脚本**：MM qcom-soc 插件双 active 槽 hot-swap
  误判（enable 内毫秒级 SIM identifier 漂移→disable 循环 21 次/min；**NM
  auto-enable = 循环加速器**实锤[autoconnect check 特征；stop NM 循环消失]）→
  `uim-sim-power-off=2` 单卡化即稳；**cell-switch.sh 双向实证**（46015 广电 ↔
  4600 移动；两卡同 AID[UICC 模板]，区分靠 slot 参数）。真 DSDS 双 standby 挂
  候补等 upstream MM。
  **短信主件 A 半武装收兵（三墙记档）**：①WMS transport (1,52) DeviceNotReady
  （投递域未激活，LTE/5G 同态，无用户态旋钮；实发两条 test 未达设备）②IMS PDN
  网络拒（mux 0xF2+APN ims bind 全绿 → start IPv4=3GPP_NETWORK_FAILURE/38、
  IPv6=IPv6 类 1 = 测试卡 IMS 接入未授权，运营商面）③SMSC 缺失（bare→73/
  空头→58 双签名）+ UIM 文件读取系统性拒（EF_MSISDN/SMSC/ICCID 三文件变体矩阵
  全 58）。探针链全通（wms_probe.py：ctypes WMS+libqmi 定义+TPDU GSM7/UCS2）。
  复燃路 = MM enable 序列 / 运营商 IMS 订阅。收发工具链留机+收编。
  **坑册新增**：本机 modem WMS 响应 flags=2（tid==0 才是 indication，tid 回显
  非零=响应）；Raw Send format=0x06（GSM_WCDMA_POINT_TO_POINT）；qmicli NAS
  组合 mode 语法不认（单值 `5gnr` 可）；sh 无引号 `Q=qmicli -d qrtr://0` =
  `-d: not found`（keeper/switch 双中招）；DMS offline 态机死锁（reset 也只回
  offline，唯一恢复=reboot）；mpss stop 无 fatal 也静默拒（101 判词升级：本平台
  stop 常态不可用）；MM restart 搅注册（init 碰 UIM；静态 active 共存零干扰，
  init/enable 流程是干扰源）；libqmi 拉定义 = gitlab API tree 找 data/qmi-service-*.json。
  **D3 签名 ledger 更新**：fatal boot 数据面照通（本 boot fatal ×2 + dataup PASS
  ——「fatal 必瘫数据面」102 判词作废）；签名不定根治仍挂。
  解封仪式（手工形态备查）= 清 override（"none"≠空串）→bind→start→查 session→
  re-provision（AID `A0000000871002FF86FFFF89FFFFFFFF`）→舞步；数据判活 =
  `sh /usr/lib/meizu20/d1_dataup.sh 223.5.5.5`（包化路径；/root/d1_dataup.sh
  = 手工别名件，内容与包内源镜像同步[11-21 网络诊断轮起含 FAIL 清死路由]）；
  切换 = `cell-switch.sh <1|2>`；取证 journalctl -k。
  在机 = **#96 + v75 + mu-r91 + plasma-mobile rootfs**；slot 2 移动卡 power-off
  待命；EFS 快照**四份全等**（b85cad2f/c40223e6；第四份 = efs-snapshot-20261119
  -sms-round）；NAS 5gnr-only 偏好非持久（reboot 回 auto，网络侧自驻 5gnr）。
  iOS 线并行走用户——**iOS 工作区/文档零接触，传话 = 用户转告**。
- **版本钉**：apk **r138**（在机 **#139**，11-27 相机残面轮二段：DT rotation 270
  定谳[df96b0421841]；r137 = orientation/rotation V4L2 控制一段轮留档
  [04d52720bf7f]；r136 = CMA 回滚 32 基线恢复留档；r133 = RPMH 收兵轮留档[fork
  79a4a228c09d]；r132 = 电池遥修留档[24df27f74fc4]；r131 = TD-11 根修轮留档
  [DTS IPA IMEM 恒等映射 cf99fc7ad737]）+ ESP **v96**（裸 `20be6b58` /
  gz 14402949B，在机，读回 ✓ 限长截取）+ **mu-r138-3f909a93**（boot_b，
  FdtBlob 与 r138 apk 同源 dbbbcfc6，读回 ✓ 限长截取；⚠boot_b readback 整分区
  ≠ 镜像 sha）+ **libcamera 99990.8.0-r2**（pmaports temp/libcamera
  刷上游 + 0003 堆序补丁 system 队首；ipa-r2 已补装）+ **设备包 r87 修订版**（r87 =
  11-27 dma_heap udev 规则 video 0660[用户会话相机全灭真凶] + touch retrigger
  glob 化+exit 0[cci i2c 编号跨 boot 漂移]；r86 = TD-10 去债留档；r85 = 启动序修复五件 Before=plasma-mobile；r79 = mm-dial
  BP 抓取修留档）；**fw r4**（已随 r131 发布；11-27 随 r89 轮 --force 重打同内容）。
  **→ 11-27 取证前置推进**：设备包仓内已到 **r89**（直装件收编 = world 差分法：
  koko/gwenview/kalk/qrca + gnss-share 两件 + ofono + megapixels +
  i2c-tools/v4l-utils/strace + libcamera/libcamera-ipa 显式化[99990.8.0-r2 版本
  胜出]；机上未装不碍事——回程镜像内建，下次 apk 腿升级自然带上；MP 收尾轮顺延
  **r90+**，pmaports `6d64a92`）+ **仓内回程镜像**
  `meizu-meizu20-r138-plasma-mobile.img.gz`（gz 1242733575B sha256 `040e6437…` /
  raw 4978638848B；本地裸件 plasma-mobile-local.img 免解压直刷；gzip -t +
  debugfs 内容抽验 + verify [1]-[5] 全绿）——**Flyme 取证窗回程 = flash-batch
  （mu-r138 + v96 在仓在钉）→ userdata 刷本图，零再构建**。
- **发布面**：**Release r131 = Latest（2026-11-24 上线，8 件制，双 UI 首次）**——
  plasma-mobile `b18a6be1`（**默认 UI**，11-22 用户拍板「两个都传，以后默认 plasma」）
  / phosh `fcd6c662` + mu `f51b3b09` + ESP v90 gz `037c8dfb`（CI 同号异字节；在机
  本地件裸 `6efc31e0`）+ **fw r4 tarball `97d7b489`（首次发布）** + linux r131 apk
  `7156e527` + upgrade-r131.zip + SUMS；CI run 45225314330 全绿；r91 = 上一代
  （phosh 单 UI）。升级口径 = apk 腿 + ESP 腿原地升级（`script/upgrade.sh`，⚠真跑
  须显式 --apk/--esp；CI rootfs 钥墙 = --allow-untrusted）。
  **云构建两条输入（2026-11-24 起）**：`fw_seed_tag`（仅当本轮 fw tarball 尚未随
  Release 发布时用；fw r4 已随 r131 发布 ⇒ 后续轮走默认 `PIN_RELEASE_BASE` 拉取即可）
  + `nuget_seed_tag`（**默认不用**：mu_nasm 现由 CI 自己 curl Azure feed 建 NuGet
  缓存，探针实证 runner 可达；该输入仅为 feed 长期不可达时的兜底，届时须临时建种子
  草稿）。⚠Mu 分支曾被 UniXNU 接线污染（`DeviceBuild.py` 加 `../UniXNU/package`）
  → 该实验存档于远端分支 `unixnu-wiring-20261030`；主分支 = 可构建树。
  ⚠Mu remote 原 SSH，22 断时 `git fetch` 静默失败致本地 ref 陈旧 —— 已改 https，
  远端结论必须 `git ls-remote` 实证。
- **▶ 下会话排面（2026-11-27 立；**用户晚拍板：下会话 = Flyme 取证轮**，见下
  ★Flyme 段——前置已毕，回程零再构建；本节 A/B/C/D 顺延取证轮之后）**：
  ~~①TD-10~~ ✅ ｜ ~~③RPMH~~ ✅ ｜ ~~相机残面五瑕疵~~ ✅ 终验过线（图标/预览/快门/
  落盘/koko 全通）；
  **A. s5k3p9sx.yaml 调参轮（主件，治发灰）**——soft ISP 调参档：BlackLevel 64
  （decode-color.py 8bit 域 16×4 线索，上机 raw 直方图实证）+ colourGains 实测
  （灰卡/白纸场景校准）+ 对比度曲线；交付 = libcamera r3 → 上机 → 用户眼判对比。
  **B. r90 设备包（MP 收尾；r89 已被 11-27 取证前置直装收编轮占用）**——meizu,meizu-20.conf 入包（797B 已验到 stride 前）
  + temp/libmegapixels Padding 配置键补丁（parse.c 加键 → mode.c padding 优先取
  配置值；可上游零破坏 daisy）→ MP 端到端（预览/拍照/EXIF orientation/姿态跟随）。
  **C. accel claim 小案（快件）**——iio-sensor-proxy "Sensor claim not allowed"
  D-Bus 策略取证 = MP 动态旋转前置（桌面 sensors 正常非链路病）。
  **D.（用户拍板）新 Release 时机**——叙事候选 = 相机 GUI 可用 + 图标挂死修复
  （xwayland）+ 深睡解禁 0.58W + 蜂窝全自动；发灰 = 质量项不挡可用性叙事，A 后切
  或直接切由用户定。⚠三仓推送窗未清（fork 2 + pmaports 5 + nura 8 笔照律待推）。
  候补池照旧：GL upload 回退（效率小损）｜视频编码面（venus encode 独立线）｜
  干净机首航（Phase-2 判据）。
  **相机矩阵排期（用户 11-27 问「其他摄像头何时做」）**：**GN5 主摄 = A/B/C 之后
  的下一个主件轮**（50MP 日用价值最高；bin 已全解 + stock FDT 真值在档 + 3P9 配方
  包现成[驱动模板/CFA 红盒法/cam-shot/libcamera 集成]；OIS/AF 马达先跳过定焦拍摄）；
  **GD2 = 不可排期**（研究墙 = FW 过渡态编排，复燃条件 = 文档级资料/新外部参照，
  勿主动排）；**5E9 = GN5 后低优捡漏**。
  **★Flyme 取证窗口轮 = 下会话主件（用户 11-27 晚拍板「下个会话就是取证轮」；
  A/B/C/D 顺延在取证轮后；需用户在场多窗口）**：
  12.6 EDL 整刷工作流在档（71 分区一次点亮实证）+ stock 镜像本地备份 + EFS 快照
  四份全等——取证清单先写好再动手：①闪光灯 torch 点亮态探针（PMIC/GPIO/轨电压实况
  = 阳极供电谜复燃条件本体）②GD2 前摄工作流 camx/csiphy/csid 寄存器 dump 与我方
  失败态差分（= 「新外部参照」本体，研究墙钥匙）③通话中 tinymix 全量 + AGM graph
  （= 通话音频施工图）④GNSS LOC 会话行为探针⑤GN5 OIS/AF 马达 I2C 探针（GN5 轮
  弹药）。⚠userdata 抹除先备份；modemst/persist 红线照旧；回程 = flash-batch
  （mu-r138 + v96）→ userdata 刷**仓内回程镜像 r138-plasma**（r89 直装收编 +
  libcamera r2 内置，**零再构建零补 apk**；FLASHING §3 首刷路径顺手验真）。
  注：此轮 ≠ 干净机首航（后者 = 构建侧二机/容器从零 clone-build-flash，仍待二机/容器）。
  **弹药已备（2026-11-27 预置）**：执行卡 = `docs/flyme-forensics-card-20261127.md`
  （前置/工具/流程/回程/判据五节）+ 探针 = `tools/flyme-forensics/`（00-prep 静态
  自建[pmbootstrap chroot musl -static，勿外来二进制] + 10-torch/20-camera/
  30-call-audio/40-gnss/99-collect + src/ 四件自研 C[media-dump/v4l-fmt/tiny-mix/
  i2c-scan，Android 零动态库依赖]）。**前置 ✅（11-27 晚，nura `ea4a827`）**：
  设备包 **r89** 直装收编 + 仓内回程镜像 r138-plasma（gz sha256 `040e6437…`，
  debugfs 内容抽验 + gzip -t + verify 全绿）——回程零再构建。**触发协议：用户刷回
  Flyme 后说「取证轮」→ 第一步跑 00-prep 出静态件 → 窗口纯执行。**
  深睡线残面（全部候补不挡路）：TD-8 睡中拔线雷取样（用户拍板延后）｜deep
  （PSCI SYSTEM_SUSPEND）档未测（§8 旧判进不去 AOSS，另案）｜s2idle 日用长稳观察
  （挂 AutoSuspend 与否 = 用户自选；解禁态已 7/7 全净）。
  纪律存档：sleep 探针 = 设备侧 systemd-run 脱会话 + 睡窗宿主零流量 + 真实时长只认
  墙钟（dmesg 跨睡停走）；netconsole 勿再投（双通道结构性废，§TD9 勘误已入册）；
  插线不算离线待机验证；不开 E 长跑（挂过夜循环长跑须用户明示解禁）；
  journalctl --grep 全库扫描勿用（先 --list-boots 定 boot 再整取）。
- **上轮排面存档（2026-11-25 更新：①已收官）**：
  **~~①电池遥测单位 bug 修（r132）~~ ✅ 11-25 收官**（#133 上机修复实证 +
  upower 复活；阈值写读仍 0 = firmware 域独立案改判候补；功耗首测取消
  [用户口径：花屏修复后功耗明显下降]）；**同轮加做（用户插卡+无人值守授权）：
  蜂窝 UI 开关 + 上游回归 = P2 全通**（NM 拨号全链真通：bearer→qmapmux0.0
  IP→表 1430→ping/HTTP；r78 qrtr0 managed + profile 入包；r79 mm-dial BP 修；
  **★单 call 域定谳 = NM×mm-dial 互斥**；标准化路线 P3[退役 mm-dial/keeper
  数据面看门]→P4[profile autoconnect=true] 等下个有卡窗，执行卡
  battery-cellular-ui-card-20261125 有全档）。
  **②S3 5E9 前摄**（配方同 S2）｜**③camss→RPMH 死锁**（GUI 相机唯一拦路虎，设备窗）
  ｜**④干净机首航**（Phase-2 最后判据，零设备风险）｜**~~⑤NM 标准化 P3-P4~~
  ✅ 11-25 晚收官**（P3 = r80+r81：数据面交还 NM 标准形态[autoconnect=true +
  mm-dial boot 退役 + cell-mm-rescue 补 boot 救援隐性依赖]；failover/DNS 实验
  全有答案[路由晋升主表原生可用 / FallbackDNS 兜底]；reboot 全验通过；P4 无余项
  ——上游形态已完全就位，余 = carrier DNS 不落 resolved 已接受[NM upstream 面]）。
  carrier DNS push 缺口已折中落地（r82：resolved FallbackDNS = 移动 carrier DNS+AliDNS，11-26 断 WiFi 实弹验证）；根治候补 = NM upstream 查 Generic device push 路径。
- **队列**：①**花屏科学解 ✅ 达成验收属实收官**（PANEL §6 条 11.7-8）；
  ~~残面挂起 = S2IDLE 深睡线~~ **✅ 11-27 一百二十六主件收官**（解锁+0.58W+7/7；
  残面收窄 = TD-8 拔线雷候补 + deep 档另案，见下会话排面节）；
  ②**蜂窝线 ✅ 八连收官（11-19~20，短信破墙轮 = 用户点名复燃后收官）：
  registered（一百零一）→ DPM 根治（一百零二）→ 数据面全通+托盘（一百零三）→
  双卡自动化：插卡即用全自动链+切换实证+keeper 自愈+rmnet0 持久化（一百零四）→
  **NM/MM 整合轮判负（一百零五）= 103 红线三死路实验级钉死**（MM bearer dial =
  IPA fatal 炸弹 kernel 实锤 / NM×qrtr0 link-not-init / NM enable = 循环加速器；
  Mobile Data 开关灰 = 结构性常态）→ **★短信破墙轮 ✅（一百零六·丙，11-20）=
  MT/MO 双向往返全通（移动卡）**：MT = WMS→MM→SpaceBar 全链（用户实发 "test"
  DB 实录）+ MO = MM send 成功 SMSC 零障碍；**104 三墙改写** = transport/SMSC
  两假墙（当时注册态波动语境）+ 广电 = 结构性不通（SA-only 网短信唯一路 = IMS，
  未授权拒 38；复燃 = 用户向运营商开通 VoLTE，非技术债）。线上成果 = registered
  5gnr + 数据面全自动 + 双卡切换 + keeper 自愈 + 官方核查（一加6 三项全 P/无
  DSDS 承诺）+ **短信收发（移动卡）**。
  **残面全部挂候补（用户拍板「以后做」）**：①NM/MM 整合复燃（upstream MM 修复
  或 plasma-nm 直连 MM）②真 DSDS（同 upstream 前提）③~~短信~~ ✅ 已破（移动
  卡双向往返；广电卡待 VoLTE 开通）④B 件 NAS 偏好持久化 ⑤D3 init 崩根治
  ⑥通话音频（大后期；前置 IMS attach = 运营商订阅面钉死，广电真卡拒 38 复现）。
  **设备包化四件 ✅ + 链腿包化 ✅（11-19 深夜两轮，见⑤）**；
  ③**Plasma Mobile 出件+上机+蜂窝用户态回归 ✅ 全链收官（同日；A 6.8.3-r0 出件 +
  B 用户自刷查收全绿 + C ✅ 本轮 = 卡 docs/plasma-mobile-cellular-card-20261119
  全项达成 → ✅ 已归档 docs/archive/）**（在机 = #96 + v75 + mu-r91 +
  plasma-mobile 6.8.3-r0 rootfs；⚠plasma rootfs 坑两连 = meizu-dsp-mount boot
  早期时序雷[restart 即愈，候补加重试] + iio 零节点[TECH-DEBT 候补 6 维持]；
  蜂窝资产 = tools/cellular/ 收编 + d1_dataup.sh 配方 + EFS 快照三份全等）；
  ④推送窗口 ✅ 已清（**11-20 再清零：nura 四笔[af01686..10b8c88] + pmaports 两笔[4dca91f/d0ef5ee = r64+r65]全推**；11-19 深夜曾清[nura 六笔+pmaports r95 bump，dc38852/4789107]；⚠SSH 22 断坑=https 通道走通；pmos_linux 永久私有无远端不推；**sfos = 独立项目本仓无远端不建不推（用户拍板 11-20，勿再提）**）。
  ⑤**本轮（11-19 深夜两连）+ 下会话排面**：设备包化四件 ✅（**r64**，pmaports
  `4dca91f`/apk `11f96db7`，九件仓↔机对拍后入库，preset +2）→ **链腿包化 ✅
  （r65，apk `8e63856e`，十三腿[rmtfs 三件/uim-selection 两件/MM 三件+base-ui 两件/
  soc-qcom-modem-systemd/tqftpserv/qrtr]进 depends = 新 rootfs 开箱插卡即用全自动；
  在机 #96 双轮 apk 腿升级+冒烟全绿[failed 0/keeper/dataup/pas/rmtfs/MM 全 active/
  registered 保持]，在机手工腿幂等零变化）**。**GNSS 取证轮 ✅（11-20 一百零七：
  fw 补料路判负[发料面=stock 全量清白 + LOC 启动零讨料] + PDS 闸门改判 modem
  内部 EFS/NV 记录域，AP 用户态无旋钮；TFTP 根结构性坑修讫[手工根会失，机上已
  重建正确形态 image→meizu 目录，包化 tmpfiles 挂候补小件]；复燃路改写 = stock
  对照/Flyme 窗取证真料/upstream PDS 语义，全大后期档；战报 = experiment-log
  一百零七）**。**▶ 相机驱动轮·第一段 ✅（11-20，一百零八；用户点名「能驱动多少
  就算多少」+ 自刷授权豁免执行）：camx sensormodule .bin 格式全破解
  （40B 记录+子链下标寻值；解码器 = meizu20-m1/vendor-dig/camx_regs_decode.py，
  四星全组 0 未解）→ **s5k3p9sx.c 自写上机（首 ACK 0x3109 命中）**+ RDI 管线
  全链 fmt 配置通 + **传感器健康在流实证**（流中 i2c 回读 0x0100=0x0103）；
  残墙 = MIPI 零包（csiphy settle 未校准，扫频网格已备：驱动 12 档可写
  link-freq 200M-950M）；**新雷三件** = hub_3 竞态两连 boot（手踢
  `echo 98c000.i2c > /sys/bus/platform/drivers/geni_i2c/bind`，挡相机）/
  camss 流挂 D 态（load 34，sysrq-b 才救回，**流进程禁 kill**）/ probe 期
  mclk WARN 杂音；在机 = boot_b mu-r97 + recovery_a v76（r97 vmlinuz）+
  r99 apk = **#98 + 模块 r99 混态（无害）**；fork 四连 commit
  ca1c283b/c65d4a6/da5af35/3bc4f16 + pmaports 65c41f6/1c0bb77；详录 =
  experiment-log（一百零八）。**▶ 多档刷新率轮 + boot 事故轮 ✅（11-20 一百零九，
  用户插队点名）：四档 60/90/120/144 上机全验证（kwin 全暴露+真掉电重建 dsi_err 零
  新增；0x91 座档四档全等 60Hz 族+bit7 = 座档不跟命令档[H2 扩展]，多档现阶段 =
  DPU pacing 面切换，真玻璃率待眼判/仪器判）；中途引爆 boot 服务面事故 = r66 无限
  重试 drop-in × oneshot 硬依赖 = multi-user 永久 waiting 全服务面瘫（触控失效/
  sensor 刷屏/audio failed/devshell 死，boot-3/4 两度复现；**相机轮与多档内核改动
  因果清白**——boot-1 r100 无 r66 零事故）→ 用户点名照官方做 = FP5/FP6 depends
  实测零 uim-selection → **r67 摘 uim-selection 两件** + r64 影子层清算（/etc 手工
  unit + /usr/local/bin 遮蔽全清）+ sensorspd 双实例冲突 mask（正主 = udev 触发的
  meizu-sensorspd 完整配方）→ 终验全绿（boot 完整/failed 0/触控/电池 100%/传感器
  accel=true/audio/四档/广电 slot1 registered + 数据面 PASS）。坑册五连 = ①oneshot+
  无限 StartLimit+硬依赖 = boot 死锁 ②/etc 与 /usr/local/bin = 包化影子层，收编必清
  ③`.requires/` 链接不吃 drop-in 空赋值重置 ④打包前查旧手工件在跑（单例资源）
  ⑤qmicli 单横线吃 stderr = devsh 假空输出。候补小件 = ~~解封尾段×rmtfs 时序竞态~~ ✅ r69 官方化结构性消灭 + temp.json 刷屏
  改判挂候补[hexagonrpcd 语义取证；tmpfiles 形态保留未根治] + reboot 挂死干净态观察。
  详录 = experiment-log（一百零九）。**▶ r69/r70 官方化轮 + 数据面取证轮 ✅（11-20
  一百一十，本轮收官）**：r69 = 摘 PAS/MSS blacklist + meizu-pas 退役 + keeper 解封段撤
  + dataup ExecStartPre 移入本体 + tmpfiles 三件（TFTP 根/retire-pas/tempjson）+
  touch-load +98c000（hub_3 自动踢）→ **boot 时序全绿**（内核三件自起/rmtfs 稳/multi-user
  4.3s/graphical ~27s/failed 0/ordering cycle 0）；**数据面撞 IPA init 握手死窗**（modem
  内核期早启 → modem 侧 IPA assert crash + AP 侧 -110 永不重试 → rmnet_ipa0 永不建；
  5 boot 实证；恢复通道全试死[ipa 重载/sysfs stop+crash 注入双拒/DMS]）→ r101 内核 =
  pas 驱动 DT 开关 qcom,autostart-off（fork 12dcde3033c8）+ keeper 延时 start ~boot+35s
  （103 时序复刻）仍败 = **挂候补 TD-11 内核域专项**（ipa init retry / modem 固件域取证 /
  105 fatal 炸弹语境考古[109 终验 PASS 高度存疑 = dataup 旧判据 WiFi 共存语境假绿，
  r70 已 -I 硬判诚实化 + bounce 重铺路由 + addr flush]）；短信/注册面/双卡切换不受影响
  （QMI 域全通）。详录 = experiment-log（一百一十）。
  **▶ 广角做实轮 ✅（11-20 晚，一百一十二；用户改序拍板「先解决广角，其他摄有问题才有参照」）**：
  **bytesperline 案子闭环 = 内核零 gap**（机上实报 bpl=5808/sizeimage=20258304 与 HW
  stride 自洽[camss-vfe.c vfe_bpl_align_rdi 8550=16→roundup(5800,16)；vfe_wm_start HW
  stride 寄存器 = bytesperline 本身]；一百一十一·补「V4L2 报 5800」=未实测假设，唯一
  错件 = 解码器 5800 连续解包）→ decode-raw10.py stride 感知修正 + 行尾 8B 定谳（亮场
  取证 = 异族 pad 渣无信息量）+ **cam-shot.sh 参照件**（机上 /root/bin + 仓内 tools/
  camera；动态发现+幂等链路+时间戳输出；boot 后 ~2.5min 可拍）→ 红盒场景实证（盒面
  文字/徽标可辨；默认曝/长曝/开关灯四态全绿，单发 5/5 rc=0 满帧）。**新雷挂候补 = 长
  曝连拍后立即重发 → csiphy 上电 async_synchronize_full_domain D 态死锁**（无超时；
  救砖 = setsid 脱会话 sysrq-b；reboot -f 后台进程会被 devsh 会话关闭连带杀；纪律 =
  单发间隔 ≥10s，cam-shot 注记）。pm8008i 竞态本 boot 复现实锤（cell2 NO-DRIVER，广角
  pm8008j 不受影响）→ r72 随 GD2 轮修。**零源码/包变更，钉子不变 = #105 + v82 +
  mu-r102**。详录 = experiment-log（一百一十二）。
  **▶ 一百一十三→一百一十四（11-21）GD2 轮两连 ✅**：一百一十三 = GD2 真值全闭合
  + 首试 ACK 0x842 命中（cci1-m1 = AON CCI gpio208/209，bin 差分三源互证），残墙
  STREAMON -32 挂起；一百一十四（本会话）= **-32 全案破**（四层：video_check_format
  静默 -EPIPE + 脚本 $Wx$H 展开吃宽 + read-back 锚错实体 + pgAA 小写 g——内核/boot
  链全洗清；cam-shot 双脚本 fmt 自适应化）+ 设备混态定谳（上会话 r104 恢复 = 只换盘
  未重载）+ **GD2 链上机全绿**（mu-r112 + v85 读回双对 + r116 模块；3-0010 ACK +
  csiphy4 ENABLED + failed 0）+ **GD2 残墙定谳 = MIPI 零包**（s_stream 全通插桩零
  触发 + 传感器在流 0x0100=0x0001 + MCLK4/引脚/rails 全绿 + csid0 IRQ delta 仅 +1
  vs 应~1200 SOF → 断层 = 传感器 TX↔csiphy4 lane 层；3P9 同 boot 同下游满帧 = 管线
  无罪；新雷 = s5kgd2sp03 int64 pixel_rate WARN[r117 顺手修]）。
  **▶ 一百一十七（11-21）sensor lib REA 轮 + 双实验判负 + camx 核心取证管线 ✅（本轮）**：
  ①REA 全函数反编译 com.qti.sensor.s5kgd2sp03.so（80 函数）→ **架构改判 = lib 是
  纯曝光计算插件（仅 GetSensorLibraryAPIs/CalculateExposure/FillExposureSettings），
  无寄存器序列——stream-on 真序列真出处 = camx 核心**；rodata 真差异 = 身份串
  "exynos9810"。②bin g3-g9 全解析（slot 不变式手工追值，unresolved 625 全消）：
  g3=startStream/g4=stopStream/**g5/g6=组保持 On/Off 0x0104←1/0**/g7=initSettings
  1264/**g8=testPatternData 走 FIFO 窗协议**/g9=vendorID。③Volla 工作栈全链取证
  （adaptor 三件拉仓）= patch→模式表直写（无组保持！）→AE 组保持→**set_dummy
  gph{VTS}**→stream-on；⚠Volla = **GD2SP 异件近亲**（wake 参数全异不可平移）。
  ④**r119 组保持{VTS} 判负**（rc137 bytes0，MIPI 域读回仍 0）+ **r120 流后补写判负**
  （T+5ms 写落过渡窗被擦[过渡 >5ms 新画像]，T+22s 读回仍 0，驱动零错误）→
  **写法/时序两轴已排除，缺口 = FW 过渡时 FW 内部态的正确性**。⑤**camx 核心取证
  新基建**：super.img lp metadata 手工解析（v10.2 三元组描述符）→ vendor_a EROFS
  （fsck.erofs --extract）→ **camera.qcom.so 26.7MB** 到手（scratch-super-vendor/）；
  capstone 锚点定位 StreamOn 四函数（0x11fe260 12.6KB 292calls/0x12013e0/0x122df70/
  0x1255cf0）+ regSetting 解析器簇 0x168b580-0x169d46c（★坑 = ADRP 立即数两段
  immhi@5-23+immlo@29-30，漏 immlo 全空报；日志宏死串要找 bin 解析活串）；Ghidra
  headless 直跑配方落地（Ghidra 12 = ghidra.Ghidra 启动器 + GhidraClassLoader + 全
  jar classpath + Java postScript；REA 26MB 撞 startup deadline）。**全量分析跑中，
  ROI 反编译落 scratch-super-vendor/dec-camx/roi_*.c**。
  **▶ 一百一十八（11-21）网上资料调研轮 + camx 源码到手 + 排除法六连矩阵 ✅（本轮）**：
  ①**camx 全源码树到手 = 头号收获**（`comprehensive9/vendor_qcom_proprietary`
  GitHub 分支 11se；sparse clone 拉 camx/chi-cdk）+ KMD（marble techpack/camera）
  ——**编排真值源码级钉死：Init+Res 在 CONFIG_DEV 执行，STREAMON/STREAMOFF 包
  KMD 只缓存（i2c_data.streamon_settings），0x0100=1 真写只在 CAM_START_DEV =
  秒级 settle 架构**；apply_settings(STREAMON) = 纯缓存寄存器写零魔法；组保持
  0x0104 只在曝光路径不在 stream-on 编排（r119 无对应物实证）；**117 ROI 反编译
  接力作废（源码即答案键；roi_11fe260 = IPE upscaler 假阳性锚实锤）**。②JD1 同族
  驱动源 s5kjd1sp_xr_sensor.cpp（277 行）= 纯曝光插件同构 → 117 架构改判源码级
  独立确认；GD2 bin res 组零 delayUs（全 bin 仅 init 5ms/11ms 两条）。③**r121
  settle-gap 判负**（settle 1s → FW 过渡后**异步**重建 MIPI 域[0x0116←0x1002 =
  0x0110 值错位一格指纹]；8s → 寄存器 T+55s 完好驻留；**两态均零包** = 时序非
  TX 门）。④**r122 patch 挪位事故 void**（patch 尾页 0x2001 → stream-on 0x0100
  错 bank；★坑册 = res 组自洽页选但组间共享页态，插序列必审尾页）→ r125 正位
  复归。⑤**排除法六连矩阵全负**（patch 全量/once/无 × 触发器发/跳 × no_boot g7
  全跳 = TX 恒零；g7 内容非 TX 门；轨电压流中实测全绿；「csid0=911 洪流」=
  **3P9 计数器跨相机累计误读**[csid0 行跨相机共享，GD2 从未发过任何包]）。
  ⑥**新基建（r123-r125）**：dbg_state（enable 内 regmap 快照 +5ms/+2s；⚠CCI
  地址必过 CCI_REG16 宏 = 位宽编码，裸地址 = -EINVAL）+ patch_limit（patch 截写
  二分）+ no_boot/no_patch/patch_once/settle_ms 模块参数族（全 0644）。
  **▶ 一百二十（11-22）WiFi 无网络修复轮 ✅ + TD-11 全案收官 ✅（shum-elli 下游
  仓分析轮 + 用户插卡终验）**：彼仓三段式修复分析毕 = modem_pr 158 件
  （我方 fw r4 同源）/ **IPA IMEM 恒等映射 = TD-11 真凶**（stock
  qcom,additional-mapping <0x146a8000 0x146a8000 0x2000> 主线化）/ MM 官方拨号
  编排。**WiFi 黑洞双凶定谳修复**：①死路由残留（数据面静默死[TX 108/RX 0 无
  fatal]后 metric 50 残留压过 wlan0 600；删路由 = WiFi 当场复活）→ r73/r74 =
  WiFi 优先路由[蜂窝 metric 700] + keeper 数据面看门（两连败撤路实证工作）+
  dial 硬败不走缓存；②TD-11 = r131 DTS 恒等映射（fork cf99fc7ad737）三腿上机
  readback 双对 ✓ + **reserved_regions 实锤 direct**。**终验（插卡后）= 数据面
  真通长稳**：手工 DPM+WDS 链判负退役（dial 通 bounce 一发 RX 秒死两 boot 复现
  = 手工 DPM modem 侧通道语义缺）；**MM 拨号形态 = 正解**（MM failed sim-missing
  死锁 → restart MM 重扫 → simple-connect apn=cbnet → MM 自建
  qmapmux0.0@rmnet_ipa0 → 手工铺 bearer IP/route → **-I qmapmux0.0 硬判 12/12
  全 PASS + RX 单调涨**）；**一百零五「MM dial = IPA fatal」判词作废**（缺映射
  时代测的）。支线 = ipa.ko netdev 仅 modem starting 事件注册（重载无法重建）。
  紧后 = r75 自动化固化（NM×qmapmux 不认 + mm-dial oneshot + keeper 看门适配）。
  坑册五连 = ip route scope link 夹中间 grep 勿相邻 / dataup PASS ≠ 长活 /
  Type=simple exit 1 也显示 Deactivated successfully / dd 读 by-name 空 sha =
  路径不存在 / **无 -I ping 假绿再实证（qmapmux_rx=0 假 PASS 3 分钟自查纠正）**。
  详录 = experiment-log（一百二十 + 终验节）。
  **▶ 下会话排面（用户 11-22 拍板「安排下个会话做这四个」= 新 Release 前置四件，
  做完发新 Release）**：
  **A. r75 数据面自动化固化**（blocker 级）= cell-dataup 退役 + mm-dial oneshot
  （MM restart 重扫 + `simple-connect apn=cbnet` + qmapmux0.0 bearer IP/route
  metric 700 铺设；配方 = 一百二十终验全通链）+ keeper 看门适配 qmapmux 路由
  形态（grep rmnet0 → qmapmux0.0）+ dial 硬败不走缓存保留；NM×qmapmux 集成
  （NM 不认 qmapmux0.0）挂候补不挡发布。
  **B. plasma-camera ANALOGUE_GAIN 补件**（快赢）= 驱动补 libcamera 强制 ctrl
  （ANALOGUE_GAIN 缺失[HBLANK 只读] = simple pipeline 建不了 CameraSensor，
  11-21 探针真因在案）→ 3P9 进 GUI。
  **C. 完整回归一轮**（设备日级清单）= 音频/触控/睡眠 rtcwake/GPU 钳零件/传感器/
  多档刷新率/S2 实验系 DTS 残留确认（r131 累 40 轮次，本轮只验了蜂窝/WiFi/boot）。
  **D. fw r4 随新 Release 出**（发布面 tarball 仍 r3；r4 = modem_pr 158 件已上机
  全绿未发布）→ 四件齐 = 发布新 Release（Release 件制照 PIPELINE；CI rootfs =
  r131 apk 底；大件上传验收 = gzip -t + 字节数对拍在册律）。
  发布判据 = A-D 全绿后新 Release 上线（叙事 = 花屏根治 + 蜂窝数据全自动 + 相机
  GUI 可用）。
  **待办池（点名制，排面外照旧挂候补）**：ⓐ双击亮屏（**11-27 用户点名保留入池 + 改判
  非快赢**——原厂情报 0xcc→键 624 只对 Android 天然成立；实机实测音量+ 不解灭屏，且
  音量键被 kglobalaccel 独占抓取 = 该测试对未知键 624 不构成定论；**架构定谳（用户拍板
  「不管桌面环境是什么都应该支持」）= 做在 DE 无关层**：内核半边[触驱灭屏前配固件手势
  模式+IRQ wake+手势→键] + 睡眠态系统 wake 白得屏幕亮 + 醒着灭屏态 = 会话无关小守护
  进程[监听手势键→注入零位移 uinput 活动事件，kwin/wlroots/Hyprland 通吃，非 Plasma
  专用胶水]；复燃入口 = uinput 交叉编译注入测试先行）ⓑ抬起亮屏
  （SSC 私有传感器 com.meizu.sensor.raise type 65539，查 ADSP 传感器表即知有无；同ⓐ
  受 Plasma 半边同款问题约束）ⓒhaptics RAM 映射升级（Flyme 11/13/3 + 增益 0x39/0x80 平移 aw8697.c）；④S2 环闪阳极谜
  （复燃 = stock 画像 REA/硬件探针，dbg_dump 在机默认关）⑤GD2（复燃 = 文档级
  资料/新参照）⑥S3 5E9（配方 = S2 同款，价值有限不急）。
  备件照旧 = stock AON 考古 → 扫频网格 → 顺手件包。
  广角（3P9）参照件 rc=0 满帧恒真。
  ~~数据面 IPA 内核域专项（TD-11）~~ ✅ 全案收官（11-22 一百二十：r131 IMEM
  映射 + MM 拨号形态真通；ipa init retry 修法序作废——真凶 = DT 缺映射非时序）。
  候选池余项照旧 = 干净机首航（Phase-2 判据）/
  S2IDLE 深睡线复燃（之后，需设备窗+用户在场）/ NFC/通话音频（点名制）/
  tempjson hexagonrpcd 语义取证（小件）；蜂窝残面 = 短信 ✅ 移动卡已破（广电卡 =
  运营商 IMS 未授权面）+ 数据面 ✅ 通（自动化 = 排面 A），余全挂起（复燃条件在册）。
  **设备当前态 = 移动卡 slot 1 在网 + 数据面 = **NM 标准形态**（11-25 晚 P3
  收官：boot→cell-mm-rescue→MM→NM autoconnect 全自动，mm-dial 已退役在册，
  profile autoconnect=true；WiFi 掉线 failover 原生可用）；WiFi 日用正常；keeper
  active-slot = 1；在机 = **#133 + v91 + mu-r131 + r83 + hexagonrpcd r8**
  + plasma rootfs；failed = 0[modem-gnss 本 boot 未触发]）。
  **SFOS 线 = 独立新仓 `~/work/sfos-meizu-m2381`（11-19 立骨架未开发，遇话题指路
  不接手；复燃入口 = 其 docs/SPIKE-PLAN.md 阶段 0[ofono×QRTR 零刷写探针]）**。
  **蜂窝用户面探针轮 ✅（同日深夜，四域一窗快扫；战报 = experiment-log 一百零六·乙）**：
  短信 transport **协议层健康**（get-protocol 0,0；104 的 not-ready 未复现）→
  **当晚升级为破墙轮（见②，一百零六·丙）**；**IMS 真卡复现拒 38 = 运营商订阅面钉死**（通话线前置卡运营商，
  非本机可修）；**GNSS = LOC 引擎启动固件侧 GeneralError 46**（服务活/读配全通，
  ~~疑 PDS/GNSS mcfg 缺料~~ → **11-20 一百零七改判：闸门 = modem 内部 PDS 态
  （EFS NV/记录域），fw 补料路判负**[发料面 = stock 全量清白 + 引擎启动零讨料；
  rf_static_521 404 = stock 本无此文件非漏发]；gnss-share 0.8.2 已装机 active，
  正路 = mm 后端，复燃 = stock 对照/Flyme 窗取证/upstream PDS 语义，大后期档）；
  **ofono 2.19 零枚举本机 modem**（SFOS 三门之 2 首查负，
  需适配工程）。现场恢复全绿。
  （✅离线轮 11-06 收官：B1 `script/devselfcheck.sh` + B3 FLASHING 第一小时清单落地；
  B2 容器首航用户砍单——setup.sh 两缺口已修[9472de7]；主件 B 未跑[设备在 iOS 链]；
  卡归档 docs/archive/）
- **开工惯例**：设备现态探测先行（devsh 连通 / uname / wowlan / cpuidle / failed
  计数）。**stable 检查已取消（2026-11-21 用户拍板：不用每轮查，需要 rebase 用户
  点名）**；历史底档 = 7.3.2~7.3.5 已出但 printk/ath12k/msm 三域零交集不跟进。
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
   vmlinuz 假件）；
   ⑤ 管道下跑 build 脚本 = systemd-run 前台等待失效且输出被吞（11-19 实测：
   `| tail` 只见守卫行即返回，单元在宿主照常跑完）——判完成必须轮询单元状态
   或产物落盘，勿拿管道返回当信号。
2. **pipefail 下 `grep -q` 会吃 SIGPIPE 假阴性**（大列表早退 rc141）——verify 类
   检查用 `grep … >/dev/null` 读全量。
3. **版本单一出处 = 本仓 config.sh + MANIFEST.md**；pmos_linux AGENTS 只留一句话
   级现态——两头详记必漂移；历史战报只进归档/experiment-log，主文档不追记战报。
4. 产物命名：`mu-r<PKGREL>-<sha8前8>.img` / `esp-recovery-vNN.img`；**#N=pkgrel+1**
   定律（上机 `uname -v` 直接对）。
5. **红线继承**（全在 FLASHING.md §8）：写分区必须 `--i-am-present`；只碰
   boot_b/recovery_a；xbl/abl/tz/modem/dtbo_b/super/modemst/persist 永不碰；
   刷写时长不算证据，只看 dd 读回；**fastboot 单通道**（两侧刷写必须互斥）。
   **⚠11-20 用户拍板豁免：DTS 变更类刷写（boot_b Mu + ESP 腿）= 授权无人值守
   自刷**（相机轮起适用；apk 腿本来可 solo；红线分区照旧永不碰；无人值守轮
   按灭屏纪律执行）。
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
| **下一轮执行卡（蜂窝用户面轮：短信/5G/双卡/VoLTE 信令）** | docs/cellular-userplane-card-20261119.md |
| 上一轮执行卡（plasma 出件 + 蜂窝续攻 ✅ 已归档 docs/archive/） | docs/archive/plasma-mobile-cellular-card-20261119.md |
| 蜂窝复燃卡（✅ 收官 11-19，registered 里程碑） | docs/archive/cellular-reactivation-card-20261107.md |
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
