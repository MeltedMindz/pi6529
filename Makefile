# pi6529: build a flashable Raspberry Pi image that runs the 6529 validator.
#
#   make image      download (and check) the inputs, build dist/pi6529-<version>.img.xz
#   make fetch      only download and check the inputs into .cache/
#   make check      re-run the checks on the image in dist/
#   make lint       syntax-check every shell script
#   make clean      remove dist/ (keeps the downloads in .cache/)
#
# Needs Docker (Docker Desktop, Colima or a Linux host). On an Apple silicon
# Mac or an ARM64 Linux host the build runs natively; on x86-64 Linux it needs
# qemu-user-static with binfmt (see docs/BUILDING.md).

VERSION := $(shell cat VERSION)
CACHE   ?= $(CURDIR)/.cache
DIST    ?= $(CURDIR)/dist

.PHONY: image fetch check lint clean imager-entry

image: lint
	CACHE="$(CACHE)" DIST="$(DIST)" ./build/build-image.sh

fetch:
	CACHE="$(CACHE)" ./build/fetch.sh

check:
	CACHE="$(CACHE)" DIST="$(DIST)" ./build/build-image.sh --check-only

imager-entry:
	DIST="$(DIST)" ./build/imager-entry.sh > imager/os_list.json && cat imager/os_list.json

lint:
	@for f in build/*.sh build/inside/*.sh image/rootfs/usr/local/sbin/* image/rootfs/usr/local/lib/pi6529/* image/rootfs/etc/profile.d/*.sh; do \
	  bash -n "$$f" || exit 1; \
	done; echo "lint: ok"

clean:
	rm -rf "$(DIST)"
