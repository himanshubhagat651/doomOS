# DoomOS Architecture Specification & Design Freeze (v1.0.0)

**Document Status:** FROZEN  
**Target Milestone:** v1.0.0 (x86_64 + UEFI + VMware Virtual Machine & Bare-Metal)  
**Author:** Lead Linux Distribution & Kernel Architecture Team  
**Date:** 2026-10-01  

---

## 1. Executive Summary & Architecture Boundary

DoomOS is a high-performance, deterministic Linux operating system engineered from the ground up for x86_64 modern hardware with primary first-class support for **VMware UEFI virtual machines** and bare-metal UEFI workstations.

This specification establishes an immutable architecture freeze for the v1.0.0 milestone. No extraneous architectures (ARM64, 32-bit x86, RISC-V), non-UEFI firmware targets (Legacy BIOS/CSM), or unvetted experimental subsystems may be introduced without formal engineering change orders.

---

## 2. Core Architectural Pillars

### 2.1 Target Architecture
- **Processor Architecture:** `x86_64` (AMD64 / Intel 64-bit strictly).
- **Instruction Set Baseline:** x86-64-v2 baseline with runtime dynamic dispatch for AVX/AVX2 instructions.
- **Byte Order:** Little-Endian.

### 2.2 Build Host Architecture
- **Authoritative CI Build Environment:** Linux x86_64 running in GitHub Actions (`ubuntu-latest` x86_64 container runner).
- **Local Host Separation:** Developers may orchestrate builds from macOS (Apple Silicon ARM64) or Linux, but target compilation and ISO mastering are strictly isolated inside the authoritative x86_64 Linux container environment. Cross-architecture binary contamination is strictly forbidden.

### 2.3 Kernel Strategy
- **Kernel Series:** Linux Zen Kernel (`linux-zen`) version 6.x/7.x branch.
- **Kernel Image Path:** `/boot/vmlinuz-linux-zen`
- **Architectural Rationale:** The Zen kernel incorporates Liquorix and Zen interactive scheduler patches, PREEMPT low-latency desktop responsiveness, multi-queue I/O block scheduling (Kyber/BFQ), and tuned tickless idle timers, maximizing frame pacing under Wayland and virtualization environments.
- **Mandatory Kernel Drivers:**
  - *VMware Virtual Hardware:* `vmwgfx` (SVGA3D accelerated DRM), `vmw_balloon` (dynamic memory ballooning), `vmw_vmci` (VM communication interface), `vmxnet3` (10Gbps virtual NIC), `mptspi`/`mptsas` (LSI Logic virtual SCSI), `nvme` (VMware virtual NVMe controller).
  - *Storage & Filesystems:* `btrfs`, `squashfs`, `overlay`, `ext4`, `fat` (`vfat`), `iso9660`, `loop`.
  - *Console & Display:* `efifb` (EFI framebuffer), `simplefb`, `drm_kms_helper`.
  - *Input & Bus:* `hid`, `usbhid`, `psmouse`, `i8042`, `pci_core`.

### 2.4 C Standard Library (Libc) Strategy
- **Implementation:** GNU C Library (`glibc`) version 2.40+.
- **Multilib Support:** Full dual-abi runtime (`/lib64` for 64-bit and `/lib` / `/usr/lib32` for 32-bit x86 applications). This guarantees full binary compatibility with 32-bit gaming runtimes (Steam, Proton, Wine) and legacy toolchains.

### 2.5 Toolchain & Compilers
- **C/C++ Compiler:** GCC 14+ (GNU Compiler Collection).
- **Assembler & Linker:** GNU Binutils (`ld.bfd`, `as`).
- **Archive & Compression Tools:** GNU `tar`, GNU `coreutils`, `zstd` (v1.5+).
- **ISO Mastering Suite:** `xorriso` (v1.5+), `mtools`, `dosfstools` (`mkfs.vfat`).

### 2.6 Userspace Strategy
- **Core Ecosystem:** Arch-compatible rolling base with custom DoomOS system manifests.
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
├── lib64 -> usr/lib
├── usr/
│   ├── bin/
│   ├── lib/
│   ├── lib32/
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
- **Core Hooks:** `base`, `udev`, `memdisk`, `archiso`, `archiso_loop_mnt`, `archiso_pxe_common`, `kms`, `block`, `btrfs`, `filesystems`, `keyboard`.
- **Output Artifact:** `/boot/initramfs-linux-zen.img` with prepended early CPU microcode (`amd-ucode.img`, `intel-ucode.img`).
- **Initramfs Role:**
  1. Load virtual hardware storage controllers (`mptspi`, `nvme`, `virtio`).
  2. Locate boot media matching label `DOOMOS_LIVE`.
  3. Mount SquashFS image and establish tmpfs writeable overlay.
  4. Pivot-root into target root filesystem and exec PID 1.

### 2.11 Bootloader & UEFI Strategy
- **Primary Firmware Target:** UEFI 2.8+ 64-bit strictly.
- **Bootloader Implementation:** GRUB 2.12 (x86_64-efi) and systemd-boot compatible payload.
- **UEFI Boot Binary:** `\EFI\BOOT\BOOTX64.EFI` installed inside a dedicated FAT12/16/32 EFI System Partition (ESP).
- **El Torito Structure:** Dual-boot hybrid ISO containing El Torito boot catalog for UEFI boot sector with fallback hybrid MBR sector for raw USB flash drives.

### 2.12 Kernel Command Line Contract
```text
archisobasedir=doomos archisolabel=DOOMOS_LIVE cow_spacesize=4G copytoram=n nvme_load=yes loglevel=3 splash quiet
```
- `archisobasedir`: Identifies directory housing system squashfs layers.
- `archisolabel`: Deterministic ISO filesystem volume label.
- `cow_spacesize`: Dynamic allocation for temporary live workspace.
- `nvme_load=yes`: Forces early probing of virtual NVMe storage buses.
- `loglevel=3`: Suppresses non-critical kernel informational messages during boot sequence.

### 2.13 Networking Strategy
- **Stack:** NetworkManager with `systemd-resolved` DNS stub resolver.
- **Live Network Policy:** Auto-connect on virtual Ethernet (`vmxnet3`, `e1000e`, `virtio-net`) via DHCP.
- **Firewall:** `nftables` enabled with baseline stateful inspection.

### 2.14 Device Management Strategy
- **Udev Manager:** `systemd-udevd`.
- **Subsystem Guardians:**
  - *NVIDIA DKMS Guardian:* `/usr/share/libalpm/hooks/90-doomos-nvidia-guardian.hook` verifying kernel symbol resolution before system reboots.
  - *Btrfs Snapper Engine:* Automated transaction snapshots (`snap-pac`) synchronized to GRUB boot menus via `grub-btrfsd`.

### 2.15 Package Management Strategy (Milestone v1.0.0)
- **Tool:** `pacman` 7.x package manager with official Arch Linux mirrors and DoomOS custom repository overrides.
- **Package Manifest:** `profile/packages.x86_64` defining exact package manifests for graphics, audio, desktop, and virtualization.

### 2.16 ISO Creation Method
- **Builder Suite:** `mkarchiso` executed within an isolated containerized Linux environment.
- **Output Filename:** `DoomOS-x86_64-UEFI-vX.Y.Z.iso`
- **Volume Identifier:** `DOOMOS_LIVE`
- **Compression:** Zstandard level 19, 1MB block size.

### 2.17 VMware Virtual Hardware Profile
- **Virtual Machine Hardware Version:** Workstation 21 / Fusion 13+.
- **Firmware:** UEFI (Secure Boot optional).
- **Virtual CPU:** 4 vCPUs (x86_64).
- **Virtual Memory:** 8192 MB RAM (minimum 4096 MB).
- **Display Controller:** VMware SVGA 3D with 2048 MB VRAM allocation.
- **Disk Controller:** NVMe or LSI Logic SAS.
- **Network Adapter:** `vmxnet3`.
- **Guest Integration:** `open-vm-tools` + `open-vm-tools-desktop` (`vmtoolsd.service`).

### 2.18 CI / CD Build Environment
- **Platform:** GitHub Actions.
- **Runner:** `ubuntu-latest` (x86_64 Linux).
- **Isolation:** Docker privileged container running clean Arch Linux builder image.
- **Storage Management:** Aggressive runner disk cleanup freeing 25+ GB workspace prior to compilation.

### 2.19 Release Artifact Distribution Strategy
- **Hosting Platform:** GitHub Releases.
- **Single Source of Truth:** One complete, verified ISO file (`DoomOS-x86_64-UEFI-vX.Y.Z.iso`).
- **Multipart Distribution Rule:** Split into 2000 MB chunks:
  - `DoomOS-x86_64-UEFI-vX.Y.Z.iso.part00`
  - `DoomOS-x86_64-UEFI-vX.Y.Z.iso.part01`
  - `...`
- **Integrity Files:**
  - Authoritative complete ISO SHA256 checksum: `DoomOS-x86_64-UEFI-vX.Y.Z.iso.sha256`
  - Cryptographic release manifest: `release-manifest.txt`
  - Standalone multi-platform reassembler: `combine.sh` (POSIX sh compatible, supporting both Linux `sha256sum` and macOS `shasum`).

---

## 3. Architecture Status Summary

| Subsystem | Strategy | Milestone v1.0.0 Status |
| :--- | :--- | :--- |
| **CPU Architecture** | `x86_64` | Frozen / Active |
| **Firmware** | UEFI 64-bit | Frozen / Active |
| **Kernel** | `linux-zen` 6.x/7.x + VMware modules | Frozen / Active |
| **Init System** | `systemd` v256+ | Frozen / Active |
| **Filesystem (Live)** | SquashFS + Zstandard-19 + OverlayFS | Frozen / Active |
| **Filesystem (Target)** | Btrfs (subvolumes: `@`, `@home`, `@snapshots`, `@var_log`) | Frozen / Active |
| **Bootloader** | GRUB 2.12 (UEFI) | Frozen / Active |
| **Display Stack** | Wayland + KWin (AdaptiveSync + LowLatency) | Frozen / Active |
| **Desktop Suite** | KDE Plasma 6 + SDDM | Frozen / Active |
| **Virtualization** | VMware SVGA 3D + `open-vm-tools` | Frozen / Active |
| **Installer** | Calamares (Btrfs subvolume mapping) | Frozen / Active |
| **CI/CD** | GitHub Actions x86_64 | Frozen / Active |
| **Distribution** | Multipart sequential chunks (`part00`, `part01`, ...) + `combine.sh` | Frozen / Active |
| **Actual VMware Boot** | Physical VM boot validation | Subject to live test execution |
