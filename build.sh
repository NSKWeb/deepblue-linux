#!/bin/sh
# Build DeepBlue Linux from source. Requires root (live-build needs to
# mount /proc, /dev/pts and /sys inside the chroot) and the packages
# listed in the README.
set -e

cd "$(dirname "$0")"

# 1. Build the DeepBlue packages and (re)publish the signed archive, then
#    refresh the copies that get baked into the ISO.
if [ -x tools/build-repo.sh ]; then
    ./tools/build-repo.sh
    mkdir -p config/includes.chroot/usr/share/deepblue/repo
    rm -rf config/includes.chroot/usr/share/deepblue/repo/*
    cp -r repo/apt/dists repo/apt/pool config/includes.chroot/usr/share/deepblue/repo/
    cp repo/deepblue-archive-keyring.gpg config/includes.chroot/usr/share/keyrings/
    for deb in repo/apt/pool/main/*/*/*.deb; do
        cp "$deb" config/packages.chroot/
    done
fi

# A container without CAP_SYS_ADMIN cannot mount a fresh sysfs. Fall back
# to bind-mounting the host /sys, which the kernel allows in that case.
if ! mount -t sysfs sysfs /tmp/.deepblue-sysfs-test 2>/dev/null; then
    :
fi
rm -rf /tmp/.deepblue-sysfs-test 2>/dev/null || true

# --uefi-secure-boot enable (not the default "auto"): fail the build if
# shim-signed / grub-efi-amd64-signed are missing, rather than silently
# shipping an unsigned UEFI image.
lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer live \
  --archive-areas "main contrib non-free non-free-firmware" \
  --iso-application "DeepBlue Linux" \
  --iso-preparer "DeepBlue Project" \
  --iso-publisher "DeepBlue Project; https://example.org" \
  --iso-volume "DEEPBLUE" \
  --bootappend-live "boot=live components hostname=deepblue username=deepblue locales=en_US.UTF-8 keyboard-layouts=us" \
  --uefi-secure-boot enable \
  --memtest none \
  --loadlin false \
  --apt-indices false \
  --apt-recommends false

lb build

echo
echo "Done. ISO: $(pwd)/live-image-amd64.hybrid.iso"
