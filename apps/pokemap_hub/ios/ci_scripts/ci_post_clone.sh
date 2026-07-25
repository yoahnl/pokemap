#!/bin/zsh
set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$IOS_DIR/.." && pwd)"

FLUTTER_DIR="$HOME/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

if [ ! -x "$FLUTTER_BIN" ]; then
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

cd "$PROJECT_ROOT"

# Xcode Cloud occasionally reaches GitHub while failing to reach Flutter's
# default artifact bucket. Retry with Flutter's official mirror only if the
# default download fails, while allowing an explicit CI override.
run_flutter_bootstrap() {
  local storage_base_url="${1:-}"

  rm -rf "$FLUTTER_DIR/bin/cache/dart-sdk"
  rm -rf "$FLUTTER_DIR/bin/cache/downloads"
  rm -rf "$FLUTTER_DIR/bin/cache/artifacts"

  if [ -n "$storage_base_url" ]; then
    export FLUTTER_STORAGE_BASE_URL="$storage_base_url"
    echo "Using Flutter storage: $FLUTTER_STORAGE_BASE_URL"
  else
    unset FLUTTER_STORAGE_BASE_URL
    echo "Using default Flutter storage"
  fi

  flutter --version || return 1
  flutter config --no-analytics || return 1
  flutter config --enable-swift-package-manager || return 1
  flutter precache --ios || return 1
  flutter pub get || return 1
}

if [ -n "${FLUTTER_STORAGE_BASE_URL:-}" ]; then
  run_flutter_bootstrap "$FLUTTER_STORAGE_BASE_URL"
else
  run_flutter_bootstrap "" || run_flutter_bootstrap "https://storage.flutter-io.cn"
fi

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -n 1 | sed -E 's/^version:[[:space:]]*//' || true)"
VERSION_NAME="${VERSION_LINE%%+*}"
APP_VERSION="${APP_VERSION:-$VERSION_NAME}"

if [ -z "$APP_VERSION" ]; then
  APP_VERSION="1.0.0"
fi

BUILD_NUMBER="${BUILD_NUMBER:-${CI_BUILD_NUMBER:-$(date +%Y%m%d%H%M)}}"
BUILD_NUMBER="$(printf "%s" "$BUILD_NUMBER" | tr -cd '0-9')"

if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER="$(date +%Y%m%d%H%M)"
fi

# Flutter regenerates this ignored directory for the Xcode target. Starting
# from a clean copy prevents stale plugin metadata from reaching SwiftPM.
rm -rf "$IOS_DIR/Flutter/ephemeral"
rm -f "$IOS_DIR/Flutter/Generated.xcconfig"
rm -f "$IOS_DIR/Flutter/flutter_export_environment.sh"

flutter build ios \
  --config-only \
  --release \
  --no-codesign \
  --build-name "$APP_VERSION" \
  --build-number "$BUILD_NUMBER"

echo "Resolved iOS version: $APP_VERSION"
echo "Resolved iOS build number: $BUILD_NUMBER"
grep -E 'FLUTTER_BUILD_NAME|FLUTTER_BUILD_NUMBER' "$IOS_DIR/Flutter/Generated.xcconfig"
