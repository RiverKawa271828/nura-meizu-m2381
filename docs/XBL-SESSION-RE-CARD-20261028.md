# XBL 会话语境逆向 — 花屏根治 S5 下一手卡（2026-10-28 排程）

> 排程：用户 10-28 拍板「排程加入到 abl 逆向之后，用同一个配方，同样出具完整
> 逆向文档，到时候看情况推送到远端仓库」。
> 队列位置 = ②（① = ABL fastboot 命令表，docs/ABL-FASTBOOT-TABLE-CARD-20261028.md）。
> **执行等用户点名**（随 ① 的开工节奏）。零设备纯宿主——设备现役 iOS 链不挡本件。

## 背景与目标（花屏根治 S5 主线）

- S5 排除链现状（全量 = docs/s5-rootcure-card-20261020.md + PANEL-CORRUPTION.md §6）：
  DisplayDxe 标准域清零（151 键 schema/冷 init-term/demura/TE/dis_id 六面定谳，
  10-21）+ vendor display 源码互证三靶全中 + 0xC4 洗清 + stock-content 旋钮判负
  ⇒ 内容值轴与标准命令域全排除，**病根收缩到两候选**：
  1. **XBL 域会话语境（本卡主攻）**：XBL splash 建立的会话里的**非命令维度**——
     面板 ID/配置选择（GETPANELID/GETPANELCONFIG 平台调用，10-21 dis_id 勘误
     指认到 XBL 域）、上电时序窗口、DPU 流特征、DDIC 内部状态；r22 档案假说
     （ProfileID=0xB vendor 会话存续）的 XBL 侧证据链。
  2. 首帧杀 vblank kernel 旋钮（B-list 唯一剩余候补）——XBL 挖穿仍不解释时回手。
- 成功判据（根治卡升级版，勿降级）：不是「XBL 序列重放后不需要 bloff」，而是
  「真睡干净」——XBL 只管冷启动（冷启动本来就干净），其价值 = **找出 splash
  会话里主线链缺失的语境维度**。

## 素材（全在库，零设备）

- XBL 本体：`meizu20-m1/backups/flyme-ota-b-20261002/images/xbl_a.img` +
  `xbl_b.img`（3.6MB ×2）；dig 提取件 `meizu20-m1/artifacts-uefi/
  uefi-partition-dig-20260930/xbl_a.bin` + `xbl_b.bin` + `xbl_config_a.bin`。
- 相邻域素材（交叉引用用）：`uefi_a-fvtool/` 已提取 DisplayDxe PE（六面底账已挖
  完，standard 域结论直接复用勿重挖）；ABL（bootargs `dis_id=4DB501` 侧写）。
- 交叉印证件：vendor display 源码 sparse 克隆 `s5-rea/vendor-display-drivers/`；
  魅族 22 移植仓对拍记录（PANEL-CORRUPTION §5/根治卡 §5）。

## 配方（同 ABL 件：REA 主刀 + abl-re 配套；XBL 输入配方照抄根治卡 §4）

- **★XBL 输入配方**（根治卡已啃出的硬知识：Qualcomm xbl ELF 头 = ELF32 +
  `e_machine=1` 占位值，REA 直读必拒 unsupported ELF architecture，须切段喂）：
  ```bash
  # xbl_a.img: ph0 = 代码段 off=0x74 size=0x20000 vaddr=0x22126000（真身 aarch64）
  dd if=xbl_a.img of=xbl_a-code.bin bs=1 skip=$((0x74)) count=$((0x20000))
  source /home/ri/work/meizu20/s5-rea/env.sh   # GHIDRA_INSTALL_DIR/JAVA_HOME/PATH + rea alias
  rea analyze xbl_a-code.bin --target-format raw-binary --architecture arm64 \
    --entry-point 0x22126000
  ```
  （各 xbl/xbl_config/devcfg 段表先 `readelf -l` 或 python struct 解一遍再切；
  xbl_b 同法；长会话用 `--snapshot` 落本地分析库加速。）
- 方法论同 BOOT-CHAIN-RE §7 三步：先抓 DEBUG 串路标 → xref → REA 反编译读控制流。
- 冒烟已过（根治卡在案）：`rea analyze` + `rea inspect-native-api` 对 xbl 代码段
  → Ghidra 12.1.4 lane（AARCH64:LE:64:v8A）函数边界/伪代码/API 边界全出。
- 配套脚本：本仓 `tools/abl-re/`（xref.py/disfunc.py 是按 ABL PE 布局写死的，
  对 xbl raw-binary 段**先复核 TEXT_OFF/TEXT_SZ 再用**，README 有提示）。

## 交付

- **完整逆向文档**（标准对标 BOOT-CHAIN-RE：结论 + 地址证据 + strings/xref 截证
  + 方法论复现节）：去向 = PANEL-CORRUPTION.md 新大节 or 独立 XBL-RE 文档，
  开工按体量定。
- §8 政策照旧：结论与原创脚本进公开面；固件派生物（反编译 dump、strings 全文、
  切段 bin）留私有面不进公开仓。
- **推送 = 届时看情况**（用户 10-28 原话）——非自动推送，与 ABL 表件的
  「已授权推送窗」分开记。

## 排面

①ABL fastboot 命令表（第一待办）→ ②XBL 会话语境 RE（本卡）→ ③S2IDLE 根治轮
二段（需设备回 nura 链）。
