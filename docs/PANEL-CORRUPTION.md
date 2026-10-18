# AMOLED 面板花屏 case 包：掉电→重新上电后的马赛克（魅族 20 / m2381）

> **定位**：给在其他 DSC AMOLED 设备上做主线移植的人——如果你撞上「**冷启动
> 永远干净，真实掉电→重新上电后必现马赛克**」，这篇是目前已知的全部测量、
> 排雷记录与活着的假说。自包含：案情、实验判据、判读方法、工程解、未测项
> 全在本文。全部结论标注证据等级：**【实测】**（上机/寄存器级实证）、
> **【推断】**（由实测推理，未被单独验证）、**【未定谳】**（假说，勿当结论引用）。
> **政策**：只含事实、参数与方法论；stock 面板 XML / DDIC 固件 / vendor dump
> 一律不附（引用的数据点均为测量读数）。
> 环境背景（这台机器怎么跑起来）→ [DESIGN.md](DESIGN.md)；启动链 →
> [BOOT-CHAIN-RE.md](BOOT-CHAIN-RE.md)；睡眠线（另一类"睡醒"问题）→
> [SUSPEND-S2IDLE.md](SUSPEND-S2IDLE.md)。

---

## 0. 一页看懂

```
病象：AMOLED 面板真实掉电（DPMS off，panel power off/reset 序列全走）
      → 重新上电后必现"固定位置逐像素色度噪声"马赛克遮罩
      冷启动永远干净；只关背光不掉电（bloff）永远干净
      判别 5/5 全花（含第一次唤醒），跨 boot 图案同构【实测】

排雷完毕（全部上机判负，§2）：
  ✗ init 序列（与 stock 逐字节同）      ✗ DSI 包流全维度（内容×形态×时机）
  ✗ bitclk/esc/PHY byte 时序            ✗ 复位时序
  ✗ 供电轨声明与门控                    ✗ UEFI/交付链（冷启干净旁证）
  ✗ DCS 可读状态空间（373 项好/坏全同）  ✗ 刷新率档位命令（强制异档不改遮罩）

活着的问题：
  ? 唯一未做单变量实验的寄存器差异 = 主线驱动写 CLKOUT_TIMING_CTRL(0xC4)
    ≠ 0，stock 三态全零（挂 7.3 stable rebase 拼车）
  ? 病灶 = DDIC sleep-out 自重载（补偿/Gamma/Demura）"落错档"【推断】，
    重载输入在一切主机可达的命令维度之外【实测边界】
  ? stock 会话语境里 DDIC 自管理所需的某个非 DCS 可见条件【未定谳】

工程解 = bloff（灭屏只发 0x51=0 黑帧，DDIC 永不睡）——现役日用默认，用户验收。
```

---

## 1. 病象定义与触发面

### 1.1 环境

- 设备：Meizu 20（m2381，SM8550/kalama），BOE AMOLED 1080×2400@120Hz，
  4-lane DSI + DSC；panel reset = TLMM133（**210 是 UFS 复位，勿混**）。
- 内核：主线 7.3 fork；显示栈 = msm DRM（dsi host + dsi_phy_7nm）+ 自写面板
  驱动 `panel-boe-meizu20.c`（公开 fork；init 序列与 stock dtbo entry9
  **逐字节同**，DSC 配置同）。
- 启动链 = XBL→ABL→Mu UEFI→EFI stub；冷启显示干净。
- stock 参照 = Flyme 12.6 原厂安卓（做过完整往返回收素材）。

### 1.2 触发与判读协议

- 触发 = `kscreen-doctor --dpms off/on` 让面板**真掉电**再上电；journal 每轮
  一条 `dsi_err status=4` 佐证链路真断。判读 = 人眼 + 照片；定量 = 遮罩能量图
  相关性（§3.3）。
- 诊断旋钮（自研调试内核，debugfs `/sys/kernel/debug/ae94000.dsi.0/`）：
  `knob`（wake 序列变体）/ `wake_mask`（32 位逐 init 表项开关）/ `cycle`
  （面板级单循环）/ `dcs_read/dcs_write/comp_sel`（会话注入）。
- 寄存器活体读取：debugfs `dsi0_{ctrl,phy}_off`（offset+count 双参）+ 同名
  `_reg`——安全接口（stock 日全程用过）。⚠ 裸读其他门控时钟域 =
  external abort（imem/i2c 前科），别把这条通道的经验外推。
- **实验窗口纪律**：桌面空闲 ~5min 自动 DPMS 灭屏后，`cycle` 复制的是灭屏态
  （面板不再 enable）——旋钮实验必须在亮屏活跃窗口跑。
- 两个**勿混**：
  - **冷启动花屏**是另一个已结的案子（DDIC demura 会话建错，DCS 级修复，已随
    面板驱动修掉），与本案（睡醒花屏）不同相；
  - boot 早期 DPU `no encoder found for crtc 0` ×3 条 = **窗口性噪音**（面板
    cold-enable restart 自愈窗口撞上合成器 vblank 请求；dpu_crtc.c），运行期
    零刷——在 dmesg 里看到别当花屏线索追。

---

## 2. 已否证清单（排雷表——每项都真烧过一轮，勿重复投）

| # | 嫌疑 | 实验/证据 | 判决 |
|---|---|---|---|
| 1 | init 序列抄错 | 我方 32 条与 stock mode-1（120Hz 档）逐字节 diff = 0（0x91/2f 02/E1-E7 全同） | ✗【实测】 |
| 2 | bitclk/hs_rate | 885.73 → 1094MHz（=stock XBL 值），5/5 仍全花；stock 内核 mode1 = 1460MHz 又一态 | ✗【实测】 |
| 3 | 复位时序 | 高10/低10/高10ms（=stock reset-sequence）单变量 | ✗【实测】 |
| 4 | PHY byte 时序（TC0-13） | stock FDT 值直灌（交付链五环实证生效 + 寄存器活体对拍确认 stock 驱动确实按 FDT 直写 TC，0xB4-0xE8 低字节逐字节全等）后 5/5 判负 | ✗【实测】 |
| 5 | esc clock | 双侧 = 19.2MHz XO 直通 | ✗【实测】 |
| 6 | 供电声明/门控 | vddio/vdd/vci 三轨 GPIO 门控、声明全 1.8V 对齐 stock；stock 每次熄屏都真掉轨+reset 仍干净（S1 实锤） | ✗【实测】（软件侧；硬件实测矛盾见 §6） |
| 7 | UEFI/交付链 | 分辨率/时序/驱动 profile 四线判负；冷启干净旁证 | ✗【实测】 |
| 8 | 唤醒重放变体 | E6（最小 wake 只发 0x11/0x29）/ E5（双遍）/ E2（全程 LP）/ default（满序列）——用户四连判全花、无差异 | ✗【实测】 |
| 9 | **主机侧 DSI 包流整体**（H1） | `knob stock` = stock 精确包形态组合（无 0x07 压缩包 + PPS 后置 LP 0x0A 形态 + 全 LP 流）从净态真睡→醒 **仍花屏** | ✗【实测，终审】 |
| 10 | 刷新率档位命令（H2） | 强制异档 0x91/0x2F + 真 sleep：遮罩能量图相关 +0.58（=同机位基线）⇒ 三张是同一张确定性错误表，DDIC 重载不消费命令档 | ✗【实测，终审】 |
| 11 | DCS 可读状态空间 | 好/坏态 373 项（24 地址×16 页 + std 5）逐字节全同 | ✗【实测】 |
| 12 | 渲染栈/帧缓冲 | 帧缓冲干净（截屏无损），病灶在 framebuffer 之后的通路 | ✗【实测】 |
| 13 | **CLKOUT_TIMING_CTRL（clk_post/clk_pre）归零**（0xC4） | 修正实验 A/B（10-19 设备日）：knob default 可达态阳性对照 6/6 全花（P1+历史基线复现，dsi_err status=4 每轮一条），`zero_clkout_timing=1` 归零臂 5/5 全花 = 零效应 | ✗【实测，终审】 |

**边界结论**：主机侧一切已知可达维度（包内容 × 包形态 × 时机 × 供电 × 时序 ×
档位命令 × 可读状态）全部清白。病灶对 DCS 100% 不可见——要么在 DDIC 内部
自管理路径，要么在会话的某个非命令维度。

---

## 3. 三个判决实验（方法论核心，可平移）

### 3.1 好/坏态全量快照对拍 → 「寄存器 diff 路线」正式关闭

会话快照引擎（LP 读，`f0 55 aa 52 08 <page>` 页选 16 页，事务间 2ms pacing、
首个 -110 立即中止、面板睡态拒绝读）：boot 好态自动抓 vs 默认 knob cycle 后
坏态抓——**37 项（扩展到 373 项全量）逐字节全同**。好态基准已入档（p00/91 =
`ab a8 00 14 c2 00 02 0e 01 e8 …` 等）。

推论【实测】：补偿/解码档案表对主机**只写不可读**（或不在寄存器空间）——
"读寄存器找差异"这条路对这类 DDIC 是死的。

### 3.2 wake 路径全变量清洗 → 主机包流无罪

一次构建覆盖全部变体（wake_mask 32 位逐表项开关 + 形态旋钮），命中后可在机
二分免重编。结果：重放/不重放/单遍/双遍/LP/HS/无压缩包/PPS 前/PPS 后全试遍，
**毒性事件锁定在 DDIC 内部 sleep 转换本身**——唤醒行为与花屏完全无关。

### 3.3 遮罩能量图 → 确定性 = 可修性的根据

遮罩 = **面板坐标系固定位置**逐像素色度噪声，图案跨完全断电不变（两个 boot
同构）。定量方法 = 照片能量图相关性（同机位基线 ~+0.6）：H2 轮 p60 vs p90
遮罩相关 +0.58、与参照场 +0.72/+0.55 ⇒ 同一张确定性错误表。**确定性图案
⇒ 错误有单一来源 ⇒ 原则上可修**——这是整个战役坚持科学线的依据。

---

## 4. 事实底账与档案假说

### 4.1 stock 三态地面真值（10-06 扩窗 dump：A 泊车态 / dyn 动态 / B 真睡醒后）

- bitclk **1094MHz**@120fps（stock 内核 mode1 = 1460MHz；XBL splash = 1094）；
  esc 无独立属性 = XO 19.2M。
- phy TC0-13（寄存器 0xB4-0xE8，每 TC 一 word、值落低字节）：
  `03 26 08 09 18 25 09 0a 08 02 04 00 1f 0f`（B 态活体 = runtime FDT 逐字节
  等；A 泊车态 = reset 默认小值族，非全零）。
- ctrl 侧：B 态 `0x44=0x00013C2C`（**bit16 = INSERT_DCS 仅醒后置位**；
  A/dyn = 0x00003C2C）、`0x58=0x04390039`、`0x5C=0x096000B4`（hsa/hbp 域活值，
  泊车归零）。
- **★host CLKOUT_TIMING_CTRL（0xC4）：stock 三态全零**（它的 clk_pre/post 在
  PHY TC 域里）；主线驱动 `dsi_host.c:899-901` 运行时写 clk_post/clk_pre 计算
  值 ≠ 0——**当前唯一未做单变量实验的寄存器级差异**（§6 第一项）。
- DDI 电源全序列（dmesg 打点）：off 向 = pre-off→off→post-off→power_off；
  on 向 = power_on→reset→pre-on→on（→PPS 动态生成）→**post-panel-on**→
  背光 ramp 0→455。泊车态 = 引擎位全零（DDIC 自刷新族上下文）。
- stock 全链（下游内核 + XBL）**从不发标准 0xA0 PPS、从不发 0x07 Compression
  Mode 包**（下游 display-drivers 三文件零命中；PPS 走 DI=0x0A 传输层包、
  每次 enable 都发、强制 LP、动态生成）。

### 4.2 ProfileID 语义破解（三链交叉【实测】）

XBL 面板 DB（FV 内 XML）里本机面板 ProfileID = **0xB**（37 块全库唯一；三星系
=7 且流内带 `0x9E` PPS 载具 + `9D 01` DSC-on；Sharp=4）⇒ **0xB =「主机不发
PPS、DDIC 自管解码档案」特类**——与三重实测互证：0xA2 读恒空、0xA0 写无效、
stock 全链无标准 PPS/压缩包。

### 4.3 DDIC 身份与 demura 机制【实测 + 公开文献】

本机 DDIC = **Novatek 族**（页选 `f0 55 aa 52 08 <page>` + 双解锁
`ff aa 55 a5 80`；NT37705/NT37701 同族，Fairphone 6 = BOE+NT37705 先例）。
Demura 机制 = 出厂 OTP 标定 + **DDIC 在 sleep-out 自行重初始化 Gamma/Demura，
按"会话建立时收到的模式参数"（含刷新率档）自选档案**（公开专利
EP4089666A1）——与 comp_sel 档案表实测互证。

### 4.4 档案假说（当前最优模型【推断/未定谳】）

> **掉电后 DDIC 回出厂默认档案（参数本就匹配厂商码流）；sleep-out 时的补偿/
> Gamma/Demura 自重载"落错档"。** stock 发同样的命令流且不发标准 DSC 包 ⇒
> 默认档案直接工作；我们（历史版本）在序列中段插入的 0x07 压缩包曾把 DDIC
> 切进标准档案 0 ⇒ 档案 0 ≠ 我方码流 ⇒ 色度级失配。

该模型的解释力（每条都对着实测）：冷启动干净（XBL 的 0xB vendor 会话存续期内
标准包被忽略）；历史"重发全序列"失败闭环（重放末尾的压缩包自己把刚锁存的态
覆盖回去）；comp_sel 0-3 全不对、0 最接近（默认档案与槽 0 最近）。

**但注意**：H1/H2 终审后（§2 表 9/10），"命令流里哪个包有毒"这一层已经全灭——
现在的表述收窄为：**sleep-out 重载的落档输入在一切主机可达的命令维度之外**
（会话语境：XBL/stock 建会话时的某个条件，或 DPU 流特征，或 DDIC 内部状态）。
修复候选见 §6；在根因找到前，DDIC 档案机制细节一律保持【未定谳】分级。

---

## 5. 工程解：bloff（现役日用默认）

**语义**：灭屏 = 只发 `0x51=0`（背光/黑帧，AMOLED 视觉关机、近零功耗）；
**0x28/0x10 一律不发 ⇒ DDIC 永不进 sleep ⇒ 补偿态永不重载**。亮屏 = 直接
恢复亮度。真睡判别 5/5 全花 vs bloff 永远干净 = 该解的实验根据。

- **固化形态**：`module_param(bloff_default, bool, 0444)` 默认 true（cmdline
  `boe_meizu20.bloff_default=0` 可关；运行时 knob 也可关）。**安全门 =
  `bl_off_live` 标志**：enable 侧"跳过重放"捷径仅在上一轮 off 也是 bloff 路径
  （面板从未睡）时生效；冷启动必走完整重放建会话。
- **历史教训（对移植者最重要的一条）**：bloff 固化当轮曾把**冷启动 recovery
  双遍**误伤——旧实证：第一遍发完 DDIC 不应答（-61），画面实为 recovery 第二遍
  建立 ⇒ 面板半初始化 → 首次灭屏唤醒全雪花。**冷启动 recovery 双遍是必需品，
  任何"实验纯度"门控不得覆盖它。**
- **边界三条**：①只防新增花屏，**不治愈已花屏**（治愈 = 冷启动重启）；
  ②功耗权衡在 AMOLED 上成立（黑帧近零），**LCD 不适用**（背光仍亮）；
  ③旋钮互斥（测 stock/profile 类旋钮会关 bloff，测完回日常需 `knob bloff` +
  重启）。**④系统 suspend 同罩（10-19 实验实证 + 代码双证）**：suspend 的 DRM off
  同走 `unprepare()` 的 bloff 分支 ⇒ DDIC 真睡全程不睡、醒来走 bl_off_live 捷径
  ——「真睡」在 bloff 默认态结构性不触发毒源（0xC4 首测前提证伪即此，§6 条 1；
  「真睡不受 bloff 影响」旧判作废）。
- 附带一条与面板无关但同轮踩出的移植雷：向用户态**暴露新 DRM 模式**会移动
  boot 时序敏感窗口（geni modprobe × DRM 探测竞态）；且当时 3 次 panic 的真凶
  是**两个 systemd 服务并发操作全局 `drivers_autoprobe`**（PAS 复位落进 touch
  的 modprobe 窗口 → geni_i2c_resume synchronous external abort）——多服务
  碰同一全局开关必须互相 `After=` 排序。刷新率多模式因此保持回退态，与花屏
  修复解耦（H2 探针用 profile 强制旋钮即可，不需要真多模式）。

---

## 6. 未解与下一步（按先验排序）

1. **0xC4 归零单变量**【✅ 10-19 设备日两阶段收官——**洗清（排除）**】：
   `msm.zero_clkout_timing`（fork `c1d84dcf80ec`，0644 运行时可写，下一个
   host clock setup 写 0 代替 clk_post/clk_pre；默认 0 = 现行为不变）。
   - **阶段一（默认态，12/12 全净）**：apk r88 + ESP v69 upgrade.sh 首跑双腿全绿
     （实测 #89 + 读回对 ✓）→ 默认态回归绿 → 默认态真睡 ×2 轮 12 次 s2idle
     （含 C0 对照，用户眼判回执「C0 也没花」；susp_success 0→13、dsi_err 零新增）
     → **排面前提「真睡不受 bloff 影响」证伪**——bloff 分支在 `unprepare()`
     （panel-boe-meizu20.c:1261 = 0x51=0 不发 0x28/0x10 + keep_rails +
     bl_off_live=true），系统 suspend 的 DRM off 同走 ⇒ **DDIC 真睡全程不睡**，
     醒来 `enable()` 走 bl_off_live 捷径跳过重放（:1177）⇒ 毒源（sleep-out 自重
     初始化）结构性不可达（§5④）→ 默认态 0xC4 不可判（阳性对照缺席）。
   - **阶段二（修正实验 = debugfs `knob default` 关 bloff，病灶可达态）**：P1
     阳性对照真睡 ×1 → **全花**（历史 5/5 基线在可达态复现 ✓；**dsi_err
     status=4 每轮一条 = 可达态链路真断的客观 marker**，对照 bloff 轮全程 0）→
     `zero_clkout_timing=1` 真睡 ×5 → **5/5 全花 = 旋钮零效应** → **0xC4 洗清：
     clk_post/clk_pre 归零既不治花也不加重**。susp_success 13→19，6 次真 s2idle，
     `r22: knob 'default'` dmesg 事件在案，cold-enable sanity 零触发（DCS 面
     全应答，与排雷 #11 一致）。
   - **档案落位**：0xC4 = 排雷表 #13（最后一个寄存器级单变量，负结果）；病根维持
     §4.4 判词（DDIC 自身 sleep transition）；条 4 残余位（RBUF / INSERT_DCS
     bit16 / 仪式位族）在可达态可测，但**日用 bloff 默认态结构性免疫 → 只记档
     不开工**。收尾 = 旋钮复值 0 + `knob bloff` + 重启回日常（冷启治愈现屏）。
     附带正面实锤：**r88 默认态真睡日用干净**（12 次 s2idle 零花屏零睡死）。
2. **唤醒命令组完整性**【✅ 静态对拍判负 = 无漏组（2026-10-19）】：stock FDT（flyme
  取证 10-19，运行态全量 fdt 791KB）全部命令组属性 = `qcom,vid-on-commands`/
  `cmd-on-commands`/off/qsync（7 面板变体各一套）；**不存在独立 pre-panel-on 组**
  （downstream dmesg 打点的 pre-on 阶段 = 驱动内部 reset/时序仪式，非 DCS 字节组）。
  我方驱动 `init_cmds[]` = stock `cmd-on-commands` 忠实翻译，**完整含 0x29 后的
  post-on 段**（f0 55 aa 52 08 08 → E1 e1 73 73 73 → E2/E3 45 31 34 a4 族 → E4-E7
  全零，字节级逐条对应）——「wake 漏发 post-on 组」怀疑排除。残留 = 「stock 唤醒
  是否重放同一套字节」仍未抓到 DCS 级运行流（可选挂 0xC4 设备日并行件）。
3. **DSC 唤醒重同步**【✅ 静态对拍判负 = 无缺位（2026-10-19）】：主线 `prep_dsc`
   挂每帧 kickoff 路径（dpu_encoder.c:2102 `_dpu_encoder_prepare_for_kickoff` 内，
   每帧重写 dsc_config + hw_pp enable_dsc；disable 才 unprep）；stock 侧 10-19 F4
   evtlog 实证 `_dce_dsc_setup`/`_dce_dsc_setup_single` 同样每帧 commit 在跑
   （1080x2400 双块参数在案，dpu/evtlog 素材）——两侧同为「每帧 DSC setup」形态，
   唤醒后 kickoff 恢复即重写，结构性「缺位」不成立。此判反而强化 §4.4 r22 判词
   （poison = DDIC 自身 sleep transition）。剩余对拍面 = PPS/threshold 内容值与
   编程时序位（非结构差异）。

   **条 3·余面对拍（S2 内容值表，2026-10-19 宿主轮落档；推算列，不改判词）**

   素材四面：F4 evtlog（18 行 DSC = 6 组三行）× CodeLinaro display-drivers
   `display-kernel.lnx.5.15.1` 分支族源码（evtlog 行号 544/358 落 r1/r15+ 族
   542/359 ± 厂家移行；r2–r14 族 = 538/356，两族语义同形）× stock FDT 面板节点
   （meizu amoled cmd mode boe with DSC，四档 timing 全读）× 主线 fork 代码
   （panel-boe-meizu20.c / dsi_host.c / drm_dsc_helper.c / dpu_encoder.c /
   dpu_hw_dsc_1_2.c；kalama core_major≥7 → 走 1.2 寄存器布局）。

   evtlog 解码（下游签名，r14 版）：

   - `_dce_dsc_setup:538` = [enc_id, topology, cur_roi.xywh, prv_roi.xywh, hact,
     vact] → `3c 9 0 0 438 960 0 0 0 0 438 960` = enc 60 / **topology 9 =
     SDE_RM_TOPOLOGY_DUALPIPE_DSCMERGE** / 全屏 ROI 1080×2400 / prv 全零
     （= enable/modeset 后首 commit 族，6 组 = 6 次 ROI 变更）。
   - `_dce_dsc_setup_single:356` = [enc_id, roi.w, roi.h, dsc_common_mode, index,
     active, merge_3d, disable_merge_3d, 4hsmerge] → `3c 438 960 3 {0|1} 1 0 1 0` =
     **dsc_common_mode = 3 = SPLIT_PANEL|MULTIPLEX（cmd）**，index 0/1 双块。
   - 时序位：`_dce_dsc_setup` 开头 ROI 相等早退 → **stock 的 DSC 重编程 = ROI 变更
     触发**，非字面每帧；主线 = 每 kickoff 无条件重写（幂等，稳态内容同，唤醒恢复
     路径两侧都重写 DSC）→ **时序差**，不动摇条 3 主判。

   逐项对拍表（stock 列 = FDT+源码推算；主线列 = fork 代码推算）：

   | # | 项 | stock | 主线 | 判 |
   |---|---|---|---|---|
   | 1 | pic 1080×2400 / slice 540×20 / slice_count 2 | ✓ | ✓ | 等价 |
   | 2 | DSC 1.2 / bpp 8 / bpc 10 / block_pred 1 / convert_rgb 1 / line_buf 11 | ✓ | ✓ | 等价 |
   | 3 | chunk 540 / slice-per-pkt 2 | FDT `qcom,mdss-dsc-slice-per-pkt=2` | `MIPI_DSI_MODE_DSC_ALL_SLICES_IN_PKT` → `dsc_slice_per_pkt = slice_count = 2` | 等价（小米类②我方无差） |
   | 4 | initial_xmit_delay 512 / initial_offset 6144 / quant 15,15 / flatness 7,16 | LUT（`sde_dsc_rc_init_param_lut`） | VESA 1.2 444 表 | 等价 |
   | 5 | buf_thresh 14 值 / min,max,bpg 15 组 | spec 表 | 同一 spec 表 | 逐值全等 |
   | 6 | slice_bpg 1302 / final_offset 4336 / scale_dec 7 / init_scale 32 / det_thresh 8 / rc_model 8192 / mux 48 / pps_id 0 | ✓ | ✓ | 等价 |
   | 7 | dsc_common_mode 3 / topology DUALPIPE_DSCMERGE / 双块 merge / ob_max_addr 2399 | evtlog 直证 + catalog（`has_reduced_ob_max` 仅 diwali） | 推算同值 | 等价 |
   | 8 | 链路速率 | FDT 四档同值 `panel-clockrate = 0x41351d80` = **1094000000** | `hs_rate` 钉 1094000000（计算值 885.7 注释在案） | 等价（小米类③已被 pin 吸收） |
   | 9 | **first_line_bpg_offset** | **13**（`_get_dsc_v1_2_bpg_offset`：slice_h 20 → ≤30 档） | **12**（VESA 1.2 444 表 8bpp/10bpc） | **内容差（根因项）** |
   | 10 | → initial_dec_delay（DSC_HRD_DELAYS[31:16] / PPS18-19） | **549**（hrd 1061−512） | **526**（hrd 1038−512） | 内容差（#9 派生） |
   | 11 | → nfl_bpg_offset（DSC_RC_OFFSETS_2[15:0] / PPS28-29） | **1402** | **1294** | 内容差（#9 派生） |
   | 12 | → scale_increment_interval（DSC_RC_SCALE_INC_DEC[15:0] / PPS22-23） | **469** | **488** | 内容差（#9 派生） |
   | 13 | **ENC_DF_CTRL.initial_lines** | **3**（Hardent 核公式：pipeline_latency 28/rtl_w 64 族） | **2**（简化公式 92×3+ixd+47；1.2 寄存器路径无 cmd +1——`+1` 只在旧版 dpu_hw_dsc.c） | **内容差** |
   | 14 | **DSC_CFG bit17（cmd 位）** | **0**（该位仅 4HS 变体路径用） | **1**（cmd 模式置位；0x23001 vs 0x3001） | **内容差** |
   | 15 | PPS 载体 | DI=0x0A 传输层包（每次 enable、强制 LP、动态生成） | 标准 DCS 0xA0 长写（`wake_pps_late` 旋钮可切 stock 形态） | 载体差（§4.1/4.2 在册，ProfileID 0xB 特类） |

   判读：
   - 全部内容差 = 一个根因族（#9 flbo 13↔12 派生 #10/11/12）+ 两条独立小差（#13
     initial_lines 3↔2、#14 bit17）。**自洽性两侧各自成立**（stock PPS↔寄存器同为
     13 族，主线同为 12 族；DDIC 按各自 PPS 解码）⇒ 正常显示两态皆工作（日用现量），
     不构成功能错误，也无结构差异级新线索——**只记档不排实验，0xC4 仍是首发实验**。
   - 收窄价值：主机可达维度上，两会话在 DSC 内容层的全部差异 = 表 #9–#15——往后任何
     「会话参数落错档」类假说的对拍面用这张表（外加 PPS 载体 0xA0↔0x0A）。
   - 小米 11 Pro 三类映射：①静态模板覆盖计算值 = 不适用（两侧 DSC 寄存器全由驱动
     算出，DT 只喂几何）；②切片打包 = 等价（#3）；③链路速率钉死 vs 计算 = 等价
     （#8）。附两小经验互证：PPS 长写语义（主线 `mipi_dsi_picture_parameter_set`
     即 DCS 长写，无彼线坑）；亮度 0x0404 回文 / panel-ready 门控 = 我方现役无此病。
   - 寄存器直证位：stock debugfs 活读（`sde_off`/`sde_reg`）对 DSC 1.2 **机制性
     不可达**——`dsc_init_1_2` 不注册 dump 子范围 → off 写入被 `is_valid_range` 拒
     （这也是 F4 只拿到 evtlog 流的深层原因）。stock 列维持推算（分支族已由 evtlog
     行号钉到 r1/r15+ 族 ± 厂家移行；解码在 r14/r1 双族复核）。
4. **寄存器 diff 残余位**【未测】：RBUF/INSERT_DCS（0x44 bit16 仅醒后置位）/
  仪式位族除 0xC4 外的残余，是否有唤醒特定语义。
5. **供电实测矛盾**【低先验】：声明全 1.8V，早轮曾实测 1.2/3.0（板上无测试点，
  只能软件侧查 regulator 状态/使能时序）。
6. **科学解主线**（工程解只是绕行）：stock 会话全对拍——stock 内核 =
  下游 msm-5.x techpack/display，源码公开（CodeLinaro display-drivers），静态
  对拍可行。路线 = S1 stock wake 包全枚举 delta 表（已做，H1 判负）→ S2
  DPU/DSC 对拍（静态 + stock 侧动态 dump）→ S3 档位/会话探针 → S5 XBL/panel-DB
  vendor 逆向（最后）。XBL splash 会话本身建在 60Hz 档（0x91 块 60Hz 族值
  实锤）——"会话建立语境"维度仍是唯一未被系统扫描的嫌疑域。

---

## 7. 移植者检查单（在你的 DSC AMOLED 机上撞到同款病时）

1. **先分相**：冷启动花屏（多为 demura/会话建立问题，DCS 级可修）≠ 掉电唤醒
   花屏（本案）。别把两个案子的证据互相引用。
2. **先建确定性证据**：遮罩图案是否跨断电不变（拍照 + 能量图相关性）；截屏
   是否无损（分清渲染栈/通路）。确定性 + 帧缓冲干净 = 值得做科学线。
3. **排雷顺序**（按成本）：init 序列与 vendor 逐字节对拍 → 唤醒重放变体
   （最小 wake 起步）→ 供电/复位/时钟单变量 → 寄存器三态对拍（好/坏/stock，
   注意泊车态 vs 活态）→ 全量 DCS 快照（警惕只读毒寄存器——本机
   page-0 0x01 一读必楔死命令链，读档要先做安全集普查）。
4. **查你的驱动在"会话语境"上与 vendor 的结构差**：ProfileID/档案类特判
   （本机 0xB = 主机不发 PPS）、PPS 包形态（0x0A 传输层 vs 0xA0 DCS）、
   压缩包有无、on/off 命令组结构（pre-on/post-panel-on）、刷新率档位语境。
5. **保命工程解先行**：本机 bloff 语义（AMOLED 黑帧近零功耗）值得第一时就
   上——但务必保留冷启动完整会话建立路径（recovery 双遍教训），且想清楚
   它只防新增不治已花。
6. **读 vendor 参考时**：下游 techpack/display 源码公开的部分优先静态对拍；
   XBL/固件侧逆向放最后（本机 XBL splash 建的会话语境至今仍是头号未知域）。

---

## 8. 资料地图（哪份事实在哪）

| 想查什么 | 在哪 |
|---|---|
| 面板驱动 / 调试旋钮源码 | <https://github.com/RiverKawa271828/linux-mobile-ports>（分支 `meizu20-t4b`，`panel-boe-meizu20.c` + profiles） |
| 设备包 / 内核配置 | <https://github.com/RiverKawa271828/pmaports>（分支 `phoenix`） |
| Demura/sleep-out 自重载机制 | 公开专利 EP4089666A1；Novatek 页选/解锁命令族 = mu_aloha Kailua 面板 XML 公开面 |
| 下游 msm display 源码（stock 参照） | CodeLinaro display-drivers（display-kernel.lnx.5.15.1.r*-rel） |
| 完整实验叙事（深夜二/ProfileID 破案、r22 诊断轮全系列、E/H 实验判据读数、遮罩能量图档案） | 私有工作区实验日志 + `panel-diag/`（未公开；本文已收编其全部结论） |
| 睡眠线的「睡醒」问题 | [SUSPEND-S2IDLE.md](SUSPEND-S2IDLE.md)（与本案不同域：那是系统电源态，这是面板电源态） |
