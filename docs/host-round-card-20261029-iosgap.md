# 下会话排面卡：iOS 窗口期宿主轮（2026-10-29 晚钉；设备刷回 iOS 后照做）

> **✅ 本卡主体当日收官（2026-10-29 深夜轮；设备提前回 nura 链 = 用户令
> 「开始吧，现在是nura设备日」，宿主件与设备件同窗并跑）**：
> §1 主件 ✅ = D4 三件拼车轮 r92/v72 全绿（fork `c7abcd61` D4-2[m2582
> fb4e8c5d 移植：RDPTR 注销门控 PANEL_DEAD + frame-done 84ms 平值] +
> `bfc79f41` D4-3[wake_pps_late default=true] + D4-4[sanity 0x0A 改 LP 读]；
> apk r92 vmlinuz `c1583825` + ESP v72 裸 `37e3f9c7`/gz `18fd54a0`；verify
> 全绿 dtb c061acd9 同源；pmaports `650fef7`。**⚠构建坑入册：build-kernel 的
> systemd-run 守卫从沙箱背景任务调用不等待 ⇒ build-esp 提前跑吃 r91 旧
> vmlinuz 造出假 v72[4aad92b3]，已显式 72 重造覆盖——build-esp 必须等单元
> 真完**）。§2 次件 ✅ = 段 4 悖论三重锁死定谳 + A1 config-only 修复形态
> + kprobe 脚本成文（pmos `ee52f63`，docs/meizu20/s2idle-seg4-paradox-20261029.md
> + kprobe-seg4.sh）——**A1 = CONFIG_PM_QOS_CPU_SYSTEM_WAKEUP=y +
> /dev/cpu_wakeup_latency 持 fd 服务（上游意图机制，清醒态簇睡不受影响，
> 优于 meizu-wfi），拼车留拍板**。§3 设备窗 ✅ 三件 = S2（#92+r91 出厂
> 组合回位）+ D1（**0xDF + stock 6B 前缀 = 23B 模组串
> "MZ1300043601ECQM3AW03MR"，DF[0]=0x4D 判读表命中；0x0A/0xA1/0xDA-DC/0x04
> 主线读路全零载荷——可读面 = {0x91, 0xDF}，页域候选部分证伪**）+ D2 寄存器
> 维度（**冷启 vs 真睡唤醒 37 项全扫 diff=0**，档案假说寄存器可见维度关闭，
> 与 r22 全扫互证；眼判维度并入 r92 A/B 窗）+ D3（页解锁域设备半边补齐/
> **PMIC 上电拍数差实锤 2/5/0ms vs 5/5/10ms = D4-1 弹药**/OLED 轨电压等值
> 语境降权）。落档 = PANEL §6 条 9 D1/D3 实测段（nura `69e6ab1`）。
> **剩余 = ③r92 上机 A/B（用户在场：upgrade.sh 双腿 → #93 → `echo stock >
> knob` 真睡×5 眼判；回归预案 = 撤 D4-2 保 D4-3/4）∥ ④S1 E 长跑过夜**
> （(开,开)×50-100 + iw show 入日志 + UPower 定量；次晨 kprobe-seg4 (关,开)
> 挂死轮拿 A1 判据）——一窗双案留拍板。**用户 10-29 深夜令「等 iOS 那边
> 做完再说，现在收尾」⇒ 两件挂起待 iOS 线收尾；设备已出厂态回位（bloff +
> failed 0 + D2 周期干净 suspend success=1 + wowlan 武装 + cpuidle 锁）。**

> 语境：设备 10-29 晚刷回 iOS（用户拍板），nura 设备通道（devsh/fastboot）
> 全失效；设备再回 nura 链的时间未定。本卡 = 设备不在期间的纯宿主轮排面
> （用户 10-29「你安排下个会话吧」拍板）；设备窗恢复排面见 §3。
> ⚠iOS 线红线照旧：iOS 工作区文件不碰、设备零接触、传话走用户。

## 0. 开工惯例

- stable 检查 30s（v7.3.1 出没出；出 = rebase 专项另议，勿与本轮拼车）。
- 设备现态探测跳过（设备在 iOS 链）。

## 1. 主件 = D4 三件拼车内核轮（r92 预备轮；验证件不上机不发布）

- **D4-2 首帧杀 vblank 修法**（m2582 `fb4e8c5d` 判据移植，判据原文 =
  PANEL-CORRUPTION §6 条 9 缝 4）：
  a) `dpu_encoder_phys_cmd.c`：RDPTR 回调注销门控到
  `DPU_ENCODER_FRAME_EVENT_PANEL_DEAD`（现状 = 首超时即注销 → 一帧慢 =
  永久死 commit 路径 = 冷启 restart 双遍怪癖候补解释）；
  b) `dpu_encoder.c`：frame-done timeout 5/vrefresh 公式（120Hz=41.7ms）→
  vendor 84ms 平值。
  patch 素材直取：参考仓 `14185638/Linux-MEIZU_22` commit `fb4e8c5d`
  （dpu_encoder_phys_cmd.c +32/-21 / dpu_encoder.c +85/-32），照判据移植到
  我方树；③TE pacing 轴不随（10-21 判无旋钮不开工）。
- **D4-3 PPS 晚发默认翻转**（一行）：`wake_pps_late` default=true——P2 旋钮
  = stock「ON 表后每 enable 发 PPS」语义 10-29 实证（PANEL §6 条 9 缝 5）。
- **D4-4 sanity 探针 LP 读**（一行）：`boe_meizu20_enable` 的
  `get_power_mode` 不再剥 LPM（stock ESD = LP 读 0x0A 实证，条 9 §2 勘误）；
  「回 page 0」探针走 dcs_write debugfs，零内核改动。
- **流程**：fork patch（meizu20-t4b）→ `build-kernel.sh --bump` → r92 apk +
  v72 ESP → `verify.sh` 全绿 → 产物归档**不上机不发布**（照 r88/v69 预构建
  先例）→ 设备窗一次刷。期望 `uname -v` = **#93**。
- 上机风险预案：D4-2 是唤醒/超时行为改变件——设备窗上机 A/B 协议（用户
  在场眼判；回归 = 撤 D4-2 保 D4-3/4 单独上）。

## 2. 次件 = S2IDLE 段 4 悖论宿主半边（（九十七）排面钉 ④ 源码面）

- v7.3 树 `idle.c` s2idle 分支对拍：`cpu_wakeup_latency_qos_limit` →
  `cpuidle_find_deepest_state` 调用链——QoS=10us 为何挡不住 750us+ 深态
  （段 4 悖论源码面收口）。
- kprobe 方案成文：`cpuidle_find_deepest_state` / `call_cpuidle_s2idle` /
  `psci_cpu_suspend_enter` 计数与实参脚本（设备回来 (关,开) 挂死轮直接跑）。
- 产出 = A/C/D 选路预判（修复轮不空手）。

## 3. 设备窗恢复排面（设备再回 nura 链时；一窗双案留用户拍板）

- **S2 现态探测**（10 分钟，首项）。
- **面板案**：D1 上户口（前置探针 = dcs_write 发 `f0 55 aa 52 08 00` 回
  page 0 → dcs_read LP 直读 0x0A/0x04/0xDA·DB·DC/0xDF(23B)/0xA1(4B)/0x91；
  判读表 = PANEL §6 条 9 §2；D1 大概率零内核改动）→ D2 会话双快照
  （0x91 PPS 镜像已验证可读；档案假说可证伪化主力）→ D3 语境差三件
  （页解锁域/PMIC 上电拍数/OLED 轨电压，已升格 = D4-1 前置对拍）→
  **r92 三件上机 A/B**。
- **睡眠案**：S1 E 长跑过夜（(开,开)×50-100 轮 + iw 武装态实读入日志 +
  UPower 定量）+ 段 4 kprobe（§2 脚本现成）。
- r92 刷入与 D1 可同窗（刷完 D1 先跑，零依赖）。

## 4. 可选插空

- stock kernel Image 代表性验证（s5-wake-ddic-card §3 遗留：flyme-ota-b
  boot.img 拆 zboot → strings/符号 vs vendor 源码树 = 七缝对拍可信度收口，
  半天）。
- 候补小件池照旧（TECH-DEBT 清账 / tuned 删包 / meizu-wowlan 默认态拍板）。

## 5. 红线照旧

- §8 政策（结论/原创脚本公开，派生物私有面）；commit 不 push（推送窗口 =
  用户）；r89 红线件不上机照旧；fastboot 单通道。
