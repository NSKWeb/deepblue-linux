# Secure Boot — plan of record

DeepBlue 1.0 ships an unsigned boot chain, so the README tells you to disable
Secure Boot once on UEFI machines. This document is the plan to remove that
asterisk, and the trade-offs behind it. It is a *plan*: nothing below is
claimed as shipped behaviour.

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

## The trust chain we would ship

```
UEFI firmware
  └─ shim (signed by Microsoft's UEFI CA)      ← the only thing firmware trusts by default
       └─ GRUB (signed by the distro key)      ← shim verifies this
            └─ kernel + modules (signed)       ← GRUB verifies this
                 └─ initramfs (measured, not signed)
```

The tricky link is the first one. Firmware trusts a fixed set of keys —
Microsoft's UEFI CA among them. A brand-new distro has two ways to get its
own chain into that set.

## Option A — reuse Debian's Microsoft-signed shim (no cost, recommended first)

Debian already ships a shim signed by Microsoft's UEFI CA
(`shim-signed`), plus a matching signed GRUB (`grub-efi-amd64-signed`) and a
signed kernel. A live-build image normally generates its *own* EFI binaries,
which is exactly why DeepBlue's ISO is rejected today.

**Plan:**

1. Pull `shim-signed` and `grub-efi-amd64-signed` into the binary stage.
2. Place the signed EFI payload on the ISO's ESP instead of the live-build
   defaults:
   - `EFI/BOOT/BOOTX64.EFI` ← shim from `shim-signed`
   - `EFI/BOOT/grubx64.efi` ← GRUB from `grub-efi-amd64-signed`
3. Keep the Debian-signed kernel that the live system already uses.

**Result:** the ISO and an installed system boot with Secure Boot *enabled*,
no disabling required. The chain terminates in Debian's key, not DeepBlue's.

**Limit:** a DeepBlue-built custom kernel would not be accepted, because it is
not signed by the Debian key. That is what Option C solves.

## Option B — own shim, signed by Microsoft (full ownership, costs money)

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

## Option C — Machine Owner Key (MOK) for custom kernels

Between A and B, a MOK lets *your own* kernel be trusted on machines you
control, with no Microsoft involvement:

1. Generate a key pair (`openssl` or `efitools`).
2. Sign the kernel and every module with `sbsign`.
3. `mokutil --import <key>.der` — this queues an enrolment.
4. At the next reboot, **MokManager** asks you to confirm once. After that the
   firmware trusts your key until it is removed.

This is how DKMS and self-built kernels work on an otherwise Secure-Boot
system. It is a per-machine, one-reboot action — acceptable for developers and
for a distro whose users expect to compile things.

## What we would do, concretely

1. **Now (docs + preseed):** encryption by default, firewall, auto-updates —
   the parts that do not need a CA. *Shipped in `deepblue-security`.*
2. **Next (Option A):** wire `shim-signed` + `grub-efi-amd64-signed` into the
   binary stage so the stock ISO boots with Secure Boot on. This is the
   highest-value, lowest-cost step and needs no external approval.
3. **Later (Option C):** ship a documented MOK flow and a `sbsign` helper so
   users who build their own kernel can enrol it.
4. **Eventually (Option B):** pursue an EV certificate and Microsoft-signed
   shim for a fully-owned chain. Revisit when the project has a budget.

## Verifying, once implemented

```sh
mokutil --sb-state                 # SecureBoot enabled / disabled
sbverify --list /boot/vmlinuz-*    # signature present on the kernel
bootctl status                     # firmware + boot chain details (systemd-boot)
```

A signed kernel with Secure Boot enabled should report `SecureBoot enabled`
and a non-empty signature list.

## Honest status

| Step | State |
|---|---|
| Disk encryption default | Implemented (`preseed.cfg`) |
| Default-deny firewall | Implemented (`deepblue-security`) |
| Automatic security updates | Implemented (`deepblue-security`) |
| AppArmor + sysctl hardening | Implemented (`deepblue-security`) |
| Reuse Debian signed shim (Option A) | Planned — not in 1.0 |
| Own MOK flow (Option C) | Planned |
| Own Microsoft-signed shim (Option B) | Not started — needs an EV certificate |

Until Option A lands, the README's advice stands: disable Secure Boot once to
boot DeepBlue, and re-enable it afterwards if you do not need DeepBlue to boot.
