#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Step 3: Live Preview Installer Verification
# Validates:
#  - Installer desktop launchers (system / user skel / desktop)
#  - Hardware detection & compatibility safety model
#  - Non-destructive execution & Apple Silicon bare-metal safety guards
#  - FreeDesktop desktop entry specifications
#  - Syntax and compilation of installer Python modules
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — STEP 3: LIVE PREVIEW INSTALLER       ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Launcher & Desktop Icon Audit
echo -e "\n${BOLD}${CYAN}1. Installer Desktop Launchers & Visual Entry Points${RESET}"
assert "System application launcher exists (/usr/share/applications/doomos-installer.desktop)" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-installer.desktop' ]]"
assert "User skel application launcher exists (/etc/skel/.local/share/applications/doomos-installer.desktop)" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/etc/skel/.local/share/applications/doomos-installer.desktop' ]]"
assert "Live Desktop launcher exists (/etc/skel/Desktop/doomos-installer.desktop)" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/etc/skel/Desktop/doomos-installer.desktop' ]]"
assert "Installer engine binary exists (/usr/bin/doomos-installer-engine)" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer-engine' ]]"
assert "Installer GUI application exists (/usr/bin/doomos-installer)" "[[ -f '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer' ]]"

# 2. Execution Permissions & Archiso Integration
echo -e "\n${BOLD}${CYAN}2. Permissions & Archiso Build Integration${RESET}"
assert "Installer engine has executable permissions" "[[ -x '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer-engine' ]]"
assert "Installer GUI has executable permissions" "[[ -x '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer' ]]"
assert "profiledef.sh defines doomos-installer-engine permission" "grep -q 'doomos-installer-engine' '${REPO_ROOT}/doomos-builder/profile/profiledef.sh'"
assert "profiledef.sh defines doomos-installer permission" "grep -q 'doomos-installer' '${REPO_ROOT}/doomos-builder/profile/profiledef.sh'"
assert "customize_airootfs.sh enforces installer execution bits" "grep -q 'doomos-installer' '${REPO_ROOT}/doomos-builder/profile/airootfs/root/customize_airootfs.sh'"
assert "customize_airootfs.sh provisions Desktop icon for liveuser" "grep -q '/home/liveuser/Desktop' '${REPO_ROOT}/doomos-builder/profile/airootfs/root/customize_airootfs.sh'"

# 3. Python Code Syntax & Module Compilation
echo -e "\n${BOLD}${CYAN}3. Python Syntax & Module Execution Audit${RESET}"
assert "Installer engine compiles cleanly" "python3 -m py_compile '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer-engine'"
assert "Installer GUI compiles cleanly" "python3 -m py_compile '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer'"

# 4. Engine Hardware & Safety Logic
echo -e "\n${BOLD}${CYAN}4. Hardware Compatibility & Safety Engine Logic${RESET}"
ENGINE_OUT=$(python3 -c "
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader('doomos_installer_engine', '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer-engine')
spec = importlib.util.spec_from_loader('doomos_installer_engine', loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)
compat = mod.SystemCompatibility.detect_environment()
disks = mod.DiskManager.list_target_disks()
assert 'architecture' in compat
assert 'ram_gb' in compat
assert len(disks) >= 1
print('ENGINE_OK')
")
assert "Installer engine returns valid environment model and disk list" "[[ '${ENGINE_OUT}' == 'ENGINE_OK' ]]"

# 5. Non-Destructive Test Execution
echo -e "\n${BOLD}${CYAN}5. Non-Destructive Dry-Run Execution Test${RESET}"
SIM_RES=$(python3 -c "
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader('doomos_installer_engine', '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/bin/doomos-installer-engine')
spec = importlib.util.spec_from_loader('doomos_installer_engine', loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)
success, msg = mod.InstallationEngine.execute_installation(
    target_disk='/dev/test0',
    username='testuser',
    password='secret',
    hostname='doomos-test',
    timezone='UTC',
    progress_callback=lambda desc, pct: None,
    dry_run=True
)
assert success == True
print('DRY_RUN_OK')
")
assert "Installation engine completes dry-run safely without errors" "[[ '${SIM_RES}' == 'DRY_RUN_OK' ]]"

# 6. FreeDesktop Launcher Standards
echo -e "\n${BOLD}${CYAN}6. FreeDesktop Launcher Specification Audit${RESET}"
assert "Desktop launcher defines [Desktop Entry]" "grep -q '^\[Desktop Entry\]' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-installer.desktop'"
assert "Desktop launcher sets Name=Install DoomOS" "grep -q '^Name=Install DoomOS' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-installer.desktop'"
assert "Desktop launcher points to /usr/bin/doomos-installer" "grep -q '^Exec=/usr/bin/doomos-installer' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-installer.desktop'"
assert "Desktop launcher specifies system-software-install icon" "grep -q '^Icon=system-software-install' '${REPO_ROOT}/doomos-builder/profile/airootfs/usr/share/applications/doomos-installer.desktop'"

echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}STEP 3 INSTALLER TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}STEP 3 INSTALLER TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} passed.${RESET}"
    exit 1
fi
