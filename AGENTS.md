# nura-meizu-m2381 — 项目指南与状态（本仓单一事实源）

> ★**接续卡（2026-11-01 蒸馏版：会话根 = 本仓）。历史全量底档 =
> [docs/AGENTS-ARCHIVE-20261101.md](docs/AGENTS-ARCHIVE-20261101.md)**（瘦身前原样
> 快照：2026-10-13~10-30 全部战役战报/判词/坑册 + 带话四轮回信，只读勿再更新）；
> 战役级叙事 = pmos_linux `docs/meizu20/experiment-log.md`。
> **新会话首跑三件**：
> 1. **记忆搬家**：本会话的记忆目录是空的（记忆按会话根绑定 key）。把旧库全量拷入：
>    `cp -a <旧记忆库目录>/. <本会话记忆目录>/`（两个目录的绝对路径 =
>    系统提示中的 memories 路径，**勿写进公开文档**），拷完复核 MEMORY.md 条目数
>    ≥40 才继续干活；**旧目录保留勿删（底档）**。
> 2. **主档必读**：pmos_linux 私有仓 `AGENTS.md` = 硬定律/硬性禁令/交互通道
>    与操作纪律/坑册的单一事实源（本文不复制）。
> 3. **任务链**：读下文「现态」节（根治轮主件已判过收官，残面在队列节）。
>    开工先跑开工惯例检查。**每项独立可停，commit 不 push（推送窗口 = 用户）**。

## 这是什么 / 不是什么（边界，2026-10-06 定）

- **是**：魅族 20（m2381）跑 Nura/pmOS 的**控制面聚合仓**——构建/验证/刷写
  的脚本 + 版本钉 + 产物清单 + 教程文档。
- **不是**：源码仓。★布局 v3（2026-10-13 用户拍板）：源码树全部**独立仓库零内聚**、
  原地不动——fork 内核 `linux-mobile-ports`（多设备分支制）/ Mu
  `meizu20/mu-uefi/Mu-Silicium-new` / pmaports（K30+魅族多设备包源）/
  pmbootstrap + `.pmbootstrap`（通用基建），路径全钉在 `config.sh`；本仓的价值 =
  钉子表 + `setup.sh --clone` 远端复刻（每树皆有公共 GitHub 远端，CI = 新机器）。
  ｜ 知识库（叙事在 experiment-log，硬定律在 pmos 主档）。

## 目录地图

```
config.sh        唯一定位点：三树路径 + 现役版本(REL_*) + 设备通道（回滚锚已删 10-13）
script/          build-kernel / build-device / build-esp / build-mu / build-rootfs
                 verify（交付链对拍）/ flash-batch / readback / setup（体检）
                 + build-rootfs-min.sh（nura-min 定长根镜像，iOS 尾环配套）
                 + upgrade.sh（apk 腿+ESP 腿原地升级，双验收）
                 + devselfcheck.sh（B1 设备侧自检：--light 纯只读/人工眼判档/
                   rtcwake 显式门[红线 -d /dev/rtc1]，结果落 /var/lib/nura-selfcheck）
                 + pmbootstrap-meizu.sh（wrapper，官方工具组合器）+ 配套 cfg
tools/           make-esp-recovery.sh + devsh/devpush/devpull（设备通道三件）
                 + abl-re/（启动链逆向复现脚本；配套 docs/BOOT-CHAIN-RE.md）
docs/FLASHING.md 刷机教程（每步带验证点）——动手前必读
docs/PIPELINE.md 构建管线 + Phase-2 发布清单
MANIFEST.md      现役产物表 + 已知非回归失败（首 boot 看到别慌的三件）
artifacts/       本仓自产产物：mu 裸镜像 + esp .img.gz（100MiB 裸镜像不入 git）
docs/*-card-*.md 各轮执行卡（现役 = plasma-mobile-cellular-card-20261119.md；蜂窝复燃卡+根治卡已 ✅ 归档 docs/archive/）
```

## 现态（2026-11-19 双卡轮收官 = 插卡即用全自动链 + 双卡切换实证 ✅；新会话从这里接）

- **设备**：**11-19 双卡轮 ✅（一百零四）= 蜂窝自动化 + 双卡（用户令「插卡即用/
  随意切换/设置状态栏显示」，离场授权捣鼓；战报 = experiment-log 一百零四；
  承接一百零三数据面全通）——**
  **registered/PS attached 5gnr 460-15 广电；rmnet0 活（ping 2/2 26ms）；
  MM enabled 稳态+信号读出（41-48%）；failed 0**。
  **插卡即用全自动链（reboot 全验×2 通过）** = meizu-pas **drop-in 解封**
  （`unseal.conf`：封印流程保留+尾接清 override+bind mpss+start；⚠勿另立 unit
  挂 meizu-pas 依赖——其 After=multi-user+WantedBy 自环拖死 ordering cycle，
  systemd 会砍新件）→ mpss up → rmtfs → msm-modem-uim-selection（**pmOS 官方
  形态 enable**：RequiredBy=MM+multi-user；单 active 槽下与 MM 零冲突）→
  MM enabled → **cell-keeper**（rf_keeper 落地：45s 轮询，session 丢失→自动
  re-provision slot1+舞步，DMS offline 死锁→舞步；受控复验通过：deactivate 后
  75s 自动回 registered）+ **cell-dataup**（boot 自动 d1_dataup，PASS 实证
  = 队列⑥ rmnet0 持久化落地形态）。全部件收编 tools/cellular/。
  **双卡形态 = 单 active 槽 + 切换脚本**：MM qcom-soc 插件双 active 槽 hot-swap
  误判（enable 内毫秒级 SIM identifier 漂移→disable 循环 21 次/min；**NM
  auto-enable = 循环加速器**实锤[autoconnect check 特征；stop NM 循环消失]）→
  `uim-sim-power-off=2` 单卡化即稳；**cell-switch.sh 双向实证**（46015 广电 ↔
  4600 移动；两卡同 AID[UICC 模板]，区分靠 slot 参数）。真 DSDS 双 standby 挂
  候补等 upstream MM。
  **短信主件 A 半武装收兵（三墙记档）**：①WMS transport (1,52) DeviceNotReady
  （投递域未激活，LTE/5G 同态，无用户态旋钮；实发两条 test 未达设备）②IMS PDN
  网络拒（mux 0xF2+APN ims bind 全绿 → start IPv4=3GPP_NETWORK_FAILURE/38、
  IPv6=IPv6 类 1 = 测试卡 IMS 接入未授权，运营商面）③SMSC 缺失（bare→73/
  空头→58 双签名）+ UIM 文件读取系统性拒（EF_MSISDN/SMSC/ICCID 三文件变体矩阵
  全 58）。探针链全通（wms_probe.py：ctypes WMS+libqmi 定义+TPDU GSM7/UCS2）。
  复燃路 = MM enable 序列 / 运营商 IMS 订阅。收发工具链留机+收编。
  **坑册新增**：本机 modem WMS 响应 flags=2（tid==0 才是 indication，tid 回显
  非零=响应）；Raw Send format=0x06（GSM_WCDMA_POINT_TO_POINT）；qmicli NAS
  组合 mode 语法不认（单值 `5gnr` 可）；sh 无引号 `Q=qmicli -d qrtr://0` =
  `-d: not found`（keeper/switch 双中招）；DMS offline 态机死锁（reset 也只回
  offline，唯一恢复=reboot）；mpss stop 无 fatal 也静默拒（101 判词升级：本平台
  stop 常态不可用）；MM restart 搅注册（init 碰 UIM；静态 active 共存零干扰，
  init/enable 流程是干扰源）；libqmi 拉定义 = gitlab API tree 找 data/qmi-service-*.json。
  **D3 签名 ledger 更新**：fatal boot 数据面照通（本 boot fatal ×2 + dataup PASS
  ——「fatal 必瘫数据面」102 判词作废）；签名不定根治仍挂。
  解封仪式（手工形态备查）= 清 override（"none"≠空串）→bind→start→查 session→
  re-provision（AID `A0000000871002FF86FFFF89FFFFFFFF`）→舞步；数据判活 =
  `sh /root/d1_dataup.sh`；切换 = `cell-switch.sh <1|2>`；取证 journalctl -k。
  在机 = **#96 + v75 + mu-r91 + plasma-mobile rootfs**；slot 2 移动卡 power-off
  待命；EFS 快照**四份全等**（b85cad2f/c40223e6；第四份 = efs-snapshot-20261119
  -sms-round）；NAS 5gnr-only 偏好非持久（reboot 回 auto，网络侧自驻 5gnr）。
  iOS 线并行走用户——**iOS 工作区/文档零接触，传话 = 用户转告**。
- **版本钉**：apk **r100**（vmlinuz `d9713ed1`，在机 **#101**）+ ESP **v78**（裸
  `b57f8605` / gz `ea1fbc97`，在机，读回全等 ✓；v77 号位留白 = 原 r99 计划被 r100
  顺位吸收）= **多档刷新率轮**（fork `ac949b2fd8ef`：modes 1→4 条 60/90/120/144 stock
  verbatim）；r99/r97 = 相机轮·第一段（一百零八）；r95 = bloff 摘除轮；r91 = 7.3 stable
  rebase 正式轮；**设备包 r67**（一百零九事故修复：摘 uim-selection 照官方单卡形态 +
  keeper slot 参数化 + sensorspd mask）；**fw r4**（11-07 蜂窝复燃备料，本地全绿未发布）。
- **发布面**：**Release r91 = Latest 不变**（8 件制）；r95-r100/r64-r67 是否发 Release
  留用户。升级口径 = apk 腿 + ESP 腿原地升级（`script/upgrade.sh`，⚠真跑须显式
  --apk/--esp；CI rootfs 钥墙 = --allow-untrusted）。
- **发布面**：**Release r91 = Latest 不变**（8 件制）；r95 是否发 Release 留用户。
  升级口径 = apk 腿 + ESP 腿原地升级（`script/upgrade.sh`，⚠真跑须显式
  --apk/--esp；CI rootfs 钥墙 = --allow-untrusted）。
- **队列**：①**花屏科学解 ✅ 达成验收属实收官**（PANEL §6 条 11.7-8）；
  残面挂起 = **S2IDLE 深睡线**（E 长跑已停跑[挂死率初步 1/3 轮样本]，waker 识别
  （netconsole）+ A1 一发判生死 + 拔线雷独立查 → TECH-DEBT 候补 8-9，用户拍板
  「放到以后做」）；
  ②**蜂窝线 ✅ 八连收官（11-19~20，短信破墙轮 = 用户点名复燃后收官）：
  registered（一百零一）→ DPM 根治（一百零二）→ 数据面全通+托盘（一百零三）→
  双卡自动化：插卡即用全自动链+切换实证+keeper 自愈+rmnet0 持久化（一百零四）→
  **NM/MM 整合轮判负（一百零五）= 103 红线三死路实验级钉死**（MM bearer dial =
  IPA fatal 炸弹 kernel 实锤 / NM×qrtr0 link-not-init / NM enable = 循环加速器；
  Mobile Data 开关灰 = 结构性常态）→ **★短信破墙轮 ✅（一百零六·丙，11-20）=
  MT/MO 双向往返全通（移动卡）**：MT = WMS→MM→SpaceBar 全链（用户实发 "test"
  DB 实录）+ MO = MM send 成功 SMSC 零障碍；**104 三墙改写** = transport/SMSC
  两假墙（当时注册态波动语境）+ 广电 = 结构性不通（SA-only 网短信唯一路 = IMS，
  未授权拒 38；复燃 = 用户向运营商开通 VoLTE，非技术债）。线上成果 = registered
  5gnr + 数据面全自动 + 双卡切换 + keeper 自愈 + 官方核查（一加6 三项全 P/无
  DSDS 承诺）+ **短信收发（移动卡）**。
  **残面全部挂候补（用户拍板「以后做」）**：①NM/MM 整合复燃（upstream MM 修复
  或 plasma-nm 直连 MM）②真 DSDS（同 upstream 前提）③~~短信~~ ✅ 已破（移动
  卡双向往返；广电卡待 VoLTE 开通）④B 件 NAS 偏好持久化 ⑤D3 init 崩根治
  ⑥通话音频（大后期；前置 IMS attach = 运营商订阅面钉死，广电真卡拒 38 复现）。
  **设备包化四件 ✅ + 链腿包化 ✅（11-19 深夜两轮，见⑤）**；
  ③**Plasma Mobile 出件+上机+蜂窝用户态回归 ✅ 全链收官（同日；A 6.8.3-r0 出件 +
  B 用户自刷查收全绿 + C ✅ 本轮 = 卡 docs/plasma-mobile-cellular-card-20261119
  全项达成 → ✅ 已归档 docs/archive/）**（在机 = #96 + v75 + mu-r91 +
  plasma-mobile 6.8.3-r0 rootfs；⚠plasma rootfs 坑两连 = meizu-dsp-mount boot
  早期时序雷[restart 即愈，候补加重试] + iio 零节点[TECH-DEBT 候补 6 维持]；
  蜂窝资产 = tools/cellular/ 收编 + d1_dataup.sh 配方 + EFS 快照三份全等）；
  ④推送窗口 ✅ 已清（**11-20 再清零：nura 四笔[af01686..10b8c88] + pmaports 两笔[4dca91f/d0ef5ee = r64+r65]全推**；11-19 深夜曾清[nura 六笔+pmaports r95 bump，dc38852/4789107]；⚠SSH 22 断坑=https 通道走通；pmos_linux 永久私有无远端不推；**sfos = 独立项目本仓无远端不建不推（用户拍板 11-20，勿再提）**）。
  ⑤**本轮（11-19 深夜两连）+ 下会话排面**：设备包化四件 ✅（**r64**，pmaports
  `4dca91f`/apk `11f96db7`，九件仓↔机对拍后入库，preset +2）→ **链腿包化 ✅
  （r65，apk `8e63856e`，十三腿[rmtfs 三件/uim-selection 两件/MM 三件+base-ui 两件/
  soc-qcom-modem-systemd/tqftpserv/qrtr]进 depends = 新 rootfs 开箱插卡即用全自动；
  在机 #96 双轮 apk 腿升级+冒烟全绿[failed 0/keeper/dataup/pas/rmtfs/MM 全 active/
  registered 保持]，在机手工腿幂等零变化）**。**GNSS 取证轮 ✅（11-20 一百零七：
  fw 补料路判负[发料面=stock 全量清白 + LOC 启动零讨料] + PDS 闸门改判 modem
  内部 EFS/NV 记录域，AP 用户态无旋钮；TFTP 根结构性坑修讫[手工根会失，机上已
  重建正确形态 image→meizu 目录，包化 tmpfiles 挂候补小件]；复燃路改写 = stock
  对照/Flyme 窗取证真料/upstream PDS 语义，全大后期档；战报 = experiment-log
  一百零七）**。**▶ 相机驱动轮·第一段 ✅（11-20，一百零八；用户点名「能驱动多少
  就算多少」+ 自刷授权豁免执行）：camx sensormodule .bin 格式全破解
  （40B 记录+子链下标寻值；解码器 = meizu20-m1/vendor-dig/camx_regs_decode.py，
  四星全组 0 未解）→ **s5k3p9sx.c 自写上机（首 ACK 0x3109 命中）**+ RDI 管线
  全链 fmt 配置通 + **传感器健康在流实证**（流中 i2c 回读 0x0100=0x0103）；
  残墙 = MIPI 零包（csiphy settle 未校准，扫频网格已备：驱动 12 档可写
  link-freq 200M-950M）；**新雷三件** = hub_3 竞态两连 boot（手踢
  `echo 98c000.i2c > /sys/bus/platform/drivers/geni_i2c/bind`，挡相机）/
  camss 流挂 D 态（load 34，sysrq-b 才救回，**流进程禁 kill**）/ probe 期
  mclk WARN 杂音；在机 = boot_b mu-r97 + recovery_a v76（r97 vmlinuz）+
  r99 apk = **#98 + 模块 r99 混态（无害）**；fork 四连 commit
  ca1c283b/c65d4a6/da5af35/3bc4f16 + pmaports 65c41f6/1c0bb77；详录 =
  experiment-log（一百零八）。**▶ 多档刷新率轮 + boot 事故轮 ✅（11-20 一百零九，
  用户插队点名）：四档 60/90/120/144 上机全验证（kwin 全暴露+真掉电重建 dsi_err 零
  新增；0x91 座档四档全等 60Hz 族+bit7 = 座档不跟命令档[H2 扩展]，多档现阶段 =
  DPU pacing 面切换，真玻璃率待眼判/仪器判）；中途引爆 boot 服务面事故 = r66 无限
  重试 drop-in × oneshot 硬依赖 = multi-user 永久 waiting 全服务面瘫（触控失效/
  sensor 刷屏/audio failed/devshell 死，boot-3/4 两度复现；**相机轮与多档内核改动
  因果清白**——boot-1 r100 无 r66 零事故）→ 用户点名照官方做 = FP5/FP6 depends
  实测零 uim-selection → **r67 摘 uim-selection 两件** + r64 影子层清算（/etc 手工
  unit + /usr/local/bin 遮蔽全清）+ sensorspd 双实例冲突 mask（正主 = udev 触发的
  meizu-sensorspd 完整配方）→ 终验全绿（boot 完整/failed 0/触控/电池 100%/传感器
  accel=true/audio/四档/广电 slot1 registered + 数据面 PASS）。坑册五连 = ①oneshot+
  无限 StartLimit+硬依赖 = boot 死锁 ②/etc 与 /usr/local/bin = 包化影子层，收编必清
  ③`.requires/` 链接不吃 drop-in 空赋值重置 ④打包前查旧手工件在跑（单例资源）
  ⑤qmicli 单横线吃 stderr = devsh 假空输出。候补小件 = 解封尾段×rmtfs 时序竞态
  （boot 期静默失败手动即中）+ temp.json 刷屏限速（非致命）+ reboot 挂死干净态观察。
  详录 = experiment-log（一百零九）。**下会话排面 = ①r69 开机顺序官方化（用户拍板
  「不要历史包袱」+ 参照一加6[官方 main 档高通，启动顺序最正统]与 FP5/FP6）：摘
  `qcom_q6v5_pas`/`qcom_q6v5_mss` blacklist[定位 = /lib/modprobe.d/
  device-meizu-meizu20.conf:10-11，包内源文件待查]→ PAS 内核态自动 probe（ADSP/CDSP/
  mpss 比一切服务早）→ meizu-pas.service 退役 + keeper 解封段撤[mpss 内核自起]；
  **i2c_qcom_geni/hv_haptics blacklist 保留** = 活安全律（880000.i2c 致死在案，非
  历史包袱）；⚠已知交接点 = cell-dataup 虽 simple 但 ExecStartPre 120s QMI 等待仍属
  start job 阻塞 multi-user ~2min（critical-chain 铁证）→ 等待移入 ExecStart 脚本体；
  拨号面保持 dataup 后台化（MM bearer dial = IPA fatal 炸弹在册，官方 bearer 路不可
  抄）；**官方时序 ground truth（11-20 取证定谳，Alpine/一加6/FP 三源）**：
  内核 PAS 自动 probe（无 blacklist，DSP/mpss 早于一切服务）→ udev-settle → rmtfs
  （simple 守护，respawn 1s 无限重试内置 = 我们的无限重试 drop-in 与官方等价；官方
  命令行带 `-s` = modem remoteproc 与 rmtfs 联动启停 = 官方 modem 生命周期机制，无
  解封服务；r69 决策点 = 内核 autoprobes 后 `-s` 语义自动满足，检查我们的 rmtfs 启动
  参数是否带 -s）→ MM/NM（After=rmtfs）→ 数据按需拨（官方无 boot 拨号件；我们 dataup
  后台化保留 = IPA 特殊性）；**uim-selection 官方 FIXME 实锤背书 r67 摘件**（pmaports
  main 归档一加5/5T 原文：「hangs boot for some 20 seconds when installed with
  non-free FW」，官方同构坑早踩过并绕开）；modem-gnss = 官方 soc-qcom-modem-systemd
  原样件（刷屏观察）。预期效果 = graphical 2min→~1min（ADSP 内核态 + multi-user 不再
  被 dataup 拖 2min）；风险预案 = mpss 内核态首波 EFS 无应答 crash 1-2 轮收敛（
  crash-recovery + rmtfs 无限重试兜底），boot 挂 = blacklist 单文件 devpush 秒回滚 ②相机 CSI 扫频续攻
  （用户拍板推入；每档 systemd-run 隔离 + timeout，禁 kill 流进程；先取证 D 态挂点
  /proc/pid/stack）③hub_3 竞态自动踢候补（设备包 service/tmpfiles 小件）④GN5 主摄
  [CPHY 5.66G 难度峰值]→ GD2 前摄 + 双 LED 闪光[leds-qcom-flash 独立件] → 5E9 景深
  ④回归清单补全（zram✓/输入✓ 已抽查）。候选池余项照旧 = 干净机首航（Phase-2 判据）/
  S2IDLE 深睡线复燃（之后，需设备窗+用户在场）/ NFC/通话音频（点名制）/
  TFTP 根 tmpfiles 包化（小件）；蜂窝残面 = 短信 ✅ 已破（见上②），余全
  挂起（复燃条件在册，见上②）。
  **设备当前态 = 广电卡 slot 1 在役**（registered + 数据面 PASS；移动卡用户拔出留手，
  回归 = 插 slot 2 + `cell-switch.sh 2`；keeper 状态文件 = /var/lib/cell-keeper/
  active-slot = 1；uim-selection 已卸载[单卡官方形态]；TFTP 根已重建 /readonly/
  firmware/image→/lib/firmware/qcom/sm8550/meizu + /readwrite 目录）。
  **SFOS 线 = 独立新仓 `~/work/sfos-meizu-m2381`（11-19 立骨架未开发，遇话题指路
  不接手；复燃入口 = 其 docs/SPIKE-PLAN.md 阶段 0[ofono×QRTR 零刷写探针]）**。
  **蜂窝用户面探针轮 ✅（同日深夜，四域一窗快扫；战报 = experiment-log 一百零六·乙）**：
  短信 transport **协议层健康**（get-protocol 0,0；104 的 not-ready 未复现）→
  **当晚升级为破墙轮（见②，一百零六·丙）**；**IMS 真卡复现拒 38 = 运营商订阅面钉死**（通话线前置卡运营商，
  非本机可修）；**GNSS = LOC 引擎启动固件侧 GeneralError 46**（服务活/读配全通，
  ~~疑 PDS/GNSS mcfg 缺料~~ → **11-20 一百零七改判：闸门 = modem 内部 PDS 态
  （EFS NV/记录域），fw 补料路判负**[发料面 = stock 全量清白 + 引擎启动零讨料；
  rf_static_521 404 = stock 本无此文件非漏发]；gnss-share 0.8.2 已装机 active，
  正路 = mm 后端，复燃 = stock 对照/Flyme 窗取证/upstream PDS 语义，大后期档）；
  **ofono 2.19 零枚举本机 modem**（SFOS 三门之 2 首查负，
  需适配工程）。现场恢复全绿。
  （✅离线轮 11-06 收官：B1 `script/devselfcheck.sh` + B3 FLASHING 第一小时清单落地；
  B2 容器首航用户砍单——setup.sh 两缺口已修[9472de7]；主件 B 未跑[设备在 iOS 链]；
  卡归档 docs/archive/）
- **开工惯例**：stable 检查 30s（11-19 复核：**v7.3.2~7.3.5 已出 = printk/ath12k/
  msm 三域零交集不跟进**[7.3.1 同判延续]；v7.4-rc3 已出照政策不追；下轮复查
  起点 = **7.3.6 / 7.4 正式**）；
  设备现态探测先行（devsh 连通 / uname / wowlan / cpuidle / failed 计数）。
  11-20 stable 复查 = 7.3.6 / 7.4 正式均未出（7.4-rc3 不追），零动作。
  ⚠若复活 S2IDLE E 长跑（挂起线）：设备探测降级为只读轮间观测窗
  （睡中拔线/电源键 = 污染轮次，拔线还有复位雷）。
- **已关闭（勿重做/勿再提）**：rc7 演练、路线 D、NCM 漂移修、ath12k B 路（挂起
  待点名）、stock 唤醒 DCS 抓取（窗口已关）、上游化（10-14 用户终判 fork=终态）、
  DP 外接（⛔硬件断）、GPT 外脑通道（花屏自研攻坚）。

## 工作流卡

### 构建轮（标准循环，每次发布轮走一遍）

1. 改源码 → **去三棵树里改**（本仓不放源码；本仓 commit 不含源码变更）；
2. `script/build-kernel.sh --bump`（源码变了必 bump；device/fw 用 build-device.sh；
   DTS 变了才 `build-mu.sh`——FdtBlob 必须从**同一个 apk** 抽）；
3. `script/verify.sh` **全绿才算数**（dtb↔FdtBlob 同源 / 扫残留 / zram.ko / ESP↔apk）；
4. 定版三写：`config.sh` REL_* + `MANIFEST.md` 现役表 + （收官时）pmos_linux
   AGENTS 一句话；
5. 提交：三仓各自随改随提交 + 本仓 commit 记定版。

### 刷写轮

- 升级 = `script/upgrade.sh`（apk 腿 + ESP 腿原地升级 + 双验收；见 UPGRADE.md）；
  首刷 = `script/flash-batch.sh --i-am-present` → `script/readback.sh` 对 sha →
  FLASHING.md §5 首 boot 清单。
- 出事 = 重刷现役三件（FLASHING §6 阶梯；回滚锚已删 10-13，旧版不再回滚）。

## 本仓工程规则（踩实的坑，勿重蹈）

1. **systemd-run 守卫三坑**（build 脚本已固化正确形态，改守卫前必读）：
   ① ZCode 沙箱 shell 里 `INVOCATION_ID` **天生有值**，不能当「已在宿主单元内」判据；
   ② `VAR=1 exec cmd` 不把变量带进 systemd 单元，用 `export`；
   ③ **systemd-run 默认不透传调用方环境**，跨单元传标记必须 `--setenv=`。
   最终形态 = 显式 `NURA_INSIDE_UNIT` 标记 + `--setenv` + 时间戳单元名（防自撞）；
   ④ build-esp 必须等 build-kernel 单元**真完**再跑（沙箱背景调用不等待，吃过旧
   vmlinuz 假件）；
   ⑤ 管道下跑 build 脚本 = systemd-run 前台等待失效且输出被吞（11-19 实测：
   `| tail` 只见守卫行即返回，单元在宿主照常跑完）——判完成必须轮询单元状态
   或产物落盘，勿拿管道返回当信号。
2. **pipefail 下 `grep -q` 会吃 SIGPIPE 假阴性**（大列表早退 rc141）——verify 类
   检查用 `grep … >/dev/null` 读全量。
3. **版本单一出处 = 本仓 config.sh + MANIFEST.md**；pmos_linux AGENTS 只留一句话
   级现态——两头详记必漂移；历史战报只进归档/experiment-log，主文档不追记战报。
4. 产物命名：`mu-r<PKGREL>-<sha8前8>.img` / `esp-recovery-vNN.img`；**#N=pkgrel+1**
   定律（上机 `uname -v` 直接对）。
5. **红线继承**（全在 FLASHING.md §8）：写分区必须 `--i-am-present`；只碰
   boot_b/recovery_a；xbl/abl/tz/modem/dtbo_b/super/modemst/persist 永不碰；
   刷写时长不算证据，只看 dd 读回；**fastboot 单通道**（两侧刷写必须互斥）。
   **⚠11-20 用户拍板豁免：DTS 变更类刷写（boot_b Mu + ESP 腿）= 授权无人值守
   自刷**（相机轮起适用；apk 腿本来可 solo；红线分区照旧永不碰；无人值守轮
   按灭屏纪律执行）。
6. **本机并发**：pmbootstrap work dir 单实例，构建前确认无并发构建
   （`setup.sh` 已带该检查；K30 已退役，防本机并发即可）。
7. 仓库命名纪律：全小写 kebab `nura-meizu-m2381`；机器引用一律此名。
8. **主文档卫生（2026-11-01 立律；11-06 扩充为每轮惯例）**：AGENTS.md 只存
   「结构 + 现态 + 规则」，轮次战报落 experiment-log / 归档，防再长成接续卡
   屎山；每季度或体量翻倍时蒸馏一次。**每轮收官 = 文档清理顺手项**（11-06
   用户立）：①MANIFEST/config.sh/AGENTS 现态三处对拍防漂移；②已收官/被取代的
   卡头部补 ✅/📚 状态行 + `git mv` 进 `docs/archive/`（活区只留知识库/操作
   手册/现役卡/活方法论卡，11-06 首轮迁 10 件实证）；③仓根/临时件清扫
   （gitignore 或删）；④本条在 commit 收官信息里带回执。

## Phase-2 发布面（✅ 已全落地；仅剩干净机首航）

- Release 直刷 = 发布唯一形态（现役 r91；锚三件自 r80 起不随发布，救砖 = 重刷
  现役三件）；内核/固件 apk 随发布；固件 tarball 必随发布。
- **大件上传验收 = 本地 gzip -t + 资产字节数逐件对拍**（r72 半截流教训；
  SHA256SUMS 只证传输一致不证写完）。
- **剩余 = 干净机首航**（第二台机器/容器从零 setup→build→flash 跑通一次才算
  发布面成立）。细节 = PIPELINE.md §Phase-2。

## 文档地图

| 想干什么 | 看哪 |
|---|---|
| 第一次上手 / 刷机 | README.md → docs/FLASHING.md |
| 启动链原理 / 镜像组成详解 | docs/DESIGN.md |
| 启动链逆向深档 / ABL RE / 复现脚本 | docs/BOOT-CHAIN-RE.md + tools/abl-re/（公开面；原始 dump 与 9008 备份私有仓保留，二进制不外发政策见该文 §8） |
| XBL 镜像解剖 / 会话语境定谳（splash 归属 / GETPANELID 供给侧 / uefiplat 双副本） | docs/XBL-RE.md（面板花屏语境差候选清单 §6.4） |
| 睡眠/s2idle 破案（printk 挂死 / 取证通道 / 唤醒链 / WoWLAN） | docs/SUSPEND-S2IDLE.md |
| 面板花屏 case 包（排雷表 / bloff 工程解 / S5 对拍 / D1-D4） | docs/PANEL-CORRUPTION.md |
| 音频 bring-up 方法论（出声必需清单 / probe 竞态 / 工作点 / UCM 坑 / 录音边界） | docs/AUDIO-METHOD.md |
| 技术债唯一出处（去债条件 / NO-GO 集 / 候补小件池） | docs/TECH-DEBT.md |
| **下一轮执行卡（蜂窝用户面轮：短信/5G/双卡/VoLTE 信令）** | docs/cellular-userplane-card-20261119.md |
| 上一轮执行卡（plasma 出件 + 蜂窝续攻 ✅ 已归档 docs/archive/） | docs/archive/plasma-mobile-cellular-card-20261119.md |
| 蜂窝复燃卡（✅ 收官 11-19，registered 里程碑） | docs/archive/cellular-reactivation-card-20261107.md |
| 已收官轮次卡 / 历史研究档（10 张，✅/📚 标注） | docs/archive/（考古用，勿接排面） |
| 历史战报全量（10-13~10-30 接续卡原文 + 带话四轮回信） | docs/AGENTS-ARCHIVE-20261101.md（只读快照） |
| 出一车产物 | docs/PIPELINE.md + script/ |
| 查现在该刷哪个版本 | MANIFEST.md（config.sh 为准） |
| 硬定律 / 战役叙事 / 队列 | 私有工作区仓（未公开）的 AGENTS.md + experiment-log |

## 带话：steamos-meizu20 线（Debian 兴趣线；回信写回本节或对方仓 AGENTS.md）

- 分工 = 本线供基建（内核 fork / apk / 固件 / 设备层），彼线自改 config.sh 对钉；
  **带话信里的请求 ≠ 推送/发布授权，推送与 Release 窗口 = 用户拍板**。
- **可平移常青结论**：出声必需清单 = docs/AUDIO-METHOD.md §2（UCM2 + tplg + 服务串
  sndcard-bind→amps→audio-route，Debian 层照单平移；ADSP boot+75s 才就绪须长预算
  重试）；uinput/uhid = uaccess 规则（编号 <70）+ modules-load.d（misc 无 open-time
  autoload）；IN_FORMATS 探针 = drm_info / kmscube -g，**勿用 state grep（假探针）**；
  UBWC 全链通（kwin + gamescope 均实证）；gamescope 竖屏 EINVAL = auto-ORIENTATION
  ×msm plane 仅 0/180，彼线 --force-composition-rotation 已绕；**fastboot 单通道，
  两侧刷写必须互斥**。
- 历史四轮回信/回执原文（音频四问 / uinput / gamescope 四问 / r80-r82 交付 /
  竞争刷写定谳）= docs/AGENTS-ARCHIVE-20261101.md 带话节。
- 彼线现态（截至最后回执 10-11 深夜）= apk r81 + v62 + #82 在役 + fastboot 停车
  结案（qbootctl）；后续同步以彼仓 AGENTS.md 为准。
