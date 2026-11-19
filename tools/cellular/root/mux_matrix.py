#!/usr/bin/env python3
"""Try endpoint type / interface combinations for WDS Bind Mux Data Port."""
import struct, sys, time
sys.path.insert(0, "/root")
from modem_daemon import Modem

WDS = 1


def tlv(t, v):
    return struct.pack("<BH", t, len(v)) + v


def u32(v):
    return struct.pack("<I", v)


m = Modem()
print("WDS port:", m.ports.get(WDS))

EP = {0: "UNKNOWN", 1: "HSIC", 2: "HSUSB", 3: "PCIE", 4: "EMBEDDED", 5: "BAM_DMUX", 6: "ETHERNET"}
for ep in (4, 2, 3):
    for iface in (0, 1):
        body = tlv(0x10, u32(ep) + u32(iface)) + tlv(0x11, bytes([0xF0])) + tlv(0x13, u32(1))
        res, err = m.call(WDS, 0x00A2, body, timeout=8)
        print("  ep=%-9s(%d) iface=%d -> %s %s" % (EP.get(ep, "?"), ep, iface, res, err or ""))
        if res and res[0] == 0:
            print("    *** accepted ***")
            sys.exit(0)
        time.sleep(2)
