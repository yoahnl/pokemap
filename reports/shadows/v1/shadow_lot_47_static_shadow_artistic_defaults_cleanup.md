# Shadow-47 — Static Shadow Artistic Defaults / Auto Cleanup V0

## 1. Résumé du lot

Shadow-47 réduit les ombres automatiques qui rendaient la carte illisible : les petits éléments ne reçoivent plus d’ombre automatique, les projections des familles statiques sont raccourcies, et le backfill retire les anciennes ombres auto reconnues quand la nouvelle politique ne propose plus rien.

## 2. Design retenu

- Auto-suggestion conservée pour `tallThin`, `buildingLarge`, et `wideLow` seulement si la surface est suffisante.
- `smallSquare` et `defaultProp` ne produisent plus de configuration automatique.
- Les familles `compactProp`, `tallProp`, `building`, `foliage` restent dans le modèle existant mais deviennent nettement plus sobres.
- Le backfill distingue maintenant `applied*`, `skipped*` et `clearedAutoNoSuggestion`.
- Le nettoyage ne touche que `ProjectElementShadowConfig`, pas les overrides d’instance.

## 3. Fichiers créés par Shadow-47

- `reports/shadows/shadow_lot_47_static_shadow_artistic_defaults_cleanup.md`

## 4. Fichiers modifiés par Shadow-47

- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`
- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`
- `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`


## 5. Fichiers déjà présents/modifiés avant Shadow-47 ou hors lot

Ces fichiers apparaissent dans le statut final mais ne font pas partie des modifications Shadow-47 :

```text
M packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart
 M packages/map_battle/lib/src/data/psdk_attack_coverage_report.dart
 M packages/map_battle/lib/src/data/psdk_parity_gate.dart
 M packages/map_battle/lib/src/domain/move/behaviors/drain_move_behavior.dart
 M packages/map_battle/test/psdk_attack_coverage_report_test.dart
 M packages/map_battle/test/psdk_move_families/drain_heal_and_power_test.dart
 M packages/map_battle/test/psdk_parity_gate_test.dart
 M packages/map_battle/test/psdk_registry_manifest_test.dart
 M packages/map_battle/tool/extract_psdk_move_registry.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
 M packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery.md
?? reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery_plan.md
?? reports/shadows/shadow_lot_47_static_shadow_artistic_defaults_cleanup_plan.md
```

## 6. Politique auto-suggestion

- `2x2` et `2x3` retournent maintenant `null`.
- `3x2` retourne `null` malgré sa forme large basse, car la surface est trop petite.
- `4x2` reste éligible comme `wideLow`.
- Les éléments hauts fins et les grands bâtiments restent éligibles.

## 7. Projection artistique

Les ratios de projection statique ont été calmés :

```text
compactProp: length 0.1216, near 0.5336, far 0.5192
tallProp: length 0.1536, near 0.2944, far 0.3304
building: length 0.1984, near 0.7176, far 0.7316
foliage: length 0.144, near 0.6624, far 0.826
```

## 8. Nettoyage des anciennes ombres auto

Le backfill peut maintenant produire `clearedAutoNoSuggestion`. Ce statut retire une ancienne ombre automatique reconnue lorsque la nouvelle politique ne propose plus de shadow config. Les configurations manuelles restent préservées.

## 9. Tests ajoutés/modifiés

- Tests auto-suggestion pour `smallSquare`, `defaultProp`, `wideLow` avec surface minimale.
- Tests backfill pour nettoyer les anciennes autos `smallSquare`, `defaultProp`, `wideLow`.
- Test use case pour vérifier que le projet est sauvegardé quand un nettoyage retire une shadow config.
- Tests projection core avec constantes stables plus sobres.

## 10. Commandes lancées

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow test/features/tileset_library
cd packages/map_core && dart analyze lib test/shadow
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 11. Résultats complets utiles des tests ciblés

```text
element_auto_shadow_suggestion_test.dart: 00:00 +16: All tests passed!
element_auto_shadow_backfill_test.dart: 00:00 +13: All tests passed!
apply_element_auto_shadow_suggestions_use_case_test.dart: 00:00 +4: All tests passed!
static_shadow_family_projection_test.dart: All tests passed!
```

## 12. Résultats des tests globaux ciblés

```text
cd packages/map_editor && flutter test test/application/shadow
00:00 +94: All tests passed!

cd packages/map_editor && flutter test test/features/tileset_library
00:03 +49: All tests passed!

cd packages/map_core && dart test test/shadow
00:00 +255: All tests passed!
```

## 13. Analyse

```text
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow test/features/tileset_library
Analyzing 3 items...
No issues found!

cd packages/map_core && dart analyze lib test/shadow
Analyzing lib, shadow...
No issues found!
```

## 14. Scans anti-dérive

```text
git diff --check
(no output)

Diff core models/codecs/generated: no output
Diff renderer avancé: no output
Diff runtime/gameplay/battle/examples: sorties détectées uniquement sur fichiers préexistants hors Shadow-47 listés en section 5.
```

## 15. git status final

```text
M packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart
 M packages/map_battle/lib/src/data/psdk_attack_coverage_report.dart
 M packages/map_battle/lib/src/data/psdk_parity_gate.dart
 M packages/map_battle/lib/src/domain/move/behaviors/drain_move_behavior.dart
 M packages/map_battle/test/psdk_attack_coverage_report_test.dart
 M packages/map_battle/test/psdk_move_families/drain_heal_and_power_test.dart
 M packages/map_battle/test/psdk_parity_gate_test.dart
 M packages/map_battle/test/psdk_registry_manifest_test.dart
 M packages/map_battle/tool/extract_psdk_move_registry.dart
 M packages/map_core/lib/src/operations/static_shadow_family_projection.dart
 M packages/map_core/test/shadow/static_shadow_family_projection_test.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
 M packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
 M packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
 M packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery.md
?? reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery_plan.md
?? reports/shadows/shadow_lot_47_static_shadow_artistic_defaults_cleanup.md
?? reports/shadows/shadow_lot_47_static_shadow_artistic_defaults_cleanup_plan.md
```

## 16. git diff --stat final

```text
.../generated/psdk_move_registry_manifest.dart     |   2 +-
 .../lib/src/data/psdk_attack_coverage_report.dart  |  33 ++
 .../map_battle/lib/src/data/psdk_parity_gate.dart  |   4 +-
 .../domain/move/behaviors/drain_move_behavior.dart |  68 ++-
 .../test/psdk_attack_coverage_report_test.dart     |  62 +++
 .../drain_heal_and_power_test.dart                 |  86 +++-
 .../map_battle/test/psdk_parity_gate_test.dart     |   4 +-
 .../test/psdk_registry_manifest_test.dart          |   2 +-
 .../tool/extract_psdk_move_registry.dart           |   9 +-
 .../static_shadow_family_projection.dart           |  24 +-
 .../static_shadow_family_projection_test.dart      |  41 +-
 .../shadow/editor_static_shadow_preview.dart       | 291 +++++++++++--
 .../shadow/element_auto_shadow_backfill.dart       | 132 +++++-
 .../shadow/element_auto_shadow_suggestion.dart     |  46 +-
 .../editor_static_shadow_preview_painter.dart      |  54 ++-
 .../shadow/editor_static_shadow_preview_test.dart  | 467 ++++++++++++++++++---
 .../shadow/element_auto_shadow_backfill_test.dart  | 177 +++++++-
 .../element_auto_shadow_suggestion_test.dart       |  64 +--
 ...ment_auto_shadow_suggestions_use_case_test.dart |  50 +++
 .../editor_static_shadow_preview_painter_test.dart |  69 ++-
 ...me_static_placed_element_shadow_collection.dart |   2 +
 ...tic_placed_element_shadow_runtime_resolver.dart |  16 +-
 ...atic_placed_element_shadow_collection_test.dart |  70 +++
 ...laced_element_shadow_runtime_resolver_test.dart |  79 ++++
 24 files changed, 1616 insertions(+), 236 deletions(-)
```

## 17. git diff --name-status final

```text
M	packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart
M	packages/map_battle/lib/src/data/psdk_attack_coverage_report.dart
M	packages/map_battle/lib/src/data/psdk_parity_gate.dart
M	packages/map_battle/lib/src/domain/move/behaviors/drain_move_behavior.dart
M	packages/map_battle/test/psdk_attack_coverage_report_test.dart
M	packages/map_battle/test/psdk_move_families/drain_heal_and_power_test.dart
M	packages/map_battle/test/psdk_parity_gate_test.dart
M	packages/map_battle/test/psdk_registry_manifest_test.dart
M	packages/map_battle/tool/extract_psdk_move_registry.dart
M	packages/map_core/lib/src/operations/static_shadow_family_projection.dart
M	packages/map_core/test/shadow/static_shadow_family_projection_test.dart
M	packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
M	packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
M	packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
M	packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
M	packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
M	packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
M	packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
M	packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
M	packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
M	packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
M	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
M	packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

## 18. Non-objectifs respectés

- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun fichier generated modifié par Shadow-47. Les fichiers generated visibles au statut sont hors lot.
- Aucun `build_runner`.
- Aucun nouveau renderer.
- Aucune lumière globale.
- Aucun commit effectué.

## 19. Risques / réserves

Ce lot améliore fortement le défaut automatique, mais ne remplace pas encore la nécessité d’une vraie passe visuelle sur les assets existants persistés dans les fixtures si ces fixtures contiennent déjà des ombres manuelles ou non reconnues. Les ombres manuelles sont volontairement conservées.

## 20. Auto-review finale

- Ai-je réduit les auto-suggestions des petits éléments ? oui.
- Ai-je conservé les cas structurants utiles ? oui.
- Ai-je raccourci les familles de projection ? oui.
- Ai-je nettoyé les anciennes ombres auto reconnues ? oui.
- Ai-je préservé les ombres manuelles ? oui.
- Ai-je évité runtime/gameplay/battle dans Shadow-47 ? oui pour les changements du lot. Les fichiers runtime/battle visibles au statut sont hors lot.
- Ai-je évité modèles persistants/codecs/generated ? oui pour Shadow-47.
- Ai-je évité toute lumière globale ? oui.

## 21. Regard critique sur le plan

Le plan était correct sur le fond : tant que l’auto-backfill continue à poser des ombres sur chaque petit décor, les améliorations de géométrie produisent seulement des losanges plus sophistiqués, pas un rendu Pokémon acceptable. La seule nuance découverte en implémentation est l’ordre de classification : `4x2` devait rester `wideLow`, tandis que `4x3` devait rester `buildingLarge`.

## 22. Code complet des fichiers créés/modifiés par Shadow-47


### `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`

```dart
import '../models/shadow.dart';
import 'static_shadow_projection_geometry.dart';

StaticShadowFamily resolveStaticShadowFamily({
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return overrideFamily ??
      elementFamily ??
      StaticShadowFamily.genericProjection;
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
        lengthRatioScale: 0.38,
        nearWidthMultiplierScale: 0.58,
        farWidthMultiplierScale: 0.44,
      );
    case StaticShadowFamily.tallProp:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.48,
        nearWidthMultiplierScale: 0.32,
        farWidthMultiplierScale: 0.28,
      );
    case StaticShadowFamily.building:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.62,
        nearWidthMultiplierScale: 0.78,
        farWidthMultiplierScale: 0.62,
      );
    case StaticShadowFamily.foliage:
      return _scaledProjectionSpec(
        baseProjectionSpec,
        lengthRatioScale: 0.45,
        nearWidthMultiplierScale: 0.72,
        farWidthMultiplierScale: 0.70,
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


### `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`

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

    test('tall props are narrow and shorter than generic', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
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

    test('buildings keep a broad but shorter block-like projection', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );
      final tall = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
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
        spec.nearWidthMultiplier,
        greaterThan(tall.nearWidthMultiplier),
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

      expect(
        foliage.nearWidthMultiplier,
        greaterThan(tallProp.nearWidthMultiplier),
      );
      expect(
        foliage.farWidthMultiplier,
        greaterThan(tallProp.farWidthMultiplier),
      );
    });

    test('compactProp V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.compactProp,
      );

      expect(spec.lengthRatio, closeTo(0.1216, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.5336, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.5192, 0.0000001));
    });

    test('tallProp V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.tallProp,
      );

      expect(spec.lengthRatio, closeTo(0.1536, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.2944, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.3304, 0.0000001));
    });

    test('building V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.building,
      );

      expect(spec.lengthRatio, closeTo(0.1984, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.7176, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.7316, 0.0000001));
    });

    test('foliage V0 constants are stable', () {
      final spec = resolveStaticShadowFamilyProjectionSpec(
        family: StaticShadowFamily.foliage,
      );

      expect(spec.lengthRatio, closeTo(0.144, 0.0000001));
      expect(spec.nearWidthMultiplier, closeTo(0.6624, 0.0000001));
      expect(spec.farWidthMultiplier, closeTo(0.826, 0.0000001));
    });

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

        expect(spec.directionX.isFinite, isTrue);
        expect(spec.directionY.isFinite, isTrue);
        expect(spec.lengthRatio, greaterThan(0));
        expect(spec.nearWidthMultiplier, greaterThan(0));
        expect(spec.farWidthMultiplier, greaterThan(0));
      }
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
      shadowProfileId: 'default-ground-soft-ellipse',
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

double _distance(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
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


### `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`

```dart
import 'package:map_core/map_core.dart';

enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

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

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
}) {
  if (element.frames.isEmpty) {
    return null;
  }
  final source = element.frames.first.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }
  final width = source.width.toDouble();
  final height = source.height.toDouble();
  if (_isMicroDecor(
    width: width,
    height: height,
  )) {
    return null;
  }
  final kind = _classifyElement(
    width: width,
    height: height,
  );
  if (!_autoShadowKindIsArtisticallySafe(
    kind,
    width: width,
    height: height,
  )) {
    return null;
  }
  final profile = _profileForKind(shadowCatalog, kind);
  if (profile == null) {
    return null;
  }
  return ElementAutoShadowSuggestion(
    kind: kind,
    config: _configForKind(kind, profile.id),
    summary: _summaryForKind(kind),
  );
}

bool _isMicroDecor({
  required double width,
  required double height,
}) {
  return width <= 1 && height <= 2;
}

ElementAutoShadowSuggestionKind _classifyElement({
  required double width,
  required double height,
}) {
  final area = width * height;
  final aspect = height / width;
  if (aspect >= 2.2 && width <= 2) {
    return ElementAutoShadowSuggestionKind.tallThin;
  }
  if (width >= 3 && height <= 2) {
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

bool _autoShadowKindIsArtisticallySafe(
  ElementAutoShadowSuggestionKind kind, {
  required double width,
  required double height,
}) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return true;
    case ElementAutoShadowSuggestionKind.wideLow:
      return width >= 4 || width * height >= 10;
    case ElementAutoShadowSuggestionKind.smallSquare:
    case ElementAutoShadowSuggestionKind.defaultProp:
      return false;
  }
}

ProjectShadowProfile? _profileForKind(
  ProjectShadowCatalog catalog,
  ElementAutoShadowSuggestionKind kind,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.smallSquare:
      return _preferredCompactProfile(catalog);
    case ElementAutoShadowSuggestionKind.buildingLarge:
    case ElementAutoShadowSuggestionKind.wideLow:
      return _preferredWideProfile(catalog);
    case ElementAutoShadowSuggestionKind.defaultProp:
      return _preferredSoftProfile(catalog);
  }
}

ProjectShadowProfile? _preferredCompactProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-contact-blob') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.contactBlob) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredWideProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-wide-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredSoftProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-soft-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _compatibleProfileById(
  ProjectShadowCatalog catalog,
  String id,
) {
  final profile = catalog.profileById(id);
  if (profile == null || !isGroundStaticElementShadowProfile(profile)) {
    return null;
  }
  return profile;
}

ProjectShadowProfile? _firstCompatibleProfileWithMode(
  ProjectShadowCatalog catalog,
  ShadowCasterMode mode,
) {
  for (final profile in catalog.profiles) {
    if (profile.mode == mode && isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectShadowProfile? _firstCompatibleProfile(ProjectShadowCatalog catalog) {
  for (final profile in catalog.profiles) {
    if (isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectElementShadowConfig _configForKind(
  ElementAutoShadowSuggestionKind kind,
  String profileId,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 1,
        scaleY: 1,
        opacity: 0.28,
        family: StaticShadowFamily.tallProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1.0,
          footprintWidthRatio: 0.18,
          footprintHeightRatio: 0.07,
        ),
      );
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 1,
        scaleY: 0.85,
        opacity: 0.30,
        family: StaticShadowFamily.building,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.82,
          footprintHeightRatio: 0.12,
        ),
      );
    case ElementAutoShadowSuggestionKind.wideLow:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.92,
        scaleY: 0.75,
        opacity: 0.27,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.72,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.smallSquare:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.78,
        scaleY: 0.70,
        opacity: 0.26,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.96,
          footprintWidthRatio: 0.46,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.defaultProp:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.90,
        scaleY: 0.80,
        opacity: 0.28,
        family: StaticShadowFamily.genericProjection,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.62,
          footprintHeightRatio: 0.12,
        ),
      );
  }
}

String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return 'lampadaire fin';
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return 'grand bâtiment';
    case ElementAutoShadowSuggestionKind.wideLow:
      return 'élément large et bas';
    case ElementAutoShadowSuggestionKind.smallSquare:
      return 'petit élément compact';
    case ElementAutoShadowSuggestionKind.defaultProp:
      return 'élément standard';
  }
}

```


### `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

enum ElementAutoShadowBackfillStatus {
  appliedMissing,
  appliedGeneric,
  skippedDisabled,
  skippedManual,
  skippedNoSuggestion,
  clearedAutoNoSuggestion,
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ElementAutoShadowBackfillEntry &&
            elementId == other.elementId &&
            elementName == other.elementName &&
            status == other.status &&
            suggestionKind == other.suggestionKind;
  }

  @override
  int get hashCode => Object.hash(
        elementId,
        elementName,
        status,
        suggestionKind,
      );
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

  int get appliedCount => entries
      .where(
        (entry) =>
            entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
            entry.status == ElementAutoShadowBackfillStatus.appliedGeneric,
      )
      .length;

  int get changedCount => entries.where(_entryChangesProject).length;

  int get skippedCount => entries.length - changedCount;

  bool get hasChanges => addedDefaultProfiles || changedCount > 0;
}

ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
  ProjectManifest project,
) {
  final projectWithDefaults =
      ensureDefaultGroundStaticShadowProfilesForProject(project);
  final addedDefaultProfiles = projectWithDefaults != project;
  final entries = <ElementAutoShadowBackfillEntry>[];
  final elements = <ProjectElementEntry>[];

  for (final element in projectWithDefaults.elements) {
    final currentShadow = element.shadow;
    if (currentShadow != null && !currentShadow.castsShadow) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedDisabled),
      );
      elements.add(element);
      continue;
    }

    final suggestion = buildElementAutoShadowSuggestion(
      element: element,
      shadowCatalog: projectWithDefaults.shadowCatalog,
    );
    if (suggestion == null) {
      if (currentShadow != null &&
          _isRecognizedAutoShadow(
            currentShadow,
            projectWithDefaults.shadowCatalog,
          )) {
        entries.add(
          _entry(
            element,
            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
          ),
        );
        elements.add(element.copyWith(shadow: null));
        continue;
      }
      entries.add(
        _entry(
          element,
          currentShadow == null
              ? ElementAutoShadowBackfillStatus.skippedNoSuggestion
              : ElementAutoShadowBackfillStatus.skippedManual,
        ),
      );
      elements.add(element);
      continue;
    }
    if (currentShadow != null &&
        !_isRecognizedAutoShadow(
          currentShadow,
          projectWithDefaults.shadowCatalog,
        )) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedManual),
      );
      elements.add(element);
      continue;
    }

    final status = currentShadow == null
        ? ElementAutoShadowBackfillStatus.appliedMissing
        : ElementAutoShadowBackfillStatus.appliedGeneric;
    entries.add(
      _entry(
        element,
        status,
        suggestionKind: suggestion.kind,
      ),
    );
    elements.add(element.copyWith(shadow: suggestion.config));
  }

  return ElementAutoShadowBackfillResult(
    project: addedDefaultProfiles || entries.any(_entryChangesProject)
        ? projectWithDefaults.copyWith(elements: elements)
        : project,
    entries: entries,
    addedDefaultProfiles: addedDefaultProfiles,
  );
}

bool _entryChangesProject(ElementAutoShadowBackfillEntry entry) {
  return entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
      entry.status == ElementAutoShadowBackfillStatus.appliedGeneric ||
      entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion;
}

ElementAutoShadowBackfillEntry _entry(
  ProjectElementEntry element,
  ElementAutoShadowBackfillStatus status, {
  ElementAutoShadowSuggestionKind? suggestionKind,
}) {
  return ElementAutoShadowBackfillEntry(
    elementId: element.id,
    elementName: element.name,
    status: status,
    suggestionKind: suggestionKind,
  );
}

bool _isRecognizedAutoShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  return _canReplaceExistingShadow(shadow, catalog) ||
      shadow == _oldAutoSmallSquareShadow() ||
      shadow == _oldAutoDefaultPropShadow() ||
      shadow == _oldAutoWideLowShadow();
}

bool _canReplaceExistingShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  if (!shadow.castsShadow) {
    return false;
  }
  if (shadow.footprint != null) {
    return false;
  }
  if (shadow.offsetX != null ||
      shadow.offsetY != null ||
      shadow.scaleX != null ||
      shadow.scaleY != null ||
      shadow.opacity != null) {
    return false;
  }

  final profileId = shadow.shadowProfileId;
  if (profileId == null) {
    return true;
  }
  if (_defaultGroundStaticProfileIds.contains(profileId)) {
    return true;
  }
  return catalog.profileById(profileId) == null;
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-soft-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.90,
    scaleY: 0.80,
    opacity: 0.28,
    family: StaticShadowFamily.genericProjection,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.62,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _oldAutoWideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.92,
    scaleY: 0.75,
    opacity: 0.27,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.72,
      footprintHeightRatio: 0.10,
    ),
  );
}

const _defaultGroundStaticProfileIds = <String>{
  'default-ground-soft-ellipse',
  'default-ground-wide-ellipse',
  'default-ground-contact-blob',
};

```


### `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('returns null without compatible ground static profile', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
            _profile('none', mode: ShadowCasterMode.none),
          ],
        ),
      );

      expect(suggestion, isNull);
    });

    test('returns null for missing frames', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _elementWithFrames(const []),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('returns null for invalid first frame source', () {
      final invalidWidth = buildElementAutoShadowSuggestion(
        element: _element(width: 0, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final invalidHeight = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 0),
        shadowCatalog: _defaultCatalog(),
      );

      expect(invalidWidth, isNull);
      expect(invalidHeight, isNull);
    });

    test('returns null for micro decor that should not cast projected shadows',
        () {
      final oneByOne = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 1),
        shadowCatalog: _defaultCatalog(),
      );
      final oneByTwo = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(oneByOne, isNull);
      expect(oneByTwo, isNull);
    });

    test('classifies tall thin elements as tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.family, StaticShadowFamily.tallProp);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
      expect(suggestion.config.opacity, 0.28);
    });

    test('classifies large buildings as buildingLarge', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.building);
      expect(suggestion.config.footprint!.anchorYRatio, 0.92);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.82);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleY, 0.85);
      expect(suggestion.config.opacity, 0.30);
    });

    test('wide low needs enough surface to receive an automatic shadow', () {
      final smallWide = buildElementAutoShadowSuggestion(
        element: _element(width: 3, height: 2),
        shadowCatalog: _defaultCatalog(),
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(smallWide, isNull);
      expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.compactProp);
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.72);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.92);
      expect(suggestion.config.scaleY, 0.75);
      expect(suggestion.config.opacity, 0.27);
    });

    test('small square returns null under artistic V0 policy', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('default prop returns null under artistic V0 policy', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('prefers default compact profile for tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-soft'),
            _profile('default-ground-contact-blob',
                mode: ShadowCasterMode.contactBlob),
          ],
        ),
      )!;

      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
    });

    test('falls back to custom compatible profile ids', () {
      final tallThin = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-contact', mode: ShadowCasterMode.contactBlob)
          ],
        ),
      )!;
      final building = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-ellipse')],
        ),
      )!;
      final wideLow = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 2),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-wide')],
        ),
      )!;

      expect(tallThin.config.shadowProfileId, 'custom-contact');
      expect(building.config.shadowProfileId, 'custom-ellipse');
      expect(wideLow.config.shadowProfileId, 'custom-wide');
    });

    test('all suggestions have castsShadow true', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.castsShadow, isTrue);
      }
    });

    test('all suggestion footprints are non-null and valid', () {
      for (final suggestion in _allSuggestionKinds()) {
        final footprint = suggestion.config.footprint;
        expect(footprint, isNotNull);
        expect(footprint!.anchorXRatio, inInclusiveRange(0, 1));
        expect(footprint.anchorYRatio, inInclusiveRange(0, 1));
        expect(footprint.footprintWidthRatio, greaterThan(0));
        expect(footprint.footprintHeightRatio, greaterThan(0));
      }
    });

    test('all suggestions carry a static shadow family', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.family, isNotNull);
      }
    });

    test('all suggestion opacities are within 0..1', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.opacity, inInclusiveRange(0, 1));
      }
    });

    test('all suggestion scaleX and scaleY are greater than zero', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.scaleX, greaterThan(0));
        expect(suggestion.config.scaleY, greaterThan(0));
      }
    });
  });
}

Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
  for (final dimensions in const [
    (width: 1, height: 4),
    (width: 4, height: 3),
    (width: 4, height: 2),
  ]) {
    yield buildElementAutoShadowSuggestion(
      element: _element(width: dimensions.width, height: dimensions.height),
      shadowCatalog: _defaultCatalog(),
    )!;
  }
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required int width,
  required int height,
}) {
  return _elementWithFrames([
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
    ),
  ]);
}

ProjectElementEntry _elementWithFrames(List<TilesetVisualFrame> frames) {
  return ProjectElementEntry(
    id: 'element',
    name: 'Element',
    tilesetId: 'tileset',
    categoryId: 'decor',
    frames: frames,
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}

```


### `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('applyElementAutoShadowSuggestionsToProject', () {
    test('applies suggestions to elements without shadow configs', () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(id: 'house', name: 'House', width: 4, height: 3),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 2);
      expect(result.skippedCount, 0);
      expect(result.hasChanges, isTrue);
      expect(result.addedDefaultProfiles, isFalse);
      expect(result.entries.map((entry) => entry.status), [
        ElementAutoShadowBackfillStatus.appliedMissing,
        ElementAutoShadowBackfillStatus.appliedMissing,
      ]);
      expect(result.entries.map((entry) => entry.suggestionKind), [
        ElementAutoShadowSuggestionKind.tallThin,
        ElementAutoShadowSuggestionKind.buildingLarge,
      ]);
      expect(
        result.project.elements[0].shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
      expect(
        result.project.elements[0].shadow!.family,
        StaticShadowFamily.tallProp,
      );
      expect(
        result.project.elements[0].shadow!.footprint!.footprintWidthRatio,
        0.18,
      );
      expect(
        result.project.elements[1].shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
      expect(
        result.project.elements[1].shadow!.family,
        StaticShadowFamily.building,
      );
      expect(
        result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
        0.82,
      );
    });

    test('replaces generic pre-footprint active shadows', () {
      final project = _project(
        elements: [
          _element(
            id: 'stand',
            name: 'Stand',
            width: 4,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'default-ground-soft-ellipse',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      expect(result.project.elements.single.shadow!.footprint, isNotNull);
      expect(
        result.project.elements.single.shadow!.footprint!.footprintWidthRatio,
        0.72,
      );
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
    });

    test('preserves disabled shadows', () {
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final project = _project(
        elements: [
          _element(
            id: 'disabled',
            name: 'Disabled',
            width: 1,
            height: 4,
            shadow: disabled,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedDisabled,
      );
      expect(result.project.elements.single.shadow, disabled);
    });

    test('preserves manual footprints and numeric overrides', () {
      final manualFootprint = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-contact-blob',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.31),
      );
      final manualNumbers = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-wide-ellipse',
        offsetX: 4,
        scaleY: 0.6,
        opacity: 0.18,
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-footprint',
            name: 'Manual footprint',
            width: 1,
            height: 4,
            shadow: manualFootprint,
          ),
          _element(
            id: 'manual-numbers',
            name: 'Manual numbers',
            width: 4,
            height: 3,
            shadow: manualNumbers,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 2);
      expect(
        result.entries.map((entry) => entry.status),
        everyElement(ElementAutoShadowBackfillStatus.skippedManual),
      );
      expect(result.project.elements[0].shadow, manualFootprint);
      expect(result.project.elements[1].shadow, manualNumbers);
    });

    test(
        'clears recognized auto small square shadow when policy has no suggestion',
        () {
      final project = _project(
        elements: [
          _element(
            id: 'small-square',
            name: 'Small square',
            width: 2,
            height: 2,
            shadow: _oldAutoSmallSquareShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('clears genericProjection auto shadow when policy has no suggestion',
        () {
      final project = _project(
        elements: [
          _element(
            id: 'default-prop',
            name: 'Default prop',
            width: 2,
            height: 3,
            shadow: _oldAutoDefaultPropShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('clears recognized auto wide low shadow below safe threshold', () {
      final project = _project(
        elements: [
          _element(
            id: 'small-stand',
            name: 'Small stand',
            width: 3,
            height: 2,
            shadow: _oldAutoWideLowShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves manual footprint even if no suggestion exists', () {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-soft-ellipse',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.33),
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-small',
            name: 'Manual small',
            width: 2,
            height: 2,
            shadow: manual,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, manual);
    });

    test('preserves non-default existing profile ids present in catalog', () {
      final customShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final project = _project(
        elements: [
          _element(
            id: 'custom-profile',
            name: 'Custom profile',
            width: 4,
            height: 3,
            shadow: customShadow,
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, customShadow);
    });

    test('replaces generic shadows with missing profile ids', () {
      final project = _project(
        elements: [
          _element(
            id: 'missing-profile',
            name: 'Missing profile',
            width: 1,
            height: 4,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'missing-profile-id',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('adds default profiles when the catalog has no compatible profile',
        () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
        ],
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
          result.project.shadowCatalog.profiles.map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('records skippedNoSuggestion for invalid element frames', () {
      final project = _project(
        elements: [
          _elementWithFrames(
            id: 'invalid',
            name: 'Invalid',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 0, height: 2),
              ),
            ],
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves element order and non-shadow fields', () {
      final project = _project(
        elements: [
          _element(
            id: 'first',
            name: 'First',
            width: 1,
            height: 4,
            presetKind: ElementPresetKind.tree,
            tags: const ['nature', 'tall'],
            sortOrder: 7,
          ),
          _element(
            id: 'second',
            name: 'Second',
            width: 4,
            height: 3,
            recommendedLayerId: 'decor_layer',
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.project.elements.map((element) => element.id), [
        'first',
        'second',
      ]);
      expect(result.project.elements[0].presetKind, ElementPresetKind.tree);
      expect(result.project.elements[0].tags, ['nature', 'tall']);
      expect(result.project.elements[0].sortOrder, 7);
      expect(result.project.elements[1].recommendedLayerId, 'decor_layer');
      expect(result.project.elements[0].shadow, isNotNull);
      expect(result.project.elements[1].shadow, isNotNull);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Backfill test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-soft-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.90,
    scaleY: 0.80,
    opacity: 0.28,
    family: StaticShadowFamily.genericProjection,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.62,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _oldAutoWideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.92,
    scaleY: 0.75,
    opacity: 0.27,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.72,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return _elementWithFrames(
    id: id,
    name: name,
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
    presetKind: presetKind,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}

ProjectElementEntry _elementWithFrames({
  required String id,
  required String name,
  required List<TilesetVisualFrame> frames,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: frames,
    presetKind: presetKind,
    shadow: shadow,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}

```


### `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('ApplyElementAutoShadowSuggestionsUseCase', () {
    test('saves when at least one element changes', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.hasChanges, isTrue);
      expect(result.appliedCount, 1);
      expect(repo.savedPath, '/tmp/project.json');
      expect(repo.lastSavedProject, result.project);
      expect(repo.lastSavedProject!.elements.single.shadow, isNotNull);
    });

    test('does not save when no element is eligible', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(
            id: 'manual',
            name: 'Manual',
            width: 2,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'custom-ground-shadow',
            ),
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.hasChanges, isFalse);
      expect(result.appliedCount, 0);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(repo.lastSavedProject, isNull);
      expect(repo.savedPath, isNull);
    });

    test('saves when cleanup removes recognized auto shadow', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(
            id: 'small-square',
            name: 'Small square',
            width: 2,
            height: 2,
            shadow: _oldAutoSmallSquareShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.hasChanges, isTrue);
      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(repo.savedPath, '/tmp/project.json');
      expect(repo.lastSavedProject, result.project);
      expect(repo.lastSavedProject!.elements.single.shadow, isNull);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
    });

    test('returns counts and saves projects that round trip through JSON',
        () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(
            id: 'disabled',
            name: 'Disabled',
            width: 4,
            height: 3,
            shadow: ProjectElementShadowConfig(castsShadow: false),
          ),
        ],
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.skippedCount, 1);
      expect(result.entries.map((entry) => entry.status), [
        ElementAutoShadowBackfillStatus.appliedMissing,
        ElementAutoShadowBackfillStatus.skippedDisabled,
      ]);
      expect(
        ProjectManifest.fromJson(repo.lastSavedProject!.toJson()),
        repo.lastSavedProject,
      );
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Apply auto shadows test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
  );
}

final class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;
  String? savedPath;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedPath = path;
    lastSavedProject = ProjectManifest.fromJson(project.toJson());
  }
}

final class _FakeWorkspace implements ProjectWorkspace {
  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return '/tmp/tilesets/image.png';
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String getMapPath(String mapId) => '/tmp/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

```

## 23. Diff complet ciblé Shadow-47

```diff
diff --git a/packages/map_core/lib/src/operations/static_shadow_family_projection.dart b/packages/map_core/lib/src/operations/static_shadow_family_projection.dart
index 4ac0c4c9..4ef5f7c7 100644
--- a/packages/map_core/lib/src/operations/static_shadow_family_projection.dart
+++ b/packages/map_core/lib/src/operations/static_shadow_family_projection.dart
@@ -21,30 +21,30 @@ StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
     case StaticShadowFamily.compactProp:
       return _scaledProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 0.72,
-        nearWidthMultiplierScale: 0.82,
-        farWidthMultiplierScale: 0.78,
+        lengthRatioScale: 0.38,
+        nearWidthMultiplierScale: 0.58,
+        farWidthMultiplierScale: 0.44,
       );
     case StaticShadowFamily.tallProp:
       return _scaledProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 1.18,
-        nearWidthMultiplierScale: 0.52,
-        farWidthMultiplierScale: 0.58,
+        lengthRatioScale: 0.48,
+        nearWidthMultiplierScale: 0.32,
+        farWidthMultiplierScale: 0.28,
       );
     case StaticShadowFamily.building:
       return _scaledProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 1.25,
-        nearWidthMultiplierScale: 1.05,
-        farWidthMultiplierScale: 0.98,
+        lengthRatioScale: 0.62,
+        nearWidthMultiplierScale: 0.78,
+        farWidthMultiplierScale: 0.62,
       );
     case StaticShadowFamily.foliage:
       return _scaledProjectionSpec(
         baseProjectionSpec,
-        lengthRatioScale: 1.05,
-        nearWidthMultiplierScale: 1.15,
-        farWidthMultiplierScale: 1.28,
+        lengthRatioScale: 0.45,
+        nearWidthMultiplierScale: 0.72,
+        farWidthMultiplierScale: 0.70,
       );
   }
 }
diff --git a/packages/map_core/test/shadow/static_shadow_family_projection_test.dart b/packages/map_core/test/shadow/static_shadow_family_projection_test.dart
index 45cc7c7a..d51fbeff 100644
--- a/packages/map_core/test/shadow/static_shadow_family_projection_test.dart
+++ b/packages/map_core/test/shadow/static_shadow_family_projection_test.dart
@@ -95,14 +95,14 @@ void main() {
       );
     });

-    test('tall props are narrow and still project farther than generic', () {
+    test('tall props are narrow and shorter than generic', () {
       final spec = resolveStaticShadowFamilyProjectionSpec(
         family: StaticShadowFamily.tallProp,
       );

       expect(
         spec.lengthRatio,
-        greaterThan(defaultStaticShadowProjectionSpec.lengthRatio),
+        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
       );
       expect(
         spec.nearWidthMultiplier,
@@ -114,18 +114,25 @@ void main() {
       );
     });

-    test('buildings keep a broad block-like projection', () {
+    test('buildings keep a broad but shorter block-like projection', () {
       final spec = resolveStaticShadowFamilyProjectionSpec(
         family: StaticShadowFamily.building,
       );
+      final tall = resolveStaticShadowFamilyProjectionSpec(
+        family: StaticShadowFamily.tallProp,
+      );

       expect(
         spec.lengthRatio,
-        greaterThan(defaultStaticShadowProjectionSpec.lengthRatio),
+        lessThan(defaultStaticShadowProjectionSpec.lengthRatio),
+      );
+      expect(
+        spec.nearWidthMultiplier,
+        lessThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
       );
       expect(
         spec.nearWidthMultiplier,
-        greaterThan(defaultStaticShadowProjectionSpec.nearWidthMultiplier),
+        greaterThan(tall.nearWidthMultiplier),
       );
       expect(
         spec.farWidthMultiplier,
@@ -156,9 +163,9 @@ void main() {
         family: StaticShadowFamily.compactProp,
       );

-      expect(spec.lengthRatio, closeTo(0.2304, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.7544, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(0.9204, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.1216, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.5336, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.5192, 0.0000001));
     });

     test('tallProp V0 constants are stable', () {
@@ -166,9 +173,9 @@ void main() {
         family: StaticShadowFamily.tallProp,
       );

-      expect(spec.lengthRatio, closeTo(0.3776, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.4784, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(0.6844, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.1536, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.2944, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.3304, 0.0000001));
     });

     test('building V0 constants are stable', () {
@@ -176,9 +183,9 @@ void main() {
         family: StaticShadowFamily.building,
       );

-      expect(spec.lengthRatio, closeTo(0.4, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(0.966, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(1.1564, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.1984, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.7176, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.7316, 0.0000001));
     });

     test('foliage V0 constants are stable', () {
@@ -186,9 +193,9 @@ void main() {
         family: StaticShadowFamily.foliage,
       );

-      expect(spec.lengthRatio, closeTo(0.336, 0.0000001));
-      expect(spec.nearWidthMultiplier, closeTo(1.058, 0.0000001));
-      expect(spec.farWidthMultiplier, closeTo(1.5104, 0.0000001));
+      expect(spec.lengthRatio, closeTo(0.144, 0.0000001));
+      expect(spec.nearWidthMultiplier, closeTo(0.6624, 0.0000001));
+      expect(spec.farWidthMultiplier, closeTo(0.826, 0.0000001));
     });

     test('scaled family specs remain valid for a custom positive base', () {
diff --git a/packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart b/packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
index e4095be9..6ad2c5f4 100644
--- a/packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
+++ b/packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
@@ -7,6 +7,7 @@ enum ElementAutoShadowBackfillStatus {
   skippedDisabled,
   skippedManual,
   skippedNoSuggestion,
+  clearedAutoNoSuggestion,
 }

 final class ElementAutoShadowBackfillEntry {
@@ -60,9 +61,11 @@ final class ElementAutoShadowBackfillResult {
       )
       .length;

-  int get skippedCount => entries.length - appliedCount;
+  int get changedCount => entries.where(_entryChangesProject).length;

-  bool get hasChanges => addedDefaultProfiles || appliedCount > 0;
+  int get skippedCount => entries.length - changedCount;
+
+  bool get hasChanges => addedDefaultProfiles || changedCount > 0;
 }

 ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
@@ -83,25 +86,44 @@ ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
       elements.add(element);
       continue;
     }
-    if (currentShadow != null &&
-        !_canReplaceExistingShadow(
-          currentShadow,
-          projectWithDefaults.shadowCatalog,
-        )) {
-      entries.add(
-        _entry(element, ElementAutoShadowBackfillStatus.skippedManual),
-      );
-      elements.add(element);
-      continue;
-    }

     final suggestion = buildElementAutoShadowSuggestion(
       element: element,
       shadowCatalog: projectWithDefaults.shadowCatalog,
     );
     if (suggestion == null) {
+      if (currentShadow != null &&
+          _isRecognizedAutoShadow(
+            currentShadow,
+            projectWithDefaults.shadowCatalog,
+          )) {
+        entries.add(
+          _entry(
+            element,
+            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
+          ),
+        );
+        elements.add(element.copyWith(shadow: null));
+        continue;
+      }
       entries.add(
-        _entry(element, ElementAutoShadowBackfillStatus.skippedNoSuggestion),
+        _entry(
+          element,
+          currentShadow == null
+              ? ElementAutoShadowBackfillStatus.skippedNoSuggestion
+              : ElementAutoShadowBackfillStatus.skippedManual,
+        ),
+      );
+      elements.add(element);
+      continue;
+    }
+    if (currentShadow != null &&
+        !_isRecognizedAutoShadow(
+          currentShadow,
+          projectWithDefaults.shadowCatalog,
+        )) {
+      entries.add(
+        _entry(element, ElementAutoShadowBackfillStatus.skippedManual),
       );
       elements.add(element);
       continue;
@@ -121,14 +143,7 @@ ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
   }

   return ElementAutoShadowBackfillResult(
-    project: addedDefaultProfiles ||
-            entries.any(
-              (entry) =>
-                  entry.status ==
-                      ElementAutoShadowBackfillStatus.appliedMissing ||
-                  entry.status ==
-                      ElementAutoShadowBackfillStatus.appliedGeneric,
-            )
+    project: addedDefaultProfiles || entries.any(_entryChangesProject)
         ? projectWithDefaults.copyWith(elements: elements)
         : project,
     entries: entries,
@@ -136,6 +151,12 @@ ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
   );
 }

+bool _entryChangesProject(ElementAutoShadowBackfillEntry entry) {
+  return entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
+      entry.status == ElementAutoShadowBackfillStatus.appliedGeneric ||
+      entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion;
+}
+
 ElementAutoShadowBackfillEntry _entry(
   ProjectElementEntry element,
   ElementAutoShadowBackfillStatus status, {
@@ -149,6 +170,16 @@ ElementAutoShadowBackfillEntry _entry(
   );
 }

+bool _isRecognizedAutoShadow(
+  ProjectElementShadowConfig shadow,
+  ProjectShadowCatalog catalog,
+) {
+  return _canReplaceExistingShadow(shadow, catalog) ||
+      shadow == _oldAutoSmallSquareShadow() ||
+      shadow == _oldAutoDefaultPropShadow() ||
+      shadow == _oldAutoWideLowShadow();
+}
+
 bool _canReplaceExistingShadow(
   ProjectElementShadowConfig shadow,
   ProjectShadowCatalog catalog,
@@ -177,6 +208,63 @@ bool _canReplaceExistingShadow(
   return catalog.profileById(profileId) == null;
 }

+ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-contact-blob',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.78,
+    scaleY: 0.70,
+    opacity: 0.26,
+    family: StaticShadowFamily.compactProp,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.96,
+      footprintWidthRatio: 0.46,
+      footprintHeightRatio: 0.10,
+    ),
+  );
+}
+
+ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-soft-ellipse',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.90,
+    scaleY: 0.80,
+    opacity: 0.28,
+    family: StaticShadowFamily.genericProjection,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.95,
+      footprintWidthRatio: 0.62,
+      footprintHeightRatio: 0.12,
+    ),
+  );
+}
+
+ProjectElementShadowConfig _oldAutoWideLowShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-wide-ellipse',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.92,
+    scaleY: 0.75,
+    opacity: 0.27,
+    family: StaticShadowFamily.compactProp,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.95,
+      footprintWidthRatio: 0.72,
+      footprintHeightRatio: 0.10,
+    ),
+  );
+}
+
 const _defaultGroundStaticProfileIds = <String>{
   'default-ground-soft-ellipse',
   'default-ground-wide-ellipse',
diff --git a/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart b/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
index 8b2978ff..dc278502 100644
--- a/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
+++ b/packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
@@ -31,10 +31,25 @@ ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
   if (source.width <= 0 || source.height <= 0) {
     return null;
   }
+  final width = source.width.toDouble();
+  final height = source.height.toDouble();
+  if (_isMicroDecor(
+    width: width,
+    height: height,
+  )) {
+    return null;
+  }
   final kind = _classifyElement(
-    width: source.width.toDouble(),
-    height: source.height.toDouble(),
+    width: width,
+    height: height,
   );
+  if (!_autoShadowKindIsArtisticallySafe(
+    kind,
+    width: width,
+    height: height,
+  )) {
+    return null;
+  }
   final profile = _profileForKind(shadowCatalog, kind);
   if (profile == null) {
     return null;
@@ -46,6 +61,13 @@ ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
   );
 }

+bool _isMicroDecor({
+  required double width,
+  required double height,
+}) {
+  return width <= 1 && height <= 2;
+}
+
 ElementAutoShadowSuggestionKind _classifyElement({
   required double width,
   required double height,
@@ -55,6 +77,9 @@ ElementAutoShadowSuggestionKind _classifyElement({
   if (aspect >= 2.2 && width <= 2) {
     return ElementAutoShadowSuggestionKind.tallThin;
   }
+  if (width >= 3 && height <= 2) {
+    return ElementAutoShadowSuggestionKind.wideLow;
+  }
   if (width >= 4 || area >= 12) {
     return ElementAutoShadowSuggestionKind.buildingLarge;
   }
@@ -67,6 +92,23 @@ ElementAutoShadowSuggestionKind _classifyElement({
   return ElementAutoShadowSuggestionKind.defaultProp;
 }

+bool _autoShadowKindIsArtisticallySafe(
+  ElementAutoShadowSuggestionKind kind, {
+  required double width,
+  required double height,
+}) {
+  switch (kind) {
+    case ElementAutoShadowSuggestionKind.tallThin:
+    case ElementAutoShadowSuggestionKind.buildingLarge:
+      return true;
+    case ElementAutoShadowSuggestionKind.wideLow:
+      return width >= 4 || width * height >= 10;
+    case ElementAutoShadowSuggestionKind.smallSquare:
+    case ElementAutoShadowSuggestionKind.defaultProp:
+      return false;
+  }
+}
+
 ProjectShadowProfile? _profileForKind(
   ProjectShadowCatalog catalog,
   ElementAutoShadowSuggestionKind kind,
diff --git a/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart b/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
index 06982b7f..fe6c9658 100644
--- a/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
+++ b/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
@@ -60,7 +60,7 @@ void main() {
           _element(
             id: 'stand',
             name: 'Stand',
-            width: 3,
+            width: 4,
             height: 2,
             shadow: ProjectElementShadowConfig(
               castsShadow: true,
@@ -160,6 +160,116 @@ void main() {
       expect(result.project.elements[1].shadow, manualNumbers);
     });

+    test(
+        'clears recognized auto small square shadow when policy has no suggestion',
+        () {
+      final project = _project(
+        elements: [
+          _element(
+            id: 'small-square',
+            name: 'Small square',
+            width: 2,
+            height: 2,
+            shadow: _oldAutoSmallSquareShadow(),
+          ),
+        ],
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      final result = applyElementAutoShadowSuggestionsToProject(project);
+
+      expect(result.appliedCount, 0);
+      expect(result.changedCount, 1);
+      expect(result.hasChanges, isTrue);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
+      );
+      expect(result.project.elements.single.shadow, isNull);
+    });
+
+    test('clears genericProjection auto shadow when policy has no suggestion',
+        () {
+      final project = _project(
+        elements: [
+          _element(
+            id: 'default-prop',
+            name: 'Default prop',
+            width: 2,
+            height: 3,
+            shadow: _oldAutoDefaultPropShadow(),
+          ),
+        ],
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      final result = applyElementAutoShadowSuggestionsToProject(project);
+
+      expect(result.appliedCount, 0);
+      expect(result.changedCount, 1);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
+      );
+      expect(result.project.elements.single.shadow, isNull);
+    });
+
+    test('clears recognized auto wide low shadow below safe threshold', () {
+      final project = _project(
+        elements: [
+          _element(
+            id: 'small-stand',
+            name: 'Small stand',
+            width: 3,
+            height: 2,
+            shadow: _oldAutoWideLowShadow(),
+          ),
+        ],
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      final result = applyElementAutoShadowSuggestionsToProject(project);
+
+      expect(result.appliedCount, 0);
+      expect(result.changedCount, 1);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
+      );
+      expect(result.project.elements.single.shadow, isNull);
+    });
+
+    test('preserves manual footprint even if no suggestion exists', () {
+      final manual = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'default-ground-soft-ellipse',
+        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.33),
+      );
+      final project = _project(
+        elements: [
+          _element(
+            id: 'manual-small',
+            name: 'Manual small',
+            width: 2,
+            height: 2,
+            shadow: manual,
+          ),
+        ],
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      final result = applyElementAutoShadowSuggestionsToProject(project);
+
+      expect(result.appliedCount, 0);
+      expect(result.changedCount, 0);
+      expect(result.hasChanges, isFalse);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.skippedManual,
+      );
+      expect(result.project.elements.single.shadow, manual);
+    });
+
     test('preserves non-default existing profile ids present in catalog', () {
       final customShadow = ProjectElementShadowConfig(
         castsShadow: true,
@@ -204,8 +314,8 @@ void main() {
           _element(
             id: 'missing-profile',
             name: 'Missing profile',
-            width: 2,
-            height: 2,
+            width: 1,
+            height: 4,
             shadow: ProjectElementShadowConfig(
               castsShadow: true,
               shadowProfileId: 'missing-profile-id',
@@ -232,7 +342,7 @@ void main() {
         () {
       final project = _project(
         elements: [
-          _element(id: 'prop', name: 'Prop', width: 2, height: 3),
+          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
         ],
         shadowCatalog: const ProjectShadowCatalog.empty(),
       );
@@ -250,7 +360,7 @@ void main() {
       ]);
       expect(
         result.project.elements.single.shadow!.shadowProfileId,
-        'default-ground-soft-ellipse',
+        'default-ground-contact-blob',
       );
     });

@@ -349,6 +459,63 @@ ProjectShadowCatalog _defaultCatalog() {
   );
 }

+ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-contact-blob',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.78,
+    scaleY: 0.70,
+    opacity: 0.26,
+    family: StaticShadowFamily.compactProp,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.96,
+      footprintWidthRatio: 0.46,
+      footprintHeightRatio: 0.10,
+    ),
+  );
+}
+
+ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-soft-ellipse',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.90,
+    scaleY: 0.80,
+    opacity: 0.28,
+    family: StaticShadowFamily.genericProjection,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.95,
+      footprintWidthRatio: 0.62,
+      footprintHeightRatio: 0.12,
+    ),
+  );
+}
+
+ProjectElementShadowConfig _oldAutoWideLowShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-wide-ellipse',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.92,
+    scaleY: 0.75,
+    opacity: 0.27,
+    family: StaticShadowFamily.compactProp,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.95,
+      footprintWidthRatio: 0.72,
+      footprintHeightRatio: 0.10,
+    ),
+  );
+}
+
 ProjectElementEntry _element({
   required String id,
   required String name,
diff --git a/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart b/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
index ac5468ac..35ffde63 100644
--- a/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
+++ b/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
@@ -45,6 +45,21 @@ void main() {
       expect(invalidHeight, isNull);
     });

+    test('returns null for micro decor that should not cast projected shadows',
+        () {
+      final oneByOne = buildElementAutoShadowSuggestion(
+        element: _element(width: 1, height: 1),
+        shadowCatalog: _defaultCatalog(),
+      );
+      final oneByTwo = buildElementAutoShadowSuggestion(
+        element: _element(width: 1, height: 2),
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      expect(oneByOne, isNull);
+      expect(oneByTwo, isNull);
+    });
+
     test('classifies tall thin elements as tallThin', () {
       final suggestion = buildElementAutoShadowSuggestion(
         element: _element(width: 1, height: 4),
@@ -75,12 +90,17 @@ void main() {
       expect(suggestion.config.opacity, 0.30);
     });

-    test('classifies wide low elements as wideLow', () {
-      final suggestion = buildElementAutoShadowSuggestion(
+    test('wide low needs enough surface to receive an automatic shadow', () {
+      final smallWide = buildElementAutoShadowSuggestion(
         element: _element(width: 3, height: 2),
         shadowCatalog: _defaultCatalog(),
+      );
+      final suggestion = buildElementAutoShadowSuggestion(
+        element: _element(width: 4, height: 2),
+        shadowCatalog: _defaultCatalog(),
       )!;

+      expect(smallWide, isNull);
       expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
       expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
       expect(suggestion.config.family, StaticShadowFamily.compactProp);
@@ -92,38 +112,22 @@ void main() {
       expect(suggestion.config.opacity, 0.27);
     });

-    test('classifies small square elements as smallSquare', () {
+    test('small square returns null under artistic V0 policy', () {
       final suggestion = buildElementAutoShadowSuggestion(
         element: _element(width: 2, height: 2),
         shadowCatalog: _defaultCatalog(),
-      )!;
+      );

-      expect(suggestion.kind, ElementAutoShadowSuggestionKind.smallSquare);
-      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
-      expect(suggestion.config.family, StaticShadowFamily.compactProp);
-      expect(suggestion.config.footprint!.anchorYRatio, 0.96);
-      expect(suggestion.config.footprint!.footprintWidthRatio, 0.46);
-      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
-      expect(suggestion.config.scaleX, 0.78);
-      expect(suggestion.config.scaleY, 0.70);
-      expect(suggestion.config.opacity, 0.26);
+      expect(suggestion, isNull);
     });

-    test('classifies remaining valid elements as defaultProp', () {
+    test('default prop returns null under artistic V0 policy', () {
       final suggestion = buildElementAutoShadowSuggestion(
         element: _element(width: 2, height: 3),
         shadowCatalog: _defaultCatalog(),
-      )!;
+      );

-      expect(suggestion.kind, ElementAutoShadowSuggestionKind.defaultProp);
-      expect(suggestion.config.shadowProfileId, 'default-ground-soft-ellipse');
-      expect(suggestion.config.family, StaticShadowFamily.genericProjection);
-      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
-      expect(suggestion.config.footprint!.footprintWidthRatio, 0.62);
-      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
-      expect(suggestion.config.scaleX, 0.90);
-      expect(suggestion.config.scaleY, 0.80);
-      expect(suggestion.config.opacity, 0.28);
+      expect(suggestion, isNull);
     });

     test('prefers default compact profile for tallThin', () {
@@ -156,16 +160,16 @@ void main() {
           profiles: [_profile('custom-ellipse')],
         ),
       )!;
-      final defaultProp = buildElementAutoShadowSuggestion(
-        element: _element(width: 2, height: 3),
+      final wideLow = buildElementAutoShadowSuggestion(
+        element: _element(width: 4, height: 2),
         shadowCatalog: ProjectShadowCatalog(
-          profiles: [_profile('custom-soft')],
+          profiles: [_profile('custom-wide')],
         ),
       )!;

       expect(tallThin.config.shadowProfileId, 'custom-contact');
       expect(building.config.shadowProfileId, 'custom-ellipse');
-      expect(defaultProp.config.shadowProfileId, 'custom-soft');
+      expect(wideLow.config.shadowProfileId, 'custom-wide');
     });

     test('all suggestions have castsShadow true', () {
@@ -210,9 +214,7 @@ Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
   for (final dimensions in const [
     (width: 1, height: 4),
     (width: 4, height: 3),
-    (width: 3, height: 2),
-    (width: 2, height: 2),
-    (width: 2, height: 3),
+    (width: 4, height: 2),
   ]) {
     yield buildElementAutoShadowSuggestion(
       element: _element(width: dimensions.width, height: dimensions.height),
diff --git a/packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart b/packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
index 8fe2276c..54d63286 100644
--- a/packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
+++ b/packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
@@ -69,6 +69,37 @@ void main() {
       expect(repo.savedPath, isNull);
     });

+    test('saves when cleanup removes recognized auto shadow', () async {
+      final repo = _FakeProjectRepository();
+      final workspace = _FakeWorkspace();
+      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
+      final project = _project(
+        elements: [
+          _element(
+            id: 'small-square',
+            name: 'Small square',
+            width: 2,
+            height: 2,
+            shadow: _oldAutoSmallSquareShadow(),
+          ),
+        ],
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      final result = await useCase.execute(workspace, project);
+
+      expect(result.hasChanges, isTrue);
+      expect(result.appliedCount, 0);
+      expect(result.changedCount, 1);
+      expect(repo.savedPath, '/tmp/project.json');
+      expect(repo.lastSavedProject, result.project);
+      expect(repo.lastSavedProject!.elements.single.shadow, isNull);
+      expect(
+        result.entries.single.status,
+        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
+      );
+    });
+
     test('returns counts and saves projects that round trip through JSON',
         () async {
       final repo = _FakeProjectRepository();
@@ -134,6 +165,25 @@ ProjectShadowCatalog _defaultCatalog() {
   );
 }

+ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
+  return ProjectElementShadowConfig(
+    castsShadow: true,
+    shadowProfileId: 'default-ground-contact-blob',
+    offsetX: 0,
+    offsetY: 0,
+    scaleX: 0.78,
+    scaleY: 0.70,
+    opacity: 0.26,
+    family: StaticShadowFamily.compactProp,
+    footprint: StaticShadowFootprintConfig(
+      anchorXRatio: 0.5,
+      anchorYRatio: 0.96,
+      footprintWidthRatio: 0.46,
+      footprintHeightRatio: 0.10,
+    ),
+  );
+}
+
 ProjectElementEntry _element({
   required String id,
   required String name,
```
