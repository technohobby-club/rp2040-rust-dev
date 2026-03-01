FROM rust:slim

# Usage:
# docker build \
#   --build-arg USER_UID=$(id -u) \
#   --build-arg USER_GID=$(id -g) \
#   -t rp2040-rust-dev:latest .
#
# mkdir -p project && chown "$(id -u)":"$(id -g)" project
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

# 2. Install embedded Rust target and tooling expected by this project
RUN rustup target add thumbv6m-none-eabi \
    && cargo install --locked elf2uf2-rs flip-link

# Make Rust tools available in login shells (bash -l / bash -lc)
RUN printf '%s\n' 'export PATH="/usr/local/cargo/bin:$PATH"' > /etc/profile.d/rust-path.sh

# 3. Setup your non-root user
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID rp2040-rust-dev && \
    useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash rp2040-rust-dev

# 4. Use home directory
WORKDIR /home/rp2040-rust-dev
ENV PATH=/usr/local/cargo/bin:/home/rp2040-rust-dev/.cargo/bin:$PATH

# 5. Switch to non-root
USER rp2040-rust-dev

CMD ["bash"]
