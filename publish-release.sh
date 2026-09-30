#!/usr/bin/env bash
# ==============================================================================
# DoomOS GitHub Release Publisher
# Automates Git tagging, repository publishing, and uploading ISO assets to GitHub Releases
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
TITLE="DoomOS ${TAG} (KDE Plasma 6 Rolling)"
NOTES_FILE="${PROJECT_ROOT}/RELEASE_NOTES.md"
ISO_FILE="${PROJECT_ROOT}/doomos-builder/output/doomos-plasma-x86_64.iso"
SHA_FILE="${PROJECT_ROOT}/doomos-builder/output/doomos-plasma-x86_64.iso.sha256"

echo -e "${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS GITHUB RELEASES AUTOMATION                                    ${RESET}"
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

# 2. Verify Release Assets
if [[ ! -f "$ISO_FILE" ]]; then
    echo -e "${RED}[ERROR] Release ISO not found at: ${ISO_FILE}${RESET}"
    echo -e "Please run the build pipeline first ('./doomos-builder/run-builder.sh')."
    exit 1
fi

if [[ ! -f "$SHA_FILE" ]]; then
    echo -e "${YELLOW}[*] Generating missing SHA256 checksum...${RESET}"
    (cd "$(dirname "$ISO_FILE")" && sha256sum "$(basename "$ISO_FILE")" > "$(basename "$SHA_FILE")")
fi
echo -e "${GREEN}[OK] ISO and SHA256 checksum confirmed.${RESET}"

# 3. Ensure Git Repository & Remote Configuration
cd "$PROJECT_ROOT"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${CYAN}[*] Initializing local git repository...${RESET}"
    git init
fi

# Configure .gitignore to avoid committing huge work directories
cat << 'EOF' > .gitignore
doomos-builder/work/
doomos-builder/cache/
*.vmwarevm/
.DS_Store
EOF

git add .gitignore *.md *.sh *.pdf doomos-builder/Dockerfile doomos-builder/build.sh doomos-builder/run-builder.sh doomos-builder/profile/ .github/ 2>/dev/null || true
git commit -m "chore(release): prepare DoomOS ${TAG} release assets and build engine" 2>/dev/null || true

# Check if remote origin exists
if ! git remote get-url origin >/dev/null 2>&1; then
    echo -e "${YELLOW}[!] Git remote 'origin' is not set.${RESET}"
    echo -e "${CYAN}[*] Creating remote repository on GitHub under current authenticated account...${RESET}"
    gh repo create DoomOS --public --source=. --remote=origin --push || {
        echo -e "${YELLOW}[!] Repo may already exist. Attempting to add remote...${RESET}"
        USER_NAME=$(gh api user -q .login)
        git remote add origin "https://github.com/${USER_NAME}/DoomOS.git" || true
        git push -u origin HEAD || true
    }
else
    echo -e "${CYAN}[*] Pushing latest commits to origin...${RESET}"
    git push -u origin HEAD || true
fi

# 4. Create GitHub Release & Upload Assets
echo -e "${CYAN}[*] Publishing release ${TAG} to GitHub Releases...${RESET}"

ASSETS=(
    "$ISO_FILE"
    "$SHA_FILE"
)

# Attach PDF manuals if available
if [[ -f "${PROJECT_ROOT}/DoomOS_Master_Specification.pdf" ]]; then
    ASSETS+=("${PROJECT_ROOT}/DoomOS_Master_Specification.pdf")
fi
if [[ -f "${PROJECT_ROOT}/TESTING_GUIDE.pdf" ]]; then
    ASSETS+=("${PROJECT_ROOT}/TESTING_GUIDE.pdf")
fi

gh release create "${TAG}" "${ASSETS[@]}" \
    --title "${TITLE}" \
    --notes-file "${NOTES_FILE}" \
    --verify-tag

echo -e "\n${BOLD}${GREEN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   DOOMOS ${TAG} SUCCESSFULLY PUBLISHED TO GITHUB RELEASES!                ${RESET}"
echo -e "${BOLD}${GREEN}========================================================================${RESET}"
gh release view "${TAG}" --web || gh release view "${TAG}"
