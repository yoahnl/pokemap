# Shadow-45 Static Shadow Family Projection Core Recovery V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Repository rule wins over generic plan guidance: do not commit unless the user explicitly asks after implementation.

**Goal:** Add the missing pure `map_core` family projection resolver so `StaticShadowFamily` can finally produce distinct Pokemon-like projected shadow shapes for generic props, compact props, tall props, buildings, and foliage.

**Architecture:** Shadow-45 is a recovery and unblocker lot. It intentionally implements the Shadow-42-shaped core API that Shadow-43 and Shadow-44 already expect, without touching runtime, editor canvas, UI, JSON codecs, generated files, or Flame components. Runtime/editor integration remains delegated to Shadow-43, and visual contracts remain delegated to Shadow-44.

**Tech Stack:** Pure Dart `map_core`, existing `StaticShadowFamily`, existing `StaticShadowProjectionSpec`, existing projected static shadow geometry tests. No Flutter, no Flame, no renderer, no build_runner.

---

## 1. Why Shadow-45 Exists

The current Shadow chain has a gap:

```text
Shadow-41 added StaticShadowFamily.
Shadow-43 plan expects resolveStaticShadowFamily(...) and resolveStaticShadowFamilyProjectionSpec(...).
Shadow-44 plan expects the same APIs for visual contracts.
But packages/map_core/lib/src/operations/static_shadow_family_projection.dart does not exist.
```

This makes Shadow-43 and Shadow-44 impossible to implement honestly.

Shadow-45 should fix that missing core seam without pretending to solve runtime/editor visuals in the same lot.

## 2. Current Audit Evidence

Observed while writing this plan:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart absent
packages/map_core/test/shadow/static_shadow_family_projection_test.dart absent
resolveStaticShadowFamily(...) absent from packages/map_core/lib
resolveStaticShadowFamilyProjectionSpec(...) absent from packages/map_core/lib
```

Existing relevant code:

```text
packages/map_core/lib/src/models/shadow.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
reports/shadows/shadow_lot_43_static_shadow_family_runtime_editor_integration_plan.md
reports/shadows/shadow_lot_44_static_shadow_visual_calibration_contract_plan.md
```

`flame_docs` was checked because future Shadow-43/visual work may touch runtime rendering:

```text
mcp__flame_docs__.search_documentation("Flame Component render Canvas render order priority PositionComponent children")
-> No results found.
mcp__flame_docs__.search_documentation("priority render order components")
-> No results found.
```

Shadow-45 itself is pure `map_core`, so it does not need Flame APIs.

## 3. Current Dirty Worktree To Preserve

At plan creation time, the worktree contains unrelated changes:

```text
 M AGENTS.md
 M examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
 M examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

Shadow-45 must not edit, stage, rewrite, or clean those files.

## 4. Scope

Allowed changes:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/test/shadow/static_shadow_family_projection_test.dart
packages/map_core/lib/map_core.dart
reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery.md
```

Forbidden changes:

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_family_json_codec.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/playable_runtime_host/**
*.g.dart
*.freezed.dart
```

No new:

```text
persistent model
JSON field
runtime integration
editor integration
UI control
Shadow Studio
WorldLightState
time-of-day persistent model
LightDirection persistent model
blur
saveLayer
ImageFilter
shadow sprite
shadow atlas
Flame component
build_runner
generated file
```

## 5. API To Add

Create:

```text
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
```

Public API:

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

Export it from:

```text
packages/map_core/lib/map_core.dart
```

## 6. Merge Rule

Family resolution is intentionally simple:

```text
overrideFamily ?? elementFamily ?? StaticShadowFamily.genericProjection
```

Why:

- source element family is the default object strategy;
- placed instance override wins only when explicitly custom;
- missing family keeps the existing generic projection behavior;
- this mirrors future runtime/editor merge expectations in Shadow-43.

## 7. Projection Spec Rule

`resolveStaticShadowFamilyProjectionSpec(...)` must preserve the caller's base direction and tune only family-specific projection length and width multipliers.

This is important because editor light preview may already provide a temporary direction:

```text
baseProjectionSpec.directionX is preserved
baseProjectionSpec.directionY is preserved
family resolver changes lengthRatio / nearWidthMultiplier / farWidthMultiplier
```

No global light model is created.

## 8. V0 Family Constants

Use conservative V0 values. These are not final art direction; they are the first measurable differentiation layer.

```text
genericProjection:
  return baseProjectionSpec unchanged

compactProp:
  lengthRatio = base.lengthRatio * 0.72
  nearWidthMultiplier = base.nearWidthMultiplier * 0.82
  farWidthMultiplier = base.farWidthMultiplier * 0.78

tallProp:
  lengthRatio = base.lengthRatio * 1.18
  nearWidthMultiplier = base.nearWidthMultiplier * 0.52
  farWidthMultiplier = base.farWidthMultiplier * 0.58

building:
  lengthRatio = base.lengthRatio * 1.25
  nearWidthMultiplier = base.nearWidthMultiplier * 1.05
  farWidthMultiplier = base.farWidthMultiplier * 0.98

foliage:
  lengthRatio = base.lengthRatio * 1.05
  nearWidthMultiplier = base.nearWidthMultiplier * 1.15
  farWidthMultiplier = base.farWidthMultiplier * 1.28
```

Rationale:

- `compactProp` becomes shorter and tighter.
- `tallProp` can cast a readable shadow without becoming wide.
- `building` becomes broad and blockier, closer to Pokemon building shadows.
- `foliage` remains wider and more organic than tall prop.
- `genericProjection` preserves exact current behavior.

If these constants are too weak or too strong, Shadow-44 visual contracts should tune them later.

## 9. Task 1: Add Failing Core Tests

**Files:**

- Create: `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`
- Read: `packages/map_core/lib/src/models/shadow.dart`
- Read: `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`

- [ ] **Step 1: Create the test file**

Add:

```dart
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveStaticShadowFamily', () {
    test('uses generic projection when no family is provided', () {
      expect(
        resolveStaticShadowFamily(),
        StaticShadowFamily.genericProjection,
      );
    });

    test('uses element family when no override family is provided', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
        ),
        StaticShadowFamily.building,
      );
    });

    test('uses override family over element family', () {
      expect(
        resolveStaticShadowFamily(
          elementFamily: StaticShadowFamily.building,
          overrideFamily: StaticShadowFamily.tallProp,
        ),
        StaticShadowFamily.tallProp,
      );
    });
  });

  group('resolveStaticShadowFamilyProjectionSpec', () {
    test('genericProjection returns the base projection unchanged', () {
      final base = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.4,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );

      expect(
        resolveStaticShadowFamilyProjectionSpec(
          family: StaticShadowFamily.genericProjection,
          baseProjectionSpec: base,
        ),
        base,
      );
    });

    test('preserves base direction for every non-generic family', () {
      final base = StaticShadowProjectionSpec(
        directionX: -0.75,
        directionY: 0.35,
        lengthRatio: 0.32,
        nearWidthMultiplier: 0.92,
        farWidthMultiplier: 1.18,
      );

      for (final family in <StaticShadowFamily>[
        StaticShadowFamily.compactProp,
        StaticShadowFamily.tallProp,
        StaticShadowFamily.building,
        StaticShadowFamily.foliage,
      ]) {
        final spec = resolveStaticShadowFamilyProjectionSpec(
          family: family,
          baseProjectionSpec: base,
        );

        expect(spec.directionX, base.directionX);
        expect(spec.directionY, base.directionY);
      }
    });

    test('compact props are shorter and tighter than generic projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(
        spec.lengthRatio,
        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('tall props are narrow and still project farther than generic', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(
        spec.lengthRatio,
        greaterThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('buildings keep a broad block-like projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );

      expect(
        spec.lengthRatio,
        greaterThan(defaultStaticShadowProjectionSpec.lengthRatio),
      );
      expect(
        spec.nearWidthMultiplier,
        greaterThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
      );
      expect(
        spec.farWidthMultiplier,
        lessThan(defaultStaticShadowProjectionSpec.farWidthMultiplier),
      );
    });

    test('foliage is broader than tall prop', () {
      final foliage = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );
      final tallProp = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(foliage.nearWidthMultiplier, greaterThan(tallProp.nearWidthMultiplier));
      expect(foliage.farWidthMultiplier, greaterThan(tallProp.farWidthMultiplier));
    });
  });

  group('family projection geometry composition', () {
    test('tall prop polygon stays much narrower than building polygon', () {
      final tall = _projectedCase(
        family: StaticShadowFamily.tallProp,
        visualWidth: 16,
        visualHeight: 64,
        footprintWidthRatio: 0.18,
        footprintHeightRatio: 0.07,
      );
      final building = _projectedCase(
        family: StaticShadowFamily.building,
        visualWidth: 96,
        visualHeight: 80,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      );

      expect(_maxWidth(tall), lessThan(_maxWidth(building) * 0.45));
      expect(_polygonArea(tall), lessThan(_polygonArea(building) * 0.45));
    });

    test('compact prop projects less area than generic for same metrics', () {
      final compact = _projectedCase(
        family: StaticShadowFamily.compactProp,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );
      final generic = _projectedCase(
        family: StaticShadowFamily.genericProjection,
        visualWidth: 72,
        visualHeight: 48,
        footprintWidthRatio: 0.72,
        footprintHeightRatio: 0.10,
      );

      expect(_polygonArea(compact), lessThan(_polygonArea(generic)));
    });
  });
}

ProjectedStaticShadowGeometry _projectedCase({
  required StaticShadowFamily family,
  required double visualWidth,
  required double visualHeight,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: 0,
      offsetY: 0,
      scaleX: 1,
      scaleY: 1,
      opacity: 0.3,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      footprintWidthRatio: footprintWidthRatio,
      footprintHeightRatio: footprintHeightRatio,
    ),
  );

  return resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(family: family),
  );
}

double _maxWidth(ProjectedStaticShadowGeometry geometry) {
  return [
    _distance(geometry.nearLeft, geometry.nearRight),
    _distance(geometry.farLeft, geometry.farRight),
  ].reduce((first, second) => first > second ? first : second);
}

double _distance(ProjectedStaticShadowPoint first, ProjectedStaticShadowPoint second) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _polygonArea(ProjectedStaticShadowGeometry geometry) {
  final points = geometry.points;
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Expected result:

```text
Compilation fails because resolveStaticShadowFamily and
resolveStaticShadowFamilyProjectionSpec are not defined.
```

Do not implement before this expected RED has been observed.

## 10. Task 2: Implement Static Shadow Family Projection Core

**Files:**

- Create: `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Test: `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

- [ ] **Step 1: Create the core operation file**

Add:

```dart
import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return overrideFamily ?? elementFamily ?? StaticShadowFamily.genericProjection;
}

StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
  required StaticShadowFamily family,
  StaticShadowProjectionSpec baseProjectionSpec =
      defaultStaticShadowProjectionSpec,
}) {
  switch (family) {
    case StaticShadowFamily.genericProjection:
      return baseProjectionSpec;
    case StaticShadowFamily.compactProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.72,
        nearWidthMultiplierScale: 0.82,
        farWidthMultiplierScale: 0.78,
      );
    case StaticShadowFamily.tallProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.18,
        nearWidthMultiplierScale: 0.52,
        farWidthMultiplierScale: 0.58,
      );
    case StaticShadowFamily.building:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.25,
        nearWidthMultiplierScale: 1.05,
        farWidthMultiplierScale: 0.98,
      );
    case StaticShadowFamily.foliage:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 1.05,
        nearWidthMultiplierScale: 1.15,
        farWidthMultiplierScale: 1.28,
      );
  }
}

StaticShadowProjectionSpec _scaledProjectionSpec(
  StaticShadowProjectionSpec baseProjectionSpec, {
  required double lengthRatioScale,
  required double nearWidthMultiplierScale,
  required double farWidthMultiplierScale,
}) {
  return StaticShadowProjectionSpec(
    directionX: baseProjectionSpec.directionX,
    directionY: baseProjectionSpec.directionY,
    lengthRatio: baseProjectionSpec.lengthRatio * lengthRatioScale,
    nearWidthMultiplier:
        baseProjectionSpec.nearWidthMultiplier * nearWidthMultiplierScale,
    farWidthMultiplier:
        baseProjectionSpec.farWidthMultiplier * farWidthMultiplierScale,
  );
}
```

- [ ] **Step 2: Export the operation**

In `packages/map_core/lib/map_core.dart`, add the export next to the other shadow operations:

```dart
export 'src/operations/static_shadow_family_projection.dart';
```

- [ ] **Step 3: Run focused test**

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Expected result:

```text
+...: All tests passed!
```

If the geometry contract thresholds are too strict, do not weaken them blindly. Inspect the computed widths/areas and adjust the family constants only if the artistic intent remains intact.

## 11. Task 3: Add Full Core Regression Coverage

**Files:**

- Modify: `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

- [ ] **Step 1: Add exact value tests for V0 constants**

Add tests:

```dart
test('compactProp V0 constants are stable', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.compactProp,
  );

  expect(spec.lengthRatio, closeTo(0.2304, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.7544, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(0.9204, 0.0000001));
});

test('tallProp V0 constants are stable', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.tallProp,
  );

  expect(spec.lengthRatio, closeTo(0.3776, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.4784, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(0.6844, 0.0000001));
});

test('building V0 constants are stable', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.building,
  );

  expect(spec.lengthRatio, closeTo(0.4, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(0.966, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(1.1564, 0.0000001));
});

test('foliage V0 constants are stable', () {
  final spec = resolveStaticShadowFamilyProjectionSpec(
    family: StaticShadowFamily.foliage,
  );

  expect(spec.lengthRatio, closeTo(0.336, 0.0000001));
  expect(spec.nearWidthMultiplier, closeTo(1.058, 0.0000001));
  expect(spec.farWidthMultiplier, closeTo(1.5104, 0.0000001));
});
```

- [ ] **Step 2: Add validation transit test**

Add:

```dart
test('scaled family specs remain valid for a custom positive base', () {
  final base = StaticShadowProjectionSpec(
    directionX: 1,
    directionY: 0.45,
    lengthRatio: 0.1,
    nearWidthMultiplier: 0.2,
    farWidthMultiplier: 0.3,
  );

  for (final family in StaticShadowFamily.values) {
    final spec = resolveStaticShadowFamilyProjectionSpec(
      family: family,
      baseProjectionSpec: base,
    );

    expect(spec.directionX, isFinite);
    expect(spec.directionY, isFinite);
    expect(spec.lengthRatio, greaterThan(0));
    expect(spec.nearWidthMultiplier, greaterThan(0));
    expect(spec.farWidthMultiplier, greaterThan(0));
  }
});
```

- [ ] **Step 3: Run focused test again**

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Expected result:

```text
+...: All tests passed!
```

## 12. Task 4: Broaden map_core Verification

**Files:**

- No new files.

- [ ] **Step 1: Format touched Dart files**

Run:

```bash
cd packages/map_core && dart format lib/src/operations/static_shadow_family_projection.dart test/shadow/static_shadow_family_projection_test.dart lib/map_core.dart
```

Expected:

```text
Formatted ...
```

or:

```text
Changed ...
```

- [ ] **Step 2: Run shadow tests**

Run:

```bash
cd packages/map_core && dart test test/shadow
```

Expected:

```text
+...: All tests passed!
```

- [ ] **Step 3: Run targeted analyze**

Run:

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Expected:

```text
No issues found!
```

- [ ] **Step 4: Run full map_core tests if time allows**

Run:

```bash
cd packages/map_core && dart test
```

Expected:

```text
+...: All tests passed!
```

If full map_core fails from pre-existing unrelated tests, capture the full useful failure and document whether Shadow-45 touched that area.

## 13. Task 5: Anti-Drift Checks

**Files:**

- No new files.

- [ ] **Step 1: Check forbidden package diffs**

Run:

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle|examples/playable_runtime_host"
```

Expected for Shadow-45-owned changes:

```text
aucune sortie Shadow-45
```

If the command prints pre-existing dirty files, report them separately and do not attribute them to Shadow-45.

- [ ] **Step 2: Check forbidden model/codec/generated diffs**

Run:

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_family_json_codec|\\.g\\.dart|\\.freezed\\.dart"
```

Expected:

```text
aucune sortie
```

- [ ] **Step 3: Check forbidden renderer/global-light concepts**

Run:

```bash
git diff -U0 -- packages/map_core \
  | rg -n "Canvas|Flame|drawOval|drawPath|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Expected:

```text
aucune sortie
```

- [ ] **Step 4: Check whitespace and final diff**

Run:

```bash
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Expected:

```text
Only Shadow-45 files plus pre-existing unrelated dirty files.
```

## 14. Task 6: Create Implementation Report

**Files:**

- Create: `reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery.md`

- [ ] **Step 1: Create the report with evidence**

The report must include:

```text
1. Resume du lot
2. Design retenu
3. Pourquoi Shadow-45 recupere la brique Shadow-42 manquante
4. Fichiers crees
5. Fichiers modifies
6. Fichiers non modifies explicitement
7. API ajoutee
8. Regle de merge family
9. Specs V0 par famille
10. Preservation de la direction de base
11. Pourquoi ce lot ne touche pas runtime/editor
12. Pourquoi ce lot ne cree pas de lumiere globale
13. Tests ajoutes
14. Commandes lancees
15. Resultats complets des tests cibles
16. Lignes finales exactes des tests globaux cibles
17. Resultats des scans anti-derive
18. git status initial
19. git status final
20. git diff --stat
21. Non-objectifs respectes
22. Risques / reserves
23. Auto-review finale
24. Regard critique sur le plan/prompt
25. Code complet des fichiers crees/modifies par Shadow-45
26. Diffs complets ou equivalents /dev/null pour fichiers crees
```

- [ ] **Step 2: Include the pre-existing dirty worktree**

The report must distinguish:

```text
fichiers deja modifies avant Shadow-45
fichiers non suivis preexistants hors lot
fichiers crees/modifies par Shadow-45
problemes introduits par Shadow-45
```

- [ ] **Step 3: Include the final summary**

Use:

```text
Shadow-45 termine.
API core StaticShadowFamily -> StaticShadowProjectionSpec ajoutee.
resolveStaticShadowFamily(...) ajoute.
resolveStaticShadowFamilyProjectionSpec(...) ajoute.
genericProjection conserve le comportement actuel.
compactProp / tallProp / building / foliage ont des specs differenciees.
Direction de base preservee.
Aucun runtime/editor modifie.
Aucun modele/codec JSON modifie.
Tests cibles : ...
map_core shadow : ...
Analyze : ...
Rapport : reports/shadows/shadow_lot_45_static_shadow_family_projection_core_recovery.md
Aucun commit effectue.
```

## 15. Auto-Review Checklist

Before finalizing implementation, answer:

```text
- Ai-je ajoute resolveStaticShadowFamily(...) ? oui.
- Ai-je ajoute resolveStaticShadowFamilyProjectionSpec(...) ? oui.
- Ai-je garde genericProjection identique au comportement actuel ? oui.
- Ai-je differencie compactProp / tallProp / building / foliage ? oui.
- Ai-je preserve directionX / directionY du baseProjectionSpec ? oui.
- Ai-je evite runtime/editor ? oui.
- Ai-je evite les modeles persistants ? oui.
- Ai-je evite les codecs JSON ? oui.
- Ai-je evite build_runner/generated files ? oui.
- Ai-je evite toute lumiere globale persistante ? oui.
- Ai-je documente que Shadow-43/44 restent necessaires pour voir le resultat ? oui.
```

## 16. Success Criteria

Shadow-45 succeeds if:

```text
- static_shadow_family_projection.dart exists;
- static_shadow_family_projection_test.dart exists;
- map_core exports the new operation;
- resolveStaticShadowFamily merges override -> element -> generic;
- resolveStaticShadowFamilyProjectionSpec returns stable V0 specs;
- genericProjection preserves current default projection;
- non-generic families preserve base direction;
- compact/tall/building/foliage produce measurable differences;
- no runtime/editor code changes are introduced by Shadow-45;
- no persistent model or JSON codec changes are introduced;
- no generated files are introduced;
- focused tests pass;
- test/shadow passes;
- analyze passes or pre-existing debt is documented;
- complete evidence report exists;
- no commit is performed unless the user explicitly asks.
```

## 17. Roadmap After Shadow-45

Shadow-45 unblocks the already planned work:

```text
Shadow-43 — Runtime + Editor Static Shadow Family Integration V0
Shadow-44 — Static Shadow Visual Calibration Contract V0
Shadow-46 — Automatic Shadow Fallback / Runtime Editor No-Manual-Click V0
Shadow-47 — Selbrume Visual Fixture Backfill / QA Slice V0
```

Important: Shadow-45 alone will not make screenshots beautiful. It only creates the missing core family resolver. The visual change arrives when runtime/editor consume this resolver and when automatic fallback/backfill applies it to real project data.

## 18. Plan Self-Review

Spec coverage:

```text
Covered: missing dependency, core API, merge rule, projection specs, tests, anti-drift, report, future roadmap.
```

Placeholder scan:

```text
No placeholder markers. Implementation values and commands are explicit.
```

Type consistency:

```text
Uses StaticShadowFamily from map_core models.
Uses StaticShadowProjectionSpec from existing static_shadow_projection_geometry.dart.
Uses resolveProjectedStaticShadowGeometry only in tests for measurable geometry composition.
No runtime/editor types are referenced.
```
