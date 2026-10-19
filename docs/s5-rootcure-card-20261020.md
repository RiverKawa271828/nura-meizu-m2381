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

## 1. ★廉价首枪（强烈建议排在 RE 之前，约半天）：stock-DSC-content 旋钮 A/B

- **为什么值得先做**：H1（knob stock）只复刻过**包形态**（无 0x07/PPS 后置 LP/全 LP），
  **从未测过 DSC 内容值**。S2 内容值对拍表（10-19 深夜，PANEL §6 条 3·余面）钉出
  我们与 stock 的会话参数差全集 = 表 #9-#15：**flbo 13↔12 根因族**（→idd 549↔526 /
  nfl 1402↔1294 / sii 469↔488）+ **initial_lines 3↔2** + **DSC_CFG bit17** +
  PPS 载体 0xA0↔0x0A（已有 wake_pps_late 旋钮）。Novatek demura 专利
  （EP4089666A1）= 补偿重载**按会话建立时收到的模式参数自选档案**——若重载键在这
  些参数上，我们每次真睡都把 DDIC 引到错误档案。
- **做法**：fork 加一个 stock-context 旋钮（一次把 flbo 族/initial_lines/bit17 钉到
  stock 值；参照 0xC4 旋钮件 `c1d84dcf80ec` 手法，module_param 0644）→ r90/v70 →
  `upgrade.sh --i-am-present --apk … --esp …`（10-19 已磨合，~30 分钟链路；⚠显式
  `--apk/--esp`，默认会取 r89 红线件）→ knob default + 真睡 A/B 眼判。
- **判读**：干净 = **病根 = 会话参数落档** → 根治 = 驱动对齐 stock 值（4 处内容差
  补丁形态用户拍板）；还花 = lane A 死，**反向喂 S5**（答案确在 vendor 专有域，
  标准命令域彻底清零）。

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

## 3. 顺序与预算

- 开工第一件照旧 = stable 检查（30 秒只报不转）。
- 首枪（半天）→ 不治即转 S5 RE（上不封顶）；RE 有阶段性产物（模块定位/命令表）
  也算交付，判词落档再排下一段。
- 判读无论正反都落 PANEL-CORRUPTION §6 条 4/条 6 + 本卡打勾 + 记忆簿更钉。

## 4. REA 工具链（10-19 晨调研落卡；用户提名 <https://github.com/morluto/rea>）

- **是什么**：RE agents 工具集（300k★，MIT）= MCP server + CLI（`npx rea-agents@latest`），
  把 agent 直接接上 RE 工具面：native 二进制（Ghidra/Hopper/IDA → 伪代码/汇编/符号/
  xref/调用图）、固件（Binwalk/Unblob 区域提取后接 native 分析）、字符串/熵/JSON/YAML
  等一键摘要。分析全本地跑。授权用途注记 = 自有设备互操作性研究——我们正是此类。
- **对 S5 的映射**（正中缺的那块肌肉）：
  - `xbl_a/b.img`（Qualcomm XBL = ELF 头 aarch64 裸固件）→ REA native lane 出伪代码
    + xref，比手拆 objdump 快一个量级；面板会话建立函数（上电时序/命令表/语境）=
    第一目标；
  - `uefi_a-fvtool` 已提取的 DisplayDxe PE 镜像（UEFI AARCH64 = PE/COFF，Ghidra 直接
    吃）→ ProfileID 0xB 消费端 + override key 表（0x3e998/46B/151 条）语义补完。
- **宿主前置（10-19 实测）**：node v26.7 ✓ / npm 11.19 ✓ / objdump ✓ / uv ✓；
  **缺 = Ghidra（未装）+ JDK 21（现装 17，Ghidra 11.x 要 21，Fedora `dnf install
  java-21-openjdk` 即可）**；无 aarch64 版 binutils（Ghidra 覆盖，不阻塞）。
- **接线姿势**：先 CLI（`npx rea-agents@latest` 系列，零注册成本）；要挂进 agent 会话
  再做 MCP 手动注册（REA setup 支持 arbitrary MCP client）。Ghidra 首次 setup 需
  下载授权（REA 可代装 Hopper，我们选免费的 Ghidra 路线）。安装/首次跑照守卫纪律
  （沙箱网络受限 → systemd-run 或用户在场跑 setup）。
