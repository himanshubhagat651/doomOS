# DoomOS Base Containerized Build Engine
# Standard Arch Linux ARM targeting aarch64 (ARM64)
ARG TARGETPLATFORM=linux/arm64
FROM --platform=$TARGETPLATFORM menci/archlinuxarm:base-devel

LABEL maintainer="DoomOS Engineering Team"
LABEL description="Isolated aarch64 reproducible build environment for DoomOS ISO mastering"

# 1. Disable Pacman seccomp sandbox and signature checks inside container build
RUN sed -i '/\[options\]/a DisableSandbox\nSigLevel = Never' /etc/pacman.conf

COPY patch-mkarchiso.py /tmp/patch-mkarchiso.py

# 2. Update pacman and install ISO mastering toolchain
RUN pacman -Syu --noconfirm --noprogressbar && \
    pacman -S --noconfirm --needed --noprogressbar \
        git \
        make \
        python \
        python-docutils \
        arch-install-scripts \
        squashfs-tools \
        dosfstools \
        libisoburn \
        xorriso \
        grub \
        mtools \
        e2fsprogs \
        zstd \
        util-linux && \
    mkdir -p /usr/share/grub && touch /usr/share/grub/sbat.csv && \
    git clone --depth=1 https://gitlab.archlinux.org/archlinux/archiso.git /tmp/archiso && \
    python3 /tmp/patch-mkarchiso.py /tmp/archiso/archiso/mkarchiso && \
    cd /tmp/archiso && make install PREFIX=/usr && cd / && rm -rf /tmp/archiso /tmp/patch-mkarchiso.py && \
    pacman -Scc --noconfirm

# Set up build workspace
WORKDIR /build

# Default entrypoint executing the master build script
ENTRYPOINT ["/build/build.sh"]
