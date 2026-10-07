# 刷机教程（Meizu 20 / m2381 · Nura 线）

> 原则：**每一步都带「怎么确认成功了」**；刷写时长不算证据，只看读回。
> 命令里的路径以 `config.sh` / `MANIFEST.md` 为准；脚本都在 `script/`。

---

## 0. 认识四件产物（先分清再动手）

| 产物 | 是什么 | 刷到哪 | 什么时候需要动 |
|---|---|---|---|
| `mu-rXX-YYYYYYYY.img` | Mu-UEFI 固件镜像（内含设备树 FdtBlob） | **boot_b** | 设备树/Mu 代码变了 |
| `esp-recovery-vNN.img.gz` | 100MiB FAT32 ESP，`BOOTAA64.EFI` = 内核（仓内 gz 化，刷写自动解压） | **recovery_a** | 每次换内核 |
| `linux-meizu-meizu20-*.apk` | 内核 vmlinuz + 全部模块 | 机上 `apk add` | 每次换内核（与 ESP 同轮！） |
| `device/firmware-*.apk` | 用户态胶水 + 固件 blob | 机上 `apk add` | 改了包内容 |
| `meizu-meizu20.img` | pmOS rootfs | **userdata** | 重装系统（日常不动） |

启动链：`XBL → ABL → boot_b(Mu) → 内核 → rootfs`；recovery_a 是 Mu 的备援引导（MsBootPolicy 标准路径）。

**两腿铁律**：换内核 = ESP 腿 + apk 模块腿，同轮完成。只刷 ESP 不装 apk = 内核新模块旧；
只装 apk 不刷 ESP = 引导旧内核配新模块。两种半死状态都会让你怀疑人生。

---

## 1. 前置检查

**适用基线（2026-10-06 定，先对上再动手）**：
- 全流程只在 **stock Flyme 12.6（最新 OTA）+ slot b 活动** 的零售机上验证过；
- 其他 Flyme 版本**未验证**——上一版 OTA 实测**起不来**（启动链绑 12.6 的 XBL/ABL 固件基线）；
- 动手前先把设备 OTA 到 12.6 并确认 b 槽活动（`fastboot getvar current-slot` → `b`）；a 槽激活态/旧版机行为未知，勿当小白鼠。

```bash
script/setup.sh          # 钉子/工具链全绿才继续；回滚锚缺失 = ⚠ 警告（救砖前必须补齐，§6）
fastboot devices         # 空输出 = 设备还没进 fastboot（看 §2）
```

- 他机复刻：`export NURA_WORK=/<你的工作根>` 后跑 `script/setup.sh --clone`
  （四仓 + 官方 pmbootstrap 自动摆位；回滚锚从 Release 下载放到 `config.sh` 指的路径）。
- 电量 >20%（刷一半没电 = 直接进 §6 救砖）。
- 数据线插宿主 USB 口（NCM 通道在系统侧，fastboot 在 bootloader 侧，都走这根线）。
- 确认回滚锚在位（`config.sh` 三个 ANCHOR_*，`setup.sh` 会查）。

## 2. 进 fastboot 的两条路

| 方式 | 操作 | 确认 |
|---|---|---|
| 软进（系统活着） | 机上 `systemctl reboot --reboot-argument=bootloader` | USB 枚举 `18d1:d00d` |
| 硬进（黑屏/死机） | 长按 **电源 + 音量减**（黑屏救砖组合） | 同上；极深死机 = 等电掉光落 9008 |

> 坑：ABL 重试计数每 ~7 次开机耗尽会自己落 fastboot——那不是坏事，是救你。
> 循环落 fastboot 先 `fastboot flash misc misc-zero.img`（清 bootonce）再重启。

## 3. 常规一车刷（内核轮标准流程）

### 3.1 刷 boot_b + recovery_a

```bash
script/flash-batch.sh --i-am-present
# 默认取 config.sh 的 REL_MU_IMG / REL_ESP_IMG；
# 可用 --boot-b / --recovery-a 指定单刷某一腿
```
脚本会打印刷写计划并要求输 `yes`；只碰 boot_b / recovery_a，别的分区碰都不碰。

### 3.2 重启进系统

```bash
fastboot reboot
```
确认：屏幕亮 → plasma 起来（首 boot ~1 分钟）。

### 3.3 装 apk 双包（模块腿 + 用户态包）

系统起来后走 NCM/WiFi 通道把 apk 推过去再装：

```bash
# 通道：ssh user@172.16.42.1（密码 1234；host key 变了加 -o UserKnownHostsFile=/dev/null）
scp linux-meizu-meizu20-7.3.0_rc3-rN.apk device-meizu-meizu20-1-rM.apk user@172.16.42.1:/tmp/
ssh user@172.16.42.1
doas apk add --allow-untrusted /tmp/linux-*.apk /tmp/device-*.apk
```

> 纪律：**主包+子包同装**（只装主包会挤掉 -systemd/-udev 子包，unit 消失 = D-Bus 激活全灭）；
> 装完 `doas systemctl daemon-reload`；设备 apk 仓库不可达告警属正常。

### 3.4 dd 读回对 sha（刷写成功的唯一证据）

`flash-batch.sh` 结束时会打印两个期望 sha。生成设备侧命令：

```bash
script/readback.sh <boot_b_sha> <recovery_a_sha>
# 把打印出来的命令粘到设备 root shell（root 通道 = nc :23 devshell，见 §7）
```

> 坑：用 `ssh user` 身份直接 dd /dev 会得空 sha（权限假象）——必须 root shell。

### 3.5 首轮特殊补装（仅重刷 userdata 后）

全量重刷 rootfs 会洗掉机上手工补装件。r52 起设备包已自带 NFC/蜂窝用户态的
摘除 mask（装包即到位）；若要**启用**蜂窝再补：

```bash
doas apk add rmtfs qmi-utils uim-selection soc-qcom-modem-systemd  # 蜂窝四件套（Alpine 仓）
# 另需：rmtfs StartLimitIntervalSec=0 drop-in + uim-selection deactivate 容错行
#       （补丁内容一行级，明细在私有工作区指纹表，未公开）
```

### 3.6 读回对不上？

只对不上的那一腿重刷（`--boot-b` 或 `--recovery-a` 单刷），再读回。连续两次对不上 = 换线/换口，
再不行 §6 回滚锚先回家，别恋战。

## 4. 两条短路径

- **只换内核（DT 没动）**：`build-kernel.sh --bump` → `build-esp.sh` → 刷 recovery_a + 装 apk。**不刷 boot_b**。
- **只换 DT（DTS 变了）**：内核重打后 **必须重编 Mu**（`build-mu.sh`，FdtBlob 从同 apk 抽）→ 刷 boot_b。
  —— 忘同步 FdtBlob = 上机还是旧设备树，这类事故血泪在册（（四十九））。
- **只换 rootfs**：`build-rootfs.sh` → `fastboot flash userdata <img>`（⚠ §3.5 补装件清零）。

## 5. 首 boot 验收清单（刷完必过一遍）

```bash
ssh user@172.16.42.1 'uname -v'                    # ① #N = pkgrel+1（#N 定律）
ssh user@172.16.42.1 'cat /proc/asound/cards'      # ② 卡名 MEIZU20 注册
ssh user@172.16.42.1 'ls /sys/class/backlight'     # ③ 背光在
ssh user@172.16.42.1 'systemctl --failed'          # ④ 已知三件非回归：rmtfs activating/
                                                   #    uim-selection start-limit / zram(若 r<r60)
journalctl -b | grep -iE "error|fail" | head       # ⑤ 无新红
```
触摸划两下、音量键、WiFi 连 现网5G。全过 = 收工；有红 = 记 journal，回滚，慢慢查。

## 6. 回滚与救砖阶梯

```bash
script/rollback.sh --i-am-present   # 30 秒：boot_b←t-b2 + recovery_a←v4d + set_active b
```
阶梯（从轻到重）：
1. 软进 fastboot 重刷出事的那条腿；
2. `rollback.sh` 回双锚；
3. 循环落 fastboot → `fastboot flash misc misc-zero.img`（misc-zero.img 自制：
   `fastboot getvar partition-size:misc` 拿大小 → `truncate -s <size> misc-zero.img` 全零即可）；
4. 黑屏无 USB → 硬进（电源+音量减）；
5. 9008/EDL = 最后通道（线刷配方在私有工作区仓，**9008 进出必须叫用户**）。

> 灭屏纪律：无人值守任务才灭屏（AMOLED 烧屏保护）；刷机是有人在场的活，屏幕亮着正常。

## 7. 通道速查

| 通道 | 用法 |
|---|---|
| root devshell | `tools/devsh.py`（NCM + nc :23，root，必须绑接口） |
| ssh | `sshpass -p 1234 ssh user@172.16.42.1`（doas 免密） |
| 推/拉文件 | `tools/devpush.py` / `devpull.py`（devsh 嵌 heredoc 会产空文件，别用） |
| 插墙充时 | RNDIS 断，走 WiFi（IP 会变，路由器后台看） |
| ping 不通 | 先查宿主 TUN 代理 TUN 劫持：`ping -I <接口>` 绑接口绕过 |

## 8. 禁令（不解释，照做）

- 不刷：xbl/abl/tz/modem、dtbo_b、super、picasso 系；不擦 modemst1/2、persist。
- misc 只按配方清零，不平时乱写。
- 一切写分区动作：用户在场 + 前台逐条 + 读回验证。
- 新 boot 镜像上机前：`verify.sh` 全绿。
