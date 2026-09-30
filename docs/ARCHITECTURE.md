# DoomOS Architecture Specification & Design Freeze (v1.0.0 ARM64 Edition)

**Document Status:** FROZEN  
**Target Milestone:** v1.0.0 (ARM64 / aarch64 + UEFI + VMware Fusion on Apple Silicon Mac)  
**Author:** Lead Linux Distribution & Kernel Architecture Team  
**Date:** 2026-10-01  

---

## 1. Executive Summary & Architecture Boundary

DoomOS is a high-performance, deterministic Linux operating system engineered from the ground up for modern 64-bit ARM architecture (`aarch64`), with primary first-class support for **VMware Fusion UEFI virtual machines on Apple Silicon Macs (M1/M2/M3/M4)**.

Per explicit engineering mandate, the v1.0.0 release is focused exclusively on **Apple Silicon ARM64 (`aarch64`)**. Support for Intel/AMD (`x86_64`) is planned for subsequent milestones after the macOS Apple Silicon platform is fully finalized and validated.

---

## 2. Core Architectural Pillars

### 2.1 Target Architecture
- **Processor Architecture:** `aarch64` (ARM64 strictly for current milestone).
- **Instruction Set Baseline:** ARMv8-A baseline (compatible with Apple Silicon virtualized CPU cores).
- **Byte Order:** Little-Endian.
- **Future Support:** `x86_64` (Intel/AMD) planned for milestone v2.0 after ARM64 validation.

### 2.2 Build Host Architecture
- **Authoritative CI Build Environment:** Linux ARM64 running in GitHub Actions (`ubuntu-24.04-arm` 4-vCPU native ARM64 runner) or multi-arch container engine.
- **Local Host Separation:** Developers may manage repository sources from macOS (Apple Silicon ARM64), but target compilation and ISO mastering are authoritatively orchestrated in CI. Docker is never required to run locally on the developer's Mac. The final ISO is booted directly inside VMware Fusion on macOS.

### 2.3 Kernel Strategy
- **Kernel Series:** Linux ARM64 Kernel (`linux-aarch64`) version 6.x branch.
- **Kernel Image Path:** `/boot/vmlinuz-linux-aarch64`
- **Architectural Rationale:** The `linux-aarch64` kernel provides native support for Apple Hypervisor virtualized devices, VirtIO subsystems, and VMware virtual hardware under ARM64.
- **Mandatory Kernel Drivers:**
  - *VMware / Virtualization Hardware:* `vmwgfx` (VMware DRM / Wayland graphics), `vmw_balloon`, `vmw_vmci`, `vmxnet3` (VMware virtual NIC), `virtio_pci`, `virtio_gpu`, `virtio_net`, `nvme`.
  - *Storage & Filesystems:* `btrfs`, `squashfs`, `overlay`, `ext4`, `fat` (`vfat`), `iso9660`, `loop`.
  - *Console & Display:* `efifb` (EFI framebuffer), `simplefb`, `drm_kms_helper`.
  - *Input & Bus:* `hid`, `usbhid`, `pci_core`.

### 2.4 C Standard Library (Libc) Strategy
- **Implementation:** GNU C Library (`glibc`) version 2.40+ (aarch64).
- **Architecture Support:** Pure 64-bit ARM (`aarch64`).

### 2.5 Toolchain & Compilers
- **C/C++ Compiler:** GCC 14+ (GNU Compiler Collection).
- **Assembler & Linker:** GNU Binutils (`ld.bfd`, `as`).
- **Archive & Compression Tools:** GNU `tar`, GNU `coreutils`, `zstd` (v1.5+).
- **ISO Mastering Suite:** `xorriso` (v1.5+), `mtools`, `dosfstools` (`mkfs.vfat`), `archiso` git master.

### 2.6 Userspace Strategy
- **Core Ecosystem:** Arch Linux ARM (ALARM) rolling base with custom DoomOS system manifests.
- **Desktop Environment:** KDE Plasma 6 (pure Wayland session via `plasma-workspace`, eliminating legacy X11 session server packages).
- **Display Manager:** SDDM (Simple Desktop Display Manager) configured for Wayland greeting and live-session auto-login.
- **Shells:** GNU Bash 5.2+ (`/bin/bash`) as POSIX default; Zsh 5.9+ (`/bin/zsh`) pre-configured with Starship prompt and fastfetch system telemetry.

### 2.7 Init System
- **Implementation:** `systemd` (version 256+) as PID 1 (`/sbin/init` symlinked to `/usr/lib/systemd/systemd`).
- **Core Responsibilities:**
  1. Initialize early kernel virtual filesystems (`/proc`, `/sys`, `/dev`, `/run`).
  2. Launch and supervise `systemd-udevd` for deterministic kernel device discovery and coldplug uevents.
  3. Mount local filesystems according to `/etc/fstab` with Btrfs subvolume declarations.
  4. Bring up network connectivity via `NetworkManager.service`.
  5. Supervise background daemons (`vmtoolsd.service`, `pipewire.service`, `sddm.service`).
  6. Manage journal logging with rate-limiting and persistent crash diagnostics.

### 2.8 Root Filesystem Layout
Standard unified Filesystem Hierarchy Standard (FHS) with merged `/usr`:
```text
/
├── bin -> usr/bin
├── sbin -> usr/bin
├── lib -> usr/lib
├── usr/
│   ├── bin/
│   ├── lib/
│   ├── share/
│   └── include/
├── etc/
├── var/
│   └── log/
├── dev/
├── proc/
├── sys/
├── run/
├── tmp/
├── home/
├── root/
└── .snapshots/
```

### 2.9 Storage & Filesystem Architecture
- **Live Media Filesystem:** Compressed SquashFS image (`airootfs.sfs`) using high-ratio Zstandard compression (`zstd -Xcompression-level 19 -b 1M`).
- **Overlay Storage:** `overlayfs` utilizing a 4GB tmpfs cowspace (`cow_spacesize=4G`) for non-persistent live operations.
- **Target Installed Filesystem:** Btrfs formatted with zstd transparent compression.
  - Subvolume `@` -> Mounted at `/` (root)
  - Subvolume `@home` -> Mounted at `/home`
  - Subvolume `@snapshots` -> Mounted at `/.snapshots`
  - Subvolume `@var_log` -> Mounted at `/var/log`

### 2.10 Initramfs Strategy
- **Generator:** `mkinitcpio` (Arch Linux modular initramfs pipeline).
- **Core Hooks:** `base`, `udev`, `memdisk`, `archiso`, `archiso_loop_mnt`, `kms`, `block`, `btrfs`, `filesystems`, `keyboard`.
- **Output Artifact:** `/boot/initramfs-linux-aarch64.img`.
- **Initramfs Role:**
  1. Load virtual hardware storage controllers (`nvme`, `virtio_pci`, `mptspi`).
  2. Locate boot media matching label `DOOMOS_LIVE`.
  3. Mount SquashFS image and establish tmpfs writeable overlay.
  4. Pivot-root into target root filesystem and exec PID 1.

### 2.11 Bootloader & UEFI Strategy
- **Primary Firmware Target:** UEFI 2.8+ 64-bit strictly (`BOOTAA64.EFI`).
- **Bootloader Implementation:** GRUB (`uefi.grub` / `arm64-efi`).
- **UEFI Boot Binary:** `\EFI\BOOT\BOOTAA64.EFI` installed inside a dedicated FAT12/16/32 EFI System Partition (ESP).
- **El Torito Structure:** ISO containing El Torito boot catalog with EFI System Partition image.

### 2.12 Kernel Command Line Contract
```text
archisobasedir=doomos archisolabel=DOOMOS_LIVE cow_spacesize=4G copytoram=n nvme_load=yes loglevel=3 splash quiet
```

### 2.13 Networking Strategy
- **Stack:** NetworkManager with `systemd-resolved` DNS stub resolver.
- **Live Network Policy:** Auto-connect on virtual Ethernet (`vmxnet3`, `virtio-net`) via DHCP.
- **Firewall:** `nftables` enabled with baseline stateful inspection.

### 2.14 Device Management Strategy
- **Udev Manager:** `systemd-udevd`.
- **Subsystem Guardians:**
  - *Btrfs Snapper Engine:* Automated transaction snapshots (`snap-pac`) synchronized to GRUB boot menus via `grub-btrfsd`.
  - *VMware Dynamic Wayland Resizer:* Auto-detection of window geometry changes in VMware Fusion on macOS.
  - *ZRAM Swap Engine:* Dynamic RAM compression to protect 4GB–8GB virtual machines from OOM killer.
  - *VMware Shared Folder Automount:* Automated mounting of host shared directories at `/mnt/hgfs`.

### 2.15 Package Management Strategy (Milestone v1.0.0)
- **Tool:** `pacman` with Arch Linux ARM (ALARM) repositories (`[core]`, `[extra]`, `[alarm]`).
- **Package Manifest:** `profile/packages.aarch64` defining exact package manifests for graphics, audio, desktop, and virtualization.

### 2.16 ISO Creation Method
- **Builder Suite:** `mkarchiso` executed within an isolated containerized Linux ARM64 environment.
- **Output Filename:** `doomos-plasma-aarch64.iso` (standardized)
- **Volume Identifier:** `DOOMOS_LIVE`
- **Compression:** Zstandard level 19, 1MB block size.

### 2.17 VMware Virtual Hardware Profile (Apple Silicon Mac)
- **Virtual Machine Software:** VMware Fusion 13.5+ (macOS on Apple Silicon).
- **Guest Operating System Identifier:** `guestOS = "arm-other-64"` or `"arm-ubuntu-64"`.
- **Hardware Version:** `virtualHW.version = "21"`.
- **Firmware:** `firmware = "efi"`.
- **RAM Allocation:** 4096 MB – 8192 MB.
- **vCPUs:** 4 cores minimum.
- **Display Controller:** 3D Accelerated Graphics enabled (Metal backed).
- **Storage Controller:** NVMe virtual disk.

### 2.18 CI Build Environment
- **Platform:** GitHub Actions runner `ubuntu-24.04-arm` (native ARM64 4-vCPU).
- **Determinism:** Pinned dependencies, isolated container workspace, pre-build workspace purification.

### 2.19 Release Artifact Strategy
- **Distribution Architecture:** GitHub Releases with multipart split chunk packaging.
- **Split Threshold:** 2000 MB per chunk (`part00`, `part01`, ...).
- **Integrity Validation:** SHA256 cryptographic verification file (`doomos-plasma-aarch64.iso.sha256`).
- **Client Tool:** Reassembly script `combine.sh` ensuring bit-for-bit reconstruction on macOS.
- **VMware Automation:** `test-vmware.sh` creating and launching the `.vmwarevm` bundle on macOS with 1 command.
