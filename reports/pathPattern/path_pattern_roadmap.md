# PathPattern Roadmap

Date: 2026-04-30

## Decision

The active product direction is deliberately small:

```text
Path Studio.
Center multi-cell pattern.
Then tall grass.
Nothing else.
```

## Starting Point

The previous complex authoring workspace has been removed from the active
editor path. The useful foundations remain:

- `packages/map_core` Surface models;
- `ProjectManifest.surfaceCatalog`;
- `SurfaceLayer`;
- Surface Painter;
- existing runtime Surface support;
- existing Surface to GameplayZone bridge.

The new work builds on the system that already behaves best in the editor:
Path / Path Painter.

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

Compatibility warning:

```text
Do not assume isolated = center.
The current path resolver must be audited first.
Lot 0 identifies the real variant used by a full-area interior cell.
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
- recreate the removed authoring workspace;
- add external map import flows;
- add AI grouping;
- add image generation workflows;
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
| C - Persistence and manifest | 7-11 | Project model, codec, golden JSON decision, manifest integration, manifest ops |
| D - Path Studio UI | 12-15 | Shell, center pattern editor, save flow, painter integration |
| E - Water closure | 16-18 | Editor canvas render, runtime render, internal water 2x2 golden slice |
| F - Tall grass | 19-21 | Decide, author, and bridge tall grass cleanly |

## Strict Order

```text
0  Center Variant Audit / Decision
1  Center Pattern Value Objects
2  Center Pattern Resolver
3  Legacy ProjectPathPreset Adapter
4  Tileset Transparent Color
5  Static Preview
6  Animated Preview
7  ProjectPathPatternPreset Model
8  JSON Codec
9  Manifest Decision / Golden JSON
10 Manifest Integration
11 Manifest Operations
12 Path Studio Shell
13 Center Pattern Editor
14 Save Flow
15 Path Painter Integration
16 Editor Canvas Render
17 Runtime Render
18 Water 2x2 Golden Slice
19 Tall Grass Decision
20 Tall Grass Authoring
21 Tall Grass Gameplay Bridge
```

## Lot 0 - Center Variant Audit / Decision

Report:

```text
reports/pathPattern/path_pattern_lot_00_center_variant_audit_decision.md
```

Goal:

```text
Understand how the current Path resolver chooses variants and identify the
actual variant used for the interior of a full painted area.
```

Required output:

```text
Cellule intérieure pleine -> TerrainPathVariant.<exact name>
```

## Lot 1 - Center Pattern Value Objects

Report:

```text
reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
```

Goal:

```text
Create pure non-persistent value objects for the center pattern only.
```

Expected objects:

```text
PathCenterPattern
PathCenterPatternCell
PathCenterPatternSize or equivalent
```

Rules:

```text
- width > 0;
- height > 0;
- cells cover exactly every local coordinate;
- no duplicate localX/localY;
- each cell contains List<TilesetVisualFrame>;
- no JSON;
- no manifest change.
```

## Lot 2 - Center Pattern Resolver

Report:

```text
reports/pathPattern/path_pattern_lot_02_center_pattern_resolver.md
```

Goal:

```text
Resolve map coordinates to a center pattern cell.
```

Recommended V0 rule:

```text
patternX = mapX modulo pattern.width
patternY = mapY modulo pattern.height
```

## Lot 3 - Legacy ProjectPathPreset Adapter

Report:

```text
reports/pathPattern/path_pattern_lot_03_legacy_project_path_preset_adapter.md
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
- no JSON.
```

## Lot 4 - Tileset Transparent Color

Report:

```text
reports/pathPattern/path_pattern_lot_04_tileset_transparent_color.md
```

Goal:

```text
Add configurable transparent color support without hardcoding any specific color.
```

Rules:

```text
- parse hex RGB case-insensitively;
- invalid color has a clear diagnostic/error;
- apply alpha only in memory;
- never modify source images;
- never create derived images automatically.
```

## Lot 5 - Static Preview

Report:

```text
reports/pathPattern/path_pattern_lot_05_static_preview.md
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

## Lot 6 - Animated Preview

Report:

```text
reports/pathPattern/path_pattern_lot_06_animated_preview.md
```

Goal:

```text
Animate center pattern previews using TilesetVisualFrame.durationMs.
```

Rules:

```text
- preview only;
- no runtime rendering;
- one-frame cells stay stable;
- timelines use a shared elapsedMs.
```

## Lot 7 - ProjectPathPatternPreset Model

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
- no JSON.
```

## Lot 8 - JSON Codec

Report:

```text
reports/pathPattern/path_pattern_lot_08_json_codec.md
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

## Lot 9 - Manifest Decision / Golden JSON

Report:

```text
reports/pathPattern/path_pattern_lot_09_manifest_decision_golden_json.md
```

Goal:

```text
Decide the manifest shape and lock golden JSON samples before integration.
```

## Lot 10 - Manifest Integration

Report:

```text
reports/pathPattern/path_pattern_lot_10_manifest_integration.md
```

Goal:

```text
Add PathPattern presets to ProjectManifest after the model, codec, and golden JSON decision are covered.
```

Rules:

```text
- old manifests decode with an empty list;
- no migration file writes;
- generated code only for touched map_core models if the current style requires it.
```

## Lot 11 - Manifest Operations

Report:

```text
reports/pathPattern/path_pattern_lot_11_manifest_operations.md
```

Goal:

```text
Pure helpers for read, replace, upsert, remove, and clear.
```

## Lot 12 - Path Studio Shell

Report:

```text
reports/pathPattern/path_pattern_lot_12_path_studio_shell.md
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
- no complete pattern editor;
- no unsupported primary actions;
- no save to disk.
```

## Lot 13 - Center Pattern Editor

Report:

```text
reports/pathPattern/path_pattern_lot_13_center_pattern_editor.md
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

## Lot 14 - Save Flow

Report:

```text
reports/pathPattern/path_pattern_lot_14_save_flow.md
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

## Lot 15 - Path Painter Integration

Report:

```text
reports/pathPattern/path_pattern_lot_15_path_painter_integration.md
```

Goal:

```text
Let users select and paint a PathPattern preset without breaking legacy Path Painter.
```

## Lot 16 - Editor Canvas Render

Report:

```text
reports/pathPattern/path_pattern_lot_16_editor_canvas_render.md
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

## Lot 17 - Runtime Render

Report:

```text
reports/pathPattern/path_pattern_lot_17_runtime_render.md
```

Goal:

```text
Render PathPattern visually in runtime.
```

Rules:

```text
- runtime package only;
- no gameplay;
- preserve layer ordering.
```

## Lot 18 - Water 2x2 Golden Slice

Report:

```text
reports/pathPattern/path_pattern_lot_18_water_2x2_golden_slice.md
```

Goal:

```text
Validate an internal water preset with a 2x2 animated center pattern.
```

Rules:

```text
- internal fixture;
- transparent color configurable;
- editor preview, paint, and runtime visual slice.
```

## Lot 19 - Tall Grass Decision

Report:

```text
reports/pathPattern/path_pattern_lot_19_tall_grass_decision.md
```

Goal:

```text
Decide whether tall grass should be visual PathPattern plus explicit gameplay zone association.
```

## Lot 20 - Tall Grass Authoring

Report:

```text
reports/pathPattern/path_pattern_lot_20_tall_grass_authoring.md
```

Goal:

```text
Create a simple tall grass visual preset flow.
```

## Lot 21 - Tall Grass Gameplay Bridge

Report:

```text
reports/pathPattern/path_pattern_lot_21_tall_grass_gameplay_bridge.md
```

Goal:

```text
Associate tall grass visuals with encounter gameplay cleanly, without hiding gameplay inside visual presets.
```

## Visual Milestones

```text
Lot 5: static center preview
Lot 6: animated center preview
Lot 13: editable center pattern
Lot 15: paintable PathPattern preset
Lot 18: water 2x2 slice
```
