#!/usr/bin/env bash
# ==============================================================================
# DoomOS Bare-Metal USB Flashing Utility
# Safe, cross-platform USB burning tool with guardrails against system disk overwrites
# ==============================================================================

set -euo pipefail

# Visual stylings
BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

ISO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ISO="${ISO_DIR}/doomos-builder/output/doomos-plasma-x86_64.iso"
TARGET_ISO="${1:-$DEFAULT_ISO}"

echo -e "${CYAN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}          DoomOS USB Installer Flasher                           ${RESET}"
echo -e "${CYAN}================================================================${RESET}"

if [[ ! -f "$TARGET_ISO" ]]; then
    echo -e "${RED}[ERROR] ISO file not found at: ${TARGET_ISO}${RESET}"
    echo -e "Please ensure Phase 6 build has finished, or pass ISO path explicitly:"
    echo -e "  $0 /path/to/doomos-plasma-x86_64.iso"
    exit 1
fi

ISO_SIZE=$(du -h "$TARGET_ISO" | awk '{print $1}')
echo -e "${GREEN}[INFO] Target ISO:${RESET} ${TARGET_ISO} (${ISO_SIZE})"

# Verify SHA256 if available
if [[ -f "${TARGET_ISO}.sha256" ]]; then
    echo -e "${CYAN}[*] Verifying ISO SHA256 integrity...${RESET}"
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$(dirname "$TARGET_ISO")" && sha256sum -c "$(basename "${TARGET_ISO}.sha256")") || {
            echo -e "${RED}[ERROR] Checksum verification failed!${RESET}"
            exit 1
        }
    elif command -v shasum >/dev/null 2>&1; then
        (cd "$(dirname "$TARGET_ISO")" && shasum -a 256 -c "$(basename "${TARGET_ISO}.sha256")") || {
            echo -e "${RED}[ERROR] Checksum verification failed!${RESET}"
            exit 1
        }
    fi
    echo -e "${GREEN}[OK] Checksum verified successfully.${RESET}"
fi

echo ""
echo -e "${YELLOW}Available Block Devices:${RESET}"

OS_TYPE="$(uname -s)"
if [[ "$OS_TYPE" == "Darwin" ]]; then
    diskutil list external
    echo ""
    echo -e "${YELLOW}Enter the target disk identifier (e.g. /dev/disk4 or disk4):${RESET}"
    read -r SELECTED_DEV

    # Strip /dev/ if entered
    DEV_NAME="${SELECTED_DEV#/dev/}"

    # Guardrail checks for macOS
    if [[ -z "$DEV_NAME" ]]; then
        echo -e "${RED}[ERROR] No disk specified.${RESET}"
        exit 1
    fi

    # Check if disk is internal
    IS_INTERNAL=$(diskutil info "$DEV_NAME" | grep "Internal:" | awk '{print $2}' || true)
    if [[ "$IS_INTERNAL" == "Yes" ]]; then
        echo -e "${RED}[FATAL ERROR] Disk ${DEV_NAME} is an INTERNAL drive! Aborting to prevent data destruction.${RESET}"
        exit 1
    fi

    TARGET_RAW_DEV="/dev/r${DEV_NAME}"
    TARGET_DEV="/dev/${DEV_NAME}"

    echo -e "${RED}${BOLD}WARNING: ALL DATA ON ${TARGET_DEV} WILL BE COMPLETELY DESTROYED!${RESET}"
    echo -e "Device Details:"
    diskutil info "$DEV_NAME" | grep -E "Device / Media Name|Disk Size|Protocol" || true
    echo ""
    echo -e "Type ${BOLD}DOOM${RESET} to confirm and proceed with flashing:"
    read -r CONFIRM
    if [[ "$CONFIRM" != "DOOM" ]]; then
        echo -e "${YELLOW}Operation cancelled by user.${RESET}"
        exit 0
    fi

    echo -e "${CYAN}[*] Unmounting ${TARGET_DEV}...${RESET}"
    diskutil unmountDisk "$TARGET_DEV"

    echo -e "${CYAN}[*] Writing DoomOS image to ${TARGET_RAW_DEV} (this may take a few minutes)...${RESET}"
    sudo dd if="$TARGET_ISO" of="$TARGET_RAW_DEV" bs=4m status=progress

    echo -e "${CYAN}[*] Syncing buffers...${RESET}"
    sync

    echo -e "${CYAN}[*] Ejecting ${TARGET_DEV}...${RESET}"
    diskutil eject "$TARGET_DEV"

    echo -e "${GREEN}${BOLD}[SUCCESS] DoomOS USB successfully created on ${TARGET_DEV}!${RESET}"
    echo -e "You can now safely unplug the drive and boot your target PC."

elif [[ "$OS_TYPE" == "Linux" ]]; then
    lsblk -d -o NAME,SIZE,TYPE,TRAN,MODEL,VENDOR
    echo ""
    echo -e "${YELLOW}Enter the target drive name (e.g. /dev/sdb or sdb):${RESET}"
    read -r SELECTED_DEV

    DEV_NAME="${SELECTED_DEV#/dev/}"
    if [[ -z "$DEV_NAME" ]]; then
        echo -e "${RED}[ERROR] No disk specified.${RESET}"
        exit 1
    fi

    TARGET_DEV="/dev/${DEV_NAME}"

    # Guardrail checks for Linux
    # Check if this drive holds the root filesystem
    if mount | grep -q "^${TARGET_DEV}"; then
        ROOT_MNT=$(mount | grep "on / " | awk '{print $1}')
        if [[ "$ROOT_MNT" == "${TARGET_DEV}"* ]]; then
            echo -e "${RED}[FATAL ERROR] Target ${TARGET_DEV} contains the active ROOT filesystem! Aborting.${RESET}"
            exit 1
        fi
    fi

    echo -e "${RED}${BOLD}WARNING: ALL DATA ON ${TARGET_DEV} WILL BE PERMANENTLY DESTROYED!${RESET}"
    lsblk -p "$TARGET_DEV"
    echo ""
    echo -e "Type ${BOLD}DOOM${RESET} to confirm and proceed with flashing:"
    read -r CONFIRM
    if [[ "$CONFIRM" != "DOOM" ]]; then
        echo -e "${YELLOW}Operation cancelled by user.${RESET}"
        exit 0
    fi

    echo -e "${CYAN}[*] Unmounting any mounted partitions on ${TARGET_DEV}...${RESET}"
    sudo umount "${TARGET_DEV}"* 2>/dev/null || true

    echo -e "${CYAN}[*] Writing DoomOS image to ${TARGET_DEV}...${RESET}"
    sudo dd if="$TARGET_ISO" of="$TARGET_DEV" bs=4M status=progress oflag=sync

    echo -e "${CYAN}[*] Syncing kernel disk buffers...${RESET}"
    sync

    echo -e "${GREEN}${BOLD}[SUCCESS] DoomOS USB successfully created on ${TARGET_DEV}!${RESET}"
    echo -e "You can now safely reboot and select this USB in your UEFI boot menu."
fi
