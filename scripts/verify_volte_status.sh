#!/usr/bin/env bash
# Quick verification of VoLTE, IMS Registration, and MMTEL status via ADB

set -e

ADB=${ADB:-adb}

echo "=== 1. Checking Voice & Data Service State ==="
$ADB shell "dumpsys telephony.registry | grep -iE 'mVoiceRegState|mDataRegState|getRilVoiceRadioTechnology|mCssIndicator' | head -4"

echo -e "\n=== 2. Checking IMS MMTEL Controller State ==="
$ADB shell "dumpsys phone | grep -iE 'notifyFeatureStateChanged.*MMTEL' | tail -5"

echo -e "\n=== 3. Checking System Properties ==="
$ADB shell "getprop persist.dbg.ims_volte_enable; getprop persist.dbg.volte_avail_ovr; getprop gsm.operator.alpha"

echo -e "\n=== 4. Dumpsys CarrierConfig VoLTE ==="
$ADB shell "dumpsys carrier_config | grep -iE 'carrier_volte_available_bool|config_ims_package_override' | head -10"
