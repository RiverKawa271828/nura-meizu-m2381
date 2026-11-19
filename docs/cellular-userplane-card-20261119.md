# 蜂窝用户面轮·执行卡（2026-11-19 交接；用户令：短信/5G/通话/双卡「安排下个会话做，做不完就加入待办一个个解决」）

> **状态 = 待开工**（设备 = #96 + v75 + mu-r91 + plasma-mobile rootfs；前态 =
> 一百零三：数据面端到端全通 + 托盘蜂窝态可见 + MM 活。解封仪式 / d1_dataup /
> 三定律 = tools/cellular/README.md）。

## 0. 底数与资源约束

- **双卡 ground truth（11-19 实读）**：槽 1 = 广电测试卡（460-15，注册态）；槽 2 =
  **中国移动卡已插，modem 已识别（card present，双槽 active）**。槽 2 卡可少量
  流量测试——**⛔总预算 ≤100MB（用户钉死；本轮所有流量测试合计计账，吃满即停）**。
- 现态速查 = `systemctl is-active ModemManager` + `qmicli --nas-get-serving-system`
  （registered？）+ `ping -c1 223.5.5.5`（数据面活？）。若设备重启过 = 全仪式重跑
  （解封→provision→舞步→`d1_dataup.sh`）。
- 一次一变量铁律照守；取证一律 journalctl -k。

## 1. 主件 A：短信收发探针（首选，半轮；流量成本零）

1. 基线：`mmcli -m any --messaging-list-sms`（MM messaging API 在册态）+
   `qmicli -d qrtr://0 --wms-register-indications="...event-reporting..."`。
2. 发送：**外发短信 = 用户授权面，先问号码**；MM `--messaging-send-sms` 与
   `qmicli --wms-send` 双路择优记档。
3. 接收：用户回一条 → indications 到达判据（MM sms 对象出现 / qmicli event）。
4. 网络面：广电无 2G/3G → NAS 级短信（LTE S1AP/SA SNS）= 中国全网标准形态，预期通；
   若 WMS 拒 = 记 signature 收兵（不重试轰炸）。
5. 判据 = 双向收发各一发全过 = 主件达成。UI 短信应用（plasma 无默认短信 app）不在本轮。

## 2. 主件 B：5G SA 钉住（搭车件，~10min）

1. `mmcli -m any --set-allowed-modes=4g|5g --set-preferred-mode=5g`（NAS 命令，
   非拨号不触红线）→ `--nas-get-serving-system` 回 5gnr。
2. `d1_dataup.sh` 数据回归（通路 RAT 无关，预期直通）+ 30min 驻留稳定性 +
   crash 计数不涨。
3. 判据：5gnr serving + ping 通。回落 lte = 信号依赖记档非失败（101 时 5gnr
   驻留 110s+、SSR 后 lte 回落在案）。

## 3. 主件 C：双卡 / DSDS（槽 2 中国移动）

- **变量顺序（一次一变量）**：①只读对拍（`mmcli -m any` SIM 视角 +
  `--uim-get-slot-status/--uim-get-card-status` 双槽全读）②**uim-selection 摘
  mask = 独立变量**（pmOS 槽管理 helper；观察其对双槽行为；MM requires 摆链已摘
  无冲突）③MM 侧 slot 2 使能/secondary 路径 ④双待判据。
- 判据 = 双卡同时待机注册（DSDS standby）或「数据卡 + 待机卡」并存；**默认数据卡
  切换 = 用户拍板项**（涉及双 PDP/多 mux——UniXNU pdp.h：Apple 用 mux 1-4 分
  上下文 + bind_family 0x4D，可平移）。
- 槽 2 卡流量测试 = 预算内计账；固件面利好 = PDC platform `DSDA_Hybrid_CDMALess-LA-Kailua`
  Active（102 已证）。

## 4. 主件 D：VoLTE 信令（长件，做不完进待办）

- **明示范围 = 呼叫信令网络面（振铃/接通/挂断可见）；音频不做**（ADSP voice
  session = 主线普遍墙，独立战役档；参考 oneplus-ace5 情报）。
- 步骤：①IMS PDN 呼叫变体（d1_bindmux 改 APN `ims` + IM CN subsystem flag；
  bind_family 0x4D + start family TLV 0x19 = pdp.h 形态）②IMS 注册判据（IMS
  settings/app 服务读态；P-CSCF 经 PCO）③voice originate（`qmicli --voice-dial-call`
  / MM call API）→ **网络面振铃 = 里程碑**④崩 = 新签名收兵记档（101 精神：
  崩了不算败，读数即里程碑）。
- 外呼号码 = 用户授权面；通话对端最好用第二台手机。

## 5. 红线继承

**流量总预算 ≤100MB（吃满即停）** / 涉及 uim-selection 摘 mask 或 slot 使能前
**EFS 快照先行（第四份）** / MM 禁 NM 建 GSM 拨号 profile（数据面 = 手工
d1_dataup） / 外发短信与默认数据卡切换 = 用户授权面 / 一次一变量 / commit 不 push /
推送与 Release = 用户。
