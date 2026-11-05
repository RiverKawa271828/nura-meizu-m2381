# S5 续轮执行卡：唤醒重载路径对照 + DDIC 考古预备（2026-10-29 排程，下会话照做）

> **✅ 宿主段收官（2026-10-29 当日轮；全量判词 = PANEL-CORRUPTION §6 条 9
> + s5-rootcure-card §5 B-list 终审）**：
> §1 七缝对拍全部定谳——缝 1 头号新判据 = **stock 唤醒 = 冷启等价**
> （unprepare 尾 reset 拉低+VREG 全断 / resume 全套上电+reset+ON 表+PPS 每
> enable 重发）vs 我方 sleep 态留轨重放（M3）＝唤醒语境差定位；缝 2 双 INTF
> 轴不适用+PHY save/restore 我方在位；缝 3 VBIF halt **B-list ④ 除名**（vendor
> 仅 secure 路径有 halt）；缝 4 m2582 fb4e8c5d 修法移植 = **D4-2 patch 候选
> 成立**；缝 5 P2 旋钮 = stock 语义（新列 D4-3 默认翻转）；缝 6 页解锁域
> kernel 半边排除（vendor 不做解锁，全在 DTSI payload 透传）；缝 7 留设备日。
> §2 DDIC 考古宿主半边收官——stock FDT 验尸（ESD=LP 读 0x0A 威 0x9C 在用/
> 双解锁域并存/无 demura-id）+ **家族锁死 Novatek NT37700 系（BOE 委工，
> 四链吻合：F0 55 AA 52 08+page 宏逐字同/FF AA 55 A5 工程域同/FB 01 MSB/
> ESD 模式同族）** + D1 判读表落地（0x0A/0xDA/DB/DC/0x04/0xDF=0x4D/0xA1=B5 01/
> 0x91）+「0x0A 不可读」新候选 = 读前页域（D1 探针增补：读前回 page 0）。
> 附赠判读 = 0x10a 编码勘误（payload=data[7]=0x0A；flags=data[3]=0x01=LP）。
> **设备日拼车排面（§4）不变**：D1-D4 + S1/S2，一窗双案留用户拍板。

> 排程：用户 10-29 拍板「下个会话做，你安排好」（语境 = XBL RE 收官后
> 「还应该增加哪些逆向」的答复：固件逆向面已穷尽，转 vendor 源码对照 +
> DDIC 三层考古）。队列位置 = ③（①ABL 表 ✅ ②XBL RE ✅）；本卡 = ③
> **宿主段先行**，设备日件与 S2IDLE 二段拼车（见 §4）。
> 零设备纯宿主——设备现役 iOS 链不挡宿主段。每项独立可停，commit 不 push。

## 0. 背景与判据（一句版）

- XBL RE 收官（10-29，../XBL-RE.md）：固件三面（xbl/abl/uefi DisplayDxe）
  全挖穿或判死；花屏病灶（真睡唤醒重载）的语境在 **vendor 内核源码域**，
  不在固件。
- 本轮判据：产出**「唤醒重载语境差全集」对拍表**（stock vendor 驱动 vs
  我方 fork，逐项判 等值/缺失/顺序差）+ B-list ④⑤② 三族的 fork 实差
  定谳 + DDIC 候选型号圈定与同族驱动寄存器地图预备——设备日验证件挂
  §4 拼车。

## 1. 主件①：vendor wake 重载路径源码对照（纯宿主，半天-一天）

- **素材（全在库）**：
  - vendor 树：`/home/ri/work/meizu20/s5-rea/vendor-display-drivers/`
    （branch `display-kernel.lnx.5.15.r10-rel`，驱动在顶层 `msm/`）；
  - 我方 fork：`/home/ri/work/linux-mobile-ports`（branch `meizu20-t4b`）
    ——dpu1 各件 + 自写面板驱动 panel-boe-meizu20.c + r22 旋钮家族
    （dcs_write / session probe / wake_pps_late，现役 r91 驱动内）。
- **对拍七缝（按先验排序）**：
  1. **suspend→resume 重载序列**：vendor `msm/dsi/dsi_panel.c`
     （suspend/unprepare/prepare/enable 全链发了什么：sleep-in 序列/
     页解锁/PPS 重发位）vs 我方 panel-boe-meizu20.c 唤醒路径——
     **头号缝**：重发集合与顺序差。
  2. **双 INTF 关闭顺序 + DSI PHY 状态保存恢复**（B-list ⑤，android-
     mainline-port skill display.md 已确认根因族）：vendor 关闭顺序
     （先停 INTF 再清 CTL）+ PHY suspend/resume save-restore vs 我方
     `dpu_encoder.c`/`dpu_encoder_phys_cmd.c`/`dsi_phy` 现状。
  3. **VBIF AXI halt 握手**（B-list ④，`dsi_err status=4` 同 marker）：
     vendor `sde_power_handle`/power-event 钩子 unprepare 序列 vs 我方。
  4. **首帧杀 vblank 族**（B-list ②）：我方两处同款形态已知
     （`dpu_encoder_phys_cmd.c:203` RDPTR 首超时注销 +
     `dpu_encoder.c:2140` frame-done 5/vrefresh）——vendor 84ms 平值 +
     仅 PANEL_DEAD 注销，照魅族 22 `m2582` 修法出 patch 候选。
  5. **PPS 重发位**：stock 唤醒时 PPS 从哪条路径重发（init 序列内/
     link-restart 单发）vs 我方 wake_pps_late 旋钮语义。
  6. **页解锁域**：stock 重载路径是否进 `f0 55 aa 52 08` 域（XBL-RE
     §6.4 候选 a 的 kernel 侧验尸）vs 我方（从未进）。
  7. **DSC 重编程触发条件**：stock ROI 变更才重编程（（九十二）判读）
     vs 主线每 kickoff 幂等——唤醒首轮的 kickoff 数对拍。
- **落档**：对拍表进 PANEL-CORRUPTION §6 新条（条 9）；B-list 三族
  判词更 s5-rootcure-card §5 B-list；每缝给「旋钮/补丁候选 + 上机验证
  判据」，可上机件排 §4 拼车。

## 2. 次件②：DDIC 考古·宿主半边（插空可停）

- **第一步（5 分钟）**：stock FDT 面板节点验尸——
  `flyme-forensics-20261019/` 的 fdt（791KB）dtc 后查 panel 节点
  compatible/命名/`qcom,demura-panel-id` 有无 → 先圈 DDIC 家族线索。
- **指纹检索（纯宿主主力）**：以**页解锁魔数 `f0 55 aa 52 08`** +
  panel_id 首字节 **0x4D** 为指纹，GitHub 定向搜同族下游内核（小米/
  OV/一加 2022-2023 旗舰，BOE 1080x2400 AMOLED DSC cmd-mode 面板代）
  ——同 DDIC 驱动的 .c = 全寄存器表/页解锁族/内部状态/demura·OTP 通道
  明文。候选家族先验：Novatek NT37xxx / Raydium RM672xx / BOE 自研。
- **交付**：候选型号清单 + 上户口判读表（0x04 DDB / 0xDF 23B / 0xA1 4B /
  0xDA 读数 → 对哪个型号）+ 同族驱动的「可读状态寄存器地图」摘录
  （demura/OTP/解码错误计数器通道优先）——喂 §4 双快照。
- **已定谳勿重查**：dip.img（QCOM demura 数据包分区）= **1MB 全零**
  （10-29 实测）⇒ demura 数据面不在分区；splash.img = logo 库无关。

## 3. 工作流卡（惯例照抄）

- 开工第一件 = 读本卡 + nura AGENTS 现态；设备默认不在线，全部宿主活。
- REA/环境：`source /home/ri/work/meizu20/s5-rea/env.sh`（本轮大概率用
  不上 REA——源码域；若做 §3 轻量内核 Image 代表性验证才用）。
- 可选插空（不主攻）：stock kernel Image（flyme-ota-b images/boot*.img
  可拆 zboot）strings/符号级对拍 vendor 源码树 = Flyme 私有补丁代表性
  验证，半天活，判「源码树是否够代表」。
- 红线照旧：iOS 工作区文件不碰；§8 政策（结论/原创脚本公开，派生物
  私有面）；commit 不 push（推送窗口 = 用户）。

## 4. 设备日拼车排面（等设备回 nura 链 + 用户拍板窗，与 S2IDLE 二段同窗）

一窗双案，由用户定哪案主线：

| # | 件 | 成本 | 来源 |
|---|---|---|---|
| D1 | **DDIC 上户口**（0x04/0xDF/0xA1/0xDA 读回定型号） | 5-30 分钟 | 本卡 §2 |
| D2 | **会话双快照**（冷启干净 vs 真睡唤醒花屏，可读寄存器全量 diff，0x91 PPS 镜像 192B 已验证可读） | 半天 | §2 交付喂此件；**档案假说可证伪化主力** |
| D3 | **语境差三件对拍**（页解锁域 / PMIC GPIO 上电拍数 / OLED 轨电压，XBL-RE §6.4） | 随 D2 顺带 | XBL-RE.md |
| D4 | **B-list 旋钮上机**（①② 对照出的 patch 候选 + 首帧杀 vblank 件） | 视 D0 产出 | 本卡 §1 |
| S1 | **S2IDLE 二段**（E 长跑过夜 + 段 4 kprobe，卡 = 10-24 排面钉） | 一夜+半天 | 九十七轮 |
| S2 | **设备现态探测**（恢复首项，10-24 ⚠钉） | 10 分钟 | 九十七轮 |

- **可能的前置内核轮**：DDIC 读回通道若缺 page-unlock 前置的 dcs_read
  旋钮（r22 家族现役 dcs_write/session probe 在 r91 驱动内），与 D4
  patch 拼车一个内核轮出件（r92/r93）再设备日——D1 前先探针确认读回
  通道现态。
- 设备日纪律：fastboot 单通道 / 刷写用户在场 / r89 红线件不上机照旧。

## 5. 判据与收官形态

- 宿主段收官 = §1 对拍表 + §2 候选清单落档（PANEL §6 条 9 + 本卡打勾
  + AGENTS/记忆更钉 + commit）；设备窗收官 = D1/D2 判词（档案假说
  立/倒）+ S2IDLE 二段判词（A/C/D/E 选路）各自落卡。
- 无论正反都落档；判词不升级不降级，一切以 D2 diff 说话。
