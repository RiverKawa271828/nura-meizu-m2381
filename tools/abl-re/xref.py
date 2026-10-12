#!/usr/bin/env python3
"""AArch64 PE 模块 xref 工具：找 ADRP+ADD 引用的字符串地址，按函数分组

用法: echo "0x37934 GetBoardDtMatch" | python3 xref.py [<image.efi>]
缺省镜像 = /tmp/abl-re/out/ 下第一个 .efi（extract_fv.py 的产物）。
注意: 假设 .text 的 VA=文件偏移（ImageBase=0）；TEXT_OFF/TEXT_SZ/.data 范围按
本机 ABL（Flyme 12.6, LinuxLoader 601KB）写死，其他代次先复核。
"""
import struct, sys, collections, bisect, glob
from capstone import *

if len(sys.argv) > 1:
    img = sys.argv[1]
else:
    hits = sorted(glob.glob("/tmp/abl-re/out/*.efi"))
    if not hits:
        sys.exit("usage: echo 'VA name' | xref.py <image.efi>")
    img = hits[0]
d = open(img, "rb").read()
TEXT_OFF, TEXT_SZ = 0x1000, 0x75000
text = d[TEXT_OFF:TEXT_OFF + TEXT_SZ]

md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
md.detail = False
insns = list(md.disasm(text, TEXT_OFF))
print(f"指令数: {len(insns)}", file=sys.stderr)

# 函数起点: pacibsp / stp x29,x30 前导
func_starts = set()
for ins in insns:
    if ins.mnemonic == "pacibsp":
        func_starts.add(ins.address)
    elif ins.mnemonic == "stp" and ins.op_str.startswith("x29, x30, [sp"):
        func_starts.add(ins.address)

fs = sorted(func_starts)
def func_of(a):
    i = bisect.bisect_right(fs, a) - 1
    return fs[i] if i >= 0 else 0

# ADRP+ADD 对
adrp_reg = {}  # reg -> (page_base, addr_of_adrp)
xrefs = collections.defaultdict(list)  # str VA -> [call sites]
for ins in insns:
    if ins.mnemonic == "adrp":
        ops = ins.op_str.split(", ")
        if len(ops) == 2 and ops[1].startswith("#"):
            adrp_reg[ops[0]] = (int(ops[1][1:], 0), ins.address)
    elif ins.mnemonic == "add":
        p = ins.op_str.split(", ")
        if len(p) == 3 and p[1] in adrp_reg and p[2].startswith("#"):
            page, _site = adrp_reg[p[1]]
            xrefs[page + int(p[2][1:], 0)].append(ins.address)
    # bl 会破坏 adrp 跟踪近似，忽略（ADD 通常紧跟 ADRP）

def xref_for(va):
    """精确 VA + 同页（用于对齐差异）"""
    hits = list(xrefs.get(va, []))
    if not hits:
        for t, sites in xrefs.items():
            if (t >> 3) == (va >> 3):  # 8 字节窗口
                hits += sites
    return sorted(set(hits))

# .data 中的绝对指针引用
def data_ptr_refs(va):
    out = []
    for off in range(0x76000, 0x76000 + 0x1e000 - 8):
        v, = struct.unpack("<Q", d[off:off+8])
        if v == va:
            out.append(off)
    return out

if __name__ == "__main__":
    targets = {}
    for line in sys.stdin:
        va, name = line.split(None, 1)
        targets[int(va, 16)] = name.strip()
    for va, name in sorted(targets.items()):
        hits = xref_for(va)
        ptrs = data_ptr_refs(va)
        print(f"\n=== {name} @ {va:#x} ===")
        for h in hits:
            print(f"  xref code @ {h:#x} (in func {func_of(h):#x})")
        for p in ptrs:
            print(f"  xref .data ptr @ {p:#x}")
