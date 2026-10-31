# 根治轮·设备窗执行卡（2026-11-01 安排；用户拍板「安排根治轮」）

> **状态 = 等门。** 两案拼一窗：**花屏 r92 上机 A/B ∥ S2IDLE E 长跑 + 段 4 kprobe**。
> **门 = 设备回 nura 链 + 用户在场（A/B 眼判必须）；iOS 线收尾后开工。**
> 每项独立可停，commit 不 push。本卡取代 host-round-card-20261029-iosgap.md §3
> 的设备窗排面；背景深档 = s5-rootcure-card-20261020.md + PANEL-CORRUPTION §6 条 9。

## S0 开工惯例（30s + 5min）

- **stable 检查**：v7.3.1 / v7.4-rc 出没出（10-30 复核均未出；出 = 先报告再动）。
- **设备现态探测**：devsh 连通 → `uname -v`（期望 #92）/ `iw phy0 wowlan show`
  武装态（★新版 iw 用 show 直读，info 段=能力表易混）/ cpuidle 锁 / failed 计数。
  设备不在 nura（iOS/Flyme）→ 本轮顺延勿等。

## 主件 A：r92 上机 A/B（花屏 D4 三件，用户在场）

- **内容**：D4-2（RD_PTR 注销门控 PANEL_DEAD + frame-done 84ms 平值，m2582
  fb4e8c5d 移植，fork `c7abcd61`）+ D4-3（wake_pps_late default=true，`bfc79f41`）
  + D4-4（sanity 探针 0x0A 改 LP 读）。
- **步骤**：`script/upgrade.sh` 显式双腿（`--apk r92 --esp v72`，⚠默认取最新 =
  红线件必显式；CI 钥墙照配方 --allow-untrusted）→ 确认 `#93` → `echo stock > knob`
  （旋钮语义照 PANEL-CORRUPTION §6 条 9）→ **真睡 ×5 用户眼判**。
- **判据**：真睡 ×5 全干净 + 零回归（回归清单照 r91 轮：rtcwake resume / 电源键 /
  出声 / GPU 钳零 / 传感器 QS / WiFi 5G / failed=0）。
- **回归预案**：撤 D4-2 保 D4-3/4 → 重编内核轮。
- **判负出口**：D4 全负 → 病根维持非命令维度（标准域已穷尽），候选续排 =
  D4-1 唤醒冷启等价化（语境差三件弹药在册：页解锁域 / PMIC 上电拍数 2/5/0 vs
  5/5/10ms / OLED 轨电压）→ **留用户拍板**，勿无假说硬烧轮次。
- **判过去向**：r92 升现役 → 是否发 Release 留用户。

## 主件 B（∥，过夜段可无人值守）：S2IDLE 二段

1. **E 长跑**：(wowlan 开 + cpuidle 开) ×50-100 轮无人值守（s2test 基建在
   `/root/s2test/run.sh` + resume unit；mask=all/state 清零即跑）。
   - 每轮 pre **实读 `iw phy0 wowlan show` 武装态写日志**（10-24 疑点清账）；
   - ★判据坑：sched_clock 深睡停走 ⇒ 挂死判读用 **>350s 无新 freeze 段 / boot_id 变**；
   - 顺带 UPower 挖 (开,开) 睡眠功耗定量（`/var/lib/upower/history-*.dat`）；
   - **100 轮零挂 ⇒ 拆 meizu-wfi 吃簇睡收益的底气**；挂 ⇒ (开,开) 真实概率入册，E 出局。
2. **段 4 kprobe 实证**（主攻）：(关,开) 触发挂死轮 + kprobe-seg4.sh
   （pmos `ee52f63`）钉 `cpuidle_find_deepest_state` / `call_cpuidle_s2idle` /
   `psci_cpu_suspend_enter` 调用计数与实参 → 深塌真入口定谳 → A/C/D 选路浮出。
   - ⚠禁手例外仅限本受控实验：wowlan runtime disable 平日列禁手，实验窗内允许
     （外部看门狗自复位兜底 + netconsole 在场：`dmesg -n 7` 抬级，覆盖窗 = 入睡段
     至 freeze 完成，dwc3 gadget 挂起即断）；实验完立即回 (开,关) 出厂组合。
3. **选路输入**（kprobe 后拍板）：
   - **A1** = `CONFIG_PM_QOS_CPU_SYSTEM_WAKEUP=y` + `/dev/cpu_wakeup_latency`
     持 fd 服务（config-only 内核轮 r93 + device 包件；可与 A 件判负后的重编拼车）；
   - C ath12k 域修 / D mpm 节点探测照 s2idle 卡预案。

## 收官三写

`config.sh` REL_*（r92 判过则转现役钉）+ `MANIFEST.md` 工作态 +
pmos AGENTS 一句话 + experiment-log 叙事；判词落 PANEL-CORRUPTION §6 条 9 /
SUSPEND-S2IDLE。**commit 不 push。**

## 风险预案

治本超窗 → 维持现役保险丝态（meizu-wfi + wowlan 武装 + bloff 日用），不比现状差；
r92 判负不发布（验证件纪律）；设备中途刷 iOS → 全部顺延勿等。
