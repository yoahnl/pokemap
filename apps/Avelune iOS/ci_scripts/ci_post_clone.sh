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

# Pinned to the tag matching flutter_runtime/.metadata. Cloning the tag rather
# than the bare revision matters: Flutter derives its version with `git
# describe`, so a tagless checkout reports 0.0.0-unknown and pub refuses to
# solve. `flutter build swift-package` does not exist on stable yet.
FLUTTER_TAG="3.48.0-0.4.pre"
FLUTTER_DIR="$HOME/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

if [ ! -x "$FLUTTER_BIN" ]; then
  rm -rf "$FLUTTER_DIR"
  if ! git clone --depth 1 --branch "$FLUTTER_TAG" https://github.com/flutter/flutter.git "$FLUTTER_DIR"; then
    echo "Tag $FLUTTER_TAG indisponible, repli sur la pointe de beta."
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

if flutter --version | grep -q "0.0.0-unknown"; then
  echo "Flutter ne résout pas sa version : le clone est sans tag, pub refusera de résoudre."
  exit 1
fi

cd "$APP_DIR"
./tool/build_runtime.sh --no-codesign

PACKAGE_DIR="$APP_DIR/flutter_runtime/build/swift-package/FlutterNativeIntegration"
ln -sfn ./Release "$PACKAGE_DIR/FlutterPluginRegistrant"
test "$(readlink "$PACKAGE_DIR/FlutterPluginRegistrant")" = ./Release
nm -gU "$PACKAGE_DIR/FlutterPluginRegistrant/Frameworks/App.xcframework/ios-arm64/App.framework/App" | grep '_kDartSnapshotText' > /dev/null
