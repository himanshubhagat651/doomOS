# DoomOS v1.0.0 — Testing & Deployment Manual

This guide outlines the complete test and deployment procedures for **DoomOS (KDE Plasma 6 Edition)** across Virtual Machines (VMware Fusion / Workstation, UTM, QEMU) and Bare-Metal hardware.

---

## 🚀 Quick Launch Matrix

| Environment | Host OS / Architecture | Command / Action | Acceleration Mode |
| :--- | :--- | :--- | :--- |
| **VMware Fusion** | macOS (Intel / x86_64) | `./test-vmware.sh` | Direct 3D SVGA / Native |
| **VMware Workstation** | Linux / Windows (x86_64) | Copy `DoomOS.vmwarevm` | Direct 3D SVGA / KVM / VT-x |
| **UTM / QEMU** | macOS (Apple Silicon arm64) | `./test-qemu.sh` | TCG Multi-threaded Emulation |
| **QEMU / KVM** | Linux (x86_64) | `./test-qemu.sh` | Hardware KVM (`-enable-kvm`) |
| **Bare-Metal PC** | Any x86_64 PC (AMD/Intel) | `./flash-usb.sh` | Native GPU (AMD / Intel / NVIDIA) |

---

## 🛠️ Step 1: Virtual Machine Verification

### Option A: Testing with VMware Fusion / Workstation
1. Run `./test-vmware.sh` to generate the pre-configured `DoomOS.vmwarevm` bundle.
2. The bundle contains:
   - **Firmware**: UEFI Modern Boot (`firmware = "efi"`).
   - **vCPU & RAM**: 4 Cores, 4096 MB RAM.
   - **Storage**: High-performance NVMe virtual disk + SATA CD-ROM mounted to `output/doomos-plasma-x86_64.iso`.
   - **Graphics**: 3D Acceleration enabled with 2048 MB VRAM (`mks.enable3d = "TRUE"`).
3. If on an Intel Mac or PC, start the VM:
   - macOS: Double-click `DoomOS.vmwarevm` or run `/Applications/VMware\ Fusion.app/Contents/Public/vmrun -T fusion start DoomOS.vmwarevm/DoomOS.vmx gui`.
   - Windows/Linux: Open `DoomOS.vmwarevm/DoomOS.vmx` in VMware Workstation.

### Option B: Testing with UTM on Apple Silicon (M1/M2/M3/M4 Macs)
1. Run `./test-qemu.sh`.
2. When prompted, select **Y** to launch UTM.
3. In UTM:
   - Click the **+** (New Machine) button -> Select **Emulate** (Emulate slower, for different CPU architecture).
   - Select **Linux**.
   - Browse and select `doomos-builder/output/doomos-plasma-x86_64.iso`.
   - Allocate **4096 MB RAM** and **4 CPU cores**.
   - Under Display, select **VirtIO-GPU**.
   - Click **Save** and hit **Play**.

### Option C: Testing with Native Linux KVM
1. Run `./test-qemu.sh`.
2. The script auto-detects `/dev/kvm` and boots the ISO using hardware virtualization, 4 cores, 4GB RAM, and OVMF UEFI firmware.

---

## 📋 Step 2: Live Session QA Checklist

Once booted into the Live Environment, verify each of the following subsystems:

### 1. Plymouth Boot & SDDM Autologin
- [ ] **Boot Animation:** Plymouth displays the DoomOS logo during kernel init without text corruption.
- [ ] **SDDM Autologin:** Boots directly into KDE Plasma 6 Wayland session as user `liveuser` without prompting for a password.
- [ ] **Wayland Verification:** Open Konsole and run:
  ```bash
  echo $XDG_SESSION_TYPE
  # Expected output: wayland
  ```

### 2. High-DPI & Display Stack
- [ ] **Fractional Scaling:** Open *System Settings -> Display and Monitor*. Verify fractional scaling (125%, 150%) renders crisp text without Xwayland blur.
- [ ] **KWin Wayland Rules:** Confirm `/etc/xdg/kwinrc` has `AdaptiveSync=Always` and `AllowTearingAtFullscreen=true`.

### 3. Audio & Wayland Screen Sharing
- [ ] **PipeWire Audio Engine:** Verify PipeWire services are running:
  ```bash
  systemctl --user status pipewire wireplumber
  ```
- [ ] **Virtual Meeting Loopback Sink:** Verify the loopback sink exists:
  ```bash
  pactl list sinks short | grep -i loopback
  # Expected: DoomOS_Meeting_Share_Sink
  ```
- [ ] **Portal Verification:** Verify `xdg-desktop-portal-kde` is active for Wayland screen sharing:
  ```bash
  systemctl --user status xdg-desktop-portal-kde
  ```

### 4. NVIDIA Guardian & Hardware Drivers
- [ ] Run the NVIDIA DKMS Guardian verification command:
  ```bash
  doomos-nvidia-verify
  ```
- [ ] Confirm kernel modules exist under `/usr/lib/modules/$(uname -r)/`.

### 5. Developer Tuning & Rootless Containers
- [ ] Verify sysctl values are applied:
  ```bash
  sysctl fs.inotify.max_user_watches
  # Expected: 1048576
  sysctl vm.max_map_count
  # Expected: 2147483642
  ```
- [ ] Confirm `/etc/subuid` and `/etc/subgid` are populated for rootless Podman/Docker.

---

## 💾 Step 3: Installation & Btrfs Subvolume Verification

### 1. Launch Calamares
- Launch **Install DoomOS** from the desktop or application menu.
- Verify branding: Deep slate background with cyan/emerald highlights, product version `DoomOS 1.0.0 Rolling`.

### 2. Disk Partitioning
- Select **Erase Disk** with **Btrfs** (default).
- Verify the installer allocates:
  - EFI System Partition (`/boot/efi`, FAT32).
  - Main Btrfs root filesystem.

### 3. Post-Install Subvolume Confirmation
After installation completes and the system reboots into the installed OS:
- [ ] Open Konsole and inspect Btrfs subvolumes:
  ```bash
  sudo btrfs subvolume list /
  ```
  Expected subvolumes:
  - `@` mounted on `/`
  - `@home` mounted on `/home`
  - `@snapshots` mounted on `/.snapshots`
  - `@var_log` mounted on `/var/log`

### 4. Snapper Auto-Rollback Verification
- [ ] Verify Snapper root configuration:
  ```bash
  sudo snapper -c root list
  ```
- [ ] Test automatic pacman pre/post snapshot:
  ```bash
  sudo pacman -S --noconfirm fastfetch
  sudo snapper -c root list
  # Confirm pre and post snapshot IDs were created by snap-pac
  ```
- [ ] Verify GRUB Btrfs boot integration:
  ```bash
  systemctl status grub-btrfsd
  ```

### 5. Dual-Boot Windows RTC Sync
If installed alongside Windows in a dual-boot setup:
- [ ] Verify local RTC status:
  ```bash
  timedatectl | grep "RTC in local TZ"
  # Expected: RTC in local TZ: yes
  ```

---

## ⚡ Step 4: Bare-Metal USB Flashing

To flash the master ISO to a physical USB thumb drive:

1. Insert a USB flash drive (minimum 8 GB recommended).
2. Run the protected flashing utility:
   ```bash
   ./flash-usb.sh
   ```
3. The script will:
   - Check the ISO's SHA256 checksum integrity.
   - List only external/removable block devices.
   - Block any attempt to write to internal or active system disks.
   - Prompt for explicit `DOOM` typing confirmation.
   - Write using high-speed block size (`4M`) and sync hardware buffers.
4. Plug the USB into your target PC, enter the UEFI boot menu (F11/F12/Del), and select **UEFI: DoomOS**.
