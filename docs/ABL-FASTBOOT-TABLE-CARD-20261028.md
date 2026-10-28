# ABL fastboot 命令表逆向 — 委托卡（2026-10-28，第一待办）

> 来源：iOS 侧（ios-m2381-unixnu）委托，用户 10-28 转交并拍板「现在不着急做，
> 但加入第一待办」——**本卡只落盘排面，执行等用户点名**。
> **零设备纯宿主**：设备现役 iOS 链 + fastboot 单通道红线，全程不碰设备。
> 工具点名（用户 10-28 追加）：**REA CLI 为主刀**，tools/abl-re 配套。

## 背景（iOS r70 轮实测）

`fastboot boot payload.img`：镜像下载 OKAY（98MB），`Booting FAILED
(remote: 'unknown command')` —— 与 nura 在册结论一致（魅族 ABL 裁了 CmdBoot，
BOOT-CHAIN-RE 墙面体系）。委托目标：把该结论做实成**完整命令表**——ABL 到底
支持哪些 fastboot 指令、哪些是残桩、哪些整个编译期删除。

## 素材（2026-10-28 已核实）

- ⚠ 委托原文指的 `artifacts/firmware-meizu-meizu20.tar.gz` **不含 abl/xbl**——
  它是 userspace 固件包（WiFi/BT/ADSP、cs35l45 wmfw、ath12k BDF 等），无分区镜像。
  「解 tarball 取 abl_a.img」路线不成立，勿白挖。
- **本机 abl dd 件现成（真素材）**：私有仓
  `meizu20-m1/artifacts-uefi/uefi-partition-dig-20260930/abl_a.bin` + `abl_b.bin`
  （各 1MiB，2026-09-30 dig 轮产物；同目录有 xbl_a/b.bin 备查）。
- **代际核对开工先跑**（BOOT-CHAIN-RE §7.1）：地址表对 Flyme 12.6 user 变体成立
  ——解出 PE 后先抽 §5.2/§6.1 任一路标串/地址对拍，对上再往下走。

## 工具（REA 点名主刀 + abl-re 配套）

- **REA CLI**：私有 `meizu20/s5-rea/rea-cli/`（ghidra 12.1.4 同在 s5-rea）；
  PE 车道配方 = `rea analyze` 建快照 → `rea decompile <path> <addr> --snapshot <name>`
  （10-21 DisplayDxe 首战跑通：PE 直吃、免 xbl raw-binary 配方；输出看
  normalized_result 段）。
- **tools/abl-re/**（本仓）：`extract_fv.py abl_a.bin out` 解 LinuxLoader PE
  （本代 ~601KB AArch64 PE32+，.text VA=文件偏移）→ `strings -a -t x` 普查 →
  `xref.py` 串引用反查 → `disfunc.py` 函数反汇编（TEXT_OFF=0x1000 /
  TEXT_SZ=0x75000 本机写死）。
- 分工建议：abl-re 抓串/xref 定位（快），REA 出反编译读控制流（省力）。

## 已有底账（从这续挖，勿重做）

- `docs/BOOT-CHAIN-RE.md §6.1` = 2026-09-25 轮 **OEM 命令表半成品**：注册点
  **0x4eab0**，已列 oem poweroff/reboot、read_psn/write_psn:、edl/random/verify:、
  lock/unlock:、root/unroot、kernel-log-enable/disable、ssr-enable/disable、
  logfs、color:/erase-bootinfo 的 handler VA + 权限档；getvar `kernel-log-enable`
  回调 0x4ed0c。§6.2 = private 分区旗标 + logfs 环机制。
  **本轮 = 把 §6.1 的 OEM 面扩成全 fastboot 命令表**（标准命令 + getvar 全集 +
  隐藏项，三档定性），产出与 §6.1 合并或扩写。
- 行为约束底账 = §5.3/§5.4：解压窗 = `DtLoad − K ≈ 0x0537E000 ≈ 83.5MB`
  （`DtLoad = RdLoad − (page+0x200000)`，DT 区恒预留 2MB）、尺寸校验九项全表
  （含 `[K+0x38]==ARMd` 才认 DTB → image_size 校验、appended DTB 末端 ≤ DtLoad
  否则 "Kernel size is over the limit" 拒）。**任务④对着这张表复核。**
- 已知未决 #2（§7.3）：UEFI 变量 "K"（GUID 882F8C2B-…）可改装载基址 = ABL 侧
  唯一合法旋钮，需 SetVariable 授权路径——顺手查 fastboot 面有无写它的命令。

## 任务清单（委托原文五项）

1. **定位命令分发器**：从 `"unknown command"` 应答串反查引用 = fastboot App 的
   fallback 路径；顺着它找命令表（{命令串, handler} 数组；注意标准命令表与
   OEM 表 0x4eab0 可能是两张表，两条都摸清）。
2. **逐条列表**：命令名 → handler VA → 三档定性（正常实现 / 残桩[handler 直接
   回错] / 表中无[编译期删除]）。**重点：`boot` 是「表中无」还是「残桩」定谳。**
3. **普查隐藏/Meizu 特有命令**：全部 `oem …`、`flashing …`、`getvar:` 变量集、
   `set_active`/`fetch`/`erase` 之类。**特别定谳：有无任何形式的内存引导或读回
   通道（`fetch`/oem read 类）——真有 = iOS 侧分区读回可免启动后 reader；
   没有 = 该路正式关门。**
   ⚠ 预判提示（防误判）：§6.1 在册的 `oem read_psn` 是序列号读写、`oem logfs`
   只读 logfs 分区环——都不构成通用内存/分区读回。
4. **复核 ABL 行为约束有无 fastboot 旋钮可改**：gunzip 窗 83.5MB=DtLoad−K、
   忽略 boot ramdisk、image_size/appended DTB 校验（nura 底账 §5.3/§5.4；
   iOS 侧对应文档 = 彼仓 `docs/HARDWARE-m2381.md §7`）——看代码里有无任何
   fastboot 变量/隐藏命令能改变这些行为。
5. **产出**：`docs/BOOT-CHAIN-RE.md` 加「fastboot 命令表」节（全表 + 地址证据 +
   strings/xref 截证）；**§8 红线 = 只进结论与原创脚本，不进固件派生物**
   （解包产物、反编译 dump 留私有面）。

## 交付判据（回报 iOS 三件，经用户转告）

1. 命令表一张（三档定性全覆盖）；
2. `boot` 命令死因一句话（表中无 / 残桩）；
3. 隐藏读回通道有无定谳。
   → iOS 侧据此决定是否关闭「绕过 ABL 限制」这条调研线。

## 排面位置

- **第一待办**（用户 10-28 拍板）。S2IDLE 根治轮二段（AGENTS.md 10-24 排面）
  顺延其后——该轮需设备回 nura 链；本卡零设备，与设备去向无关，随时可点名开工。
