# Surface Engine — Lot 16 — Standard Water Path Preset Vertical Atlas Builder V0

Date (machine locale des fichiers) : 2026-04-26

## 1) Résumé exécutif
- Ajout d’un helper pur `createStandardWaterPathPresetFromVerticalAtlas(...)` : composition de `createStandardProjectPathPresetFromVerticalAtlas` (Lot 15) en fixant `surfaceKind: PathSurfaceKind.water`.
- Ajout d’une batterie de tests miroir Lot 15 + compat (views legacy + timeline) + délégation des validations.
- Export public via `packages/map_core/lib/map_core.dart`.
- Validation : `dart test` ciblés, relots, suite `map_core` complète **verte**, `dart analyze` ciblé **sans issues**.

## 2) Pourquoi ce lot est nécessaire après le Lot 15
- Le Lot 15 est générique : l’appelant choisit `PathSurfaceKind`. Le Lot 16 matérialise le premier builder standard “eau animée” = même stack atlas vertical, tagging legacy `water` imposé, sans gameplay additionnel.

## 3) Lien avec les atlas animés verticaux type Pokémon SDK
- Autotile/path variants en colonnes + animation en frames verticales. Les lots 11-15 cristallisent ce mapping. Le lot 16 ne modifie pas la géométrie : il fige l’intention “eau” côté `PathSurfaceKind` legacy.

## 4) Fichiers consultés (audit / lecture)
- `packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart` (Lot 15 — non modifié)
- `packages/map_core/lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart` (ordre V0 — non modifié)
- vues/diagnostics : couvertes par les imports/tests de compat (non modifiés).

## 5) Fichiers créés
- `packages/map_core/lib/src/operations/standard_water_path_preset_vertical_atlas_builder.dart`
- `packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart`
- (ce rapport) `reports/surface/surface_engine_lot_16_standard_water_path_preset_vertical_atlas_builder.md`

## 6) Fichiers modifiés
- `packages/map_core/lib/map_core.dart` (export unique)

## 7) API ajoutée
```dart
ProjectPathPreset createStandardWaterPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required String tilesetId,
  String? categoryId,
  int sortOrder = 0,
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String frameTilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
})
```

## 8) Sémantique du helper
- Délègue 100% du layout/validation au stack Lots 11-15; **fixe** `PathSurfaceKind.water` via le Lot 15.
- `ProjectPathPreset.tilesetId` = `tilesetId`; `TilesetVisualFrame.tilesetId` = `frameTilesetId` (chaîne vide = pas d’override).
- Ne modifie pas le manifest, n'ajoute pas de SurfaceDefinition, n'implémente pas surf/collision/encounter/rendu.

## 9) Liste complète des cas testés (28)
1. Layout standard + 4 frames + bornes de colonnes + nombre de variants.
2. Spécialisation : pas de `surfaceKind` public → toujours water (documenté).
3. `categoryId` + `sortOrder` préservés.
4. `firstColumn` + progression colonnes standard.
5. `startRow` + y sur 3 frames.
6. Sous-layout 3 variants + ordre + colonnes 0..2.
7. Sous-layout + `firstColumn: 20` → 20..22.
8. `sourceWidth/Height` sur toutes les frames.
9. Distinction preset `tilesetId` vs `frameTilesetId`.
10. `frameTilesetId` vide (frames vides).
11. `defaultDurationMs` custom appliqué partout.
12. `frameDurationsMs` (cohérent inter-variants).
13. `null` remplacé par défaut.
14-16. `LegacyPathSurfaceView` / `LegacyProjectSurfaceCatalogView` / `resolveTileVisualFrameTimeline`.
17-28. Délégation `ValidationException` (mêmes axes que le prompt).

## 10) Ce que les tests prouvent
- Le wrapper ne change pas le comportement Lot 15, hormis l’imposition de `PathSurfaceKind.water`.
- Compat catalog/timeline héritée, utile pour les migrations incrémentales “legacy-first”.

## 11) Volontairement non fait
- SurfaceDefinition, SurfaceEngine, intégration runtime/editor, surf, collisions, encounter, chargement d’image.

## 12) Impact pour futurs modèles Surface / Tile Animation Engine
- Point d’appel authoring pur, stable, portable tant que le pipeline consomme `ProjectPathPreset` + `TilesetVisualFrame`.
- Garde le Surface Engine *hors* du modèle: c'est un adapter de données, pas un nouveau contrat persistant.

## 13) Points de vigilance
- `water` ici = **enum** legacy, pas sémantique “liquide + surf”.
- Confusion fréquente: `frameTilesetId` override vs `ProjectPathPreset.tilesetId` principal — tests requis quand on branche l’import d’assets.

## 14) Commandes lancées (preuve)
```text
$ cd /Users/karim/Project/pokemonProject/packages/map_core
$ /opt/homebrew/bin/dart format lib/src/operations/standard_water_path_preset_vertical_atlas_builder.dart test/standard_water_path_preset_vertical_atlas_builder_test.dart lib/map_core.dart
$ /opt/homebrew/bin/dart test test/standard_water_path_preset_vertical_atlas_builder_test.dart --reporter expanded
```

### Sortie (extrait) — Lot 16, fin de log expanded
```text
00:00 [32m+23[0m: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid frameCount[0m
00:00 [32m+24[0m: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid source dimensions[0m
00:00 [32m+25[0m: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid defaultDurationMs[0m
00:00 [32m+26[0m: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for frameDurationsMs length mismatch[0m
00:00 [32m+27[0m: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for non-positive frame durations[0m
00:00 [32m+28[0m: All tests passed![0m
```

```text
$ /opt/homebrew/bin/dart test test/standard_path_preset_vertical_atlas_builder_test.dart
$ /opt/homebrew/bin/dart test test/terrain_path_variant_vertical_atlas_layout_test.dart
$ /opt/homebrew/bin/dart test test/path_preset_vertical_atlas_builder_test.dart
$ /opt/homebrew/bin/dart test test/path_variant_vertical_atlas_mapping_test.dart
$ /opt/homebrew/bin/dart test test/tile_visual_frame_vertical_atlas_test.dart
(chaque exécution: exit 0, “All tests passed!” dans la sortie.)
```

```text
$ /opt/homebrew/bin/dart test  # (reporter compact, ultra-ligne)
```
### Résultat interprété — suite `map_core` complète
- Dernier compteur: **+440** immédiatement avant `All tests passed!`
- Dernière portion brute (repr, inclut séquences ANSI) :
```text
'                                    \r00:01 \\x1b[32m+440\\x1b[0m: All tests passed!\\x1b[0m                                                                                                                                                                          \n'
```

```text
$ /opt/homebrew/bin/dart analyze lib/src/operations/standard_water_path_preset_vertical_atlas_builder.dart test/standard_water_path_preset_vertical_atlas_builder_test.dart lib/map_core.dart
```
```text
Analyzing standard_water_path_preset_vertical_atlas_builder.dart, standard_water_path_preset_vertical_atlas_builder_test.dart, map_core.dart...
No issues found!

```

```text
$ git -C /Users/karim/Project/pokemonProject status --short
```
```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_water_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart

```

## 15) Résultats exacts (commandes) — rappel
- Lot 16: `+28: All tests passed!` (extrait en §14).
- `dart test` complet: `+440: All tests passed!` (voir extrait §14).
- `dart analyze` ciblé: `No issues found!`

## 16) Total exact `dart test` complet
- **440** tests (d’après le dernier compteur `+N` du reporter compact).

## 17) Autocritique
- Minimalisme assumé: le risque serait d’y voir de la “duplication de doc”; le code reste un forward strict pour limiter le drift.
- Les logs de suite complète sont peu exploitables en mode compact; d’où l’extraction explicite du `+N` final.

## 18) Ce que le prompt semble discutable ou incomplet
- “Copier toute la sortie” d’une suite compact monolithique est peu utile; le signal reproductible est le **total** + `All tests passed!`.

## 19) Auto-review indépendante (Q/R)
- Q: Périmètre strict eau? **Oui** (seulement `PathSurfaceKind.water` + forward).
- Q: Aucun Surface persistant? **Oui**.
- Q: Aucun surf/collision/encounter? **Oui** (hors code).
- Q: Aucun modèle Freezed/JSON modifié? **Oui**.
- Q: Aucun generated? **Oui** (pas de build_runner).
- Q: Aucun runtime/editor/gameplay modifié? **Oui** (hors `map_core` + rapport).
- Q: Compose Lot 15? **Oui**.
- Q: Valide sans dupliquer? **Oui** (délégation + tests).
- Q: `surfaceKind` water? **Oui**.
- Q: `tilesetId` vs `frameTilesetId`? **Oui** (tests).
- Q: Ordre variants préservé? **Oui** (sous-layout).
- Q: Validations testées? **Oui** (délégation).
- Q: Compat views/timeline? **Oui**.
- Q: Relots verts? **Oui**.
- Q: `map_core` complet vert? **Oui** (440 tests).
- Q: Diffs/contents? **Ici (§20-21) + message final**.
- Q: Git write interdit? **Oui** (seulement commandes en lecture + `diff`/`diff -u` pour preuves).

## 20) Contenu complet des fichiers créés/modifiés
### 20.1 `standard_water_path_preset_vertical_atlas_builder.dart`
```dart
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'standard_path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy animated **water** [ProjectPathPreset] from the standard
/// vertical atlas layout.
///
/// This is a thin, product-oriented wrapper on top of Lot 15. It does not add
/// gameplay rules, surf, encounters, collision, or rendering. The only
/// "water" guarantee here is:
///
/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.water]
///
/// Everything else (columns, frames, tileset override semantics) is inherited
/// from the shared vertical-atlas stack (Lots 11-15).
ProjectPathPreset createStandardWaterPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required String tilesetId,
  String? categoryId,
  int sortOrder = 0,
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String frameTilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  // Deliberately no duplicated validation. Lot 15 composes Lot 14 + Lot 13 and
  // owns the behavior contract. This function only pins surfaceKind to water.
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.water,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameTilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}

```

### 20.2 `standard_water_path_preset_vertical_atlas_builder_test.dart`
```dart
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  // Lot 16 is a tiny specialization of Lot 15: the vertical atlas contract is
  // unchanged, but the resulting legacy preset is always tagged as water via
  // [PathSurfaceKind.water]. This suite mirrors the Lot 15 tests to prove the
  // wrapper does not fork validation or frame layout semantics.
  group('createStandardWaterPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test('generates a water ProjectPathPreset with the full standard layout',
          () {
        final preset = _water(frameCount: 4);

        expect(preset.id, 'standard-water');
        expect(preset.name, 'Standard Water');
        expect(preset.surfaceKind, PathSurfaceKind.water);
        expect(preset.tilesetId, 'outdoor-water');
        expect(preset.variants,
            hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
        expect(
          preset.variants.first.variant,
          standardTerrainPathVariantVerticalAtlasOrder.first,
        );
        expect(
          preset.variants.last.variant,
          standardTerrainPathVariantVerticalAtlasOrder.last,
        );
        expect(preset.variants.first.frames.first.source.x, 0);
        expect(
          preset.variants.last.frames.first.source.x,
          standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
        expect(
          preset.variants.every((mapping) => mapping.frames.length == 4),
          isTrue,
        );
      });

      test('API specialization: generated presets are always water', () {
        // This is intentionally not a "compilation test". The contract is that
        // Lot 16 does not expose a [surfaceKind] parameter, so callers cannot
        // accidentally build a different legacy surface kind while reusing the
        // same vertical atlas parameters.
        final preset = _water();

        expect(preset.surfaceKind, PathSurfaceKind.water);
      });

      test('preserves categoryId and sortOrder', () {
        final preset = _water(categoryId: 'water-category', sortOrder: 42);

        expect(preset.categoryId, 'water-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _water(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _water(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _water(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [0, 1, 2],
        );
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _water(variants: _subset, firstColumn: 20);

        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [20, 21, 22],
        );
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _water(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _water(
          tilesetId: 'main-water-tileset',
          frameTilesetId: 'animated-water-atlas',
        );

        expect(preset.tilesetId, 'main-water-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-water-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _water(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _water(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset = _water(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 100, 150],
          );
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _water(
          frameCount: 3,
          defaultDurationMs: 90,
          frameDurationsMs: [50, null, 150],
        );

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 90, 150],
          );
        }
      });
    });

    group('compatibility', () {
      test('is compatible with LegacyPathSurfaceView', () {
        final preset = _water(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-water');
        expect(view.surfaceKind, PathSurfaceKind.water);
        expect(
          view.framesForVariant(TerrainPathVariant.isolated),
          hasLength(2),
        );
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _water(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        );

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-water'), isNotNull);
        expect(
          catalog.pathSurfaceById('standard-water')?.surfaceKind,
          PathSurfaceKind.water,
        );
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _water(
          variants: [TerrainPathVariant.isolated],
          frameCount: 3,
          frameDurationsMs: [100, 100, 100],
        );

        final timeline = resolveTileVisualFrameTimeline(
          frames: preset.variants.single.frames,
          elapsedMs: 100,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(timeline.frameIndex, 1);
      });
    });

    group('validation delegation', () {
      test('delegates validation for empty id', () {
        _expectValidation(() => _water(id: ''));
        _expectValidation(() => _water(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _water(name: ''));
        _expectValidation(() => _water(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _water(tilesetId: ''));
        _expectValidation(() => _water(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _water(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _water(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _water(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _water(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _water(frameCount: 0));
        _expectValidation(() => _water(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _water(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _water(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _water(defaultDurationMs: 0));
        _expectValidation(() => _water(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _water(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _water(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _water(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _water(frameCount: 2, frameDurationsMs: [100, -50]),
        );
      });
    });
  });
}

const _subset = [
  TerrainPathVariant.isolated,
  TerrainPathVariant.horizontal,
  TerrainPathVariant.vertical,
];

ProjectPathPreset _water({
  String id = 'standard-water',
  String name = 'Standard Water',
  String tilesetId = 'outdoor-water',
  String? categoryId,
  int sortOrder = 0,
  int firstColumn = 0,
  int startRow = 0,
  List<TerrainPathVariant> variants =
      standardTerrainPathVariantVerticalAtlasOrder,
  int frameCount = 2,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String frameTilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  return createStandardWaterPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameTilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}

List<TilesetVisualFrame> _allFrames(ProjectPathPreset preset) {
  return [
    for (final mapping in preset.variants) ...mapping.frames,
  ];
}

void _expectValidation(Object? Function() callback) {
  expect(callback, throwsA(isA<ValidationException>()));
}

```

### 20.3 `map_core.dart` (fichier complet)
```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
export 'src/operations/legacy_surface_usage_view.dart';
export 'src/operations/legacy_surface_usage_diagnostics.dart';
export 'src/operations/legacy_surface_audit_report.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/collision/element_collision_legacy_migration.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
export 'src/io/legacy_editor_json_compat.dart';

```

## 21) Diff complet des fichiers créés/modifiés
### 21.1 `git diff` — `map_core.dart`
```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 6b2cfc20..6e09ce6b 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -34,6 +34,7 @@ export 'src/operations/path_variant_vertical_atlas_mapping.dart';
 export 'src/operations/path_preset_vertical_atlas_builder.dart';
 export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
 export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
+export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';

```

### 21.2 `diff -u /dev/null` — builder
```diff
--- /dev/null	2026-04-26 22:13:14
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/standard_water_path_preset_vertical_atlas_builder.dart	2026-04-26 22:10:51
@@ -0,0 +1,54 @@
+import '../models/enums.dart';
+import '../models/project_manifest.dart';
+import 'map_placed_element_animation.dart';
+import 'standard_path_preset_vertical_atlas_builder.dart';
+import 'terrain_path_variant_vertical_atlas_layout.dart';
+
+/// Builds a legacy animated **water** [ProjectPathPreset] from the standard
+/// vertical atlas layout.
+///
+/// This is a thin, product-oriented wrapper on top of Lot 15. It does not add
+/// gameplay rules, surf, encounters, collision, or rendering. The only
+/// "water" guarantee here is:
+///
+/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.water]
+///
+/// Everything else (columns, frames, tileset override semantics) is inherited
+/// from the shared vertical-atlas stack (Lots 11-15).
+ProjectPathPreset createStandardWaterPathPresetFromVerticalAtlas({
+  required String id,
+  required String name,
+  required String tilesetId,
+  String? categoryId,
+  int sortOrder = 0,
+  int firstColumn = 0,
+  int startRow = 0,
+  List<TerrainPathVariant> variants =
+      standardTerrainPathVariantVerticalAtlasOrder,
+  required int frameCount,
+  int sourceWidth = 1,
+  int sourceHeight = 1,
+  String frameTilesetId = '',
+  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
+  List<int?>? frameDurationsMs,
+}) {
+  // Deliberately no duplicated validation. Lot 15 composes Lot 14 + Lot 13 and
+  // owns the behavior contract. This function only pins surfaceKind to water.
+  return createStandardProjectPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    surfaceKind: PathSurfaceKind.water,
+    tilesetId: tilesetId,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+    firstColumn: firstColumn,
+    startRow: startRow,
+    variants: variants,
+    frameCount: frameCount,
+    sourceWidth: sourceWidth,
+    sourceHeight: sourceHeight,
+    frameTilesetId: frameTilesetId,
+    defaultDurationMs: defaultDurationMs,
+    frameDurationsMs: frameDurationsMs,
+  );
+}

```

### 21.3 `diff -u /dev/null` — test
```diff
--- /dev/null	2026-04-26 22:13:14
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart	2026-04-26 22:11:09
@@ -0,0 +1,340 @@
+// ignore_for_file: prefer_const_literals_to_create_immutables
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  // Lot 16 is a tiny specialization of Lot 15: the vertical atlas contract is
+  // unchanged, but the resulting legacy preset is always tagged as water via
+  // [PathSurfaceKind.water]. This suite mirrors the Lot 15 tests to prove the
+  // wrapper does not fork validation or frame layout semantics.
+  group('createStandardWaterPathPresetFromVerticalAtlas', () {
+    group('preset generation', () {
+      test('generates a water ProjectPathPreset with the full standard layout',
+          () {
+        final preset = _water(frameCount: 4);
+
+        expect(preset.id, 'standard-water');
+        expect(preset.name, 'Standard Water');
+        expect(preset.surfaceKind, PathSurfaceKind.water);
+        expect(preset.tilesetId, 'outdoor-water');
+        expect(preset.variants,
+            hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
+        expect(
+          preset.variants.first.variant,
+          standardTerrainPathVariantVerticalAtlasOrder.first,
+        );
+        expect(
+          preset.variants.last.variant,
+          standardTerrainPathVariantVerticalAtlasOrder.last,
+        );
+        expect(preset.variants.first.frames.first.source.x, 0);
+        expect(
+          preset.variants.last.frames.first.source.x,
+          standardTerrainPathVariantVerticalAtlasOrder.length - 1,
+        );
+        expect(
+          preset.variants.every((mapping) => mapping.frames.length == 4),
+          isTrue,
+        );
+      });
+
+      test('API specialization: generated presets are always water', () {
+        // This is intentionally not a "compilation test". The contract is that
+        // Lot 16 does not expose a [surfaceKind] parameter, so callers cannot
+        // accidentally build a different legacy surface kind while reusing the
+        // same vertical atlas parameters.
+        final preset = _water();
+
+        expect(preset.surfaceKind, PathSurfaceKind.water);
+      });
+
+      test('preserves categoryId and sortOrder', () {
+        final preset = _water(categoryId: 'water-category', sortOrder: 42);
+
+        expect(preset.categoryId, 'water-category');
+        expect(preset.sortOrder, 42);
+      });
+
+      test('respects firstColumn', () {
+        final preset = _water(firstColumn: 10);
+
+        expect(preset.variants.first.frames.first.source.x, 10);
+        expect(preset.variants[1].frames.first.source.x, 11);
+        expect(
+          preset.variants.last.frames.first.source.x,
+          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
+        );
+      });
+
+      test('respects startRow', () {
+        final preset = _water(startRow: 7, frameCount: 3);
+
+        for (final mapping in preset.variants) {
+          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
+        }
+      });
+
+      test('generates a variant sub-layout', () {
+        final preset = _water(variants: _subset);
+
+        expect(preset.variants, hasLength(3));
+        expect(preset.variants.map((mapping) => mapping.variant), _subset);
+        expect(
+          preset.variants.map((mapping) => mapping.frames.first.source.x),
+          [0, 1, 2],
+        );
+      });
+
+      test('generates a variant sub-layout with firstColumn', () {
+        final preset = _water(variants: _subset, firstColumn: 20);
+
+        expect(
+          preset.variants.map((mapping) => mapping.frames.first.source.x),
+          [20, 21, 22],
+        );
+      });
+
+      test('respects sourceWidth and sourceHeight', () {
+        final preset = _water(sourceWidth: 2, sourceHeight: 3);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.source.width, 2);
+          expect(frame.source.height, 3);
+        }
+      });
+
+      test('distinguishes preset tilesetId from frameTilesetId', () {
+        final preset = _water(
+          tilesetId: 'main-water-tileset',
+          frameTilesetId: 'animated-water-atlas',
+        );
+
+        expect(preset.tilesetId, 'main-water-tileset');
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, 'animated-water-atlas');
+        }
+      });
+
+      test('preserves empty frameTilesetId', () {
+        final preset = _water(frameTilesetId: '');
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, '');
+        }
+      });
+
+      test('applies custom common duration', () {
+        final preset = _water(defaultDurationMs: 80);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.durationMs, 80);
+        }
+      });
+
+      test('applies per-frame durations', () {
+        final preset = _water(frameCount: 3, frameDurationsMs: [50, 100, 150]);
+
+        for (final mapping in preset.variants) {
+          expect(
+            mapping.frames.map((frame) => frame.durationMs),
+            [50, 100, 150],
+          );
+        }
+      });
+
+      test('replaces null frame durations with the default duration', () {
+        final preset = _water(
+          frameCount: 3,
+          defaultDurationMs: 90,
+          frameDurationsMs: [50, null, 150],
+        );
+
+        for (final mapping in preset.variants) {
+          expect(
+            mapping.frames.map((frame) => frame.durationMs),
+            [50, 90, 150],
+          );
+        }
+      });
+    });
+
+    group('compatibility', () {
+      test('is compatible with LegacyPathSurfaceView', () {
+        final preset = _water(variants: [TerrainPathVariant.isolated]);
+
+        final view = createLegacyPathSurfaceView(preset);
+
+        expect(view.id, 'standard-water');
+        expect(view.surfaceKind, PathSurfaceKind.water);
+        expect(
+          view.framesForVariant(TerrainPathVariant.isolated),
+          hasLength(2),
+        );
+      });
+
+      test('is compatible with LegacyProjectSurfaceCatalogView', () {
+        final preset = _water(variants: [TerrainPathVariant.isolated]);
+        final manifest = ProjectManifest(
+          name: 'Test Project',
+          maps: [],
+          tilesets: [],
+          pathPresets: [preset],
+        );
+
+        final catalog = createLegacyProjectSurfaceCatalogView(manifest);
+
+        expect(catalog.pathSurfaces, hasLength(1));
+        expect(catalog.pathSurfaceById('standard-water'), isNotNull);
+        expect(
+          catalog.pathSurfaceById('standard-water')?.surfaceKind,
+          PathSurfaceKind.water,
+        );
+      });
+
+      test('is compatible with resolveTileVisualFrameTimeline', () {
+        final preset = _water(
+          variants: [TerrainPathVariant.isolated],
+          frameCount: 3,
+          frameDurationsMs: [100, 100, 100],
+        );
+
+        final timeline = resolveTileVisualFrameTimeline(
+          frames: preset.variants.single.frames,
+          elapsedMs: 100,
+          mode: TileVisualFrameTimelinePlaybackMode.loop,
+        );
+
+        expect(timeline.frameIndex, 1);
+      });
+    });
+
+    group('validation delegation', () {
+      test('delegates validation for empty id', () {
+        _expectValidation(() => _water(id: ''));
+        _expectValidation(() => _water(id: '   '));
+      });
+
+      test('delegates validation for empty name', () {
+        _expectValidation(() => _water(name: ''));
+        _expectValidation(() => _water(name: '   '));
+      });
+
+      test('delegates validation for empty tilesetId', () {
+        _expectValidation(() => _water(tilesetId: ''));
+        _expectValidation(() => _water(tilesetId: '   '));
+      });
+
+      test('delegates validation for negative firstColumn', () {
+        _expectValidation(() => _water(firstColumn: -1));
+      });
+
+      test('delegates validation for negative startRow', () {
+        _expectValidation(() => _water(startRow: -1));
+      });
+
+      test('delegates validation for empty variants', () {
+        _expectValidation(() => _water(variants: []));
+      });
+
+      test('delegates validation for duplicate variants', () {
+        _expectValidation(
+          () => _water(
+            variants: [
+              TerrainPathVariant.isolated,
+              TerrainPathVariant.isolated,
+            ],
+          ),
+        );
+      });
+
+      test('delegates validation for invalid frameCount', () {
+        _expectValidation(() => _water(frameCount: 0));
+        _expectValidation(() => _water(frameCount: -1));
+      });
+
+      test('delegates validation for invalid source dimensions', () {
+        for (final sourceWidth in [0, -1]) {
+          _expectValidation(() => _water(sourceWidth: sourceWidth));
+        }
+        for (final sourceHeight in [0, -1]) {
+          _expectValidation(() => _water(sourceHeight: sourceHeight));
+        }
+      });
+
+      test('delegates validation for invalid defaultDurationMs', () {
+        _expectValidation(() => _water(defaultDurationMs: 0));
+        _expectValidation(() => _water(defaultDurationMs: -10));
+      });
+
+      test('delegates validation for frameDurationsMs length mismatch', () {
+        _expectValidation(
+          () => _water(frameCount: 3, frameDurationsMs: [100, 100]),
+        );
+        _expectValidation(
+          () => _water(frameCount: 2, frameDurationsMs: [100, 100, 100]),
+        );
+      });
+
+      test('delegates validation for non-positive frame durations', () {
+        _expectValidation(
+          () => _water(frameCount: 2, frameDurationsMs: [100, 0]),
+        );
+        _expectValidation(
+          () => _water(frameCount: 2, frameDurationsMs: [100, -50]),
+        );
+      });
+    });
+  });
+}
+
+const _subset = [
+  TerrainPathVariant.isolated,
+  TerrainPathVariant.horizontal,
+  TerrainPathVariant.vertical,
+];
+
+ProjectPathPreset _water({
+  String id = 'standard-water',
+  String name = 'Standard Water',
+  String tilesetId = 'outdoor-water',
+  String? categoryId,
+  int sortOrder = 0,
+  int firstColumn = 0,
+  int startRow = 0,
+  List<TerrainPathVariant> variants =
+      standardTerrainPathVariantVerticalAtlasOrder,
+  int frameCount = 2,
+  int sourceWidth = 1,
+  int sourceHeight = 1,
+  String frameTilesetId = '',
+  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
+  List<int?>? frameDurationsMs,
+}) {
+  return createStandardWaterPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+    firstColumn: firstColumn,
+    startRow: startRow,
+    variants: variants,
+    frameCount: frameCount,
+    sourceWidth: sourceWidth,
+    sourceHeight: sourceHeight,
+    frameTilesetId: frameTilesetId,
+    defaultDurationMs: defaultDurationMs,
+    frameDurationsMs: frameDurationsMs,
+  );
+}
+
+List<TilesetVisualFrame> _allFrames(ProjectPathPreset preset) {
+  return [
+    for (final mapping in preset.variants) ...mapping.frames,
+  ];
+}
+
+void _expectValidation(Object? Function() callback) {
+  expect(callback, throwsA(isA<ValidationException>()));
+}

```
