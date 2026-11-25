# 执行卡：电池电量计 r132 + 蜂窝 UI 开关（2026-11-25）

> 状态：**✅ 收官（2026-11-25 晚，无人值守全程）**。结果 = 电池遥测修上机 #133 全绿
> + 蜂窝 UI 开关活 + **P2 上游回归全通（NM 拨号链真通）** + 单 call 域互斥定谳 +
> mm-dial 潜在 bug 修（r79）+ 数据面恢复。SIM 后半程 = 用户插卡 + ≤50MB 授权
> （实际消耗 <20KB）。功耗首测取消（用户口径）。
>
> **✅ 加演：P3 蜂窝标准化收官（同日晚，用户拍板「跟着上游来」，卡在机全程）**——
> 数据面交还 NM 标准形态（r80+r81），reboot 全验通过，详见文末 P3 节。

## P3 蜂窝标准化（r80+r81，收官补记）

**实验先行（两问全有答案）**：
- **WiFi failover**：断 WiFi → NM 把 qmapmux 默认路由**晋升进主表**（metric 700），
  非绑定流量即走蜂窝（HTTP 实弹）——`50-wwan-policy.conf` 表 1430 形态原生可用，
  无需任何手工路由；WiFi 回来自动退回（600<700）。
- **DNS**：NM 收到 carrier DNS（journal 实录）但**不推 resolved**（qmapmux 被
  注册为 Generic device，push 环节 NM 侧断）；断 WiFi 时 resolved 走 systemd
  上游默认 **FallbackDNS（quad9）** 经蜂窝解析实证成功（baidu 真解出）。功能无
  缺口，carrier DNS 缺席 = 已知小缺口接受（纯上游默认行为；复燃 = NM upstream）。
- keeper 数据面看门**结构性失活**（只 grep 主表 qmapmux 路由；NM 形态路由在表
  1430）⇒ keeper 零改动，注册面自愈照旧。

**实现（pmaports b1bc18d，REL_DEVICE=81）**：
- **r80**：profile autoconnect=true×2 + preset mm-dial enable→disable + tmpfiles
  `meizu20-retire-mmdial.conf`（清扫旧装机 enable 残链）+ cell-switch.sh 数据尾
  改「NM autoconnect 跟卡」（显式 mm-dial 重拨 = 单 call 域双死路径）。
- **r81（reboot 全验暴露的隐性依赖）**：mm-dial 退役连带拔掉它内嵌的 boot 救援
  （等 modem 对象 + failed→restart MM 重扫）——本平台 MM×qcom-soc boot 竞速
  **常态性落 failed/power-off**，无人救则 NM autoconnect 永远 unavailable。
  补 `cell-mm-rescue` oneshot（只 restart MM 不拨号不铺路，≤2 轮有界，After
  禁 multi-user[pas 自环前科]）。
- **终验（reboot 全程）**：rescue 开机自启（boot+54s 完成退出）→ MM 恢复 →
  **NM autoconnect 自动激活 cmnet** → qmapmux0.0 → `ping -I` 3/3 @39ms；
  mm-dial 全程未跑；failed=0； keeper 注册面舞步正常。
- **回滚**：`systemctl enable mm-dial` + profile autoconnect 翻回 false +
  装回 r79；一条 preset 翻转即复活。

**现态语义**：插卡即用 = 纯上游形态（NM autoconnect），短信/信号/双卡切换 UI 面
= MM/plasma-nm 标准；非标残余仅两件有上游理由的：单 active 槽（upstream MM
双槽 bug workaround）+ keeper 注册面自愈（DMS offline 平台特有）+ boot 救援
oneshot（平台竞速特有）。

## 结果速记（收官时补）

**任务 A（电池 r132）✅**：
- fork `24df27f74fc4` + pmaports `6629f7e`（pkgrel 132）→ 本机构建 19:17-19:49 →
  ESP v91（裸 `b80fb8b2` / gz `db0ac0c8`）→ verify 全绿（dtb 同源 35652d24，
  Mu 免重编正确）→ upgrade.sh 双腿上机 → **uname #133** + recovery_a 读回对 sha ✓。
- **修复实证**：`charge_counter=3,994,000 µAh`（修前 3941）、`energy_now=17,577,594 µWh`
  ≈17.58Wh（修前 17360）；upower `energy-full=17.973Wh`、percentage/time-to 全真值、
  history 文件恢复滚动写入。TECH-DEBT 13 主诉求闭合。
- **阈值另案定谳**：`charge_control_end_threshold` 写读仍 0——与 ×1000 连锁**无关**
  （该路径 = get 回内存缓存 / set 走 `BATTMGR_CHG_CTRL_LIMIT_EN` opcode；写 RC=0
  但缓存不更新 ⇒ firmware 对 opcode 无应答 + 上游 store 无条件 `return 0` 吞错）。
  TECH-DEBT 13 的阈值子项改判 firmware 域独立问题（低值，候补池）。

**任务 B（蜂窝 UI + 上游回归）✅**：
- r78 上机（先删 11-22 手工件再装包）→ restart NM → **qrtr0 managed**、
  两枚 profile 可见（AUTOCONNECT=no）、无循环签名。
- **P2 全通（无既有 call 时）**：`nmcli con up cmnet` 1 秒激活 → NM 自建
  qmapmux0.0@rmnet_ipa0（IP 10.164.22.143/27）+ 表 1430 标准路由（policy conf
  自动生效，无需手工 metric）+ `ping -I` 4/4 @41ms + 绑口 TCP/HTTP 实弹 ✓。
  **"NM 不认 qmapmux"旧判词翻案**——r75 的 unmanaged conf 才是当年 blocker
  （TD-11 死窗时代遗留误伤）。
- **互斥定谳（重要）**：mm-dial 占线时 NM 激活 = **`call-already-present`**（本平台
  IPA 路径单 call 域），且 MM 断开流程把旧 bearer 带走（双死，数据面全下）。
  NM 与 mm-dial **互斥不可并存**；P3 取舍（退役谁）从"可能"变"确定"。
- **mm-dial 潜在 bug 实战暴露 + r79 修复**：modem 输出 `initial bearer path`
  （无配置 initial-EPS 对象）排在 Bearer 节 paths 之前，`grep -o|head -1` 抓错
  （initial=Bearer/1 vs 数据=Bearer/0）⇒ -b 1 无 IPv4 三连 FAIL。r79 改遍历取
  「connected+IPv4」者，上机 PASS 第 1 轮（pmaports `fe8f1de`）。
- DNS 缺口（P3 清单）：NM 侧 `IP4.DNS` 有 carrier DNS 但未推 resolved（mm-dial
  形态自己 resolvectl 挂好了）；上游化时须解决。
- 交回态：数据面 = mm-dial 自动链**在网**（cbnet 被移动卡受理实测）；NM path
  已验证待 P3 接管；failed=0；流量消耗 <20KB ≪ 50MB 预算。

## 现态速览（2026-11-25 19:20 实测）

- 设备在线：`uname -v` = `#132`（= apk r131），`systemctl --failed` = 0；
  数据面 = r77 自动化链在机；**当前无 SIM**（MM `failed/sim-missing`）。
- 电池 bug 现场仍可复现：`charge_full=3,941,000 µAh` vs `charge_counter=3941`、
  `energy_now=17360 µWh`（应 ≈17,360,000）。
- 任务 A 源码已完成：fork `24df27f74fc4`（SM8550/MEIZU variant 门控 ×1000，
  `qcom_battmgr.c` BATT_CHG_COUNTER）；pmaports `6629f7e`（kernel pkgrel=132 +
  tarball sha512）。**fork 该 commit 未推远端**（推送窗口 = 用户）。
- 任务 A 构建：**已在跑**，systemd user 单元 `pmx-nura-build-kernel-191712`
  （19:17 起），日志 `~/work/pmos_linux/pmos/.pmbootstrap/log.txt`。
- 任务 B 现场：NM 里 `qrtr0` = **unmanaged**（`/usr/lib/NetworkManager/conf.d/00-nura-qrtr-unmanaged.conf`），
  MM 有 modem、NM 无 ModemDevice。

## 任务 A：电池遥测单位修 → r132（主件）

### 已做
1. fork commit `24df27f74fc4`：`BATT_CHG_COUNTER` 在 `QCOM_BATTMGR_SM8550` /
   `SM8550_MEIZU` variant 下 `val *= 1000`（和既有 `BATT_POWER_NOW` 毫瓦修法同风格）。
2. pmaports `6629f7e`：`device/downstream/linux-meizu-meizu20/APKBUILD` pkgrel=132
   + tarball sha512。

### 待做（按序，坑已标注）
1. **等构建单元真完**（勿拿命令返回当完成：脚本经 systemd-run 后台发射）：
   ```
   systemctl --user is-active pmx-nura-build-kernel-191712     # 等到 inactive/failed
   ls -l ~/work/pmos_linux/pmos/.pmbootstrap/packages/edge/aarch64/linux-meizu-meizu20-7.3.0_rc6-r132.apk
   ```
   ⚠ 沙箱 shell 的 `HOME=/home/ri/ubuntu`，工作区在 `/home/ri/work`：
   **手动重跑必须先 `export NURA_WORK=/home/ri/work`**（否则 nura_precheck 报钉子失效）。
   重跑命令：`NURA_WORK=/home/ri/work script/build-kernel.sh`（不用 `--bump`，pkgrel 已是 132）。
2. **ESP 腿**：`script/build-esp.sh`（自动取 artifacts 最大 vN+1 = **v91**）。
   ⚠ 必须等内核单元真完再跑（v86 半写竞态废件教训）。
3. **定版三写**（必须在 `verify.sh` 之前，否则 [4] 红）：
   `config.sh`：`REL_LINUX_PKGREL=132`、`REL_KERNEL_VER="#133"`、
   `REL_ESP_IMG=...esp-recovery-v91.img.gz`；**`REL_MU_IMG` 不动**（DTS 未变，
   Mu 不重编，FdtBlob 仍与 mu-r131 同源）。
4. `script/verify.sh` **全绿**（[1] apk↔Mu FdtBlob 同源 / [4] ESP↔apk vmlinuz）。
5. **上机两腿**（用户在场地报）：`script/upgrade.sh --i-am-present --apk <r132.apk> --esp artifacts/esp-recovery-v91.img.gz`
   （⚠ 默认取最新 apk ⇒ 必须显式 `--apk/--esp`；只碰 recovery_a，boot_b 不动）。
6. reboot 验收：
   - `uname -v` = `#133`；
   - `charge_counter` ≈ **3.9×10⁶ µAh**（≈ capacity% × charge_full）；
   - `energy_now` ≈ **1.7×10⁷ µWh**（≈17.3 Wh）；
   - upower `/var/lib/upower/history-*.dat` 不再是 `0.000/unknown`；
   - `charge_control_end_threshold` 可读回非 0；`time_to_empty` 数量级正常；
   - `systemctl --failed` = 0，数据面/蜂窝不受影响（本改动无 DTS/无 Mu）。
7. 收官：MANIFEST 现役表 + config 钉子对拍；commit（**不 push**）。

## 任务 B：蜂窝 UI 开关（无卡限定）

### 根因（源码级已定，2026-11-25 取证）
- 用户看到的两处 UI 都来自 plasma-nm：
  - 快速设置开关：`/usr/share/plasma/quicksettings/org.kde.plasma.quicksetting.mobiledata/contents/ui/main.qml`
  - 设置页：`kcm_cellular_network`（`plasma-nm-6.8.3`）
- 二者共用 `plasma-nm libs/cellular/CellularModem`：
  - `mobileDataSupported() = m_nmModem && hasSim()`
  - `needsAPNAdded() = m_nmModem && mobileDataSupported() && m_nmModem->availableConnections().count()==0`
  - `mobileDataEnabled()` 看 `isWwanEnabled() && m_nmModem && (Activated || device autoconnect + 某 profile autoconnect)`
  - `m_nmModem` 来自 `NetworkManager::networkInterfaces()` 中 **UDI == MM modem UNI** 的 ModemDevice。
- 现 `00-nura-qrtr-unmanaged.conf` 把 `qrtr0` 列入 `unmanaged-devices`
  ⇒ `m_nmModem = nullptr` ⇒ 开关恒关/点了只跳设置页，APN 列表也建不起来
  （"APN needs to be configured"）。这就是"数据开关没用 + 显示 APN 未配置"的结构因。
- 另：`/etc/NetworkManager/system-connections/meizu-mobile-data.nmconnection`
  （APN=cbnet，11-22 手工建、**未入包**、autoconnect 默认 yes）已在设备上，
  但设备不归 NM 管 ⇒ 不进 `availableConnections`，UI 看不见。

### 方案 A（推荐，本轮做）：让 NM 托管 qrtr0 + 收编 APN profile
设备包 **r78**（pmaports `device/downstream/device-meizu-meizu20`）：
1. 改 `00-nura-qrtr-unmanaged.conf`：unmanaged 只留
   `rmnet_ipa0,rmnet0,qmapmux*`，**摘掉 qrtr0**；注释写清"UI 开关需要 NM
   看到 ModemDevice，拨号仍归 mm-dial/keeper"。
2. 新增 `meizu-mobile-data.nmconnection` 入包（`package()` 显式
   `install -Dm600` 到 `/etc/NetworkManager/system-connections/`），并在
   `[connection]` 里**显式 `autoconnect=false`**（关键：防 NM 开机自动拨号 =
   历史"NM auto-enable 循环加速器"复发路径）。APN 建议 cbnet（广电）与
   cmnet（移动）两条 profile，均 autoconnect=false。
3. 打包顺序纪律：改源 → checksum → commit（`027e081` 踩过顺序反的坑）。

**无卡可验（本轮验收口径）**：
- `nmcli -t dev` 里 `qrtr0:gsm:unavailable:managed`（managed=yes）；
- 快速开关状态从 "Not Available" 变成 **"No SIM inserted"**（不再死灰）；
- 设置 → 蜂窝 → APN 列表出现 cbnet/cmnet；`needsAPNAdded` 不再报未配置；
- boot 后 `systemctl --failed`=0、MM state 仍 `sim-missing`、journal 无
  modem enable/disable 循环、WiFi/数据面自动化不受影响（kill 判据：
  `grep -c "modem.*enabled"` 无分钟级风暴）。

**有卡窗口待办（不在本轮，卡回来自动进队列；★用户 11-25 拍板「跟着上游来」）**：
- ★**上游语义已接受并入档**：plasma-nm `setMobileDataEnabled(true)` 只激活"最近
  用过"（timestamp 非空）的连接 ⇒ **新 profile 首次点开关 On 不会拨号**（只置
  autoconnect）。正确用法 = 插卡后先去 设置→蜂窝→APN 列表 **手动激活一次**
  （此后 timestamp 落库，开关 On/Off 才能真拨/真断）。⚠插卡当天若"点开关没反应"
  先走这步再判故障，勿误判回退。
- 开关 On/Off 实测：On = NM 激活 profile → MM bearer（= 一百二十验证通的 MM
  拨号形态，r131 IMEM 在位）→ **存疑段 = NM 给 qmapmux0.0 配 IP**（r75 起
  qmapmux* unmanaged；NM 不认）；Off = autoconnect 清零 + NM disconnect。
- 三种结局分支：① NM 拨号全通（含 qmapmux0.0 IP 配置）⇒ **mm-dial 退役/降级
  为兜底，开关成数据面唯一权威**（"Mobile Data 开关灰"翻案）；② 卡死在
  qmapmux IP 配置 ⇒ 摘 qmapmux* 出 unmanaged 交 NM 接管（= 排面⑤本体）或
  维持"开关=意图表达"现状并文档明示；③ 复发 21 次/min 循环 ⇒ 立即回滚。
- 并存期已知脱节（接受，文档明示）：boot 后 mm-dial 自动拨好但 NM 视角未激活
  ⇒ 开关显示 Off（假阴）；点 Off disconnect 不动 mm-dial 链路（假阳）。

**回滚（一步）**：把 `qrtr0` 加回 unmanaged + `systemctl restart NetworkManager`；
或装回 r77 设备包。

## 附：上游 SIM/数据标准栈 vs 我们的偏差（用户 11-25 问「上游怎么做的」）

**上游五层**（pmOS Qualcomm 机型 FP5/FP6/OP6/平板6SPro 同构）：
1. 链腿（remoteproc mss/rmtfs/qrtr/tqftpserv/pd-mapper）——**我们 ✅ 已对齐**（r65）；
2. **ModemManager** = 唯一 modem 控制 daemon：SIM 检测/PIN/注册/信号/短信(WMS)/
   bearer 创建（qcom-soc 插件建 qmapmux0.x@rmnet_ipa0）——**我们 ✅ 已标准**（短信/注册/拨号全走 MM）；
3. **NM + wwan 插件** = 数据面标准路径：激活 gsm profile → NM 命 MM connect →
   bearer → NM 自动配 bearer 数据口 IP/路由/DNS（推 resolved）；pmOS base-ui
   随发 `50-wwan-policy.conf`（gsm 路由专表 1430）⇒ **上游无需手工 metric**；
4. UI（plasma-nm 开关+KCM / initialstart 向导 / SimLockPage PIN）——只讲 NM D-Bus；
5. SpaceBar(短信)=MM 直连——**我们 ✅ 已通**。

**我们的非标偏差（全在第 3 层用户态胶水）**：`mm-dial.sh`（替 NM 激活+手工
IP/路由 metric 700/DNS）+ `cell-keeper.sh` 数据面看门 + `00-nura-qrtr-unmanaged.conf`
隔离。**标准化路线（P2-P4 全等有卡窗口；P1=本轮 r78 已落）**：
- **P1（本轮）**：qrtr0 交还 NM + profile 入包（autoconnect=false）→ UI 活；
- **P2**：NM 激活全链实测（profile→MM bearer→**qmapmux0.0 IP 配置**，一步同时验
  "NM 不认 qmapmux"是否成立）；
- **P3（P2 通后）**：退役手工链——mm-dial 退/降兜底、keeper 数据面看门退
  （注册面自愈可留）、unmanaged conf 摘除或缩编；
- **P4**：profile autoconnect 恢复上游默认 true（插卡自动连）——前置复验 keeper
  舞步×NM enable 交互。
- **上游理由保留件**：①单 active 槽（upstream MM 双槽 hot-swap bug workaround，
  upstream 修好前不撤）②keeper 注册面自愈（DMS offline 死锁 = 平台特有）。

### 方案 B（备选，重，不建议本轮）
不放开 NM，改 plasma-nm QML/KCM 走自研 `cell-data` 脚本 —— 需 pmaports 打
plasma-nm patch + rootfs 重出（Release 级），且升级会覆盖。留作有卡实测
失败后的备选。

### 明确不做
- 不改 MM 侧（单 active 槽 + `uim-sim-power-off=2` 形态保持）；
- 不碰 `mm-dial.sh` / `cell-keeper.sh` 逻辑（本轮只让 UI 看见设备）；
- 不重启 MM、不 `mmcli -m any --enable` 手工舞步（无卡无意义）。

## 纪律提醒
- `commit` 不 `push`；Release/推送窗口 = 用户。
- 红线分区永不碰；本轮仅 apk 腿 + recovery_a（ESP 腿）；刷写需用户在场
  （本轮非 DTS 变更，不走 11-20 自刷豁免，除非用户明确授权）。
- 无人值守任务才灭屏（用户在场不灭屏）。
- 设备无 SIM = MM `failed/sim-missing` 是**常态**，别当故障修。
