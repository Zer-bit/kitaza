#!/usr/bin/env bash
# Regenerates every logo, launcher icon and splash asset from one source glyph.
#
#   assets/brand/source/kitaza_glyph.svg   <- the only file to edit
#
# Requires `rsvg-convert` (librsvg) and ImageMagick 7 (`magick`).
set -euo pipefail

cd "$(dirname "$0")/.."

GLYPH="assets/brand/source/kitaza_glyph.svg"
OUT="assets/brand"
BRAND_TEAL="#0F766E"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

glyph() { rsvg-convert -w "$1" -h "$1" "$GLYPH" -o "$WORK/glyph-$1.png"; }

# Full-bleed square for launcher icons. iOS rejects transparency and applies
# its own corner mask, so this must fill the whole canvas.
glyph 580
magick -size 1024x1024 "xc:$BRAND_TEAL" "$WORK/glyph-580.png" \
  -gravity center -composite "$OUT/app_icon.png"

# Android adaptive-icon foreground. The launcher may crop to a circle of 61%
# of the canvas, so the glyph stays well inside that.
glyph 440
magick -size 1024x1024 xc:none "$WORK/glyph-440.png" \
  -gravity center -composite "$OUT/app_icon_foreground.png"

# Splash logo: a rounded tile, drawn at 4x for a 120dp on-screen size.
glyph 280
magick -size 480x480 xc:none -fill "$BRAND_TEAL" \
  -draw "roundrectangle 0,0 479,479 108,108" \
  "$WORK/glyph-280.png" -gravity center -composite "$OUT/splash_logo.png"

# Android 12+ splash icon: 1152px canvas whose content must fit a 768px circle.
glyph 520
magick -size 1152x1152 xc:none "$WORK/glyph-520.png" \
  -gravity center -composite "$OUT/splash_android12.png"

echo "Brand assets written to $OUT/"

if [[ "${1:-}" != "--assets-only" ]]; then
  dart run flutter_launcher_icons
  dart run flutter_native_splash:create
fi
