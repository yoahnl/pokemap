# Element Collision Cells + Padding Overrides Report

## Executive Summary

This lot intentionally narrows the element collision system back to a simple, deterministic, grid-based model:

- automatic base cells come only from existing padding
- authors can add cells manually
- authors can remove cells manually
- runtime/gameplay still read only `collisionProfile.cells`

The final rule is:

```text
finalCells = (baseCells + manualAddedCells) - manualRemovedCells
```

No image analysis, no alpha mask, no pixel-perfect collision, no runtime occlusion logic, and no gameplay refactor were introduced.

## Need Reframed

The project already had the correct high-level runtime contract:

- placed elements expose `collisionProfile.cells`
- gameplay/runtime consume those cells directly
- padding already exists as a simple author-facing concept

The real missing piece was not a smarter engine. It was a safer authoring workflow:

- derive a simple base shape from padding
- let the author retouch locally with cell brushes
- keep the runtime contract unchanged
- make the result recalculable when padding changes

## Why The Previous Direction Was Wrong

The previous generator in `map_editor` inspected sprite pixels and tried to infer collisions from image coverage. That direction was a poor fit for the stated product need because it introduced:

- image-dependent behavior
- heuristic thresholds
- preset-specific shape clipping rules
- unnecessary complexity in a system that only needs final blocking cells

This lot deliberately removes that drift. Collision authoring is now explicit and grid-based again.

## Solution Chosen

### Core Model

`map_core` now persists:

- `cells`: final runtime truth
- `manualAddedCells`: explicit author additions
- `manualRemovedCells`: explicit author removals
- `padding`: existing automatic base descriptor

This keeps author intent available while preserving runtime simplicity.

### Application Services

Three small services were introduced in `map_editor`:

1. `ElementCollisionBaseCellsFromPaddingService`
   - derives base cells from `TilesetSourceRect`, tile size, and `WarpTriggerPadding`

2. `ElementCollisionCellsOverlayService`
   - applies the overlay rule
   - normalizes order and uniqueness

3. `ElementCollisionAuthoringService`
   - editor-facing facade
   - rebuilds coherent profiles
   - exposes add/remove/reset/clear behavior for the UI

### UI

The element collision editor remains tile-based and now exposes:

- preview mode
- add mode
- remove mode
- base/add/remove/final visual layers
- explicit actions:
  - recalculate + keep overrides
  - reset overrides
  - restore base only
  - clear all collision

Padding changes now recompute the base immediately and reapply overrides deterministically.

## Architecture Details

### `map_core`

The runtime-facing model remains `ElementCollisionProfile`.

Important invariant:

- runtime/gameplay still know only `profile.cells`

New model fields are authoring metadata only. They are never required by gameplay.

### `map_editor` Application Layer

The editor now owns all override semantics. This is the only place where:

- base cells are derived
- author overrides are interpreted
- final cells are rebuilt

That keeps runtime concerns clean and avoids a second collision truth.

### `map_editor` UI Layer

The collision editor widget only orchestrates explicit author actions.

Complex logic was not hidden in the widget tree; it calls `ElementCollisionAuthoringService` for:

- add mode taps
- remove mode taps
- padding recalculation
- reset/restore/clear actions

### Runtime Consumption

Confirmed unchanged:

- [`packages/map_gameplay/lib/src/gameplay_world_state.dart`](/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart)
- [`packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart)

Both still iterate only over `profile.cells`.

## Algorithms

### 1. Base Cells From Padding

The base service computes a trimmed active rectangle:

- full source size in pixels = `source.width * tileWidth`, `source.height * tileHeight`
- apply padding on left/right/top/bottom
- for each source-grid cell, keep it if its tile rectangle still intersects the trimmed rectangle

This is intentionally conservative and easy to explain.

### 2. Overlay Rule

Overlay service logic:

```text
start with baseCells
add manualAddedCells
remove manualRemovedCells
deduplicate
sort by y then x
```

### 3. Profile Reconstruction

Authoring service:

1. derives base cells from padding
2. normalizes overrides inside source bounds
3. applies overlay
4. writes final cells into `ElementCollisionProfile.cells`

If overrides are empty, profile source is marked `generated`.  
If overrides exist, profile source is marked `manual`.

## Product / Data Invariants

- Collision remains case-based only.
- Padding remains the automatic base input.
- `cells` stays the sole runtime truth.
- Overrides are editor-only metadata.
- Padding changes always rebuild the profile deterministically.
- Cell lists are normalized:
  - unique
  - bounded
  - sorted by `y`, then `x`

## Files Created

- [`packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart)
- [`packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart)
- [`packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart)
- [`packages/map_editor/test/element_collision_authoring_service_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart)
- [`packages/map_core/test/element_collision_profile_model_test.dart`](/Users/karim/Project/pokemonProject/packages/map_core/test/element_collision_profile_model_test.dart)
- [`reports/element-collision-padding-overrides-report.md`](/Users/karim/Project/pokemonProject/reports/element-collision-padding-overrides-report.md)

## Files Modified

- [`packages/map_core/lib/src/models/element_collision_profile.dart`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart)
  - added `manualAddedCells` and `manualRemovedCells`

- [`packages/map_core/lib/src/validation/validators.dart`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart)
  - validates final cells and override cell lists

- [`packages/map_core/lib/src/models/element_collision_profile.freezed.dart`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.freezed.dart)
  - regenerated

- [`packages/map_core/lib/src/models/element_collision_profile.g.dart`](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.g.dart)
  - regenerated

- [`packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart)
  - converted into a compatibility facade
  - no image analysis anymore
  - keeps preset-to-padding defaults only

- [`packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
  - UI now edits explicit add/remove overrides
  - padding changes rebuild collisions immediately
  - preview shows base/add/remove/final layers

## Important Code Excerpts

### Final Overlay Rule

From the overlay service:

```dart
final merged = <String, GridPos>{
  for (final cell in _normalize(baseCells)) _key(cell): cell,
};

for (final cell in _normalize(manualAddedCells)) {
  merged[_key(cell)] = cell;
}

for (final cell in _normalize(manualRemovedCells)) {
  merged.remove(_key(cell));
}
```

### Deterministic Rebuild

From the authoring facade:

```dart
final baseCells = baseCellsFromPaddingService.derive(
  source: source,
  tileWidth: tileWidth,
  tileHeight: tileHeight,
  padding: padding,
);
final finalCells = cellsOverlayService.apply(
  baseCells: baseCells,
  manualAddedCells: manualAdded,
  manualRemovedCells: manualRemoved,
);
```

## Edge Cases Covered

- duplicate cells in base/add/remove lists
- out-of-bounds override cells
- removing a cell that is not currently present
- adding a cell already present
- extreme padding that trims the whole source
- recalculation after padding changes

## What Was Explicitly Refused

This lot explicitly refused:

- pixel-perfect collision
- alpha-mask-based collision
- visual mask / occlusion mask systems
- image analysis / heuristic roof-shadow detection
- OpenCV / AI / segmentation
- runtime Flame collision refactor
- movement logic changes
- speed / walk system changes
- alternate runtime collision truths

These were rejected because they do not solve the actual product need and would increase complexity without improving author control.

## Tests Added

### `map_editor`

[`packages/map_editor/test/element_collision_authoring_service_test.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart)

Covered:

- base derivation from padding
- add overlay
- remove overlay
- combined add/remove behavior
- stable uniqueness and ordering
- rebuild with no overrides
- recalc after padding changes
- reset overrides
- add mode behavior
- remove mode behavior
- clear-all behavior

### `map_core`

[`packages/map_core/test/element_collision_profile_model_test.dart`](/Users/karim/Project/pokemonProject/packages/map_core/test/element_collision_profile_model_test.dart)

Covered:

- serialization roundtrip with manual overrides
- backward compatibility with legacy JSON that has no override fields

### Runtime Safety Check

Existing gameplay collision test re-run:

- [`packages/map_gameplay/test/placed_elements_collision_test.dart`](/Users/karim/Project/pokemonProject/packages/map_gameplay/test/placed_elements_collision_test.dart)

This confirms gameplay still operates through `collisionProfile.cells`.

## Validation Executed

Executed successfully:

1. `dart run build_runner build --delete-conflicting-outputs` in `packages/map_core`
2. `dart test test/element_collision_profile_model_test.dart` in `packages/map_core`
3. `dart analyze lib/src/models/element_collision_profile.dart lib/src/validation/validators.dart test/element_collision_profile_model_test.dart` in `packages/map_core`
4. `flutter test test/element_collision_authoring_service_test.dart` in `packages/map_editor`
5. `dart test test/placed_elements_collision_test.dart` in `packages/map_gameplay`

Also executed:

- targeted `flutter analyze` on the changed `map_editor` files

Result:

- no errors introduced by this lot
- `tileset_palette_panel.dart` still carries pre-existing info-level lints outside this scope

## Limits Remaining

- The collision editor UI was improved locally inside the existing panel, not extracted into its own dedicated screen/module.
- `Restaurer base seule` and `Reinitialiser retouches` currently resolve to the same underlying behavior because both mean “clear overrides and rebuild from padding”.
- The compatibility facade `ElementCollisionProfileGenerator` still exists to avoid a wider notifier/UI refactor in this lot.

## Safe Future Improvements

Without breaking the chosen direction, future work could add:

- a small dedicated authoring state object for the collision sheet
- a focused widget test around the collision editor controls
- a compact legend/help panel explaining the four layers more visually
- migration tooling if old projects need profile normalization at load time

## Final Assessment

The resulting system is simpler than the previous one:

- no image heuristics
- no gameplay changes
- no runtime contract changes
- explicit author intent
- deterministic recalculation

That matches the requested direction exactly: a small, local, explainable evolution of the existing collision system.
