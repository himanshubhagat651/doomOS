#!/usr/bin/env bash
# ==============================================================================
# DoomOS Cross-Platform Virtual Testing Utility (QEMU & UTM)
# Automatically adapts to host architecture and hypervisor availability
# ==============================================================================

set -euo pipefail

# Formatting colors
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
echo -e "${BOLD}${GREEN}          DoomOS Virtualization & Testing Runner                ${RESET}"
echo -e "${CYAN}================================================================${RESET}"

if [[ ! -f "$TARGET_ISO" ]]; then
    echo -e "${RED}[ERROR] ISO image not found at: ${TARGET_ISO}${RESET}"
    echo -e "Please ensure Phase 6 build completes first."
    exit 1
fi

HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"

echo -e "${GREEN}[*] Host OS:${RESET} ${HOST_OS}"
echo -e "${GREEN}[*] Host CPU Architecture:${RESET} ${HOST_ARCH}"
echo -e "${GREEN}[*] Boot ISO:${RESET} ${TARGET_ISO} ($(du -h "$TARGET_ISO" | awk '{print $1}'))"

# Define VM resources
RAM="4096"
CORES="4"

if [[ "$HOST_OS" == "Linux" ]]; then
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        echo -e "${RED}[ERROR] qemu-system-x86_64 is not installed.${RESET}"
        echo -e "Install with: sudo pacman -S qemu-desktop edk2-ovmf (Arch) or sudo apt install qemu-system-x86 ovmf (Debian/Ubuntu)"
        exit 1
    fi

    # Locate OVMF firmware
    OVMF_CODE=""
    for p in /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2-ovmf/x64/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
        if [[ -f "$p" ]]; then
            OVMF_CODE="$p"
            break
        fi
    done

    OVMF_ARGS=()
    if [[ -n "$OVMF_CODE" ]]; then
        echo -e "${GREEN}[*] Using UEFI Firmware:${RESET} ${OVMF_CODE}"
        OVMF_ARGS=(-drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}")
    fi

    ACCEL_ARGS=()
    if [[ "$HOST_ARCH" == "x86_64" ]] && [[ -e /dev/kvm ]] && [[ -r /dev/kvm ]] && [[ -w /dev/kvm ]]; then
        echo -e "${GREEN}[*] Hardware Acceleration: KVM Enabled${RESET}"
        ACCEL_ARGS=(-enable-kvm -cpu host)
    else
        echo -e "${YELLOW}[!] KVM not available; falling back to TCG multi-threading${RESET}"
        ACCEL_ARGS=(-accel tcg,thread=multi -cpu max)
    fi

    echo -e "${CYAN}[*] Launching QEMU VM...${RESET}"
    exec qemu-system-x86_64 \
        "${ACCEL_ARGS[@]}" \
        -m "${RAM}" \
        -smp "${CORES}" \
        -cdrom "${TARGET_ISO}" \
        -boot d \
        -vga virtio \
        -display default,show-cursor=on \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0 \
        -device intel-hda -device hda-duplex \
        "${OVMF_ARGS[@]}"

elif [[ "$HOST_OS" == "Darwin" ]]; then
    echo -e "${CYAN}[*] Running on macOS Darwin (${HOST_ARCH})${RESET}"

    # Check for UTM
    if [[ -d "/Applications/UTM.app" ]]; then
        echo -e "${GREEN}[*] Detected UTM Virtual Machine Environment${RESET}"
        echo -e "UTM provides the highest performance emulation of x86_64 guests on Apple Silicon."
        echo ""
        echo -e "You can boot DoomOS in UTM with 3 simple steps:"
        echo -e "  1. Open UTM (/Applications/UTM.app)"
        echo -e "  2. Click '+' -> 'Emulate' -> 'Linux'"
        echo -e "  3. Select Boot ISO: ${TARGET_ISO}"
        echo -e "     Allocate 4096MB RAM, 4 CPU cores, and enable UEFI."
        echo ""
        read -p "Would you like to open UTM now? [Y/n] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            open -a "/Applications/UTM.app"
        fi
        exit 0
    fi

    # Fallback to Homebrew QEMU if installed
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
        echo -e "${CYAN}[*] Launching Homebrew QEMU with TCG Emulation...${RESET}"
        exec qemu-system-x86_64 \
            -accel tcg,thread=multi \
            -cpu max \
            -m "${RAM}" \
            -smp "${CORES}" \
            -cdrom "${TARGET_ISO}" \
            -boot d \
            -vga virtio \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0 \
            -device intel-hda -device hda-duplex
    else
        echo -e "${YELLOW}[!] Neither UTM nor qemu-system-x86_64 was found.${RESET}"
        echo -e "Recommended options on macOS Apple Silicon:"
        echo -e "  1. Install UTM (Free GUI QEMU frontend): brew install --cask utm"
        echo -e "  2. Install QEMU CLI: brew install qemu"
        exit 1
    fi
fi
