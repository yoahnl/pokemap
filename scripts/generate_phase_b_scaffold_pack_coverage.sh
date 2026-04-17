#!/usr/bin/env bash
set -euo pipefail

# Wrapper Phase B volontairement simple :
# - exporte d'abord le bootstrap embarqué courant depuis map_editor ;
# - mesure ensuite le pack d'import versionné avec le vrai bridge runtime ;
# - accepte en option un bootstrap baseline capturé avant le lift pour
#   documenter honnêtement le delta de ce run ;
# - écrit enfin le report markdown sous reports/.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_BOOTSTRAP_JSON="$(mktemp)"
trap 'rm -f "$CURRENT_BOOTSTRAP_JSON"' EXIT
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  echo "Flutter binary not found on PATH. Set FLUTTER_BIN if needed." >&2
  exit 1
fi

BASELINE_ARGS=()
if [[ $# -ge 1 ]]; then
  BASELINE_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  if command -v shasum >/dev/null 2>&1; then
    BASELINE_SHA="$(shasum -a 256 "$BASELINE_PATH" | awk "{print \$1}")"
  else
    BASELINE_SHA="$(sha256sum "$BASELINE_PATH" | awk "{print \$1}")"
  fi
  BASELINE_ARGS+=(
    --baseline-bootstrap-json "$BASELINE_PATH"
    --baseline-label "$BASELINE_PATH (sha256:$BASELINE_SHA)"
  )
fi

(
  cd "$REPO_ROOT/packages/map_editor"
  "$FLUTTER_BIN" pub run tool/export_embedded_pokemon_moves_bootstrap.dart > "$CURRENT_BOOTSTRAP_JSON"
)

(
  cd "$REPO_ROOT/packages/map_runtime"
  "$FLUTTER_BIN" pub run tool/phase_b_scaffold_pack_coverage.dart \
    --bootstrap-json "$CURRENT_BOOTSTRAP_JSON" \
    "${BASELINE_ARGS[@]}" \
    --import-pack "$REPO_ROOT/packages/map_editor/test/fixtures/manual_pokemon_import_pack_10" \
    --level 10 \
    --output "$REPO_ROOT/reports/phase-b-scaffold-pack-coverage.md"
)

echo "Coverage report written to $REPO_ROOT/reports/phase-b-scaffold-pack-coverage.md"
