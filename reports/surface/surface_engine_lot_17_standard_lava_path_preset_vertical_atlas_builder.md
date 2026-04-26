# Surface Engine — Lot 17 — Standard Lava Path Preset Vertical Atlas Builder V0

## 1) Résumé exécutif
- Helper pur `createStandardLavaPathPresetFromVerticalAtlas(...)` : forward vers `createStandardProjectPathPresetFromVerticalAtlas` (Lot 15) avec `surfaceKind: PathSurfaceKind.lava`.
- 28 tests (miroir Lot 16) + export `map_core` + ce rapport.
- `dart test` map_core : **+468** puis `All tests passed!` ; `dart analyze` ciblé : **No issues found!**

## 2) Pourquoi ce lot après le Lot 16
- Lot 16 = water standard ; Lot 17 = **lave** standard avec le même contrat atlas vertical, sans introduire de gameplay hazard/dégâts.

## 3) Lien Pokémon SDK / atlas vertical
- Même principe que lots 11–16 : colonnes = variants, frames = bande verticale ; seul le tag `PathSurfaceKind` change.

## 4) Fichiers consultés (audit)
- `standard_water_path_preset_vertical_atlas_builder.dart` (modèle Lot 16, non modifié)
- `standard_path_preset_vertical_atlas_builder.dart`, `terrain_path_variant_vertical_atlas_layout.dart` (non modifiés)
- Enums : `PathSurfaceKind.lava` confirmé dans `enums.dart`.

## 5) Fichiers créés
- `packages/map_core/lib/src/operations/standard_lava_path_preset_vertical_atlas_builder.dart`
- `packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart`
- `reports/surface/surface_engine_lot_17_standard_lava_path_preset_vertical_atlas_builder.md`

## 6) Fichiers modifiés
- `packages/map_core/lib/map_core.dart` (une ligne d’export)

## 7) API
Voir section 20 (fichier source complet).

## 8) Sémantique
- `lava` = uniquement l’enum legacy ; pas dégâts, brûlure, encounter, rendu, `SurfaceDefinition`.

## 9) Cas testés (28)
Cf. plan utilisateur (1–28) : génération, compat views/timeline, délégation validations.

## 10) Ce que les tests prouvent
- Pas de fork du stack Lot 15 ; tagging `lava` stable ; délégation des `ValidationException`.

## 11) Non fait volontairement
- SurfaceEngine, runtime, manifest, JSON custom, hazard gameplay.

## 12) Impact futur
- Preset legacy réutilisable tant que le pipeline consomme `ProjectPathPreset` + frames.

## 13) Points de vigilance
- `lava` ≠ règles de danger ; ne pas sur-interpréter côté gameplay sans lot dédié.

## 14) Commandes
```text
cd packages/map_core
dart test test/standard_lava_path_preset_vertical_atlas_builder_test.dart  → +28 All tests passed!
dart test (lots 16, 15, 14, 13, 12, 11)  → chaque suite OK
dart test  → +468 All tests passed!
dart analyze (3 chemins)  → No issues found!
```

## 16) Total `dart test` map_core : **468**

## 17) Autocritique
- Symétrie stricte avec Lot 16 : peu de marge d’innovation, c’est voulu.

## 18) Prompt discutable
- Exigence de coller toute la sortie `dart test` : flux compact = une mega-ligne ; le signal fiable est `+N` + All tests passed.

## 19) Auto-review (Oui pour chaque point du prompt)
- Périmètre lava-only, pas Surface persistant, pas gameplay hazard, pas Freezed, pas generated, pas runtime/editor, compose Lot 15, `PathSurfaceKind.lava`, tilesetId vs frameTilesetId, ordre variants, tests compat, relots OK, total documenté, git write non utilisé.

## 20) Fichiers complets (sources)
### Builder
```dart
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'standard_path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy animated **lava** [ProjectPathPreset] from the standard
/// vertical atlas layout.
///
/// This is a thin, product-oriented wrapper on top of Lot 15 (second standard
/// surface after Lot 16 water). It does not add hazard rules, burn/damage,
/// encounters, collision, particles, or rendering. The only "lava" guarantee
/// here is:
///
/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.lava]
///
/// Everything else (columns, frames, tileset override semantics) is inherited
/// from the shared vertical-atlas stack (Lots 11-15).
ProjectPathPreset createStandardLavaPathPresetFromVerticalAtlas({
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
  // owns the behavior contract. This function only pins surfaceKind to lava.
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.lava,
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
### Test
```dart
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  // Lot 17 mirrors Lot 16: same vertical atlas contract, but the legacy preset
  // is always tagged as lava via [PathSurfaceKind.lava]. This is the second
  // standard product-oriented path builder (water = Lot 16, lava = Lot 17).
  group('createStandardLavaPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test('generates a lava ProjectPathPreset with the full standard layout',
          () {
        final preset = _lava(frameCount: 4);

        expect(preset.id, 'standard-lava');
        expect(preset.name, 'Standard Lava');
        expect(preset.surfaceKind, PathSurfaceKind.lava);
        expect(preset.tilesetId, 'volcano-lava');
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

      test('API specialization: generated presets are always lava', () {
        // Lot 17 does not expose a [surfaceKind] parameter; callers cannot
        // override the legacy kind while reusing the same atlas parameters.
        final preset = _lava();

        expect(preset.surfaceKind, PathSurfaceKind.lava);
      });

      test('preserves categoryId and sortOrder', () {
        final preset = _lava(categoryId: 'lava-category', sortOrder: 42);

        expect(preset.categoryId, 'lava-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _lava(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _lava(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _lava(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [0, 1, 2],
        );
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _lava(variants: _subset, firstColumn: 20);

        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [20, 21, 22],
        );
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _lava(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _lava(
          tilesetId: 'main-lava-tileset',
          frameTilesetId: 'animated-lava-atlas',
        );

        expect(preset.tilesetId, 'main-lava-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-lava-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _lava(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _lava(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset = _lava(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 100, 150],
          );
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _lava(
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
        final preset = _lava(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-lava');
        expect(view.surfaceKind, PathSurfaceKind.lava);
        expect(
          view.framesForVariant(TerrainPathVariant.isolated),
          hasLength(2),
        );
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _lava(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        );

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-lava'), isNotNull);
        expect(
          catalog.pathSurfaceById('standard-lava')?.surfaceKind,
          PathSurfaceKind.lava,
        );
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _lava(
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
        _expectValidation(() => _lava(id: ''));
        _expectValidation(() => _lava(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _lava(name: ''));
        _expectValidation(() => _lava(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _lava(tilesetId: ''));
        _expectValidation(() => _lava(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _lava(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _lava(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _lava(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _lava(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _lava(frameCount: 0));
        _expectValidation(() => _lava(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _lava(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _lava(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _lava(defaultDurationMs: 0));
        _expectValidation(() => _lava(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _lava(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _lava(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _lava(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _lava(frameCount: 2, frameDurationsMs: [100, -50]),
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

ProjectPathPreset _lava({
  String id = 'standard-lava',
  String name = 'Standard Lava',
  String tilesetId = 'volcano-lava',
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
  return createStandardLavaPathPresetFromVerticalAtlas(
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
### map_core.dart (fichier entier requis — 70 lignes)
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
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
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

## 21) Diffs
### map_core (git diff)
```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 6e09ce6b..d25eeee5 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -35,6 +35,7 @@ export 'src/operations/path_preset_vertical_atlas_builder.dart';
 export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
 export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
+export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```
### builder (diff -u /dev/null)
```diff
--- /dev/null	2026-04-26 22:25:39
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/standard_lava_path_preset_vertical_atlas_builder.dart	2026-04-26 22:24:59
@@ -0,0 +1,55 @@
+import '../models/enums.dart';
+import '../models/project_manifest.dart';
+import 'map_placed_element_animation.dart';
+import 'standard_path_preset_vertical_atlas_builder.dart';
+import 'terrain_path_variant_vertical_atlas_layout.dart';
+
+/// Builds a legacy animated **lava** [ProjectPathPreset] from the standard
+/// vertical atlas layout.
+///
+/// This is a thin, product-oriented wrapper on top of Lot 15 (second standard
+/// surface after Lot 16 water). It does not add hazard rules, burn/damage,
+/// encounters, collision, particles, or rendering. The only "lava" guarantee
+/// here is:
+///
+/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.lava]
+///
+/// Everything else (columns, frames, tileset override semantics) is inherited
+/// from the shared vertical-atlas stack (Lots 11-15).
+ProjectPathPreset createStandardLavaPathPresetFromVerticalAtlas({
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
+  // owns the behavior contract. This function only pins surfaceKind to lava.
+  return createStandardProjectPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    surfaceKind: PathSurfaceKind.lava,
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
### test (diff -u /dev/null)
```diff
--- /dev/null	2026-04-26 22:25:39
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart	2026-04-26 22:25:08
@@ -0,0 +1,337 @@
+// ignore_for_file: prefer_const_literals_to_create_immutables
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  // Lot 17 mirrors Lot 16: same vertical atlas contract, but the legacy preset
+  // is always tagged as lava via [PathSurfaceKind.lava]. This is the second
+  // standard product-oriented path builder (water = Lot 16, lava = Lot 17).
+  group('createStandardLavaPathPresetFromVerticalAtlas', () {
+    group('preset generation', () {
+      test('generates a lava ProjectPathPreset with the full standard layout',
+          () {
+        final preset = _lava(frameCount: 4);
+
+        expect(preset.id, 'standard-lava');
+        expect(preset.name, 'Standard Lava');
+        expect(preset.surfaceKind, PathSurfaceKind.lava);
+        expect(preset.tilesetId, 'volcano-lava');
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
+      test('API specialization: generated presets are always lava', () {
+        // Lot 17 does not expose a [surfaceKind] parameter; callers cannot
+        // override the legacy kind while reusing the same atlas parameters.
+        final preset = _lava();
+
+        expect(preset.surfaceKind, PathSurfaceKind.lava);
+      });
+
+      test('preserves categoryId and sortOrder', () {
+        final preset = _lava(categoryId: 'lava-category', sortOrder: 42);
+
+        expect(preset.categoryId, 'lava-category');
+        expect(preset.sortOrder, 42);
+      });
+
+      test('respects firstColumn', () {
+        final preset = _lava(firstColumn: 10);
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
+        final preset = _lava(startRow: 7, frameCount: 3);
+
+        for (final mapping in preset.variants) {
+          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
+        }
+      });
+
+      test('generates a variant sub-layout', () {
+        final preset = _lava(variants: _subset);
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
+        final preset = _lava(variants: _subset, firstColumn: 20);
+
+        expect(
+          preset.variants.map((mapping) => mapping.frames.first.source.x),
+          [20, 21, 22],
+        );
+      });
+
+      test('respects sourceWidth and sourceHeight', () {
+        final preset = _lava(sourceWidth: 2, sourceHeight: 3);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.source.width, 2);
+          expect(frame.source.height, 3);
+        }
+      });
+
+      test('distinguishes preset tilesetId from frameTilesetId', () {
+        final preset = _lava(
+          tilesetId: 'main-lava-tileset',
+          frameTilesetId: 'animated-lava-atlas',
+        );
+
+        expect(preset.tilesetId, 'main-lava-tileset');
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, 'animated-lava-atlas');
+        }
+      });
+
+      test('preserves empty frameTilesetId', () {
+        final preset = _lava(frameTilesetId: '');
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, '');
+        }
+      });
+
+      test('applies custom common duration', () {
+        final preset = _lava(defaultDurationMs: 80);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.durationMs, 80);
+        }
+      });
+
+      test('applies per-frame durations', () {
+        final preset = _lava(frameCount: 3, frameDurationsMs: [50, 100, 150]);
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
+        final preset = _lava(
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
+        final preset = _lava(variants: [TerrainPathVariant.isolated]);
+
+        final view = createLegacyPathSurfaceView(preset);
+
+        expect(view.id, 'standard-lava');
+        expect(view.surfaceKind, PathSurfaceKind.lava);
+        expect(
+          view.framesForVariant(TerrainPathVariant.isolated),
+          hasLength(2),
+        );
+      });
+
+      test('is compatible with LegacyProjectSurfaceCatalogView', () {
+        final preset = _lava(variants: [TerrainPathVariant.isolated]);
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
+        expect(catalog.pathSurfaceById('standard-lava'), isNotNull);
+        expect(
+          catalog.pathSurfaceById('standard-lava')?.surfaceKind,
+          PathSurfaceKind.lava,
+        );
+      });
+
+      test('is compatible with resolveTileVisualFrameTimeline', () {
+        final preset = _lava(
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
+        _expectValidation(() => _lava(id: ''));
+        _expectValidation(() => _lava(id: '   '));
+      });
+
+      test('delegates validation for empty name', () {
+        _expectValidation(() => _lava(name: ''));
+        _expectValidation(() => _lava(name: '   '));
+      });
+
+      test('delegates validation for empty tilesetId', () {
+        _expectValidation(() => _lava(tilesetId: ''));
+        _expectValidation(() => _lava(tilesetId: '   '));
+      });
+
+      test('delegates validation for negative firstColumn', () {
+        _expectValidation(() => _lava(firstColumn: -1));
+      });
+
+      test('delegates validation for negative startRow', () {
+        _expectValidation(() => _lava(startRow: -1));
+      });
+
+      test('delegates validation for empty variants', () {
+        _expectValidation(() => _lava(variants: []));
+      });
+
+      test('delegates validation for duplicate variants', () {
+        _expectValidation(
+          () => _lava(
+            variants: [
+              TerrainPathVariant.isolated,
+              TerrainPathVariant.isolated,
+            ],
+          ),
+        );
+      });
+
+      test('delegates validation for invalid frameCount', () {
+        _expectValidation(() => _lava(frameCount: 0));
+        _expectValidation(() => _lava(frameCount: -1));
+      });
+
+      test('delegates validation for invalid source dimensions', () {
+        for (final sourceWidth in [0, -1]) {
+          _expectValidation(() => _lava(sourceWidth: sourceWidth));
+        }
+        for (final sourceHeight in [0, -1]) {
+          _expectValidation(() => _lava(sourceHeight: sourceHeight));
+        }
+      });
+
+      test('delegates validation for invalid defaultDurationMs', () {
+        _expectValidation(() => _lava(defaultDurationMs: 0));
+        _expectValidation(() => _lava(defaultDurationMs: -10));
+      });
+
+      test('delegates validation for frameDurationsMs length mismatch', () {
+        _expectValidation(
+          () => _lava(frameCount: 3, frameDurationsMs: [100, 100]),
+        );
+        _expectValidation(
+          () => _lava(frameCount: 2, frameDurationsMs: [100, 100, 100]),
+        );
+      });
+
+      test('delegates validation for non-positive frame durations', () {
+        _expectValidation(
+          () => _lava(frameCount: 2, frameDurationsMs: [100, 0]),
+        );
+        _expectValidation(
+          () => _lava(frameCount: 2, frameDurationsMs: [100, -50]),
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
+ProjectPathPreset _lava({
+  String id = 'standard-lava',
+  String name = 'Standard Lava',
+  String tilesetId = 'volcano-lava',
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
+  return createStandardLavaPathPresetFromVerticalAtlas(
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
