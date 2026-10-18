# 7.3 rebase 演练（rc7 dry-run）— 2026-10-19

> 目的：stable（~10-25）发布前把 rebase 的冲突/语义风险前置消化，stable 一出即可
> 快车道正式重放。演练基点 = `v7.3-rc7`（`ec8bf8280261`，10-19 fetch 自
> github.com/torvalds/linux，增量对象极小——本地 `github/master` 镜像
> `a5ebb76233b7` 已含 rc7 周期绝大部分历史）。

## 结果一句话

**98 提交零冲突一次重放通过**（rc6 重放时代 84 件 + 近两周新增 14 件），
语义 sanity 全绿，构建验证 = r89（rc7 基线）——stable 正式 rebase 预期
= 同一条零冲突快车道（rc7→stable 仅差收尾提交）。

## 冲突面预判（merge-base `a90ee4305c4a` = rc6 基线）

- 上游 rc6→rc7 变更 338 文件；我方现役触碰 106 文件；**交集 = 3 个文件**，
  全在 ath12k：`core.c` / `core.h` / `pci.c`。
- 上游 ath12k 该窗口净变更 = **一个 panic notifier 块的纯删除**
  （`05165f7b3b9a` Revert "wifi: ath12k: add panic handler"，加于窗口内又回退，
  触碰 core.c/core.h/hif.h/pci.c）——删除区在 core_init/deinit，与我方
  resume/挂起改动区（suspend/resume_early/qmi）无行级重叠 ⇒ 三方合并自动通过。

## 演练操作记录（stable 正式轮照抄）

```sh
cd /home/ri/work/linux-mobile-ports
git fetch https://github.com/torvalds/linux.git tag v7.3-rc7 --no-tags   # stable 轮换 v7.3
git switch -c rebase-dryrun-rc7 meizu20-t4b                              # 演练分支
git rebase --onto v7.3-rc7 a90ee4305c4a rebase-dryrun-rc7                # a90ee4305c4a = rc6 基线
# stable 轮：git switch -c meizu20-t4b-73 meizu20-t4b && git rebase --onto v7.3 <merge-base> meizu20-t4b-73
```

## 语义 sanity（零冲突≠语义正确，逐项核过）

- 提交数 98 = `v7.3-rc7..rebase-dryrun-rc7` ✓
- 上游 panic revert 吸收正确：演练分支 `grep panic_notifier|panic_handler core.c` = 0 ✓
- 我方 ath12k 挂点在位：`warm_resume_pending`（186/205/213）+ `ATH12K_RESUME_TIMEOUT_HZ`（250）✓
- 0xC4 旋钮在位：`dsi_zero_clkout_timing`（dsi_host.c:46-48）✓
- diff 面对拍：`v7.3-rc7..rebase-dryrun-rc7` = 106 文件 = 现役分支触碰面逐文件一致 ✓

## 构建验证

**r89（rc7 基线）出件成功**（sha8 `d8918256`，pkgrel 89，DONE @ 03:11:57）——
rc7 上的全量编译零错误，语义合并正确性获编译背书；演练分支落 tag
`archive/rc7-dryrun-20261019`（`87ca59a3afac`）后删除（分支规范）。r89 = rc7
演练验证件留档不上机（正式件从 pkgrel 90 起）。v7.3-rc7 对象已入本地仓，
正式 rebase 无需再 fetch。

坑记录：①首跑死于上一轮 unit 收尾的 dev tmpfs 残挂（`mknod dev/null` 失败），
照坑册清挂载重跑仍在；②真根因 = **手动直调 wrapper 绕过了 build-kernel.sh 的
systemd-run 守卫 → 沙箱内 sudo mknod EPERM**（wrapper 本身无守卫，一直靠
build-kernel.sh 包着用）——修复 = 显式 systemd-run 重入（`--setenv=NURA_INSIDE_UNIT=1`），
一条即绿。**新坑入册：pmbootstrap-meizu.sh wrapper 无沙箱守卫，任何直接调用
必须自己 systemd-run**（或等守卫固化进 wrapper）。

## stable 正式轮清单（届时照此执行）

1. `git fetch … tag v7.3` + `git switch -c meizu20-t4b-73 meizu20-t4b` +
   `git rebase --onto v7.3 a90ee4305c4a meizu20-t4b-73`（预期零冲突）；
2. 快车道 sanity 四件（同上 panic/挂点/旋钮/diff 面）；
3. tag 双锚：`archive/rc7-dryrun-20261019`（演练分支）+ 正式重放后老 tip
   `archive/pre-73-meizu20-t4b`（分支规范：历史一律落 tag）；
4. 构建链 bump（正式件 pkgrel 从 90 起；r88=0xC4 rc6 验证件、r89=rc7 演练件留档）；
5. verify 全绿 + printk 流程卡第一测（`docs/printk-regression-2min-card.md`）；
6. 0xC4 设备日拼车照旧（旋钮归零 → 真睡×5 → 眼判）。

演练分支 `rebase-dryrun-rc7` 本地保留（tag 后删分支，分支规范：分支只留
现役+上游镜像）；全部本地操作零推送。
