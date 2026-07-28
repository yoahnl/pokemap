import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

const _fixturePath =
    '../map_core/test/fixtures/map_visual_stack/monochrome_parity_v1.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ParityFixture fixture;
  late MapData map;
  late ProjectManifest manifest;

  setUpAll(() async {
    fixture = await _ParityFixture.load();
    map = fixture.buildMap();
    manifest = fixture.buildManifest();
  });

  test('shared fixture covers the canonical editor composition contract', () {
    expect(
      fixture.authoredLayerKinds,
      <String>[
        'surface',
        'terrain',
        'tile',
        'path',
        'border',
        'objectNoop',
        'environmentNoop',
      ],
    );
    expect(
      fixture.deferredContent,
      <String>[
        'placedElements',
        'entities',
        'foregroundEntity',
        'collisionOverlay',
      ],
    );

    final order = buildEditorMapLayerPaintOrder(map);

    expect(
      order.compositionPlan.steps.map((step) => step.stableKey),
      fixture.expectedStablePlanKeys,
    );
  });

  test('real editor painter matches every monochrome center-pixel probe',
      () async {
    final images = await fixture.loadEditorImages();
    addTearDown(() {
      for (final image in images.values.whereType<ui.Image>()) {
        image.dispose();
      }
    });

    final actual = <String, List<int>>{};
    for (final probe in fixture.expectedCenterPixels.keys) {
      actual[probe] = await _paintCenterPixel(
        map: _mapForProbe(map, probe),
        manifest: manifest,
        images: images,
        tileSize: fixture.tileSize,
      );
    }
    expect(actual, fixture.expectedCenterPixels);
  });

  test('full-stack pixel changes when two authored layers are permuted',
      () async {
    final images = await fixture.loadEditorImages();
    addTearDown(() {
      for (final image in images.values.whereType<ui.Image>()) {
        image.dispose();
      }
    });
    final layers = map.layers.toList(growable: false);
    final pathIndex = layers.indexWhere((layer) => layer is PathLayer);
    final surfaceIndex = layers.indexWhere((layer) => layer is SurfaceLayer);
    final swapped = layers.toList(growable: true);
    final path = swapped[pathIndex];
    swapped[pathIndex] = swapped[surfaceIndex];
    swapped[surfaceIndex] = path;

    final pixel = await _paintCenterPixel(
      map: map.copyWith(layers: swapped),
      manifest: manifest,
      images: images,
      tileSize: fixture.tileSize,
    );

    expect(pixel, isNot(fixture.expectedCenterPixels['visualStack']));
  });

  test('editor collision overlay is asserted outside the visual stack',
      () async {
    final pixel = await _paintCenterPixel(
      map: _mapForProbe(map, 'collision'),
      manifest: manifest,
      images: const <String, ui.Image?>{},
      tileSize: fixture.tileSize,
    );

    expect(pixel, fixture.expectedCollisionCenterPixel('editor'));
  });
}

final class _ParityFixture {
  _ParityFixture(this.json);

  final Map<String, dynamic> json;

  static Future<_ParityFixture> load() async {
    final source = await File(_fixturePath).readAsString();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Parity fixture root must be an object.');
    }
    return _ParityFixture(decoded);
  }

  int get tileSize => json['tileSize']! as int;

  Map<String, dynamic> get _coverage => _object(json['coverage']);

  Map<String, dynamic> get _map => _object(json['map']);

  Map<String, dynamic> get _assets => _object(json['assets']);

  Map<String, dynamic> get _tilesets => _object(_assets['tilesets']);

  List<String> get authoredLayerKinds =>
      _strings(_coverage['authoredLayerKinds']);

  List<String> get deferredContent => _strings(_coverage['deferredContent']);

  List<String> get expectedStablePlanKeys =>
      _strings(json['expectedStablePlanKeys']);

  Map<String, List<int>> get expectedCenterPixels => <String, List<int>>{
        for (final entry in _object(json['expectedCenterPixels']).entries)
          entry.key: _rgba(entry.value),
      };

  String get borderSnapshotId => _assets['borderSnapshotId']! as String;

  String get borderDigest => _assets['borderDigest']! as String;

  List<int> expectedCollisionCenterPixel(String consumer) =>
      _rgba(_object(json['expectedCollisionCenterPixels'])[consumer]);

  MapData buildMap() {
    final layers = <MapLayer>[
      for (final value in _list(_map['layersTopFirst']))
        _buildLayer(_object(value)),
    ];
    final placed = _object(_map['placedElement']);
    final entity = _object(_map['entity']);
    final authored = MapData(
      id: _map['id']! as String,
      name: _map['name']! as String,
      version: ProjectVersion.v3,
      size: const GridSize(width: 1, height: 1),
      visualStack: MapVisualStackConfig(
        semanticsVersion: _map['visualStackSemanticsVersion']! as int,
      ),
      layers: layers,
      placedElements: <MapPlacedElement>[
        MapPlacedElement(
          id: placed['id']! as String,
          layerId: placed['layerId']! as String,
          elementId: placed['elementId']! as String,
          pos: const GridPos(x: 0, y: 0),
          opacity: (placed['opacity']! as num).toDouble(),
        ),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: entity['id']! as String,
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 0, y: 0),
          editorVisual: MapEntityEditorVisual(
            elementId: entity['elementId']! as String,
            renderInForeground: entity['renderInForeground']! as bool,
          ),
        ),
      ],
    );
    return MapData.fromJson(
      migrateMapDataJson(
        Map<String, dynamic>.from(authored.toJson()),
      ),
    );
  }

  MapLayer _buildLayer(Map<String, dynamic> layer) {
    final id = layer['id']! as String;
    final name = layer['name']! as String;
    final opacity = (layer['opacity'] as num?)?.toDouble() ?? 1;
    return switch (layer['kind']) {
      'tile' => TileLayer(
          id: id,
          name: name,
          opacity: opacity,
          tilesetId: layer['tilesetId']! as String,
          tiles: <int>[layer['tileId']! as int],
        ),
      'path' => PathLayer(
          id: id,
          name: name,
          opacity: opacity,
          presetId: layer['presetId']! as String,
          properties: <String, String>{
            'paintAfterTileLayerId': layer['paintAfterTileLayerId']! as String,
          },
          cells: const <bool>[true],
        ),
      'terrain' => TerrainLayer(
          id: id,
          name: name,
          opacity: opacity,
          terrains: <TerrainType>[
            TerrainType.values.byName(layer['terrainType']! as String),
          ],
        ),
      'surface' => SurfaceLayer(
          id: id,
          name: name,
          opacity: opacity,
          placements: <SurfaceCellPlacement>[
            SurfaceCellPlacement(
              x: 0,
              y: 0,
              surfacePresetId: layer['presetId']! as String,
            ),
          ],
        ),
      'border' => _borderLayer(
          id: id,
          name: name,
          opacity: opacity,
          snapshotId: borderSnapshotId,
          receiptHash: 'sha256:$borderDigest',
        ),
      'object' => ObjectLayer(id: id, name: name),
      'environment' => EnvironmentLayer(id: id, name: name),
      'collision' => CollisionLayer(
          id: id,
          name: name,
          collisions: <bool>[layer['blocked']! as bool],
        ),
      final kind => throw FormatException('Unsupported fixture layer: $kind'),
    };
  }

  ProjectManifest buildManifest() {
    final placed = _object(_map['placedElement']);
    final entity = _object(_map['entity']);
    return ProjectManifest(
      name: _map['name']! as String,
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      settings: ProjectSettings(
        tileWidth: tileSize,
        tileHeight: tileSize,
        displayScale: 1,
      ),
      tilesets: <ProjectTilesetEntry>[
        for (final id in _tilesets.keys)
          ProjectTilesetEntry(
            id: id,
            name: id,
            relativePath: 'assets/parity/$id.png',
          ),
      ],
      elements: <ProjectElementEntry>[
        _element(
          id: placed['elementId']! as String,
          tilesetId: 'placed',
        ),
        _element(
          id: entity['elementId']! as String,
          tilesetId: 'entity',
        ),
      ],
      pathPresets: const <ProjectPathPreset>[
        ProjectPathPreset(
          id: 'path-preset',
          name: 'Path preset',
          tilesetId: 'path',
          variants: <PathPresetVariantMapping>[
            PathPresetVariantMapping(
              variant: TerrainPathVariant.isolated,
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      terrainPresets: const <ProjectTerrainPreset>[
        ProjectTerrainPreset(
          id: 'terrain-preset',
          name: 'Terrain preset',
          terrainType: TerrainType.grass,
          tilesetId: 'terrain',
          variants: <TerrainPresetVariant>[
            TerrainPresetVariant(
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      surfaceCatalog: _surfaceCatalog(tileSize),
      borderCatalog: ProjectBorderCatalog(
        visualSnapshots: <BorderVisualSnapshot>[
          BorderVisualSnapshot(
            id: borderSnapshotId,
            contentFingerprint: borderDigest,
            frames: <BorderVisualFrameSnapshot>[
              BorderVisualFrameSnapshot(
                relativeAssetPath:
                    'assets/borders/snapshots/$borderDigest/frame_0000.png',
                sourceRectPx: BorderPixelRect(
                  x: 0,
                  y: 0,
                  width: tileSize,
                  height: tileSize,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, ui.Image?>> loadEditorImages() async {
    final result = <String, ui.Image?>{};
    for (final entry in _tilesets.entries) {
      final id = entry.key;
      final image = await _solidImage(_color(_rgba(entry.value)), tileSize);
      if (id == 'border') {
        result[editorBorderFrameImageKey(borderSnapshotId, 0)] = image;
      } else {
        result[id] = image;
      }
    }
    return result;
  }
}

ProjectElementEntry _element({
  required String id,
  required String tilesetId,
}) =>
    ProjectElementEntry(
      id: id,
      name: id,
      tilesetId: tilesetId,
      categoryId: 'parity',
      frames: const <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    );

ProjectSurfaceCatalog _surfaceCatalog(int tileSize) => ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: 'surface-atlas',
          name: 'Surface atlas',
          tilesetId: 'surface',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(
              width: tileSize,
              height: tileSize,
            ),
            gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
          ),
        ),
      ],
      animations: <ProjectSurfaceAnimation>[
        ProjectSurfaceAnimation(
          id: 'surface-animation',
          name: 'Surface animation',
          timeline: SurfaceAnimationTimeline(
            frames: <SurfaceAnimationFrame>[
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'surface-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ),
      ],
      presets: <ProjectSurfacePreset>[
        ProjectSurfacePreset(
          id: 'surface-preset',
          name: 'Surface preset',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: <SurfaceVariantAnimationRef>[
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'surface-animation',
              ),
            ],
          ),
        ),
      ],
    );

BorderLayer _borderLayer({
  required String id,
  required String name,
  required double opacity,
  required String snapshotId,
  required String receiptHash,
}) =>
    BorderLayer(
      id: id,
      name: name,
      opacity: opacity,
      content: BorderLayerContent(
        features: <BorderFeature>[
          BorderFeature(
            id: 'border-feature',
            name: 'Border feature',
            blueprintId: 'border-blueprint',
            seed: BorderSignedInt64.zero,
            geometry: BorderRegionGeometry(
              width: 1,
              height: 1,
              cells: const <bool>[true],
            ),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
            materialization: BorderMaterialization(
              receipt: _receipt(receiptHash),
              ground: <BorderResolvedGroundCell>[
                BorderResolvedGroundCell(
                  x: 0,
                  y: 0,
                  visualSnapshotId: snapshotId,
                  resolvedRole: SurfaceVariantRole.isolated,
                ),
              ],
              placements: const <BorderResolvedPlacement>[],
            ),
          ),
        ],
      ),
    );

BorderResolutionReceipt _receipt(String hash) => BorderResolutionReceipt(
      resolverVersion: 1,
      blueprintRevision: 1,
      components: BorderInputFingerprints(
        blueprint: hash,
        geometryAndSeed: hash,
        parameters: hash,
        overrides: hash,
        keepOutRegions: hash,
        mapContext: hash,
        visualSnapshots: hash,
      ),
      inputFingerprint: hash,
      outputFingerprint: hash,
    );

MapData _mapForProbe(MapData source, String probe) {
  final withoutDeferred =
      source.copyWith(placedElements: const [], entities: const []);
  return switch (probe) {
    'tile' => withoutDeferred.copyWith(
        layers: source.layers.whereType<TileLayer>().toList(),
      ),
    'path' => withoutDeferred.copyWith(
        layers: source.layers.whereType<PathLayer>().toList(),
      ),
    'terrain' => withoutDeferred.copyWith(
        layers: source.layers.whereType<TerrainLayer>().toList(),
      ),
    'surface' => withoutDeferred.copyWith(
        layers: source.layers.whereType<SurfaceLayer>().toList(),
      ),
    'border' => withoutDeferred.copyWith(
        layers: source.layers.whereType<BorderLayer>().toList(),
      ),
    'placedElement' => source.copyWith(
        layers: <MapLayer>[
          source.layers
              .whereType<TileLayer>()
              .single
              .copyWith(tiles: const <int>[0]),
        ],
        entities: const <MapEntity>[],
      ),
    'entity' => source.copyWith(
        layers: source.layers
            .where(
              (layer) => layer is ObjectLayer || layer is EnvironmentLayer,
            )
            .toList(),
        placedElements: const <MapPlacedElement>[],
      ),
    'collision' => withoutDeferred.copyWith(
        layers: source.layers.whereType<CollisionLayer>().toList(),
      ),
    'visualStack' => source.copyWith(
        layers:
            source.layers.where((layer) => layer is! CollisionLayer).toList(),
      ),
    _ => throw ArgumentError.value(probe, 'probe'),
  };
}

Future<List<int>> _paintCenterPixel({
  required MapData map,
  required ProjectManifest manifest,
  required Map<String, ui.Image?> images,
  required int tileSize,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: tileSize.toDouble(),
    tileHeight: tileSize.toDouble(),
    tilesetImagesById: images,
    sourceTileWidth: tileSize,
    sourceTileHeight: tileSize,
    tilesPerRowById: <String, int>{
      for (final tileset in manifest.tilesets) tileset.id: 1,
    },
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: <String, PathAutotileSet>{
      for (final preset in manifest.pathPresets)
        preset.id: PathAutotileSet.fromPreset(preset),
    },
    terrainPresetsByType: <TerrainType, ProjectTerrainPreset>{
      for (final preset in manifest.terrainPresets) preset.terrainType: preset,
    },
    project: manifest,
    showGrid: false,
    showEntityEditorChrome: false,
  ).paint(
    canvas,
    ui.Size(tileSize.toDouble(), tileSize.toDouble()),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(tileSize, tileSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final center = tileSize ~/ 2;
  final offset = ((center * tileSize) + center) * 4;
  final pixel = <int>[
    bytes!.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
  picture.dispose();
  image.dispose();
  return pixel;
}

Future<ui.Image> _solidImage(ui.Color color, int size) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  return image;
}

ui.Color _color(List<int> rgba) =>
    ui.Color.fromARGB(rgba[3], rgba[0], rgba[1], rgba[2]);

Map<String, dynamic> _object(Object? value) =>
    Map<String, dynamic>.from(value! as Map);

List<Object?> _list(Object? value) => List<Object?>.from(value! as List);

List<String> _strings(Object? value) => List<String>.from(value! as List);

List<int> _rgba(Object? value) => List<int>.from(value! as List);
