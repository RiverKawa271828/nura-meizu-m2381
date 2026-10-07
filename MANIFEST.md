# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 现役产物（2026-10-07 @ 设备日（七十三）后）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_rc3-r**66**（fsa4480 摘除 DTB + CONFIG_PSI=y；fork `f56a9783d245`） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc3-r66.apk` | — | 机上 apk add |
| 设备包 apk | 1-r**52**（NFC 摘除 + 蜂窝用户态摘除随包 mask） | 同目录 `device-meizu-meizu20-1-r52.apk` | — | 机上 apk add |
| 固件包 apk | 1-r**3** | 同目录 `firmware-meizu-meizu20-1-r3.apk` | — | 机上 apk add |
| Mu 镜像 | r66 | `artifacts/mu-r66-9033a734.img` | 9033a734 | boot_b |
| ESP | v47（仓内 `.img.gz`；刷写/verify 自动解压） | `artifacts/esp-recovery-v47.img.gz` | a0455923（裸镜像） | recovery_a |
| 源码钉 | fork `f56a9783d245` @meizu20-t4b ｜ Mu `d53165b3` @meizu20-mars-port ｜ pmaports `607eeed` @phoenix | — | — | — |

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
⚠ 锚三件 = Release 资产（未上传前仅存在于原工作区；他机 `setup.sh` 会对缺失报警告，
跑 rollback 前必须先补齐）。当前时代的次级回退对（手动刷，非 rollback.sh）：
`artifacts/mu-r64-686a4c0f.img`（686a4c0f）+ `artifacts/esp-recovery-v46.img.gz`（裸 0d4796ed）+ device r51。

## 已知非回归失败（首 boot 看到**不用慌**）

| unit | 形态 | 定性 |
|---|---|---|
| rmtfs | activating | 封印态存活模式（drop-in 生效中） |
| uim-selection | start-limit-hit | 在役同款（deactivate 容错补丁在机） |
| postmarketos-zram-swap | failed（仅 r<60 内核） | 无 CONFIG_ZRAM=m；r60 起修复 |

## 通道速查

- root devshell：`tools/devsh.py`（NCM + nc :23）｜ ssh：`user@172.16.42.1` / 1234 / doas 免密
- 软进 fastboot：`systemctl reboot --reboot-argument=bootloader`（18d1:d00d）
- 宿主长构建：systemd-run（脚本已内置）；与 K30 wrapper 串行（共享 work dir，仅本机布局）

## 历史轮次

r61 首航（10-06）→ r63/r64 录音轮 → r65 pm8008 → r66 fsa4480 摘除（10-07）；
逐轮产物/sha 明细见 git log。ESP 自 v47 起仓内 gz 化（v43–v45 裸镜像已退役出史）。
