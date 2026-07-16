#!/bin/zsh
# Wraps the SwiftPM-built Wisp binary into a real Wisp.app bundle.
#
# WHY: several TCC permission classes (Speech Recognition especially) hard-abort a bare
# terminal-launched binary that requests them, and permission grants stick better to a stable
# .app identity than to whatever terminal happened to run `swift run`. This produces
# dist/Wisp.app — grant permissions to THAT and they survive rebuilds (the bundle id and
# ad-hoc signature stay stable).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
APP_DIR="$REPO_ROOT/dist/Wisp.app"

echo "Building Wisp…"
cd "$REPO_ROOT/Wisp"
swift build -c release

echo "Assembling $APP_DIR…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$REPO_ROOT/Wisp/.build/release/Wisp" "$APP_DIR/Contents/MacOS/Wisp"
cp "$REPO_ROOT/Wisp/Supporting/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Wisp" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$APP_DIR/Contents/Info.plist" 2>/dev/null || true

echo "Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP_DIR"

echo
echo "Done: $APP_DIR"
echo "Run it with:  open '$APP_DIR'"
echo "The sidecar venv is found relative to the CWD; launch from the repo root, or set"
echo "WISP_SIDECAR_PATH=$REPO_ROOT/voice-sidecar/parakeet_stt.py"
