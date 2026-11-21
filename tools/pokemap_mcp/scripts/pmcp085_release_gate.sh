#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
qa_parent="${AVELUNE_QA_ROOT:-$HOME/Library/Caches/AveluneQA}"
if [[ $# != 0 && ( $# != 2 || $1 != --evidence-dir || -z $2 ) ]]; then
  echo 'Usage: pmcp085_release_gate.sh [--evidence-dir <new-directory>]' >&2
  exit 64
fi
mkdir -p -- "$qa_parent"
qa_parent="$(cd "$qa_parent" && pwd -P)"
proof_root="$(mktemp -d "${qa_parent%/}/pokemap-pmcp085.XXXXXX")"
trap 'rm -rf -- "$proof_root"' EXIT
mkdir "$proof_root/tmp"
export TMPDIR="$proof_root/tmp"
export AVELUNE_QA_ROOT="$proof_root"

evidence_dir="$proof_root"
if [[ $# == 2 ]]; then
  mkdir -- "$2"
  evidence_dir="$(cd "$2" && pwd -P)"
fi
source_revision="$(git -C "$repo_root" rev-parse HEAD)"
certification_directory="$repo_root/tools/pokemap_product_certification"
transport_receipts="$evidence_dir/item-transports.json"
fixtures_directory="$certification_directory/test/fixtures"

for family in characters maps projects story; do
  if [[ ! -f "$fixtures_directory/pmcp085_$family/scenarios.json" ]]; then
    echo "PMCP-085 missing scenario family: $family" >&2
    exit 1
  fi
done

(cd "$repo_root/packages/map_authoring" && dart pub get)
(cd "$repo_root/apps/avelune_studio" && flutter pub get)
(cd "$repo_root/tools/pokemap_mcp" && npm run check && npm run build)

cd "$certification_directory"
flutter pub get
dart run bin/certify_item_system_v1.dart \
  --skip-mcp-build --output "$evidence_dir/item-certification.json" \
  --transport-receipts-out "$transport_receipts"

release_status=0
transport_args=(--source-revision "$source_revision")
for recipe in "$fixtures_directory"/pmcp085_*/scenarios.json; do
  fixture_directory="${recipe%/*}"
  projects="$fixture_directory/projects"
  output="$proof_root/${fixture_directory##*/}-transports.json"
  if dart run bin/certify_authoring_transports.dart \
    --recipes "$recipe" --fixtures "$projects" --qa-root "$proof_root" \
    --source-revision "$source_revision" --out "$output" && [[ -s "$output" ]]; then
    transport_args+=(--transport-run "$output" "$recipe" "$projects")
    if [[ "$evidence_dir" != "$proof_root" ]]; then
      cp -- "$output" "$evidence_dir/"
    fi
  else
    echo "PMCP-085 did not produce proof for ${fixture_directory##*/}." >&2
    release_status=1
  fi
done

cd "$repo_root/packages/map_authoring"
if ! dart run tool/pmcp085_conformance.dart \
  --transport-receipts "$transport_receipts" --require-transports \
  "${transport_args[@]}" > "$evidence_dir/conformance.json"; then
  release_status=1
fi

cd "$repo_root/apps/avelune_studio"
flutter test --no-pub --reporter failures-only \
  test/map_workspace/map_catalog_transaction_guard_test.dart \
  test/infrastructure/project_settings_transport_test.dart \
  test/infrastructure/narrative_batch_transport_test.dart \
  test/scenes/scene_graph_patch_publication_test.dart \
  test/presentations/presentation_adapter_ui11_test.dart

if [[ "$release_status" != 0 ]]; then
  exit "$release_status"
fi

cd "$repo_root/packages/map_authoring"
dart test --reporter failures-only
dart analyze

cd "$repo_root/apps/avelune_studio"
flutter analyze --no-pub

cd "$repo_root/tools/pokemap_mcp"
npm test

cd "$repo_root/packages/map_runtime"
flutter test --reporter failures-only \
  test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart
flutter analyze

cd "$repo_root/examples/playable_runtime_host"
flutter test --reporter failures-only \
  test/evaluation/evaluation_authoring_job_service_test.dart \
  test/evaluation/evaluation_playtest_adapter_test.dart
flutter analyze

echo 'PMCP-085 release claim authorized.'
