#!/bin/zsh
# Regenerates docs/images (hero and screenshots) from the current build. The icon comes from Tools/make-icons.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

./build.sh >/dev/null
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

"Paws Off.app/Contents/MacOS/PawsOff" --render-previews "$TMP/previews" >/dev/null
mkdir -p docs/images
swift Tools/make-readme-art.swift "$TMP/previews" docs/images

# Keep the banner light for fast page loads.
sips -Z 1600 docs/images/hero.png >/dev/null
