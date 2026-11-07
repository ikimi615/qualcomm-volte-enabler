# Qualcomm VoLTE Enabler (No QPST / macOS & Linux Friendly)

[![GitHub Repo](https://img.shields.io/badge/GitHub-ikimi615%2Fqualcomm--volte--enabler-181717.svg?logo=github)](https://github.com/ikimi615/qualcomm-volte-enabler)
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

```
       +-------------------------------------------------------+
       |           Qualcomm VoLTE Enabler Workflow            |
       +-------------------------------------------------------+
                                   |
                     [ 1. Check Root & Telephony ]
                                   |
                [ 2. Push & Run aarch64 qcom-efsd ]
                                   |
             [ 3. ADB Forward abstract socket -> :9999 ]
                                   |
       +---------------------------+---------------------------+
       |                                                       |
[ Inspect & Backup NV ]                                 [ Write EFS NV ]
/nv/item_files/ims/                                     IMS_enable = 0x01
/policyman/                                             Commit EFS Journal
/nv/item_files/mcfg/                                    Relock Read-Only
       |                                                       |
       +---------------------------+---------------------------+
                                   |
                     [ 4. Reboot Qualcomm Modem ]
                                   |
                   [ 5. VoLTE IMS HD Calling OK! ]
```

### ❓ The Problem
When 2G/3G networks are retired:
1. Devices can still access **4G LTE mobile data**, but all incoming and outgoing **phone calls fail immediately** (dropping to "No Service" or "Call Ended" within 200ms).
2. Dialing `*#*#4636#*#*` -> Phone Info reveals:
   - `IMS Registration: Not Registered`
   - `Voice Network Type: Unknown` / `LTE Voice: Not Supported`
3. The underlying Qualcomm baseband modem has disabled IMS hardware services (`/nv/item_files/ims/IMS_enable = 0x00`).

### 🚀 Key Features
- **Zero Windows / QPST Dependency**: Operates entirely over ADB and Linux/macOS command lines using the DIAG protocol and direct NV item manipulation.
- **One-Click Automation**: Run `bash scripts/auto_enable_volte.sh` to automatically check root, start the daemon, apply properties, and update baseband NVRAM.
- **Baseband EFS NVRAM Injection**: Directly flips `/nv/item_files/ims/IMS_enable` to `0x01`.
- **Carrier Database Sync**: Configures `qcril.db` with correct MBN mapping rules.
- **Boot Persistence**: Deploys an automated Magisk/KernelSU post-fs-data daemon to lock ICCID cache and persist carrier configs across reboots.
- **Antigravity Skill Native**: Drop into `.agents/skills/` or `~/.gemini/config/skills/` to enable your AI coding agent to diagnose and fix VoLTE autonomously.

### 📋 Prerequisites
- **Root Access Required**: Magisk, KernelSU, or APatch (UID 0 / `su`).
- USB Debugging enabled via ADB.
- Python 3.7+ installed on host machine (macOS / Linux / WSL).

### ❓ FAQ: Can I use this on a non-rooted / stock ROM Key2?
**No. Root access is strictly required.**
- **Why Root is mandatory**: Android's Linux kernel and SELinux policies strictly prevent non-root shell (UID 2000) or regular apps from opening `/dev/diag` character devices, writing to baseband NVRAM, or altering `persist.dbg.*` system telephony properties.
- **Why secret dial codes don't work**: On stock BlackBerry Key2 firmware (Android 8.1), TCL/BlackBerry completely stripped and patched out all Qualcomm engineering dial codes (e.g., `*#*#717717#*#*`). A standard USB DIAG COM port cannot be exposed without root.
- **What non-rooted users should do**:
  1. **Recommended Path**: Unlock the bootloader and flash LineageOS + Magisk. Once rooted, this toolkit will fix VoLTE in one click.
  2. **Stock China Retail Variant (BBF100-4)**: If you are running stock unrooted BBF100-4, ensure the SIM card is in **Slot 1 (primary slot)**, create an APN with name `IMS` and APN type `ims`, and check if `*#*#4636#*#*` allows toggling "VoLTE Provisioned".
  3. **Stock Overseas Variants (BBF100-2, BBF100-6)**: These firmwares lack domestic carrier VoLTE MBN authorizations in hardware NV. Bootloader unlocking and root are the only reliable way to enable VoLTE.

### 🛠️ Quick Start

#### Method A: One-Click Automated Fix (Recommended)
Connect your rooted Qualcomm phone via USB and simply run:
```bash
git clone https://github.com/ikimi615/qualcomm-volte-enabler.git
cd qualcomm-volte-enabler
bash scripts/auto_enable_volte.sh
```
Follow the prompt to reboot your phone, and VoLTE will be active.

#### Method B: Step-by-Step Manual Run

1. **Start the baseband DIAG daemon**:
   ```bash
   adb push bin/qcom-efsd /data/local/tmp/qcom-efsd
   adb shell "chmod 755 /data/local/tmp/qcom-efsd"
   adb shell "su -c 'setsid /data/local/tmp/qcom-efsd -uid 2000 -socket qcom_efsd_dbg &'"
   adb forward tcp:9999 localabstract:qcom_efsd_dbg
   ```

2. **Inspect & Backup EFS**:
   ```bash
   python3 scripts/diag_efs_inspect.py ./efs_backup
   ```

3. **Enable Hardware VoLTE**:
   ```bash
   python3 scripts/enable_volte_efs.py
   ```

4. **Reboot and Verify**:
   ```bash
   adb reboot
   # After reboot:
   bash scripts/verify_volte_status.sh
   ```

---

## 中文说明

### 📌 项目简介
**Qualcomm VoLTE Enabler** 是一个面向高通骁龙（Qualcomm Snapdragon）平台的免 QPST、跨平台（完美支持 macOS 与 Linux）的 VoLTE 修复工具集与 Google Antigravity Agent 技能库。

本项目源于在 **BlackBerry Key2（athena，骁龙 660）** 运行第三方 **LineageOS 22.2（Android 15）** 上的实机调试成果。在全国运营商（如中国联通、中国电信、中国移动）大范围清退 2G（GSM）与 3G（WCDMA）网络后，传统电路域回落（CSFB）失效，通过本项目成功恢复了纯 4G LTE 下的高清 VoLTE 通话与 IMS 注册。

### ❓ 解决的核心痛点
* 手机能正常使用 4G 移动数据上网，但**完全无法拨打或接听普通电话**（拨号后立即闪退或提示通话结束）。
* 拨打 `*#*#4636#*#*` 进入手机信息查看：
  * **IMS 状态：未注册**
  * **LTE 语音通话：不可用**（中文系统有时机翻为“不支持该付款方式”）
* 高通基带硬件底层未开启 IMS 实体支持（`/nv/item_files/ims/IMS_enable = 0x00`）。

### 🚀 核心原理
1. **基带 EFS NV 注入**：利用高通 DIAG 协议与 Linux abstract socket，直接对 modem 分区 NVRAM 写入 `IMS_enable = 0x01` 并提交 journal 刷入闪存。
2. **QCRIL 运营商库规则修正**：在 `/data/vendor/radio/qcril.db` 中绑定运营商（如中国联通 MCC `460` MNC `01`）与 `VoLTE-CU` 基带 MBN 固件映射。
3. **ICCID 与开机自启守护**：通过 Magisk `post-fs-data.d` 部署开机保护脚本，锁定 SIM 标识缓存（`chattr +i`），防止重启后基带复位。

### 📋 运行前置要求
* **必须具备 Root 权限**：已安装 Magisk、KernelSU 或 APatch（获得 `su` 权限）。
* 电脑端已安装 ADB 工具并已开启手机“USB 调试”。
* 电脑端具备 Python 3.7+ 环境（macOS、Linux 或 Windows WSL 均可）。

---

### ❓ 常见问题：非 Root 的 Key2 原厂系统是否可以使用本项目？

**答：不能直接使用。本项目严格依赖 Root 权限。**

#### 为什么非 Root 系统无法运行？
1. **安全权限限制**：Android 内核与 SELinux 强制隔离，非 Root 用户（UID 2000）或普通 App **绝对无权打开 `/dev/diag` 字符设备**，也无法改写 `persist.dbg.*` 等系统级电话属性。
2. **原厂暗码被屏蔽**：在其他普通高通机型上，未 Root 偶尔可通过拨号盘工程暗码（如 `*#*#717717#*#*`）开启 USB 诊断 COM 口。但 BlackBerry Key2 的官方原厂固件（Android 8.1）经过了黑莓与 TCL 的深度安全加固，**彻底封堵了所有的免 Root 开启 DIAG 端口的暗码**，电脑端无法直接识别出 Diagnostic 端口。

#### 非 Root 的 Key2 用户该如何解决？
1. **推荐路线（最彻底）**：
   * 将 Key2 解锁 Bootloader 并刷入 **LineageOS（Android 15）+ Magisk Root**。
   * 取得 Root 权限后，直接运行本项目的一键脚本，即可立刻点亮纯 4G LTE VoLTE 高清通话。
2. **国行零售版（BBF100-4）原厂系统尝试**：
   * 国行底层内置了联通/电信/移动的基础 MBN，请务必将 SIM 卡插在**卡槽 1（主卡槽，靠近内侧的卡位）**；
   * 在系统设置中手动添加一条 APN：名称填 `IMS`，APN 填 `ims`，APN 类型填 `ims`，协议选 `IPv4/IPv6`；
   * 拨打 `*#*#4636#*#*` 进入手机信息，检查“VoLTE 配置的标记”能否开启，开启飞行模式 10 秒后关闭尝试激活。
3. **海外版（美版 BBF100-2、港版 BBF100-6 等）**：
   * 海外版官方固件硬件 NVRAM 默认未配置中国运营商 VoLTE，目前**唯一可行的途径就是解锁 Bootloader 并获取 Root 权限后使用本项目写入**。

---

### 📦 目录结构
```text
qualcomm-volte-enabler/
├── README.md                     # 项目说明、中英完整指南与 FAQ
├── SKILL.md                      # Antigravity Agent Skill 规范配置
├── LICENSE                       # MIT 开源许可证
├── bin/
│   └── qcom-efsd                 # aarch64 Qualcomm DIAG 守护进程独立二进制
├── scripts/
│   ├── auto_enable_volte.sh      # 一键全自动激活脚本（包含提权、启动守护、写入NV与清理）
│   ├── diag_efs_inspect.py       # EFS 与 IMS 状态诊断与备份脚本
│   ├── enable_volte_efs.py       # EFS 自动写入与 VoLTE 激活脚本
│   └── verify_volte_status.sh    # 电话与 IMS 注册状态验证脚本
└── references/
    └── troubleshooting.md        # 疑难排查（双卡槽位选择、频段冲突、翻译陷阱等）
```

### 🛠️ 快速使用指南

#### 一键自动修复（推荐）
保持手机开启 USB 调试并连接电脑，确保已获得 Root 权限（Magisk/KernelSU）：
```bash
git clone https://github.com/ikimi615/qualcomm-volte-enabler.git
cd qualcomm-volte-enabler
bash scripts/auto_enable_volte.sh
```
按照终端提示重启手机即可！

#### 验证是否生效
重启手机后运行：
```bash
bash scripts/verify_volte_status.sh
```
* 检查输出中的 `notifyFeatureStateChanged, type=MMTEL, state=READY`
* 手机拨打客服电话（如 `10010`），状态栏全程保持 **LTE / 4G** 图标且语音接通，即证明 VoLTE 激活成功！

### ⚠️ 免责声明
本工具涉及对底层高通基带 EFS 分区的读取与写入。在操作前，脚本会自动备份相关 NV 项。请严格按照操作流程执行，作者不对因误操作造成的设备异常负责。

---

## 🌟 Star & Fork
如果你觉得这个项目对你有帮助，欢迎点击右上角给一个 **Star** ⭐，也欢迎提交 Issue 和 PR！
