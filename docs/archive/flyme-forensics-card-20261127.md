# Flyme 取证窗口轮 · 执行卡（✅ 收官 2026-11-27：五探针+四插单全收官，归档 ~/work/meizu20-m1/flyme-forensics-20261127/；战果判词入 AGENTS 现态 + 记忆；残面 = camera.ko sy7808 RE）

> **触发方式**：用户自行刷回 Flyme 后说「**取证轮**」即开工。
> **目标**：一次窗口收齐五件活体取证——闪光灯阳极 / GD2 工作流参照 / 通话音频
> 施工图 / GNSS 边界 / GN5 马达弹药。**清单先立后动手，窗内纯执行。**
> 红线继承：modemst / persist（EFS）永不碰（快照四份已归档 b85cad2f/c40223e6）；
> 9008 需用户在场；回程 = flash-batch + rootfs 首刷（顺手验真 FLASHING §3）。
> **前置 ✅（11-27 晚）**：设备包 r89（直装收编）+ 仓内回程镜像
> `meizu-meizu20-r138-plasma-mobile.img.gz`（sha256 040e6437…）已建——回程零再
> 构建零补 apk，见 §4。本会话排面 = 下会话主件（用户拍板）。
> ⚠**一百三十勘误（11-27 晚）**：上述 gz（040e6437）**含判负 hexagonrpcd r9 孤儿
> 坏件，刷之必 boot 循环，已作废**——有效回程件 = 重打版 sha256 **ec969644…**
> （hexagonrpcd 0.4.0-r8），见 AGENTS 版本钉 + MANIFEST rootfs 行。

## 0 · 前置（用户侧，刷机时）

- [ ] 设备个人数据备份（**userdata 会被抹**；测试照宿主已有副本）
- [ ] 开发者选项 + USB 调试打开；确认 BL 解锁态（10-19 窗口先例 = 已解锁）
- [ ] 通话测试对象约好（取证窗内要打/接真实电话两通以上）
- [ ] 灰卡或白纸一张（AWB/曝光参照物，可选但强烈建议）

## 1 · 工具准备（宿主侧，刷机期间并行做）

| 工具 | 用途 | 来源 |
|---|---|---|
| adb（宿主已有） | 全部通道 | — |
| media-ctl / v4l2-ctl（**静态 aarch64**） | 相机 media graph / 格式 | `tools/flyme-forensics/00-prep-static-bins.sh`（pmbootstrap chroot 内 musl-gcc -static 自建，禁外来二进制） |
| tinymix / tinycap（静态） | 通话 mixer dump | 同上（alsa-utils） |
| i2cdetect / i2cget / i2cdump（静态） | GN5 马达/传感器 I2C | 同上（i2c-tools） |
| busybox aarch64 静态 | 设备侧通用件 | 同上或复用 nura 构建产物 |

**注**：pmOS apk 二进制是 musl 动态链接，**Android 上跑不起来**——必须 -static
自建（chroot 原生 aarch64 musl gcc，r124 轮已自举过）。

## 2 · 窗口流程（设备侧，`tools/flyme-forensics/*.sh`，adb push 后 `su -c` 执行）

统一收集目录：`/data/local/tmp/forensics/`（最后 `99-collect.sh` tar + adb pull）。

### 2.1 闪光灯阳极探针（`10-torch-probe.sh` ×3 次）
快照集 = `/sys/class/leds/`（全部节点×全部属性）+ flash PMIC regmap 寄存器全 dump
（`/sys/kernel/debug/regmap/*pm8350c*/registers` 类路径，先 find 确认）+ tlmm GPIO
快照（`/sys/kernel/debug/pinctrl/*/pinmux-pins`）+ dmesg tail。
**三遍**：A=灭灯态基线 → 用户在快捷面板开手电 → B=**点亮态** → 熄灭 → C=熄灭态。
差分 A/B = 阳极供电真相（谁被拉高、哪条轨被使能）。
⚠若 debugfs 不可读（SELinux），先 `su -c setenforce 0`（仅取证窗内），不行再退
`adb shell dmesg` + logcat 兜底。

### 2.2 GD2 前摄工作流参照（`20-camera-probe.sh`）
用户操作：stock 相机切前摄保持取景 60s。
抓取 = camx debugfs 全 dump（`find /sys/kernel/debug -iname '*cam*'` 先摸路径）+
`dmesg`（camx probe/stream 日志）+ **media-ctl -p 全拓扑**（静态工具）+ 每 video
节点 `v4l2-ctl --get-fmt/--all` + logcat（CameraProvider/camx tag）。
**价值 = 与我方失败态逐寄存器差分**（csiphy4/csid/vfe 状态实况 vs 我们零包态）。
后摄顺跑一遍同款（GN5 工作流参照 + AF 过程 logcat 抓 actuator I2C 地址与行为，
`logcat | grep -iE 'actuator|ois|focus'`）。

### 2.3 通话音频施工图（`30-call-audio-probe.sh` ×3 态）
用户操作：待机 → 拨真实电话（对方接）→ 挂断。
抓取 = 每态一次 `tinymix` **全部 card 全部控件 dump** + `/proc/asound/pcm` +
`dumpsys media.audio_flinger` + `dumpsys audio` + logcat（AudioFlinger/AudioPolicy/
AGM tag）。**in-call − idle 差分 = 我们 AP 侧要复刻的 voice graph**。
（若 stock 无 tinymix 二进制则用我们自建静态件；ALSA 卡节点 /dev/snd/* 在 stock
由 ADSP 后端呈现，控件集合即路线图。）

### 2.4 GNSS 会话边界（`40-gnss-probe.sh`）
用户操作：开定位 + 打开地图类 app 等 5 分钟。
抓取 = `logcat -b radio,main` grep -i gnss/gps/loc + `dumpsys location` +
dmesg。目标 = LOC 引擎会话行为与报错边界（对照我方 GeneralError 46）。

### 2.5 杂项收尾（`99-collect.sh`）
`getprop` 全量 + `/proc/config.gz` + `dmesg` 全量 + 内核版本 + 上述全部打包
tar → adb pull → 归档 `~/work/meizu20-m1/flyme-forensics-<date>/`
（**归档进私有区**，公开仓不进 stock 二进制——政策同 BOOT-CHAIN-RE §8）。

## 3 · 已有档案（勿重复收集）
stock FDT 791KB + bootargs（10-19 窗口）；sensormodule 四星 bin 解码（108 轮）；
vendor_a EROFS 全量（camera.qcom.so 26.7MB 等）；modem_pr 158 件（= fw r4 同源）；
SWR 麦域 418 控件清单；EFS 四分区哈希。

## 4 · 回程（取证完毕即回；✅ 前置已毕 = 零再构建）
`script/flash-batch.sh --i-am-present`（boot_b = mu-r138-3f909a93 + recovery_a =
esp v96，仓内在钉）→ rootfs 刷写 = **`artifacts/meizu-meizu20-r138-plasma-mobile.img.gz`**
（或裸件 `meizu-meizu20-plasma-mobile-local.img` 免解压直刷；已含设备包 **r89**
直装收编 + libcamera 99990.8.0-r2 + koko 查看链 + xwayland，**无需 upgrade.sh 补
apk**；userdata 全新 = **首刷路径实测**，FLASHING §3/§5 验真；首 boot failed=3
件非回归在册 MANIFEST）→ readback + 开工惯例全套。
最坏情况 = EDL 整刷工作流（71 分区直写，一次点亮先例）。

## 5 · 判据
- 闪光灯：A/B 差分锁定阳极供电链（哪个元件/轨/引脚）→ nura 侧补齐 → 物理点亮
- GD2：工作态寄存器差分 → 找出 FW 编排差异字节 → r1xx 复燃轮有靶
- 通话：in-call mixer/graph 差分 → AGM voice session 复刻清单 → 通话有声轮
- GNSS：会话边界画像（哪怕只确认闸门位置）
- GN5：actuator I2C 地址/协议样本 → GN5 轮弹药入库
