# 构建管线（源码 → 工具 → 镜像）

> 本仓 = 控制面（脚本+文档+钉子）；源码树原地不动，`config.sh` 是唯一升级点。

## 一张图

```
源码树（config.sh 钉住）                脚本                  产物 → 去向
──────────────────────────────────────────────────────────────────────────
linux-mobile-ports            build-kernel.sh ──→ linux apk（模块腿）──→ 机上 apk add
 (meizu20-t4b)                    │ git archive tarball
                                  │ ↓ dtb 抽取
Mu-Silicium-new               build-mu.sh ─────→ mu-rXX-YYYY.img ──→ boot_b
 (meizu20-mars-port)              │ build_uefi.py -d m2381
pmos/pmaports 三包            build-device.sh ──→ device/firmware apk ─→ 机上 apk add
mtools + tools/make-esp…      build-esp.sh ────→ esp-recovery-vNN.img.gz ─→ recovery_a
                              build-rootfs.sh ──→ meizu-meizu20.img ───→ userdata

verify.sh  ←── 每轮必跑：dtb↔FdtBlob sha 对拍 / tarball 扫残留 / zram.ko 在列 / ESP↔apk 同源
```

## 各环节细节

### 内核（build-kernel.sh）
1. `git archive` 从 fork 分支打 tarball → pmaports 包目录（gitignore 的，不入库）；
2. 改了源码必须 `--bump`（pkgrel+1；同 pkgrel 设备端拒装）；
3. `pmbootstrap checksum`（sha512sums 重算）→ `build --force`；
4. `KBUILD_BUILD_VERSION = pkgrel+1` 烤进 uname → **#N=pkgrel+1 定律**，上机第一验证点。
5. 工具链：clang/LLVM=1；pmbootstrap 经 wrapper 在宿主跑（脚本自动 systemd-run 重入）。

### Mu（build-mu.sh）
- 触发条件：**仅 DTS 变了**才需要（铁律：FV DTB = 内核唯一 DT 源）；
- FdtBlob 必须 = **同一个 apk** 里的 dtb（verify.sh 第 1 项对拍，防（四十九）事故）；
- 构建后 Source.txt 更新 + Mu 树 git commit（交付链纪律）；
- BootShim 改动守硬定律 #2（字面量池↔_Payload 相对位置，新增代码 movz/movk）。

### ESP（build-esp.sh）
- make-esp-recovery.sh 配方：100MiB FAT32 512B / 16h63s，内核必须 `\EFI\BOOT\BOOTAA64.EFI`
  （mkfs.vfat / 根目录放置都 fail，T-B2 实验定案）；
- 每版 +1（vNN），sha 记 MANIFEST.md。

### rootfs（build-rootfs.sh）
- pmbootstrap install（phosh / 密码 1234）——**⚠ `--single-partition` 铁律**
  （脚本已固化）：不加它产出 GPT 分区镜像 + fstab 假 /boot 条目，无 initramfs 内核
  `root=/dev/sda22` 直挂 userdata 必挂载失败（2026-10-07 Release r66 rootfs 首航
  暴雷实锤，坏件已从 Release 撤换）。产物 = 裸 ext4（~4.4G，首启自动扩满 464G）。
- 设备包 r53 起 depends 含 hexagonrtc 三件（传感器 PD 守护链）——rootfs 自动带齐。
- 替代路线：L2 快照锚复原（mkfs.ext4 -d 直出，experiment-log（六十二）），Arch 线遗产、已验证。

## 版本与提交纪律

- 包状态随改随提交（pmaports / fork / Mu 三仓各自本地分支）；
- 每个发布轮：bump → checksum → build → verify → **MANIFEST.md 更新现役行**；
- 产物命名：`mu-r<PKGREL>-<sha8前8位>.img`、`esp-recovery-v<N>.img`。

## Phase-2（公开发布，2026-10-07 清理轮已落地大半）

1. ✅ `PIN_LINUX_GIT` = RiverKawa271828/linux-mobile-ports（fork torvalds/linux；
   推分支 `meizu20-t4b`——基点 58785836 = 主线 7.3 merge window，fork 自带全史，只传增量）；
2. ✅ `PIN_MU_GIT` = RiverKawa271828/Mu-Silicium（fork Project-Silicium；推
   `meizu20-mars-port`）；`PIN_MU_BINARIES_GIT` = RiverKawa271828/Device-Binaries
   （fork 已建，main 钉在 `036ba9f7`）；
3. ✅ `PIN_PMAPORTS_GIT` = RiverKawa271828/pmaports（独立仓已建整条推 `phoenix`）；
4. 内核 tarball **无需 Release**：build-kernel.sh 每轮从 fork 现打（git archive）+
   checksum 重算，APKBUILD `source=` 保持本地文件名——外人 clone 后自给自足；
5. ✅ 固件 tarball（81MB，meizu20_linux 厂商资产，永不入 git）已上 Release
   （用户 10-07 拍板上传，licensing 照 silime 先例）；sha512 已钉 APKBUILD；
6. ✅ 成品镜像：现役对在仓（mu 裸 1.1MB + esp .img.gz ~14MB）；ESP 裸镜像
   （恰 100MiB）不入 git（v43–v45 已 filter-branch 出史）；
7. ✅ `setup.sh --clone`：四仓 + 官方 pmbootstrap（gitlab.postmarketos.org）自动摆位；
   wrapper（script/pmbootstrap-meizu.sh + cfg）与 tools（tools/）已收编本仓；
   ⚠ 回滚锚三件已删（2026-10-13 用户拍板：T 时代旧版 bug 多不再回滚；rollback.sh 一并删）——
   `--fetch-release` 只拉直刷三件+固件+SUMS；救砖 = flash-batch.sh 重刷现役三件；
8. ✅ **推送状态（2026-10-12 终态）**：内核 fork `meizu20-t4b` = `140e5a8e308a`（v7.3-rc6
   重放 + r82-84 三轮，84+3 提交），pmaports `phoenix` = `b4e5147`（pkgrel 84），nura
   `master` = `770c92f`（发布面切换 + 文档对齐）——三树全推清账；3 个历史分支已改挂 tag
   （`archive/*`）；GitHub 默认分支 = `meizu20-t4b`。⚠ **分支规范：分支只留「现役 + 上游镜像」，历史落 tag**。
8. ⬜ **干净机首航**：找一台第二机器/容器从零跑通 setup→build→flash，发布面才算成立。
   （2026-10-07 本机已用 Release 资产完整重放直刷三件一轮：rootfs 两雷修复后
   全绿，boot ~40s；但同机非干净机，此项仍开。）
9. ✅ **上传后脚本对齐**：①`build-rootfs.sh` 出 Release 件（`meizu-meizu20-rN.img.gz`
   + SHA256SUMS 一并生成；**2026-10-12 起固化条件 = NURA_NO_RELEASE 开关，phosh 默认
   进发布面**）②`setup.sh --fetch-release` 拉现役件+固件+SUMS ③直刷命令文件名与
   Release 页已实刷对拍（r66 首对拍；r84 = 10-12 本机 phosh 回归轮直刷全绿 =（八十七））。
10. ✅ **发布面切换（2026-10-12，用户拍板「以后专注 phosh」）**：Release r84 = 首个
    phosh 发布面（7 件制）；r66 已删；r80 = plasma 末版存档未删。**升级口径 = apk 腿
    （rootfs 内 apk add）+ ESP 腿（recovery_a）原地升级，不重刷 userdata**——rootfs
    全量重刷仅换 UI/换发行版/从零装机。

### Release 资产清单（现役 = <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r91>，2026-10-21 上线 Latest = 7.3 stable rebase 首发 + device r63 传感器依赖闭合；r87 = 上一个 waydroid+phosh 发布面未删，r80 = plasma 末版存档）

| 件 | 文件 | 出处 |
|---|---|---|
| 现役 boot_b | `mu-r91-350386e0.img`（1.1MB） | Release 资产（CI 构建） |
| 现役 recovery_a | `esp-recovery-v71.img.gz`（gz 化，刷写自动解压；CI 发布件 gz f08139e3） | Release 资产 |
| 现役 rootfs | `meizu-meizu20-r91-phosh.img.gz`（836M gz；**同轮产物，内含 r91 内核 apk + 设备包 r63 + 固件 r3 + iio fork r3，phosh 桌面 = pmOS 官方 phosh 包集**，刷完即完整系统）。**r86 起件名带 UI 后缀** = `meizu-meizu20-<tag>-<ui>.img.gz`（如 r91-phosh；本地实验件 = `meizu-meizu20-<ui>-local.img`，多 UI 并存不混） | `build-rootfs.sh`（gz+SHA256SUMS 自动产出） |
| 附带 apk 两件 | `linux-meizu-meizu20-7.3.0_rc6-r84.apk`（sha8 b5dd7e62）+ `firmware-meizu-meizu20-1-r3.apk`（sha8 6e6dac0a） | `$PMB_WORK/packages/edge/aarch64/` |
| 固件 tarball | `firmware-meizu-meizu20.tar.gz`（81MB，仅构建者需要） | pmaports 包目录 |
| SHA256SUMS | 不含 apk 件（apk sha8 见 Release 页说明） | `build-rootfs.sh` |

（历史：锚三件 t-b2/esp-v4d/mu-r57 自 r80 起不随 Release 上传；2026-10-13 本地件与
`rollback.sh` 一并删除——旧版 bug 多，不再回滚。）

外人消费路径 = Release 下载三件（boot / recovery / rootfs）→ FLASHING.md「快速路径 A」
直刷，**无需构建**（构建者才需要固件 tarball）。
