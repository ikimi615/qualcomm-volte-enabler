# Qualcomm VoLTE Troubleshooting Guide

## 1. Hardware SIM Slot Selection (DSDS Restriction)
On dual-SIM Qualcomm platforms (such as Snapdragon 660 / BlackBerry Key2), **Slot 0 (Slot 1 in physical tray)** is wired to the primary RF transceiver path with full band support and primary IMS capability.
- If only one SIM is used, **always insert it into Slot 1 (Slot 0 in OS / primary slot)**.
- Inserting single SIM into Slot 2 often results in CS domain registration rejection (`DENIED` / `NOT_REG_SEARCHING`) because the modem firmware cannot upgrade secondary slot to primary VoLTE path.

## 2. Machine Translation Quirk: "不支持该付款方式"
In Android's `*#*#4636#*#*` -> Phone Info -> IMS Status menu, `Not supported` is notoriously mistranslated into Chinese as:
> `不支持该付款方式` (Incorrect machine translation of payment method instead of network capability)

- If you see `不支持该付款方式`, it strictly means **Capability Not Supported / Disabled in Baseband**.
- Once properly activated, it will change to **`可用` (Available)** and `IMS 注册: 已注册` (Registered).

## 3. Why Framework CarrierConfig Overrides Are Not Enough
Editing Android's `CarrierConfig` or setting `persist.dbg.ims_volte_enable=1` only instructs the Android OS framework to attempt to bind IMS.
If the underlying Qualcomm modem's non-volatile memory has `/nv/item_files/ims/IMS_enable` set to `0x00`:
- The modem firmware forcefully rejects all IMS activation commands with `error: 2` (NOT_SUPPORTED).
- The MMTEL controller remains stuck in `state=UNAVAILABLE`.
- Hardware NV must be flipped to `0x01` via DIAG protocol.

## 4. Checking Carrier MBN Profiles in EFS
Check `/nv/item_files/mcfg/mcfg_sel_db.xml`:
Search for your MCC/MNC (e.g. `460-01` for China Unicom) to ensure the hardware supports `volte="true"`. Most modern regional firmwares include China Mobile (CMCC), China Unicom (CU), and China Telecom (CT) MBN profiles out of the box.
