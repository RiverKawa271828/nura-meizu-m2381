# tools/cellular — 蜂窝用户态件（设备侧收编镜像）

刷 userdata 前从设备 `/root` 与 `/etc` 回收的蜂窝件（2026-11-19 D1 轮收官，
C1 重装配方 = 卡 docs/plasma-mobile-cellular-card-20261119.md §3）。目录结构
= 设备侧原路径（`root/` → `/root`，`etc/` → `/etc`）。

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

- 装包腿钉版件 = 宿主 pmbootstrap cache（rmtfs 三件/uim-selection 两件/
  soc-qcom-modem-systemd + tqftpserv-1.0-r0 + qrtr/qmi-utils）——不在本目录。
  ⚠apk3 + devsh 会话 arg-less `apk info` 挂死占锁（须 `</dev/null` 或清锁尸）。
- 解封仪式 / provisioning session / DMS 舞步配方 = pmos_linux
  docs/meizu20/experiment-log（一百零一/一百零二/一百零三）。
- EFS 快照 = pmos_linux/efs-snapshot-20261119{,-plasma-reflash,-c3-unseal}/（sha 双侧对拍；
  11-19 三份全等 = 蜂窝战役零 EFS 写入实证）。
