# rp2040-rust-dev

Development container for building Rust firmware for the RP2040 Waveshare Zero board.

## Table of Contents

- [Purpose](#purpose)
- [Why Docker is required](#why-docker-is-required)
- [Why this is not based on the official Rust Docker image](#why-this-is-not-based-on-the-official-rust-docker-image)
- [Build the image](#build-the-image)
  - [Windows (PowerShell) equivalent](#windows-powershell-equivalent)
- [Run with a bind mount](#run-with-a-bind-mount)
- [Why the volume mount is necessary](#why-the-volume-mount-is-necessary)

## Purpose

This project provides a reproducible development environment for RP2040 firmware work, including Rust toolchain setup and `elf2uf2-rs` for generating `.uf2` images used by the board.

## Why Docker is required

Using Docker keeps the toolchain, system libraries, and build dependencies consistent across machines.

- No local Rust/embedded toolchain setup required on host OS.
- Avoids "works on my machine" issues from mismatched package versions.
- Makes onboarding easier: build image, run container, start building firmware.

## Why this is not based on the official Rust Docker image

This image is intentionally built from `debian:stable-slim` so we fully control the base OS packages needed for embedded RP2040 development.

- The environment needs Debian packages such as `libudev-dev`, `pkg-config`, and build tools in known versions.
- We create a non-root user with host-matching UID/GID for correct file ownership on bind mounts.
- Rust is installed via `rustup` in-container, so the Rust toolchain version and targets (`thumbv6m-none-eabi`) are explicit in this repo.

An official Rust base image can work, but this project prioritizes explicit, reproducible setup tailored to this RP2040 workflow.

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

## Run with a bind mount

```bash
docker run -it --rm \
	-v "$(pwd)/project":/home/rp2040-rust-dev/project \
	-w /home/rp2040-rust-dev/project \
	rp2040-rust-dev:latest
```

## Why the volume mount is necessary

The bind mount (`-v "$(pwd)/project":/home/rp2040-rust-dev/project`) shares the same project directory between host and container.

- Build outputs produced in the container are written to the host filesystem.
- When `elf2uf2-rs` converts your ELF into a `.uf2` file, that `.uf2` remains available on your host.
- You can then copy/drag-and-drop the `.uf2` to a connected Waveshare Zero board in BOOTSEL mode.

Without the mount, artifacts stay inside the container filesystem and are lost when the container is removed (`--rm`).
