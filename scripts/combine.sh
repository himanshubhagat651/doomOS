#!/usr/bin/env bash
# ==============================================================================
# DoomOS ISO Reassembly & Cryptographic Integrity Verifier
# Reconstructs multipart release chunks (*.iso.part*) into the unified bootable ISO
# and strictly verifies cryptographic SHA256 checksum integrity.
# Works across Linux (sha256sum) and macOS (shasum -a 256).
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# 1. Detect base directory independent of caller's cwd
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS MULTIPART REASSEMBLY & INTEGRITY VERIFIER                     ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 2. Check for checksum tools (strict compliance: fail if neither exists)
CALC_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    CALC_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    CALC_CMD="shasum -a 256"
else
    echo -e "${BOLD}${RED}[FATAL ERROR] Neither 'sha256sum' (Linux) nor 'shasum' (macOS) was found on PATH.${RESET}"
    echo -e "Checksum verification is mandatory. Please install coreutils or perl."
    exit 1
fi

# 3. Detect SHA256 checksum file
SHA_FILE=$(find "$BASE_DIR" -maxdepth 1 -name "*.iso.sha256" | head -n 1)
if [[ -z "$SHA_FILE" || ! -f "$SHA_FILE" ]]; then
    echo -e "${BOLD}${RED}[FATAL ERROR] Authoritative SHA256 file (*.iso.sha256) not found in ${BASE_DIR}.${RESET}"
    echo -e "Please ensure the .sha256 file is downloaded alongside the release chunks."
    exit 1
fi

EXPECTED_ISO_NAME=$(awk '{print $2}' "$SHA_FILE" | sed 's/^\*//' | tr -d '\r\n')
EXPECTED_HASH=$(awk '{print $1}' "$SHA_FILE" | tr -d '\r\n')
OUTPUT_ISO="${BASE_DIR}/${EXPECTED_ISO_NAME}"

echo -e "${CYAN}[*] Target ISO to reconstruct:${RESET} ${BOLD}${EXPECTED_ISO_NAME}${RESET}"
echo -e "${CYAN}[*] Authoritative SHA256:${RESET}      ${EXPECTED_HASH}"

# 4. Detect part files matching pattern
PARTS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && PARTS+=("$line")
done < <(find "$BASE_DIR" -maxdepth 1 -name "${EXPECTED_ISO_NAME}.part*" -o -name "*.iso.part*" | sort -V | uniq)

if [[ ${#PARTS[@]} -eq 0 ]]; then
    echo -e "\n${BOLD}${RED}[FATAL ERROR] No multipart chunks found matching '*.iso.part*' in ${BASE_DIR}!${RESET}"
    echo -e "Please download all part chunks (e.g. part00, part01, ...) from GitHub Releases."
    exit 1
fi

echo -e "\n${GREEN}[*] Discovered ${#PARTS[@]} multipart chunks:${RESET}"
for p in "${PARTS[@]}"; do
    FILE_SIZE=$(stat -f%z "$p" 2>/dev/null || stat -c%s "$p" 2>/dev/null || echo 0)
    if [[ "$FILE_SIZE" -le 0 ]]; then
        echo -e "${BOLD}${RED}[FATAL ERROR] Chunk $(basename "$p") is EMPTY (0 bytes). Download corrupted.${RESET}"
        exit 1
    fi
    HUMAN_SIZE=$(du -h "$p" | awk '{print $1}')
    echo -e "    - ${BOLD}$(basename "$p")${RESET} (${HUMAN_SIZE}, ${FILE_SIZE} bytes)"
done

# 5. Numerical sequence validation
echo -e "\n${CYAN}[*] Validating chunk sequence and checking for gaps...${RESET}"
FIRST_PART=$(basename "${PARTS[0]}")
# Extract suffix
SUFFIX="${FIRST_PART##*.part}"
if [[ "$SUFFIX" =~ ^[0-9]+$ ]]; then
    EXPECTED_IDX=$((10#$SUFFIX))
    for p in "${PARTS[@]}"; do
        P_NAME=$(basename "$p")
        P_SUFFIX="${P_NAME##*.part}"
        P_IDX=$((10#$P_SUFFIX))
        if [[ $P_IDX -ne $EXPECTED_IDX ]]; then
            echo -e "${BOLD}${RED}[FATAL ERROR] Missing part chunk detected! Expected index ${EXPECTED_IDX}, got ${P_IDX} (${P_NAME}).${RESET}"
            exit 1
        fi
        EXPECTED_IDX=$((EXPECTED_IDX + 1))
    done
    echo -e "  ${GREEN}[PASS] Sequential part sequence verified without missing chunks.${RESET}"
fi

# 6. Recombine parts
TEMP_OUTPUT="${OUTPUT_ISO}.tmp"
rm -f "$TEMP_OUTPUT"
echo -e "\n${CYAN}[*] Concatenating ${#PARTS[@]} chunks into: ${OUTPUT_ISO}...${RESET}"
cat "${PARTS[@]}" > "$TEMP_OUTPUT"
mv "$TEMP_OUTPUT" "$OUTPUT_ISO"
RECON_SIZE=$(du -h "$OUTPUT_ISO" | awk '{print $1}')
echo -e "${GREEN}[OK] Reassembly complete.${RESET} Total size: ${BOLD}${RECON_SIZE}${RESET}"

# 7. Strictly verify SHA256 integrity
echo -e "\n${CYAN}[*] Calculating cryptographic SHA256 checksum (${CALC_CMD})...${RESET}"
ACTUAL_HASH=$(cd "$BASE_DIR" && $CALC_CMD "$(basename "$OUTPUT_ISO")" | awk '{print $1}')

echo -e "  - Expected:     ${BOLD}${EXPECTED_HASH}${RESET}"
echo -e "  - Reconstructed: ${BOLD}${ACTUAL_HASH}${RESET}"

if [[ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]]; then
    echo -e "\n${BOLD}${GREEN}========================================================================${RESET}"
    echo -e "${BOLD}${GREEN}   VERIFICATION SUCCESSFUL: SHA256 CHECKSUM MATCHED!                   ${RESET}"
    echo -e "${BOLD}${GREEN}========================================================================${RESET}"
    echo -e "DoomOS ISO is 100% verified, untampered, and ready for deployment."
    echo -e "\nNext steps:"
    echo -e "  - Launch in VMware:   ${BOLD}./scripts/test-vmware.sh${RESET} or ${BOLD}./test-vmware.sh${RESET}"
    echo -e "  - Flash to USB Drive: ${BOLD}./scripts/flash-usb.sh${RESET} or ${BOLD}./flash-usb.sh${RESET}"
    exit 0
else
    echo -e "\n${BOLD}${RED}========================================================================${RESET}"
    echo -e "${BOLD}${RED}   VERIFICATION FAILED: SHA256 CHECKSUM MISMATCH!                      ${RESET}"
    echo -e "${BOLD}${RED}========================================================================${RESET}"
    echo -e "The reconstructed ISO does NOT match the authoritative release signature."
    echo -e "One or more chunks may have experienced network transmission corruption."
    exit 1
fi
