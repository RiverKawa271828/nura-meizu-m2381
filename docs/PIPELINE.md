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
- pmbootstrap install（plasma-mobile / 密码 1234）——**⚠ `--single-partition` 铁律**
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
   ⚠ 回滚锚三件自 r80（2026-10-11）起**不随 Release 上传**（用户拍板：刷坏重刷现役三件
   即可）——`--fetch-release` 只拉直刷三件+固件+SUMS，本地锚私有保留（rollback.sh 自用）；
8. ✅ **推送状态（2026-10-08 （七十七）rc6 轮）**：内核 fork `meizu20-t4b` 已 force-push 到
   `2431440968fe`（**v7.3-rc6 重放**，84 提交），`master` 同步到 rc6 基线提交 `a90ee4305c4a`
   ⇒ 公开页面「领先 84 提交」= 恰好板级内容；3 个历史分支已改挂 tag（`archive/*`）并推送；
   GitHub 默认分支 = `meizu20-t4b`。⚠ **分支规范：分支只留「现役 + 上游镜像」，历史落 tag**。
8. ⬜ **干净机首航**：找一台第二机器/容器从零跑通 setup→build→flash，发布面才算成立。
   （2026-10-07 本机已用 Release 资产完整重放直刷三件一轮：rootfs 两雷修复后
   全绿，boot ~40s；但同机非干净机，此项仍开。）
9. ✅ **上传后脚本对齐**：①`build-rootfs.sh` 出 Release 件（`meizu-meizu20-rN.img.gz`
   + SHA256SUMS 一并生成）②`setup.sh --fetch-release` 拉锚三件/现役件 ③直刷命令
   文件名与 Release 页已实刷对拍（10-07）。

### Release 资产清单（2026-10-07 上线 <https://github.com/RiverKawa271828/nura-meizu-m2381/releases/tag/r66>；当日 rootfs 换件一次：首版漏 `--single-partition` 上机暴雷，修复版 sha8 `e4636bfe`）

| 件 | 文件 | 出处 |
|---|---|---|
| 现役 boot_b | `mu-r66-9033a734.img`（1.1MB） | 本仓 `artifacts/` |
| 现役 recovery_a | `esp-recovery-v47.img.gz`（gz 化，刷写自动解压） | 本仓 `artifacts/` |
| 现役 rootfs | `meizu-meizu20-r66.img.gz`（1.1G gz；裸 ~4.4G 超无压力但 gz 化统一走 Release 单件 2GiB 规则；**同轮产物，内含 r66 内核 apk + 设备包 r53 + hexagonrtc 依赖链**，刷完即完整系统） | `build-rootfs.sh`（gz+SHA256SUMS 自动产出） |
| 锚 t-b2 | `t-b2-m2381Pkg-RELEASE-d4928661.img` | `<NURA_WORK>/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/` |
| 锚 esp-v4d | `esp-recovery-v4d.img` | `<NURA_WORK>/meizu20/meizu20-m1/m1-work/arch-a/` |
| 锚 mu-r57 | `mu-r57-4640ebb5.img` | `<NURA_WORK>/meizu20/meizu20-m1/artifacts-uefi/mars-t-series/` |
| 固件 tarball | `firmware-meizu-meizu20.tar.gz`（81MB，仅构建者需要） | pmaports 包目录 |

外人消费路径 = Release 下载三件（boot / recovery / rootfs）→ FLASHING.md「快速路径 A」
直刷，**无需构建**（构建者才需要固件 tarball；锚三件 = 可选救砖件，下载后放回
`config.sh` 指的同布局路径即可，缺失时 `setup.sh` 只警告）。
