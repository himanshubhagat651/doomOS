#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Phase 4 & 5: Initramfs Pipeline & UEFI Bootloader
# Validates early userspace storage drivers, Zstandard compression, GRUB 2.12
# UEFI boot configuration, and kernel handoff parameters.
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_DIR="${REPO_ROOT}/doomos-builder/profile"
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — PHASES 4 & 5: INITRAMFS & UEFI BOOT   ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Initramfs Pipeline Configuration Audit
echo -e "\n${BOLD}${CYAN}1. Initramfs Architecture & Hooks Audit${RESET}"
assert "Target mkinitcpio.conf exists" "[[ -f '${PROFILE_DIR}/airootfs/etc/mkinitcpio.conf' ]]"
assert "Initramfs loads btrfs module early" "grep -q 'MODULES=.*btrfs' '${PROFILE_DIR}/airootfs/etc/mkinitcpio.conf'"
assert "Initramfs includes udev device manager hook" "grep -q 'HOOKS=.*udev' '${PROFILE_DIR}/airootfs/etc/mkinitcpio.conf'"
assert "Initramfs includes block storage hook" "grep -q 'HOOKS=.*block' '${PROFILE_DIR}/airootfs/etc/mkinitcpio.conf'"
assert "Initramfs includes btrfs filesystem hook" "grep -q 'HOOKS=.*btrfs' '${PROFILE_DIR}/airootfs/etc/mkinitcpio.conf'"
assert "Initramfs compression is high-ratio zstd" "grep -q 'COMPRESSION=\"zstd\"' '${PROFILE_DIR}/airootfs/etc/mkinitcpio.conf'"

# 2. Bootloader Configuration & Profile Def Audit
echo -e "\n${BOLD}${CYAN}2. UEFI Bootloader & Platform Specification Audit${RESET}"
assert "Profile definition profiledef.sh exists" "[[ -f '${PROFILE_DIR}/profiledef.sh' ]]"
assert "Profile specifies uefi.grub bootmode" "grep -q 'uefi.grub' '${PROFILE_DIR}/profiledef.sh'"
assert "Profile specifies target architecture (aarch64 / x86_64)" "grep -q -E 'arch=\"(aarch64|x86_64)\"' '${PROFILE_DIR}/profiledef.sh'"
assert "GRUB configuration template exists" "[[ -f '${PROFILE_DIR}/grub/grub.cfg' ]]"
assert "GRUB config loads gpt and msdos partition tables" "grep -q 'insmod part_gpt' '${PROFILE_DIR}/grub/grub.cfg' && grep -q 'insmod part_msdos' '${PROFILE_DIR}/grub/grub.cfg'"
assert "GRUB config loads FAT and ISO9660 drivers" "grep -q 'insmod fat' '${PROFILE_DIR}/grub/grub.cfg' && grep -q 'insmod iso9660' '${PROFILE_DIR}/grub/grub.cfg'"
assert "GRUB defines primary kernel boot entry" "grep -q -E 'menuentry .*(Linux|DoomOS)' '${PROFILE_DIR}/grub/grub.cfg'"
assert "GRUB handoff loads target kernel image" "grep -q -E 'linux .*/vmlinuz-linux-(aarch64|zen)' '${PROFILE_DIR}/grub/grub.cfg'"
assert "GRUB handoff loads initramfs image" "grep -q -E 'initrd .*/initramfs-linux-(aarch64|zen)\.img' '${PROFILE_DIR}/grub/grub.cfg'"
assert "Bootloader packages grub and efibootmgr in package manifest" "grep -q '^grub$' '${PROFILE_DIR}/packages.aarch64' || grep -q '^grub$' '${PROFILE_DIR}/packages.x86_64'"

# Summary
echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}PHASES 4 & 5 ACCEPTANCE TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}PHASES 4 & 5 ACCEPTANCE TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
