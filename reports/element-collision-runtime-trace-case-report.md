# Element Collision Runtime Trace Report

## Executive Summary

The real bug was **not** that `map_gameplay` read the wrong source of truth.  
In this checkout, gameplay and runtime **do** read `collisionProfile.cells`.

The real bug was a **load-time compatibility gap**:

- the real project file on disk still contains a **broken legacy manual profile** for `petite_maison_toit_bleu`
- the editor preview could reinterpret that profile **in memory** through `ElementCollisionAuthoringService.describe()`
- but `migrateProjectManifestJson(...)` did **not** normalize the same broken payload when the manifest was loaded for real runtime consumption
- so the runtime kept consuming the old full-grid `cells`

The correction in this lot is therefore:

1. prove the exact placed element on the real map,
2. prove the exact `cells` currently present on disk,
3. prove the runtime collision chain reads those `cells`,
4. add a **targeted manifest migration** for the broken legacy pattern,
5. validate `load -> save -> disk -> reload -> gameplay`.

No Git operation was performed.

---

## Real Case Audit

### 1. Real map loaded by runtime

Real project:

- `/Users/karim/Desktop/my_new_project/project.json`

Relevant manifest entry:

- map id: `Bourivka center`
- relative path: `maps/Bourivka center.json`

### 2. Exact placed instance on the map

From `/Users/karim/Desktop/my_new_project/maps/Bourivka center.json`, the exact placed element instance is:

```json
{
  "id": "l_tile_building::3::9",
  "layerId": "l_tile_building",
  "elementId": "petite_maison_toit_bleu",
  "pos": { "x": 3, "y": 9 },
  "applyCollision": true,
  "animation": null,
  "behaviors": [],
  "properties": {}
}
```

### 3. Does the placed instance match the edited element?

Binary answer:

- **YES**: the map places `petite_maison_toit_bleu`
- **YES**: the edited element in `project.json` is also `petite_maison_toit_bleu`

This rules out the “wrong element id” hypothesis for the real user case.

### 4. Real collision profile currently on disk

From `/Users/karim/Desktop/my_new_project/project.json`, the collision profile for `petite_maison_toit_bleu` was:

- `source = manual`
- `padding = { top: 0, right: 0, bottom: 0, left: 0 }`
- `shapeCells = []`
- `cells = 42` cells (`6 x 7`, full source rectangle)
- `manualAddedCells = 14` cells (the actual house silhouette)
- `manualRemovedCells = []`

This is the exact broken pattern.

### 5. Why runtime blocked the whole house

Because on disk the placed element still said:

```text
cells = full 6x7 grid
```

and gameplay reads `cells` directly.

So runtime was not hallucinating or applying a hidden fallback.  
It was faithfully reading the stale, legacy-broken `cells`.

---

## Exact Runtime Consumption Chain

### Manifest loading

Runtime bundle loading:

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`

Relevant method:

- `loadProjectManifestFromFile(String manifestPath)`

Chain:

1. `jsonDecode(await file.readAsString())`
2. `migrateProjectManifestJson(raw)`
3. `ProjectManifest.fromJson(migrated)`
4. `ProjectValidator.validate(manifest)`

### Gameplay collision cache

Gameplay collision construction:

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart`

Relevant logic:

```dart
for (final instance in map.placedElements) {
  if (!instance.applyCollision) {
    continue;
  }
  final profile = elementById[instance.elementId]?.collisionProfile;
  if (profile == null || profile.cells.isEmpty) {
    continue;
  }
  for (final localCell in profile.cells) {
    final x = instance.pos.x + localCell.x;
    final y = instance.pos.y + localCell.y;
    ...
    cache[y * map.size.width + x] = true;
  }
}
```

### Runtime debug overlay

Debug overlay also reads the same data:

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Relevant logic:

```dart
final profile = elementById[instance.elementId]?.collisionProfile;
if (profile == null || profile.cells.isEmpty) {
  continue;
}
for (final local in profile.cells) {
  ...
}
```

### Conclusion

In this checkout:

- gameplay reads `collisionProfile.cells`
- runtime overlay reads `collisionProfile.cells`
- no pixel mask is involved
- no alternate collision source was found for this placed element path

---

## Fallback Audit

Explicit audit target:

- `map_gameplay`
- `map_runtime`
- project/map loading

### Result

For the placed element collision path, **no fallback** was found of the form:

- full sprite bounding box if `cells` is empty
- source-rect collision fallback
- implicit footprint fallback
- hidden placement-layer collision fallback

The only gates found were:

- `instance.applyCollision == true`
- `profile != null`
- `profile.cells.isNotEmpty`

If `cells` is wrong, runtime collision is wrong.  
If `cells` is correct, runtime collision is correct.

---

## Legacy / Heterogeneous Project Audit

The user warned that the real project might still contain legacy keys such as:

- `visualMask`
- `pixelMask`
- `occlusionMask`

Concrete grep run on the provided real project:

- `/Users/karim/Desktop/my_new_project/project.json`
- `/Users/karim/Desktop/my_new_project/maps/*.json`

Result:

- **no match found** for `visualMask`
- **no match found** for `pixelMask`
- **no match found** for `occlusionMask`

So for the provided real project, those keys do **not** explain the runtime mismatch.

The real mismatch came from the broken legacy manual payload still persisted in `cells`.

---

## Root Cause

The root cause was:

1. the editor preview pipeline used `ElementCollisionAuthoringService.describe()`
2. `describe()` already contained an in-memory reinterpretation of the broken legacy manual profile:
   - if `source == manual`
   - and `shapeCells == []`
   - and `manualAddedCells` contains the intended silhouette
   - and `cells` still equals the full padding-derived rectangle
   - then the editor can infer the intended authored base
3. but `migrateProjectManifestJson(...)` did **not** perform the same repair
4. therefore:
   - editor preview could look correct
   - disk JSON could still be wrong
   - runtime could still read wrong `cells`

There was also a second concrete issue in the compat layer:

- `migrateProjectManifestJson(...)` had an early `return` when `pathPresets` was absent
- so even if collision migration had been added only at the end, it would still have been skipped for simpler manifests

This was fixed too.

---

## Minimal Correction Applied

### Strategy

No runtime contract change was introduced.

We did **not**:

- introduce a new runtime source of truth
- modify gameplay blocking rules
- add pixel-perfect collision
- add image analysis
- add Flame-side collision logic

We fixed the real problem where it actually lived:

- manifest compatibility / load normalization

### Main fix

Updated file:

- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/io/legacy_editor_json_compat.dart`

Added a collision-profile migration that repairs the exact proven legacy pattern:

- `source == manual`
- `shapeCells == []`
- `manualAddedCells != []`
- `manualRemovedCells == []`
- `cells == full padding-derived base`

It now rewrites that payload at load time to:

- `shapeCells = manualAddedCells`
- `manualAddedCells = []`
- `manualRemovedCells = []`
- `cells = shapeCells`

This aligns:

- editor preview
- loaded manifest
- runtime blocking
- debug overlay
- future saves to disk

### Important side fix

The migration is now applied both:

- in the normal end-of-function path
- and in the early-return branch when `pathPresets` is absent

Without that, some real manifests would still skip the correction entirely.

---

## Files Modified

### Production code

- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
  - added legacy collision profile migration
  - fixed early-return path so migration is not skipped

### Tests

- `/Users/karim/Project/pokemonProject/packages/map_core/test/legacy_editor_json_compat_collision_test.dart`
  - validates manifest migration of the broken manual profile
  - validates that unknown legacy keys do not block parsing

- `/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`
  - validates `load -> migrate -> save -> disk -> reload`

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/test/placed_elements_collision_test.dart`
  - validates gameplay uses migrated placed-element cells
  - validates collision lookup uses the placed `elementId`

---

## Important Before / After

### Before (real broken disk payload)

For `petite_maison_toit_bleu`:

```text
source = manual
shapeCells = []
cells = 42 (full 6x7 rectangle)
manualAddedCells = 14 (house silhouette)
manualRemovedCells = 0
```

### After migration in memory

```text
source = manual
shapeCells = 14 (house silhouette)
cells = 14 (house silhouette)
manualAddedCells = 0
manualRemovedCells = 0
```

### After save to disk

The repository roundtrip test proves that saving the loaded manifest writes the corrected form back to `project.json`.

---

## Tests Added / Strengthened

### 1. Manifest migration test

File:

- `/Users/karim/Project/pokemonProject/packages/map_core/test/legacy_editor_json_compat_collision_test.dart`

Covers:

- broken manual profile is normalized at load time
- `cells` no longer remain the full rectangle
- `shapeCells` becomes the authored silhouette

### 2. Save -> disk -> reload test

File:

- `/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`

Covers:

- file load uses migration
- repository save writes corrected `cells`
- reload keeps the same result

### 3. Gameplay integration test

File:

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/test/placed_elements_collision_test.dart`

Covers:

- placed element with broken legacy payload is migrated before gameplay reads it
- the roof area stays passable
- the base/body cells block
- collision lookup follows the placed `elementId`

---

## Commands Executed

### Audit / tracing

- inspected real project manifest:
  - `/Users/karim/Desktop/my_new_project/project.json`
- inspected real runtime map:
  - `/Users/karim/Desktop/my_new_project/maps/Bourivka center.json`
- grepped for legacy keys in the real project:
  - `visualMask`
  - `pixelMask`
  - `occlusionMask`

### Formatting

- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart format ...`

### Tests

- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart test test/legacy_editor_json_compat_collision_test.dart`
- `/opt/homebrew/bin/flutter test test/project_element_collision_file_repository_roundtrip_test.dart test/project_element_collision_persistence_test.dart`
- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart test test/placed_elements_collision_test.dart`

### Analyze

- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart analyze lib/src/io/legacy_editor_json_compat.dart test/legacy_editor_json_compat_collision_test.dart`
- `/opt/homebrew/bin/flutter analyze lib/src/infrastructure/repositories/file_repositories.dart test/project_element_collision_file_repository_roundtrip_test.dart test/project_element_collision_persistence_test.dart --no-fatal-infos`
- `/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/cache/dart-sdk/bin/dart analyze test/placed_elements_collision_test.dart`

---

## Validation Results

### Passing

- `map_core` targeted tests: passed
- `map_editor` targeted persistence tests: passed
- `map_gameplay` targeted collision tests: passed
- `map_core` targeted analyze: passed
- `map_gameplay` targeted analyze: passed

### Non-blocking analyzer infos

`flutter analyze` in `map_editor` still reports existing info-level lints in:

- `/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart`

These are `prefer_const_*` style infos and are unrelated to the runtime collision bug.

---

## Manual Validation Checklist

- [x] Proved the exact placed runtime element id on the real map
- [x] Proved it matches the edited element id
- [x] Proved the real disk payload still contained full-grid `cells`
- [x] Proved gameplay/runtime read `collisionProfile.cells`
- [x] Found no blocking fallback beyond `cells`
- [x] Verified legacy mask keys are not present in the provided real project
- [x] Added load-time migration for the broken legacy manual pattern
- [x] Verified save -> disk -> reload preserves corrected cells
- [x] Verified gameplay blocks only the intended house base after migration

---

## Remaining Honest Limits

1. The provided real project file on disk is **not automatically rewritten** just by loading it.
   - The runtime now migrates it in memory.
   - The editor repository also migrates it in memory on load.
   - To physically rewrite the corrected profile into `/Users/karim/Desktop/my_new_project/project.json`, the project must be saved again through the editor flow.

2. The migration is intentionally targeted.
   - It repairs the **proven broken legacy manual pattern**.
   - It does not attempt a speculative rewrite of every possible historical malformed profile.

3. The editor still contains defensive in-memory repair logic in `describe()`.
   - That is fine as a safety net.
   - The important change in this lot is that the manifest load path now shares the same correction logic, so runtime is no longer left behind.

---

## Final Cause in One Sentence

The real runtime bug happened because the placed element `petite_maison_toit_bleu` still had a legacy-broken full-rectangle `cells` payload on disk, while only the editor preview reinterpreted that payload in memory; the manifest load path did not, so runtime kept reading the stale full-grid collision.
