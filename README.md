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
- **Installer:** ships the Debian installer (graphical + textual). The boot
  menu offers "Start installer" alongside the live system, so the distro can be
  installed to disk, not just run live.
- **Live user:** `deepblue` (password `live`, member of `sudo`)
- **Auto-login:** the live session boots straight into the LXQt desktop,
  no login prompt (Deepin-live style)
- **Branding:** custom `/etc/os-release`, `/etc/lsb-release`, TTY banner,
  wallpaper, logo, boot splash and a live-session welcome message

## ISO

| Property        | Value                                  |
| --------------- | -------------------------------------- |
| Volume label    | `DEEPBLUE`                             |
| Size            | ~2.1 GB (live + installer)             |
| Boot records    | El Torito BIOS (`isolinux`) + UEFI (`grub`) |
| Live user       | `deepblue` / `live`                    |
| Hostname        | `deepblue`                             |
| Installer       | Debian installer, graphical + textual  |

The built ISO is intentionally **not** committed to this repository (it is
large and fully reproducible from the source here). Build it yourself with
`./build.sh`.

## Ownership

DeepBlue Linux is your own distribution in the practical sense: the identity
files, the `deepblue-base` package, the signed package archive and the release
versioning are all yours and under your control. The underlying Debian/LXQt/
kernel code is Free Software owned by its authors and is used under licence —
see [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md) for the full, honest picture.

## Packages and archive

DeepBlue ships its identity as real Debian packages rather than loose files:

| Package                    | Purpose                                             |
| -------------------------- | --------------------------------------------------- |
| `deepblue-base`            | Distro identity (`os-release`, `lsb-release`, banners, release marker). Diverts the `base-files`/`lsb-release` copies so upgrades cannot clobber the branding. |
| `deepblue-archive-keyring` | Public key for the DeepBlue archive                 |

Both are built from source in `pkg/` and published to a **signed APT archive**
(`repo/`) via `tools/build-repo.sh`. The archive is wired into the ISO at
`/usr/share/deepblue/repo` with a `deb822` source in
`/etc/apt/sources.list.d/deepblue.sources`, so the installed system can update
DeepBlue packages from its own archive.

## Repository layout

```
config/
  package-lists/deepblue.list.chroot      # packages installed into the live system
  package-lists/installer.list.chroot     # debian-installer-launcher
  packages.chroot/                        # local .deb files (deepblue-base, keyring)
  hooks/live/0100-deepblue-branding.hook.chroot
                                          # runs in the chroot: session, wallpaper,
                                          # welcome message, display manager
  includes.chroot/etc/apt/sources.list.d/deepblue.sources
  includes.chroot/usr/share/deepblue/repo # signed archive shipped on the ISO
  includes.chroot/usr/share/keyrings/deepblue-archive-keyring.gpg
  includes.chroot/usr/share/backgrounds/deepblue/wallpaper.png
  includes.chroot/usr/share/deepblue/logo/deepblue-logo.png
  includes.binary/isolinux/splash.png     # BIOS boot splash
pkg/                                      # Debian source packages
  deepblue-base/
  deepblue-archive-keyring/
repo/                                     # signed APT archive (reprepro)
  apt/conf/distributions                  # release "cobalt"
  apt/dists/cobalt/                       # signed indices
  apt/pool/                               # package files
  deepblue-archive-keyring.gpg            # public key
  gnupg/                                  # private signing keyring (gitignored)
tools/build-repo.sh                       # build + publish + sign packages
setup-host.sh                             # install toolchain + container workaround
build.sh                                  # configure + build the ISO
docs/                                     # boot/login/gui/installer evidence + ownership
```

## Building

Requires a Debian (or Debian-derived) host, root privileges, ~60 GB free disk
and an internet connection.

```sh
sudo ./setup-host.sh     # installs the toolchain + applies container workaround
sudo ./build.sh          # configures and builds the ISO
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

- `docs/gui-session-test.log` — confirms the graphical session actually comes
  up: `lightdm` active, `Xorg :0` running, and a full LXQt desktop
  (`lxqt-session`, `lxqt-panel`, `openbox`, `pcmanfm-qt`, …) running as
  `deepblue` via auto-login.
- `docs/installer-test.log` — the Debian installer boots from the same medium
  and runs its dialog flow (language → location → keyboard → detecting
  hardware to find installation media → network detection), confirming the
  ISO can install to disk and not just run live.

## Build timing

On a 4-vCPU sandbox with no KVM (QEMU TCG):

| Scenario                        | Duration |
| ------------------------------- | -------- |
| First build, empty apt cache    | ~12.5 min |
| Rebuild, warm apt cache         | ~8.5 min  |
| Installer-enabled, warm cache   | ~12 min   |

The long pole is `mksquashfs -comp xz` compressing the ~1.3 GB root filesystem.
Adding the installer pulls ~700 MB of udebs and grows the ISO to ~2.1 GB.

### live-build rebuild gotchas

`lb build` reuses cached stage files in `.build/` and will silently skip stages
whose inputs look unchanged — hook edits are a common victim. To force a stage
to re-run, remove its marker (for example `sudo rm -rf .build/chroot_hooks`)
or run `lb clean` and rebuild; keep `cache/` so package downloads are not
repeated. Do not delete `.build/config`, or `lb build` aborts with
`the following stage is required to be done first: config` — re-run
`lb config` (as `build.sh` does) to recreate it.

## Extending

- **Different desktop:** swap the LXQt packages in
  `config/package-lists/deepblue.list.chroot` for GNOME, KDE, XFCE, etc.
- **Real Deepin desktop:** install the `dde` packages from the Deepin
  repositories (`linuxdeepin` / `deepin-community` on GitHub) and point the
  session at DDE instead of LXQt.
- **Unattended installs:** add a preseed file
  (`--debian-installer-preseedfile`) and a matching kernel append line to make
  the "Automated install" boot entry hands-off.
- **Own repository:** host custom `.deb` packages with `reprepro`/`aptly` and
  add them via `config/archives/`.

## Notes

Deepin, DDE and their logos are projects of their respective owners. DeepBlue
is an independent, educational rebrand and is not affiliated with or endorsed
by Deepin or UnionTech. URLs in the branding (`example.org`) are placeholders.

---

This project and its documentation were generated with the assistance of an
AI agent (OpenHands).
