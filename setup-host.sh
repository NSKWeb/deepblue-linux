#!/bin/sh
# Prepare a Debian (or Debian-derived) host to build DeepBlue Linux.
# Safe to re-run: installs the toolchain and applies the container
# workaround for live-build's sysfs mount.
set -e

PKGS="live-build xorriso squashfs-tools debootstrap \
isolinux syslinux-common syslinux-efi grub-pc-bin grub-efi-amd64-bin \
grub-common mtools dosfstools imagemagick qemu-system-x86 expect"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root (or with sudo): sudo $0" >&2
    exit 1
fi

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PKGS

# Containers without CAP_SYS_ADMIN cannot mount a fresh sysfs inside the
# chroot. Bind-mounting the host /sys is permitted there.
SYSFS=/usr/lib/live/build/chroot_sysfs
if [ -f "$SYSFS" ] && grep -q 'mount -t sysfs -o x-gvfs-hide sysfs-live chroot/sys' "$SYSFS"; then
    cp "$SYSFS" "$SYSFS.orig"
    sed -i 's#mount -t sysfs -o x-gvfs-hide sysfs-live chroot/sys#mount --bind /sys chroot/sys#' "$SYSFS"
    echo "Patched $SYSFS for container builds"
fi

echo "Host ready. Next: sudo ./build.sh"
