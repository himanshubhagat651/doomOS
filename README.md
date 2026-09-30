# ⚡ DoomOS (x86_64 UEFI Linux Distribution)

[![Build and Release DoomOS](https://github.com/himanshubhagat651/doomOS/actions/workflows/build-doomos.yml/badge.svg)](https://github.com/himanshubhagat651/doomOS/actions/workflows/build-doomos.yml)
[![GitHub Release](https://img.shields.io/github/v/release/himanshubhagat651/doomOS?color=emerald)](https://github.com/himanshubhagat651/doomOS/releases)
[![Architecture: x86_64 UEFI](https://img.shields.io/badge/Architecture-x86__64%20UEFI-blue.svg)](docs/ARCHITECTURE.md)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

**DoomOS** is a performance-tuned, reproducible Linux operating system built for **x86_64 UEFI** with first-class optimization for **VMware Fusion & Workstation** and bare-metal UEFI workstations.

Engineered with native **KDE Plasma 6 on Wayland**, low-latency **Linux Zen kernel**, Btrfs subvolumes with automated GRUB snapshot rollback, and 6 core problem-solving subsystems for gamers, developers, and desktop users.

---

## 🏛️ System Architecture Freeze

The DoomOS distribution architecture is frozen for milestone **v1.0.0**:
- **Target Architecture:** `x86_64` (AMD64 / Intel 64-bit)
- **Target Firmware:** `UEFI` 64-bit strictly (`\EFI\BOOT\BOOTX64.EFI`)
- **Kernel:** `linux-zen` 6.x/7.x branch + VMware guest modules (`vmwgfx`, `vmw_balloon`, `vmw_vmci`, `vmxnet3`)
- **Init System:** `systemd` v256+ (`/sbin/init` -> `/usr/lib/systemd/systemd`)
- **Live Filesystem:** SquashFS compressed with Zstandard Level 19 (`zstd -Xcompression-level 19 -b 1M`) over OverlayFS
- **Target Filesystem:** Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`)
- **Desktop Environment:** KDE Plasma 6 (pure Wayland session via `plasma-workspace`, eliminating legacy X11 session bloat)
- **Virtualization Integration:** VMware SVGA 3D hardware acceleration + `open-vm-tools` (`vmtoolsd.service`)

Full architectural details: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

---

## 📁 Repository & Project Layout

```text
DoomOS/
├── .github/workflows/         # Authoritative CI/CD pipeline (build-doomos.yml)
├── configs/                   # Kernel and subsystem configuration references
│   └── doomos-kernel.config
├── docs/                      # Architectural specifications & release standards
│   ├── ARCHITECTURE.md        # Frozen system design specifications
│   ├── BUILD.md               # Build environment and execution guide
│   ├── VMWARE-VALIDATION.md   # Hypervisor boot verification ledger
│   └── RELEASE.md             # Multipart distribution & gate checklist
├── scripts/                   # Distribution management & deployment scripts
│   ├── check-build-environment.sh
│   ├── combine.sh
│   ├── test-vmware.sh
│   ├── test-qemu.sh
│   ├── flash-usb.sh
│   └── build-in-vmware.sh
├── tests/                     # Deterministic acceptance test suites
│   ├── test-phase0.sh         # Architecture & structure validation
│   ├── test-combine.sh        # Multipart reassembly unit tests
│   └── verify-iso.sh          # 20-point deep ISO and subsystem audit
├── doomos-builder/            # Containerized mkarchiso build engine
│   ├── Dockerfile
│   ├── build.sh
│   ├── run-builder.sh
│   └── profile/               # Packages, airootfs, branding & hooks
└── combine.sh                 # Root client-side reassembler
```

---

## 📦 Downloading & Recombining Releases

Due to cloud transfer constraints, the complete, unified ISO is distributed in **sequential multipart chunks**:
- `doomos-plasma-x86_64.iso.part00` (~2000 MB)
- `doomos-plasma-x86_64.iso.part01` (~510 MB)
- `doomos-plasma-x86_64.iso.sha256` (authoritative cryptographic hash)
- `combine.sh` (standalone POSIX reassembler)
- `release-manifest.txt` (build metadata and chunk signatures)

### How to Recombine the ISO:

1. Download all chunks, the `.sha256` checksum, and `combine.sh` from [GitHub Releases](https://github.com/himanshubhagat651/doomOS/releases).
2. Execute the reassembly utility:
   ```bash
   chmod +x combine.sh
   ./combine.sh
   ```
3. The script verifies sequential order, checks for missing chunks, concatenates the parts into `doomos-plasma-x86_64.iso`, and validates the SHA256 checksum across Linux (`sha256sum`) and macOS (`shasum -a 256`).

---

## 🚀 Running in VMware Fusion / Workstation

Once recombined, launch DoomOS with automated hardware configuration:
```bash
chmod +x scripts/test-vmware.sh
./scripts/test-vmware.sh
```
This automatically configures a VMware virtual machine bundle (`DoomOS.vmwarevm`) with:
- 4 vCPUs, 8192 MB RAM, and UEFI firmware
- VMware SVGA 3D hardware acceleration with 2048 MB VRAM
- `vmxnet3` 10Gbps virtual Ethernet adapter
- NVMe virtual disk controller

---

## ⚙️ Building from Source

### Automated Cloud Build (GitHub Actions)
The authoritative production build runs on GitHub Actions Linux x86_64 runners via `.github/workflows/build-doomos.yml`.

### Local Native Build in an Arch VM
To build without Docker on an Arch Linux x86_64 virtual machine:
```bash
sudo ./scripts/build-in-vmware.sh
```

### Local Container Build
```bash
./scripts/check-build-environment.sh
cd doomos-builder
./run-builder.sh
```

---

## 🧪 Acceptance Testing & Quality Assurance

Run the local acceptance test suites:
```bash
# Validate Phase 0 architecture freeze & project layout
./tests/test-phase0.sh

# Validate combine.sh multipart reassembly logic
./tests/test-combine.sh

# Validate completed ISO structure & subsystems (after build)
./tests/verify-iso.sh doomos-builder/output/doomos-plasma-x86_64.iso
```

---

## 📄 Engineering Documentation

- [Frozen Architecture Specification (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)
- [Build Engineering Guide (docs/BUILD.md)](docs/BUILD.md)
- [VMware Validation Ledger (docs/VMWARE-VALIDATION.md)](docs/VMWARE-VALIDATION.md)
- [Release Engineering Protocol (docs/RELEASE.md)](docs/RELEASE.md)
- [Master Specification PDF](DoomOS_Master_Specification.pdf)
