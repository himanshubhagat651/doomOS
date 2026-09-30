# Product Requirements Document (PRD)

**Project Name:** DoomOS (KDE Plasma Edition)  
**Document Version:** 1.0.0  
**Status:** Approved for Architecture & Design  
**Target Environments:** Modern x86_64 Desktops, Laptops, and Handhelds  
**Author:** Senior Systems Engineer / Technical Lead  

---

## 1. Executive Overview & Mission Statement

**DoomOS** is a next-generation, performance-tuned Linux distribution engineered to bridge the gap between uncompromising power-user performance and an intuitive, foolproof out-of-the-box experience. Built on top of a cutting-edge **KDE Plasma 6 (Wayland-native)** desktop environment, DoomOS directly eliminates the systemic friction points that drive users away from Linux—specifically targeting:
1. **Gamers:** Eliminating driver breakage, Wayland frame pacing stutter, controller friction, and HDR hurdles.
2. **Everyday Users:** Eliminating update anxiety with automated snapshot rollbacks, blurry fractional scaling, battery drain, and codec headaches.
3. **Developers:** Providing seamless Wayland screen sharing with system audio, pre-configured rootless containers, and optimized kernel IPC/inotify limits.

---

## 2. Target Personas & Core Use Cases

```
+---------------------------------------------------------------------------------------+
|                                    TARGET USERS                                       |
+---------------------------+-------------------------------+---------------------------+
|        THE GAMER          |       THE EVERYDAY USER       |       THE DEVELOPER       |
| High refresh, low latency | Rock-solid stability, battery | Fast toolchains, Docker,  |
| Steam, Proton, G-Sync/HDR | Netflix, Office, App Store    | Multi-monitor, Portals    |
+---------------------------+-------------------------------+---------------------------+
```

### Persona 1: The Modern Gamer ("Alex")
- **Hardware:** Modern AMD/Intel CPU + NVIDIA RTX 3000/4000 or AMD Radeon RX 7000 series GPU, 144Hz+ VRR display.
- **Goals:** Wants to install the OS, launch Steam, enable HDR, plug in an Xbox/PS5 controller, and play without editing config files or facing black screens after kernel updates.

### Persona 2: The Daily Driver ("Taylor")
- **Hardware:** Ultrabook / Laptop (Framework, Dell XPS, ThinkPad, ASUS Zenbook) with high-DPI display.
- **Goals:** Requires reliable suspend/resume without battery drain in backpacks, crystal-clear 125%/150% UI scaling, universal media playback, and an assurance that system updates will never brick their workstation.

### Persona 3: The Full-Stack / Systems Developer ("Marcus")
- **Hardware:** Multi-monitor developer workstation or laptop, running Docker/Podman, VS Code, JetBrains IDEs, and heavy compilation workloads.
- **Goals:** Demands instant Wayland screen sharing with audio for remote meetings, high inotify file watch limits for large mono-repos, rootless container execution out-of-the-box, and isolated sandbox development environments.

---

## 3. System Architecture Specification

```
+---------------------------------------------------------------------------------------+
|                                 USERLAND INTERACTION                                  |
|  KDE Plasma 6 (KWin Wayland) | Calamares Offline/Online Installer | KDE Discover / CLI|
+---------------------------------------------------------------------------------------+
|                                PLATFORM SUBSYSTEMS                                    |
|   DoomOS Guardian (DKMS check)   | Snapper / Btrfs Hooks | PipeWire Audio/Video Wire  |
|   Auto-CPUFreq / Power Profiles  | xdg-desktop-portal-kde | Flathub Sandbox Runtime   |
+---------------------------------------------------------------------------------------+
|                                   INIT & RUNTIME                                      |
|                    systemd (PID 1) | D-Bus Message Bus | Polkit ACL                   |
+---------------------------------------------------------------------------------------+
|                                KERNEL & HARDWARE ABSTRACTION                          |
|   Linux Kernel (LTS / Zen low-latency) | Btrfs Filesystem | ZRAM Compressed Swap      |
|   Mesa Gallium/Vulkan | NVIDIA Open/DKMS Module | xone / DualSense HID Drivers         |
+---------------------------------------------------------------------------------------+
```

---

## 4. Non-Functional Requirements (NFRs)

### 4.1 Stability & Fault Tolerance (The "Immortal Boot" Guarantee)
- **Zero-Unbootable Policy:** System updates must automatically create a Btrfs pre-transaction snapshot. If an update breaks the kernel or graphics driver, the bootloader (GRUB) must expose an instant rollback menu allowing full recovery into the pre-update state in $< 10$ seconds.
- **Safe Driver Recompilation:** NVIDIA driver DKMS compilation must execute during package installation. If the driver compilation fails, the transaction must halt before replacing the running kernel.

### 4.2 Performance & Responsiveness
- **Cold Boot Time:** $\le 8\text{ seconds}$ from UEFI bootloader to SDDM login screen on standard NVMe PCIe Gen3+ SSDs.
- **Idle Memory Footprint:** $\le 950\text{ MB}$ RAM consumption at cold boot with KDE Plasma running on Wayland.
- **Kernel Scheduling Latency:** Kernel tuned with `CONFIG_PREEMPT` / Zen scheduling patches to maintain consistent frame pacing under heavy background CPU load.
- **Memory Pressure Resilience:** Dynamic ZRAM enabled with `zstd` compression algorithm allocating $50\%$ of physical RAM as swap space to prevent Out-Of-Memory (OOM) lockups.

### 4.3 Hardware Compatibility
- **Display Configurations:** Independent fractional scaling per monitor on Wayland without blur on legacy X11 applications.
- **Audio Routing:** PipeWire routing with automatic sample rate switching matching hardware capabilities without crackling or high latency.
- **Dual-Boot Interoperability:** Hardware RTC clock automatically configured to coordinate with Windows to eliminate the standard 5.5-hour time drift bug.

---

## 5. Security & Isolation Model

1. **Rootless by Default:**
   - User account provisioned with password-less `sudo` restrictions.
   - Container engines (Docker/Podman) configured for daemonless/rootless execution without requiring `sudo docker`.
2. **Application Sandboxing:**
   - GUI applications distributed via Flathub run under Flatpak sandbox permissions managed through Plasma System Settings.
3. **Immutable Boot Snapshots:**
   - Read-only boot snapshots mounted with copy-on-write integrity to prevent ransomware or rogue installer scripts from compromising recovery points.

---

## 6. Build & Delivery Architecture

- **Host-Agnostic Build Engine:** The ISO generation toolchain runs within an isolated container, enabling the OS to be built and verified on Linux servers, GitHub Actions CI/CD, or macOS developer workstations.
- **Target Deliverable:** Bootable hybrid ISO (`doomos-plasma-x86_64.iso`) compatible with UEFI Secure Boot and legacy BIOS (CSM).
- **Installer:** Fully customized **Calamares** graphical installer providing automated partitioning (Btrfs subvolumes layout `@`, `@home`, `@snapshots`, `@var_log`), timezone auto-detection, and driver selection.

---

## 7. Phased Release Roadmap

```
Phase 1: Foundation (M1)
├── Base Kernel + ZRAM + Btrfs Layout
├── KDE Plasma 6 Wayland Minimal Base
└── SDDM with DoomOS Theme & Autologin

Phase 2: The Core Problem Fixers (M2)
├── Snapper Automated Snapshot Hooks in GRUB
├── PipeWire Screen Sharing & Audio Loopback
├── Developer Sysctl tuning & Rootless Docker
└── NVIDIA DKMS Guardian Scripts

Phase 3: Gaming & Polishing (M3)
├── Wayland Explicit Sync & HDR Auto-calibrator
├── Game Controller (Xbox/PS5) Drivers + OpenRGB
├── Calamares Installer Customization & Btrfs Provisioning
└── Flathub Verified App Store Integration

Phase 4: ISO Mastering & Verification (M4)
├── Automated Build Pipeline (Dockerfile + archiso/live-build)
├── QEMU Virtual Machine Verification Test Suite
└── Golden Master ISO Release (v1.0.0)
```
