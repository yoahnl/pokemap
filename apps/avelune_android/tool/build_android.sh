#!/usr/bin/env bash
set -euo pipefail

avelune_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
if [[ -z "${JAVA_HOME:-}" && -x /usr/libexec/java_home ]]; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
fi

if [[ ! -d "$ANDROID_HOME/platforms/android-36" ]]; then
    printf '%s\n' "Android SDK 36 is required. Set ANDROID_HOME to its SDK directory." >&2
    exit 1
fi

if [[ ! -f "$avelune_root/flutter_runtime/build/host/outputs/repo/com/yoahnl/avelune/runtime/android/flutter_debug/1.0/flutter_debug-1.0.pom" ]]; then
    printf '%s\n' "Build the shared runtime first: bash apps/avelune_android/tool/build_runtime.sh" >&2
    exit 1
fi

native_has_task=false
for native_argument in "$@"; do
    if [[ "$native_argument" != -* ]]; then
        native_has_task=true
    fi
done
if [[ "$native_has_task" == false ]]; then
    set -- :host_core:test :app:testDebugUnitTest :app:assembleDebug "$@"
fi

exec "$avelune_root/gradlew" -p "$avelune_root" --console=plain "$@"
