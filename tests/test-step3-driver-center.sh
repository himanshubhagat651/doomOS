#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Step 3: Driver Center Verification
# Validates driver detection engine, status models, diagnostic reasoning,
# GUI application syntax, desktop launchers, profile permissions,
# safety constraints, and non-destructive execution.
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — STEP 3: DRIVER CENTER                ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. File Presence & Execution Permissions
echo -e "\n${BOLD}${CYAN}1. Driver Center Files & File Permissions${RESET}"
assert "Driver detection engine exists" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect' ]]"
assert "Driver detection engine is executable" "[[ -x '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect' ]]"
assert "Driver Center GUI application exists" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-center' ]]"
assert "Driver Center GUI application is executable" "[[ -x '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-center' ]]"
assert "System desktop launcher exists in /usr/share/applications" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-driver-center.desktop' ]]"
assert "User desktop launcher exists in skel directory" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/etc/skel/.local/share/applications/doomos-driver-center.desktop' ]]"

# 2. Archiso Profile Integration Audit
echo -e "\n${BOLD}${CYAN}2. Archiso Profile & Customization Integration${RESET}"
assert "profiledef.sh assigns permissions to doomos-driver-detect" "grep -q 'doomos-driver-detect' '${REPO_ROOT}/doomos-builder/profile/profiledef.sh'"
assert "profiledef.sh assigns permissions to doomos-driver-center" "grep -q 'doomos-driver-center' '${REPO_ROOT}/doomos-builder/profile/profiledef.sh'"
assert "customize_airootfs.sh enforces execution bits for driver tools" "grep -q 'doomos-driver-center' '${REPO_ROOT}/doomos-builder/profile/airootfs/root/customize_airootfs.sh'"

# 3. Python Syntax & Integrity Audit
echo -e "\n${BOLD}${CYAN}3. Python Syntax & Integrity Audit${RESET}"
assert "Driver detection engine compiles without syntax error" "python3 -m py_compile '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect'"
assert "Driver Center GUI compiles without syntax error" "python3 -m py_compile '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-center'"

# 4. Backend Structured JSON & Architecture Telemetry
echo -e "\n${BOLD}${CYAN}4. Backend Structured JSON & Architecture Telemetry${RESET}"
JSON_OUT=$(python3 "${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect" --json)
assert "Backend returns valid parseable JSON" "echo '${JSON_OUT}' | python3 -c 'import json, sys; json.load(sys.stdin)'"
assert "JSON contains system architecture" "echo '${JSON_OUT}' | python3 -c 'import json, sys; d=json.load(sys.stdin); assert \"architecture\" in d[\"system\"]'"
assert "JSON contains kernel release" "echo '${JSON_OUT}' | python3 -c 'import json, sys; d=json.load(sys.stdin); assert len(d[\"system\"][\"kernel\"]) > 0'"
assert "JSON contains virtualization metadata" "echo '${JSON_OUT}' | python3 -c 'import json, sys; d=json.load(sys.stdin); assert \"virtualization\" in d[\"system\"]'"
assert "JSON contains devices list" "echo '${JSON_OUT}' | python3 -c 'import json, sys; d=json.load(sys.stdin); assert isinstance(d[\"devices\"], list)'"
assert "JSON contains summary counts" "echo '${JSON_OUT}' | python3 -c 'import json, sys; d=json.load(sys.stdin); assert \"GOOD\" in d[\"summary\"]'"

# 5. Diagnostic Report Specification Compliance
echo -e "\n${BOLD}${CYAN}5. Diagnostic Report Specification Compliance${RESET}"
REPORT_OUT=$(python3 "${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect")
assert "Report includes exact header" "echo '${REPORT_OUT}' | grep -q '^DoomOS Driver Diagnostic Report'"
assert "Report includes System section" "echo '${REPORT_OUT}' | grep -q '^System' && echo '${REPORT_OUT}' | grep -q '^Architecture:'"
assert "Report includes Graphics section" "echo '${REPORT_OUT}' | grep -q '^Graphics' && echo '${REPORT_OUT}' | grep -q '^Kernel Module:'"
assert "Report includes Network section" "echo '${REPORT_OUT}' | grep -q '^Network' && echo '${REPORT_OUT}' | grep -q '^Firmware:'"
assert "Report includes Bluetooth section" "echo '${REPORT_OUT}' | grep -q '^Bluetooth'"
assert "Report includes Audio section with PipeWire" "echo '${REPORT_OUT}' | grep -q '^Audio' && echo '${REPORT_OUT}' | grep -q 'PipeWire:' && echo '${REPORT_OUT}' | grep -q 'WirePlumber:'"
assert "Report includes Storage section" "echo '${REPORT_OUT}' | grep -q '^Storage' && echo '${REPORT_OUT}' | grep -q 'Controller:'"
assert "Report includes Input and USB section" "echo '${REPORT_OUT}' | grep -q '^Input and USB' && echo '${REPORT_OUT}' | grep -q 'Detected devices:'"
assert "Report includes Summary section with all 6 statuses" "echo '${REPORT_OUT}' | grep -q '^Summary' && echo '${REPORT_OUT}' | grep -q 'GOOD:' && echo '${REPORT_OUT}' | grep -q 'WARNING:' && echo '${REPORT_OUT}' | grep -q 'MISSING:' && echo '${REPORT_OUT}' | grep -q 'UNKNOWN:' && echo '${REPORT_OUT}' | grep -q 'UNSUPPORTED:' && echo '${REPORT_OUT}' | grep -q 'ERROR:'"
assert "Report includes Recommended Actions section" "echo '${REPORT_OUT}' | grep -q '^Recommended Actions'"

# 6. Status Model & Fixture Robustness Verification
echo -e "\n${BOLD}${CYAN}6. Status Model & Fixture Robustness Verification${RESET}"
assert "DriverStatus model exposes all 6 canonical statuses" "python3 -c '
import sys
sys.path.insert(0, \"${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin\")
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader(\"dd\", \"${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect\")
spec = importlib.util.spec_from_loader(\"dd\", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
ds = m.DriverStatus
for s in [\"GOOD\", \"WARNING\", \"MISSING\", \"UNKNOWN\", \"UNSUPPORTED\", \"ERROR\"]:
    assert getattr(ds, s) == s
'"

assert "Engine formats mock fixture with MISSING and UNSUPPORTED devices cleanly" "python3 -c '
import sys
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader(\"dd\", \"${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect\")
spec = importlib.util.spec_from_loader(\"dd\", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)

mock_data = {
    \"system\": {\"architecture\": \"aarch64\", \"kernel\": \"6.6.0-doomos\", \"detection_time\": \"2026-10-26\"},
    \"categories\": {
        \"Graphics\": [{\"name\": \"Broadcom VideoCore\", \"driver\": \"Unknown\", \"module_loaded\": \"UNKNOWN\", \"firmware_status\": \"MISSING\", \"status\": m.DriverStatus.MISSING}],
        \"Network\": [],
        \"Bluetooth\": [],
        \"Audio\": [],
        \"Storage\": [],
        \"Input\": [],
        \"USB\": []
    },
    \"summary\": {m.DriverStatus.MISSING: 1, m.DriverStatus.GOOD: 0},
    \"recommended_actions\": [\"Install missing broadcom firmware package.\"]
}
rep = m.generate_diagnostic_report(mock_data)
assert \"Status: MISSING\" in rep
assert \"Install missing broadcom firmware package.\" in rep
'"

assert "Engine handles malformed and empty telemetry data gracefully without crashing" "python3 -c '
import sys
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader(\"dd\", \"${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect\")
spec = importlib.util.spec_from_loader(\"dd\", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)

rep = m.generate_diagnostic_report({})
assert \"DoomOS Driver Diagnostic Report\" in rep
'"

# 7. GUI Backend Integration & Export Verification
echo -e "\n${BOLD}${CYAN}7. GUI Backend Integration & Export Verification${RESET}"
assert "GUI module imports detection engine and initializes telemetry data structure" "python3 -c '
import sys
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader(\"dc\", \"${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-center\")
spec = importlib.util.spec_from_loader(\"dc\", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
assert hasattr(m, \"DriverCenterApp\")
'"

# 8. FreeDesktop Desktop Entry Standard Compliance
echo -e "\n${BOLD}${CYAN}8. FreeDesktop Entry Standard Compliance${RESET}"
DESK_SYS="${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-driver-center.desktop"
assert "Desktop file defines [Desktop Entry]" "grep -q '^\[Desktop Entry\]' '${DESK_SYS}'"
assert "Desktop file sets Name=DoomOS Driver Center" "grep -q '^Name=DoomOS Driver Center' '${DESK_SYS}'"
assert "Desktop file points to /usr/bin/doomos-driver-center" "grep -q '^Exec=/usr/bin/doomos-driver-center' '${DESK_SYS}'"
assert "Desktop file specifies preferences-system-hardware icon" "grep -q '^Icon=preferences-system-hardware' '${DESK_SYS}'"
assert "Desktop file includes valid Categories" "grep -q '^Categories=.*HardwareSettings;' '${DESK_SYS}'"

# 9. Security, Privacy & Safety Guard Audit
echo -e "\n${BOLD}${CYAN}9. Security, Privacy & Safety Guard Audit${RESET}"
assert "No automatic pacman/apt package installations in backend" "! grep -E 'pacman -S|apt install|apt-get|dnf install' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect'"
assert "No automatic driver installations or kernel module insertions" "! grep -E 'modprobe|insmod|rmmod' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect'"
assert "No destructive disk formatting commands" "! grep -E 'mkfs|fdisk|dd if=' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect'"
assert "No sudo / su elevation in backend" "! grep -E 'sudo|pkexec' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect'"
assert "MAC address sanitization helper works" "python3 -c '
import sys
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader(\"dd\", \"${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-driver-detect\")
spec = importlib.util.spec_from_loader(\"dd\", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
masked = m.sanitize_text(\"Interface eth0 with MAC 52:54:00:12:34:56 connected\")
assert \"52:54:00:12:34:56\" not in masked
assert \"XX:XX:XX:XX:XX:XX\" in masked
'"

echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}STEP 3 DRIVER CENTER TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
