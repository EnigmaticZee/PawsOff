#!/bin/zsh
# Regenerates every copy of the app icon from Tools/make-icon.swift:
# the Mac icon (Assets/AppIcon.icns), the Windows icon (windows/Assets/PawsOff.ico),
# the README icon (docs/images/icon.png) and the installer art that shows it (Assets/installer).
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

swift Tools/make-icon.swift "$TMP"
iconutil -c icns "$TMP/AppIcon.iconset" -o Assets/AppIcon.icns
swift Tools/make-ico.swift windows/Assets/PawsOff.ico "$TMP"/ico/{16,20,24,32,40,48,64,128,256}.png
mkdir -p docs/images
cp "$TMP/AppIcon.iconset/icon_256x256@2x.png" docs/images/icon.png
swift Tools/make-installer-art.swift Assets/installer
