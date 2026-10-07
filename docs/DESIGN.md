# 设计：启动链原理与镜像解剖

> 回答两个问题：**这台机器怎么跑起来的**（上电到桌面的完整链路，以及为什么长这样）、
> **每件产物里面是什么**（组成 / 构建 / 怎么验证）。
> 构建命令 → [PIPELINE.md](PIPELINE.md)；刷写操作 → [FLASHING.md](FLASHING.md)。

---

## 一、启动链原理

### 1.1 为什么不是"主线内核直接刷进 boot"（设计动机）

高通设备的 Android 启动链是**验签的封闭链**：XBL → ABL 只认签过名的镜像，且 ABL 对
"Linux 内核"的形态有隐含假设。实测把主线内核直接交给 ABL：`Start Kernel` 后极短时间
内必死——ABL 的内核补丁器（KEP）特征扫描**误匹配 zboot 内核形态**，在退出版本引导
服务时往活内核上写跳转导致秒崩。这条路在本机上被多轮判别实验钉死，也是整个
「Mu 链载」方案存在的理由：**在 ABL 和内核之间插一层标准 UEFI**。

```
XBL（原封）→ ABL（原封）→ boot_b: Mu-UEFI（我们构建）──标准 UEFI 引导──→ ESP 上的内核（EFI stub）
                               ↘ recovery_a: ESP = 备援引导（MsBootPolicy 标准路径）
                                                         ↓
                                            root=/dev/sda22（userdata, ext4, pmOS rootfs）
```

设计要点：

- **只动三条腿**：boot_b（Mu 固件）、recovery_a（ESP）、userdata（rootfs）。
  xbl / abl / tz / modem / dtbo_b / vendor_boot / super / persist / modemst 全部原封
  （stock 验签链 + ABL 的 DTB 来源，细节禁令见私有工作区仓）。
- **GPT 零改动**：分区布局复用 stock slot 表；recovery_a 借用作 ESP（stock 的
  recovery 语义在这条链上不用），boot_b 之外多一条标准引导路。
- **Mu = 全功能 UEFI 固件**：设备树（FdtBlob）直接烤在固件 FV 里，出厂自带 SMBIOS
  （`MEIZU 20` / `m2381` 命名串的来源），然后按 UEFI 标准加载 ESP 上的
  `\EFI\BOOT\BOOTAA64.EFI`（= 内核本体）。
- **内核以 EFI stub 接管**：从 UEFI 拿内存映射与运行时服务，cmdline（`root=/dev/sda22`
  烤在内核里，**无 initramfs**）直挂 userdata 上的 pmOS rootfs → systemd → plasma-mobile。

### 1.2 链上每一环怎么坏、怎么救

| 环节 | 死法 | 对策 |
|---|---|---|
| ABL 重试计数耗尽 | ~7 次开机后自动落 fastboot | 不是坏事，是救你；循环时 `fastboot flash misc misc-zero.img` 清 bootonce |
| boot_b（Mu）坏 | 黑屏 / 卡 ABL | fastboot 重刷 boot_b；兜底 = 锚 t-b2 |
| recovery_a（ESP）坏 | Mu 活但找不到内核 | fastboot 重刷 recovery_a；兜底 = 锚 esp-v4d |
| 内核/模块错配 | 起来但半身不遂 | 两腿铁律（§2.2），同轮配对 |
| userdata 坏 | 内核活、rootfs 起不来 | 重刷 rootfs 三件套 |
| 全死（USB 全灭） | 9008/EDL | 最后通道，线刷（高危，谨慎） |

救砖阶梯全量 → [FLASHING.md](FLASHING.md) §6。

### 1.3 两条版本定律（发布为什么不会乱）

- **两腿铁律**：换内核 = ESP（`BOOTAA64.EFI` = vmlinuz）+ apk（`/usr/lib/modules`）
  **同轮完成**。单刷一腿 = 引导旧内核配新模块（或反之），两种半死状态。
- **#N = pkgrel + 1**：内核包的 pkgrel 烤进 `uname -v` 的 `#N`，上机第一验证点；
  Release 三件（boot / recovery / rootfs）**同轮配对**，rootfs 里烤的模块包必须与
  ESP 里的内核同版。

---

## 二、镜像解剖（四件产物）

### 2.1 boot_b：`mu-rNN-<sha8>.img`（Mu-UEFI 固件，~1.1MB）

| 组成 | 是什么 |
|---|---|
| BootShim | ~4.7KB 预算的 AArch64 汇编跳板：把固件本体搬到运行地址、准备栈与 CPU 状态后跳进 Mu 入口（改动受硬约束，见私有仓硬定律） |
| Mu FD（m2381Pkg） | Mu-UEFI 固件本体：DXE 驱动族（块设备 / 文件系统 / 显示 / 平台）+ UEFI 引导管理（扫到 ESP 的 `BOOTAA64.EFI` 并加载） |
| FdtBlob | **我们的设备树**（`sm8550-meizu-20.dtb`）烤在固件 FV 里——**内核唯一 DT 源** |

- 构建：Mu 树（fork Project-Silicium/Mu-Silicium，分支 `meizu20-mars-port`）经
  `build-mu.sh`。**触发条件 = 仅 DTS 变了**（内核纯代码改动不用重编 Mu）；
  FdtBlob 必须从**同一个内核 apk** 抽取（verify.sh 第 1 项对拍，防"新固件配旧设备树"
  事故）。
- 验证：文件名 sha8 = dd 读回对拍；上机后 `/chosen` 有 UEFI 内存映射 = Mu 完整活到
  内核。

### 2.2 recovery_a：`esp-recovery-vNN.img(.gz)`（100MiB FAT32 ESP）

| 组成 | 是什么 |
|---|---|
| `\EFI\BOOT\BOOTAA64.EFI` | **内核本体**（vmlinuz-efi，EFI stub 形态）——分区内就这一个关键文件 |
| 分区本身 | FAT32，100MiB，mformat 制作（mkfs.vfat 有坑，实测 fail） |

- "recovery" 只是分区名（stock 语义），这条链里它就是普通 ESP；Mu 经 MsBootPolicy
  的可移动介质标准路径扫到它，构成 boot_b 之外的备援引导。
- 构建：`build-esp.sh`（从内核 apk 抽 vmlinuz-efi 灌入）；每版 +1（vNN），sha 记
  [MANIFEST.md](../MANIFEST.md)。发布 gz 化（100MiB 裸镜像超 GitHub 单文件上限），
  刷写 / verify 自动解压。

### 2.3 userdata：`meizu-meizu20-rNN.img(.gz)`（pmOS rootfs，8G，首启自动扩满）

| 组成 | 是什么 |
|---|---|
| Nura（postmarketOS edge）基础系统 | Alpine musl 用户态 + systemd + plasma-mobile |
| linux-meizu-meizu20 apk | 内核模块腿（与 ESP 同轮） |
| device-meizu-meizu20 apk | 用户态胶水全量（见 2.4） |
| firmware-meizu-meizu20 apk | 厂商固件 blob（见 2.4） |

- 构建：`build-rootfs.sh` = pmbootstrap install（本地 pmaports 三包烤入）→ 8G ext4 镜像，
  发布 gz 化（同 GitHub 上限）。
- 出厂形态：登录 `user` / `1234`；首启自动扩容占满整盘；**蜂窝 / NFC 用户态默认摘除**
  （设备包随包 mask——省电与稳定性的拍板形态，非功能缺失，见 [README](../README.md) 状态表）。

### 2.4 机上 apk 三包（构成明细）

| 包 | 内容 | 什么时候动 |
|---|---|---|
| **linux** | `boot/vmlinuz-efi`（灌 ESP 用）+ 全部内核模块；`KBUILD_BUILD_VERSION=pkgrel+1` 实现 #N 定律 | 每轮内核（`--bump`） |
| **device** | 音频（UCM / 拓扑 / 路由守卫重试环 / 默认 sink 自愈环）、传感器（barrier + udev 触发）、触控（定向绑定 service）、NFC/蜂窝用户态摘除 mask、boot 噪音治理（PAM stub / ddcutil / pulse drop-in）、Discover 后端依赖 | 用户态配置变更 |
| **firmware** | Cirrus 双功放固件（per-amp）、ath12k 板卡数据、视频硬解 vpu 固件等 blob（sha512 钉在 APKBUILD） | 固件更新（罕见） |

---

## 三、内核 fork 里有什么（相对主线 7.3 的增量速览）

> 完整逐 commit 分类与上游化候选 = 私有工作区 carry-list；政策 = 养肥就进主线。

- **板级 DTS**（`sm8550-meizu-20.dts`）：按原厂 DT 忠实重建（factory-first 翻译到主线
  bindings；固件合约面除外）；**fsa4480 摘除**（板上未焊，摘掉解锁 typec 栈点亮）。
- **自写/改驱动**：AW8697 震动（ff-memless × CONT 闭环，stock 真值烧缺省）、pm8008
  双颗 supply-only（stock 全 DT 零 IRQ 布线，只挂 regulator）、面板驱动、相机
  camss/cci 腿（挂起态）。
- **config 要点**：`CONFIG_PSI=y`、`ZRAM=m`（lzo-rle）、`NF_TABLES` 全家 =m、
  binder/docker 系 =m、BT RFCOMM/BNEP =m、zboot。

---

## 四、验证链（一件产物从构建到上机怎么自证清白）

`verify.sh` 四件套：**dtb ↔ FdtBlob 同源 sha 对拍 ｜ tarball 扫残留 ｜ zram.ko 在列 ｜
ESP ↔ apk 同源**。上机第一验证点 = `uname -v` 的 `#N`（= 内核包 pkgrel+1）；
刷写唯一证据 = **dd 读回 sha**（刷写时长不算证据）。全流程 → [PIPELINE.md](PIPELINE.md)。
