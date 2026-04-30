# Lot PathPattern-0 - Path Studio Center Pattern Decision V0

Date: 2026-04-30

## 1. Verdict

Accepted as an audit / decision lot.

No product code was changed. No UI, model persistence, runtime, gameplay, TSX,
TMX, Mistral, PixelLab, or MCP work was added.

Decision:

```text
Use a separate future ProjectPathPatternPreset.
Limit V0 to a multi-cell center fill pattern.
Keep legacy ProjectPathPreset compatible as center 1x1.
Keep borders, corners, inner corners, ends, tees, and junctions on the legacy resolver.
```

Critical compatibility finding:

```text
The interior of a full painted path block resolves to TerrainPathVariant.cross.
TerrainPathVariant.isolated is only the one-cell island / no-neighbor case.
```

Important nuance:

```text
Not every cross should become a center pattern.
The current resolver also returns cross for a four-way junction and some map-edge fill cases.
Future implementation must detect "center fill cell" from neighborhood context, not only from variant == cross.
```

## 2. Audit Initial

### Commands Run

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "ProjectPathPreset|PathSurfaceKind|TerrainPathVariant|PathLayer|PathAutotileSet|TilesetVisualFrame|TilesetSourceRect|resolve.*Path|autotile|cross|isolated|horizontal|vertical|corner|tee|PathLayerEditingCoordinator|PathLayer" packages/map_core packages/map_editor
```

Initial working tree:

```text
?? reports/pathPattern/path_pattern_roadmap.md
```

Initial `git diff --stat`:

```text
no tracked diff
```

Context Mode:

```text
ctx command unavailable in PATH.
```

### Inspected Files

```text
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/operations/map_terrain_autotile.dart
packages/map_core/lib/src/operations/map_path.dart
packages/map_core/test/map_terrain_autotile_characterization_test.dart
packages/map_editor/lib/src/application/models/path_autotile_set.dart
packages/map_editor/lib/src/application/services/path_autotile_resolver.dart
packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart
packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
```

### Answers To Required Audit Questions

1. Where is `ProjectPathPreset` defined?

`ProjectPathPreset` is defined in `packages/map_core/lib/src/models/project_manifest.dart` lines 367-379. It is stored on `ProjectManifest.pathPresets`, defined at lines 56-88 with the path preset list at line 71.

2. Where is `TerrainPathVariant` defined?

`TerrainPathVariant` is defined in `packages/map_core/lib/src/models/enums.dart` lines 180-200.

3. How are variants stored today?

`ProjectPathPreset` stores `variants` as `List<PathPresetVariantMapping>` in `packages/map_core/lib/src/models/project_manifest.dart` lines 367-376. Each mapping stores one `TerrainPathVariant` plus frames in lines 382-393.

4. Does each variant point to a unique tile/frame or a list of frames?

Each variant points to `List<TilesetVisualFrame>`, not a single frame. `TilesetVisualFrame` contains `tilesetId`, `TilesetSourceRect`, and optional `durationMs` in `packages/map_core/lib/src/models/project_manifest.dart` lines 269-284. Editor resolution animates multiple frames through `PathAutotileSet.frameForVariantAt` in `packages/map_editor/lib/src/application/models/path_autotile_set.dart` lines 101-126.

5. Which variant is really used for the interior of a large full area?

`TerrainPathVariant.cross`.

Evidence:

- `resolvePathVariantFromMask(15)` returns `cross` in `packages/map_core/lib/src/operations/map_terrain_autotile.dart` lines 22-40.
- `map_terrain_autotile_characterization_test.dart` lines 212-238 documents that the center of a full 3x3 block resolves to `cross`.
- The same test shows `isolated` only for a single active cell with no path neighbors at lines 44-62.

6. Is it `isolated`, `cross`, or something else?

It is `cross` for full-area interior fill. `isolated` is a disconnected one-cell island. For future center pattern work, the legacy anchor is therefore `cross`, but implementation must distinguish full-area interior from four-way junctions.

7. Where does `PathAutotileSet` choose the frame to draw?

`PathAutotileSet.frameForVariantAt` chooses the frame in `packages/map_editor/lib/src/application/models/path_autotile_set.dart` lines 101-126. `sourceForVariantAt` exposes the chosen `TilesetSourceRect` at lines 128-134, and `resolvedTilesetIdForVariantAt` resolves per-frame tileset override or fallback preset tileset at lines 136-146.

8. Where does the editor canvas render paths?

`packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`.

Important render path:

- `_paintPathLayer` iterates `PathLayer.cells` at lines 1635-1679.
- `_paintPathLayerCell` calls `resolvePathVariantAt` at lines 1681-1721.
- `_paintAutotileVariantCell` resolves source/tileset and calls `canvas.drawImageRect` at lines 1724-1774.

9. Where can a center pattern be inserted without breaking borders/corners?

The safest insertion point is after legacy neighborhood resolution and before source frame drawing:

```text
map cell
-> resolvePathVariantAt(...)
-> if selected preset is ProjectPathPatternPreset and cell is true center fill
   resolve PathCenterPattern cell by mapX/mapY
-> otherwise draw legacy variant through PathAutotileSet
```

This keeps legacy borders/corners/junctions in the current resolver and changes only the future center-fill branch.

10. How do we keep old `ProjectPathPreset` entries compatible as center 1x1?

Use an adapter view later:

```text
ProjectPathPreset
-> legacy variant mappings stay intact
-> centerPattern 1x1 uses the legacy interior-fill frames
-> interior-fill frames = TerrainPathVariant.cross frames when present
-> fallback uses the resolved default cross frame if the preset omits cross
```

Do not reinterpret `isolated` as center. A single-cell path must still use `isolated`.

## 3. Files Created / Modified / Deleted

Created:

```text
reports/pathPattern/path_pattern_lot_00_center_pattern_decision.md
```

Modified:

```text
reports/pathPattern/path_pattern_roadmap.md
```

Deleted:

```text
none
```

Production code changed:

```text
none
```

## 4. Current Path System Summary

### Manifest And Models

`ProjectManifest` owns `pathPresets` as a list of `ProjectPathPreset`. A `ProjectPathPreset` contains:

```text
id
name
surfaceKind
categoryId?
tilesetId
variants: List<PathPresetVariantMapping>
sortOrder
```

`PathLayer` stores:

```text
presetId
cells: List<bool>
properties
animationMode
animationTriggers
```

The layer stores occupancy and selected preset, not per-cell frame data.

### Resolution

Path rendering is neighborhood-driven:

```text
PathLayer.cells
-> resolvePathVariantAt
-> TerrainPathVariant
-> PathAutotileSet frame/source
-> drawImageRect
```

The four cardinal neighbors form a mask:

```text
north = 1
east = 2
south = 4
west = 8
```

Mask `15` means all cardinal neighbors exist and resolves to `cross`.

### Interior Finding

The current resolver has no explicit `center` or `interior` enum. Full-area interior is represented by `cross`. The characterization test states this directly for a full 3x3 block.

This means PathPattern must not start from a new assumption. It must preserve:

```text
one-cell island -> isolated
horizontal/vertical lines -> horizontal/vertical
corners -> corner*
tees -> tee*
true full-area interior -> cross today, center pattern tomorrow
four-way path junction -> cross legacy
```

## 5. Option Comparison

### Option A - Extend ProjectPathPreset Directly

Description:

```text
ProjectPathPreset remains the only path preset model.
Add a centerPattern field directly to ProjectPathPreset.
```

Advantages:

```text
- fewer top-level concepts;
- existing Path Painter can keep using presetId;
- old UI code may need fewer lookup branches.
```

Risks:

```text
- changes the legacy JSON contract early;
- generated model churn in map_core before behavior is proven;
- old ProjectPathPreset semantics become mixed with new center-pattern semantics;
- easy to accidentally treat every cross as center;
- harder to preserve old presets as untouched compatibility data.
```

### Option B - Create ProjectPathPatternPreset Separately

Description:

```text
Create a new future project model that references or wraps legacy path behavior,
but owns a centerPattern explicitly.
```

Advantages:

```text
- safest legacy compatibility;
- no immediate ProjectPathPreset JSON break;
- clear product boundary: this is PathPattern, not legacy Path;
- allows center-only V0 without pretending every variant is NxM;
- gives Path Studio a simple authoring target.
```

Risks:

```text
- requires a painter/read-model bridge;
- requires future manifest integration;
- needs careful UI copy so users understand legacy paths and PathPattern presets.
```

## 6. Decision

Choose Option B.

Recommended future shape:

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

```text
PathCenterPattern
- width
- height
- cells
```

```text
PathCenterPatternCell
- localX
- localY
- frames: List<TilesetVisualFrame>
```

Compatibility rule:

```text
width = 1 and height = 1
=> legacy-style center fill.
```

2x2 rule:

```text
patternX = mapX % 2
patternY = mapY % 2
```

Center-fill detection rule to design in the next lots:

```text
Do not key only on TerrainPathVariant.cross.
Use neighborhood context to identify true fill interior.
```

For V0, a conservative definition should be:

```text
active path cell
all four cardinal neighbors active
all four diagonal neighbors active
```

This treats a full-area interior as center fill and keeps a plus-shaped four-way junction on legacy `cross`.

Map-edge fill behavior needs an explicit decision later because the current resolver can return `cross` for some edge fill cells when a painted area touches map bounds.

## 7. Transparency Decision

Transparency belongs in a separate lot.

Future rule:

```text
TilesetTransparentColor
- configurable RGB value;
- case-insensitive hex parse;
- no hardcoded f05ba1;
- in-memory preview/render processing only;
- source image never modified;
- no derived asset written automatically.
```

Roadmap lot:

```text
PathPattern-4 - Tileset Transparent Color V0
```

## 8. Corrected Roadmap

The roadmap was rewritten in:

```text
reports/pathPattern/path_pattern_roadmap.md
```

Corrected sequence:

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

Explicitly removed from this roadmap:

```text
external map import
AI grouping
Surface authoring workspace
image generation
```

## 9. Non-Goals Confirmed

Confirmed:

```text
- no Surface Studio;
- no Path Studio UI in this lot;
- no persistent model in this lot;
- no manifest change;
- no runtime change;
- no gameplay change;
- no image source mutation;
- no map_gameplay modification;
- no map_battle modification.
```

## 10. Tests Run

```bash
cd packages/map_core && dart test
```

Result:

```text
00:03 +1301: All tests passed!
```

## 11. Analyze

```bash
cd packages/map_editor && flutter analyze lib/src/application/models/path_autotile_set.dart lib/src/application/services/path_autotile_resolver.dart
```

Result:

```text
Analyzing 2 items...
No issues found! (ran in 1.1s)
```

## 12. Limits And Risks

Remaining decisions:

```text
- exact `PathCenterPattern` value-object names;
- whether negative map coordinates are rejected or use positive modulo;
- exact treatment of map-edge fill cells that currently resolve to cross;
- whether ProjectPathPatternPreset references a basePathPresetId or snapshots legacy variant mappings;
- manifest integration timing after JSON golden samples.
```

Main risk:

```text
cross is overloaded today.
It means full-area interior in solid blocks, but also a four-way path junction.
```

Mitigation:

```text
center patterns must use a future neighborhood predicate for center fill,
not only `variant == TerrainPathVariant.cross`.
```

## 13. Recommended Next Lot

```text
Lot PathPattern-1 - Path Center Pattern Value Objects V0
```

Goal:

```text
Create pure map_core value objects for a 1x1 / 2x2 / NxM center pattern,
without JSON, manifest, UI, runtime, gameplay, or image processing.
```

## 14. Git Status Final

```text
?? reports/pathPattern/path_pattern_lot_00_center_pattern_decision.md
?? reports/pathPattern/path_pattern_roadmap.md
```

Tracked diff stat:

```text
no tracked diff
```
