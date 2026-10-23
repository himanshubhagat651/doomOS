#!/usr/bin/env bash
# ==============================================================================
# DoomOS Acceptance Test Suite — Step 4: Immortal Boot & Subsystems
# ==============================================================================
set -euo pipefail

PASS=0
FAIL=0

check_pass() {
    echo -e "  [CHECK $1] $2 ... \033[0;32mPASS\033[0m"
    PASS=$((PASS + 1))
}

check_fail() {
    echo -e "  [CHECK $1] $2 ... \033[0;31mFAIL\033[0m"
    FAIL=$((FAIL + 1))
}

echo "========================================================================"
echo "   DOOMOS ACCEPTANCE TEST SUITE — STEP 4: IMMORTAL BOOT & SUBSYSTEMS    "
echo "========================================================================"

# 1. Subsystem 1: Immortal Boot (Automated Btrfs Snapshot Rollback)
echo -e "\n1. Subsystem 1: Automated Btrfs Rollback (Snapper & grub-btrfs)"
SNAPPER_CONF="doomos-builder/profile/airootfs/etc/snapper/configs/root"
if [[ -f "${SNAPPER_CONF}" ]]; then
    check_pass 1 "Snapper root subvolume config exists (${SNAPPER_CONF})"
else
    check_fail 1 "Missing ${SNAPPER_CONF}"
fi

if grep -q "TIMELINE_CREATE=\"yes\"" "${SNAPPER_CONF}" 2>/dev/null && grep -q "NUMBER_LIMIT=\"10\"" "${SNAPPER_CONF}" 2>/dev/null; then
    check_pass 2 "Snapper enforces TIMELINE_CREATE=yes and NUMBER_LIMIT=10"
else
    check_fail 2 "Snapper configuration does not enforce retention limits"
fi

if grep -q "snapper" doomos-builder/profile/packages.aarch64 && grep -q "snap-pac" doomos-builder/profile/packages.aarch64 && grep -q "grub-btrfs" doomos-builder/profile/packages.aarch64; then
    check_pass 3 "Package manifest includes snapper, snap-pac, and grub-btrfs"
else
    check_fail 3 "Package manifest missing snapper or rollback tools"
fi

if grep -q "grub-btrfsd.service" doomos-builder/profile/airootfs/root/customize_airootfs.sh; then
    check_pass 4 "customize_airootfs.sh enables grub-btrfsd.service daemon"
else
    check_fail 4 "grub-btrfsd.service is not enabled in customize_airootfs.sh"
fi

# 2. Subsystem 2: DoomOS Guardian (DKMS Driver Safety Hook)
echo -e "\n2. Subsystem 2: DoomOS Guardian (DKMS Driver Safety Hook)"
HOOK_FILE="doomos-builder/profile/airootfs/usr/share/libalpm/hooks/90-doomos-nvidia-guardian.hook"
VERIFY_BIN="doomos-builder/profile/airootfs/usr/bin/doomos-nvidia-verify"

if [[ -f "${HOOK_FILE}" ]]; then
    check_pass 5 "ALPM Guardian hook exists (${HOOK_FILE})"
else
    check_fail 5 "Missing ALPM Guardian hook"
fi

if grep -q "Target = nvidia-dkms" "${HOOK_FILE}" && grep -q "When = PostTransaction" "${HOOK_FILE}"; then
    check_pass 6 "Guardian hook triggers PostTransaction on driver upgrades"
else
    check_fail 6 "Guardian hook missing target trigger configuration"
fi

if [[ -x "${VERIFY_BIN}" ]]; then
    check_pass 7 "Guardian verification script is executable (${VERIFY_BIN})"
else
    check_fail 7 "Guardian verification script missing or not executable"
fi

if bash -n "${VERIFY_BIN}"; then
    check_pass 8 "Guardian verification script compiles without syntax errors"
else
    check_fail 8 "Syntax errors detected in Guardian verification script"
fi

# 3. Subsystem 3: Developer Kernel & Inotify Performance Tuning
echo -e "\n3. Subsystem 3: Developer Kernel & Inotify Performance Tuning"
SYSCTL_CONF="doomos-builder/profile/airootfs/etc/sysctl.d/99-developer-performance.conf"

if [[ -f "${SYSCTL_CONF}" ]]; then
    check_pass 9 "Developer sysctl configuration exists (${SYSCTL_CONF})"
else
    check_fail 9 "Missing ${SYSCTL_CONF}"
fi

if grep -q "fs.inotify.max_user_watches = 1048576" "${SYSCTL_CONF}" && \
   grep -q "fs.inotify.max_user_instances = 2048" "${SYSCTL_CONF}"; then
    check_pass 10 "Sysctl configures high-capacity inotify watcher limits (1048576)"
else
    check_fail 10 "Sysctl missing required inotify limits"
fi

if grep -q "vm.max_map_count = 2147483642" "${SYSCTL_CONF}" && \
   grep -q "net.core.somaxconn = 8192" "${SYSCTL_CONF}"; then
    check_pass 11 "Sysctl configures vm.max_map_count (2147483642) and somaxconn (8192)"
else
    check_fail 11 "Sysctl missing memory map or socket connection backlog tuning"
fi

# 4. Subsystem 4: PipeWire Audio Loopback & Wayland Portal
echo -e "\n4. Subsystem 4: PipeWire Audio Loopback & Wayland Portal"
PW_CONF="doomos-builder/profile/airootfs/etc/pipewire/pipewire.conf.d/10-loopback.conf"

if [[ -f "${PW_CONF}" ]]; then
    check_pass 12 "PipeWire audio loopback profile exists (${PW_CONF})"
else
    check_fail 12 "Missing PipeWire loopback configuration"
fi

if grep -q "libpipewire-module-loopback" "${PW_CONF}" && \
   grep -q "doomos_share_sink" "${PW_CONF}" && \
   grep -q "doomos_share_source" "${PW_CONF}"; then
    check_pass 13 "PipeWire loopback module defines shared sink and source nodes"
else
    check_fail 13 "PipeWire loopback configuration missing node definitions"
fi

if grep -q "xdg-desktop-portal-kde" doomos-builder/profile/packages.aarch64 && \
   grep -q "pipewire" doomos-builder/profile/packages.aarch64; then
    check_pass 14 "Packages manifest includes xdg-desktop-portal-kde and pipewire"
else
    check_fail 14 "Missing xdg-desktop-portal-kde or pipewire in package manifest"
fi

# 5. Subsystem 5: Laptop Power & Deep Sleep Optimization
echo -e "\n5. Subsystem 5: Laptop Power & Deep Sleep Policy"
SLEEP_CONF="doomos-builder/profile/airootfs/etc/systemd/sleep.conf.d/10-doomos-sleep.conf"

if [[ -f "${SLEEP_CONF}" ]]; then
    check_pass 15 "Systemd sleep configuration exists (${SLEEP_CONF})"
else
    check_fail 15 "Missing ${SLEEP_CONF}"
fi

if grep -q "MemorySleepMode=deep s2idle" "${SLEEP_CONF}"; then
    check_pass 16 "Sleep config specifies MemorySleepMode=deep s2idle"
else
    check_fail 16 "Sleep config missing deep s2idle sleep mode"
fi

if grep -q "power-profiles-daemon" doomos-builder/profile/packages.aarch64 && \
   grep -q "power-profiles-daemon.service" doomos-builder/profile/airootfs/root/customize_airootfs.sh; then
    check_pass 17 "Power profiles daemon packaged and enabled in customize_airootfs.sh"
else
    check_fail 17 "Power profiles daemon not configured"
fi

echo "========================================================================"
if [[ "${FAIL}" -eq 0 ]]; then
    echo -e "\033[0;32mSTEP 4 SUBSYSTEM TESTS PASSED: ${PASS}/${PASS} checks successful.\033[0m\n"
    exit 0
else
    echo -e "\033[0;31mSTEP 4 SUBSYSTEM TESTS FAILED: ${FAIL} failure(s) detected.\033[0m\n"
    exit 1
fi
