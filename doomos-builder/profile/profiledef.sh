#!/usr/bin/env bash
# ==============================================================================
# DoomOS Archiso Profile Definition (profiledef.sh)
# Defines ISO metadata, compression algorithms, boot modes, and file permissions
# ==============================================================================

iso_name="doomos-plasma"
iso_label="DOOMOS_LIVE"
iso_publisher="DoomOS Systems Project <https://doomos.org>"
iso_application="DoomOS Live / Rescue / Install Media"
iso_version="1.0.0"
install_dir="doomos"
build_modes=('iso')
bootmodes=('bios.syslinux'
           'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--ultra' '-19')

# File permissions for custom scripts and system binaries
file_permissions=(
  ["/usr/bin/doomos-nvidia-verify"]="0:0:755"
  ["/usr/bin/doom-game"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
)
