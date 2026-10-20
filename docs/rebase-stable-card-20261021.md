# 7.3 stable rebase 正式轮执行卡（2026-10-21 深夜落盘，下会话照此做；用户点名「安排下个会话」）

> **✅ 宿主段已收官（2026-10-21 深夜，零设备）：§1-§2 全绿**——§1 stable 在
> （`091b0638`）/ v7.4-rc1 无；fetch v7.3 → 99 提交零冲突重放（tip
> `665230b58a29`；锚 `archive/t4b-rc6-final`+`archive/pre-73-meizu20-t4b`@旧 tip
> `26ab9bf3e442`；临时分支已删）→ sanity 四件全绿 → **printk 上游未修 ⇒
> `no_console_suspend` 留**（rc7→stable 仅 `5f339c46f153` nbcon kthread 早启件，
> 非挂起路径；实机 2min 判别法仍留设备日第一测）+ **ath12k 0012 三件 carry 全留**
> （Shenghan 修复不在 v7.3，rc7→stable ath12k 零提交）→ pmaports `972412f` →
> **apk r91**（sha8 `df13faa6`，内核 release **7.3.0**、模块目录 7.3.0/）+
> **ESP v71**（裸 `0a102220` / gz `6fe7811a`）→ **verify 全绿**（[4] 曾红 =
> 发布面钉子口径，v71↔r91 手工对拍 `4aad92b3` 同源后随钉子更新自消）。
>
> **✅ 设备日段已收官（2026-10-21 深夜，用户在场）：§3-§5 全绿**——upgrade.sh
> 显式 `--apk r91 --esp v71` 双腿全绿（**实测 uname = #92-meizu-meizu20** +
> recovery_a 读回 `0a102220` 对 ✓）；§5 回归清单全绿：真睡 rtcwake（N 发 resume
> 0.228s）+ **电源键秒醒**（眼判）+ 音频三服务 active + 出声（眼判）+ GPU 钳零件
> `busy_delta_us` 真空闲 5 连读恒 0 + 传感器 proxy 在会话总线/accel 已 claim +
> QS 开关在（眼判）+ WiFi 5G 扫描见 LZ-5G（实连无凭据记档）+ failed=0；
> **printk 流程卡第一测 = 基线 N 发 PASS + Y 态 3/3 全活**（按卡判据 = 上游已修
> 候选；**摘 CONFIG_CMDLINE 件 = 另开内核轮留用户拍板**——在册注：rc6 亦 3/3
> 未死 = 回归时序依赖，保险件零成本建议留）；waydroid 现底无预装跳过记档；
> 收尾 console_suspend 复 N + bloff_default=Y 日用态确认。**本轮全项收官，
> 唯余推送窗口（= 用户）。**

> 前置：7.3 stable 已出（tag `091b0638`，10-21 两次复核在案，无 rc8）。rc7 演练
> 全绿（10-19：98 提交零冲突重放 + 语义 sanity 四件 + r89 编译验证；tag
> `archive/rc7-dryrun-20261019`@`87ca59a3afac`；报告/配方 =
> pmos_linux `docs/rebase-dryrun-rc7-20261019.md`）。本卡 = 正式轮排面。
> 每段独立可停；commit 不 push；fastboot 单通道 / 刷写用户在场照旧。

## 0. 目标与判据（钉死）

- **交付**：`meizu20-t4b` 重放到 v7.3 stable（`091b0638`）→ 内核 **r91** apk +
  **ESP v71** → verify 全绿 → 设备日双腿升级（apk+ESP 原地，不重刷 userdata）→
  上机 `uname -v` = **#92**（#N=pkgrel+1 律）→ 回归清单全绿。
- **成功判据**：回归清单（§5）零回归 + 花屏现状不劣化（日用 bloff 态真睡干净照旧）。
- 分支规范照旧：`meizu20-t4b` 只留现役，历史落 tag（正式轮开工先把 rc6 现役
  tip 打 tag `archive/t4b-rc6-final` 再动）。

## 1. 开工第一件（30 秒，只报不转）

- ls-remote kernel.org：v7.3 在 = 直接开工；顺带只报 v7.4-rc1 有无（信息项，
  7.4 前瞻雷 §7 只记档不动工）。

## 2. 纯宿主段（零设备，随时开工）

1. **fetch stable tag**：`091b0638` 入本地仓（rc7 对象已在）。
2. **carry-list 重放**：rc7 演练配方照 `rebase-dryrun-rc7-20261019.md` 重放到
   stable 基点；携带面 = 演练 98 提交 + **新增 1 = 首枪旋钮件 `26ab9bf3e442`**
   （`msm_dsc_stock_content`，默认 0 = debug 设施随车）；0xC4 旋钮件
   （`zero_clkout_timing`）已在演练基内。预期 ~99 提交，冲突预算 = 零（rc7→stable
   仅收尾修复）。
3. **两个实质复核项**（rebase 轮的正文，非走形式）：
   - **printk**：v7.3 stable 上核 `9e70a5e109a4` 后续修复是否进（流程卡 =
     `docs/printk-regression-2min-card.md`）；未进 ⇒ `no_console_suspend` 留
     （10-19 定谳默认）。
   - **ath12k 0012**：核 Shenghan Gao freq-range 修复是否进 stable；进 ⇒ 摘
     本地补丁；未进 ⇒ 三件 carry 全留（10-19 定谳默认）。
4. **语义 sanity**（演练四件照跑）+ `--bump` 构建 **r91** + verify 全绿
   （dtb↔FdtBlob 同源 / uhid·uinput·zram.ko 在列 / ESP↔apk vmlinuz 同源）。
5. **build-esp → v71**（本地先建先钉，出货 gz 解压反推裸 sha 记录）。

## 3. 设备日段（需用户在场；upgrade.sh 已三轮磨合）

- `upgrade.sh --i-am-present --apk <r91> --esp <v71>`（**显式 --apk/--esp**，
  不依赖默认取最新）；双腿升级不重刷 userdata；读回对 ✓。
- 在机背景 = #91+v70+r90+CI r86-phosh rootfs（device r60+fw r3+iio fork r3
  热修）；本轮 rootfs 不动。

## 4. 判读纪律

- 首启 `uname -v` = #92；failed=0；首 boot 三 unit 枚举竞态（meizu-dsp-mount/
  qbootctl）= 已知自愈非回归。
- DPU「no encoder found」boot 早期 3 条 = 窗口性噪音勿追。

## 5. 回归清单（设备日，全绿才算数）

①真睡 rtcwake + 电源键唤醒 + resume 时间；②音频 T4c 直驱自动钉 + 出声；
③GPU 钳零件真空闲 busy_delta 恒 0；④传感器 SensorProxy 三属性 + QS 开关在
（iio fork r3 热修态）；⑤WiFi 5G 扫描+实连；⑥waydroid 网络四连（现 rootfs
无 waydroid 预装则跳过记档——r62 发布面才有）。

## 6. 拼车纪律（默认全不拼车）

- **花屏 S5 下一手（XBL 平台域逆向 / 首帧杀 vblank 旋钮）不进本轮**——rebase 轮
  = 干净版本基线（7.3 stable + 已知 carry，零实验变量）；S5 下一手 rebase 收官
  后单开，候选留用户拍板（PANEL §6 条 7）。
- **device r63**（depends 加 iio-sensor-proxy）= 设备包轴，本轮内核轴不动；
  用户哪轮点头哪轮带走。
- **推送窗口**：fork push 是 CI 构建前置——本轮默认本地构建不阻塞；用户若要点
  CI，先拍板推送。

## 7. 7.4 前瞻雷（随车记档，不动工）

binder Rust 化 / kalama SDE catalog 收割 / `drivers/virt` gunyah 复查点
（7.3 全周期无 gunyah，驱动只进 merge window）。

## 8. 落档清单（收官三写 + 记录）

`config.sh` REL_*（r91/v71/#92）+ `MANIFEST.md` 现役表 + pmos AGENTS 一句话；
experiment-log（九十六）+ 记忆簿更钉；commit 不 push（推送窗口 = 用户）。
