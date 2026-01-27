FROM cachyos/cachyos:latest

# Update system and install dependencies
# We combine everything into a single RUN to reduce layers
RUN pacman -Sy --noconfirm archlinux-keyring cachyos-keyring && \
    pacman -Su --noconfirm && \
    pacman -S --noconfirm --needed \
        base-devel \
        clang \
        gcc \
        cmake \
        ninja \
        git \
        python \
        python-pip \
        wget \
        curl \
        zip \
        unzip \
        tar && \
    # Clean up pacman cache to reduce image size
    pacman -Scc --noconfirm && \
    # Remove EXTERNALLY-MANAGED to allow pip usage if needed (optional but helpful)
    rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED

# Install Vcpkg
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    /opt/vcpkg/bootstrap-vcpkg.sh && \
    # Clean up to reduce image size
    rm -rf /opt/vcpkg/downloads/* && \
    rm -rf /opt/vcpkg/buildtrees/* && \
    rm -rf /opt/vcpkg/packages/*

# Environment variables
ENV VCPKG_ROOT=/opt/vcpkg
ENV PATH=$VCPKG_ROOT:$PATH
ENV VCPKG_FORCE_SYSTEM_BINARIES=1
