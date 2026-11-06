# 蜂窝复燃·设备窗执行卡（2026-11-07 备料轮产出；复燃 = 用户 11-06 点名「参考 21 Note 仓来修」）

> **状态 = 离线备料 ✅ 完成，等设备回链 + 用户在场窗**（与根治卡 rootcure-window-card
> 两门同源，可拼车/让路，用户定序）。
> 配方 ground truth = **leluo123/m2468-mainline**（同 SM8550/Kailua：注册+5G n41+
> WDS 拨号真 IP 已通，剩射频 30-45s PLL 崩墙）+ 我方 10-04 第一轮底档
> （pmos experiment-log 五十五/五十五乙：S0/S1/S2 全过 = 控制面全活，S3 拦截于
> DMS online DeviceNotReady）。

## 0. 战局定位（复燃为什么现在便宜了）

- 我方 S3 拦截点 = `--dms-set-operating-mode=online` → **QMI error 52
  'DeviceNotReady'** 稳定复现；当时排除清单（rmtfs/pd-mapper/冷启/DTS/slot2/电池实电）
  全判负，头号嫌疑 = modem 电池视图 0%。
- **21 Note 仓 34 条坑给出三个我方当时没做过的动作**：
  ① **#33 mcfg TFTP 通道**：modem 经 qrtr-TFTP 向 AP 拉 `mcfg/RF 卡文件`
  （`/readonly/firmware/image/...`），根目录缺料 = 射频起不来——我们 Stock Day
  收割树里 `modem/image/modem_pr` 全树（158 件：mcfg_hw/mcfg_sw + so 默认校准）
  一直在库，**从未进固件包** ⇒ S3 拦截点头号新嫌疑 = modem 拉 mcfg 无门；
  ② **#31 DMS 上下电舞步**：冷启后 RF=none 是常态，必须
  `low-power → sleep 8 → online` 拉起（我们当时只会反复 set online）；
  ③ **uim provision 必须显式 aid=**（`--uim-change-provisioning-session` 不带
  aid = QMI Internal/拒）。
- **电池视图 0% 假说降权**（彼仓无此症状记录、注册照通），保留观察不排除。
- 我方 tqftpserv-1.0 **自带 translate.c**：`/readonly/firmware/image/modem_pr/...`
  按 DTS `firmware-name = qcom/sm8550/meizu/modem.mbn` 自动翻译到
  `/lib/firmware/qcom/sm8550/meizu/modem_pr/...` ⇒ **设备侧零配置，目录是唯一缺口**
  （彼仓 #33 的手工软链 = 彼 tqftpserv 旧形态；我们不需要）。

## 1. 已落地离线件（本轮产出，全绿）

- **fw r4** = pmaports `f2885ef`（firmware-meizu-meizu20 pkgrel 3→4）：
  tarball +`qcom/sm8550/meizu/modem_pr/`（158 件 8.7M，IMEI 反查干净；
  **本地 apk 已构建** = `firmware-meizu-meizu20-1-r4.apk` 82.3M，APK-TOOLS 验
  modem_pr 462 项在包）。
- 本卡全序 + 判据 + 撞墙预案。
- （设备未重刷 ⇒ 10-04 本地件应仍在机：rmtfs drop-in / uim-selection 容错行 /
  pd-mapper binary+unit——窗内**先核对再补装**，勿盲装覆盖）。

## 2. 红线（继承 + 新增）

- **EFS 快照先行**：窗内第一动作 = devpull `modemst1 modemst2` 本地归档
  （彼仓 #34：bring-up 过程 modem 会写 modemst1/2；**fsg/fsc 永不碰**）。
- **MM 禁拨号**（彼仓 #25）：MM/NM 拨号必败且拖崩 modem（彼崩溃计数 8→10）；
  数据面 = WDS daemon 路线；NM 对 qrtr0 unmanage。MM 保持 mask。
- **qmicli DMS 读数不可信**（#29：显示 low-power 实为 online）——判态一律
  `--nas-get-serving-system` / 原始 QMI（dms_mode.py）。
- 一次一变量；journal 取证（dmesg 会被 ath12k 刷洗）；解封后每重启必回封
  （meizu-pas），重做解封步。
- 硬性禁令照旧（FLASHING §8）：不碰 modemst/persist 分区（AP 侧写）。

## 3. 设备窗全序（每步判据；每步独立可停）

**S-0 现态核对**：devselfcheck --light（B1 件）→ 10-04 本地件核对：
  `cat /etc/systemd/system/rmtfs.service.d/10-unlimited-retry.conf` 在？
  uim-selection 容错行在（.orig-20261004 备份在机）？pd-mapper unit 在？
  `apk info` 四件套版本 vs version-fingerprints-20261004.md。

**S-1 EFS 快照**：`devpull /dev/disk/by-partlabel/modemst1 modemst2`（dd 读）→
  本地 sha256 归档。判据 = 双份非零 + 记档。

**S-2 fw r4 装**：devpush r4 apk → `apk add --allow-untrusted
  firmware-meizu-meizu20-1-r4.apk`（或 upgrade）。判据 =
  `ls /lib/firmware/qcom/sm8550/meizu/modem_pr/so/` 有 so/*.mbn；
  `systemctl is-active tqftpserv` = active。

**S-3 用户态拉起**：rmtfs unmask → active（drop-in 在，start-limit 死锁不复发）；
  qrtr-lookup 确认 tqftpserv/rmtfs 在位。判据 = 两者 active 且无 failed。

**S-4 解封 mpss**（10-04 配方原样）：
  `echo '' > /sys/bus/platform/devices/4080000.remoteproc/driver_override` →
  `echo 4080000.remoteproc > /sys/bus/platform/drivers/qcom_q6v5_pas/bind` →
  `echo start > /sys/class/remoteproc/remoteproc2/state`（**auto_boot=false 必手动**；
  stop 有 8-10s 时滞，脚本轮询 offline 再动）。
  **tqftpserv 日志同步开**：`journalctl -u tqftpserv -f` ——modem boot 期 RRQ
  `modem_pr/...` 命中 = mcfg 通道通（本轮头号判据）；404/reject = 缺料实锤记档。
  判据 = remoteproc2 running + qrtr lookup WDS(1)/DMS(2)/NAS(3)/UIM(11) 有号 +
  rmtfs 3s 内收敛 + RRQ 命中。

**S-5 SIM provision（aid 显式）**：
  AID = `qmicli -d qrtr://0 --uim-get-card-status` 解析 slot1 application AID →
  `qmicli -d qrtr://0 --uim-change-provisioning-session="session-type=primary-gw-provisioning,activate=yes,slot=1,aid=<AID>"`。
  （彼仓实测 AID 形态 `A0000000871002FF86FFFF89FFFFFFFF` = 卡相关，**必须用本机卡
  解析值勿抄彼**。）判据 = Primary GW: slot '1' / card state present / app ready。
  ⚠ 若 session 已激活（EFS 持久），select 幂等重发即可；deactivate 分支别碰
  （10-04 坑②死循环在案）。

**S-6 DMS 舞步（#31）**：`--dms-set-operating-mode=low-power` → `sleep 8` →
  `--dms-set-operating-mode=online`。判据 = `--nas-get-serving-system`：
  registered / PS attached / radio '5gnr'（或 lte）；**无 error 52**。
  若仍 DeviceNotReady：取证 `--dms-get-power-state`（电池视图对照）+
  tqftpserv RRQ 全量回读 → 记档收兵；**S3 旧排除清单不重跑**。

**S-7 撞墙预案（预期管理）**：彼仓射频起 30-45s（数据态 ~2.5min）必撞
  `mcpm_resrc_modem_pll.c:1213` PLL assertion = 同 SoC 未解墙。**崩了不算败**：
  注册窗内 serving-system 读数（MCC/MNC/ band）就是里程碑。缓解 = rf_keeper 式
  DMS 断电循环自动恢复（参考实现彼仓 userspace/rf_keeper.py）；根治弹药 = 彼仓
  四剩余假设（`hyp_assign_phys(mpss_dsm_mem)` / MSS 寄存器块 `0x4080000` ioremap /
  `qcom,signal-aop`[主线零实现] / `crypto_ddr` 互联路径）= 我方 S3 贵路②
  （下游-主线 PIL diff）已被彼做半程，后续单列轮。

**S-8 数据面（可选，注册稳定 ≥10min 后）**：`nmcli device set qrtr0 managed no`
  → WDS daemon 拨号（彼仓 userspace/data_daemon.py 配方：mux 固定 INTERNAL(3)、
  modem 重启后重绑、**daemon 常驻持 socket**、崩后重启 daemon 重开 fd；APN 按
  用户 SIM，CMCC=cmnet 量级）。MM 全程 masked。判据 = rmnet_ipa0 有地址 +
  ping/DNS 通；间歇可接受（对齐彼仓现态）。

## 4. 收官判定

- **成功** = serving-system registered 里程碑成立 → 蜂窝从「挂起」转「半通」
  （= 彼仓现态对齐）；PLL 墙立新战线条目；文档三写（本卡状态行/AGENTS 现态/
  experiment-log 轮报）。
- **判负** = 逐步判据记 experiment-log，S3 排除清单**增补**（tqftpserv 根/
  DMS 舞步/aid provision 三件现已被本轮检验），不重跑旧项。

## 5. 出处

- 彼仓 = leluo123/m2468-mainline：README / docs/00-踩坑合集 §五（24-35）/
  evidence/{rf-bringup-dms-powercycle,uim-provisioning-fix,modem-state} /
  userspace/{dms_mode,data_daemon,rf_keeper}.py；固件仓 leluo123/m2468-firmware
  （隐私纪律同款：modemst/QCN/EFS 永不入公开仓）。
- 我方 = pmos experiment-log 五十五/五十五乙（S0-S2 底档 + S3 排除清单）、
  modem-kickoff-prep-20261004、（七十三）10-07 摘除（unmask 即复燃路径）、
  Stock Day vendor-fw-harvest（modem_pr 出处）、version-fingerprints-20261004.md。
- 审计底档 /tmp/m2468-mainline（会话级，复燃窗重克隆即可）。
