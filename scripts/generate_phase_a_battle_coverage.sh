#!/usr/bin/env bash
set -euo pipefail

# Wrapper Phase A volontairement simple :
# - exporte d'abord la vraie vérité bootstrap depuis map_editor ;
# - puis demande à map_runtime de mesurer le vrai golden slice versionné ;
# - écrit enfin le report markdown sous reports/.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_JSON="$(mktemp)"
trap 'rm -f "$BOOTSTRAP_JSON"' EXIT

(
  cd "$REPO_ROOT/packages/map_editor"
  /opt/homebrew/bin/flutter pub run tool/export_embedded_pokemon_moves_bootstrap.dart > "$BOOTSTRAP_JSON"
)

(
  cd "$REPO_ROOT/packages/map_runtime"
  /opt/homebrew/bin/flutter pub run tool/phase_a_battle_coverage.dart \
    --bootstrap-json "$BOOTSTRAP_JSON" \
    --project "$REPO_ROOT/examples/playable_runtime_host/golden_battle_slice/project.json" \
    --save "$REPO_ROOT/examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json" \
    --output "$REPO_ROOT/reports/phase-a-battle-coverage.md"
)

echo "Coverage report written to $REPO_ROOT/reports/phase-a-battle-coverage.md"
