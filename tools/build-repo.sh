#!/bin/sh
# Build the DeepBlue packages and publish them into the signed APT repo.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
PROJECT=$(cd "$HERE/.." && pwd)
REPO="$PROJECT/repo/apt"
export GNUPGHOME="$PROJECT/repo/gnupg"

# 1. Build every source package under pkg/
for src in "$PROJECT"/pkg/*/; do
    name=$(basename "$src")
    version=$(sed -n 's/^Version: //p' "$src/DEBIAN/control" | head -1)
    deb="$PROJECT/${name}_${version}_all.deb"
    echo ">> building $name $version"
    chmod 0755 "$src/DEBIAN"
    chmod g-s "$src/DEBIAN"
    find "$src/DEBIAN" -type f -exec chmod 0755 {} +
    dpkg-deb --build --root-owner-group "$src" "$deb" >/dev/null
    echo ">> publishing $name into repo"
    reprepro -b "$REPO" remove cobalt "$name" 2>/dev/null || true
    reprepro -b "$REPO" includedeb cobalt "$deb"
    rm -f "$deb"
done

echo ">> repo contents:"
reprepro -b "$REPO" list cobalt
