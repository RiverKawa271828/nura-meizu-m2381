#!/usr/bin/env python3
"""devpull.py — 从设备拉文件到宿主（绕过宿主 TUN 代理：监听套接字绑 USB 网卡）。

设备侧配合：busybox nc 172.16.42.2 <PORT> < <设备上的文件>

用法：devpull.py <输出文件> [--port 5555] [--iface <名>]
"""
import argparse
import os
import re
import socket
import subprocess
import sys
import time

HOST_IP = "172.16.42.2"


def pick_iface() -> str:
    env = os.environ.get("DEVSHELL_IF")
    if env:
        return env
    out = subprocess.run(["ip", "-o", "-4", "addr", "show"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = re.match(r"\d+:\s+(\S+)\s+.*\b(172\.16\.42\.\d+)/", line)
        if m:
            return m.group(1)
    sys.exit("!! 找不到 172.16.42.x 接口")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--port", type=int, default=5555)
    ap.add_argument("--iface", default=None)
    ap.add_argument("--timeout", type=float, default=180.0)
    a = ap.parse_args()

    iface = a.iface or pick_iface()
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, iface.encode())
    srv.bind((HOST_IP, a.port))
    srv.listen(1)
    srv.settimeout(a.timeout)
    print(f"[listening on {HOST_IP}:{a.port} iface={iface}] waiting for device...", flush=True)

    conn, addr = srv.accept()
    conn.settimeout(30)
    total = 0
    t0 = time.time()
    with open(a.out, "wb") as f:
        while True:
            try:
                chunk = conn.recv(1 << 20)
            except socket.timeout:
                break
            if not chunk:
                break
            f.write(chunk)
            total += len(chunk)
    conn.close()
    srv.close()
    dt = time.time() - t0
    print(f"[got {total} B in {dt:.1f}s -> {a.out}]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
