# nura-min 定长根镜像 · 上机验收报告(转 iOS 侧)

> 2026-10-21,nura 侧执行。结论:**nura-min 腿(③刷 nura-min → ④起 nura 读回)上机
> 验证通过,iOS 侧无需重复测试**;彼方直接部署真环即可。

## 交付物

| 件 | 值 |
|---|---|
| 镜像 | `meizu-meizu20-nura-min-r91-2G.img`,定长 **2147483648 B**(2GiB),实占 1.2G |
| sha256 | `c841f6455d02ad5d6cb8bf7b0fdda5800bd9df0aacba4bbf4de37e5ad43519df` |
| sparse 件 | 同名 `.simg`(img2simg 同源转换),sha256 `a84d921233041a9cd8c6cf95572fd92edcf9d7862689cb0f764367ae0793cd3f` |
| 内容钉 | 内核模块 7.3.0(=在跑 #92)/device r63/firmware r3/python3/openssh/NetworkManager/usb-moded(developer) |

## 系统安全件(与尾部共存直接相关)

- `meizu-grow-rootfs.service` = **masked**(首启整分区扩容器已废);自启链接同摘。
- fstab = `UUID=… / ext4 defaults 0 0`,零扩容语义。
- fs 恒 **524288 × 4KiB = 2GiB**(实测两轮重启后 Block count 不变);一切 fs 活动
  物理圈在分区 [0, 2GiB)。

## 验收过程(m2381,serial 381QYGEP222XJ,fastboot 单通道)

1. **pass1**:`fastboot flash userdata`(sparse,38s)→ 起机 **48s** 到 devsh:23;
   `uname -v` = `#92-meizu-meizu20`;usb0 = `172.16.42.1/16`(NM 配 IP + unudhcpd 发
   DHCP);grow masked / 工具七件全在 / fstab 净。
2. **写标记**(从 nura-min 内,其 fs 仅 2GiB,尾部在 fs 之外零损伤):分区尾部
   8200 扇区(= 末 4MiB+4KiB,即 iOS 环位)写整段随机 pattern + 头/末 ASCII 标记:
   - 基准 SPAN_SHA = `2b78a9f0f2da25ddd4c69c84aaf97a90fc8a9594f64bcc4bb117b95d1ff97494`
   - HEAD = `NURA-ACC-HEAD-20261021`(环头位扇区);LAST = `NURA-ACC-LAST-20261021`(末扇区)
3. **pass2**:重启落 fastboot → **重刷同一镜像** → 重启起机 → 读回:
   - SPAN_SHA 与基准**逐字节一致**;HEAD/LAST 原样;Block count 仍 524288。

## 结论

**「刷 nura-min(sparse)+ 起 nura-min」对分区尾部零扰动**——按 iOS 侧原协议,
③④两腿已上机证实,无需重测。①写环标记、②刷 iOS 根为彼方一贯流程(彼方历史
实测从未波及尾部);若要兜底,刷完 iOS 根后先 `dd` 读一次尾部确认环在,再刷
nura-min 即可(一次 dd 的事)。我方测试标记为 pattern 非 SWEETLOG 真身,彼方
部署真环时直接覆盖写。

## iOS 侧使用速查

- 通道:`devsh.py '<cmd>'`(宿主侧工具,raw nc **:23**,root 直达,非 ssh 协议);
  设备 `172.16.42.1` / 宿主 `172.16.42.2`。
- 取环:`dd if=/dev/sda22 bs=512 skip=$((972326040-8200)) count=8200`(分区
  972,326,040 × 512B;末 4MiB+4KiB = 8200 扇区)。
- python3 在;**/tmp = tmpfs**(暂存 pattern/解环文件不落分区)。
- 备腿:面板 tty1 登录 user/1234;sshd:22(同密码)。

## 边界(诚实声明)

- 本验收未含 iOS 根刷写腿(彼方工件与流程);组合逻辑 = 我方证明(min 刷写+启动
  不碰尾)+ 彼方历史证明(iOS 根 sparse 刷写不碰尾)⇒ 全轮回安全,与顺序无关。
- 任何 mkfs/全分区写仍会毁尾部——定长镜像的存在意义就是消掉 nura 侧这个变量;
  iOS 侧向 userdata 做全分区写操作时同样要避开。
- 设备现态:停在 nura-min,尾部带我方测试标记,彼方可直接在其上执行原协议。
