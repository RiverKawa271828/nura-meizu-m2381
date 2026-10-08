# nura-meizu-m2381 — Nura (postmarketOS) on Meizu 20

> English version: [README.en.md](README.en.md)

> 一句话：把 Nura（postmarketOS edge + 主线内核）完整跑在魅族 20（m2381 / SM8550 / kalama）上的全流程项目——源码在哪、用哪个工具出哪个镜像、刷到哪个分区、怎么回滚，四件事一张图说完。

## 免责与救砖（刷机前必读）

- **免责**：本项目按现状提供。刷机写入系统分区存在**变砖与数据全丢**风险，bootloader
  解锁本身也有安全与保修影响；验证过的基线只有 Flyme 12.6.0.0A + slot b 一种，其他版本
  行为未知。动手前请完整阅读 [docs/FLASHING.md](docs/FLASHING.md)，风险自负——作者不对
  任何设备损坏或数据损失负责。
- **救砖镜像自备**：刷机前先从 Release 页下载**锚三件**（`t-b2-*.img` /
  `esp-recovery-v4d.img` / `mu-r57-*.img`，均为实测已知好的历史版本）。刷坏回不进系统时，
  fastboot 重刷锚三件即可回家（30 秒配方 → FLASHING §6）；**不备锚件 = 出事只剩 EDL
  线刷一条高危路**。
- **锚三件 ≠ 原厂镜像，刷完也不回 Flyme**：三件全是本项目自建链（Mu-UEFI 固件 + ESP）
  的历史好版本，刷完回到的是**旧一版的 Nura/pmOS**。魅族原厂层（XBL/ABL/super 里的
  Flyme）本项目从不触碰、也不随锚恢复；想回原厂 Flyme 需自备官方完整线刷包走原厂
  通道，本项目不提供。

## 快速开始

镜像 = **Nura（postmarketOS edge）+ plasma-mobile 桌面**（内置默认），刷完即完整系统：
内核包 + 设备包已烤进 rootfs；登录用户 `user`，密码 `1234`（root 命令用 `sudo`，同密码）。

**路径 A：下载即刷（推荐，无需构建）**——GitHub Release 下载三件套（boot + recovery + rootfs）
与 `SHA256SUMS`，解压两个 gz 后四条命令：

```bash
sha256sum -c SHA256SUMS                 # 全 OK 才继续
fastboot flash boot_b      mu-r66-9033a734.img    # Mu-UEFI 固件（含设备树）
fastboot flash recovery_a  esp-recovery-v47.img   # ESP = 内核引导腿
fastboot flash userdata    meizu-meizu20-r66.img  # rootfs（⚠清空全部数据）
fastboot set_active b && fastboot reboot
```

约 1 分钟起 plasma 桌面。**首启必做**（**仅本 Release 的 r66 内核**）：进桌面后打开
「电源管理 → 节电」，**把自动睡眠/空闲挂起关掉**——r66 内核 suspend 必死，放着不管会在
空闲后睡死假重启（系统重启后一切正常，但每次空闲都会再来一次）；熄屏走屏幕熄灭（DPMS）即可。
**✅ 已在下一版内核（rc6 / r72 工作态）修好**：真凶 = in-tree printk 的 console 挂起路径
回归（`console_suspend_all()`），修法 = cmdline 加 `no_console_suspend`；新内核上真睡、
电源键/RTC 唤醒、自动睡眠均已实测通过（残留：ath12k 睡醒恢复约 20s，屏幕迟亮且 WiFi 需
重载模块，治本挂后续）。

刷机前准备八项（BL 解锁 / Flyme 基线 / 回滚锚）与逐条验证、
回滚救砖 → **[docs/FLASHING.md](docs/FLASHING.md)「快速路径 A：Release 直刷」**。

**路径 B：自己构建**（想改源码 / 出新一轮）：

```bash
script/setup.sh            # 环境体检（钉子/工具链/回滚锚）
script/build-kernel.sh --bump   # 内核 rN+1（tarball→checksum→build）
script/verify.sh           # 交付链对拍（dtb↔FdtBlob 同源等）
script/flash-batch.sh --i-am-present   # 一车刷（需人在设备旁）
```

他机复刻（从零摆构建布局）：`export NURA_WORK=/<你的工作根>` → `script/setup.sh --clone`
（按 `config.sh` 的 PIN_*_GIT 拉四仓 + 官方 pmbootstrap）。

> 两条路径共同前提：**bootloader 已解锁**（本项目不提供解锁 BL 方法，请自行研究）+ 设备为 **Flyme 12.6.0.0A + slot b 活动**——
> 这是唯一验证过的基线（精确版本/官方下载/MD5 见 FLASHING §1）；其他 Flyme 版本未验证，上一版 OTA 实测起不来，更新版本同样勿盲升。

刷机详细教程（含回滚救砖）→ **[docs/FLASHING.md](docs/FLASHING.md)**。
构建管线详解 → [docs/PIPELINE.md](docs/PIPELINE.md)；启动原理与镜像解剖 → [docs/DESIGN.md](docs/DESIGN.md)；现役产物与锚点 → [MANIFEST.md](MANIFEST.md)。

## 启动链 30 秒

```
XBL → ABL → boot_b: Mu-UEFI (m2381Pkg) ──送核──→ 主线内核 (EFI stub/zboot)
                 ↘ recovery_a: ESP (BOOTAA64.EFI = 内核，U-Boot 式备援)    root = /dev/sda22 (userdata, ext4)
四条腿各自独立更新：boot_b = Mu 镜像 ｜ recovery_a = ESP ｜ apk = 内核模块腿 ｜ userdata = rootfs
```

- **boot_b（Mu 镜像）**：链载 UEFI 固件，内含我们的设备树（FdtBlob）。DT 变了才需要重刷。
- **recovery_a（ESP）**：100MiB FAT32，`\EFI\BOOT\BOOTAA64.EFI` = 内核本体。换内核刷它。
- **apk（模块腿）**：内核包 = vmlinuz + /usr/lib/modules。**刷 ESP ≠ 换模块，两腿必须同轮走**。
- **userdata（rootfs）**：pmOS 根文件系统，日常不动。

为什么长这样、每件镜像内部是什么 → **[docs/DESIGN.md](docs/DESIGN.md)**（启动链原理与镜像解剖）。

## 硬件状态（2026-10-07 @ r66；本表只保现态，进度叙事在私有工作区 experiment-log）

**✅ 可工作**
显示（120Hz OLED + 背光/自动亮度）｜触控｜GPU 加速｜WiFi 双频含 5G｜蓝牙（含音频输出）｜
充电（PD）+ 电池电量计｜扬声器播放（直驱路径，干净无杂音；听筒留通话）｜视频硬解（H.264）｜
传感器四类 + 转屏｜震动（AW8697）｜zram｜Docker 容器｜NCM USB 网络（调试通道）。

**◐ 挂起（战役冻结、判决与素材都在档，复燃有路径）**
蜂窝数据/短信/语音（控制面已点亮 = 全球首个 SM8550 pmOS 蜂窝；卡在 S3 RF init，**用户态默认摘除**）｜
NFC（芯片应答、NCI init 不完成；**用户态默认摘除**）｜USB-C host/扩展坞（typec 栈已点亮，整机实测随手验）｜
Waydroid。

**✗ 不可工作**
录音/麦克风（SWR 域 bring-up，大后期）｜相机（平台已开放，传感器驱动未做）｜指纹｜GNSS（随蜂窝）｜
DP 视频外接（板上未焊 fsa4480，判负终审）｜深睡 MPM/AOSS（大后期；**普通 sleep 已在 rc6/r72
工作态修好并放开自动睡眠**，本 Release 的 r66 内核仍按上文关自动睡眠）｜IR/UWB（身份未定）。
硬件不存在：3.5mm 耳机孔、SD 卡槽。

> 蜂窝/NFC 默认摘除是省电与稳定性的**拍板形态**（设备包随包 mask），不是功能缺失。

## 三条红线（先读再动手）

1. **刷机需用户在场**：所有写分区动作走 `flash-batch.sh --i-am-present` / `rollback.sh --i-am-present`。
2. **不碰的分区**：xbl/abl/tz/modem、dtbo_b、super、modemst1/2、persist、misc（除非按配方清零）。
3. **两腿铁律**：换内核 = apk（模块）+ ESP（引导）同轮；只刷一条腿 = 半死状态。

## 版本号怎么看（Release 文件名速查）

| 记号 | 例子 | 含义 |
|---|---|---|
| `r66` | `mu-r66-*.img`、`meizu-meizu20-r66.img.gz` | **发布轮次** = 内核包 pkgrel，每出一轮 +1。同轮三件（boot / recovery / rootfs）**必须配对使用**，别混搭旧轮 |
| `v47` | `esp-recovery-v47.img.gz` | **ESP 版本**，独立计数，每换一次内核腿 +1（与 r 轮无换算关系，v47 恰好陪 r66） |
| `#67` | 上机 `uname -v` | 内核编译号 = **r + 1**（pkgrel+1 烤进内核）。上机第一验证点：看到 #67 = r66 内核真的在跑 |
| `9033a734` | `mu-r66-9033a734.img` | 镜像 sha256 前 8 位，防伪 + 刷后 dd 读回对拍用 |

设计细节与 #N 定律原理 → [docs/DESIGN.md](docs/DESIGN.md)；现役各件对应哪版 → [MANIFEST.md](MANIFEST.md)。

## 布局原则与源码仓库

本仓只聚**控制面**（脚本 + 文档 + 锚点清单）。源码树原地不动、按 `config.sh` 钉子引用；
厂商资产（meizu20_linux，~29G）永不入 git。

| 仓 | 地址 | 内容 | 分支 |
|---|---|---|---|
| 本项目（控制面） | <https://github.com/RiverKawa271828/nura-meizu-m2381> | 构建/验证/刷写脚本 + 版本钉 + 文档 + Release | master |
| fork 内核 | <https://github.com/RiverKawa271828/linux-mobile-ports> | fork torvalds/linux，魅族 20 增量 commit | meizu20-t4b |
| Mu-UEFI 固件 | <https://github.com/RiverKawa271828/Mu-Silicium> | fork Project-Silicium/Mu-Silicium，m2381Pkg | meizu20-mars-port |
| Mu Binaries | <https://github.com/RiverKawa271828/Device-Binaries> | Mu 设备二进制 submodule（钉 `036ba9f7`） | main |
| pmaports | <https://github.com/RiverKawa271828/pmaports> | 内核/设备/固件三包 + hexagonrtc 补丁 | phoenix |

工具链用官方 pmbootstrap（gitlab.postmarketos.org，`setup.sh --clone` 自动拉取）。
复刻路径：clone 本仓 → `export NURA_WORK=/<工作根>` → `script/setup.sh --clone`（按
`config.sh` 的 `PIN_*_GIT` 拉齐上述四仓 + pmbootstrap，回滚锚用 `--fetch-release` 补齐）。

## 治理

- 版本纪律：`#N = pkgrel + 1`（上机 `uname -v` 直接对）；包状态随改随提交；构建前 checksum。
- 硬定律与操作纪律的单一事实源在私有工作区仓的 AGENTS.md（未公开），本仓不复制、只引用。
- 项目名 `nura-meizu-m2381`（全小写 kebab；机器引用一律此名，人读标题随意）。
