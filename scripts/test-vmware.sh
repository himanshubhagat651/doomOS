#!/usr/bin/env bash
# ==============================================================================
# DoomOS VMware VM Generator & Launcher (Apple Silicon ARM64 & PC Edition)
# Generates an optimized VMware Fusion (.vmwarevm) bundle for DoomOS
# Native 64-bit ARM hypervisor execution on Apple Silicon (M1/M2/M3/M4)
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"

# Auto-detect target ISO
TARGET_ISO="${1:-}"
if [[ -z "$TARGET_ISO" ]]; then
    if [[ -f "${BASE_DIR}/doomos-plasma-aarch64.iso" ]]; then
        TARGET_ISO="${BASE_DIR}/doomos-plasma-aarch64.iso"
    elif [[ -f "${BASE_DIR}/doomos-builder/output/doomos-plasma-aarch64.iso" ]]; then
        TARGET_ISO="${BASE_DIR}/doomos-builder/output/doomos-plasma-aarch64.iso"
    elif [[ -f "${BASE_DIR}/doomos-plasma-x86_64.iso" ]]; then
        TARGET_ISO="${BASE_DIR}/doomos-plasma-x86_64.iso"
    elif [[ -f "${BASE_DIR}/doomos-builder/output/doomos-plasma-x86_64.iso" ]]; then
        TARGET_ISO="${BASE_DIR}/doomos-builder/output/doomos-plasma-x86_64.iso"
    else
        # Find any *.iso
        TARGET_ISO=$(find "$BASE_DIR" -maxdepth 2 -name "*.iso" 2>/dev/null | head -n 1 || echo "")
    fi
fi

VM_NAME="DoomOS-Mac"
VM_BUNDLE="${BASE_DIR}/${VM_NAME}.vmwarevm"
VMX_FILE="${VM_BUNDLE}/${VM_NAME}.vmx"

echo -e "${CYAN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}     DoomOS VMware Fusion Setup — Apple Silicon Mac Edition     ${RESET}"
echo -e "${CYAN}================================================================${RESET}"

if [[ -z "$TARGET_ISO" || ! -f "$TARGET_ISO" ]]; then
    echo -e "${YELLOW}[INFO] Reassembled ISO not found directly in root.${RESET}"
    echo -e "If you downloaded multipart chunks from GitHub Releases, run:"
    echo -e "  ${BOLD}./combine.sh${RESET}"
    echo -e "Target ISO will be detected automatically."
    TARGET_ISO="${BASE_DIR}/doomos-plasma-aarch64.iso"
fi

echo -e "${GREEN}[*] Target ISO:${RESET} ${TARGET_ISO}"
echo -e "${GREEN}[*] Host OS:${RESET}    ${HOST_OS} (${HOST_ARCH})"

# Determine guestOS based on architecture
GUEST_OS="arm-other-64"
HW_VER="21"
if [[ "$HOST_ARCH" == "x86_64" ]] || [[ "$TARGET_ISO" == *"x86_64"* ]]; then
    GUEST_OS="archlinux-64"
    HW_VER="20"
fi

mkdir -p "$VM_BUNDLE"
echo -e "${CYAN}[*] Generating optimized VMware Fusion configuration (${VMX_FILE})...${RESET}"

cat <<EOF > "$VMX_FILE"
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "${HW_VER}"
displayName = "DoomOS (Apple Silicon ARM64)"
guestOS = "${GUEST_OS}"

# CPU & Memory (Optimized for Apple Silicon M-series)
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

# 3D Graphics Acceleration (Metal backed in VMware Fusion)
mks.enable3d = "TRUE"
svga.graphicsMemoryKB = "2097152"
svga.autodetect = "TRUE"

# Virtual Disk (NVMe)
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "${VM_NAME}.vmdk"

# Sound & Network (vmxnet3 high-speed virtual NIC)
sound.present = "TRUE"
sound.virtualDev = "hdaudio"
sound.autodetect = "TRUE"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "vmxnet3"
ethernet0.wakeOnPdc = "TRUE"

# USB 3.1 Controller
usb.present = "TRUE"
ehci.present = "TRUE"
usb_xhci.present = "TRUE"

# VMware Tools & Shared Folders
isolation.tools.copy.disable = "FALSE"
isolation.tools.paste.disable = "FALSE"
isolation.tools.dnd.disable = "FALSE"
EOF

echo -e "${GREEN}[OK] VMware configuration bundle generated:${RESET} ${VM_BUNDLE}"

if [[ -d "/Applications/VMware Fusion.app" ]]; then
    echo -e "\n${BOLD}${GREEN}[READY TO LAUNCH]${RESET} Opening DoomOS in VMware Fusion..."
    open -a "VMware Fusion" "$VM_BUNDLE" || open "$VM_BUNDLE"
else
    echo -e "\n${YELLOW}[INFO] VMware Fusion not found in /Applications.${RESET}"
    echo -e "You can open '${VM_BUNDLE}' directly once VMware Fusion is installed."
fi
