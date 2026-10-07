#!/usr/bin/env python3
"""devsh.py — 经 USB 网络与设备 shell 通信（强制绑接口，绕开 TUN 代理 TUN 劫持）。

用法：
  devsh.py '<shell 命令>'                  # 单条命令（默认 172.16.42.1:23）
  devsh.py --port 22 --raw '<cmd>'         # 其它端口（22 需设备侧是 ssh，本工具不做 ssh 协议）
  环境：DEVSHELL_IF 指定接口名（默认自动挑带 172.16.42.x 的接口）

背景：宿主的策略路由把 172.16.42.1 指向 TUN 代理 TUN，普通 socket 打不到设备；
SO_BINDTODEVICE 直接绑定网卡可绕过（与 ping -I 同理）。
"""
import argparse
import os
import re
import socket
import subprocess
import sys
import time

HOST = "172.16.42.1"
PROMPT_WAIT = 1.2


def pick_iface() -> str:
    env = os.environ.get("DEVSHELL_IF")
    if env:
        return env
    out = subprocess.run(["ip", "-o", "-4", "addr", "show"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = re.match(r"\d+:\s+(\S+)\s+.*\b(172\.16\.42\.\d+)/", line)
        if m:
            return m.group(1)
    sys.exit("!! macchina: 找不到 172.16.42.x 接口（USB 网络没起来？）")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("command", nargs="?", default="echo DEVSH-OK; uname -a")
    ap.add_argument("--port", type=int, default=23)
    ap.add_argument("--wait", type=float, default=6.0, help="读取等待秒数")
    ap.add_argument("--iface", default=None)
    a = ap.parse_args()

    iface = a.iface or pick_iface()
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, iface.encode())
    s.settimeout(a.wait + 6)
    s.connect((HOST, a.port))
    s.sendall((a.command + "\necho __DEVSH_END__\n").encode())

    buf = b""
    deadline = time.time() + a.wait
    s.settimeout(1.0)
    while time.time() < deadline:
        try:
            chunk = s.recv(65536)
        except socket.timeout:
            continue
        except (ConnectionResetError, OSError) as e:
            print(f"!! 连接中断（设备大概率复位）: {type(e).__name__}", file=sys.stderr)
            break
        if not chunk:
            print("!! 对端关闭连接", file=sys.stderr)
            break
        buf += chunk
        if b"__DEVSH_END__" in buf:
            break
    s.close()

    text = buf.decode(errors="replace")
    text = text.replace("__DEVSH_END__", "")
    print(f"[iface={iface} port={a.port}]")
    print(text.rstrip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
