# DoomOS Base Containerized Build Engine
# Standard Arch Linux Base Devel targeting x86_64
FROM --platform=linux/amd64 archlinux:base-devel

LABEL maintainer="DoomOS Engineering Team"
LABEL description="Isolated x86_64 reproducible build environment for DoomOS ISO mastering"

# 1. Disable Pacman seccomp sandbox restriction inside Docker container
RUN sed -i '/\[options\]/a DisableSandbox' /etc/pacman.conf

# 2. Update pacman keyring and install ISO mastering toolchain
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        archiso \
        git \
        squashfs-tools \
        dosfstools \
        libisoburn \
        xorriso \
        grub \
        mtools \
        e2fsprogs \
        zstd \
        util-linux && \
    pacman -Scc --noconfirm

# Set up build workspace
WORKDIR /build

# Default entrypoint executing the master build script
ENTRYPOINT ["/build/build.sh"]
