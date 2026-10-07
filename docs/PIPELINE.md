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
- pmbootstrap install（plasma-mobile / 密码 1234）；
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
   （**待建仓**：fork 后推 Binaries 钉住的 `036ba9f7`，不在上游 main）；
3. ✅ `PIN_PMAPORTS_GIT` = RiverKawa271828/pmaports（**待建仓**；pmOS 官方在
   GitLab、GitHub 无镜像可 fork，独立仓整条推 `phoenix`，.git 仅 69MB）；
4. 内核 tarball **无需 Release**：build-kernel.sh 每轮从 fork 现打（git archive）+
   checksum 重算，APKBUILD `source=` 保持本地文件名——外人 clone 后自给自足；
5. ⬜ 固件 tarball（81MB，meizu20_linux 厂商资产，永不入 git）挂本仓 Release
   （licensing 照 silime 先例，待拍板）；sha512 已钉 APKBUILD；
6. ✅ 成品镜像：现役对在仓（mu 裸 1.1MB + esp .img.gz ~14MB）；ESP 裸镜像
   （恰 100MiB）不入 git（v43–v45 已 filter-branch 出史）；
7. ✅ `setup.sh --clone`：四仓 + 官方 pmbootstrap（gitlab.postmarketos.org）自动摆位；
   wrapper（script/pmbootstrap-meizu.sh + cfg）与 tools（tools/）已收编本仓；
   回滚锚三件 = Release 资产（⬜ 待传，缺失时 setup 只警告）；
8. ⬜ **干净机首航**：找一台第二机器/容器从零跑通 setup→build→flash，发布面才算成立。
