#!/bin/bash
# Rebuilds the Flutter runtime as a Swift package and regenerates the Xcode project.
#
# `flutter build swift-package` is the CocoaPods-free integration path: plugins
# resolve through Swift Package Manager. It needs a regular Flutter project, not
# an add-to-app module, because the tool disables SPM for modules
# (xcode_project.dart, flutter/flutter#146957).
#
# Extra arguments are forwarded to the Flutter command; CI passes --no-codesign.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$ROOT/flutter_runtime/build/swift-package"
CONFIGURATION="${CONFIGURATION-Debug}"
case "$CONFIGURATION" in
  Debug) FLUTTER_BUILD_MODE=debug ;;
  Release) FLUTTER_BUILD_MODE=release ;;
  *) echo "Unsupported CONFIGURATION: $CONFIGURATION. Use Debug or Release." >&2; exit 2 ;;
esac

cd "$ROOT/flutter_runtime"
flutter pub get
python3 "$ROOT/tool/patch_flutter_gpu.py"

# The tool rsyncs into <mode>/Frameworks without creating the parent first.
rm -rf "$OUTPUT"
mkdir -p "$OUTPUT/FlutterNativeIntegration/Debug/Frameworks"
mkdir -p "$OUTPUT/FlutterNativeIntegration/Release/Frameworks"

flutter build swift-package \
  --platform ios \
  --build-mode debug \
  --build-mode release \
  -o "$OUTPUT" \
  "$@"

python3 "$ROOT/tool/patch_swift_package.py" "$OUTPUT"
CONFIGURATION="$CONFIGURATION" FLUTTER_BUILD_MODE="$FLUTTER_BUILD_MODE" \
  FLUTTER_SWIFT_PACKAGE_OUTPUT="$OUTPUT" \
  /bin/bash "$OUTPUT/Scripts/flutter_integration.sh" prebuild

cd "$ROOT"
if command -v xcodegen > /dev/null; then
  xcodegen generate
else
  echo "xcodegen absent, le projet Xcode existant est conservé."
fi
