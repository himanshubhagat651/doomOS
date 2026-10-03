#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Step 2: Hardware Center Verification
# Validates detection engine, data models, GUI application syntax,
# desktop launchers, profile permissions, and non-destructive execution.
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS_COUNT=0
TOTAL_CHECKS=0

assert() {
    local DESC="$1"
    local CMD="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -ne "  [CHECK ${TOTAL_CHECKS}] ${DESC} ... "
    if eval "$CMD" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${RESET}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${RESET}"
        echo -e "    Failed assertion: ${CMD}"
    fi
}

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — STEP 2: HARDWARE CENTER              ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. File Presence & Execution Permissions
echo -e "\n${BOLD}${CYAN}1. Hardware Center Files & File Permissions${RESET}"
assert "Hardware detection engine exists" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-detect' ]]"
assert "Hardware detection engine is executable" "[[ -x '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-detect' ]]"
assert "Hardware Center GUI application exists" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-center' ]]"
assert "Hardware Center GUI application is executable" "[[ -x '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-center' ]]"
assert "System desktop launcher exists in /usr/share/applications" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-hardware-center.desktop' ]]"
assert "User desktop launcher exists in skel directory" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/etc/skel/.local/share/applications/doomos-hardware-center.desktop' ]]"

# 2. Archiso Profile Integration Audit
echo -e "\n${BOLD}${CYAN}2. Archiso Profile & Customization Integration${RESET}"
assert "profiledef.sh assigns permissions to doomos-hardware-detect" "grep -q 'doomos-hardware-detect' '${REPO_ROOT}/doomos-builder/profile/profiledef.sh'"
assert "profiledef.sh assigns permissions to doomos-hardware-center" "grep -q 'doomos-hardware-center' '${REPO_ROOT}/doomos-builder/profile/profiledef.sh'"
assert "customize_airootfs.sh enforces execution bits" "grep -q 'doomos-hardware-center' '${REPO_ROOT}/doomos-builder/profile/airootfs/root/customize_airootfs.sh'"

# 3. Python Code Syntax & Integrity
echo -e "\n${BOLD}${CYAN}3. Python Syntax & Module Execution Audit${RESET}"
assert "Hardware detection engine compiles without syntax error" "python3 -m py_compile '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-detect'"
assert "Hardware Center GUI compiles without syntax error" "python3 -m py_compile '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-center'"

# 4. Engine Output Verification
echo -e "\n${BOLD}${CYAN}4. Hardware Report Data Generation Audit${RESET}"
OUTPUT=$(python3 "${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-hardware-detect")
assert "Report includes DOOMOS HARDWARE SPECIFICATION REPORT header" "echo '${OUTPUT}' | grep -q 'DOOMOS HARDWARE SPECIFICATION REPORT'"
assert "Report includes PROCESSOR section" "echo '${OUTPUT}' | grep -q 'PROCESSOR (CPU)'"
assert "Report includes SYSTEM MEMORY section" "echo '${OUTPUT}' | grep -q 'SYSTEM MEMORY (RAM)'"
assert "Report includes GRAPHICS section" "echo '${OUTPUT}' | grep -q 'GRAPHICS & ACCELERATION'"
assert "Report includes STORAGE section" "echo '${OUTPUT}' | grep -q 'STORAGE & DISKS'"
assert "Report includes NETWORK CONTROLLERS section" "echo '${OUTPUT}' | grep -q 'NETWORK CONTROLLERS'"
assert "Report includes AUDIO HARDWARE section" "echo '${OUTPUT}' | grep -q 'AUDIO HARDWARE'"
assert "Report includes DISPLAYS section" "echo '${OUTPUT}' | grep -q 'DISPLAYS'"

# 5. Desktop Entry Standard Compliance
echo -e "\n${BOLD}${CYAN}5. FreeDesktop Entry Standard Audit${RESET}"
DESKTOP_FILE="${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-hardware-center.desktop"
assert "Desktop file defines [Desktop Entry]" "grep -q '^\[Desktop Entry\]' '${DESKTOP_FILE}'"
assert "Desktop file sets Name=Hardware Center" "grep -q '^Name=Hardware Center' '${DESKTOP_FILE}'"
assert "Desktop file points to /usr/bin/doomos-hardware-center" "grep -q '^Exec=/usr/bin/doomos-hardware-center' '${DESKTOP_FILE}'"
assert "Desktop file includes valid Categories" "grep -q '^Categories=.*System' '${DESKTOP_FILE}'"

echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}STEP 2 HARDWARE CENTER TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
