# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。

## 现役产物（2026-10-06 @ T1 审计轮收口）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_rc3-r**60**（r61 待建：吃 yaml 修复 `82ecc62184c0`） | `.pmbootstrap/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc3-r60.apk` | — | 机上 apk add |
| 设备包 apk | 1-r**37** | 同目录 `device-meizu-meizu20-1-r37.apk` | — | 机上 apk add |
| 固件包 apk | 1-r**3** | 同目录 `firmware-meizu-meizu20-1-r3.apk` | — | 机上 apk add |
| Mu 镜像 | r60 | `../meizu20/meizu20-m1/artifacts-uefi/mars-t-series/mu-r60-4b1b4315.img` | 4b1b4315 | boot_b |
| ESP | v42 | `../meizu20/meizu20-m1/m1-work/arch-a/esp-recovery-v42.img` | 7373e097 | recovery_a |
| 源码钉 | fork `82ecc62184c0` @meizu20-t4b ｜ Mu `98768952` @meizu20-mars-port ｜ pmaports `1669cdb` @phoenix | — | — | — |

期望 uname：`7.3.0_rc3-r60` → **#61**（r61 → #62）。

## 回滚锚（救命的三个文件，勿删勿挪；同 config.sh）

| 锚 | 文件 | sha8 | 用途 |
|---|---|---|---|
| t-b2 | `artifacts-uefi/mars-t-series/t-b2-m2381Pkg-RELEASE-d4928661.img` | d4928661 | boot_b 兜底（UEFI 基线） |
| esp-v4d | `m1-work/arch-a/esp-recovery-v4d.img` | 3b106f07 | recovery_a 兜底 |
| mu-r57 | `artifacts-uefi/mars-t-series/mu-r57-4640ebb5.img` | 4640ebb5 | boot_b 最近已知好（r57 时代） |

30 秒回滚 = `script/rollback.sh --i-am-present`（前两个锚）。

## 已知非回归失败（首 boot 看到**不用慌**）

| unit | 形态 | 定性 |
|---|---|---|
| rmtfs | activating | 封印态存活模式（drop-in 生效中） |
| uim-selection | start-limit-hit | 在役同款（deactivate 容错补丁在机） |
| postmarketos-zram-swap | failed（r<60 内核） | 无 CONFIG_ZRAM=m；r60 起修复 |

## 通道速查

- root devshell：`tools/devsh.py`（NCM + nc :23）｜ ssh：`user@172.16.42.1` / 1234 / doas 免密
- 软进 fastboot：`systemctl reboot --reboot-argument=bootloader`（18d1:d00d）
- 宿主长构建：systemd-run（脚本已内置）；与 K30 wrapper 串行（共享 work dir）
