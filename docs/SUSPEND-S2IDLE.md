# s2idle 睡死破案全集：printk console 挂死 · 死亡取证 · 唤醒链（魅族 20 / m2381）

> **定位**：把 2026-10-08 → 10-09 睡眠战役（11 轮实验，全量记录在私有工作区
> FINDINGS/实验日志，未公开）蒸馏成一篇**自包含公开文档**。角度不是"我们修好了
> 一台手机"，而是**高通新机 s2idle「睡死」的通用病全解剖**：凶手机理、为什么
> 六次死亡零现场、怎么搭死亡现场直播、修复、以及"睡得进"之后才暴露出来的整条
> 唤醒链。每条结论带实验编号或数据；适用面不限于本机——printk 挂死一层是
> v6.4+（nbcon 时代）内核的通用回归，任何 s2idle 设备都可能撞。
> **政策**：本文只含事实、方法论与我们自己的补丁/配置（全部在公开 fork，§7 有
> 指针）。无任何 stock 固件二进制或派生转储。
> 链路背景（这台机器怎么跑起来）→ [DESIGN.md](DESIGN.md)；启动链逆向 →
> [BOOT-CHAIN-RE.md](BOOT-CHAIN-RE.md)（其 §6.3 与本文 §2 互链）。

---

## 0. 一页看懂

```
用户面：入睡 → 屏黑 → 按什么都没反应；或设备"自己重启了"
          │
          ▼ 内核面：三层病 + 一层取证壳
┌────────────────────────────────────────────────────────────────┐
│ ① 睡不进  printk console 挂起路径挂死（console_suspend=Y 默认）  │
│    console_suspend_all() 在 dpm_suspend_start() 之前；          │
│    挂死点 = "Suspending console(s)" 那行 pr_info 之后的          │
│    Y-only 段（CON_SUSPENDED 标记 + synchronize_srcu）           │
│    → 外部看门狗 ~35-40s 复位 = 用户看到的「睡死假重启」           │
│    修复 = cmdline 一行 no_console_suspend                        │
├────────────────────────────────────────────────────────────────┤
│ ② 醒不来（内核活、用户态死）                                      │
│    s2idle 睡着时 CLOCK_MONOTONIC 照走（内核跳过 syscore 的设计）  │
│    → systemd 3min 服务看门狗把睡眠时长计入 → 醒来瞬间             │
│      SIGABRT udevd/logind → 会话丢输入/DRM 设备 → 屏黑输入死      │
│    修复 = udevd/logind WatchdogSec=0 + 内部服务放宽 30min        │
├────────────────────────────────────────────────────────────────┤
│ ③ 睡死某个设备：ath12k resume 侧按"冷启动"重初始化一个暖着的固件   │
│    → host cap 被固件拒（err 90）/ WMI SERVICE_READY 永不再发      │
│    → resume 被 5-25s 超时绑架（屏不亮的体感真身）+ WiFi 睡后死     │
│    正解 = WoWLAN 路径（mac80211 不停机 ⇒ resume 无 reconfig）     │
├────────────────────────────────────────────────────────────────┤
│ 取证壳：六次死亡零现场——四条事后取证通道全死 + loglevel=3 压制     │
│         + 挂死点恰好在"挂起 console"⇒ pstore 结构性收不到日志      │
│         破法 = netconsole 死亡现场直播（§3）                      │
└────────────────────────────────────────────────────────────────┘
```

五条硬结论（每条后文有完整证据链）：

1. **凶手不是任何驱动**（§4）：`console_suspend=Y`（内核默认）时代码路径必经
   `console_suspend_all()` 的 Y-only 段，实验矩阵里它是唯一与死亡相关的变量。
   上游已知回归 `9e70a5e109a4`，LKML 有在查的同族报告。修复 = cmdline 一行。
2. **"必死"不是确定性属性**（§4.4）：rc3 基座上 Y 侧 4/4 死，rebase 到 rc6 后
   Y 侧 3/3 活——代码逐字节相同，触发依赖状态/时序。`no_console_suspend` 作为
   便宜保险保留；**「为什么曾必死」未钉死，如实记**。
3. **挂死窗口内 pstore/ramoops 结构性收不到日志**（§2）：挂死点就是"给所有
   console 打 CON_SUSPENDED"的那一刻，事后取证通道全部落空。
4. **freezer 档 PASS 不说明设备相位没问题**（§3.1）：`pm_test=freezer` 的检查点
   在 `enter_state()` 里、设备相位之前——它 PASS 只说明"压根没走到凶手"。
5. **WiFi 睡眠保连接的正解 = WoWLAN**（§6.1）：非 wow 路径睡 = cfg80211 结构性
   断连 + mac80211 停机 ⇒ resume 必走 reconfig ⇒ 撞上"暖固件不发
   WMI_SERVICE_READY"死结。wow 路径不停机，全部状态保持：**resume 0.18~0.24s、
   零 deauth**（现役出货形态，默认武装）。

现役出货形态（Release r84，2026-10-12 回归全绿）：rtcwake 51s 一发 →
`PM: resume devices took 0.240s`、wowlan 武装、看门狗 drop-in 生效、failed 0。

---

## 1. 病历：一台「睡死假重启」的手机

起点状态：pmOS + 主线 7.3 内核（fork 分支），桌面与日用全绿，唯独睡眠 =
历史 6 次尝试 1 成 5 死（2026-09-28 起），且**每次死亡零现场**（§2）。

| 日期 | 条件 | 结果 |
|---|---|---|
| 09-28 boot A | deep | 死 |
| 09-28 boot B | s2idle | **成功**（59s 后 RTC 唤醒） |
| 09-28 boot C | s2idle | 死 |
| 09-28 boot E | s2idle + WFI-only | 死（真断电深挂） |
| 10-07 ×2 | s2idle（powerdevil 自动睡 / 手动 echo mem） | 死（长按救机） |

用户面统一形态 = **「睡死假重启」**：入睡后设备像被拔电，约半分钟后自己回到
锁屏（= 外部看门狗复位的冷启动）。journal 每次都止于
`PM: suspend entry (s2idle)` + `Filesystems sync: 0.000 seconds`，之后全无。

**第一条方法论教训**：`journal 止于 suspend entry` 是**正常假象**，不能当挂点
证据——journald 随进程冻结停止写盘、且默认 5min 批量 sync，死亡窗口的内核行
结构性丢失。09-28「失败点在 device suspend 阶段」的旧结论从未被真正证明，
后来（§4）被整体推翻。

同轮顺带根治的一件（不在本文展开，详见 fork 提交
`a479cfcd8f3b`/`69da9c63997d`）：熄屏后 ~4.7-8k/s 的功放中断风暴（IRQ244），
真根因 = DTS 从未配置 CS35L45 的 INTB pad（芯片不驱动 pad = 线浮空自激），
照搬 stock 的 gpio-ctrl 全套后 **~500 倍根除**。它是耗电第二大头，与睡眠
第一大头（进不了 suspend）同轮清账。

---

## 2. 为什么六次死亡零现场：取证通道战役

> 这是本案方法论价值最大的一层：**每条"事后看现场"的通道都独立地死了**，
> 而其中两条的死法相当隐蔽。

### 2.1 通道死因全表

| 通道 | 状态 | 死因 |
|---|---|---|
| pstore/ramoops | **写入侧活，读取侧四重死** | 见 §2.2/§2.3 |
| journal | 死亡窗口结构性丢失 | journald 随冻结停写 + 5min 批量 sync；修复 = `SyncIntervalSec=30s`（随设备包） |
| kcore | 对本案无效 | 段表无低 4GB 直映段（16 段全在高地址），0xa8000000 无别名可读 |
| /dev/mem | 被拒 | `CONFIG_STRICT_DEVMEM=y` 按 memblock `page_is_ram` 拦，iomem "reserved" 标签救不了 |

### 2.2 ramoops 的四重死（每重都单独足以致哑）

1. **主因，结构性**：死亡窗口恰好在 `console_suspend_all()` 给**所有** console
   （含 pstore console）打 `CON_SUSPENDED` 的那一段（§4.2）⇒ 就算设备真死在
   后面，死亡日志也进不了 ramoops ring。**事后取证在这个 bug 面前本来就不可能
   出结果。**
2. **magic 撞车**：pstore 区签名 `PERSISTENT_RAM_SIG = 0x43474244 = "DBGC"`
   （fs/pstore/ram_core.c:39）与高通 ABL 的 DBGC 调试日志 magic **相同**——
   "区头读到 DBGC"既可能是 pstore 本尊也可能是 ABL 日志，纯头判读必然误导。
3. **地址踩踏**：把 ramoops 搬到 0xa8000000 的尝试被 ABL 每 boot 重写
   0xA8000000 起的大片区域打死；0xB0000000（Mu "Kernel" Reserv 区）写标记也
   没活过暖重启。（ABL 本身对原址 0xa5100000 无感知——清零之谜在
   [BOOT-CHAIN-RE.md §6.3](BOOT-CHAIN-RE.md) 洗清。）
4. **loglevel=3 烤死在 cmdline**：pr_info 级（pm_print_times 的全部输出、
   `Suspending console(s)` 本行）被所有 console 滤掉。**运行时 `dmesg -n 7`
   即解，无需重编**——但每次开机都要重打。

写入侧"活着"的实证 = probe.ko（`phys_to_virt` 直读的调试模块）：ramoops 区内
找到 kernel 文本。读取侧替代通道两路皆死：用户态 i2c 直读在 runtime suspend +
geni 时钟门控下**永久挂死**；裸读 IMEM (0x14680000)、写 PIL 区 (0x9c000000)
各换来一次整机硬挂死——**非 DRAM 地址必须只读先行**。

### 2.3 教训（写进操作纪律）

> **取证通道从部署日起从未闭环验证过（写入→重启→读回），六次死亡每次都以
> "环境解释"翻篇。先修通道，再跑实验。**

"干净热重启（linux reboot，DRAM 全程保持）后 pstore 仍空"是判死 ramoops
通道的关键一枪——它把"掉电丢残片"类解释整体出局，逼着往通道本身找。

---

## 3. 定位仪器：pm_test 阶梯 + 死亡现场直播

### 3.1 pm_test 阶梯（先收窄域，但注意语义陷阱）

前置 config 三行：`CONFIG_PM_DEBUG=y / CONFIG_PM_ADVANCED_DEBUG=y /
CONFIG_PM_TEST_SUSPEND=y`（本机pkgrel 67 起）。测法 =
`echo <档> > /sys/power/pm_test` 后 `rtcwake -d /dev/rtc1 -m mem -s 60`。

| 档 | 检查点位置（本树 kernel/power/suspend.c） | 实测 |
|---|---|---|
| freezer | `enter_state()` 内 :613，**设备相位之前** | ×3 PASS |
| devices | `dpm_suspend_start()` = dpm_prepare + 常规相位，:523 起 | 一发即死（当时误判"凶手域收窄"） |
| platform | `suspend_enter()` 入口附近（late/noirq 已过） | 一发即死 |
| processors/core | **s2idle 结构性不可达**：`enter_state()` :583 对 s2idle 直接拒收 ≤TEST_CPUS（-EAGAIN） | N/A |

**两个语义陷阱**（都实测踩过）：

- freezer PASS **不是**"冻结相位没问题"，是"压根没走到设备相位"——freezer
  的检查点在 `console_suspend_all()` 之前，真凶永远碰不到它。
- devices/platform 死 → "凶手 ∈ dpm_suspend 常规回调"是**错误推理**：死因
  在 `dpm_suspend_start()` **之前**的 `console_suspend_all()`（:521 vs :523），
  所以当时所有驱动排查（rmmod 音频 FE / ath12k、panel unbind）注定不命中。
  阶梯只告诉你"freezer 之后、platform 之前"，**点名要靠直播**。

### 3.2 死亡现场直播（本案真正的破案仪器）

事后取证全死后，唯一正道 = **netconsole 把死亡窗口直播出去**。配方五件，
缺一不可（每件背后都是一次白跑）：

1. **内核**：`CONFIG_NETCONSOLE=m`（模块带参最省事）+ `NETPOLL` 跟随。
2. **解 loglevel**：`echo 7 > /proc/sys/kernel/printk`（cmdline `loglevel=3`
   会滤掉全部 pr_info，§2.2-4）。
3. **解 console 静音**：`echo N > /sys/module/printk/parameters/console_suspend`
   ——**最关键的一步**（printk.c 的 module_param，运行时可写）。不写这条，
   窗口内所有 console（含 netconsole 自己）被静音，流里只有
   `Suspending console(s)` 一行。
4. **串行化 dpm 序**：`echo 0 > /sys/power/pm_async`——默认 1 时 leaf 设备
   异步抢跑，"流末行 = 凶手"的语义不成立。
5. **点名仪器二选一**：
   - 遍历打印补丁（fork `2431440968fe`）：`dpm-prepare:`/`dpm-suspend:`
     逐设备 dev_info。为什么需要它——pm_print_times 的 `calling <cb>` 只覆盖
     `dpm_run_callback()` 路径，`device_prepare()` 直调回调**无行**，
     `pm_runtime_barrier()`/`direct_complete` 也在回调之前（无行）。
   - `CONFIG_DPM_WATCHDOG`（fork `6ba9d7cb3fc0` 摘掉上游的 EXPERT 依赖；
     超时即 `**** DPM device timeout ****` + 点设备名 + 打栈）。注意它只覆盖
     `device_suspend()`，覆盖不到 prepare 相位。

模块参数形态：`modprobe netconsole netconsole=6666@<设备IP>/usb0,6666@<宿主IP>/<宿主MAC>`。
两个实操坑：宿主 USB 网卡 MAC **每次设备重启都会变**（必须现探）；直播通道的
断点是 **dwc3 自己**（NCM/f_ncm 没有 .suspend 钩子，netdev 和 gadget 也无 pm ops
⇒ 链路活到顶层 DT 设备 `a600000.usb`，注册极早 ⇒ 逆序里挂得极晚）⇒
**覆盖率 ≈ 整条 dpm 序**，不是"NCM 晚注册所以只能看一段"。

判读：`dmesg -n 7` 后死一发，流末行 ±1 = 凶手（相位一眼可辨）；+20s 应有
DPM watchdog 点名 + 栈；~+35-40s 外部看门狗复位（本机 watch 数值）。
屏幕兜底：`console=tty1` + fbcon 在 console_suspend=N 后同样画在屏上（显示栈
挂得晚，覆盖尾部，用户在场可直接读屏）。

### 3.3 实操雷册（睡眠调试专属，全部实测）

- `pm_test=freezer` 的 PASS 无信息量（§3.1）。
- 睡眠窗口的 journal 时间戳**不可用于测时长**（整段 resume 簇被压到醒后同一秒）；
  只看内核 `PM: resume devices took X seconds`。
- 判"真重启"三件套：`uptime` 归零 / 宿主侧 USB 网卡 MAC 变 /
  `/sys/power/suspend_stats` 归零。**"不可达"≠死**（resume 慢时 NCM 口会暂时
  消失，是假死象）。
- drm.debug 抓显示栈先估环缓冲（每帧数十行，0x1f 洪泛实测冲掉 PM 行），抓完
  立刻归零。
- rtcwake 打的是 RTC 时刻；`-d /dev/rtc1`（pm8xxx，PDC 布线真唤醒源）——
  本机 rtc0 是 rtc-efi（Mu 交付链特有，读数 EIO，不可用）。
- 设备侧后台脚本必须 `systemd-run --unit=`（`setsid nohup` 会被 ssh 会话的
  systemd scope 连带杀）。
- ⛔ 运行态 remove/rescan WiFi PCI 设备（0000:01:00.0）= kernel Oops 自重启 +
  `mhi0_IPCR` 泄漏撞名 ⇒ WiFi 运行期救不回，只能重启。

---

## 4. 凶手定谳：console_suspend_all()（不是驱动）

### 4.1 实验矩阵（变量分离）

全部在装好 §3.2 仪器的内核上做，宿主收流，用 uptime/宿主 MAC/suspend_stats
判真重启：

| # | netconsole | console_suspend | pm_async | 档位 | 结果 |
|---|---|---|---|---|---|
| d1 | 载 | **N** | 0 | devices | ✅ rc=0 |
| d2 | 载 | **N** | 1 | devices | ✅ rc=0 |
| 实睡1 | 载 | **N** | 1 | 真睡 | ✅ 睡 ~60s，RTC 唤醒 |
| N1-N3 | 卸 | **N** | 1 | 真睡 ×3 | ✅ stats 递增，无重启 |
| A | 卸 | **N** | 1 | devices | ✅ |
| 死1 | 卸 | **Y** | 1 | devices | ❌ 真重启 |
| B | 载 | **Y** | 1 | devices | ❌ **流末行 = `printk: Suspending console(s)…`**，之后零输出 |
| C | 载 | **Y** | 1 | 真睡 | ❌（用户面场景复现） |
| D | 卸 | **Y** | 1 | devices | ❌（无逐设备打印 + loglevel=3 仍死 ⇒ 不依赖后续 console 写） |

**唯一相关变量 = `console_suspend`**：Y 侧 4/4 死，N 侧 7/7 过；netconsole
有无、pm_async、pm_print_times、loglevel 全部被证无关。

### 4.2 挂死点定位（源码 + 流末行互证）

流末行正好停在 `pr_info` 那一行 ⇒ 挂死发生在**它之后的 Y-only 段**。
本树（v7.3-rc6 基，行号可直接对）：

```c
void console_suspend_all(void)                       /* kernel/printk/printk.c:2785 */
{
	if (console_suspend_enabled)
		pr_info("Suspending console(s) (use no_console_suspend to debug)\n");  /* :2790 ← 流末行 */

	pr_flush(1000, true);
	console_irqwork_blocked = true;                  /* :2799 nbcon/netconsole 从此不投递 */

	if (!console_suspend_enabled)
		return;                                      /* :2801-2802 ← N 的全部活命道理 */

	console_list_lock();
	for_each_console(con)
		console_srcu_write_flags(con, con->flags | CON_SUSPENDED);   /* :2806 */
	console_list_unlock();

	synchronize_srcu(&console_srcu);                 /* :2815 ← 「潜在阻塞操作」（上游维护者语） */
}
```

调用时序（kernel/power/suspend.c）：`:521 console_suspend_all()` →
`:523 dpm_suspend_start(PMSG_SUSPEND)`——**凶手在所有驱动回调之前执行**，
这就是驱动排查全部落空的结构原因。

- `console_suspend=N` 时函数在 :2802 就返回 ⇒ CON_SUSPENDED 与
  synchronize_srcu 整段不执行 ⇒ 不死。
- 死法 = 挂死 + 外部看门狗 ~35-40s 复位（非 oops：panic=120 时延不符；
  B 例流末行后零输出 = 卡死在静音段）。

### 4.3 三条旧判词作废（保留推理过程，防重蹈）

1. ~~"凶手域 = dpm_suspend 常规回调"~~ → 挂死点在 `dpm_suspend_start()` 之前。
2. ~~"freezer PASS = 冻结相位没问题"~~ → 检查点根本不在凶手路径上。
3. ~~"零现场 = ramoops 通道坏/掉电丢残片"~~ → 主因 = 挂死点就在挂起 console
   的那一刻，**pstore console 一起被静音**；DBGC 撞车/ABL 重写只是叠加因素
   （§2.2）。

### 4.4 上游状态与「必死」的反转（如实记录）

- 代码出处 = **`9e70a5e109a4` "printk: Add per-console suspended state"**
  （把 console 挂起状态改成 per-console `CON_SUSPENDED` + SRCU 管理）。
  已知回归线：LKML 2026-01/02 "Regression: system freeze on resume from
  suspend introduced by printk per-console suspended state"（维护者在场，
  Petr Mladek 点名 `synchronize_srcu(&console_srcu)` 为潜在阻塞操作）；
  拟议修复 = 系列 "printk: Reintroduce consoles_suspended global state"
  （部分 revert，恢复全局挂起态）。
- **rc6 反转**：rebase 到 v7.3-rc6 后（rc1→rc6 对 `kernel/printk/` **零提交**，
  代码逐字节相同），`console_suspend=Y` 侧 3/3 没死（含真睡）⇒ **「Y 必死」
  不是确定性属性**，触发依赖状态/时序——rc3 那 4 发死全在"反复
  insmod/rmmod netconsole（console 注册扰动）+ 重日志"的会话里，rc6 复测时
  没有这个扰动。**本机为什么曾必死未钉死**；上游那条回归本身仍在、LKML 在查。
- **结论口径**：`no_console_suspend` 作为便宜保险随包（副作用 = 挂起期间
  console 不静音，无串口的手机上几乎零代价）；**rebase 到任何新内核后，先用
  §5 的判别法实测，别凭 release note 或代码比对猜**。

---

## 5. 修复与判别法

**修复 = cmdline 一行**（本机随内核包 `CONFIG_CMDLINE`，rc6 起在册）：

```text
no_console_suspend
```

等价运行时形态 = `echo N > /sys/module/printk/parameters/console_suspend`
（调试时临时用；出货走 cmdline）。

**判别法（2 分钟回归测试，rebase/换内核后必跑）**：

```bash
# 1) Y 腿：确认默认态
cat /sys/module/printk/parameters/console_suspend        # 期望 Y
rtcwake -d /dev/rtc1 -m mem -s 30                         # 死/不死皆记录
# 2) N 腿：活命对照
echo N > /sys/module/printk/parameters/console_suspend
rtcwake -d /dev/rtc1 -m mem -s 30                         # 期望 rc=0、RTC 唤醒
# 判"没重启"：uptime 连续 + /sys/power/suspend_stats success 递增
```

放开自动睡眠前还要验两件（本机踩过的顺序坑）：唤醒源武装状态（§6.3）与
systemd 层无睡眠封条（§6.4）。

---

## 6. 睡得进 ≠ 醒得来：唤醒链三案

printk 修复当天就把「睡不进」变成了「睡得进」，随后三案依次现形——它们在
「睡死」的用户面里曾经是同一个病，破案后是三个独立的坑。

### 6.1 ath12k：resume 侧的模型错配与 WoWLAN 正解

**用户面**：唤醒后屏幕要等 20 秒+才回来（「狂按电源键才亮」的真身——resume
被 WiFi 驱动绑架，期间用户态整体冻结），且 WiFi 睡后死（只能重启）。

**机理链**（多轮实机 + 代码级勘验，判负表在后）：

- 睡眠中 WiFi **固件主体带配置活着**（resume 现场 `WLAON_WARM_SW_ENTRY
  0x14b6e64` = 暖 entry；冷启动是 0x0），但 keep-dev 路径的 resume 侧按
  **冷启动**语义重跑初始化：重发 host cap → 固件拒收
  （`Host capability request failed, result: 1, err: 90`，冷启动只发 ×1、
  resume 发 ×2 是现场指纹）→ `restart_completed` 永不送达 → 旧码干等
  `ATH12K_RESET_TIMEOUT_HZ` = 20s。
- 两条失败变体：A 型 = MHI 状态位残留（`failed to set mhi state INIT(0) in
  current mhi state (0x5)` → -22 → 20s 超时 -110）；B 型 = QMI 握手被拒
  （上面的 err 90 链）。表现相同：resume 拖 20-26s。
- **service-ready 死结（本案定谳的结构性发现）**：keep-dev 重连后固件的 QMI
  层自己会重启（host cap 能被接受、内存重要、BDF 完整重下），但**固件 WMI 层
  暖态永不重发 `WMI_SERVICE_READY`** ⇒ 任何"重跑 core_start/firmware_ready"
  的恢复路径必死在 `ath12k_wmi_wait_for_service_ready` 的 5s 超时上；
  mac80211 的 reconfig（drv_start）同样不被支持。**这是模型错配，不是时序
  bug**——驱动以为要重新初始化固件，固件认为自己已经初始化好了。

**判负表**（每行都是实机一发，防重蹈）：

| 方案 | 结果 |
|---|---|
| resume 早返回保险（`resume_early_err`，fork `e73053678c43`） | 未触发（失败点在 resume_early 之后的异步段） |
| 搬入上游 2026-02 mhi.c suspend 补丁 + 等待有界 5s（`84d13db7a2ac`） | resume 25.7s → 9.0s（止损 ✓），WiFi 仍死——它修的是 A 型状态位残留，不治本机 B 型 |
| 腿 A：s2idle 走裸 M3（`mhi_pm_suspend/resume`，`ebd0e2b5a9f6`） | **判负**：M3 挂起成功，睡眠期 MHI 掉 SYS ERROR（平台 PCIe 链路在裸 M3 下拉爆），resume 反 ~95s；已 revert（`6f4d6bab8fba`） |
| 腿 B：FW_READY 事件挂暖重连分支（`e01faa774e37`） | 挂点证伪——keep-dev 重连场景固件**不重发 FW_READY indication**，分支永不触发 |
| 腿 B 挂点修正到 `ath12k_core_resume_early`（`02fe4629080a`，现役） | resume 6.2s、-110 超时消失；WiFi 仍死（死结如上）——作为 wowlan 关闭时的回退路径保留 |
| **WoWLAN 路径（零内核改动，现役出货）** | **✅ 正解，见下** |

**WoWLAN 为什么是正解**（cfg80211 层结构行为）：`wiphy_suspend`
（net/wireless/sysfs.c）只在 `wiphy->wowlan_config` 非空时走 wow 块
（`ath12k_wow_op_suspend`：保连接 + wow enable + MHI M3 + hif_suspend）；
wowlan_config 为空则**无条件 `cfg80211_leave_all` 断连** + mac80211 停机 ⇒
resume 必走 `ieee80211_reconfig` ⇒ 必撞 service-ready 死结。**wow 路径不停机
⇒ resume 的 reconfig 整段跳过**（`if (local->wowlan)` 直接 goto wake_up）⇒
驱动/固件状态全程保持。

实测五发（含 logind 路 E2E）：睡 61/46/120/301/316s，
`PM: resume devices took` **0.184~0.236s**，整 boot 零 deauth、关联 + DHCP
租约保持（30s keepalive），**裸 M3 的 SYS ERROR 在 wow 态零复现**——固件进
WoW 低功耗后平台上下文与裸 M3 不同，两个判词不互相适用。

**附带发现**：无 wowlan 时"睡 = 断连"是 cfg80211 的结构行为（`deauth by
local choice`）；NM（NetworkManager）对睡眠的行为是硬编码的（睡 = 设备
DISABLED，醒 = unmanaged + 重跑 DHCP，本机实测 2.6s 拿回同一 IP）——wow 保
的是**链路/关联层**，IP 层归 NM 醒后重建。rtcwake 直写 /sys/power/state 路径
NM 全程不知情 ⇒ 零 deauth、租约连续 = wow 链路保全能力的最纯对照。

**非 wow 路径的现状（如实）**：wowlan 关闭（或 wlan0 不存在）时入睡，WiFi
仍会睡后死 + resume 秒级拖累。修法候选：①等上游对暖固件 resume 语义的修复；
②非 wow 路径改造（需固件行为感知的"跳过 core_start 重跑"，工程脏，未排）；
③接受现状——现役出货已默认走 wow，非 wow 只在人为关闭时触达。

### 6.2 s2idle × systemd 看门狗：「醒不来」的真身

**用户面**：睡后屏黑、电源键无反应、拔插 USB 只有提示音（= 内核活着，音频链
还能出声）。

**根因链**（代码 + 实测）：

1. **内核侧（设计如此）**：`suspend_enter()` 对 `PM_SUSPEND_TO_IDLE` 直接
   `s2idle_loop(); goto Platform_wake;`（kernel/power/suspend.c:447-450），
   **跳过 `syscore_suspend()`**（:462）⇒ `timekeeping_suspend()` 不运行 ⇒
   s2idle 睡着期间 **CLOCK_MONOTONIC 照常走**。实测：睡 223.9s，
   wall 与 monotonic 各 +223.9s（python 双采样）。
2. **systemd 侧**：服务看门狗（udevd/logind/journald/resolved/… 上游均
   `WatchdogSec=3min`，monotonic 计时）在唤醒瞬间发现"超 3 分钟没喂狗"⇒
   SIGABRT + 重启。97s/212s/210s 三档睡眠实测复现不同服务的击杀。
3. **会话侧**：udevd/logind 被杀重启 ⇒ logind 丢"会话设备接管"⇒ 合成器
   （kwin/phosh）拿不到输入与 DRM 设备（journal 指纹：
   `Failed to open /dev/input/eventN … Operation not permitted` +
   `Could not find edid for connector DSI-1`）⇒ 屏黑 + 输入全死。

**修复**（设备包 drop-in 三件）：

- `10-meizu-no-watchdog.conf`：systemd-udevd / systemd-logind
  `WatchdogSec=0`（会话关键，被杀 = 接管与输入全废）；
- `10-meizu-watchdog-relax.conf`：其余 14 个 systemd 内部服务放宽 30min
  （保留兜底）;
- `10-meizu-journald-sync.conf`：journald `SyncIntervalSec=30s`（默认 5min
  批量 sync = 长按强重启的取证盲区，§2.1）。

回归：logind 路睡 212s（>3min 翻车档）→ 唤醒后合成器输入全部成功重挂、屏回、
零服务击杀。

**「醒不来」三件套鉴别法**（给后来人的判读顺序）：
① 内核侧看 `PM: resume devices took`（亚秒 = 内核好）；
② journal 查 `systemd-udevd/logind … Watchdog timeout`；
③ 查合成器的 `Failed to open /dev/input`（= logind 接管丢）。
三者齐 = 本坑；只有 ③ 无 ② 则查 ACL/seat 层。

### 6.3 唤醒源盘点

| 唤醒源 | 状态 | 备注 |
|---|---|---|
| RTC 闹钟（rtc1 = pm8xxx） | ✅ 最可靠，历轮自动化全靠它 | rtc0 = rtc-efi 死件（读 EIO）；内核 r81 起 hctosys/systohc 也钉 rtc1 |
| 电源键 | ✅ 内核级唤醒源，输入栈坏时也能醒内核 | 历史上有过"首次睡眠后不醒、拔插 USB 可醒"窗口（r72 时代记录，疑 pmic 唤醒重武装，未钉死）；wow 形态多轮实测含用户实按均过。计数法：`pmic_pwrkey` IRQ delta |
| USB-C 拔插 | ✅ 实测有效 | `ucsi-source-psy-pmic_glink` wakeup enabled；**当救急手段写进用户文档** |
| 音量上键 | 已武装待实测 | DTS `wakeup-source` 在，`gpio-keys power/wakeup` = enabled |
| 触屏 | ❌ 无 wake 支持 | 驱动 suspend = disable_irq + power_off，无 `enable_irq_wake`；中等工程，非一行改 |
| **WoL magic packet** | ❌ 不通，根因已钉 | 见下 |

magic packet 不通的根因（代码级，可复燃）：root port 的 of_node 是
`pcie@1c00000/pcie@0`（端口子节点），而 `wake-gpios` 挂在**控制器节点**
`pcie@1c00000` 上 ⇒ `pci_configure_of_wake_gpio()`（drivers/pci/of.c）从
`pci_device_to_OF_node(root_port)` 取 "wake" 属性必然落空 ⇒ root port
`power/wakeup` 恒 disabled ⇒ WAKE# 无到 SoC 的路径。复燃配方 = DTS 给端口
节点 `&pcie0_port0` 补 `wake-gpios = <&tlmm 96 GPIO_ACTIVE_HIGH>;`（一行 +
重编），判据 = root port wakeup 变 enabled + 睡中发包能醒 + EP wakeup 计数
增长。**出厂触发器仍选 magic-packet 单件**：要的是 wow 块（保连接），不是
"disconnect"件那种 AP 侧掉线就亮屏的误唤醒。

**两个 systemd 层的坑**（都曾造成"自动睡失效"的误判）：

- **ssh 会话自带 sleep block 抑制器**（`systemd-inhibit --list` 可见）——
  只要有一条 ssh 会话在线，logind 路的挂起（`systemctl suspend` / 桌面自动
  睡）必被拒。`rtcwake` 直写 /sys/power/state 绕过抑制器（所以测试腿全通、
  logind 腿全拒）。**测 logind 路先断全部 ssh。**
- **已装机的 /etc 符号链接是包升级盲区**：早期把 sleep/suspend/hibernate 三
  target mask 成 `→ /dev/null` 当安全网，后来包里删了创建规则，但**已装机
  现场的符号链接不会随升级消失** ⇒ logind 路挂起被
  `Unit suspend.target is masked, refusing operation` 拒。修复 =
  wowlan 单元里加自愈
  `ExecStartPre=-/usr/bin/systemctl unmask sleep.target suspend.target hibernate.target`
  （未封条时 no-op）——新装机与老装机升级两条路径都收敛。验收睡眠能力要查
  target 层（`ls -l /etc/systemd/system/*.target`），别只看 unit enabled。

---

## 7. 现役出货形态与复现检查单

### 7.1 本机出货配方（全部随公开仓交付）

| 层 | 件 | 内容 |
|---|---|---|
| 内核 cmdline | `CONFIG_CMDLINE`（pmaports config） | `no_console_suspend`（+既有的 root=/dev/sda22 等） |
| 内核 config/补丁 | fork meizu20-t4b | `CONFIG_DPM_WATCHDOG`（`6ba9d7cb3fc0` 摘 EXPERT 依赖）+ dpm 遍历打印（`2431440968fe`）——调试仪器，平时零开销 |
| ath12k | fork `02fe4629080a` | 非 wow 路径的止损件（resume_early 暖分支）；wow 路径不出场 |
| 设备包 | `meizu-wowlan.service` + preset | `iw phy phy0 wowlan enable magic-packet`（武装 wow 路径）+ sleep 封条自愈 + `depends iw` |
| 设备包 | `10-meizu-no-watchdog.conf` 等 drop-in 三件 | §6.2 的看门狗/journald 修复 |
| 内核 r81+ | `CONFIG_RTC_HCTOSYS_DEVICE="rtc1"` | rtc0（rtc-efi）废件不再吃时钟角色 |

现役回归（Release r84 / 内核 #85，2026-10-12，用户在场验收）：rtcwake 51s →
`resume devices took 0.240s`、wowlan 武装保持、udevd/logind WatchdogUSec=0
生效、failed 0、桌面会话睡醒全活。

### 7.2 在其他 s2idle 设备上的复现检查单

1. **先跑 §5 判别法**（Y 死 / N 过，2 分钟）——printk 这层与本机器件无关，
   v6.4+ 内核都可能撞；先把它摘掉再排查别的。
2. **取证通道先闭环**：别信"部署了 ramoops 就有现场"——写标记→重启→读回
   验证一圈再开始实验（§2.3）。窗口内直播 = netconsole + `dmesg -n 7` +
   `console_suspend=N` + `pm_async=0`（§3.2）。
3. **测 logind 路前断 ssh**；判真重启看 uptime/MAC/stats 三件套，别看
   "网络不可达"。
4. WiFi 死活的判别装 `iw`（本机曾因没装 iw、把空输出当阴性，白走三轮——
   **判据工具先验存在**）；无 iw 的替代判据 = WiFi PCI 设备的
   `power/wakeup` 在 `iw phy0 wowlan enable` 后翻 enabled。
5. 睡醒体感差的先看 `PM: resume devices took` 找绑架者（§6.1），再看
   看门狗击杀（§6.2）——两层都过还有问题才轮到显示栈/合成器。
6. >3min 的睡眠必须处理 systemd 看门狗（§6.2），否则每次长睡都送一次
   udevd/logind。

---

## 8. 已知残留与未决（截至 2026-10-12，如实）

| 项 | 状态 |
|---|---|
| 非 wow 路径的 WiFi 睡后死 | **未治，已绕行**（出货默认 wow）。根因 = service-ready 死结（§6.1）；候选修法三条，均未排程 |
| magic packet 唤醒 | 一行 DTS + 重编（§6.3 配方），结果未知（MHI/PME 平台路径可能还有门槛），低优 |
| 电源键"入睡"动作 | KDE/plasma 侧默认动作未验（B3 项） |
| 触屏唤醒 | 驱动无 wake 支持，中等工程（§6.3） |
| pstore 长期家 | 未解决：0xa8000000/0xB0000000 双杀，RSRV0 两址未做标记存活测试；且需先验 `console_suspend=N` 下 legacy console（ramoops）能否收到窗口日志 |
| 「Y 必死」的本机触发条件 | 未钉死（§4.4 反转）；补测方向 = Y + netconsole 扰动复现 |
| 期望管理 | s2idle 修好 ≠ 安卓级待机：deep（PSCI SYSTEM_SUSPEND）档本机与参照机都进不去 AOSS 深睡（`aosd=0` 同款），MPM/AOSS 是另一场战役；本文交付的是"熄屏进 s2idle、RTC/电源键可唤醒、醒后亚秒恢复" |

---

## 9. 资料地图（哪份事实在哪）

| 想查什么 | 在哪 |
|---|---|
| 刷机 / 交付链背景 | 本仓 [FLASHING.md](FLASHING.md)、[DESIGN.md](DESIGN.md) |
| ABL 与 ramoops 地址的关系 | [BOOT-CHAIN-RE.md §6.3](BOOT-CHAIN-RE.md) |
| 内核 fork（printk 仪器补丁 / ath12k 系列补丁，本文全部 hash 所在） | <https://github.com/RiverKawa271828/linux-mobile-ports>（分支 `meizu20-t4b`；rc3 时代旧 hash 见 tag `archive/pre-rc6-meizu20-t4b`） |
| 设备包（wowlan unit / watchdog drop-in / cmdline） | <https://github.com/RiverKawa271828/pmaports>（分支 `phoenix`，device-meizu-meizu20） |
| 上游回归与修复讨论 | `9e70a5e109a4`；LKML 2026-01 "freeze on resume" 线（lkml.org/lkml/2026/1/29/619）与 "Reintroduce consoles_suspended global state" 系列（patchew.org/linux/20251111144328.887159-1-john.ogness@linutronix.de/） |
| 完整实验叙事（11 轮判据读数） | 私有工作区 `suspend-test-20261008/FINDINGS-20261008.md` + 实验日志（未公开；本文已收编其全部结论） |
