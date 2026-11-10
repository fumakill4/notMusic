#!/bin/sh
# Make NotMusic.app from a built binary:
#   macos/bundle.sh target/release/notmusic 1.0.0 2 out [portable]
# With `portable`, the app keeps its data in a folder beside itself (see portable.txt).
# The app is signed ad hoc (there's no Developer ID), so macOS asks before its first
# launch: right-click it and pick Open, or run `xattr -dr com.apple.quarantine notmusic.app`.
set -e

bin=$1
version=$2
build=$3
out=$4
kind=$5
[ -n "$bin" ] && [ -n "$version" ] && [ -n "$build" ] && [ -n "$out" ] || { echo "usage: $0 <binary> <version> <build> <out dir>"; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
icon="$here/../assets/icon/icon.png"
app="$out/NotMusic.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/notmusic"
chmod 755 "$app/Contents/MacOS/notmusic"
sed -e "s/@VERSION@/$version/g" -e "s/@BUILD@/$build/g" "$here/Info.plist" > "$app/Contents/Info.plist"

# The Dock and Finder icon, at each size iconutil takes up to the 256 px source.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
set=$tmp/notmusic.iconset
mkdir "$set"
for spec in 16:16x16 32:16x16@2x 32:32x32 64:32x32@2x 128:128x128 256:128x128@2x 256:256x256; do
    sips -z "${spec%%:*}" "${spec%%:*}" "$icon" --out "$set/icon_${spec#*:}.png" >/dev/null
done
iconutil -c icns "$set" -o "$app/Contents/Resources/notmusic.icns"

# Before signing: the signature seals everything in Resources.
[ "$kind" = portable ] && cp "$here/portable.txt" "$app/Contents/Resources/portable.txt"

codesign --force --sign - "$app"
echo "Made $app"
