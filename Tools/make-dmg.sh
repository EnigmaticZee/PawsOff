#!/bin/zsh
# Builds a universal "Paws Off.app" and packs it into dist/PawsOff-mac.dmg
# with a drag-to-Applications layout.
set -euo pipefail
cd "$(dirname "$0")/.."

UNIVERSAL=1 ./build.sh "$@"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "Paws Off.app" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

mkdir -p dist
rm -f dist/PawsOff-mac.dmg
hdiutil create -volname "Paws Off" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov dist/PawsOff-mac.dmg >/dev/null
echo "Packed dist/PawsOff-mac.dmg"
