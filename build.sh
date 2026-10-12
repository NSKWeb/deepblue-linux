#!/bin/sh
# Build DeepBlue Linux from source. Requires root (live-build needs to
# mount /proc, /dev/pts and /sys inside the chroot) and the packages
# listed in the README.
set -e

cd "$(dirname "$0")"

# A container without CAP_SYS_ADMIN cannot mount a fresh sysfs. Fall back
# to bind-mounting the host /sys, which the kernel allows in that case.
if ! mount -t sysfs sysfs /tmp/.deepblue-sysfs-test 2>/dev/null; then
    :
fi
rm -rf /tmp/.deepblue-sysfs-test 2>/dev/null || true

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
  --memtest none \
  --apt-indices false \
  --apt-recommends false

lb build

echo
echo "Done. ISO: $(pwd)/live-image-amd64.hybrid.iso"
