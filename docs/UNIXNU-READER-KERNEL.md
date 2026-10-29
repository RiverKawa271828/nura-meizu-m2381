# UniXNU 读者专用精简内核（unixnu-reader-7.3.0）

> 2026-10-30 收官。UniXNU 急件委托：payload ESP（recovery_a，100 MiB）里 SHLOG 读者
> 原用 nura ESP v71 整机内核（13.9 MiB），payload 内核涨到 85.2 MiB 后放不下，
> 需要读者专用精简内核（**目标 PE ≤ 4 MiB**）。本仓只出内核 PE + .config 两个件；
> busybox / initramfs 沿用现役不动（13 hex 字段 110 字节 newc cpio 契约不变）。

## 交付物（artifacts/unixnu-reader/）

| 件 | 大小 | sha256（全值见同目录 SHA256SUMS） |
|---|---|---|
| `vmlinuz-unixnu-reader-7.3.0-20261030` | **3,977,728 B（3.79 MiB）** | `1512301a…694d42ff` |
| `config-unixnu-reader-7.3.0-20261030` | ~60 KB | `f7142f19…a506e05` |

- PE32+ executable (EFI application) AArch64 ✓（zboot + zstd，格式与现役 v71 vmlinuz 同族，Mu/payload 菜单 LoadImage + LoadFile2 initramfs 契约不变）。
- 内核 release = **`7.3.0-unixnu-reader`**（CONFIG_LOCALVERSION 标记，UART `uname -r` 即辨身份）。
- 预算对账：85.2（payload 内核）+ 3.79（本件）+ 2.4（杂件）≈ 91.4 MiB + FAT 开销 ≈ 92+ < 100 ✓。

## 源码与构建配方（复现）

- 源码 = fork `linux-mobile-ports` 分支 `meizu20-t4b` @ **`bfc79f41633b`**（7.3 stable
  基线 + 99 提交 carry + D4 三件；D4 件全在 DRM 域，对本内核零影响——DRM 已整体删除）。
- 工具链 = 宿主 `aarch64-linux-gnu-gcc`（Ubuntu 13.3.0 交叉包）；未走 pmbootstrap。
- 构建车道 = `git archive` 打纯净源码副本 + **out-of-tree `O=`**（fork 树内残留历史
  in-tree 构建工件，`O=` 会被 outputmakefile 干净性检查拒绝；也不动 fork 树原样）：

```bash
SRC=/home/ri/work/linux-mobile-ports          # fork 树（零接触，只 git archive）
SRC2=/home/ri/work/temp/unixnu-reader-src     # 纯净副本
OUT=/home/ri/work/temp/unixnu-reader-build    # O= 构建目录（迭代全在这里）
BASE=<pmaports>/device/downstream/linux-meizu-meizu20/config-meizu-meizu20.aarch64

git -C "$SRC" archive meizu20-t4b | tar -x -C "$SRC2"
cp "$BASE" "$OUT/.config"
"$SRC2/scripts/config" --file "$OUT/.config" -e EXPERT   # ★先开 EXPERT（见坑册②）
# …按审计表 -e 必保 / -d 必删（全量清单 = 交付的 config 文件本体）…
make -C "$SRC2" O="$OUT" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
make -C "$SRC2" O="$OUT" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j16
# 产物 = $OUT/arch/arm64/boot/vmlinuz.efi（zboot PE）+ Image（内层，审计用）
```

## 行为契约（对 UniXNU）

- **CONFIG_CMDLINE 与现役逐字节一致**（`earlycon=efifb console=ttyMSM0,115200n8 …
  root=/dev/sda22 rootwait rw loglevel=3 fw_devlink=off clk_ignore_unused
  pd_ignore_unused icc-rpmh.qos_disable=1 … no_console_suspend init=/usr/lib/systemd/systemd`）。
  initramfs `/init` 优先运行，`root=`/`init=` 仅在 unpack 失败的兜底路径生效（同现役）。
- **initramfs**：`CONFIG_BLK_DEV_INITRD=y`（newc cpio 解包路径编译实锤：Image strings
  含 `Unpacking initramfs...` / `Initramfs unpacking failed: %s`）；LoadFile2 外部投递，
  不打进内核（`CONFIG_INITRAMFS_SOURCE` 空）。
- **屏幕文字（用户拍板「能看见字就行，黑屏也没关系」）**：DRM/GPU/panel 全家已删
  （msm_drm/Adreno/DSI/panel-boe-meizu20/backlight 零残留）。文字来源 =
  `earlycon=efifb`（早期字写在 UEFI GOP 残留帧缓冲上）+ `FB_EFI`/`FRAMEBUFFER_CONSOLE`
  （fbcon 常显内核日志）。无 KMS，fb 不会被接管，UEFI 菜单画面之后就是内核文字。
- **USB NCM 腿**：dwc3 **gadget-only** 构建（`USB_DWC3_GADGET=y`，无 host/双角色，
  无 PMIC_GLINK/UCSI/typec——PMIC_GLINK 硬依赖 DRM）。device 模式从 probe 起固定，
  现役 initramfs 的 configfs NCM 脚本绑 UDC 即通，不依赖任何 typec/角色切换事件。
  PHY 链全在位：`PHY_SNPS_EUSB2`（sm8550 HS）+ `PHY_QCOM_EUSB2_REPEATER`（pm8550b，
  走 SPMI——**SPMI 链因此保留**）+ `PHY_QCOM_QMP_USB/COMBO`（usb3-dp combo）。
  f_ncm 链接实锤：System.map 含 `gether_connect` / `ncmmod_init`。
- **UFS 腿**：`SCSI_UFSHCD(+PLATFORM/+QCOM)` + `PHY_QCOM_QMP_UFS` + `BLK_DEV_SD` +
  `EFI_PARTITION`（GPT）全 =y，busybox dd 直读分区。
- **UART 腿**：`SERIAL_QCOM_GENI(+CONSOLE)` + `QCOM_GENI_SE` + `QCOM_GPI_DMA`。
- **自验通道**：`CONFIG_IKCONFIG_PROC=y` → 设备上 `zcat /proc/config.gz` 可核对本
  config；`DEBUG_FS`/`DYNAMIC_DEBUG` 保留。
- 压舱物（删不掉，无功能，合计 ~150 KB）：`POWER_SUPPLY`（arm64 arch 本体 select）、
  `NLS`（复活根头未定谳，同类 arch/文件系统 select 链）、`INPUT`（VT select——
  fbcon 常显的代价，无任何输入设备驱动）。

## 审计终态（终版 config = 1,018 项 =y / 0 项 =m）

**必删全灭**：DRM/DRM_MSM/panel/backlight、SOUND/ALSA、WLAN/CFG80211/BT、QRTR/MHI/
REMOTEPROC/RPMSG/PDR、MEDIA/CAMSS/VENUS、PCI/PCIE、KVM、IPV6/NETFILTER、EXT4/NFS/
EXFAT/HFS、SPMI 之外的 PMIC 外设、MMC/MTD、USB host（XHCI/EHCI）、gadget 非 NCM 函数、
MODULES、SECURITY/KEYS、COMPAT、BPF_SYSCALL、FTRACE/KPROBES、KALLSYMS、SMMU/IOMMU、
TEE/OPTEE、crypto 算法动物园（留框架 8 项）、SUSPEND、THP/COMPACTION、cgroup 全家
（SCHED_AUTOGROUP 是根头）、PERF/AUDIT/TASKSTATS/COREDUMP、**94 个非 qcom `ARCH_*`
平台门**（Renesas/TEGRA/BCM/Exynos…连同三十个子门）、ACPI/XEN/VIRTIO。

**必保全在**（63 项抽检全绿）：EFI_STUB/ZBOOT/EARLYCON、SERIAL_QCOM_GENI(+CONSOLE)、
USB_DWC3(+QCOM/GADGET)、USB_CONFIGFS(+NCM)/USB_F_NCM、SCSI_UFSHCD 三件、PHY 四件、
SM_GCC_8550/SM_TCSRCC_8550、PINCTRL_SM8550、INTERCONNECT_QCOM_SM8550(+BCM_VOTER)、
QCOM_RPMH/COMMAND_DB/RPMHPD/SMEM/PDC/GPI_DMA/SCM/GENI_SE、REGULATOR_QCOM_RPMH、
ARM_QCOM_CPUFREQ_HW、DEVTMPFS(+MOUNT)、CONFIGFS_FS、BLK_DEV_INITRD、EFI_PARTITION、
FB_EFI/FRAMEBUFFER_CONSOLE/VT、IKCONFIG_PROC、DEBUG_FS、DYNAMIC_DEBUG。
CONFIG_CMDLINE 未动一个字节。

## kconfig 坑册（六轮屠杀实录，下轮改 config 必读）

1. **MODULES=n 时 base 全部 `=m` 被 olddefconfig 升级成 `=y`**（m 值失效回退默认 y）。
   解法 = 按 base 的 m 起源符号全体强制 `-d`。
2. **EXPERT=n（base 现态）时 `if EXPERT` 门控符号不可见 → olddefconfig 直接取 default y，
   无视 `not set`**（INPUT `default y`、XEN、ACPI 全中招）。解法 = 先 `-e EXPERT` 再杀。
3. **select 链复活**：QCOM_PDR_HELPERS→RPMSG→VIRTIO、SCHED_AUTOGROUP→CGROUPS、
   LIVEUPDATE→KEXEC_FILE、efi_secret→SECURITYFS、VT→INPUT。逐级追根头再压。
4. **菜单门连锁塌方**：杀 USB_SUPPORT → USB/gadget/NCM 全家蒸发；杀 PHY_QCOM_QMP
   伞 → QMP_* 三件全蒸发。每次 olddefconfig 后必跑必保抽检。
5. **误伤教训**：m 起源屠杀误杀 `PHY_SNPS_EUSB2`/`EUSB2_REPEATER`/SPMI——sm8550 的
   HS PHY 是 eusb2（非 qusb2），repeater 走 SPMI，缺一件 dwc3 永久 defer、NCM 死。
   救法 = DTS compatible→driver→Kconfig→config 四级对账。
6. **kbuild 陈旧 .o 污染**：目录级 `size` 聚合会把已禁目标的旧 .o 算进去；只信最终
   `Image`/`vmlinux`（最终链接产物）与 `.config` 本体。
7. RELR：GNU 工具链过不了 `TOOLS_SUPPORT_RELR` 探测（内核偏 LLD），未启用。

## 验收（UniXNU 侧，设备日）

1. payload 菜单进 reader 项 → UART 出 shell，`uname -r` 应为 `7.3.0-unixnu-reader`；
2. 「Initramfs unpacking」不回归（110 字节 newc 头照旧解包；若失败 UART 会有
   `Initramfs unpacking failed` 行——本件 strings 已验证该路径在）；
3. NCM 起来后宿主 dd recovery_a 前 96 MiB 对拍（= nura-min 现行验收同款）；
4. 可选：设备上 `zcat /proc/config.gz | grep -E 'USB_F_NCM|SCSI_UFS_QCOM'` 自验。

构建/审计全程宿主完成（fork 树零接触、iOS 工作区零接触、设备零接触）；设备实机
验收在 UniXNU 侧。交付 = 本 commit；commit 不 push。
