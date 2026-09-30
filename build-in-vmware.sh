#!/usr/bin/env bash
# ==============================================================================
# DoomOS Native VMware Builder (No Docker Required)
# Run this script directly inside an Arch Linux Virtual Machine in VMware
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS NATIVE VMWARE BUILD ENGINE (NO DOCKER)                        ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Check Root Privileges
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script must be run as root inside your VMware Linux VM.${RESET}"
    echo -e "Please run with: sudo $0"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${PROJECT_DIR}/doomos-builder/profile"
OUTPUT_DIR="${PROJECT_DIR}/doomos-builder/output"
WORK_DIR="/tmp/doomos-work"

# 2. Check Architecture
ARCH="$(uname -m)"
echo -e "${GREEN}[*] Native VM Architecture:${RESET} ${ARCH}"
if [[ "$ARCH" != "x86_64" ]]; then
    echo -e "${YELLOW}[!] Warning: Building x86_64 ISO on ${ARCH} VM may require QEMU binfmt emulation.${RESET}"
fi

# 3. Install Native Dependencies
echo -e "\n${CYAN}[*] Step 1: Installing native ISO mastering toolchain via pacman...${RESET}"
pacman -Sy --needed --noconfirm \
    archiso \
    git \
    squashfs-tools \
    dosfstools \
    libisoburn \
    xorriso \
    grub \
    mtools \
    e2fsprogs \
    btrfs-progs \
    zstd

# 4. Prepare Directories
echo -e "\n${CYAN}[*] Step 2: Preparing clean build workspace at ${WORK_DIR}...${RESET}"
mkdir -p "${OUTPUT_DIR}"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

# 5. Execute mkarchiso natively
echo -e "\n${CYAN}[*] Step 3: Compiling, compressing (Zstd 19), and mastering ISO...${RESET}"
mkarchiso -v -w "${WORK_DIR}" -o "${OUTPUT_DIR}" "${PROFILE_DIR}"

# 6. Verify and Standardize ISO
echo -e "\n${CYAN}[*] Step 4: Post-build verification and checksum generation...${RESET}"
GENERATED_ISO=$(find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "doomos-plasma-*.iso" | head -n 1)

if [[ -z "${GENERATED_ISO}" ]]; then
    echo -e "${RED}[ERROR] No ISO file was generated in ${OUTPUT_DIR}!${RESET}"
    exit 1
fi

STANDARDIZED_ISO="${OUTPUT_DIR}/doomos-plasma-x86_64.iso"
if [[ "${GENERATED_ISO}" != "${STANDARDIZED_ISO}" ]]; then
    cp -f "${GENERATED_ISO}" "${STANDARDIZED_ISO}"
fi

# Generate SHA256
cd "${OUTPUT_DIR}"
sha256sum "$(basename "${STANDARDIZED_ISO}")" > "doomos-plasma-x86_64.iso.sha256"

ISO_SIZE=$(du -h "${STANDARDIZED_ISO}" | awk '{print $1}')
echo -e "\n${BOLD}${GREEN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS ISO SUCCESSFULLY BUILT IN VMWARE!                             ${RESET}"
echo -e "${BOLD}${GREEN}========================================================================${RESET}"
echo -e "Master ISO:  ${STANDARDIZED_ISO} (${ISO_SIZE})"
echo -e "SHA256 File: ${OUTPUT_DIR}/doomos-plasma-x86_64.iso.sha256"
cat "${OUTPUT_DIR}/doomos-plasma-x86_64.iso.sha256"
