# Plasma Mobile 出件 + 蜂窝续攻·执行卡（2026-11-19 交接；用户令「下个会话出件 plasma mobile，最新版，完成之后继续攻蜂窝网络；phosh 不方便看蜂窝状态」）

> **状态 = 主件 A ✅ 出件 + 主件 D1 ✅ 双墙根治（2026-11-19，用户令本会话改跑蜂窝线、
> plasma 自刷）**。A = plasma-mobile **6.8.3-r0** 上墙（world 对拍零混装，
> `artifacts/meizu-meizu20-plasma-mobile-local.img` 3.4G + r95 gz 1.2G）——**userdata
> 重刷 = 用户自行执行**（B 清单照 §2 跑）。D1 = **DPM Open Port 缺位实锤根治双墙**：
> DPM open（endpoint TX=2/RX=24）→ mux bind 0xF1 (0,0) → start network (0,0) →
> **IP 10.17.132.15 + DNS 全分 = 空口 PDP 首次建立**；残墙 = IPA 硬件通路（μC 崩尸态
> → TX dropped 包不出 AP）须 reboot 冷启重试（候补，禁令待用户拍板）。
> 战报 = experiment-log（一百零二）+ 记忆 cellular-d1-dataplane-dpm-open-20261119。
> 剩余 = B（用户自刷 plasma）→ C（含 plasma-nm 状态面实验 = 用户核心诉求）→
> D 残面（IPA fatal 墙 + 端到端真包）。

## 0. 版本底数（本轮已核）

- **plasma-mobile = 6.8.3-r0 族**（Alpine edge aarch64，2026-11-11 build；plasma-mobile/-meta/-systemd/-waydroid 同版）=「最新版」预期值，构建时以 APKINDEX 实解析为准；上机后 `apk info | grep plasma-mobile` 对拍。
- 内核/设备包 = 现役钉 **r95/#96 + device r63**（不出新 apk，纯换 UI）；**fw r4 应自动烤入**（本地 packages 最新 apk；上机后核 `/lib/firmware/qcom/sm8550/meizu/modem_pr/` 在位）。
- stable 复查起点 = **7.3.6 / 7.4 正式**（11-19 复核 7.3.5 = 最新，零交集不跟进）。

## 1. 主件 A：plasma rootfs 出件（宿主，零设备）

1. **换 UI 必 zap**：`script/pmbootstrap-meizu.sh -y zap`（⚠**-y 在子命令前**，放 zap 后报 unrecognized；防 phosh/plasma 混装——脚本有 world 校验会自拦）。
2. 构建：`export NURA_WORK=/home/ri/work`（沙箱跑须此步）→ `script/build-rootfs.sh`（**默认 NURA_UI=plasma-mobile，勿再覆盖**；install ~10-20 分钟 + 打包）。
3. 产物 = `artifacts/meizu-meizu20-plasma-mobile-local.img`（+release gz 走 r86 起 UI 后缀命名；**发布/上传窗口 = 用户拍板**，赶时间可 `NURA_NO_RELEASE=1`）。
4. 判据 = build 日志零 FATAL + img 生成 + （可选）pmbootstrap 内 apk world 对拍 plasma-mobile 6.8.x。
5. ⚠pmbootstrap 单实例律：构建前确认无并发构建；systemd-run 守卫脚本已固化勿改。

## 2. 主件 B：上机回归（用户在场窗；fastboot 单通道律）

1. **重刷前先拍 EFS 快照**（S-1 红线不变；11-19 份已在 `pmos_linux/efs-snapshot-20261119/`，本轮注册写过 EFS = 重拍一份归档）。
2. rootfs 腿 = **userdata 全量重刷**（换 UI 口径；/home 清空——`/root/*.py` 蜂窝件会丢，C1 重推）。fastboot flash userdata（FLASHING §5 首 boot 清单照跑；红线 §8 照守，只碰 userdata 不碰 boot/recovery）。
3. 回归清单 = boot 时长 / plasma 会话起 / failed 0 / uname #96 / WiFi / 音频 / 触控 / 声卡 / wowlan。
4. ⚠plasma 楔死坑 = restart plasma-mobile + 杀 kwin_wayland{,_wrapper}/plasmashell/plasma-keyboard 孤儿四件（记忆 meizu20-phosh-build）。
5. 上机核对：`apk info | grep plasma-mobile`（6.8.x?）+ modem_pr 目录在位（fw r4 烤入实证）。

## 3. 主件 C：蜂窝用户态回归 + plasma-nm 状态面实验（一次一变量）

- **C1 重装蜂窝用户态**（同 11-19 轮配方，件全在宿主 pmbootstrap cache/packages）：
  钉版件 = rmtfs 三件 + uim-selection 两件 + soc-qcom-modem-systemd + tqftpserv-1.0-r0
  （单次 apk add 防子包挤掉坑）+ qrtr/qmi-utils（edge 直装）；/etc 层五件重做 =
  rmtfs 无限重试 drop-in + MM/modem-gnss/uim-selection 三 mask + NM unmanaged
  `qrtr0,rmnet_ipa0`；白嫖件重推 `/root/{bind_all,data_daemon,modem_daemon,mux_matrix,scan_mux}.py`。
- **C2 解封仪式**（experiment-log 一百零一 §坑册）：清 `driver_override`（⚠字面量
  "none"≠空串）→ bind → `echo start` → 查 provisioning session（**重启/SSR 后必消，
  缺则 re-provision**，aid = `A0000000871002FF86FFFF89FFFFFFFF` 本机值）→ DMS 舞步
  （low-power→8s→online）→ registered 判据（460-15 广电）。取证一律 `journalctl -k`
  （dmesg 环形被 GPU IFPC 刷洗）。
- **C3 MM/plasma-nm 状态面实验（用户核心诉求 = UI 看到蜂窝状态）**：
  1. 基线 = MM 保持 mask，registered 达成（plasma-nm 无蜂窝图标 = 预期态）。
  2. 实验 = `systemctl unmask --now ModemManager` → 观察：①MM 认领 qrtr0（qcom-soc
     插件 10-04 已证可读 IMEI/选卡）②plasma-nm 托盘出蜂窝信号/注册态？③注册保持否？
  3. **禁拨号红线**（彼仓 #25：MM 拨号必败且拖崩 modem，崩溃计数 8→10）：NM 侧
     **不得创建 GSM/蜂窝连接配置**；若 MM enable 数据呼叫 → 立即看 modem 健康
     （journalctl -k fatal 计数 + serving-system），崩 = 回 mask 收兵记档。
  4. 判据 = plasma-nm 显示蜂窝态 且 注册保持 ≥10min = 用户诉求达成；MM 拖崩 =
     mask 回退 + rf_keeper 式自愈件升候补（D2）。
  5. 注：MM 自带 uim provision + DMS online（可能全包办 C2 舞步）——若实验证实，
     下轮流程可简化，记档。

## 4. 主件 D：蜂窝续攻（C 落定后）

- **D1 数据面双墙轮**（11-19 判收的候补，头号）：①DSD raw start-data-call（raw QMI
  探针，libqmi 无 dsd start 命令；mid 待验 0x0037 域，bind_all.py 同款 ctypes 形态）；
  ②PDC profile 路线（qmicli --pdc-* 族）；③firmware 对拍（彼仓 m2468-firmware
  c3-00008 提取法 vs 我方 MPSS.DE.3.0-KAILUA——彼通我拒的 firmware 级差异定位）。
  判据 = rmnet_ipa0 拿地址 + ping/DNS 通。
- **D2 rf_keeper 适配**（可选；若 C3 MM 路判负则升正选）：改 rf_keeper.py → nura 自愈
  unit（rproc=remoteproc2 / DMS 舞步 / journal 取证 / pause 逃生门 / 恢复后 restart data）。
- **D3 IPA fatal 墙**：候补池独立查（modem 侧 IPA μC 崩因；对拍彼仓四剩余假设 +
  观察 crash 与 RF 窗的相关性节奏）。

## 5. 红线继承

EFS 快照先行 / fsg-fsc-modemst-persist 永不写 / fastboot 单通道 / 刷写只看 dd 读回 /
MM 禁拨号 / 一次一变量 / commit 不 push / 推送与 Release 窗口 = 用户。
