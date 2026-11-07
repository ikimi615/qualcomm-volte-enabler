#!/usr/bin/env python3
"""
Safely enable hardware IMS in Qualcomm modem EFS (/nv/item_files/ims/IMS_enable).
Commits EFS journal to flash memory and re-enables read-only lock.
"""

import sys
import base64
import json
import socket

PORT = 9999

class DiagClient:
    def __init__(self, port=PORT):
        try:
            self.s = socket.create_connection(("127.0.0.1", port), timeout=60)
        except ConnectionRefusedError:
            print(f"[!] Error: Cannot connect to 127.0.0.1:{port}.")
            print("[!] Please ensure 'qcom-efsd' is running on device and forwarded via:")
            print(f"    adb forward tcp:{port} localabstract:qcom_efsd_dbg")
            print("[!] Alternatively, run the all-in-one script: bash scripts/auto_enable_volte.sh")
            sys.exit(1)
        self.buf = b""

    def cmd(self, **kw):
        self.s.sendall((json.dumps(kw) + "\n").encode())
        while b"\n" not in self.buf:
            chunk = self.s.recv(1 << 20)
            if not chunk:
                raise RuntimeError("Modem daemon closed connection")
            self.buf += chunk
        line, self.buf = self.buf.split(b"\n", 1)
        return json.loads(line)

def main():
    c = DiagClient()
    c.cmd(cmd="open")
    
    # Read before
    r = c.cmd(cmd="read", path="/nv/item_files/ims/IMS_enable")
    val = base64.b64decode(r.get("data", "")) if r.get("data") else b""
    print(f"[*] Current /nv/item_files/ims/IMS_enable value: {val.hex() or 'empty'}")

    if val == b"\x01":
        print("[+] /nv/item_files/ims/IMS_enable is already 0x01 (Hardware IMS Enabled).")
        c.cmd(cmd="close")
        return

    # Disable read-only mode in daemon
    c.cmd(cmd="readonly", on=False)
    print("[*] Unlocked EFS write access.")

    # Write 0x01
    w_res = c.cmd(cmd="write", path="/nv/item_files/ims/IMS_enable", data=base64.b64encode(b"\x01").decode(), item=True)
    print(f"[*] Write result: {w_res}")

    # Commit EFS journal
    s_res = c.cmd(cmd="sync")
    print(f"[*] Sync result: {s_res}")

    # Relock read-only mode
    c.cmd(cmd="readonly", on=True)

    # Verify
    r_after = c.cmd(cmd="read", path="/nv/item_files/ims/IMS_enable")
    val_after = base64.b64decode(r_after.get("data", "")) if r_after.get("data") else b""
    print(f"[+] Verified IMS_enable after write: {val_after.hex()}")

    c.cmd(cmd="close")
    if val_after == b"\x01":
        print("[+] SUCCESS: Hardware IMS successfully enabled in modem NV! Please reboot device.")
    else:
        print("[-] FAILED: Value not updated.")
        sys.exit(1)

if __name__ == "__main__":
    main()
