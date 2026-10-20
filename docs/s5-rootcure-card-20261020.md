# S5 根治执行卡（2026-10-19 晨落盘，下会话照此做；用户拍板「下个会话逆向试试，我要根治」）

> 背景：0xC4 设备日已收官（0xC4 洗清 = 排雷表 #13，前提证伪 = bloff 连 suspend 也罩，
> 日用结构性免疫）。用户诉求升级 = **根治**：`knob default`（面板真睡）→ 真睡×5 也不花。
> 本卡 = 花屏战役科学解的最后主线（S5）+ 一条强烈建议的廉价首枪。
> 每项独立可停；commit 不 push；fastboot 单通道 / 刷写用户在场 / r89 红线件不上机照旧。

## 0. 目标与判据（钉死）

- **终态判据**：`knob default`（bloff 关，病灶可达态）→ 真睡 ×5 眼判**全干净**
  （dsi_err status=4 每轮一条 = 链路真断 marker 佐证可达态成立）+ 冷启/bloff 零回归。
  达成 = 根治补丁形态讨论（日用默认态要不要关 bloff 留用户拍板）。
- **成功判据继承**（09-30 钉死的升级版）：不只是「XBL 序列重放后不需要 bloff」，
  而是「真睡干净」——注意 XBL 只管冷启动（我们冷启动本来就干净），其价值 =
  读懂「正确会话」如何建立；真正要治疗的路径 = 我方 sleep→wake 的重载语境。

## 1. ★廉价首枪（✅ 10-21 设备日收官——**判负：内容值轴清零**；判读详录 =
   PANEL-CORRUPTION §6 条 4）：stock-DSC-content 旋钮 A/B

- **✅ 判词（10-21，用户在场眼判）**：`msm.msm_dsc_stock_content`（fork
  `26ab9bf3e442`：flbo 12→13 全家族 + initial_lines 2→3 + DSC_CFG bit17 cmd
  清位，一次钉 S2 表 #9/#13/#14 三靶；0644 运行时可写，populate 挂每轮
  host power-on = 下次睡眠即生效）→ r90/v70 双腿升级全绿（#91 + 读回
  dca69c1d 对 ✓）→ 控臂（旋钮 0）花屏 6/6 → 治疗臂（旋钮 1，机制面全绿：
  ctx PPS 三字段精确翻转 + **DDIC 0x91 读回镜像同步** = 双端同值实锤）
  真睡 ×2 → **2/2 全花 = 判负**。
- **结论**：H1（包形态）+ 本轮（内容值 #9-#14 全集）双判负 ⇒ 标准命令域
  主机可达维度全部排除 ⇒ 病根在 vendor 专有域/非命令维度 → **S5 RE 本体
  升为主线，§6 后半场触发条件达成**。×5 协议按判负提前锁死（字节级验证后
  续跑无新信息）。
- **判读面勘定**：Meizu22 的 0x0A→0x9C marker **不可平移**（本 DDIC 0x0A
  机制性不可读）；改用 **DDIC `0x91` = PPS 镜像读回**（192B 重复块，decoder
  档案 ground truth，本轮机制验证的主力证据）。
- （原做法记录）为什么值得先做：H1（knob stock）只复刻过**包形态**（无 0x07/PPS
  后置 LP/全 LP），**从未测过 DSC 内容值**。S2 内容值对拍表（10-19 深夜，PANEL
  §6 条 3·余面）钉出我们与 stock 的会话参数差全集 = 表 #9-#15：**flbo 13↔12
  根因族**（→idd 549↔526 / nfl 1402↔1294 / sii 469↔488）+ **initial_lines 3↔2** +
  **DSC_CFG bit17** + PPS 载体 0xA0↔0x0A（已有 wake_pps_late 旋钮）。Novatek
  demura 专利（EP4089666A1）= 补偿重载**按会话建立时收到的模式参数自选档案**——
  若重载键在这些参数上，我们每次真睡都把 DDIC 引到错误档案。
- （原做法记录）做法：fork 加一个 stock-context 旋钮（一次把 flbo 族/
  initial_lines/bit17 钉到 stock 值；参照 0xC4 旋钮件 `c1d84dcf80ec` 手法，
  module_param 0644）→ r90/v70 → `upgrade.sh --i-am-present --apk … --esp …`
  （⚠显式 `--apk/--esp`，默认会取 r89 红线件）→ knob default + 真睡 A/B 眼判。

## 2. S5 逆向本体（主线，纯宿主可先跑）

- **素材地图（全部在库，勿重挖）**：
  - XBL 本体：`meizu20-m1/backups/flyme-ota-b-20261002/images/xbl_a.img` +
    `xbl_b.img`（3.6MB aarch64 ×2，9008 全分区备份；另见
    `artifacts-uefi/uefi-partition-dig-20260930/` 的 xbl_a/b.bin 提取件）；
  - DisplayDxe 半程成果：`artifacts-uefi/uefi-partition-dig-20260930/uefi_a-fvtool/`
    （`Panel_meizu_amoled_boe_dsc_cmd.xml` 已提取 = `9ed70eaf`；**ProfileID 0xB**
    本机 BOE 全库唯一特类；DisplayDxe override key 表 = 0x3e998 基址 / 46B 步长 /
    151 条已定位）；
  - 计划档：pmos_linux `docs/meizu20/xbl-session-science-plan.md`（H1-H4 + S1-S5
    阶梯 + 方向修正注记：主参考 = stock 内核、XBL = 最后手段——本卡把 XBL 升格
    为收官手段）；
  - 弹药库（勿重复投）：`panel-corruption-gpt-handoff-20261007.md` +
    PANEL-CORRUPTION.md 排雷表 #1-#13 全档 + r22 知识（`0x01` 读毒药 / f0 55 aa
    52 08 页解锁家族 / comp_sel 档案切换实测）。
- **目标分层**：
  1. **XBL 冷启动会话**：面板上电时序 / 命令表 / 「语境」维度（非命令：时序窗口、
     引擎状态、PLL 形态、会话建立顺序）——objdump/Ghidra 可拆（aarch64 裸固件，
     无签名校验阻碍分析）；
  2. **DisplayDxe vendor 路径**：ProfileID 0xB 消费端（NDA 闭源在册，二进制逆向
     是唯一路）+ override key 表语义补完（哪 151 个值覆写什么）；
  3. **产物形态** = vendor 重放清单（页写序列/非命令维度清单）→ r22 旋钮家族
     （dcs_write / session probe 现役在 r88 驱动内）上机重放验证。
- **预期校准**（09-30 原版照旧）：一个会话现实交付 = 定位显示模块 + 命令表结构；
  完整语境提取可能 2-3 会话 + 设备日验证。
- **★外部锚点（10-21 魅族22 仓白捡，检索模式直接抄）**：见 §5——DisplayDxe 搜
  「sleep-out(0x11) 前的 DCS 冷初始化写」+ INTF_TIMING_ENGINE_EN 写值邻域
  （其设备 0x323AC 处写 0x1801011）+ **vendor 源码互证 lane**（读源码非逆向，
  最便宜，§5a）。

## 2a. 10-21 排面修正（用户拍板「开干」本轮执行序）

- 本轮 = RE 纯宿主段先行：**vendor 源码互证（§5a）→ DisplayDxe 锚点检索（§2）**；
- **首枪 A/B 挂设备回 pmOS 窗口**（设备现役 Flyme、去向待用户拍板——升级当天反正
  走 upgrade.sh 磨合链路，半天出判词，与 RE 产物互不阻塞）。

## 3. 顺序与预算

- 开工第一件照旧 = stable 检查（30 秒只报不转）。
- 首枪（半天）→ 不治即转 S5 RE（上不封顶）；RE 有阶段性产物（模块定位/命令表）
  也算交付，判词落档再排下一段。
- 判读无论正反都落 PANEL-CORRUPTION §6 条 4/条 6 + 本卡打勾 + 记忆簿更钉。

## 4. REA 工具链（✅ 10-19 晨已装好并实测跑通；用户提名 <https://github.com/morluto/rea>）

- **安装形态**（用户纠偏后定案 = 装在当前工作容器里，不用再嵌 Debian 容器）：全部
  落 `/home/ri/work/meizu20/s5-rea/`（宿主持久 fs，跨会话存活，删目录即卸载）：
  - REA CLI 6.7.0：`s5-rea/rea-cli/node_modules/.bin/rea`（npm prefix 安装）；
  - Ghidra 12.1.4（doctor healthy）+ Temurin JDK 21；
  - **环境一行**：`source /home/ri/work/meizu20/s5-rea/env.sh`（设
    GHIDRA_INSTALL_DIR/JAVA_HOME/PATH + rea alias）。
- **冒烟全通（真素材）**：`rea analyze` + `rea inspect-native-api` 对 xbl 代码段 →
  Ghidra 12.1.4 lane（AARCH64:LE:64:v8A）函数边界/伪代码分类/API 边界全出
  （evidence 在 `s5-rea/out/`）。
- **★xbl 输入配方（当轮啃出的硬知识，下会话直接抄）**：Qualcomm xbl 的 ELF 头是
  **ELF32 + `e_machine=1`（占位值）**，REA 直读必拒「unsupported ELF architecture」。
  解法 = 按 program header 切出代码段再 raw-binary 喂：
  ```bash
  # xbl_a.img: ph0 = 代码段 off=0x74 size=0x20000 vaddr=0x22126000（真身 aarch64）
  dd if=xbl_a.img of=xbl_a-code.bin bs=1 skip=$((0x74)) count=$((0x20000))
  source s5-rea/env.sh
  rea analyze xbl_a-code.bin --target-format raw-binary --architecture arm64 \
    --entry-point 0x22126000
  ```
  （各 xbl/xbl_config/devcfg 的段表先 `readelf -l` 或 python struct 解一遍再切；
  xbl_b 同法。分析产物 ephemeral——长会话用 `--snapshot` 落本地分析库加速。）
- **对 S5 的映射**：
  - xbl 代码段 → REA native lane 伪代码/xref 读面板会话建立（上电时序/命令表/语境）；
  - `uefi_a-fvtool` 已提取的 DisplayDxe PE（UEFI AARCH64 = PE/COFF，格式良 → REA 直吃，
    无需 raw-binary 套路）→ ProfileID 0xB 消费端 + override key 表（0x3e998/46B/151
    条）语义补完。
- **授权用途**：自有设备互操作性研究（REA 声明的合法场景，本案正是）。

## 5. 魅族22 移植仓交叉印证（2026-10-21 评估入卡；素材 = github `14185638/Linux-MEIZU_22`
   设备分支 `Linux-7.2-MEIZU_22-M2582`，10-17 修复批 + 10-05 基础提交）

- **定性**：SM8735 "tuna"（DPU 12.3）+ CSOT VTDR6130A 1200x2670 DSC 2×600x30
  命令模式面板的第三方主线移植，与我们无关联。边界 = SoC/面板/症状均不同
  （他 = bring-up 常显花屏 + 冷启 TE 死；我们 = 真睡唤醒才花、两侧各自自洽）；
  **字节不通用、模式通用**。仓无 README/issue，全部主张在 commit message 层，
  但每个修复带实测数字（137.625MHz byte clock / 0x0A=0x9C / 缺三连半数冷启 TE 死）。
- **★flbo 实测案例（他修的就是真花屏，病灶 = DSC 内容值）**：`panel-meizu-m2582.c`
  `m2582_apply_table_rc()` 注释——「decoder 要 flbo=**15**，尽管 DSC 1.2 与 factory
  推导对 30 行 slice 都给 **13**；encoder/decoder 都吃此字段，错值使两者 rate-buffer
  模型每 slice 行失步；**实测 13 = 画面下六分之五噪点，15 = 整幅正确**」⇒
  ① PPS 内容值 = 承重墙非摆设，**单字段即可翻 noise↔clean**；
  ② DDIC 解码端 = ground truth，可同时推翻规范表与厂商推导。
  **对首枪的含义**：stock 重放仍是对的第一枪（stock 13 族本机现量干净）；**若整包
  重放后仍有残余花，别排除 DDIC 想要第三种值——按他这招单字段实测迭代**
  （flbo 是已证明的杠杆）。
- **S2 表 #9-#12 全族机制陈述**：`48287575`（其显示基础提交）——「encoder ICH 精度
  与 PPS 模型漂移 ⇒ reconstructs corrupted output；flbo 由 slice 高度导出
  （30 行→13），**nfl_bpg_offset / initial_dec_delay / scale_increment_interval
  随之**」+ PPS 必须与 encoder 同一 `drm_dsc_config` 打包（`drm_dsc_pps_payload_pack`；
  其 DT 的 PPS 占位包曾带 flbo=1 = 反面教材）。
- **S2 表 #13/#14 两靶方向实证**：`fb4e8c5d`——
  ① initial_lines：upstream 简化公式（92×3+ixd+47）给 2，vendor
  `sde_hw_dsc_initial_line_calc()` 给 3（diff 全文转录；常量 pipeline_latency=28 /
  rtl_output_data_width=64 = 我方 S2 表所记 Hardent 族同源）；我方 fork
  `dpu_encoder.c:1966` 同款简化公式 → 旋钮 = 直接钉 stock 值 3；
  ② **BIT(17) = video-mode 位、仅 VIDEO 模式置位**（「BIT(17) 让 decoder 用上预期
  slice 时序」）；我方 fork `dpu_hw_dsc_1_2.c:235` 同款 cmd 模式反置位 bug
  （stock=0x3001 / 我方=0x23001，S2 #14 方向吻合）→ 旋钮 = cmd 模式清位。
- **新锚点 → §2 DisplayDxe 腿**：
  ① 其 INTF_TIMING_ENGINE_EN 写 **0x1801011**（bits 4/20/24，「DisplayDxe 形态」，
  其设备位置 0x323AC；写 1 则 tear-check 不锁帧、cmd kickoff 全超时）→ 我方
  DisplayDxe 同类写值可对读（我方 fork 写 1，`dpu_hw_intf.c:283`）；
  ② **面板冷初始化三连写在 DisplayDxe、sleep-out(0x11) 之前**：
  `f0 aa 10 / 65 04 / cf 4b`（settle 20ms；power-on set 后 300ms；缺则半数冷启
  TE 死、0x0A 读 0x0C 非 0x9C）→ 我方 DisplayDxe 检索模式 = 「sleep-out 前的
  DCS 写」；
  ③ te-source mdp_vsync_p / DATA_HCTL_EN cmd 模式 / hw_vsync_mode=1 —— 我方
  fork 已是新形态或已配，无 gap。
- **0x0A GET_POWER_MODE 读回 = DDIC 状态客观 marker**（期望 0x9C）→ §1 首枪
  判读面 + 后续实验矩阵通用。
- **B-list 候补旋钮（首枪不治后再议，勿提前摊开）**：
  ① **VBIF QoS remap**——upstream 只从 WB encoder 编程，cmd 面板读帧一直在复位
  优先级；我方 `sm8550_vbif` 用 sdm845 表 {3,3,4,4,5,5,6,6}，kalama factory 表待
  §5a 互证；
  ② **首帧杀 vblank 族**——upstream 首次 ping-pong 超时即注销 RD_PTR 回调
  （vblank_refcount 卡 1，vblank 永死）+ frame-done timeout = 5/vrefresh（mode
  clock 源 link rate → vrefresh 虚高、27ms 太短）；其修 = vendor 84ms 平值 +
  仅 PANEL_DEAD 注销。我方 fork 两处同款形态在（`dpu_encoder_phys_cmd.c:203` /
  `dpu_encoder.c:2140`）——**候补解释我方冷启 restart 双遍怪癖**；
  ③ tearcheck sync_cfg_height 2×vtotal vs 其 vendor 0xFFF0（微差，暂不动）。
- **「90Hz 修好」勘定** = `121f62e0` both scan rates（120@30/20/10 + 90@30/18/10
  两档 ADFR 族按 mode 名选尾），**非花屏条目**。
- **5a. vendor 源码互证 lane（✅ 10-21 收官；sparse 克隆落
  `meizu20/s5-rea/vendor-display-drivers/`，branch `display-kernel.lnx.5.15.r10-rel`，
  techpack 布局 = 驱动在顶层 `msm/`；三靶全中）**：
  - **initial_lines 公式原文** = `msm/sde/sde_encoder_dce.c`
    `_dce_dsc_initial_line_calc()`——源码注释即 **"Hardent core config"**，常量
    rtl_max_bpc=10 / rtl_output_data_width=64 / pipeline_latency=28，
    `dsc->num_active_ss_per_enc` 入式；与魅族 22 转录逐字同族。
    **旋钮值 = stock 3 钉死**。
  - **flbo 推导原文** = `msm/sde_dsc_helper.c` `_get_dsc_v1_2_bpg_offset()`：
    slice_h<8→2(sh-1)；<20→12；**≤30→13（我方 slice_h=30 正落此档 = stock 值出处）**；
    <42→14；≥42→15。魅族 22 面板要的 15 = 最高档——同表印证 DDIC 预期可越过推导档位。
  - **kalama VBIF factory 真值 = 本机 stock FDT**（vendor catalog 为 DT 驱动
    `qcom,sde-vbif-*` 解析、非 mainline 硬编码表；`fdt/stock-fdt.dts:30027-30040`）：
    `qos-rt-remap` = 16 项 `{3,3,4,4,5,5,6,6, 3,3,4,4,5,5,6,6}`；
    `default-ot-rd/wr-limit` = 0x28/0x20（与魅族22 tuna factory 同值）；
    `dynamic-ot-wr-limit` = {0x3b53800→2, 0x76a7000→6, 0x1da9c000→0x10}；
    `vbif-size` = 0x1074（mainline sm8550_vbif.len=0x1040 微差）。
  - **B-list① 降级记档**：我方 fork（newer upstream）`dpu_plane.c:416`
    `_dpu_plane_set_qos_remap` 已做 per-plane QoS remap（非魅族22 旧树「只从 WB」
    形态）；catalog 8 项 sdm845 表在 XIN 0-7 与 factory 16 项表**等值**，差异只在
    XIN 8-15 未编程（plane SSPP 的 XIN 用不到该域）→ 对我方花屏的实际 delta 很小，
    降级为记档不开工。

## 6. DisplayDxe override 键表语义补完（✅ 10-21 前半场收官；后半场挂起）

- **素材**：`uefi_a-fvtool/.../DisplayDxe`（323584B PE32+ AArch64；ImageBase=0，
  file offset == RVA；节 .text 0x1000-0x3a000 / .data 0x3a000-0x4e000）；
  表 @0x3e998，46B×151 条。
- **表格式解开 = XML schema 全量键表（非补丁表）**：每条 = {内联键名（NUL 结尾，
  ≤27B）+ name-len u16@+28 + value-type u16@+30（2=int/4=bool/5=命令串/7/8=数组）
  + 值域指针 qword@+32}。151 键 = DisplayDxe 面板 XML 的完整参数 schema；值 =
  所选面板 XML 解析回填（HIGHLOW 重定位；13 对 PHY timing override（四十）已解）。
- **键族盘点**（全 151 键已抽，脚本可重放）：
  - ①**DSC 族 9 键**（#42-50：Enable/Major/Minor/Scr/ProfileID/SliceHeight/
    SliceWidth/SlicePerPacket/ChromaFormat）——**无 flbo/initial_lines/bpc 键** ⇒
    DisplayDxe 冷会话 PPS 的 rate-control 内容 = 代码内硬编码算法（= §5a vendor
    源码同族，slice_h≤30→13 档）。**推论（置信中高，PPS 生成路径未逐指令验证）：
    冷会话（DisplayDxe）与 stock Flyme 内核会话同为 13 族；12 族只有我方内核喂过
    ⇒ 强化 §1 首枪「DDIC 偏好档案按会话参数选择」的落档面。**
  - ②**TE 族 12 键**（#98-109：TECheckEnable/SetDisable/UsingDedicatedTEPin/
    TEvSyncStartPos/ContinueLines/StartLineDivisor/PosSafetyMargin/
    BelowSafetyMargin/PercentVariance/RdPtrIrqLine/Select/InitVal）= stock 侧
    tearcheck 编程参考面（Meizu22 TE pacing 修复的我方对应；值未解，后半场）。
  - ③**DSIDemuraPanelIDReadCMD(#116)/DSIDemuraPanelID(#117)** = demura 面板 ID
    读命令键（DDIC OTP demura ID 读取入口——r22 档案假说相邻，后半场语义）。
  - ④其他：DSIDynamicRefreshRates(t8)/DSIRefreshRate/DSILP11AtInit/AutoRefresh
    族/背光 4 键/I2C 与 EDP 族（本机惰性）。
- **负结果三件**：①`0x01801011` 全镜像 0 命中（DPU 代差——我方 DPU 9.0
  INTF_TIMING_ENGINE_EN=offset 0x00、INTF_CONFIG2=0x60，Meizu22 DPU 12.3 写值
  不迁移）；②0x1011 立即数簇（0x37de0±）= 面板时序小整数表假阳性；③
  `39 f0 55 aa 52 08 03 6f 00` 内联块紧贴 VirtioDSI 640x480 兜底模板 =
  qemu 模拟路径惰性件（诱饵，非本机面板序列）。
- **后半场挂起**：值域解码（除已解 13 对）+ TE 键值对读（vs 我方 tearcheck 现值）
  + demura ID 命令键语义。**▶触发条件已达成（10-21 首枪判负）——升为下会话主件**。
