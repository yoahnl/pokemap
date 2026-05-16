# Shadow-44 Static Shadow Visual Calibration Contract V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Repository rule wins over generic plan guidance: do not commit unless the user explicitly asks after implementation.

**Goal:** Add measurable visual contracts for Pokemon-like static shadows so future tuning can prove that lamps, buildings, compact props, foliage, and generic objects no longer collapse into the same odd slab or roaming pancake.

**Architecture:** Shadow-44 is a calibration and regression lot. It should run after Shadow-42 core family projection and Shadow-43 runtime/editor integration. The lot introduces canonical shadow calibration cases and tests their geometry across `map_core`, `map_runtime`, and `map_editor` without adding a new renderer, new UI, persistent light model, or screenshot-only oracle.

**Tech Stack:** Dart, Flutter tests, pure `map_core` geometry, existing runtime/editor projected polygon instructions. No `build_runner`, no generated files, no Flame component, no image snapshot dependency in the first pass.

---

## 1. Why Shadow-44 Exists

The user-facing problem is not only "are shadows visible?" anymore.

The problem is now:

```text
Can we prove that the generated shadows are shaped differently enough for object families?
```

Current risk:

```text
lamp post -> still too wide
building -> still too arbitrary
foliage -> still too mechanical
compact prop -> still too large
generic -> no clear baseline
```

Shadow-41 added the persistent family signal.
Shadow-42 must resolve family into projection specs.
Shadow-43 must consume that family in runtime/editor.

Shadow-44 should add the calibration net that keeps the visual result honest.

## 2. Dependency Gate

Do not implement Shadow-44 until Shadow-42 and Shadow-43 are actually present.

Required APIs/files:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/test/shadow/static_shadow_family_projection_test.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
```

Required functions, names may be adapted only if Shadow-42 chose equivalent names:

```dart
StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
});

StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
  required StaticShadowFamily family,
  StaticShadowProjectionSpec baseProjectionSpec =
      defaultStaticShadowProjectionSpec,
});
```

Required Shadow-43 behavior:

```text
runtime passes elementFamily / overrideFamily
editor preview passes element.shadow?.family / placed.shadowOverride?.family
override family wins over element family
custom override without family keeps element family
```

If these are missing, stop and implement Shadow-42/43 first.

## 3. Current Dirty Worktree To Preserve

At plan creation time, the worktree contains unrelated changes:

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

Shadow-44 must not stage or rewrite those unless they become part of the explicit implementation scope after Shadow-42/43.

## 4. Scope

Shadow-44 should create measurable contracts and, if needed, tune the family projection constants from Shadow-42.

Allowed changes:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/test/shadow/static_shadow_family_visual_contract_test.dart
packages/map_runtime/test/shadow/static_shadow_family_runtime_visual_contract_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_family_visual_contract_test.dart
reports/shadows/shadow_lot_44_static_shadow_visual_calibration_contract.md
```

Optional if implementation needs shared test helpers and they remain test-only:

```text
packages/map_core/test/shadow/static_shadow_visual_contract_helpers.dart
packages/map_runtime/test/shadow/static_shadow_visual_contract_helpers.dart
packages/map_editor/test/application/shadow/static_shadow_visual_contract_helpers.dart
```

Forbidden changes:

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/presentation/flame/**
packages/map_editor/lib/src/ui/canvas/**
packages/map_editor/lib/src/ui/panels/**
packages/map_gameplay/**
packages/map_battle/**
examples/playable_runtime_host/**
```

No new:

```text
Shadow Studio
UI controls
new persistent model
new JSON field
WorldLightState
time-of-day persistent model
LightDirection persistent model
blur
saveLayer
ImageFilter
shadow sprite
shadow atlas
new Flame component
golden image as the only oracle
build_runner
generated files
```

## 5. Calibration Cases

Use deterministic synthetic cases, not real asset screenshots, for the first contract.

### Case A — Lamp Post / Tall Prop

```text
name: lampPostTallProp
family: tallProp
visualWidth: 16
visualHeight: 64
footprintWidthRatio: 0.18
footprintHeightRatio: 0.07
anchorXRatio: 0.5
anchorYRatio: 1.0
scaleX: 1
scaleY: 1
```

Expected contract:

```text
max polygon width is narrow
max polygon width < building max polygon width * 0.45
projection length remains readable but not huge
polygon area < building polygon area * 0.45
```

### Case B — House / Building

```text
name: houseBuilding
family: building
visualWidth: 96
visualHeight: 80
footprintWidthRatio: 0.82
footprintHeightRatio: 0.12
anchorXRatio: 0.5
anchorYRatio: 0.92
scaleX: 1
scaleY: 0.85
```

Expected contract:

```text
building polygon is wider than generic for the same metrics
building polygon area > compact prop polygon area * 2
far edge remains below near edge for default down-right projection
polygon remains attached near the footprint center
```

### Case C — Market Stand / Compact Prop

```text
name: standCompactProp
family: compactProp
visualWidth: 72
visualHeight: 48
footprintWidthRatio: 0.72
footprintHeightRatio: 0.10
anchorXRatio: 0.5
anchorYRatio: 0.95
scaleX: 0.92
scaleY: 0.75
```

Expected contract:

```text
compact area < generic area for the same metrics
compact length < building length for the same metrics
compact far width does not exceed building far width
```

### Case D — Tree / Foliage

```text
name: treeFoliage
family: foliage
visualWidth: 96
visualHeight: 128
footprintWidthRatio: 0.78
footprintHeightRatio: 0.18
anchorXRatio: 0.5
anchorYRatio: 0.90
scaleX: 1
scaleY: 1
```

Expected contract:

```text
foliage area > tall prop area for comparable height
foliage far width is broader than tall prop far width
foliage length remains capped enough to avoid screen-crossing slabs
```

### Case E — Generic Projection Baseline

```text
name: genericProjectionBaseline
family: genericProjection
visualWidth: 48
visualHeight: 48
footprintWidthRatio: 0.62
footprintHeightRatio: 0.12
anchorXRatio: 0.5
anchorYRatio: 0.95
scaleX: 0.90
scaleY: 0.80
```

Expected contract:

```text
generic projection equals the Shadow-35 default behavior
null family resolves to genericProjection
```

## 6. Metrics To Test

Tests should avoid brittle pixel snapshots and inspect geometry metrics:

```dart
final class ShadowVisualContractMetrics {
  const ShadowVisualContractMetrics({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.nearWidth,
    required this.farWidth,
    required this.length,
    required this.area,
    required this.nearCenterX,
    required this.nearCenterY,
    required this.farCenterX,
    required this.farCenterY,
  });
}
```

Helper formulas:

```dart
nearCenter = midpoint(nearLeft, nearRight)
farCenter = midpoint(farLeft, farRight)
nearWidth = distance(nearLeft, nearRight)
farWidth = distance(farLeft, farRight)
length = distance(nearCenter, farCenter)
area = shoelace polygon area
min/max = bounds over points
```

These helpers should stay in tests unless a production need appears later.

## 7. Implementation Tasks

### Task 1: Dependency Gate

**Files:**

- Inspect: `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- Inspect: `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- Inspect: `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`

- [ ] **Step 1: Verify Shadow-42 and Shadow-43 exist**

Run:

```bash
cd /Users/karim/Project/pokemonProject
rg -n "resolveStaticShadowFamily|resolveStaticShadowFamilyProjectionSpec" packages/map_core/lib packages/map_core/test/shadow packages/map_runtime/lib packages/map_editor/lib
```

Expected:

```text
map_core exposes the family resolver and family projection spec resolver.
map_runtime calls resolveStaticShadowFamilyProjectionSpec.
map_editor calls resolveStaticShadowFamilyProjectionSpec.
```

- [ ] **Step 2: Stop if dependencies are missing**

If any required dependency is absent, stop with:

```text
Shadow-44 blocked: Shadow-42/43 family projection integration is missing.
```

Do not add calibration tests against APIs that do not exist.

### Task 2: Add Core Visual Contract Tests

**Files:**

- Create: `packages/map_core/test/shadow/static_shadow_family_visual_contract_test.dart`
- Potentially modify: `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

- [ ] **Step 1: Create contract test file**

Add:

```dart
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('static shadow family visual contracts', () {
    test('null family matches genericProjection baseline', () {
      final implicit = _projectedFor(
        _case(
          family: resolveStaticShadowFamily(
            elementFamily: null,
            overrideFamily: null,
          ),
        ),
      );
      final explicit = _projectedFor(
        _case(family: StaticShadowFamily.genericProjection),
      );

      _expectMetricsClose(_metricsOf(implicit), _metricsOf(explicit));
    });

    test('tallProp stays much narrower than building', () {
      final tall = _metricsOf(_projectedFor(_lampPostTallProp()));
      final building = _metricsOf(_projectedFor(_houseBuilding()));

      expect(tall.maxWidth, lessThan(building.maxWidth * 0.45));
      expect(tall.area, lessThan(building.area * 0.45));
    });

    test('building is broader than compact prop', () {
      final building = _metricsOf(_projectedFor(_houseBuilding()));
      final compact = _metricsOf(_projectedFor(_standCompactProp()));

      expect(building.area, greaterThan(compact.area * 2));
      expect(building.farWidth, greaterThan(compact.farWidth));
    });

    test('compactProp is smaller than generic with same metrics', () {
      final compactCase = _standCompactProp();
      final compact = _metricsOf(_projectedFor(compactCase));
      final generic = _metricsOf(
        _projectedFor(
          compactCase.copyWith(family: StaticShadowFamily.genericProjection),
        ),
      );

      expect(compact.area, lessThan(generic.area));
      expect(compact.length, lessThan(generic.length));
    });

    test('foliage is broader than tallProp without becoming a screen slab', () {
      final foliage = _metricsOf(_projectedFor(_treeFoliage()));
      final tallComparable = _metricsOf(
        _projectedFor(
          _treeFoliage().copyWith(family: StaticShadowFamily.tallProp),
        ),
      );

      expect(foliage.farWidth, greaterThan(tallComparable.farWidth));
      expect(foliage.area, greaterThan(tallComparable.area));
      expect(foliage.length, lessThan(128 * 0.55));
    });
  });
}
```

Add helper types in the same test file:

```dart
final class _VisualCase {
  const _VisualCase({
    required this.family,
    required this.visualWidth,
    required this.visualHeight,
    required this.footprint,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  final StaticShadowFamily family;
  final double visualWidth;
  final double visualHeight;
  final StaticShadowFootprintConfig footprint;
  final double scaleX;
  final double scaleY;

  _VisualCase copyWith({StaticShadowFamily? family}) {
    return _VisualCase(
      family: family ?? this.family,
      visualWidth: visualWidth,
      visualHeight: visualHeight,
      footprint: footprint,
      scaleX: scaleX,
      scaleY: scaleY,
    );
  }
}

final class _VisualMetrics {
  const _VisualMetrics({
    required this.maxWidth,
    required this.nearWidth,
    required this.farWidth,
    required this.length,
    required this.area,
  });

  final double maxWidth;
  final double nearWidth;
  final double farWidth;
  final double length;
  final double area;
}
```

Add case helpers:

```dart
_VisualCase _lampPostTallProp() => _VisualCase(
      family: StaticShadowFamily.tallProp,
      visualWidth: 16,
      visualHeight: 64,
      footprint: StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 1,
        footprintWidthRatio: 0.18,
        footprintHeightRatio: 0.07,
      ),
    );

_VisualCase _houseBuilding() => _VisualCase(
      family: StaticShadowFamily.building,
      visualWidth: 96,
      visualHeight: 80,
      scaleY: 0.85,
      footprint: StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.92,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      ),
    );

_VisualCase _standCompactProp() => _VisualCase(
      family: StaticShadowFamily.compactProp,
      visualWidth: 72,
      visualHeight: 48,
      scaleX: 0.92,
      scaleY: 0.75,
      footprint: StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.95,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      ),
    );

_VisualCase _treeFoliage() => _VisualCase(
      family: StaticShadowFamily.foliage,
      visualWidth: 96,
      visualHeight: 128,
      footprint: StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.90,
        footprintWidthRatio: 0.78,
        footprintHeightRatio: 0.18,
      ),
    );

_VisualCase _case({required StaticShadowFamily family}) => _VisualCase(
      family: family,
      visualWidth: 48,
      visualHeight: 48,
      scaleX: 0.90,
      scaleY: 0.80,
      footprint: StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.95,
        footprintWidthRatio: 0.62,
        footprintHeightRatio: 0.12,
      ),
    );
```

Add projection helpers:

```dart
ProjectedStaticShadowGeometry _projectedFor(_VisualCase visualCase) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualCase.visualWidth,
    visualHeight: visualCase.visualHeight,
  );
  final base = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: 'visual-contract',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: 0,
      offsetY: 0,
      scaleX: visualCase.scaleX,
      scaleY: visualCase.scaleY,
      opacity: 0.35,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: visualCase.footprint,
  );
  return resolveProjectedStaticShadowGeometry(
    baseGeometry: base,
    metrics: metrics,
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
      family: visualCase.family,
    ),
  );
}
```

Add metric helpers:

```dart
_VisualMetrics _metricsOf(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  final xs = points.map((point) => point.x);
  final nearCenter = _midpoint(geometry.nearLeft, geometry.nearRight);
  final farCenter = _midpoint(geometry.farLeft, geometry.farRight);
  return _VisualMetrics(
    maxWidth: xs.reduce(math.max) - xs.reduce(math.min),
    nearWidth: _distance(geometry.nearLeft, geometry.nearRight),
    farWidth: _distance(geometry.farLeft, geometry.farRight),
    length: _distance(nearCenter, farCenter),
    area: _area(points),
  );
}

ProjectedStaticShadowPoint _midpoint(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  return ProjectedStaticShadowPoint(
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  );
}

double _distance(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _area(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

void _expectMetricsClose(_VisualMetrics actual, _VisualMetrics expected) {
  expect(actual.maxWidth, closeTo(expected.maxWidth, 0.000001));
  expect(actual.nearWidth, closeTo(expected.nearWidth, 0.000001));
  expect(actual.farWidth, closeTo(expected.farWidth, 0.000001));
  expect(actual.length, closeTo(expected.length, 0.000001));
  expect(actual.area, closeTo(expected.area, 0.000001));
}
```

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_visual_contract_test.dart
```

Expected RED possibilities:

```text
If Shadow-42 absent: compile failure for resolveStaticShadowFamilyProjectionSpec.
If Shadow-42 present but calibration weak: one or more visual contract assertions fail.
```

- [ ] **Step 3: Tune only Shadow-42 family projection specs if needed**

If tests fail because contracts are not met, modify only:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
```

Allowed tuning dimensions:

```text
lengthRatio
nearWidthMultiplier
farWidthMultiplier
```

Forbidden tuning dimensions:

```text
global direction persistence
new model fields
runtime renderer behavior
editor painter behavior
profile defaults JSON
```

Recommended tuning intent:

```text
tallProp: lower width multipliers, moderate length
compactProp: shorter length, restrained widths
building: broader widths, stable medium length
foliage: broad but capped length
genericProjection: unchanged Shadow-35 default
```

- [ ] **Step 4: Run core tests**

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_visual_contract_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
```

Expected:

```text
All tests passed!
```

### Task 3: Add Runtime Visual Contract Tests

**Files:**

- Create: `packages/map_runtime/test/shadow/static_shadow_family_runtime_visual_contract_test.dart`

- [ ] **Step 1: Create runtime visual contract tests**

Add tests that call:

```dart
resolveStaticPlacedElementShadowRuntimeInstruction(...)
```

with the same canonical cases.

Required behaviors:

```text
runtime tallProp polygon max width < runtime building polygon max width * 0.45
runtime building polygon area > runtime compactProp area * 2
runtime overrideFamily tallProp matches explicit tallProp element family
runtime custom override without family keeps element family
runtime genericProjection matches null family
```

Test skeleton:

```dart
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';

void main() {
  group('runtime static shadow family visual contracts', () {
    test('tallProp remains narrower than building', () {
      final tall = _metricsOf(_instructionFor(_lampPostTallProp()));
      final building = _metricsOf(_instructionFor(_houseBuilding()));

      expect(tall.maxWidth, lessThan(building.maxWidth * 0.45));
      expect(tall.area, lessThan(building.area * 0.45));
    });

    test('override family wins over element family', () {
      final expected = _instructionFor(
        _lampPostTallProp().copyWith(elementFamily: StaticShadowFamily.tallProp),
      );
      final actual = _instructionFor(
        _lampPostTallProp().copyWith(
          elementFamily: StaticShadowFamily.building,
          overrideFamily: StaticShadowFamily.tallProp,
        ),
      );

      _expectSamePolygon(actual, expected);
    });

    test('custom override without family keeps element family', () {
      final expected = _instructionFor(
        _houseBuilding().copyWith(elementFamily: StaticShadowFamily.building),
      );
      final actual = _instructionFor(
        _houseBuilding().copyWith(
          elementFamily: StaticShadowFamily.building,
          overrideFamily: null,
        ),
      );

      _expectSamePolygon(actual, expected);
    });
  });
}
```

Implementation should copy helpers from the core test but adapt point access:

```dart
point.worldX
point.worldY
```

- [ ] **Step 2: Run and verify RED/GREEN**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_shadow_family_runtime_visual_contract_test.dart
```

Expected:

```text
All tests passed after Shadow-43 integration.
If this fails while core passes, Shadow-43 runtime integration is incomplete.
```

### Task 4: Add Editor Preview Visual Contract Tests

**Files:**

- Create: `packages/map_editor/test/application/shadow/editor_static_shadow_family_visual_contract_test.dart`

- [ ] **Step 1: Create editor preview contract tests**

Use:

```dart
buildEditorStaticShadowPreviewInstructions(...)
```

Required behaviors:

```text
editor tallProp polygon max width < editor building polygon max width * 0.45
editor building polygon area > editor compactProp area * 2
editor override family wins over element family
editor custom override without family keeps element family
morning/evening light preview still changes horizontal direction with building family
```

Test skeleton:

```dart
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_light_preview.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('editor static shadow family visual contracts', () {
    test('tallProp remains narrower than building', () {
      final tall = _metricsOf(
        _previewFor(family: StaticShadowFamily.tallProp, width: 1, height: 4),
      );
      final building = _metricsOf(
        _previewFor(family: StaticShadowFamily.building, width: 4, height: 3),
      );

      expect(tall.maxWidth, lessThan(building.maxWidth * 0.45));
      expect(tall.area, lessThan(building.area * 0.45));
    });

    test('light preview direction remains active with building family', () {
      final morning = _previewFor(
        family: StaticShadowFamily.building,
        width: 4,
        height: 3,
        lightPreviewPreset: editorShadowLightPreviewPresetById('morning'),
      );
      final evening = _previewFor(
        family: StaticShadowFamily.building,
        width: 4,
        height: 3,
        lightPreviewPreset: editorShadowLightPreviewPresetById('evening'),
      );

      expect(_farCenterX(morning), greaterThan(_nearCenterX(morning)));
      expect(_farCenterX(evening), lessThan(_nearCenterX(evening)));
    });
  });
}
```

Use local fixture builders from `editor_static_shadow_preview_test.dart` style.

- [ ] **Step 2: Run and verify RED/GREEN**

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_family_visual_contract_test.dart
```

Expected:

```text
All tests passed after Shadow-43 integration.
If this fails while runtime/core pass, editor family integration is incomplete.
```

### Task 5: Optional Calibration Report Table

**Files:**

- Create: `reports/shadows/shadow_lot_44_static_shadow_visual_calibration_contract.md`

- [ ] **Step 1: Add measured values table**

The report should include a table like:

```text
family | case | maxWidth | nearWidth | farWidth | length | area | verdict
tallProp | lampPostTallProp | ... | ... | ... | ... | ... | pass
building | houseBuilding | ... | ... | ... | ... | ... | pass
compactProp | standCompactProp | ... | ... | ... | ... | ... | pass
foliage | treeFoliage | ... | ... | ... | ... | ... | pass
genericProjection | genericProjectionBaseline | ... | ... | ... | ... | ... | pass
```

The values may be copied from test helper diagnostics or computed in the report manually from deterministic tests. Do not invent values; include only measured values from commands or omit the numeric table and state why.

- [ ] **Step 2: Explain limits**

The report must state:

```text
This lot does not prove final art quality.
It proves family separation and guards against regression to identical slabs.
Pixel/screenshot QA remains a later lot.
```

## 8. Verification Commands

Minimum:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_visual_contract_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow

cd packages/map_runtime && flutter test test/shadow/static_shadow_family_runtime_visual_contract_test.dart
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow

cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_family_visual_contract_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Anti-drift:

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle|examples/playable_runtime_host"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_family_json_codec"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core packages/map_runtime packages/map_editor \
  | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 9. Implementation Report Requirements

Create:

```text
reports/shadows/shadow_lot_44_static_shadow_visual_calibration_contract.md
```

Include:

```text
1. Résumé du lot
2. Design retenu
3. Fichiers créés
4. Fichiers modifiés
5. Fichiers non modifiés explicitement
6. Dépendances Shadow-42/43 vérifiées
7. Cas de calibration
8. Métriques mesurées
9. Contrats visuels par famille
10. Tuning effectué ou justification sans tuning
11. Pourquoi ce lot ne change pas renderer/painter
12. Pourquoi ce lot ne crée pas de modèle lumière globale
13. Tests ajoutés/modifiés
14. Commandes lancées
15. Résultats complets utiles des tests ciblés
16. Lignes finales exactes des tests globaux ciblés
17. Résultats des scans anti-dérive
18. git status initial
19. git status final
20. git diff --stat
21. Non-objectifs respectés
22. Risques / réserves
23. Auto-review finale
24. Regard critique sur le prompt/plan
25. Code complet des fichiers créés/modifiés par Shadow-44
26. Diffs complets ou équivalents /dev/null pour fichiers créés
```

Auto-review:

```text
- Ai-je ajouté des contrats visuels mesurables ? oui.
- Ai-je couvert tallProp / building / compactProp / foliage / genericProjection ? oui.
- Ai-je évité les screenshots comme seule preuve ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de modifier les codecs JSON ? oui.
- Ai-je évité de modifier renderer/painter/Flame components ? oui.
- Ai-je évité une lumière globale persistante ? oui.
- Ai-je documenté les limites artistiques restantes ? oui.
```

## 10. Expected Final Summary

```text
Shadow-44 terminé.
Contrats visuels statiques ajoutés pour tallProp / building / compactProp / foliage / genericProjection.
Lampadaire, bâtiment, compact prop et foliage ont des métriques différenciées.
Runtime et editor preview couverts par contrats.
Aucun renderer/painter/Flame component modifié.
Aucun modèle/codec JSON modifié.
Tests ciblés : ...
map_core shadow : ...
map_runtime shadow : ...
map_editor application/shadow : ...
Analyze : ...
Rapport : reports/shadows/shadow_lot_44_static_shadow_visual_calibration_contract.md
Aucun commit effectué.
```

## 11. Plan Self-Review

Spec coverage:

```text
Covered: dependency gate, core contracts, runtime contracts, editor contracts, report, verification, anti-drift.
Intentional dependency: Shadow-42 and Shadow-43 must exist first.
```

Placeholder scan:

```text
No placeholder markers, no unfinished sections, no generic test steps without code examples.
```

Type consistency:

```text
Uses StaticShadowFamily from Shadow-41.
Uses expected Shadow-42 APIs resolveStaticShadowFamily and resolveStaticShadowFamilyProjectionSpec.
Uses runtime/editor polygon instruction types already introduced by Shadow-36/38.
```
