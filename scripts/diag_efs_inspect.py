#!/usr/bin/env python3
"""
Inspect Qualcomm Modem EFS configuration via DIAG protocol.
Backs up IMS, Policyman, and MCFG configurations without QPST/Windows.
"""

import sys
import os
import base64
import json
import socket

PORT = 9999

class DiagClient:
    def __init__(self, port=PORT):
        self.s = socket.create_connection(("127.0.0.1", port), timeout=60)
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
    backup_dir = sys.argv[1] if len(sys.argv) > 1 else "./efs_backup"
    os.makedirs(backup_dir, exist_ok=True)
    
    c = DiagClient()
    info = c.cmd(cmd="open")
    print(f"[*] DIAG Connected: transport={info.get('transport')}, subsys={info.get('subsys')}, readonly={info.get('readonly')}")

    # 1. Read IMS_enable
    r = c.cmd(cmd="read", path="/nv/item_files/ims/IMS_enable")
    val = base64.b64decode(r.get("data", "")) if r.get("data") else b""
    print(f"[!] /nv/item_files/ims/IMS_enable: len={len(val)}, hex={val.hex()} ({'ENABLED' if val == b'\\x01' else 'DISABLED'})")

    # 2. Backup essential dirs
    for d in ["/nv/item_files/ims", "/policyman", "/nv/item_files/mcfg"]:
        local_subdir = os.path.join(backup_dir, os.path.basename(d))
        os.makedirs(local_subdir, exist_ok=True)
        res = c.cmd(cmd="ls", path=d)
        for e in res.get("entries", []):
            fpath = d + "/" + e["name"]
            try:
                fr = c.cmd(cmd="read", path=fpath)
                data = base64.b64decode(fr.get("data", ""))
                with open(os.path.join(local_subdir, e["name"]), "wb") as f:
                    f.write(data)
            except Exception as err:
                pass
        print(f"[*] Backed up {d} -> {local_subdir}")

    c.cmd(cmd="close")
    print("[+] Inspection and backup completed.")

if __name__ == "__main__":
    main()
