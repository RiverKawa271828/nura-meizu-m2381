# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-10-08 @ （七十七）rc6 轮 —— **在机就是这套**）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**72**（qcom DTS 相对 rc3 零改动 ⇒ DTB 不变；cmdline 加 `no_console_suspend` = 睡死修复；fork `2431440968fe` @meizu20-t4b） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r72.apk` | 67069cb8 | 机上 apk add |
| Mu 镜像 | r69 | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | v53（内核腿；仓内 `.img.gz`） | `artifacts/esp-recovery-v53.img.gz` | c8d07289（裸镜像） | recovery_a |
| 设备包 / 固件包 | r53 / r3（同发布面） | 同目录 | — | 机上 apk add |
| 上机期望 | `uname -v` = `7.3.0-rc6` → **#73**；`/proc/cmdline` 含 `no_console_suspend` | — | — | — |

**rc6 轮实测**（10-08）：failed 0 / boot 29.5s / 音频·触控·传感器·显示全绿 / 功放 IRQ 零增长 /
真睡 + 电源键·RTC 唤醒通过 / **自动睡眠已放开**（powerdevil 5min，t+300s 入睡实证）。
已知残留 = ath12k 睡醒恢复 21.2s（屏幕迟亮 + WiFi 睡后死，治本挂下轮）。
两腿刷新法：`build-kernel.sh` → `build-esp.sh 53` → 刷；**Mu 不用重编（DTB 未变）**。

## 发布面现役产物（2026-10-07 @ 设备日（七十三）后；= Release r66，已发布）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_rc3-r**66**（fsa4480 摘除 DTB + CONFIG_PSI=y；fork `f42761da35ab`） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc3-r66.apk` | — | 机上 apk add |
| 设备包 apk | 1-r**53**（r52 = NFC+蜂窝用户态摘除随包 mask；r53 = **depends + hexagonrtc 三件**——Release rootfs 首航暴雷修复，传感器 PD 守护链随 rootfs 带齐） | 同目录 `device-meizu-meizu20-1-r53.apk` | — | 机上 apk add |
| 固件包 apk | 1-r**3** | 同目录 `firmware-meizu-meizu20-1-r3.apk` | — | 机上 apk add |
| Mu 镜像 | r66 | `artifacts/mu-r66-9033a734.img` | 9033a734 | boot_b |
| ESP | v47（仓内 `.img.gz`；刷写/verify 自动解压） | `artifacts/esp-recovery-v47.img.gz` | a0455923（裸镜像） | recovery_a |
| rootfs 镜像 | r66 同轮（**--single-partition 修复版 10-07 换件**；内含内核 r66 apk + 设备包 r53 + hexagonrtc 依赖链；纯官方预装，机上后装件不在内） | Release 分发件 `meizu-meizu20-r66.img.gz`（1.10GiB，sha8 **e4636bfe**；首版 90961230 漏 `--single-partition` 上机暴雷已撤换） | e4636bfe | userdata |
| 源码钉（发布轮 r66 时） | fork `f42761da35ab` @meizu20-t4b ｜ Mu `14692e56822c` @meizu20-mars-port ｜ pmaports `222f0c5` @phoenix（r53 depends 修复轮） ｜ Binaries fork main=`036ba9f7`——**四仓已推 GitHub**；推送前敏感信息清扫：三树历史中性化过 WiFi SSID/本地路径，hash 相应重写；DTS 注释级改动不影响编译产物 | — | — | — |

**源码钉（工作态 2026-10-08 推）**：内核 fork `2431440968fe` @meizu20-t4b（**v7.3-rc6 重放**；
`master` 已同步到 rc6 基线提交 `a90ee4305c4a` ⇒ 公开页面显示「领先 84 提交」= 恰好板级内容；
历史线归档 tag：`archive/pre-rc6-meizu20-t4b` / `archive/meizu20-7.3-T3` / `archive/meizu20-m2381-local`）
｜ Mu `bdea825c` @meizu20-mars-port（r69 FdtBlob）｜ pmaports `959c775` @phoenix（rc6 + cmdline）。

**Release r66 = <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r66>**（2026-10-07
推送窗口上传）：直刷三件 + 锚三件 + 固件 tarball（自建者用）+ `SHA256SUMS`。
**Release 直刷三件（boot / recovery / rootfs）必须同轮配对**——外人路径 = FLASHING「快速路径 A」。

期望 uname：`7.3.0_rc3-r66` → **#67**。10-07 上机已实证（#N=pkgrel+1 第 13 证）；
当轮战果（typec 首亮 / pm8008 ×14 撤除 / Docker e2e 全绿 / 空转清剿第一轮 / NFC 摘除）
= 私有工作区 experiment-log（七十三）。

## 回滚锚（救命的三个文件，勿删勿挪；同 config.sh）

| 锚 | 文件 | sha8 | 用途 |
|---|---|---|---|
| t-b2 | `<NURA_WORK>/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/t-b2-m2381Pkg-RELEASE-d4928661.img` | d4928661 | boot_b 兜底（UEFI 基线） |
| esp-v4d | `<NURA_WORK>/meizu20/meizu20-m1/m1-work/arch-a/esp-recovery-v4d.img` | 3b106f07 | recovery_a 兜底 |
| mu-r57 | `<NURA_WORK>/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/mu-r57-4640ebb5.img` | 4640ebb5 | boot_b 最近已知好（r57 时代） |

30 秒回滚 = `script/rollback.sh --i-am-present`（前两个锚）。
⚠ 锚三件 = Release r66 资产（已上传）；他机一键拉齐 = `setup.sh --fetch-release`，
本机缺失时也会在 `setup.sh` 体检里报警告。当前时代的次级回退对（手动刷，非 rollback.sh）：
`artifacts/mu-r64-686a4c0f.img`（686a4c0f）+ `artifacts/esp-recovery-v46.img.gz`（裸 0d4796ed）+ device r51。

## 已知非回归失败（首 boot 看到**不用慌**）

| unit | 形态 | 定性 |
|---|---|---|
| rmtfs | activating | 封印态存活模式（drop-in 生效中） |
| uim-selection | start-limit-hit | 在役同款（deactivate 容错补丁在机） |
| postmarketos-zram-swap | failed（仅 r<60 内核） | 无 CONFIG_ZRAM=m；r60 起修复 |

## 通道速查

- root devshell：`tools/devsh.py`（NCM + nc :23）｜ ssh：`user@172.16.42.1` / 1234 / root 走 `sudo`（密码 1234，本机无 doas）
- 软进 fastboot：`systemctl reboot --reboot-argument=bootloader`（18d1:d00d）
- 宿主长构建：systemd-run（脚本已内置）；与 K30 wrapper 串行（共享 work dir，仅本机布局）

## 历史轮次

r61 首航（10-06）→ r63/r64 录音轮 → r65 pm8008 → r66 fsa4480 摘除（10-07）；
逐轮产物/sha 明细见 git log。ESP 自 v47 起仓内 gz 化（v43–v45 裸镜像已退役出史）。
