# Shadow-37 Runtime Static Object Projection Integration V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make runtime static placed element shadows produce `projectedPolygon` instructions instead of oval/contact blob footprints, using the core projected shadow geometry added by Shadow-35 and the renderer support added by Shadow-36.

**Architecture:** `map_core` remains the source of truth for static footprint and projection geometry. `map_runtime` converts the resolved core geometry into `ShadowRuntimeRenderInstruction(shape: ShadowRuntimeShapeKind.projectedPolygon, ...)` for static placed elements only. Actor contact shadows, editor preview, persistent models, JSON codecs, and Flame component wiring stay unchanged.

**Tech Stack:** Dart, Flutter, Flame runtime package, `map_core` pure geometry operations, `ShadowRuntimeRenderer` polygon rendering already present from Shadow-36.

---

## 1. Executive Summary

Shadow-37 is the first lot that should make static object shadows visibly less like round slabs in the runtime.

Current runtime flow:

```text
static placed element -> resolveStaticShadowGeometry(...) -> ShadowRuntimeAnchor -> resolveShadowRuntimeInstruction(...) -> ellipse/contactBlob instruction
```

Target runtime flow:

```text
static placed element -> resolveStaticShadowGeometry(...) -> resolveProjectedStaticShadowGeometry(...) -> projectedPolygon instruction
```

The key design decision is to stop using `resolveShadowRuntimeInstruction(...)` for static placed object shadows in this lot. That generic resolver intentionally maps persistent `ShadowCasterMode.ellipse` and `ShadowCasterMode.contactBlob` to oval-like runtime shapes. Shadow-37 needs a derived runtime-only shape, `projectedPolygon`, without adding a persistent mode.

`ShadowCasterMode.contactBlob` remains valid for actor contact shadows and for the generic resolver. In the static placed element resolver, a `groundStatic` config now means "build a projected static object shadow" regardless of whether the source profile mode was `ellipse` or `contactBlob`.

## 2. Current Audit

Relevant existing files:

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

Shadow-35 already provides:

```dart
ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec = defaultStaticShadowProjectionSpec,
});
```

Shadow-36 already provides:

```dart
enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
  projectedPolygon,
}

final class ShadowRuntimePoint {
  ShadowRuntimePoint({
    required this.worldX,
    required this.worldY,
  });
}
```

And `ShadowRuntimeRenderer` already draws `projectedPolygon` with `Canvas.drawPath(...)`.

Flame documentation check:

```text
mcp__flame_docs__.search_documentation("Flame Component render Canvas draw order priority render method")
-> No results found.

mcp__flame_docs__.search_documentation("Flame render canvas components priority")
-> No results found.
```

Because the MCP documentation search did not return usable entries, this plan relies on local runtime architecture: Shadow instructions are already rendered by the existing runtime shadow renderer, and Shadow-37 does not need to change Flame components or render ordering.

## 3. Files To Modify

Modify:

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
reports/shadows/shadow_lot_37_runtime_static_object_projection_integration.md
```

Optional only if an existing assertion fails because it still expects static placed objects to be oval-shaped:

```text
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
```

Do not modify unless a targeted failure proves they are coupled to the static placed object shape.

## 4. Files Not To Modify

Do not modify:

```text
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
```

The renderer and instruction model were completed in Shadow-36. Shadow-37 should only make static placed sources produce the new shape.

## 5. Design Decision

### 5.1 Static placed shadows should become runtime-only projected polygons

Do:

```text
ProjectShadowProfile / ResolvedShadowConfig -> style and eligibility
StaticShadowFootprintConfig -> base footprint and anchor
resolveStaticShadowGeometry(...) -> final base geometry with offset/scale
resolveProjectedStaticShadowGeometry(...) -> projected polygon points
ShadowRuntimeRenderInstruction.projectedPolygon -> runtime render payload
```

Do not:

```text
add ShadowCasterMode.projectedPolygon
add JSON fields
add renderer code
add Flame components
route through editor canvas
```

### 5.2 Do not use `resolveShadowRuntimeInstruction(...)` for projected static objects

Reason:

`resolveShadowRuntimeInstruction(...)` returns `ellipse` or `contactBlob` based on persistent caster mode. It is still correct for actor contact shadows and generic old-style runtime instructions, but it cannot return a `projectedPolygon` without either adding a persistent mode or changing generic behavior.

Shadow-37 should instead construct `ShadowRuntimeRenderInstruction` directly after projection.

### 5.3 Preserve eligibility semantics

Keep these rules:

```text
resolved.mode == ShadowCasterMode.none -> null
resolved.renderPass != ShadowRenderPass.groundStatic -> ValidationException
resolved.mode must be ellipse or contactBlob for static placed ground shadows
opacity == 0 still returns an instruction
missing profile remains filtered by collection builder
disabled placed override remains filtered by resolveShadowConfig
```

The static resolver may accept both `ellipse` and `contactBlob` as source profile modes, but both should produce `projectedPolygon` when `renderPass == groundStatic`.

## 6. Runtime Resolver Implementation Sketch

Target file:

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
```

Add a private helper to build the same visual metrics object in one place:

```dart
StaticShadowVisualMetrics _visualMetricsFromRuntimeMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return StaticShadowVisualMetrics(
    left: metrics.worldLeft,
    top: metrics.worldTop,
    visualWidth: metrics.visualWidth,
    visualHeight: metrics.visualHeight,
  );
}
```

Update `staticPlacedElementShadowAnchorFromMetrics(...)` to use this helper but preserve its public behavior:

```dart
final geometry = resolveStaticShadowGeometry(
  metrics: _visualMetricsFromRuntimeMetrics(metrics),
  shadowConfig: shadowConfig ?? _identityShadowConfig,
  elementFootprint: legacyAndElementFootprint,
  overrideFootprint: overrideFootprint,
);
```

Add a private helper for full base geometry:

```dart
ResolvedStaticShadowGeometry _resolveStaticPlacedElementBaseGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
    metrics: input.metrics,
    elementFootprint: input.elementFootprint,
  );
  return resolveStaticShadowGeometry(
    metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
    shadowConfig: input.resolvedConfig,
    elementFootprint: legacyAndElementFootprint,
    overrideFootprint: input.overrideFootprint,
  );
}
```

Add mapping from core projection points to runtime points:

```dart
List<ShadowRuntimePoint> _runtimePointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<ShadowRuntimePoint>.unmodifiable(
    geometry.points.map(
      (point) => ShadowRuntimePoint(
        worldX: point.x,
        worldY: point.y,
      ),
    ),
  );
}
```

Add bounds calculation:

```dart
final class _ProjectedRuntimeShadowBounds {
  const _ProjectedRuntimeShadowBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

_ProjectedRuntimeShadowBounds _boundsFromRuntimePoints(
  List<ShadowRuntimePoint> points,
) {
  var minX = points.first.worldX;
  var maxX = points.first.worldX;
  var minY = points.first.worldY;
  var maxY = points.first.worldY;
  for (final point in points.skip(1)) {
    if (point.worldX < minX) {
      minX = point.worldX;
    }
    if (point.worldX > maxX) {
      maxX = point.worldX;
    }
    if (point.worldY < minY) {
      minY = point.worldY;
    }
    if (point.worldY > maxY) {
      maxY = point.worldY;
    }
  }
  return _ProjectedRuntimeShadowBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}
```

Change `resolveStaticPlacedElementShadowRuntimeInstruction(...)` after validation:

```dart
final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: baseGeometry,
  metrics: _visualMetricsFromRuntimeMetrics(input.metrics),
);
final points = _runtimePointsFromProjection(projectedGeometry);
final bounds = _boundsFromRuntimePoints(points);

return ShadowRuntimeRenderInstruction(
  shape: ShadowRuntimeShapeKind.projectedPolygon,
  renderPass: resolved.renderPass,
  worldLeft: bounds.left,
  worldTop: bounds.top,
  width: bounds.width,
  height: bounds.height,
  opacity: resolved.opacity,
  colorHexRgb: resolved.colorHexRgb,
  softnessMode: resolved.softnessMode,
  polygonPoints: points,
);
```

Do not reapply:

```text
offsetX
offsetY
scaleX
scaleY
```

They are already applied by `resolveStaticShadowGeometry(...)`.

## 7. Expected Numeric Baseline

Using current resolver test defaults:

```text
worldLeft = 80
worldTop = 120
visualWidth = 40
visualHeight = 60
anchorXRatio = 0.5
anchorYRatio = 1.0
baseWidthMultiplier = 0.75
baseHeightMultiplier = 0.25
offsetX = 6
offsetY = 10
scaleX = 1.2
scaleY = 0.5
```

Base geometry from Shadow-28/29:

```text
centerX = 106
centerY = 190
width = 36
height = 7.5
```

Default projection from Shadow-35:

```text
directionX = 1.0
directionY = 0.45
lengthRatio = 0.32
nearWidthMultiplier = 0.92
farWidthMultiplier = 1.18
```

Expected projected points, approximately:

```text
nearLeft  = (99.1977, 205.1163)
nearRight = (112.8023, 174.8837)
farRight  = (130.8375, 183.0012)
farLeft   = (113.4112, 221.7251)
```

Expected bounds, approximately:

```text
worldLeft = 99.1977
worldTop = 174.8837
width = 31.6398
height = 46.8414
```

Use `closeTo(..., 0.0001)` in tests. If exact values differ slightly after reading the current core tests, prefer deriving expected points in the test from the public core resolver to avoid duplicating projection math in runtime tests.

## 8. Test Plan

### Task 1: Add resolver RED tests

**Files:**

```text
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

- [ ] Change `resolves ellipse groundStatic into an instruction` to expect:

```dart
expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
expect(instruction.polygonPoints, hasLength(4));
expect(instruction.renderPass, ShadowRenderPass.groundStatic);
```

- [ ] Change `resolves contactBlob groundStatic into an instruction` to expect:

```dart
expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
expect(instruction.polygonPoints, hasLength(4));
expect(instruction.renderPass, ShadowRenderPass.groundStatic);
```

- [ ] Replace oval bounds assertions in `applies static metrics and Shadow-12 offset/scale geometry` with projected bounds assertions from the expected numeric baseline.

- [ ] Add a helper:

```dart
void _expectAllPointsInsideBounds(ShadowRuntimeRenderInstruction instruction) {
  for (final point in instruction.polygonPoints) {
    expect(point.worldX, greaterThanOrEqualTo(instruction.worldLeft));
    expect(point.worldX, lessThanOrEqualTo(instruction.worldLeft + instruction.width));
    expect(point.worldY, greaterThanOrEqualTo(instruction.worldTop));
    expect(point.worldY, lessThanOrEqualTo(instruction.worldTop + instruction.height));
  }
}
```

- [ ] Add a test:

```dart
test('sets bounds that contain all projected polygon points', () {
  final instruction =
      resolveStaticPlacedElementShadowRuntimeInstruction(_input());

  expect(instruction, isNotNull);
  _expectAllPointsInsideBounds(instruction!);
});
```

- [ ] Add a test that proves offset/scale are applied once by comparing the projected points from runtime output to `resolveProjectedStaticShadowGeometry(...)` called with `resolveStaticShadowGeometry(...)`.

Expected RED result before implementation:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Expected failure:

```text
Expected: ShadowRuntimeShapeKind:<ShadowRuntimeShapeKind.projectedPolygon>
  Actual: ShadowRuntimeShapeKind:<ShadowRuntimeShapeKind.ellipse>
```

### Task 2: Implement projected static runtime instruction

**Files:**

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
```

- [ ] Add `_visualMetricsFromRuntimeMetrics(...)`.
- [ ] Add `_resolveStaticPlacedElementBaseGeometry(...)`.
- [ ] Add `_runtimePointsFromProjection(...)`.
- [ ] Add `_ProjectedRuntimeShadowBounds`.
- [ ] Add `_boundsFromRuntimePoints(...)`.
- [ ] Replace the `resolveShadowRuntimeInstruction(...)` call in `resolveStaticPlacedElementShadowRuntimeInstruction(...)` with direct `ShadowRuntimeRenderInstruction(shape: ShadowRuntimeShapeKind.projectedPolygon, ...)`.
- [ ] Keep `staticPlacedElementShadowAnchorFromMetrics(...)` working for existing tests and helper usage.
- [ ] Keep validation messages for `none`, non-`groundStatic`, and unsupported source modes.

Verification:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Expected final line:

```text
+N: All tests passed!
```

Use the exact final line from the command output in the implementation report.

### Task 3: Update collection tests

**Files:**

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

- [ ] Update the main active element test to expect:

```dart
expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
expect(instruction.polygonPoints, hasLength(4));
```

- [ ] Replace old oval width/height/left/top expectations with projected bounds expectations.
- [ ] Update `contactBlob groundStatic profile creates a groundStatic instruction` to assert `projectedPolygon`, while preserving `renderPass == groundStatic`.
- [ ] Update footprint tests to assert polygon points or projected bounds change when `elementShadow.footprint` and `placedOverride.footprint` are present.
- [ ] Keep tests for:

```text
invisible source -> no instruction
null element shadow -> no instruction
castsShadow false -> no instruction
disabled placed override -> no instruction
inherit placed override -> element profile still used
custom placed override -> opacity preserved and geometry changed
missing profile -> no instruction
opacity zero -> retained
multiple sources -> order preserved
identical sources -> not deduplicated
```

Verification:

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Expected final line:

```text
+N: All tests passed!
```

### Task 4: Update host integration tests if coupled to old shape

**Files:**

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

- [ ] Search current assertions for:

```text
ShadowRuntimeShapeKind.ellipse
width
height
worldLeft
worldTop
```

- [ ] If the test asserts static placed shadows are ellipse-shaped, change only those assertions to:

```dart
expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
expect(instruction.polygonPoints, hasLength(4));
```

- [ ] Do not add pixel-golden fragility in this lot.
- [ ] Do not modify Flame host wiring.

Verification:

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Expected final line:

```text
+N: All tests passed!
```

### Task 5: Regression checks

Run:

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
```

If `flutter test` full runtime fails outside `test/shadow`, document the full useful failure and classify whether it is pre-existing or introduced by Shadow-37.

### Task 6: Anti-drift scans

Run from repo root:

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected empty scans:

```text
packages/map_editor|packages/map_gameplay|packages/map_battle -> no output
core models/codecs -> no output
generated files -> no output
advanced renderer/global light terms -> no new Shadow-37 output
git diff --check -> no output
```

`AGENTS.md` is currently modified before Shadow-37 planning. If it is still modified during implementation and unrelated to Shadow-37, report it as pre-existing and do not touch it.

## 9. Report Requirements For Implementation Lot

Create:

```text
reports/shadows/shadow_lot_37_runtime_static_object_projection_integration.md
```

Required sections:

```text
1. Resume du lot
2. Design retenu
3. Fichiers crees
4. Fichiers modifies
5. Fichiers non modifies explicitement
6. Integration de resolveProjectedStaticShadowGeometry cote runtime
7. Mapping ProjectedStaticShadowPoint -> ShadowRuntimePoint
8. Calcul des bounds runtime polygonaux
9. Compatibilite mode none / groundStatic / actorContact
10. Protection contre double offset/scale
11. Transmission elementFootprint / overrideFootprint
12. Pourquoi ce lot ne touche pas editor
13. Pourquoi ce lot ne touche pas aux modeles/codecs
14. Pourquoi ce lot ne change pas les composants Flame
15. Tests ajoutes/modifies
16. Commandes lancees
17. Resultats complets des tests cibles
18. Ligne finale exacte des tests globaux
19. Resultats des scans anti-derive
20. git status initial
21. git status final
22. git diff --stat
23. Non-objectifs respectes
24. Risques / reserves
25. Auto-review finale
26. Regard critique sur le prompt
27. Contenu complet des fichiers crees/modifies
28. Diffs complets ou equivalents /dev/null pour fichiers crees
```

The report must include complete contents of every text/code file modified by Shadow-37 except the report itself.

## 10. Non-Goals

Do not implement:

```text
editor preview polygon rendering
new UI
automatic authoring suggestions
time-of-day
global light direction
ShadowLightProfile
WorldLightState
LightDirection
blur
saveLayer
ImageFilter
shadow atlas
sprite shadows
zOrder
zIndex
new Flame Component
build_runner
JSON migration
persistent model changes
```

## 11. Risks

Risk 1: `contactBlob` static profiles becoming projected polygons may surprise tests.

Mitigation: Document that in static placed `groundStatic`, source mode is an eligibility/style legacy value. Actor contact shadows remain `contactBlob`.

Risk 2: Bounds calculation can be subtly wrong.

Mitigation: Add a test proving all polygon points are inside instruction bounds and that width/height are positive.

Risk 3: Double offset/scale.

Mitigation: Use `resolveStaticShadowGeometry(...)` once, project from the resulting final base geometry, and never call `resolveShadowRuntimeInstruction(...)` for the final static object instruction.

Risk 4: Editor still shows oval shadows after Shadow-37.

Mitigation: This is expected. Shadow-38 is the editor preview integration lot.

Risk 5: Visual output may still need tuning.

Mitigation: Shadow-37 changes the shape class from oval to projected polygon, but projection spec V0 remains heuristic. Later lots can add automatic authoring and visual polish.

## 12. Success Criteria

Shadow-37 is complete when:

```text
static placed runtime instructions are projectedPolygon
polygonPoints are present and valid
bounds contain all polygon points
mode none still returns null
actorContact render pass is still rejected by static resolver
actor contact shadow resolver remains unchanged
elementFootprint influences polygon geometry
overrideFootprint influences polygon geometry
offset/scale are applied exactly once
collection builder still preserves order
renderer code is unchanged
editor code is unchanged
core models/codecs are unchanged
targeted tests pass
runtime shadow suite passes
runtime analyze passes
implementation report is complete
no commit is made unless the user explicitly asks
```

## 13. Auto-Review Checklist

Before finalizing Shadow-37 implementation, answer:

```text
- Ai-je fait produire projectedPolygon aux static placed shadows runtime ? oui.
- Ai-je utilise resolveProjectedStaticShadowGeometry(...) ? oui.
- Ai-je mappe les points core vers ShadowRuntimePoint ? oui.
- Ai-je calcule les bounds depuis les points polygonaux ? oui.
- Ai-je evite resolveShadowRuntimeInstruction(...) pour la sortie statique finale ? oui.
- Ai-je evite double offset/scale ? oui.
- Ai-je conserve mode none -> null ? oui.
- Ai-je conserve le rejet actorContact dans le resolver statique ? oui.
- Ai-je laisse les actor contact shadows intactes ? oui.
- Ai-je evite editor ? oui.
- Ai-je evite les modeles/codecs core ? oui.
- Ai-je evite les composants Flame et l'ordre de rendu ? oui.
- Ai-je evite toute lumiere globale ? oui.
```

## 14. Execution Handoff

Recommended implementation mode:

```text
Inline execution with superpowers:executing-plans.
```

Reason:

The lot is tightly scoped to one runtime resolver and a small set of tests. Subagents are not needed unless unexpected failures split across independent files.

Implementation should proceed in this order:

```text
1. RED resolver tests.
2. Runtime resolver implementation.
3. Collection tests.
4. Host integration adjustments if needed.
5. Targeted regression tests.
6. Anti-drift scans.
7. Evidence report.
```

