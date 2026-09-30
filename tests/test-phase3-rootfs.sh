#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Phase 3: Root Filesystem & System Initialization
# Validates rootfs staging, system identity, systemd service supervision,
# and desktop environment parameters.
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIROOTFS="${REPO_ROOT}/doomos-builder/profile/airootfs"
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
echo -e "${BOLD}${GREEN}   DOOMOS ACCEPTANCE TEST SUITE — PHASE 3: ROOTFS & INIT SYSTEM         ${RESET}"
echo -e "${CYAN}========================================================================${RESET}"

# 1. System Identity Audit
echo -e "\n${BOLD}${CYAN}1. Rootfs System Identity Audit${RESET}"
assert "System identity /etc/os-release exists" "[[ -f '${AIROOTFS}/etc/os-release' ]]"
assert "OS ID is set to doomos" "grep -q 'ID=doomos' '${AIROOTFS}/etc/os-release'"
assert "System hostname /etc/hostname exists" "[[ -f '${AIROOTFS}/etc/hostname' ]]"
assert "Hostname is set to doomos" "grep -q 'doomos' '${AIROOTFS}/etc/hostname'"

# 2. Init System & Service Enablement Audit
echo -e "\n${BOLD}${CYAN}2. Init System & Services Audit${RESET}"
assert "Rootfs customization script exists" "[[ -f '${AIROOTFS}/root/customize_airootfs.sh' ]]"
assert "Customization script enables sddm.service" "grep -q 'sddm.service' '${AIROOTFS}/root/customize_airootfs.sh'"
assert "Customization script enables NetworkManager.service" "grep -q 'NetworkManager.service' '${AIROOTFS}/root/customize_airootfs.sh'"
assert "Customization script enables vmtoolsd.service (VMware)" "grep -q 'vmtoolsd.service' '${AIROOTFS}/root/customize_airootfs.sh'"
assert "Customization script enables grub-btrfsd.service (Rollback)" "grep -q 'grub-btrfsd.service' '${AIROOTFS}/root/customize_airootfs.sh'"

# 3. User Environment & Sudoers Audit
echo -e "\n${BOLD}${CYAN}3. User Environment & Desktop Audit${RESET}"
assert "Customization script provisions liveuser" "grep -q 'useradd -m .* liveuser' '${AIROOTFS}/root/customize_airootfs.sh'"
assert "Customization script configures passwordless sudo" "grep -q 'NOPASSWD' '${AIROOTFS}/root/customize_airootfs.sh'"
assert "Default skeleton .bashrc exists" "[[ -f '${AIROOTFS}/etc/skel/.bashrc' ]]"
assert "Default skeleton .zshrc exists" "[[ -f '${AIROOTFS}/etc/skel/.zshrc' ]]"
assert "SDDM autologin configuration exists" "[[ -f '${AIROOTFS}/etc/sddm.conf.d/liveuser.conf' ]]"
assert "KWin Wayland low-latency tearing enabled" "grep -q 'AllowTearingAtFullscreen=true' '${AIROOTFS}/etc/xdg/kwinrc'"
assert "HiDPI fractional scaling environment variables set" "grep -q 'QT_QPA_PLATFORM=\"wayland;xcb\"' '${AIROOTFS}/etc/environment.d/10-hidpi.conf'"

# 4. Six Problem-Solving Subsystems Audit
echo -e "\n${BOLD}${CYAN}4. Six Problem-Solving Subsystems Staging Audit${RESET}"
assert "Subsystem 1: NVIDIA Guardian hook exists" "[[ -f '${AIROOTFS}/usr/share/libalpm/hooks/90-doomos-nvidia-guardian.hook' ]]"
assert "Subsystem 1: NVIDIA verification binary exists" "[[ -f '${AIROOTFS}/usr/bin/doomos-nvidia-verify' ]]"
assert "Subsystem 2: Btrfs Snapper root config deployed" "[[ -f '${AIROOTFS}/etc/snapper/configs/root' ]]"
assert "Subsystem 3: PipeWire audio loopback sink configured" "grep -q 'DoomOS Meeting Share Sink' '${AIROOTFS}/etc/pipewire/pipewire.conf.d/10-loopback-share.conf' || grep -q 'doomos_share_sink' '${AIROOTFS}/etc/pipewire/pipewire.conf.d/10-loopback-share.conf'"
assert "Subsystem 4: Developer sysctl memory tuning configured" "grep -q '2147483642' '${AIROOTFS}/etc/sysctl.d/99-developer-performance.conf'"
assert "Subsystem 5: Deep S3/S2Idle laptop power policy configured" "grep -q 'deep s2idle' '${AIROOTFS}/etc/systemd/sleep.conf.d/10-doomos-power.conf'"
assert "Subsystem 6: HDR game launcher wrapper exists" "[[ -f '${AIROOTFS}/usr/bin/doom-game' ]]"

# Summary
echo -e "\n${CYAN}========================================================================${RESET}"
if [[ ${PASS_COUNT} -eq ${TOTAL_CHECKS} ]]; then
    echo -e "${BOLD}${GREEN}PHASE 3 ACCEPTANCE TESTS PASSED: ${PASS_COUNT}/${TOTAL_CHECKS} checks successful.${RESET}"
    exit 0
else
    echo -e "${BOLD}${RED}PHASE 3 ACCEPTANCE TESTS FAILED: ${PASS_COUNT}/${TOTAL_CHECKS} checks passed.${RESET}"
    exit 1
fi
