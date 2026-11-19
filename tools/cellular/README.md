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

然后 `python3 /root/d1_bindmux.py`：bind mux 0xF1 → bind sub → start network
（APN cbnet）→ get settings；拿到 IP 后 `ip addr add <ip>/32 dev rmnet_ipa0 &&
ip link set rmnet_ipa0 up && ip route replace default dev rmnet_ipa0 metric 50`
→ ping 判 IPA 硬件通路生死。

## 关联

- 装包腿钉版件 = 宿主 pmbootstrap cache（rmtfs 三件/uim-selection 两件/
  soc-qcom-modem-systemd + tqftpserv-1.0-r0 + qrtr/qmi-utils）——不在本目录。
- 解封仪式 / provisioning session / DMS 舞步配方 = pmos_linux
  docs/meizu20/experiment-log（一百零一/一百零二）。
- EFS 快照 = pmos_linux/efs-snapshot-20261119{,-plasma-reflash}/（sha 双侧对拍）。
