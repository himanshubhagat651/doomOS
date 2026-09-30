# DoomOS v1.0.0 — Production Release (KDE Plasma 6 Edition)

Welcome to the official release of **DoomOS v1.0.0**, an advanced, high-performance Arch-based Linux distribution engineered from the ground up to eliminate the real-world friction experienced by **Gamers**, **Everyday Users**, and **Developers**.

Built with native **KDE Plasma 6 on Wayland**, dual Linux kernels (**Linux Zen** for maximum responsiveness + **Linux LTS** for bedrock stability), and first-class virtualization support for **VMware Fusion & Workstation**.

---

## 🌟 Highlights & Key Innovations

### 1. 🎮 Gaming & Display Stack
- **KDE Plasma 6 on Wayland Native:** Pure Wayland desktop environment without legacy X11 session bloat.
- **Adaptive Sync & Low-Latency Gaming:** KWin configured with `AdaptiveSync=Always` (Variable Refresh Rate / G-Sync / FreeSync) and `AllowTearingAtFullscreen=true` for competitive esports FPS titles.
- **Hardware HDR Detection:** Bundled `doom-game` game launcher auto-detects HDR monitors via `kscreen-doctor` and seamlessly engages `gamescope` and `gamemoderun`.
- **Complete 32-Bit Multilib Ecosystem:** Native support for Steam, Proton, Wine, Vulkan 32-bit runtimes, and high-performance Mesa graphics.

### 2. 🛡️ The 6 Problem-Solving Subsystems
1. **NVIDIA DKMS Guardian:** Automated libalpm post-transaction hook prevents unbootable black screens after kernel updates by verifying kernel module symbols before rebooting.
2. **Btrfs Snapper Auto-Rollback:** Automated pre/post transaction snapshots via `snap-pac` integrated with `grub-btrfsd` for instant grub-menu rollbacks.
3. **Wayland Audio Loopback Engine:** Hardware virtual meeting audio loopback sink (`DoomOS Meeting Share Sink`) allowing simultaneous desktop game audio and microphone streaming in Discord/OBS/Zoom.
4. **Developer Performance Sysctl:** Tuned for high-concurrency developer workflows (`vm.max_map_count = 2147483642`, `fs.inotify.max_user_watches = 1048576`) and pre-configured rootless container namespaces.
5. **Laptop Power & Deep Sleep Policy:** Dual battery management with `auto-cpufreq` and `power-profiles-daemon`, tuned for deep `s2idle/deep` ACPI states.
6. **HDR Auto-Engagement:** Dynamic Wayland compositor HDR switching for gaming.

### 3. 🖥️ VMware & Virtual Machine Excellence
- **Native `open-vm-tools`:** Out-of-the-box auto-fitting screen resolutions, host-to-guest bidirectional clipboard copy/paste, and VMware shared folders (`vmhgfs`).
- **VMware 3D SVGA Graphics:** Full 3D hardware acceleration via `vmwgfx` DRM kernel driver and Mesa.
- **Pre-configured VM Bundle:** Run `./test-vmware.sh` to generate an optimized `DoomOS.vmwarevm` bundle.

### 4. 💾 Calamares Automated Btrfs Installer
- Custom DoomOS slate/emerald dark-mode branding.
- Automated creation of industry-standard Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`).
- **Dual-Boot Windows RTC Sync (`doomos-rtc`):** Detects existing Windows EFI installations and synchronizes hardware RTC clock mode, eliminating the dreaded 5.5-hour dual-boot clock discrepancy.

---

## 📦 Release Artifacts

| File | Description |
| :--- | :--- |
| `doomos-plasma-x86_64.iso` | Bootable Hybrid UEFI/BIOS ISO image |
| `doomos-plasma-x86_64.iso.sha256` | SHA256 integrity checksum |
| `DoomOS_Master_Specification.pdf` | Complete 19-page engineering specification |
| `TESTING_GUIDE.pdf` | Full testing and QA deployment manual |

---

## 🚀 Quick Verification & Booting

```bash
# Verify checksum
sha256sum -c doomos-plasma-x86_64.iso.sha256

# Flash to USB on Linux/macOS
sudo dd if=doomos-plasma-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
