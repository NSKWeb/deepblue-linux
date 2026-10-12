# Secure Boot — implemented, and where it goes next

DeepBlue 1.0 boots **with Secure Boot enabled** on UEFI machines. This
document explains how, why the chain terminates in Debian's key rather than a
DeepBlue one, and the route to a fully-owned chain later.

## Why Secure Boot matters (and what it does not do)

Secure Boot makes the firmware refuse to run a bootloader or kernel whose
signature it cannot verify against keys it trusts. Its real value is narrow
and worth stating plainly:

- It stops **evil-maid** and **bootkit** attacks — someone with brief physical
  access replacing your kernel or bootloader to persist malware that survives
  reinstalls.
- It does **not** protect your data if the attacker can also change firmware
  settings or has time to disable it.
- It does **not** replace disk encryption. A locked-down boot chain with an
  unencrypted disk still hands over your data.

So Secure Boot and LUKS (see `config/includes.installer/preseed.cfg`) are
complementary, not alternatives.

## The trust chain we ship

```
UEFI firmware
  └─ shim  (signed by Microsoft's UEFI CA)   ← the only thing firmware trusts by default
       └─ GRUB  (signed by Debian)           ← shim verifies this against the Debian key it embeds
            └─ kernel  (signed by Debian)    ← booted under the same chain of trust
                 └─ initramfs
```

The first link is the hard one: firmware trusts a fixed set of keys, with
Microsoft's UEFI CA among them, and a brand-new distro has no way to be in that
set without Microsoft's involvement. Debian solved it once, years ago, and we
reuse that solution.

## Option A — reuse Debian's Microsoft-signed shim (shipped)

Debian ships `shim-signed` (signed by Microsoft's UEFI CA) and
`grub-efi-amd64-signed` (signed by Debian, verified by that shim). live-build's
`binary_grub-efi` stage looks for exactly these two in the chroot and, when it
finds them, lays down the Secure Boot chain instead of the plain one:

- `EFI/BOOT/BOOTX64.EFI` ← shim from `shim-signed`
- `EFI/BOOT/grubx64.efi` ← GRUB from `grub-efi-amd64-signed`
- `EFI/BOOT/mmx64.efi` ← MokManager, for enrolling your own keys later

DeepBlue turns this on with two changes:

1. `config/package-lists/deepblue.list.chroot` lists `grub-efi-amd64-bin`,
   `grub-efi-amd64-signed` and `shim-signed`. (They must be listed explicitly
   because the build runs with `--apt-recommends false`, so the Recommends
   chain that normally pulls them in is not followed.)
2. `build.sh` passes `--uefi-secure-boot enable` to `lb config`, which makes
   live-build *require* the shim and signed GRUB (the default, `auto`, would
   fall back to an unsigned image if they were missing — a silent downgrade we
   do not want).

**Result:** the ISO and an installed system boot with Secure Boot *enabled*,
no disabling required. The chain terminates in Debian's key, not DeepBlue's.

**Limit:** a DeepBlue-built custom kernel would not be accepted, because it is
not signed by the Debian key. That is what the MOK route below solves.

## Option B — Machine Owner Key (MOK) for custom kernels (planned)

Between A and C, a MOK lets *your own* kernel be trusted on machines you
control, with no Microsoft involvement:

1. Generate a key pair (`openssl` or `efitools`).
2. Sign the kernel and every module with `sbsign`.
3. `mokutil --import <key>.der` — this queues an enrolment.
4. At the next reboot, **MokManager** (`mmx64.efi`, already on the ISO) asks
   you to confirm once. After that the firmware trusts your key until it is
   removed.

This is how DKMS and self-built kernels work on an otherwise Secure-Boot
system. It is a per-machine, one-reboot action — acceptable for developers and
for a distro whose users expect to compile things. Shipping a documented flow
and an `sbsign` helper is future work.

## Option C — own shim, signed by Microsoft (full ownership, costs money)

This is what Ubuntu, Fedora and Deepin do: generate your own keys, build your
own shim, and submit it to Microsoft for signing.

**Requirements:**

- An **EV code-signing certificate** (roughly US$99–300/year from a CA such as
  DigiCert, Sectigo or GlobalSign).
- A completed Microsoft **UEFI signing request**, including a copy of your
  shim and a description of the project.
- A review that can take days to weeks per submission, and must be repeated
  for shim updates.

**Then** you sign GRUB and the kernel with your own key, and the chain is
entirely yours. This is the end goal, but it is a funding and process
commitment, not a code change.

## Verifying on a built image

Boot the ISO on a UEFI machine (or VM) with Secure Boot enabled, then:

```sh
mokutil --sb-state                 # expect: SecureBoot enabled
sbverify --list /boot/vmlinuz-*    # signature present on the kernel
bootctl status                     # firmware + boot chain details (systemd-boot)
```

To confirm the ISO's EFI payload before booting, mount it and check the files:

```sh
xorriso -osirrox on -indev DeepBlue-Linux-1.0-amd64.iso -extract /EFI/BOOT/BOOTX64.EFI /tmp/BOOTX64.EFI
sbverify --list /tmp/BOOTX64.EFI   # should list a Microsoft UEFI CA signature
```

## Honest status

| Step | State |
|---|---|
| Disk encryption default | Implemented (`preseed.cfg`) |
| Default-deny firewall | Implemented (`deepblue-security`) |
| Automatic security updates | Implemented (`deepblue-security`) |
| AppArmor + sysctl hardening | Implemented (`deepblue-security`) |
| Reuse Debian signed shim (Option A) | **Implemented** — ISO boots with Secure Boot enabled |
| Own MOK flow (Option B) | Planned |
| Own Microsoft-signed shim (Option C) | Not started — needs an EV certificate |

What Option A does *not* give you: it does not make the boot chain
*DeepBlue's*. The signature that ultimately authorises boot is Debian's, which
means a DeepBlue-built custom kernel needs Option B or C to be trusted. Until
then, keep your kernels from the DeepBlue/Debian archive and the chain holds.
