#!/usr/bin/env bash
# ==============================================================================
# DoomOS GitHub Release Publisher (Multipart ISO Chunks)
# Automates Git tagging, splitting ISO into part01/part02, and publishing to GitHub Releases
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="${1:-v1.0.0}"
TITLE="DoomOS ${TAG} (KDE Plasma 6 VMware Edition)"
NOTES_FILE="${PROJECT_ROOT}/RELEASE_NOTES.md"
OUTPUT_DIR="${PROJECT_ROOT}/doomos-builder/output"
ISO_FILE="${OUTPUT_DIR}/doomos-plasma-x86_64.iso"
SHA_FILE="${OUTPUT_DIR}/doomos-plasma-x86_64.iso.sha256"

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS GITHUB RELEASES PUBLISHER (MULTIPART & SHA256)                ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Verify GitHub CLI Authentication
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] GitHub CLI ('gh') is not installed.${RESET}"
    echo -e "Please install via 'brew install gh' or your system package manager."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] GitHub CLI is not authenticated.${RESET}"
    echo -e "Please run 'gh auth login' first."
    exit 1
fi
echo -e "${GREEN}[OK] GitHub CLI is authenticated.${RESET}"

# 2. Check if ISO exists; if present, generate multipart chunks
ASSETS=()

if [[ -f "$ISO_FILE" ]]; then
    echo -e "${GREEN}[OK] Master ISO located:${RESET} ${ISO_FILE} ($(du -h "$ISO_FILE" | awk '{print $1}'))"
    
    # Generate SHA256
    echo -e "${CYAN}[*] Generating SHA256 checksum...${RESET}"
    (cd "$OUTPUT_DIR" && if command -v sha256sum >/dev/null 2>&1; then sha256sum "$(basename "$ISO_FILE")" > "$(basename "$SHA_FILE")"; else shasum -a 256 "$(basename "$ISO_FILE")" > "$(basename "$SHA_FILE")"; fi)
    echo -e "${GREEN}[OK] Checksum created:${RESET} ${SHA_FILE}"

    # Split into 2000M parts (part01, part02)
    echo -e "${CYAN}[*] Splitting ISO into 2000MB multipart chunks (part01, part02)...${RESET}"
    (
        cd "$OUTPUT_DIR"
        rm -f doomos-plasma-x86_64.iso.part*
        split -b 2000m -d -a 2 "$(basename "$ISO_FILE")" "doomos-plasma-x86_64.iso.part"
        if [[ -f "doomos-plasma-x86_64.iso.part00" ]]; then
            mv "doomos-plasma-x86_64.iso.part00" "doomos-plasma-x86_64.iso.part01"
        fi
        if [[ -f "doomos-plasma-x86_64.iso.part01" ]] && [[ ! -f "doomos-plasma-x86_64.iso.part02" ]]; then
            mv "doomos-plasma-x86_64.iso.part01" "doomos-plasma-x86_64.iso.part02" 2>/dev/null || true
        fi
    )

    for p in "${OUTPUT_DIR}"/doomos-plasma-x86_64.iso.part*; do
        if [[ -f "$p" ]]; then
            ASSETS+=("$p")
            echo -e "    - Prepared chunk: $(basename "$p") ($(du -h "$p" | awk '{print $1}'))"
        fi
    done
    ASSETS+=("$SHA_FILE")
fi

# Always attach helper tools and documentation
ASSETS+=(
    "${PROJECT_ROOT}/combine.sh"
    "${PROJECT_ROOT}/test-vmware.sh"
    "${PROJECT_ROOT}/flash-usb.sh"
)

if [[ -f "${PROJECT_ROOT}/DoomOS_Master_Specification.pdf" ]]; then
    ASSETS+=("${PROJECT_ROOT}/DoomOS_Master_Specification.pdf")
fi
if [[ -f "${PROJECT_ROOT}/TESTING_GUIDE.pdf" ]]; then
    ASSETS+=("${PROJECT_ROOT}/TESTING_GUIDE.pdf")
fi

# 3. Commit and Push to Remote
cd "$PROJECT_ROOT"
git add .
git commit -m "chore(release): configure GitHub Actions multipart release pipeline and combine.sh" || true

echo -e "\n${CYAN}[*] Target remote repository: $(git remote get-url origin 2>/dev/null || echo 'Not configured')${RESET}"
echo -e "${CYAN}[*] Pushing code to origin...${RESET}"
git push -u origin main || {
    echo -e "${YELLOW}[!] If push failed due to permissions or missing repo, please create 'doomOS' at https://github.com/new and run 'git push -u origin main'.${RESET}"
}

# 4. Create GitHub Release if assets exist
if [[ ${#ASSETS[@]} -gt 3 ]] && [[ -f "$ISO_FILE" ]]; then
    echo -e "\n${CYAN}[*] Creating GitHub Release ${TAG} with multipart assets...${RESET}"
    gh release create "${TAG}" "${ASSETS[@]}" \
        --title "${TITLE}" \
        --notes-file "${NOTES_FILE}" \
        --verify-tag
    echo -e "${GREEN}${BOLD}[SUCCESS] Release published to GitHub!${RESET}"
else
    echo -e "\n${CYAN}[INFO] Code pushed to GitHub. The GitHub Actions workflow will automatically build and publish the multipart ISO release!${RESET}"
fi
