#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO="$ROOT/repo"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <deb-url>" >&2
    exit 2
fi

URL=$1
NAME=${URL##*/}
DEST="$REPO/debs/$NAME"
TMP=$(mktemp -d "$ROOT/.add-deb.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

mkdir -p "$REPO/debs"
curl -L --fail --retry 2 -o "$DEST" "$URL"
CONTROL=$(ar p "$DEST" control.tar.gz | tar -xzO ./control)

field() {
    printf '%s\n' "$CONTROL" | awk -v key="$1" 'index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }'
}

PACKAGE=$(field Package)
VERSION=$(field Version)
ARCH=$(field Architecture)
DESCRIPTION=$(field Description)
MAINTAINER=$(field Maintainer)
SECTION=$(field Section)
DEPENDS=$(field Depends || true)

[ -n "$PACKAGE" ] || { echo "The downloaded file has no Package field." >&2; exit 1; }
[ -n "$VERSION" ] || { echo "The downloaded file has no Version field." >&2; exit 1; }

SIZE=$(stat -c '%s' "$DEST")
MD5=$(md5sum "$DEST" | awk '{print $1}')
SHA256=$(sha256sum "$DEST" | awk '{print $1}')

awk -v package="$PACKAGE" 'BEGIN { RS=""; ORS="\n\n" } $0 !~ "(^|\\n)Package: " package "(\\n|$)" { print }' "$REPO/Packages" > "$TMP/Packages"
{
    printf 'Package: %s\n' "$PACKAGE"
    printf 'Name: %s\n' "$(field Name)"
    printf 'Version: %s\n' "$VERSION"
    printf 'Architecture: %s\n' "$ARCH"
    printf 'Description: %s\n' "$DESCRIPTION"
    printf 'Maintainer: %s\n' "$MAINTAINER"
    printf 'Section: %s\n' "$SECTION"
    [ -n "$DEPENDS" ] && printf 'Depends: %s\n' "$DEPENDS"
    printf 'Filename: ./debs/%s\n' "$NAME"
    printf 'Size: %s\n' "$SIZE"
    printf 'MD5sum: %s\n' "$MD5"
    printf 'SHA256: %s\n' "$SHA256"
} >> "$TMP/Packages"
mv "$TMP/Packages" "$REPO/Packages"
gzip -n -c "$REPO/Packages" > "$REPO/Packages.gz"
bzip2 -c "$REPO/Packages" > "$REPO/Packages.bz2"

echo "Added $PACKAGE $VERSION ($ARCH) to $REPO"
