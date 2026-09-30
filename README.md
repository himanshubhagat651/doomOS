# ⚡ DoomOS (KDE Plasma 6 VMware Edition)

[![Build and Release DoomOS ISO](https://github.com/himanshubhagat651/doomOS/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/himanshubhagat651/doomOS/actions/workflows/build-and-release.yml)
[![GitHub Release](https://img.shields.io/github/v/release/himanshubhagat651/doomOS?color=emerald)](https://github.com/himanshubhagat651/doomOS/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

**DoomOS** is a high-performance Arch-based Linux distribution engineered from the ground up to solve the real-world friction experienced by **Gamers**, **Everyday Users**, and **Developers**.

Featuring native **KDE Plasma 6 on Wayland**, dual Linux kernels (**Linux Zen** + **Linux LTS**), automated Btrfs snapshots with GRUB rollback, and first-class virtualization integration for **VMware Fusion & Workstation**.

---

## 🌟 Key Highlights & Innovations

### 🖥️ First-Class VMware & Virtualization Integration
- **Pre-installed `open-vm-tools` & `gtkmm3`:** Auto-resizing display resolution, bidirectional clipboard synchronization (copy/paste), and drag-and-drop file sharing.
- **Hardware-Accelerated 3D Graphics:** Native Linux kernel `vmwgfx` DRM driver paired with Mesa 3D SVGA acceleration.
- **One-Command VM Generator (`test-vmware.sh`):** Instantly creates a fully tuned `DoomOS.vmwarevm` configuration bundle.

### 🛡️ The 6 Problem-Solving Subsystems
1. **NVIDIA DKMS Guardian:** Automated libalpm post-transaction hook prevents unbootable black screens after kernel upgrades.
2. **Btrfs Snapper Auto-Rollback:** Automated pre/post transaction snapshots via `snap-pac` integrated with `grub-btrfsd` for instant GRUB boot menu rollbacks.
3. **Wayland Portal Audio Loopback:** Hardware virtual meeting audio loopback sink (`DoomOS Meeting Share Sink`) allowing simultaneous desktop game audio and microphone streaming in Discord, OBS, and Zoom.
4. **Developer Performance Sysctl:** High-concurrency limits (`vm.max_map_count = 2147483642`, `fs.inotify.max_user_watches = 1048576`) and pre-configured rootless container user namespaces (`/etc/subuid`, `/etc/subgid`).
5. **Laptop Battery & Deep Sleep Policy:** Dual battery management with `auto-cpufreq` and `power-profiles-daemon`, tuned for deep `s2idle/deep` ACPI states.
6. **HDR Auto-Engagement:** Dynamic Wayland compositor HDR switching for gaming via `doom-game` with `gamescope` and `gamemoderun`.

### 💾 Calamares Automated Btrfs Installer
- Custom DoomOS slate/emerald dark-mode branding.
- Automated creation of industry-standard Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`).
- **Dual-Boot Windows RTC Sync (`doomos-rtc`):** Automatically detects existing Windows EFI installations and sets local RTC clock mode, eliminating dual-boot clock discrepancy.

---

## 📦 Downloading & Recombining Releases

Due to GitHub Release artifact constraints, the ISO is distributed in **two verified multipart chunks**:
- `doomos-plasma-x86_64.iso.part01` (~2.0 GB)
- `doomos-plasma-x86_64.iso.part02` (~1.0 GB)
- `doomos-plasma-x86_64.iso.sha256`
- `combine.sh`

### How to Recombine the ISO:

1. Download all chunks and `combine.sh` into the same folder from [GitHub Releases](https://github.com/himanshubhagat651/doomOS/releases).
2. Run the automated reassembly script:
```bash
chmod +x combine.sh
./combine.sh
```
3. The script recombines `part01` and `part02` into `doomos-plasma-x86_64.iso` and validates the SHA256 checksum automatically.

---

## 🚀 Testing & Deployment

### Run in VMware Fusion / Workstation:
```bash
chmod +x test-vmware.sh
./test-vmware.sh
```

### Run in QEMU / UTM (macOS & Linux):
```bash
chmod +x test-qemu.sh
./test-qemu.sh
```

### Flash to Bare-Metal USB:
```bash
chmod +x flash-usb.sh
./flash-usb.sh
```

---

## ⚙️ Building from Source

To build the ISO locally using the containerized build engine:
```bash
cd doomos-builder
./run-builder.sh
```

Or trigger the automated GitHub Actions pipeline under `.github/workflows/build-and-release.yml`.

---

## 📄 Documentation & Specifications

- [Master Engineering Specification (PDF)](DoomOS_Master_Specification.pdf) — Complete 19-page combined specification.
- [Testing & Deployment Manual (PDF)](TESTING_GUIDE.pdf) — Full QA test checklists for VMware, UTM, and bare metal.
- [Product Requirements Document (PRD.md)](PRD.md)
- [Product Features & Architecture (PRODUCT_FEATURES.md)](PRODUCT_FEATURES.md)
- [Build Steps & Packaging Playbook (BUILD_STEPS.md)](BUILD_STEPS.md)
