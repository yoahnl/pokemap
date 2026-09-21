#!/bin/bash
# Builds and installs the app on a booted iOS simulator.
#
# project.yml embeds the Release frameworks, whose simulator slice carries no
# Dart snapshot: the app launches but the runtime never boots. Simulator runs
# therefore need a throwaway project pointing at the Debug frameworks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DERIVED="${ROOT}/build/simulator"
SPEC="project.simulator.yml"
PROJECT="AveluneiOSSimulator.xcodeproj"

trap 'rm -rf "$SPEC" "$PROJECT"' EXIT

sed -e 's/^name: AveluneiOS$/name: AveluneiOSSimulator/' \
    -e 's#framework/Release#framework/Debug#g' \
    project.yml > "$SPEC"

xcodegen generate --spec "$SPEC" > /dev/null
xcodebuild -project "$PROJECT" -scheme AveluneiOS -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" build

APP="${DERIVED}/Build/Products/Debug-iphonesimulator/AveluneiOS.app"
xcrun simctl install booted "$APP"
echo "Installé : $APP"
echo "Lancer avec : xcrun simctl launch booted com.avelune.ios"
