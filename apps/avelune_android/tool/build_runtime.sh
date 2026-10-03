#!/usr/bin/env bash
set -euo pipefail

runtime_root="$(cd "$(dirname "$0")/.." && pwd)"
runtime_mode="${1:-debug}"
case "$runtime_mode" in
  debug) runtime_task="assembleAarDebug" ;;
  profile) runtime_task="assembleAarProfile" ;;
  release) runtime_task="assembleAarRelease" ;;
  *) echo 'Usage: bash tool/build_runtime.sh [debug|profile|release]' >&2; exit 2 ;;
esac

runtime_flutter="${AVELUNE_FLUTTER_BIN:-flutter}"
cd "$runtime_root/flutter_runtime"
"$runtime_flutter" pub get
rm -rf -- .ios
runtime_sdk="$(sed -n 's/^flutter.sdk=//p' .android/local.properties)"
bash "$runtime_root/gradlew" \
  --no-daemon \
  -p "$runtime_root/flutter_runtime/.android" \
  -I "$runtime_root/tool/runtime_gradle_override.gradle" \
  -I "$runtime_sdk/packages/flutter_tools/gradle/aar_init_script.gradle" \
  -Pflutter-root="$runtime_sdk" \
  -Poutput-dir="$runtime_root/flutter_runtime/build/host" \
  -Pis-plugin=false \
  -PbuildNumber=1.0 \
  -Ptarget=lib/main.dart \
  -Ptarget-platform=android-arm64 \
  -Pdart-obfuscation=false \
  -Ptrack-widget-creation=true \
  -Ptree-shake-icons=false \
  "$runtime_task"
