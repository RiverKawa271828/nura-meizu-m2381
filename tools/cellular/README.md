# tools/cellular — 蜂窝用户态件（设备侧收编镜像）

刷 userdata 前从设备 `/root` 与 `/etc` 回收的蜂窝件（2026-11-19 D1 轮收官，
C1 重装配方 = 卡 docs/plasma-mobile-cellular-card-20261119.md §3）。目录结构
= 设备侧原路径（`root/` → `/root`，`etc/` → `/etc`）。

**2026-11-19 双卡轮（一百零四）新增（根目录平铺件）**：

| 件 | 设备路径 | 说明 |
|---|---|---|
| wms_probe.py | /root/ | QMI WMS ctypes 短信探针（info/listen/send/read；TPDU GSM7+UCS2 编解码；⚠本机 modem 响应 flags=2 的怪癖已内建适配） |
| uim_read.py | /root/ | UIM Read Transparent ctypes（本机全拒 58，留作判别工具） |
| ims_dial.py | /root/ | IMS PDN 拨号（mux 0xF2 + APN ims；本机网络拒 38，留档） |
| cell-keeper.sh | /usr/libexec/ | **注册面自愈守卫（rf_keeper 落地）**：45s 轮询，session 丢失→自动 re-provision+舞步，DMS offline 死锁→舞步；受控复验通过。⚠`Q="qmicli -d qrtr://0"` 引号必须带（无引号 = sh 把 -d 当命令） |
| cell-switch.sh | /usr/local/bin/ | **双卡切换**：`cell-switch.sh <1\|2>` = 另槽 power off → 目标槽 power on → provision → 舞步 → MM rescan；双向实证 46015(广电)↔4600(移动) |
| units/cell-keeper.service | /etc/systemd/system/ | keeper unit（After=rmtfs；⚠勿依赖 meizu-pas——其 After=multi-user 自环会拖死 ordering cycle） |
| units/cell-dataup.service | /etc/systemd/system/ | 开机数据面 oneshot（等 QMI→d1_dataup；boot 自动 PASS 实证） |
| units/meizu-pas-unseal.conf | /etc/systemd/system/meizu-pas.service.d/ | **解封自动化 drop-in**（封印流程原样保留，尾接清 override+bind mpss+start；boot 后三 remoteproc running 实证）|

插卡即用链（reboot 全验通过）：meizu-pas(drop-in 解封) → mpss up → rmtfs → msm-modem-uim-selection(选槽) → MM(enabled) → cell-keeper(session 兜底) + cell-dataup(数据面)。

**2026-11-19 深夜设备包化（device r64，pmaports `4dca91f`）**：上述四件 + 两伴生件
（rmtfs 无限重试 drop-in / NM qrtr unmanaged）已收编 device-meizu-meizu20 包——
新路径 = `/usr/lib/meizu20/{cell-keeper.sh,d1_dataup.sh,d1_bindmux.py}` +
`/usr/bin/cell-switch.sh` + `/usr/lib/systemd/system/{cell-keeper,cell-dataup}.service`
+ 两 drop-in/conf；preset 新装机自动 enable，现网升级零行为变化（机上手工件同内容，
九件 sha256 对拍等价）。⚠链腿 apk（rmtfs 三件/uim-selection 两件/MM 底座等）仍为
手工腿，全链自动待拍板。本目录保留 = 收编镜像（包版路径适配 diff 见 pmaports r64）。

**2026-11-22 数据面自动化固化（device r75，pmaports `c5275e8`；一百二十终验正解收编）**：
**d1_dataup/d1_bindmux/cell-dataup 判负退役**（手工 DPM 链 modem 侧 IPA 通道语义缺，
dial 通 RX 秒死两 boot 复现；下方「一键判生死」与「三定律」= 历史档案，rmnet0 链已死）。
**正解 = mm-dial（MM 拨号形态）**：`/usr/lib/meizu20/mm-dial.sh` + mm-dial.service
（boot 自动：MM failed 死锁 restart 重扫 → simple-connect apn=cbnet → MM 自建
qmapmux0.0@rmnet_ipa0 → bearer 活体取 IP/gw/DNS → metric 700 WiFi 优先铺配置 +
resolvectl DNS → `-I qmapmux0.0` 硬判；硬败 = FAIL 撤路由诚实退出，无卡 boot =
预期 failed 无害；复活 = 插卡后 `systemctl restart mm-dial`）。keeper 数据面看门
同轮适配 qmapmux 形态；cell-switch 尾接 mm-dial 自动重拨（数据面跟卡走）；NM
unmanaged 加 qmapmux*（防半接管）。镜像纪律：cell-keeper.sh / cell-switch.sh /
mm-dial.sh / units/{cell-keeper,mm-dial}.service 与包内件逐字对等（ retired 件镜像
已删，历史 = git 史）。

双卡形态 = **单 active 槽 + 切换脚本**（非 DSDS 双 standby）：MM qcom-soc 插件在双
active 槽下 SIM identifier 漂移 → enable 后毫秒级 disable 循环（NM auto-enable 加速）；
slot 2 power-off 单卡化后稳。真 DSDS 挂候补等 upstream MM。

## 出处

| 件 | 出处 | 设备路径 |
|---|---|---|
| bind_all.py | 白嫖 leluo123/m2468-mainline（21 Note）userspace | /root/bind_all.py |
| data_daemon.py | 同上（WDS 拨号常驻客户端） | /root/data_daemon.py |
| modem_daemon.py | 同上 | /root/modem_daemon.py |
| mux_matrix.py | 同上（WDS mux 扫描） | /root/mux_matrix.py |
| scan_mux.py | 我方自制（mux 扫描变体） | /root/scan_mux.py |
| d1_bindmux.py | 我方 11-19 D1 轮探针（一百零二） | /root/d1_bindmux.py |
| 10-unlimited-retry.conf | rmtfs 无限重试 drop-in（StartLimitIntervalSec=0） | /etc/systemd/system/rmtfs.service.d/ |
| 00-nura-qrtr-unmanaged.conf | NM unmanaged qrtr0+rmnet_ipa0 | /etc/NetworkManager/conf.d/ |

## d1_bindmux.py 使用前提（D1 判生死探针）

先发 DPM Open Port（数据口语境，缺位 = mux bind 全域拒，一百零二判词）：

```
qmicli -d qrtr://0 --dpm-open-port="hw-data-ep-type=embedded,hw-data-ep-iface-number=1,hw-data-rx-id=2,hw-data-tx-id=24"
```

（endpoint 2/24 = SM8550 IPA v5.5 AP_MODEM_TX/RX 真值，不可平移他 SoC。）

**一键判生死（2026-11-19 C 轮固化的现役配方）**：`sh /root/d1_dataup.sh [目标 IP]`
= DPM open → dial → rmnet0(QMAP mux 1) → bounce+ping 收敛环 → PASS/FAIL。
（一次性手动版：`python3 /root/d1_bindmux.py` 后 `ip addr add <ip>/32 dev rmnet0`
等价展开见脚本头注释。）

## 数据面打通三定律（一百零三，勿重蹈）

1. **rmnet0 上层件是必需品**：主线 `ipa_data-v5.5.c` AP_MODEM_TX 端点 `.qmap=true`
   ——裸 IP 包撞 `ipa_start_xmit` 静默丢弃分支（TX dropped 涨 / RX 0 / 零 error）。
   `ip link add link rmnet_ipa0 name rmnet0 type rmnet mux_id 1`（CONFIG_RMNET=m
   自动装载；mux_id 1 = bind mux 0xF1 的 id）后裸 IP 走 rmnet0 即出。
2. **RX buffer 靠 bounce 重铺**：SSR（甚至 dial/DPM reopen）后回程死（rmnet0 RX=0）
   ——`rmnet_ipa0` down/up 重铺 RX buffer 即活（PDP 不受影响）；但落定窗不定
   （dial 后 25s 可能不够）→ 收敛环硬兜（脚本内置 ≤3 轮）。
3. **wire 真值自检**：python AF_PACKET 抓 rmnet_ipa0，出向帧应见 MAPv1 头
   `0001`（mux id 1）+ IP 载荷；RX=0 且出向帧健康 = 回程死 = bounce 判活域。

## 关联

- 装包腿钉版件（rmtfs 三件/uim-selection 两件/MM 底座/soc-qcom-modem-systemd +
  tqftpserv + qrtr/qmi-utils）——**r65 起已全部烤进 device 包 depends**（2026-11-19
  深夜链腿包化收口），新 rootfs 开箱即全链；qmi-utils 亦 r64 进 depends。
  ⚠apk3 + devsh 会话 arg-less `apk info` 挂死占锁（须 `</dev/null` 或清锁尸）。
- 解封仪式 / provisioning session / DMS 舞步配方 = pmos_linux
  docs/meizu20/experiment-log（一百零一/一百零二/一百零三）。
- EFS 快照 = pmos_linux/efs-snapshot-20261119{,-plasma-reflash,-c3-unseal}/（sha 双侧对拍；
  11-19 三份全等 = 蜂窝战役零 EFS 写入实证）。
