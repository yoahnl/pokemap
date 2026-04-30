# Lot PathPattern-0 - Center Variant Audit / Path Studio Decision V0

Date: 2026-04-30

## 1. Verdict

Accepted as an audit and decision lot.

No production code was changed. No UI was created. No persistent model was
created. `ProjectManifest`, `ProjectPathPreset`, runtime packages, gameplay
packages, generated files, and JSON codecs were not modified.

Essential answer:

```text
Cellule intérieure pleine -> TerrainPathVariant.cross
```

Recommendation:

```text
Start with Option C:
non-persistent value objects + legacy ProjectPathPreset adapted as center 1x1.

Later, after tests and previews are proven, move to Option B:
a separate ProjectPathPatternPreset.
```

Do not modify `ProjectPathPreset` directly yet.

## 2. Audit Initial

Commands run before edits:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "ProjectPathPreset|PathSurfaceKind|TerrainPathVariant|PathLayer|PathAutotileSet|TilesetVisualFrame|TilesetSourceRect|resolve.*Path|autotile|cross|isolated|horizontal|vertical|corner|tee|PathLayerEditingCoordinator|PathLayer" packages/map_core packages/map_editor
```

Outputs:

```text
pwd
/Users/karim/Project/pokemonProject

git status --short --untracked-files=all
<empty>

git diff --stat
<empty>
```

Context Mode:

```text
`ctx` command was not available in PATH.
Context Mode MCP stats were available.
```

Context Mode MCP stats:

```text
775.1K tokens saved  ·  80.0% reduction  ·  20h 20m

Without context-mode  |████████████████████████████████████████| 3.7 MB
With context-mode     |████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 758.4 KB

3.0 MB kept out of your conversation. Never entered context.

143 calls

  ctx_batch_execute         43 calls    2.1 MB saved
  ctx_search                15 calls  368.9 KB saved
  ctx_execute               61 calls  350.5 KB saved
  ctx_execute_file          15 calls  136.9 KB saved
  ctx_fetch_and_index        3 calls   39.1 KB saved
  ctx_stats                  6 calls   16.4 KB saved

v1.0.103
```

## 3. Fichiers Inspectés

Inspected files:

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

Found files from the requested audit set:

```text
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/operations/map_path.dart
packages/map_core/lib/src/operations/map_terrain_autotile.dart
packages/map_editor/lib/src/application/models/path_autotile_set.dart
packages/map_editor/lib/src/application/services/path_autotile_resolver.dart
packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart
packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
packages/map_editor/lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart
packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
```

No requested priority file was missing.

## 4. Comportement Actuel Du Resolver Path

The current path system stores occupancy in `PathLayer.cells` and stores the
selected visual mapping through `PathLayer.presetId`.

`PathLayer` is defined in `packages/map_core/lib/src/models/map_layer.dart`
lines 53-65:

```text
PathLayer fields:
- id
- name
- isVisible
- opacity
- presetId
- cells: List<bool>
- properties
- animationMode
- animationTriggers
```

The resolver derives a four-bit cardinal mask:

```text
north = 1
east = 2
south = 4
west = 8
```

`resolvePathVariantFromMask` in
`packages/map_core/lib/src/operations/map_terrain_autotile.dart` lines 22-40
maps:

```text
0  -> isolated
1  -> endNorth
2  -> endEast
3  -> cornerNE
4  -> endSouth
5  -> vertical
6  -> cornerSE
7  -> teeEast
8  -> endWest
9  -> cornerNW
10 -> horizontal
11 -> teeNorth
12 -> cornerSW
13 -> teeWest
14 -> teeSouth
15 -> cross
```

When the mask is 15, `_resolvePathVariantAt` may return inner corners if a
single diagonal is missing. If all diagonals are present, it returns the base
variant, which is `cross`.

The resolver also has map-edge compatibility behavior: some non-corner edge
cells can be promoted to `cross` when a filled area touches the map boundary.

## 5. Preuve Du Variant Utilisé Au Centre

Existing test used:

```text
packages/map_core/test/map_terrain_autotile_characterization_test.dart
```

Specific test:

```text
map_terrain_autotile characterization cardinal path shapes full 3x3 block center is cross and edges receive border fill
```

Relevant expectations in that file:

```text
pathMaskAt(grid, 1, 1) -> 15
pathVariantAt(grid, 1, 1) -> TerrainPathVariant.cross
pathMaskAt(grid, 1, 0) -> 14
pathVariantAt(grid, 1, 0) -> TerrainPathVariant.cross
pathMaskAt(grid, 0, 0) -> 6
pathVariantAt(grid, 0, 0) -> TerrainPathVariant.cornerSE
```

Targeted command:

```bash
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded
```

Complete targeted output:

```text
00:00 +0: loading test/map_terrain_autotile_characterization_test.dart
00:00 +0: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping
00:00 +1: map_terrain_autotile characterization mask table rejects masks outside the current four-bit range
00:00 +2: map_terrain_autotile characterization cardinal path shapes isolated active cell resolves to isolated
00:00 +3: map_terrain_autotile characterization cardinal path shapes horizontal line resolves center and both ends distinctly
00:00 +4: map_terrain_autotile characterization cardinal path shapes vertical line resolves center and both ends distinctly
00:00 +5: map_terrain_autotile characterization cardinal path shapes four cardinal L joins resolve to the matching corner variants
00:00 +6: map_terrain_autotile characterization cardinal path shapes four T joins resolve to the current tee variants
00:00 +7: map_terrain_autotile characterization cardinal path shapes four-way intersection resolves to cross
00:00 +8: map_terrain_autotile characterization cardinal path shapes full 3x3 block center is cross and edges receive border fill
00:00 +9: map_terrain_autotile characterization diagonal-aware interior corners single missing diagonal with all cardinals present creates inner corners
00:00 +10: map_terrain_autotile characterization diagonal-aware interior corners multiple missing diagonals keep the all-cardinal cell as cross
00:00 +11: map_terrain_autotile characterization map edges and out-of-map neighbors non-corner edge cells can be promoted to cross
00:00 +12: map_terrain_autotile characterization map edges and out-of-map neighbors map corner cells keep corner variants when two map edges touch
00:00 +13: map_terrain_autotile characterization map edges and out-of-map neighbors single-edge corner replacements turn some corner variants into ends
00:00 +14: map_terrain_autotile characterization inactive cells and invalid inputs inactive current cell is not checked before resolving neighbors
00:00 +15: map_terrain_autotile characterization inactive cells and invalid inputs coordinates outside the grid throw validation errors
00:00 +16: map_terrain_autotile characterization inactive cells and invalid inputs empty sizes and incomplete grids throw validation errors
00:00 +17: map_terrain_autotile characterization inactive cells and invalid inputs extra path cells beyond map bounds are tolerated and ignored
00:00 +18: map_terrain_autotile characterization terrain resolver parity terrain autotile uses the selected terrain type as the matcher
00:00 +19: map_terrain_autotile characterization terrain resolver parity terrain resolver has the same inactive-current-cell behavior
00:00 +20: map_terrain_autotile characterization terrain resolver parity terrain validation rejects incomplete grids and out-of-bounds positions
00:00 +21: All tests passed!
```

Conclusion:

```text
Cellule intérieure pleine -> TerrainPathVariant.cross
```

`TerrainPathVariant.isolated` is not the center of a filled area. It is the
single active cell with no cardinal neighbors.

## 6. Localisation Exacte Du Choix De Variant

`TerrainPathVariant` is defined in
`packages/map_core/lib/src/models/enums.dart` lines 180-200.

`PathSurfaceKind` is defined in
`packages/map_core/lib/src/models/enums.dart` lines 210-225.

`ProjectPathPreset` is defined in
`packages/map_core/lib/src/models/project_manifest.dart` lines 367-379.

`PathPresetVariantMapping` is defined in
`packages/map_core/lib/src/models/project_manifest.dart` lines 382-393.

`TilesetSourceRect` and `TilesetVisualFrame` are defined in
`packages/map_core/lib/src/models/project_manifest.dart` lines 257-284.

`PathAutotileSet` chooses the frame to draw in
`packages/map_editor/lib/src/application/models/path_autotile_set.dart`:

```text
lines 101-126: frameForVariantAt(...)
lines 128-134: sourceForVariantAt(...)
lines 136-146: resolvedTilesetIdForVariantAt(...)
```

`PathAutotileResolver` overlays preset mappings on default mappings in
`packages/map_editor/lib/src/application/services/path_autotile_resolver.dart`
lines 8-29.

The editor canvas renders paths in
`packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`:

```text
lines 1635-1679: _paintPathLayer(...)
lines 1681-1721: _paintPathLayerCell(...)
lines 1696-1700: resolvePathVariantAt(...)
lines 1724-1774: _paintAutotileVariantCell(...)
lines 1767-1772: canvas.drawImageRect(...)
```

## 7. Comparaison Option A / B / C

### Option A - Extend ProjectPathPreset Directly

Hypothesis:

```text
Add centerPattern directly to the existing ProjectPathPreset model.
```

Impact:

```text
- JSON impact: immediate schema change to a legacy contract.
- Legacy compatibility: risky because existing presets currently mean variant mappings only.
- Migration complexity: high, because old presets need default center behavior.
- Path Painter simplicity: superficially simpler because presetId can keep pointing to the same model.
- Legacy flow risk: high; old path editing, mapping, generated files, and fixtures can churn.
```

Decision:

```text
Do not start here.
```

Reason:

```text
The center behavior is now characterized, but preview, painter, and JSON are not locked.
Changing ProjectPathPreset now would front-load schema risk.
```

### Option B - Create ProjectPathPatternPreset Separately

Hypothesis:

```text
Create a separate model that adds centerPattern and can reference or snapshot legacy path mappings.
```

Impact:

```text
- Legacy compatibility: strong; ProjectPathPreset remains unchanged.
- Model clarity: strong; PathPattern is explicit.
- UI integration: requires a bridge in Path Studio / Path Painter.
- Duplication risk: moderate; old path preset and new pattern preset concepts must be explained.
- Rollback: good; new model can be removed without rewriting existing path presets.
```

Decision:

```text
Good later step, but not Lot 1.
```

Reason:

```text
The model should wait until value objects, resolver, preview, and compatibility adapter are tested.
```

### Option C - In-Memory Adapter First

Hypothesis:

```text
Create non-persistent value objects for center patterns.
Adapt ProjectPathPreset in memory as center 1x1.
Defer manifest and JSON.
```

Impact:

```text
- Safety: highest; no schema change.
- Iteration speed: high; pure tests can prove the center model and resolver.
- UI limit: cannot save real project presets yet, but that is acceptable before preview/painter proof.
- Future manifest: still open, but informed by tests.
- Rendering proof: possible before persistence.
```

Decision:

```text
Recommended first implementation step.
```

Reason:

```text
It lets PathPattern prove the core idea without touching JSON, ProjectManifest, runtime, or gameplay.
```

## 8. Décision Recommandée

Recommended sequence:

```text
1. Option C now:
   pure non-persistent value objects for center patterns.

2. Legacy adapter next:
   ProjectPathPreset -> center pattern 1x1 view.

3. Option B later:
   ProjectPathPatternPreset after resolver and previews are proven.

4. Avoid Option A until there is a deliberate schema migration reason.
```

Interior-fill anchor:

```text
Use TerrainPathVariant.cross as the legacy full-area interior source for 1x1 compatibility,
but do not use only `variant == cross` to detect center cells.
```

Recommended center-fill predicate for future rendering:

```text
active current cell
all four cardinal neighbors active
all four diagonal neighbors active
```

This keeps a plus-shaped four-way junction on legacy `cross`.

Open edge-case:

```text
Map-edge fill cells can currently resolve to cross.
Lot 2 or Lot 15 must decide whether edge fill cells use center pattern or stay legacy when a painted area touches map bounds.
```

## 9. Modèle Mental Cible

No model was implemented in this lot.

Minimal future model:

```text
PathCenterPattern
- size: width x height
- cells: List<PathCenterPatternCell>
```

```text
PathCenterPatternCell
- localX
- localY
- frames: List<TilesetVisualFrame>
```

Compatibility:

```text
ProjectPathPreset legacy
-> center pattern 1x1
-> cell frames come from TerrainPathVariant.cross for full-area interior compatibility
```

Important:

```text
ProjectPathPreset.isolated must remain the single-cell island visual.
It must not be reinterpreted as the filled-area center.
```

## 10. Décision Coordonnées Absolues Vs Relatives

Recommended V0:

```text
Use absolute map coordinates: mapX/mapY.
```

Formula:

```text
patternX = mapX % patternWidth
patternY = mapY % patternHeight
```

Reason:

```text
- deterministic across paint sessions;
- stable when the user erases part of a zone;
- no connected-component scan needed;
- simpler to test;
- matches tilemap-style global animated water patterns.
```

Rejected for V0:

```text
Relative coordinates to the painted component.
```

Reason:

```text
Relative component coordinates would shift when a zone splits, merges, or is edited.
That behavior can be useful later, but it is too stateful for the first PathPattern slice.
```

Negative-coordinate contract remains for Lot 2:

```text
Current maps use bounded non-negative GridPos.
Lot 2 should either reject negative coordinates or document positive modulo.
```

## 11. Transparence : Décision Différée

Transparency is not implemented in this lot.

Future rules:

```text
- no hardcoded color;
- configurable RGB value;
- in-memory application only;
- source image never modified;
- no derived image created automatically.
```

Future lot:

```text
PathPattern-4 - Tileset Transparent Color
```

## 12. Roadmap Corrigée Sans Ancien Axe D’Import

The active roadmap was modified:

```text
reports/pathPattern/path_pattern_roadmap.md
```

Corrected roadmap:

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

Roadmap verification command:

```bash
rg -n "TSX|TMX|Mistral|PixelLab|Surface Studio" reports/pathPattern/path_pattern_roadmap.md || true
```

Output:

```text
<empty>
```

## 13. Tests Lancés

Targeted characterization test:

```bash
cd packages/map_core && dart test test/map_terrain_autotile_characterization_test.dart --reporter expanded
```

Final line:

```text
00:00 +21: All tests passed!
```

Global map_core test command:

```bash
cd packages/map_core && dart test
```

Final line:

```text
00:02 +1027: All tests passed!
```

## 14. Analyze

Command:

```bash
cd packages/map_editor && flutter analyze lib/src/application/models/path_autotile_set.dart lib/src/application/services/path_autotile_resolver.dart
```

Output:

```text
Analyzing 2 items...
No issues found! (ran in 0.5s)
```

## 15. Non-Objectifs Confirmés

Confirmed:

```text
- no new UI;
- no Path Studio UI;
- no runtime modification;
- no gameplay modification;
- no MapGameplayZone work;
- no ProjectManifest modification;
- no direct ProjectPathPreset modification;
- no persistent model;
- no JSON;
- no generated files;
- no build_runner;
- no image source modification;
- no Surface Painter deletion;
- no SurfaceLayer deletion;
- no map_runtime modification;
- no map_gameplay modification;
- no map_battle modification.
```

## 16. Limites Restantes

Remaining risks before Lot 1:

```text
- cross is overloaded: full-area interior and four-way junction both resolve to cross;
- map-edge fill promotion to cross needs a future explicit rule;
- negative coordinate modulo contract is not decided;
- basePathPresetId vs copied legacy mappings is not decided for the future persistent model;
- preview is not built yet, so model ergonomics are not visually proven.
```

## 17. Git Status Final

```text
 M reports/pathPattern/path_pattern_roadmap.md
?? reports/pathPattern/path_pattern_lot_00_center_variant_audit_decision.md
```

Diff stat:

```text
reports/pathPattern/path_pattern_roadmap.md | 241 +++++++++++++---------------
1 file changed, 109 insertions(+), 132 deletions(-)
```

Name status:

```text
M	reports/pathPattern/path_pattern_roadmap.md
```

## Auto-review

Ai-je réellement prouvé le variant du centre ?

```text
Yes. Existing characterization test `full 3x3 block center is cross and edges receive border fill`
was cited and run. It proves the full-area center resolves to TerrainPathVariant.cross.
```

Ai-je supprimé les anciens imports externes de la roadmap ?

```text
Yes. The active roadmap has no matches for the old import/AI/removed-studio terms checked by rg.
```

Ai-je évité toute UI ?

```text
Yes. No UI source file was modified.
```

Ai-je évité runtime/gameplay ?

```text
Yes. No runtime, gameplay, or battle package was modified.
```

Ai-je évité modification ProjectManifest ?

```text
Yes. ProjectManifest was inspected only.
```

Quels risques restent avant le Lot 1 ?

```text
The main risk is the overloaded meaning of TerrainPathVariant.cross.
Lot 1 can define value objects safely, but Lot 2 must avoid a naive `variant == cross`
center-detection rule.
```

## Critique du prompt

Ambiguities:

```text
- The prompt allows a characterization test only if none exists; an existing test does exist, so no new test was added.
- The prompt requests complete contents and real diffs when files are created/modified. The created final report is this document; the modified roadmap content and real diff are included below.
- The prompt asks to remove the old import terms from the roadmap, but the auto-review asks to confirm their removal. This report mentions them only in the removal/verification context, not as a product axis.
```

Decisions taken because of those ambiguities:

```text
- Reused the existing characterization test instead of adding a duplicate.
- Changed only the roadmap and this report.
- Recommended absolute map coordinates for V0.
```

Points to validate before Lot 1:

```text
- Keep the name PathCenterPattern for value objects.
- Confirm that Lot 1 remains non-persistent.
- Confirm that edge-fill cross behavior can wait until resolver/render lots.
```

## Evidence Pack

### Files Created / Modified / Deleted

Created:

```text
reports/pathPattern/path_pattern_lot_00_center_variant_audit_decision.md
```

Modified:

```text
reports/pathPattern/path_pattern_roadmap.md
```

Deleted:

```text
none
```

### Complete Modified Roadmap Content

````md
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
````

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
````

### Complete Roadmap Diff

````diff
diff --git a/reports/pathPattern/path_pattern_roadmap.md b/reports/pathPattern/path_pattern_roadmap.md
index cb10fb3c..97ad3e59 100644
--- a/reports/pathPattern/path_pattern_roadmap.md
+++ b/reports/pathPattern/path_pattern_roadmap.md
@@ -4,7 +4,7 @@ Date: 2026-04-30
 
 ## Decision
 
-The active product direction is now deliberately small:
+The active product direction is deliberately small:
 
 ```text
 Path Studio.
@@ -13,14 +13,10 @@ Then tall grass.
 Nothing else.
 ```
 
-This roadmap does not recreate Surface Studio and does not use TSX, TMX,
-Pokemon SDK imports, Mistral, PixelLab, MCP, or external map import flows as
-product objectives.
-
 ## Starting Point
 
-Surface Studio and the TSX authoring workspace were purged from the active
-editor UI. The useful foundations remain:
+The previous complex authoring workspace has been removed from the active
+editor path. The useful foundations remain:
 
 - `packages/map_core` Surface models;
 - `ProjectManifest.surfaceCatalog`;
@@ -29,8 +25,8 @@ editor UI. The useful foundations remain:
 - existing runtime Surface support;
 - existing Surface to GameplayZone bridge.
 
-The new work should build on the system that already behaves best in the
-editor: Path / Path Painter.
+The new work builds on the system that already behaves best in the editor:
+Path / Path Painter.
 
 ## Product Goal
 
@@ -59,13 +55,12 @@ patternX = mapX % 2
 patternY = mapY % 2
 ```
 
-Important compatibility note:
+Compatibility warning:
 
 ```text
 Do not assume isolated = center.
 The current path resolver must be audited first.
-The interior of a full block currently resolves through the legacy path
-variant system, and Lot 0 must identify the real variant used.
+Lot 0 identifies the real variant used by a full-area interior cell.
 ```
 
 ## Reports
@@ -117,11 +112,10 @@ Touch `packages/map_runtime` only in lots explicitly marked runtime.
 Do not:
 
 ```text
-- recreate Surface Studio;
-- recreate TSX/TMX authoring;
-- add Mistral;
-- add PixelLab;
-- add MCP;
+- recreate the removed authoring workspace;
+- add external map import flows;
+- add AI grouping;
+- add image generation workflows;
 - add gameplay to visual presets;
 - mutate ProjectManifest directly from UI flows;
 - write project files automatically.
@@ -148,71 +142,60 @@ Each lot report should contain:
 | --- | ---: | --- |
 | A - Decision and minimal model | 0-3 | Decide center anchor, define pure center pattern objects, keep legacy compatible |
 | B - Transparency and preview | 4-6 | Transparent color, static preview, animated preview |
-| C - Persistence and manifest | 7-10 | Minimal project model, external JSON codec, manifest integration, manifest ops |
-| D - Path Studio UI | 11-14 | Shell, center pattern editor, save flow, painter integration |
-| E - Water closure | 15-17 | Editor canvas render, runtime render, internal water 2x2 golden slice |
-| F - Tall grass | 18-20 | Decide, author, and bridge tall grass cleanly |
+| C - Persistence and manifest | 7-11 | Project model, codec, golden JSON decision, manifest integration, manifest ops |
+| D - Path Studio UI | 12-15 | Shell, center pattern editor, save flow, painter integration |
+| E - Water closure | 16-18 | Editor canvas render, runtime render, internal water 2x2 golden slice |
+| F - Tall grass | 19-21 | Decide, author, and bridge tall grass cleanly |
 
 ## Strict Order
 
 ```text
-0  Path Studio Center Pattern Decision
-1  Path Center Pattern Value Objects
-2  Path Center Pattern Resolver
-3  Legacy Path Preset Center Adapter
+0  Center Variant Audit / Decision
+1  Center Pattern Value Objects
+2  Center Pattern Resolver
+3  Legacy ProjectPathPreset Adapter
 4  Tileset Transparent Color
-5  Path Center Pattern Static Preview
-6  Path Center Pattern Animated Preview
+5  Static Preview
+6  Animated Preview
 7  ProjectPathPatternPreset Model
-8  ProjectPathPatternPreset JSON Codec
-9  ProjectManifest PathPattern Integration
-10 PathPattern Manifest Operations
-11 Path Studio Shell
-12 Path Studio Center Pattern Editor
-13 Path Studio Save Flow
-14 Path Painter Integration
-15 Editor Canvas PathPattern Render
-16 Runtime PathPattern Render
-17 Water 2x2 Golden Slice
-18 Tall Grass PathPattern Decision
-19 Tall Grass PathPattern Authoring
-20 Tall Grass Gameplay Bridge
+8  JSON Codec
+9  Manifest Decision / Golden JSON
+10 Manifest Integration
+11 Manifest Operations
+12 Path Studio Shell
+13 Center Pattern Editor
+14 Save Flow
+15 Path Painter Integration
+16 Editor Canvas Render
+17 Runtime Render
+18 Water 2x2 Golden Slice
+19 Tall Grass Decision
+20 Tall Grass Authoring
+21 Tall Grass Gameplay Bridge
 ```
 
-## Lot 0 - Path Studio Center Pattern Decision V0
+## Lot 0 - Center Variant Audit / Decision
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_00_center_pattern_decision.md
+reports/pathPattern/path_pattern_lot_00_center_variant_audit_decision.md
 ```
 
 Goal:
 
 ```text
-Decide how to let the existing Path system support a multi-cell center fill.
-```
-
-Lot 0 must answer:
-
-```text
-- where ProjectPathPreset and TerrainPathVariant are defined;
-- how path variants are stored;
-- whether variants store one frame or frame lists;
-- which variant is actually used by the current resolver for the interior of a full painted block;
-- where the editor resolves and draws path frames;
-- where a center pattern can be inserted without changing borders, corners, junctions, gameplay, or runtime.
+Understand how the current Path resolver chooses variants and identify the
+actual variant used for the interior of a full painted area.
 ```
 
-Expected recommendation:
+Required output:
 
 ```text
-Create a separate ProjectPathPatternPreset later.
-Adapt existing ProjectPathPreset entries as center 1x1.
-Keep V0 center-only; bords/corners/junctions remain legacy.
+Cellule intérieure pleine -> TerrainPathVariant.<exact name>
 ```
 
-## Lot 1 - Path Center Pattern Value Objects V0
+## Lot 1 - Center Pattern Value Objects
 
 Report:
 
@@ -223,16 +206,15 @@ reports/pathPattern/path_pattern_lot_01_center_pattern_value_objects.md
 Goal:
 
 ```text
-Create pure map_core value objects for the center pattern only.
+Create pure non-persistent value objects for the center pattern only.
 ```
 
 Expected objects:
 
 ```text
-PathCenterPatternSize
-PathCenterPatternCellCoordinate
-PathCenterPatternCell
 PathCenterPattern
+PathCenterPatternCell
+PathCenterPatternSize or equivalent
 ```
 
 Rules:
@@ -243,11 +225,11 @@ Rules:
 - cells cover exactly every local coordinate;
 - no duplicate localX/localY;
 - each cell contains List<TilesetVisualFrame>;
-- no JSON yet;
+- no JSON;
 - no manifest change.
 ```
 
-## Lot 2 - Path Center Pattern Resolver V0
+## Lot 2 - Center Pattern Resolver
 
 Report:
 
@@ -261,21 +243,19 @@ Goal:
 Resolve map coordinates to a center pattern cell.
 ```
 
-Rule:
+Recommended V0 rule:
 
 ```text
 patternX = mapX modulo pattern.width
 patternY = mapY modulo pattern.height
 ```
 
-The lot must define the negative-coordinate contract explicitly.
-
-## Lot 3 - Legacy Path Preset Center Adapter V0
+## Lot 3 - Legacy ProjectPathPreset Adapter
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_03_legacy_center_adapter.md
+reports/pathPattern/path_pattern_lot_03_legacy_project_path_preset_adapter.md
 ```
 
 Goal:
@@ -291,10 +271,10 @@ Rules:
 - preserve frame order and durationMs;
 - preserve frame tilesetId overrides;
 - preserve legacy variants for borders/corners/junctions;
-- do not add JSON.
+- no JSON.
 ```
 
-## Lot 4 - Tileset Transparent Color V0
+## Lot 4 - Tileset Transparent Color
 
 Report:
 
@@ -305,7 +285,7 @@ reports/pathPattern/path_pattern_lot_04_tileset_transparent_color.md
 Goal:
 
 ```text
-Add configurable transparent color support, for example f05ba1, without hardcoding any specific color.
+Add configurable transparent color support without hardcoding any specific color.
 ```
 
 Rules:
@@ -318,12 +298,12 @@ Rules:
 - never create derived images automatically.
 ```
 
-## Lot 5 - Path Center Pattern Static Preview V0
+## Lot 5 - Static Preview
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_05_center_pattern_static_preview.md
+reports/pathPattern/path_pattern_lot_05_static_preview.md
 ```
 
 Goal:
@@ -341,12 +321,12 @@ Rules:
 - provide a fallback when image bytes are unavailable.
 ```
 
-## Lot 6 - Path Center Pattern Animated Preview V0
+## Lot 6 - Animated Preview
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_06_center_pattern_animated_preview.md
+reports/pathPattern/path_pattern_lot_06_animated_preview.md
 ```
 
 Goal:
@@ -359,12 +339,12 @@ Rules:
 
 ```text
 - preview only;
-- no Flame runtime;
+- no runtime rendering;
 - one-frame cells stay stable;
 - timelines use a shared elapsedMs.
 ```
 
-## Lot 7 - ProjectPathPatternPreset Model V0
+## Lot 7 - ProjectPathPatternPreset Model
 
 Report:
 
@@ -396,15 +376,15 @@ Rules:
 ```text
 - do not modify ProjectManifest in this lot;
 - do not modify ProjectPathPreset;
-- no JSON yet.
+- no JSON.
 ```
 
-## Lot 8 - ProjectPathPatternPreset JSON Codec V0
+## Lot 8 - JSON Codec
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_08_project_path_pattern_json_codec.md
+reports/pathPattern/path_pattern_lot_08_json_codec.md
 ```
 
 Goal:
@@ -422,18 +402,32 @@ Rules:
 - transparentColor encoded only when present.
 ```
 
-## Lot 9 - ProjectManifest PathPattern Integration V0
+## Lot 9 - Manifest Decision / Golden JSON
+
+Report:
+
+```text
+reports/pathPattern/path_pattern_lot_09_manifest_decision_golden_json.md
+```
+
+Goal:
+
+```text
+Decide the manifest shape and lock golden JSON samples before integration.
+```
+
+## Lot 10 - Manifest Integration
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_09_manifest_path_pattern_integration.md
+reports/pathPattern/path_pattern_lot_10_manifest_integration.md
 ```
 
 Goal:
 
 ```text
-Add pathPatternPresets to ProjectManifest after the model and codec are covered.
+Add PathPattern presets to ProjectManifest after the model, codec, and golden JSON decision are covered.
 ```
 
 Rules:
@@ -444,12 +438,12 @@ Rules:
 - generated code only for touched map_core models if the current style requires it.
 ```
 
-## Lot 10 - PathPattern Manifest Operations V0
+## Lot 11 - Manifest Operations
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_10_manifest_operations.md
+reports/pathPattern/path_pattern_lot_11_manifest_operations.md
 ```
 
 Goal:
@@ -458,12 +452,12 @@ Goal:
 Pure helpers for read, replace, upsert, remove, and clear.
 ```
 
-## Lot 11 - Path Studio Shell V0
+## Lot 12 - Path Studio Shell
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_11_path_studio_shell.md
+reports/pathPattern/path_pattern_lot_12_path_studio_shell.md
 ```
 
 Goal:
@@ -484,17 +478,17 @@ Path Studio
 Rules:
 
 ```text
-- no Surface Studio;
-- no placeholder promising unsupported actions;
+- no complete pattern editor;
+- no unsupported primary actions;
 - no save to disk.
 ```
 
-## Lot 12 - Path Studio Center Pattern Editor V0
+## Lot 13 - Center Pattern Editor
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_12_center_pattern_editor.md
+reports/pathPattern/path_pattern_lot_13_center_pattern_editor.md
 ```
 
 Goal:
@@ -512,12 +506,12 @@ V0 UX:
 - transparent color display/config if already available.
 ```
 
-## Lot 13 - Path Studio Save Flow V0
+## Lot 14 - Save Flow
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_13_save_flow.md
+reports/pathPattern/path_pattern_lot_14_save_flow.md
 ```
 
 Goal:
@@ -534,12 +528,12 @@ Rules:
 - no direct disk write.
 ```
 
-## Lot 14 - Path Painter Integration V0
+## Lot 15 - Path Painter Integration
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_14_path_painter_integration.md
+reports/pathPattern/path_pattern_lot_15_path_painter_integration.md
 ```
 
 Goal:
@@ -548,12 +542,12 @@ Goal:
 Let users select and paint a PathPattern preset without breaking legacy Path Painter.
 ```
 
-## Lot 15 - Editor Canvas PathPattern Render V0
+## Lot 16 - Editor Canvas Render
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_15_editor_canvas_render.md
+reports/pathPattern/path_pattern_lot_16_editor_canvas_render.md
 ```
 
 Goal:
@@ -570,12 +564,12 @@ Rules:
 - borders/corners/junctions remain legacy.
 ```
 
-## Lot 16 - Runtime PathPattern Render V0
+## Lot 17 - Runtime Render
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_16_runtime_render.md
+reports/pathPattern/path_pattern_lot_17_runtime_render.md
 ```
 
 Goal:
@@ -587,17 +581,17 @@ Render PathPattern visually in runtime.
 Rules:
 
 ```text
-- map_runtime only;
+- runtime package only;
 - no gameplay;
 - preserve layer ordering.
 ```
 
-## Lot 17 - Water 2x2 Golden Slice V0
+## Lot 18 - Water 2x2 Golden Slice
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_17_water_2x2_golden_slice.md
+reports/pathPattern/path_pattern_lot_18_water_2x2_golden_slice.md
 ```
 
 Goal:
@@ -610,18 +604,16 @@ Rules:
 
 ```text
 - internal fixture;
-- no TSX;
-- no TMX;
 - transparent color configurable;
 - editor preview, paint, and runtime visual slice.
 ```
 
-## Lot 18 - Tall Grass PathPattern Decision V0
+## Lot 19 - Tall Grass Decision
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_18_tall_grass_decision.md
+reports/pathPattern/path_pattern_lot_19_tall_grass_decision.md
 ```
 
 Goal:
@@ -630,12 +622,12 @@ Goal:
 Decide whether tall grass should be visual PathPattern plus explicit gameplay zone association.
 ```
 
-## Lot 19 - Tall Grass PathPattern Authoring V0
+## Lot 20 - Tall Grass Authoring
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_19_tall_grass_authoring.md
+reports/pathPattern/path_pattern_lot_20_tall_grass_authoring.md
 ```
 
 Goal:
@@ -644,12 +636,12 @@ Goal:
 Create a simple tall grass visual preset flow.
 ```
 
-## Lot 20 - Tall Grass Gameplay Bridge V0
+## Lot 21 - Tall Grass Gameplay Bridge
 
 Report:
 
 ```text
-reports/pathPattern/path_pattern_lot_20_tall_grass_gameplay_bridge.md
+reports/pathPattern/path_pattern_lot_21_tall_grass_gameplay_bridge.md
 ```
 
 Goal:
@@ -658,27 +650,12 @@ Goal:
 Associate tall grass visuals with encounter gameplay cleanly, without hiding gameplay inside visual presets.
 ```
 
-## Removed From This Roadmap
-
-The following are intentionally out:
-
-```text
-TSX Import Lite
-TMX import
-Mistral grouping
-PixelLab
-Surface Studio
-Surface TSX builder
-Golden Slice Exterior TMX
-runtime import of external maps
-```
-
 ## Visual Milestones
 
 ```text
 Lot 5: static center preview
 Lot 6: animated center preview
-Lot 12: editable center pattern
-Lot 14: paintable PathPattern preset
-Lot 17: water 2x2 slice
+Lot 13: editable center pattern
+Lot 15: paintable PathPattern preset
+Lot 18: water 2x2 slice
 ```
````
