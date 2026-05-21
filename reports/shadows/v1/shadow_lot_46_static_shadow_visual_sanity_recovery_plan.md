# Shadow-46 Static Shadow Visual Sanity Recovery V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Repository rule wins over generic plan guidance: do not commit unless the user explicitly asks after implementation.

**Goal:** Stop catastrophic projected-shadow spam on tiny decor and make runtime/editor projected shadows actually use `StaticShadowFamily` projection specs.

**Architecture:** Keep the fix narrow. `map_editor` auto-suggestion becomes more selective for micro decor, while runtime/editor shadow projection builders pass element/override family into the pure `map_core` family projection resolver added in Shadow-45. No persistent model, JSON codec, Flame component, renderer order, or canvas-layer rewrite is introduced.

**Tech Stack:** Dart/Flutter tests, `map_core` shadow operations, existing runtime/editor shadow preview builders.

---

## 1. Root Cause Summary

The screenshot shows two bugs stacked together:

- tiny decor elements can receive automatic source shadows, producing many small projected polygons over grass/path;
- runtime/editor projection paths do not yet consume `resolveStaticShadowFamilyProjectionSpec(...)`, so `tallProp`, `building`, `compactProp`, and `foliage` authoring data do not control the projected silhouette.

## 2. Scope

Allowed:

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery.md
```

Forbidden:

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/*json_codec.dart
packages/map_gameplay/**
packages/map_battle/**
generated files
build_runner
Shadow Studio
new Flame Component
renderer ordering changes
global light persistent model
```

## 3. Tasks

### Task 1: Auto-Suggestion Sanity

- [ ] Add tests proving `1x1` and `1x2` micro decor return `null`.
- [ ] Keep `1x4` tall thin, `2x2` compact, and buildings suggested.
- [ ] Implement a micro-decor guard before the existing classifier.

Expected behavior:

```text
1x1 -> no automatic shadow
1x2 -> no automatic shadow
1x4 -> tallProp
2x2 -> compactProp
4x3 -> building
```

### Task 2: Runtime Family Wiring

- [ ] Add `elementFamily` and `overrideFamily` to `StaticPlacedElementShadowRuntimeInput`.
- [ ] Pass families from `RuntimeStaticPlacedElementShadowSource` into the input.
- [ ] Use `resolveStaticShadowFamily(...)` and `resolveStaticShadowFamilyProjectionSpec(...)` before `resolveProjectedStaticShadowGeometry(...)`.
- [ ] Add tests proving tall prop projection is narrower than building for comparable inputs and override family wins.

Expected behavior:

```text
input elementFamily tallProp -> tallProp projection spec
input overrideFamily building -> building projection spec wins
missing family -> genericProjection
```

### Task 3: Editor Preview Family Wiring

- [ ] In `editor_static_shadow_preview.dart`, merge `element.shadow?.family` and `placed.shadowOverride?.family`.
- [ ] Compose the light preview projection spec with `resolveStaticShadowFamilyProjectionSpec(...)`.
- [ ] Add tests proving family changes preview polygon bounds without changing filtering behavior.

Expected behavior:

```text
editor preview uses same family silhouette resolver as runtime
light preview direction remains preserved
missing family keeps generic projection
```

### Task 4: Verification And Report

- [ ] Run targeted editor/runtime tests.
- [ ] Run `map_core` family projection test.
- [ ] Run targeted analyze commands.
- [ ] Run anti-drift scans.
- [ ] Create `reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery.md` with changed files, commands, exact results, status, risks, and self-review.

## 4. Notes

This lot is a visual sanity recovery, not final visual polish. It should remove the worst shadow spam and make families meaningful. Further tuning may still be needed for Pokemon-like art direction.
