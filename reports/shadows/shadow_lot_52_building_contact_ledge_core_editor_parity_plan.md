# Shadow-52 — Building Contact Ledge Core / Editor Preview Parity V0 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Use TDD for every behavior change.

**Goal:** make runtime and editor preview use the same building contact ledge geometry, without duplicating the Shadow-51 formula in `map_editor`.

**Architecture:** extract the Shadow-51 building contact ledge point computation into a pure `map_core` operation, make `map_runtime` consume it, then make `map_editor` consume the same operation for preview. The renderer and painter stay unchanged: both already draw 4-point `projectedPolygon` instructions.

**Tech Stack:** Dart, Flutter tests, `map_core` pure operations, `map_runtime` shadow resolver, `map_editor` preview builder.

---

## 1. Why This Lot Exists

Shadow-51 changed runtime building shadows from long projected slabs to short contact ledges. That improves the playable runtime, but the editor preview still builds building shadows through `resolveProjectedStaticShadowGeometry(...)`.

If Shadow-52 simply copies the runtime constants into `map_editor`, runtime/editor drift will return immediately.

Shadow-52 should therefore:

- move the building contact ledge formula into `map_core`;
- keep the formula pure and Flutter-free;
- update runtime to consume the core operation;
- update editor preview to consume the same core operation;
- keep painter/renderer unchanged;
- keep all persistent models and JSON codecs unchanged.

## 2. Files

### Create

```text
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md
```

### Modify

```text
packages/map_core/lib/map_core.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

### Do Not Modify

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/*json_codec.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/presentation/flame/**
packages/map_editor/lib/src/ui/canvas/**
packages/map_editor/lib/src/ui/panels/**
packages/map_gameplay/**
packages/map_battle/**
```

## 3. Core API

Create:

```dart
ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
});
```

Why return `ProjectedStaticShadowGeometry`:

- it already stores ordered 4-point polygon geometry;
- it already validates non-degenerate polygons;
- runtime and editor already convert this shape into their own instruction point types;
- no new persistent model is needed.

The operation should use the exact Shadow-51 behavior:

```dart
const buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.55;
const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.48;
const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.30;
const buildingStaticShadowContactLedgeDepthRatio = 0.035;
const buildingStaticShadowContactLedgeMinDepth = 4.0;
const buildingStaticShadowContactLedgeMaxDepth = 14.0;
const buildingStaticShadowContactLedgeSkewRatio = 0.025;
const buildingStaticShadowContactLedgeMinSkew = 0.0;
const buildingStaticShadowContactLedgeMaxSkew = 8.0;
```

Formula:

```dart
final centerX = baseGeometry.centerX;
final nearY = baseGeometry.centerY -
    baseGeometry.height *
        buildingStaticShadowContactLedgeNearHeightOffsetMultiplier;
final farY = baseGeometry.centerY + depth;
final nearHalfWidth =
    baseGeometry.width *
        buildingStaticShadowContactLedgeNearHalfWidthMultiplier;
final farHalfWidth =
    baseGeometry.width *
        buildingStaticShadowContactLedgeFarHalfWidthMultiplier;
final skewX = skew;

return ProjectedStaticShadowGeometry(
  nearLeft: ProjectedStaticShadowPoint(
    x: centerX - nearHalfWidth,
    y: nearY,
  ),
  nearRight: ProjectedStaticShadowPoint(
    x: centerX + nearHalfWidth,
    y: nearY,
  ),
  farRight: ProjectedStaticShadowPoint(
    x: centerX + skewX + farHalfWidth,
    y: farY,
  ),
  farLeft: ProjectedStaticShadowPoint(
    x: centerX + skewX - farHalfWidth,
    y: farY,
  ),
);
```

Depth helper:

```dart
double resolveBuildingStaticShadowContactLedgeDepth(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualHeight * buildingStaticShadowContactLedgeDepthRatio,
    buildingStaticShadowContactLedgeMinDepth,
    buildingStaticShadowContactLedgeMaxDepth,
  );
}
```

Skew helper:

```dart
double resolveBuildingStaticShadowContactLedgeSkew(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualWidth * buildingStaticShadowContactLedgeSkewRatio,
    buildingStaticShadowContactLedgeMinSkew,
    buildingStaticShadowContactLedgeMaxSkew,
  );
}
```

The depth/skew helpers may be public if tests need direct coverage; otherwise keep them private and test through the geometry function.

## 4. Task 1 — Core Contact Ledge Tests

**Files:**

- Create: `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`

Add tests:

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveBuildingStaticShadowContactLedgeGeometry', () {
    test('creates a shallow four point contact ledge', () {
      final metrics = StaticShadowVisualMetrics(
        left: 160,
        top: 96,
        visualWidth: 192,
        visualHeight: 224,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 0.72, scaleY: 0.44),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      expect(geometry.points, hasLength(4));
      expect(geometry.nearLeft.y, closeTo(geometry.nearRight.y, 0.000001));
      expect(geometry.farLeft.y, closeTo(geometry.farRight.y, 0.000001));
      expect(geometry.farLeft.y, greaterThan(geometry.nearLeft.y));
      expect(_bounds(geometry).height, lessThan(18));
      expect(_bounds(geometry).width, lessThan(100));
    });

    test('uses base footprint width', () {
      final metrics = StaticShadowVisualMetrics(
        left: 80,
        top: 120,
        visualWidth: 40,
        visualHeight: 60,
      );
      final narrow = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.25),
        metrics: metrics,
      );
      final wide = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: _base(metrics, footprintWidthRatio: 0.75),
        metrics: metrics,
      );

      expect(_bounds(narrow).width, lessThan(_bounds(wide).width));
    });

    test('applies offset and scale only through base geometry', () {
      final metrics = StaticShadowVisualMetrics(
        left: 80,
        top: 120,
        visualWidth: 40,
        visualHeight: 60,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(
          offsetX: 5,
          offsetY: 7,
          scaleX: 2,
          scaleY: 0.5,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
      );

      final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      final centerX = (geometry.nearLeft.x + geometry.nearRight.x) / 2;
      expect(centerX, closeTo(base.centerX, 0.000001));
      expect(_bounds(geometry).width, greaterThan(base.width));
      expect(_bounds(geometry).height, lessThan(18));
    });
  });
}
```

Run red:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart
```

Expected before implementation:

```text
Error: Method not found: 'resolveBuildingStaticShadowContactLedgeGeometry'
```

## 5. Task 2 — Implement Core Operation

**Files:**

- Create: `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- Modify: `packages/map_core/lib/map_core.dart`

Implementation:

```dart
import 'static_shadow_geometry.dart';
import 'static_shadow_projection_geometry.dart';

const buildingStaticShadowContactLedgeNearHalfWidthMultiplier = 0.55;
const buildingStaticShadowContactLedgeFarHalfWidthMultiplier = 0.48;
const buildingStaticShadowContactLedgeNearHeightOffsetMultiplier = 0.30;
const buildingStaticShadowContactLedgeDepthRatio = 0.035;
const buildingStaticShadowContactLedgeMinDepth = 4.0;
const buildingStaticShadowContactLedgeMaxDepth = 14.0;
const buildingStaticShadowContactLedgeSkewRatio = 0.025;
const buildingStaticShadowContactLedgeMinSkew = 0.0;
const buildingStaticShadowContactLedgeMaxSkew = 8.0;

ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
}) {
  final centerX = baseGeometry.centerX;
  final nearY = baseGeometry.centerY -
      baseGeometry.height *
          buildingStaticShadowContactLedgeNearHeightOffsetMultiplier;
  final farY = baseGeometry.centerY +
      _buildingStaticShadowContactLedgeDepth(metrics);
  final nearHalfWidth =
      baseGeometry.width *
          buildingStaticShadowContactLedgeNearHalfWidthMultiplier;
  final farHalfWidth =
      baseGeometry.width *
          buildingStaticShadowContactLedgeFarHalfWidthMultiplier;
  final skewX = _buildingStaticShadowContactLedgeSkew(metrics);

  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(
      x: centerX - nearHalfWidth,
      y: nearY,
    ),
    nearRight: ProjectedStaticShadowPoint(
      x: centerX + nearHalfWidth,
      y: nearY,
    ),
    farRight: ProjectedStaticShadowPoint(
      x: centerX + skewX + farHalfWidth,
      y: farY,
    ),
    farLeft: ProjectedStaticShadowPoint(
      x: centerX + skewX - farHalfWidth,
      y: farY,
    ),
  );
}

double _buildingStaticShadowContactLedgeDepth(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualHeight * buildingStaticShadowContactLedgeDepthRatio,
    buildingStaticShadowContactLedgeMinDepth,
    buildingStaticShadowContactLedgeMaxDepth,
  );
}

double _buildingStaticShadowContactLedgeSkew(
  StaticShadowVisualMetrics metrics,
) {
  return _clampDouble(
    metrics.visualWidth * buildingStaticShadowContactLedgeSkewRatio,
    buildingStaticShadowContactLedgeMinSkew,
    buildingStaticShadowContactLedgeMaxSkew,
  );
}

double _clampDouble(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
```

Export:

```dart
export 'src/operations/static_shadow_contact_ledge_geometry.dart';
```

Run green:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_contact_ledge_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
```

## 6. Task 3 — Runtime Consumes Core Ledge Operation

**Files:**

- Modify: `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- Modify: `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

Remove the private Shadow-51 constants and helpers from runtime.

Replace:

```dart
final points = _buildingContactLedgePoints(
  geometry: baseGeometry,
  metrics: input.metrics,
);
```

with:

```dart
final ledgeGeometry = resolveBuildingStaticShadowContactLedgeGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
);
final points = _runtimePointsFromProjection(ledgeGeometry);
```

Keep:

```dart
shape: ShadowRuntimeShapeKind.projectedPolygon
```

Test update:

- remove duplicated expected formula helpers from runtime tests where possible;
- use the core operation to compute expected points;
- keep behavior tests proving building is short and non-building still uses projection.

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

## 7. Task 4 — Editor Preview Uses Core Building Ledge

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- Modify: `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

In the builder, compute the family once:

```dart
final family = resolveStaticShadowFamily(
  elementFamily: element.shadow?.family,
  overrideFamily: placed.shadowOverride?.family,
);
```

Then:

```dart
final polygonGeometry = family == StaticShadowFamily.building
    ? resolveBuildingStaticShadowContactLedgeGeometry(
        baseGeometry: geometry,
        metrics: metrics,
      )
    : resolveProjectedStaticShadowGeometry(
        baseGeometry: geometry,
        metrics: metrics,
        projectionSpec: resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: _projectionSpecForEditorLightPreview(
            resolvedLightPreviewPreset,
          ),
        ),
      );
```

Then map:

```dart
final points = _editorPreviewPointsFromProjection(polygonGeometry);
```

Decision:

```text
Building contact ledges ignore editor light preview direction and length.
They still use light preview opacity multiplier.
```

Why:

- a contact ledge is not a long cast shadow;
- morning/evening direction should not reintroduce diagonal slabs for buildings;
- opacity preview remains useful to compare visibility.

## 8. Editor Tests

Add tests in:

```text
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

### Test 1 — building family emits contact ledge preview

Expected:

```text
- shape projectedPolygon
- 4 points
- near edge horizontal
- far edge horizontal
- far edge below near edge
- height < 18 for Selbrume-like house metrics
```

### Test 2 — preview building matches core ledge

Build expected:

```dart
final base = resolveStaticShadowGeometry(...);
final expected = resolveBuildingStaticShadowContactLedgeGeometry(
  baseGeometry: base,
  metrics: metrics,
);
```

Assert points/bounds match.

### Test 3 — override family building wins

Use:

```dart
element.family = StaticShadowFamily.tallProp
override.family = StaticShadowFamily.building
```

Expected:

```text
contact ledge, not long projected shadow
```

### Test 4 — non-building keeps light-preview projection

Use:

```dart
family = StaticShadowFamily.tallProp
lightPreviewPreset = morning
```

Expected:

```text
old morning direction behavior still applies
```

### Test 5 — building ignores morning/evening direction but keeps opacity multiplier

Build neutral and morning for a building.

Expected:

```text
polygon points equal
morning opacity < neutral opacity
```

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

## 9. Anti-Drift Scans

Run:

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git status --short --untracked-files=all
```

Expected for Shadow-52-owned changes:

```text
No map_gameplay/map_battle changes.
No model/codec/generated changes.
No advanced renderer/light/global time concepts.
No map_runtime import in map_editor.
```

Existing unrelated dirty files must be reported separately and not staged.

## 10. Report Requirements

Create:

```text
reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md
```

Include:

- summary;
- files created/modified;
- files explicitly not modified;
- Flame docs note: no new Flame API used;
- core ledge operation design;
- runtime extraction result;
- editor preview parity result;
- tests run with exact outputs;
- global test failures, if any, attributed precisely;
- anti-drift scans;
- final `git status --short --untracked-files=all`;
- self-review;
- full contents of created/modified text/code files where reasonable.

## 11. Acceptance Criteria

Shadow-52 is done when:

- `map_core` owns the building contact ledge formula;
- runtime building shadows still use short contact ledges;
- editor preview building shadows use the same core ledges;
- non-building projected previews still honor light preview direction/length;
- building contact ledges do not reintroduce morning/evening long slabs;
- editor preview still applies opacity preview multipliers;
- painter and renderer are unchanged;
- no model/codec/generated files are modified;
- targeted tests pass;
- analyzer checks pass;
- unrelated `map_battle` dirty work remains untouched.

