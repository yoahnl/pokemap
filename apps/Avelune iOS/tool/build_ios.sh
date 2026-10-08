#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION-Debug}"
case "$CONFIGURATION" in
  Debug) FLUTTER_BUILD_MODE=debug ;;
  Release) FLUTTER_BUILD_MODE=release ;;
  *) echo "Unsupported CONFIGURATION: $CONFIGURATION. Use Debug or Release." >&2; exit 2 ;;
esac

for argument in "$@"; do
  case "$argument" in
    -configuration|-configuration=*|CONFIGURATION=*|FLUTTER_BUILD_MODE=*|FLUTTER_SWIFT_PACKAGE_OUTPUT=*)
      echo "Set CONFIGURATION=Debug or CONFIGURATION=Release in the environment; Flutter build settings are selected by the pipeline." >&2
      exit 2 ;;
  esac
done

FLUTTER_SWIFT_PACKAGE_OUTPUT="$ROOT/flutter_runtime/build/swift-package"
if [[ ! -f "$FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh" ]]; then
  echo "Flutter Swift package is missing. Run tool/build_runtime.sh first." >&2
  exit 1
fi
export CONFIGURATION FLUTTER_BUILD_MODE FLUTTER_SWIFT_PACKAGE_OUTPUT
/bin/bash "$FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh" prebuild

exec xcodebuild -project "$ROOT/AveluneiOS.xcodeproj" -scheme AveluneiOS \
  -configuration "$CONFIGURATION" -destination 'generic/platform=iOS' \
  -derivedDataPath "$ROOT/build/native/$CONFIGURATION" \
  "$@" CODE_SIGNING_ALLOWED=NO build
