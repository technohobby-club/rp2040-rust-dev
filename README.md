# rp2040-rust-dev

Development container for building Rust firmware for the RP2040 Waveshare Zero board.

## Table of Contents

- [Purpose](#purpose)
- [Why Docker is required](#why-docker-is-required)
- [Base image and RP2040 additions](#base-image-and-rp2040-additions)
- [Build the image](#build-the-image)
  - [Windows (PowerShell) equivalent](#windows-powershell-equivalent)
- [Validate image](#validate-image)
- [Run with a bind mount](#run-with-a-bind-mount)
- [Why the volume mount is necessary](#why-the-volume-mount-is-necessary)

## Purpose

This project provides a reproducible development environment for RP2040 firmware work, including embedded target support and `elf2uf2-rs` for generating `.uf2` images used by the board.

## Why Docker is required

Using Docker keeps the toolchain, system libraries, and build dependencies consistent across machines.

- No local Rust/embedded toolchain setup required on host OS.
- Avoids "works on my machine" issues from mismatched package versions.
- Makes onboarding easier: build image, run container, start building firmware.

## Base image and RP2040 additions

This image is based on the official `rust:slim` Docker image and adds the RP2040-specific dependencies needed for embedded development.

- Debian packages: `libudev-dev`, `pkg-config`, `build-essential`, and common CLI tools.
- Embedded target: `thumbv6m-none-eabi`.
- Rust tools: `elf2uf2-rs` and `flip-link`.
- Non-root user with host-matching UID/GID for correct file ownership on bind mounts.

This keeps the image close to upstream Rust while still providing a reproducible RP2040 workflow.

## Build the image

```bash
docker build \
	--build-arg USER_UID=$(id -u) \
	--build-arg USER_GID=$(id -g) \
	-t rp2040-rust-dev:latest .
```

### Windows (PowerShell) equivalent

```powershell
docker build `
	--build-arg USER_UID=1000 `
	--build-arg USER_GID=1000 `
	-t rp2040-rust-dev:latest .
```

Note: Windows commands are provided as reference and have not been tested in this project.

## Validate image

Run this smoke test to verify Rust, the embedded target, and RP2040 helper tools are available:

```bash
docker run --rm rp2040-rust-dev:latest bash -c '
rustc --version &&
rustup target list --installed | grep -q "thumbv6m-none-eabi" &&
elf2uf2-rs --help >/dev/null &&
flip-link --help >/dev/null &&
echo "OK: image is ready for RP2040 builds"
'
```

Notes:

- `flip-link --help` prints a short informational message to stdout; this is expected.
- This check uses `bash -c` (not `bash -lc`) to avoid login-shell `PATH` differences.

## Run with a bind mount

```bash
mkdir -p project && chown "$(id -u)":"$(id -g)" project

docker run -it --rm \
	-v "$(pwd)/project":/home/rp2040-rust-dev/project \
	-w /home/rp2040-rust-dev/project \
	rp2040-rust-dev:latest
```

If `project/` does not exist, Docker can create it as `root:root` on Linux when using `-v`, which causes host-side ownership surprises.

## Why the volume mount is necessary

The bind mount (`-v "$(pwd)/project":/home/rp2040-rust-dev/project`) shares the same project directory between host and container.

- Build outputs produced in the container are written to the host filesystem.
- When `elf2uf2-rs` converts your ELF into a `.uf2` file, that `.uf2` remains available on your host.
- You can then copy/drag-and-drop the `.uf2` to a connected Waveshare Zero board in BOOTSEL mode.

Without the mount, artifacts stay inside the container filesystem and are lost when the container is removed (`--rm`).
