#!/usr/bin/env python3
"""反汇编指定地址段，ADRP+ADD 引用解析为字符串内容

用法: python3 disfunc.py <start_hex> [end_hex] [<image.efi>]
缺省镜像 = /tmp/abl-re/out/ 下第一个 .efi（extract_fv.py 的产物）。
注意: 假设 .text 的 VA=文件偏移（ImageBase=0）；TEXT_OFF/TEXT_SZ 按本机 ABL
（Flyme 12.6, LinuxLoader 601KB）写死，其他代次先复核这两个值。
"""
import sys, os
from capstone import *

img, start, end = None, None, None
for a in sys.argv[1:]:
    try:
        v = int(a, 16)
        if start is None:
            start = v
        elif end is None:
            end = v
    except ValueError:
        img = a
if img is None and os.path.isdir("/tmp/abl-re/out"):
    efi = [x for x in os.listdir("/tmp/abl-re/out") if x.endswith(".efi")]
    if efi:
        img = os.path.join("/tmp/abl-re/out", efi[0])
if img is None or start is None:
    sys.exit("usage: disfunc.py <start_hex> [end_hex] [<image.efi>]")

d = open(img, "rb").read()
TEXT_OFF, TEXT_SZ = 0x1000, 0x75000
text = d[TEXT_OFF:TEXT_OFF + TEXT_SZ]

def get_str(va, maxlen=80):
    if 0x1000 <= va < len(d):
        e = d.find(b"\x00", va, va + maxlen)
        if e < 0: e = va + maxlen
        s = d[va:e]
        if s and all(32 <= c < 127 or c in (9, 10, 13) for c in s):
            return s.decode()
    return None

md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
code = text[start - TEXT_OFF: (end - TEXT_OFF) if end else len(text)]
adrp_reg = {}
for ins in md.disasm(code, start):
    ann = ""
    if ins.mnemonic == "adrp":
        p = ins.op_str.split(", ")
        if len(p) == 2 and p[1].startswith("#"):
            adrp_reg[p[0]] = int(p[1][1:], 0)
    elif ins.mnemonic == "add":
        p = ins.op_str.split(", ")
        if len(p) == 3 and p[1] in adrp_reg and p[2].startswith("#"):
            va = adrp_reg[p[1]] + int(p[2][1:], 0)
            s = get_str(va)
            ann = f"  ; ={va:#x}" + (f' "{s}"' if s else "")
    elif ins.mnemonic == "bl":
        ann = f"  ; -> {ins.op_str}"
    print(f"{ins.address:#08x}  {ins.mnemonic:8} {ins.op_str}{ann}")
