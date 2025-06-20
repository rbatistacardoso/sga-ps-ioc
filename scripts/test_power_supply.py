#!/usr/bin/env python3
"""
Sorensen SGI Series CLI – SCPI over TCP
(c) 2025 – MIT license

Usage:
  python3 sgi_cli.py [ip] [port] [--eol CR|LF|CRLF|LFCR]

Default IP:   192.168.0.200
Default Port: 9221
Default EOL:  CRLF

Implements:
  - Measure: Voltage, Current, Power
  - Control: Output ON/OFF, Remote/Local mode
"""

import socket
import argparse

CMDS = {
    "1": "MEAS:VOLT?",
    "2": "MEAS:CURR?",
    "3": "MEAS:POW?",
    "4": "OUTP:STAT 1",
    "5": "OUTP:STAT 0",
    "6": "SYST:LOCAL 0",  # Remote
    "7": "SYST:LOCAL 1",  # Local
    "8": "SOUR:CURR 1",
    "9": "SOUR:CURR?",
}

MENU = """
--- Sorensen SGI CLI ---
 1) Measure Voltage           4) Output  ON
 2) Measure Current           5) Output  OFF
 3) Measure Power             6) Remote (SYST:LOCAL 0)
 7) Local  (SYST:LOCAL 1)     8) Set Current (SOUR:CURR 1)
 9) Get Current (SOUR:CURR?   0) Exit
Choose> """


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("host", nargs="?", default="192.168.1.233")
    parser.add_argument("port", nargs="?", type=int, default=9221)
    parser.add_argument("--eol", choices=["CR", "LF", "CRLF", "LFCR"], default="CRLF")
    return parser.parse_args()


def get_terminator(eol):
    return {
        "CR": b"\r",
        "LF": b"\n",
        "CRLF": b"\r\n",
        "LFCR": b"\n\r"
    }[eol]


def send(sock, cmd, terminator):
    sock.sendall(cmd.encode() + terminator)

    # Read until LF seen
    data = bytearray()
    while True:
        chunk = sock.recv(1024)
        if not chunk:
            break
        data.extend(chunk)
        if data.endswith(b"\n"):
            break

    return data.decode(errors="replace").strip("\r\n")


def main():
    args = parse_args()
    tx_term = get_terminator(args.eol)

    print(f"Connecting to {args.host}:{args.port} with terminator {args.eol} …")
    try:
        with socket.create_connection((args.host, args.port), timeout=3) as s:
            while True:
                choice = input(MENU).strip()
                if choice == "0":
                    print("Bye.")
                    break
                if choice not in CMDS:
                    print("Invalid choice.")
                    continue
                try:
                    cmd = CMDS[choice]
                    response = send(s, cmd, tx_term)
                    print(f"> {cmd}  →  {response}")
                except Exception as e:
                    print("⚠ Communication error:", e)
                    break
    except Exception as e:
        print(f"⚠ Could not connect: {e}")


if __name__ == "__main__":
    main()

