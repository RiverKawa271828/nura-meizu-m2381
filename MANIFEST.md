# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-10-10 @ uinput 轮；在机就是这套）

> ⚠ **r72 Release 已整体撤回**（含 tag）：首传的 rootfs 资产被抓到是**「正在写入的半截流」**
> （607,911,936 B，正确件 = 1,177,103,795 B）——上传与 gzip 落盘竞态所致；启停件本身未动。
> **教训**：SHA256SUMS 只能证明传输一致，**不能证明生成时文件已写完** ⇒ 以后传大件必须
> 「传完再下载回来做 `gzip -t` + sha 对拍」闭环。修好（外加 ath12k 唤醒残留）后再按新 tag 重发。

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**78**（**config-only 轮：+CONFIG_INPUT_UINPUT=m**，steamos 线带话主诉求；DTS/驱动源码零改动 ⇒ DTB 不变、Mu 免重打；fork tip 同 r77 `02fe4629080a` @meizu20-t4b） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r78.apk` | — | 机上 apk add |
| Mu 镜像 | r69 | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | v59（内核腿；仓内 `.img.gz`） | `artifacts/esp-recovery-v59.img.gz` | 78f425ac（裸镜像）/ 903bbf6b（gz） | recovery_a |
| 设备包 / 固件包 | **r59**（uinput 用户态胶水：`60-meizu20-uinput.rules` uaccess+static_node / `modules-load.d` 开机加载）/ r3 | 同目录 | — | 机上 apk add |
| 上机期望 | `uname -v` = `7.3.0-rc6` → **#79**；`/dev/uinput` 存在（r78+ 装 r59 后） | — | — | — |

**uinput 轮实测**（10-10）：verify 全绿（dtb 同源 c061acd9 / uinput.ko 在列 / ESP↔apk 同源 b5e13ca5）；
**r78 `uinput.ko` 在 Debian v5 盒（在跑 r77/#78 内核）insmod 实机预演通过**——/dev/uinput 出现
（root:root 600，与 steamos 线报的默认态一致 ⇒ uaccess 规则确有必要）、rmmod 零残留。
IN_FORMATS 查证（steamos 线第二问）= **翻案成立**：DPU 平面自 mainline 2019 就带
IN_FORMATS（QCOM_COMPRESSED+LINEAR），steamos 的 `grep in_formats state` 是假探针
（state dump 不打该属性）；实探 kwin 正用 UBWC（modifier 0x0500…0001）扫出，判词见
AGENTS「带话」节回信。

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

**源码钉（工作态 2026-10-10 推）**：内核 fork `02fe4629080a` @meizu20-t4b（r77/r78 同 tip；
`master` 已同步到 rc6 基线提交 `a90ee4305c4a` ⇒ 公开页面显示「领先 84 提交」= 恰好板级内容；
历史线归档 tag：`archive/pre-rc6-meizu20-t4b` / `archive/meizu20-7.3-T3` / `archive/meizu20-m2381-local`）
｜ Mu `bdea825c` @meizu20-mars-port（r69 FdtBlob）｜ pmaports `77b235c` @phoenix（r78 uinput + r59 胶水）。

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
