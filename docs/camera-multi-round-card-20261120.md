# 相机多摄扩展轮执行卡（2026-11-20 立；11-20 晚广角做实轮 ✅ 后改序：用户拍板「先解决广角，其他摄有问题才有参照」）

> 接续一百一十一（首光）+ 一百一十二（广角做实 ✅）。在机 = #105（r104）+ v82 +
> mu-r102 + device r71 + fw r4（本轮零源码/包变更，钉子不变）。
> 广角（3P9）= **已做实参照件**：`tools/camera/cam-shot.sh`（机上 /root/bin/）+
> `decode-raw10.py`（stride 感知修正版）= 一键捕获+原生直出可视帧。
> ⚠ 会话首跑：记忆搬家惯例 + pmos 主档必读 + 设备探测（devsh 连通/uname/failed）。

## ✅ 已收官（一百一十二，11-20 晚：广角做实）

- [x] **bytesperline 核对（S0-a）✅ = 案子闭环，内核零 gap**：v4l2-ctl 实报
      bytesperline=5808 / sizeimage=20258304 = HW RDI stride 自洽
      （camss-vfe.c `vfe_bpl_align_rdi` CAMSS_8550=16 → roundup(5800,16)=5808；
      `vfe_wm_start` HW stride 寄存器 = bytesperline 本身）。「V4L2 报 5800」=
      一百一十一·补里**未实测的假设**；唯一错件 = 解码器按 5800 连续解包。
      修 = decode-raw10.py 认 stride（行尾 8B pad 跳过）+ 高字节渲染 + 亮度拉伸。
- [x] **行尾 8B 取证 ✅**：亮场帧定谳 = 异族字节（散布 0x60-0xb4 大值，行数据
      族外）= pad/残留渣，无信息量、非元数据、非移位数据——解码跳过即正确。
- [x] **cam-shot.sh 参照件 ✅**：动态发现实体 + 幂等链路（tear all→csid0/rdi0
      实证路）+ stride 实报回读 + 时间戳命名输出；机上 /root/bin/ + 仓内
      tools/camera/。boot 后 ~2.5 分钟即可拍（自动 bind 链 r71 工作）。
- [x] **验证链 ✅**：idx7（名义档 657.5MHz）单发 5/5 rc=0 满帧；默认曝光/长曝
      （exposure=3655+vblank=62047）/关灯/开灯四态全实证；红盒场景盒面文字
      与徽标可辨、切割垫 45°/60° 角标清晰 = 广角全链原生直出。
- [x] **新雷挂账 ⚠**：长曝 5 连拍后**立即重发** → 第二发 streamon 上电在
      `csiphy_set_power→regulator_bulk_enable→async_synchronize_full_domain`
      D 态死锁（无超时；sysrq-b 落地前 reboot -f/trigger 写也被堵——**恢复
      = setsid 脱会话 sysrq-b**，`reboot -f` 后台进程会被 devsh 会话关闭连带
      杀掉）。108 流挂 D 态雷家族新签名，挂 TECH-DEBT 候补；cam-shot.sh 已
      注记纪律：单发间隔 ≥10s、禁长曝连拍后立即重拍。
- [x] **S0-b pm8008i 竞态复现实锤**（非本轮修）：重启后 pm8008-regulator.2.auto
      又 NO-DRIVER（cell1/pm8008j = 广角 7 轨不受影响；cell2/pm8008i = GD2
      供电 blocker）→ 留 GD2 轮修（bind-988000 同款 force-bind，r72）。

## ✅ 一百一十二·补（11-20 深夜，用户令「拍个彩色的看看」）：彩色直出 + 真实 CFA 定谳 + 曝光上限发现

- [x] **decode-color.py**：Bayer→RGB 纯 stdlib（2×2 Bayer 块直映一 RGB 像素零插值 +
      黑位扣除 + 高分位 WB + 全局拉伸 + gamma）；彩色首图 =
      `tools/camera/color-first-20261120.png`（红盒金字/木桌/垫面/G-SYNC 绿标全可辨）。
- [x] **★真实 CFA = GBRG**（首行 G 行；红盒眼判定谳：GRBG 版盒蓝/桌蓝/垫棕 = R/B
      互换特征，GBRG 版全自然）——**驱动 mbus 标 SRGGB10 与实际线序不符**（灰度
      无影响、彩色才暴露）。小件候补：s5k3p9sx.c mbus code/卷名修正（随 GD2 轮顺手，
      或至少 userspace 记死 GBRG）。
- [x] **★曝光上限跟帧长走**：max = height+vblank-8（vblank=175 时 3655；
      vblank=62047 时 **65527 ≈ 0.66s/frame → 300ms 级长曝解锁**）——夜景色彩
      信号 16 倍（类均值 1.3→20.7），暗场彩色从此有门。
- 判据链：WB 后场景自然（白=白/木=暖/垫=深蓝）、盒面金字竖排可辨。

## ✅ 一百一十二·乙（同夜，用户问「VP9/HEVC 什么时候加」）：Iris 硬解码冒烟 ✅ = 已在内，三编码全通

- [x] **底态零成本**：Iris（aa00000.video-codec）随主线在内——qcom-iris 已绑定，
      /dev/video0/1 = 硬解码/编码节点，fw vpu30_4v.mbn 在包，caps = H264/HEVC/
      VP90/AV01。**「加解码器」这个问题不存在——已经在了**。
- [x] **冒烟实证**：gst-play 无头 + `GST_PLUGIN_FEATURE_RANK` 提权，h264/hevc/
      vp9 三路测试流全通（v4l2h264dec/v4l2h265dec/v4l2vp9dec → DMABuf NV12
      零拷贝 + EOS）；AV1 留流抽验。
- 候补小件：①日用化 = v4l2 解码器 rank 持久化（默认 rank=0 不自动入选）+
  真机屏上播放眼判 ②AV1 流抽验 ③编码面（video1，相机录像/录屏未来用）④设备
  apk 网络路堵（wifi 无 CDN 流量，装包走 sideload；修复挂小件）。测试流留机
  /tmp/vdec/。

## 下一轮主线：S1 GD2 前摄（配方 = 3P9 全套复刻，模板/工具全在）

- [ ] stock FDT 真值：GD2 节点（S5KGD2SP03，stock-fdt.dts ~27637 行带）=
      csiphy-sd-index / CCI 总线+从地址（前摄惯例 i2c 不同 master）/ cell-index /
      gpio（MCLK/RESET 位）
- [ ] 供电轨：pm8008i 哪几路 LDO → DTS 引用（**前置 = 先修 S0-b pm8008i 竞态**）
- [ ] bin 解码全组（GD2 10 组已解）→ 模式选择（前摄常 2-lane 低速 = 撕裂案
      速率裕量的旁证对照，一石二鸟）
- [ ] 驱动 s5kgd2.c（ident/模式表/streamon 序列照 .bin）+ DTS 端点 + config =m
- [ ] 构建 r105+ → 自刷（授权在案）→ 捕获验收 = **cam-shot.sh 改实体名复用**
- 判据：满帧落盘 + cam-shot 渲染场景可辨（广角已做实 = 对照基准在案）
- **难度闸**：若 bin/stock 真值显示 CPHY 或异常轨组 → 记档跳 S2，GD2 降候补

## 后排（难度规则不变）

- S2 闪光灯（leds-qcom-flash 独立件，零 CSI 污染）
- S3 5E9 景深（同配方第三遍）
- GN5 主摄 = CPHY 5.66G 难度峰值 → 大后期

## 纪律（增补）

- 自刷授权在案（boot_b/ESP 腿 solo，apk 腿 solo；红线分区永不碰）
- 长构建 systemd-run；devsh 长命令拆短+落文件；流进程禁 kill（timeout 包 systemd-run）
- **捕获纪律**：单发间隔 ≥10s；长曝连拍后勿立即重拍（死锁雷，见上）；devsh
  超时后设备侧命令仍会跑完（本次 c5/c6 互踩教训 → 输出已时间戳命名防覆写）
- 每阶段收官 commit 不 push；推送/Release = 用户拍板
