#!/usr/bin/env bash
# Build AgentDock.app (universal, ad-hoc signed) and a distributable zip.
# Usage: scripts/build-app.sh [version]   (defaults to latest git tag or 0.0.0)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0}"

DIST="$REPO_ROOT/dist"
APP="$DIST/AgentDock.app"
ZIP="$DIST/AgentDock-$VERSION.zip"

echo "Building AgentDock ${VERSION}…"
swift build -c release --arch arm64 --arch x86_64

BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/AgentDock"

rm -rf "$APP" "$ZIP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/AgentDock"
sed "s/__VERSION__/$VERSION/g" "$REPO_ROOT/scripts/Info.plist" > "$APP/Contents/Info.plist"

codesign --force --sign - "$APP"

ditto -c -k --keepParent "$APP" "$ZIP"
shasum -a 256 "$ZIP" | tee "$ZIP.sha256"

echo "Built $APP"
echo "Zipped $ZIP"
