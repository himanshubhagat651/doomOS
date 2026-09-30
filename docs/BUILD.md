# DoomOS Build & Engineering Guide

**Target Audience:** Release Engineers, Systems Architects, and Distribution Developers  
**Target Architecture:** `x86_64`  
**Target Firmware:** `UEFI`  

---

## 1. Build Host vs. Target Architecture

Building an operating system requires strict separation between the development machine and the build environment:

- **Development Host:** Can be macOS (Apple Silicon or Intel) or Linux.
- **Build Host:** Must be an authoritative **Linux x86_64** environment with root privileges (for mounting filesystems, creating loop devices, and chroot isolation).
- **Target OS:** DoomOS is strictly **x86_64 UEFI**.

---

## 2. Prerequisites & Host Requirements

A supported Linux x86_64 build host requires:
- Kernel: Linux 5.15+ (with overlayfs and squashfs modules)
- RAM: Minimum 8 GB (16 GB recommended)
- Disk Space: 30 GB free space on a high-speed filesystem
- Installed Tools:
  - `archiso` (>= 70)
  - `xorriso` (>= 1.5.4)
  - `zstd` (>= 1.5.0)
  - `mtools` & `dosfstools`
  - `squashfs-tools`
  - `git`, `coreutils`, `sha256sum`, `bash`

Run the build environment verification script before initiating any compilation:
```bash
./scripts/check-build-environment.sh
```

---

## 3. Build Workflows

### 3.1 Authoritative Automated Build (GitHub Actions)
The primary production build environment is GitHub Actions running on `ubuntu-latest` x86_64.
- Triggered automatically on push to `main` or release tag.
- Can be manually dispatched via `workflow_dispatch` with a custom release tag.

### 3.2 Native Build in an Arch Linux Virtual Machine
For local builds without Docker:
1. Boot an Arch Linux x86_64 virtual machine in VMware Fusion/Workstation.
2. Clone the repository:
   ```bash
   git clone https://github.com/himanshubhagat651/doomOS.git
   cd doomOS
   ```
3. Run the native build script:
   ```bash
   sudo ./scripts/build-in-vmware.sh
   ```

### 3.3 Containerized Build
To execute inside a controlled OCI container:
```bash
cd doomos-builder
./run-builder.sh
```

---

## 4. Build Pipeline Stages

Every official build strictly executes:
1. **Clean Workspace:** All previous output directories, work directories, and temporary files are purged.
2. **Environment Validation:** Kernel headers, packages, and tools are verified.
3. **Rootfs Preparation (`airootfs`):** Core configurations, 6 problem-solving subsystems, SDDM autologin, and Calamares branding are staged.
4. **Package Installation:** `mkarchiso` populates the rootfs from upstream repositories.
5. **SquashFS Compression:** High-efficiency Zstandard level 19 compression with 1MB block size.
6. **UEFI Boot Sector Integration:** FAT EFI partition generation with `BOOTX64.EFI` and El Torito hybrid boot sectors.
7. **ISO Mastering:** `xorriso` outputs `DoomOS-x86_64-UEFI-vX.Y.Z.iso`.
8. **Static Verification:** 20-point test suite (`./tests/verify-iso.sh`).
9. **Multipart Splitting:** Split into sequential `part00`, `part01`, etc. (2000 MB chunks).
10. **Reassembly & SHA256 Verification:** Automatic recombination test verifying bit-for-bit parity before release.
