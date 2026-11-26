# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-11-27 **相机残面轮 ✅（一百二十八：④图标打不开破案 = dma_heap 权限 + ①旋转全案 270 定谳 + touch 假 failed 消音，双刷写两 reboot）**：**④真凶 = `/dev/dma_heap/*` 0600 root:root 且 systemd 262 上游零规则** → 用户会话 libcamera「Could not open any dma-buf provider」→ SoftwareIsp 禁 → plasma-camera 转圈自杀（127 轮「预览出画」全是 devsh root 拉起 = 权限失败被系统性掩盖）；修 = device **r87** `73-meizu20-dma-heap.rules`（video 0660，镜像 video4linux 惯例）→ 用户侧预览出画 30 帧实证；**①旋转 = 驱动暴露 V4L2_CID_CAMERA_ORIENTATION/_SENSOR_ROTATION 只读控制**（libcamera 0.8.0 CameraSensorLegacy 只读控制 default、无 fwnode 回退，fork `04d52720bf7f`）+ DT orientation=<1>/rotation=<270>（90 眼判 = 侧转修好但上下颠倒 → 270 定谳，fork `df96b0421841`）→ plasma-camera 应用实证「Camera offset orientation: 270」；**r137 留档**（rotation=90 一段轮）；**②「CFA 一行修」作废 = 命名撞车误判**（4 字符 GBRG ≡ V4L2 SGBRG10，驱动标签本来就对；复古感主嫌 = 无调参 yaml AE/AWB，待眼判复核）；**touch retrigger 地址不可知化**（cci 子总线编号跨 boot 漂移实证 0-002d/2-002d 同日两 boot；deferred 自愈 = 主机制 + 段尾 exit 0）→ failed=0 全清；**#139 + v96 + mu-r138-3f909a93 在机**，读回双对 ✓。相机 GUI 残面 = 色彩 yaml 候补 + 拍照落盘复测；详录 = experiment-log 一百二十八 → ）

## 工作态（2026-11-27 **RPMH 收兵轮 + GUI 相机缓冲双修 ✅（相机线③ + 用户所见报错破案，同日多构建）**：内核 **r133**（fork `79a4a228c09d` = rpmh 超时收兵——`rpmh_write_batch`/`rpmh_write`/`rpmh_read` 超时后主动回收卡死 TCS（镜像 tx_done 序列 + req[] 先置 NULL 防迟 IRQ UAF），把「一次 RPM 不应答 → 全平台 icc 饥荒[UFS 冻结/sysrq-b 救砖]」降级为「一次 10s 停顿 + 相机打开报错」；死锁链源码级钉死 = bcm-voter AMC 提交超时留 TCS 占用 + `rpmh_rsc_send_data` 无限等 + `qcom_icc_bcm_voter_commit` 持 icc_lock；案发取证 = 11-22 boot -15 journal 尾段尽、栈面全靠源码重建）→ #134 上机 + **r136**（`CONFIG_CMA_SIZE_MBYTES` 回滚 32：512 尝试轮[r134/v93 上机 #135]实锤本平台早期分配窗放不下 = `cma: Failed to reserve 512 MiB`，32 = 恰卡 0xf0800000 缝隙的天然上限）+ **libcamera 99990.8.0-r2**（pmaports temp/libcamera 刷新上游 0.8.0 + 0003 补丁 = DmaBufAllocator 堆序 system 挪队首——原序首开即独占零回退，reserved=CMA 32MB 池 < SoftwareIsp 全分辨率输出缓冲 61.7MB = plasma-camera「configuration not valid」真凶；系统堆实测 61.7MB 健康，IOMMU 平台无需物理连续）+ ESP **v94**（裸 `6c1e000e`/gz `0700ce47`）上机（DTS 不变 ⇒ mu-r131 续用）→ GUI 复测战果 = experiment-log 一百二十七 → ）

## 工作态（2026-11-25 **电池遥修 + 蜂窝 UI/上游回归轮 ✅ + P3 蜂窝标准化加演 ✅（同日晚，无人值守→用户在场）**：内核 r132（fork `24df27f74fc4` SM8550 charge_count mAh→µAh ×1000 变体门控；**DTS 不变 ⇒ Mu 不重编**）+ ESP **v91**（裸 `b80fb8b2`/gz `db0ac0c8`，读回 ✓）双腿上机 **#133 实测**：`charge_counter=3,994,000 µAh`/`energy_now=17.58Wh` 修复实证 + upower 历史复活；充电阈值写读仍 0 = **firmware 域独立案**（非本连锁，TD-13 残面改判候补）。设备包 **r78→r81**：r78 = qrtr0 摘出 NM unmanaged（plasma-nm CellularModem 需 NM ModemDevice）+ cbnet/cmnet profile 入包 ⇒ UI 开关活/APN 可配；**P2 上游回归全通**（NM 拨号全链：MM bearer→qmapmux0.0 IP→表 1430 路由→ping/HTTP 实弹，"NM 不认 qmapmux"旧判词翻案 = r75 conf 才是 blocker）；**★单 call 域定谳**：mm-dial 占线时 NM 激活 = `call-already-present` 且带走旧 bearer（双死）⇒ 互斥；r79 = mm-dial BP 抓取修；**P3（用户拍板「跟着上游来」）= r80+r81：数据面交还 NM 标准形态**——profile autoconnect=true + mm-dial boot 退役[preset flip + retire-mmdial tmpfiles] + cell-switch 尾改 NM 跟卡 + **cell-mm-rescue oneshot**（补 mm-dial 内嵌 boot 救援的隐性依赖：MM×qcom-soc boot 竞速常态落 failed/power-off）；实验定谳：WiFi 掉线 NM 路由晋升主表 = failover 原生可用，DNS 断粮走 systemd 上游 FallbackDNS 兜底实证；reboot 全验：rescue 自启→NM 自连→ping -I 3/3 @39ms。移动卡 slot1 在网纯上游形态交回。叙事 = 执行卡 battery-cellular-ui-card-20261125；Release r131（Latest）不变 → ）

## 工作态（2026-11-24 **Release r131 已上线 Latest** = 8 件制：双 UI rootfs（plasma-mobile `b18a6be1` / phosh `fcd6c662`）+ mu `f51b3b09` + ESP v90 gz `037c8dfb`（CI 同号异字节；在机本地件裸 `6efc31e0`）+ fw r4 tarball `97d7b489` + linux r131 apk `7156e527` + upgrade-r131.zip + SHA256SUMS；CI run 45225314330。云构建三雷已清：systemd 262.2-r0 usrmerge 断包（上游 r2 自愈）/ Mu NuGet 对 runner 稳定失败（NuGet 缓存种子草稿 `mu-nuget-seed` + workflow `nuget_seed_tag`）/ Mu 分支被 UniXNU 接线污染（远端存档 `unixnu-wiring-20261030`，本地树 force 回主分支）。种子草稿 `fw-r4-seed`/`mu-nuget-seed` 保留供后续发布轮复用。叙事 = experiment-log 一百二十一 + 补记；以下为四件轮原始记录 → ）

| 件 | 版本 | sha8 | 刷写目标 |
|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**138**（11-27 相机残面轮·二段：DT rotation 270 定谳[df96b0421841]；r137 = 一段留档[s5k3p9sx orientation/rotation 控制 04d52720bf7f]；r136 = CMA 回滚轮留档；r133 = RPMH 收兵轮留档[fork `79a4a228c09d`]；**r117 = 空 bump 死包勿用**） | 在机 apk（模块文件 live） | 机上 apk add |
| ESP | **v96**（r138 内核腿，11-27；裸 `20be6b58` / gz 14402949B；v95 = r137 件留档；v94 = r136 件留档） | 20be6b58（裸） | recovery_a |
| Mu 镜像 | **mu-r138-3f909a93**（在机，FdtBlob 与 r138 apk 同源 dbbbcfc6；**读回 ✓ 限长截取对拍[boot_b 分区 96MB ≫ 镜像 1.1MB，整分区读回必掺尾垃圾]**） | 3f909a93 | boot_b |
| 设备包 / 固件包 | **r87**（11-27 相机用户会话轮：`73-meizu20-dma-heap.rules` = dma_heap video 0660[上游 systemd 262 无规则 = 用户会话 libcamera 全灭真凶④破案] + meizu-touch-load.sh retrigger 地址不可知化[glob 全 *-002d + exit 0；cci 子总线编号跨 boot 漂移实证]；r86 = TD-10 去债留档；r85 = 启动序修复留档；r83 = carrier DNS 上链留档）/ **r4**（11-19，已随 r131 发布） | 在机 apk live | 机上 apk add |
| libcamera | **99990.8.0-r2**（11-27：pmaports temp/libcamera 刷新上游 0.8.0 + 0003 system-heap-first 补丁 = GUI 相机缓冲真凶修复） | 在机 apk live | 机上 apk add |
| rootfs | Release **r131 双 UI**（2026-11-24 上线 = plasma-mobile `b18a6be1` / phosh `fcd6c662`；11-22 用户拍板「两个都传，以后默认 plasma」；r91 = 上一代 phosh 单 UI） | b18a6be1 / fcd6c662 | userdata |
| 上机期望 | `uname -v` → **#139**（r138）+ 模块 r138 + CMA 池 32MB + `apk list --installed \| grep libcamera` = 99990.8.0-r2 + `/dev/dma_heap/*` = root:video 0660 + `systemctl --failed` = 0 + IPA reserved_regions 含 `146a8000 direct` | — | — |

**历史实验件判词（叙事细节 = git log + PANEL-CORRUPTION §6，本表不追记）**：
- **r88/v69**（`msm.zero_clkout_timing` 旋钮，10-19 上机）→ **0xC4 洗清**（排雷表 #13 终审）+ bloff 结构性免疫实锤（PANEL §5④/§6 条 1）+ upgrade.sh UNTRUSTED 假绿坑根治。
- **r90/v70**（`msm.msm_dsc_stock_content` 旋钮，10-21 上机 A/B）→ **内容值轴判负**（控臂 6/6 花 / 治疗臂 2/2 花，PANEL §6 条 4）→ S5 RE 升主线。

- **r92/v72**（D4 三件拼车轮，10-29 构建 → **11-19 上机 A/B 判负**：D4-2/3/4 + knob stock 可达态真睡×5 用户眼判 **5/5 全花**——D4-2 RD_PTR 门控 / D4-3 PPS 后置 / D4-4 LP sanity 全部零疗效，标准命令域主机可达维度排除面闭合[含 D4 内核件]，病根收缩 = 非命令维度[重载语境] → D4-1 升主线，PANEL §6 条 9）。
- **r93/v73**（D4-1 无背光修复版，11-19 上机）→ 冷启/RTC 唤醒通路实证但**真睡醒后屏黑**（DDIC 断电亮度锁存归零无人重写）→ 背光恢复补丁升 r94，本版退役。
- **r94/v74**（D4-1 完整版，11-19 上机）→ **判过 + 科学解验收属实**（三形态×两时长×灭屏面全净）；pmaports 拼车 KPROBES/KPROBE_EVENTS/FTRACE/PM_QOS + 摘 KVM/F2FS 死件（config 陈旧重复行坑两连记档）。
- **r95/v75**（bloff 摘除轮，11-19 用户拍板）→ 日用灭屏改走真睡路径（`bloff_default=false`），新默认态 bloff=0+pps_late=1 上机抽查全净；**TD-03 已还**。

**r92/v72 D4 三件拼车轮（2026-10-29 设备日预备轮；验证件不上机不发布照 r88/v69 先例）**：
fork `c7abcd61`（D4-2 = m2582 fb4e8c5d 移植：RDPTR 注销门控 PANEL_DEAD +
frame-done 84ms 平值[dpu_encoder.c + dpu_encoder_phys_cmd.c]）+ `bfc79f41`
（D4-3 = wake_pps_late default=true[P2=stock 语义，缝 5] + D4-4 = 冷启 sanity
0x0A 改 LP 读[stock ESD 语义]）+ pmaports pkgrel 92 → apk **r92**（vmlinuz
`c1583825`）+ ESP **v72**（裸 `37e3f9c7` / gz `18fd54a0`；v72↔r92 手工对拍
c1583825 同源）。verify 全绿（[1] dtb 同源 c061acd9 / [4] c1583825 / 期望
**#93**）。上机排程 = **rootcure-window-card-20261101.md**（★花屏腿加门：
等 21 Note 仓开源对拍再修，11-05 用户拍板；构建坑 = build-esp 须等
build-kernel 单元真完，详见 config.sh v72 行）。

**r91/v71 7.3 stable rebase 正式轮（2026-10-21 宿主段收官，零设备；待设备日双腿上机）**：
fork `meizu20-t4b` 重放到 v7.3 stable（tag `091b0638` → commit `c03c1a14507d`），
**99 提交零冲突**（演练 98 + 首枪旋钮 1；合流点 a90ee4305c4a = rc6 基线；sanity 四件
全绿[panic 吸收 0 / ath12k 挂点 186/205/213/250 原行号 / 双旋钮在位 / diff 面 106 文件
逐文件全等]）；锚 = `archive/t4b-rc6-final` + `archive/pre-73-meizu20-t4b`（同指旧 tip
`26ab9bf3e442`）。两实质复核 = **printk 上游未修**（rc7→stable 仅 5f339c46f153
nbcon kthread 早启件，非挂起路径 ⇒ `no_console_suspend` 留）+ **ath12k 0012 三件
carry 全留**（Shenghan freq-range 修复不在 v7.3）。pmaports `972412f` → apk **r91**
（sha8 `df13faa6`；内核 release = **7.3.0**，模块目录 /usr/lib/modules/7.3.0/，Mu 链
无 initrd 无牵连）+ ESP **v71**（裸 `0a102220` / gz `6fe7811a`）。verify [1]-[3][5]
绿；[4] 红 = 发布面钉子口径（v68 vs 工作态 v71），手工对拍 v71↔r91 vmlinuz
`4aad92b3` 逐字节同源非真红。构建 26min（06:00 DONE）。**10-21 深夜上机实锤**：
upgrade.sh 显式双腿全绿（**#92** + 读回 0a102220 对 ✓）；回归清单全绿 = 真睡
rtcwake resume 0.228-0.232s + 电源键秒醒（眼判）+ 音频三服务 active + 出声（眼判）+
GPU 钳零件 busy_delta_us 真空闲 5 连读恒 0 + 传感器 proxy 在会话总线 + QS 开关在
（眼判）+ WiFi 5G 扫描见 LZ-5G（实连无凭据记档）+ failed=0；**printk 流程卡第一测
= Y 态 3/3 全活**（按卡判据 = 上游已修候选；摘 CONFIG_CMDLINE 件留用户拍板另开轮，
在册注：rc6 亦 3/3 未死 = 回归时序依赖，保险件零成本建议留）；waydroid = 现底无
预装跳过记档；收尾 console_suspend 已复 N + bloff_default=Y 日用态确认。


**r81 回归回执**（10-11 晚，steamos 线）：EFI↔apk vmlinuz 5cb94ebd 双侧互证；zstd sqsh 直挂
（gzip 重压 workaround 撤）；RTC 用户态三件下线后时钟正确 + timedatectl 首次读出 RTC；
彼侧 qbootctl v0.2.2 设备端现编落地（fastboot 停车根除，SLOT b Successful=1 重启重标 ✓）。
※勘误（10-11 深夜定谳）：v62 裸镜像 8 位前缀 = **b41b8888（原手记无误，全量
b41b88889cadf6060e35…）**——「b41b8889cadf」系连排四个 8 丢一位的转抄病，当轮勘误
本身勘错，全谱手记已改回；build-esp.sh 出货 gz 反推（单一真值源）做法照旧。

**r84 收官回执**（10-12，GPU/IFPC 轮 =（八十六）判过）：EFI↔apk vmlinuz 01ddbb77 双侧互证 +
本机复核全等；真空闲钳零 PASS（busy_delta 恒 0）+ 静态 UI 220 单档 94.8% + GPU 温
39-41°C + 七条回归全绿；payload[0]=SUCCESS 但 ifpc 恒零 =「ack 不执行」[FW 行为态]——
内核线收官，全量 = pmos_linux `docs/meizu20/gpu-idle-devfreq-round-20261011.md` §13。

**回退配对**：内核 r86 + ESP v67（裸 2ad63003 / gz 444dec3f；CI 同号件 gz dc8bed66 异字节同版本）+ device r60（= #87 在机验证过的一代，10-13/10-14 两轮实机绿）；再退 = r84 + v65（裸 463efc45 / gz 00d2d5f9）+ device r60（= Release r84 在役件；r87 发布件上线并验收前勿销）。

## 发布面现役产物（2026-10-21 @ r91；= Release r91 已发布 Latest；CI run 39511226412；发布真值 = CI SHA256SUMS）

| 件 | 版本 | 发布件 sha8 | 刷写目标 |
|---|---|---|---|
| 内核 apk | 7.3.0_rc6-r**91**（**7.3 stable 重放轮**：99 提交零冲突；内核 release=**7.3.0**） | d2f0c51b（CI）/ df13faa6（本地同轮件，异字节） | 机上 apk add |
| 设备包 apk | 1-r**63**（depends +iio-sensor-proxy 闭合；waydroid 五件/flatpak 商店 r61-r62 起全继承） | 2013b691（本地构建补传件，在机实装 RC=0） | 机上 apk add |
| 固件 tarball | r3（零改动，与 r72 原件同串） | 29c1ee88 | — |
| Mu 镜像 | **mu-r91-350386e0**（DTS = FdtBlob c061acd9 同源，CI 构建） | 350386e0 | boot_b |
| ESP | **v71**（r91 内核腿；同号异字节：CI gz `f08139e3`[发布件] / 本地 gz `6fe7811a`[裸 0a102220，**#92 在机件**]；CI 内 verify[4] 配对 ✓） | f08139e3（CI 发布件） | recovery_a |
| rootfs 镜像 | r91 同轮（--single-partition；内含 r91 + device r63 + fw r3 + **iio fork r3** + waydroid 五件 + flatpak 商店；phosh） | 29490177（875.8MB，`meizu-meizu20-r91-phosh.img.gz`） | userdata |
| 升级包 | upgrade-r91.zip = 内核 apk + ESP v71 + UPGRADE.md | a05d57f1 | 升级腿 |

**Release r91 = <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r91>**（2026-10-21
上线 Latest；8 件 = 直刷三件 + 固件 tarball + apk 两件[内核 CI/设备本地补传] + upgrade zip + SHA256SUMS；
**验收口径 = 用户令直发[全量下载回读豁免]**：CI 内建上传字节数逐件对拍 ✓ + 生成时 gzip -t + CI verify 全绿
[[1] DTB≡c061acd9 / [4] ESP↔apk 配对 / [5] 期望 #92] + CI 日志证据[iio fork 预编 01:10 → device r63
01:13[depends 闭合取 fork]→ rootfs r91-phosh 01:21 顺序链]；rootfs debugfs 内容级未回读[豁免]）。
**回退配对**：r87 + v68 + device r62（#88 实机绿，10-14 两轮）；再退 r84 + v65（未删）。

期望 uname：`7.3.0_rc6-r91` → **#92**（10-21 深夜本地件双腿升级实测 ✓，读回 0a102220 对；CI 件同源异字节同 #92）。

## 回滚锚（已删，2026-10-13）

> 2026-10-11 起锚三件不随 Release 发布；**2026-10-13 用户拍板：T 时代旧版 bug 太多，
> 不再回滚——本地锚三件（t-b2 d4928661 / esp-v4d 3b106f07 / mu-r57 4640ebb5）与
> `rollback.sh`、config.sh ANCHOR_* 一并删除**。
> 救砖路径唯一 = 重刷现役三件（flash-batch.sh + r84 rootfs，见 FLASHING §6 阶梯）。
> 当前时代的次级回退对（手动刷，文件在仓：`artifacts/mu-r64-686a4c0f.img` +
> `artifacts/esp-recovery-v46.img.gz`（裸 0d4796ed）+ device r51）。

## 已知非回归失败（首 boot 看到**不用慌**；=（八十七）phosh r84 实测清单）

| 现象 | 形态 | 定性 |
|---|---|---|
| **首 boot 三 unit failed**（meizu-dsp-mount / qbootctl / qbootctl-meizu） | `systemctl --failed` 3 件：「no dsp partition found」/「Failed to open bootdev dir」 | **全新刷写 userdata 后首 boot 独有竞态**：units 跑早于块设备枚举；boot-2 起全自愈 failed=0 + qbootctl 正常重标（10-14 CI rootfs 首刷实测）。传感器首 boot 缺 /mnt/dsp 一次，`systemctl start meizu-dsp-mount` 即补。OSK Stevia 同型（×6 败后 Started 收敛，锁屏可用）。候补修 = 三 unit 排序加固 |
| journal 早期时间戳 | 标着旧日期（如 Oct 06） | **rtc1 旧值未同步**：NTP 前内核时钟 = RTC 存值，早期日志全错标；勿当旧 boot 日志读。WiFi+NTP 后恢复；写回闭环待复验 |
| DPU「no encoder found for crtc 0」 | *ERROR* ×2-3 条，仅 boot 早期 | 窗口性噪音：面板 cold-enable restart 自愈窗口撞上合成器 vblank 请求（dpu_crtc.c:192/282）；运行期零刷，勿追 |
| a740_sqe.fw | failed with error -2 | 假警报（27s 后重试成功；silime 时代已定性） |
| pmic-spmi 0-0c/0-0d | probe failed -5 | 在册已知（多轮 boot 一致，无功能影响） |
| 应用商店「系统升级」提示 | 显示快照版本串如 v20260805-… | UI 噪音：滚动发行版无 distro upgrade，商店列不出（journal: failed to get upgrades），快照标签 vs edge 的版本串观感差；apk 实测升级/降级候选均 0。**忽略之，系统升级只走 UPGRADE.md** |

（历史行留档：rmtfs activating / uim-selection start-limit-hit = 蜂窝用户态在役时代现象，
现役 rootfs 蜂窝摘除态 + 未装四件套时不见；postmarketos-zram-swap failed 仅 r<60 内核，r60 起修复。）

## 通道速查

- root devshell：`tools/devsh.py`（NCM + nc :23）｜ ssh：`user@172.16.42.1` / 1234 / root 走 `sudo`（密码 1234，本机无 doas）
- 软进 fastboot：`systemctl reboot --reboot-argument=bootloader`（18d1:d00d）
- 宿主长构建：systemd-run（脚本已内置；K30 已退役，work dir 独占，防本机并发即可）

## 历史轮次

r61 首航（10-06）→ r63/r64 录音轮 → r65 pm8008 → r66 fsa4480 摘除（10-07，首个 Release）→
r72 首传半截流撤回（10-08，教训入流程）→ r80 async flip + uhid（10-11，Release 上线）→ r84 phosh 首个 phosh 发布面 + r66 删除（10-12，专注 phosh 拍板）→
r85 waydroid netd 策略路由 v4 半层（10-13，config-only）→ r86 v6 补全（IPV6_MULTIPLE_TABLES/SUBTREES，
上机四连通）→ **r87 waydroid 预装 + phosh 商店 flatpak + 摘 discover（10-14，CI 云构建 #22 首发轮，
Release 上线 Latest；未发布代次 r85/r86 随本记录在案）**；
逐轮产物/sha 明细见 git log。ESP 自 v47 起仓内 gz 化（v43–v45 裸镜像已退役出史）。
