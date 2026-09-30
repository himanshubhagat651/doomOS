# DoomOS Technical Product Features Specification
## How DoomOS Solves Every Major Linux Pain Point

This document details the exact engineering architecture, technical implementations, configuration files, and system mechanisms employed by **DoomOS** to eliminate the top pain points experienced by **Gamers**, **Everyday Users**, and **Developers**.

---

# SECTION 1: GAMER PAIN POINTS & TECHNICAL SOLUTIONS

```
+---------------------------------------------------------------------------------------+
| GAMER PROBLEM                | DOOMOS ARCHITECTURAL SOLUTION                          |
+------------------------------+--------------------------------------------------------+
| 1. NVIDIA Update Black Screen| DKMS Pre-reboot Verification + Safe Rollback Hook      |
| 2. Wayland Stutter / Tearing | Wayland Explicit Sync + VRR Default in KWin            |
| 3. HDR Washed Out / Missing  | Plasma 6 Tone-Mapping + Auto-Gamescope Launch Wrapper  |
| 4. Missing 32-bit Wine Libs  | Comprehensive Multi-lib Baseline Pre-baked in ISO     |
| 5. Controller Connection Lag | Built-in xone / xpadneo Drivers + DualSense Haptics    |
| 6. Anti-Cheat Confusion      | Real-time AreWeAntiCheatYet Badge Integration          |
+---------------------------------------------------------------------------------------+
```

---

### Problem 1.1: NVIDIA Driver Updates Break the System (Black Screen on Reboot)
- **Root Cause:** A new Linux kernel is installed before the NVIDIA proprietary kernel module (`nvidia.ko`) is successfully compiled by DKMS, or the driver version is incompatible with the kernel ABI. Upon reboot, the display manager (SDDM) fails to initialize DRM, stranding the user at a black screen or TTY.
- **DoomOS Engineering Solution:**
  1. **DKMS Transaction Interceptor:** DoomOS introduces a package manager transaction hook (`/usr/share/libalpm/hooks/90-doomos-nvidia-guardian.hook`):
     - Compiles the NVIDIA kernel module *inside* the update transaction before touching `/boot/vmlinuz`.
     - Validates that `modinfo -k <new-kernel-version> nvidia` returns exit code 0.
     - If compilation fails, the entire transaction rolls back automatically and keeps the existing functional kernel active.
  2. **Automated Kernel Fallback:** The system always maintains both the `linux-zen` (primary performance kernel) and `linux-lts` (long-term stability fallback) side-by-side with separate boot entries.

---

### Problem 1.2: Wayland Stutter, Micro-Jank, and Flickering
- **Root Cause:** In legacy Wayland implementations, synchronization between the compositor (KWin) and the GPU driver relied on implicit sync primitives, causing out-of-order buffer presentations, tearing, and flickering on NVIDIA hardware.
- **DoomOS Engineering Solution:**
  1. **Wayland Explicit Sync Engine:** Ships with KDE Plasma 6 + Wayland protocols (`linux-drm-syncobj-v1`) and NVIDIA driver series 555+ enabled by default.
  2. **Zero-Latency Variable Refresh Rate (VRR):** Configured in `/etc/xdg/kwinrc`:
     ```ini
     [Wayland]
     AllowTearingAtFullscreen=true
     
     [Displays]
     AdaptiveSync=Always
     ```
  3. **High-Performance Memory Tuning:** Enables split-lock mitigate disabling (`split_lock_mitigate=0`) in kernel cmdline to eliminate micro-stutters during intensive game scene transitions.

---

### Problem 1.3: HDR is Inconsistent, Washed Out, or Requires Obscure Scripts
- **Root Cause:** Upstream Linux desktop environments traditionally lacked color management infrastructure, requiring manual invocation of `gamescope` with complex color-space conversion arguments.
- **DoomOS Engineering Solution:**
  1. **Native Plasma 6 Color Pipeline:** Pre-enables KDE’s native Wayland color management stack supporting HDR10 (BT.2020 PQ).
  2. **The `doom-game` One-Click Execution Wrapper:** Installs `/usr/bin/doom-game`, which auto-detects HDR-capable displays and wraps games automatically:
     ```bash
     #!/usr/bin/env bash
     # Auto-detects HDR monitor capability via kscreen-doctor
     if kscreen-doctor -o | grep -q "HDR: supported"; then
         export ENABLE_HDR_WSI=1
         export PROTON_ENABLE_HDR=1
     fi
     exec gamemoderun gamescope --hdr-enabled --adaptive-sync --fullscreen -- "$@"
     ```

---

### Problem 1.4: Missing 32-bit Multi-lib Libraries Crash Steam & Wine
- **Root Cause:** Users install Steam or Lutris, only to discover that ancient 32-bit game binaries fail silently because fundamental 32-bit graphics, audio, and Vulkan loaders are omitted from the default base install.
- **DoomOS Engineering Solution:**
  - The DoomOS ISO pre-bakes the complete 32-bit runtime suite:
    - Graphics: `lib32-vulkan-radeon`, `lib32-nvidia-utils`, `lib32-mesa`, `lib32-vulkan-intel`
    - Audio: `lib32-pipewire`, `lib32-alsa-plugins`, `lib32-libpulse`
    - Crypto/Core: `lib32-gnutls`, `lib32-glibc`

---

### Problem 1.5: Wireless Game Controllers Lag or Drop Connection
- **Root Cause:** The upstream Linux kernel lacks out-of-the-box support for the proprietary Microsoft Xbox Wireless USB Dongle protocol, and Bluetooth DualSense/Xbox pads suffer from conservative energy-saving polling intervals.
- **DoomOS Engineering Solution:**
  1. **Kernel Driver Modules Pre-installed:**
     - `xone-dkms` (driver for Xbox One and Series X/S wireless adapters with full audio support).
     - `xpadneo-dkms` (advanced Linux driver for Xbox One Wireless Gamepads over Bluetooth).
     - `hid-playstation` official Sony driver with full DualSense touchpad and haptic feedback support.
  2. **Bluetooth High-Frequency Polling:** `/etc/bluetooth/input.conf` configured with `IdleTimeout=0` and low-latency connection intervals.

---

# SECTION 2: EVERYDAY USER PAINS & TECHNICAL SOLUTIONS

```
+---------------------------------------------------------------------------------------+
| EVERYDAY USER PROBLEM        | DOOMOS ARCHITECTURAL SOLUTION                          |
+------------------------------+--------------------------------------------------------+
| 1. Fear of Breaking the OS   | Btrfs Snapper Automated Pre/Post Snapshots in GRUB     |
| 2. Blurry Fractional Scaling | Wayland-First Subpixel Scaling + Crisp XWayland Flags  |
| 3. Backpack Battery Drain    | auto-cpufreq + Deep Sleep / Suspend Kernel Hooks       |
| 4. Headset Mono Audio Bug    | PipeWire Auto-Switching Faststream / LDAC / aptX-HD    |
| 5. Missing Video Codecs      | Universal GStreamer/FFmpeg + Hardware VA-API Decoding  |
| 6. App Store Chaos           | Unified KDE Discover with Verified Flathub Sandbox     |
+---------------------------------------------------------------------------------------+
```

---

### Problem 2.1: "Update Anxiety" (A Routine Update Renders the PC Unbootable)
- **Root Cause:** A bad update or power interruption damages libc, systemd, or kernel drivers. Non-technical users cannot fix this via chroot/TTY and reinstall Windows.
- **DoomOS Engineering Solution:**
  1. **Default Btrfs Subvolume Layout:**
     - `@` -> Root filesystem (`/`)
     - `@home` -> User data (`/home`) — *never rolled back, keeping user files intact*
     - `@snapshots` -> System snapshots (`/.snapshots`)
     - `@var_log` -> Persistent system logs (`/var/log`)
  2. **Automated Transaction Snapping (`snapper` + `grub-btrfs`):**
     - Before every update, a snapshot named `Pre-Update [timestamp]` is generated.
     - After every update, a snapshot named `Post-Update [timestamp]` is generated.
  3. **Instant GRUB Rollback Menu:**
     - If the system fails to boot, the user turns on the PC, selects `DoomOS Snapshots` from the bootloader menu, picks the snapshot taken 10 minutes ago, and boots into a read-write working system instantly.

---

### Problem 2.2: Blurry Text & Apps on Laptops (Fractional Scaling Issues)
- **Root Cause:** Under legacy X11, scaling an interface to 125% or 150% scales the display as a raster image, producing blurry fonts and window elements.
- **DoomOS Engineering Solution:**
  1. **True Wayland-Native Fractional Scaling:** KDE Plasma 6 renders UI elements at integer viewport buffers and downscales dynamically using bicubic filtering.
  2. **High-DPI Flag Injection for Legacy X11 Apps:** Automated environment profiles (`/etc/environment.d/10-hidpi.conf`):
     ```ini
     # Enables crisp rendering in Qt and Electron/Chromium apps under Wayland
     QT_QPA_PLATFORM="wayland;xcb"
     ELECTRON_OZONE_PLATFORM_HINT="auto"
     GDK_BACKEND="wayland,x11,*"
     ```

---

### Problem 2.3: Laptop Overheating & Battery Drain During Sleep
- **Root Cause:** Modern laptops use ACPI "Modern Standby" (`s2idle`) instead of traditional S3 deep sleep. Linux distros often fail to disable wake-timers on USB/PCI devices, causing laptops to wake up inside backpacks and overheat.
- **DoomOS Engineering Solution:**
  1. **Kernel Sleep Policy Tuning:** `/etc/systemd/sleep.conf.d/10-doomos-power.conf`:
     ```ini
     [Sleep]
     MemorySleepMode=deep s2idle
     HibernateDelaySec=1800
     SuspendState=mem
     ```
  2. **Intelligent Power Daemon (`auto-cpufreq`):** Monitors battery status and CPU temperature:
     - On Battery: Downclocks E-cores, throttles aggressive turbo boost, dims display refresh rate to 60Hz.
     - On AC: Unlocks full performance and high refresh rates (120Hz/144Hz/240Hz).

---

### Problem 2.4: Bluetooth Audio Drops to Horrible Mono Quality During Calls
- **Root Cause:** When an application requests microphone access, PulseAudio historically switched the entire Bluetooth profile from high-fidelity A2DP (music) to low-bandwidth HSP/HFP (voice), collapsing sample rates to 8kHz mono.
- **DoomOS Engineering Solution:**
  - DoomOS ships with **PipeWire 1.2+ and WirePlumber** configured with `bluez5.enable-msbc = true` and `bluez5.enable-sbc-xq = true`.
  - When microphones are engaged, WirePlumber keeps output channels separated or utilizes mSBC wideband speech codecs, avoiding degradation of desktop background sound.

---

# SECTION 3: DEVELOPER PAINS & TECHNICAL SOLUTIONS

```
+---------------------------------------------------------------------------------------+
| DEVELOPER PROBLEM            | DOOMOS ARCHITECTURAL SOLUTION                          |
+------------------------------+--------------------------------------------------------+
| 1. Broken Wayland Screen Share| xdg-desktop-portal-kde + PipeWire WebRTC Portal Hooks  |
| 2. Docker Requires `sudo`    | Pre-configured Rootless Docker / Podman Group Engine   |
| 3. IDE / Webpack Inotify Crash| Enhanced /etc/sysctl.d/99-developer.conf Inotify Limits|
| 4. Toolchain Version Clashes | Pre-installed Distrobox / BoxBuddy Containerized Dev   |
| 5. Dual-Boot Clock Drift     | Automated LocalTime RTC Sync Flag in Calamares         |
+---------------------------------------------------------------------------------------+
```

---

### Problem 3.1: Screen Sharing Fails or Lacks Audio in Discord, Slack, and Zoom
- **Root Cause:** Wayland does not permit applications to read pixels from the global display frame (for security). Video conferencing tools must use the Desktop Portal API (`XDG Desktop Portal`). If portals or PipeWire WebRTC hooks are missing or mismatched, screen sharing produces a black box or crashes.
- **DoomOS Engineering Solution:**
  1. **Complete Portal Suite Pre-installed:**
     - `xdg-desktop-portal-kde` (optimized for KWin Wayland)
     - `xdg-desktop-portal-gtk` (for GTK/GNOME compatibility)
  2. **Virtual Audio Loopback Sink:** Pre-configured PipeWire module allowing developers to stream their microphone *and* system sound simultaneously in Discord/Slack without third-party virtual cables:
     ```ini
     # /etc/pipewire/pipewire.conf.d/10-loopback-share.conf
     context.modules = [
         { name = libpipewire-module-loopback
           args = {
               node.description = "DoomOS Meeting Share Sink"
               capture.props = { media.class = "Audio/Sink" }
           }
         }
     ]
     ```

---

### Problem 3.2: Docker Requires Root Privileges or Updates Break Network Daemon
- **Root Cause:** Traditional Docker distributions run a root daemon. Running commands without `sudo` requires manual group creation (`sudo usermod -aG docker $USER`), which is error-prone and presents security vulnerabilities.
- **DoomOS Engineering Solution:**
  1. **Rootless Docker Pre-configured:** System user accounts provisioned during Calamares installation are automatically enrolled in rootless namespaces with subuid/subgid mapping pre-populated in `/etc/subuid` and `/etc/subgid`.
  2. **Container Engine Alternatives:** Both `docker` and daemonless `podman` are installed out-of-the-box, with `podman-docker` compatibility aliases enabled.

---

### Problem 3.3: IDEs (VS Code, Webpack, JetBrains) Crash on Large Codebases
- **Root Cause:** The Linux kernel's default `fs.inotify.max_user_watches` is set to 8,192. When an engineer opens a repository with extensive `node_modules` or thousands of source files, the watch handles are exhausted, causing silent file-saving failures or IDE crashes.
- **DoomOS Engineering Solution:**
  - Ships with high-capacity sysctl configurations in `/etc/sysctl.d/99-developer-performance.conf`:
    ```ini
    # Prevent inotify exhaustion in large codebases
    fs.inotify.max_user_watches = 1048576
    fs.inotify.max_user_instances = 2048
    
    # Increase memory map areas for databases and JVM
    vm.max_map_count = 2147483642
    
    # Fast network buffer tuning
    net.core.somaxconn = 8192
    ```

---

### Problem 3.4: Dual-Boot Clock Desynchronization with Windows
- **Root Cause:** Linux assumes the computer hardware clock (RTC) is set to UTC, while Windows assumes the hardware clock is set to Local Time. Booting between the two OSes results in the system clock jumping by several hours.
- **DoomOS Engineering Solution:**
  - The DoomOS Calamares installer automatically inspects existing partitions on all NVMe/SATA drives.
  - If a Microsoft EFI partition (`/EFI/Microsoft/Boot/bootmgfw.efi`) is detected, the installer automatically executes:
    ```bash
    timedatectl set-local-rtc 1 --adjust-system-clock
    ```
    This completely eliminates clock desynchronization out-of-the-box.

---

### Problem 3.5: Dirty Host Toolchain Pollution (Managing Node, Python, Rust Versions)
- **Root Cause:** Developers installing multiple Python or Node versions directly on the host OS risk breaking system utilities that rely on system-level interpreters.
- **DoomOS Engineering Solution:**
  1. **Distrobox & BoxBuddy GUI Integrated:**
     - Developers can launch isolated Ubuntu, Debian, Fedora, or Alpine containers inside their host terminal with one click.
     - Full access to host files (`$HOME`), GPU acceleration, and audio without polluting host libraries.
  2. **Modern Developer Shell:**
     - Pre-configured Fish or Zsh terminal with **Starship prompt**, `fzf` fuzzy finder, `bat` (syntax-highlighted cat), and `eza` (modern ls).

---

## SECTION 4: VERIFICATION & ACCEPTANCE CRITERIA

| Feature | Automated / Manual Test Method | Pass Criteria |
| :--- | :--- | :--- |
| **NVIDIA Driver Safe-Guard** | Simulate broken DKMS build during mock package update. | Transaction aborts; active kernel remains untouched. |
| **Btrfs Snapshot Rollback** | Induce simulated system corruption; reboot into snapshot. | System boots to graphical desktop in $< 10$ seconds. |
| **Wayland Screen Share** | Launch Chromium / Discord; trigger window/screen share. | Screen captures smoothly with zero flicker or crash. |
| **Xbox Wireless Controller** | Connect Xbox dongle; verify `dmesg` output. | `xone` loads; controller pairs and operates instantly. |
| **Inotify Limit Verification**| Run watch script on 200,000 files in mock repo. | No `ENOSPC` errors thrown by kernel. |
| **Windows Clock Sync** | Install in dual-boot VM with Windows 11. | Host RTC time remains identical between OS reboots. |

---

*This document serves as the implementation blueprint for all default packages, kernel patches, and systemd configurations for DoomOS.*
