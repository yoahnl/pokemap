import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest JSON characterization before Surface model', () {
    test('minimal current manifest parses and materializes defaults', () {
      // This is the smallest manifest accepted by the current generated
      // ProjectManifest parser. Future Surface collections must be added in a
      // way that keeps this legacy shape readable.
      final manifest = ProjectManifest.fromJson(minimalManifestJson());
      final json = manifest.toJson();

      expect(manifest.name, 'Surface Characterization');
      expect(manifest.maps, isEmpty);
      expect(manifest.tilesets, isEmpty);
      expect(manifest.groups, isEmpty);
      expect(manifest.tilesetFolders, isEmpty);
      expect(manifest.elementCategories, isEmpty);
      expect(manifest.elements, isEmpty);
      expect(manifest.terrainCategories, isEmpty);
      expect(manifest.pathCategories, isEmpty);
      expect(manifest.terrainPresets, isEmpty);
      expect(manifest.pathPresets, isEmpty);
      expect(manifest.encounterTables, isEmpty);
      expect(manifest.dialogueFolders, isEmpty);
      expect(manifest.dialogues, isEmpty);
      expect(manifest.scripts, isEmpty);
      expect(manifest.scenarios, isEmpty);
      expect(manifest.trainers, isEmpty);
      expect(manifest.characters, isEmpty);
      expect(manifest.surfaceCatalog.isEmpty, isTrue);
      expect(manifest.settings.tileWidth, 16);
      expect(manifest.settings.tileHeight, 16);
      expect(json.containsKey('surfaceCatalog'), isTrue);
      expect(
        json['surfaceCatalog'],
        encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
      );
      expect(json, isNot(contains('surfaceDefinitions')));
      expect(json['settings'], containsPair('tileWidth', 16));
      expect(json['settings'], containsPair('tileHeight', 16));
    });

    test('unknown root surfaceDefinitions is ignored and lost on round-trip',
        () {
      // This characterizes how today's binaries react when a future manifest
      // contains Surface data at the root. The current generated parser ignores
      // unknown keys; it does not preserve them for forward-compatible writes.
      final manifest = ProjectManifest.fromJson(
        minimalManifestJson(
          extra: {
            'surfaceDefinitions': [
              {'id': 'future-water', 'name': 'Future Water'},
            ],
          },
        ),
      );

      expect(manifest.name, 'Surface Characterization');
      expect(manifest.toJson(), isNot(contains('surfaceDefinitions')));

      final reparsed = roundTripManifest(manifest);
      expect(reparsed, manifest);
      expect(reparsed.toJson(), isNot(contains('surfaceDefinitions')));
    });

    test('manifest preserves a simple ProjectTilesetEntry as wire JSON', () {
      // Tilesets are the source of visual atlases. Surface definitions will
      // likely reference these ids, so this locks down the current manifest
      // representation before adding any new references.
      final manifest = ProjectManifest.fromJson(
        minimalManifestJson(
          extra: {
            'tilesets': [
              {
                'id': 'outdoor',
                'name': 'Outdoor',
                'relativePath': 'tilesets/outdoor.png',
                'scope': 'group',
                'groupId': 'route-group',
                'folderId': 'environment',
                'sortOrder': 7,
                'isWorldTileset': true,
                'paletteEntries': [
                  {
                    'id': 'water_tile',
                    'name': 'Water Tile',
                    'category': 'water',
                    'frames': [
                      frameJson(0, 0, durationMs: 100),
                    ],
                    'recommendedLayerId': 'paths',
                  },
                ],
              },
            ],
          },
        ),
      );

      final tileset = manifest.tilesets.single;
      expect(tileset.id, 'outdoor');
      expect(tileset.name, 'Outdoor');
      expect(tileset.relativePath, 'tilesets/outdoor.png');
      expect(tileset.scope, TilesetScope.group);
      expect(tileset.groupId, 'route-group');
      expect(tileset.folderId, 'environment');
      expect(tileset.sortOrder, 7);
      expect(tileset.isWorldTileset, isTrue);
      expect(tileset.paletteEntries.single.frames.single.durationMs, 100);

      final reparsed = roundTripManifest(manifest);
      expect(reparsed.tilesets.single, tileset);
    });

    test('TilesetSourceRect preserves its grid coordinates and size', () {
      // Surface atlases depend on stable source rectangles. This direct test
      // documents the current source rectangle wire keys and integer values.
      final rect = TilesetSourceRect.fromJson({
        'x': 3,
        'y': 5,
        'width': 2,
        'height': 4,
      });

      expectSourceRect(rect, x: 3, y: 5, width: 2, height: 4);
      expect(
        TilesetSourceRect.fromJson(wireJson(rect.toJson())),
        rect,
      );
    });

    test('TilesetVisualFrame without tileset override defaults to empty id',
        () {
      // The prompt describes a nullable override, but the current model uses
      // an empty string as the "no override" sentinel. Future Surface JSON must
      // either preserve this behavior or migrate it deliberately.
      final frame = TilesetVisualFrame.fromJson({
        'source': {'x': 1, 'y': 2, 'width': 1, 'height': 1},
        'durationMs': 90,
      });

      expectFrame(frame, tilesetId: '', x: 1, y: 2, durationMs: 90);
      expect(TilesetVisualFrame.fromJson(wireJson(frame.toJson())), frame);
    });

    test('TilesetVisualFrame with tileset override preserves the override', () {
      // Animated surfaces may eventually reference alternate atlases per frame.
      // The existing frame model already persists a tilesetId override string.
      final frame = TilesetVisualFrame.fromJson(
        frameJson(2, 4, tilesetId: 'water-atlas-b', durationMs: 140),
      );

      expectFrame(
        frame,
        tilesetId: 'water-atlas-b',
        x: 2,
        y: 4,
        durationMs: 140,
      );
      expect(TilesetVisualFrame.fromJson(wireJson(frame.toJson())), frame);
    });

    test('ProjectTerrainPreset preserves animated variants in order', () {
      // Terrain presets are the closest existing model to paintable base
      // surfaces. This locks down their frame lists before Surface definitions
      // introduce a more explicit visual contract.
      final preset = ProjectTerrainPreset.fromJson({
        'id': 'grass-soft',
        'name': 'Soft Grass',
        'terrainType': 'grass',
        'categoryId': 'terrain-nature',
        'tilesetId': 'outdoor',
        'variants': [
          {
            'weight': 3,
            'frames': [
              frameJson(0, 1, durationMs: 80),
              frameJson(1, 1, durationMs: 120),
            ],
          },
        ],
        'sortOrder': 4,
      });

      expect(preset.terrainType, TerrainType.grass);
      expect(preset.categoryId, 'terrain-nature');
      expect(preset.tilesetId, 'outdoor');
      expect(preset.variants.single.weight, 3);
      expectFrame(preset.variants.single.frames[0], x: 0, y: 1, durationMs: 80);
      expectFrame(preset.variants.single.frames[1],
          x: 1, y: 1, durationMs: 120);
      expect(ProjectTerrainPreset.fromJson(wireJson(preset.toJson())), preset);
    });

    test('ProjectPathPreset water preserves mappings and animated frames', () {
      // Water is the motivating Surface Engine example. Today it is still a
      // path preset with per-variant visual frames, so this test records that
      // legacy representation without making it more powerful.
      final preset = ProjectPathPreset.fromJson({
        'id': 'water-route',
        'name': 'Route Water',
        'surfaceKind': 'water',
        'categoryId': 'liquid-paths',
        'tilesetId': 'outdoor',
        'variants': [
          mappingJson('isolated', [frameJson(0, 0, durationMs: 100)]),
          mappingJson('horizontal', [
            frameJson(1, 0, durationMs: 70),
            frameJson(2, 0, tilesetId: 'water-alt', durationMs: 130),
          ]),
          mappingJson('vertical', [frameJson(3, 0, durationMs: 100)]),
          mappingJson('cornerNE', [frameJson(4, 0, durationMs: 100)]),
          mappingJson('cross', [frameJson(5, 0, durationMs: 100)]),
        ],
      });

      expect(preset.surfaceKind, PathSurfaceKind.water);
      expect(preset.variants.map((mapping) => mapping.variant), [
        TerrainPathVariant.isolated,
        TerrainPathVariant.horizontal,
        TerrainPathVariant.vertical,
        TerrainPathVariant.cornerNE,
        TerrainPathVariant.cross,
      ]);
      expect(preset.variants[1].frames, hasLength(2));
      expectFrame(preset.variants[1].frames[0], x: 1, y: 0, durationMs: 70);
      expectFrame(
        preset.variants[1].frames[1],
        tilesetId: 'water-alt',
        x: 2,
        y: 0,
        durationMs: 130,
      );
      expect(ProjectPathPreset.fromJson(wireJson(preset.toJson())), preset);
    });

    test('ProjectPathPreset tallGrass is known to JSON serialization', () {
      // Tall grass must not be modeled as "green water" later. This test only
      // proves the current enum can persist the tall_grass surface kind; it says
      // nothing about runtime overlay or encounter behavior.
      final preset = ProjectPathPreset.fromJson({
        'id': 'tall-grass',
        'name': 'Tall Grass',
        'surfaceKind': 'tall_grass',
        'tilesetId': 'outdoor',
        'variants': [
          mappingJson('isolated', [frameJson(6, 0)]),
        ],
      });

      expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
      expect(
          wireJson(preset.toJson()), containsPair('surfaceKind', 'tall_grass'));
      expect(ProjectPathPreset.fromJson(wireJson(preset.toJson())), preset);
    });

    test('PathLayer animationMode preserves always_active and triggered', () {
      // Animation mode currently lives on PathLayer rather than ProjectPathPreset.
      // This distinction matters for migration because Surface definitions
      // should not accidentally absorb layer-specific playback state.
      final alwaysActive = MapLayer.fromJson({
        'runtimeType': 'path',
        'id': 'water-paths',
        'name': 'Water Paths',
        'presetId': 'water-route',
        'cells': [true, false],
        'animationMode': 'always_active',
      }) as PathLayer;
      final triggered = MapLayer.fromJson({
        'runtimeType': 'path',
        'id': 'grass-paths',
        'name': 'Grass Paths',
        'presetId': 'tall-grass',
        'cells': [false, true],
        'animationMode': 'triggered',
      }) as PathLayer;

      expect(alwaysActive.animationMode, PathAnimationMode.alwaysActive);
      expect(triggered.animationMode, PathAnimationMode.triggered);
      expect(
        (MapLayer.fromJson(wireJson(alwaysActive.toJson())) as PathLayer)
            .animationMode,
        PathAnimationMode.alwaysActive,
      );
      expect(
        (MapLayer.fromJson(wireJson(triggered.toJson())) as PathLayer)
            .animationMode,
        PathAnimationMode.triggered,
      );
    });

    test('PathAnimationTriggerRule preserves current trigger fields', () {
      // The current rule has no duration or cooldown fields. It stores id,
      // enabled, trigger, playback mode, and activation scope only.
      final rule = PathAnimationTriggerRule.fromJson({
        'id': 'step-cell',
        'enabled': false,
        'trigger': 'on_step',
        'mode': 'restart_on_trigger',
        'scope': 'cell_only',
      });

      expect(rule.id, 'step-cell');
      expect(rule.enabled, isFalse);
      expect(rule.trigger, PathAnimationTriggerType.onStep);
      expect(rule.mode, PathAnimationPlaybackMode.restartOnTrigger);
      expect(rule.scope, PathAnimationActivationScope.cellOnly);
      expect(PathAnimationTriggerRule.fromJson(wireJson(rule.toJson())), rule);
    });

    test('PathLayer preserves presetId, cells, properties, mode and triggers',
        () {
      // This locks the layer-level path payload that future Surface maps may
      // need to coexist with during a long compatibility period.
      final layer = MapLayer.fromJson({
        'runtimeType': 'path',
        'id': 'animated-water-layer',
        'name': 'Animated Water',
        'isVisible': false,
        'opacity': 0.75,
        'presetId': 'water-route',
        'cells': [true, false, true, true],
        'properties': {'encounterTableId': 'surf-route-1'},
        'animationMode': 'triggered',
        'animationTriggers': [
          {
            'id': 'enter-loop',
            'enabled': true,
            'trigger': 'on_enter',
            'mode': 'loop_while_active',
            'scope': 'whole_layer',
          },
        ],
      }) as PathLayer;

      expect(layer.presetId, 'water-route');
      expect(layer.cells, [true, false, true, true]);
      expect(layer.properties, {'encounterTableId': 'surf-route-1'});
      expect(layer.animationMode, PathAnimationMode.triggered);
      expect(layer.animationTriggers.single.trigger,
          PathAnimationTriggerType.onEnter);
      expect(layer.animationTriggers.single.mode,
          PathAnimationPlaybackMode.loopWhileActive);
      expect(MapLayer.fromJson(wireJson(layer.toJson())), layer);
    });

    test('TerrainLayer preserves terrain grid enum values', () {
      // TerrainLayer is still a separate legacy layer model. Surface migration
      // must not silently rewrite its enum grid or visibility/opacity fields.
      final layer = MapLayer.fromJson({
        'runtimeType': 'terrain',
        'id': 'terrain-base',
        'name': 'Terrain Base',
        'isVisible': true,
        'opacity': 0.5,
        'terrains': ['none', 'grass', 'sand', 'indoor'],
      }) as TerrainLayer;

      expect(layer.terrains, [
        TerrainType.none,
        TerrainType.grass,
        TerrainType.sand,
        TerrainType.indoor,
      ]);
      expect(MapLayer.fromJson(wireJson(layer.toJson())), layer);
    });

    test('unknown preset fields are ignored and lost on round-trip', () {
      // Unknown-key loss is important for forward compatibility planning:
      // current binaries can read past future preset metadata, but they will
      // drop it if they save the object back.
      final pathPreset = ProjectPathPreset.fromJson({
        'id': 'water-route',
        'name': 'Route Water',
        'surfaceKind': 'water',
        'tilesetId': 'outdoor',
        'surfaceDraft': {'candidate': true},
        'variants': [
          mappingJson('isolated', [frameJson(0, 0)]),
        ],
      });
      final terrainPreset = ProjectTerrainPreset.fromJson({
        'id': 'mud',
        'name': 'Mud',
        'terrainType': 'dirt',
        'surfaceDraft': {'candidate': true},
        'variants': [
          {
            'frames': [frameJson(1, 0)],
          },
        ],
      });

      expect(pathPreset.toJson(), isNot(contains('surfaceDraft')));
      expect(terrainPreset.toJson(), isNot(contains('surfaceDraft')));
      expect(ProjectPathPreset.fromJson(wireJson(pathPreset.toJson())),
          pathPreset);
      expect(
        ProjectTerrainPreset.fromJson(wireJson(terrainPreset.toJson())),
        terrainPreset,
      );
    });

    test('manifest business object remains stable after wire JSON round-trip',
        () {
      // This is a broad stability check over the existing manifest surface:
      // tilesets, terrain presets, path presets, and settings survive the same
      // JSON encode/decode path used by file persistence.
      final manifest = ProjectManifest.fromJson(
        minimalManifestJson(
          extra: {
            'settings': {
              'tileWidth': 32,
              'tileHeight': 32,
              'displayScale': 2.0,
              'defaultMapWidth': 24,
              'defaultMapHeight': 18,
            },
            'tilesets': [
              {
                'id': 'outdoor',
                'name': 'Outdoor',
                'relativePath': 'tilesets/outdoor.png',
              },
            ],
            'terrainPresets': [
              {
                'id': 'grass-soft',
                'name': 'Soft Grass',
                'terrainType': 'grass',
                'tilesetId': 'outdoor',
                'variants': [
                  {
                    'weight': 2,
                    'frames': [frameJson(0, 1, durationMs: 100)],
                  },
                ],
              },
            ],
            'pathPresets': [
              {
                'id': 'water-route',
                'name': 'Route Water',
                'surfaceKind': 'water',
                'tilesetId': 'outdoor',
                'variants': [
                  mappingJson('cross', [frameJson(5, 0, durationMs: 100)]),
                ],
              },
            ],
          },
        ),
      );

      final reparsed = roundTripManifest(manifest);

      expect(reparsed, manifest);
      expect(reparsed.settings.tileWidth, 32);
      expect(reparsed.settings.tileHeight, 32);
      expect(reparsed.tilesets.single.id, 'outdoor');
      expect(reparsed.terrainPresets.single.terrainType, TerrainType.grass);
      expect(reparsed.pathPresets.single.surfaceKind, PathSurfaceKind.water);
    });
  });
}

Map<String, dynamic> minimalManifestJson({Map<String, dynamic>? extra}) {
  return <String, dynamic>{
    'name': 'Surface Characterization',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[],
    ...?extra,
  };
}

Map<String, dynamic> frameJson(
  int x,
  int y, {
  String? tilesetId,
  int? durationMs,
}) {
  return <String, dynamic>{
    if (tilesetId != null) 'tilesetId': tilesetId,
    'source': <String, dynamic>{
      'x': x,
      'y': y,
      'width': 1,
      'height': 1,
    },
    if (durationMs != null) 'durationMs': durationMs,
  };
}

Map<String, dynamic> mappingJson(
  String variant,
  List<Map<String, dynamic>> frames,
) {
  return <String, dynamic>{
    'variant': variant,
    'frames': frames,
  };
}

ProjectManifest roundTripManifest(ProjectManifest manifest) {
  return ProjectManifest.fromJson(wireJson(manifest.toJson()));
}

Map<String, dynamic> wireJson(Map<String, dynamic> json) {
  return jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
}

void expectSourceRect(
  TilesetSourceRect rect, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  expect(rect.x, x);
  expect(rect.y, y);
  expect(rect.width, width);
  expect(rect.height, height);
}

void expectFrame(
  TilesetVisualFrame frame, {
  String tilesetId = '',
  required int x,
  required int y,
  int? durationMs,
}) {
  expect(frame.tilesetId, tilesetId);
  expectSourceRect(frame.source, x: x, y: y, width: 1, height: 1);
  expect(frame.durationMs, durationMs);
}
