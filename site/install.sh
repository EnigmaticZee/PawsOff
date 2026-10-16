#!/bin/bash
# Installs Paws Off (https://github.com/EnigmaticZee/PawsOff) on a Mac and opens it.
#   curl -fsSL https://enigmaticzee.github.io/PawsOff/install.sh | bash
# It downloads the latest release's DMG from GitHub, copies "Paws Off.app" into /Applications
# (or ~/Applications if that isn't writable), and opens it. Files downloaded with curl aren't
# marked "downloaded from the internet", so macOS opens the app without the "Open Anyway" step.
set -euo pipefail

URL="https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-mac.dmg"
APP="Paws Off.app"

major=$(sw_vers -productVersion | cut -d. -f1)
if [ "$major" -lt 14 ]; then
  echo "Paws Off needs macOS 14 (Sonoma) or later." >&2
  exit 1
fi

work=$(mktemp -d)
mount="$work/mount"
cleanup() {
  hdiutil detach -quiet "$mount" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

echo "🐾 Downloading Paws Off…"
curl -fL --progress-bar -o "$work/PawsOff.dmg" "$URL"
mkdir -p "$mount"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mount" "$work/PawsOff.dmg"

dest="/Applications"
[ -w "$dest" ] || { dest="$HOME/Applications"; mkdir -p "$dest"; }

# Replace any copy that's already there (quit it first).
if pgrep -x PawsOff >/dev/null; then
  osascript -e 'quit app "Paws Off"' >/dev/null 2>&1 || true
  sleep 1
  pkill -x PawsOff 2>/dev/null || true
fi
rm -rf "$dest/$APP"
ditto "$mount/$APP" "$dest/$APP"
xattr -dr com.apple.quarantine "$dest/$APP" 2>/dev/null || true

echo "🐾 Installed in $dest. Opening Paws Off…"
open "$dest/$APP"
cat <<'NEXT'

One last step, so Paws Off can pause your keyboard:
  1. In the Paws Off window, click Grant Access.
  2. Click Open System Settings, then switch on Paws Off (Touch ID or password).
  3. Done: look for the paw in your menu bar. Click it to lock your keyboard.
NEXT
