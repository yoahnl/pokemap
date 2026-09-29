import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/src/border/border_runtime_asset_cache.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('authoring pixels and runtime passes obey order after JSON reload',
      () async {
    final map = MapData.fromJson(const MapData(
      id: 'order',
      name: 'Order',
      size: GridSize(width: 1, height: 1),
      layers: [
        TileLayer(id: 'decor', name: 'Decor', cells: [0])
      ],
      placedElements: [
        MapPlacedElement(
            id: 'red',
            layerId: 'decor',
            elementId: 'red',
            pos: GridPos(x: 0, y: 0),
            visualOrder: 2),
        MapPlacedElement(
            id: 'blue',
            layerId: 'decor',
            elementId: 'blue',
            pos: GridPos(x: 0, y: 0),
            visualOrder: 1),
      ],
    ).toJson());
    final bundle = surfaceTestBundle(map: map, elements: [
      for (final id in ['red', 'blue'])
        ProjectElementEntry(
            id: id,
            name: id,
            tilesetId: id,
            categoryId: 'test',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
            ]),
    ]);
    final images = {
      'red': await runtimeTilesetImage(const [Color(0xffff0000)]),
      'blue': await runtimeTilesetImage(const [Color(0xff0000ff)]),
    };
    addTearDown(() {
      for (final image in images.values) {
        image.dispose();
      }
    });
    final authoring =
        RuntimeAuthoringMapRenderer(bundle: bundle, images: images)..update(0);
    final studioImage = await _paint((canvas) => authoring.paint(canvas));
    addTearDown(studioImage.dispose);
    final background =
        MapLayersComponent(bundle: bundle, tileImagesByTilesetId: images)
          ..update(0);
    final foreground = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
        renderPass: MapLayerRenderPass.foreground)
      ..update(0);
    final runtimeImage = await _paint((canvas) {
      background.render(canvas);
      foreground.render(canvas);
    });
    addTearDown(runtimeImage.dispose);
    expect(await pixelAt(studioImage, 16, 16), rgba(255, 0, 0, 255));
    expect(await pixelAt(runtimeImage, 16, 16), rgba(255, 0, 0, 255));
  });

  test('fixed rank never moves upper decor behind actor pass', () async {
    final bundle = surfaceTestBundle(
        map: const MapData(
          id: 'phase',
          name: 'Phase',
          size: GridSize(width: 1, height: 2),
          layers: [
            TileLayer(id: 'decor', name: 'Decor', cells: [0, 0])
          ],
          placedElements: [
            MapPlacedElement(
                id: 'tree',
                layerId: 'decor',
                elementId: 'tree',
                pos: GridPos(x: 0, y: 0),
                visualOrder: -100)
          ],
        ),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'tree',
            categoryId: 'test',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2))
            ],
            collisionProfile:
                ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]),
          )
        ]);
    final pixels = await _paint(
        (canvas) => canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 64),
            Paint()..color = const Color(0xffff0000)),
        height: 64);
    final image = RuntimeTilesetImage(
        images: [pixels],
        chunks: const [RuntimeTilesetChunk(top: 0, height: 64, width: 32)],
        width: 32,
        height: 64);
    addTearDown(image.dispose);
    final background = MapLayersComponent(
        bundle: bundle, tileImagesByTilesetId: {'tree': image})
      ..update(0);
    final foreground = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: {'tree': image},
        renderPass: MapLayerRenderPass.foreground)
      ..update(0);
    final rendered = await _paint((canvas) {
      background.render(canvas);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 64),
          Paint()..color = const Color(0xff00ff00));
      foreground.render(canvas);
    }, height: 64);
    addTearDown(rendered.dispose);
    expect(await pixelAt(rendered, 16, 16), rgba(255, 0, 0, 255));
    expect(await pixelAt(rendered, 16, 48), rgba(0, 255, 0, 255));
  });

  for (final rockInFront in [false, true]) {
    test(
        'overlapping split and whole decors paint in authored order '
        'with rockInFront=$rockInFront', () async {
      final map = MapData.fromJson(MapData(
        id: 'mixed-order',
        name: 'Mixed order',
        size: const GridSize(width: 1, height: 2),
        layers: const [
          TileLayer(id: 'decor', name: 'Decor', cells: [0, 0]),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'tree',
            layerId: 'decor',
            elementId: 'tree',
            pos: const GridPos(x: 0, y: 0),
            visualOrder: rockInFront ? 0 : 1,
          ),
          MapPlacedElement(
            id: 'rock',
            layerId: 'decor',
            elementId: 'rock',
            pos: const GridPos(x: 0, y: 0),
            visualOrder: rockInFront ? 1 : 0,
          ),
        ],
      ).toJson());
      final bundle = surfaceTestBundle(map: map, elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'tree',
          categoryId: 'test',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
            ),
          ],
          collisionProfile: ElementCollisionProfile(
            cells: [GridPos(x: 0, y: 1)],
          ),
        ),
        ProjectElementEntry(
          id: 'rock',
          name: 'Rock',
          tilesetId: 'rock',
          categoryId: 'test',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
        ),
      ]);
      final treePixels = await _paint(
        (canvas) => canvas.drawRect(
          const Rect.fromLTWH(0, 0, 32, 64),
          Paint()..color = const Color(0xffff0000),
        ),
        height: 64,
      );
      final treeImage = RuntimeTilesetImage(
        images: [treePixels],
        chunks: const [RuntimeTilesetChunk(top: 0, height: 64, width: 32)],
        width: 32,
        height: 64,
      );
      final rockImage = await runtimeTilesetImage(const [Color(0xff0000ff)]);
      addTearDown(treeImage.dispose);
      addTearDown(rockImage.dispose);
      final images = {'tree': treeImage, 'rock': rockImage};

      final studio = RuntimeAuthoringMapRenderer(bundle: bundle, images: images)
        ..update(0);
      final studioImage = await _paint(studio.paint, height: 64);
      addTearDown(studioImage.dispose);
      expect(
        await pixelAt(studioImage, 16, 16),
        rockInFront ? rgba(0, 0, 255, 255) : rgba(255, 0, 0, 255),
      );

      final background = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
      )..update(0);
      final foreground = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
        renderPass: MapLayerRenderPass.foreground,
      )..update(0);
      final playerImage = await _paint((canvas) {
        background.render(canvas);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 32, 64),
          Paint()..color = const Color(0xff00ff00),
        );
        foreground.render(canvas);
      }, height: 64);
      addTearDown(playerImage.dispose);
      expect(
        await pixelAt(playerImage, 16, 16),
        rockInFront ? rgba(0, 255, 0, 255) : rgba(255, 0, 0, 255),
      );
      expect(await pixelAt(playerImage, 16, 48), rgba(0, 255, 0, 255));

      if (rockInFront) {
        final translucentRock = RuntimeAuthoringMapRenderer(
          bundle: bundle.copyWith(
            map: map.copyWith(placedElements: [
              map.placedElements.first,
              map.placedElements.last.copyWith(opacity: 0.5),
            ]),
          ),
          images: images,
        )..update(0);
        final translucentImage = await _paint(
          translucentRock.paint,
          height: 64,
        );
        addTearDown(translucentImage.dispose);
        final blended = await pixelAt(translucentImage, 16, 16);
        expect(blended[0], inInclusiveRange(120, 136));
        expect(blended[2], inInclusiveRange(120, 136));

        final transparentRock = await runtimeTilesetImage(
          const [Color(0x00000000)],
        );
        addTearDown(transparentRock.dispose);
        final fadedImages = {'tree': treeImage, 'rock': transparentRock};
        final fadedTree = map.placedElements.first.copyWith(opacity: 0.5);
        final baseline = RuntimeAuthoringMapRenderer(
          bundle: bundle.copyWith(
            map: map.copyWith(placedElements: [fadedTree]),
          ),
          images: fadedImages,
        )..update(0);
        final withTransparentRock = RuntimeAuthoringMapRenderer(
          bundle: bundle.copyWith(
            map: map
                .copyWith(placedElements: [fadedTree, map.placedElements.last]),
          ),
          images: fadedImages,
        )..update(0);
        final baselineImage = await _paint(baseline.paint, height: 64);
        final transparentImage = await _paint(
          withTransparentRock.paint,
          height: 64,
        );
        addTearDown(baselineImage.dispose);
        addTearDown(transparentImage.dispose);
        expect(
          await pixelAt(transparentImage, 16, 16),
          await pixelAt(baselineImage, 16, 16),
        );
      }
    });
  }

  test('unprepared border does not hide placed elements in authoring preview',
      () async {
    final map = MapData(
      id: 'border-preview',
      name: 'Border preview',
      size: const GridSize(width: 1, height: 1),
      layers: [
        _borderLayer(),
        const TileLayer(id: 'decor', name: 'Decor', cells: [0]),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final bundle = surfaceTestBundle(map: map, elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'tree',
        categoryId: 'test',
        frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
      ),
    ]);
    final image = await runtimeTilesetImage(const [Color(0xffff0000)]);
    addTearDown(image.dispose);
    final renderer = RuntimeAuthoringMapRenderer(
      bundle: bundle,
      images: {'tree': image},
    )..update(0);

    final painted = await _paint((canvas) => renderer.paint(canvas));
    addTearDown(painted.dispose);
    expect(await pixelAt(painted, 16, 16), rgba(255, 0, 0, 255));
  });

  test('prepared border paints the same saved pixels in Studio and Player',
      () async {
    final bundle = surfaceTestBundle(
      map: MapData(
        id: 'prepared-border',
        name: 'Prepared border',
        size: const GridSize(width: 1, height: 1),
        layers: [_borderLayer()],
      ),
    );
    final image = await runtimeTilesetImage(const [Color(0xff2387e0)]);
    addTearDown(image.dispose);
    const snapshotId =
        'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final assets = BorderRuntimeAssetBundle(snapshots: [
      BorderRuntimeLoadedSnapshot(snapshotId: snapshotId, frames: [
        BorderRuntimeLoadedFrame(
          request: BorderRuntimeFrameRequest(
            snapshotId: snapshotId,
            frameIndex: 0,
            relativeAssetPath: 'unused.png',
            sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
            durationMs: 100,
            transparentColorArgb: null,
          ),
          image: image,
        ),
      ]),
    ]);
    final studio = RuntimeAuthoringMapRenderer(
      bundle: bundle,
      images: const {},
      borderAssets: assets,
    )..update(0);
    final player = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: const {},
      borderAssets: assets,
    )..update(0);
    final studioImage = await _paint(studio.paint);
    final playerImage = await _paint(player.render);
    addTearDown(studioImage.dispose);
    addTearDown(playerImage.dispose);
    expect(await pixelAt(studioImage, 16, 16), rgba(35, 135, 224, 255));
    expect(await pixelAt(playerImage, 16, 16), rgba(35, 135, 224, 255));
  });
}

BorderLayer _borderLayer() {
  const hash =
      'sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
  return BorderLayer(
    id: 'border',
    name: 'Border',
    content: BorderLayerContent(features: [
      BorderFeature(
        id: 'feature',
        name: 'Feature',
        blueprintId: 'blueprint',
        seed: BorderSignedInt64.zero,
        geometry: BorderRegionGeometry(
          width: 1,
          height: 1,
          cells: [true],
        ),
        overrides: const [],
        keepOutRegions: const [],
        materialization: BorderMaterialization(
          receipt: BorderResolutionReceipt(
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
          ),
          ground: [
            BorderResolvedGroundCell(
              x: 0,
              y: 0,
              visualSnapshotId:
                  'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              resolvedRole: BorderGroundVariantRole.isolated,
            ),
          ],
          placements: const [],
        ),
      ),
    ]),
  );
}

Future<ui.Image> _paint(void Function(Canvas) paint, {int height = 32}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  final result = await picture.toImage(32, height);
  picture.dispose();
  return result;
}
