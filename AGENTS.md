# AGENTS.md

## Project
DeepBlue Linux — a Deepin-inspired Debian live distribution, built with
Debian's `live-build`. Source of truth lives in `config/`; `build.sh`
regenerates the ISO.

## Build
- Host: Debian (or derived), root required, ~60 GB free disk, internet.
- `sudo ./setup-host.sh` installs the toolchain and applies the container
  workaround; `sudo ./build.sh` configures and builds.
- `sudo ./build.sh` → produces `live-image-amd64.hybrid.iso` (~2.1 GB).
- Base: Debian `trixie`, amd64, hybrid BIOS+UEFI.
- Desktop: LXQt + LightDM. Live user `deepblue` / password `live`.
- Installer: Debian installer enabled (`--debian-installer live`). Adds
  `/install/` (vmlinuz, initrd.gz, gtk/) and `/dists/` udebs to the ISO, plus
  "Start installer" boot entries for BIOS and UEFI.

## Container gotcha (important)
`live-build` mounts a fresh `sysfs` into the chroot. Containers without
`CAP_SYS_ADMIN` (most Docker/CI sandboxes) reject that mount even as root,
failing with `mount: .../chroot/sys: permission denied`. `proc` and `devpts`
mounts are fine.

Fix that works in such sandboxes: bind-mount the host `/sys` instead. Patch
`/usr/lib/live/build/chroot_sysfs` (back it up first) replacing:

    mount -t sysfs -o x-gvfs-hide sysfs-live chroot/sys

with:

    mount --bind /sys chroot/sys

`build.sh` documents this; it does not auto-patch the system script.

## Verification
Boot the ISO under QEMU (no KVM in this sandbox, so TCG — slow). Working recipe:

    qemu-system-x86_64 -m 2048 -smp 2 -nographic -no-reboot \
      -cdrom live-image-amd64.hybrid.iso \
      -kernel <extracted vmlinuz> -initrd <extracted initrd.img> \
      -append "boot=live components hostname=deepblue username=deepblue console=ttyS0,115200"

The live user password is `live` (live-config default). Evidence logs live in
`docs/`.

## Conventions
- ISO and live-build work dirs are gitignored; never commit the ISO.
- Keep branding placeholders (`example.org`) until real URLs exist.
- Any content posted to external services must note it was AI-generated.

## Auto-login
`config/hooks/live/0100-deepblue-branding.hook.chroot` sets
`autologin-user=deepblue` in `/etc/lightdm/lightdm.conf.d/60-deepblue.conf`.
Debian's `lightdm-autologin` PAM stack uses `pam_permit.so`, so no
`nopasswdlogin` group is needed. Verified: boots straight into LXQt.

## live-build rebuild gotchas
- `lb build` silently reuses cached stage files in `.build/` and will NOT pick
  up hook changes if stages look current. To force hooks to re-run, remove the
  relevant stages (`sudo rm -rf .build/chroot_hooks .build/binary_*`) or run
  `lb clean` — but keep `cache/` to stay fast.
- Do NOT delete `.build/config`: `lb build` then fails with
  `the following stage is required to be done first: config`. Re-run `lb config`
  (exactly as in `build.sh`) if you do.

## Packages and signed archive (ownership)
The distribution identity ships as real Debian packages, not loose files:

- `pkg/deepblue-base` — owns `/etc/os-release`, `/etc/lsb-release`,
  `/etc/issue`, `/etc/issue.net`, `/etc/deepblue/release`. It **diverts**
  the copies from `base-files`/`lsb-release` so an upgrade of those packages
  cannot overwrite the branding (verified: reinstalling `base-files` leaves
  the DeepBlue `os-release` intact).
- `pkg/deepblue-archive-keyring` — the public key for the DeepBlue archive.

`tools/build-repo.sh` builds each `pkg/*` with `dpkg-deb` and publishes it
into the reprepro archive under `repo/apt` (release "cobalt"), signing the
indices with the key in `repo/gnupg` (gitignored — **never commit it**).
`build.sh` runs it automatically and copies the archive into
`config/includes.chroot/usr/share/deepblue/repo` so the ISO ships its own repo.

### dpkg-divert gotcha (important)
`base-files` ships `/etc/os-release`, so an unconditional `dpkg-divert
--package <pkg> ... --rename` **fails at unpack time** with
`trying to overwrite '/etc/os-release'`. Two things fix it:

1. Use `--no-rename` — we do not want the file moved aside, we replace its
   contents.
2. debootstrap leaves a *local* diversion on `/etc/os-release`
   (`→ /etc/os-release.debootstrap`) which clashes with ours. The `preinst`
   must drop it first, and **must pass `--local`**:
   `dpkg-divert --local --remove --no-rename /etc/os-release`.
   Without `--local`, dpkg (with `DPKG_MAINTSCRIPT_PACKAGE` set) scopes the
   removal to the package and errors `mismatch on package`.

The `prerm` must mirror the `preinst` exactly (`--package <pkg> --divert
<f>.deepblue --no-rename --remove`).

### Build environment gotcha (setgid)
The workspace is an ext4 **idmapped** mount where new directories inherit the
parent setgid bit, giving `DEBIAN/` mode `2755` and `dpkg-deb` fails with
`control directory has bad permissions 2755`. `tools/build-repo.sh` runs
`chmod g-s` on every `DEBIAN/` before building.


### live-build stage markers (rebuild gotcha)
`lb build` skips any stage whose marker exists in `.build/`. When you change a
hook, package list, or anything that affects the *binary* or *installer*
stages, the marker must be cleared or the change silently never lands in the
ISO. This bit us twice: a rebuild kept the **old ISO** (missing the debian
installer payload) because `.build/installer_debian-installer` and
`.build/installer_preseed` were stale.

To force a full binary+installer rebuild:

    sudo rm -rf binary binary.modified_timestamps chroot/binary chroot/binary.sh
    sudo rm -f .build/binary_* .build/installer_*
    lb build

Then verify the payload actually made it in:

    xorriso -indev live-image-amd64.hybrid.iso -find /install/gtk/vmlinuz   # want 1
    xorriso -indev live-image-amd64.hybrid.iso -find /dists                # want ~30
    xorriso -indev live-image-amd64.hybrid.iso -find /pool-udeb            # want ~490

### Release size limit (GitHub 2 GB)
GitHub release assets must be **< 2 GiB per file**. A full Debian live ISO with
firmware + the debian installer lands around 2.05 GiB, over the limit. The
branding hook trims to fit: drop unused Bibata cursor variants, non-`en` locale
catalogs, and the `netronome` NIC firmware. Keep the ISO under 2 GiB when
adding packages.

### Verifying the desktop headlessly
Boot the ISO under QEMU with a VGA adapter and a monitor socket, then take a
screenshot without any GUI on the host:

    qemu-system-x86_64 -m 2048 -smp 2 -vga std -display none \
      -monitor unix:/tmp/qmon,server,nowait \
      -cdrom live-image-amd64.hybrid.iso -kernel /tmp/boot/vmlinuz \
      -initrd /tmp/boot/initrd.img \
      -append "boot=live components hostname=deepblue username=deepblue console=ttyS0,115200"

Then, from Python, connect to `/tmp/qmon` and send `screendump /tmp/desktop.ppm`.
Serial console (login `deepblue` / `live`) is enough to check config files and
that `plank`/`picom` are running; the screendump confirms the actual look.

