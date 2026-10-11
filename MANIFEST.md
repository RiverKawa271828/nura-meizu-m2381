# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-10-11 晚 @ r81 升现役——彼线点火回归 PASS；在机 = 彼侧 armada-sheng #82；发布面 = Release r80）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**81**（彼线回归 PASS：CONFIG_SQUASHFS_ZSTD/XZ=y + RTC_HCTOSYS/SYSTOHC→rtc1；config-only，fork tip `349e8aa5579b` 不动 ⇒ DTB/Mu 免重打） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r81.apk` | 1c31babe | 机上 apk add |
| Mu 镜像 | r69（DTS 零改动沿用） | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | v62（内核腿；仓内 `.img.gz`） | `artifacts/esp-recovery-v62.img.gz` | b41b8889（裸镜像，10-11 勘误※）/ 3e4987d5（gz） | recovery_a |
| 设备包 / 固件包 | **r60**（modules-load.d 补 uhid 自载）/ r3 | 同目录 | — | 机上 apk add |
| 上机期望 | `uname -v` = `7.3.0-rc6` → **#82**（彼侧在役实测 ✓）；回滚 = r80/v61/r59（=Release r80） | — | — | — |

**r81 回归回执**（10-11 晚，steamos 线）：EFI↔apk vmlinuz 5cb94ebd 双侧互证；zstd sqsh 直挂
（gzip 重压 workaround 撤）；RTC 用户态三件下线后时钟正确 + timedatectl 首次读出 RTC；
彼侧 qbootctl v0.2.2 设备端现编落地（fastboot 停车根除，SLOT b Successful=1 重启重标 ✓）。
※勘误：v62 裸镜像原记 b41b8888 为构建当拍坏读数，真值 b41b8889cadf…（出货 gz 解压/
彼侧实测/make-esp 末行三方全等）；build-esp.sh 打印已改为出货 gz 反推。

**回滚配对**：内核 r80 + ESP v61（裸 cb7f1e5a）+ device r59 = **Release r80**
（2026-10-11 上线：kwin sync / BLE HID / async flip 四合一回归全 PASS，steamos 线四合一回执）。

## 发布面现役产物（2026-10-11 @ async flip + uhid 轮后；= Release r80，已发布）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_rc6-r**80**（async flip 三件套 r79 + CONFIG_UHID=m r80；fork `349e8aa5579b`） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r80.apk` | — | 机上 apk add |
| 设备包 apk | 1-r**59**（uinput uaccess + modules-load.d；r57/r58 = wowlan service + s2idle 看门狗修复随包） | 同目录 `device-meizu-meizu20-1-r59.apk` | — | 机上 apk add |
| 固件包 apk | 1-r**3** | 同目录 `firmware-meizu-meizu20-1-r3.apk` | — | 机上 apk add |
| Mu 镜像 | r69（DTS 零改动自 r66 轮沿用） | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | v61（仓内 `.img.gz`；刷写/verify 自动解压） | `artifacts/esp-recovery-v61.img.gz` | cb7f1e5a（裸镜像） | recovery_a |
| rootfs 镜像 | r80 同轮（--single-partition；内含内核 r80 apk + 设备包 r59 + 固件 r3；纯官方预装，机上后装件不在内） | Release 分发件 `meizu-meizu20-r80.img.gz`（1.10GiB） | e1b9494f | userdata |
| 源码钉（发布轮 r80 时） | fork `349e8aa5579b` @meizu20-t4b ｜ Mu `bdea825c` @meizu20-mars-port（r69 FdtBlob，未变）｜ pmaports `850e86d` @phoenix（r80 UHID 轮）——**三树已推 GitHub** | — | — | — |

**Release r80 = <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r80>**（2026-10-11
上传；本地件 `gzip -t` 过 + 上传后资产字节数与本地逐件对拍全等——r72 半截流教训的完整
「下载回读 gzip -t」闭环本轮由用户豁免）：直刷三件 + 固件
tarball（自建者用）+ `SHA256SUMS`，共 5 件。**Release 直刷三件（boot / recovery / rootfs）
必须同轮配对**——外人路径 = FLASHING「快速路径 A」。

期望 uname：`7.3.0_rc6-r80` → **#81**（#N=pkgrel+1）。本轮发布面新增用户可见项 =
**suspend 可用**（空闲自动睡 + 电源键/RTC 唤醒 + WoWLAN 保 WiFi）+ BLE HID（uhid）；
async flip（r79，uAPI 层）为 compositor 侧能力。当轮战果全量 = 私有工作区 experiment-log
（八十二）+ steamos 线四合一回归回信。

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

r61 首航（10-06）→ r63/r64 录音轮 → r65 pm8008 → r66 fsa4480 摘除（10-07，首个 Release）→
r72 首传半截流撤回（10-08，教训入流程）→ r80 async flip + uhid（10-11，Release 上线）；
逐轮产物/sha 明细见 git log。ESP 自 v47 起仓内 gz 化（v43–v45 裸镜像已退役出史）。
