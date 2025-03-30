FROM ubuntu:22.04 AS build_qemu

ARG QEMU_VERSION=8.2.5

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git build-essential gdb-multiarch qemu-system-misc \
    gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu curl autoconf automake autotools-dev curl \
    libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc \
    zlib1g-dev libexpat-dev pkg-config libglib2.0-dev libpixman-1-dev libsdl2-dev libslirp-dev tmux python3 \
    python3-pip ninja-build wget python3-venv python3-dev libclang-dev python3-pexpect bash-completion \
    qemu-utils qemu-system-arm qemu-efi-aarch64 ipxe-qemu cmake libcapstone-dev

RUN wget https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz && \
    tar xf qemu-${QEMU_VERSION}.tar.xz && \
    cd qemu-${QEMU_VERSION} && \ 
    ./configure --target-list=riscv64-softmmu,riscv64-linux-user --enable-capstone && \
    make -j$(nproc) && \
    make install

RUN rm -rf qemu-${QEMU_VERSION} && \
    tar xf qemu-${QEMU_VERSION}.tar.xz && \
    cd qemu-${QEMU_VERSION} && \ 
    ./configure --target-list=aarch64-softmmu,aarch64-linux-user --enable-capstone && \
    make -j$(nproc) && \
    make install

FROM ubuntu:22.04 AS rel4_dev

COPY --from=build_qemu /usr/local/bin/* /usr/local/bin

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential cmake ccache ninja-build \
    cmake-curses-gui libxml2-utils ncurses-dev curl git doxygen device-tree-compiler u-boot-tools \
    python3-dev python3-pip python-is-python3 protobuf-compiler python3-protobuf \
    gcc-arm-linux-gnueabi g++-arm-linux-gnueabi gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu repo gdb-multiarch libglib2.0-dev zlib1g-dev \
    libpixman-1-dev cpio g++ python3-libarchive-c sudo git build-essential gdb-multiarch \
    qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu curl autoconf automake \
    autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc zlib1g-dev libexpat-dev pkg-config libglib2.0-dev libpixman-1-dev \
    libsdl2-dev libslirp-dev tmux python3 python3-pip ninja-build wget libcapstone-dev

RUN pip install setuptools sel4-deps aenum pyelftools grpcio_tools pygments capstone lief

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/usr/local/bin/riscv/bin:$PATH \
    RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static \
    RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup \
    REL4_PREFIX=/workspace/.seL4 \
    SEL4_PREFIX=/workspace/.seL4

RUN curl -L -O https://github.com/yfblock/rel4-docker/releases/download/toolchain/riscv.tar.gz && \
    tar xzvf riscv.tar.gz -C /usr/local/bin && \
    rm riscv.tar.gz

COPY docker_start_user.sh /usr/local/bin

COPY --from=build_qemu /usr/local/share/qemu/* /usr/local/share/qemu/

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --no-modify-path \
    --default-toolchain nightly-2024-08-01 \
    --component rust-src \
    --component cargo \
    --component clippy \
    --component rust-docs \
    --component rust-std \
    --component rustc \
    --component rustfmt \
    --target aarch64-unknown-none-softfloat \
    --target aarch64-unknown-none \
    --target riscv64imac-unknown-none-elf

RUN rustup install nightly-2024-02-01 && \
    rustup target add aarch64-unknown-none-softfloat --toolchain nightly-2024-02-01 && \
    rustup target add aarch64-unknown-none --toolchain nightly-2024-02-01 && \
    rustup target add riscv64imac-unknown-none-elf --toolchain nightly-2024-02-01

RUN curl -L -O https://musl.cc/aarch64-linux-musl-cross.tgz && \
    tar xzvf aarch64-linux-musl-cross.tgz -C /opt && \
    rm aarch64-linux-musl-cross.tgz

ENV PATH=/opt/aarch64-linux-musl-cross/bin:/workspace/.seL4/bin:$PATH

RUN apt -y install gcc-riscv64-unknown-elf

RUN cargo install --force --git https://github.com/reL4team2/reL4-cli.git
