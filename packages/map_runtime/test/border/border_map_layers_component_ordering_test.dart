import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/border/border_runtime_asset_cache.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _snapshotA = 'border-snapshot-sha256:$_digestA';
const _snapshotB = 'border-snapshot-sha256:$_digestB';
const _receiptHash =
    'sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent Border authored ordering', () {
    test('keeps the exact legacy visual phases when no Border exists',
        () async {
      final component = await _surfaceThenTileComponent(
        layers: <MapLayer>[
          surfaceTestLayer(),
          const TileLayer(
            id: 'tile',
            name: 'Tile',
            tilesetId: 'base',
            tiles: <int>[1],
          ),
        ],
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test(
      'a hidden Border activates authored legacy-direction order without '
      'painting itself',
      () async {
        final component = await _surfaceThenTileComponent(
          layers: <MapLayer>[
            surfaceTestLayer(),
            const TileLayer(
              id: 'tile',
              name: 'Tile',
              tilesetId: 'base',
              tiles: <int>[1],
            ),
            const BorderLayer(
              id: 'hidden-border',
              name: 'Hidden Border',
              isVisible: false,
            ),
          ],
        );

        final image = await renderSurfaceTestComponent(component);

        // Legacy authored direction is reverse serialization: hidden Border,
        // Tile, then Surface. The hidden Border creates no pixels, so Surface
        // must be the visible top result.
        expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
      },
    );

    test(
      'renders multiple Border layers among every authored visual slot in '
      'bottom-to-top order',
      () async {
        final borderAssets = await _borderAssets();
        final component = MapLayersComponent(
          bundle: surfaceTestBundle(
            map: MapData(
              id: 'authored-modern',
              name: 'Authored modern',
              size: const GridSize(width: 1, height: 1),
              properties: const <String, dynamic>{
                'tileLayerOrder': 'bottom_to_top',
              },
              layers: <MapLayer>[
                const TerrainLayer(
                  id: 'terrain',
                  name: 'Terrain',
                  terrains: <TerrainType>[TerrainType.grass],
                ),
                const PathLayer(
                  id: 'path',
                  name: 'Path',
                  cells: <bool>[true],
                ),
                surfaceTestLayer(),
                _borderLayer(id: 'border-a', snapshotId: _snapshotA),
                const TileLayer(
                  id: 'tile',
                  name: 'Tile',
                  tilesetId: 'base',
                  tiles: <int>[1],
                ),
                const ObjectLayer(id: 'objects', name: 'Objects'),
                const EnvironmentLayer(
                  id: 'environment',
                  name: 'Environment',
                ),
                _borderLayer(id: 'border-b', snapshotId: _snapshotB),
              ],
            ),
          ),
          tileImagesByTilesetId: {
            'surface-water': await runtimeTilesetImage(
              const <Color>[Color(0xFF0000FF)],
            ),
            'base': await runtimeTilesetImage(
              const <Color>[Color(0xFFFF0000)],
            ),
          },
          borderAssets: borderAssets,
        );

        final image = await renderSurfaceTestComponent(component);

        expect(await pixelAt(image, 16, 16), rgba(255, 0, 255, 255));
      },
    );

    test('keeps a later tile above Border in bottom-to-top order', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'tile-over-border',
            name: 'Tile over Border',
            size: const GridSize(width: 1, height: 1),
            properties: const <String, dynamic>{
              'tileLayerOrder': 'bottom_to_top',
            },
            layers: <MapLayer>[
              _borderLayer(id: 'border-a', snapshotId: _snapshotA),
              const TileLayer(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: <int>[1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(
            const <Color>[Color(0xFFFF0000)],
          ),
        },
        borderAssets: await _borderAssets(),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('keeps ocean visible around transparent two-tier cliff stones',
        () async {
      final cliffImage = await _transparentCliffStoneImage();
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'ocean-with-cliff',
            name: 'Ocean with cliff',
            size: const GridSize(width: 1, height: 1),
            properties: const <String, dynamic>{
              'tileLayerOrder': 'bottom_to_top',
            },
            layers: <MapLayer>[
              surfaceTestLayer(),
              _borderPlacementLayer(
                id: 'two-tier-cliff',
                snapshotId: _snapshotA,
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage(
            const <Color>[Color(0xFF0000FF)],
          ),
        },
        borderAssets: BorderRuntimeAssetBundle(
          snapshots: <BorderRuntimeLoadedSnapshot>[
            _loadedSnapshot(
              snapshotId: _snapshotA,
              digest: _digestA,
              image: cliffImage,
            ),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 4, 16), rgba(0, 0, 255, 255));
      expect(await pixelAt(image, 16, 16), rgba(255, 255, 0, 255));
      expect(await pixelAt(image, 28, 16), rgba(0, 0, 255, 255));
    });

    test('keeps paintAfterTileLayerId paths immediately above their ground',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'deferred-path',
            name: 'Deferred path',
            size: const GridSize(width: 1, height: 1),
            properties: const <String, dynamic>{
              'tileLayerOrder': 'bottom_to_top',
            },
            layers: <MapLayer>[
              const PathLayer(
                id: 'path',
                name: 'Path',
                cells: <bool>[true],
                properties: <String, String>{
                  'paintAfterTileLayerId': 'ground',
                },
              ),
              _borderLayer(id: 'border-a', snapshotId: _snapshotA),
              const TileLayer(
                id: 'ground',
                name: 'Ground',
                tilesetId: 'base',
                tiles: <int>[1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(
            const <Color>[Color(0xFFFF0000)],
          ),
        },
        borderAssets: await _borderAssets(),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 150, 136, 255));
    });

    test('renders the same authored stack in reverse for legacy direction',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'authored-legacy',
            name: 'Authored legacy',
            size: const GridSize(width: 1, height: 1),
            layers: <MapLayer>[
              _borderLayer(id: 'border-b', snapshotId: _snapshotB),
              const EnvironmentLayer(
                id: 'environment',
                name: 'Environment',
              ),
              const ObjectLayer(id: 'objects', name: 'Objects'),
              const TileLayer(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: <int>[1],
              ),
              _borderLayer(id: 'border-a', snapshotId: _snapshotA),
              surfaceTestLayer(),
              const PathLayer(
                id: 'path',
                name: 'Path',
                cells: <bool>[true],
              ),
              const TerrainLayer(
                id: 'terrain',
                name: 'Terrain',
                terrains: <TerrainType>[TerrainType.grass],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage(
            const <Color>[Color(0xFF0000FF)],
          ),
          'base': await runtimeTilesetImage(
            const <Color>[Color(0xFFFF0000)],
          ),
        },
        borderAssets: await _borderAssets(),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 255, 255));
    });

    test('renders Border only in the background pass', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: MapData(
            id: 'foreground',
            name: 'Foreground',
            size: const GridSize(width: 1, height: 1),
            layers: <MapLayer>[
              _borderLayer(id: 'border-a', snapshotId: _snapshotA),
            ],
          ),
        ),
        tileImagesByTilesetId: const {},
        borderAssets: await _borderAssets(),
        renderPass: MapLayerRenderPass.foreground,
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
    });

    test('keeps foreground tiles above Border and out of the background pass',
        () async {
      final map = MapData(
        id: 'foreground-tile',
        name: 'Foreground tile',
        size: const GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          _borderLayer(id: 'border-a', snapshotId: _snapshotA),
          const TileLayer(
            id: 'tile_overhead',
            name: 'Overhead',
            tilesetId: 'base',
            tiles: <int>[1],
          ),
        ],
      );
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(map: map),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(
            const <Color>[Color(0xFF285AB4)],
          ),
        },
        borderAssets: await _borderAssets(),
        renderPass: MapLayerRenderPass.foreground,
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(40, 90, 180, 255));
    });

    test('passes manifest displayScale to persisted Border rendering',
        () async {
      final baseBundle = surfaceTestBundle(
        map: MapData(
          id: 'scaled',
          name: 'Scaled',
          size: const GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            _borderLayer(id: 'border-a', snapshotId: _snapshotA),
          ],
        ),
      );
      final scaledBundle = RuntimeMapBundle(
        manifest: baseBundle.manifest.copyWith(
          settings: baseBundle.manifest.settings.copyWith(displayScale: 2),
        ),
        map: baseBundle.map,
        projectRootDirectory: baseBundle.projectRootDirectory,
        tilesetAbsolutePathsById: baseBundle.tilesetAbsolutePathsById,
      );
      final component = MapLayersComponent(
        bundle: scaledBundle,
        tileImagesByTilesetId: const {},
        borderAssets: await _borderAssets(),
      );

      final image = await _renderComponent(component, width: 64, height: 64);

      expect(await _pixelAt(image, 48, 48), rgba(255, 255, 0, 255));
    });

    test('keeps shadows and placed elements above authored backgrounds',
        () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          elements: <ProjectElementEntry>[
            surfaceTestElement(id: 'placed', tilesetId: 'entity'),
          ],
          map: MapData(
            id: 'sentinels',
            name: 'Sentinels',
            size: const GridSize(width: 1, height: 1),
            properties: const <String, dynamic>{
              'tileLayerOrder': 'bottom_to_top',
            },
            layers: <MapLayer>[
              _borderLayer(id: 'border-a', snapshotId: _snapshotA),
              const TileLayer(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: <int>[1],
              ),
            ],
            placedElements: const <MapPlacedElement>[
              MapPlacedElement(
                id: 'placed',
                layerId: 'tile',
                elementId: 'placed',
                pos: GridPos(x: 0, y: 0),
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'base': await runtimeTilesetImage(
            const <Color>[Color(0xFF0000FF)],
          ),
          'entity': await runtimeTilesetImage(
            const <Color>[Color(0xFFFF0000)],
          ),
        },
        borderAssets: await _borderAssets(),
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: <ShadowRuntimeRenderInstruction>[
            ShadowRuntimeRenderInstruction(
              shape: ShadowRuntimeShapeKind.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
              worldLeft: 0,
              worldTop: 0,
              width: 32,
              height: 32,
              opacity: 1,
              colorHexRgb: '000000',
            ),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('keeps background project-element entities above Border', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          elements: <ProjectElementEntry>[
            surfaceTestElement(id: 'entity-prop', tilesetId: 'entity'),
          ],
          map: MapData(
            id: 'entity-sentinel',
            name: 'Entity sentinel',
            size: const GridSize(width: 1, height: 1),
            layers: <MapLayer>[
              _borderLayer(id: 'border-a', snapshotId: _snapshotA),
            ],
            entities: const <MapEntity>[
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'entity-prop',
                ),
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'entity': await runtimeTilesetImage(
            const <Color>[Color(0xFF800080)],
          ),
        },
        borderAssets: await _borderAssets(),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(128, 0, 128, 255));
    });
  });
}

Future<MapLayersComponent> _surfaceThenTileComponent({
  required List<MapLayer> layers,
}) async {
  return MapLayersComponent(
    bundle: surfaceTestBundle(
      map: surfaceTestMap(layers: layers),
    ),
    tileImagesByTilesetId: {
      'surface-water':
          await runtimeTilesetImage(const <Color>[Color(0xFF0000FF)]),
      'base': await runtimeTilesetImage(const <Color>[Color(0xFFFF0000)]),
    },
  );
}

BorderLayer _borderLayer({
  required String id,
  required String snapshotId,
}) {
  return BorderLayer(
    id: id,
    name: id,
    content: BorderLayerContent(
      features: <BorderFeature>[
        BorderFeature(
          id: 'feature-$id',
          name: 'Feature $id',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const <bool>[true],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
          materialization: BorderMaterialization(
            receipt: _receipt(),
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
}

BorderLayer _borderPlacementLayer({
  required String id,
  required String snapshotId,
}) {
  const slotKey = 'slot-two-tier-cliff';
  return BorderLayer(
    id: id,
    name: id,
    content: BorderLayerContent(
      features: <BorderFeature>[
        BorderFeature(
          id: 'feature-$id',
          name: 'Feature $id',
          blueprintId: 'blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const <bool>[true],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
          materialization: BorderMaterialization(
            receipt: _receipt(),
            ground: const <BorderResolvedGroundCell>[],
            placements: <BorderResolvedPlacement>[
              BorderResolvedPlacement(
                id: 'placement-two-tier-cliff',
                slotKey: slotKey,
                primitiveId: 'primitive-two-tier-cliff',
                visualSnapshotId: snapshotId,
                anchorCell: const GridPos(x: 0, y: 0),
                topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
                opaqueWorldBoundsPx: BorderPixelRect(
                  x: 12,
                  y: 0,
                  width: 8,
                  height: 32,
                ),
                transform: BorderSpriteTransform(
                  quarterTurns: 0,
                  flipX: false,
                ),
                drawBand: BorderDrawBand.structure,
                stableOrderKey: BorderStableOrderKey(
                  drawBandIndex: BorderDrawBand.structure.stableV1Index,
                  anchorRowMajor: 0,
                  passIndex: 0,
                  rank: 0,
                  ordinalLocal: 0,
                  slotKey: slotKey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

BorderResolutionReceipt _receipt() {
  return BorderResolutionReceipt(
    resolverVersion: 1,
    blueprintRevision: 1,
    components: BorderInputFingerprints(
      blueprint: _receiptHash,
      geometryAndSeed: _receiptHash,
      parameters: _receiptHash,
      overrides: _receiptHash,
      keepOutRegions: _receiptHash,
      mapContext: _receiptHash,
      visualSnapshots: _receiptHash,
    ),
    inputFingerprint: _receiptHash,
    outputFingerprint: _receiptHash,
  );
}

Future<BorderRuntimeAssetBundle> _borderAssets() async {
  final yellow = await runtimeTilesetImage(
    const <Color>[Color(0xFFFFFF00)],
  );
  final magenta = await runtimeTilesetImage(
    const <Color>[Color(0xFFFF00FF)],
  );
  return BorderRuntimeAssetBundle(
    snapshots: <BorderRuntimeLoadedSnapshot>[
      _loadedSnapshot(
        snapshotId: _snapshotA,
        digest: _digestA,
        image: yellow,
      ),
      _loadedSnapshot(
        snapshotId: _snapshotB,
        digest: _digestB,
        image: magenta,
      ),
    ],
  );
}

Future<RuntimeTilesetImage> _transparentCliffStoneImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(12, 0, 8, 32),
    ui.Paint()..color = const ui.Color(0xFFFFFF00),
  );
  final image = await recorder.endRecording().toImage(
        surfaceTestTileSize,
        surfaceTestTileSize,
      );
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(
        top: 0,
        height: surfaceTestTileSize,
        width: surfaceTestTileSize,
      ),
    ],
    width: surfaceTestTileSize,
    height: surfaceTestTileSize,
  );
}

BorderRuntimeLoadedSnapshot _loadedSnapshot({
  required String snapshotId,
  required String digest,
  required RuntimeTilesetImage image,
}) {
  return BorderRuntimeLoadedSnapshot(
    snapshotId: snapshotId,
    frames: <BorderRuntimeLoadedFrame>[
      BorderRuntimeLoadedFrame(
        request: BorderRuntimeFrameRequest(
          snapshotId: snapshotId,
          frameIndex: 0,
          relativeAssetPath: 'assets/borders/snapshots/$digest/frame_0.png',
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: surfaceTestTileSize,
            height: surfaceTestTileSize,
          ),
          durationMs: 100,
          transparentColorArgb: null,
        ),
        image: image,
      ),
    ],
  );
}

Future<ui.Image> _renderComponent(
  MapLayersComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

Future<List<int>> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return <int>[
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}
