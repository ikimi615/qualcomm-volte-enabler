---
name: qualcomm-volte-enabler
description: >-
  Enables VoLTE and IMS HD calling on Qualcomm Snapdragon devices (e.g. BlackBerry Key2
  athena, SDM660, and legacy devices running LineageOS or AOSP) without QPST or Windows.
  Use when users report that their phone can access 4G mobile data but cannot make calls,
  IMS is unregistered, or dialing fails after 2G/3G network shutdown.
---

# Qualcomm Snapdragon VoLTE Enabler (No QPST / Mac & Linux Friendly)

This skill provides an end-to-end, reproducible procedure to enable Voice over LTE (VoLTE) and IMS calling on Qualcomm Snapdragon devices (such as the BlackBerry Key2 `athena`, SDM660 devices, and custom ROMs like LineageOS 22 / Android 15) without requiring Windows, QPST, or PDC tools.

---

## 📌 Problem Symptoms

1. **4G Mobile data works, but phone calls immediately fail** (network drops to "No service" or "Call Ended" within 200ms).
2. **2G/3G Carrier Shutdown**: Carriers (like China Unicom / AT&T / T-Mobile) have decommissioned legacy 2G/3G CSFB fallback networks.
3. In `*#*#4636#*#*` -> Phone Info -> IMS Status:
   - `IMS Status: Not Registered` (未注册)
   - `VoLTE / Video Calling: Not supported` (机翻常显示为“不支持该付款方式”)
4. In Android logs: `QImsService` sends `REQUEST_SET_IMS_CONFIG` and receives `error: 2` (Hardware rejected).

---

## 🛠️ Step-by-Step Enablement Runbook

### Step 1: Ensure Primary SIM Slot Binding
1. On dual-SIM Qualcomm devices (DSDS), **Slot 1 (primary slot, slot 0 in OS)** is wired to the full RF chain and VoLTE transceiver.
2. If only one SIM is used, ensure it is placed in **Slot 1** (the inner slot of the SIM tray).
   - If placed in Slot 2 with Slot 1 empty, the modem often rejects CS/PS registration (`DENIED`).

### Step 2: Configure Android Framework Overrides (Root)
Ensure Android Framework does not soft-block VoLTE:
1. Set persistent telephony properties:
   ```bash
   adb shell "su -c 'setprop persist.dbg.ims_volte_enable 1; setprop persist.dbg.volte_avail_ovr 1; setprop persist.dbg.vt_avail_ovr 1; setprop persist.dbg.wfc_avail_ovr 1; setprop persist.vendor.radio.volte_is_needed 1'"
   ```
2. In `/data/user_de/0/com.android.phone/files/carrierconfig-*.xml`, ensure:
   - `carrier_volte_available_bool = true`
   - `enhanced_4g_lte_on_by_default_bool = true`
   - `config_ims_package_override_string = org.codeaurora.ims`
3. In Settings -> Mobile Network -> APN, ensure default APN is set to IPv4v6 (e.g. `3gnet`) and an `ims` APN (APN type: `ims`) is enabled.

### Step 3: Direct Baseband EFS Inspection & Backup via DIAG
Bypassing QPST by leveraging Qualcomm DIAG over root daemon:
1. Push `qcom-efsd` (aarch64 helper from `catxeon/qcom-efs-browser`) to `/data/local/tmp/qcom-efsd` and set executable permission:
   ```bash
   adb push qcom-efsd /data/local/tmp/qcom-efsd
   adb shell "chmod +x /data/local/tmp/qcom-efsd"
   ```
2. Start the daemon with UID 2000 (shell):
   ```bash
   adb shell "su -c '/data/local/tmp/qcom-efsd -uid 2000 -socket qcom_efsd_dbg &'"
   adb forward tcp:9999 localabstract:qcom_efsd_dbg
   ```
3. Run the inspection script [diag_efs_inspect.py](./scripts/diag_efs_inspect.py):
   ```bash
   python3 scripts/diag_efs_inspect.py ./efs_backup
   ```
4. Verify whether `/nv/item_files/ims/IMS_enable` is `0x00` (Disabled).

### Step 4: Flip Hardware IMS Enable in Modem NV
If `/nv/item_files/ims/IMS_enable` is `0x00`:
1. Execute [enable_volte_efs.py](./scripts/enable_volte_efs.py):
   ```bash
   python3 scripts/enable_volte_efs.py
   ```
   - This writes `0x01` to `/nv/item_files/ims/IMS_enable`.
   - Flushes the EFS journal commit to flash memory (`sync`).
   - Automatically restores read-only guard.
2. Clean up daemon:
   ```bash
   adb shell "su -c 'pkill -f qcom-efsd'"
   ```

### Step 5: Reboot and Verify
1. Reboot the device:
   ```bash
   adb reboot
   ```
2. Run [verify_volte_status.sh](./scripts/verify_volte_status.sh):
   - Confirm `notifyFeatureStateChanged, type=MMTEL, state=READY`.
   - Confirm `mVoiceRegState = 0(IN_SERVICE)`, `mCssSupported = true`.
3. Open Phone app, dial carrier customer service (e.g. `10010` / `10086`), and confirm:
   - Voice audio is connected.
   - Status bar icon stays on **LTE / 4G** throughout the call (VoLTE confirmed).
4. Verify in `*#*#4636#*#*` -> Phone Info -> IMS Status:
   - `IMS Status: Registered` (已注册)
   - `Voice over LTE: Available` (可用)

---

## 📚 References & Background Notes
- [Troubleshooting & FAQ](./references/troubleshooting.md) for details on SIM slot allocation, carrier MBN selection, and machine-translation quirks.
