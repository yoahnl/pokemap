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
BUILD_MODES=(--build-mode debug --build-mode release)
BUILD_CONFIGURATIONS=(Debug Release)
case "$CONFIGURATION" in
  Debug) FLUTTER_BUILD_MODE=debug ;;
  Profile)
    FLUTTER_BUILD_MODE=profile
    BUILD_MODES=(--build-mode profile)
    BUILD_CONFIGURATIONS=(Profile)
    ;;
  Release) FLUTTER_BUILD_MODE=release ;;
  *) echo "Unsupported CONFIGURATION: $CONFIGURATION. Use Debug, Profile or Release." >&2; exit 2 ;;
esac

cd "$ROOT/flutter_runtime"
flutter pub get
python3 "$ROOT/tool/patch_flutter_gpu.py"

# The tool rsyncs into <mode>/Frameworks without creating the parent first.
rm -rf "$OUTPUT"
for build_configuration in "${BUILD_CONFIGURATIONS[@]}"; do
  mkdir -p "$OUTPUT/FlutterNativeIntegration/$build_configuration/Frameworks"
done

flutter build swift-package \
  --platform ios \
  "${BUILD_MODES[@]}" \
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
