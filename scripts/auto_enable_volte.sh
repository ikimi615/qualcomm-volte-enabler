#!/usr/bin/env bash
# ==============================================================================
# Qualcomm VoLTE One-Click Enabler (No QPST / macOS & Linux Friendly)
# Automates: Root Check -> Telephony Props -> DIAG Daemon -> EFS Flip -> Cleanup
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ADB="${ADB:-adb}"
PORT="${DIAG_PORT:-9999}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}      Qualcomm VoLTE One-Click Enablement Tool        ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. Check ADB connection
echo -e "\n${BLUE}[1/6] Checking ADB device connection...${NC}"
DEVICE_COUNT=$($ADB devices | grep -v "List" | grep "device$" | wc -l | tr -d ' ')
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}[ERROR] No authorized ADB device found. Please connect your device and enable USB debugging.${NC}"
    exit 1
fi
DEVICE_MODEL=$($ADB shell getprop ro.product.model | tr -d '\r')
echo -e "${GREEN}[+] Device connected: ${DEVICE_MODEL}${NC}"

# 2. Check Root Access
echo -e "\n${BLUE}[2/6] Checking Root permissions (Magisk / KernelSU / su)...${NC}"
ROOT_CHECK=$($ADB shell "su -c id" 2>/dev/null || true)
if [[ "$ROOT_CHECK" != *"uid=0"* ]]; then
    echo -e "${RED}[ERROR] Root access is required to access Qualcomm baseband DIAG interface.${NC}"
    echo -e "${RED}Please ensure Magisk or KernelSU is installed and grant Shell superuser access.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Root access confirmed: ${ROOT_CHECK}${NC}"

# 3. Configure Android Framework Telephony Overrides
echo -e "\n${BLUE}[3/6] Applying telephony persistent properties...${NC}"
$ADB shell "su -c '
    setprop persist.dbg.ims_volte_enable 1
    setprop persist.dbg.volte_avail_ovr 1
    setprop persist.dbg.vt_avail_ovr 1
    setprop persist.dbg.wfc_avail_ovr 1
    setprop persist.vendor.radio.volte_is_needed 1
'"
echo -e "${GREEN}[+] Telephony properties configured.${NC}"

# 4. Deploy & Start Qualcomm DIAG Daemon
echo -e "\n${BLUE}[4/6] Deploying and starting baseband DIAG daemon (qcom-efsd)...${NC}"
if [ ! -f "$PROJECT_ROOT/bin/qcom-efsd" ]; then
    echo -e "${RED}[ERROR] Binary $PROJECT_ROOT/bin/qcom-efsd not found!${NC}"
    exit 1
fi

$ADB push "$PROJECT_ROOT/bin/qcom-efsd" /data/local/tmp/qcom-efsd >/dev/null
$ADB shell "chmod 755 /data/local/tmp/qcom-efsd"

# Kill any existing instance
$ADB shell "su -c 'pkill -f qcom-efsd || true'" >/dev/null 2>&1 || true

# Start daemon in background listening on abstract socket with shell UID (2000)
$ADB shell "su -c 'setsid /data/local/tmp/qcom-efsd -uid 2000 -socket qcom_efsd_dbg >/dev/null 2>&1 &'"
sleep 1

# Forward port
$ADB forward tcp:"$PORT" localabstract:qcom_efsd_dbg
echo -e "${GREEN}[+] Baseband DIAG daemon active and forwarded to localhost:${PORT}.${NC}"

# 5. Execute Python EFS Writing Script
echo -e "\n${BLUE}[5/6] Inspecting and updating modem NV (/nv/item_files/ims/IMS_enable)...${NC}"
python3 "$SCRIPT_DIR/enable_volte_efs.py"

# 6. Cleanup
echo -e "\n${BLUE}[6/6] Cleaning up daemon and forwarding...${NC}"
$ADB forward --remove tcp:"$PORT" >/dev/null 2>&1 || true
$ADB shell "su -c 'pkill -f qcom-efsd || true'" >/dev/null 2>&1 || true
$ADB shell "rm -f /data/local/tmp/qcom-efsd" >/dev/null 2>&1 || true

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}  SUCCESS: Qualcomm hardware VoLTE configuration done!${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Reboot your device now: ${GREEN}adb reboot${NC}"
echo -e "2. Once booted, run verification script: ${GREEN}bash scripts/verify_volte_status.sh${NC}"
echo -e "3. Dial 10010 / 10086 / carrier service to verify voice on LTE.\n"
