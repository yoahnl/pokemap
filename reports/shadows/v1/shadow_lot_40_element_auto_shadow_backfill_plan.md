# Shadow-40 Element Auto Shadow Backfill V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not run Git write operations unless the user explicitly asks for them.

**Goal:** Apply the Shadow-39 automatic element shadow suggestions across existing project elements so current maps visibly improve without editing every element by hand.

**Architecture:** Keep the bulk decision in `map_editor` application code, not in runtime or persistent model code. Add a pure backfill helper that computes a next `ProjectManifest`, a small save use case, an `EditorNotifier` entrypoint, and a compact action in `TilesetPalettePanel`. The default behavior is safe: apply to missing shadows and replace only generic pre-footprint shadows, while preserving disabled/manual shadows.

**Tech Stack:** Dart, Flutter/macOS editor widgets, Riverpod notifier, `map_core` shadow models, existing `ProjectRepository`, existing Shadow-39 suggestion helper.

---

## 1. Current Context

Shadow-39 added:

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
```

It works only when the user activates or recalculates one element inside `ElementShadowSection`.

The visible issue remains:

```text
Existing Selbrume elements already have old shadow configs or no configs.
The user does not see a project-wide improvement unless every source element is edited manually.
```

Shadow-40 should add the missing bridge:

```text
One explicit editor action applies automatic source-element shadow configs to eligible project elements.
```

## 2. Current Worktree Warning

At plan time the worktree still contains unrelated pre-existing local changes from Shadow-38 and `AGENTS.md`:

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

Do not include those files in Shadow-40 unless the user explicitly asks.

## 3. Scope

Shadow-40 creates:

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart
packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
reports/shadows/shadow_lot_40_element_auto_shadow_backfill.md
```

Shadow-40 modifies:

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
packages/map_editor/test/ui_panels_smoke_test.dart
```

Optional if targeted widget coverage is easier:

```text
packages/map_editor/test/tileset_palette_element_auto_shadow_backfill_test.dart
```

## 4. Non-Goals

Do not modify:

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/*json_codec.dart
packages/map_editor/lib/src/ui/canvas/**
packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
```

Do not create:

```text
new persistent shadow model
JSON migration
runtime renderer change
editor canvas change
global light model
time-of-day model
sprite-mask shadows
shadow atlas
saveLayer
ImageFilter
blur
zOrder
zIndex
build_runner output
```

Shadow-40 is an editor backfill/application lot, not a rendering lot.

## 5. Product Decision

### 5.1 Why not silently mutate on load?

Do not change project data automatically when a project opens.

Reasons:

- silent data mutation is surprising;
- projects may contain manually tuned shadows;
- the user needs a clear action and status feedback;
- tests and reports can prove a discrete operation.

### 5.2 V0 action

Add an explicit action in the element library:

```text
Ombres auto
```

The action opens a confirmation dialog:

```text
Appliquer les ombres automatiques aux éléments ?
```

When confirmed, it updates eligible `ProjectElementEntry.shadow` values using Shadow-39 suggestions.

### 5.3 Safe replacement rule

Apply a suggestion when:

```text
element.shadow == null
```

or when the existing shadow looks like an old generic pre-footprint config:

```text
element.shadow.castsShadow == true
element.shadow.footprint == null
element.shadow.offsetX == null
element.shadow.offsetY == null
element.shadow.scaleX == null
element.shadow.scaleY == null
element.shadow.opacity == null
element.shadow.shadowProfileId is null or a known default ground static profile id or missing from catalog
```

Skip an element when:

```text
shadow.castsShadow == false
shadow.footprint != null
any offset / scale / opacity override is non-null
shadowProfileId is a non-default existing profile id
no valid first frame exists
no suggestion can be built
```

This rule should fix old generic shadows while preserving intentional manual work.

## 6. Files and Responsibilities

### 6.1 `element_auto_shadow_backfill.dart`

Pure application helper. No Flutter, no repository, no notifier.

Responsibilities:

- ensure default ground static shadow profiles are available before suggesting;
- scan `ProjectManifest.elements`;
- decide whether each element is eligible;
- apply `buildElementAutoShadowSuggestion(...)`;
- return a result containing the updated project and per-element statuses.

### 6.2 `apply_element_auto_shadow_suggestions_use_case.dart`

Small persistence use case.

Responsibilities:

- call the pure backfill helper;
- save the updated project through `ProjectRepository` only if something changed;
- return the backfill result.

No Riverpod provider is required in V0. Instantiate it directly in `EditorNotifier` with `ref.read(projectRepositoryProvider)` to avoid generator churn.

### 6.3 `editor_notifier.dart`

Add one method:

```dart
Future<void> applyElementAutoShadowSuggestions()
```

Responsibilities:

- handle missing workspace/project;
- run the use case;
- update `state.project`;
- set useful status messages;
- resync placed elements for the active map after the project changes.

### 6.4 `tileset_palette_panel.dart`

Add a compact element library action.

Responsibilities:

- show an `Ombres auto` action near the `Éléments à placer` header;
- ask for confirmation;
- call `notifier.applyElementAutoShadowSuggestions()`;
- keep UI copy no-code friendly.

## 7. Proposed API

Create:

```dart
enum ElementAutoShadowBackfillStatus {
  appliedMissing,
  appliedGeneric,
  skippedDisabled,
  skippedManual,
  skippedNoSuggestion,
}

final class ElementAutoShadowBackfillEntry {
  const ElementAutoShadowBackfillEntry({
    required this.elementId,
    required this.elementName,
    required this.status,
    this.suggestionKind,
  });

  final String elementId;
  final String elementName;
  final ElementAutoShadowBackfillStatus status;
  final ElementAutoShadowSuggestionKind? suggestionKind;
}

final class ElementAutoShadowBackfillResult {
  const ElementAutoShadowBackfillResult({
    required this.project,
    required this.entries,
    required this.addedDefaultProfiles,
  });

  final ProjectManifest project;
  final List<ElementAutoShadowBackfillEntry> entries;
  final bool addedDefaultProfiles;

  int get appliedCount;
  int get skippedCount;
  bool get hasChanges;
}

ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
  ProjectManifest project,
);
```

## 8. Implementation Tasks

### Task 1: Pure Backfill RED Tests

**Files:**

- Create: `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

- [ ] Add tests for applying to missing shadows.
- [ ] Add tests for replacing generic pre-footprint active shadows.
- [ ] Add tests for preserving disabled shadows.
- [ ] Add tests for preserving manual footprints.
- [ ] Add tests for preserving custom offset / scale / opacity.
- [ ] Add tests for preserving non-default existing profile ids.
- [ ] Add tests for adding default profiles when the catalog has no compatible profile.
- [ ] Add tests for status counts and element ordering.
- [ ] Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Expected before implementation:

```text
Compilation fails because element_auto_shadow_backfill.dart does not exist.
```

Example test shape:

```dart
test('applies suggestions to elements without shadow configs', () {
  final project = _project(
    elements: [
      _element(id: 'lamp', width: 1, height: 4),
      _element(id: 'house', width: 4, height: 3),
    ],
    shadowCatalog: _defaultCatalog(),
  );

  final result = applyElementAutoShadowSuggestionsToProject(project);

  expect(result.appliedCount, 2);
  expect(result.project.elements[0].shadow!.shadowProfileId,
      'default-ground-contact-blob');
  expect(result.project.elements[0].shadow!.footprint!.footprintWidthRatio,
      0.18);
  expect(result.project.elements[1].shadow!.shadowProfileId,
      'default-ground-wide-ellipse');
  expect(result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
      0.82);
});
```

### Task 2: Pure Backfill Implementation

**Files:**

- Create: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`

- [ ] Import `map_core` and `element_auto_shadow_suggestion.dart`.
- [ ] Add `ElementAutoShadowBackfillStatus`.
- [ ] Add `ElementAutoShadowBackfillEntry`.
- [ ] Add `ElementAutoShadowBackfillResult`.
- [ ] Add `applyElementAutoShadowSuggestionsToProject(...)`.
- [ ] Add a private `_canReplaceExistingShadow(...)`.
- [ ] Add known default profile id helper:

```dart
const _defaultGroundStaticProfileIds = <String>{
  'default-ground-soft-ellipse',
  'default-ground-wide-ellipse',
  'default-ground-contact-blob',
};
```

- [ ] Use `ensureDefaultGroundStaticShadowProfilesForProject(project)` before computing suggestions.
- [ ] Preserve element order and all non-shadow fields.
- [ ] Run the pure tests.

Expected:

```text
All element_auto_shadow_backfill_test.dart tests pass.
```

### Task 3: Persistence Use Case RED Tests

**Files:**

- Create: `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`

- [ ] Test that the use case saves when at least one element changes.
- [ ] Test that it does not save when no element is eligible.
- [ ] Test that it returns the backfill counts.
- [ ] Test that saved JSON round-trips through `ProjectManifest.fromJson(project.toJson())`.
- [ ] Run:

```bash
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
```

Expected before implementation:

```text
Compilation fails because apply_element_auto_shadow_suggestions_use_case.dart does not exist.
```

### Task 4: Persistence Use Case Implementation

**Files:**

- Create: `packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart`

Implementation outline:

```dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

final class ApplyElementAutoShadowSuggestionsUseCase {
  ApplyElementAutoShadowSuggestionsUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ElementAutoShadowBackfillResult> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
  ) async {
    final result = applyElementAutoShadowSuggestionsToProject(project);
    if (result.hasChanges) {
      await _repo.saveProject(result.project, workspace.projectManifestPath);
    }
    return result;
  }
}
```

- [ ] Run the use case tests.

Expected:

```text
All apply_element_auto_shadow_suggestions_use_case_test.dart tests pass.
```

### Task 5: EditorNotifier RED Tests

**Files:**

- Modify: `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`

- [ ] Add a test for applying automatic shadows to project elements.
- [ ] Add a test for no-op status when every element is manual/skipped.
- [ ] Add a test that default profiles are added when needed.
- [ ] Run:

```bash
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
```

Expected before notifier implementation:

```text
Compilation fails because EditorNotifier.applyElementAutoShadowSuggestions does not exist.
```

### Task 6: EditorNotifier Implementation

**Files:**

- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

- [ ] Import `apply_element_auto_shadow_suggestions_use_case.dart`.
- [ ] Add:

```dart
Future<void> applyElementAutoShadowSuggestions() async {
  final fs = _projectWorkspace;
  final project = state.project;
  if (fs == null || project == null) {
    state = state.copyWith(
      errorMessage: 'No project open to update element shadows.',
    );
    return;
  }
  try {
    final useCase = ApplyElementAutoShadowSuggestionsUseCase(
      ref.read(projectRepositoryProvider),
    );
    final result = await useCase.execute(fs, project);
    if (!result.hasChanges) {
      state = state.copyWith(
        statusMessage: 'Aucune ombre automatique à appliquer.',
        errorMessage: null,
      );
      return;
    }
    state = state.copyWith(
      project: result.project,
      statusMessage:
          'Ombres automatiques appliquées à ${result.appliedCount} éléments.',
      errorMessage: null,
    );
    _resyncPlacedElementsForActiveMapFromProject();
  } catch (e) {
    state = state.copyWith(
      errorMessage: 'Failed to apply automatic element shadows: $e',
    );
  }
}
```

- [ ] Run notifier tests.

Expected:

```text
All editor_notifier_project_dirty_state_test.dart tests pass.
```

### Task 7: TilesetPalettePanel UI RED Test

**Files:**

- Modify or create: `packages/map_editor/test/tileset_palette_element_auto_shadow_backfill_test.dart`

- [ ] Pump `TilesetPalettePanel` with a project containing one eligible lamp element.
- [ ] Assert the `Ombres auto` action is visible in the element library.
- [ ] Trigger the action and confirm.
- [ ] Assert the project element now has a thin footprint.
- [ ] Run:

```bash
cd packages/map_editor && flutter test test/tileset_palette_element_auto_shadow_backfill_test.dart
```

Expected before UI implementation:

```text
Test fails because the action is not rendered.
```

### Task 8: TilesetPalettePanel UI Implementation

**Files:**

- Modify: `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`

- [ ] Add an `Ombres auto` action in the `Éléments à placer` header row.
- [ ] Use existing `_inspectorAccentPopupMenu(...)` or a compact `PushButton`.
- [ ] Show confirmation:

```text
Appliquer les ombres automatiques aux éléments ?
```

- [ ] Message copy:

```text
Les éléments sans ombre ou avec une ancienne ombre générique recevront une empreinte automatique. Les ombres manuelles et désactivées seront conservées.
```

- [ ] On confirmation, call:

```dart
await notifier.applyElementAutoShadowSuggestions();
```

- [ ] Do not touch `ElementShadowSection`; it already has the single-element recalculation.
- [ ] Run the UI test.

Expected:

```text
All tileset_palette_element_auto_shadow_backfill_test.dart tests pass.
```

### Task 9: Regression Commands

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
cd packages/map_editor && flutter test test/tileset_palette_element_auto_shadow_backfill_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/application/use_cases lib/src/features/editor/state lib/src/ui/panels/tileset_palette_panel.dart test/application/shadow test/features/tileset_library test/editor_notifier_project_dirty_state_test.dart
```

Run `map_core` guards:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib test/shadow
```

## 9. Anti-Drift Checks

Run from repo root:

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected for Shadow-40-owned files:

```text
No runtime/gameplay/battle diff.
No core model/codec diff.
No editor canvas diff caused by Shadow-40.
No renderer/global-light drift caused by Shadow-40.
No map_runtime import in map_editor.
```

Because Shadow-38 changes are currently still uncommitted, global canvas scans may show Shadow-38 output. The implementation report must distinguish this explicitly.

## 10. Report Requirements

Create:

```text
reports/shadows/shadow_lot_40_element_auto_shadow_backfill.md
```

Include:

1. summary;
2. design retained;
3. files created;
4. files modified;
5. pre-existing modified/untracked files;
6. backfill eligibility rules;
7. skipped-element rules;
8. default profile behavior;
9. UI action;
10. persistence behavior;
11. tests added/modified;
12. commands launched;
13. complete useful targeted test outputs;
14. final lines for broader suites;
15. anti-drift results;
16. initial/final git status;
17. diff stat;
18. full contents of created text/code files;
19. diffs for modified files;
20. risks and limitations;
21. auto-review.

## 11. Success Criteria

Shadow-40 succeeds if:

- existing elements without shadows receive automatic source shadows;
- old generic pre-footprint shadows are replaced;
- disabled shadows are preserved;
- manual footprints and manual numeric overrides are preserved;
- default ground-static profiles are added when needed;
- the editor exposes one clear bulk action;
- the operation saves through the existing project repository path;
- runtime/editor canvas/model/codecs are untouched;
- targeted tests and analyze pass;
- the report distinguishes Shadow-40 from pre-existing Shadow-38 worktree changes.

## 12. Honest Product Limitation

Shadow-40 still does not create final Pokémon-like shadow silhouettes.

It should make the current map visibly better because existing elements finally get the Shadow-39 suggested footprints. The next rendering-oriented lots are still needed for true object-family silhouettes:

```text
Shadow-41 — Static Shadow Family Model / Style V0
Shadow-42 — Building / Tall Prop Shadow Family Geometry V0
Shadow-43 — Runtime + Editor Family Integration V0
Shadow-44 — Selbrume Visual Tuning / Golden Slice V0
```

## 13. Self-Review Checklist

- [ ] Does the plan avoid runtime changes?
- [ ] Does the plan avoid core model/codec changes?
- [ ] Does the plan avoid canvas/painter changes?
- [ ] Does the plan preserve disabled/manual shadows?
- [ ] Does the plan apply suggestions to old generic shadows?
- [ ] Does the plan add a user-visible bulk action?
- [ ] Does the plan save through project repository infrastructure?
- [ ] Does the plan include tests for no-op/skipped cases?
- [ ] Does the plan document Shadow-38 pre-existing worktree drift?
