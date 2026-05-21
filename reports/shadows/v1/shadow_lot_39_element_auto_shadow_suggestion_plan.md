# Shadow-39 Element Auto Shadow Suggestion V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not run Git write operations unless the user explicitly asks for them.

**Goal:** Add an editor-only automatic shadow suggestion for one source element so users no longer have to guess footprint, profile, opacity, offset, or scale values manually.

**Architecture:** Keep the suggestion logic in `map_editor` application code, because this is authoring assistance rather than a persistent model or runtime rule. The helper reads `ProjectElementEntry.frames.first.source` and a `ProjectShadowCatalog`, classifies the element by sprite dimensions, and returns a `ProjectElementShadowConfig` using existing fields only. `ElementShadowSection` consumes the helper on activation from `null` and through an explicit `Calculer automatiquement` action.

**Tech Stack:** Dart, Flutter/macOS editor widgets, `map_core` shadow models, existing editor widget tests.

---

## 1. Resume

Shadow-35 to Shadow-38 gave PokeMap a projected-shadow rendering path. The remaining visible problem is authoring: every source element still starts from generic values unless the user manually edits footprint ratios.

Shadow-39 should add a per-element automatic suggestion. It should make lamp posts thin, buildings broad, stands local, and small props compact without changing runtime, JSON, models, or project files silently.

This lot should be conservative:

- no batch repair;
- no project-wide migration;
- no runtime integration;
- no new persistent fields;
- no global light model;
- no image/sprite-mask shadow system.

## 2. Current Worktree Warning

At plan time the worktree contains Shadow-38 changes and an unrelated `AGENTS.md` modification:

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

Before coding Shadow-39, decide whether to commit/push Shadow-38 first. Do not include `AGENTS.md` in Shadow-39.

## 3. Scope

Shadow-39 creates:

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
reports/shadows/shadow_lot_39_element_auto_shadow_suggestion.md
```

Shadow-39 modifies:

```text
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
```

Optional only if imports require it:

```text
packages/map_editor/test/application/shadow
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
packages/map_editor/lib/src/features/editor/state/**
```

Do not create:

```text
Shadow Studio
projection spec persistent model
world light model
time-of-day model
build_runner output
JSON migration
sprite shadow atlas
saveLayer
ImageFilter
blur
zOrder
zIndex
```

## 5. Design Decision

### 5.1 Helper API

Create `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`.

Public API:

```dart
enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}
```

```dart
final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}
```

```dart
ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
});
```

Return `null` when:

- there is no first frame;
- `frames.first.source.width <= 0`;
- `frames.first.source.height <= 0`;
- no compatible ground static profile exists.

Compatible profile means:

```dart
isGroundStaticElementShadowProfile(profile)
```

from `map_core`.

### 5.2 Profile Selection

Add helper functions:

```dart
ProjectShadowProfile? _preferredCompactProfile(ProjectShadowCatalog catalog)
ProjectShadowProfile? _preferredWideProfile(ProjectShadowCatalog catalog)
ProjectShadowProfile? _preferredSoftProfile(ProjectShadowCatalog catalog)
ProjectShadowProfile? _firstCompatibleProfile(ProjectShadowCatalog catalog)
```

Selection rules:

- compact prefers `default-ground-contact-blob`, then first `contactBlob`, then first compatible;
- wide prefers `default-ground-wide-ellipse`, then first compatible `ellipse`, then first compatible;
- soft prefers `default-ground-soft-ellipse`, then first compatible `ellipse`, then first compatible.

The helper must work with custom catalogs that do not use default IDs.

### 5.3 Dimension Classification

Use the first visual frame source dimensions in source cells:

```dart
final width = source.width.toDouble();
final height = source.height.toDouble();
final area = width * height;
final aspect = height / width;
```

V0 classification:

```text
tallThin:
  aspect >= 2.2 && width <= 2

buildingLarge:
  width >= 4 || area >= 12

wideLow:
  width >= 3 && height <= 3

smallSquare:
  area <= 4

defaultProp:
  everything else
```

Order matters: tall-thin should be tested before building-large so lamp posts do not become buildings.

### 5.4 Suggested Config Values

All suggestions must use existing `ProjectElementShadowConfig` fields only.

Tall-thin, for lamp posts and poles:

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: compactProfile.id,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 0.28,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 1.0,
    footprintWidthRatio: 0.18,
    footprintHeightRatio: 0.07,
  ),
)
```

Building-large, for houses and large structures:

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: wideProfile.id,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 0.85,
  opacity: 0.30,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 0.92,
    footprintWidthRatio: 0.82,
    footprintHeightRatio: 0.12,
  ),
)
```

Wide-low, for stands and kiosks:

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: wideProfile.id,
  offsetX: 0,
  offsetY: 0,
  scaleX: 0.92,
  scaleY: 0.75,
  opacity: 0.27,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 0.95,
    footprintWidthRatio: 0.72,
    footprintHeightRatio: 0.10,
  ),
)
```

Small-square, for wells, signs, crates, small props:

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: compactProfile.id,
  offsetX: 0,
  offsetY: 0,
  scaleX: 0.78,
  scaleY: 0.70,
  opacity: 0.26,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 0.96,
    footprintWidthRatio: 0.46,
    footprintHeightRatio: 0.10,
  ),
)
```

Default-prop:

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  shadowProfileId: softProfile.id,
  offsetX: 0,
  offsetY: 0,
  scaleX: 0.90,
  scaleY: 0.80,
  opacity: 0.28,
  footprint: StaticShadowFootprintConfig(
    anchorXRatio: 0.5,
    anchorYRatio: 0.95,
    footprintWidthRatio: 0.62,
    footprintHeightRatio: 0.12,
  ),
)
```

### 5.5 Known Limitation

Shadow-39 cannot yet tune projection length per element because there is no persistent per-element `StaticShadowProjectionSpec`. This means building shadows will improve through better footprint and scale, but may still need Shadow-40 or Shadow-43 style family work for truly handcrafted Pokemon-like building silhouettes.

Document this honestly in the implementation report.

## 6. ElementShadowSection UX

### 6.1 Activation From Null

When the user toggles `Projette une ombre` from `shadow == null` to active:

1. call `buildElementAutoShadowSuggestion(...)`;
2. if it returns a suggestion, emit `suggestion.config`;
3. if it returns `null`, keep existing behavior: first compatible profile with empty numeric overrides.

This gives automatic values immediately without a separate user action.

### 6.2 Explicit Button

Add a button in `ElementShadowSection`, visible when a suggestion exists:

```text
Calculer automatiquement
```

Placement:

- after the profile picker;
- before `Empreinte au sol`;
- visible whether `shadow` is null or active, as long as there is a valid suggestion;
- disabled only if no compatible profile or no valid frame.

When clicked:

- emit `suggestion.config`;
- clear footprint/number validation errors;
- show a short `_activationMessage`, for example `Ombre automatique : lampadaire fin.`

This action intentionally replaces current shadow values because it is an explicit recalculation.

### 6.3 Preserve Existing Manual Editing

Existing manual mutations must keep preserving footprint:

- `_setCastsShadow(false)` preserves existing config;
- `_setProfile(...)` preserves existing footprint;
- `_setNumber(...)` preserves existing footprint;
- `_setFootprintNumber(...)` preserves offset/scale/opacity/profile.

Shadow-39 should not break the guarantees added by Shadow-31.

## 7. Tests

### 7.1 Helper Tests

Create `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`.

Tests:

1. `returns null without compatible ground static profile`
2. `returns null for missing frames`
3. `returns null for invalid first frame source`
4. `classifies tall thin elements as tallThin`
5. `classifies large buildings as buildingLarge`
6. `classifies wide low elements as wideLow`
7. `classifies small square elements as smallSquare`
8. `classifies remaining valid elements as defaultProp`
9. `prefers default compact profile for tallThin`
10. `falls back to custom compatible profile ids`
11. `all suggestions have castsShadow true`
12. `all suggestion footprints are non-null and valid`
13. `all suggestion opacities are within 0..1`
14. `all suggestion scaleX/scaleY are > 0`

Example expected assertions for tall-thin:

```dart
final suggestion = buildElementAutoShadowSuggestion(
  element: _element(width: 1, height: 4),
  shadowCatalog: _defaultCatalog(),
)!;

expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
expect(suggestion.config.opacity, 0.28);
```

### 7.2 Widget Tests

Modify `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`.

Tests:

1. `activating from null applies an auto suggestion`
   - element width 1 height 4;
   - toggle on;
   - expect `harness.shadow!.footprint!.footprintWidthRatio == 0.18`;
   - expect compact profile id.

2. `auto calculate button is visible with compatible profile and valid frame`
   - pump active or inactive section;
   - expect `find.text('Calculer automatiquement')`.

3. `auto calculate button applies suggestion to active config`
   - start with custom manual values;
   - tap button;
   - expect suggested footprint/profile/opacity replace old manual values.

4. `auto calculate button is absent without compatible profile`
   - actorContact-only or none-only catalog;
   - expect no button.

5. `activation falls back to first profile when suggestion is unavailable`
   - invalid frame or no first frame;
   - keep existing behavior.

6. `changing profile after auto suggestion preserves footprint`
   - apply suggestion;
   - call popup change;
   - footprint remains non-null.

## 8. Implementation Tasks

### Task 1: Helper Red Tests

**Files:**

- Create: `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

- [ ] Add tests for null cases, classification, profile selection, and numeric validity.
- [ ] Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Expected before implementation:

```text
Compilation fails because element_auto_shadow_suggestion.dart does not exist.
```

### Task 2: Helper Implementation

**Files:**

- Create: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`

- [ ] Add `ElementAutoShadowSuggestionKind`.
- [ ] Add `ElementAutoShadowSuggestion`.
- [ ] Add `buildElementAutoShadowSuggestion(...)`.
- [ ] Add private classification and profile-selection helpers.
- [ ] Use only `ProjectElementEntry`, `ProjectShadowCatalog`, `ProjectElementShadowConfig`, `StaticShadowFootprintConfig`, and existing default profile helpers.
- [ ] Run helper tests.

Expected:

```text
All element_auto_shadow_suggestion_test.dart tests pass.
```

### Task 3: Widget Red Tests

**Files:**

- Modify: `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`

- [ ] Add activation test.
- [ ] Add button visibility test.
- [ ] Add explicit recalculation test.
- [ ] Add no-compatible-profile absence test.
- [ ] Add fallback test.
- [ ] Add preservation-after-profile-change test.
- [ ] Run:

```bash
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
```

Expected before widget implementation:

```text
New tests fail because the button and auto activation are not wired yet.
```

### Task 4: Widget Implementation

**Files:**

- Modify: `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`

- [ ] Import `element_auto_shadow_suggestion.dart`.
- [ ] Compute `final autoSuggestion = buildElementAutoShadowSuggestion(...)` in `build`.
- [ ] Insert `Calculer automatiquement` action after `_profilePicker(...)`.
- [ ] Add `_applyAutoSuggestion(ElementAutoShadowSuggestion suggestion)`.
- [ ] Update `_setCastsShadow(true)` to use suggestion when `widget.shadow == null`.
- [ ] Keep existing fallback when suggestion is null.
- [ ] Do not change reset behavior.
- [ ] Run widget tests.

Expected:

```text
All element_shadow_section_test.dart tests pass.
```

### Task 5: Report

**Files:**

- Create: `reports/shadows/shadow_lot_39_element_auto_shadow_suggestion.md`

Report sections:

1. resume;
2. design;
3. files created;
4. files modified;
5. files not modified explicitly;
6. helper API;
7. classification rules;
8. suggested values;
9. UI action;
10. activation behavior;
11. preservation rules;
12. tests;
13. commands;
14. full targeted outputs;
15. anti-drift scans;
16. initial/final git status;
17. full contents of created/modified text files;
18. risks and limitations;
19. auto-review.

## 9. Verification Commands

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib test/shadow
```

Anti-drift:

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas|packages/map_editor/lib/src/features/editor/state"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected anti-drift:

```text
No runtime/gameplay/battle diff.
No core model/codec diff.
No canvas/state diff.
No renderer/global-light drift.
No map_runtime import in map_editor.
```

## 10. Success Criteria

- Tall-thin elements get a thin footprint automatically.
- Large building elements get a broad, lower footprint automatically.
- Wide-low elements get a local footprint automatically.
- Small-square elements get a compact footprint automatically.
- Activating an unconfigured shadow uses the suggestion.
- The explicit button recalculates the current element.
- Existing manual controls still preserve footprint.
- No runtime changed.
- No persistent model changed.
- No JSON codec changed.
- Tests and analyze pass.

## 11. Honest Product Limitation

Shadow-39 should improve the lampadaire problem a lot because footprint width becomes narrow automatically.

For houses and large buildings, it will improve the anchoring and width, but it may not fully match Pokemon references because the current projection length is still global/default and based on visual height. A later lot should add either:

- projection family presets for static object categories; or
- a persistent per-element projection style/value object.

Do not oversell Shadow-39 as the final Pokemon-like shadow solution.

## 12. Self-Review Checklist

- [ ] Does the helper use existing model fields only?
- [ ] Does it avoid runtime imports?
- [ ] Does it avoid core model/codec changes?
- [ ] Does activation from null apply a suggestion?
- [ ] Does explicit recalculation exist?
- [ ] Are existing manual edits still possible after auto suggestion?
- [ ] Are invalid/no-profile cases safe?
- [ ] Are limitations documented?
