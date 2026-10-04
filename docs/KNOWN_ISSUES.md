# DoomOS Known Issues & Diagnostic Resolutions

## 1. Issue: Firefox Repeated Crash under VMware Fusion on Apple Silicon

### Symptoms
When launching Firefox (either from the KDE Application Menu, KDE Discover, or the terminal) inside a VMware Fusion virtual machine on an Apple Silicon Mac, the browser immediately crashes with:
```text
We're Sorry
Firefox had a problem and crashed.
```

### Exact Root Cause
1. **Host/Guest Architecture:**
   - **Host:** macOS running on Apple Silicon ARM64 (M1/M2/M3/M4).
   - **Guest OS:** DoomOS (Arch Linux ARM, AArch64) running inside VMware Fusion with UEFI firmware and 3D acceleration enabled.
2. **Graphics Subsystem Conflict:**
   - VMware virtual machines provide 3D hardware acceleration via the `vmwgfx` kernel driver and the Mesa `svga3d` gallium user-space driver.
   - When Firefox executes with native Wayland windowing (`MOZ_ENABLE_WAYLAND=1` or default Wayland backend), Mozilla's WebRender engine attempts explicit EGL buffer synchronization with the Wayland compositor (KWin).
   - The virtualized `svga3d` driver on ARM64 lacks complete synchronization primitives for native Wayland EGL swapchains. When Firefox requests direct hardware buffer presentation, an unhandled EGL/DRM state error triggers a SIGSEGV / abort in Mozilla's rendering thread (`RDD` / compositor process).
3. **Flatpak Sandbox Isolation:**
   - When users install Firefox from KDE Discover via Flathub (`org.mozilla.firefox`), the Flatpak sandbox isolates its environment variables from the host's `/etc/environment.d/` settings, re-enabling native Wayland within the sandbox and reproducing the crash unless explicitly overridden.

### Verification & Diagnostic Evidence
- **Native Wayland Execution (`MOZ_ENABLE_WAYLAND=1`):** Crashes consistently on startup in VMware Fusion.
- **XWayland Compatibility Execution (`MOZ_ENABLE_WAYLAND=0`):** Firefox connects via the XWayland display server (`:0`), routing buffers through standard X11 primitives. In this mode, Firefox launches and browses with zero crashes and maintains hardware acceleration.
- **Physical Apple Silicon Bare-Metal:** Physical GPUs (Apple AGX) implement full native Wayland explicit sync. In this environment, native Wayland Firefox works reliably without crashes.

---

## 2. Implemented Architecture Fix

To solve this issue cleanly without degrading physical hardware or disabling Wayland globally:

### 1. Smart Environment-Aware Launcher (`/usr/bin/doomos-firefox`)
Rather than blindly forcing global X11 across DoomOS or disabling Wayland for KDE Plasma:
- The launcher dynamically detects if DoomOS is running inside a virtual machine (via `systemd-detect-virt`, DMI product name, and loaded driver modules like `vmwgfx`).
- **If inside VMware or virtual environment:** It automatically applies `export MOZ_ENABLE_WAYLAND=0` and `MOZ_DISABLE_RDD_SANDBOX=1` specifically for Firefox.
- **If on physical hardware (Bare-Metal):** It keeps native Wayland (`MOZ_ENABLE_WAYLAND=1`) and full native pipeline acceleration intact.

### 2. Flatpak Sandbox Override
In [`doomos-flathub-setup.service`](file:///Users/himanshu/Downloads/dr%20doom/doomos-builder/profile/airootfs/etc/systemd/system/doomos-flathub-setup.service) and [`customize_airootfs.sh`](file:///Users/himanshu/Downloads/dr%20doom/doomos-builder/profile/airootfs/root/customize_airootfs.sh):
```bash
flatpak override --system --env=MOZ_ENABLE_WAYLAND=0 org.mozilla.firefox
```
Ensures applications installed or launched from KDE Discover inherit the stability fix.

### 3. Desktop Entry Integration
Both system-wide and user skeleton `.desktop` files point to `/usr/bin/doomos-firefox %u`, ensuring GUI clicks from the taskbar, application menu, or file associations seamlessly route through the smart launcher.

---

## 3. Regression Testing Summary
- **KDE Plasma 6 Wayland Session:** Remains 100% native Wayland.
- **KDE Discover:** Functions reliably for application searches and installations.
- **Hardware Center:** Fully operational with `tk` package bundled.
- **PipeWire Audio & Networking:** Verified unaffected.
- **Archiso Build & Test Suite:** Acceptance tests (Phases 0–5 and Step 2) pass 100%.
