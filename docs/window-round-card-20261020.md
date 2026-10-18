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

## 1. 蒸馏③音频方法论（首项；steamos 线在等正式版）

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

## 2. 相机驱动轮预备卡（素材保鲜，复燃成本大降）

- **目标**：`pmos_linux docs/meizu20/s5k3p9-driver-round-card.md` = 相机轮（挂起档）
  的复燃执行卡：s5k3p9sx 驱动轮的 DT 配方（supply/MCLK/RST 映射）+ 首 ACK 判据。
- **素材**：`meizu20-m1/flyme-forensics-20261019/`（fdt/stock-fdt.dts 的 cam-cpas/CSI/
  eeprom/actuator 节点 + cam/dmesg-cam-delta.txt 的 **s5k3p9sx id 0x3109 @0x5a
  ACQUIRE Success** 真值 + CPHY 5.66G/IFE[2] 形态）+ **stock dtbo 解包提 sensor 子树**
  （工具 = `meizu20_linux/tools/libufdt/mkdtboimg.py`；dtbo 备份 =
  `meizu20-m1/slot-backup-20260921/` 与 `flyme-ota-b-20261002/images/`——sensor 节点
  在 vendor dtbo 不在 boot FDT，10-19 取证已证）。主线侧对拍 = fork 树 camera 静态
  准备（`pmos_linux docs/meizu20/camera-static-prep.md`，Chromatix 逆向在案）。
- **完成定义**：执行卡含「DT 节点草案（supply regulator/MCLK clock/RST gpio/cci 地址）
  + 首 ACK 判据（probe 读 id=0x3109）+ 红线（不碰门闩 i2c8=880000）」，存档即可，
  不开驱动轮（复燃 = 用户点名）。

## 3. wrapper 守卫固化（小件，10 分钟，随时插空）

- **目标**：`script/pmbootstrap-meizu.sh` 加 build-kernel.sh 同款守卫
  （NURA_INSIDE_UNIT 缺失 → systemd-run `--setenv=NURA_INSIDE_UNIT=1` 重入）——
  10-19 演练轮新坑（直调 wrapper 沙箱 sudo mknod EPERM）根治。
- **完成定义**：守卫落地 + 沙箱里跑一次 `wrapper checksum` 冒烟（应走 systemd-run）
  + commit。三坑注释照 build-kernel.sh 抄。

## 4. 花屏 S2 内容值对拍表（调研件，弹药库补件）

- **目标**：stock `_dce_dsc_setup/_dce_dsc_setup_single` 每帧参数（F4 evtlog，
  `meizu20-m1/flyme-forensics-20261019/dpu/dpu-evtlog.txt`）vs 主线
  `dpu_encoder_dsc_pipe_cfg → dpu_hw_dsc_config`（PPS/threshold/初始行计算，
  fork 树 `drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c:1993+` + `dpu_hw_dsc.c`）
  逐项对拍表，落 `docs/PANEL-CORRUPTION.md` §6 条 3 剩余面对拍结果（追加，不改判词）。
- **完成定义**：对拍表落档；差异项标注「内容差/时序差/等价」；若发现结构差异级别
  的新线索，只记档不排实验（0xC4 仍是首发实验）。

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

## 7. upgrade.sh 固化（用户点头件）

- **方案已答 =（八十七）**（apk 腿 + ESP 腿原地升级脚本化，不重刷 userdata）。
  排入本轮 = 若您对清单无异议即视为点头；做完对齐 FLASHING/UPGRADE 文档。

## 顺序与预算

- 单会话预算 1-2 件大件：**首选 1（蒸馏③）+ 3（wrapper 守卫）**；次选 2（相机卡）。
- 4/5/6 为并列调研件，谁先有兴致做谁；7 随时插空。
- 每件收尾 = 落档 + commit（**不 push**，推送窗口 = 用户拍板）+ 接续卡对应段落打勾。
- 收官时：experiment-log 追加窗口轮叙事 + 记忆簿更新 + 接续卡「等 stable」态刷新。
