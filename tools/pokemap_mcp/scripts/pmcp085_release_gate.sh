#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
qa_parent="${AVELUNE_QA_ROOT:-${TMPDIR:-/tmp}}"
proof_root="$(mktemp -d "${qa_parent%/}/pokemap-pmcp085.XXXXXX")"
trap 'rm -rf -- "$proof_root"' EXIT
source_revision="$(git -C "$repo_root" rev-parse HEAD)"
certification_directory="$repo_root/tools/pokemap_product_certification"
transport_receipts="$proof_root/item-transports.json"

cd "$certification_directory"
dart run bin/certify_item_system_v1.dart \
  --output "$proof_root/item-certification.json" \
  --transport-receipts-out "$transport_receipts"

cd "$repo_root/packages/map_authoring"
dart test --reporter compact
dart analyze

cd "$repo_root/packages/map_editor"
flutter test \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/authoring_api/editor_write_boundary_test.dart \
  test/authoring_api/no_bypass_guardrail_test.dart \
  --reporter compact
flutter analyze

cd "$repo_root/tools/pokemap_mcp"
npm run check
AVELUNE_QA_ROOT="$proof_root" npm test

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

release_status=0
transport_args=(--source-revision "$source_revision")
cd "$certification_directory"
for recipe in "$certification_directory"/test/fixtures/pmcp085_*/scenarios.json; do
  fixture_directory="${recipe%/*}"
  projects="$fixture_directory/projects"
  output="$proof_root/${fixture_directory##*/}-transports.json"
  if ! dart run bin/certify_authoring_transports.dart \
    --recipes "$recipe" --fixtures "$projects" --qa-root "$proof_root" \
    --source-revision "$source_revision" --out "$output"; then
    release_status=1
  fi
  if [[ -f "$output" ]]; then
    transport_args+=(--transport-run "$output" "$recipe" "$projects")
  fi
done

cd "$repo_root/packages/map_authoring"
if ! dart run tool/pmcp085_conformance.dart \
  --transport-receipts "$transport_receipts" --require-transports \
  "${transport_args[@]}" >/dev/null; then
  release_status=1
fi

editor_guard="$repo_root/packages/map_editor/test/authoring_api/editor_write_boundary_test.dart"
if grep -q 'const _legacyStructuredAuthoringDebt = <String>{' "$editor_guard"; then
  echo 'PMCP-085 BLOCKED: PMCP-081 editor mutation debt is still explicit.' >&2
  release_status=1
fi

if [[ "$release_status" != 0 ]]; then
  exit "$release_status"
fi
echo 'PMCP-085 release claim authorized.'
