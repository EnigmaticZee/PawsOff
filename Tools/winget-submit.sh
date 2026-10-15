#!/bin/zsh
# Submits a released version of Paws Off to winget (Microsoft's package list) as a pull request to
# microsoft/winget-pkgs, using the GitHub CLI (`gh`, signed in). Run after a release is published:
#   Tools/winget-submit.sh 2.0.0
# It works through GitHub's API (no clone of the huge winget-pkgs repo): it keeps a fork in your
# account, writes the three manifest files on a new branch there, and opens the pull request.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=${1:?usage: Tools/winget-submit.sh <version>}
GH=${GH:-gh}
OWNER=$($GH api user --jq .login)
ID="EnigmaticZee.PawsOff"
URL="https://github.com/EnigmaticZee/PawsOff/releases/download/v${VERSION}/PawsOff-Windows-Setup.exe"
DIR="manifests/e/EnigmaticZee/PawsOff/${VERSION}"
BRANCH="paws-off-${VERSION}"

echo "Hashing the released installer…"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/setup.exe" "$URL"
SHA=$(shasum -a 256 "$TMP/setup.exe" | cut -d' ' -f1 | tr 'a-f' 'A-F')

render() { sed -e "s/{VERSION}/${VERSION}/g" -e "s#{URL}#${URL}#g" -e "s/{SHA256}/${SHA}/g" "$1"; }

echo "Preparing your fork of microsoft/winget-pkgs…"
$GH repo fork microsoft/winget-pkgs --clone=false >/dev/null 2>&1 || true
$GH repo sync "$OWNER/winget-pkgs" --source microsoft/winget-pkgs >/dev/null
BASE=$($GH api "repos/$OWNER/winget-pkgs/git/ref/heads/master" --jq .object.sha)
$GH api "repos/$OWNER/winget-pkgs/git/refs" -f ref="refs/heads/$BRANCH" -f sha="$BASE" >/dev/null

for f in "$ID.yaml" "$ID.installer.yaml" "$ID.locale.en-US.yaml"; do
  render "packaging/winget/$f" > "$TMP/$f"
  $GH api -X PUT "repos/$OWNER/winget-pkgs/contents/$DIR/$f" \
    -f message="Add $ID $VERSION" -f branch="$BRANCH" \
    -f content="$(base64 < "$TMP/$f" | tr -d '\n')" >/dev/null
done

if $GH api "repos/microsoft/winget-pkgs/contents/manifests/e/EnigmaticZee/PawsOff" >/dev/null 2>&1; then
  TITLE="New version: $ID version $VERSION"
else
  TITLE="New package: $ID version $VERSION"
fi
$GH pr create --repo microsoft/winget-pkgs --head "$OWNER:$BRANCH" --title "$TITLE" \
  --body "Paws Off pauses your keyboard with one click, for cleaning it or keeping pets off it. Installer: Inno Setup, per-user, from the official GitHub release."
