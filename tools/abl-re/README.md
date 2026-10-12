# abl-re 工具集（stock ABL 静态逆向复现脚本）

> 配套文档：[docs/BOOT-CHAIN-RE.md](../../docs/BOOT-CHAIN-RE.md)（魅族 20 / m2381
> 启动链逆向全集——结论、地址表、实验判读全在那里）。
> **本目录只有原创分析脚本，不含任何 stock 固件二进制或其派生转储**，分界理由见
> 该文档 §8。

## 脚本清单

| 脚本 | 用途 | 依赖 |
|---|---|---|
| `extract_fv.py` | 定向解包：ELF(PIL) → UEFI FV → FFS → section（含 LZMA GUIDed、嵌套 FV），导出 PE32 模块 | 标准库 |
| `extract_fv_raw.py` | 全镜像扫 `_FVH`，把**每一段（含 RAW/UI）**都导出（找回原厂面板 XML 这类 freeform 段用） | 标准库 |
| `unwrap-qcom-pil.py` | 通用兜底：QCOM PIL 包装（xbl/abl 这类 ELF）两级解包 + gzip/zlib/bz2/裸 LZMA 全试 | 标准库 |
| `xref.py` | AArch64 PE 的 ADRP+ADD 字符串引用反查 + .data 绝对指针扫描，按函数分组 | capstone |
| `disfunc.py` | 函数级反汇编，ADRP+ADD 自动注解字符串内容，bl 标调用 | capstone |

## 用法（对象 = 你自己设备的 abl 分区镜像）

```bash
pip install capstone

# 1) 解出 LinuxLoader PE（魅族 20 / Flyme 12.6 上 = 601KB AArch64 PE32+）
python3 extract_fv.py abl_a.img out
#    out/mod*.efi 即全量逻辑本体；.text 的 VA = 文件偏移（ImageBase=0）

# 2) 字符串普查（DEBUG 串即路标：先抓串，再反查引用定位函数）
strings -a -t x -n 6 out/mod*.efi > linuxloader-strings.txt

# 3) 引用反查（xref）
echo "0x37934 GetBoardDtMatch" | python3 xref.py out/mod001_xxx.efi

# 4) 函数反汇编（disfunc；缺省镜像 = /tmp/abl-re/out/ 下第一个 .efi）
python3 disfunc.py 0x37934 0x38000 out/mod001_xxx.efi

# 5) 其他分区：xbl/uefi 用 unwrap-qcom-pil.py；要 RAW 段用 extract_fv_raw.py
```

地址前提：`disfunc.py` / `xref.py` 写死了 `TEXT_OFF=0x1000`、`TEXT_SZ=0x75000`
与 `.data` 范围（本机 ABL 的布局）。**其他机型/固件代次先复核这几个值再用**；
同代 Flyme 12.6 的件可与 BOOT-CHAIN-RE.md 的地址表逐字对拍。

vbmeta/分区 AVB 结构解析直接用 `avbtool info_image`；boot 镜像解包用 AOSP
`unpack_bootimg`。
