#!/usr/bin/env python3
import sys

if len(sys.argv) < 2:
    print("Usage: patch-mkarchiso.py <path_to_mkarchiso>", file=sys.stderr)
    sys.exit(1)

filepath = sys.argv[1]
with open(filepath, 'r') as f:
    content = f.read()

target = '    grub-mkstandalone -O "$grub_target"'
patch = '''    local _filtered_grubmodules=()
    for _m in "${grubmodules[@]}"; do
        if [[ -f "/usr/lib/grub/${grub_target}/${_m}.mod" ]]; then
            _filtered_grubmodules+=("$_m")
        fi
    done
    grubmodules=("${_filtered_grubmodules[@]}")
    grub-mkstandalone -O "$grub_target"'''

if target not in content:
    print(f"ERROR: Could not find target line in {filepath}", file=sys.stderr)
    sys.exit(1)

new_content = content.replace(target, patch, 1)
with open(filepath, 'w') as f:
    f.write(new_content)

print(f"Successfully patched {filepath} for dynamic arm64 grubmodules!")
