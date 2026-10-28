# XBL 逆向全集：镜像解剖 + 会话语境定谳（魅族 20 / m2381）

> 2026-10-29 轮（队列②，零设备纯宿主，REA/Ghidra lane）。
> 上游卡 = docs/XBL-SESSION-RE-CARD-20261028.md；根治语境 =
> docs/s5-rootcure-card-20261020.md + PANEL-CORRUPTION.md §6。
> 配套底账 = docs/BOOT-CHAIN-RE.md（§1.1 血统链 / §8 政策）。
> 素材：9008 备份 `xbl_a.img`/`xbl_b.img`（3.6MB，两源 sha256 同为
> `aab919bd632dcc6d…` 逐字节互换）+ dig 件 `xbl_config_a.bin`（300KB）——
> 私有仓保管，本文只进结论、地址与原创脚本（§8 政策）。

## 0. 一页看懂

1. **XBL 零面板域 = 结构性定谳**：xbl 分区三层镜像 = loader 桩（128KB，
   0x22126000，attestation/安全加载）+ ELF#2（~208KB，0x20412800，SMEM/
   IPCC/证书域）+ 主镜像（~832KB，0x14800000，sbl1 流程/DDR 训练/
   PMIC/XBL Config）。全镜像 strings 普查 panel/dsi/splash/display 族
   **只命中一条 PMIC DAL 路径** `/sw/pmic/pm/display`——XBL 不碰 DSI/
   DDIC/帧缓冲内容，**splash 显示会话整体由 uefi 分区里的 DisplayDxe
   建立**（BOOT-CHAIN-RE §1.1「显示栈在 uefi 非 xbl/abl」在 XBL 侧反向
   坐实）。
2. **「GETPANELID 平台调用（XBL 域）」正式勘误**（推翻（九十五）⑤的域归
   属）：`MDPPlatformConfigure` 分发器就在 DisplayDxe 内部
   （DisplayDxe+0x7704），type=1 = **经 DSI 直读 DDIC**——先发页解锁序列
   `39 f0 55 aa 52 08 03 6f`（r22 页解锁家族 `f0 55 aa 52 08` 的 stock
   侧用点实锤），再读 `0xDF`（23B）与 `0xA1`（4B），拼出
   `panel_id = DF[0]<<16 | A1[0]<<8 | A1[1]`（本机 0x4DB501 逐位吻
   合）；type=4 只回缓存，type=10 回面板 XML 表指针。**供给侧全在
   DisplayDxe，与 XBL 无关**。
3. **XBL 对显示域的全部贡献 = 三件非命令维度**：①PMIC OLED 电源轨默认
   电压（DT `/sw/pmic/pm/display`：ELVSS 0xfffff060 / ELVDD 0x11f8 /
   OLEDB 0x1900，主镜像 PMIC DT 解析器 boot 时应用）；②显示内存保留区
   （`Display Reserved 0xB8000000+43MB`[splash 帧缓冲域，iOS 线 fb 同址
   互证] / `disp_rdump_region 0xB8000000+8MB` / `Display Demura
   0xA2A80000+43MB`）；③`EnableDisplayThread=0x1`（UEFI 面板初始化并行
   线程旗标）随 uefiplat.cfg 递交。
4. **uefiplat.cfg 双副本对拍（新档案）**：XBL DT `/sw/uefi/uefiplat`
   payload（XBL loader 建内存图的源）vs UEFI FV 内置份（UefiPlatCfg.c
   `LoadAndParsePlatformCfg` 的源）**内容漂移**——Display Demura 区地址
   0xA2A80000（XBL 份）↔ 0xEEB00000（FV 份）、PIL Reserved/TZApps/
   RSRV 布局不同、`EnableLogFsSyncInRetail` 0x0↔0x1、`LoadAutoImageInP
   ILFlag`/`UEFI Log` 区只在 FV 份。两份各有消费者，双副本并存是本机
   boot 链的实态。
5. **对花屏根治（S5）的回答**：XBL 域挖穿后，「splash 会话缺失维度」收
   缩到 DisplayDxe 侧已建档的清单 + 本轮新增三件（PMIC GPIO 上电时
   序、页解锁+ID 读法、OLED 轨默认电压）——见 §6。

## 1. 素材与方法论

- 输入配方（根治卡 §4 在案 + 本轮增量）：xbl 外层 = **ELF32 占位头**
  （`e_machine=1`），`readelf` 必拒；须先解 program header（Python
  struct，勿信 `unwrap-qcom-pil.py` 旧版——其 ELF32 phnum 偏移
  off-by-2，读恒 0，**10-29 已修**：phentsize@0x2A / phnum@0x2C）。
- **REA raw-binary lane 的基址语义（本轮踩坑定谳）**：`rea
  analyze/decompile <raw.bin> --entry-point <E>` 把 **E 当镜像基址**，
  内部地址 = 文件偏移 + E；对外文档一律换算回**真基址**。主镜像真基址
  `0x14800000` 的定谳法：ELF#3 头 `e_entry=0x14819fa8` 且该 vaddr 落在
  文件偏移 0x19fa8 处 = `mov x20,x0` 经典入口序言（自洽闭环）。
- ADRP/ADD 引用反查用 capstone 暴力扫描（Ghidra 对 raw 段常不定义字符
  串数据项 → `rea xrefs` 空）；扫描空间用**真基址**线性映射即可自洽。
- 三步法同 BOOT-CHAIN-RE §5.1：strings 路标 → xref → 反编译读控制流。
- 快照库：`s5-rea` 私有面（`xbl-loader` / `xbl-main` / `displaydxe` 三
  snapshot 可重放；切段产物与反编译 md 全在私有面 out/xbl/）。

## 2. 镜像解剖（xbl_a.img 3,670,016 B；xbl_b ≡ xbl_a 逐字节相同）

```
0x000000  ELF32 占位头（type=2, machine=1[占位], entry=0x22126000,
          phoff=0x34, phnum=2）
0x000074  PT_LOAD#0  128KB  vaddr 0x22126000  = ①XBL loader 桩
          （strings = CHIP_*_K_LBL 芯片级密钥标签 + SEQ_FW r6 版本串
          → 身份 = attestation/安全装载桩）
0x020074  PT_LOAD#1  640B   vaddr 0x22283000  = 元数据小段
0x0202F4  内嵌 ELF#2（machine=0xf3 占位, entry=0x20412800, phnum=13）
   ph06 LOAD 168KB RX  0x20412800  = 代码（SMEM/mproc/IPCC 域）
   ph07 LOAD 23KB  RW  0x2043B7D8  = 数据
   ph08 LOAD 4.6KB RW  0x204414AC  = 数据
   ph10/11        0x200×2 @0x20400000/0x20400200 = secboot 元数据/哈希块
   ph12           哈希表 0x2CA0 @ELF 尾（0x52F94 处结束）
   （strings：/sources/external_teams/core/mproc/smem/*、IPCC 全家、
   SRoT MBNv7 签名证书链、TME_FW_VERSION → 身份 = SMEM/IPCC/密码域
   支持镜像）
0x055F94  内嵌 ELF#3 头（machine=0xb7 占位, entry=0x14819FA8,
          phnum=0[纯头]）+ 主镜像裸 payload
   真 base = 0x14800000（§1 定谳法），payload 0x55FC8..0x125F94
   ≈ 832KB = ②主镜像（余下至 0x380000 全零填充）
   （strings：sbl1_* 全家族、xbl_loader/xblconfig_init/xbl_ddr/
   xbl_map_smem/xbl_dtb_node_init 符号名族、XBL Config/XBL_LOG/
   XBL_SC_MINI_CTX、DDR_FW/CPUCPFW、DDR 训练全套[PLL Pre-Cal/DCC
   monitor/WCK2DQI(DIT)/RCW CDC]、/sw/pmic/pm/* → 身份 = sbl1 主
   流程 + DDR 初始化训练 + PMIC + XBL Config 的主镜像）
```

- xbl_config 分区（307,200 B，ELF64 占位头，entry=0x1494E000，phnum=8，
  全部 LOAD 落 0x1494E000..0x1496E000 = 主镜像同地址域）：

```
xc0 0x11C  文件索引（pre-ddr-soc-kailua-1.0.dtb / soc-kailua-1.0.dtb /
           A003_8_*_dcb.bin / cpr.bin）
xc1/xc5 0xC804×2  DDR 训练数据双份（PLL Pre-Cal/WCK2CK/DCC 族）
xc2 0x33C8  pre-DDR soc DTB（qcom,kailua）
xc3 0xDAE4  soc DTB（qcom,kailua，本档 §4 全集）
xc4 0x16A8  DCB/CPR 裸数据块
```
  ⇒ **xbl_config = XBL 自用配置包（DDR/PMIC/CPR/DT），零面板域**。
  "XBL Config" = 这个包，由主镜像 `xblconfig_init` 消费；不是面板配置。

## 3. XBL 零面板域（负结果的结构性证据）

- 全镜像 strings（1856 条）按 family 普查：`panel|display|dsi|splash|
  mdp|demura|backlight` 仅 2 命中 = `/sw/pmic/pm/display`（DAL 路径，
  §6）+ 裸词 "display"；`xbl|uefi|smem` 族只含 boot 基建（无 UEFI 模块
  装载显示面）。
- 镜像清单（§2）无一含 DSI 控制器/MDP/DDIC 读写代码；splash 字全镜像
  0 命中。
- 交叉印证：memmap 保留区名只有 "Display Reserved/Demura"（内存划区，
  非驱动）；`EnableDisplayImageFv = 0x0`（logo 不走 XBL imagefv）。
- **判词：XBL 不建立显示会话。**splash 会话（面板上电、ID 读取、XML
  选择、init 序列、DSC/TE 编程、帧缓冲内容）整体在 uefi 分区
  DisplayDxe——（九十五）的标准域清零结论 + 本轮 §5 的平台侧补完 =
  splash 会话语境的完整域图。

## 4. XBL DT（soc DTB，xc3）显示相关全集

dtc 反编译 2394 行（完整 dts 留私有面 out/xbl/xbl-dt.dts）。显示域节点：

```
/disp_rdump_region@b8000000   compatible="qcom,display"
                              reg=<0xb8000000 0x800000>  ← 8MB splash 帧缓冲/
                                                             显示 ramdump 域
                              （iOS 线实测 fb=0xB8000000 同址互证）
/sw/pmic/pm/display           compatible="qcom,pm-display"
                              swire-map=[00]; apply-default-volt=[00]
                              default-elvss=<0xfffff060>   ← OLED 负轨默认
                              default-elvdd=<0x11f8>       ← OLED 正轨默认
                              default-oledb=<0x1900>       ← 亮度电源轨默认
/iort/NAMEDNODE_Display       DISPLAY 设备 SMMU SID 映射（InputBase
                              0x3000000 → OutputBase 0x21c00, 4 组）
/sw/boot/xbl_sc_wdog=<1> 等   主镜像行为旗标（非显示）
```

## 5. uefiplat.cfg 双副本对拍 + 递交合约

- **XBL DT 内嵌副本**：DTB 节点 `/sw/uefi/uefiplat` 属性 `payload`
  （8342B，DTB 内偏移 0x8850..0xA8E6）= 完整 uefiplat.cfg 文本
  （[Config]/[MemoryMap]/[RegisterMap]/[ConfigParameters]/[ChipIDConfig]
  五节）。XBL loader 据此建 UEFI 内存图（HOB 源）。
- **UEFI FV 内置副本**：fvtool 已提取的 uefiplat.cfg（8286B+21 NUL），
  消费者 = UefiPlatCfg.c（DEBUG 路标 `LoadAndParsePlatformCfg` /
  `uefiplat.cfg`[FFS 名] / BuildHob 选项族 AddMem/AddDev/AllocOnly/
  HobOnlyNoCacheSetting/AddDynamicMem，@uefi 镜像 0x35532 一带）。
- **对拍差异（显示相关加粗）**：

| 项 | XBL DT 份（loader 建 HOB 源） | UEFI FV 份（UefiPlatCfg 源） |
|---|---|---|
| **Display Demura** | **0xA2A80000 + 0x2B00000** | **0xEEB00000 + 0x2B00000** |
| PIL Reserved | 0x89800000 + 0x19280000 | 0x8A800000 + 0x1A280000 |
| TZApps Reserved | +0x8A00000 | +0x7400000 |
| UEFI Log 区 | 无 | 0x81CE4000 + 0x10000 |
| EnableLogFsSyncInRetail | 0x0 | 0x1 |
| LoadAutoImageInPILFlag | 无 | 0x1 |

- 共有显示键（两份同值）：

```
0xB8000000, 0x02B00000, "Display Reserved",  AddMem, MEM_RES, …  ← splash 帧缓冲域
EnableDisplayThread = 0x1     ← "Initialize Display panel in its own thread
                                 to run in parallel to booting"
EnableDisplayImageFv = 0x0    ← logo 不走 imagefv
```

- 判词：**双副本并存且漂移是本机实态**——内存 HOB 以 XBL 份为准、
  UEFI 自身配置解析以 FV 份为准；对显示域的实际影响 = demura 保留区
  地址在两个消费面各不相同（本机 BOE 面板 demura 全惰性 ⇒ 均为空置
  保留，PANEL §6 条 7 前提不变，只记档）。

## 6. splash 会话语境定谳（对根治卡判据的正式回答）

### 6.1 供给侧：GETPANELID/GETPANELCONFIG 全在 DisplayDxe（勘误定谳）

`MDPPlatformConfigure` = DisplayDxe 内部函数（ImageBase=0 → 文件偏移即
RVA）**0x7704**（snapshot `displaydxe` 反编译 dec-7704）。switch(type)：

| type | 语义 | 行为（地址证据） |
|---|---|---|
| 1 | RETRIEVE_PANEL_ID（实读） | param_1=0（主屏）分支：见下 |
| 4 | GETPANELID | `param_3[0x14] = DAT_46e08`（纯回缓存）；失败串 "MDPPLATFORM_CONFIG_GETPANELID failed"（调用点 0x1cd38 一带） |
| 10 | GETPANELCONFIG | `*param_3 = &DAT_46fd8 + idx*0x52`（面板 XML 表指针，0x52=82B/项） |
| 0 | init | 清 config 全局区 + protocol 定位；VDDI/VDDR/VCI 上电序列（下述） |
| 6/0xc | PANEL_NAME/XML 全文 | 回 XML 串（兜底 VirtioDSI 640x480 模板 = qemu 诱饵，PANEL §6 条 6 已档） |

**type=1 实读流程（0x7704 case 1，param_1==0）**：

1. 发页解锁/页选择序列 `39 f0 55 aa 52 08 03 6f`（常量 0x6f030852aa55
   f039 @栈；即 DCS 长写 `f0 55 aa 52 08` 解锁 + `03 6f`——r22 页解锁
   家族的 stock 侧用点，每轮读前双写：长包 6 型 + 短包 2 型）；
2. DSI 读 `0xDF` 起共 **23 字节**（"PanelID Info(DF) : 0x%23a."）+
   `0xA1` 起共 **4 字节**（"PanelID Info(BF) : 0x%02x%02x%02x%02x."）；
3. **`panel_id = DF[0]<<16 | A1[0]<<8 | A1[1]`** → DAT_46e08
   （本机 0x4DB501：DF[0]=0x4D, A1[0]=0xB5, A1[1]=0x01，与 bootargs
   `dis_id=4DB501` 逐位吻合）。

⇒（九十五）⑤「GETPANELID 平台调用（XBL 域）」的域标注**作废**：整个
供给链（读法、缓存、XML 表）都在 DisplayDxe PE 内，XBL 无涉。dis_id
UEFI 变量（0x358cc 处名字串，调用点 0x1ceb0 附近 SetVariable）照旧。

### 6.2 面板电源上电序列（DisplayDxe case 0，Ghidra 标 unreachable 块）

经 PMIC GPIO 协议（GUID 表 0x3a258）+ TLMM 协议（0x3a268），前置
`project_id`/`hw_id` 读数（0x8740 带日志 "DisplayDxe: project_id/hw_id"）
分派 GPIO 组：

```
VDDI: GPIO 组 (hw_id 分支 10/0xb) → enable + 5000µs
VDDR: GPIO 组 (7,4)            → enable + 5000µs
VCI : GPIO 组 (1,0)            → enable + 10000µs
TLMM 复位: 0x200fc850↑ → 0x200e4850↓/↑ 各 10000µs（10ms×3 拍）
失败路标: "DisplayDxe: Enable for VDDI/VDDR/VCI enable GPIO success!"
          "DisplayDxe: Locate PMIC GPIO/TLMM protocol failed!"
```

这是 stock 冷会话的**上电时序 ground truth**（VDDI→VDDR→VCI→复位
10ms 拍），我方内核链由 panel 驱动 DT regulator 序列自建——维度差
在案（对拍素材，不直接判因果）。

### 6.3 XBL 侧对显示域的全部动作（= 本轮新增非命令维度）

1. **PMIC OLED 轨默认电压**：主镜像 PMIC DT 解析器（PM_DT_PARSING_ERR
   家族，路径串表 0x14893900 区：`/sw/pmic/pm/{sw-config,pon,charger,
   haptics,display,camera}`）消费 `/sw/pmic/pm/display` 节点
   （配置结构 malloc(0x10) = swire-map/apply-default-volt/elvss/elvdd/
   oledb 五属性）；引用点 0x1480CE44（capstone 直证，真基址 0x14800000）。
   即使 UEFI/内核不重设，ELVSS/ELVDD/OLEDB 上电即有 XBL 默认值。
2. **显示内存保留区**：Display Reserved 0xB8000000+43MB（splash 帧缓冲
   域）、disp_rdump_region 8MB、Display Demura 43MB（§4/§5）。
3. **递交旗标**：EnableDisplayThread=1 / EnableDisplayImageFv=0（§5）。

### 6.4 对花屏根治的含义

- 卡面判据「XBL 只管冷启动，其价值 = 找出 splash 会话里主线链缺失的语
  境维度」——XBL 域已挖穿：**会话本体在 DisplayDxe**（（九十五）标准域
  清零 + 本轮 6.1/6.2 平台侧补完 = stock 冷会话语境全集在档）。
- 我方真睡唤醒重载语境 vs stock 冷会话的**语境差候选清单**（全部已有
  地址级证据，设备日验证留给下轮拍板）：
  a. 页解锁域（`f0 55 aa 52 08` 族）——我方会话从未进过该域；
  b. PMIC GPIO 上电时序（6.2）——我方 regulator 序列与 stock 拍数
     是否等值未对拍；
  c. OLED 轨默认电压（6.3①）——我方会话的 ELVSS/ELVDD/OLEDB 值与
     XBL 默认值是否一致未对拍；
  d. demura/档案选择——stock 冷会话主机侧全惰性（（九十五）③），
     维度除名维持。
- 首帧杀 vblank kernel 旋钮（B-list 唯一剩余候补）地位不变。

## 7. 复现指南（自有设备 + 自有备份）

```bash
# 0) 修过的脚本：tools/abl-re/unwrap-qcom-pil.py（ELF32 phnum off-by-2 已修 10-29）
# 1) 外层段表 + 全段切割（Python struct，勿用 readelf）
python3 - <<'EOF'
import struct
raw = open('xbl_a.img','rb').read()
e_phoff, = struct.unpack_from('<I', raw, 0x1C)   # 0x34
e_phnum, = struct.unpack_from('<H', raw, 0x2C)   # 2
for i in range(e_phnum):
    t,off,va,pa,sz,msz,fl,al = struct.unpack_from('<8I', raw, e_phoff+i*32)
    print(i, hex(t), hex(off), hex(va), hex(sz))
# 内嵌 ELF 扫描：b'\x7fELF' 命中 0x0 / 0x202f4 / 0x55f94，逐个再解
EOF
# 2) REA（真基址换算见 §1；REA 内部地址 = 文件偏移 + entry 值）
source /home/ri/work/meizu20/s5-rea/env.sh
rea analyze <loader 128KB 切段> --target-format raw-binary --architecture arm64 \
  --entry-point 0x22126000 --snapshot xbl-loader
rea analyze <main 832KB 切段>  --target-format raw-binary --architecture arm64 \
  --entry-point 0x14819fa8 --snapshot xbl-main
# 3) 字符串引用反查（raw 段 Ghidra 常不定义字符串 → capstone ADRP/ADD 暴力扫，
#    线性映射 vaddr = 0x14800000 + (off - 0x55f94)）
# 4) XBL DT：xc3 段 dtc -I dtb -O dts；uefiplat payload = /sw/uefi/uefiplat
#    属性（DTB 结构内偏移 0x8850 起 8342B），与 FV 份 diff 对拍
```

## 8. 政策（照 BOOT-CHAIN-RE §8）

结论、地址、结构图、原创脚本（unwrap 修复）进公开面；固件派生物（切段
bin、完整 dts/strings 全文、反编译 md、snapshot 库）留私有面
（s5-rea/out/xbl/）不进公开仓。素材本体（xbl_a/b.img、xbl_config_a.bin）
私有仓保管不外发。

## 9. 更钉记录

- tools/abl-re/unwrap-qcom-pil.py：ELF32/ELF64 phnum 解析 off-by-2 修复
  （旧版对 xbl 类镜像 phnum 恒 0）。
- PANEL-CORRUPTION.md §6 条 8 = 本档指针；（九十五）⑤「GETPANELID=XBL
  域」勘误交叉引用。
- BOOT-CHAIN-RE.md 文档地图 + XBL-SESSION-RE-CARD-20261028.md 收官标记。
