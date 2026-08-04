#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
erw_root="${POKEMAP_ERW_ROOT:-}"
if [[ -z "$erw_root" || ! -d "$erw_root" ]]; then
  echo "STN-11 ERW: set POKEMAP_ERW_ROOT to the licensed pack root." >&2
  exit 64
fi
erw_root="$(cd "$erw_root" && pwd -P)"
tiled_root="$erw_root/TiledMap Editor"
tileset_root="$tiled_root/Tilesets"
if [[ ! -d "$tileset_root" ]]; then
  echo "STN-11 ERW: TiledMap Editor/Tilesets is missing." >&2
  exit 66
fi

wang_tsx=""
while IFS= read -r candidate; do
  if grep -q '<wangset' "$candidate"; then
    wang_tsx="$candidate"
    break
  fi
done < <(find "$tileset_root" -type f -name '*.tsx' -print | LC_ALL=C sort)
if [[ -z "$wang_tsx" ]]; then
  echo "STN-11 ERW: no Wang TSX was found." >&2
  exit 66
fi

forest_png="$(
  find "$erw_root" -type f -iname '*tree*.png' -print |
    LC_ALL=C sort |
    sed -n '1p'
)"
if [[ -z "$forest_png" ]]; then
  echo "STN-11 ERW: no tree PNG was found." >&2
  exit 66
fi

tsx_count="$(find "$tileset_root" -type f -name '*.tsx' | wc -l | tr -d ' ')"
tmx_count="$(find "$tiled_root" -type f -name '*.tmx' | wc -l | tr -d ' ')"
png_count="$(find "$erw_root" -type f -iname '*.png' | wc -l | tr -d ' ')"
before_status="$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all)"

echo "STN-11 ERW inventory: TSX=$tsx_count TMX=$tmx_count PNG=$png_count"
echo "STN-11 ERW 1/4: generic finite TMX corpus"
(
  cd "$repo_root/packages/map_core"
  POKEMAP_TMX_CORPUS_ROOT="$tiled_root" \
    dart test test/smart_tiles/tiled_map_local_corpus_test.dart
)

echo "STN-11 ERW 2/4: four image collections and durable reopen"
(
  cd "$repo_root/packages/map_editor"
  POKEMAP_ERW_ROOT="$erw_root" \
    flutter test \
      test/smart_tiles_studio/smart_tile_tiled_wang_import_service_test.dart \
      --plain-name \
      'imports and reopens all four locally licensed ERW image collections'
)

echo "STN-11 ERW 3/4: Wang atlas compilation"
(
  cd "$repo_root/packages/map_editor"
  POKEMAP_STN07_ERW_TSX="$wang_tsx" \
    flutter test \
      test/smart_tiles_studio/smart_tile_tiled_wang_import_service_test.dart \
      --plain-name \
      'accepts a user-owned ERW Wang atlas without copying licensed assets'
)

echo "STN-11 ERW 4/4: organic forest projection"
(
  cd "$repo_root/packages/map_editor"
  POKEMAP_STN07_ERW_FOREST_PNG="$forest_png" \
    flutter test \
      test/smart_tiles_studio/smart_tile_stn07_organic_forest_golden_workflow_test.dart \
      --plain-name \
      'projects a user-owned ERW tree into canopy, trunk and collision masks'
)

after_status="$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all)"
if [[ "$after_status" != "$before_status" ]]; then
  echo "STN-11 ERW: the campaign changed the Git worktree." >&2
  diff <(printf '%s\n' "$before_status") <(printf '%s\n' "$after_status") || true
  exit 1
fi
echo "STN-11 ERW: PASS; licensed inputs stayed outside the Git worktree."
