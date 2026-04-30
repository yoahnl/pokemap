# PathPattern Roadmap

Date: 2026-04-30

## Decision

The active product direction is now deliberately small:

```text
Path Studio.
Center multi-cell pattern.
Then tall grass.
Nothing else.
```

This roadmap does not recreate Surface Studio and does not use TSX, TMX,
Pokemon SDK imports, Mistral, PixelLab, MCP, or external map import flows as
product objectives.

## Starting Point

Surface Studio and the TSX authoring workspace were purged from the active
editor UI. The useful foundations remain:

- `packages/map_core` Surface models;
- `ProjectManifest.surfaceCatalog`;
- `SurfaceLayer`;
- Surface Painter;
- existing runtime Surface support;
- existing Surface to GameplayZone bridge.

The new work should build on the system that already behaves best in the
editor: Path / Path Painter.

## Product Goal

Allow a path or visual surface to use a multi-cell center fill pattern.

V0 scope:

```text
- borders, corners, inner corners, ends, tees, and junctions remain legacy;
- only the interior fill can become a 1x1, 2x2, 4x4, or NxM pattern;
- existing ProjectPathPreset entries remain compatible as center 1x1;
- no gameplay is added to visual presets.
```

Example target:

```text
Water center pattern 2x2:

[ A ][ B ]
[ C ][ D ]

When painted over a large area:

patternX = mapX % 2
patternY = mapY % 2
```

Important compatibility note:

```text
Do not assume isolated = center.
The current path resolver must be audited first.
The interior of a full block currently resolves through the legacy path
variant system, and Lot 0 must identify the real variant used.
```

## Reports

All PathPattern reports must be written in:

```text
reports/pathPattern/
```

## Common Contract

Git is read-only unless the user explicitly asks for a separate commit.

Allowed git commands:

```text
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git diff -- <file>
git ls-files
```

Forbidden git commands during lots:

```text
git add
git commit
git push
git restore
git reset
git stash
git checkout
git merge
git rebase
git rm
```

Never modify:

```text
packages/map_gameplay
packages/map_battle
```

Touch `packages/map_runtime` only in lots explicitly marked runtime.

Do not:

```text
- recreate Surface Studio;
- recreate TSX/TMX authoring;
- add Mistral;
- add PixelLab;
- add MCP;
- add gameplay to visual presets;
- mutate ProjectManifest directly from UI flows;
- write project files automatically.
```

Each lot report should contain:

```text
1. Verdict
2. Audit initial
3. Files created / modified / deleted
4. Decisions made
5. Non-goals confirmed
6. Tests run
7. Analyze
8. Git status final
9. Remaining limits
10. Recommended next lot
```

## Phases

| Phase | Lots | Goal |
| --- | ---: | --- |
| A - Decision and minimal model | 0-3 | Decide center anchor, define pure center pattern objects, keep legacy compatible |
| B - Transparency and preview | 4-6 | Transparent color, static preview, animated preview |
| C - Persistence and manifest | 7-10 | Minimal project model, external JSON codec, manifest integration, manifest ops |
| D - Path Studio UI | 11-14 | Shell, center pattern editor, save flow, painter integration |
| E - Water closure | 15-17 | Editor canvas render, runtime render, internal water 2x2 golden slice |
| F - Tall grass | 18-20 | Decide, author, and bridge tall grass cleanly |

## Strict Order

```text
0  Path Studio Center Pattern Decision
1  Path Center Pattern Value Objects
2  Path Center Pattern Resolver
3  Legacy Path Preset Center Adapter
4  Tileset Transparent Color
5  Path Center Pattern Static Preview
6  Path Center Pattern Animated Preview
7  ProjectPathPatternPreset Model
8  ProjectPathPatternPreset JSON Codec
9  ProjectManifest PathPattern Integration
10 PathPattern Manifest Operations
11 Path Studio Shell
12 Path Studio Center Pattern Editor
13 Path Studio Save Flow
14 Path Painter Integration
15 Editor Canvas PathPattern Render
16 Runtime PathPattern Render
17 Water 2x2 Golden Slice
18 Tall Grass PathPattern Decision
19 Tall Grass PathPattern Authoring
20 Tall Grass Gameplay Bridge
```

## Lot 0 - Path Studio Center Pattern Decision V0

Report:

```text
reports/pathPattern/path_pattern_lot_00_center_pattern_decision.md
```

Goal:

```text
Decide how to let the existing Path system support a multi-cell center fill.
```

Lot 0 must answer:

```text
- where ProjectPathPreset and TerrainPathVariant are defined;
- how path variants are stored;
- whether variants store one frame or frame lists;
- which variant is actually used by the current resolver for the interior of a full painted block;
- where the editor resolves and draws path frames;
- where a center pattern can be inserted without changing borders, corners, junctions, gameplay, or runtime.
```

Expected recommendation:

```text
Create a separate ProjectPathPatternPreset later.
Adapt existing ProjectPathPreset entries as center 1x1.
Keep V0 center-only; bords/corners/junctions remain legacy.
```

## Lot 1 - Path Center Pattern Value Objects V0

Report:

```text
reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
```

Goal:

```text
Create pure map_core value objects for the center pattern only.
```

Expected objects:

```text
PathCenterPatternSize
PathCenterPatternCellCoordinate
PathCenterPatternCell
PathCenterPattern
```

Rules:

```text
- width > 0;
- height > 0;
- cells cover exactly every local coordinate;
- no duplicate localX/localY;
- each cell contains List<TilesetVisualFrame>;
- no JSON yet;
- no manifest change.
```

## Lot 2 - Path Center Pattern Resolver V0

Report:

```text
reports/pathPattern/path_pattern_lot_02_center_pattern_resolver.md
```

Goal:

```text
Resolve map coordinates to a center pattern cell.
```

Rule:

```text
patternX = mapX modulo pattern.width
patternY = mapY modulo pattern.height
```

The lot must define the negative-coordinate contract explicitly.

## Lot 3 - Legacy Path Preset Center Adapter V0

Report:

```text
reports/pathPattern/path_pattern_lot_03_legacy_center_adapter.md
```

Goal:

```text
Adapt existing ProjectPathPreset entries to a center 1x1 view without changing ProjectPathPreset.
```

Rules:

```text
- use the actual legacy interior-fill variant identified by Lot 0;
- preserve frame order and durationMs;
- preserve frame tilesetId overrides;
- preserve legacy variants for borders/corners/junctions;
- do not add JSON.
```

## Lot 4 - Tileset Transparent Color V0

Report:

```text
reports/pathPattern/path_pattern_lot_04_tileset_transparent_color.md
```

Goal:

```text
Add configurable transparent color support, for example f05ba1, without hardcoding any specific color.
```

Rules:

```text
- parse hex RGB case-insensitively;
- invalid color has a clear diagnostic/error;
- apply alpha only in memory;
- never modify source images;
- never create derived images automatically.
```

## Lot 5 - Path Center Pattern Static Preview V0

Report:

```text
reports/pathPattern/path_pattern_lot_05_center_pattern_static_preview.md
```

Goal:

```text
Show a static editor preview of a center pattern.
```

Rules:

```text
- first frame only;
- support 1x1 and 2x2 at minimum;
- use transparent color in memory if available;
- provide a fallback when image bytes are unavailable.
```

## Lot 6 - Path Center Pattern Animated Preview V0

Report:

```text
reports/pathPattern/path_pattern_lot_06_center_pattern_animated_preview.md
```

Goal:

```text
Animate center pattern previews using TilesetVisualFrame.durationMs.
```

Rules:

```text
- preview only;
- no Flame runtime;
- one-frame cells stay stable;
- timelines use a shared elapsedMs.
```

## Lot 7 - ProjectPathPatternPreset Model V0

Report:

```text
reports/pathPattern/path_pattern_lot_07_project_path_pattern_preset_model.md
```

Goal:

```text
Create a minimal project model for a path preset with a center pattern.
```

Expected shape:

```text
ProjectPathPatternPreset
- id
- name
- basePathPresetId? or legacy variant mappings
- centerPattern
- transparentColor?
- categoryId?
- sortOrder
```

Rules:

```text
- do not modify ProjectManifest in this lot;
- do not modify ProjectPathPreset;
- no JSON yet.
```

## Lot 8 - ProjectPathPatternPreset JSON Codec V0

Report:

```text
reports/pathPattern/path_pattern_lot_08_project_path_pattern_json_codec.md
```

Goal:

```text
Create an external manual codec for ProjectPathPatternPreset.
```

Rules:

```text
- no generated JSON;
- no toJson/fromJson on the model;
- stable ordering;
- transparentColor encoded only when present.
```

## Lot 9 - ProjectManifest PathPattern Integration V0

Report:

```text
reports/pathPattern/path_pattern_lot_09_manifest_path_pattern_integration.md
```

Goal:

```text
Add pathPatternPresets to ProjectManifest after the model and codec are covered.
```

Rules:

```text
- old manifests decode with an empty list;
- no migration file writes;
- generated code only for touched map_core models if the current style requires it.
```

## Lot 10 - PathPattern Manifest Operations V0

Report:

```text
reports/pathPattern/path_pattern_lot_10_manifest_operations.md
```

Goal:

```text
Pure helpers for read, replace, upsert, remove, and clear.
```

## Lot 11 - Path Studio Shell V0

Report:

```text
reports/pathPattern/path_pattern_lot_11_path_studio_shell.md
```

Goal:

```text
Create a clean Path Studio entry with no full editor yet.
```

UI:

```text
Path Studio
- Presets
- Create preset
- Diagnostics
```

Rules:

```text
- no Surface Studio;
- no placeholder promising unsupported actions;
- no save to disk.
```

## Lot 12 - Path Studio Center Pattern Editor V0

Report:

```text
reports/pathPattern/path_pattern_lot_12_center_pattern_editor.md
```

Goal:

```text
Let the user choose center size and fill center cells.
```

V0 UX:

```text
- size: 1x1 or 2x2;
- select a frame per cell;
- preview;
- transparent color display/config if already available.
```

## Lot 13 - Path Studio Save Flow V0

Report:

```text
reports/pathPattern/path_pattern_lot_13_save_flow.md
```

Goal:

```text
Add a valid ProjectPathPatternPreset to the working project/manifest state.
```

Rules:

```text
- local mutation only;
- dirty state through existing project save flow;
- no direct disk write.
```

## Lot 14 - Path Painter Integration V0

Report:

```text
reports/pathPattern/path_pattern_lot_14_path_painter_integration.md
```

Goal:

```text
Let users select and paint a PathPattern preset without breaking legacy Path Painter.
```

## Lot 15 - Editor Canvas PathPattern Render V0

Report:

```text
reports/pathPattern/path_pattern_lot_15_editor_canvas_render.md
```

Goal:

```text
Render painted center pattern cells in the editor canvas.
```

Rules:

```text
- legacy paths still render;
- center pattern applies only to center fill cells;
- borders/corners/junctions remain legacy.
```

## Lot 16 - Runtime PathPattern Render V0

Report:

```text
reports/pathPattern/path_pattern_lot_16_runtime_render.md
```

Goal:

```text
Render PathPattern visually in runtime.
```

Rules:

```text
- map_runtime only;
- no gameplay;
- preserve layer ordering.
```

## Lot 17 - Water 2x2 Golden Slice V0

Report:

```text
reports/pathPattern/path_pattern_lot_17_water_2x2_golden_slice.md
```

Goal:

```text
Validate an internal water preset with a 2x2 animated center pattern.
```

Rules:

```text
- internal fixture;
- no TSX;
- no TMX;
- transparent color configurable;
- editor preview, paint, and runtime visual slice.
```

## Lot 18 - Tall Grass PathPattern Decision V0

Report:

```text
reports/pathPattern/path_pattern_lot_18_tall_grass_decision.md
```

Goal:

```text
Decide whether tall grass should be visual PathPattern plus explicit gameplay zone association.
```

## Lot 19 - Tall Grass PathPattern Authoring V0

Report:

```text
reports/pathPattern/path_pattern_lot_19_tall_grass_authoring.md
```

Goal:

```text
Create a simple tall grass visual preset flow.
```

## Lot 20 - Tall Grass Gameplay Bridge V0

Report:

```text
reports/pathPattern/path_pattern_lot_20_tall_grass_gameplay_bridge.md
```

Goal:

```text
Associate tall grass visuals with encounter gameplay cleanly, without hiding gameplay inside visual presets.
```

## Removed From This Roadmap

The following are intentionally out:

```text
TSX Import Lite
TMX import
Mistral grouping
PixelLab
Surface Studio
Surface TSX builder
Golden Slice Exterior TMX
runtime import of external maps
```

## Visual Milestones

```text
Lot 5: static center preview
Lot 6: animated center preview
Lot 12: editable center pattern
Lot 14: paintable PathPattern preset
Lot 17: water 2x2 slice
```
