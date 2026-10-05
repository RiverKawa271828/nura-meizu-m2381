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
pmbootstrap（meizu wrapper）  build-esp.sh ────→ esp-recovery-vNN.img ─→ recovery_a
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

## Phase-2（公开发布，用户拍板后）

1. fork 内核树 → GitHub（`PIN_LINUX_GIT`）；pmaports phoenix 分支 → GitHub fork（`PIN_PMAPORTS_GIT`）；
2. Mu meizu20-mars-port 分支 → GitHub fork（`PIN_MU_GIT`），Binaries 子模块改指公共仓；
3. 内核 tarball 不塞 git（.gitignore 是对的）→ APKBUILD `source=` 切 GitHub Release URL；
4. 固件 tarball 挂 Release（licensing 照 silime 先例，待拍板）；sha512 已钉 APKBUILD；
5. 成品镜像（mu/esp）挂本仓 Release——外人可直刷不构建；
6. `setup.sh` 补 clone 逻辑（按 `PIN_*_GIT` 摆规范布局）；
7. **干净机首航**：找一台第二机器/容器从零跑通 setup→build→flash，发布面才算成立。
