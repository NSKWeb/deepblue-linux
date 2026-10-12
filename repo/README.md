# DeepBlue Linux package archive

A signed APT repository that carries the DeepBlue Linux distribution identity
and (in future) DeepBlue-specific packages.

## Layout

```
repo/
  gnupg/                     # signing keyring (NEVER commit; see .gitignore)
  deepblue-archive-keyring.gpg   # public key, shipped on the ISO
  deepblue-archive-keyring.asc   # ASCII-armored public key
  apt/                       # reprepro repository
    conf/distributions       # release "cobalt"
    dists/cobalt/            # signed indices (InRelease, Release.gpg)
    pool/main/d/...          # package files
```

## Rebuild

```sh
./tools/build-repo.sh
```

This builds every source package under `pkg/`, publishes it into the archive
and re-signs the indices.

## Using the archive

On a DeepBlue system the archive is already wired up:

```
# /etc/apt/sources.list.d/deepblue.sources
Types: deb
URIs: file:///usr/share/deepblue/repo
Suites: cobalt
Components: main
Signed-By: /usr/share/keyrings/deepblue-archive-keyring.gpg
```

To add it to another Debian machine, copy the keyring into
`/usr/share/keyrings/` and point a sources file at wherever the archive is
hosted (HTTP, file://, or a mounted ISO).
