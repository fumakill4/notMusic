#!/bin/sh
# Make NotMusic.app from a built binary:
#   macos/bundle.sh target/release/notmusic 1.0.0 3 out [portable]
# With `portable`, the app keeps its data in a folder beside itself (see portable.txt).
# Use the same local signing identity on repeat builds when available. A stable code
# requirement lets Keychain remember an Always Allow decision for NotMusic.
set -e

bin=$1
version=$2
build=$3
out=$4
kind=$5
[ -n "$bin" ] && [ -n "$version" ] && [ -n "$build" ] && [ -n "$out" ] || { echo "usage: $0 <binary> <version> <build> <out dir>"; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
icns="$here/../assets/icon/notmusic.icns"
app="$out/NotMusic.app"
identity=${NOTMUSIC_SIGNING_IDENTITY:-"Chris Tambayong Code Signing"}

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/notmusic"
chmod 755 "$app/Contents/MacOS/notmusic"
sed -e "s/@VERSION@/$version/g" -e "s/@BUILD@/$build/g" "$here/Info.plist" > "$app/Contents/Info.plist"

# Use the supplied macOS iconset after cleaning stray translucent pixels from its edges.
cp "$icns" "$app/Contents/Resources/notmusic.icns"

# Before signing: the signature seals everything in Resources.
[ "$kind" = portable ] && cp "$here/portable.txt" "$app/Contents/Resources/portable.txt"

if security find-identity -v -p codesigning | grep -F "\"$identity\"" >/dev/null; then
  codesign --force --sign "$identity" "$app"
else
  echo "Signing identity '$identity' not found; using ad-hoc signing. Keychain may ask again after each rebuild." >&2
  codesign --force --sign - "$app"
fi
echo "Made $app"
