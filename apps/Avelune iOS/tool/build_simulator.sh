#!/bin/bash
# Builds and installs the app on a booted iOS simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodebuild -project AveluneiOS.xcodeproj -scheme AveluneiOS -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath build/simulator build

APP="$ROOT/build/simulator/Build/Products/Debug-iphonesimulator/AveluneiOS.app"
xcrun simctl install booted "$APP"
echo "Installé : $APP"
echo "Lancer avec : xcrun simctl launch booted com.yoahnl.avelune.player"
