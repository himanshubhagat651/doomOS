#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Phase 1: Build Environment & Toolchain System
# Verifies build manifest pinning, Dockerfile toolchain specification, and
# build-environment validation logic.
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — PHASE 1: BUILD ENVIRONMENT & TOOLCHAIN ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. Manifest Validation
echo -e "\n${BOLD}${CYAN}1. Build Environment Manifest Audit${RESET}"
assert "Build environment manifest exists" "[[ -f '${REPO_ROOT}/configs/build-environment.manifest' ]]"
assert "Manifest specifies target architecture aarch64 / x86_64" "grep -q -E 'TARGET_ARCH=\"(aarch64|x86_64)\"' '${REPO_ROOT}/configs/build-environment.manifest'"
assert "Manifest specifies target firmware UEFI" "grep -q 'TARGET_FIRMWARE=\"UEFI\"' '${REPO_ROOT}/configs/build-environment.manifest'"
assert "Manifest pins kernel package" "grep -q -E 'KERNEL_PACKAGE=\"(linux-aarch64|linux-zen)\"' '${REPO_ROOT}/configs/build-environment.manifest'"
assert "Manifest pins bootloader target as efi" "grep -q -E 'BOOTLOADER_TARGET=\"(arm64-efi|x86_64-efi)\"' '${REPO_ROOT}/configs/build-environment.manifest'"
assert "Manifest records required host packages" "grep -q 'REQUIRED_DEB_PACKAGES=' '${REPO_ROOT}/configs/build-environment.manifest'"

# 2. Build Environment Verification Script
echo -e "\n${BOLD}${CYAN}2. Build Environment Check Script Audit${RESET}"
assert "check-build-environment.sh exists" "[[ -f '${REPO_ROOT}/scripts/check-build-environment.sh' ]]"
assert "check-build-environment.sh is executable" "[[ -x '${REPO_ROOT}/scripts/check-build-environment.sh' ]]"
assert "check-build-environment.sh checks host architecture" "grep -q 'HOST_ARCH' '${REPO_ROOT}/scripts/check-build-environment.sh'"
assert "check-build-environment.sh checks compression tools (zstd, tar)" "grep -q 'zstd' '${REPO_ROOT}/scripts/check-build-environment.sh'"
assert "check-build-environment.sh checks ISO mastering tools (xorriso)" "grep -q 'xorriso' '${REPO_ROOT}/scripts/check-build-environment.sh'"

# 3. Containerized Toolchain Engine Specification
echo -e "\n${BOLD}${CYAN}3. Container Toolchain Engine Audit${RESET}"
assert "Dockerfile exists in doomos-builder" "[[ -f '${REPO_ROOT}/doomos-builder/Dockerfile' ]]"
assert "Dockerfile specifies container platform" "grep -q -- '--platform=' '${REPO_ROOT}/doomos-builder/Dockerfile'"
assert "Dockerfile installs archiso and xorriso" "grep -q 'archiso' '${REPO_ROOT}/doomos-builder/Dockerfile' && grep -q 'xorriso' '${REPO_ROOT}/doomos-builder/Dockerfile'"
assert "Dockerfile installs zstd and squashfs-tools" "grep -q 'zstd' '${REPO_ROOT}/doomos-builder/Dockerfile' && grep -q 'squashfs-tools' '${REPO_ROOT}/doomos-builder/Dockerfile'"
assert "run-builder.sh uses --privileged for loopback mounting" "grep -q -- '--privileged' '${REPO_ROOT}/doomos-builder/run-builder.sh'"

# Summary
echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}PHASE 1 ACCEPTANCE TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}PHASE 1 ACCEPTANCE TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
