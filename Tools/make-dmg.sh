#!/bin/zsh
# Builds a universal "Paws Off.app" and packs it into dist/PawsOff-mac.dmg: a branded window with
# drag-to-Applications layout, background art and the paw as the disk icon.
# Needs dmgbuild (pip install dmgbuild); it writes the Finder layout directly, so no Finder/GUI needed.
set -euo pipefail
cd "$(dirname "$0")/.."

UNIVERSAL=1 ./build.sh "$@"

DMGBUILD=${DMGBUILD:-dmgbuild}
command -v "$DMGBUILD" >/dev/null || { echo "dmgbuild not found: pip install dmgbuild" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
# Retina background: one TIFF holding the 1x and 2x art.
tiffutil -cathidpicheck Assets/installer/dmg-background.png Assets/installer/dmg-background@2x.png \
  -out "$WORK/background.tiff" >/dev/null

mkdir -p dist
rm -f dist/PawsOff-mac.dmg
"$DMGBUILD" -s Tools/dmg-settings.py \
  -D app="Paws Off.app" -D background="$WORK/background.tiff" -D volume_icon=Assets/AppIcon.icns \
  "Paws Off" dist/PawsOff-mac.dmg >/dev/null
echo "Packed dist/PawsOff-mac.dmg"
