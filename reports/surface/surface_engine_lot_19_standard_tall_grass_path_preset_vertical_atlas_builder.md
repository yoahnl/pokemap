# Surface Engine — Lot 19 — Standard Tall Grass Path Preset Vertical Atlas Builder V0

## 1) Résumé exécutif
- `createStandardTallGrassPathPresetFromVerticalAtlas` : forward Lot 15, `PathSurfaceKind.tallGrass`.
- 28 tests, export `map_core`, rapport.
- `dart test` map_core : **+524** All tests passed! ; `dart analyze` : No issues found!

## 2) Après le Lot 18
- Quatrième wrapper « produit » (eau, lave, glace, **hautes herbes**) sur le même atlas vertical ; pas d’encounter/overlay ici.

## 3) Pokémon SDK
- Colonnes = variants, frames = bande verticale ; seul le tag [PathSurfaceKind] change.

## 4) Fichiers consultés
- Wrappers 16–18 (non modifiés), `standard_path_preset_*` Lot 15, `enums` : `tallGrass`.

## 5) Fichiers créés
- `packages/map_core/lib/src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart`
- `packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart`
- `reports/surface/surface_engine_lot_19_standard_tall_grass_path_preset_vertical_atlas_builder.md`

## 6) Modifié
- `packages/map_core/lib/map_core.dart`

## 7) API
Voir §20 (builder).

## 8) Sémantique
- `tallGrass` = enum legacy seul.

## 9) 28 cas (liste prompt 1–28).

## 10) Preuves
- Miroir lots 16–18 + délégation `ValidationException`.

## 11) Non fait
- Encounter, overlay, bruissement, `SurfaceDefinition`, runtime.

## 12) Impact
- Brique d’authoring pur.

## 13) Vigilance
- Ne pas confondre ce preset avec le gameplay herbes hautes complet.

## 14–15) Commandes
| Suite | +N |
|-------|-----|
| standard_tall_grass_... | 28 |
| standard_ice_... | 28 |
| standard_lava_... | 28 |
| standard_water_... | 28 |
| standard_path_preset_... | 28 |
| terrain_path_variant_... | 14 |
| path_preset_... (Lot 13) | 34 |
| path_variant_... | 28 |
| tile_visual_frame_... | 23 |
| `dart test` (complet) | **524** |

`dart analyze` (3 chemins) : **No issues found!**

## 16) Total : **524** tests

## 17) Autocritique
- Symétrie voulue avec les lots précédents.

## 18) Prompt discutable
- Coller toute la sortie `dart test` compacte : une mega-ligne ; le compteur final suffit.

## 19) Auto-review
- Tous les critères du prompt : Oui (git write interdit : respecté ici).

## 20) Fichiers complets
### Builder
```dart
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'standard_path_preset_vertical_atlas_builder.dart';
import 'terrain_path_variant_vertical_atlas_layout.dart';

/// Builds a legacy animated **tall grass** [ProjectPathPreset] from the
/// standard vertical atlas layout.
///
/// This is a thin, product-oriented wrapper on top of Lot 15 (fourth standard
/// surface in this series: water, lava, ice, then tall grass). It does not add
/// wild encounters, local step rustle, player foreground overlay, passability
/// rules, or rendering. The only "tall grass" guarantee here is:
///
/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.tallGrass]
///
/// Full product behavior for tall grass belongs to future Surface Engine /
/// gameplay lots. Everything else (columns, frames, tileset override
/// semantics) is inherited from the shared vertical-atlas stack (Lots 11-15).
ProjectPathPreset createStandardTallGrassPathPresetFromVerticalAtlas({
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
  // owns the behavior contract. This function only pins surfaceKind to
  // tallGrass.
  return createStandardProjectPathPresetFromVerticalAtlas(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.tallGrass,
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
  // Lot 19: same vertical-atlas contract as Lots 16–18; legacy [surfaceKind] is
  // always [PathSurfaceKind.tallGrass]. Encounters, overlay, and step rustle
  // are out of scope—this is only the standard animated path preset builder.
  group('createStandardTallGrassPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test(
          'generates a tallGrass ProjectPathPreset with the full standard layout',
          () {
        final preset = _tallGrass(frameCount: 4);

        expect(preset.id, 'standard-tall-grass');
        expect(preset.name, 'Standard Tall Grass');
        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
        expect(preset.tilesetId, 'field-tall-grass');
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

      test('API specialization: generated presets are always tallGrass', () {
        // No public [surfaceKind]: callers cannot pick another kind via this
        // entry point; specialization is by function name and fixed enum.
        final preset = _tallGrass();

        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
      });

      test('preserves categoryId and sortOrder', () {
        final preset =
            _tallGrass(categoryId: 'tall-grass-category', sortOrder: 42);

        expect(preset.categoryId, 'tall-grass-category');
        expect(preset.sortOrder, 42);
      });

      test('respects firstColumn', () {
        final preset = _tallGrass(firstColumn: 10);

        expect(preset.variants.first.frames.first.source.x, 10);
        expect(preset.variants[1].frames.first.source.x, 11);
        expect(
          preset.variants.last.frames.first.source.x,
          10 + standardTerrainPathVariantVerticalAtlasOrder.length - 1,
        );
      });

      test('respects startRow', () {
        final preset = _tallGrass(startRow: 7, frameCount: 3);

        for (final mapping in preset.variants) {
          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
        }
      });

      test('generates a variant sub-layout', () {
        final preset = _tallGrass(variants: _subset);

        expect(preset.variants, hasLength(3));
        expect(preset.variants.map((mapping) => mapping.variant), _subset);
        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [0, 1, 2],
        );
      });

      test('generates a variant sub-layout with firstColumn', () {
        final preset = _tallGrass(variants: _subset, firstColumn: 20);

        expect(
          preset.variants.map((mapping) => mapping.frames.first.source.x),
          [20, 21, 22],
        );
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = _tallGrass(sourceWidth: 2, sourceHeight: 3);

        for (final frame in _allFrames(preset)) {
          expect(frame.source.width, 2);
          expect(frame.source.height, 3);
        }
      });

      test('distinguishes preset tilesetId from frameTilesetId', () {
        final preset = _tallGrass(
          tilesetId: 'main-tall-grass-tileset',
          frameTilesetId: 'animated-tall-grass-atlas',
        );

        expect(preset.tilesetId, 'main-tall-grass-tileset');
        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, 'animated-tall-grass-atlas');
        }
      });

      test('preserves empty frameTilesetId', () {
        final preset = _tallGrass(frameTilesetId: '');

        for (final frame in _allFrames(preset)) {
          expect(frame.tilesetId, '');
        }
      });

      test('applies custom common duration', () {
        final preset = _tallGrass(defaultDurationMs: 80);

        for (final frame in _allFrames(preset)) {
          expect(frame.durationMs, 80);
        }
      });

      test('applies per-frame durations', () {
        final preset =
            _tallGrass(frameCount: 3, frameDurationsMs: [50, 100, 150]);

        for (final mapping in preset.variants) {
          expect(
            mapping.frames.map((frame) => frame.durationMs),
            [50, 100, 150],
          );
        }
      });

      test('replaces null frame durations with the default duration', () {
        final preset = _tallGrass(
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
        final preset = _tallGrass(variants: [TerrainPathVariant.isolated]);

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'standard-tall-grass');
        expect(view.surfaceKind, PathSurfaceKind.tallGrass);
        expect(
          view.framesForVariant(TerrainPathVariant.isolated),
          hasLength(2),
        );
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = _tallGrass(variants: [TerrainPathVariant.isolated]);
        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        );

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaceById('standard-tall-grass'), isNotNull);
        expect(
          catalog.pathSurfaceById('standard-tall-grass')?.surfaceKind,
          PathSurfaceKind.tallGrass,
        );
      });

      test('is compatible with resolveTileVisualFrameTimeline', () {
        final preset = _tallGrass(
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
        _expectValidation(() => _tallGrass(id: ''));
        _expectValidation(() => _tallGrass(id: '   '));
      });

      test('delegates validation for empty name', () {
        _expectValidation(() => _tallGrass(name: ''));
        _expectValidation(() => _tallGrass(name: '   '));
      });

      test('delegates validation for empty tilesetId', () {
        _expectValidation(() => _tallGrass(tilesetId: ''));
        _expectValidation(() => _tallGrass(tilesetId: '   '));
      });

      test('delegates validation for negative firstColumn', () {
        _expectValidation(() => _tallGrass(firstColumn: -1));
      });

      test('delegates validation for negative startRow', () {
        _expectValidation(() => _tallGrass(startRow: -1));
      });

      test('delegates validation for empty variants', () {
        _expectValidation(() => _tallGrass(variants: []));
      });

      test('delegates validation for duplicate variants', () {
        _expectValidation(
          () => _tallGrass(
            variants: [
              TerrainPathVariant.isolated,
              TerrainPathVariant.isolated,
            ],
          ),
        );
      });

      test('delegates validation for invalid frameCount', () {
        _expectValidation(() => _tallGrass(frameCount: 0));
        _expectValidation(() => _tallGrass(frameCount: -1));
      });

      test('delegates validation for invalid source dimensions', () {
        for (final sourceWidth in [0, -1]) {
          _expectValidation(() => _tallGrass(sourceWidth: sourceWidth));
        }
        for (final sourceHeight in [0, -1]) {
          _expectValidation(() => _tallGrass(sourceHeight: sourceHeight));
        }
      });

      test('delegates validation for invalid defaultDurationMs', () {
        _expectValidation(() => _tallGrass(defaultDurationMs: 0));
        _expectValidation(() => _tallGrass(defaultDurationMs: -10));
      });

      test('delegates validation for frameDurationsMs length mismatch', () {
        _expectValidation(
          () => _tallGrass(frameCount: 3, frameDurationsMs: [100, 100]),
        );
        _expectValidation(
          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, 100, 100]),
        );
      });

      test('delegates validation for non-positive frame durations', () {
        _expectValidation(
          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, 0]),
        );
        _expectValidation(
          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, -50]),
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

ProjectPathPreset _tallGrass({
  String id = 'standard-tall-grass',
  String name = 'Standard Tall Grass',
  String tilesetId = 'field-tall-grass',
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
  return createStandardTallGrassPathPresetFromVerticalAtlas(
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

### map_core.dart (fichier entier)
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
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
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
```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 40106e2f..46e6067b 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -37,6 +37,7 @@ export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
+export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

### diff -u /dev/null builder
```diff
--- /dev/null	2026-04-26 22:48:44
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart	2026-04-26 22:47:47
@@ -0,0 +1,57 @@
+import '../models/enums.dart';
+import '../models/project_manifest.dart';
+import 'map_placed_element_animation.dart';
+import 'standard_path_preset_vertical_atlas_builder.dart';
+import 'terrain_path_variant_vertical_atlas_layout.dart';
+
+/// Builds a legacy animated **tall grass** [ProjectPathPreset] from the
+/// standard vertical atlas layout.
+///
+/// This is a thin, product-oriented wrapper on top of Lot 15 (fourth standard
+/// surface in this series: water, lava, ice, then tall grass). It does not add
+/// wild encounters, local step rustle, player foreground overlay, passability
+/// rules, or rendering. The only "tall grass" guarantee here is:
+///
+/// - [ProjectPathPreset.surfaceKind] is always [PathSurfaceKind.tallGrass]
+///
+/// Full product behavior for tall grass belongs to future Surface Engine /
+/// gameplay lots. Everything else (columns, frames, tileset override
+/// semantics) is inherited from the shared vertical-atlas stack (Lots 11-15).
+ProjectPathPreset createStandardTallGrassPathPresetFromVerticalAtlas({
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
+  // owns the behavior contract. This function only pins surfaceKind to
+  // tallGrass.
+  return createStandardProjectPathPresetFromVerticalAtlas(
+    id: id,
+    name: name,
+    surfaceKind: PathSurfaceKind.tallGrass,
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
--- /dev/null	2026-04-26 22:48:44
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart	2026-04-26 22:47:56
@@ -0,0 +1,340 @@
+// ignore_for_file: prefer_const_literals_to_create_immutables
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  // Lot 19: same vertical-atlas contract as Lots 16–18; legacy [surfaceKind] is
+  // always [PathSurfaceKind.tallGrass]. Encounters, overlay, and step rustle
+  // are out of scope—this is only the standard animated path preset builder.
+  group('createStandardTallGrassPathPresetFromVerticalAtlas', () {
+    group('preset generation', () {
+      test(
+          'generates a tallGrass ProjectPathPreset with the full standard layout',
+          () {
+        final preset = _tallGrass(frameCount: 4);
+
+        expect(preset.id, 'standard-tall-grass');
+        expect(preset.name, 'Standard Tall Grass');
+        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
+        expect(preset.tilesetId, 'field-tall-grass');
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
+      test('API specialization: generated presets are always tallGrass', () {
+        // No public [surfaceKind]: callers cannot pick another kind via this
+        // entry point; specialization is by function name and fixed enum.
+        final preset = _tallGrass();
+
+        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
+      });
+
+      test('preserves categoryId and sortOrder', () {
+        final preset =
+            _tallGrass(categoryId: 'tall-grass-category', sortOrder: 42);
+
+        expect(preset.categoryId, 'tall-grass-category');
+        expect(preset.sortOrder, 42);
+      });
+
+      test('respects firstColumn', () {
+        final preset = _tallGrass(firstColumn: 10);
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
+        final preset = _tallGrass(startRow: 7, frameCount: 3);
+
+        for (final mapping in preset.variants) {
+          expect(mapping.frames.map((frame) => frame.source.y), [7, 8, 9]);
+        }
+      });
+
+      test('generates a variant sub-layout', () {
+        final preset = _tallGrass(variants: _subset);
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
+        final preset = _tallGrass(variants: _subset, firstColumn: 20);
+
+        expect(
+          preset.variants.map((mapping) => mapping.frames.first.source.x),
+          [20, 21, 22],
+        );
+      });
+
+      test('respects sourceWidth and sourceHeight', () {
+        final preset = _tallGrass(sourceWidth: 2, sourceHeight: 3);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.source.width, 2);
+          expect(frame.source.height, 3);
+        }
+      });
+
+      test('distinguishes preset tilesetId from frameTilesetId', () {
+        final preset = _tallGrass(
+          tilesetId: 'main-tall-grass-tileset',
+          frameTilesetId: 'animated-tall-grass-atlas',
+        );
+
+        expect(preset.tilesetId, 'main-tall-grass-tileset');
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, 'animated-tall-grass-atlas');
+        }
+      });
+
+      test('preserves empty frameTilesetId', () {
+        final preset = _tallGrass(frameTilesetId: '');
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.tilesetId, '');
+        }
+      });
+
+      test('applies custom common duration', () {
+        final preset = _tallGrass(defaultDurationMs: 80);
+
+        for (final frame in _allFrames(preset)) {
+          expect(frame.durationMs, 80);
+        }
+      });
+
+      test('applies per-frame durations', () {
+        final preset =
+            _tallGrass(frameCount: 3, frameDurationsMs: [50, 100, 150]);
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
+        final preset = _tallGrass(
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
+        final preset = _tallGrass(variants: [TerrainPathVariant.isolated]);
+
+        final view = createLegacyPathSurfaceView(preset);
+
+        expect(view.id, 'standard-tall-grass');
+        expect(view.surfaceKind, PathSurfaceKind.tallGrass);
+        expect(
+          view.framesForVariant(TerrainPathVariant.isolated),
+          hasLength(2),
+        );
+      });
+
+      test('is compatible with LegacyProjectSurfaceCatalogView', () {
+        final preset = _tallGrass(variants: [TerrainPathVariant.isolated]);
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
+        expect(catalog.pathSurfaceById('standard-tall-grass'), isNotNull);
+        expect(
+          catalog.pathSurfaceById('standard-tall-grass')?.surfaceKind,
+          PathSurfaceKind.tallGrass,
+        );
+      });
+
+      test('is compatible with resolveTileVisualFrameTimeline', () {
+        final preset = _tallGrass(
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
+        _expectValidation(() => _tallGrass(id: ''));
+        _expectValidation(() => _tallGrass(id: '   '));
+      });
+
+      test('delegates validation for empty name', () {
+        _expectValidation(() => _tallGrass(name: ''));
+        _expectValidation(() => _tallGrass(name: '   '));
+      });
+
+      test('delegates validation for empty tilesetId', () {
+        _expectValidation(() => _tallGrass(tilesetId: ''));
+        _expectValidation(() => _tallGrass(tilesetId: '   '));
+      });
+
+      test('delegates validation for negative firstColumn', () {
+        _expectValidation(() => _tallGrass(firstColumn: -1));
+      });
+
+      test('delegates validation for negative startRow', () {
+        _expectValidation(() => _tallGrass(startRow: -1));
+      });
+
+      test('delegates validation for empty variants', () {
+        _expectValidation(() => _tallGrass(variants: []));
+      });
+
+      test('delegates validation for duplicate variants', () {
+        _expectValidation(
+          () => _tallGrass(
+            variants: [
+              TerrainPathVariant.isolated,
+              TerrainPathVariant.isolated,
+            ],
+          ),
+        );
+      });
+
+      test('delegates validation for invalid frameCount', () {
+        _expectValidation(() => _tallGrass(frameCount: 0));
+        _expectValidation(() => _tallGrass(frameCount: -1));
+      });
+
+      test('delegates validation for invalid source dimensions', () {
+        for (final sourceWidth in [0, -1]) {
+          _expectValidation(() => _tallGrass(sourceWidth: sourceWidth));
+        }
+        for (final sourceHeight in [0, -1]) {
+          _expectValidation(() => _tallGrass(sourceHeight: sourceHeight));
+        }
+      });
+
+      test('delegates validation for invalid defaultDurationMs', () {
+        _expectValidation(() => _tallGrass(defaultDurationMs: 0));
+        _expectValidation(() => _tallGrass(defaultDurationMs: -10));
+      });
+
+      test('delegates validation for frameDurationsMs length mismatch', () {
+        _expectValidation(
+          () => _tallGrass(frameCount: 3, frameDurationsMs: [100, 100]),
+        );
+        _expectValidation(
+          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, 100, 100]),
+        );
+      });
+
+      test('delegates validation for non-positive frame durations', () {
+        _expectValidation(
+          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, 0]),
+        );
+        _expectValidation(
+          () => _tallGrass(frameCount: 2, frameDurationsMs: [100, -50]),
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
+ProjectPathPreset _tallGrass({
+  String id = 'standard-tall-grass',
+  String name = 'Standard Tall Grass',
+  String tilesetId = 'field-tall-grass',
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
+  return createStandardTallGrassPathPresetFromVerticalAtlas(
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
