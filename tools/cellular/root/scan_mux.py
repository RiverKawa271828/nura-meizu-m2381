#!/usr/bin/env python3
"""Scan WDS Bind Mux Data Port combinations (nura adaptation of mux_matrix)."""
import struct, sys
sys.path.insert(0, "/root")
from modem_daemon import Modem

WDS = 1
EP = {0: "UNKNOWN", 1: "HSIC", 2: "HSUSB", 3: "PCIE", 4: "EMBEDDED", 5: "BAM_DMUX", 6: "ETHERNET"}


def tlv(t, v):
    return struct.pack("<BH", t, len(v)) + v


def u32(v):
    return struct.pack("<I", v)


m = Modem()
print("WDS port:", m.ports.get(WDS), flush=True)

muxes = list(range(1, 9)) + [0xF0, 0xF1, 0xF8, 0xF9]
eps = [(4, 1), (4, 0), (5, 0)]
hits = []
for ep, iface in eps:
    for mux in muxes:
        for extra in (tlv(0x13, u32(1)), b""):
            body = tlv(0x10, u32(ep) + u32(iface)) + tlv(0x11, bytes([mux])) + extra
            res, err = m.call(WDS, 0x00A2, body, timeout=4)
            tag = "%s(%d)/if%d mux=0x%02X %s" % (EP.get(ep, "?"), ep, iface, mux, "t13" if extra else "not13")
            if res and res[0] == 0:
                print("  *** ACCEPT: %s -> %s" % (tag, res), flush=True)
                hits.append(tag)
            else:
                print("  %s -> %s %s" % (tag, res, err or ""), flush=True)
print("=== hits:", hits or "NONE", flush=True)
