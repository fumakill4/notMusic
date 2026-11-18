#!/bin/sh
# Make the macOS app bundle from a built binary:
#   macos/bundle.sh target/release/notmusic 1.0.0 9 out [portable]
# With `portable`, the app keeps its data in a folder beside itself (see portable.txt).
# Use the same local signing identity on repeat builds when available. A stable code
# requirement lets Keychain remember an Always Allow decision for notMusic.
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
# Select the Apple Development certificate by fingerprint. Two certificates with
# the same display name are present in this Mac's login keychain.
identity=${NOTMUSIC_SIGNING_IDENTITY:-"09B49292213320D0D1E9822875B706C756651B2E"}

# Keychain's "Always Allow" decision is tied to the app's code identity. Don't
# silently produce a differently identified release when the stable signer is
# unavailable. Ad-hoc builds remain possible only when explicitly requested.
if ! security find-identity -v -p codesigning | grep -F "$identity" >/dev/null; then
  if [ "${NOTMUSIC_ALLOW_ADHOC:-0}" != 1 ]; then
    echo "Signing identity '$identity' not found. Refusing to make a release with a changing Keychain identity. For a local-only build, set NOTMUSIC_ALLOW_ADHOC=1." >&2
    exit 1
  fi
  echo "WARNING: using ad-hoc signing; Keychain may prompt again after rebuilds." >&2
fi

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$app/Contents/Frameworks"
cp "$bin" "$app/Contents/MacOS/notmusic"
chmod 755 "$app/Contents/MacOS/notmusic"
sed -e "s/@VERSION@/$version/g" -e "s/@BUILD@/$build/g" "$here/Info.plist" > "$app/Contents/Info.plist"

# Matching glyph alpha masks let the native glass stay continuous while text and
# icons underneath remain crisp (instead of creating rectangular clear patches).
mkdir -p "$app/Contents/Resources/GlassGlyphs"
for glyph in shuffle prev play pause next repeat repeat_one star star_filled lyrics lyrics_off queue volume_0 volume_1 volume_2 volume_3; do
  cp "$here/../assets/icon/glyphs/$glyph.png" "$app/Contents/Resources/GlassGlyphs/$glyph.png"
done

# The SwiftUI host supplies native macOS Liquid Glass surfaces to the Rust UI.
glass="$(dirname "$bin")/libNotMusicGlass.dylib"
if [ -f "$glass" ]; then
  cp "$glass" "$app/Contents/Frameworks/libNotMusicGlass.dylib"
  install_name_tool -id @rpath/libNotMusicGlass.dylib "$app/Contents/Frameworks/libNotMusicGlass.dylib"
  if security find-identity -v -p codesigning | grep -F "$identity" >/dev/null; then
    codesign --force --sign "$identity" "$app/Contents/Frameworks/libNotMusicGlass.dylib"
  else
    codesign --force --sign - "$app/Contents/Frameworks/libNotMusicGlass.dylib"
  fi
fi

# Use the supplied macOS iconset after cleaning stray translucent pixels from its edges.
cp "$icns" "$app/Contents/Resources/notmusic.icns"

# Before signing: the signature seals everything in Resources.
[ "$kind" = portable ] && cp "$here/portable.txt" "$app/Contents/Resources/portable.txt"

if security find-identity -v -p codesigning | grep -F "$identity" >/dev/null; then
  codesign --force --sign "$identity" "$app"
else
  codesign --force --sign - "$app"
fi
echo "Made $app"
