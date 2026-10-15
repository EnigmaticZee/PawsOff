#!/bin/zsh
# Regenerates docs/images (README icon, hero and screenshots) from the current build.
set -euo pipefail
cd "$(dirname "$0")/.."

./build.sh >/dev/null
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

"Paws Off.app/Contents/MacOS/PawsOff" --render-previews "$TMP/previews" >/dev/null
swift Tools/make-icon.swift "$TMP/AppIcon.iconset"
mkdir -p docs/images
cp "$TMP/AppIcon.iconset/icon_256x256@2x.png" docs/images/icon.png
swift Tools/make-readme-art.swift "$TMP/previews" docs/images

# Keep the banner light for fast page loads.
sips -Z 1600 docs/images/hero.png >/dev/null
