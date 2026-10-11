# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-10-12 @（八十七）phosh 回归轮收官：发布面 = **Release r84（首个 phosh 发布面）**；在机 = pmOS phosh #85 本机实测全绿；用户拍板「以后专注 phosh」）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**84**（GPU/IFPC 轮收官件：revert A 路 + 钳零防御 + payload 订阅；fork tip `140e5a8e308a`） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r84.apk` | b5dd7e62 | 机上 apk add |
| Mu 镜像 | r69（DTS 零改动沿用） | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | v65（内核腿；仓内 `.img.gz`） | `artifacts/esp-recovery-v65.img.gz` | 463efc45（裸镜像）/ 00d2d5f9（gz） | recovery_a |
| 设备包 / 固件包 | **r60**（modules-load.d 补 uhid 自载）/ r3 | 同目录 | — | 机上 apk add |
| 上机期望 | `uname -v` = `7.3.0-rc6` → **#85**（彼侧在役实测 ✓） | — | — | — |

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

**回滚配对**：内核 r82 + ESP v63（裸 533f40d0；gz = 彼侧重压版 425ecd37，原打包件两侧
均已断）+ device r60（= r82/v63/#83，彼侧在役回滚件）。

## 发布面现役产物（2026-10-12 @ r84；= Release r84 已发布；用户拍板「以后专注 phosh」：r66 已删，r80 = plasma 末版存档未删）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_rc6-r**84**（GPU/IFPC 轮收官：revert A 路 + 钳零防御 + payload 订阅；fork `140e5a8e308a`） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r84.apk` | b5dd7e62 | 机上 apk add |
| 设备包 apk | 1-r**60**（uhid 自载；r57-59 = wowlan service + s2idle 看门狗修复 + uinput 随包历史） | 同目录 `device-meizu-meizu20-1-r60.apk` | — | 机上 apk add |
| 固件包 apk | 1-r**3** | 同目录 `firmware-meizu-meizu20-1-r3.apk` | 6e6dac0a | 机上 apk add |
| Mu 镜像 | r69（DTS 零改动自 r66 轮沿用） | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | v65（仓内 `.img.gz`；刷写/verify 自动解压） | `artifacts/esp-recovery-v65.img.gz` | 463efc45（裸）/ 00d2d5f9（gz） | recovery_a |
| rootfs 镜像 | r84 同轮（--single-partition；内含内核 r84 apk + 设备包 r60 + 固件 r3；**phosh** 桌面 = pmOS 官方 phosh 包集） | Release 分发件 `meizu-meizu20-r84.img.gz`（1.04GiB） | a2fdcd33 | userdata |
| 源码钉（发布轮 r84 时） | fork `140e5a8e308a` @meizu20-t4b ｜ Mu `bdea825c` @meizu20-mars-port（r69 FdtBlob，未变）｜ pmaports `b4e5147` @phoenix（pkgrel 84）——**三树已推 GitHub** | — | — | — |

**Release r84 = <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r84>**（2026-10-12
上传；本地件 `gzip -t` 过 + 上传后资产字节数与本地逐件对拍全等；gz 自回归通过的在机
同款 local.img 生成 = 单一真值源）：直刷三件 + 固件 tarball + apk 两件 + `SHA256SUMS`
共 7 件（r80 同构）。**直刷三件（boot / recovery / rootfs）必须同轮配对**——外人路径 =
FLASHING「快速路径 A」。**r84 起 build-rootfs.sh 固化条件 = NURA_NO_RELEASE 开关**
（UI 无关，phosh 默认进发布面；原「非 plasma 自动跳过」作废）。

期望 uname：`7.3.0_rc6-r84` → **#85**（10-12 本机 phosh 回归全绿实测 ✓ =（八十七）：
boot ~50s / failed 0 / 音频 T4c 直驱自动钉 / GPU 钳零件 busy_delta 恒 0 / 睡眠 rtcwake
51s resume 0.240s + wowlan 武装 / 看门狗修复件全生效）。本轮发布面变化：UI =
plasma→**phosh**；**升级口径**：内核/设备包/固件 = **apk 腿（rootfs 内 apk add）+ ESP 腿
（recovery_a）原地升级，不重刷 userdata**（/home 与配置全保留）；rootfs 全量重刷仅用于
换 UI/换发行版/从零装机。r80 plasma 末版存档（Release 未删）。

## 回滚锚（私有工作区本地保留；r80 起不随 Release 发布）

> 2026-10-11 用户拍板：现役件可信，**刷坏 = 重刷 Release 现役三件回家**，历史锚不再上传
> （r66 页上的旧锚资产留档不删）。下表三件仅本机私有保留，`rollback.sh` / config.sh
> ANCHOR_* 自用；公开 FLASHING §6 已改为现役件重刷阶梯。

| 锚 | 文件 | sha8 | 用途 |
|---|---|---|---|
| t-b2 | `<NURA_WORK>/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/t-b2-m2381Pkg-RELEASE-d4928661.img` | d4928661 | boot_b 兜底（UEFI 基线） |
| esp-v4d | `<NURA_WORK>/meizu20/meizu20-m1/m1-work/arch-a/esp-recovery-v4d.img` | 3b106f07 | recovery_a 兜底 |
| mu-r57 | `<NURA_WORK>/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/mu-r57-4640ebb5.img` | 4640ebb5 | boot_b 最近已知好（r57 时代） |

30 秒回滚 = `script/rollback.sh --i-am-present`（前两个锚，仅私有工作区布局可用）。
当前时代的次级回退对（手动刷，非 rollback.sh）：
`artifacts/mu-r64-686a4c0f.img`（686a4c0f）+ `artifacts/esp-recovery-v46.img.gz`（裸 0d4796ed）+ device r51。

## 已知非回归失败（首 boot 看到**不用慌**；=（八十七）phosh r84 实测清单）

| 现象 | 形态 | 定性 |
|---|---|---|
| journal 早期时间戳 | 标着旧日期（如 Oct 06） | **rtc1 旧值未同步**：NTP 前内核时钟 = RTC 存值，早期日志全错标；勿当旧 boot 日志读。WiFi+NTP 后恢复；写回闭环待复验 |
| DPU「no encoder found for crtc 0」 | *ERROR* ×2-3 条，仅 boot 早期 | 窗口性噪音：面板 cold-enable restart 自愈窗口撞上合成器 vblank 请求（dpu_crtc.c:192/282）；运行期零刷，勿追 |
| a740_sqe.fw | failed with error -2 | 假警报（27s 后重试成功；silime 时代已定性） |
| pmic-spmi 0-0c/0-0d | probe failed -5 | 在册已知（多轮 boot 一致，无功能影响） |

（历史行留档：rmtfs activating / uim-selection start-limit-hit = 蜂窝用户态在役时代现象，
现役 rootfs 蜂窝摘除态 + 未装四件套时不见；postmarketos-zram-swap failed 仅 r<60 内核，r60 起修复。）

## 通道速查

- root devshell：`tools/devsh.py`（NCM + nc :23）｜ ssh：`user@172.16.42.1` / 1234 / root 走 `sudo`（密码 1234，本机无 doas）
- 软进 fastboot：`systemctl reboot --reboot-argument=bootloader`（18d1:d00d）
- 宿主长构建：systemd-run（脚本已内置）；与 K30 wrapper 串行（共享 work dir，仅本机布局）

## 历史轮次

r61 首航（10-06）→ r63/r64 录音轮 → r65 pm8008 → r66 fsa4480 摘除（10-07，首个 Release）→
r72 首传半截流撤回（10-08，教训入流程）→ r80 async flip + uhid（10-11，Release 上线）→ r84 phosh 首个 phosh 发布面 + r66 删除（10-12，专注 phosh 拍板）；
逐轮产物/sha 明细见 git log。ESP 自 v47 起仓内 gz 化（v43–v45 裸镜像已退役出史）。
