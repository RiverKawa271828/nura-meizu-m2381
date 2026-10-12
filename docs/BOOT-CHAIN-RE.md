# 启动链逆向全集：XBL → ABL → Mu-UEFI（魅族 20 / m2381）

> **定位**：把散在私有工作区（1.3 万行实验日志 + ABL 静态逆向两篇）的启动链逆向
> 结论蒸馏成一篇**自包含公开文档**——给想理解这台机器怎么跑起来的人，以及想在
> 其他高通零售机上复现同款路线的人。全部结论来自 2026-09-21 → 10-12 的实机判别
> 实验与纯静态逆向，每条带证据链（地址 / 实验编号 / 对照结果）。
> 链路速览与镜像解剖（"是什么"）→ [DESIGN.md](DESIGN.md)；本文管"为什么长这样"
> 与"怎么逆向出来的"。复现脚本 → [tools/abl-re/](../tools/abl-re/)。
> **政策**：本文只含事实与方法论。stock 固件二进制本体与其派生转储（全量反汇编、
> 字符串表、解包产物）**不随本文分发**，理由与边界见 §8。

---

## 0. 一页看懂

```
XBL（sbl1 → xbl_sec[EL3] → xbl_core[EDKII-UEFI]）
  └─ 强制验签加载 → ABL（slot b，stock LinuxLoader）      ← 零售机 eFuse 烧死，不可替换
       └─ gunzip boot payload → 0x80080000 → 关 MMU → blr（x0=DTB，标准 Linux 协议）
            └─ boot_b：BootShim(~144B) + Mu FD(3MB)        ← 我们构建的 UEFI 固件
                 └─ 拷 FD → 链接地址 0xA7100000 → Mu SEC/DXE/BDS
                      └─ MsBootPolicy 扫全部 FAT 卷 → recovery_a: \EFI\BOOT\BOOTAA64.EFI
                           └─ 内核 EFI stub（DTB = Mu FV 内的 sm8550-meizu-20.dtb）
                                └─ root=/dev/sda22 → pmOS rootfs → systemd → phosh
```

五条硬结论（每条后文有完整证据链）：

1. **主线内核直刷 boot 必死**（§2）：而且不是尺寸问题——ABL 根本没有任何尺寸门
   （§5.4）。死因至今未定谳，但四堵墙 + 第一秒零观测 = 既无法调试也无法绕过。
2. **ABL 可以被"骗"着加载任意 arm64 形态的 payload**（§3/§4）：它只认「gzip 成员 +
   arm64 头」这个壳，UEFI 固件伪装成内核过门——这就是 Mu 链载方案的全部支点。
3. **ABL 的交接语义是标准 Linux boot 协议**（§5.5/§5.6）：ExitBootServices → 纯
   cache 维护 → 关 MMU → `blr`，x0=DTB。无重定位阶段、无内存清零、无映射拆除。
4. **KEP 是 Mu 链自带的雷，不是 ABL 的**（§3.3）：高通血统的 winload 补丁器误匹配
   zboot 内核形态，EBS 时往活内核写跳转 → Data Abort。关掉即绿。
5. **零售机的唯一活路 = 不碰 stock 验签链**：只动 boot_b / recovery_a / userdata
   三条腿（§2.1 对照实验钉死：解锁态不豁免 XBL→abl 镜像认证）。

---

## 1. Stock 启动链解剖

### 1.1 XBL 血统链（外来情报 + 本机结构互证）

链序 = **sbl1 → xbl_sec（EL3）→ xbl_core（EDKII UEFI 环境）→ LinuxLoader.efi**。
最后一级"ABL"并不是独立固件，而是**单个 LinuxLoader PE 模块包在 FV 里、外面套一
层 ELF 头**——我们对 abl 分区解包的结构与 linux-msm `xbltools` 的结论完全吻合。

### 1.2 abl.img 容器解剖（本机静态解包实测）

```text
abl_a.img (1MB)
├── ELF32 头（QCOM PIL 风格包装，machine=ARM，entry 0x9FA00000 为占位无效值）
├── PH1 PT_LOAD：file 0x1000-0x33000（200KB）→ DRAM 0x9FA00000
│   = UEFI Firmware Volume（FFS2 GUID 8c8ce578-8a3d-4f1c-9935-896185c32dd3）
│   └── FFS 9e21fd93（APPLICATION）→ LZMA GUIDed section
│      （ee4e5898-3914-4259-9d6e-dc7bd79403cf，0x2CEB4 → 0x950C8）
│       └── 内层 FV → 单一 PE32+ 模块 "LinuxLoader"（601KB，AArch64）
│           = ABL 全部逻辑（高通 QcomModulePkg 应用）
└── PH2：QCOM 哈希/签名段（v7 格式 @0x33000）
```

要点：

- **payload 不是加密，只是 LZMA 压缩**（熵 7.64）。解包后 DEBUG 字符串全留——
  这是纯静态逆向可行的前提。
- 构建路径串：`/home/flyme/NewFlyme/Code/Qcom_13_m2381/kernel_platform/bootable/
  bootloader/edk2/QcomModulePkg/...`，变体 `abl-user`。
- PE 节表 `.text` 的 VA = 文件偏移（ImageBase=0）——**全文所有地址因此可直接按
  偏移复核**（llvm-objdump / 本仓 `tools/abl-re/disfunc.py`）。
- 同代性验证：所用 abl 来自 9008 全分区备份（Flyme 12.6 / Android 16），其
  boot_a 内核与 init_boot ramdisk 对设备现役解包基准逐字节一致；另与 eng 10.2.0.0A
  工程件交叉验证（DEBUG 串同集，无新增装载诊断）。abl_a ≠ abl_b 仅尾部签名区，
  代码段一致。

### 1.3 Android boot v4 交付面

Flyme 12.6 为 boot header v4 分组交付（OTA 内 `ota-type=AB`、`pre-device=meizu20`）：

| 件 | 内容 |
|---|---|
| `boot.img` | 只有 kernel（5.15 GKI，zboot 压缩 PE），无 ramdisk |
| `init_boot.img` | 无 kernel，generic ramdisk（GKI 件） |
| `vendor_boot.img` | vendor ramdisk（~339 个 .ko + fstab.qcom）+ DTB（517509B）+ bootconfig |
| `dtbo.img` | 面板/触控等 overlay（本机 `ro.boot.dtbo_idx=9`：goodix brl-d 触控 + BOE AMOLED cmd-mode DSC 面板） |
| `vbmeta.img` | AVB 元数据（见 §2.5） |

---

## 2. 四堵墙：主线内核直刷为什么死（判别实验史）

> 目标很朴素：把主线内核打成 boot payload 直接喂给 ABL。多轮判别实验（2026-09
> 下旬）的结果是四堵墙 + 一条终审记录。这些实验的完整过程在私有实验日志，此处
> 收结论与可复现的判别方法。

### 2.1 墙一：XBL→abl 镜像签名认证（eFuse 层，不可换ABL）

- **实验 A（换 ABL）**：ROCKNIX 的重签名 `abl_signed-SM8550.elf` 经 EDL 刷入
  abl_b（回读逐字节一致）→ 复位 **t+2s 进 900E 并周期循环** → 出厂件写回
  恢复正常。【实测钉死】
- **实验 B（单字节判别）**：出厂 abl_b 签名表区域内翻转 1 字节（@0x33100）→
  fastboot 刷入 → **900E @24s**；写回出厂件 → 正常开机（adb t+12s）。【对照闭环】
- **结论**：**解锁态（orange，fastboot unlocked）不豁免 XBL→abl 镜像认证**。
  sec-boot 是 eFuse 熔丝层、不可逆；常见的"解锁工具"（煤油工具箱类）走的是 EDL
  改 private 分区（@0x11000 写 "LOCK"+256B 解锁码等）= **ABL/AVB 层**解锁，与
  QC sec-boot 熔丝无关。qtestsign 文档亦明示：test 签名仅对未熔丝工程机有效，
  量产机 "firmware secure boot permanently enabled"。
- **推论**：任何方案都不能替换 ABL 本身；ABL 只能当"别人家的 bootloader"用，
  我们能控制的入口只剩 boot payload（boot_b）与它加载的对象。

### 2.2 墙二：BoardDtMatch 板级匹配（内容级，非密码学——已破案）

ABL 加载 boot 时对 DTB 做**板级内容匹配**，全不匹配才拒载。反汇编定案（§5.1
方法论产出）：

```text
GetBoardDtMatch (0x37934)                        ← 遍历 DTB blob 条目逐条步进
└─ BoardDtMatch (0x37c08，10.5KB，stock + 魅族魔改，自递归 @0x38f3c)
   ├─ stock 段：qcom,msm-id / qcom,board-id / qcom,pmic-id 匹配打分
   └─ 魅族新增段 @0x38a84-0x38c14：
        fdt_path_offset(dtb, "/")                ; 0x3eee0
        fdt_getprop(root, "meizu,board-id")      ; 0x3f280（len≥1，8 字节对齐 = 两个 BE u32）
        DtbProjectId = fdt32(prop[0])；DtbBoardId = fdt32(prop[1])
        对比硬件值 GetMeizuProjectId(0x18840) / GetMeizuBoardId(0x18660)
          ← UEFI 变量式查询 "meizu_project_id" / "meizu_hw_id"（ERF 背书；
             meizu_ReadDataFromErf @0x18d20）
        全等 → 置 exact-match 位；硬件值读不到(0) → 回退分支要求
               ProjectId==1 && BoardId==0xF
全部条目不匹配 → "No match found for Soc Dtb type" → 拒载（返回 0）
```

- **性质判明**：不是哈希/签名校验，是**内容匹配**。缺 `meizu,board-id` 属性本身
  只打 DEBUG log 然后落回 stock 匹配——但主线 DT 同样没有 qcom,msm-id/board-id，
  所以整体零匹配仍被拒。
- **上机实证（T8a）**：工厂 DTB 经 fdtput 字节级重写 + 根节点补属性 → **通过
  ABL**，槽 b 起到用户态。"内容匹配非哈希"成立。
- **绕过配方**（主线 DTS 根节点补工厂同值属性；主线内核不解析这些属性，无害，
  纯为过 ABL）：

```dts
/ {
    qcom,msm-id    = <0x218 0x20000 0x207 0x20000 0x207 0x10000 0x218 0x10000>;
    qcom,board-id  = <0x10008 0x00>;
    meizu,board-id = <0x01 0x0f>;   /* project_id=1, board_id=0xF（设备实测，
                                       与 ABL 回退分支常量逐字互证） */
};
```

- **新边界（T8 系列后续）**：匹配**之后**还有一段 DTB 加工逻辑存在**结构依赖**——
  主线 sm8550-mtp DTB（补齐三属性，130K / 170K / 垫到 517506B 三种形态）全部
  立即被拒；排除法钉掉尺寸（T8d 证伪）、`__symbols__`（T8c 证伪）、root 属性
  （与工厂逐值相同）。嫌疑锁定下游结构约定：`soc` vs `soc@0` 节点名（ABL 内
  `fdt_path_offset("/soc/...")`）、`memory/ddr-regions`、顶层 `sram@17D09400`、
  `idle-states`——ABL 内存账本/补丁路径的宿主。downstream 基底做节点手术同样
  被拒（T7，伤到同族结构）。⇒ **直刷路线里"伪造工厂 DT 结构"成本不可控**。
- 另：overlay apply 失败 = 非致命（0x7b54 → 0x7c0c 成功失败汇合，仅 DEBUG 打印），
  "dtbo 改写拒"另有门槛，与 overlay apply 无关。

### 2.3 墙三 + 墙四：dtbo 原封依赖、第一秒无观测

- **墙三**：dtbo 与 stock 面板/触控驱动族强耦合，原封才稳；自组 vendor_boot /
  dtbo 的每一步都要重验（含 §6.4 的 0x80 私有类型问题）。
- **墙四（最致命）**：**交接后第一秒没有任何观测通道**——无 UART 引出、USB 未及
  初始化、logfs 环默认关（§6.2）、ramoops 会被内核侧重建清掉（§6.3）。死给你看
  但不告诉你为什么。

### 2.4 直刷终审记录

主线内核直刷 boot payload：**ABL 交接成功（`Start Kernel` 打印实证）后 ~0 秒
panic**；DT / cmdline / 装载落点 / 交付形态（v2/v4 全部形态）**7 组合逐一排除**；
死因未定谳（唯一的卡点就是墙四）。后续 ABL 深度逆向（§5）补了刀：**ABL 侧没有
任何尺寸门、没有重定位阶段**（旧"死于 ABL 重定位"归因被反汇编推翻），死亡在
`blr` 之后或 XBL/TZ 侧的静默路径。⇒ **直刷路线正式关门，不是修修补补能救的。**

### 2.5 AVB 实测架构（顺带破案三件）

avbtool 解析 vbmeta_a（flags=0，OEM key sha1 `030956f3…`）：

```text
CHAIN boot        (rollback loc 3, OEM key)   ← boot 尾部 AVBf footer = 内嵌签名 vbmeta 块
CHAIN recovery    (rollback loc 1, OEM key)
CHAIN vbmeta_system (rollback loc 2, Google key)
HASH dtbo         (3658899B)
HASH init_boot    (2039808B, digest d0fb4e44…)
HASH vendor_boot  (10952704B)
PROP com.android.build.*.{fingerprint,os_version,security_patch}
     = meizu/meizu_20_CN/meizu20:16/BQ2A.251016.001-BP2A.250605.031.A3/…
```

破案三件：① 早期记录的"com.android.build 指纹区"= vbmeta 的 **PROP 描述符**，
不在 vendor_boot 镜像内；② "分区尾 AVBf footer（疑 OEM 签名）"= **CHAIN 分区的
内嵌 vbmeta 块**（stock libavb 机制，非魅族私有）；③ 自建镜像加 avbtool footer
能过，是因为**解锁态 allow-verification-error 容忍签名失败**——不是验签放水。
vbmeta_a 为原厂未重签（init_boot HASH digest 对原厂件 sha256(salt+content)
逐字节吻合）。

### 2.6 init_boot 槽不对称之谜（未全破，结论修正过）

现役 slot a 的 Magisk 版 init_boot 同时违反主 vbmeta HASH digest 与自身尾部
footer 的 digest，仍天天开机；而无旗标的 Magisk 件刷 slot b 即死、原厂件刷
slot b 可活。⇒ 死亡机制是**槽 a 宽松 / 槽 b 严格的执行不对称**，不是"init_boot
有独立内容校验"的绝对规律。嫌疑：misc `\x01roms` 选择器 / devinfo 逐槽标志 /
ABL 槽选择代码的分支差异（未继续深挖——我们的最终链路不触碰 init_boot）。
注意 ABL 里 `Device is unlocked, Skipping boot verification`（0x6d9eb）只是
orange-state 提示文案，不是校验逻辑本体。

---

## 3. 破局：在 ABL 和内核之间插一层标准 UEFI

### 3.1 候选路线全表（判决与理由）

| 路线 | 判决 | 理由 |
|---|---|---|
| 主线内核直刷 boot | **死**（§2） | 四墙 + 零观测 |
| 替换 ABL（ROCKNIX 等） | **死** | §2.1 验签熔丝，零售拒签 |
| ROCKNIX UEFI 裸跳（BootShim 借道） | 死 | 其内层 PE 需要外层 SEC 给上下文，裸交接不起 |
| U-Boot 作为 boot payload | 理论可行，未走 | 过 ABL 后自选 DT，不受 BoardDtMatch 约束；但当时无现成可用的 m2381 U-Boot |
| GKI/下游内核混合路线 | 否决 | 用户拍板"只做主线"（2026-09-25） |
| **Mu-UEFI 链载（Project-Silicium 系）** | **✅ 现役** | silime 的 mars（魅族 20 Infinity）已证明 ABL 肯加载 UEFI 固件形态 payload；标准 UEFI 环境给内核最干净的交付面 + framebuffer 控制台可观测 |

### 3.2 Project-Silicium 的正确打开方式（和一次违反的代价）

上游 Mu-Silicium（Project-Silicium）的移植模式：每设备一个 `<device>Pkg`，其中
`Binaries/<device>/` 放**从该设备自己的 uefi/xbl 分区里用 UEFIReader（WOA-Project）
提取的 UEFI 模块**（nuwa=小米 13、qrd8550=高通参考设计等 75+ 套），平台胶水全在
里面。我们最初违反了这一模式：借 nuwa 的整套模块给 m2381 → **显示七连崩**，根因
正是小米的 PMIC 供电轨/GPIO/时钟胶水与本机不符。

转机：silime 的 **mars**（Meizu 20 Infinity，同代 SM8550、同族 BOOT.MXF 构建时代）
的 blob 在 m2381 上能活（§3.3 判决链）。最终 m2381Pkg 仍用 `Binaries/mars/`（出处
Infinity 硬件）——**同族代用成立**。备援资产：我们从本机 9008 备份的 uefi_a 分区
（5MB PIL ELF → 两个 gzip 嵌套 FV，高通自定义 gzip GUID `1d301fe9`，**不是**
LZMA/LZMAF86）完整提取了 **96 个本机 UEFI 模块**（DisplayDxe 本机版 323,584B、
QcomBds、PmicDxe/ClockDxe/RpmhDxe 等平台胶水全家；93/95 个模块靠 PE 内嵌
CodeView RSDS .pdb 路径自动还原名字）——若未来 mars blob 出兼容性问题，本机原生
模块集是现成的替补。

### 3.3 KEP 破案（T-A 系列判决链，2026-09-29）

Mu 链最初也是崩的，崩因值得单独记——它花了整个 T-A 系列：

```text
T-A   原版 Mu-mars.img × 我们的 ESP      → 滚日志 45s 冻结（RELEASE 无 DEBUG）
T-A2  原版源 + 只改分辨率 1080x2400      → 可读控制台立功：Synchronous Exception @0xC2D62FB0
T-A3  原版 + FB PCD + DEBUG 转储        → 内核已被完整加载并跑起来，崩在
        BdsDxe+0x5E48 = PatchTransferToKernel（Winload.c:90）
        ← KepExitBootServicesHook（KernelErrataPatcherLib.c:120）
T-A4  原版 + FB PCD + KEP 构造器 return → 内核完整开跑（内存图/CPU/GIC/时钟全过）
T-B1  移植 mars-port + m2381 DTB + KEP off → m2381 上 pmOS 内核启动（8 企鹅 fbcon）
T-B2/r19+ESP v4d                        → pmOS 图形会话完整启动（终判 ✅）
```

**根因 = KEP（KernelErrataPatcher）**：高通 LA 血统的 winload 补丁器，随 mars
移植的 BdsDxe 进了 Mu 链。ReadyToBoot 时钩掉 `gBS->AllocatePages` /
`ExitBootServices`，对 EfiLoaderCode 分配做 winload 双指令特征扫描 → **我们的
zboot 内核代码误匹配** → AllocatePages 时就被误打"平台勘错补丁"（WARN 级日志被
ERROR-only 过滤），EBS 时 `PatchTransferToKernel` 往活内核里写跳转 + shellcode →
Data Abort。silime 自己的设备没事 = 他的内核不误匹配。
**修复 = KEP 构造器直接 return（KEP off）**，随 m2381Pkg 固化。
**勘误**：stock ABL 里没有 KEP（全二进制字符串普查零命中 errata/winload）——
这颗雷是 Mu 链从高通血统里继承的，不是 ABL 的。

### 3.4 m2381Pkg 终形态（对 silime mars 的 8 项语义增量）

① DTB 换 m2381（`sm8550-meizu-20.dtb`，内核唯一 DT 源）② FB PCD 1080x2400
③ SSU 键 ④ **KEP 构造器 return（根因修复）** ⑤ 日志级别 0x80001846
⑥ SMBIOS `MEIZU 20` / `m2381` 命名串 ⑦ UfsWakeDxe 未挂（保留代码）
⑧ 更名 `m2381Pkg`（命名先例 nx729jPkg = 型号命名；m2381 无公开词代号）。
构建：`build_uefi.py -d m2381 -r RELEASE` → `Mu-m2381.img` → 刷 boot_b。

---

## 4. BootShim 与 Mu 如何工作（源码导读）

> 本章对应公开仓 [Mu-Silicium fork](https://github.com/RiverKawa271828/Mu-Silicium)
> 分支 `meizu20-mars-port`：`BootShim/BootShim.S` + `Platforms/Meizu/m2381Pkg/`。
> 全部为我们的/上游的开源代码，可直接对照源码读。

### 4.1 BootShim.S 逐段解读（二进制本体 ~144B）

ABL 跳进的是 boot payload 的内核成员——所以这个成员必须长得像"内核"。BootShim
就是 144B 的伪装皮 + 搬运工：

```asm
_Head:                      ; [0x00] ABL 跳转落点 = K
  adr   x1, _Payload        ; x1 = FD 本体的运行时地址（自定位，无固定偏移假设）
  b     _Start

_StackBase:  .quad FD_BASE  ; [0x08] ← arm64 Image 头 text_offset 槽位
_StackSize:  .quad FD_SIZE  ; [0x10] ← image_size 槽位（ABL 拿它做 §5.4 校验#8）
  .quad 0 / 0 / 0 / 0       ; flags + reserved
  .ascii "ARM\x64"          ; [0x38] ← ABL 两处校验的魔数（0x9a24 / 0x7614）

_Start:                     ; [0x40] 真代码
  mov   x4, x1              ; x4 = 拷贝源（payload 里的 FD 起点）
  ; DISABLE_GUNYAH_WATCHDOG=1：SMC 0x86000005（vendor-hyp owner，fast call）
  ;   arg=2 (WDT_CTRL_DISABLE)。防 ABL 留下的 Gunyah VM 看门狗在慢 UEFI 初始化
  ;   期间超时咬人。SMC 无返回值检查。
  ldr   x5, =FD_BASE        ; 0xA7100000 = FD 链接地址（Mu MemoryMapLib 同值）
  cmp   x4, x5 / beq _Entry ; 已在链接地址（直跳形态）则免拷
  ldr   x6, =FD_SIZE        ; 3MB
_CopyLoop:
  ldp   x2, x3, [x4], #16   ; 16B 步进拷贝 FD → 0xA7100000
  stp   x2, x3, [x5], #16
  subs  x6, x6, #16 / b.ne
_Entry:
  br    x5                  ; 跳进 Mu SEC
```

设计约束：拷贝**必须发生**——ABL 把 payload 解压在 0x80080000（staging 窗，§5.3），
而 FD 的链接地址在 0xA7100000；跳转前这 3MB 在 ABL 语义下可读（§5.6），但 staging
窗不是长久居所。`m2381.toml` 配置：`requires_kernel_header=true`（伪装头）、
`disable_gunyah_watchdog=true`、`base=0xA7100000`、`size=0x300000`。

### 4.2 交付打包与 ABL 侧通过性

打包（`build_uefi.py`，`Resources/Configs/m2381.toml`）：**BootShim + Mu FD 拼接
为内核成员 → gzip → Android boot v4 头**（`kernel_compression="gzip"`、
`header_version=4`、`append_dtb=false`——DTB 烤在 FV 里，不 append）。ABL 侧的
通过性由 §5.4 的校验表背书：gzip 魔数 ✓、arm64 魔数（shim 伪装头）✓、
image_size=FD_SIZE(3MB) ≤ 缓冲上限(~83.5MB) ✓、appended-DTB 检查 N/A ✓。
**这就是"UEFI 固件冒充内核"的全部机关**——ABL 对内核成员的理解止步于
gzip + arm64 头 + 尺寸数学（§5.3），跳进来的到底是什么它既不知道也不关心。

### 4.3 Mu FD 内部（SEC → DXE → BDS → 内核）

```text
SEC（SiliciumPkg/Sec，FD 0xA7100000 起；SEC Heap/栈/MMU 页表在 MemoryMapLib 预留区）
└─ DXE（APRIORI: DxeMain/PCD/EnvDxe → ~86 个 INF）
   ├─ 我们/开源族：CpuDxe、ArmGicDxe、TimerDxe、Metronome、RuntimeDxe、
   │  DtPlatformDxe、IortDtDxe、SmbiosDxe + SmBiosTableDxe（MEIZU 20/m2381 串）、
   │  UfsWakeDxe（m2381Pkg 自带，未挂）
   ├─ Binaries/mars/ blob 族（silime 从 Infinity 提取的平台胶水）：
   │  SmemDxe、DALSYSDxe、PmicDxe、ClockDxe、RpmhDxe、UFSDxe、USB 全栈…
   └─ 显示：FrameBufferSerialPortLib（崩溃可读控制台的物理基础）+ 显示驱动
└─ BDS：扫块设备/FAT 卷 → MsBootPolicy 可移动介质标准路径试
   `\EFI\BOOT\BOOTAA64.EFI` → LoadImage/StartImage
```

关键机制：

- **FdtBlob 烤在固件 FV 里**（`m2381Pkg/FdtBlob/sm8550-meizu-20.dtb`）：内核的
  唯一 DT 源。经 `gFdtTableGuid` 交付给 EFI stub；上机 `/chosen` 出现
  `linux,uefi-mmap-*` + `uefi-system-table` = Mu 完整活到内核的铁证。**DTS 变了
  才需要重编 Mu**，内核纯代码改动不动 boot_b。
- **内存地图**（m2381Pkg MemoryMapLib 节选）：FD Reserved 0xA7000000(1MB) /
  **UEFI FD 0xA7100000(3MB)** / FD Reserved 0xA7400000(2MB) / Info Blk、页表、
  Log Buffer、UEFI Stack、SEC Heap / FV Region 0xA7AD9000(4MB) / UEFI RESV
  0xA7ED9000 / **Kernel 0xA8000000(256MB, Reserv)**——最后这块是 Mu 自己的
  "给内核留的窗"，§5.7 的 0xA8000000 栅栏疑云与它相邻。
- **被动固件定形（2026-09-29 定性）**：Mu 只做枚举硬件/BlockIo/FAT/加载
  `\EFI\BOOT\BOOTAA64.EFI`/交内存图与 DT/EBS 干净退出；OS 层一切在 ESP+rootfs。
  换内核不动 Mu、动系统不动 Mu——与上游其他可用设备同形态。

### 4.4 ESP 与内核侧接应

- **ESP = recovery_a 分区借名**（stock 语义在这条链上不用），100MiB FAT32、
  **512B 扇区**、mformat 制作。分区内关键文件只有一个：
  `\EFI\BOOT\BOOTAA64.EFI` = 内核本体（vmlinuz-efi，zboot zstd 自解压 PE）。
  **MsBootPolicy 只试标准路径**——文件放 ESP 根目录 = "Failed to Find an OS"
  （T-B2 实测教训）；mkfs.vfat 版 ESP 亦必 fail。
- **内核以 EFI stub 接管**：从 UEFI 拿内存映射与运行时服务；cmdline 烤在内核里
  （CONFIG_CMDLINE：`root=/dev/sda22` 起步，无 initramfs 直挂 userdata 上的
  pmOS rootfs；随轮追加 `no_console_suspend` 等）。上机第一验证点 =
  `uname -v` 的 `#N`（= 内核包 pkgrel+1，两腿铁律见 [DESIGN.md](DESIGN.md) §1.3）。

---

## 5. ABL 装载与 handoff 深度逆向（2026-09-25 轮全量结论）

> 对象：stock LinuxLoader PE32+（VA=文件偏移）。本轮回答四个问题：装载地址由什么
> 决定（Q1）、"重定位字节数"由什么决定（Q2）、尺寸/范围校验全集（Q3）、handoff
> 时刻 staging 窗可读性（Q4）。全部纯静态、零设备操作，地址可按偏移复核。

### 5.1 方法论（为什么纯静态就能打穿）

```text
9008 全分区备份的 abl_a.img
  → tools/abl-re/extract_fv.py（ELF→FV→LZMA→PE32 模块导出）
  → strings 全量普查（DEBUG 串即路标：QcomModulePkg 的日志串覆盖全部关键路径）
  → xref.py（ADRP+ADD 字符串引用反查 + .data 指针扫描，定位函数身份与调用点）
  → disfunc.py（函数级反汇编 + ADRP+ADD 自动注解字符串内容）
  → 全量反汇编交叉复核（llvm-objdump；常量普查 = mov/movk 链重建 + adrp +
     32/64 位 literal 池 + .data 全扫）
```

DEBUG 字符串是最高效的路标：QcomModulePkg 每个关键分支都有日志串，先抓串再反查
xref，函数身份基本自动定。两个坑：① `orr` 拼装的大常量（0x80080000）在
mov/movk/adrp 里都不出现，必须跟到常量池（0x74f94）才能看到 0x00080000；
② libavb 类无日志的库函数只能靠结构特征（GUID 表、协议调用形状）定。

### 5.2 主流程地图（LoadImageAndAuth → blr，一次读完的证据链）

```text
0x2e048 LoadImageAndAuth
  └ AVB(0x460a8 avb_slot_verify) → boot 镜像读入 → AllocatePool 缓冲
    （大小 = vbmeta HASH descriptor 的 image_size；地址 = UEFI 池分配器运行时决定）
0x6a18 UpdateBootParamsSizeAndCmdLine（超大函数，含最后跳转）：
  0x6c1c  GetImage("boot") → 缓冲/大小
  0x6d0c  解析 boot 头 v0-v2（kernel_size/ramdisk_size/second_size/page_size）；
          v3/v4 走 vendor_boot 取件，0x7480 汇入同一布局算术
  0x70b8  QueryMemoryBase(0xbe88)：遍历 RAM 分区表取最低基址 → "Memory Base
          Address: 0x%x"（stock = 0x80000000；失败 → "Base memory not found!!!"）
  0x70fc  IsGzip(0x5029c)：成员头三字节 == 1F 8B 08？
  0x7110  CompareMem("UNCOMPRESSED_IMG") → 跳过 20B 包装标头
  0x7134  IsArm64Image(0x9a24)：[成员+0x38]==0x644d5241("ARM\x64")？否则置 patched 旗标
  0x7144  GetVariable("K", GUID 882F8C2B-9646-435F-8DE5-F208FF80C1BD, 8B) ×2
          → 都成功 = 装载基址覆盖路径（stock 无此变量，不走）；否则
  0x71d8  默认值路径（stock 实走）：
            K    = MemoryBase | 0x00080000（.text 常量池 @0x74f94；patched 时
                   改 | 0x00008000 @0x74fa0）——orr 拼装，无直接 movz/movk
            RdEnd = MemoryBase + 0x05600000（0x74f98；备用 +0x03C00000 @0x74f9c）
  0x72a4  布局算术：
            sum   = AlignUp(ramdisk+second+vendor量, page) + page
            RdLoad = RdEnd − sum
            DtLoad = RdLoad − (page + 0x200000)     ← DT 区恒预留 2MB
            w27    = DtLoad − K                      ← 解压缓冲上限
  0x742c  Gunzip(0x4fed0)：src=BootImg+page(±标头) → dst=K，dstLen=w27
  0x7614  再验 [K+0x38]==ARMd → image_size=[K+0x10] ≤ DtLoad−K 否则拒
  0x7ab0+ DTB 选择/加工（BoardDtMatch §2.2、UpdateDeviceTree 0x3b3ec）
  0x8134  appended DTB 末端 ≤ DtLoad 否则 "Kernel size is over the limit" 拒
0x8294→0x85a0 收尾与跳转（§5.5/§5.6）
```

### 5.3 Q1/Q2 答案：装载地址数学与"重定位不存在"

- **K = 0x80080000（stock）= MemoryBase | 0x00080000**；解压缓冲上限 =
  `DtLoad − K ≈ 0x0537E000 ≈ 83.5MB`（精确式：`0x05580000 − AlignUp(ramdisk,page)
  − 0x200000 − 2×page`，即 RdEnd−K 减 DT 间隙再减页余量）。
- **"重定位拷贝"不存在**：gzip 路径 = zlib inflate 把解压流直接写进
  [K, K+outlen)，`outlen` = zlib `total_out`（解压流实际长度）——**FD 多大就落
  多少字节**，不由任何头字段决定。boot 头 kernel_size 只用于显示与 ramdisk 摆放
  （解压后不更新）；arm64 头 image_size [K+0x10] 只被**校验**不消费；
  text_offset [+0x08] 仅在 "K" 变量覆盖路径 + 非 gzip + image_size≠0 三条件
  同时成立时被读（stock 与我们的 gzip payload 都不走）——**ABL 消费 arm64 头的
  完整清单：+0x38 魔数（两处）、+0x10 image_size（校验）、+0x08 text_offset
  （仅覆盖分支）**。
- ABL 对 boot 头的隐含假设就这些。没有任何 "uefiplat"/平台 config 概念
  （字符串表零命中）。

### 5.4 Q3 答案：尺寸校验九项全表 + 常量普查（无任何尺寸门）

| # | 校验 | 位置 | 违例后果 |
|---|---|---|---|
| 1 | gzip 魔数 1F 8B 08（成员头） | 0x5029c@0x70fc | 走 UNCOMPRESSED/裸 arm64 分支 |
| 2 | srcLen > 0xA 且非空 | 0x4fef4 | "the input data is not a gzip package" |
| 3 | dstLen > srcLen | 0x4ff08 | "the available length … is not enough" |
| 4 | 解压输出 ≤ dstLen（avail_out 单次 inflate） | 0x50124 | "Output buffer full" → 拒载 |
| 5 | outlen > 8 | 0x7578 | "Decompress kernel size is smaller than image header size" → 拒载 |
| 6 | w27 > 0（空间数学） | 0x72dc | "Not Enough space left to load kernel image" → 拒载 |
| 7 | w27 高 32 位 = 0 | 0x7304 | "Integer Overflow …" → 拒载 |
| 8 | image_size [K+0x10] ≤ DtLoad−K（仅当 [K+0x38]==ARMd） | 0x7614 | "DTB header can get corrupted …" → 拒载 |
| 9 | appended DTB 末端 ≤ DtLoad | 0x816c | "Kernel size is over the limit" → 拒载 |

**常量普查**：对全二进制（mov/movk 链重建、adrp、32/64 位 literal 池、.data 全扫）
查找 0xA8000000 / 0xA7100000 / 0x80080000 / 0x85600000 / 0x300000 / 0xF00000 /
0x1080000 / 0x1200000——除 0x74f94 常量池与 0x8508 的 w6=0x200000（DT flush 长度，
见下）外**零命中**。⇒ **不存在任何 3MB/15MB/0xA8000000 尺寸门**；历史上
"FD>15MB 死于 ABL"的归因被整体推翻（§5.7）。

### 5.5 Q3 补充：EBS 收尾链 = 纯 cache 维护 + 关 MMU

0x21890（ExitBootServices 后、跳转前）的完整动作清单：

- 区域迭代器 0x21e24 读 CTR_EL0.DminLine 取 cache line，逐 line 调 worker
  0x21b78 = **`dc civac`（clean + invalidate）**。五个 (addr,size)：
  ① (K, "K"变量数据)——stock 无变量且预清零 ⇒ **长度 0，空转**；
  ② (RdLoad, ramdisk 实际长度)；③ (DtLoad, **0x200000**——2MB 常数的真实语义 =
  DT 区 flush 长度)；④⑤ kernel-stack 协议（GUID B5062BE7-…，LocateProtocol）
  提供的两个栈区。
- 随后 `ic iallu`、全 set/way `dc csw`、**SCTLR.C=0 / I=0 / M=0**、
  `TLBI VMALL`、`daifset`。
- **不清零、不捐赠内存、不拆任何映射、不做 3MB 边界操作；区域边界 = 数据实际
  长度**。`dc csw` 全清反而把 zlib 刚写进 dcache 的脏行刷进 DRAM——对 handoff
  后的读取是保障而非破坏。

### 5.6 Q4 答案：最后一公里与寄存器约定

```text
0x8334  日志 flush → LocateProtocol ×2 → GetVariable("K")
0x84fc  ShutdownUefiBootServices(0x21758：GetMemoryMap 重试环 + ExitBootServices)
0x8504  §5.5 的 cache/MMU 收尾
0x9d60  SMC(0x86000000)——SMCCC 标准形（包装器 0x555d4，OEN6=vendor hyp 服务），
        参数为栈残留、非地址类调用：不构成内存保护动作（全 ABL 仅此一个 SMC 包装）
0x8540  ldr x20,[sp,#0x90]   ← 内核入口 = K
0x8590  x0 = [sp+0xa8](DTB), x1=x2=x3=0
        blr x20              ← 标准 Linux boot 协议交棒
```

**判定：handoff 时刻 staging 窗内数据仍在、ABL 无任何清除/重映射动作，读它在
ABL 语义上不 fault。** 实证上界：FD 3MB 的实验轮里 BootShim 在同一时刻
（post-EBS、MMU off）顺序读到 0x8038003F 全程成功。**残留未知数**：Mu DXE 期
读 0x803808B8 曾报 synchronous external abort（FAR 实锤）——与 0x8038003F 同处
一个 4KB 页 ⇒ 栅栏要么在 handoff→DXE 之间才生效/被触碰，要么根本是 Mu 自身页表
未覆盖被误读为 external abort。**无法静态排除 post-EBS 某时刻 staging 3MB 外
存在访存栅栏**（§7.4 留了一次性探测方案）。

### 5.7 FD>15MB 死因修正（替代归因）

旧判 "FD_SIZE>stock = ABL 重定位阶段死" 被推翻（ABL 无该阶段、九项校验 16.5/18MB
全过）。候选按概率排序：

1. **BootShim 拷贝目的越界**：0xA7100000 + FD_SIZE = 0xA8180000 跨 0xA8000000——
   若该界外存在 post-EBS 物理栅栏/未映射空洞，`stp` 即死且无控制台（Mu 帧缓冲
   控制台在 FD SEC 之后才起），与无输出观测完全吻合。注意 ABL 证据不能裁决
   （ABL 全二进制无 0xA8000000）；栅栏只能来自 XBL/TZ 侧或物理布局，Mu 侧
   MemoryMapLib 恰在 0xA8000000 画了 256MB "Kernel" Reserv 区。
2. **拷贝源越界**（源读到 0x80380040 以上）：§5.6 的未知数。FD 3MB 实验证明
   边界不在 0x80380000 之前。
3. ABL 更早的无声路径（池分配落位异常）：静态未见尺寸相关性，低概率。

**分界定律（对实验设计最有用）**：ABL 对 46MB stock 内核做同窗 CopyMem
（pre-EBS）天天成功 ⇒ **pre-EBS 时代 [0x80080000, ~0x85600000) 无栅栏；一切
"栅栏"只可能出生在 ExitBootServices 之后**。任何 staging 探测都必须在 BootShim
（post-EBS）身份下做——ABL 阶段读得通不代表 handoff 后还活着。

### 5.8 对账表（本轮推翻/修正/证实了什么）

| 旧结论 | 判决 |
|---|---|
| "FD>stock 死于 ABL 重定位阶段" | **推翻**：无重定位阶段；死点后移到 blr 之后（§5.7） |
| "ABL 荣誉 arm64 头 text_offset" | **限定条件落地**：仅 "K" 变量覆盖分支消费（§5.3） |
| "0x80080000/0xA8000000 来自结构体/config" | **落地**：前者 = MemoryBase \| 常量池 0x80000；后者 ABL 零引用，是 Mu 侧概念 |
| 装载布局 0x80080000 / RdEnd+0x05600000 / DT−2MB | **证实**并补全出处（常量池 + orr 数学） |
| "关停链内无 SMC" | **修正**：跳转前有一次 SMC(0x86000000)，非内存保护形态（§5.6） |

---

## 6. 附属机制（fastboot OEM 面、日志通道、杂项）

### 6.1 魅族 fastboot OEM 命令表（注册点 0x4eab0）

| 命令 | handler | 权限 |
|---|---|---|
| oem poweroff / reboot | 0x4ed90 / 0x4ede0 | — |
| oem read_psn / write_psn: | 0x4ee50 / 0x4eea0 | — |
| oem edl / random / verify: | 0x4ef30 / 0x4ef90 / 0x4f010 | — |
| oem lock / unlock: | 0x4f2e0 / 0x4f350 | — |
| oem root / unroot | 0x4fa10 / 0x4fa90 | user 变体拒 |
| **oem kernel-log-enable** | 0x4fb10 | 解锁或 eng/userdebug |
| **oem kernel-log-disable** | 0x4fbc0 | 无检查 |
| oem ssr-enable / ssr-disable | 0x4fc40 / 0x4fcc0 | 同 enable 族 |
| **oem logfs** | 0x4fd70 | 无检查（纯读） |
| oem color: / erase-bootinfo | 0x4fdc0 / 0x4fe60 | — |

另有 fastboot 变量 `kernel-log-enable`（getvar 可查，回调 0x4ed0c）。

### 6.2 private 分区旗标与 kernel-log/logfs 环

- **private（sda6，7MB）已知字段**：@0x13400 100B key=value 串（"memtest=0" 等）；
  @0x13800 **12B `[u32 magic 0xFEDA8558][u32 kernel_log][u32 ssr]`**（oem
  kernel-log-enable/disable 与 ssr-* 共写，读-改-写各改各的 dword）；@0x14000
  1KB 配置块（细节未拆）。分区 IO 走 `get_partition_io`（0x1c080）按 GPT 名找
  句柄 → OpenProtocol 魅族私有 partition_rw 协议（+8=Read / +0x10=Write）。
  ⚠ 实测 `oem kernel-log-enable` 的 Write 路径会**卡死 ABL**（协议后端在 fastboot
  单线程环境等不到依赖）——**别用**。
- **启用 kernel-log 的安全方式 = 不碰 ABL**：cmdline 构造器内（~0x41010，门
  @0x427a4）唯一受旗标门控的内核侧效果是追加 `msm_serial.console_enable=1`
  （另一个或门 = 单字母 UEFI 变量 "K" 非零，与 §5.2 装载基址覆盖读的是同一个
  变量名/GUID）。**自己刷写的 boot 镜像 cmdline 里直接带
  `msm_serial.console_enable=1` 即可激活**内核写入端（stock GKI 内核的
  msm_serial 魔改把 console/printk 镜写进 logfs 分区环）；读回走 EDL `r logfs`
  或 rooted 读 /dev/block/sde66。主线内核无此写入端（对我们的链路无意义，
  记录备查）。
- **logfs（sde66，8MB）**：`oem logfs`（0x1bc60）读 32KB，若 `[0x70]==0x9D9D9D9D`
  （环初始化标记）按 `[0x64]=rptr/[0x68]=wptr` 打印 `[0x1000+i]` 载荷；魔数不匹配
  则静默跳过。现态该分区是 ABL 自己的 UEFI 调试日志文本（无环头）⇒ 敲 oem logfs
  输出为空。cmdline 构造器同段还无条件追加 `verify_rpmbkey=<reason>`、维护
  memtest 标志、按 RAM 容量决定 zram 开关（≥6001MB→`mz_mem.zram_enable=0`、
  ≥4001MB→`=1`）。

### 6.3 ramoops 0xa5100000 清零之谜（ABL 侧洗清）

ABL 全镜像**零 pstore/ramoops 感知**（无字符串、无 0xa5100000 常量序列）；装载
活动全部局限在 [0x80080000, ~0x85700000)，够不到 DRAM+593MB 处的 0xa5100000
⇒ "失败链/普通重启后 ramoops 被清"**不是 ABL 干的**。嫌疑收敛到内核侧（探针镜像
各版 ramoops 配置不一致触发 pstore 重建清区；健康启动 console 环正常覆写）。
抓主线死因要用 memramoops/earlycon，且先排除探针自己清区。

### 6.4 vendor_ramdisk 0x80 私有类型

vendor_boot v4 的 vendor_ramdisk table 条目 `ramdisk_type` 字段被魅族私用 0x80
（stock 枚举只到 3=DLKM）。ABL 侧未发现对 0x80 的特判代码；stock 拼接 vendor
ramdisk 时 type 只影响 recovery/normal 模式筛选。**vendor_boot 原封则无风险**；
若将来自组 vendor_boot，需实测 0x80 条目去留。

---

## 7. 复现指南（在你的设备上）

### 7.1 前置与素材

- 前提：可解锁的设备 + 一次完整备份。素材获取二选一：**9008/EDL 全分区备份**
  （最全，也最重要——动手前先有它）或 rooted 状态 `dd` 出
  `/dev/block/bootdevice/by-name/abl_a`（以及 xbl/uefi 若要研究 §3.2 的模块集）。
- **代际核对**：本文地址表对 Flyme 12.6（Android 16，BQ2A.251016.001）user 变体
  成立，并与 eng 10.2.0.0A 交叉验证过。其他固件代次/变体**地址会漂移**——先用
  DEBUG 字符串（§5.1 路标法）确认同名函数，再套用结构结论。
- 工具链：Python3 + capstone（`pip install capstone`）；avbtool（vbmeta 解析）；
  AOSP `unpack_bootimg` / `mkbootimg`；payload-dumper（OTA 提取）；UEFIReader
  （WOA-Project，提取 uefi 分区模块集用）。

### 7.2 解包与反汇编（本仓 tools/abl-re/）

```bash
# 1) 从你自己的 abl 分区解出 LinuxLoader PE
python3 tools/abl-re/extract_fv.py abl_a.img out
#    产物 out/mod*.efi = LinuxLoader（本代 ~601KB AArch64 PE32+）

# 2) 字符串普查（路标）
strings -a -t x -n 6 out/mod*.efi > linuxloader-strings.txt

# 3) 引用反查：echo "0x37934 GetBoardDtMatch" | python3 tools/abl-re/xref.py out/mod*.efi
# 4) 函数反汇编（ADRP+ADD 自动注解字符串）：
python3 tools/abl-re/disfunc.py 0x37934 0x38000 out/mod*.efi
# 5) 通用兜底：xbl/uefi 这类 PIL 包装用 unwrap-qcom-pil.py；
#    要 RAW 段（如原厂面板 XML）用 extract_fv_raw.py
```

`.text` VA=文件偏移（ImageBase=0），本文所有地址直接可用；你的件若同代，
§5.2/§5.4/§6.1 的每个地址都应逐字对上。脚本全为独立 Python，无外部依赖
（xref/disfunc 需 capstone）。

### 7.3 已知未决（想续挖的入口）

1. handoff 后 staging 窗栅栏边沿（0x80380040 → 0x80400000）：在 BootShim 里做
   1 页步进读探测（每步套 abort→死循环回收帧），一次实验钉死 §5.6 未知数；
   同一实验另一半做 0xA8000000 附近试写。
2. UEFI 变量 "K"（GUID 882F8C2B-…）覆盖装载基址：若能拿到设备端 SetVariable
   授权路径，可把整个装载窗搬家——避开低 3MB staging 的 ABL 侧唯一合法旋钮。
3. VTS（vendor_ramdisk table）解析函数未定位（无 DEBUG 串）——自组 vendor_boot
   前需补课。
4. init_boot 槽 a/b 不对称执行点：misc `\x01roms` 选择器 / devinfo / 槽选择分支，
   三选一待定（§2.6）。
5. XBL 侧 staging 窗授予/回收机制（0x80080000 起点与 post-EBS 栅栏的来源）：
   需 xbl 反汇编，另立项。

---

## 8. 政策：二进制本体与派生转储为何不外发

本文档公开的是**事实**（地址、机制、校验表、实验判读）与**方法论**（脚本、路标
法）。stock 固件的二进制本体及其派生转储**不在公开面**，四条理由：

1. **版权与许可（核心）**。ABL/LinuxLoader 是高通（QcomModulePkg EDK2 派生）与
   魅族（BoardDtMatch 魔改段、OEM 命令表、kernel-log 环等定制）的版权作品，随
   设备以使用许可分发，不授予再分发权。逆向**结论**是事实，事实不受版权保护——
   这正是本文能存在的原因；**二进制本体与其完整派生物**（全量反汇编 dump、全量
   字符串表、解包出的 .efi 模块）是作品的复制品/演绎品，公开即未经许可的再分发。
   两者的法律地位完全不同，本文与私有仓的分界就画在这里。
2. **安全边界敏感性**。ABL 是验签链的安全边界本体：内含 AVB 实现、OEM 解锁/命令
   面（含 root/psn 类 handler）、ERF 读取路径。带完整注解的分析件 + 提取工具
   打包流通，外观接近"验签链分析工具包"，在 DMCA §1201 类反规避框架下有被误伤
   的现实风险（即便用途纯互操作、且我们的链路全程不绕过 AVB）。结论公开没有这个
   问题；二进制+工具打包公开有。
3. **必要性为零**。任何复现者都应该从**自己的设备**提取自己的 abl/uefi 分区
   （§7.1）：一方面这保证拿到与自己设备代际/变体一致的件（不同代次地址本来就
   会漂移，反正要自己复核）；另一方面我们不经手任何人的固件分发。我们要给的
   只有"怎么提取 + 怎么分析 + 我们的结论可对拍"。
4. **社区惯例一致**。mainlining 社区（postmarketOS/LineageOS 等）的通行做法：
   设备**功能性固件 blob**（wifi 板卡数据、功放 DSP 固件等——本仓 Release 的
   firmware apk 属此类，设备运行必需）随发行版分发没有争议；**bootloader 本体**
   则一律"自机自提"，没有第三方渠道分发 stock bootloader 的先例——而且在零售机
   上刷别人的 abl 本来就会被 XBL 拒签（§2.1），分发它连实用价值都是零。

**分界清单**：公开 = 本文 + [tools/abl-re/](../tools/abl-re/) 五个原创脚本 +
我们自己构建的产物（Mu FD / ESP / rootfs / apk，本仓 Release 面）。私有保留 =
解包出的 stock 模块（.efi/.depex）、全量反汇编与字符串 dump、9008 全分区备份
镜像。后者在私有工作区，不随本仓与 Release 分发。

---

## 9. 资料地图（哪份事实在哪）

| 想查什么 | 在哪 |
|---|---|
| 链路速览 / 镜像解剖 / 版本定律 | 本仓 [DESIGN.md](DESIGN.md) |
| 刷写操作 / 救砖 | 本仓 [FLASHING.md](FLASHING.md) |
| 事件顺序完整叙事（R/T 系列逐轮） | 私有工作区 experiment-log（未公开） |
| ABL 逆向原始两篇（含更多中间产物清单） | 私有工作区 `docs/meizu20/abl-re-notes.md`、`abl-reloc-re-20260925.md`（未公开；本文 §5/§6 已全量收编其结论） |
| 解包/反汇编脚本 | 本仓 [tools/abl-re/](../tools/abl-re/) |
| Mu 移植源码（BootShim/m2381Pkg） | <https://github.com/RiverKawa271828/Mu-Silicium>（分支 `meizu20-mars-port`） |
| 内核 fork（DTS/驱动/config） | <https://github.com/RiverKawa271828/linux-mobile-ports>（分支 `meizu20-t4b`） |
| 设备包/固件包配方 | <https://github.com/RiverKawa271828/pmaports>（分支 `phoenix`） |
