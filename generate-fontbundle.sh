#!/usr/bin/env bash
set -euo pipefail

# generate-fontbundle.sh
# Usage: ./generate-fontbundle.sh 3.18
# Alpine default: 3.18

ALPINE_VERSION="${1:-3.18}"
ENGINE="${DOCKER_ENGINE:-docker}"
BUILDER="fontbundle-builder-$(date +%s)"
OUT_DIR="$(pwd)/fontbundle"

echo "=> Using engine: $ENGINE"
echo "=> Using Alpine version: $ALPINE_VERSION"

$ENGINE pull alpine:$ALPINE_VERSION

echo "=> Starting builder container..."
$ENGINE run -d --name "$BUILDER" alpine:$ALPINE_VERSION sleep infinity

echo "=> Installing packages..."
$ENGINE exec "$BUILDER" sh -c "
  apk update >/dev/null && apk add --no-cache \
    fontconfig freetype ttf-dejavu ttf-freefont \
    libpng expat bzip2 util-linux
"

echo "=> Preparing bundle directories..."
$ENGINE exec "$BUILDER" sh -c "
  mkdir -p /fontbundle/usr/lib
  mkdir -p /fontbundle/usr/share/fonts
  mkdir -p /fontbundle/etc/fonts/conf.d
"

echo "=> Copying libs..."
$ENGINE exec "$BUILDER" sh -c "
  cp -L /usr/lib/libfontconfig.so* /fontbundle/usr/lib/ || true
  cp -L /usr/lib/libfreetype.so*   /fontbundle/usr/lib/ || true
  cp -L /usr/lib/libpng*.so*       /fontbundle/usr/lib/ || true
  cp -L /usr/lib/libexpat*.so*     /fontbundle/usr/lib/ || true
  cp -L /usr/lib/libbz2*.so*       /fontbundle/usr/lib/ || true
  cp -L /usr/lib/libz.so*          /fontbundle/usr/lib/ || true
  cp -L /usr/lib/libuuid*.so*      /fontbundle/usr/lib/ || true
"

echo "=> Copying system fonts & config..."
$ENGINE exec "$BUILDER" sh -c "
  cp -a /usr/share/fonts /fontbundle/usr/share/
  cp -a /etc/fonts/* /fontbundle/etc/fonts/
"

echo "=> Copying bundle to host..."
rm -rf "$OUT_DIR"
$ENGINE cp "$BUILDER:/fontbundle" "$OUT_DIR"

echo "=> Cleaning up..."
$ENGINE rm -f -v "$BUILDER"

echo "=> Compressing bundle..."
tar -czvf fontbundle.tar.gz -C "$(dirname "$OUT_DIR")" "$(basename "$OUT_DIR")"

echo "=> DONE."
echo "fontbundle.tar.gz generated!"
