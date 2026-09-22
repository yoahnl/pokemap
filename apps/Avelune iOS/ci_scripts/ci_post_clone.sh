#!/bin/zsh
# Xcode Cloud post-clone hook, run before package dependencies are resolved.
#
# The Xcode project depends on a local Swift package that is a build artifact
# weighing over a gigabyte, so it cannot live in the repository. Flutter is
# installed here and the package is produced on the spot.
set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Pinned to flutter_runtime/.metadata: `flutter build swift-package` does not
# exist on stable yet.
FLUTTER_REVISION="e3005e3402d9cfa2043114c8bc53c59d12e9b98e"
FLUTTER_DIR="$HOME/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

if [ ! -x "$FLUTTER_BIN" ]; then
  rm -rf "$FLUTTER_DIR"
  git init --quiet "$FLUTTER_DIR"
  git -C "$FLUTTER_DIR" remote add origin https://github.com/flutter/flutter.git
  if git -C "$FLUTTER_DIR" fetch --depth 1 --quiet origin "$FLUTTER_REVISION"; then
    git -C "$FLUTTER_DIR" checkout --quiet FETCH_HEAD
  else
    echo "Révision épinglée indisponible, repli sur la pointe de beta."
    rm -rf "$FLUTTER_DIR"
    git clone --depth 1 --branch beta https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

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
}

if [ -n "${FLUTTER_STORAGE_BASE_URL:-}" ]; then
  run_flutter_bootstrap "$FLUTTER_STORAGE_BASE_URL"
else
  run_flutter_bootstrap "" || run_flutter_bootstrap "https://storage.flutter-io.cn"
fi

cd "$APP_DIR"
./tool/build_runtime.sh --no-codesign
