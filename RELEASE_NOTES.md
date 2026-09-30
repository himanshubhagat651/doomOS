# DoomOS v1.1.0 — Apple Silicon ARM64 Edition (KDE Plasma 6 VMware Edition)

Welcome to the official release of **DoomOS v1.1.0 (ARM64 Edition)**, an advanced, high-performance Arch Linux ARM-based distribution engineered specifically for **Apple Silicon Macs (M1/M2/M3/M4)** running **VMware Fusion 13.5+ (UEFI)**.

Per explicit design mandate, this edition eliminates cross-architecture virtualization friction by compiling natively for 64-bit ARM (`aarch64`), featuring **KDE Plasma 6 on native Wayland**, the **`linux-aarch64` kernel**, **ZRAM memory compression**, **dynamic Wayland resolution auto-resizing**, and **VMware shared folders (`/mnt/hgfs`)**.

---

## 🌟 Highlights & Key Innovations

### 1. 🍎 Native Apple Silicon & VMware Fusion Compatibility
- **ARM64 Native Architecture (`aarch64`):** Eliminates CPU emulation overhead. Boots natively via Apple's `Hypervisor.framework` on M1, M2, M3, and M4 Apple Silicon Macs.
- **64-bit UEFI Firmware Boot:** Direct EFI execution via `\EFI\BOOT\BOOTAA64.EFI` and GRUB for ARM64.
- **Zero-Config VMware Script:** Run `./test-vmware.sh` on macOS to automatically generate and launch a tuned `DoomOS.vmwarevm` bundle configured with `guestOS = "arm-other-64"` and `virtualHW.version = "21"`.

### 2. 🖥️ Dynamic Display & Desktop Experience
- **KDE Plasma 6 on Wayland Native:** Blazing-fast desktop rendered with GPU acceleration.
- **Dynamic Wayland Window Resizer:** Integrated `vmware-wayland-resizer` listener automatically synchronizes guest display resolution when dragging the VMware Fusion window on macOS.
- **HiDPI Fractional Scaling:** Crisp, razor-sharp rendering on Retina and Liquid Retina XDR displays.

### 3. 🛡️ Resource Protection & VM Integration
- **ZRAM Dynamic RAM Compression:** Auto-configured `zram-generator` compresses swap inside RAM with zstd, preventing OOM crashes in 4GB–8GB VMs.
- **VMware Shared Folders Automount:** Host-shared directories are automatically mounted at `/mnt/hgfs` on boot via `mnt-hgfs.mount`.
- **Integrated `open-vm-tools`:** Bidirectional copy/paste clipboard sharing, time synchronization, and graceful shutdown.

### 4. 💾 Calamares Automated Btrfs Installer
- Custom DoomOS slate/emerald dark-mode branding.
- Automated creation of industry-standard Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`).
- High-fidelity `unpackfs` rootfs deployment for ARM64 live media.

---

## 📦 Release Artifacts (Multipart & Reassembly)

| File | Size | Description |
| :--- | :--- | :--- |
| `doomos-plasma-aarch64.iso.part00` | ~2.0 GB | DoomOS ARM64 Master ISO — Chunk 1 |
| `doomos-plasma-aarch64.iso.part01` | ~1.0 GB | DoomOS ARM64 Master ISO — Chunk 2 |
| `doomos-plasma-aarch64.iso.sha256` | < 1 KB | Cryptographic SHA256 integrity checksum |
| `combine.sh` | < 2 KB | Automated recombine and integrity verification script |
| `test-vmware.sh` | < 3 KB | Automated VMware Fusion (Apple Silicon) VM generator |
| `scripts/flash-usb.sh` | < 4 KB | Safe bare-metal USB flashing utility with guardrails |
| `DoomOS_Master_Specification.pdf` | 848 KB | Complete 19-page engineering specification |
| `TESTING_GUIDE.pdf` | 316 KB | Full testing, QA audit, and deployment manual |
| `VMWARE_GUIDE.pdf` | 318 KB | VMware setup and troubleshooting manual |

---

## 🚀 Recombining the ISO & Verification on macOS

Download the release files into a single folder on your Mac, then run:

```bash
# 1. Recombine part00 and part01 into doomos-plasma-aarch64.iso & verify SHA256
chmod +x combine.sh test-vmware.sh
./combine.sh

# 2. Launch directly in VMware Fusion on your Mac
./test-vmware.sh
```
