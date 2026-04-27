# Element Collision Final Pass

## Need Restated

The goal of this last pass was **not** to make padding smarter.

The goal was to make the system honest and coherent:

- padding remains available for simple/generated cases
- a building polygon becomes the real primary collision base
- local brush edits remain additive/subtractive retouches
- the runtime contract stays unchanged and continues to read only
  `collisionProfile.cells`

## Product Invariants

The final model is now explicitly:

### Generated/simple case

```text
base = padding
final = base + manualAddedCells - manualRemovedCells
```

### Building / author-shape case

```text
base = shapeCells
final = base + manualAddedCells - manualRemovedCells
```

Important:

- when `source == manual`, padding no longer silently regains control
- changing padding updates the stored secondary helper, but does not overwrite
  the authored primary shape
- the only runtime truth remains `collisionProfile.cells`

## Code Changes

### 1. Model comments clarified

File:

- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart)

Updated documentation to make the contract explicit:

- `shapeCells` is the primary author base when `source == manual`
- padding is only a secondary helper in that mode
- `manualAddedCells` / `manualRemovedCells` are retouches on top of the
  **current primary base**, not always on top of a padding rectangle

### 2. Authoring service clarified

File:

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart)

Changes:

- comments now describe the intended split between:
  - generated base from padding
  - manual primary shape for complex buildings
- added:
  - `usePaddingAsPrimaryBase(...)`

This method exists for one explicit product action only:

- the user deliberately wants to go back to a simple padding-driven base

That behavior is now distinct from:

- `recalculateFromPadding(...)`

This distinction matters:

- `recalculateFromPadding(...)` should **not** steal control from a manual
  primary shape
- `usePaddingAsPrimaryBase(...)` is the explicit switch back to generated mode

Also added:

- `ElementCollisionAuthoringSnapshot.usesManualPrimaryShape`

This lets the UI speak honestly about the current mode.

### 3. Collision editor UI made explicit

File:

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart)

Changes:

- the old action `Restaurer base padding` now maps to an explicit mode switch:
  - `Utiliser le padding comme base`
- the sidebar summary now distinguishes:
  - `Forme principale`
  - `Base padding`
- the helper text now clearly states:
  - manual shape = current business base
  - padding = secondary helper
- display toggles no longer call the manual base “Base auto”
- tooltips/help labels now describe:
  - polygon = main shape definition
  - brush = local retouching
  - preview = exact saved final form
- the padding editor explanation now changes depending on mode:
  - in manual mode: padding is stored but does not redefine the base
  - in generated mode: padding is the active automatic base

### 4. Element summary card wording updated

File:

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)

Changes:

- summary text now explains whether the element currently uses:
  - a manual primary shape
  - or a generated padding base
- the legend chip now says `Forme` when the manual author base is active

This removes the misleading impression that padding remains the dominant
mechanism for complex buildings.

## Tests Added

File:

- [/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart)

New tests:

### `recalculateFromPadding does not replace a manual primary shape with the padding base`

This proves:

- manual primary shape survives padding edits
- padding is updated as stored data
- the final collision still comes from the author shape plus retouches

### `usePaddingAsPrimaryBase explicitly switches back to generated mode`

This proves:

- we still support the simple/generated workflow
- switching back is now an explicit user action
- the mode is no longer ambiguous

## Why This Correction Is the Right One

The runtime contract is still:

- `collisionProfile.cells`

That did not change.

What changed is the **authoring honesty**:

- we no longer pretend that padding is the main answer for sloped-roof
  buildings
- we no longer let padding silently reclaim the base when a manual building
  shape exists
- the editor wording now matches the actual business behavior

## What Was Intentionally Not Changed

We deliberately did **not**:

- introduce sub-tile collision
- introduce polygon collision in runtime
- introduce pixel-perfect collision
- change Flame/gameplay runtime
- add image analysis or smart silhouette extraction

Those would be different projects with different runtime contracts.

## Validation Executed

Formatting:

- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart format ...`

Tests:

- `/opt/homebrew/bin/flutter test test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart`

Analyze:

- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart analyze lib/src/models/element_collision_profile.dart`
- `/opt/homebrew/bin/flutter analyze lib/src/application/services/element_collision_authoring_service.dart lib/src/ui/panels/element_collision_editor_sheet.dart lib/src/ui/panels/tileset_palette_panel.dart test/element_collision_authoring_service_test.dart --no-fatal-infos`

## Validation Result

Passing:

- targeted format: passed
- targeted tests: passed
- targeted `dart analyze` on `map_core`: passed

Non-blocking infos remain in `map_editor`:

- several existing `prefer_const_*`
- several existing `minSize` deprecation infos in
  `tileset_palette_panel.dart`

These are analyzer infos only and are not caused by a runtime collision
contract regression.

## Final Outcome

The system is now coherent and honest:

- padding still exists
- but it is secondary for complex buildings
- the author shape is the real primary base in manual mode
- local retouches still work cleanly
- the final saved truth remains exactly `collisionProfile.cells`
- runtime remains unchanged

No Git operation was performed.
