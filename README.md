# nura-meizu-m2381 — Nura (postmarketOS) on Meizu 20

> 一句话：把 Nura（postmarketOS edge + 主线内核）完整跑在魅族 20（m2381 / SM8550 / kalama）上的全流程项目——源码在哪、用哪个工具出哪个镜像、刷到哪个分区、怎么回滚，四件事一张图说完。

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
DP 视频外接（板上未焊 fsa4480，判负终审）｜suspend/深睡（熄屏走 DPMS 替代；真深睡唤醒有花屏史，
bloff 工程解默认兜底）｜IR/UWB（身份未定）。硬件不存在：3.5mm 耳机孔、SD 卡槽。

> 蜂窝/NFC 默认摘除是省电与稳定性的**拍板形态**（设备包 r52 随包 mask），不是功能缺失。

## 快速开始

**路径 A：下载即刷（推荐，无需构建）**——GitHub Release 下载三件套（boot + recovery + rootfs，
附 SHA256SUMS），fastboot 三条命令直刷，刷完即完整系统（内核包+设备包已烤进 rootfs）。
前置准备与逐条命令 → **[docs/FLASHING.md](docs/FLASHING.md)「快速路径 A：Release 直刷」**。

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

## 三条红线（先读再动手）

1. **刷机需用户在场**：所有写分区动作走 `flash-batch.sh --i-am-present` / `rollback.sh --i-am-present`。
2. **不碰的分区**：xbl/abl/tz/modem、dtbo_b、super、modemst1/2、persist、misc（除非按配方清零）。
3. **两腿铁律**：换内核 = apk（模块）+ ESP（引导）同轮；只刷一条腿 = 半死状态。

## 布局原则

本仓只聚**控制面**（脚本 + 文档 + 锚点清单）。源码树原地不动、按 `config.sh` 钉子引用：
fork 内核（linux-mobile-ports）、Mu 固件树、pmaports 三包、厂商资产（meizu20_linux，永不入 git）。
Phase-2（公开发布）时在 `config.sh` 填四个公共 URL，`setup.sh` 即可在任何机器复刻布局。

## 治理

- 版本纪律：`#N = pkgrel + 1`（上机 `uname -v` 直接对）；包状态随改随提交；构建前 checksum。
- 硬定律与操作纪律的单一事实源在私有工作区仓的 AGENTS.md（未公开），本仓不复制、只引用。
- 项目名 `nura-meizu-m2381`（全小写 kebab；机器引用一律此名，人读标题随意）。
