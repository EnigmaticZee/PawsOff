#!/bin/zsh
# Builds a universal "Paws Off.app" and packs it into dist/PawsOff-mac.dmg: a branded window with
# drag-to-Applications layout, background art and the paw as the disk icon.
# Needs dmgbuild (pip install dmgbuild); it writes the Finder layout directly, so no Finder/GUI needed.
#
# With SIGN_IDENTITY set ("Developer ID Application: …") the app is signed with it (see build.sh)
# and so is the DMG. When Apple's notary key is there too (the APP_STORE_CONNECT_* variables, see
# Tools/notarize.sh), both are notarized and stapled and the window drops its first-launch guide;
# NOTARIZE=0 skips that, NOTARIZE=1 insists on it. Unnotarized builds show the "Open Anyway" guide.
set -euo pipefail
cd "$(dirname "$0")/.."

NOTARIZE="${NOTARIZE:-auto}"
if [ "$NOTARIZE" = auto ]; then
  if [ -n "${SIGN_IDENTITY:-}" ] && [ -n "${APP_STORE_CONNECT_KEY:-}" ]; then NOTARIZE=1; else NOTARIZE=0; fi
fi
if [ "$NOTARIZE" = 1 ] && [ -z "${SIGN_IDENTITY:-}" ]; then
  echo "Notarizing needs SIGN_IDENTITY (a Developer ID Application certificate)" >&2
  exit 1
fi

UNIVERSAL=1 ./build.sh "$@"
[ "$NOTARIZE" = 1 ] && Tools/notarize.sh "Paws Off.app"

DMGBUILD=${DMGBUILD:-dmgbuild}
command -v "$DMGBUILD" >/dev/null || { echo "dmgbuild not found: pip install dmgbuild" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
if [ "$NOTARIZE" = 1 ]; then ART=dmg-background-notarized; HEIGHT=400; else ART=dmg-background; HEIGHT=596; fi
HEIGHT=$((HEIGHT + 32)) # the window's height includes its title bar; show the whole picture
# Retina background: one TIFF holding the 1x and 2x art.
tiffutil -cathidpicheck "Assets/installer/$ART.png" "Assets/installer/$ART@2x.png" \
  -out "$WORK/background.tiff" >/dev/null

mkdir -p dist
rm -f dist/PawsOff-mac.dmg dist/notarized
"$DMGBUILD" -s Tools/dmg-settings.py \
  -D app="Paws Off.app" -D background="$WORK/background.tiff" -D volume_icon=Assets/AppIcon.icns -D height="$HEIGHT" \
  "Paws Off" dist/PawsOff-mac.dmg >/dev/null
if [ -n "${SIGN_IDENTITY:-}" ]; then
  codesign --force --sign "$SIGN_IDENTITY" --timestamp dist/PawsOff-mac.dmg
fi
if [ "$NOTARIZE" = 1 ]; then
  Tools/notarize.sh dist/PawsOff-mac.dmg
  touch dist/notarized # tells the release notes which install steps to show
fi
echo "Packed dist/PawsOff-mac.dmg$([ "$NOTARIZE" = 1 ] && echo ', notarized')"
