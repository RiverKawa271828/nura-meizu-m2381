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

## 现在能干什么（速览）

✅ 显示/触控/GPU、WiFi 5G、蓝牙、充电（PD）、传感器四类+自动亮度+转屏、扬声器+听筒立体声、
震动（AW8697）、NFC probe、视频硬解、zram（r60 起）、蜂窝控制面（QMI 全注册，全球首个 SM8550 pmOS 蜂窝）。
◐ 蜂窝数据/语音（S3 卡 RF init）、BT 音频小声、录音。
✗ 相机、指纹、花屏真睡后 wake（bloff 工程解兜底）、深睡。

全表 → pmos_linux 仓 `docs/meizu20/status-inventory.md`；战役叙事 → `docs/meizu20/experiment-log.md`。

## 快速开始（本机现役布局）

> 前提：设备须为 **Flyme 12.6（最新 OTA）+ slot b 活动**——这是唯一验证过的基线；
> 其他 Flyme 版本未验证，上一版 OTA 实测起不来。详见 [docs/FLASHING.md](docs/FLASHING.md) §1。

```bash
script/setup.sh            # 环境体检（钉子/工具链/回滚锚）
script/build-kernel.sh --bump   # 内核 rN+1（tarball→checksum→build）
script/verify.sh           # 交付链对拍（dtb↔FdtBlob 同源等）
script/flash-batch.sh --i-am-present   # 一车刷（需人在设备旁）
```

刷机详细教程（含回滚救砖）→ **[docs/FLASHING.md](docs/FLASHING.md)**。
构建管线详解 → [docs/PIPELINE.md](docs/PIPELINE.md)；现役产物与锚点 → [MANIFEST.md](MANIFEST.md)。

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
- 硬定律与操作纪律的单一事实源在 pmos_linux 仓 `AGENTS.md`，本仓不复制、只引用。
- 项目名 `nura-meizu-m2381`（全小写 kebab；机器引用一律此名，人读标题随意）。
