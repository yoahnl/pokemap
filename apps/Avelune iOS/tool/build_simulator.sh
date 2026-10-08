#!/bin/bash
# Builds and installs the app on a booted iOS simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CONFIGURATION=Debug FLUTTER_BUILD_MODE=debug \
    FLUTTER_SWIFT_PACKAGE_OUTPUT="$ROOT/flutter_runtime/build/swift-package" \
    /bin/bash "$ROOT/flutter_runtime/build/swift-package/Scripts/flutter_integration.sh" prebuild

xcodebuild -project AveluneiOS.xcodeproj -scheme AveluneiOS -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath build/simulator build

APP="$ROOT/build/simulator/Build/Products/Debug-iphonesimulator/AveluneiOS.app"
xcrun simctl install booted "$APP"
echo "Installé : $APP"
echo "Lancer avec : xcrun simctl launch booted com.yoahnl.avelune.player"
