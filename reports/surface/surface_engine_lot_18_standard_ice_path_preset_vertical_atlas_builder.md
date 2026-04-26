# Surface Engine — Lot 18 — Standard Ice Path Preset Vertical Atlas Builder V0

## 1) Résumé exécutif
- `createStandardIcePathPresetFromVerticalAtlas` : forward Lot 15 avec `PathSurfaceKind.ice`.
- 28 tests, export `map_core`, pas de `SurfaceDefinition`, pas de gameplay glissade.

## 2) Après le Lot 17
- Même empreinte que Lots 16–17 : eau, lave, **glace** = trois helpers « produit » sur l’atlas vertical standard.

## 3) Atlas type Pokémon SDK
- Colonnes = variants path ; frames = colonne verticale ; l’ice ne change que le tag `PathSurfaceKind`.

## 4) Fichiers consultés
- Lots 15–17 (wrappers eau/lave) non modifiés ; `enums.dart` : `PathSurfaceKind.ice`.

## 5) Fichiers créés
- `packages/map_core/lib/src/operations/standard_ice_path_preset_vertical_atlas_builder.dart`
- `packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart`
- Ce rapport

## 6) Fichier modifié
- `packages/map_core/lib/map_core.dart` (+1 export)

## 7) API
Voir §20 (builder complet).

## 8) Sémantique
- `ice` = enum legacy uniquement.

## 9) Cas testés
- 28 (liste utilisateur 1–28).

## 10) Preuves
- Miroir Lot 16/17 + compat legacy + `ValidationException` déléguées.

## 11) Non fait
- Glissade, friction, moteur, `SurfaceDefinition`.

## 12) Impact futur
- Bricks d’authoring pur tant que le runtime lit `ProjectPathPreset`.

## 13) Vigilance
- Ne pas confondre rendu/physique glace avec ce preset.

## 14–15) Commandes & résultats
- `dart test test/standard_ice_path_preset_vertical_atlas_builder_test.dart` → **+28** All tests passed!
- `dart test test/standard_lava_...` → **+28** All tests passed!
- `dart test test/standard_water_...` → **+28** All tests passed!
- `dart test test/standard_path_preset_...` → **+28** All tests passed!
- `dart test test/terrain_path_variant_...` → **+14** All tests passed!
- `dart test test/path_preset_vertical_atlas_builder_test.dart` → **+34** All tests passed!
- `dart test test/path_variant_...` → **+28** All tests passed!
- `dart test test/tile_visual_frame_...` → **+23** All tests passed!
- `dart test` (map_core) → **+496** All tests passed!
- `dart analyze` (3 chemins) → No issues found!

## 16) Total `dart test` map_core : **496**

## 17) Autocritique
- Copie structurelle de Lot 17 : intentionnelle.

## 18) Prompt discutable
- Coller toute la sortie compacte `dart test` : peu lisible ; compteur `+N` + All tests passed suffit en preuve.

## 19) Auto-review
- Tous critères du prompt : **Oui** (helper ice-only, compose Lot 15, git write interdit non utilisé ici).

## 20) Fichiers complets
### builder
```dart
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'standard_path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy animated **ice** [ProjectPathPreset] from the standard
/// vertical atlas layout.
///
/// This is a thin, product-oriented wrapper on top of Lot 15 (third standard
/// surface after Lot 16 water and Lot 17 lava). It does not add sliding
/// movement, forced motion, friction rules, collision, or rendering. The only
/// "ice" guarantee here is:
///
/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.ice]
///
/// Everything else (columns, frames, tileset override semantics) is inherited
/// from the shared vertical-atlas stack (Lots 11-15).
ProjectPathPreset createStandardIcePathPresetFromVerticalAtlas({
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
  // owns the behavior contract. This function only pins surfaceKind to ice.
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.ice,
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

### test
```dart
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  // Lot 18 mirrors Lots 16–17: same vertical atlas contract, legacy preset
  // always [PathSurfaceKind.ice]. Third standard product path builder
  // (water = 16, lava = 17, ice = 18).
  group('createStandardIcePathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test('generates an ice ProjectPathPreset with the full standard layout',
          () {
        final preset = _ice(frameCount: 4);

        expect(preset.id, 'standard-ice');
        expect(preset.name, 'Standard Ice');
        expect(preset.surfaceKind, PathSurfaceKind.ice);
        expect(preset.tilesetId, 'cavern-ice');
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

      test('API specialization: generated presets are always ice', () {
        // No [surfaceKind] parameter: specialization is by API shape, not
        // runtime override of the legacy enum.
        final preset = _ice();

        expect(preset.surfaceKind, PathSurfaceKind.ice);
      });

      test('preserves categoryId and sortOrder', () {
        final preset = _ice(categoryId: 'ice-category', sortOrder: 42);

        expect(preset.categoryId, 'ice-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _ice(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _ice(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _ice(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [0, 1, 2],
        );
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _ice(variants: _subset, firstColumn: 20);

        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [20, 21, 22],
        );
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _ice(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _ice(
          tilesetId: 'main-ice-tileset',
          frameTilesetId: 'animated-ice-atlas',
        );

        expect(preset.tilesetId, 'main-ice-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-ice-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _ice(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _ice(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset = _ice(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 100, 150],
          );
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _ice(
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
        final preset = _ice(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-ice');
        expect(view.surfaceKind, PathSurfaceKind.ice);
        expect(
          view.framesForVariant(TerrainPathVariant.isolated),
          hasLength(2),
        );
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _ice(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        );

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-ice'), isNotNull);
        expect(
          catalog.pathSurfaceById('standard-ice')?.surfaceKind,
          PathSurfaceKind.ice,
        );
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _ice(
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
        _expectValidation(() => _ice(id: ''));
        _expectValidation(() => _ice(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _ice(name: ''));
        _expectValidation(() => _ice(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _ice(tilesetId: ''));
        _expectValidation(() => _ice(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _ice(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _ice(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _ice(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _ice(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _ice(frameCount: 0));
        _expectValidation(() => _ice(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _ice(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _ice(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _ice(defaultDurationMs: 0));
        _expectValidation(() => _ice(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _ice(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _ice(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _ice(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _ice(frameCount: 2, frameDurationsMs: [100, -50]),
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

ProjectPathPreset _ice({
  String id = 'standard-ice',
  String name = 'Standard Ice',
  String tilesetId = 'cavern-ice',
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
  return createStandardIcePathPresetFromVerticalAtlas(
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

### map_core.dart (complet)
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
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
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
### git map_core
```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index d25eeee5..40106e2f 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -36,6 +36,7 @@ export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
 export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
+export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

### diff -u /dev/null builder
```diff
--- /dev/null	2026-04-26 22:31:47
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/standard_ice_path_preset_vertical_atlas_builder.dart	2026-04-26 22:31:06
@@ -0,0 +1,55 @@
+import '../models/enums.dart';
+import '../models/project_manifest.dart';
+import 'map_placed_element_animation.dart';
+import 'standard_path_preset_vertical_atlas_builder.dart';
+import 'terrain_path_variant_vertical_atlas_layout.dart';
+
+/// Builds a legacy animated **ice** [ProjectPathPreset] from the standard
+/// vertical atlas layout.
+///
+/// This is a thin, product-oriented wrapper on top of Lot 15 (third standard
+/// surface after Lot 16 water and Lot 17 lava). It does not add sliding
+/// movement, forced motion, friction rules, collision, or rendering. The only
+/// "ice" guarantee here is:
+///
+/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.ice]
+///
+/// Everything else (columns, frames, tileset override semantics) is inherited
+/// from the shared vertical-atlas stack (Lots 11-15).
+ProjectPathPreset createStandardIcePathPresetFromVerticalAtlas({
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
+  // owns the behavior contract. This function only pins surfaceKind to ice.
+  return createStandardProjectPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    surfaceKind: PathSurfaceKind.ice,
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

### diff -u /dev/null test
```diff
--- /dev/null	2026-04-26 22:31:47
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart	2026-04-26 22:31:23
@@ -0,0 +1,337 @@
+// ignore_for_file: prefer_const_literals_to_create_immutables
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  // Lot 18 mirrors Lots 16–17: same vertical atlas contract, legacy preset
+  // always [PathSurfaceKind.ice]. Third standard product path builder
+  // (water = 16, lava = 17, ice = 18).
+  group('createStandardIcePathPresetFromVerticalAtlas', () {
+    group('preset generation', () {
+      test('generates an ice ProjectPathPreset with the full standard layout',
+          () {
+        final preset = _ice(frameCount: 4);
+
+        expect(preset.id, 'standard-ice');
+        expect(preset.name, 'Standard Ice');
+        expect(preset.surfaceKind, PathSurfaceKind.ice);
+        expect(preset.tilesetId, 'cavern-ice');
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
+      test('API specialization: generated presets are always ice', () {
+        // No [surfaceKind] parameter: specialization is by API shape, not
+        // runtime override of the legacy enum.
+        final preset = _ice();
+
+        expect(preset.surfaceKind, PathSurfaceKind.ice);
+      });
+
+      test('preserves categoryId and sortOrder', () {
+        final preset = _ice(categoryId: 'ice-category', sortOrder: 42);
+
+        expect(preset.categoryId, 'ice-category');
+        expect(preset.sortOrder, 42);
+      });
+
+      test('respects firstColumn', () {
+        final preset = _ice(firstColumn: 10);
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
+        final preset = _ice(startRow: 7, frameCount: 3);
+
+        for (final mapping in preset.variants) {
+          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
+        }
+      });
+
+      test('generates a variant sub-layout', () {
+        final preset = _ice(variants: _subset);
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
+        final preset = _ice(variants: _subset, firstColumn: 20);
+
+        expect(
+          preset.variants.map((mapping) => mapping.frames.first.source.x),
+          [20, 21, 22],
+        );
+      });
+
+      test('respects sourceWidth and sourceHeight', () {
+        final preset = _ice(sourceWidth: 2, sourceHeight: 3);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.source.width, 2);
+          expect(frame.source.height, 3);
+        }
+      });
+
+      test('distinguishes preset tilesetId from frameTilesetId', () {
+        final preset = _ice(
+          tilesetId: 'main-ice-tileset',
+          frameTilesetId: 'animated-ice-atlas',
+        );
+
+        expect(preset.tilesetId, 'main-ice-tileset');
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, 'animated-ice-atlas');
+        }
+      });
+
+      test('preserves empty frameTilesetId', () {
+        final preset = _ice(frameTilesetId: '');
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, '');
+        }
+      });
+
+      test('applies custom common duration', () {
+        final preset = _ice(defaultDurationMs: 80);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.durationMs, 80);
+        }
+      });
+
+      test('applies per-frame durations', () {
+        final preset = _ice(frameCount: 3, frameDurationsMs: [50, 100, 150]);
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
+        final preset = _ice(
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
+        final preset = _ice(variants: [TerrainPathVariant.isolated]);
+
+        final view = createLegacyPathSurfaceView(preset);
+
+        expect(view.id, 'standard-ice');
+        expect(view.surfaceKind, PathSurfaceKind.ice);
+        expect(
+          view.framesForVariant(TerrainPathVariant.isolated),
+          hasLength(2),
+        );
+      });
+
+      test('is compatible with LegacyProjectSurfaceCatalogView', () {
+        final preset = _ice(variants: [TerrainPathVariant.isolated]);
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
+        expect(catalog.pathSurfaceById('standard-ice'), isNotNull);
+        expect(
+          catalog.pathSurfaceById('standard-ice')?.surfaceKind,
+          PathSurfaceKind.ice,
+        );
+      });
+
+      test('is compatible with resolveTileVisualFrameTimeline', () {
+        final preset = _ice(
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
+        _expectValidation(() => _ice(id: ''));
+        _expectValidation(() => _ice(id: '   '));
+      });
+
+      test('delegates validation for empty name', () {
+        _expectValidation(() => _ice(name: ''));
+        _expectValidation(() => _ice(name: '   '));
+      });
+
+      test('delegates validation for empty tilesetId', () {
+        _expectValidation(() => _ice(tilesetId: ''));
+        _expectValidation(() => _ice(tilesetId: '   '));
+      });
+
+      test('delegates validation for negative firstColumn', () {
+        _expectValidation(() => _ice(firstColumn: -1));
+      });
+
+      test('delegates validation for negative startRow', () {
+        _expectValidation(() => _ice(startRow: -1));
+      });
+
+      test('delegates validation for empty variants', () {
+        _expectValidation(() => _ice(variants: []));
+      });
+
+      test('delegates validation for duplicate variants', () {
+        _expectValidation(
+          () => _ice(
+            variants: [
+              TerrainPathVariant.isolated,
+              TerrainPathVariant.isolated,
+            ],
+          ),
+        );
+      });
+
+      test('delegates validation for invalid frameCount', () {
+        _expectValidation(() => _ice(frameCount: 0));
+        _expectValidation(() => _ice(frameCount: -1));
+      });
+
+      test('delegates validation for invalid source dimensions', () {
+        for (final sourceWidth in [0, -1]) {
+          _expectValidation(() => _ice(sourceWidth: sourceWidth));
+        }
+        for (final sourceHeight in [0, -1]) {
+          _expectValidation(() => _ice(sourceHeight: sourceHeight));
+        }
+      });
+
+      test('delegates validation for invalid defaultDurationMs', () {
+        _expectValidation(() => _ice(defaultDurationMs: 0));
+        _expectValidation(() => _ice(defaultDurationMs: -10));
+      });
+
+      test('delegates validation for frameDurationsMs length mismatch', () {
+        _expectValidation(
+          () => _ice(frameCount: 3, frameDurationsMs: [100, 100]),
+        );
+        _expectValidation(
+          () => _ice(frameCount: 2, frameDurationsMs: [100, 100, 100]),
+        );
+      });
+
+      test('delegates validation for non-positive frame durations', () {
+        _expectValidation(
+          () => _ice(frameCount: 2, frameDurationsMs: [100, 0]),
+        );
+        _expectValidation(
+          () => _ice(frameCount: 2, frameDurationsMs: [100, -50]),
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
+ProjectPathPreset _ice({
+  String id = 'standard-ice',
+  String name = 'Standard Ice',
+  String tilesetId = 'cavern-ice',
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
+  return createStandardIcePathPresetFromVerticalAtlas(
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
