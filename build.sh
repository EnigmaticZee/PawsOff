#!/bin/zsh
# Builds "Paws Off.app" into the project root.
# Usage: ./build.sh            (uses the version in VERSION)
#        ./build.sh 1.1.0      (sets VERSION to 1.1.0, then builds)
#        UNIVERSAL=1 ./build.sh (Apple Silicon + Intel, used for releases)
set -euo pipefail
cd "$(dirname "$0")"

# SwiftUI's macros ship with Xcode, not the Command Line Tools, so use Xcode when it's installed.
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p)" == *CommandLineTools* && -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

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
    -F Vendor/Sparkle -framework Sparkle -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    Sources/*.swift -o "build/PawsOff-$arch"
  SLICES+=("build/PawsOff-$arch")
done
lipo -create $SLICES -output "$APP/Contents/MacOS/PawsOff"

# Sparkle (automatic updates), bundled in Vendor/Sparkle. See docs/DEVELOPMENT.md.
mkdir -p "$APP/Contents/Frameworks"
ditto Vendor/Sparkle/Sparkle.framework "$APP/Contents/Frameworks/Sparkle.framework"

# Icon is committed in Assets/; regenerate every copy with Tools/make-icons.sh.
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
  <!-- Updates: Sparkle reads the feed from the latest GitHub release and only installs updates
       signed with the matching private key (kept in the release workflow's secrets). -->
  <key>SUFeedURL</key><string>https://github.com/EnigmaticZee/PawsOff/releases/latest/download/appcast.xml</string>
  <key>SUPublicEDKey</key><string>AWihztekrNYm4LajURAnfH/LVfMNto0710fljAbVhP8=</string>
  <key>SUEnableAutomaticChecks</key><true/>
  <key>SUAutomaticallyUpdate</key><true/>
  <!-- Starts as a menu bar app (no Dock icon); the window brings the Dock icon back while open. -->
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc signature with a stable requirement: macOS ties the Accessibility grant to the
# designated requirement, and the default ad-hoc one (cdhash) changes on every build.
# Sign Sparkle's helpers inside-out, then the app.
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
for part in "$SPARKLE"/XPCServices/*.xpc "$SPARKLE/Autoupdate" "$SPARKLE/Updater.app" "$APP/Contents/Frameworks/Sparkle.framework"; do
  codesign --force --sign - "$part"
done
codesign --force --sign - -r='designated => identifier "local.pawsoff"' "$APP"
echo "Built $APP $VERSION ($BUILD_NUMBER)"
