# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-11-19 根治轮·设备窗更钉：**r95/v75 双腿上机 #96 = 花屏科学解达成且验收属实**——D4-1 冷启等价化判过 + 三形态×两时长×灭屏面全净验收 + **bloff 工程解摘除**（TD-03 已还，日用灭屏 = 真睡路径，新默认态抽查全净）；在机 = **#96 + v75（读回 09759c87）** + mu-r91 + plasma-mobile 6.8.3-r0 rootfs（11-19 用户自刷，蜂窝资产刷前已回收）；回归全绿；r92 判负退役；**发布面 = Release r91（Latest）不变，r95 是否发 Release 留用户**）

| 件 | 版本 | sha8 | 刷写目标 |
|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**95**（**11-19 上机在役**，本地件 `16a8a872`；bloff 摘除 = 日用灭屏走真睡路径；fork c23b9afb+4daca081+2da7ac41） | 16a8a872 | 机上 apk add |
| ESP | **v75**（r95 内核腿；本地 gz `c97f3e11` = **#96 在机件**，裸 `09759c87` 读回对 ✓） | 09759c87（裸） | recovery_a |
| Mu 镜像 | r91（**11-19 首刷在机**；r87 起 DTS 零改动沿用，dtb 同源 c061acd9；r69 前代留档） | 350386e0 | boot_b |
| 设备包 / 固件包 | **r63**（depends +iio-sensor-proxy 闭合；r61 起继承 waydroid 五件/r62 起 flatpak 商店）/ **r4**（11-19 蜂窝复燃轮上机 = +modem_pr mcfg/so 158 件，pmaports `f2885ef`，未发布；发布面仍 r3） | 2013b691 / bb2e9399（apk） | 机上 apk add |
| rootfs | Release r91-phosh（**11-19 直刷在机**；裸 16147c7d = CI 发布件同字节；waydroid 五件/flatpak 商店/iio fork r3 烤入） | 16147c7d | userdata |
| 上机期望 | `uname -v` → **#96**（11-19 r95/v75 双腿实测 ✓ 读回双对） | — | — |

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
