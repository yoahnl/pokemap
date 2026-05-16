# Shadow-50 — Selbrume Static Shadow Visual Calibration V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Use `superpowers:test-driven-development` for every behavioral change. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** make the automatic static shadows in Selbrume visibly less slab-like by tightening family projection specs, replacing legacy broad auto-shadow configs, and improving dimension-based classification for lamps and wide props.

**Architecture:** keep this lot in `map_core` only. Runtime and editor already consume `ProjectElementShadowConfig.family`, `footprint`, and `resolveStaticShadowFamilyProjectionSpec(...)`, so changing the pure core policy updates the visible result without touching Flame, canvas painters, persistent model classes, JSON codecs, or editor UI.

**Tech Stack:** Dart, `map_core` pure operations, existing Shadow models/tests, no Flutter/Flame production changes.

---

## 1. Context And Root Cause

Shadow-49 made projected polygon rendering less uniform by drawing opacity bands, but the screenshot still shows oversized geometric slabs.

The current Selbrume project at `/Users/karim/Desktop/selbrume/project.json` contains many stored broad shadow configs shaped like this:

```text
castsShadow: true
shadowProfileId: default-ground-wide-ellipse
scaleX: 1.0
scaleY: 0.85
opacity: 0.3
family: null or building
footprint:
  anchorXRatio: 0.5
  anchorYRatio: 0.92
  footprintWidthRatio: 0.82
  footprintHeightRatio: 0.12
```

Examples observed locally include houses, `le_puits`, `kiosque_l_gumes`, `barri_re_pierre`, `parasol`, and `lampadaire`.

That matters because `applyElementAutoShadowPolicyToProject(...)` currently preserves configs it considers manual. So the runtime auto policy does not reliably replace these old broad auto-looking configs. The result: the new renderer still paints old, oversized geometry.

Shadow-50 must fix that root cause:

```text
1. Replace legacy broad auto-shadow configs when they match the old generated values.
2. Reclassify lamp-like 3x5 elements as tallThin, not buildingLarge.
3. Reclassify very wide low elements as wideLow instead of buildingLarge.
4. Tighten projection family specs and auto footprints.
```

## 2. Non-Goals

Do not modify:

```text
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/*json_codec*.dart
*.g.dart
*.freezed.dart
examples/playable_runtime_host/**
```

Do not create:

```text
Shadow Studio
new UI
new persistent model
JSON migration
Flame component
runtime renderer
editor painter
blur
saveLayer
ImageFilter
shadow atlas
global light
time-of-day
WorldLightState
zOrder / zIndex
build_runner
```

Do not edit `/Users/karim/Desktop/selbrume/project.json` in this lot. It is evidence only, not a tracked test fixture.

Do not commit unless the user explicitly asks after implementation.

## 3. Files

Modify:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/test/shadow/static_shadow_family_projection_test.dart
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
```

Create after implementation:

```text
reports/shadows/shadow_lot_50_selbrume_visual_calibration.md
```

This plan file already exists:

```text
reports/shadows/shadow_lot_50_selbrume_visual_calibration_plan.md
```

## 4. Target Calibration Values

### 4.1 Family Projection Specs

Use fixed default V1 effective values, while still preserving custom base direction and proportional scaling for custom base numeric values.

Target effective values when using `defaultStaticShadowProjectionSpec`:

```text
compactProp:
  lengthRatio: 0.0704
  nearWidthMultiplier: 0.3312
  farWidthMultiplier: 0.2832

tallProp:
  lengthRatio: 0.0704
  nearWidthMultiplier: 0.2208
  farWidthMultiplier: 0.1770

building:
  lengthRatio: 0.0832
  nearWidthMultiplier: 0.4416
  farWidthMultiplier: 0.3422

foliage:
  lengthRatio: 0.0960
  nearWidthMultiplier: 0.5060
  farWidthMultiplier: 0.4720
```

These values are intentionally much more restrained than Shadow-49 inputs:

```text
building old: length 0.1984, near 0.7176, far 0.7316
tall old:     length 0.1536, near 0.2944, far 0.3304
```

### 4.2 Auto Policy Configs

Target configs:

```text
tallThin:
  profile: default-ground-contact-blob
  scaleX: 0.80
  scaleY: 0.55
  opacity: 0.20
  family: tallProp
  footprint: anchorX 0.5, anchorY 1.0, width 0.28, height 0.05

buildingLarge:
  profile: default-ground-wide-ellipse
  scaleX: 0.72
  scaleY: 0.48
  opacity: 0.20
  family: building
  footprint: anchorX 0.5, anchorY 0.98, width 0.60, height 0.06

wideLow:
  profile: default-ground-wide-ellipse
  scaleX: 0.74
  scaleY: 0.50
  opacity: 0.20
  family: compactProp
  footprint: anchorX 0.5, anchorY 0.98, width 0.58, height 0.06

defaultProp and smallSquare:
  keep existing legacy recognition helpers, but they are not emitted by current safe auto policy.
```

## 5. Task 1 — RED Family Projection Calibration Tests

**Files:**

- Modify: `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

- [ ] Replace the old V0 constant tests with V1 tests:

```dart
test('compactProp V1 calibration is short and tapered', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.compactProp,
  );

  expect(spec.lengthRatio, closeTo(0.0704, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.3312, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(0.2832, 0.0000001));
  expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
});

test('tallProp V1 calibration is very narrow and short', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.tallProp,
  );

  expect(spec.lengthRatio, closeTo(0.0704, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.2208, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(0.1770, 0.0000001));
  expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
});

test('building V1 calibration avoids broad slabs', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.building,
  );

  expect(spec.lengthRatio, closeTo(0.0832, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.4416, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(0.3422, 0.0000001));
  expect(spec.farWidthMultiplier, lessThan(spec.nearWidthMultiplier));
});

test('foliage V1 calibration is restrained but broader than tall props', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.foliage,
  );
  final tall = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.tallProp,
  );

  expect(spec.lengthRatio, closeTo(0.0960, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.5060, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(0.4720, 0.0000001));
  expect(spec.nearWidthMultiplier, greaterThan(tall.nearWidthMultiplier));
});
```

- [ ] Add a geometry composition test for Selbrume-like buildings:

```dart
test('building V1 projected geometry stays compact for a Selbrume house', () {
  final geometry = _projectedCase(
    family: StaticShadowFamily.building,
    visualWidth: 192,
    visualHeight: 224,
    footprintWidthRatio: 0.60 * 0.72,
    footprintHeightRatio: 0.06 * 0.48,
  );

  expect(_projectedLength(geometry), lessThan(20));
  expect(_maxWidth(geometry), lessThan(40));
  expect(_polygonArea(geometry), lessThan(700));
});
```

- [ ] Add helper:

```dart
double _projectedLength(ProjectedStaticShadowGeometry geometry) {
  final near = _midpoint(geometry.nearLeft, geometry.nearRight);
  final far = _midpoint(geometry.farLeft, geometry.farRight);
  return _distance(near, far);
}
```

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Expected RED:

```text
Expected: close to new V1 values
Actual: old V0 values
```

## 6. Task 2 — Implement Family Projection Calibration

**Files:**

- Modify: `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

- [ ] Replace raw scale literals with named effective default constants:

```dart
const _compactPropLengthRatio = 0.0704;
const _compactPropNearWidthMultiplier = 0.3312;
const _compactPropFarWidthMultiplier = 0.2832;

const _tallPropLengthRatio = 0.0704;
const _tallPropNearWidthMultiplier = 0.2208;
const _tallPropFarWidthMultiplier = 0.1770;

const _buildingLengthRatio = 0.0832;
const _buildingNearWidthMultiplier = 0.4416;
const _buildingFarWidthMultiplier = 0.3422;

const _foliageLengthRatio = 0.0960;
const _foliageNearWidthMultiplier = 0.5060;
const _foliageFarWidthMultiplier = 0.4720;
```

- [ ] Replace `_scaledProjectionSpec(...)` with a helper that preserves proportional custom base behavior:

```dart
StaticShadowProjectionSpec _calibratedProjectionSpec(
  StaticShadowProjectionSpec baseProjectionSpec, {
  required double defaultLengthRatio,
  required double defaultNearWidthMultiplier,
  required double defaultFarWidthMultiplier,
}) {
  return StaticShadowProjectionSpec(
    directionX: baseProjectionSpec.directionX,
    directionY: baseProjectionSpec.directionY,
    lengthRatio: baseProjectionSpec.lengthRatio *
        defaultLengthRatio /
        defaultStaticShadowProjectionLengthRatio,
    nearWidthMultiplier: baseProjectionSpec.nearWidthMultiplier *
        defaultNearWidthMultiplier /
        defaultStaticShadowProjectionNearWidthMultiplier,
    farWidthMultiplier: baseProjectionSpec.farWidthMultiplier *
        defaultFarWidthMultiplier /
        defaultStaticShadowProjectionFarWidthMultiplier,
  );
}
```

- [ ] Update switch cases:

```dart
case StaticShadowFamily.compactProp:
  return _calibratedProjectionSpec(
    baseProjectionSpec,
    defaultLengthRatio: _compactPropLengthRatio,
    defaultNearWidthMultiplier: _compactPropNearWidthMultiplier,
    defaultFarWidthMultiplier: _compactPropFarWidthMultiplier,
  );
```

Repeat for `tallProp`, `building`, `foliage`.

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Expected GREEN:

```text
All tests passed!
```

## 7. Task 3 — RED Auto Policy Classification And Legacy Replacement Tests

**Files:**

- Modify: `packages/map_core/test/shadow/element_auto_shadow_policy_test.dart`

- [ ] Add test: 3x5 lamp becomes `tallThin`.

```dart
test('Selbrume lamp dimensions are classified as tall thin', () {
  final suggestion = buildElementAutoShadowSuggestion(
    element: _element(id: 'lampadaire', width: 3, height: 5),
    shadowCatalog: _defaultCatalog(),
  );

  expect(suggestion, isNotNull);
  expect(suggestion!.kind, ElementAutoShadowSuggestionKind.tallThin);
  expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
  expect(suggestion.config.family, StaticShadowFamily.tallProp);
  expect(suggestion.config.scaleX, 0.80);
  expect(suggestion.config.scaleY, 0.55);
  expect(suggestion.config.opacity, 0.20);
  expect(
    suggestion.config.footprint,
    StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1.0,
      footprintWidthRatio: 0.28,
      footprintHeightRatio: 0.05,
    ),
  );
});
```

- [ ] Add test: wide barrier becomes `wideLow`.

```dart
test('very wide low Selbrume props are classified as wideLow', () {
  final suggestion = buildElementAutoShadowSuggestion(
    element: _element(id: 'barriere', width: 13, height: 6),
    shadowCatalog: _defaultCatalog(),
  );

  expect(suggestion, isNotNull);
  expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
  expect(suggestion.config.family, StaticShadowFamily.compactProp);
  expect(suggestion.config.scaleX, 0.74);
  expect(suggestion.config.scaleY, 0.50);
  expect(suggestion.config.opacity, 0.20);
});
```

- [ ] Add test: building config uses V1 values.

```dart
test('building auto suggestion uses restrained V1 footprint', () {
  final suggestion = buildElementAutoShadowSuggestion(
    element: _element(id: 'house', width: 6, height: 7),
    shadowCatalog: _defaultCatalog(),
  );

  expect(suggestion, isNotNull);
  expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
  expect(suggestion.config.family, StaticShadowFamily.building);
  expect(suggestion.config.scaleX, 0.72);
  expect(suggestion.config.scaleY, 0.48);
  expect(suggestion.config.opacity, 0.20);
  expect(
    suggestion.config.footprint,
    StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.60,
      footprintHeightRatio: 0.06,
    ),
  );
});
```

- [ ] Add test: old broad Selbrume config with `family: null` is replaced.

```dart
test('backfill replaces legacy broad Selbrume shadow without family', () {
  final result = applyElementAutoShadowPolicyToProject(
    _project(
      elements: [
        _element(
          id: 'lampadaire',
          width: 3,
          height: 5,
          shadow: _legacyBroadSelbrumeShadowWithoutFamily(),
        ),
      ],
      shadowCatalog: _defaultCatalog(),
    ),
  );

  expect(result.changedCount, 1);
  expect(result.appliedCount, 1);
  expect(
    result.entries.single.status,
    ElementAutoShadowBackfillStatus.appliedGeneric,
  );
  final shadow = result.project.elements.single.shadow!;
  expect(shadow.family, StaticShadowFamily.tallProp);
  expect(shadow.shadowProfileId, 'default-ground-contact-blob');
  expect(shadow.footprint!.footprintWidthRatio, 0.28);
});
```

- [ ] Add test: old broad Selbrume config with `family: building` is replaced.

```dart
test('backfill replaces legacy broad Selbrume building shadow', () {
  final result = applyElementAutoShadowPolicyToProject(
    _project(
      elements: [
        _element(
          id: 'house',
          width: 6,
          height: 7,
          shadow: _legacyBroadSelbrumeShadowWithFamily(
            StaticShadowFamily.building,
          ),
        ),
      ],
      shadowCatalog: _defaultCatalog(),
    ),
  );

  final shadow = result.project.elements.single.shadow!;
  expect(result.changedCount, 1);
  expect(result.appliedCount, 1);
  expect(shadow.family, StaticShadowFamily.building);
  expect(shadow.scaleX, 0.72);
  expect(shadow.scaleY, 0.48);
  expect(shadow.opacity, 0.20);
  expect(shadow.footprint!.footprintWidthRatio, 0.60);
});
```

- [ ] Add helper functions:

```dart
ProjectElementShadowConfig _legacyBroadSelbrumeShadowWithoutFamily() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 0.85,
    opacity: 0.3,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.92,
      footprintWidthRatio: 0.82,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _legacyBroadSelbrumeShadowWithFamily(
  StaticShadowFamily family,
) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 0.85,
    opacity: 0.3,
    family: family,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.92,
      footprintWidthRatio: 0.82,
      footprintHeightRatio: 0.12,
    ),
  );
}
```

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Expected RED:

```text
lampadaire is currently buildingLarge
old broad shadow is currently skippedManual or remains unchanged
```

## 8. Task 4 — Implement Auto Policy Calibration

**Files:**

- Modify: `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`

- [ ] Update `_classifyElement(...)`:

```dart
ElementAutoShadowSuggestionKind _classifyElement({
  required double width,
  required double height,
}) {
  final area = width * height;
  final aspect = height / width;
  final wideAspect = width / height;
  if ((aspect >= 2.2 && width <= 2) ||
      (width <= 3 && height >= 5 && aspect >= 1.4)) {
    return ElementAutoShadowSuggestionKind.tallThin;
  }
  if (width >= 3 && height <= 2) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (width >= 4 && height <= 6 && wideAspect >= 2.0) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (width >= 4 || area >= 12) {
    return ElementAutoShadowSuggestionKind.buildingLarge;
  }
  if (width >= 3 && height <= 3) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (area <= 4) {
    return ElementAutoShadowSuggestionKind.smallSquare;
  }
  return ElementAutoShadowSuggestionKind.defaultProp;
}
```

- [ ] Update `_configForKind(...)` values according to section 4.2.

- [ ] Add legacy broad recognition:

```dart
bool _isRecognizedAutoShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  return _canReplaceExistingShadow(shadow, catalog) ||
      shadow == _oldAutoSmallSquareShadow() ||
      shadow == _oldAutoDefaultPropShadow() ||
      shadow == _oldAutoWideLowShadow() ||
      _isLegacyBroadSelbrumeAutoShadow(shadow);
}

bool _isLegacyBroadSelbrumeAutoShadow(ProjectElementShadowConfig shadow) {
  if (shadow.family != null && shadow.family != StaticShadowFamily.building) {
    return false;
  }
  return shadow.castsShadow &&
      shadow.shadowProfileId == 'default-ground-wide-ellipse' &&
      shadow.offsetX == 0 &&
      shadow.offsetY == 0 &&
      shadow.scaleX == 1 &&
      shadow.scaleY == 0.85 &&
      shadow.opacity == 0.3 &&
      shadow.footprint ==
          StaticShadowFootprintConfig(
            anchorXRatio: 0.5,
            anchorYRatio: 0.92,
            footprintWidthRatio: 0.82,
            footprintHeightRatio: 0.12,
          );
}
```

- [ ] Keep manual custom configs protected:

```text
Do not broaden recognition to any config with custom profile id,
custom opacity, non-zero offset, non-default scale, or non-matching footprint.
```

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Expected GREEN:

```text
All tests passed!
```

## 9. Task 5 — Add Core Integration Calibration Tests

**Files:**

- Modify: `packages/map_core/test/shadow/element_auto_shadow_policy_test.dart`

- [ ] Add a pure geometry assertion proving the new building config produces a smaller projected polygon than the legacy broad config:

```dart
test('V1 building auto config projects far less area than legacy broad config',
    () {
  final legacy = _projectedAreaForShadow(
    _legacyBroadSelbrumeShadowWithFamily(StaticShadowFamily.building),
    visualWidth: 192,
    visualHeight: 224,
  );
  final suggestion = buildElementAutoShadowSuggestion(
    element: _element(id: 'house', width: 6, height: 7),
    shadowCatalog: _defaultCatalog(),
  )!;
  final v1 = _projectedAreaForShadow(
    suggestion.config,
    visualWidth: 192,
    visualHeight: 224,
  );

  expect(v1, lessThan(legacy * 0.30));
});
```

- [ ] Add helper:

```dart
double _projectedAreaForShadow(
  ProjectElementShadowConfig shadow, {
  required double visualWidth,
  required double visualHeight,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: shadow.shadowProfileId!,
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: shadow.offsetX ?? 0,
      offsetY: shadow.offsetY ?? 0,
      scaleX: shadow.scaleX ?? 1,
      scaleY: shadow.scaleY ?? 1,
      opacity: shadow.opacity ?? 0.35,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: shadow.footprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: geometry,
    metrics: metrics,
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
      family: shadow.family ?? StaticShadowFamily.genericProjection,
    ),
  );
  return _projectedPolygonArea(projected.points);
}

double _projectedPolygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var index = 0; index < points.length; index += 1) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}
```

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Expected:

```text
All tests passed!
```

## 10. Task 6 — Regression Matrix

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
```

Optional runtime safety check, without modifying runtime:

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
```

Expected:

```text
All tests passed!
No issues found!
```

## 11. Task 7 — Anti-Drift Scans

Run from repo root:

```bash
git diff --name-only | rg -n "packages/map_runtime/lib|packages/map_editor/lib|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git status --short --untracked-files=all
```

Expected for Shadow-50-owned changes:

```text
No runtime production changes.
No editor production changes.
No map_gameplay changes.
No map_battle changes from Shadow-50.
No model/codec/generated changes.
No renderer/light concepts.
No whitespace errors.
```

Important current repo caveat:

```text
At plan time, main is ahead of origin/main by one non-Shadow commit:
bc67cd3e Lot 25: improve weight-power move parity

There are also map_battle modifications in the working tree. They are out of scope and must not be staged by Shadow-50.
```

## 12. Task 8 — Report

Create:

```text
reports/shadows/shadow_lot_50_selbrume_visual_calibration.md
```

Report must include:

```text
1. Résumé du lot
2. Root cause Selbrume
3. Files created
4. Files modified
5. Pre-existing/out-of-scope files
6. Family projection V1 values
7. Auto policy V1 values
8. Legacy broad config replacement
9. Classification changes
10. Why runtime/editor were not modified
11. Tests added/modified
12. Commands run
13. RED outputs
14. GREEN outputs
15. Regression outputs
16. Anti-drift scans
17. git status initial/final
18. git diff --stat
19. Non-goals respected
20. Risks/reserves
21. Auto-review
22. Full contents of modified text/code files
23. Full focused diff
```

Do not omit changed file contents from the report.

## 13. Acceptance Criteria

Shadow-50 is successful if:

```text
- 3x5 Selbrume lamp dimensions produce tallThin/tallProp config.
- old broad Selbrume configs with family null are recognized and replaced.
- old broad Selbrume configs with family building are recognized and replaced.
- building V1 config is much narrower/lower opacity than legacy broad config.
- family projection V1 values are short and tapered.
- projected area for V1 building auto config is < 30% of legacy broad config in the core test.
- no runtime production file changes.
- no editor production file changes.
- no persistent model or JSON codec changes.
- map_core shadow tests pass.
- map_core analyze passes.
- report is complete.
- no commit unless user explicitly asks.
```

## 14. Expected Visual Result

This lot should not create perfect hand-authored Pokémon shadows yet, but it should visibly remove the worst issue from the screenshot:

```text
Before:
large diagonal slabs attached to houses, lamps, barriers, and props.

After:
shorter, narrower, lower-opacity projected shadows.
lampadaire becomes a thin local projection instead of a building-like slab.
legacy broad configs in Selbrume get upgraded automatically at runtime.
```

If the result is still not acceptable after Shadow-50, the next lots should stop tuning projections and move to:

```text
Shadow-51 — Building Contact Ledge Shadow Mode V0
Shadow-52 — Asset/Family Shadow Mask Decision V0
```

