# 音频方法论全集：SM8550 主线出声从零到日用（魅族 20 / m2381）

> **定位**：把 2026-10-01 → 10-07 音频战役（审计轮 + T 系列设备日 + 日用化 + 修复型
> 收尾，全量叙事在私有工作区 experiment-log，未公开）蒸馏成一篇**自包含公开文档**。
> 角度不是"我们修好了一台手机"，而是**高通 SM8550（kalama）主线 Linux 音频
> bring-up 的通用方法论**：音频硬件路径长什么样、路线怎么判别、声卡为什么起不来
> （probe 竞态全家族）、出声必需清单（可平移到其他发行版）、工作点与响度域的账、
> UCM 的三个坑、录音腿的现状边界。每条结论带实验轮次或实文件指针；适用面不限于
> 本机——**"卡注册要人工编排 + 长预算重试"和"过 DSP 路径每流重载固件"两层是
> AudioReach 主线栈的通用形态**，任何 qcom DSP 音频机器都可能撞。
> **政策**：本文只含事实、方法论与我们自己的补丁/配置（全部在公开 fork/包仓，
> §8 有指针）。stock 提取件（flyme 场景调音 txt、CS35L45 wmfw/bin 原件、PAL/ACLM
> XML）一律不入公开仓——结论和参数照写，原件不附。
> 链路背景（这台机器怎么跑起来）→ [DESIGN.md](DESIGN.md)；启动链逆向 →
> [BOOT-CHAIN-RE.md](BOOT-CHAIN-RE.md)；睡眠/s2idle → [SUSPEND-S2IDLE.md](SUSPEND-S2IDLE.md)。

---

## 0. 一页看懂

```
用户面：桌面滑条 → pulse → UCM(HiFi) → ASoC FE(MultiMedia1) → ADSP 路由(APM)
        → Secondary MI2S → CS35L45×2 直驱出声（SPK 底部主扬声器 + RCV 顶部听筒单元）
                     ▲
        三大判决（本文展开）：
 ① 出声链 = CS35L45×2 智能功放（I2C 控制 + MI2S 数据）**直驱**，绕开 DSP 音频处理
    和 WCD9385/SoundWire 编解码域。"过 DSP 路径"（DACPCM=DSP_TX1）= 每次开流全量
    重载 amp 固件 + PLL unlock/错误风暴 = 杂音/不实时真凶，判负（§5.1）。
 ② 声卡不是自然 probe 的：LPI pinctrl → va_macro → machine 三件要按序人工 attach，
    且必须等 ADSP 就绪（~boot+75s，实测 75–290s 窗）。一次性 kick 在每次真 boot
    都输给窗口（§3），**机制无关的验证重试环是唯一稳态**（r48 形态，§4.3）。
 ③ 工作点 = 直驱 T4c 点（DACPCM RCV=ASP_RX1/SPK=ASP_RX2；数字 SPK 409/RCV 251，
    模拟 3/1；stream 垫片 12740 = 滑条 100% 恰 = flyme 100% 响度，§5.2/§5.3）。
    工作点回退/对拍必须四维全对（stream/数字×2/模拟×2 是一组耦合工作点，§5.4）。
```

一图流（boot 时序）：

```
boot → remoteproc 拉 ADSP(~75s, 实测 75–290s) 
     → meizu-amps：autoprobe=0 定向绑 i2c10/888000 → CS35L45×2 上电(REVID A0)
     → meizu-sndcard-bind（r48 环）：每 2s autoprobe=1 + 三连 drivers_probe
       (6e80000.pinctrl → 6d44000.codec(va) → sound) → 查 /proc/asound/MEIZU20
     → 卡注册（MEIZU20，tplg=MEIZU20-tplg.bin）
     → meizu-audio-route：钉直驱工作点 + 30s×20 漂移重钉环
     → pulse 认卡（UCM HiFi profile）→ meizu20-spk-mono.pa 建 remap sink
     → meizu-spk-default.sh autostart 环把默认 sink 钉在 meizu-spk
```

---

## 1. 硬件地图：这台机器的音频通路

### 1.1 通路盘点（mainline 视角）

| 域 | 器件 | 本机状态 |
|---|---|---|
| 功放 | CS35L45×2 @ i2c10/**888000**（@30=RCV 顶部听筒单元 / @31=SPK 底部主扬声器），数据走 Secondary MI2S | ✅ 出声主链（I2C 控制 + MI2S 数据，**直驱**） |
| 编解码 | WCD9385 + SoundWire swr1(6ad0000)/swr2(6d30000) | ⛔ 未 bring-up（耳机/录音域；TX 总线 CLASH 挂起档，§1.3） |
| SoC 数字麦 | VA 宏 6d44000.codec + LPI pinctrl 6e80000（dmic01/23） | ◐ 节点在、DAPM 全绿、样本全零（§7） |
| DSP 路由 | ADSP（remoteproc + APM/PRM，AudioReach GPR 命令面） | ✅ FE/BE 路由必经；**注意**：出声不需要 audiopd 会话守护（§4.4） |

⚠ **i2c 地址纪律**：功放总线是 **i2c10 = 0x888000**；**i2c8 = 0x880000 是另一条
总线（门闩，绑了致死）**。两个地址长得像，历史上不止一人看串——黑名单必须留着，
meizu-amps 只做 888000 的定向 bind（`meizu-amps-load.sh`，注释原文即此警告）。

### 1.2 stock 形态（判定素材，原件不外发）

- stock 卡名 `kalama-mtp-snd-card`（下游 qcom,model 惯例）；stock **没有 tplg**——
  topology 是主线 ASoC 概念，stock 音频走 PAL/ACLM XML + acdbdata（super.img
  vendor 分区考古实锤）。⇒ **自建 tplg 是主线侧唯一路线**（后来用
  audioreach-topology 的 m4 图编出，内容 = 本机硬件图：MM1→SEC_MI2S[CS35L45×2]）。
- flyme 把顶部听筒单元**当立体声左扬声器用**：stock mixer_paths 的 `speaker`
  场景 = rcv_prot + spk_prot 双单元同 817 数字音量（vendored 量纲 ≈ raw 0dB，§5.2）。
  我们最终选择尊重物理角色（听筒当听筒，§5.5），是产品决策不是技术约束。
- stock 录音 = SoC PDM 数字麦（VA/SWR 域，WCD 零关系）——2026-10-19 Flyme 取证
  再证（FDT 有 va_swr_master + swr-dmic×4；手拨 mixer 不通 = stock SWR 路径要
  HAL AFE 会话语义）。录音腿现状见 §7。

### 1.3 路线判别史：为什么是 CS35L45 直驱

最初按 stock 拓扑对齐抄了 WCD 全链（wcd-playback/capture dai-link + audio-routing），
卡死在 `failed to instantiate card -110`——根因 = swr TX 总线 `SWR CMD error,
fifo status 0xe00c000` 风暴 → wcd938x component probe -110 阻断卡实例化。风洞
（无 wcd 空载拉链）证明 CLASH 与 codec 驱动无关（首发于 TX probe 同一秒、复位
wcd 芯片无效、摘 CLASH 中断后 INT_STATUS 仍恒 0x08 = 持续性真实冲突，dout 端口
编号错位嫌疑）→ **WCD/SWR 链转挂起档**。改走 T4 变体（只留 SEC-MI2S × CS35L45
单链验出声）一次点亮 → 直驱定型。教训：**把出声验证和编解码链解耦——先让能亮的
链亮，编解码域单独排期**；stock 拓扑对齐是正确的终点，不是正确的第一步。

---

## 2. 出声必需清单（平移到其他发行版照单抄）

以下按"从电到声"的依赖序排列；全部实文件在公开 fork（内核 DTS）与 pmaports
device 包（`device/downstream/device-meizu-meizu20/`，路径以该仓为准）。

### 2.1 DTS（fork `sm8550-meizu-20.dts`）

- `sound` 节点：`compatible = "meizu,meizu-20-sndcard", "qcom,sm8550-sndcard",
  "qcom,sm8450-sndcard"`（机器驱动 = `snd-sc8280xp`，meizu 条目里带 mi2s
  mclk/bclk 配置）；`model = "MEIZU20"` **既是卡短名也是 tplg 文件名契约**
  （驱动按 model 请求 `/usr/lib/firmware/qcom/sm8550/MEIZU20-tplg.bin`）；
  `pinctrl-0 = <&i2s1_default>, <&dmic01_default>, <&dmic23_default>`（全在
  LPI pinctrl 6e80000）。
- `secondary-i2s-dai-link`：cpu=`SECONDARY_MI2S_RX`，platform=`q6apm`，
  codec=`cs35l45_rcv + cs35l45_spk`。
- `va-dai-link`（录音腿）：cpu=`TX_CODEC_DMA_TX_3`，codec=`lpass_vamacro 0`
  （照 sm8550-hdk.dts 同构模板抄的；⚠ 拓扑侧真正的 DSP 接口参数要改 VA/TX0，
  见 §2.5 与 §7——DTS dai id 只是 ASoC 配对名）。
- `cs35l45@30/@31`（i2c10）：`cirrus,cs35l45` + `sound-name-prefix`（@30=
  cs35l45-rcv / @31=cs35l45-spk）。两个关键坑都在 DTS 注释里：
  ①**reset 极性**——主线 cs35l45.c 把 active 当"出复位"用（probe `set_value(1)`），
  本机 RCV 复位线必须配 active-high 才对（T4 修复，yodo 同款）；SPK 无复位线。
  ②IRQ 必须 `IRQF_TRIGGER_HIGH` 语义（驱动不看 DT flags，见 cs35l45.c irq_pol）。
  supply 照主线 binding（VP 域 = VSYS 同构重建出 vdd-batt）。
- `sound-name-prefix` 的另一半在内核 fork：`b52b99bfc6de` 把 prefix 折进
  wm_adsp 的 part 字符串 ⇒ @30/@31 各自请求 `cs35l45-{rcv,spk}-dsp1-spk-prot.*`
  per-amp 固件（无 prefix 时回落通用对）。

### 2.2 内核 config（fork config，全 =m 除注明）

`SND_SOC_SC8280XP`（机器）+ q6 DSP 全家（`SND_SOC_QDSP6` 族：q6apm/q6prm/
dais/clocks）+ `SND_SOC_CS35L45_I2C` + 四宏（rx/tx/va/wsa_macro）+
`SOUNDWIRE_QCOM` + `QCOM_PDR`/`QCOM_QMI_HELPERS` + **pd_mapper 内建**（=y，
用户态 pd-mapper 不需要装）+ `QRTR`/`QRTR_SMD`。

### 2.3 固件包（`firmware-meizu-meizu20`，tarball 制）

- `qcom/sm8550/meizu/adsp.*`（ADSP split 固件本体 + adspr/adspua/cdspr `.jsn`
  元数据；DTS `firmware-name` 双串指向）——ADSP 起不来，ASoC q6 栈全 defer。
- `cirrus/cs35l45-{spk,rcv}-dsp1-spk-prot.{wmfw,bin}` 6 件（stock spk 调音
  改名成主线 cs_dsp 标准名；per-amp 配对 harvested 自本机 stock vendor 镜像）。
  ⚠ 不同机型（如 Meizu 20 PRO）的 prot bin md5 不同，**勿混**。
- 刻意**不**发货的：用户态 DSP 文件树（hexagonfs /usr/share/qcom 形态）——
  在本机从未验证过，不盲目扩已知好基线。

### 2.4 设备包服务串（出声的编排核心，§3 展开）

| 文件（设备包内） | 装机路径 | 作用 |
|---|---|---|
| `meizu-amps-load.sh` + `meizu-amps.service` | /usr/lib/meizu20/ + systemd | autoprobe=0 → 定向 bind i2c10/888000 → CS35L45×2 上电；每 boot 重跑（bind 是 session-only） |
| `meizu-sndcard-bind.sh` + `meizu-sndcard-bind.service` | 同上 | **attach 地板**：验证重试环拉起卡（§4.3） |
| `meizu-audio-route.sh` + `meizu-audio-route.service` | 同上 | bind 重试兜底 + **钉直驱工作点** + 漂移重钉环（§5） |
| `MEIZU20-tplg.bin` | /usr/lib/firmware/qcom/sm8550/ | 自建拓扑（17148B；含 VA/TX0 修正，§2.5） |
| `MEIZU20.conf` + `HiFi.conf` | /usr/share/alsa/ucm2/Qualcomm/sm8550/ + conf.d 双 symlink | UCM2 卡/profile（§6） |
| `meizu20-spk-mono.pa` | /etc/pulse/default.pa.d/ | remap sink：媒体 L+R 全上主扬声器，听筒留通话（§5.5） |
| `meizu-spk-default.sh` + `meizu20-spk-default.desktop` | /usr/lib/meizu20/ + /etc/xdg/autostart/ | 默认 sink 自愈环（会话启动尾声有东西改回 Built-in，§5.5） |
| `80-device-meizu-meizu20.preset` | systemd system-preset | enable amps/sndcard-bind/audio-route/dsp-mount |

`preset` 里 `meizu-audio.service`（r9 时代的 WCD/SWR 有序加载链）保持
**disable**——那是挂起档遗产，现役不用，勿误 enable。

### 2.5 拓扑（tplg）与 BE intf：一个零刷机的关键认知

自建拓扑源 = audioreach-topology 的 m4（`meizu20.m4`，图 = MM1→SEC_MI2S +
MM2→RX_CODEC_DMA_RX_0 + MM3←TX_CODEC_DMA_TX_3）。录音轮破案（（六十九））钉死
一条主线栈通用规律：**DSP 侧的 LPAIF 接口类型/序号由拓扑"设备子图"参数决定，
DTS 的 dai id 只是内核 ASoC 层的配对名**。我们 VA 链最初逐字抄了
sm8550-hdk.dts 的 `TX_CODEC_DMA_TX_3`，DSP 就真被配到 RXTX 域 TX3（WCD TX 端口）
监听空端口——数据面全零 + 零错误。修法只换拓扑参数（`LPAIF_INTF_TYPE_RXTX/TX3`
→ `VA/TX0`），新旧 bin **全文件只差 2 字节**，零刷机（重载声卡栈读新拓扑）。
全内核在役 vamacro dai-link + 上游全部拓扑都是 VA 配 VA_CODEC_DMA_TX_0——
HDK 那条是与 WCD Capture 共用 cpu dai 的 outlier，抄模板前先横向对拍。

---

## 3. 声卡为什么起不来：probe 竞态全家族

这是本文最值钱的一节——「`no soundcards` 但 journal 干净、cs35l45 双 probe 成功」
这个矛盾形态，我们前后破案四轮，每轮揭一层：

### 3.1 第一层：udev 冷插拔缺口

`sound` 平台设备的 of:modalias 无 device_type，**udev 永远不会冷绑它**；LPI
pinctrl（`pinctrl-sm8550-lpass-lpi.ko`）也是——modules.alias 有条目、模块在位、
开机从不装载。⇒ 机器驱动的 probe 前置件全靠人工。

判读要点：**空的 deferred 条目 = driver core 供应商检查拦截（probe 回调从未
运行）**，与 `dev_err_probe` 带消息的 deferred 形态区分开——前者查
modules.alias/autoload，后者查依赖。

### 3.2 第二层：drivers_autoprobe 全局仲裁竞态

`/sys/bus/platform/drivers_autoprobe` 是**全局开关**，而本机 pas/touch/amps/
retimer/nfc 各服务的脚本都在拨它（0 → 定向 bind → 1）。`device_attach()`
（= `drivers_probe` 重扫路径）**honours 这个旗标**——任何一次 kick 落进别人
的 0 窗口就静默无效。r64 相机节点加入后 boot 工作量变化，把原本"碰巧活"的
时序骰子掷输了（潜伏竞态三代后才首发）。r63 曾在 unit 注释里写
"drivers_probe honours nothing"——**那是误判**，(七十) 实测推翻并勘正注释。
教训：**注释里的断言要跟着实验走**；竞态类"当时活了"不等于"每次活"。

### 3.3 第三层：suppress_bind_attrs 坑

主线 va-macro `.suppress_bind_attrs=true` ⇒ `/sys/bus/platform/drivers/
va_macro/` 下**bind 文件根本不存在**——unit 里的 `echo ... > bind` 永远失败，
又被 `|| true` 掩盖。上 boot 卡能出纯靠 autoprobe=1 窗口的时序运气。
正解 = **总线级强制探针** `echo 6d44000.codec > /sys/bus/platform/drivers_probe`
（bus_rescan_devices_helper，不查 autoprobe 闸——但注意 §3.2，它查的是
attach 时的旗标，所以依旧要 autoprobe=1 垫底）。判读要点：写 bind 前先
`ls` 确认文件存在；`|| true` 的清理脚本必须留日志。

### 3.4 第四层：ADSP 就绪窗 + deferred-probe 救不回

r47 的一次性三连 kick（autoprobe=1 + pinctrl→va→sound）**live 验证通过**，
但**每次真 boot 都失败**：guard 的 12ms 执行窗落在 ADSP 就绪前（GPR ready 在
fast boot 上还要 ~600ms；老 boot 形态 ADSP 就绪实测 75–290s 后），且撞进仲裁
链的 0 窗。而**内核 deferred-probe 自动重试救不回这三件**——实测卡死 20+ 分钟，
boot+11s 的 "deferred probe pending" dump 只列别的设备。meizu-audio-route 的
bind-retry 也救不回：machine probe 在 pinctrl/va 未绑定时**硬失败**。

### 3.5 解法形态：机制无关的验证重试环（r48，现役）

```sh
test -d /proc/asound/MEIZU20 && exit 0          # 幂等早退
i=0; while [ "$i" -lt 180 ]; do                  # 2s × 180 = ~6.5min 预算
    echo 1 > .../drivers_autoprobe               # 每轮强制（belt）
    echo 6e80000.pinctrl > .../drivers_probe     # 三连 kick（幂等，rc 忽略）
    ( va_macro 驱动未注册则 modprobe + 短轮询 )   # 注册窗防御
    echo 6d44000.codec > .../drivers_probe
    echo sound          > .../drivers_probe
    [ -d /proc/asound/MEIZU20 ] && exit 0
    usleep 2000000
done
exit 0                                           # 永远成功：route 是失败金丝雀
```

设计要点：①**验证而非盲发**——每轮查卡，命中即退；②**机制无关**——ADSP 窗、
旗标弹跳、未命名的 kick 落空全被"再试一轮"兜住；③**永远 exit 0**——失败报警
交给 meizu-audio-route（它 150×3s 重试后查不到卡会 failed，journal 一眼可见）；
④unit `After=` 整条仲裁链（pas→touch→amps→retimer→bind-nfc-haptics），链尾
之后没人再写旗标。实测：三连 boot 形态全救回，r48 后每次 boot 第 1 轮拉卡
（boot+3~10s——因为等的是 ADSP，不是盲等）。

---

## 4. ADSP 域：要什么、不要什么

### 4.1 必要件

ADSP（remoteproc）必须起来：固件（§2.3）+ 内核 pd_mapper（内建）+ PDR/QRTR。
机器驱动 probe 等 q6 组件，q6 组件等 APM/PRM 应答——这就是 §3.4 那个窗的物理
来源。ADSP 就绪的 signature = journal 里 PDR UP（`gprsvc:service:2:1/2:2` 注册）
+ `qcom-apm` 无 timeout。

### 4.2 GET_SPF_STATE 静默之谜（定谳 = 间歇，非域死）

审计时代（10-01）APM 对 GPR 查询零应答（5s timeout → q6prm 长期 defer → 四宏
静默失败 → 声卡永不注册），一度把整个域判死。插桩内核（r39，GPR RX 计数 +
apm_callback 打点）反证：**DSP 是应答型的**——开机 5.1s 主动推送 SPF state
（当时没人接线被丢）、q6prm probe 查询 µs 级应答 state=1；r38 boot 的超时
= 间歇相（候选机制 = ADSP 重启后 APM 装载竞速，**成因未定谳**，如实挂起）。
r39 顺手修了 `q6apm_is_adsp_ready()` 的 errno-as-bool wart（失败返回负
PTR_ERR 被 bool 化成 true = 假 ready），"绑定必真应答"。
⇒ 方法论：**"零响应"要先插桩证明 RX 通道死没死，再谈域死**；GPR 静态端口
无 announce 协议，服务不在 = 没人答，连拒绝都没有比收到 EFAILED 更深一层。

### 4.3 audiopd 会话守护：判负（出声不需要）

审计阶段头号假说 = "audio static PD（uAPM）启动缺 APPS 侧会话守护全家
（listener/文件服务/3MB 堆交割）"。B2 设备轮实测判负：**audiopd 会话在场，
GET_SPF_STATE 照旧 timeout**；且堆交割需 DT `memory-region`+`qcom,vmids`
（内核只在 vmcount>0 时交割）——整条 A2/A3 线对"出声"无因果。现役 rootfs
不跑 audiopd（`audiopd` 永不 enable 是纪律），出声照常。hexagonrpcd rootpd
仍随设备包装（传感器链 load-bearing），但它不是出声链的一环。

### 4.4 dsp-mount 是什么

`meizu-dsp-mount.service` 把活动槽的 dsp 分区只读挂到 /mnt/dsp（ Android OTA
交付件，永不写）。当前形态是录音/SPF 前沿的**接口预留**（若将来真跑 audiopd
文件服务，`-R /mnt -d adsp` 的 HexagonFS 别名全指向这里），无害常挂。

---

## 5. 工作点与响度域（直驱的账）

### 5.1 直驱 vs 过 DSP（杂音/不实时案定谳）

过 DSP 形态（`DACPCM Source=DSP_TX1`，r32–r40 时代）的机制账：流结束 DAPM
teardown → `cs_dsp_power_down` 清 booted/释放固件区 ⇒ 下次开流
`wm_adsp_early_event → boot_work` **全量重下 wmfw+bin（双 amp 各 ~2s）**——
`dsp->preloaded` 保态机制在位但 cs35l45 从不置位（preloader 控件无消费者）；
且 DSP 运行期 `PLL unlock` + `Unspecified global error condition (239)` 风暴。
用户症状全对齐：「音量键按好几次才响」= 每流 2–4s 固件下载静默窗（sink resume
高频撞上）；「杂音/雪花」= 错误风暴域。**直驱态实测：开流/停放全程内核音频
日志 = 0 条** ⇒ 实时性恢复 + 错误域根除。用户耳判正弦「非常干净」。

### 5.2 寄存器域（对拍 stock 的结论）

- 数字：`Digital PCM Volume` = −102.25dB + 0.25×N ⇒ **409 = 0dB**、
  **457 = +12dB = mainline 上限**；flyme 播放 dump 的 817（vendored 量纲）
  ≡ 409 raw + 模拟 3——**stock 工作点我们已到达**。
- 模拟：`Analog PCM Volume` = 10dB + 3dB×N（2-bit 域）⇒ **3 = 19dB = 硬件顶格**
  （flyme 同值）；RCV 模式锁 13dB（未用）。
- RCV（顶部小单元）**数字 409 直驱会触发 short-error 保护**（r30 前科）⇒ 现钉
  **251**（过载点的 55%）。SPK 409/3 + RCV 251/1 = 现役。
- 满幅正弦测试音**勿开最大音量**（余量是给音乐波峰的，不是给测试音的）；
  短路/PLL 监视窗常开。

### 5.3 响度封卷（r46）

滑条 100% ≡ flyme 100% 的校准：pulse 滑条是**立方映射**（实测滑条 60% =
sink 39322/65535 = 线性 0.216 ≈ −13.3dB）⇒ 只动垫片 `stream0.vol_ctrl0
MultiMedia1 Playback Volume` = **0.216 × 58981 = 12740**，功放值不动 ⇒
滑条全段连续可用且 100% 恰落在硬件安全上限，其上再无任何增益级。
（历轮「两个极端」的病根 = 只大跳固定点从不校准固定点；单旋钮校准一次解决。）

### 5.4 工作点回退纪律：四维全对

stream 垫片 / SPK 数字+模拟 / RCV 数字+模拟 是**一组耦合工作点**。杂音案的
S2「457→409 不治愈 ⇒ 工作点出局」判决后来发现有洞——只回了数字一维，垫片与
RCV 模拟从未回退，假阴性。四维全回后治愈（（六十八）改判）。
**单变量实验在耦合工作点上必须按"组"回退。**

顺带两个听判假象：**`aplay xxx.ogg` = 把压缩数据当裸 PCM 播 = 纯噪声**
（三轮 A/B"杂音"全是它；测音用 speaker-test 或真 wav）；满幅正弦 + 最大音量
= 主动制造过载（§5.2）。**听判类实验的信号源必须显式验证格式。**

### 5.5 听筒角色与默认 sink（r48/r49）

用户拍板「听筒当听筒」：RCV 物理受限（251），当立体声 L 声道天生太小 ⇒
pulse `module-remap-sink` 建 `meizu-spk`（媒体 L+R 双声道全映射主扬声器
slot1/R），设为默认；RCV 端静默留通话场景。两个坑：①**plasma 会话启动尾声**
（plasma-pa/设备预设一类）会把默认改回 Built-in——一次性 startup 竞速 ⇒
autostart 自愈环（每 2s 查/设，稳定 10s 退出，此后用户手动改动受尊重）；
②stock prot bin JSON 里 `mix_type: mono_mix` —— flyme 主扬声器本就单声道
混音，remap 形态反而是"对齐原厂听感"。

BT 小声+杂音随直驱一起痊愈（同属"过 DSP 时代 ADSP 会话域病"殃及，无独立
transport/codec 缺陷）——**系统级病态时代做的取证，结论要跟着病一起复核**。

### 5.6 fast-switch 场景调音：判负挂起（如实）

stock 的 10 个场景 delta（spk/rcv × music/game/movie/voice/music-out .txt）：
单行定长 CSV（63/64 字段），头部 `platform_id 1237` 与 prot wmfw 内嵌 JSON 全等
（halo 平台）⇒ CSPL/halo DSP 体系的场景 patch。移植三层全负：主线全树零消费；
stock DT `cirrus,fast-switch` = 下游私有用法；联网无 vendored 驱动源码。
**写入面 = 零**（设备实决定性）：`amixer -c0 controls` 73 个全是标准驱动控件，
wm_adsp 算法控件零暴露（Protect Lite 自主运行）⇒ 纯用户态切 csets 不可行；
内核移植需逆向无源码 CSPL DMEM 映射，性价比判负。**若复燃响度储备，唯一推荐
= pulse 侧 dynamics 插件（LADSPA 压缩+makeup，零内核零固件风险）。**

---

## 6. UCM 的三个坑（三次血泪换来的）

1. **控件蒸发态**（r25→r29）：UCM 激活后 `amixer` sees ZERO controls（卡活、
   PCM 活）。修法 = **摘到最小集**（只留 UseCase 定义），以后想回填任何一段
   （BootSequence csets / remap 库），回一件就开一次 UCM 数一遍控件——
   「加东西必须重验控件数」。
2. **一个映射 open 失败 = 整 profile 清零**（r26 / r39 / r42 三次复发）：
   pulse 对 verb 里每个映射走 alsa-lib UCM PCM 前缀探针
   （`plug:SLAVE='_ucmNNNN.hw:MEIZU20,2'`），裸 `hw:0,2` 能开而前缀路径开不了
   （ENOENT）⇒ n_mappings=0 ⇒ `Failed to find a working profile` ⇒ **整卡从
   桌面消失**。Mic 段两次被这个机制打出局。复活条件（写死在 HiFi.conf 注释）：
   数据面真出样本 + 前缀打开验证过 + **独立 verb**（不塞进 HiFi）。
3. **UCM csets 与 route 钉值互锁**：pulse 每次 enable profile 都重放
   EnableSequence——UCM 里钉什么，工作点就漂回什么。解法 = 两头同值（UCM
   EnableSequence 与 route 脚本钉同一组直驱值）+ route 的漂移重钉环
   （30s × 20 轮查/回钉数字域）。

另：**UCM 长名 = SMBIOS 派生，别乱改**。`Meizu-MEIZU20-m2381-meizu20` 不是
DTS model 派生——是 `snd_soc_set_dmi_name()` 用 UEFI SMBIOS 四字段
（vendor-product-version-board，来自 Mu m2381Pkg 的 PCD）拼的，设计目的就是
给 UCM 当配置目录名。⇒ conf.d 必须**双 symlink**（短名 `MEIZU20.conf` +
长名）；改卡短名不动长名，反之统一命名时 SMBIOS PCD 与 symlink 必须同批。

---

## 7. 录音腿：已通三层，断在物理域（如实边界）

**已通**（（六十六）–（六十九））：
1. capture PCM 枚举/open/FE-BE trigger 全通（五层破案链见 §2.5 + §8 方法论）；
2. **micb 补线**：主线 va-macro 是唯一声明 `vdd-micb` REGULATOR_SUPPLY 却
   routes 零连接的宏（sc7280 们的 vdd-micb-supply 是常开轨所以十年没暴露；
   我们是 gpio 门控轨，必须 DAPM route enable）⇒ fork 补
   `{"VA DMIC0..3", NULL, "vdd-micb"}` 四条（对拍 cs35l56/wm5110/msm8916-wcd
   同族形态）。上机实证 widget On + regulator consumer=1 + gpio hi 全绿；
3. **BE intf 修复**（§2.5）后 capture PCM **首次跑满长**——DSP 首次对录音流
   真正出数据流。

**未通**：样本仍全零（四值 MUX0 × DMIC0-3 扫描 + DEC0/1 MUX 全对、micb 链全绿、
APM/PRM 命令面健康零错误）⇒ 断点钉死在 **DMIC 物理输入域**。2026-10-19 Flyme
取证把边界钉死：stock 录音 = **SWR 域**（FDT 有 va_swr_master + swr-dmic×4 +
wcd938x TX slave；手拨 mixer 报 `Invalid DMIC Selection` = stock SWR 路径要
HAL AFE 会话语义，不是 mixer 值不对）。⇒ 录音复燃 = **WCD/SWR bring-up**
（与 §1.3 的 CLASH 挂起档同域）——这是 rebase 后的下一个音频里程碑，不是
小补丁。

判据与方法坑：**WAV 满长 ≠ 非零样本**（1.3MB 也可能全零，判据必须样本统计）；
`arecord` RUNNING 态 0 字节时 `-d` **不退**（挂死家族）⇒ 设备侧长探针一律
`timeout` 包裹；一次 boot 一次干净 probe；**风暴期禁 rmmod wcd**（整机冻结，
（十二）事故）。

---

## 8. 五层排查序（方法论总结，录音/通路两用）

```
① 卡实例化   —— LPI pinctrl attach？宏绑了？机器驱动 probe 前置件齐？
                （drivers_probe 总线探针；空 deferred 条目 = 供应商检查拦截）
② PCM 枚举   —— /proc/asound/card0/pcm*？capture 设备在不在？
③ open 层    —— EINVAL「no backend DAIs enabled」= DPCM FE→BE 断边
                （拓扑解包：graph 控件默认 off 的边，DFS 不走 → amixer 拨 on）
④ FE/BE 层   —— prepare/trigger 全过？（journalctl 窗口法：录音窗 vs 播放窗对拍
                APM 消息流 + PRM 投票；BE 命名 = "VA Capture" 之类）
⑤ 数据面     —— 样本统计（勿信 WAV 满长）；全零 → MUX 扫描 + micb 链 + AFE 域
⑥ BE intf    —— DSP 侧 LPAIF 类型/序号 = 拓扑设备子图参数（§2.5，零刷机可换）
```

---

## 9. 现役出货形态速查 + 验证清单

**验证四件**（新装镜像 / 改动后必跑）：
1. `test -d /proc/asound/MEIZU20`（卡注册；guard journal 应见 "attached (round N)"）；
2. `pactl info` 默认 sink = `meizu-spk`，profile = HiFi（Speaker）；
3. 开流/停放**内核音频日志 0 条**（`journalctl -k | grep -iE 'wm_adsp|PLL|cs35l45'`
   对照开流时间窗）；
4. route 日志钉值行（RCV=ASP_RX1 251/1, SPK=ASP_RX2 409/3, stream=12740）。

**已知非问题**（勿追）：开流瞬间 amp IRQ1 电平挂死计数（报错通路死，音频路径
不依赖；（七十一）降级为观察项）；boot 早期 `gpr_do_rx_callback: N callbacks
suppressed` 刷屏（GPR 噪音，污染 dmesg 环是已知副作用）；Elisa/flatpak 播放
卡顿 = Qt Multimedia 21ms 紧缓冲（上游议题，日用 mpv）。

**遗留队列**（全部优化/大后期档）：录音 WCD/SWR bring-up（§7）；fast-switch
响度储备 = pulse dynamics 插件路线（§5.6）；UCM 件逐件回填；BT 自启件；
横屏 swap（stock 有 speaker_swap_channel 现成旋钮线索）。

---

## 10. 资料地图（哪份事实在哪）

**公开（随仓可复刻）**：
- 设备包（服务串/UCM/tplg/route 脚本全文，注释即判词）：
  pmaports fork `device/downstream/device-meizu-meizu20/`；
- 固件清单与来源纪律（per-amp wmfw 契约/勿混 M2391 件）：同仓
  `device/downstream/firmware-meizu-meizu20/APKBUILD` 头注释；
- 内核 DTS（sound 节点/cs35l45 节点注释=坑册/VA dai-link）与
  `b52b99bfc6de`（per-amp part 字符串）、va-macro micb 补线：
  linux-mobile-ports fork 分支 `meizu20-t4b`；
- 兄弟篇：[BOOT-CHAIN-RE.md](BOOT-CHAIN-RE.md)（启动链）·
  [SUSPEND-S2IDLE.md](SUSPEND-S2IDLE.md)（睡眠/printk）·
  [PANEL-CORRUPTION.md](PANEL-CORRUPTION.md)（面板）·
  [DESIGN.md](DESIGN.md)（交付链）。

**私有（未公开，仅指路——结论已全部收进本文）**：audio-audit-20261001.md
（APM/GPR 审计主档）· experiment-log（五十七）–（七十二）（T 系列/日用化/
修复型全叙事）· audio-stock-align-next-20261005.md（T1/T2 工作点）·
micb-wiring-round-card-20261006.md（micb 配方）·
fast-switch-port-eval-20261007.md（判负全证）·
audio-first-recording-second-card-20261006.md（录音执行卡）。

**给平行移植线的一句话**：出声必需清单（§2）+ attach 编排（§3/§4）可直接照单
平移——内核/固件之外就这六七个文件；本文已公开成文，无需再等移交。
