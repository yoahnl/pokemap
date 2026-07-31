#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"

cd "$repo_root/packages/map_authoring"
dart test --reporter compact
dart analyze
dart run tool/pmcp085_conformance.dart >/dev/null

cd "$repo_root/packages/map_editor"
flutter test \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/authoring_api/editor_write_boundary_test.dart \
  test/authoring_api/no_bypass_guardrail_test.dart \
  --reporter compact
flutter analyze

cd "$repo_root/tools/pokemap_mcp"
npm run check
npm test

cd "$repo_root/packages/map_runtime"
flutter test \
  test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart \
  --reporter compact
flutter analyze

cd "$repo_root/examples/playable_runtime_host"
flutter test \
  test/evaluation/evaluation_authoring_job_service_test.dart \
  test/evaluation/evaluation_playtest_adapter_test.dart \
  --reporter compact
flutter analyze

# The generic editor adapter proves transport parity, not migration of every
# existing product gesture. Keep the production claim closed while PMCP-081's
# exact debt inventory remains in the editor guardrail.
editor_guard="$repo_root/packages/map_editor/test/authoring_api/editor_write_boundary_test.dart"
if grep -q 'const _legacyStructuredAuthoringDebt = <String>{' "$editor_guard"; then
  echo 'PMCP-085 BLOCKED: PMCP-081 editor mutation debt is still explicit.' >&2
  exit 1
fi

echo 'PMCP-085 release claim authorized.'
