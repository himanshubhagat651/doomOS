#!/usr/bin/env bash
# ==============================================================================
# DoomOS Build Environment & Dependency Validator
# Verifies that the host build system satisfies all prerequisites for mastering
# the x86_64 UEFI DoomOS distribution.
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS BUILD ENVIRONMENT VALIDATOR                                  ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

ERRORS=0

check_cmd() {
    local CMD="$1"
    local DESC="$2"
    echo -ne "  [*] Checking for ${DESC} (${CMD}) ... "
    if command -v "$CMD" >/dev/null 2>&1; then
        local VERSION
        VERSION=$("$CMD" --version 2>/dev/null | head -n 1 || echo "installed")
        echo -e "${GREEN}FOUND${RESET} [${VERSION}]"
    else
        echo -e "${RED}MISSING${RESET}"
        ERRORS=$((ERRORS + 1))
    fi
}

# 1. Architecture Check
echo -e "\n${BOLD}${CYAN}1. Host CPU Architecture${RESET}"
HOST_ARCH=$(uname -m)
echo -ne "  [*] Host architecture: ${HOST_ARCH} ... "
if [[ "$HOST_ARCH" == "aarch64" || "$HOST_ARCH" == "arm64" ]]; then
    echo -e "${GREEN}COMPATIBLE (Native ARM64 Host)${RESET}"
elif [[ "$HOST_ARCH" == "x86_64" ]]; then
    echo -e "${GREEN}COMPATIBLE (x86_64 Host)${RESET}"
else
    echo -e "${YELLOW}CROSS-ENVIRONMENT DETECTED${RESET}"
fi

# 2. Core POSIX and Compression Tools
echo -e "\n${BOLD}${CYAN}2. Core Build Utilities & Compression Engines${RESET}"
check_cmd "bash" "GNU Bourne Again Shell"
check_cmd "tar" "GNU Tar"
check_cmd "zstd" "Zstandard Compression Suite"
check_cmd "gzip" "GNU Gzip"
check_cmd "sha256sum" "Coreutils SHA256 Checksum (or shasum)" || check_cmd "shasum" "SHA Checksum Utility"

# 3. ISO Mastering Tools (Required on native build host)
echo -e "\n${BOLD}${CYAN}3. ISO Mastering & Filesystem Engines${RESET}"
check_cmd "xorriso" "Rock Ridge / Joliet / El Torito ISO Master"
check_cmd "mksquashfs" "SquashFS Filesystem Creator"
check_cmd "mcopy" "Mtools FAT Manipulator"
check_cmd "mkfs.vfat" "Dosfstools EFI Partition Formatter"

# 4. Git & Repository Management
echo -e "\n${BOLD}${CYAN}4. Version Control & Packaging${RESET}"
check_cmd "git" "Git Version Control System"

# 5. Disk Space Verification
echo -e "\n${BOLD}${CYAN}5. Free Disk Space Verification${RESET}"
if command -v df >/dev/null 2>&1; then
    FREE_GB=$(df -BG . 2>/dev/null | tail -n 1 | awk '{print $4}' | sed 's/G//' || echo 0)
    echo -ne "  [*] Available disk space: ${FREE_GB} GB ... "
    if [[ "$FREE_GB" -ge 20 ]]; then
        echo -e "${GREEN}SUFFICIENT (>= 20 GB)${RESET}"
    else
        echo -e "${YELLOW}WARNING (< 20 GB available, recommend at least 25 GB for full build)${RESET}"
    fi
fi

# Summary
echo -e "\n${CYAN}========================================================================${RESET}"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${BOLD}${GREEN}ENVIRONMENT VALIDATION PASSED: System ready for DoomOS compilation.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}ENVIRONMENT VALIDATION FAILED: ${ERRORS} mandatory build dependencies missing.${RESET}"
    echo -e "Please install the missing tools using your system package manager."
    exit 1
fi
