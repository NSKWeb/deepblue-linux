# DeepBlue Linux

A Deepin-inspired Debian live distribution, built with Debian's
[`live-build`](https://wiki.debian.org/DebianLive) framework.

DeepBlue is a *rebrand* of the Debian live system rather than a from-scratch
distribution: it takes a Debian `trixie` base and layers on its own identity,
default packages and desktop experience. Deepin itself is built the same way
(Debian base + its own desktop environment), so this is the same approach taken
to a smaller, reproducible scale.

## What you get

- **Base:** Debian GNU/Linux 13 (trixie), `amd64`
- **Desktop:** LXQt (a Qt-based desktop, closest stock Debian equivalent to
  Deepin's DDE feel)
- **Display manager:** LightDM
- **Boot:** hybrid ISO — boots on both BIOS and UEFI machines
- **Live user:** `deepblue` (password `live`, member of `sudo`)
- **Branding:** custom `/etc/os-release`, `/etc/lsb-release`, TTY banner,
  wallpaper, logo, boot splash and a live-session welcome message

## ISO

| Property        | Value                                  |
| --------------- | -------------------------------------- |
| Volume label    | `DEEPBLUE`                             |
| Size            | ~1.4 GB                                |
| Boot records    | El Torito BIOS (`isolinux`) + UEFI (`grub`) |
| Live user       | `deepblue` / `live`                    |
| Hostname        | `deepblue`                             |

The built ISO is intentionally **not** committed to this repository (it is
large and fully reproducible from the source here). Build it yourself with
`./build.sh`.

## Repository layout

```
config/
  package-lists/deepblue.list.chroot      # packages installed into the live system
  hooks/live/0100-deepblue-branding.hook.chroot
                                          # runs in the chroot: user session,
                                          # wallpaper, welcome message, DM
  includes.chroot/etc/                    # os-release, lsb-release, issue banners
  includes.chroot/usr/share/backgrounds/deepblue/wallpaper.png
  includes.chroot/usr/share/deepblue/logo/deepblue-logo.png
  includes.chroot/usr/share/pixmaps/deepblue-logo.png
  includes.binary/isolinux/splash.png     # BIOS boot splash
build.sh                                  # configure + build
docs/                                     # boot/login test evidence
```

## Building

Requires a Debian (or Debian-derived) host, root privileges, ~60 GB free disk
and an internet connection.

```sh
sudo apt-get install live-build xorriso squashfs-tools debootstrap \
     isolinux syslinux-common syslinux-efi grub-pc-bin grub-efi-amd64-bin \
     grub-common mtools dosfstools imagemagick
sudo ./build.sh
```

The result is `live-image-amd64.hybrid.iso`.

### Note for container builds

`live-build` mounts a fresh `sysfs` inside the chroot. Containers that lack
`CAP_SYS_ADMIN` (most Docker/CI sandboxes) reject that mount. `build.sh`
detects this situation and falls back to bind-mounting the host `/sys`, which
those environments do permit. On a normal VM or bare-metal host no workaround
is needed.

## Writing to a USB stick

```sh
sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Replace `/dev/sdX` with your USB device. The hybrid image is bootable on both
BIOS and UEFI firmware.

## Verification

The image was booted under QEMU and logged into. See `docs/`:

- `docs/boot-test.log` — full boot log, reaching `multi-user.target` and
  `graphical.target`, ending at the `deepblue login:` prompt.
- `docs/login-test.log` — an automated login as `deepblue` confirming the live
  user, hostname and branding:

```
deepblue@deepblue:~$ id
uid=1000(deepblue) gid=1000(deepblue) groups=...,27(sudo),...
deepblue@deepblue:~$ cat /etc/os-release
PRETTY_NAME="DeepBlue Linux 1.0"
ID=deepblue
ID_LIKE=debian
deepblue@deepblue:~$ cat /etc/deepblue/release
DeepBlue Linux 1.0 (Cobalt)
Base: Debian GNU/Linux trixie
Desktop: LXQt
```

## Extending

- **Different desktop:** swap the LXQt packages in
  `config/package-lists/deepblue.list.chroot` for GNOME, KDE, XFCE, etc.
- **Real Deepin desktop:** install the `dde` packages from the Deepin
  repositories (`linuxdeepin` / `deepin-community` on GitHub) and point the
  session at DDE instead of LXQt.
- **Installer:** add `--debian-installer live` and an installer package list to
  let users install to disk, or wire up Calamares.
- **Own repository:** host custom `.deb` packages with `reprepro`/`aptly` and
  add them via `config/archives/`.

## Notes

Deepin, DDE and their logos are projects of their respective owners. DeepBlue
is an independent, educational rebrand and is not affiliated with or endorsed
by Deepin or UnionTech. URLs in the branding (`example.org`) are placeholders.

---

This project and its documentation were generated with the assistance of an
AI agent (OpenHands).
