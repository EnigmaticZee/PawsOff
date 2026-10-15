#!/bin/zsh
# Builds "Paws Off.app" into the project root.
# Usage: ./build.sh            (uses the version in VERSION)
#        ./build.sh 1.1.0      (sets VERSION to 1.1.0, then builds)
#        UNIVERSAL=1 ./build.sh (Apple Silicon + Intel, used for releases)
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# -ge 1 ]]; then echo "$1" > VERSION; fi
VERSION=$(cat VERSION)
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo 1)

APP="Paws Off.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

if [[ "${UNIVERSAL:-0}" == 1 ]]; then ARCHS=(arm64 x86_64); else ARCHS=($(uname -m)); fi
SLICES=()
for arch in $ARCHS; do
  mkdir -p build
  xcrun swiftc -O -swift-version 5 -parse-as-library \
    -target "$arch-apple-macos14.0" \
    Sources/*.swift -o "build/PawsOff-$arch"
  SLICES+=("build/PawsOff-$arch")
done
lipo -create $SLICES -output "$APP/Contents/MacOS/PawsOff"

# Icon is committed in Assets/; regenerate it with Tools/make-icon.swift (see README).
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Paws Off</string>
  <key>CFBundleDisplayName</key><string>Paws Off</string>
  <key>CFBundleIdentifier</key><string>local.pawsoff</string>
  <key>CFBundleExecutable</key><string>PawsOff</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Made by Zaid</string>
</dict>
</plist>
PLIST

# Ad-hoc signature with a stable requirement: macOS ties the Accessibility grant to the
# designated requirement, and the default ad-hoc one (cdhash) changes on every build.
codesign --force --sign - -r='designated => identifier "local.pawsoff"' "$APP"
echo "Built $APP $VERSION ($BUILD_NUMBER)"
