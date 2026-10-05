# nura-meizu-m2381 — 项目指南与状态（本仓单一事实源）

> 新会话入口顺序：先读 pmos_linux 仓 `AGENTS.md` 现态一句话（战役级）→ 再读本文
> （本项目操作规则）。两档分工：**硬定律/操作纪律/战役叙事 = pmos_linux 主档**，
> 本文不复制；**本仓管：控制面脚本怎么用、版本钉在哪、发布轮怎么走**。

## 这是什么 / 不是什么（边界，2026-10-06 定）

- **是**：魅族 20（m2381）跑 Nura/pmOS 的**控制面聚合仓**——构建/验证/刷写/回滚
  的脚本 + 版本钉 + 产物清单 + 教程文档。
- **不是**：源码仓（三棵树原地不动：fork 内核 `linux-mobile-ports`、Mu
  `mu-uefi/Mu-Silicium-new`、pmaports——路径全钉在 `config.sh`）｜ 知识库
  （叙事在 experiment-log，硬定律在主 AGENTS）｜ 可独立于 K30 的基建
  （pmbootstrap work dir 双设备共享，必须串行）。

## 目录地图

```
config.sh        唯一定位点：三树路径 + 现役版本(REL_*) + 回滚锚(ANCHOR_*) + 设备通道
script/          build-kernel / build-device / build-esp / build-mu / build-rootfs
                 verify（交付链对拍）/ flash-batch / readback / rollback / setup（体检）
docs/FLASHING.md 刷机教程（每步带验证点）——动手前必读
docs/PIPELINE.md 构建管线 + Phase-2 发布清单（未启用）
MANIFEST.md      现役产物表 + 回滚锚表 + 已知非回归失败（首 boot 看到别慌的三件）
artifacts/       本仓自产产物（esp-recovery-v43.img 起）
```

## 现态一句话（2026-10-06 更；新会话从这里接）

- **首航完成**：`build-kernel.sh` 实弹跑通（ccache 2.5min）→ **r61 apk**（吃 yaml
  修复 `82ecc62184c0`）+ **ESP v43**（c0f7e6cb，本仓 artifacts/）；verify 全绿；
  **r61 dtb ↔ Mu FdtBlob 同源（2d01bf32）= Mu 免重编**。期望 uname **#62**。
- 现役四件 = r61 apk + device r37 apk + mu-r60（boot_b，仍有效）+ esp-v43。
- **T3 一车刷待两条件**：T2 统一命名拍板（全 m2381 系 or 全 MEIZU20 系；若改
  model 行 → 同脚本增量出 r62）+ 用户在场。之后开修音频⓪（零刷机可先行）。
- Phase-2 公共发布：**未启用**（用户拍板「先做完项目再一起上传」）；发布面现状 =
  外人不可构建（四仓零公共 remote、tarball 被 pmaports .gitignore），清单在
  PIPELINE.md §Phase-2。

## 工作流卡

### 构建轮（标准循环，每次发布轮走一遍）

1. 改源码 → **去三棵树里改**（本仓不放源码；本仓 commit 不含源码变更）；
2. `script/build-kernel.sh --bump`（源码变了必 bump；device/fw 用 build-device.sh；
   DTS 变了才 `build-mu.sh`——FdtBlob 必须从**同一个 apk** 抽）；
3. `script/verify.sh` **全绿才算数**（dtb↔FdtBlob 同源 / 扫残留 / zram.ko / ESP↔apk）；
4. 定版三写：`config.sh` REL_* + `MANIFEST.md` 现役表 + （收官时）pmos_linux
   AGENTS 一句话；
5. 提交：三仓各自随改随提交 + 本仓 commit 记定版。

### 刷写轮

- `script/flash-batch.sh --i-am-present` → 装 apk 双包（主包+子包同装）→
  `script/readback.sh` 对 sha → FLASHING.md §5 首 boot 清单。
- 出事 = `script/rollback.sh --i-am-present`（t-b2 + esp-v4d 双锚）。

## 本仓工程规则（踩实的坑，勿重蹈）

1. **systemd-run 守卫三坑**（build 脚本已固化正确形态，改守卫前必读）：
   ① ZCode 沙箱 shell 里 `INVOCATION_ID` **天生有值**，不能当「已在宿主单元内」判据；
   ② `VAR=1 exec cmd` 不把变量带进 systemd 单元，用 `export`；
   ③ **systemd-run 默认不透传调用方环境**，跨单元传标记必须 `--setenv=`。
   最终形态 = 显式 `NURA_INSIDE_UNIT` 标记 + `--setenv` + 时间戳单元名（防自撞）。
2. **pipefail 下 `grep -q` 会吃 SIGPIPE 假阴性**（大列表早退 rc141）——verify 类
   检查用 `grep … >/dev/null` 读全量。
3. **版本单一出处 = 本仓 config.sh + MANIFEST.md**；pmos_linux AGENTS 只留一句话
   级现态——两头详记必漂移。
4. 产物命名：`mu-r<PKGREL>-<sha8前8>.img` / `esp-recovery-vNN.img`；**#N=pkgrel+1**
   定律（上机 `uname -v` 直接对）。
5. **红线继承**（全在 FLASHING.md §8）：写分区必须 `--i-am-present`；只碰
   boot_b/recovery_a；xbl/abl/tz/modem/dtbo_b/super/modemst/persist 永不碰；
   刷写时长不算证据，只看 dd 读回。
6. **K30 并发**：pmbootstrap 共享 work dir，构建前确认 phoenix wrapper 无活动
   （`setup.sh` 已带该检查）。
7. 仓库命名纪律：全小写 kebab `nura-meizu-m2381`；机器引用一律此名。

## Phase-2 发布面（未启用，触发 = 用户拍板）

要点：四仓推 GitHub（fork 内核/pmaports 分支/Mu 分支/本仓）→ APKBUILD `source=`
切 Release URL（tarball 不塞 git）→ 固件 tarball 挂 Release（licensing 照 silime
先例，需用户确认）→ 成品镜像挂 Release → `setup.sh` 补 clone 逻辑 → **干净机
首航验证一次才算发布面成立**。细节 = PIPELINE.md §Phase-2。

## 文档地图

| 想干什么 | 看哪 |
|---|---|
| 第一次上手 / 刷机 | README.md → docs/FLASHING.md |
| 出一车产物 | docs/PIPELINE.md + script/ |
| 查现在该刷哪个版本 | MANIFEST.md（config.sh 为准） |
| 硬定律 / 战役叙事 / 队列 | pmos_linux 仓 AGENTS.md + docs/meizu20/experiment-log.md |
