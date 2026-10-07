#!/usr/bin/env python3
"""devpush.py — 从宿主推文件到设备（绕过宿主 TUN 代理：连接套接字绑 USB 网卡）。

与 devpull.py 对称。设备侧配合：busybox nc -l -p <PORT> > <设备上的文件>

用法：devpush.py <本地文件> [--port 9] [--iface <名>]
"""
import argparse
import os
import re
import socket
import subprocess
import sys

HOST = "172.16.42.1"


def pick_iface() -> str:
    env = os.environ.get("DEVSHELL_IF")
    if env:
        return env
    out = subprocess.run(["ip", "-o", "-4", "addr", "show"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = re.match(r"\d+:\s+(\S+)\s+.*\b(172\.16\.42\.\d+)/", line)
        if m:
            return m.group(1)
    sys.exit("!! 找不到 172.16.42.x 接口（USB 网络没起来？）")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--port", type=int, default=9)
    ap.add_argument("--iface", default=None)
    a = ap.parse_args()

    iface = a.iface or pick_iface()
    data = open(a.src, "rb").read()
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, iface.encode())
    s.settimeout(120)
    s.connect((HOST, a.port))
    view = memoryview(data)
    while view:
        n = s.send(view[:1048576])
        view = view[n:]
    s.shutdown(socket.SHUT_WR)
    # 吃掉设备侧回显/等待对端关闭
    s.settimeout(5)
    try:
        while s.recv(65536):
            pass
    except socket.timeout:
        pass
    s.close()
    print(f"pushed {len(data)} bytes -> {HOST}:{a.port}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
