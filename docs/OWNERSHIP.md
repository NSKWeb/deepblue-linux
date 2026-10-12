# Ownership and licensing

"Ownership" of a Linux distribution has two very different meanings. This
document is deliberately explicit about both.

## 1. Practical ownership — yes, and this project has it

DeepBlue Linux is *your* distribution in the operational sense that every
distro actually controls:

- **Identity** — `/etc/os-release`, `/etc/lsb-release`, the TTY banner and the
  release marker are owned by the `deepblue-base` package, which **diverts**
  the copies shipped by Debian's `base-files`/`lsb-release`. Upgrading Debian
  packages will not silently overwrite your branding.
- **Packages** — the `deepblue-base` package is built from source in `pkg/`
  and published to your own archive, so you version and ship it yourself.
- **Repository** — the archive under `repo/` is signed with the DeepBlue
  repository key. Only holders of that private key can publish packages your
  systems will trust.
- **Release** — you choose the version numbers (`1.0.0`, "Cobalt") and the
  release cadence.

This is exactly the level of control Debian derivatives such as Ubuntu,
Linux Mint, Kali and Deepin themselves exercise.

## 2. Legal ownership — no, and no distro has it

DeepBlue is built from Debian, LXQt, the Linux kernel and thousands of other
Free/Open Source components. Those are the property of their respective
authors and are licensed, not sold:

- the Linux kernel, Debian utilities, LXQt and most of the stack are **GPL /
  LGPL / MIT / BSD** — you may use, modify and redistribute them, but you
  cannot claim authorship or exclusive ownership;
- **Deepin, DDE and their logos/trademarks** belong to Deepin Technology /
  the Deepin community. DeepBlue is *inspired by* Deepin; it does not contain
  or claim Deepin's trademarked material.

So "everything is mine" is true in the sense that you own and control the
distribution you assembled — the branding, packaging, repository and release
process. It is not true in the sense of owning the underlying Free Software,
and claiming that would both be inaccurate and a licence violation.

## Trademarks and names

`DeepBlue` is this project's working name. Before publishing widely, check
that it does not collide with an existing trademark in your jurisdiction.
The example contact addresses (`*.example`) and the signing key are
placeholders — replace them with your own.
