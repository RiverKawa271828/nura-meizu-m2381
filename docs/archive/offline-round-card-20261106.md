# 下会话执行卡：离线轮（2026-11-06 落盘；用户拍板主工时投 B1，本会话被卫生轮占满顺延）

> **✅ 收官（2026-11-06）**：主件 A = B1 `script/devselfcheck.sh` 落地（自动七项只读 +
> 人工眼判四项 + rtcwake 显式门；shellcheck(dash) 全绿 + 本机烟测全过；真机首跑挂下个
> 设备窗）✅；B3 = FLASHING.md「用户第一小时审计清单」落地 ✅；主件 B = 设备在 iOS 链
> 未跑（S2IDLE 腿原封留根治卡）⛔；B2 容器首航 = 用户砍单收兵（半截 clone 324M 已清）
> ⛔，顺手修 setup.sh 两真缺口（--fetch-release 硬编码 r84 名单改 SHA256SUMS 驱动 +
> 固件 tarball 自动摆进包目录，commit 9472de7）；stable 复核 = 7.3.2 / 7.4 正式均未出
> 不跟进（kernel.org 官方 + gregkh 镜像双核）。本卡归档。

> **性质 = 纯离线轮 + 设备窗条件跳板**；每项独立可停，commit 不 push。
> 收官时执行 AGENTS 规则 8 四动作（三处对拍 / 死卡进 archive / 仓根清扫 / 回执）。

## S0 开工惯例（30s + 2min）

- **stable 检查**：起点 = v7.3.2 / v7.4 正式（11-06 复核：7.3.1 = 40 修批零交集
  不跟进，7.4-rc1 已出不追；走 GitHub 镜像 gregkh/linux，kernel.org 直连慢）。
- **门检查**：①设备在 nura 链？（在 = 主件 B 可跑）②**21 Note 仓开源没**？
  （开源 = 花屏腿解冻：先拉彼仓修复 commit 对拍再排窗，判词/门 = rootcure 卡头部
  + 记忆 panel-rootcure-gate-21note-opensource）。
- 设备现态探测照旧（devsh / uname #92 / wowlan show / cpuidle / systemctl --failed）。

## 主件 A：B1 设备侧自检脚本（纯离线可全部完成）

- **交付**：`script/devselfcheck.sh`（回归清单一条命令出结果 + 与上一版对比）。
- **自动项（只读，默认跑）**：uname 对期望 / `iw phy0 wowlan show` 武装态 /
  cpuidle 深度态 disable 计数 / `systemctl --failed` = 0 / GPU 钳零读数 /
  传感器（iio-sensor-proxy 就绪态）/ WiFi 5G 频段在表（wiphy freqs）。
- **人工引导项（脚本提示、用户眼判后 y/n 记录）**：电源键 / 出声（工作点配方 =
  AUDIO-METHOD §2）/ 触屏 / rtcwake resume。
- **★红线**：rtcwake 用 `-d /dev/rtc1` + 每轮留 ≥25s 眼判（bringup-traps 在册）；
  默认 `--light` 只跑只读项，rtcwake/真睡类必须显式 `--with-rtcwake`；
  脚本在设备侧跑（devpush 上去），结果落 `/var/lib/nura-selfcheck/` 供对比。
- **验收**：本机 shellcheck 过 + 逻辑走查；真机验证 = 下个设备窗顺手（不阻塞）。

## 主件 B（条件件：S0 探测设备在链 + 用户在场才跑）：S2IDLE 腿

- **直接接 [rootcure-window-card-20261101.md](rootcure-window-card-20261101.md)
  主件 B**（E 长跑 ×50-100 无人值守 + 段 4 kprobe 实证），判据坑已写在该卡。
- 花屏腿（彼卡主件 A）**仍等 21 Note 门**，勿抢跑；r92/v72 冻结照旧。

## 拼车池（主件完有余力再，不强制）

- **B2 容器首航预演**：setup→build 两腿从零复刻（不碰 flash 腿）；长任务可背景，
  跑完 = Phase-2 判据的容器半段。
- **B3 用户第一小时审计清单**：FLASHING.md 或 README 加固定一节（语言/键盘/时区/
  联网/浏览器/音量/亮度/电源键/主机名/apk 可用）。
