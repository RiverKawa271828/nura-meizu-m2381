# MANIFEST — 现役产物 / 回滚锚 / 版本钉

> 每个发布轮更新「现役」表；锚点表只在变动时更新并同步 `config.sh` + FLASHING.md。
> 历史轮次明细 = 本仓 git log + 私有工作区 experiment-log，本表只保现役。

## 工作态（2026-10-14 @ r87 发布轮：**device r62 = 摘 discover + phosh 商店 flatpak 支持**（waydroid 五件 r61 起在包）——CI 云构建出 r87 发布件；在机 = **#88 + v68 + device r62**（apk+ESP 双腿升级 10-14，读回对 ✓）；发布面 = Release r84（r87 发布件随本轮云构建出）

| 件 | 版本 | 路径 | sha8 | 刷写目标 |
|---|---|---|---|---|
| 内核 apk | 7.3.0_**rc6**-r**87**（**纯版本 bump，内容与 r86 全同**：waydroid netd 双族策略路由/GPU 钳零件/no_console_suspend 全在；fork tip `140e5a8e308a` 不动；r87 腾号给本轮 release tag=r87 律） | `$PMB_WORK/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r87.apk` | 1aa9a260 | 机上 apk add |
| Mu 镜像 | r69（DTS 零改动沿用；r87 apk dtb 同源 c061acd9 verify ✓） | `artifacts/mu-r69-97cdea20.img` | 97cdea20 | boot_b |
| ESP | **v68**（r87 内核腿；仓内 `.img.gz`；10-14 上机读回整分区逐字节 ✓） | `artifacts/esp-recovery-v68.img.gz` | e7a044a8（裸镜像）/ 086a4eef（gz） | recovery_a |
| 设备包 / 固件包 | **r62**（摘 discover-backend-apk[KDE 商店=plasma 伴生件] + flatpak/gnome-software-plugin-flatpak[phosh 商店真 flatpak 支持，用户拍板]；r61 = waydroid 五件 + 52_waydroid.nft + preset disable）/ r3（零改动） | 同目录 | 5dc0fbd9（r62 apk）/ 6e6dac0a（fw） | 机上 apk add |
| 上机期望 | `uname -v` = `7.3.0-rc6` → **#88**（10-14 实测 ✓；waydroid v4 互联网+DNS 通，netd 零报错；52_waydroid.nft 装包后首 boot 手工 `nft -f` 补应用一次，后续 boot 由 nftables.service 正常加载） | — | — | — |

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

## 发布面现役产物（2026-10-14 @ r87；= Release r87 已发布 Latest；**CI 云构建 #22 首发**（run 38492230609，20m28s）；发布真值 = CI SHA256SUMS）

| 件 | 版本 | 发布件 sha8 | 刷写目标 |
|---|---|---|---|
| 内核 apk | 7.3.0_rc6-r**87**（=r86 内容纯版本轮） | 191f2344（CI）/ 1aa9a260（本地同轮件，异字节=时间戳） | 机上 apk add |
| 设备包 apk | 1-r**62**（摘 discover + flatpak 商店支持；waydroid 五件 r61 起） | 5dc0fbd9 | 机上 apk add（升级用户：waydroid 预装/flatpak/discover 摘除只随新装 rootfs，已装机手动补装） |
| 固件包 apk / tarball | 1-r**3** / r3（零改动） | apk 6e6dac0a / tarball 29c1ee88 | 机上 apk add |
| Mu 镜像 | **mu-r87-646a0eff**（DTS = FdtBlob c061acd9 同源，CI 构建） | 646a0eff | boot_b |
| ESP | **v68**（r87 内核腿；CI vmlinuz `901ebc15` ↔ CI apk 配对；同号异字节：CI gz `883610f6` / 本地 gz `086a4eef`（裸 e7a044a8，在机件）各自真值） | 883610f6（CI 发布件） | recovery_a |
| rootfs 镜像 | r87 同轮（--single-partition；内含 r87 + device r62 + fw r3 + **waydroid 五件预装** + **flatpak 商店**；phosh） | e53e804d（876.9MB，`meizu-meizu20-r87-phosh.img.gz`） | userdata |
| 升级包 | upgrade-r87.zip = 内核 apk + ESP v68 + UPGRADE.md | ff726542 | 升级腿 |

**Release r87 = <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r87>**（2026-10-14
上线 Latest；8 件 = 直刷三件 + 固件 tarball + apk 三件[内核/设备/固件] + upgrade zip + SHA256SUMS；
SUMS 自洽全 OK + 三层对拍全过[DTB CI≡本地 c061acd9 逐字节 / CI ESP↔CI apk 901ebc15 配对 /
rootfs debugfs 内容级 = r87+r62+r3+waydroid+flatpak 插件零 discover + 版本层 TAG=r87/ESP=v68/#88]）。
**回退配对**：r86 + v67 + device r60（#87 两轮实机绿）；再退 r84 + v65（= 上一个发布面，未删）。
上轮 r86 草稿已删（被 r87 取代；r85/r86 未发布，历史轮次在册）。

期望 uname：`7.3.0_rc6-r87` → **#88**（10-14 在机 apk+ESP 双腿升级实测 ✓，读回整分区逐字节）。

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
