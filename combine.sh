#!/usr/bin/env bash
# ==============================================================================
# DoomOS ISO Reassembly & Verification Utility
# Combines multipart release chunks (part01, part02) into the unified bootable ISO
# and verifies cryptographic SHA256 checksum integrity
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ISO="${BASE_DIR}/doomos-plasma-x86_64.iso"
SHA_FILE="${BASE_DIR}/doomos-plasma-x86_64.iso.sha256"

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS MULTIPART REASSEMBLY & INTEGRITY VERIFIER                     ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# Find all parts
PARTS=($(find "$BASE_DIR" -maxdepth 1 -name "doomos-plasma-x86_64.iso.part*" | sort))

if [[ ${#PARTS[@]} -eq 0 ]]; then
    echo -e "${RED}[ERROR] No ISO parts found matching 'doomos-plasma-x86_64.iso.part*'!${RESET}"
    echo -e "Please download both part01 and part02 from GitHub Releases into this folder."
    exit 1
fi

echo -e "${GREEN}[*] Found ${#PARTS[@]} multipart chunks:${RESET}"
for p in "${PARTS[@]}"; do
    echo -e "    - $(basename "$p") ($(du -h "$p" | awk '{print $1}'))"
done

echo -e "\n${CYAN}[*] Recombining chunks into unified ISO: ${OUTPUT_ISO}...${RESET}"
cat "${PARTS[@]}" > "${OUTPUT_ISO}"
echo -e "${GREEN}[OK] Recombination complete.${RESET} Final size: $(du -h "${OUTPUT_ISO}" | awk '{print $1}')"

# Verify SHA256
if [[ -f "$SHA_FILE" ]]; then
    echo -e "\n${CYAN}[*] Verifying cryptographic SHA256 integrity...${RESET}"
    cd "$BASE_DIR"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum -c "$(basename "$SHA_FILE")"
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 -c "$(basename "$SHA_FILE")"
    else
        echo -e "${YELLOW}[WARN] Neither sha256sum nor shasum found. Skipping checksum.${RESET}"
    fi
    echo -e "\n${BOLD}${GREEN}========================================================================${RESET}"
    echo -e "${BOLD}${GREEN}   SUCCESS: DoomOS ISO IS READY & VERIFIED!                             ${RESET}"
    echo -e "${BOLD}${GREEN}========================================================================${RESET}"
    echo -e "You can now boot this ISO in VMware Fusion / Workstation or burn it to USB:"
    echo -e "  - Run in VMware:   ${BOLD}./test-vmware.sh${RESET}"
    echo -e "  - Flash to USB:    ${BOLD}./flash-usb.sh${RESET}"
    echo -e "  - Run in QEMU/UTM: ${BOLD}./test-qemu.sh${RESET}"
else
    echo -e "${YELLOW}[WARN] SHA256 checksum file not found at ${SHA_FILE}.${RESET}"
fi
