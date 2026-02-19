FROM debian:stable-slim
# Rationale for Debian base vs official Rust image: see README section 
# "Why this is not based on the official Rust Docker image".

# Usage:
# docker build \
#   --build-arg USER_UID=$(id -u) \
#   --build-arg USER_GID=$(id -g) \
#   -t rp2040-rust-dev:latest .
#
# docker run -it --rm \
#   -v "$(pwd)/project":/home/rp2040-rust-dev/project \
#   -w /home/rp2040-rust-dev/project \
#   rp2040-rust-dev:latest

# 1. Install build tools and libraries as root
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    curl \
    wget \
    git \
    procps \
    ca-certificates \
    pkg-config \
    libudev-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup your non-root user
ARG USER_UID
ARG USER_GID
RUN groupadd --gid $USER_GID rp2040-rust-dev && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash rp2040-rust-dev

# 3. Use home directory
WORKDIR /home/rp2040-rust-dev
ENV PATH=/home/rp2040-rust-dev/.cargo/bin:$PATH

# 4. Switch to non-root
USER rp2040-rust-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . ~/.profile \
    && rustup self update \
    && rustup update stable \
    && rustup target add thumbv6m-none-eabi \
    && cargo install --locked elf2uf2-rs


CMD ["bash"]
