#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# DoomOS Windows Dual-Boot RTC Synchronizer
# Eliminates clock drift by aligning Linux RTC to LocalTime if Windows is detected
# ==============================================================================

import os
import subprocess

try:
    import libcalamares
except ImportError:
    libcalamares = None


def run():
    """
    Scans the installed EFI partition for Windows Boot Manager.
    If detected, configures RTC to LocalTime to avoid time jumps.
    """
    if libcalamares:
        root_mount = libcalamares.target_env.target_path
    else:
        root_mount = "/"

    candidate_paths = [
        os.path.join(root_mount, "boot/efi/EFI/Microsoft/Boot/bootmgfw.efi"),
        os.path.join(root_mount, "boot/EFI/Microsoft/Boot/bootmgfw.efi"),
        os.path.join(root_mount, "efi/EFI/Microsoft/Boot/bootmgfw.efi"),
    ]

    windows_found = False
    for path in candidate_paths:
        if os.path.exists(path):
            windows_found = True
            break

    if windows_found:
        if libcalamares:
            libcalamares.utils.debug("DoomOS: Microsoft Windows EFI detected. Setting Local RTC.")
            try:
                libcalamares.target_env.check_call(
                    ["timedatectl", "set-local-rtc", "1", "--adjust-system-clock"]
                )
            except Exception as e:
                libcalamares.utils.warning(f"DoomOS: Failed to set Local RTC: {e}")
        else:
            print("Standalone check: Windows detected. RTC adjustment command would run.")
    else:
        if libcalamares:
            libcalamares.utils.debug("DoomOS: No Windows EFI loader detected. Maintaining UTC RTC.")
        else:
            print("Standalone check: No Windows EFI found. Maintaining UTC.")

    return None
