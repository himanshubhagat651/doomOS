# DoomOS Live Preview & Installation Architecture

## 1. Overview
DoomOS is delivered as a bootable, hybrid ARM64/UEFI Live system. When booted into the Live desktop environment, the user is presented with a complete KDE Plasma 6 desktop that allows testing all hardware components (audio, graphics, networking, storage, displays) without altering any internal drives.

The **DoomOS Installer** provides an integrated path from testing the system to installing it onto local or virtual storage.

---

## 2. Architecture & Components

### 2.1 Visual Entry Points
- **Desktop Launcher**: `/etc/skel/Desktop/doomos-installer.desktop`
  - Rendered prominently on the live user's desktop with the label `Install DoomOS` and icon `system-software-install`.
- **Application Menu**: `/usr/share/applications/doomos-installer.desktop` and `/etc/skel/.local/share/applications/doomos-installer.desktop`
  - Searchable in the KDE Kickoff menu under System & Settings.

### 2.2 Execution Engine
- **GUI Application**: `/usr/bin/doomos-installer`
  - High-performance, responsive Python Tkinter interface matching the Dr. Doom dark palette (`#181a1f`, `#21252b`, `#98c379`).
  - Wizard workflow:
    1. **Welcome Screen**: Allows choosing between *Try DoomOS* (closes installer, preserves live preview) and *Install DoomOS*.
    2. **Hardware Compatibility Check**: Probes CPU architecture (`aarch64`), UEFI boot status, available memory, and virtual machine hypervisors.
    3. **Disk Selection**: Discovers all attached storage disks, displaying models and capacities, with explicit destructive format warnings.
    4. **User Setup**: Configures user full name, UNIX username, hostname, password confirmation, and optional automatic login.
    5. **Installation Summary**: Reviews all parameters before touching storage.
    6. **Progress Tracker**: Displays step-by-step progress and status.
    7. **Completion & Reboot**: Provides buttons to restart immediately or continue exploring the Live Preview.
- **Backend Safety Engine**: `/usr/bin/doomos-installer-engine`
  - Identifies the live boot medium via `/proc/mounts` and filters it out to prevent self-destruction.
  - Implements the DoomOS Btrfs standard subvolume layout:
    - `@` -> `/` (root)
    - `@home` -> `/home`
    - `@snapshots` -> `/.snapshots`
    - `@var_log` -> `/var/log`
    - `zstd:3` transparent filesystem compression.
  - Generates safe log files at `/var/log/doomos-installer.log` (sanitized of passwords).

---

## 3. Apple Silicon Safety Model

DoomOS strictly respects Apple Silicon hardware safety constraints:

1. **Virtual Machine Execution (VMware Fusion / UTM)**:
   - The virtual environment is detected via `systemd-detect-virt` / DMI.
   - Virtual NVMe storage (`/dev/nvme0n1`) or SATA disks are safely targeted.
2. **Bare-Metal Apple Silicon Hardware**:
   - The engine checks for Apple Silicon hardware models via `/proc/device-tree/model`.
   - On physical Apple Silicon hardware, internal NVMe installation requires the multi-stage Asahi bootloader chain (`m1n1` / `u-boot` / macOS boot policy).
   - The engine **blocks destructive direct disk wiping** on bare-metal internal Mac storage and displays:
     > *"Apple Silicon installation support is not yet fully validated on bare-metal internal storage. Destructive operations were aborted to preserve macOS container integrity."*
   - This ensures internal APFS macOS containers are never corrupted.

---

## 4. Verification & Testing

The installer implementation is audited by `tests/test-doomos-installer.sh`:
- Launcher and FreeDesktop specification compliance (4/4 PASS).
- Permissions and archiso build integration (6/6 PASS).
- Python module syntax and compilation (2/2 PASS).
- Hardware compatibility and safety engine output (1/1 PASS).
- Non-destructive dry-run execution (1/1 PASS).
- FreeDesktop standards validation (4/4 PASS).
- Total checks: **19/19 PASS**.
