#!/bin/zsh
# Builds a universal "Paws Off.app" and packs it into dist/PawsOff-mac.dmg: a branded window with
# drag-to-Applications layout, background art and the paw as the disk icon.
# Needs dmgbuild (pip install dmgbuild); it writes the Finder layout directly, so no Finder/GUI needed.
# The window shows a first-launch guide ("Open Anyway") while the app isn't notarized. Once it is,
# build with NOTARIZED=1 for the clean window without the guide.
set -euo pipefail
cd "$(dirname "$0")/.."

UNIVERSAL=1 ./build.sh "$@"

DMGBUILD=${DMGBUILD:-dmgbuild}
command -v "$DMGBUILD" >/dev/null || { echo "dmgbuild not found: pip install dmgbuild" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
if [ "${NOTARIZED:-0}" = 1 ]; then ART=dmg-background-notarized; WIDTH=660; HEIGHT=400; else ART=dmg-background; WIDTH=660; HEIGHT=596; fi
HEIGHT=$((HEIGHT + 32)) # the window's height includes its title bar; show the whole picture
# Retina background: one TIFF holding the 1x and 2x art.
tiffutil -cathidpicheck "Assets/installer/$ART.png" "Assets/installer/$ART@2x.png" \
  -out "$WORK/background.tiff" >/dev/null

mkdir -p dist
rm -f dist/PawsOff-mac.dmg
"$DMGBUILD" -s Tools/dmg-settings.py \
  -D app="Paws Off.app" -D background="$WORK/background.tiff" -D volume_icon=Assets/AppIcon.icns -D width="$WIDTH" -D height="$HEIGHT" \
  "Paws Off" dist/PawsOff-mac.dmg >/dev/null
echo "Packed dist/PawsOff-mac.dmg"
