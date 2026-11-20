# 相机多摄扩展轮执行卡（2026-11-20 立；用户拍板：撕裂挂以后修，先攻 GD2 前摄 + 闪光灯，难度不大先做、太大放后）

> 接续一百一十一（首光达成）。在机 = #105（r104）+ v82 + mu-r102 + device r71 + fw r4。
> 资产 = tools/camera/（扫频/恢复/解码五件）+ vendor GPL 源（/tmp/zcode/camera-driver，
> 重克隆：qualcomm-linux/camera-driver @ camera-kernel.qclinux.0.0）+ 解码器
> meizu20-m1/vendor-dig/camx_regs_decode.py（GD2 已 10 组解出）。
> ⚠ 会话首跑：记忆搬家惯例 + pmos 主档必读 + 设备探测（devsh 连通/uname/failed）。

## S0 前置小件（~30min，GD2 blocker + 顺路骑乘车）
- [ ] **pm8008i 细胞 boot 竞态**（GD2 供电侧 blocker）：r71 验收 boot 实测 cell1(pm8008j)
      自动绑定 ✓ 但 cell2(pm8008i) NO-DRIVER——touch-load 只踢 98c000，pm8008i 挂
      988000（hub_2，meizu-bind-988000.sh 另一条时序链）。修法 = bind-988000 脚本同款
      force-bind 补绑（或 touch-load 尾部延时代跑），r72 设备包。
- [ ] **stride/bytesperline 核对**（撕裂案已破 = VFE 实际行 stride 5808[5800 取 16 对齐]，
      5800-stride 解码伪影全案定谳；数据没坏）：v4l2-ctl --get-fmt 实报 bytesperline 核对
      → mainline camss RDI 16 对齐 gap 判定（kernel 一行对齐 or userspace 适配，大概率小件）
      + 行尾 8B 性质取证（pad/元数据）。修复后原生直出干净帧，无需任何还原算法。

## S1 GD2 前摄（主线，难度预判 = 中）
配方 = 3P9 全套复刻（模板现成：驱动 s5k3p9sx.c + DTS 端点形态 + 解码器）：
- [ ] stock FDT 真值：GD2 节点（S5KGD2SP03，stock-fdt.dts ~27637 行带）= csiphy-sd-index /
      CCI 总线+从地址（前摄惯例 i2c 不同 master）/ cell-index / gpio（MCLK/RESET 位）
- [ ] 供电轨：pm8008i 哪几路 LDO（rgltr 表 RT 75 轨在档）→ DTS 引用（依赖 S0 cell2 修复）
- [ ] bin 解码全组（GD2 10 组已解）→ 模式选择（前摄常 2-lane 低速 = 若成立则是撕裂案
      速率裕量的旁证对照，一石二鸟）
- [ ] 驱动 s5kgd2.c（ident/模式表/streamon 序列照 .bin）+ DTS 端点 + config =m
- [ ] 构建 r105+ → 自刷（授权在案）→ 捕获验收 = csi-sweep 脚本改实体名复用
- 判据：满帧落盘 + 行均值剖面过 scene 靶（撕裂不影响判「第二颗传感器通链」里程碑）
- **难度闸**：若 bin/stock 真值显示 CPHY 或异常轨组 → 记档跳 S2，GD2 降候补

## S2 闪光灯（独立件，零 CSI 污染，难度 = 低-中）
- [ ] stock FDT 闪光节点（led-flash-src 挂在传感器节点下，pm8550 flash 通道）
- [ ] 内核 leds-qcom-flash 驱动（config 检查，主线在树）+ DTS
- [ ] 验收 = /sys/class/leds 节点 + 亮灯眼判（用户在场）+ 电流档
- **难度闸**：驱动不在树或需 PMI 大改 → 记档放后

## S3 5E9 景深（余力点名制）
- 同配方第三遍（10 组已解）；价值=凑齐四摄面，难度同 GD2 再降（景深低速率）

## 候补（默认放后，按用户难度规则）
- GN5 主摄 = CPHY 5.66G 难度峰值（mainline sm8550 表仅 2PH DPHY，需 3ph CPHY 表移植
  + 高速裕量战，且撕裂案未结前 CPHY 更难判伤）→ 大后期
- 撕裂修复（一百一十一 §6 假设链：r105 PLL 回读 → Flyme 窗 stock 对照）
- pm8008i 竞态若 S0 未根治则升正式件

## 纪律
- 自刷授权在案（boot_b/ESP 腿 solo，apk 腿 solo；红线分区永不碰）
- 长构建 systemd-run；devsh 长命令拆短+落文件；流进程禁 kill（timeout 包 systemd-run）
- 每阶段收官 commit 不 push；推送/Release = 用户拍板
