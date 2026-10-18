# 窗口期轮执行卡（2026-10-19 落盘，下会话照此做；每项独立可停）

> 背景：rc7 rebase 演练已收官（10-19，98 提交零冲突 + r89 编译验证，报告 =
> `docs/rebase-dryrun-rc7-20261019.md`——**勿重做**）。本卡 = 窗口期剩余任务排程。
> 路线 D（32 位 app）已关闭（10-19 用户终判无需求），勿再提。

## 0. 开工第一件事：窗口检查（2 分钟）

- 核 7.3 stable 是否已发布（`git ls-remote https://github.com/torvalds/linux.git refs/tags/v7.3`
  或 kernel.org）：
  - **已出** → 窗口期任务全部挂起，转**正式 rebase 轮**：照
    `docs/rebase-dryrun-rc7-20261019.md` §stable 正式轮清单执行（fetch `v7.3` tag →
    重放 → sanity 四件 → bump pkgrel 90 出件 → verify 全绿 → printk 流程卡第一测；
    推送/发布窗口仍 = 用户拍板）。
  - 未出（或 rc8 出现顺延 ~11-01）→ 按下表顺序做，做几件算几件，每件做完落档即停。

  > ✅ **10-19 执行：未出**（ls-remote kernel.org 只到 v7.3-rc7 `ec8bf828`，rc8 未出）
  > → 按卡执行；下会话开工仍需**重跑本检查**（窗口随时可能开）。

## 1. 蒸馏③音频方法论（首项；steamos 线在等正式版）✅ 2026-10-19 收官（nura `782f3d1` + pmos 队列卡打勾 `f1b2d5d`；未 push）

- **目标**：`nura docs/AUDIO-METHOD.md`（命名对齐 BOOT-CHAIN-RE/PANEL-CORRUPTION 风格）。
  核心 = 出声必需清单的展开版：直驱 T4c 工作点 + 声卡非自然 probe 的编排
  （autoprobe=1→pinctrl→va→sound + ADSP ~boot+75s 长预算重试）+ BE intf 五层排查序 +
  UCM/tplg/服务串清单。**蒸馏不改判词**；fast-switch 判负与响度封卷照实写。
- **素材**（先核对再引用，勿凭记忆写）：执行卡 =
  `pmos_linux docs/meizu20/public-distill-queue-20261012.md` ③节（素材地图 + 红线）；
  主档 = `pmos_linux docs/meizu20/audio-audit-20261001.md`（370 行，注意文内 B5 勘误块）
  + experiment-log（五十九）（六十六）（六十八）（七十）（七十一）+ nura AGENTS「带话」节
  出声清单回信。
- **红线**：stock 提取件（flyme 调音 txt/wmfw 等）不入公开仓；我们自产件（UCM/tplg/
  服务串/补丁）放心引用。
- **完成定义**：文档落 nura docs/ + `文档：` 前缀独立 commit（不 push，窗口随大轮）+
  执行卡 ③ 节打勾 + 带话素材备好（「已公开成文」一句，用户转告渠道）。

## 2. 相机驱动轮预备卡（素材保鲜，复燃成本大降）✅ 2026-10-19 晚收官（pmos_linux `1692ace` = docs/meizu20/s5k3p9-driver-round-card.md；未 push）

- **结果**：执行卡含 DT 节点草案（mainline binding 形态：CCI0 master0 / 7-bit 0x2d /
  MCLK1=tlmm101 19.2M / RST=tlmm117 / 供给 pm8008j L5·L2·L4）+ 首 ACK 判据
  （probe 读 id = 0x3109）+ 红线（880000 门闩 / DTS 变更须重编 Mu）。10-19 取证
  补掉两缺口 = i2c 地址真值（stock ACK 0x5a→0x2d 口径换算）+ stock sensor 节点
  全属性（boot FDT 27279-27462 本体；dtbo fragment 只做供给 phandle 补丁——
  「sensor 子树在 dtbo」判读精确化）。GN5 次目标同表在案（0x8e5@0x7a / csiphy3
  CPHY 5.66G settle 7.2e9）。待驱动轮首测 = 3P9 DPHY 速率 / lane 数 / RESET 极性 /
  regSetting 12/20B 对齐末档。

## 3. wrapper 守卫固化（小件，10 分钟，随时插空）✅ 2026-10-19 收官（nura `0f3a3e4`；守卫置于 cfg 生成前 + NURA_*/PMB_* 钉子逐个 --setenv 透传；沙箱 checksum 冒烟 exit 0 走 systemd-run，pmaports 零 diff）

- **目标**：`script/pmbootstrap-meizu.sh` 加 build-kernel.sh 同款守卫
  （NURA_INSIDE_UNIT 缺失 → systemd-run `--setenv=NURA_INSIDE_UNIT=1` 重入）——
  10-19 演练轮新坑（直调 wrapper 沙箱 sudo mknod EPERM）根治。
- **完成定义**：守卫落地 + 沙箱里跑一次 `wrapper checksum` 冒烟（应走 systemd-run）
  + commit。三坑注释照 build-kernel.sh 抄。

## 4. 花屏 S2 内容值对拍表（调研件，弹药库补件）✅ 2026-10-19 晚收官（nura `8cbb1cc`；PANEL-CORRUPTION §6 条 3 追加「条 3·余面对拍」段；未 push）

- **结果**：evtlog 解码（r14/r1 双族复核）= topology 9（DUALPIPE_DSCMERGE）+ dsc_common_mode 3（SPLIT_PANEL|MULTIPLEX cmd）+ 双块 index 0/1 + ROI 相等早退（stock = ROI 变更触发 vs 主线每 kickoff = 时序差）；15 行对拍表 = 等价 8 项（几何/bpp/bpc/version/RC spec 表/slice-per-pkt 2/链路速率 1094 四档 FDT 同值/ob_max_addr）+ 内容差 = **flbo 13↔12 根因族**（downstream `_get_dsc_v1_2_bpg_offset` slice_h 20→≤30 档 vs VESA 1.2 444 表 → idd 549↔526 / nfl 1402↔1294 / sii 469↔488）+ **initial_lines 3↔2**（Hardent 公式 vs 简化公式；1.2 寄存器路径无 cmd +1——旧判「殊途同归 3=3」修正）+ **DSC_CFG bit17**（主线 cmd 置位 stock 不置）+ PPS 载体 0xA0↔0x0A（在册）。
- **判读**：自洽性两侧各自成立（PPS↔寄存器各自一致）⇒ 非功能错误、无结构差异级新线索，**只记档不排实验，0xC4 仍是首发实验**；主机可达维度的两会话 DSC 内容差全集 = 表 #9-#15（往后「落档输入」类假说的对拍面）。小米11 Pro 三类映射 = ①静态模板覆盖不适用 ②切片打包等价 ③链路速率等价（已被 pin 吸收）。
- **新机制发现**：stock debugfs 活读 DSC 1.2 不可达 = `dsc_init_1_2` 不注册 dump 子范围 → off 写入被 `is_valid_range` 拒——**F4 当日只拿到 evtlog 流的深层原因**；stock 列 = FDT+源码推算（分支族由 evtlog 行号钉 r1/r15+ ± 厂家移行）。

## 5. kalama SDE catalog 收割（彼线受益件）

- **目标**：下游 kalama techpack/display（CodeLinaro msm-5.x/6.x display-drivers）
  的 SDE catalog 真值收割：RGB rot 支持清单 / maxheight / UBWC×rot 组合——rotate-90
  候补件（②）的前置。落 `pmos_linux docs/meizu20/kalama-sde-catalog-20261020.md`。
- **入口**：联网调研规范（先搜现成方案；CodeLinaro REST API 纯 curl 可用）+ fork 树
  `dpu1/`（主线侧 catalog 对拍面）+ 记忆簿 steamos-gamescope-crossline（彼线
  `--force-composition-rotation` workaround 的撤销判据）。

## 6. 7.4 前瞻雷调研（rebase 清单补条目）

- **目标**：binder Rust 化（v6.18-rc1 合入，7.4 生效）对 waydroid 的配置面影响
  （binderfs 行为/CONFIG 面变化/已装机 rootfs 的重验点）+ `drivers/virt` gunyah 在
  7.4 merge window 的复查点——调研落档补进 rebase 清单（只在 7.3→7.4 时需要）。

## 7. upgrade.sh 固化（用户点头件）——✅ **2026-10-19 晚收官（nura `e640683`；未 push）**

- **落地**：`script/upgrade.sh` = apk 腿（devpush+设备侧 sha256 对拍+apk add 主子包
  同装）+ ESP 腿（软进 fastboot→只刷 recovery_a→reboot）+ 双验收（uname #N=pkgrel+1
  + recovery_a dd 读回对 sha）；`--skip-apk/--skip-esp` = 单腿补完；`--host` = NCM
  漂移指定。守卫 = systemd-run **--pipe**（在场交互形态，与 build 类进 journal 的
  差异已注释）；devsh/devpush 补 `--host` 参数（网段漂移坑变门）。沙箱冒烟三路径
  （无件退出/全跳过/报错文案）过；**设备腿首跑随下轮升级实机验证**。UPGRADE.md 已加
  「一键脚本」节对齐。

## 顺序与预算（10-19 深夜更：第 0/1/2/3/4/7 项已收官，见各节 ✅；下会话排面已钉）

- **▶ 下会话排面（10-19 深夜钉，用户令「安排一下下个会话」）**：
  - 开工照旧：记忆复核 → 主档现态 → **第 0 项 stable 复核（第 4 次核）**。
  - **stable 已出 → 窗口任务全部挂起，转正式 rebase 轮**：照
    `docs/rebase-dryrun-rc7-20261019.md` §stable 正式轮清单走（fetch `v7.3` →
    重放 98 commits → sanity 四件 → bump pkgrel 90 出件 → verify 全绿 → printk
    流程卡第一测；0xC4 旋钮预写预构建在册随车；**upgrade.sh 设备腿首跑顺路**
    ——rebase 出件后 apk+ESP 双腿升级正好首验脚本）；推送/发布窗口 = 用户拍板。
  - **未出（或 rc8 出现顺延 ~11-01）→ 主件 = 6（7.4 前瞻雷调研）**：binder Rust
    化（v6.18-rc1 合入 7.4 生效）对 waydroid 的配置面影响（binderfs 行为/CONFIG
    面/已装机 rootfs 重验点）+ `drivers/virt` gunyah 7.4 merge window 复查点，
    落档补进 rebase 清单（§6 节）——**先做 6 的理由：直接喂紧后的 rebase 专项，
    越早入册越防车漏项**。次选 = 5（kalama SDE catalog 收割；本轮已趟通
    CodeLinaro sparse+blobless 克隆法，5 的入场券现成），6 做完即停、5 看兴致。
  - 每件收尾 = 落档 + commit（**不 push**）+ 接续卡打勾 + 记忆簿更新。
  - 非任务待拍板项：Flyme 设备去向（留 Flyme / 重刷现役三件回 pmOS——取证四件
    已全落袋，无新取证需求；回 pmOS = 窗口关闭）。

- **本会话排面收官记录（用户拍板 10-19 晚的排面全部走完）**：首步核 stable
  （未出，rc7 `ec8bf828` 止 rc8 未出）；**主件 4 = ✅**（对拍表落 §6，nura
  `8cbb1cc`）；**插空 7 = ✅**（upgrade.sh + UPGRADE.md，nura `e640683`）；
  **次选 2 = ✅**（相机卡，pmos_linux `1692ace`）。0xC4 设备日可选并行件（条 2
  「stock 唤醒是否重放同一套字节」DCS 级运行流）仍挂 0xC4 车上。
- 每件收尾 = 落档 + commit（**不 push**，推送窗口 = 用户拍板）+ 接续卡对应段落打勾。
- 收官时：experiment-log 追加窗口轮叙事 + 记忆簿更新 + 接续卡「等 stable」态刷新。
