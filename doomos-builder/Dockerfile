# DoomOS Base Containerized Build Engine
# Standard Arch Linux ARM targeting aarch64 (ARM64)
FROM --platform=linux/arm64 menci/archlinuxarm:base-devel

LABEL maintainer="DoomOS Engineering Team"
LABEL description="Isolated aarch64 reproducible build environment for DoomOS ISO mastering"

# 1. Disable Pacman seccomp sandbox and signature checks inside container build
RUN sed -i '/\[options\]/a DisableSandbox\nSigLevel = Never' /etc/pacman.conf

# 2. Update pacman and install ISO mastering toolchain
RUN pacman -Syu --noconfirm --noprogressbar && \
    pacman -S --noconfirm --needed --noprogressbar \
        git \
        make \
        squashfs-tools \
        dosfstools \
        libisoburn \
        xorriso \
        grub \
        mtools \
        e2fsprogs \
        zstd \
        util-linux && \
    git clone --depth=1 https://gitlab.archlinux.org/archlinux/archiso.git /tmp/archiso && \
    cd /tmp/archiso && make install && cd / && rm -rf /tmp/archiso && \
    pacman -Scc --noconfirm

# Set up build workspace
WORKDIR /build

# Default entrypoint executing the master build script
ENTRYPOINT ["/build/build.sh"]
