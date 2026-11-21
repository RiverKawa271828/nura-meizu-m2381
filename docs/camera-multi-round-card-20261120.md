# 相机多摄扩展轮执行卡（2026-11-20 立；11-20 晚广角做实轮 ✅ 后改序：用户拍板「先解决广角，其他摄有问题才有参照」）

## ✅ 一百一十四（11-21）：-32 双案破译 + GD2 链上机（接续一百一十三排面，全项达成）

- [x] **-32 案全破 ✅**（四层：①camss `video_check_format` 静默 -EPIPE[全拆脚本
      pad 统一 SGBRG10 时 video 节点留 pRAA=SRGGB10 → 必炸且零打印；pGAA 一发
      满帧实锤] ②脚本 `$Wx$H` 展开吃宽[/3488 残废 fmt → pad set 全静默失败 →
      响版 -32] ③read-back grep 锚错实体[撞 csiphy 链接行] ④pgAA 小写 g）——
      **内核/boot 链/pm-Runtime 全洗清**；cam-shot.sh + cam-shot-front.sh
      **fmt 自适应版**落库+上机（读回驱动实际 code → 全 pad+video 跟随）。
- [x] **设备混态定谳 ✅**：上会话"r104 原版模块恢复"= 只换盘未重载（apk 锁尸 +
      devsh 短窗双坑），运行态 = r116 模块；重启洗净后 112 精确流程复刻 =
      暗场签名帧（与 box2 直方图逐值同族）= **链健康**。判据 = gain ctrl 有无 +
      crop/selection 有无 + .ko 常量位移扫。
- [x] **GD2 链上机全绿 ✅**（授权自刷）：r116 apk sideload（`--no-network` 破
      APKINDEX 网络堵；锁尸 pkill）→ mu-r112 boot_b（读回 a3dbcf6c ✓ 按镜像
      字节截取）+ v85 recovery_a（44f25038 ✓ 全分区）；3-0010 ACK + csiphy4
      [ENABLED,IMMUTABLE] + failed 0。**在机 = #113 + r116 模块 + device r72**。
- [x] **GD2 残墙定谳 ✅ = MIPI 零包（一百一十一同族）**：s_stream 全通（r116
      插桩零触发 = 无 subdev 报错）+ STREAMON 接受、dqbuf 干等 + **传感器在流
      （流中 i2c 直读 0x0100=0x0001，bin 精确命中）** + MCLK4 19.2M on +
      GPIO104 = cam_aon_mclk4 引脚绿 + pm8008i/j 轨活 + csiphy4 clk 400M on +
      **csid0 IRQ delta：40s@30fps 流内仅 +1（边界）vs 应 ~1200 SOF** → 断层 =
      **传感器 TX ↔ csiphy4 lane 层之间**。3P9 同 boot 同下游满帧 rc=0 =
      管线机制无罪。候选 = ①GD2 PLL 块 bin 真值从未硬件验证（19.2M/7×145×2=
      795.43MHz 数学闭合但寄存器未在硬件活着过）②csiphy4 AON 域 PHY 层
      （GD2 全链 = AON 域[cci1/mclk4/前摄]，3P9 = 非 AON）。
- [x] **新雷挂账**：s5kgd2sp03.c int64 pixel_rate WARN（`__v4l2_ctrl_s_ctrl ←
      s5kgd2_set_pad_format+0x164`，-22，libcamera 枚举触发）= 3P9 已修款
      （59b2cd1ca8e3）的同款未修 → **r117 顺手件**。timeout -s KILL 杀流后
      REQBUFS EBUSY 瞬态（秒级自愈）。csiphy 计数非包级（成功帧也 0），csid
      计数 = SOF 级有用。

## 下轮排面（用户 11-21 拍板改序：「误入歧途」审计优先——先验真值再动内核）

0. **★寄存器真值审计 ✅（一百一十五，11-21，纯宿主侧全案收官——「误入歧途」
   假说寄存器面否决）**：
   - **bin 解码全案成立 ✅**：字节级 slot 不变式（记录 w[1]/w[4]/w[9] = 三字段
     节点槽位下标 [registerData/delayUs/trailing]，addr = w[2] 立即数）四 bin
     **12011/12011 零失配**（GD2 1866/3P9 1937/5E9 160/GN5 9048；审计器 =
     vendor-dig/camx_regs_audit.py）。`plausible=198/396` 定谳 = **旧 20B 步长
     产物的化石**（records=2×真数、plausible=真数 7920/40），非现行解码器疑点；
     g3 `{0x077f}` = w[1] 节点下标 1919 误读成数据，真值 = **0x0100←0x0001**
     与笔记一致。
   - **Volla 真机驱动对拍 ✅**（mt6878 s5kgd2sp，HelloVolla/
     android_kernel_modules_volla_mt6878，源件存 vendor-dig/volla-ref/）：
     寄存器集结构同构（0x0114/0116/0136/0x0300 块/0340/0342 全对上）；**boot
     链 = 标准 GD2 唤醒+patch 配方**（Volla sensor_init 与我方 bin 头逐条同款：
     0x0000←ID 值→0x0000←0x0842→0x6010←1→delay→0x6214/0x6218 kick）；
     **4-lane 双源**（bin 0x0114←0x0300 + Volla SENSOR_MIPI_4_LANE）；
     stream 0x0100/gain 0x0204 双源。**MCLK 编码考据**：0x0136 = Q8.8 MHz
     （Volla 0x1800=24 头注释锚定；3P9 0x1333=19.2 在机活体锚定）；GD2 bin 写
     0x1300（=19.0）而 **stock FDT 喂 19.2M**（clock-rates 0x124f800）→ 1.05%
     差记档，**非墙源**（一百一十一 3P9 settle 网格 idx0/3/5/7=200~657MHz 全
     出帧 = 窗宽容差实证）。
   - **stock FDT GD2 节点重审 ✅**（flyme-forensics-20261019/fdt）：
     MCLK4=19.2M + cci-master=1 + gpio104/120 + csiphy-sd-index=4 + 四轨
     phandle 全部与我方 DTS/驱动**相等**；Qualcomm camx 形态传感器节点
     **无 lane 属性**（运行时域）→ 4-lane 站 bin+Volla 双源；csiphy4 =
     `csiphy-v2.1.2` @acec000 + **shared-clks=<1 0 0 0>（AON 共享时钟 stock
     实证，一百一十四 b 候选加持）**。
   - **驱动保真 ✅**：mode 序列 0/198 diff；boot(6)+kick(2)+patch(1256) =
     bin g7 1264 全等 + 双 delay（5ms/11ms）时序保留。
   - 顺手件：camx_regs_audit.py（不变式审计器）+ camx_vs_driver_diff.py
     （驱动↔bin verbatim diff）+ volla-ref/ 五件源码入库。
1. **r117/r118 内核插桩 ✅（一百一十六）**：csiphy4 三点插桩全绿
   [set_clock_rates bpp10/4lanes/795.43M + power-on 双 400M + lanes_enable
   settle=29/lane_mask=0x8f/pos[0,1,2,3] = 与工作 3P9 链同构 = **RX 无罪**]
   + s5kgd2sp03 int64 修复。⚠r117 = 空 bump 死包（APKBUILD git-archive
   取源吃未提交编辑——**改源必先 commit 再 build**）；真件 = r118。
2. **GD2 PLL 寄存器读回 ✅（一百一十六）**：PLL 头 0x0300-0306 落位读回全等；
   **PLL 尾 0x0308-0310 = NAK/FW 管控区**；**VTS/LLP/MIPI TX（0x0340/0342/
   0114/0136）驱动流前写不驻留（读回 0）而流中用户态写驻留精确**；
   0x0136/0116 读回漂移 = FW 状态；五连实验全无帧 → **判词 = 传感器流启动
   FW 过渡丢弃驱动预流写，stock 编排层（bin 之外）= 残墙**。
3. **★下会话主件（一百一十七排面，用户 11-21 拍板「安排下个会话」）= sensor
   lib REA 轮**（**✅ 一百一十七已收官 11-21，判词改写见下**）：
   - **目标件**：`meizu20-m1/vendor-dig/vendor-root/lib64/camera/
     com.qti.sensor.s5kgd2sp03.so`（23824B ARM64，入口
     **GetSensorLibraryAPIs**；★差分锚 = **com.qti.sensor.s5k3p9sx.so
     同尺寸 23824B 异 md5**[643374f3 vs a6f8d325] = 同模板异嵌入表，
     3P9 在机工作 = 差分真值参照）。
   - **REA 车道**：env = `source /home/ri/work/tools/rea/env.sh`
     （Ghidra 12.1.4 + jdk21 + rea-cli；九十五轮 PE 车道跑通先例
     `rea analyze/decompile --snapshot <名>`）；GD2 lib 全函数反编译，
     提 stream-on/power/init 真序列；先 byte-diff 两 lib 找嵌入表差异区
     再定点反编译。
   - **候补三面**（一百一十六判词）：组保持 0x0104 编排[bin g5/g6 专设
     而我方从未用；Volla s_gph 挂点=adaptor 在用] / 流启动后补序列
     [传感器 FW 过渡丢驱动预流写] / FIFO 窗（0x602A/0x6F12）协议写
     模式寄存器。
   - **r119 = 按真值改 s5kgd2sp03.c stream-on** → 构建（**改源必先 commit
     再 build**[r117 死包律]）→ apk 腿 solo → 净 boot → cam-shot-front
     捕获验收。
   - 破墙后 = 首帧验收（4-cell HW bayer Gr-first 真实行序）+ CFA/decode
     验证；不破 = 差分 3P9 lib 定位缺失件继续。

## ✅ 一百一十七（11-21）：REA 轮收官 = 架构改判 + 双实验判负 + camx 核心取证管线

- [x] **架构改判 ✅**：com.qti.sensor.s5kgd2sp03.so = **纯曝光计算插件**
      （全 80 函数反编译，导出面仅 GetSensorLibraryAPIs/CalculateExposure/
      FillExposureSettings，AEC 填表循环）——**无寄存器序列，stream-on 真序列
      真出处 = camx 核心 camera.qcom.so**；rodata 真差异 = 身份串 "exynos9810"
      （.text 差异 = BL 布局噪音）。素材 = vendor-dig/out/gd2-lib-rea/。
- [x] **bin g3-g9 全解析 ✅**（slot 不变式手工追值）：g3=startStream 0x0100←1 /
      g4=stopStream←0 / **g5=组保持On 0x0104←1 / g6=组保持Off←0** / g7=
      initSettings 1264 全解（旧 decoded.txt unresolved 625 全消）/
      **g8=testPatternData 走 FIFO 窗协议**（0x6028←0x4000/0x602a←0x0600/
      0x6f12←0）/ g9=vendorID 读件；g0 模式表 = 页 0x2000 FIFO 窗头（~45 窗）
      + 直写尾（0x0114←0x0300 四 lane/0x0136←0x1300/PLL 块/0x0340←0x1408/
      0x0342←0x5070/曝光族）。
- [x] **Volla 工作栈全链取证 ✅**（GitHub 拉 adaptor-subdrv-ctrl/drv/i2c 三件
      → /tmp/volla-adt/）：工作链 = patch→**模式表直写无组保持**→AE 组保持→
      **set_dummy gph{VTS}→commit**→0x0100←0x01；⚠**Volla = GD2SP 异件近亲**
      （wake 参数 0x26/0x0A02←0xFFFF/30ms/0xFCFC 全异，不可直平移）。
- [x] **r119 组保持{VTS} 判负 ✅**：fork e7971b90182f → apk r119（md5 89cb49d2
      装机）→ 净 boot → cam-shot-front rc=137 bytes=0；流中读回 MIPI 域仍全 0
      = 组保持单写 commit 不改擦除画像。
- [x] **r120 流后补写判负 ✅ + 过渡时长新画像**：fork 85ef83950ea4 → apk r120
      （md5 c5c17f5f 装机）→ rc=137 bytes=0；**T+5ms 写落过渡窗被擦（驱动零错误
      = CCI 全 ACK 但 T+22s 读回 0）→ 过渡时长 >5ms；T+秒级写才驻留（116 轮）
      但引擎不消费** → 写法/时序两轴已排除，缺口 = FW 过渡时 FW 内部态正确性。
- [x] **camx 核心取证新基建 ✅**：OTA 备份 super.img → lp metadata v10.2 手工
      解析（三元组描述符@52/64/76/88）→ vendor_a 5 extents 1235MiB dd 拼装 →
      **EROFS = fsck.erofs --extract** → **camera.qcom.so 26.7MB**（
      scratch-super-vendor/）；capstone 锚点（★ADRP 两段立即数 immhi@5-23+
      immlo@29-30，漏 immlo 全空报；日志宏死串，活锚 = bin 解析串）定位
      **StreamOn 四函数** 0x11fe260(12.6KB 292calls)/0x12013e0/0x122df70/
      0x1255cf0 + regSetting 解析器簇 0x168b580-0x169d46c；Ghidra headless
      直跑配方（Ghidra 12 = `ghidra.Ghidra` 启动器 + `-Djava.system.class.
      loader=ghidra.GhidraClassLoader` + 全 jar classpath + Java postScript；
      AnalyzeHeadless 无 static main；REA 26MB 撞 startup deadline）。
      **全量分析跑中 → ROI 反编译落 scratch-super-vendor/dec-camx/roi_*.c**。
- **下轮排面（用户 11-21 拍板「网上估计有资料，下个会话先查查」）= 网上资料
  调研先行，再决定 RE 深挖还是按资料改驱动**：
  ①**camx 泄漏/dump 源码**（GitHub code search：`camxsensor.cpp` /
  `SensorDriverData` / `SettingsType` / `ApplyGroupHoldOn` / `GetSensorLibraryAPIs`
  ——vendor dump 镜像仓概率大；gh CLI 可认证搜索）；
  ②**三星 ISOCELL GD2 系资料**：S5KGD2 datasheet/register ref（grouped parameter
  hold 0x0104 语义/stream 过渡/FIFO 窗协议 0x6028/0x602A/0x6F12 固件 patch 协议
  ——Volla 源已证该协议形状）；
  ③**他人 GD2 系 mainline 带机案例**（Volla=GD2SP 异件已入档；搜 s5kgd2/s5kgn
  系 mainline driver patch）；④MIT/Chromatix 侧：sensormodule bin 解析器现成
  实现（"QTI Chromatix Header" 格式他人实现可对拍我方解码器）。
  调研收敛后 → 按资料改驱动（r121）或继续 ROI 反编译稿（dec-camx/ 在盘）。
- **ROI 反编译接力（调研无果时）**：读 ROI 反编译提 stock stream-on 编排真值
  （settings type 应用顺序/FIFO 窗协议语义/组保持/0x0A02 类 bin 外补写）→ r121
  按真值改 → apk 腿 solo → 净 boot → cam-shot-front；若 camx 编排 = bin 全等 →
  墙源收缩回 patch 数据面（g7 完整性/FW RAM 写达性，页 0x2000 读路径不镜像
  写路径已证）。⚠今日教训：字符串锚点有假阳性（0x167b92c 落插值模板 = 算术
  巧合），26MB 混淆库 RE 是多会话工程。
4. **stock AON 域考古**：stock FDT csiphy4/AON 域配置 + Flyme 窗真值（stock 前摄
   在同域工作过 = 有地面真值）。
5. CSI 扫频网格适配 GD2（一百一十一的 12 档是 3P9 驱动的；GD2 单档 → 扫 settle
   需驱动面改动，排 2/3 之后）。


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

## 下会话排面（用户 11-21 拍板）：S1 GD2 前摄 + S2 闪光灯 + 顺手件包

- **S1 GD2 前摄**（主线，前置 = r72 pm8008i 竞态）
- **S2 闪光灯**（leds-qcom-flash）
- **顺手件包**（GD2 轮搭车，各 ~小件）：
  - ★**libcamera 合规补件（s5k3p9sx.c）**：真因在案（11-21 探针）——plasma-camera
    本体好着，差的是驱动强制控制项：`V4L2_CID_ANALOGUE_GAIN`（0x009e0903）缺失
    [致命] + HBLANK 只读[须可写] + selection/PixelArray + orientation ctrl[警告级
    可默认]——补齐后 libcamera simple pipeline 出相机 → pipewire-spa-libcamera
    节点 → plasma-camera 出画面（debayer 须按真 CFA **GBRG** 配，见一百一十二·补）
  - ★**CFA 标签修正**：驱动 mbus 标 SRGGB 与实际线序 GBRG 不符
  - ★**录像编码面（video1 Iris encoder）**（用户 11-21 点名入计划）：录像要编码，
    与相机线搭车；验证形态 = v4l2 编码 M2M 产流冒烟
  - DmaBufAllocator 无 provider 警告（dma_heap 用户态权限，出画面后按需）

## 原排面存档（11-20 版）

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
