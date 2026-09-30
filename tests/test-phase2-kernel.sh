#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Phase 2: Kernel Strategy & Hardware Drivers
# Validates kernel configuration, VMware driver parameters, CPU microcode,
# and bootloader kernel arguments.
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — PHASE 2: KERNEL & HARDWARE DRIVERS   ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Kernel Architecture & Hardware Config Reference
echo -e "\n${BOLD}${CYAN}1. Kernel Architecture Configuration Reference Audit${RESET}"
assert "Kernel configuration reference exists" "[[ -f '${REPO_ROOT}/configs/doomos-kernel.config' ]]"
assert "Kernel config specifies CONFIG_X86_64=y" "grep -q 'CONFIG_X86_64=y' '${REPO_ROOT}/configs/doomos-kernel.config'"
assert "Kernel config specifies UEFI stub boot (CONFIG_EFI_STUB=y)" "grep -q 'CONFIG_EFI_STUB=y' '${REPO_ROOT}/configs/doomos-kernel.config'"
assert "Kernel config enables VMware SVGA 3D (CONFIG_DRM_VMWGFX)" "grep -q 'CONFIG_DRM_VMWGFX' '${REPO_ROOT}/configs/doomos-kernel.config'"
assert "Kernel config enables VMware vmxnet3 NIC (CONFIG_VMXNET3)" "grep -q 'CONFIG_VMXNET3' '${REPO_ROOT}/configs/doomos-kernel.config'"
assert "Kernel config enables Btrfs filesystem (CONFIG_BTRFS_FS=y)" "grep -q 'CONFIG_BTRFS_FS=y' '${REPO_ROOT}/configs/doomos-kernel.config'"
assert "Kernel config enables SquashFS with Zstandard (CONFIG_SQUASHFS_ZSTD=y)" "grep -q 'CONFIG_SQUASHFS_ZSTD=y' '${REPO_ROOT}/configs/doomos-kernel.config'"
assert "Kernel config enables OverlayFS (CONFIG_OVERLAY_FS=y)" "grep -q 'CONFIG_OVERLAY_FS=y' '${REPO_ROOT}/configs/doomos-kernel.config'"

# 2. Kernel Packages Manifest
echo -e "\n${BOLD}${CYAN}2. Kernel & Microcode Package Manifest Audit${RESET}"
assert "Performance Zen kernel in package manifest" "grep -q '^linux-zen$' '${REPO_ROOT}/doomos-builder/profile/packages.x86_64'"
assert "Zen kernel headers in package manifest" "grep -q '^linux-zen-headers$' '${REPO_ROOT}/doomos-builder/profile/packages.x86_64'"
assert "Fallback LTS kernel in package manifest" "grep -q '^linux-lts$' '${REPO_ROOT}/doomos-builder/profile/packages.x86_64'"
assert "AMD CPU microcode in package manifest" "grep -q '^amd-ucode$' '${REPO_ROOT}/doomos-builder/profile/packages.x86_64'"
assert "Intel CPU microcode in package manifest" "grep -q '^intel-ucode$' '${REPO_ROOT}/doomos-builder/profile/packages.x86_64'"
assert "Linux core firmware in package manifest" "grep -q '^linux-firmware$' '${REPO_ROOT}/doomos-builder/profile/packages.x86_64'"

# 3. Bootloader Kernel Command Line Contract
echo -e "\n${BOLD}${CYAN}3. Bootloader Kernel Command Line Contract Audit${RESET}"
assert "GRUB config references vmlinuz-linux-zen" "grep -q 'vmlinuz-linux-zen' '${REPO_ROOT}/doomos-builder/profile/grub/grub.cfg'"
assert "GRUB config references vmlinuz-linux-lts" "grep -q 'vmlinuz-linux-lts' '${REPO_ROOT}/doomos-builder/profile/grub/grub.cfg'"
assert "Kernel command line includes archisobasedir" "grep -q 'archisobasedir=' '${REPO_ROOT}/doomos-builder/profile/grub/grub.cfg'"
assert "Kernel command line defines live overlay cow_spacesize" "grep -q 'cow_spacesize=' '${REPO_ROOT}/doomos-builder/profile/grub/grub.cfg'"

# Summary
echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}PHASE 2 ACCEPTANCE TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}PHASE 2 ACCEPTANCE TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
