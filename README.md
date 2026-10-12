<div align="center">

<img src="docs/assets/hero.svg" alt="DeepBlue Linux — Debian-based, LXQt desktop, your own signed archive" width="100%"/>

**A Deepin-inspired, Debian-based Linux distribution you actually own — its own identity packages, its own signed APT archive, its own release.**

[![Release](https://img.shields.io/badge/release-1.0%20%22Cobalt%22-0891b2?style=for-the-badge)](#-release)
[![Download ISO](https://img.shields.io/badge/download-ISO%20%C2%B7%202%20GB-16a34a?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/NSKWeb/deepblue-linux/releases/latest)
[![Base](https://img.shields.io/badge/base-Debian%20trixie-A80030?style=for-the-badge&logo=debian&logoColor=white)](#-what-you-get)
[![Desktop](https://img.shields.io/badge/desktop-LXQt%20%2F%20Qt-0ea5e9?style=for-the-badge)](#-what-you-get)
[![Arch](https://img.shields.io/badge/arch-amd64-334155?style=for-the-badge)](#-release)
[![Boot](https://img.shields.io/badge/boot-BIOS%20%2B%20UEFI-16a34a?style=for-the-badge)](#-release)

</div>

---

## 📥 Download &amp; run

### 1. Get the ISO

Download the latest image from the **[Releases page](https://github.com/NSKWeb/deepblue-linux/releases/latest)**:

**`DeepBlue-Linux-1.0-amd64.iso`** — ~2.0 GB (live + installer)

Or from the command line:

```sh
curl -L -O https://github.com/NSKWeb/deepblue-linux/releases/download/v1.0/DeepBlue-Linux-1.0-amd64.iso
curl -L -O https://github.com/NSKWeb/deepblue-linux/releases/download/v1.0/DeepBlue-Linux-1.0-amd64.iso.sha256
```

### 2. Verify the download (recommended)

```sh
sha256sum -c DeepBlue-Linux-1.0-amd64.iso.sha256
# expected: DeepBlue-Linux-1.0-amd64.iso: OK
```

The expected hash is `4517ddfa9be0220f415483d0eda9c1db609f89ae4e7c567345c273d1d28abb3b`.

### 3. Flash it to a USB stick

Use a stick of **4 GB or larger** — everything on it will be erased.

<table>
<tr><th align="left">OS</th><th align="left">Command</th></tr>
<tr><td><b>Linux / macOS</b></td><td>

```sh
sudo dd if=DeepBlue-Linux-1.0-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

(Replace `/dev/sdX` with your USB device — check with `lsblk`. On macOS use `/dev/rdiskN`.)

</td></tr>
<tr><td><b>Windows</b></td><td>Use <a href="https://rufus.ie">Rufus</a> or <a href="https://etcher.balena.io">balenaEtcher</a>: select the ISO, select the USB stick, press Start. Choose “DD image” mode in Rufus if prompted.</td></tr>
</table>

### 4. Boot from the USB stick

1. Plug the stick into the machine and **reboot**.
2. Open the **boot menu** — usually `F12`, `F10`, `F9`, `Esc`, or `Del` during the splash.
3. Pick the USB entry. On a **UEFI** machine you may need to disable Secure Boot once (the image is not Secure-Boot signed).

The boot menu offers three ways in:

| Entry | What it does |
| --- | --- |
| **Live system** | Boots the full desktop without touching your disk — auto-logs into LXQt. |
| **Start installer** | Launches the Debian installer (graphical or textual) to install DeepBlue to disk. |
| **Live system (failsafe)** | Live boot with conservative kernel options, if the normal one has trouble. |

> [!NOTE]
> The live session logs in automatically as **`deepblue`** (password `live`, member of `sudo`). Nothing is written to your disk until you run the installer.

### 5. Try it in a virtual machine (no USB needed)

Any of these work — give it **2 GB RAM** and **20 GB disk**:

<table>
<tr><th align="left">Tool</th><th align="left">How</th></tr>
<tr><td><b>QEMU (Linux/macOS)</b></td><td>

```sh
qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm \
  -cdrom DeepBlue-Linux-1.0-amd64.iso -boot d
```

(drop `-enable-kvm` on macOS/Windows; it will run under TCG)

</td></tr>
<tr><td><b>VirtualBox</b></td><td>New VM → Linux / Debian 64-bit → attach the ISO as the optical disk → Start.</td></tr>
<tr><td><b>VMware / Hyper-V</b></td><td>New VM → attach the ISO → boot. UEFI or BIOS both work.</td></tr>
</table>

### 6. Install to disk

From the live session, double-click **Install DeepBlue** on the desktop (or pick **Start installer** at the boot menu), then follow the Debian installer: language → location → keyboard → disk → user → install. On first boot you get the installed DeepBlue system, which updates from its own signed archive.

---

## Why this exists

Most “make your own distro” advice stops at a wallpaper and an `os-release`
file. DeepBlue goes the full distance and does what real derivatives — Ubuntu,
Linux Mint, Kali, and Deepin itself — do:

- ships its **identity as a real Debian package** that **diverts** the copies
  from `base-files`, so a Debian upgrade can never silently overwrite the
  branding;
- builds its **own signed APT archive** with its own GPG key, so only you can
  publish packages your systems will trust;
- wires that archive into the ISO, so an **installed** DeepBlue system updates
  from its own repository.

DeepBlue is a *rebrand* of the Debian live system, not a from-scratch distro.
Deepin is built the same way (Debian base + its own desktop), so this is the
same approach taken to a smaller, reproducible scale.

---

## What you get

<table>
<tr><th align="left">Layer</th><th align="left">Choice</th><th align="left">Why</th></tr>
<tr><td><b>Base</b></td><td>Debian GNU/Linux 13 (trixie), <code>amd64</code></td><td>Stable, huge package set, the same base Deepin uses</td></tr>
<tr><td><b>Desktop</b></td><td>LXQt (Qt-based)</td><td>Closest stock-Debian equivalent to Deepin’s DDE look &amp; feel</td></tr>
<tr><td><b>Display manager</b></td><td>LightDM with slick-greeter</td><td>Themeable, auto-login friendly</td></tr>
<tr><td><b>Boot</b></td><td>Hybrid ISO — BIOS + UEFI</td><td>One image boots on anything</td></tr>
<tr><td><b>Installer</b></td><td>Debian installer, graphical + textual</td><td>Install to disk, not just live</td></tr>
<tr><td><b>Live user</b></td><td><code>deepblue</code> (password <code>live</code>, in <code>sudo</code>)</td><td>Deepin-live style, no friction</td></tr>
<tr><td><b>Auto-login</b></td><td>Straight into the LXQt desktop</td><td>No login prompt on the live session</td></tr>
</table>

---

## Architecture

<img src="docs/assets/architecture.svg" alt="DeepBlue build pipeline: sources → build → ISO → installed system and the update loop back into the signed archive" width="100%"/>

The pipeline is short and reproducible. `build.sh` runs four things:

1. **`tools/build-repo.sh`** builds every source package under `pkg/` with
   `dpkg-deb`, publishes it into the reprepro archive under `repo/`, and
   **re-signs the archive indices** with the DeepBlue signing key.
2. It copies the signed archive into `config/includes.chroot/usr/share/deepblue/repo`
   so the ISO **ships its own repository**, plus the keyring into
   `/usr/share/keyrings/`.
3. `lb config` sets the live-build parameters (distribution, arch, installer,
   ISO metadata, live user).
4. `lb build` bootstraps the chroot, installs packages, squashfs-es the live
   system and produces a **hybrid ISO** with both BIOS and UEFI boot records.

On an installed system the loop closes: `apt update` validates the archive’s
`InRelease` against the shipped keyring, and `deepblue-base` updates come
straight from `DeepBlue Linux:cobalt`.

---

## Ownership — the honest picture

<img src="docs/assets/ownership.svg" alt="Three ownership layers: yours, used under licence, and third-party names" width="100%"/>

“Ownership” has two meanings, and it is worth being precise:

| | Meaning | Reality for DeepBlue |
|---|---|---|
| ✅ **Practical** | Who controls the distribution: identity, packages, repository, release | **Yours.** You decide what ships, when, its name, and who may publish. |
| 🧩 **Licence** | The underlying Debian/LXQt/kernel code | Owned by its authors under GPL/LGPL/MIT/BSD. You may use, modify, redistribute — **not** claim authorship. |
| 🚫 **Trademark** | “Deepin”, “DDE”, Deepin logos | Belong to Deepin Technology / the Deepin community. DeepBlue is *inspired by* Deepin and ships none of its marks. |

Practical ownership is exactly what Ubuntu, Mint, Kali and Deepin exercise.
Full legal ownership of the Free Software stack is not something any
distribution has — and claiming it would be inaccurate and a licence
violation. See [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md).

---

## Packages — the identity is code, not files

DeepBlue’s branding lives in **real Debian packages**, built from source in
[`pkg/`](pkg/):

| Package | Purpose |
| --- | --- |
| [`deepblue-base`](pkg/deepblue-base) | Owns `/etc/os-release`, `/etc/lsb-release`, `/etc/issue`, `/etc/issue.net`, `/etc/deepblue/release`. Diverts the `base-files`/`lsb-release` copies. |
| [`deepblue-archive-keyring`](pkg/deepblue-archive-keyring) | The public key of the DeepBlue archive. |

### How the branding survives upgrades

<img src="docs/assets/diversion.svg" alt="deepblue-base diverts base-files so the DeepBlue /etc/os-release wins, with the preinst diversion code" width="100%"/>

`base-files` is an *Essential* package that ships `/etc/os-release`, so a naive
`dpkg-divert --rename` fails at unpack time with
`trying to overwrite '/etc/os-release'`. Two things fix it, both in
[`pkg/deepblue-base/DEBIAN/preinst`](pkg/deepblue-base/DEBIAN/preinst):

1. **`--no-rename`** — we do not want the file moved aside, we replace its
   contents.
2. debootstrap leaves a *local* diversion on `/etc/os-release`
   (`→ /etc/os-release.debootstrap`) that clashes with ours; the `preinst`
   drops it first and **must pass `--local`**, otherwise dpkg scopes the
   removal to the package and errors `mismatch on package`.

The `prerm` mirrors the `preinst` exactly. The result is verified behaviour:

| Action | `/etc/os-release` after |
| --- | --- |
| Install `deepblue-base` | `PRETTY_NAME="DeepBlue Linux 1.0"` |
| Reinstall `base-files` | **still DeepBlue** — the upgrade cannot clobber it |
| Purge `deepblue-base` | Debian’s original, diversions cleanly removed |

---

## The signed archive

`repo/` is a [reprepro](https://salsa.debian.org/brlink/reprepro) archive,
release codename **`cobalt`**, whose indices (`InRelease`, `Release.gpg`) are
signed with the DeepBlue key. On the ISO it is wired in with a `deb822`
source:

```ini
# /etc/apt/sources.list.d/deepblue.sources
Types: deb
URIs: file:///usr/share/deepblue/repo
Suites: cobalt
Components: main
Signed-By: /usr/share/keyrings/deepblue-archive-keyring.gpg
```

> [!IMPORTANT]
> The **private signing key** lives in `repo/gnupg/` and is **gitignored —
> never commit or share it.** It is the one thing that lets you publish
> packages your systems will trust. To host the archive over HTTP later, copy
> `repo/apt/` to a web root and point the `URIs:` field at your URL.

---

## Verified behaviour

<img src="docs/assets/terminal-flow.svg" alt="Terminal transcript: live boot banner, os-release, apt update against the signed archive, apt-cache policy" width="100%"/>

Everything below was exercised on the built image (evidence in [`docs/`](docs/)):

- [x] Live ISO **boots** under QEMU (TCG) — banner `DeepBlue Linux 1.0 (Cobalt)`, `deepblue login:`
- [x] **Auto-login** into the LXQt graphical session
- [x] Debian **installer** boots (textual + graphical) — language → location → keyboard → hardware → network
- [x] `deepblue-base` **installs cleanly** in the chroot
- [x] `apt-get update` validates the archive’s `InRelease` with the shipped keyring — no prompts, no errors
- [x] `apt-cache policy deepblue-base` → candidate from **`DeepBlue Linux:cobalt`**
- [x] `base-files` reinstall leaves the DeepBlue identity intact; purge restores Debian’s

---

## Release

| Property | Value |
| --- | --- |
| Version | **1.0 “Cobalt”** |
| File | `DeepBlue-Linux-1.0-amd64.iso` |
| Size | ~2.0 GB (live + installer) |
| Volume label | `DEEPBLUE` |
| Boot records | El Torito **BIOS** (`isolinux`) + **UEFI** (`grub`) |
| Live user | `deepblue` / `live` |
| Hostname | `deepblue` |

The built ISO is intentionally **not** committed to git (it is large); it is
published as a **release asset** and is fully reproducible from this source.

**[Download the latest ISO](https://github.com/NSKWeb/deepblue-linux/releases/latest)** �
[all releases](https://github.com/NSKWeb/deepblue-linux/releases) �
[how to flash &amp; boot](#-download--run)

---

## Repository layout

```text
config/                                   # live-build tree
  package-lists/deepblue.list.chroot      # packages installed into the live system
  package-lists/installer.list.chroot     # debian-installer-launcher
  packages.chroot/                        # local .deb files baked into the ISO
  hooks/live/0100-deepblue-branding.hook.chroot
                                          # chroot hook: session, wallpaper,
                                          # welcome message, display manager
  includes.chroot/etc/apt/sources.list.d/deepblue.sources
  includes.chroot/usr/share/deepblue/repo # the signed archive, shipped on the ISO
  includes.chroot/usr/share/keyrings/deepblue-archive-keyring.gpg
  includes.chroot/usr/share/backgrounds/deepblue/wallpaper.png
  includes.chroot/usr/share/deepblue/logo/deepblue-logo.png
  includes.binary/isolinux/splash.png     # BIOS boot splash
pkg/                                      # Debian source packages (yours)
  deepblue-base/
  deepblue-archive-keyring/
repo/                                     # signed APT archive (reprepro)
  apt/conf/distributions                  # release "cobalt"
  apt/dists/cobalt/                       # signed indices
  apt/pool/                               # package files
  deepblue-archive-keyring.gpg            # public key
  gnupg/                                  # private signing keyring (GITIGNORED)
tools/build-repo.sh                       # build + publish + sign packages
build.sh                                  # configure + build the ISO
setup-host.sh                             # install toolchain + container workaround
docs/                                     # evidence, ownership notes, SVG assets
```

---

## Building

Requires a Debian (or Debian-derived) host, root (live-build mounts
`/proc`, `/dev/pts`, `/sys` inside the chroot), and ~60 GB free disk.

```sh
sudo apt-get install live-build debootstrap xorriso squashfs-tools \
     gpg reprepro qemu-system-x86
sudo ./setup-host.sh      # installs the toolchain and applies the sysfs workaround
sudo ./build.sh           # builds packages + signs the archive + builds the ISO
```

On a 4-vCPU QEMU/TCG sandbox: first build ~12.5 min, warm rebuild ~8.5 min,
with the installer ~12 min.

---

## Verification

Boot the ISO under QEMU (no KVM in this sandbox, so TCG — slow):

```sh
qemu-system-x86_64 -m 2048 -smp 2 -nographic -no-reboot \
  -cdrom live-image-amd64.hybrid.iso \
  -kernel <extracted vmlinuz> -initrd <extracted initrd.img> \
  -append "boot=live components hostname=deepblue username=deepblue console=ttyS0,115200"
```

The live user password is `live`. Evidence logs live in [`docs/`](docs/).

---

## Roadmap

- [ ] Host the signed archive over HTTPS and point the source at it
- [ ] Deepin-style theming pass (icons, Qt style, panel layout)
- [ ] Custom installer branding
- [ ] A `deepblue-meta` metapackage to pull in the default desktop set

---

<div align="center">

**DeepBlue Linux** — built with Debian’s [`live-build`](https://wiki.debian.org/DebianLive) · release **1.0 “Cobalt”**

*Practical ownership is yours; the Free Software stack is used under licence. See [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md).*

</div>
