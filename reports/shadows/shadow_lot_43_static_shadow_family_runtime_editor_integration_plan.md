# Shadow-43 Static Shadow Family Runtime / Editor Integration V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Repository rule wins over generic plan guidance: do not commit unless the user explicitly asks after implementation.

**Goal:** Make runtime static shadows and editor static preview consume the `StaticShadowFamily` semantics introduced in Shadow-41 and resolved by Shadow-42, so buildings, tall props, compact props, foliage, and generic objects can produce different projected shadow silhouettes.

**Architecture:** Shadow-43 is an integration lot. It must not invent new family geometry values; those belong in Shadow-42 core. Runtime and editor should pass element/override families into the same core family projection resolver, then keep using the existing projected polygon renderer/painter paths. The merge rule is source element family by default, custom placed override family when present, and generic projection when neither is set.

**Tech Stack:** Dart, Flutter tests, `map_core` public operations, `map_runtime` shadow resolver/collection, `map_editor` application preview builder. No build_runner, no generated files, no new Flame component.

---

## 1. Current State

### Completed Lots

Shadow-35 added pure projected shadow geometry:

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
```

Current key API:

```dart
ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec =
      defaultStaticShadowProjectionSpec,
});
```

Shadow-37 connected runtime static shadows to projected polygons:

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
```

Current behavior:

```dart
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
);
```

Shadow-38 connected editor preview to projected polygons:

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
```

Current behavior:

```dart
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: geometry,
  metrics: metrics,
  projectionSpec: _projectionSpecForEditorLightPreview(
    resolvedLightPreviewPreset,
  ),
);
```

Shadow-41 added family semantics:

```dart
enum StaticShadowFamily {
  genericProjection,
  compactProp,
  tallProp,
  building,
  foliage,
}
```

and fields:

```dart
ProjectElementShadowConfig.family
MapPlacedElementShadowOverride.family
```

### Missing Piece Before Shadow-43

Shadow-42 must exist before Shadow-43 implementation. Expected Shadow-42 core contract:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
```

Expected API shape:

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

If Shadow-42 chooses slightly different names, Shadow-43 should adapt at implementation time, but the responsibilities must stay the same:

- family merge is pure `map_core`;
- projection spec adjustment is pure `map_core`;
- runtime/editor consume it, they do not duplicate family tables.

## 2. Scope

Shadow-43 should do:

```text
Runtime Static Shadow Family Integration V0
Editor Static Shadow Family Preview Integration V0
```

Allowed changes:

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
reports/shadows/shadow_lot_43_static_shadow_family_runtime_editor_integration.md
```

Potentially allowed only if tests reveal direct coverage needs:

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_editor/test/map_grid_painter_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
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
```

No new:

```text
Shadow Studio
UI field
persistent light model
time-of-day model
WorldLightState
ShadowLightProfile
LightDirection persistent model
blur
saveLayer
ImageFilter
shadow sprite
shadow atlas
zOrder
zIndex
Flame Component
build_runner
generated files
```

## 3. Flame Documentation Findings

The Flame MCP documentation search was attempted with:

```text
Component render Canvas PositionComponent render order priority Flame
rendering components priority canvas
```

It returned no matching entries.

Shadow-43 does not need new Flame APIs because it should not modify Flame components or the renderer. Existing PokeMap code already routes projected polygon instructions to the current runtime renderer. Shadow-43 only changes the pure data fed to that renderer.

If implementation discovers that `packages/map_runtime/lib/src/presentation/flame/**` must be touched, stop and re-run a focused Flame documentation search before editing.

## 4. Design Decision

Recommended approach:

```text
Family-aware projection spec at resolver boundary
```

Runtime:

```text
StaticPlacedElementShadowRuntimeInput
  resolvedConfig
  metrics
  elementFootprint
  overrideFootprint
  elementFamily
  overrideFamily
```

Runtime collection builder:

```dart
elementFamily: source.elementShadow?.family,
overrideFamily: source.placedOverride?.family,
```

Runtime resolver:

```dart
final family = resolveStaticShadowFamily(
  elementFamily: input.elementFamily,
  overrideFamily: input.overrideFamily,
);
final projectionSpec = resolveStaticShadowFamilyProjectionSpec(
  family: family,
);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
  projectionSpec: projectionSpec,
);
```

Editor:

```dart
final family = resolveStaticShadowFamily(
  elementFamily: element.shadow?.family,
  overrideFamily: placed.shadowOverride?.family,
);
final projectionSpec = resolveStaticShadowFamilyProjectionSpec(
  family: family,
  baseProjectionSpec: _projectionSpecForEditorLightPreview(
    resolvedLightPreviewPreset,
  ),
);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: geometry,
  metrics: metrics,
  projectionSpec: projectionSpec,
);
```

Why this approach:

- runtime and editor share the same family behavior;
- the editor light preview keeps owning time-of-day-like direction and opacity multipliers;
- family modifies silhouette style, not global light direction;
- renderer/painter remain unchanged;
- no family lookup table is duplicated outside `map_core`.

Rejected alternatives:

```text
1. Hard-code family tables in runtime and editor
   Rejected because divergence would return immediately.

2. Put family behavior into ProjectShadowProfile
   Rejected because profiles are shared style, while family belongs to object geometry.

3. Add renderer-specific drawing per family in Shadow-43
   Rejected because the current polygon path is enough; this lot should only feed better specs.
```

## 5. Merge Rules

Family merge is not partial because family is one enum value.

Rules:

```text
elementFamily null + overrideFamily null -> genericProjection
elementFamily building + overrideFamily null -> building
elementFamily building + overrideFamily tallProp -> tallProp
elementFamily null + overrideFamily compactProp -> compactProp
```

`MapPlacedElementShadowOverride.family` can only be non-null in mode `custom` because Shadow-41 model validation already enforces custom-only fields.

Custom override without family must keep the element family:

```text
element family building
placed override custom with family null
-> building
```

## 6. Expected Visual Behavior

Exact geometry values belong to Shadow-42, but Shadow-43 must prove that the resolved family reaches visible instructions.

Expected qualitative differences:

```text
genericProjection
  Same as current projected polygon default.

compactProp
  Smaller, less invasive projection.

tallProp
  Narrower silhouette suitable for lamp posts and signs.

building
  Broader and more stable projection, closer to Pokemon building shadows.

foliage
  Wider organic-ish projection within V0 polygon limits.
```

Editor light presets must remain visible:

```text
morning -> far edge goes one horizontal direction
evening -> far edge goes opposite horizontal direction
family -> changes length/width style but does not cancel light direction
```

## 7. Implementation Tasks

### Task 1: Confirm Shadow-42 Core API Exists

**Files:**

- Inspect: `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- Inspect: `packages/map_core/lib/map_core.dart`
- Inspect: `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

- [ ] **Step 1: Verify exported API**

Run:

```bash
cd /Users/karim/Project/pokemonProject
rg -n "resolveStaticShadowFamily|resolveStaticShadowFamilyProjectionSpec|StaticShadowFamily" packages/map_core/lib packages/map_core/test/shadow
```

Expected:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart contains resolveStaticShadowFamily
packages/map_core/lib/src/operations/static_shadow_family_projection.dart contains resolveStaticShadowFamilyProjectionSpec
packages/map_core/lib/map_core.dart exports static_shadow_family_projection.dart
```

- [ ] **Step 2: Stop if Shadow-42 is absent**

If the API is absent, do not implement Shadow-43. Write:

```text
Shadow-43 blocked: Shadow-42 core family projection resolver is missing.
```

Then create or request the Shadow-42 implementation first.

### Task 2: Runtime Input Carries Family

**Files:**

- Modify: `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- Test: `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

- [ ] **Step 1: Write failing input equality test**

Add under `StaticPlacedElementShadowRuntimeInput` group:

```dart
test('equality includes element and override families', () {
  final a = _input(
    elementFamily: StaticShadowFamily.building,
    overrideFamily: StaticShadowFamily.tallProp,
  );
  final b = _input(
    elementFamily: StaticShadowFamily.building,
    overrideFamily: StaticShadowFamily.tallProp,
  );
  final c = _input(
    elementFamily: StaticShadowFamily.compactProp,
    overrideFamily: StaticShadowFamily.tallProp,
  );

  expect(a, b);
  expect(a.hashCode, b.hashCode);
  expect(a, isNot(c));
});
```

Update test helper signature:

```dart
StaticPlacedElementShadowRuntimeInput _input({
  ResolvedShadowConfig? resolvedConfig,
  StaticPlacedElementShadowRuntimeMetrics? metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ?? _metrics(),
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
    elementFamily: elementFamily,
    overrideFamily: overrideFamily,
  );
}
```

- [ ] **Step 2: Run test and verify RED**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Expected RED:

```text
No named parameter with the name 'elementFamily'
No named parameter with the name 'overrideFamily'
```

- [ ] **Step 3: Add input fields**

In `StaticPlacedElementShadowRuntimeInput`:

```dart
final class StaticPlacedElementShadowRuntimeInput {
  const StaticPlacedElementShadowRuntimeInput({
    required this.resolvedConfig,
    required this.metrics,
    this.elementFootprint,
    this.overrideFootprint,
    this.elementFamily,
    this.overrideFamily,
  });

  final ResolvedShadowConfig resolvedConfig;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final StaticShadowFootprintConfig? elementFootprint;
  final StaticShadowFootprintConfig? overrideFootprint;
  final StaticShadowFamily? elementFamily;
  final StaticShadowFamily? overrideFamily;
}
```

Update equality/hashCode to include both fields:

```dart
other.elementFamily == elementFamily &&
other.overrideFamily == overrideFamily
```

and:

```dart
Object.hash(
  resolvedConfig,
  metrics,
  elementFootprint,
  overrideFootprint,
  elementFamily,
  overrideFamily,
);
```

- [ ] **Step 4: Run test and verify GREEN for input group**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Expected:

```text
All tests passed!
```

### Task 3: Runtime Resolver Uses Family Projection Spec

**Files:**

- Modify: `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- Test: `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`

- [ ] **Step 1: Add family behavior tests**

Add tests under `resolveStaticPlacedElementShadowRuntimeInstruction` group:

```dart
test('null family matches generic projection', () {
  final implicit = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(),
  )!;
  final explicit = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.genericProjection),
  )!;

  _expectSamePolygon(implicit, explicit);
});

test('element family changes projected polygon', () {
  final generic = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.genericProjection),
  )!;
  final building = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.building),
  )!;

  _expectDifferentPolygon(building, generic);
});

test('override family wins over element family', () {
  final expected = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.tallProp),
  )!;
  final actual = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(
      elementFamily: StaticShadowFamily.building,
      overrideFamily: StaticShadowFamily.tallProp,
    ),
  )!;

  _expectSamePolygon(actual, expected);
});

test('custom override without family keeps element family', () {
  final expected = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.building),
  )!;
  final actual = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(
      elementFamily: StaticShadowFamily.building,
      overrideFamily: null,
    ),
  )!;

  _expectSamePolygon(actual, expected);
});

test('tallProp remains narrower than building for same footprint', () {
  final tall = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.tallProp),
  )!;
  final building = resolveStaticPlacedElementShadowRuntimeInstruction(
    _input(elementFamily: StaticShadowFamily.building),
  )!;

  expect(_maxPolygonWidth(tall), lessThan(_maxPolygonWidth(building)));
});
```

Add helpers if absent:

```dart
void _expectSamePolygon(
  ShadowRuntimeRenderInstruction actual,
  ShadowRuntimeRenderInstruction expected,
) {
  expect(actual.polygonPoints, hasLength(expected.polygonPoints.length));
  for (var i = 0; i < expected.polygonPoints.length; i += 1) {
    expect(
      actual.polygonPoints[i].worldX,
      closeTo(expected.polygonPoints[i].worldX, 0.000001),
    );
    expect(
      actual.polygonPoints[i].worldY,
      closeTo(expected.polygonPoints[i].worldY, 0.000001),
    );
  }
}

void _expectDifferentPolygon(
  ShadowRuntimeRenderInstruction actual,
  ShadowRuntimeRenderInstruction expected,
) {
  var hasDifference = false;
  for (var i = 0; i < expected.polygonPoints.length; i += 1) {
    final dx =
        (actual.polygonPoints[i].worldX - expected.polygonPoints[i].worldX)
            .abs();
    final dy =
        (actual.polygonPoints[i].worldY - expected.polygonPoints[i].worldY)
            .abs();
    if (dx > 0.000001 || dy > 0.000001) {
      hasDifference = true;
    }
  }
  expect(hasDifference, isTrue);
}

double _maxPolygonWidth(ShadowRuntimeRenderInstruction instruction) {
  var minX = instruction.polygonPoints.first.worldX;
  var maxX = instruction.polygonPoints.first.worldX;
  for (final point in instruction.polygonPoints.skip(1)) {
    if (point.worldX < minX) {
      minX = point.worldX;
    }
    if (point.worldX > maxX) {
      maxX = point.worldX;
    }
  }
  return maxX - minX;
}
```

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Expected RED:

```text
element family changes projected polygon
Expected different polygon, but family is ignored
```

- [ ] **Step 3: Implement family projection selection**

In `resolveStaticPlacedElementShadowRuntimeInstruction(...)`, replace current projection call:

```dart
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
);
```

with:

```dart
final family = resolveStaticShadowFamily(
  elementFamily: input.elementFamily,
  overrideFamily: input.overrideFamily,
);
final projectionSpec = resolveStaticShadowFamilyProjectionSpec(
  family: family,
);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
  projectionSpec: projectionSpec,
);
```

- [ ] **Step 4: Run runtime resolver tests**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Expected:

```text
All tests passed!
```

### Task 4: Runtime Collection Transmits Families

**Files:**

- Modify: `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`
- Test: `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`

- [ ] **Step 1: Add collection tests**

Add under `buildRuntimeStaticPlacedElementShadowCollection`:

```dart
test('element shadow family is transmitted to runtime resolver', () {
  final generic = buildRuntimeStaticPlacedElementShadowCollection(
    catalog: _catalog(),
    sources: [
      _source(
        elementShadow: _elementShadow(
          profileId: 'plain_ellipse',
          family: StaticShadowFamily.genericProjection,
        ),
      ),
    ],
  ).groundStatic.single;

  final building = buildRuntimeStaticPlacedElementShadowCollection(
    catalog: _catalog(),
    sources: [
      _source(
        elementShadow: _elementShadow(
          profileId: 'plain_ellipse',
          family: StaticShadowFamily.building,
        ),
      ),
    ],
  ).groundStatic.single;

  _expectDifferentPolygon(building, generic);
});

test('placed override family wins over element family in collection', () {
  final expected = buildRuntimeStaticPlacedElementShadowCollection(
    catalog: _catalog(),
    sources: [
      _source(
        elementShadow: _elementShadow(
          profileId: 'plain_ellipse',
          family: StaticShadowFamily.tallProp,
        ),
      ),
    ],
  ).groundStatic.single;

  final actual = buildRuntimeStaticPlacedElementShadowCollection(
    catalog: _catalog(),
    sources: [
      _source(
        elementShadow: _elementShadow(
          profileId: 'plain_ellipse',
          family: StaticShadowFamily.building,
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          family: StaticShadowFamily.tallProp,
        ),
      ),
    ],
  ).groundStatic.single;

  _expectSamePolygon(actual, expected);
});

test('custom override without family keeps element family in collection', () {
  final expected = buildRuntimeStaticPlacedElementShadowCollection(
    catalog: _catalog(),
    sources: [
      _source(
        elementShadow: _elementShadow(
          profileId: 'plain_ellipse',
          family: StaticShadowFamily.building,
        ),
      ),
    ],
  ).groundStatic.single;

  final actual = buildRuntimeStaticPlacedElementShadowCollection(
    catalog: _catalog(),
    sources: [
      _source(
        elementShadow: _elementShadow(
          profileId: 'plain_ellipse',
          family: StaticShadowFamily.building,
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      ),
    ],
  ).groundStatic.single;

  _expectSamePolygon(actual, expected);
});
```

Update `_elementShadow` helper to accept family:

```dart
ProjectElementShadowConfig _elementShadow({
  String profileId = 'plain_ellipse',
  StaticShadowFamily? family,
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: profileId,
    family: family,
  );
}
```

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Expected RED:

```text
family ignored because collection does not pass elementFamily/overrideFamily
```

- [ ] **Step 3: Pass family into input**

In `buildRuntimeStaticPlacedElementShadowCollection(...)`:

```dart
inputs.add(
  StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolved,
    metrics: source.metrics,
    elementFootprint: source.elementShadow?.footprint,
    overrideFootprint: source.placedOverride?.footprint,
    elementFamily: source.elementShadow?.family,
    overrideFamily: source.placedOverride?.family,
  ),
);
```

- [ ] **Step 4: Run collection tests**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Expected:

```text
All tests passed!
```

### Task 5: Editor Preview Uses Family Projection Spec

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- Test: `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

- [ ] **Step 1: Add editor family tests**

Add under `buildEditorStaticShadowPreviewInstructions`:

```dart
test('element family changes projected preview polygon', () {
  final generic = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.genericProjection),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
  ).single;

  final building = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.building),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
  ).single;

  _expectDifferentPreviewPolygon(building, generic);
});

test('placed override family wins over element family in preview', () {
  final expected = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.tallProp),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
  ).single;

  final actual = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.building),
    ),
    map: _map(
      shadowOverride: MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.tallProp,
      ),
    ),
    tileWidth: 16,
    tileHeight: 16,
  ).single;

  _expectSamePreviewPolygon(actual, expected);
});

test('custom override without family keeps element family in preview', () {
  final expected = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.building),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
  ).single;

  final actual = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.building),
    ),
    map: _map(
      shadowOverride: MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
      ),
    ),
    tileWidth: 16,
    tileHeight: 16,
  ).single;

  _expectSamePreviewPolygon(actual, expected);
});

test('family preserves morning and evening preview directions', () {
  final morning = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.building),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
    lightPreviewPreset: editorShadowLightPreviewPresetById('morning'),
  ).single;
  final evening = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      elementShadow: _elementShadow(family: StaticShadowFamily.building),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
    lightPreviewPreset: editorShadowLightPreviewPresetById('evening'),
  ).single;

  expect(_farCenterX(morning), greaterThan(_nearCenterX(morning)));
  expect(_farCenterX(evening), lessThan(_nearCenterX(evening)));
});
```

Add preview helpers if absent:

```dart
void _expectSamePreviewPolygon(
  EditorStaticShadowPreviewInstruction actual,
  EditorStaticShadowPreviewInstruction expected,
) {
  expect(actual.polygonPoints, hasLength(expected.polygonPoints.length));
  for (var i = 0; i < expected.polygonPoints.length; i += 1) {
    expect(actual.polygonPoints[i].x, closeTo(expected.polygonPoints[i].x, 0.000001));
    expect(actual.polygonPoints[i].y, closeTo(expected.polygonPoints[i].y, 0.000001));
  }
}

void _expectDifferentPreviewPolygon(
  EditorStaticShadowPreviewInstruction actual,
  EditorStaticShadowPreviewInstruction expected,
) {
  var hasDifference = false;
  for (var i = 0; i < expected.polygonPoints.length; i += 1) {
    final dx = (actual.polygonPoints[i].x - expected.polygonPoints[i].x).abs();
    final dy = (actual.polygonPoints[i].y - expected.polygonPoints[i].y).abs();
    if (dx > 0.000001 || dy > 0.000001) {
      hasDifference = true;
    }
  }
  expect(hasDifference, isTrue);
}
```

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Expected RED:

```text
element family changes projected preview polygon
Expected different preview polygon, but family is ignored
```

- [ ] **Step 3: Apply family projection spec in preview builder**

Replace:

```dart
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: geometry,
  metrics: metrics,
  projectionSpec: _projectionSpecForEditorLightPreview(
    resolvedLightPreviewPreset,
  ),
);
```

with:

```dart
final family = resolveStaticShadowFamily(
  elementFamily: element.shadow?.family,
  overrideFamily: placed.shadowOverride?.family,
);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
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

- [ ] **Step 4: Run editor preview tests**

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Expected:

```text
All tests passed!
```

### Task 6: Regression and Anti-Drift Verification

**Files:**

- Create: `reports/shadows/shadow_lot_43_static_shadow_family_runtime_editor_integration.md`

- [ ] **Step 1: Run targeted runtime tests**

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Expected:

```text
All tests passed!
No issues found!
```

- [ ] **Step 2: Run targeted editor tests**

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Expected:

```text
All tests passed!
No issues found!
```

- [ ] **Step 3: Run map_core family/projection tests**

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
```

Expected:

```text
All tests passed!
No issues found!
```

- [ ] **Step 4: Run anti-drift scans**

Run:

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_family_json_codec"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core \
  | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected:

```text
No gameplay/battle changes from Shadow-43.
No core models/codecs changes from Shadow-43.
No generated files.
No advanced renderer/global light drift.
No runtime import in editor.
git diff --check has no output.
```

### Task 7: Implementation Report

**Files:**

- Create: `reports/shadows/shadow_lot_43_static_shadow_family_runtime_editor_integration.md`

- [ ] **Step 1: Write report**

The report must contain:

```text
1. Résumé du lot
2. Design retenu
3. Fichiers créés
4. Fichiers modifiés
5. Fichiers non modifiés explicitement
6. Contrat Shadow-42 consommé
7. Intégration runtime family
8. Intégration editor preview family
9. Règles de merge family
10. Compatibilité null/genericProjection
11. Interaction avec preview lumière editor
12. Pourquoi ce lot ne modifie pas renderer/painter
13. Pourquoi ce lot ne crée pas de lumière globale persistante
14. Tests ajoutés/modifiés
15. Commandes lancées
16. Résultats complets utiles des tests ciblés
17. Lignes finales exactes des tests globaux ciblés
18. Résultats des scans anti-dérive
19. git status initial
20. git status final
21. git diff --stat
22. Non-objectifs respectés
23. Risques / réserves
24. Auto-review finale
25. Regard critique sur le prompt/plan
26. Code complet des fichiers créés/modifiés par Shadow-43
27. Diffs complets ou équivalents /dev/null pour fichiers créés
```

- [ ] **Step 2: Auto-review in report**

Include:

```text
- Ai-je consommé la géométrie familiale core Shadow-42 ? oui.
- Ai-je transmis elementFamily et overrideFamily runtime ? oui.
- Ai-je transmis elementFamily et overrideFamily editor ? oui.
- Ai-je gardé null compatible avec genericProjection ? oui.
- Ai-je gardé custom override sans family héritant de l’élément ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de modifier les codecs JSON ? oui.
- Ai-je évité de modifier renderer/painter/Flame components ? oui.
- Ai-je évité une lumière globale persistante ? oui.
- Ai-je préservé la preview lumière editor ? oui.
```

## 8. Final Validation Matrix

Minimum commands before declaring Shadow-43 complete:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow

cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow

cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow

cd /Users/karim/Project/pokemonProject
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 9. Expected Final Summary

```text
Shadow-43 terminé.
Runtime static shadows consomment StaticShadowFamily.
Editor static preview consomme StaticShadowFamily.
Famille élément et override instance transmises.
Override family gagne sur family élément.
Custom override sans family conserve la family élément.
Null/genericProjection reste compatible.
Preview lumière editor préservée.
Aucun renderer/painter/Flame component modifié.
Aucun modèle/codec JSON modifié.
Tests ciblés : ...
map_core shadow : ...
Analyze : ...
Rapport : reports/shadows/shadow_lot_43_static_shadow_family_runtime_editor_integration.md
Aucun commit effectué.
```

## 10. Plan Self-Review

Spec coverage:

```text
Covered: runtime input, runtime resolver, runtime collection, editor preview, family merge, light preview preservation, verification, report.
Intentional dependency: Shadow-42 core family projection API must exist first.
```

Placeholder scan:

```text
No placeholder markers, no unfinished sections, no generic "add tests" steps without examples.
```

Type consistency:

```text
Uses StaticShadowFamily from Shadow-41.
Uses expected Shadow-42 APIs resolveStaticShadowFamily and resolveStaticShadowFamilyProjectionSpec.
Uses existing runtime/editor projected polygon instruction types.
```
