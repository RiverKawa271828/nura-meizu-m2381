# nura-meizu-m2381 — Nura (postmarketOS) on Meizu 20

> English version: [README.en.md](README.en.md)

> 一句话：把 Nura（postmarketOS edge + 主线内核）完整跑在魅族 20（m2381 / SM8550 / kalama）上的全流程项目——源码在哪、用哪个工具出哪个镜像、刷到哪个分区、怎么回滚，四件事一张图说完。

## 免责与救砖（刷机前必读）

- **免责**：本项目按现状提供。刷机写入系统分区存在**变砖与数据全丢**风险，bootloader
  解锁本身也有安全与保修影响；验证过的基线只有 Flyme 12.6.0.0A + slot b 一种，其他版本
  行为未知。动手前请完整阅读 [docs/FLASHING.md](docs/FLASHING.md)，风险自负——作者不对
  任何设备损坏或数据损失负责。
- **救砖姿态 = 重刷即回家**：刷坏回不进系统时，用 fastboot 重刷 Release 的三件即可回家
  （都是当轮验证过的现役件，配方 → FLASHING §6）。历史回滚锚件自 r80 起不再随 Release
  发布；9008/EDL 线刷是最后通道，不在本项目范围内。
- **本项目不回原厂**：所有镜像都是本项目自建链（Mu-UEFI 固件 + ESP + pmOS rootfs）；
  魅族原厂层（XBL/ABL/super 里的 Flyme）本项目从不触碰、也不提供恢复。想回原厂 Flyme
  需自备官方完整线刷包走原厂通道，本项目不提供。

## 快速开始

镜像 = **Nura（postmarketOS edge）+ plasma-mobile 桌面**（内置默认），刷完即完整系统：
内核包 + 设备包已烤进 rootfs；登录用户 `user`，密码 `1234`（root 命令用 `sudo`，同密码）。

**路径 A：下载即刷（推荐，无需构建）**——GitHub Release 下载三件套（boot + recovery + rootfs）
与 `SHA256SUMS`，解压两个 gz 后四条命令：

```bash
sha256sum -c SHA256SUMS                 # 全 OK 才继续
fastboot flash boot_b      mu-r69-97cdea20.img    # Mu-UEFI 固件（含设备树）
fastboot flash recovery_a  esp-recovery-v61.img   # ESP = 内核引导腿
fastboot flash userdata    meizu-meizu20-r80.img  # rootfs（⚠清空全部数据）
fastboot set_active b && fastboot reboot
```

约 1 分钟起 plasma 桌面。**睡眠可直接用**（本 Release 起）：空闲自动睡（默认 5 分钟）+
电源键/RTC 唤醒，睡眠期间 **WoWLAN 保持 WiFi 连接**（设备包自带服务，零配置）。
已知小边角：唤醒后若无输入，桌面的空闲自动睡不自动重新武装——给一次输入即恢复，日常无感。

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

## 硬件状态（2026-10-11 @ r80；本表只保现态，进度叙事在私有工作区 experiment-log）

**✅ 可工作**
显示（120Hz OLED + 背光/自动亮度）｜触控｜GPU 加速｜WiFi 双频含 5G（睡眠保连接 WoWLAN）｜
蓝牙（含音频输出 + BLE HID 键鼠/手柄）｜充电（PD）+ 电池电量计｜扬声器播放（直驱路径，干净
无杂音；听筒留通话）｜视频硬解（H.264）｜传感器四类 + 转屏｜震动（AW8697）｜zram｜Docker 容器｜
NCM USB 网络（调试通道）｜**suspend（s2idle：空闲自动睡 + 电源键/RTC 唤醒 + WoWLAN 保链路）**。

**◐ 挂起（战役冻结、判决与素材都在档，复燃有路径）**
蜂窝数据/短信/语音（控制面已点亮 = 全球首个 SM8550 pmOS 蜂窝；卡在 S3 RF init，**用户态默认摘除**）｜
NFC（芯片应答、NCI init 不完成；**用户态默认摘除**）｜USB-C host/扩展坞（typec 栈已点亮，整机实测随手验）｜
Waydroid。

**✗ 不可工作**
录音/麦克风（SWR 域 bring-up，大后期）｜相机（平台已开放，传感器驱动未做）｜指纹｜GNSS（随蜂窝）｜
DP 视频外接（板上未焊 fsa4480，判负终审）｜深睡 MPM/AOSS（大后期；普通 sleep 已可用见 ✅）｜
IR/UWB（身份未定）。
硬件不存在：3.5mm 耳机孔、SD 卡槽。

> 蜂窝/NFC 默认摘除是省电与稳定性的**拍板形态**（设备包随包 mask），不是功能缺失。

## 三条红线（先读再动手）

1. **刷机需用户在场**：所有写分区动作走 `flash-batch.sh --i-am-present` / `rollback.sh --i-am-present`。
2. **不碰的分区**：xbl/abl/tz/modem、dtbo_b、super、modemst1/2、persist、misc（除非按配方清零）。
3. **两腿铁律**：换内核 = apk（模块）+ ESP（引导）同轮；只刷一条腿 = 半死状态。

## 版本号怎么看（Release 文件名速查）

| 记号 | 例子 | 含义 |
|---|---|---|
| `r80` | `mu-r69-*.img`、`meizu-meizu20-r80.img.gz` | **发布轮次** = 内核包 pkgrel，每出一轮 +1。同轮三件（boot / recovery / rootfs）**必须配对使用**，别混搭旧轮 |
| `v61` | `esp-recovery-v61.img.gz` | **ESP 版本**，独立计数，每换一次内核腿 +1（与 r 轮无换算关系，v61 恰好陪 r80） |
| `#81` | 上机 `uname -v` | 内核编译号 = **r + 1**（pkgrel+1 烤进内核）。上机第一验证点：看到 #81 = r80 内核真的在跑 |
| `97cdea20` | `mu-r69-97cdea20.img` | 镜像 sha256 前 8 位，防伪 + 刷后 dd 读回对拍用 |

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
