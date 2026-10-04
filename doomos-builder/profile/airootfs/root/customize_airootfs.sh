#!/usr/bin/env bash
# ==============================================================================
# DoomOS airootfs Customization Script
# Executed by mkarchiso inside the chroot environment after pacstrap
# ==============================================================================

set -euo pipefail

echo "==> [DoomOS Customize] Initializing live filesystem configurations..."

# 1. Apply Calamares Configurations & Custom Branding
if [[ -d "/root/calamares-overlay/etc/calamares" ]]; then
    echo "==> [DoomOS Customize] Deploying Calamares installer configuration and branding..."
    mkdir -p /etc/calamares/modules /etc/calamares/branding
    cp -rf /root/calamares-overlay/etc/calamares/* /etc/calamares/
    rm -rf /root/calamares-overlay
fi

# 2. Permissions on Executables
echo "==> [DoomOS Customize] Setting execution bits on DoomOS tools and hooks..."
chmod -f +x /usr/bin/doom-game || true
chmod -f +x /usr/bin/doomos-nvidia-verify || true
chmod -f +x /usr/bin/doomos-hardware-detect || true
chmod -f +x /usr/bin/doomos-hardware-center || true
if [[ -f "/etc/calamares/modules/doomos-rtc/main.py" ]]; then
    chmod +x /etc/calamares/modules/doomos-rtc/main.py
fi

# 3. Create Live User & Configure Passwordless Sudo
echo "==> [DoomOS Customize] Setting up default 'liveuser' for SDDM autologin..."
if ! id "liveuser" >/dev/null 2>&1; then
    useradd -m -u 1000 -G wheel,audio,video,storage,optical,network,power -s /bin/bash liveuser
    passwd -d liveuser
fi

# Configure sudoers
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-wheel
echo "liveuser ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/20-liveuser
chmod 0440 /etc/sudoers.d/*

# 4. Configure Locales & Timezone
echo "==> [DoomOS Customize] Generating UTF-8 locales..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen || true
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen || true
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 5. Enable System Services
echo "==> [DoomOS Customize] Enabling core systemd services..."
systemctl enable sddm.service || true
systemctl enable NetworkManager.service || true
systemctl enable bluetooth.service || true
systemctl enable power-profiles-daemon.service || true
systemctl enable grub-btrfsd.service || true
systemctl enable vmtoolsd.service || true
systemctl enable vmware-vmblock-fuse.service || true
mkdir -p /mnt/hgfs
systemctl enable mnt-hgfs.mount || true
systemctl enable doomos-flathub-setup.service || true

# Configure Flathub as the default app repository
echo "==> [DoomOS Customize] Initializing Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# Pre-configure Flatpak Firefox sandbox environment to prevent Wayland VM crash
flatpak override --system --env=MOZ_ENABLE_WAYLAND=0 org.mozilla.firefox 2>/dev/null || true

# Ensure GUI browser and installer wrappers have executable permissions
if [[ -f /usr/bin/doomos-firefox ]]; then
    chmod +x /usr/bin/doomos-firefox
fi
if [[ -f /usr/local/bin/firefox ]]; then
    chmod +x /usr/local/bin/firefox
fi
if [[ -f /usr/bin/doomos-installer-engine ]]; then
    chmod +x /usr/bin/doomos-installer-engine
fi
if [[ -f /usr/bin/doomos-installer ]]; then
    chmod +x /usr/bin/doomos-installer
fi

# Ensure liveuser Desktop has the Install DoomOS shortcut pre-populated
mkdir -p /home/liveuser/Desktop
if [[ -f /etc/skel/Desktop/doomos-installer.desktop ]]; then
    cp -a /etc/skel/Desktop/doomos-installer.desktop /home/liveuser/Desktop/
    chown -R 1000:1000 /home/liveuser/Desktop
    chmod +x /home/liveuser/Desktop/doomos-installer.desktop
fi

# Point system-installed Firefox desktop entry to DoomOS smart launcher
if [[ -f /usr/share/applications/firefox.desktop ]]; then
    sed -i 's|^Exec=/usr/bin/firefox|Exec=/usr/bin/doomos-firefox|g' /usr/share/applications/firefox.desktop
    sed -i 's|^Exec=firefox|Exec=/usr/bin/doomos-firefox|g' /usr/share/applications/firefox.desktop
fi

# 6. Fallback symlink for Calamares installer compatibility
mkdir -p /run/archiso/bootmnt/arch/aarch64 /run/archiso/bootmnt/arch/x86_64
ln -sf /run/archiso/bootmnt/doomos/aarch64/airootfs.sfs /run/archiso/bootmnt/arch/aarch64/airootfs.sfs 2>/dev/null || true
ln -sf /run/archiso/bootmnt/doomos/x86_64/airootfs.sfs /run/archiso/bootmnt/arch/x86_64/airootfs.sfs 2>/dev/null || true

# 7. Normalize ARM64 kernel & initramfs names for mkarchiso ISO mastering
echo "==> [DoomOS Customize] Regenerating live initramfs with archiso hooks..."
mkinitcpio -P || true
if [[ -f /boot/Image ]]; then
    cp -a /boot/Image /boot/vmlinuz-linux-aarch64
    cp -a /boot/Image /boot/vmlinuz-linux
fi
if [[ -f /boot/Image.gz ]]; then
    cp -a /boot/Image.gz /boot/vmlinuz-linux-aarch64.gz
fi
if [[ -f /boot/initramfs-linux.img && ! -f /boot/initramfs-linux-aarch64.img ]]; then
    cp -a /boot/initramfs-linux.img /boot/initramfs-linux-aarch64.img
fi
if [[ -f /boot/initramfs-linux-aarch64.img && ! -f /boot/initramfs-linux.img ]]; then
    cp -a /boot/initramfs-linux-aarch64.img /boot/initramfs-linux.img
fi
ls -la /boot/

# 8. Clean pacman cache inside rootfs to minimize ISO squashfs footprint
echo "==> [DoomOS Customize] Cleaning chroot pacman cache..."
pacman -Scc --noconfirm || true

echo "==> [DoomOS Customize] Customization completed successfully."
