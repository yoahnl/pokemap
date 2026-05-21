# Shadow-38 Editor Static Projected Shadow Preview V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Do not run Git write operations unless the user explicitly asks for them.

**Goal:** Make the editor canvas static shadow preview draw the same projected polygon family that the runtime static shadows now draw.

**Architecture:** `map_core` remains the source of truth for static shadow footprint and projection geometry. `map_editor` resolves the existing editor preview inputs, converts the core projected geometry into editor preview points, and lets the existing canvas painter draw either a projected path or the legacy oval fallback. Runtime, persistent models, JSON codecs, editor panels, and editor state remain out of scope.

**Tech Stack:** Dart, Flutter canvas `dart:ui`, `map_core` pure shadow geometry, `map_editor` application builder and canvas painter tests.

---

## 1. Resume

Shadow-37 made runtime static placed element shadows use `resolveProjectedStaticShadowGeometry` and produce projected polygon render instructions.

Shadow-38 should now make the editor canvas preview use the same projected polygon core operation, so what the author sees in the editor is aligned with what the runtime renders for static placed elements.

The lot should not add a new UI, should not touch `map_runtime`, and should not change any persistent shadow model. This is an editor preview integration lot only.

## 2. Audit Workflow

Applicable `AGENTS.md` files found:

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Only `../pokemonProject/AGENTS.md` applies to this repository.

Important constraints for Shadow-38:

- keep `map_editor` decoupled from `map_runtime`;
- keep shared geometry in `map_core`;
- do not modify persistent models or JSON codecs;
- do not change editor panels/state;
- do not run Git write operations unless the user explicitly asks;
- produce a complete implementation report when coding the lot.

Initial working tree observed while writing this plan:

```text
 M AGENTS.md
```

`AGENTS.md` is pre-existing/unrelated to Shadow-38 and must not be modified by this lot.

## 3. Current State

### 3.1 Core Projection

`packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart` already provides:

```dart
ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec =
      defaultStaticShadowProjectionSpec,
});
```

The operation is exported by `packages/map_core/lib/map_core.dart`, so `map_editor` can consume it through `package:map_core/map_core.dart`.

Default projection V0:

```text
directionX = 1.0
directionY = 0.45
lengthRatio = 0.32
nearWidthMultiplier = 0.92
farWidthMultiplier = 1.18
```

### 3.2 Runtime After Shadow-37

`packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart` now:

- resolves the base static shadow geometry with `resolveStaticShadowGeometry`;
- projects it with `resolveProjectedStaticShadowGeometry`;
- maps core points to runtime `ShadowRuntimePoint`;
- returns a `ShadowRuntimeRenderInstruction` with `shape: ShadowRuntimeShapeKind.projectedPolygon`, polygon points, and bounds derived from those points.

This is the behavior the editor preview should mirror for static placed elements.

### 3.3 Editor Preview Before Shadow-38

`packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart` currently:

- filters invalid layers/elements/profiles;
- resolves `ResolvedShadowConfig`;
- computes `ResolvedStaticShadowGeometry`;
- applies `applyEditorShadowLightPreviewPreset` to a rectangle;
- emits `EditorStaticShadowPreviewInstruction` with `left/top/width/height`;
- stores `shape` as `ShadowCasterMode`.

`packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart` currently:

- ignores `ShadowCasterMode.none`;
- draws every preview instruction with `canvas.drawOval`;
- uses no blur, no `saveLayer`, no atlas, and no runtime import.

## 4. Decision

Implement Shadow-38 by adding editor-local projected preview support:

- add `EditorStaticShadowPreviewShapeKind`;
- add `EditorStaticShadowPreviewPoint`;
- extend `EditorStaticShadowPreviewInstruction` with `polygonPoints`;
- make `buildEditorStaticShadowPreviewInstructions` emit `projectedPolygon` instructions for static placed element shadows;
- use `resolveProjectedStaticShadowGeometry` after `resolveStaticShadowGeometry`;
- map projected geometry bounds into `left/top/width/height`;
- make the painter draw `projectedPolygon` with `ui.Path` and `canvas.drawPath`;
- keep an oval fallback for tests/future non-projected preview instructions;
- preserve existing filters and render order.

Do not reuse `ShadowRuntimeShapeKind` or `ShadowRuntimePoint` in `map_editor`. That would couple the editor to runtime internals. The editor should have small local preview value objects and consume only `map_core`.

## 5. Files To Modify

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

`test/map_grid_painter_test.dart` should only be changed if constructors or expected preview instruction fields require it. The intended render order must remain unchanged.

Implementation report to create during the coding lot:

```text
reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
```

## 6. Files Not To Modify

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
packages/map_editor/lib/src/ui/panels/**
packages/map_editor/lib/src/features/editor/state/**
```

Do not modify `MapGridPainter` production code unless an audit reveals an actual compile break. The expected result is that the existing painter receives richer preview instructions while the existing canvas render order stays the same.

## 7. Editor Preview API

In `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`, add an editor-local render shape:

```dart
enum EditorStaticShadowPreviewShapeKind {
  oval,
  projectedPolygon,
}
```

Add an editor-local point value object:

```dart
final class EditorStaticShadowPreviewPoint {
  EditorStaticShadowPreviewPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'EditorStaticShadowPreviewPoint.x');
    _validateFinite(y, 'EditorStaticShadowPreviewPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewPoint &&
          other.x == x &&
          other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
```

Update `EditorStaticShadowPreviewInstruction` so `shape` is an editor render shape and polygon points are explicit:

```dart
final class EditorStaticShadowPreviewInstruction {
  EditorStaticShadowPreviewInstruction({
    required this.instanceId,
    required this.elementId,
    required this.shape,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.colorHexRgb,
    Iterable<EditorStaticShadowPreviewPoint> polygonPoints = const [],
  }) : polygonPoints =
            List<EditorStaticShadowPreviewPoint>.unmodifiable(polygonPoints) {
    _validateNonBlank(instanceId, 'EditorStaticShadowPreviewInstruction.instanceId');
    _validateNonBlank(elementId, 'EditorStaticShadowPreviewInstruction.elementId');
    _validateFinite(left, 'EditorStaticShadowPreviewInstruction.left');
    _validateFinite(top, 'EditorStaticShadowPreviewInstruction.top');
    _validatePositiveFinite(width, 'EditorStaticShadowPreviewInstruction.width');
    _validatePositiveFinite(height, 'EditorStaticShadowPreviewInstruction.height');
    _validateOpacity(opacity);
    _validateColorHexRgb(colorHexRgb);
    _validatePreviewPolygon(shape, this.polygonPoints);
  }

  final String instanceId;
  final String elementId;
  final EditorStaticShadowPreviewShapeKind shape;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final List<EditorStaticShadowPreviewPoint> polygonPoints;
}
```

The validation helpers should mirror the runtime rules without importing runtime:

```dart
void _validatePreviewPolygon(
  EditorStaticShadowPreviewShapeKind shape,
  List<EditorStaticShadowPreviewPoint> points,
) {
  switch (shape) {
    case EditorStaticShadowPreviewShapeKind.oval:
      if (points.isNotEmpty) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction polygonPoints are only allowed for projectedPolygon',
        );
      }
    case EditorStaticShadowPreviewShapeKind.projectedPolygon:
      if (points.length < 3) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon requires at least 3 points',
        );
      }
      if (_previewPolygonArea(points) <= 0) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon must be non-degenerate',
        );
      }
  }
}
```

Why a local enum:

- `ShadowCasterMode` is persistent authoring/domain state;
- projected polygon is a preview/render instruction shape, not a JSON model mode;
- `map_editor` must not import runtime's `ShadowRuntimeShapeKind`.

## 8. Builder Changes

In `buildEditorStaticShadowPreviewInstructions`, preserve all existing filters:

- invalid `tileWidth` / `tileHeight` returns no instructions;
- no placed elements returns no instructions;
- missing element returns no instruction;
- empty frames return no instruction;
- invalid source rect returns no instruction;
- invisible tile layer returns no instruction;
- missing profile returns no instruction through `resolveShadowConfig`;
- `resolved.renderPass != ShadowRenderPass.groundStatic` returns no instruction;
- `resolved.mode == ShadowCasterMode.none` returns no instruction.

Replace the final rectangle-only light preview mapping with:

```dart
final visualMetrics = StaticShadowVisualMetrics(
  left: baseLeft,
  top: baseTop,
  visualWidth: visualWidth,
  visualHeight: visualHeight,
);
final baseGeometry = resolveStaticShadowGeometry(
  metrics: visualMetrics,
  shadowConfig: resolved,
  elementFootprint: element.shadow?.footprint,
  overrideFootprint: placed.shadowOverride?.footprint,
);
final projectionSpec = _projectionSpecForEditorLightPreview(
  resolvedLightPreviewPreset,
);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  baseGeometry: baseGeometry,
  metrics: visualMetrics,
  projectionSpec: projectionSpec,
);
final polygonPoints = _editorPreviewPointsFromProjection(projectedGeometry);
final bounds = _boundsFromEditorPreviewPoints(polygonPoints);
final opacity = _opacityForEditorLightPreview(
  resolved.opacity,
  resolvedLightPreviewPreset,
);

instructions.add(
  EditorStaticShadowPreviewInstruction(
    instanceId: placed.id,
    elementId: placed.elementId,
    shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
    left: bounds.left,
    top: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: opacity,
    colorHexRgb: resolved.colorHexRgb,
    polygonPoints: polygonPoints,
  ),
);
```

Do not call `applyEditorShadowLightPreviewPreset` for projected polygon instructions. That helper transforms an oval rectangle; applying it after projection would distort polygon bounds separately from polygon points or apply the time-of-day preview twice.

Add local conversion helpers in `editor_static_shadow_preview.dart`:

```dart
List<EditorStaticShadowPreviewPoint> _editorPreviewPointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<EditorStaticShadowPreviewPoint>.unmodifiable(
    geometry.points.map(
      (point) => EditorStaticShadowPreviewPoint(x: point.x, y: point.y),
    ),
  );
}
```

```dart
_EditorStaticShadowPreviewBounds _boundsFromEditorPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _EditorStaticShadowPreviewBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}
```

```dart
final class _EditorStaticShadowPreviewBounds {
  const _EditorStaticShadowPreviewBounds({
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
```

## 9. Light Preview Mapping

Shadow-34 added `EditorShadowLightPreviewPreset`. Shadow-38 should keep that input meaningful, but it must adapt it to projection instead of transforming the old oval rectangle.

Use this mapping:

```dart
StaticShadowProjectionSpec _projectionSpecForEditorLightPreview(
  EditorShadowLightPreviewPreset preset,
) {
  final hasDirection = preset.directionX != 0 || preset.directionY != 0;
  final lengthRatio = preset.lengthMultiplier > 0
      ? preset.lengthMultiplier
      : defaultStaticShadowProjectionLengthRatio * preset.scaleYMultiplier;

  return StaticShadowProjectionSpec(
    directionX: hasDirection
        ? preset.directionX
        : defaultStaticShadowProjectionDirectionX,
    directionY: hasDirection
        ? preset.directionY
        : defaultStaticShadowProjectionDirectionY,
    lengthRatio: lengthRatio,
    nearWidthMultiplier:
        defaultStaticShadowProjectionNearWidthMultiplier *
            preset.scaleXMultiplier,
    farWidthMultiplier:
        defaultStaticShadowProjectionFarWidthMultiplier *
            preset.scaleXMultiplier,
  );
}
```

Opacity still uses the preset multiplier:

```dart
double _opacityForEditorLightPreview(
  double opacity,
  EditorShadowLightPreviewPreset preset,
) {
  final nextOpacity = opacity * preset.opacityMultiplier;
  if (nextOpacity < 0) {
    return 0;
  }
  if (nextOpacity > 1) {
    return 1;
  }
  return nextOpacity;
}
```

Behavior after this change:

- neutral preview uses the same default projected shape as runtime;
- noon preview keeps the same direction but uses a shorter projection and lower opacity;
- morning preview projects toward bottom-right;
- evening preview projects toward bottom-left;
- this remains editor-only preview state and does not create a persistent global light model.

## 10. Painter Changes

In `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`, replace the unconditional `drawOval` with a switch:

```dart
switch (instruction.shape) {
  case EditorStaticShadowPreviewShapeKind.oval:
    canvas.drawOval(
      ui.Rect.fromLTWH(
        instruction.left,
        instruction.top,
        instruction.width,
        instruction.height,
      ),
      paint,
    );
  case EditorStaticShadowPreviewShapeKind.projectedPolygon:
    final path = _pathFromEditorStaticShadowPreviewPoints(
      instruction.polygonPoints,
    );
    if (path != null) {
      canvas.drawPath(path, paint);
    }
}
```

Add:

```dart
ui.Path? _pathFromEditorStaticShadowPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  if (points.length < 3) {
    return null;
  }
  final first = points.first;
  final path = ui.Path()..moveTo(first.x, first.y);
  for (final point in points.skip(1)) {
    path.lineTo(point.x, point.y);
  }
  path.close();
  return path;
}
```

Keep:

```dart
ui.Paint()
  ..color = color
  ..style = ui.PaintingStyle.fill
  ..isAntiAlias = false
```

Do not add:

- `saveLayer`;
- `ImageFilter`;
- blur;
- atlas rendering;
- runtime imports.

## 11. Test Plan

### 11.1 Builder Tests

Modify `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`.

Replace rectangle-only expectations with projection-aware expectations. Add a helper that compares instructions to the core projection instead of duplicating projection math in hardcoded numbers:

```dart
void _expectProjectedInstructionMatchesCore({
  required EditorStaticShadowPreviewInstruction instruction,
  required ResolvedShadowConfig shadowConfig,
  required StaticShadowVisualMetrics metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  StaticShadowProjectionSpec projectionSpec =
      defaultStaticShadowProjectionSpec,
  double opacity = 0.35,
}) {
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: shadowConfig,
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: projectionSpec,
  );

  expect(instruction.shape, EditorStaticShadowPreviewShapeKind.projectedPolygon);
  expect(instruction.opacity, closeTo(opacity, 0.001));
  expect(instruction.polygonPoints, hasLength(projected.points.length));
  for (var i = 0; i < projected.points.length; i += 1) {
    expect(instruction.polygonPoints[i].x, closeTo(projected.points[i].x, 0.001));
    expect(instruction.polygonPoints[i].y, closeTo(projected.points[i].y, 0.001));
  }

  final bounds = _testBounds(projected.points);
  expect(instruction.left, closeTo(bounds.left, 0.001));
  expect(instruction.top, closeTo(bounds.top, 0.001));
  expect(instruction.width, closeTo(bounds.width, 0.001));
  expect(instruction.height, closeTo(bounds.height, 0.001));
}
```

Add test-local bounds helper:

```dart
_TestBounds _testBounds(List<ProjectedStaticShadowPoint> points) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    minX = point.x < minX ? point.x : minX;
    maxX = point.x > maxX ? point.x : maxX;
    minY = point.y < minY ? point.y : minY;
    maxY = point.y > maxY ? point.y : maxY;
  }
  return _TestBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}
```

Add test-local bounds class:

```dart
final class _TestBounds {
  const _TestBounds({
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
```

Builder tests to keep or add:

1. `builds a projected groundStatic instruction`
   - old `builds an ellipse groundStatic instruction` becomes projected;
   - expect `shape == EditorStaticShadowPreviewShapeKind.projectedPolygon`;
   - expect `polygonPoints.length == 4`;
   - expect `instanceId`, `elementId`, `opacity`, `colorHexRgb` unchanged.

2. `neutral light preview matches the runtime default projection`
   - call without explicit light preset and with `neutral`;
   - both should match `defaultStaticShadowProjectionSpec`.

3. `noon light preview shortens the projected polygon once`
   - compare default/neutral vs noon;
   - expect far-center distance from near-center to be smaller;
   - expect opacity lower than neutral;
   - do not assert old ellipse `width/height`.

4. `morning and evening light previews project in opposite horizontal directions`
   - morning far center x greater than near center x;
   - evening far center x less than near center x;
   - both far center y greater than near center y.

5. `contactBlob groundStatic still produces a projected preview instruction`
   - profile mode `contactBlob`;
   - output shape is projected polygon because static placed elements use projected shadows in Shadow-38;
   - this does not affect actor contact shadows.

6. `ignores empty catalog and missing profiles`
   - keep current expectations.

7. `ignores missing disabled incompatible and invalid sources`
   - keep current expectations.

8. `ignores invisible tile layers`
   - keep current expectations.

9. `applies disabled and custom overrides`
   - disabled remains empty;
   - custom offset/scale affects projected points once through `resolveStaticShadowGeometry`.

10. `uses element footprint for preview projection`
    - compare against core projection with `elementFootprint`.

11. `uses override footprint over element footprint field by field`
    - compare against core projection with both footprints.

12. `custom override without footprint keeps element footprint`
    - compare against core projection with element footprint only.

13. `custom profile overrides source profile and null profile inherits it`
    - verify opacity/color and projected points reflect selected profile scale.

14. `preserves source order and opacity zero instructions`
    - keep order expectation;
    - opacity zero instructions remain emitted so painter can skip them.

15. `instruction equality and hashCode include polygon points`
    - two instructions with equal points compare equal;
    - different point list compares different.

16. `projected instruction rejects degenerate polygon points`
    - direct constructor throws `ValidationException` for three collinear points.

### 11.2 Painter Tests

Modify `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`.

Add a projected polygon fixture:

```dart
EditorStaticShadowPreviewInstruction _projectedInstruction({
  double opacity = 0.5,
}) {
  return EditorStaticShadowPreviewInstruction(
    instanceId: 'stand_1',
    elementId: 'stand',
    shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
    left: 8,
    top: 8,
    width: 28,
    height: 20,
    opacity: opacity,
    colorHexRgb: '000000',
    polygonPoints: [
      EditorStaticShadowPreviewPoint(x: 10, y: 12),
      EditorStaticShadowPreviewPoint(x: 24, y: 10),
      EditorStaticShadowPreviewPoint(x: 34, y: 28),
      EditorStaticShadowPreviewPoint(x: 12, y: 26),
    ],
  );
}
```

Painter tests to keep or add:

1. `draws a projected polygon interior pixel`
   - paint `_projectedInstruction()`;
   - sample a point inside the polygon, such as `(20, 18)`;
   - expect alpha greater than 0.

2. `projected polygon leaves outside pixel transparent`
   - sample `(4, 4)`;
   - expect alpha equals 0.

3. `opacity zero does not color projected polygon pixel`
   - paint `_projectedInstruction(opacity: 0)`;
   - sample inside pixel;
   - expect alpha equals 0.

4. `draws an oval fallback instruction`
   - construct `EditorStaticShadowPreviewInstruction(shape: EditorStaticShadowPreviewShapeKind.oval, left: 8, top: 8, width: 24, height: 16, opacity: 0.5, colorHexRgb: '000000')`;
   - sample center pixel;
   - expect alpha greater than 0.

5. `empty instructions do not throw`
   - keep current test.

### 11.3 MapGridPainter Test

Run:

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Only adjust test fixture constructors if the instruction API changes. The semantic assertion must remain:

```text
static shadow preview is painted below placed elements
```

Do not change `MapGridPainter` production render order.

## 12. Implementation Tasks

### Task 1: Extend Editor Preview Instruction Model

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- Test: `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

- [ ] Add `EditorStaticShadowPreviewShapeKind`.
- [ ] Add `EditorStaticShadowPreviewPoint`.
- [ ] Change `EditorStaticShadowPreviewInstruction.shape` from `ShadowCasterMode` to `EditorStaticShadowPreviewShapeKind`.
- [ ] Add `polygonPoints`.
- [ ] Add validation for finite point coordinates, finite bounds, positive size, opacity 0..1, hex color, and projected polygon non-degeneracy.
- [ ] Update equality/hashCode to include `shape` and `polygonPoints`.
- [ ] Add constructor-focused tests for equality/hashCode and invalid polygon points.

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Expected after Task 1 before builder migration:

```text
Some existing tests may fail because they still expect ShadowCasterMode. The new constructor tests should pass once call sites are updated.
```

### Task 2: Emit Projected Polygon Instructions From Builder

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- Test: `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

- [ ] Replace the old `applyEditorShadowLightPreviewPreset` rectangle path in `buildEditorStaticShadowPreviewInstructions`.
- [ ] Build `StaticShadowVisualMetrics` once per source.
- [ ] Keep `resolveStaticShadowGeometry`.
- [ ] Add `_projectionSpecForEditorLightPreview`.
- [ ] Add `_opacityForEditorLightPreview`.
- [ ] Call `resolveProjectedStaticShadowGeometry`.
- [ ] Convert core projection points to `EditorStaticShadowPreviewPoint`.
- [ ] Compute bounds from polygon points.
- [ ] Emit `EditorStaticShadowPreviewShapeKind.projectedPolygon`.
- [ ] Keep all existing filtering conditions unchanged.

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Expected:

```text
All builder tests pass after old ellipse rectangle expectations are replaced by projection-aware expectations.
```

### Task 3: Draw Projected Polygons In Editor Painter

**Files:**

- Modify: `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`
- Test: `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`

- [ ] Replace unconditional `canvas.drawOval` with a switch on `EditorStaticShadowPreviewShapeKind`.
- [ ] Keep `drawOval` for `oval`.
- [ ] Add `_pathFromEditorStaticShadowPreviewPoints`.
- [ ] Draw `projectedPolygon` with `canvas.drawPath`.
- [ ] Keep `isAntiAlias = false`.
- [ ] Keep color parsing and opacity clamping.
- [ ] Add projected polygon pixel tests.
- [ ] Keep oval fallback pixel test.

Run:

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Expected:

```text
All painter tests pass, with projected polygon and oval fallback both drawing visible pixels.
```

### Task 4: Verify Canvas Order Stays Stable

**Files:**

- Test: `packages/map_editor/test/map_grid_painter_test.dart`

- [ ] Run the existing MapGridPainter test.
- [ ] If it fails only because a test fixture constructs `EditorStaticShadowPreviewInstruction`, update the fixture to use `EditorStaticShadowPreviewShapeKind.projectedPolygon` with valid points.
- [ ] Do not change `MapGridPainter` production ordering.

Run:

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Expected:

```text
MapGridPainter tests pass and static shadow preview remains below placed elements.
```

### Task 5: Write Shadow-38 Implementation Report

**Files:**

- Create: `reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md`

The report must include:

- summary;
- design retained;
- created/modified/non-modified files;
- editor projected preview API;
- projection mapping;
- light preview mapping;
- painter `drawPath`;
- compatibility with runtime Shadow-37;
- why no runtime/core model/codec/panel/state was touched;
- tests and exact outputs;
- anti-drift scan results;
- initial and final git status;
- complete contents of every text/code file created or modified by Shadow-38, excluding recursive copy of the report itself;
- self-review.

### Task 6: Run Targeted Verification

Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/ui/canvas
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/canvas/shadow test/application/shadow test/ui/canvas test/map_grid_painter_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib test/shadow
```

Expected:

```text
All targeted editor shadow tests pass.
MapGridPainter test passes.
map_core static shadow geometry/projection tests pass.
Targeted analyze passes or reports only documented pre-existing debt.
```

### Task 7: Run Anti-Drift Scans

Run from repo root:

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/panels|packages/map_editor/lib/src/features/editor/state"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected:

```text
No runtime/gameplay/battle diff.
No core model/codec diff.
No editor panel/state diff.
No advanced renderer/global-light drift.
No map_runtime import in map_editor.
git diff --check reports no whitespace errors.
```

`drawPath` is intentionally allowed only in:

```text
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Do not use a broad anti-drift scan that treats this expected `drawPath` as a failure.

## 13. Non-Goals

Shadow-38 must not:

- modify `map_runtime`;
- modify `map_core` models or codecs;
- introduce `ShadowCasterMode.projectedPolygon`;
- introduce a persistent global light or time-of-day model;
- add automatic footprint authoring;
- add Shadow Studio;
- modify editor panels or state;
- change MapGridPainter render order;
- add blur, `saveLayer`, `ImageFilter`, sprite shadows, shadow atlases, `zOrder`, or `zIndex`.

## 14. Risks And Mitigations

Risk: the editor `neutral` light preview no longer matches the old Shadow-24 ellipse rectangle.

Mitigation: this is intentional because runtime static shadows are now projected after Shadow-37. The new neutral preview should match runtime default projection, not the old oval.

Risk: existing tests construct `EditorStaticShadowPreviewInstruction` with `const`.

Mitigation: update those tests to non-const constructors if validation is added, mirroring runtime `ShadowRuntimeRenderInstruction`.

Risk: `EditorShadowLightPreviewPreset` was designed for rectangle transforms.

Mitigation: keep the existing preset data and map it into `StaticShadowProjectionSpec` locally. Do not delete or rewrite the light preview helper in Shadow-38.

Risk: projected polygon painter pixel tests can be flaky if sampled near edges.

Mitigation: use a simple convex quadrilateral fixture and sample a pixel well inside the polygon.

## 15. Self-Review Checklist

- [ ] The plan keeps Shadow-38 editor-only.
- [ ] The plan avoids `map_runtime` imports in `map_editor`.
- [ ] The plan uses `resolveProjectedStaticShadowGeometry`.
- [ ] The plan preserves existing builder filters.
- [ ] The plan preserves editor canvas render order.
- [ ] The plan keeps `drawOval` fallback and adds `drawPath` only in the editor shadow preview painter.
- [ ] The plan does not create a persistent global light model.
- [ ] The plan does not modify persistent models or JSON codecs.
- [ ] The plan includes focused tests for builder, painter, and MapGridPainter ordering.
- [ ] The plan includes anti-drift scans and exact verification commands.

## 16. Expected Result

After Shadow-38 is implemented:

- runtime static shadows and editor static shadow preview use the same projected shadow geometry family;
- static object shadows stop appearing as editor-only oval galettes;
- editor preview can still show neutral/noon/morning/evening/soft-night variations without persisting a world light;
- actor contact shadows remain outside this editor static preview path;
- no runtime, core model, core codec, panel, or state file changes are required.
