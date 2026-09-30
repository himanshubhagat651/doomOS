#!/usr/bin/env bash
# ==============================================================================
# DoomOS VMware VM Generator & Launcher
# Creates an optimized VMware Virtual Machine (.vmwarevm / .vmx) bundle for DoomOS
# Compatible with VMware Fusion (macOS) and VMware Workstation (Linux/Windows)
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ISO="${BASE_DIR}/doomos-builder/output/doomos-plasma-x86_64.iso"
TARGET_ISO="${1:-$DEFAULT_ISO}"
VM_NAME="DoomOS"
VM_BUNDLE="${BASE_DIR}/${VM_NAME}.vmwarevm"
VMX_FILE="${VM_BUNDLE}/${VM_NAME}.vmx"

echo -e "${CYAN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}          DoomOS VMware Fusion / Workstation Setup               ${RESET}"
echo -e "${CYAN}================================================================${RESET}"

if [[ ! -f "$TARGET_ISO" ]]; then
    echo -e "${RED}[ERROR] ISO image not found at: ${TARGET_ISO}${RESET}"
    echo -e "Please ensure Phase 6 build completes first."
    exit 1
fi

HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"

echo -e "${GREEN}[*] Target ISO:${RESET} ${TARGET_ISO}"
echo -e "${GREEN}[*] Host OS:${RESET} ${HOST_OS} (${HOST_ARCH})"

# Create VMware VM bundle directory
mkdir -p "$VM_BUNDLE"

echo -e "${CYAN}[*] Generating optimized VMware configuration (${VMX_FILE})...${RESET}"

cat <<EOF > "$VMX_FILE"
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "20"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
vmci0.present = "TRUE"
hpet0.present = "TRUE"
nvram = "${VM_NAME}.nvram"
virtualHW.productCompatibility = "hosted"
displayName = "DoomOS (KDE Plasma 6)"
guestOS = "archlinux-64"

# CPU & Memory
numvcpus = "4"
cpuid.coresPerSocket = "4"
memsize = "4096"

# UEFI Modern Boot
firmware = "efi"
uefi.secureBoot.enabled = "FALSE"

# CD-ROM with DoomOS ISO
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.fileName = "${TARGET_ISO}"
sata0:0.deviceType = "cdrom-image"
sata0:0.startConnected = "TRUE"

# 3D Graphics Acceleration
mks.enable3d = "TRUE"
svga.graphicsMemoryKB = "2097152"
svga.autodetect = "TRUE"

# High-Performance Virtual Disk (NVMe)
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "${VM_NAME}.vmdk"

# Sound & Network
sound.present = "TRUE"
sound.virtualDev = "hdaudio"
sound.autodetect = "TRUE"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "e1000e"
ethernet0.wakeOnPdc = "TRUE"

# USB 3.1 Controller
usb.present = "TRUE"
ehci.present = "TRUE"
usb_xhci.present = "TRUE"
EOF

echo -e "${GREEN}[OK] VMware configuration bundle generated:${RESET} ${VM_BUNDLE}"

# Check for Apple Silicon compatibility notice
if [[ "$HOST_OS" == "Darwin" ]] && [[ "$HOST_ARCH" == "arm64" ]]; then
    echo ""
    echo -e "${YELLOW}${BOLD}[NOTICE FOR APPLE SILICON MACS]${RESET}"
    echo -e "VMware Fusion on Apple Silicon (M1/M2/M3/M4) virtualizes ARM64 natively."
    echo -e "Because DoomOS is a high-performance x86_64 OS with Zen kernel & proprietary NVIDIA stack:"
    echo -e "  - ${GREEN}Option A (Recommended for Apple Silicon):${RESET} Launch via ${BOLD}UTM${RESET} (using './test-qemu.sh'), which provides full x86_64 TCG emulation."
    echo -e "  - ${GREEN}Option B (Bare-Metal PC / Intel Mac):${RESET} Copy '${VM_BUNDLE}' to any Intel Mac or Windows/Linux PC running VMware Workstation Pro."
    echo -e "  - ${GREEN}Option C (Direct Fusion Launch):${RESET} Open '${VM_BUNDLE}' directly in VMware Fusion if using an Intel Mac."
    echo ""
fi

VMRUN="/Applications/VMware Fusion.app/Contents/Public/vmrun"
if [[ -x "$VMRUN" ]] && [[ "$HOST_ARCH" == "x86_64" ]]; then
    read -p "Would you like to start the VM now in VMware Fusion? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        "$VMRUN" -T fusion start "$VMX_FILE" gui
    fi
elif [[ -d "/Applications/VMware Fusion.app" ]]; then
    echo -e "VM bundle is ready. To inspect in VMware Fusion:"
    echo -e "  open \"${VM_BUNDLE}\""
fi
