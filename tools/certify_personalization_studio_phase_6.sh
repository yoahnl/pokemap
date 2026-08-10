#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
phase6_tmp="$(mktemp -d "${TMPDIR:-/tmp}/pokemap-phase6-studio.XXXXXX")"

cleanup() {
  if [[ -n "${phase6_tmp:-}" && -d "$phase6_tmp" ]]; then
    rm -rf "$phase6_tmp"
  fi
}
trap cleanup EXIT

package_path="$phase6_tmp/aube.avelunegame"

(
  cd "$repository_root/packages/map_editor"
  POKEMAP_PHASE6_PACKAGE_OUTPUT="$package_path" \
    flutter test \
      test/personalization/phase_6_personalization_studio_restart_e2e_test.dart \
      test/personalization/phase_6_personalization_studio_export_e2e_test.dart \
      --reporter expanded
)

(
  cd "$repository_root/apps/pokemap_hub"
  POKEMAP_PHASE6_PACKAGE_INPUT="$package_path" \
    flutter test \
      test/presentation/features/player/phase_6_personalization_packaging_e2e_test.dart \
      --reporter expanded
)

(
  cd "$repository_root/examples/playable_runtime_host"
  flutter test \
    test/phase_a_golden_slice_launch_test.dart \
    --reporter expanded
)
