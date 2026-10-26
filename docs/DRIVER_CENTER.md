# DoomOS Driver Center Specification & Technical Architecture

## 1. Purpose & Design Philosophy

The **DoomOS Driver Center** provides everyday users and system administrators with a transparent, beginner-friendly diagnostic tool to inspect device drivers, kernel module bindings, and hardware support status without requiring complex terminal commands (`lsmod`, `lspci -k`, `modinfo`, `dmesg`, `rfkill`).

### Core Design Principles:
- **Detect → Diagnose → Explain → Recommend:** The Driver Center identifies hardware, checks driver and module status, explains problems in clear plain language, and provides safe, evidence-based recommendations.
- **Never Blindly or Silently Install Drivers:** Does not alter system packages, load/unload kernel modules, modify bootloader parameters, or execute destructive disk commands.
- **Zero-Privilege Security:** Runs entirely under standard user permissions (`liveuser` / normal desktop user). No setuid-root binaries, sudo elevation, or polkit privilege bypasses.
- **Architectural Portability:** Dynamically identifies AArch64 (ARM64) Apple Silicon, virtualized hypervisors (VMware, QEMU, KVM), and standard hardware platforms.
- **Privacy-First Telemetry:** Serial numbers, UUIDs, and network MAC addresses are sanitized and masked before being rendered or exported in diagnostic reports.

---

## 2. Architecture & Subsystem Layout

```
+---------------------------------------------------------------------------------------+
|                                     UI LAYER                                          |
|            doomos-driver-center (Tkinter / Wayland / KDE Dark Theme Integrated)       |
+---------------------------------------------------------------------------------------+
|                                 DATA MODEL LAYER                                      |
|            DriverStatus: GOOD | WARNING | MISSING | UNKNOWN | UNSUPPORTED | ERROR      |
|            Structured Telemetry & Plaintext Export Diagnostic Reports                 |
+---------------------------------------------------------------------------------------+
|                             DRIVER DETECTION LAYER                                    |
|            doomos-driver-detect (/sys, /proc/modules, udev, ALSA, PipeWire)           |
+---------------------------------------------------------------------------------------+
|                                   OS RUNTIME                                          |
|            Linux Kernel (ARM64 / vmwgfx / Asahi) | systemd | D-Bus | Wayland          |
+---------------------------------------------------------------------------------------+
```

### Files & Locations:
1. **Driver Detection Engine & CLI:** `/usr/bin/doomos-driver-detect`
2. **Driver Center Graphical Interface:** `/usr/bin/doomos-driver-center`
3. **FreeDesktop System Launcher:** `/usr/share/applications/doomos-driver-center.desktop`
4. **User Template Launcher:** `/etc/skel/.local/share/applications/doomos-driver-center.desktop`
5. **Acceptance Test Suite:** `tests/test-step3-driver-center.sh`
6. **Documentation:** `docs/DRIVER_CENTER.md`

---

## 3. Hardware & Driver Detection Methods

| Subsystem | Source Interface | Detection Method & Evidence Logic |
| :--- | :--- | :--- |
| **System Info** | `/proc/sys/kernel/osrelease`, `platform.machine()`, `systemd-detect-virt` | Audits CPU architecture, kernel release, hypervisor presence (VMware, QEMU, KVM), and physical Apple Silicon device-tree compatible strings. |
| **Graphics** | `/sys/class/drm/card*`, sysfs `device/driver` | Checks DRM card nodes, bound driver link (e.g. `vmwgfx`, `virtio_gpu`, `apple-drm`, `amdgpu`), verifies module in `/proc/modules`, and validates display acceleration status. |
| **Network (Wi-Fi & Ethernet)** | `/sys/class/net/*`, sysfs `device/driver`, `operstate` | Identifies network adapters, confirms bound driver (e.g. `vmxnet3`, `brcmfmac`), inspects link carrier state (`up`, `down`), and reports connection status. |
| **Bluetooth** | `/sys/class/bluetooth/hci*`, `/sys/class/rfkill/` | Audits HCI controller nodes, driver attachments, and inspects RFKILL software/hardware blocks. |
| **Audio** | `/proc/asound/cards`, `/sys/class/sound/card*`, PipeWire & WirePlumber pids | Catalogs ALSA sound cards, bound kernel audio modules (`snd_hda_intel`, `snd_soc_*`), and verifies runtime status of PipeWire and WirePlumber daemons. |
| **Storage** | `/sys/block/*`, sysfs `device/driver` | Probes physical and virtual block devices (NVMe, SCSI/SATA, VirtIO), validating controller drivers and mounted subvolumes. |
| **Input & Peripherals** | `/proc/bus/input/devices`, `/sys/bus/usb/devices/` | Discovers attached keyboards, pointing devices, trackpads, and USB controllers with active handler drivers (`evdev`, `hid`, `usbcore`). |
| **Displays** | `/sys/class/drm/card*-*`, `kscreen-doctor` | Probes connected DRM display outputs and active resolutions under Wayland. |

---

## 4. Status Model Definitions

The Driver Center adheres to 6 canonical diagnostic statuses:

- `GOOD` — Driver/module is detected and available evidence confirms the device is bound and operational.
- `WARNING` — Driver exists and is bound, but an issue requires attention (e.g. network interface is down/unplugged, Bluetooth is soft-blocked by RFKILL, audio server is in standby).
- `MISSING` — Evidence confirms that a required driver or firmware is missing (e.g. device node present without driver binding, firmware load error).
- `UNKNOWN` — Available evidence is insufficient to make a definitive assessment.
- `UNSUPPORTED` — Verified evidence indicates the current DoomOS environment or architecture does not support the device.
- `ERROR` — Reliable diagnostic evidence indicates a device or driver runtime error.

---

## 5. ARM64 / Apple Silicon & Virtual Machine Considerations

### Virtual Machine Environments (VMware Fusion / Workstation)
- **Host Hardware Abstraction:** In virtual machines, hardware devices are virtualized (e.g. VMware SVGA II, vmxnet3, vmmouse).
- **Driver Clarity:** The Driver Center explicitly detects the `vmware` hypervisor. It explains that 3D acceleration is host-backed via `vmwgfx` and Metal on macOS.
- **No Physical Drivers in VMs:** Prevents confusion by recommending against installing physical GPU (NVIDIA/AMD) drivers inside a virtual guest.

### Physical Apple Silicon (M1/M2/M3/M4)
- **Upstream Kernel & Asahi Drivers:** Drivers are integrated directly into the kernel image (e.g. `apple-drm`, `brcmfmac`, `apple-nvme`).
- **Architecture Enforcement:** Highlights that proprietary x86_64 drivers cannot be installed on ARM64 systems.
- **Safety Lock:** Prohibits raw partition operations on internal Apple SSDs.

---

## 6. Security & Privacy Safeguards

1. **Read-Only Operation:** Telemetry is gathered purely through read-only access to `/sys`, `/proc`, and standard user query tools.
2. **Zero Root Privilege:** Never prompts for `sudo` or requires elevated rights.
3. **Data Sanitization:**
   - Network MAC addresses: All patterns matching `xx:xx:xx:xx:xx:xx` are masked to `XX:XX:XX:XX:XX:XX`.
   - UUIDs & Serial Numbers: System and drive UUIDs/serials are masked.
   - Credentials: No Wi-Fi passphrases, tokens, or private keys are ever inspected or included in reports.

---

## 7. Diagnostic Report Format

Diagnostic reports adhere strictly to the standardized DoomOS structure:

```text
DoomOS Driver Diagnostic Report
================================

System
------
Architecture: aarch64
Kernel: 6.6.x-doomos
Detection Time: 2026-10-26 04:46:42 UTC

Graphics
--------
Device: VMware SVGA3D Virtual Graphics Adapter
Driver: vmwgfx
Kernel Module: LOADED
Firmware: HOST_BACKED
Status: GOOD

Network
-------
Device: VMware vmxnet3 Virtual High-Speed NIC (eth0)
Driver: vmxnet3
Firmware: NOT_REQUIRED
Status: GOOD

Bluetooth
---------
Device: Integrated Bluetooth Subsystem
Driver: kernel-bluetooth
Firmware: NOT_REQUIRED
Status: GOOD

Audio
-----
Device: High Definition Audio Device (card0)
Kernel Module: LOADED
PipeWire: Active
WirePlumber: Active
Status: GOOD

Storage
-------
Device: Storage Drive (/dev/sda)
Controller: SCSI / SATA Disk Controller
Kernel Module: BUILTIN
Status: GOOD

Input and USB
-------------
Detected devices: VMware Virtual USB Mouse, AT Translated Set 2 keyboard
Driver information: evdev, hid
Status: GOOD

Summary
-------
GOOD: 7
WARNING: 0
MISSING: 0
UNKNOWN: 0
UNSUPPORTED: 0
ERROR: 0

Recommended Actions
------------------
1. Virtualization Detected (vmware): Host hardware abstraction is active.
   Hardware drivers are provided by hypervisor guest tools. Do not install physical GPU drivers.
```

---

## 8. Verification & Test Suite

The test suite is located at `tests/test-step3-driver-center.sh` and contains 41 automated checks across 9 categories:
1. File Presence & Execution Permissions (6 checks)
2. Archiso Profile Integration Audit (3 checks)
3. Python Syntax & Integrity Audit (2 checks)
4. Backend Structured JSON & Architecture Telemetry (6 checks)
5. Diagnostic Report Specification Compliance (10 checks)
6. Status Model & Fixture Robustness Verification (3 checks)
7. GUI Backend Integration & Export Verification (1 check)
8. FreeDesktop Entry Standard Compliance (5 checks)
9. Security, Privacy & Safety Guard Audit (5 checks)

---

## 9. Known Limitations

- **Physical Apple Silicon Testing:** Development and validation was conducted within an ARM64 virtualized environment (VMware Fusion on Apple Silicon macOS host) and automated test suites. Validation on bare-metal Asahi Linux partition chains remains an extended release testing milestone.
- **Proprietary Wireless Firmware:** In rare bare-metal scenarios where Broadcom firmware blobs are absent from the live medium, the wireless interface will correctly report `MISSING` firmware and prompt the user to establish a wired connection.
