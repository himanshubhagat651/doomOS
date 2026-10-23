# DoomOS Immortal Boot & Problem-Solving Subsystems

## 1. Overview
DoomOS implements 5 automated, zero-configuration background subsystems that directly solve the most critical stability and productivity bottlenecks encountered by Linux desktop users:

1. **Immortal Boot (Btrfs Snapper Automated Rollback)**
2. **DoomOS Guardian (DKMS Driver Verification Hook)**
3. **Developer Kernel & Inotify Performance Tuning**
4. **Wayland Portal & PipeWire Audio Loopback Suite**
5. **Laptop Power & Deep Sleep Policy**

---

## 2. Subsystem Architecture

### 2.1 Immortal Boot (Automated Btrfs Rollback)
* **Goal:** Completely eliminate update anxiety and unbootable systems.
* **Mechanism:**
  - Root partition is formatted as Btrfs with standard subvolumes: `@`, `@home`, `@snapshots`, and `@var_log`.
  - Configured via `/etc/snapper/configs/root` with `TIMELINE_CREATE=yes` and `NUMBER_LIMIT=10`.
  - Integrates `snap-pac` to automatically capture pre-transaction and post-transaction snapshots during every `pacman` operation.
  - `grub-btrfsd.service` dynamically parses `/btrfs-root/@snapshots` and regenerates the GRUB boot menu in real time.
* **Recovery:** If a system update ever breaks userspace or the kernel, the user selects the previous snapshot from the GRUB menu at boot to roll back instantly without a terminal.

### 2.2 DoomOS Guardian (DKMS Driver Safety Hook)
* **Goal:** Prevent unbootable black screens caused by broken GPU driver module compilations.
* **Mechanism:**
  - Deploys ALPM hook `/usr/share/libalpm/hooks/90-doomos-nvidia-guardian.hook`.
  - Triggers on `PostTransaction` upgrades of `nvidia-dkms`, custom modules, and target kernels.
  - Invokes `/usr/bin/doomos-nvidia-verify` to verify that `nvidia.ko` exists and compiles cleanly.
  - If a build failure is detected, it logs an alert and preserves fallback entries (`linux-lts`) in the GRUB boot menu before the user reboots.

### 2.3 Developer Kernel & Inotify Performance Tuning
* **Goal:** Prevent IDE crashes, file-watcher exhaustion, and container memory errors in heavy dev environments.
* **Mechanism:**
  - Deploys `/etc/sysctl.d/99-developer-performance.conf`.
  - **Inotify Limits:** `fs.inotify.max_user_watches = 1048576`, `fs.inotify.max_user_instances = 2048`. Prevents VS Code, JetBrains IDEs, Vite, and Webpack from dropping file watchers on large monorepos.
  - **Memory Mapping:** `vm.max_map_count = 2147483642`. Necessary for databases, JVM runtimes, and Docker containers.
  - **Network Backlog:** `net.core.somaxconn = 8192`. Eliminates connection dropped errors during local load testing.

### 2.4 Wayland Portal & PipeWire Audio Loopback
* **Goal:** Seamless screen sharing with internal desktop audio on Wayland without third-party audio routers.
* **Mechanism:**
  - Deploys `/etc/pipewire/pipewire.conf.d/10-loopback.conf`.
  - Creates a virtual audio node (`doomos_share_sink`) and source (`doomos_share_source`).
  - Merges microphone input with desktop audio so applications (Discord, OBS, browser meetings) can capture crisp system audio along with the speaker's voice.
  - Coordinates with `xdg-desktop-portal-kde` for one-click Wayland window/screen sharing.

### 2.5 Laptop Power & Deep Sleep Policy
* **Goal:** Stop battery drain and prevent laptop overheating inside closed backpacks.
* **Mechanism:**
  - Deploys `/etc/systemd/sleep.conf.d/10-doomos-sleep.conf`.
  - Enforces `MemorySleepMode=deep s2idle`, requiring hardware to drop to true ACPI S3 low-power states rather than draining battery on modern standby.
  - Integrates `power-profiles-daemon` to dynamically adjust power modes based on battery vs. AC power states.

---

## 3. Verification & Acceptance Testing
All 5 subsystems are tested automatically via `tests/test-step4-subsystems.sh` (17/17 checks PASS) and integrated into the continuous integration build workflow.
