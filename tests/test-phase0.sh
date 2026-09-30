#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Phase 0: Architecture & Project Structure
# Validates directory layout, architectural freeze documentation, build guides,
# and environment validation scripts.
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — PHASE 0: ARCHITECTURE FREEZE          ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Directory Structure Checks
echo -e "\n${BOLD}${CYAN}1. Standard Project Hierarchy${RESET}"
assert "Directory 'docs/' exists" "[[ -d '${REPO_ROOT}/docs' ]]"
assert "Directory 'configs/' exists" "[[ -d '${REPO_ROOT}/configs' ]]"
assert "Directory 'scripts/' exists" "[[ -d '${REPO_ROOT}/scripts' ]]"
assert "Directory 'tests/' exists" "[[ -d '${REPO_ROOT}/tests' ]]"
assert "Directory 'tools/' exists" "[[ -d '${REPO_ROOT}/tools' ]]"
assert "Directory 'boot/' exists" "[[ -d '${REPO_ROOT}/boot' ]]"
assert "Directory 'kernel/' exists" "[[ -d '${REPO_ROOT}/kernel' ]]"
assert "Directory 'rootfs/' exists" "[[ -d '${REPO_ROOT}/rootfs' ]]"
assert "Directory 'initramfs/' exists" "[[ -d '${REPO_ROOT}/initramfs' ]]"
assert "Directory 'iso/' exists" "[[ -d '${REPO_ROOT}/iso' ]]"
assert "Directory '.github/workflows/' exists" "[[ -d '${REPO_ROOT}/.github/workflows' ]]"

# 2. Architecture Specification Freeze
echo -e "\n${BOLD}${CYAN}2. Architecture Freeze Audit${RESET}"
assert "Architecture document exists" "[[ -s '${REPO_ROOT}/docs/ARCHITECTURE.md' ]]"
assert "Target architecture specified as x86_64" "grep -q 'Target Architecture:' '${REPO_ROOT}/docs/ARCHITECTURE.md' || grep -q 'x86_64' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Firmware target specified as UEFI" "grep -q 'UEFI' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Kernel strategy specified (linux-zen)" "grep -q 'linux-zen' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Libc strategy specified (glibc multilib)" "grep -q 'glibc' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Init system specified (systemd)" "grep -q 'systemd' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Live filesystem strategy specified (SquashFS + zstd-19)" "grep -q 'SquashFS' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Target filesystem specified (Btrfs subvolumes)" "grep -q 'Btrfs' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "UEFI layout defined (BOOTX64.EFI)" "grep -q 'BOOTX64.EFI' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "VMware hardware profile documented" "grep -q 'VMware' '${REPO_ROOT}/docs/ARCHITECTURE.md'"
assert "Release artifact strategy documented (multipart)" "grep -q 'Multipart' '${REPO_ROOT}/docs/ARCHITECTURE.md'"

# 3. VMware Validation Ledger
echo -e "\n${BOLD}${CYAN}3. VMware Validation Ledger Integrity${RESET}"
assert "VMware validation ledger exists" "[[ -s '${REPO_ROOT}/docs/VMWARE-VALIDATION.md' ]]"
assert "Ledger does NOT fabricate untested success (records NOT TESTED)" "grep -q 'NOT TESTED' '${REPO_ROOT}/docs/VMWARE-VALIDATION.md'"

# 4. Build Guide & Release Specifications
echo -e "\n${BOLD}${CYAN}4. Build & Release Engineering Documentation${RESET}"
assert "Build guide exists" "[[ -s '${REPO_ROOT}/docs/BUILD.md' ]]"
assert "Release distribution protocol exists" "[[ -s '${REPO_ROOT}/docs/RELEASE.md' ]]"
assert "Build environment check script exists and executable" "[[ -x '${REPO_ROOT}/scripts/check-build-environment.sh' ]]"

# Summary
echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}PHASE 0 ACCEPTANCE TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}PHASE 0 ACCEPTANCE TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
