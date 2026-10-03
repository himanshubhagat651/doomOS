# DoomOS Hardware Center Specification & Technical Architecture

## 1. Purpose & Design Philosophy

The **DoomOS Hardware Center** provides everyday users and systems administrators with an intuitive, single-pane-of-glass graphical interface to inspect, audit, and understand their physical and virtual computer hardware without requiring cryptic terminal commands (`lscpu`, `lspci`, `lsblk`, `free`, `ip`, `inxi`).

### Core Design Principles:
- **Informational & Non-Destructive:** The Hardware Center strictly detects and reports telemetry. It never partitions disks, modifies network configurations, changes audio sinks, or uninstalls drivers.
- **Pure Zero-Privilege Security:** The detection engine and GUI run strictly with standard user privileges (`liveuser` / unprivileged user). Root elevation via `sudo` or `pkexec` is never requested or required.
- **Architectural Portability:** Fully dynamic detection supporting ARM64 (Apple Silicon M1/M2/M3/M4 via VMware Fusion), AMD/Intel x86_64, VirtIO, and physical bare-metal systems.
- **Decoupled Architecture:** Clean separation between the Detection Engine, Data Model, and User Interface to allow future centers (Driver Center, Fix Center) to reuse the detection logic without duplicating code.

---

## 2. Architecture & Subsystem Layout

```
+---------------------------------------------------------------------------------------+
|                                     UI LAYER                                          |
|         doomos-hardware-center (Tkinter / Wayland / KDE Dark Theme Integrated)        |
+---------------------------------------------------------------------------------------+
|                                 DATA MODEL LAYER                                      |
|                 HardwareStatus Badges: GOOD | WARNING | UNKNOWN | ERROR               |
|                 Normalized Dictionaries & Plaintext Export Summaries                  |
+---------------------------------------------------------------------------------------+
|                              HARDWARE DETECTION LAYER                                 |
|         doomos-hardware-detect (/sys, /proc, udev, PipeWire, kscreen-doctor)           |
+---------------------------------------------------------------------------------------+
|                                   OS RUNTIME                                          |
|        Linux Kernel (ARM64 / Zen / LTS) | systemd | D-Bus | Wayland Compositor        |
+---------------------------------------------------------------------------------------+
```

### Files & Locations:
1. **Detection Engine & CLI Utility:** `/usr/bin/doomos-hardware-detect`
2. **Graphical User Interface:** `/usr/bin/doomos-hardware-center`
3. **FreeDesktop System Launcher:** `/usr/share/applications/doomos-hardware-center.desktop`
4. **User Template Launcher:** `/etc/skel/.local/share/applications/doomos-hardware-center.desktop`

---

## 3. Hardware Detection Methods

| Category | Source Interface | Method & Logic |
| :--- | :--- | :--- |
| **System Info** | `/etc/os-release`, `/proc/uptime`, `/sys/firmware/efi` | Extracts distribution branding, kernel release, uptime in hours/minutes, and detects UEFI vs. BIOS boot mode. |
| **CPU** | `/proc/cpuinfo`, `/sys/devices/system/cpu/` | Parses CPU model string, vendor ID, physical core topology, logical thread counts, and current frequency scaling. |
| **Memory & ZRAM** | `/proc/meminfo`, `/proc/swaps`, `/dev/zram0` | Calculates installed RAM, used memory, available memory, swap allocation, and validates active ZRAM compression status. |
| **GPU & Acceleration** | `/sys/class/drm/card*`, sysfs `device/driver` | Detects physical and virtual display adapters (VMware SVGA3D, VirtIO, AMD Radeon, Intel Iris, NVIDIA), identifying active kernel drivers. |
| **Storage Drives** | `/sys/block/*`, `/proc/mounts`, `statvfs` | Filters loop/zram devices, calculates drive capacity, classifies disk types (NVMe SSD, SATA SSD, HDD, VirtIO), mounts, and filesystem types. |
| **Networking** | `/sys/class/net/*`, `/sys/class/bluetooth/` | Audits Ethernet, Wi-Fi, and Bluetooth adapters, identifying interface names, driver modules, connection states, and link speeds. |
| **Audio Subsystem** | `/proc/asound/cards`, PipeWire process supervisor | Confirms low-latency PipeWire daemon status and lists available ALSA sound cards, default sinks, and loopback devices. |
| **Displays** | `kscreen-doctor -o`, `/sys/class/drm/` connectors | Probes connected monitors, resolutions, and refresh rates under KDE Plasma 6 Wayland. |
| **Input Devices** | `/proc/bus/input/devices` | Identifies attached keyboards, mice, trackpads, and gamepads. |
| **USB Devices** | `/sys/bus/usb/devices/`, `lsusb` | Catalogs attached USB peripherals with vendor and model names. |

---

## 4. UI Structure & Features

### 1. Header Control Bar
- **Refresh Hardware (🔄):** Re-runs the detection layer on-demand and updates all cards without blocking or restarting the application.
- **Copy Report (📋):** Generates a formatted plaintext specification report and places it into the system clipboard.
- **Export File (💾):** Opens a file dialog allowing users to save `DoomOS-Hardware-Report.txt` anywhere on disk.

### 2. Category Navigation Panel
- **System Overview:** High-level summary of OS, CPU, RAM, and GPU.
- **Dedicated Categories:** Deep-dive cards for Processor, Memory, Graphics, Storage Drives, Network & Wi-Fi, Audio, Displays, Input Devices, and USB Peripherals.
- **Technical Details:** Scrollable raw diagnostic export viewer.

### 3. Status Badges
- **GOOD (Green):** Component detected and fully operational.
- **WARNING (Yellow):** Component detected with degraded connectivity or missing metric.
- **UNKNOWN (Blue):** Kernel or hypervisor does not expose metric.
- **ERROR (Red):** Detection failure or missing hardware node.

---

## 5. Security & Privacy Considerations

- **No Elevated Privileges:** Executes entirely in userspace with standard UID permissions.
- **Privacy Protection:** Network reports include interface names and connection states but strip MAC addresses, local IP addresses, Wi-Fi SSIDs, and credentials.
- **No Telemetry:** Reports are generated strictly on the local machine and never transmitted to external endpoints.

---

## 6. Testing & Validation

The test suite [`tests/test-step2-hardware-center.sh`](file:///Users/himanshu/Downloads/dr%20doom/tests/test-step2-hardware-center.sh) verifies:
- Executable presence and permissions (`755`).
- Python syntax compilation (`py_compile`).
- Archiso integration in `profiledef.sh` and `customize_airootfs.sh`.
- Desktop entry compliance with FreeDesktop standards.
- Full regression testing with Phases 0 through 5 passing 100%.

---

## 7. Future Integration Opportunities

The decoupled `HardwareDetector` engine in `/usr/bin/doomos-hardware-detect` is architected to directly feed:
1. **Driver Center (Step 4):** Querying `detect_gpu()` and `detect_network()` to offer 1-click proprietary driver and firmware installations.
2. **Fix Center (Step 5):** Querying `detect_audio()` and `detect_network()` to automate audio sink restores and network route repairs.
