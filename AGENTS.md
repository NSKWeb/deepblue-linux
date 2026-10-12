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
- README must be **valid UTF-8 with real Unicode** (—, →, “ ”, emoji). It once
  accumulated double-encoded mojibake (`â€”`, `đź§©`) from earlier edits; if you
  see C1/C2 sequences, normalize each line with `line.encode(codec).decode('utf-8')`
  trying cp1252, then cp1250, then latin-1 (cp1250 is needed for `ś/ť/ź/Ą`).
  Check with: `python3 -c "import io;s=io.open('README.md',encoding='utf-8').read();print('\u00e2\u20ac' in s)"`.

## Docs assets (SVG infographics)
- Diagrams live in `docs/assets/*.svg`; style convention: dark-blue gradient
  header (`#0a4a86`→`#0891b2`), light body, accent `#38bdf8`/`#1c6fd6`, CSS
  classes, `role="img"` + `aria-label`, `viewBox` width 1200–1240.
- XML comments may **not** contain `--` (e.g. `<!-- ---- foo ---- -->` is
  invalid). Validate every SVG: `python3 -c "import xml.dom.minidom as m;m.parse('docs/assets/x.svg')"`.
- Preview headlessly with `chromium --headless --no-sandbox --disable-gpu
  --screenshot=out.png file://$PWD/docs/assets/x.svg` before committing.

## Auto-login
`config/hooks/live/0100-deepblue-branding.hook.chroot` sets
`autologin-user=deepblue` in `/etc/lightdm/lightdm.conf.d/60-deepblue.conf`.
Debian's `lightdm-autologin` PAM stack uses `pam_permit.so`, so no
`nopasswdlogin` group is needed. Verified: boots straight into LXQt.
This is **live-session only**: an installed system has no auto-login, and the
greeter asks for the user's password every boot (README “How a session boots”).

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
branding hook (`0100-deepblue-branding.hook.chroot`) trims to fit, taking the
ISO to ~1.86 GiB: APT lists/caches, CJK + obscure-script Noto fonts, legacy X11
fonts, `Papirus-Light`, documentation bodies (each package keeps its
`copyright`), unused Bibata cursor variants, non-`en` locale catalogs, and the
`netronome` NIC firmware. Keep the ISO under 2 GiB when adding packages.

Two gotchas found while trimming:

* **`--loadlin false` is required** (`build.sh`). live-build's `binary_loadlin`
  stage copies `chroot/usr/share/doc/loadlin/manual.txt.gz` into the image; the
  doc trim removes that file and the build then fails at `binary_loadlin`. The
  legacy DOS loader is useless for a BIOS+UEFI ISO anyway.
* **Trim `usr/share/doc` by file, not by directory.** `rm -rf` on package doc
  dirs can remove `copyright` (needed for licence compliance). The hook keeps
  one `copyright` per package.

If you re-trim by hand on an existing build tree, remember the files are
**root-owned** — the chroot dirs need `sudo`; a plain `rm` silently fails
(exit 1) and the next `lb build` reuses the untrimmed chroot.

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

### Security package (`deepblue-security`)
The hardening lives in one package, `pkg/deepblue-security/`, so it is
inspectable and removable like any other Debian package. It ships:

* `/etc/nftables.conf` — a default-deny ruleset. `nftables.service` loads that
  exact path, so the package **diverts** the nftables package's own copy to
  `/etc/nftables.conf.nftables` (`--no-rename`, same pattern as
  `deepblue-base` and `/etc/os-release`). Without the divert, a `nftables`
  upgrade would restore the permissive default.
* `etc/apt/apt.conf.d/20deepblue-auto-upgrades` + `51deepblue-unattended-upgrades`
  — enables unattended-upgrades, security pocket only, no forced reboot.
* `etc/sysctl.d/90-deepblue-hardening.conf` — desktop-safe kernel hardening.
* `DEBIAN/postinst` enables `nftables`, `unattended-upgrades` and `apparmor`
  and syntax-checks the firewall **before** starting it (a bad ruleset would
  otherwise cut the machine off the network on boot).

Gotchas:

* `nft -c -f /etc/nftables.conf` needs `CAP_NET_ADMIN`; in an unprivileged
  container it fails with `Operation not permitted` on `flush ruleset` before
  it ever parses the table. To syntax-check offline, drop the `flush` line and
  check the `table` block, or just run the build on a host with the capability.
* `--apt-recommends false` is set in `build.sh`, so any `Recommends` you rely
  on (here, `apparmor`) must be listed explicitly in the package list.

### Installer preseed
`config/includes.installer/preseed.cfg` is read by live-build and changes the
Debian installer's *defaults* — encrypted LVM partitioning, no root login,
`deepblue-base deepblue-security` included. Verify it parses with
`debconf-set-selections -c config/includes.installer/preseed.cfg`. Never
preseed a disk passphrase: it would be stored in plaintext on the ISO.

### Secure Boot (UEFI)
live-build has native Secure Boot support — no ISO surgery needed.
`scripts/build/binary_grub-efi` checks for `shim-signed` and
`grub-efi-amd64-signed` in the chroot and, when present, writes shim to
`EFI/BOOT/BOOTX64.EFI`, Debian-signed GRUB to `grubx64.efi`, and MokManager to
`mmx64.efi`. Two things are required:

* the packages in `config/package-lists/deepblue.list.chroot` — listed
  explicitly because `--apt-recommends false` means the Recommends chain
  (`grub-efi-amd64-bin` → `grub-efi-amd64-signed` → `shim-signed`) is not
  followed;
* `--uefi-secure-boot enable` in `build.sh`. `enable` makes live-build error
  out if the shim is missing; the default `auto` silently falls back to an
  unsigned image, which is the failure mode to avoid. (`LB_UEFI_SECURE_BOOT`
  defaults to `auto`; `LB_BOOTLOADER_EFI` defaults to `grub-efi`.)

Verify the result by extracting `EFI/BOOT/BOOTX64.EFI` from the ISO and
running `sbverify --list` on it — it should show a Microsoft UEFI CA signature.
The chain ends in Debian's key, so a self-built kernel needs a MOK; see
`docs/SECURE-BOOT.md`.

