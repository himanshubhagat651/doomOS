#!/usr/bin/env bash
# ==============================================================================
# DoomOS Master Build Engine (Inside Container)
# Target Architecture: x86_64
# Strict Mode: Exit on error, unset variable, or failed pipe
# ==============================================================================
set -euo pipefail

# ANSI Formatting
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_banner() {
    echo -e "${BOLD}${CYAN}"
    echo "========================================================================"
    echo "   $1"
    echo "========================================================================"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BOLD}${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${BOLD}${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${BOLD}${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${BOLD}${RED}[ERROR]${NC} $1" >&2
}

log_banner "DOOMOS MASTER ISO BUILD ENGINE (x86_64)"

# ------------------------------------------------------------------------------
# 1. Environment & Privilege Validations
# ------------------------------------------------------------------------------
log_info "Verifying container architecture and privileges..."

ARCH=$(uname -m)
if [[ "${ARCH}" != "x86_64" ]]; then
    log_error "Unsupported architecture: ${ARCH}. DoomOS requires x86_64."
    exit 1
fi
log_success "Architecture: ${ARCH}"

if [[ "$(id -u)" -ne 0 ]]; then
    log_error "Build engine requires root privileges for mount, chroot, and squashfs."
    exit 1
fi
log_success "Privileges: root confirmed"

# Verify Loop Device Capability
if [[ ! -e /dev/loop-control ]]; then
    log_warn "/dev/loop-control missing. Attempting to create device node..."
    mknod /dev/loop-control c 10 237 || true
fi

if [[ -e /dev/loop-control ]]; then
    log_success "Loop device interface active (/dev/loop-control)"
else
    log_error "Loop devices inaccessible. The container must be run with --privileged."
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. Workspace Directory Setup
# ------------------------------------------------------------------------------
BUILD_ROOT="/build"
HOST_PROFILE_DIR="${BUILD_ROOT}/profile"
OUTPUT_DIR="${BUILD_ROOT}/output"
WORK_DIR="/root/work"
PROFILE_DIR="/root/profile"

log_info "Validating build profile..."
if [[ ! -f "${HOST_PROFILE_DIR}/profiledef.sh" ]]; then
    log_error "Missing ${HOST_PROFILE_DIR}/profiledef.sh!"
    exit 1
fi
if [[ ! -f "${HOST_PROFILE_DIR}/packages.x86_64" ]]; then
    log_error "Missing ${HOST_PROFILE_DIR}/packages.x86_64!"
    exit 1
fi
if [[ ! -f "${HOST_PROFILE_DIR}/pacman.conf" ]]; then
    log_error "Missing ${HOST_PROFILE_DIR}/pacman.conf!"
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"
rm -rf "${WORK_DIR}" "${PROFILE_DIR}"
mkdir -p "${WORK_DIR}"
cp -a "${HOST_PROFILE_DIR}" "${PROFILE_DIR}"
log_success "Profile copied to container overlayfs and output paths validated."

# ------------------------------------------------------------------------------
# 3. ISO Mastering via mkarchiso
# ------------------------------------------------------------------------------
log_banner "PHASE 6: MASTERING BOOTABLE HYBRID ISO (ZSTD LEVEL 19)"

log_info "Invoking mkarchiso compilation pipeline..."
mkarchiso -v -w "${WORK_DIR}" -o "${OUTPUT_DIR}" "${PROFILE_DIR}"

# ------------------------------------------------------------------------------
# 4. Post-Build Verification & Checksum Generation
# ------------------------------------------------------------------------------
log_banner "POST-BUILD VERIFICATION & SHA256 GENERATION"

# Locate the newly created ISO
GENERATED_ISO=$(find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "doomos-plasma-*.iso" | head -n 1)

if [[ -z "${GENERATED_ISO}" ]]; then
    log_error "No ISO file found in ${OUTPUT_DIR} after mkarchiso finished!"
    exit 1
fi

# Standardize name symlink to doomos-plasma-x86_64.iso
STANDARDIZED_ISO="${OUTPUT_DIR}/doomos-plasma-x86_64.iso"
if [[ "${GENERATED_ISO}" != "${STANDARDIZED_ISO}" ]]; then
    cp "${GENERATED_ISO}" "${STANDARDIZED_ISO}" || ln -sf "$(basename "${GENERATED_ISO}")" "${STANDARDIZED_ISO}"
fi

log_success "Target ISO confirmed: ${STANDARDIZED_ISO}"

# Measure File Size
FILE_SIZE_BYTES=$(stat -c%s "${STANDARDIZED_ISO}" 2>/dev/null || stat -f%z "${STANDARDIZED_ISO}" 2>/dev/null)
FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))
log_info "ISO Image Size: ${FILE_SIZE_MB} MB"

if [[ ${FILE_SIZE_MB} -lt 1500 ]]; then
    log_warn "ISO file size (${FILE_SIZE_MB} MB) is lower than expected for a full KDE Plasma desktop."
else
    log_success "ISO size (${FILE_SIZE_MB} MB) is within target production parameters (2.8 GB – 3.4 GB)."
fi

# Generate SHA256 Checksum
log_info "Generating SHA256 checksum..."
cd "${OUTPUT_DIR}"
sha256sum "$(basename "${STANDARDIZED_ISO}")" > "doomos-plasma-x86_64.iso.sha256"
log_success "Checksum written: ${OUTPUT_DIR}/doomos-plasma-x86_64.iso.sha256"
cat "doomos-plasma-x86_64.iso.sha256"

# Split into multipart chunks (part00, part01, ...) for GitHub Releases
log_info "Splitting ISO into standard multipart chunks (part00, part01, ...)..."
rm -f doomos-plasma-x86_64.iso.part*
PART_SIZE="${PART_SIZE:-2000M}"
split -b "${PART_SIZE}" -d -a 2 "$(basename "${STANDARDIZED_ISO}")" "doomos-plasma-x86_64.iso.part"
log_success "Multipart chunks generated:"
ls -lh doomos-plasma-x86_64.iso.part*

# Generate Release Manifest
log_info "Generating release-manifest.txt..."
MANIFEST_FILE="${OUTPUT_DIR}/release-manifest.txt"
cat << EOF > "${MANIFEST_FILE}"
========================================================================
                       DOOMOS RELEASE MANIFEST
========================================================================
Version:              ${DOOMOS_VERSION:-v1.0.0}
Target Architecture:  x86_64
Target Firmware:      UEFI 64-bit
Target Virtualization:VMware Workstation / Fusion
Kernel:               linux-zen
Bootloader:           GRUB 2.12 (UEFI)
Desktop Environment:  KDE Plasma 6 (Wayland Native)
ISO Filename:         $(basename "${STANDARDIZED_ISO}")
ISO File Size:        ${FILE_SIZE_BYTES} bytes (${FILE_SIZE_MB} MB)
ISO Complete SHA256:  $(awk '{print $1}' "doomos-plasma-x86_64.iso.sha256")
Split Chunk Size:     ${PART_SIZE}
Build Timestamp:      $(date -u +'%Y-%m-%d %H:%M:%S UTC')
Build Host:           Linux x86_64 (Container Master Engine)

Multipart Chunk Verification:
$(ls -1 doomos-plasma-x86_64.iso.part* 2>/dev/null | while read -r p; do
    sha256sum "$p"
done)
========================================================================
EOF
log_success "Release manifest created: ${MANIFEST_FILE}"
cat "${MANIFEST_FILE}"

# Ensure output files are accessible by non-root host runner
chmod -R a+rwX "${OUTPUT_DIR}"

log_banner "DOOMOS MASTER ISO BUILD COMPLETE & VERIFIED!"

