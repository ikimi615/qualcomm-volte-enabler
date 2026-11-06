# Qualcomm VoLTE Enabler (No QPST / macOS & Linux Friendly)

[![Qualcomm](https://img.shields.io/badge/Qualcomm-Snapdragon-blue.svg)](https://www.qualcomm.com/)
[![Android](https://img.shields.io/badge/Android-Marshmallow%20to%2015-green.svg)](https://source.android.com/)
[![LineageOS](https://img.shields.io/badge/LineageOS-22.2%20(Android%2015)-orange.svg)](https://lineageos.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English](#english) | [中文说明](#中文说明)

---

## English

### 📌 Overview
**Qualcomm VoLTE Enabler** is an open-source automation toolkit and [Google Antigravity](https://github.com/) Agent Skill that enables **Voice over LTE (VoLTE)** and **IMS HD Calling** on Qualcomm Snapdragon devices without requiring Windows, QPST, or PDC tools.

This project was developed and battle-tested on the **BlackBerry Key2 (`athena`, Snapdragon SDM660)** running unofficial **LineageOS 22.2 (Android 15)** after carriers (such as China Unicom, AT&T, and T-Mobile) decommissioned legacy 2G/3G Circuit-Switched (CSFB) fallback networks.

### ❓ The Problem
When 2G/3G networks are retired:
1. Devices can still access **4G LTE mobile data**, but all incoming and outgoing **phone calls fail immediately** (dropping to "No Service" or "Call Ended" within 200ms).
2. Dialing `*#*#4636#*#*` -> Phone Info reveals:
   - `IMS Registration: Not Registered`
   - `Voice Network Type: Unknown` / `LTE Voice: Not Supported`
3. The underlying Qualcomm baseband modem has disabled IMS hardware services (`/nv/item_files/ims/IMS_enable = 0x00`).

### 🚀 Key Features
- **Zero Windows / QPST Dependency**: Operates entirely over ADB and Linux/macOS command lines using the DIAG protocol and direct NV item manipulation.
- **Baseband EFS NVRAM Injection**: Directly flips `/nv/item_files/ims/IMS_enable` to `0x01`.
- **Carrier Database Sync**: Configures `qcril.db` with correct MBN mapping rules.
- **Boot Persistence**: Deploys an automated Magisk/KernelSU post-fs-data daemon (`fix_volte.sh`) to lock ICCID cache and persist carrier configs across reboots.

### 📋 Prerequisites
- Rooted Qualcomm Snapdragon device (Magisk, KernelSU, or APatch).
- USB Debugging enabled via ADB.
- Python 3.7+ installed on host machine.

### 🛠️ Quick Start

#### 1. Inspect Current Baseband IMS State
```bash
python3 scripts/diag_efs_inspect.py
```

#### 2. Enable VoLTE & Write IMS Configuration
```bash
python3 scripts/enable_volte_efs.py
```

#### 3. Reboot & Verify
```bash
adb reboot
# After reboot:
bash scripts/verify_volte_status.sh
```

---

## 中文说明

### 📌 项目简介
**Qualcomm VoLTE Enabler** 是一个面向高通骁龙（Qualcomm Snapdragon）平台的免 QPST、跨平台（支持 macOS 与 Linux）VoLTE 修复工具集与 Antigravity AI Agent 技能库。

本项目源于在 **BlackBerry Key2（athena，骁龙 660）** 运行第三方 **LineageOS 22.2（Android 15）** 上的实机调试成果。在全国运营商（如中国联通）大范围清退 2G（GSM）与 3G（WCDMA）网络后，传统电路域回落（CSFB）失效，通过本项目成功恢复了纯 4G LTE 下的高清 VoLTE 通话与 IMS 注册。

### ❓ 解决的问题
* 手机能正常使用 4G 移动数据上网，但**完全无法拨打或接听普通电话**（拨号后立即闪退或提示通话结束）。
* 拨打 `*#*#4636#*#*` 进入手机信息查看：
  * **IMS 状态：未注册**
  * **LTE 语音通话：不可用 / 不支持该付款方式**
* 高通基带硬件底层未开启 IMS 实体支持（`/nv/item_files/ims/IMS_enable = 0x00`）。

### 🚀 核心原理
1. **基带 EFS NV 注入**：利用高通 DIAG 协议与 QMI 接口，直接对 modem 分区 NVRAM 写入 `IMS_enable = 0x01`。
2. **QCRIL 运营商库规则修正**：在 `/data/vendor/radio/qcril.db` 中绑定运营商（如中国联通 MCC `460` MNC `01`）与 `VoLTE-CU` 基带 MBN 固件映射。
3. **ICCID 与开机自启守护**：通过 Magisk `post-fs-data.d` 部署开机保护脚本，锁定 SIM 标识缓存（`chattr +i`），防止重启后基带复位。

### 📦 目录结构
```text
qualcomm-volte-enabler/
├── README.md                     # 本说明文档
├── SKILL.md                      # Antigravity Agent Skill 规范文件
├── scripts/
│   ├── diag_efs_inspect.py       # EFS 与 IMS 状态诊断脚本
│   ├── enable_volte_efs.py       # EFS 自动写入与 VoLTE 激活脚本
│   └── verify_volte_status.sh    # 电话与 IMS 注册状态验证脚本
└── references/
    └── troubleshooting.md        # 疑难排查与频段冲突解决指南
```

### ⚠️ 免责声明
本工具涉及对底层高通基带 EFS 分区的读取与写入。在操作前，脚本会自动备份相关 NV 项。请严格按照操作流程执行，作者不对因误操作造成的设备异常负责。
