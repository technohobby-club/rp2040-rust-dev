.PHONY: build build-no-cache validate run clean

IMAGE_NAME = rp2040-rust-dev:latest
USER_UID = $(shell id -u)
USER_GID = $(shell id -g)
PROJECT_DIR = $(shell pwd)/project

build:
	docker build \
		--build-arg USER_UID=$(USER_UID) \
		--build-arg USER_GID=$(USER_GID) \
		-t $(IMAGE_NAME) .

build-no-cache:
	docker build --no-cache \
		--build-arg USER_UID=$(USER_UID) \
		--build-arg USER_GID=$(USER_GID) \
		-t $(IMAGE_NAME) .

validate:
	docker run --rm $(IMAGE_NAME) bash -c '\
		rustc --version && \
		rustup target list --installed | grep -q "thumbv6m-none-eabi" && \
		elf2uf2-rs --help >/dev/null && \
		flip-link --help >/dev/null && \
		echo "OK: image is ready for RP2040 builds"'

run:
	mkdir -p $(PROJECT_DIR)
	chown "$(USER_UID):$(USER_GID)" $(PROJECT_DIR)
	docker run -it --rm \
		-v "$(PROJECT_DIR):/home/rp2040-rust-dev/project" \
		-w /home/rp2040-rust-dev/project \
		$(IMAGE_NAME)

clean:
	docker rmi $(IMAGE_NAME)
