#!/bin/zsh
# Sends the app or the disk image to Apple's notary service, waits for the verdict and staples the
# ticket, so Gatekeeper opens it without a prompt, even offline.
#
#   Tools/notarize.sh "Paws Off.app"      (zipped for the upload; the app is stapled)
#   Tools/notarize.sh dist/PawsOff-mac.dmg
#
# Credentials: an App Store Connect API key, from APP_STORE_CONNECT_KEY (path to the .p8),
# APP_STORE_CONNECT_KEY_ID and APP_STORE_CONNECT_ISSUER_ID. Nothing here prints a secret.
set -euo pipefail
cd "$(dirname "$0")/.."

# notarytool and stapler ship with Xcode, which build.sh already prefers.
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p)" == *CommandLineTools* && -d /Applications/Xcode.app ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

TARGET="${1:?usage: Tools/notarize.sh <Paws Off.app or PawsOff-mac.dmg>}"
KEY=(--key "${APP_STORE_CONNECT_KEY:?APP_STORE_CONNECT_KEY is not set}"
     --key-id "${APP_STORE_CONNECT_KEY_ID:?APP_STORE_CONNECT_KEY_ID is not set}"
     --issuer "${APP_STORE_CONNECT_ISSUER_ID:?APP_STORE_CONNECT_ISSUER_ID is not set}")

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
UPLOAD="$TARGET"
if [[ "$TARGET" == *.app ]]; then
  UPLOAD="$WORK/PawsOff.zip"
  ditto -c -k --keepParent "$TARGET" "$UPLOAD"
fi

echo "Notarizing ${TARGET:t}…"
xcrun notarytool submit "$UPLOAD" "${KEY[@]}" --wait --timeout 30m --output-format json > "$WORK/notary.json"
read -r STATUS ID < <(python3 -c 'import json, sys; d = json.load(open(sys.argv[1])); print(d.get("status", ""), d.get("id", ""))' "$WORK/notary.json")
if [[ "$STATUS" != Accepted ]]; then
  echo "Apple answered: ${STATUS:-no answer} (submission $ID). The log:" >&2
  xcrun notarytool log "$ID" "${KEY[@]}" >&2 || true
  exit 1
fi
xcrun stapler staple "$TARGET" >/dev/null
echo "Notarized and stapled ${TARGET:t} (submission $ID)"
