# nura-min 定长根镜像(iOS userdata 尾部日志通道配套)

> 2026-10-21 落地。需求方 = iOS-on-魅族20 线(急件取证配合);nura 侧受益 =
> 自家观测/救砖通道复用。**本镜像非发布面**,私有特殊用途,几乎不维护不更新。

## 一句话

iOS 内核把控制台日志环写在 userdata 分区**最尾部**(末 4MiB+4KiB,`SWEETLOG`
头)。旧 nura 根每次恢复都全分区写(mkfs 元数据横扫)必毁尾部;改用**定长镜像**
后 iOS ↔ nura 随便轮回,尾部原样保留——nura 里一条 `dd` 就能取回 iOS 崩溃日志。

## 硬规格(与 iOS 侧对齐的成败线)

| 项 | 值 |
|---|---|
| 形态 | 固定尺寸 raw ext4 根镜像文件(非分区镜像、非 tar) |
| 尺寸 | 默认 2G 定长(≤4GiB 硬上限;刷得快) |
| 尾部红线 | 镜像尾 ≤ 分区尾 − 8GiB(2G 天然满足;写出来防将来做大) |
| root | `/dev/sda22`(内核 cmdline 烤定,Mu 链无 initrd) |
| 启动链 | mu-r69 / ESP v71 / 内核位置 **零改动**(本镜像只换 userdata 内容) |
| 内核模块 | `/lib/modules/7.3.0` = 在跑内核 release(在机 #92 = r91 apk) |
| 必留 | devshell `:23`(busybox nc shell)、dd/sha256sum/hexdump/base64/grep(busybox)、python3、起机到登录壳 |

**三条禁令 → 构建侧落实**(脚本 `script/build-rootfs-min.sh` 逐条断言,失败不出件):

1. **构建零全分区写**:本脚本只产独立定长文件,从不碰设备;对 userdata 的唯一
   写入 = iOS 侧 `img2simg` → `fastboot flash userdata`(sparse 只写镜像自身
   那 2GiB,物理上碰不到尾部)。
2. **零首启扩容**:真凶 = device 包 preset 自启的 `meizu-grow-rootfs.service`
   (resize2fs 打到 userdata 整分区 464G)——官方最小镜像同样带它。镜像内
   **mask**(→`/dev/null`)+ 摘 `multi-user.target.wants` 自启链接。
3. **fstab 无 resize 语义**:pmbootstrap 原生写法 = `UUID=… / ext4 defaults 0 0`,
   天然干净;断言把关(出现 growfs/resize/x-systemd 扩容 token 即 die)。

## 路线(用户拍板「官方最小,不拆来拆去」)

`pmbootstrap ui=none`(wrapper `NURA_UI=none` 临时 cfg)+ `--add` 五件:

```
python3,openssh,unudhcpd,postmarketos-usb-moded,
postmarketos-usb-moded-default-profile-developer
```

内核/设备/固件包自动取本地包仓现役(**r91 / r63 / r3**),包名版本由脚本断言
钉死。USB 网络 = usb-signaller(postmarketos-base `90-base.preset` 使能)+
`unudhcpd@usb0`(设备侧 172.16.42.1,给宿主发 DHCP);developer profile 由
`usb-signaller.toml` 启动自选——与 r87 全量镜像同款官方栈,零自写脚本。
唯二镜像内手术(均 debugfs 后处理,不改包):①mask grow 单元(见上);
②写 `/etc/nura-min` 溯源标记(版本钉 + 用途)。

## 构建 / 刷写 / 验收

```sh
bash script/build-rootfs-min.sh                # 默认 2G;NURA_MIN_SIZE=3G 可调
# 产物 artifacts/meizu20-nura-min-r<内核pkgrel>-<size>.img (+ .sha256 / .simg 若宿主有 img2simg)
```

**刷写(iOS 侧执行)**:①尾部预写标记块(环头位 + 末块)→ ②刷 iOS 根
(分区头部 16GiB sparse)→ ③`img2simg` 后 `fastboot flash userdata` nura-min
→ ④起 nura-min,`dd` 读回标记原样 = 通过。此后尾部成为永久日志通道。

**nura 侧取环**(分区 972,326,040 × 512B;末 4MiB+4KiB = 8200 扇区):

```sh
tools/devsh.py 'dd if=/dev/sda22 bs=512 skip=$((972326040-8200)) count=8200 | sha256sum'
tools/devpull.py ring.bin   # 设备侧 nc 172.16.42.2 <port> < 文件 推回
```

登录:`tools/devsh.py '<cmd>'`(busybox nc :23,root 直达,零 ssh 依赖);
面板 tty1 getty `user/1234`;openssh 备腿(sshd 随包)。

## 分区几何核对(userdata = /dev/sda22)

```text
0 ──────── 16GiB ──────────── 2GiB(nura-min 终点)                    ~463.8GiB − 4MiB − 4KiB ─── 463.8GiB
│ iOS 根(sparse,头部) │  nura-min 定长镜像(0..2GiB)  │      ……空……      │ iOS SWEETLOG 日志环(4MiB+4KiB) │
```

镜像内任何 fs 活动(含 journald/tmp)都物理圈在 0..2GiB;`fstrim` 范围同样
限于 fs 内;grow 单元已 mask——**尾部对 nura 侧是只读事实**。

## 已知边界

- 无 GUI/无桌面:无 NetworkManager(WiFi 未配置,不影响 USB 通道);sensors/
  audio 的 device 包单元照常随 preset 跑,失败与否均无害(特种镜像不判 failed)。
- journald 易失(无持久目录),rootfs 只读式使用;要留证据先 devpull 出来。
- 该镜像**不进 Release 不进 verify 链**,版本钉只随内核/设备包现役走;重建 =
  重跑本脚本(包缓存热,~10-20 分钟)。
