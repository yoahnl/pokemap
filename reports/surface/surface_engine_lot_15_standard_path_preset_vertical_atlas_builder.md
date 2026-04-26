# Surface Engine - Lot 15 - Standard Path Preset Vertical Atlas Builder V0

## 1. Résumé exécutif

Le Lot 15 ajoute une primitive pure `createStandardProjectPathPresetFromVerticalAtlas(...)` dans `map_core`. Elle compose le layout standard V0 du Lot 14 avec le builder legacy `ProjectPathPreset` du Lot 13 afin de générer un preset path complet sans fournir manuellement les `PathVariantVerticalAtlasColumn`.

Le scope reste strict : aucun modèle Surface persistant, aucun JSON custom, aucun Freezed, aucun fichier généré, aucun runtime/editor/gameplay, aucune modification des APIs Lots 11-14.

## 2. Pourquoi ce lot est nécessaire après le Lot 14

Le Lot 14 produit un layout standard `TerrainPathVariant -> column`, mais ne produit pas de preset. Le Lot 13 produit un `ProjectPathPreset`, mais demande des colonnes explicites. Le Lot 15 est la composition minimale entre ces deux primitives pour couvrir le cas courant des atlas verticaux standards.

## 3. Lien avec les atlas animés verticaux type Pokémon SDK

La convention reste : colonne = variante visuelle/autotile, ligne = frame d'animation. Ce lot facilite l'auteurisation d'un atlas vertical standard où les variantes path suivent l'ordre V0 explicite, tout en gardant les frames compatibles avec `resolveTileVisualFrameTimeline(...)`.

## 4. Fichiers consultés

- `codex_rule.md`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/operations/terrain_path_variant_vertical_atlas_layout.dart`
- `packages/map_core/lib/src/operations/path_preset_vertical_atlas_builder.dart`
- `packages/map_core/lib/src/operations/path_variant_vertical_atlas_mapping.dart`
- `packages/map_core/lib/src/operations/tile_visual_frame_vertical_atlas.dart`
- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`
- `packages/map_core/lib/src/operations/legacy_project_surface_catalog_view.dart`
- `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/terrain_path_variant_vertical_atlas_layout_test.dart`
- `packages/map_core/test/path_preset_vertical_atlas_builder_test.dart`
- `packages/map_core/test/path_variant_vertical_atlas_mapping_test.dart`
- `packages/map_core/test/tile_visual_frame_vertical_atlas_test.dart`
- `packages/map_core/test/legacy_path_surface_view_test.dart`
- `packages/map_core/test/legacy_project_surface_catalog_view_test.dart`

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart`
- `packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart`
- `reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md`

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` : ajout unique de l'export public du helper Lot 15.

## 7. API ajoutée

```dart
ProjectPathPreset createStandardProjectPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required PathSurfaceKind surfaceKind,
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

## 8. Sémantique du helper

Le helper appelle d'abord `createStandardTerrainPathVariantVerticalAtlasColumns(...)` avec `firstColumn`, `startRow` et `variants`. Il passe ensuite les colonnes à `createProjectPathPresetFromVerticalAtlas(...)` avec les métadonnées du preset et les paramètres de frames.

La distinction reste explicite : `ProjectPathPreset.tilesetId` reçoit `tilesetId`, tandis que chaque `TilesetVisualFrame.tilesetId` reçoit `frameTilesetId`.

L'ordre n'est jamais trié : l'ordre standard est utilisé par défaut, ou l'ordre du sous-layout fourni est conservé.

## 9. Liste complète des cas testés

1. Génère un `ProjectPathPreset` water avec le layout standard complet.
2. Génère un `ProjectPathPreset` tallGrass.
3. Préserve `categoryId` et `sortOrder`.
4. Respecte `firstColumn`.
5. Respecte `startRow`.
6. Génère un sous-layout de variants.
7. Génère un sous-layout avec `firstColumn`.
8. Respecte `sourceWidth` et `sourceHeight`.
9. Distingue `tilesetId` du preset et `frameTilesetId`.
10. Préserve `frameTilesetId` vide.
11. Applique une durée commune personnalisée.
12. Applique les durées par frame.
13. Remplace les durées null par la durée par défaut.
14. Compatibilité `LegacyPathSurfaceView`.
15. Compatibilité `LegacyProjectSurfaceCatalogView`.
16. Compatibilité `resolveTileVisualFrameTimeline(...)`.
17. Délègue la validation `id` vide.
18. Délègue la validation `name` vide.
19. Délègue la validation `tilesetId` vide.
20. Délègue la validation `firstColumn` négatif.
21. Délègue la validation `startRow` négatif.
22. Délègue la validation `variants` vide.
23. Délègue la validation variants dupliqués.
24. Délègue la validation `frameCount`.
25. Délègue la validation `sourceWidth` / `sourceHeight`.
26. Délègue la validation `defaultDurationMs`.
27. Délègue la validation longueur de `frameDurationsMs`.
28. Délègue la validation durées non positives.

## 10. Ce que les tests prouvent

Les tests prouvent que l'API compose correctement les Lots 14 et 13, conserve les métadonnées legacy, respecte l'ordre standard ou custom, garde la séparation preset tileset / frame tileset, supporte les durées communes et par frame, et reste compatible avec les vues legacy et le resolver de timeline.

## 11. Ce qui n'a volontairement pas été fait

- Aucun `SurfaceDefinition`.
- Aucun `SurfaceEngine`.
- Aucune vue Surface unifiée.
- Aucun champ ajouté à `ProjectManifest`.
- Aucun modèle Freezed/JSON modifié.
- Aucun fichier `.g.dart` ou `.freezed.dart` modifié.
- Aucun branchement runtime/editor/gameplay.
- Aucune validation contre une image ou un tileset chargé.
- Aucune résolution temporelle dans le builder.
- Aucun mapping automatique spécifique à l'eau.

## 12. Impact pour les futurs modèles Surface / Tile Animation Engine

Ce helper fournit une primitive de migration/auteurisation stable : les futurs modèles Surface pourront comparer ou générer des presets legacy standards sans connaître les détails de colonnes. Le Tile Animation Engine pourra continuer à consommer les `TilesetVisualFrame` existants, car la timeline reste indépendante du builder.

## 13. Points de vigilance

- Si `TerrainPathVariant` évolue, le Lot 14 doit être revu pour décider de l'ordre standard V0/VNext.
- Ce helper ne garantit pas qu'un atlas réel possède les colonnes ou lignes demandées.
- Les comportements métier différents entre eau, tall grass, lave, glace, etc. restent hors scope.
- `frameTilesetId == ''` garde la convention legacy : pas d'override frame.

## 14. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart format lib/src/operations/standard_path_preset_vertical_atlas_builder.dart test/standard_path_preset_vertical_atlas_builder_test.dart lib/map_core.dart
/opt/homebrew/bin/dart test test/standard_path_preset_vertical_atlas_builder_test.dart
/opt/homebrew/bin/dart test test/terrain_path_variant_vertical_atlas_layout_test.dart
/opt/homebrew/bin/dart test test/path_preset_vertical_atlas_builder_test.dart
/opt/homebrew/bin/dart test test/path_variant_vertical_atlas_mapping_test.dart
/opt/homebrew/bin/dart test test/tile_visual_frame_vertical_atlas_test.dart
/opt/homebrew/bin/dart test
/opt/homebrew/bin/dart analyze lib/src/operations/standard_path_preset_vertical_atlas_builder.dart test/standard_path_preset_vertical_atlas_builder_test.dart lib/map_core.dart
```

## 15. Résultats exacts des tests

```text
00:00 +28: All tests passed!
00:00 +14: All tests passed!
00:00 +34: All tests passed!
00:00 +28: All tests passed!
00:00 +23: All tests passed!
00:01 +412: All tests passed!
```

Analyse ciblée :

```text
Analyzing standard_path_preset_vertical_atlas_builder.dart, standard_path_preset_vertical_atlas_builder_test.dart, map_core.dart...
No issues found!
```

## 16. Total exact du dart test complet

```text
00:01 +412: All tests passed!
```

## 17. Autocritique finale

Le helper est volontairement très petit. C'est correct pour ce lot : il compose deux primitives existantes sans réimplémenter leurs validations. Le principal risque restant est documentaire : si un futur lot modifie l'ordre standard, il faudra choisir explicitement entre versionner le helper ou faire évoluer le layout V0.

## 18. Ce que le prompt semble discutable ou incomplet

Le prompt contient une contradiction contextuelle : il interdit `git commit` et `git push`, mais la demande utilisateur actuelle corrige explicitement la suppression précédente et demande de commit/push. L'interprétation appliquée est : respecter l'interdiction pendant l'implémentation et les validations, puis utiliser `git add`, `git commit` et `git push` uniquement pour l'action finale explicitement demandée.

## 19. Auto-review indépendante

- Est-ce que le lot est resté strictement limité à un standard path preset builder ? Oui.
- Est-ce qu'aucun modèle Surface persistant n'a été créé ? Oui.
- Est-ce qu'aucun modèle Freezed/JSON n'a été modifié ? Oui.
- Est-ce qu'aucun fichier generated n'a été modifié ? Oui.
- Est-ce qu'aucun runtime/editor/gameplay n'a été modifié ? Oui.
- Est-ce que le helper compose bien les helpers Lots 14 et 13 ? Oui.
- Est-ce que le helper ne duplique pas inutilement les validations ? Oui.
- Est-ce que `tilesetId` et `frameTilesetId` sont bien distingués ? Oui.
- Est-ce que l'ordre standard et les sous-layouts sont préservés ? Oui.
- Est-ce que les validations sont strictes et testées ? Oui, via délégation testée.
- Est-ce que le preset généré est compatible avec `LegacyPathSurfaceView` ? Oui.
- Est-ce que le preset généré est compatible avec `LegacyProjectSurfaceCatalogView` ? Oui.
- Est-ce que les frames générées restent compatibles avec `resolveTileVisualFrameTimeline` ? Oui.
- Est-ce que les tests des lots précédents passent toujours ? Oui.
- Est-ce que `map_core` complet passe avec un total exact documenté ? Oui, `+412`.
- Est-ce que les contenus complets et diffs complets sont fournis ? Oui, dans ce rapport.
- Est-ce que les commandes Git interdites n'ont pas été utilisées ? Pendant l'implémentation oui ; `git add`, `git commit` et `git push` seront utilisés seulement ensuite, car l'utilisateur l'a explicitement demandé.

## 20. Contenu complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart`

```dart
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy [ProjectPathPreset] from the standard vertical atlas layout.
///
/// This is the thin composition layer for Lot 15:
///
/// 1. Lot 14 creates the standard [TerrainPathVariant] -> column layout.
/// 2. Lot 13 turns those columns into a complete legacy [ProjectPathPreset].
///
/// The helper deliberately stays boring and explicit. It does not duplicate the
/// validations owned by Lot 14 or Lot 13, and it does not introduce a new
/// persistent Surface model. It only removes repetitive boilerplate for the
/// common case where an atlas follows the standard V0 column order.
ProjectPathPreset createStandardProjectPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required PathSurfaceKind surfaceKind,
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
  // Lot 14 owns layout validation: firstColumn/startRow bounds, non-empty
  // variant lists, and duplicate variant detection. Keeping that validation in
  // one place avoids this standard preset helper drifting from the layout helper.
  final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
    firstColumn: firstColumn,
    startRow: startRow,
    variants: variants,
  );

  // Lot 13 owns preset/frame validation and the important tileset distinction:
  // tilesetId is stored on ProjectPathPreset, while frameTilesetId is propagated
  // to each TilesetVisualFrame. This helper only forwards the caller intent.
  return createProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    columns: columns,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameTilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}
```

### `packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart`

```dart
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  // Lot 15 is intentionally a composition primitive: Lot 14 owns the standard
  // V0 TerrainPathVariant column layout, while Lot 13 owns the legacy
  // ProjectPathPreset builder. These tests prove that the composition preserves
  // both contracts without adding persistent Surface JSON or runtime/editor
  // behavior.
  group('createStandardProjectPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test('generates a water ProjectPathPreset with the full standard layout',
          () {
        final preset = _preset(frameCount: 4);

        expect(preset.id, 'standard-water');
        expect(preset.name, 'Standard Water');
        expect(preset.surfaceKind, PathSurfaceKind.water);
        expect(preset.tilesetId, 'outdoor-water');
        expect(preset.variants,
            hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
        expect(preset.variants.first.variant,
            standardTerrainPathVariantVerticalAtlasOrder.first);
        expect(preset.variants.last.variant,
            standardTerrainPathVariantVerticalAtlasOrder.last);
        expect(preset.variants.first.frames.first.source.x, 0);
        expect(
          preset.variants.last.frames.first.source.x,
          standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
        expect(preset.variants.every((mapping) => mapping.frames.length == 4),
            isTrue);
      });

      test('generates a tallGrass ProjectPathPreset', () {
        final preset = _preset(surfaceKind: PathSurfaceKind.tallGrass);

        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
      });

      test('preserves categoryId and sortOrder', () {
        final preset = _preset(categoryId: 'water-category', sortOrder: 42);

        expect(preset.categoryId, 'water-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _preset(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _preset(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _preset(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(preset.variants.map((mapping) => mapping.frames.first.source.x),
            [0, 1, 2]);
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _preset(variants: _subset, firstColumn: 20);

        expect(preset.variants.map((mapping) => mapping.frames.first.source.x),
            [20, 21, 22]);
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _preset(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _preset(
          tilesetId: 'main-water-tileset',
          frameTilesetId: 'animated-water-atlas',
        );

        expect(preset.tilesetId, 'main-water-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-water-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _preset(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _preset(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset = _preset(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
              mapping.frames.map((frame) => frame.durationMs), [50, 100, 150]);
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _preset(
          frameCount: 3,
          defaultDurationMs: 90,
          frameDurationsMs: [50, null, 150],
        );

        for (final mapping in preset.variants) {
          expect(
              mapping.frames.map((frame) => frame.durationMs), [50, 90, 150]);
        }
      });
    });

    group('compatibility', () {
      test('is compatible with LegacyPathSurfaceView', () {
        final preset = _preset(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-water');
        expect(view.surfaceKind, PathSurfaceKind.water);
        expect(
            view.framesForVariant(TerrainPathVariant.isolated), hasLength(2));
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _preset(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        );

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-water'), isNotNull);
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _preset(
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
        _expectValidation(() => _preset(id: ''));
        _expectValidation(() => _preset(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _preset(name: ''));
        _expectValidation(() => _preset(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _preset(tilesetId: ''));
        _expectValidation(() => _preset(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _preset(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _preset(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _preset(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _preset(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _preset(frameCount: 0));
        _expectValidation(() => _preset(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _preset(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _preset(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _preset(defaultDurationMs: 0));
        _expectValidation(() => _preset(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _preset(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _preset(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _preset(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _preset(frameCount: 2, frameDurationsMs: [100, -50]),
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

ProjectPathPreset _preset({
  String id = 'standard-water',
  String name = 'Standard Water',
  PathSurfaceKind surfaceKind = PathSurfaceKind.water,
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
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
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

### `packages/map_core/lib/map_core.dart`

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

## 21. Diff complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart b/packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
new file mode 100644
index 00000000..40e80163
--- /dev/null
+++ b/packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
@@ -0,0 +1,63 @@
+import '../models/enums.dart';
+import '../models/project_manifest.dart';
+import 'map_placed_element_animation.dart';
+import 'path_preset_vertical_atlas_builder.dart';
+import 'terrain_path_variant_vertical_atlas_layout.dart';
+
+/// Builds a legacy [ProjectPathPreset] from the standard vertical atlas layout.
+///
+/// This is the thin composition layer for Lot 15:
+///
+/// 1. Lot 14 creates the standard [TerrainPathVariant] -> column layout.
+/// 2. Lot 13 turns those columns into a complete legacy [ProjectPathPreset].
+///
+/// The helper deliberately stays boring and explicit. It does not duplicate the
+/// validations owned by Lot 14 or Lot 13, and it does not introduce a new
+/// persistent Surface model. It only removes repetitive boilerplate for the
+/// common case where an atlas follows the standard V0 column order.
+ProjectPathPreset createStandardProjectPathPresetFromVerticalAtlas({
+  required String id,
+  required String name,
+  required PathSurfaceKind surfaceKind,
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
+  // Lot 14 owns layout validation: firstColumn/startRow bounds, non-empty
+  // variant lists, and duplicate variant detection. Keeping that validation in
+  // one place avoids this standard preset helper drifting from the layout helper.
+  final columns = createStandardTerrainPathVariantVerticalAtlasColumns(
+    firstColumn: firstColumn,
+    startRow: startRow,
+    variants: variants,
+  );
+
+  // Lot 13 owns preset/frame validation and the important tileset distinction:
+  // tilesetId is stored on ProjectPathPreset, while frameTilesetId is propagated
+  // to each TilesetVisualFrame. This helper only forwards the caller intent.
+  return createProjectPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    surfaceKind: surfaceKind,
+    tilesetId: tilesetId,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+    columns: columns,
+    frameCount: frameCount,
+    sourceWidth: sourceWidth,
+    sourceHeight: sourceHeight,
+    frameTilesetId: frameTilesetId,
+    defaultDurationMs: defaultDurationMs,
+    frameDurationsMs: frameDurationsMs,
+  );
+}
```

### `packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart`

```diff
diff --git a/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
new file mode 100644
index 00000000..b2c99cfb
--- /dev/null
+++ b/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
@@ -0,0 +1,319 @@
+// ignore_for_file: prefer_const_literals_to_create_immutables
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  // Lot 15 is intentionally a composition primitive: Lot 14 owns the standard
+  // V0 TerrainPathVariant column layout, while Lot 13 owns the legacy
+  // ProjectPathPreset builder. These tests prove that the composition preserves
+  // both contracts without adding persistent Surface JSON or runtime/editor
+  // behavior.
+  group('createStandardProjectPathPresetFromVerticalAtlas', () {
+    group('preset generation', () {
+      test('generates a water ProjectPathPreset with the full standard layout',
+          () {
+        final preset = _preset(frameCount: 4);
+
+        expect(preset.id, 'standard-water');
+        expect(preset.name, 'Standard Water');
+        expect(preset.surfaceKind, PathSurfaceKind.water);
+        expect(preset.tilesetId, 'outdoor-water');
+        expect(preset.variants,
+            hasLength(standardTerrainPathVariantVerticalAtlasOrder.length));
+        expect(preset.variants.first.variant,
+            standardTerrainPathVariantVerticalAtlasOrder.first);
+        expect(preset.variants.last.variant,
+            standardTerrainPathVariantVerticalAtlasOrder.last);
+        expect(preset.variants.first.frames.first.source.x, 0);
+        expect(
+          preset.variants.last.frames.first.source.x,
+          standardTerrainPathVariantVerticalAtlasOrder.length - 1,
+        );
+        expect(preset.variants.every((mapping) => mapping.frames.length == 4),
+            isTrue);
+      });
+
+      test('generates a tallGrass ProjectPathPreset', () {
+        final preset = _preset(surfaceKind: PathSurfaceKind.tallGrass);
+
+        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
+      });
+
+      test('preserves categoryId and sortOrder', () {
+        final preset = _preset(categoryId: 'water-category', sortOrder: 42);
+
+        expect(preset.categoryId, 'water-category');
+        expect(preset.sortOrder, 42);
+      });
+
+      test('respects firstColumn', () {
+        final preset = _preset(firstColumn: 10);
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
+        final preset = _preset(startRow: 7, frameCount: 3);
+
+        for (final mapping in preset.variants) {
+          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
+        }
+      });
+
+      test('generates a variant sub-layout', () {
+        final preset = _preset(variants: _subset);
+
+        expect(preset.variants, hasLength(3));
+        expect(preset.variants.map((mapping) => mapping.variant), _subset);
+        expect(preset.variants.map((mapping) => mapping.frames.first.source.x),
+            [0, 1, 2]);
+      });
+
+      test('generates a variant sub-layout with firstColumn', () {
+        final preset = _preset(variants: _subset, firstColumn: 20);
+
+        expect(preset.variants.map((mapping) => mapping.frames.first.source.x),
+            [20, 21, 22]);
+      });
+
+      test('respects sourceWidth and sourceHeight', () {
+        final preset = _preset(sourceWidth: 2, sourceHeight: 3);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.source.width, 2);
+          expect(frame.source.height, 3);
+        }
+      });
+
+      test('distinguishes preset tilesetId from frameTilesetId', () {
+        final preset = _preset(
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
+        final preset = _preset(frameTilesetId: '');
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, '');
+        }
+      });
+
+      test('applies custom common duration', () {
+        final preset = _preset(defaultDurationMs: 80);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.durationMs, 80);
+        }
+      });
+
+      test('applies per-frame durations', () {
+        final preset = _preset(frameCount: 3, frameDurationsMs: [50, 100, 150]);
+
+        for (final mapping in preset.variants) {
+          expect(
+              mapping.frames.map((frame) => frame.durationMs), [50, 100, 150]);
+        }
+      });
+
+      test('replaces null frame durations with the default duration', () {
+        final preset = _preset(
+          frameCount: 3,
+          defaultDurationMs: 90,
+          frameDurationsMs: [50, null, 150],
+        );
+
+        for (final mapping in preset.variants) {
+          expect(
+              mapping.frames.map((frame) => frame.durationMs), [50, 90, 150]);
+        }
+      });
+    });
+
+    group('compatibility', () {
+      test('is compatible with LegacyPathSurfaceView', () {
+        final preset = _preset(variants: [TerrainPathVariant.isolated]);
+
+        final view = createLegacyPathSurfaceView(preset);
+
+        expect(view.id, 'standard-water');
+        expect(view.surfaceKind, PathSurfaceKind.water);
+        expect(
+            view.framesForVariant(TerrainPathVariant.isolated), hasLength(2));
+      });
+
+      test('is compatible with LegacyProjectSurfaceCatalogView', () {
+        final preset = _preset(variants: [TerrainPathVariant.isolated]);
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
+      });
+
+      test('is compatible with resolveTileVisualFrameTimeline', () {
+        final preset = _preset(
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
+        _expectValidation(() => _preset(id: ''));
+        _expectValidation(() => _preset(id: '   '));
+      });
+
+      test('delegates validation for empty name', () {
+        _expectValidation(() => _preset(name: ''));
+        _expectValidation(() => _preset(name: '   '));
+      });
+
+      test('delegates validation for empty tilesetId', () {
+        _expectValidation(() => _preset(tilesetId: ''));
+        _expectValidation(() => _preset(tilesetId: '   '));
+      });
+
+      test('delegates validation for negative firstColumn', () {
+        _expectValidation(() => _preset(firstColumn: -1));
+      });
+
+      test('delegates validation for negative startRow', () {
+        _expectValidation(() => _preset(startRow: -1));
+      });
+
+      test('delegates validation for empty variants', () {
+        _expectValidation(() => _preset(variants: []));
+      });
+
+      test('delegates validation for duplicate variants', () {
+        _expectValidation(
+          () => _preset(
+            variants: [
+              TerrainPathVariant.isolated,
+              TerrainPathVariant.isolated,
+            ],
+          ),
+        );
+      });
+
+      test('delegates validation for invalid frameCount', () {
+        _expectValidation(() => _preset(frameCount: 0));
+        _expectValidation(() => _preset(frameCount: -1));
+      });
+
+      test('delegates validation for invalid source dimensions', () {
+        for (final sourceWidth in [0, -1]) {
+          _expectValidation(() => _preset(sourceWidth: sourceWidth));
+        }
+        for (final sourceHeight in [0, -1]) {
+          _expectValidation(() => _preset(sourceHeight: sourceHeight));
+        }
+      });
+
+      test('delegates validation for invalid defaultDurationMs', () {
+        _expectValidation(() => _preset(defaultDurationMs: 0));
+        _expectValidation(() => _preset(defaultDurationMs: -10));
+      });
+
+      test('delegates validation for frameDurationsMs length mismatch', () {
+        _expectValidation(
+          () => _preset(frameCount: 3, frameDurationsMs: [100, 100]),
+        );
+        _expectValidation(
+          () => _preset(frameCount: 2, frameDurationsMs: [100, 100, 100]),
+        );
+      });
+
+      test('delegates validation for non-positive frame durations', () {
+        _expectValidation(
+          () => _preset(frameCount: 2, frameDurationsMs: [100, 0]),
+        );
+        _expectValidation(
+          () => _preset(frameCount: 2, frameDurationsMs: [100, -50]),
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
+ProjectPathPreset _preset({
+  String id = 'standard-water',
+  String name = 'Standard Water',
+  PathSurfaceKind surfaceKind = PathSurfaceKind.water,
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
+  return createStandardProjectPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    surfaceKind: surfaceKind,
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

### `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 1ebfa8a9..6b2cfc20 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -33,6 +33,7 @@ export 'src/operations/tile_visual_frame_vertical_atlas.dart';
 export 'src/operations/path_variant_vertical_atlas_mapping.dart';
 export 'src/operations/path_preset_vertical_atlas_builder.dart';
 export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
+export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

## État Git observé pendant le rapport

```text
M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
```

Diff stat hors fichiers non suivis :

```text
packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```
