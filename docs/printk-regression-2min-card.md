# printk console 挂起回归 — 两分钟判别法流程卡

> 用途：**7.3 stable rebase 完成后、内核上机的第一测**——实测上游是否已修
> `9e70a5e109a4 "printk: Add per-console suspended state"` 引入的挂起回归，
> 决定 `no_console_suspend`（CONFIG_CMDLINE 保险件）摘/留。**别凭 release note 猜。**
> 破案背景 = experiment-log（七十七）（全量 = meizu20-m1/suspend-test-20261008/FINDINGS）。

## 原理一句话

回归本体：`console_suspend=Y`（内核默认）时 `console_suspend_all()` 在挂起路径
阻塞（嫌疑 = `synchronize_srcu(&console_srcu)`），外部看门狗 ~35-40s 复位 =
用户面「睡死假重启」。`console_suspend=N`（= cmdline `no_console_suspend`）全过。
**runtime 开关 = `/sys/module/printk/parameters/console_suspend`，不用重编内核。**

## 判别流程（设备在 pmOS 上，约 2-4 分钟）

### 0. 前提
- 新内核双腿已上机（apk 腿 + ESP 腿），`uname -v` 对上期望 `#N`；
- 通道：ssh/NCM root 可用；设备无用户在用。

### 1. 基线发（console_suspend=N，必须过）
```sh
cat /proc/cmdline                       # 确认带 no_console_suspend（现役 CONFIG_CMDLINE 随包）
cat /sys/module/printk/parameters/console_suspend   # 应显示 N
cat /sys/power/suspend_stats
rtcwake -m mem -d /dev/rtc1 -s 60       # 真睡 60s，RTC 闹钟唤醒
echo $?
cat /sys/power/suspend_stats
```
判读：rc=0、success 计数 +1、failed 不增、`dmesg` 见
`PM: suspend entry`→`PM: suspend exit` ⇒ 基线绿，继续。

### 2. 回归态发（console_suspend=Y，判别关键）
```sh
echo Y > /sys/module/printk/parameters/console_suspend
rtcwake -m mem -d /dev/rtc1 -s 60 ; echo $?
```
判读（死签名，任一即死）：shell 无返回（session 断）→ 设备复位
（`uptime` 归零 / 宿主侧 NCM MAC 变 / 无 rc）⇒ **回归仍在**。
活签名：rc=0、uptime 连续、dmesg 有
`printk: Suspending console(s) (use no_console_suspend to debug)`
**之后**仍有 `PM: suspend exit` ⇒ 本发活。

### 3. 判据
- Y 态死（哪怕 1/3）⇒ **`no_console_suspend` 留**，收工。
- Y 态活：**连测 3 发全活**才判「上游已修」⇒ 摘件走 CONFIG_CMDLINE 移除
  `no_console_suspend` 的内核轮（r 内核 bump 一轮出件）。
  ⚠历史注：rc3 上 Y 态 4/4 必死是在 netconsole 反复注册/注销扰动的会话里；
  rc6 上 Y 态 3/3 未死 ⇒ 该回归是状态/时序依赖的，**单发活不算数，3/3 全活才算**。

### 4. 收尾
- `echo N > /sys/module/printk/parameters/console_suspend`（恢复保险态，无论判读结果）；
- dmesg / suspend_stats 全程留档；结论写回接续卡「printk 复核」格。

## 雷册（复用既有判据，勿再踩）
- ssh 会话自带 sleep block 抑制器：**rtcwake 直写 /sys/power/state 才是通的**
  （rtcwake -m mem 即此路）；logind 路挂起会被拒。
- rtcwake 用 `-d /dev/rtc1`（pm8xxx 走电计时；rtc0 = rtc-efi 废件读 EIO）。
- 死态不可怕：外部看门狗复位回链即可；回链后先 `uname -v` 确认还在新内核腿。
- dmesg 早期日志段（boot 相位）journal 时间戳 = rtc1 旧值，勿当旧日志读。
