# UPGRADE — 原地升级（不刷 userdata，数据全保留）

> 装机 = [FLASHING.md](FLASHING.md)（三件全刷，清数据）｜**升级 = 本文（两条腿，/home 与配置全保留）**。

## 心智模型（30 秒）

系统由四条独立腿组成，升级只动两条：

| 腿 | 内容 | 升级时 |
|---|---|---|
| **apk**（rootfs 内包） | 内核模块 + 用户态 | ✅ 装（步骤 1） |
| **recovery_a**（ESP） | 内核本体（`BOOTAA64.EFI`） | ✅ 刷（步骤 2） |
| boot_b（Mu-UEFI） | 固件 + 设备树 | ❌ 不动（仅当 Release 说明标注「Mu 更新」才刷） |
| userdata（rootfs） | 根文件系统 + /home | ❌ 永不动 |

两条腿必须来自**同一个 Release**（内核二进制与模块同 apk 出产，天然配对）；
唯一硬纪律 = **步骤 1 和 2 之间不要重启**——中断了就补完另一条腿再重启。
（镜像解剖实证：rootfs 的 fstab/cmdline/模块目录/apk world 均无版本号绑定，
`/boot` 目录是 apk 装的副本、boot 链不读它；boot_b 只含设备树内容配对，
DTS 不变的轮次跨轮通用。）

## 升级两步

前提：电脑装了 fastboot；设备能进系统。apk/ESP 从**同一个新 Release** 页下载，
传到设备的通道随意（WiFi curl、scp、nc 均可，不规定）。

> **一键脚本（宿主侧）**：上面两步可由 `script/upgrade.sh --i-am-present` 自动走完
> （默认件 = config.sh 现役钉 + 本地包仓最新三包；通道 = devsh/devpush 绑 USB 接口；
> 含设备侧 sha 对拍、软进 fastboot、只刷 recovery_a、`uname -v` 与 dd 读回双验收；
> NCM 网段重启漂移自动重探，`--host` 可指定）。`--skip-apk` / `--skip-esp` = 单腿补完
> （升级翻车补腿用）。2026-10-19 固化 = 10-14 设备日手动首验路径的脚本化；设备腿首跑
> 随下轮升级实机验证。

```bash
# ── 步骤 1：装模块腿（设备上）─────────────────
# 把 linux-meizu-meizu20-*.apk（+ 本轮 Release 列出的 device/firmware apk）传到设备后：
sudo apk add ./linux-meizu-meizu20-7.3.0_rc6-rN.apk
# 签名公钥已烤在 rootfs 里，直接验签通过；装完**先别重启**

# ── 步骤 2：刷引导腿（电脑上）─────────────────
# 解压 Release 的 esp-recovery-vN+.img.gz 得到 .img，然后：
# （设备上）软进 fastboot：
sudo systemctl reboot --reboot-argument=bootloader
# （电脑上）刷 ESP：
fastboot flash recovery_a esp-recovery-vN+.img
fastboot reboot
```

仅当本轮 Release 说明标注「**Mu 更新**」时，步骤 2 加一条：
`fastboot flash boot_b mu-rN-*.img`（可与 recovery_a 同一次 fastboot 会话里刷）。

## 验收

重启后第一件事：

```bash
uname -v        # 应显示 #N = 新内核 pkgrel + 1（如 r85 → #86）
```

对上即成。smoke：`systemctl --failed` 为 0 + 音频/触控正常。

## 回滚

升级翻车（新内核有问题）→ 下载**上一轮 Release** 的 apk + ESP，按同样两步刷回去
（顺序无关，两腿之间别重启的纪律不变）。历史 Release 全部保留在 GitHub Releases 页
（现役之外另有上一轮存档）。

最坏情况（系统都进不去）→ [FLASHING.md](FLASHING.md) §6：fastboot 三件全量重刷回家
（⚠ 清 userdata 数据，最后手段）。

## FAQ

- **「装完 apk 忘了刷 ESP 就重启了」**：重新走一遍步骤 1+2 即可（大概率还能正常进系统，
  旧内核配新模块或反之都可能半死——别慌，两腿补齐就好；进不去走回滚）。
- **「应用商店提示系统升级，版本看着还是降级」**：UI 噪音，忽略。滚动发行版没有
  distro upgrade，商店列不出也做不了（日志可证）；它显示的快照版本串（v20260805-…）
  与 `edge` 语义不同才显得像降级，apk 实测升级/降级候选均为 0。系统升级只按本文走。
- **「boot_b 到底刷不刷」**：永远以本轮 Release 说明为准。没提 = 不刷（近几轮 DTS 零改动，
  mu 镜像一直沿用，看 SHA256SUMS 里 mu 件 hash 是否变化即可）。
- **「为什么两腿要同轮」**：ESP 里的 `BOOTAA64.EFI` = 内核本体，apk 里的
  `/lib/modules/` = 模块；两者来自同一个 apk 才能互相咬合（上机验证点 `#N = pkgrel+1`，
  详见 [MANIFEST.md](MANIFEST.md) 版本号速查）。
