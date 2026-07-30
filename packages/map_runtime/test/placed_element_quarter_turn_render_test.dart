import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

const _tileWidth = 8;
const _tileHeight = 4;
const _mapSize = GridSize(width: 5, height: 5);
const _anchor = GridPos(x: 1, y: 1);
const _sourceGridSize = GridSize(width: 2, height: 1);
final _sourcePixelSize = GridSize(
  width: _sourceGridSize.width * _tileWidth,
  height: _sourceGridSize.height * _tileHeight,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent placed-element quarter turns', () {
    test(
      'matches QuarterTurnPixelTransform for q0-q3 with rectangular pixels',
      () async {
        final atlas = await _asymmetricAtlas(frameCount: 1);
        addTearDown(atlas.image.dispose);

        for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
          final component = _component(
            atlas: atlas.runtimeImage,
            quarterTurns: quarterTurns,
          );
          final rendered = await _render(component);
          final bytes =
              (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          final gridTransform = QuarterTurnGridTransform(
            sourceSize: _sourceGridSize,
            quarterTurns: quarterTurns,
          );
          final destinationPixelSize = GridSize(
            width: gridTransform.destinationSize.width * _tileWidth,
            height: gridTransform.destinationSize.height * _tileHeight,
          );
          final pixelTransform = QuarterTurnPixelTransform(
            sourcePixelSize: _sourcePixelSize,
            destinationPixelSize: destinationPixelSize,
            quarterTurns: quarterTurns,
          );

          for (var y = 0; y < destinationPixelSize.height; y++) {
            for (var x = 0; x < destinationPixelSize.width; x++) {
              final source = pixelTransform.destinationPixelToSourcePixel(
                GridPos(x: x, y: y),
              );
              expect(
                _rgbaAt(
                  bytes,
                  imageWidth: rendered.width,
                  x: _anchor.x * _tileWidth + x,
                  y: _anchor.y * _tileHeight + y,
                ),
                _sourceRgba(source.x, source.y),
                reason: 'q$quarterTurns destination ($x, $y) '
                    'must sample source $source',
              );
            }
          }
          rendered.dispose();
        }
      },
    );

    test('culls against the rotated destination footprint', () async {
      final atlas = await _asymmetricAtlas(frameCount: 1);
      addTearDown(atlas.image.dispose);
      final component = _component(
        atlas: atlas.runtimeImage,
        quarterTurns: 1,
      )..setVisibleLocalRect(
          Rect.fromLTWH(
            (_anchor.x * _tileWidth).toDouble(),
            _anchor.y * _tileHeight + _tileHeight + 0.25,
            _tileWidth.toDouble(),
            _tileHeight - 0.5,
          ),
        );

      final rendered = await _render(component);
      final bytes =
          (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!;

      expect(
        _rgbaAt(
          bytes,
          imageWidth: rendered.width,
          x: _anchor.x * _tileWidth + _tileWidth ~/ 2,
          y: _anchor.y * _tileHeight + _tileHeight + _tileHeight ~/ 2,
        )[3],
        255,
      );
      rendered.dispose();
    });

    test('keeps the quarter turn when the animation frame advances', () async {
      final atlas = await _asymmetricAtlas(frameCount: 2);
      addTearDown(atlas.image.dispose);
      final component = _component(
        atlas: atlas.runtimeImage,
        quarterTurns: 1,
        frames: const <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
            durationMs: 100,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 1, width: 2, height: 1),
            durationMs: 100,
          ),
        ],
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          autoplay: true,
        ),
      )..update(0.12);

      final rendered = await _render(component);
      final bytes =
          (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final destinationPixelSize = GridSize(
        width: _tileWidth,
        height: _sourceGridSize.width * _tileHeight,
      );
      final transform = QuarterTurnPixelTransform(
        sourcePixelSize: _sourcePixelSize,
        destinationPixelSize: destinationPixelSize,
        quarterTurns: 1,
      );

      for (var y = 0; y < destinationPixelSize.height; y++) {
        for (var x = 0; x < destinationPixelSize.width; x++) {
          final source = transform.destinationPixelToSourcePixel(
            GridPos(x: x, y: y),
          );
          expect(
            _rgbaAt(
              bytes,
              imageWidth: rendered.width,
              x: _anchor.x * _tileWidth + x,
              y: _anchor.y * _tileHeight + y,
            ),
            _sourceRgba(source.x, source.y + _tileHeight),
            reason: 'animated q1 destination ($x, $y)',
          );
        }
      }
      rendered.dispose();
    });

    test('rotates source collision cells before splitting render passes',
        () async {
      final atlas = await _asymmetricAtlas(frameCount: 1);
      addTearDown(atlas.image.dispose);
      const collisionProfile = ElementCollisionProfile(
        cells: <GridPos>[GridPos(x: 0, y: 0)],
      );
      final background = await _render(
        _component(
          atlas: atlas.runtimeImage,
          quarterTurns: 1,
          collisionProfile: collisionProfile,
        ),
      );
      final foreground = await _render(
        _component(
          atlas: atlas.runtimeImage,
          quarterTurns: 1,
          collisionProfile: collisionProfile,
          renderPass: MapLayerRenderPass.foreground,
        ),
      );
      final backgroundBytes = (await background.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final foregroundBytes = (await foreground.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final x = _anchor.x * _tileWidth + _tileWidth ~/ 2;
      final topY = _anchor.y * _tileHeight + _tileHeight ~/ 2;
      final bottomY = topY + _tileHeight;

      expect(
        _rgbaAt(
          backgroundBytes,
          imageWidth: background.width,
          x: x,
          y: topY,
        )[3],
        255,
      );
      expect(
        _rgbaAt(
          backgroundBytes,
          imageWidth: background.width,
          x: x,
          y: bottomY,
        )[3],
        0,
      );
      expect(
        _rgbaAt(
          foregroundBytes,
          imageWidth: foreground.width,
          x: x,
          y: topY,
        )[3],
        0,
      );
      expect(
        _rgbaAt(
          foregroundBytes,
          imageWidth: foreground.width,
          x: x,
          y: bottomY,
        )[3],
        255,
      );
      background.dispose();
      foreground.dispose();
    });

    test(
        'applyCollision false keeps the whole visual in background with no foreground tile split',
        () async {
      final atlas = await _asymmetricAtlas(frameCount: 1);
      addTearDown(atlas.image.dispose);
      const collisionProfile = ElementCollisionProfile(
        cells: <GridPos>[GridPos(x: 0, y: 0)],
      );
      final background = await _render(
        _component(
          atlas: atlas.runtimeImage,
          quarterTurns: 1,
          collisionProfile: collisionProfile,
          applyCollision: false,
          includeUnderlyingTileAtNonCollisionCell: true,
        ),
      );
      final foreground = await _render(
        _component(
          atlas: atlas.runtimeImage,
          quarterTurns: 1,
          collisionProfile: collisionProfile,
          applyCollision: false,
          includeUnderlyingTileAtNonCollisionCell: true,
          renderPass: MapLayerRenderPass.foreground,
        ),
      );
      final backgroundBytes = (await background.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final foregroundBytes = (await foreground.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final destinationSize = GridSize(
        width: _tileWidth,
        height: _sourceGridSize.width * _tileHeight,
      );

      for (var y = 0; y < destinationSize.height; y++) {
        for (var x = 0; x < destinationSize.width; x++) {
          final worldX = _anchor.x * _tileWidth + x;
          final worldY = _anchor.y * _tileHeight + y;
          expect(
            _alphaAt(
              backgroundBytes,
              imageWidth: background.width,
              x: worldX,
              y: worldY,
            ),
            255,
            reason: 'background destination ($x, $y)',
          );
          expect(
            _alphaAt(
              foregroundBytes,
              imageWidth: foreground.width,
              x: worldX,
              y: worldY,
            ),
            0,
            reason: 'foreground destination ($x, $y)',
          );
        }
      }
      background.dispose();
      foreground.dispose();
    });
  });

  group('MapLayersComponent rotated collision overlay', () {
    test('maps legacy collision cells into destination space', () async {
      final rendered = await _renderCollisionOverlay(
        const ElementCollisionProfile(
          cells: <GridPos>[GridPos(x: 1, y: 0)],
        ),
      );
      final bytes =
          (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!;

      expect(_alphaAt(bytes, imageWidth: rendered.width, x: 2, y: 2),
          greaterThan(0));
      expect(_alphaAt(bytes, imageWidth: rendered.width, x: 4, y: 1), 0);
      rendered.dispose();
    });

    test('samples pixel masks exactly like gameplay collision', () async {
      final rendered = await _renderCollisionOverlay(
        ElementCollisionProfile(
          cells: const <GridPos>[],
          collisionMask: ElementCollisionPixelMask(
            widthPx: 2,
            heightPx: 1,
            dataBase64: ElementCollisionMaskCodec.encodePackedBits(
              widthPx: 2,
              heightPx: 1,
              solidPixels: const <bool>[false, true],
            ),
          ),
        ),
      );
      final bytes =
          (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!;

      expect(_alphaAt(bytes, imageWidth: rendered.width, x: 2, y: 1), 0);
      expect(_alphaAt(bytes, imageWidth: rendered.width, x: 3, y: 1), 0);
      expect(_alphaAt(bytes, imageWidth: rendered.width, x: 2, y: 2),
          greaterThan(0));
      expect(_alphaAt(bytes, imageWidth: rendered.width, x: 3, y: 2),
          greaterThan(0));
      rendered.dispose();
    });
  });
}

MapLayersComponent _component({
  required RuntimeTilesetImage atlas,
  required int quarterTurns,
  List<TilesetVisualFrame> frames = const <TilesetVisualFrame>[
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
    ),
  ],
  MapPlacedElementAnimation? animation,
  ElementCollisionProfile? collisionProfile,
  bool applyCollision = true,
  bool includeUnderlyingTileAtNonCollisionCell = false,
  MapLayerRenderPass renderPass = MapLayerRenderPass.background,
}) {
  final tiles = List<int>.filled(
    _mapSize.width * _mapSize.height,
    0,
    growable: false,
  );
  if (includeUnderlyingTileAtNonCollisionCell) {
    final destinationX = _anchor.x;
    final destinationY = _anchor.y + 1;
    tiles[destinationY * _mapSize.width + destinationX] = 1;
  }
  final map = MapData(
    id: 'quarter-turn-render',
    name: 'Quarter turn render',
    size: _mapSize,
    layers: <MapLayer>[
      TileLayer(
        id: 'decor',
        name: 'Decor',
        tilesetId: 'element',
        tiles: tiles,
      ),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'placed',
        layerId: 'decor',
        elementId: 'asymmetric',
        pos: _anchor,
        applyCollision: applyCollision,
        quarterTurns: quarterTurns,
        animation: animation,
      ),
    ],
  );
  return MapLayersComponent(
    bundle: _bundle(
      map: map,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      element: ProjectElementEntry(
        id: 'asymmetric',
        name: 'Asymmetric',
        tilesetId: 'element',
        categoryId: 'decor',
        frames: frames,
        collisionProfile: collisionProfile,
      ),
    ),
    tileImagesByTilesetId: <String, RuntimeTilesetImage>{
      'element': atlas,
    },
    renderPass: renderPass,
  );
}

Future<ui.Image> _renderCollisionOverlay(
  ElementCollisionProfile collisionProfile,
) {
  const tileWidth = 2;
  const tileHeight = 1;
  const mapSize = GridSize(width: 4, height: 4);
  final map = MapData(
    id: 'collision-overlay-rotation',
    name: 'Collision overlay rotation',
    size: mapSize,
    layers: <MapLayer>[
      TileLayer(
        id: 'decor',
        name: 'Decor',
        tilesetId: 'element',
        tiles: List<int>.filled(
          mapSize.width * mapSize.height,
          0,
          growable: false,
        ),
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'placed',
        layerId: 'decor',
        elementId: 'collision-element',
        pos: GridPos(x: 1, y: 1),
        quarterTurns: 1,
      ),
    ],
  );
  final component = MapLayersComponent(
    bundle: _bundle(
      map: map,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      element: ProjectElementEntry(
        id: 'collision-element',
        name: 'Collision element',
        tilesetId: 'element',
        categoryId: 'decor',
        frames: const <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
        collisionProfile: collisionProfile,
      ),
    ),
    tileImagesByTilesetId: const <String, RuntimeTilesetImage>{},
    showCollisionOverlay: true,
  );
  return _render(component);
}

RuntimeMapBundle _bundle({
  required MapData map,
  required int tileWidth,
  required int tileHeight,
  required ProjectElementEntry element,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Quarter turn runtime',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'element',
          name: 'Element',
          relativePath: 'tilesets/element.png',
        ),
      ],
      settings: ProjectSettings(
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        displayScale: 1,
      ),
      elements: <ProjectElementEntry>[element],
    ),
    map: map,
    projectRootDirectory: '/tmp/quarter-turn-runtime-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(
        component.bundle.map.size.width * component.bundle.cellWidth.toInt(),
        component.bundle.map.size.height * component.bundle.cellHeight.toInt(),
      );
}

Future<({ui.Image image, RuntimeTilesetImage runtimeImage})> _asymmetricAtlas({
  required int frameCount,
}) async {
  final width = _sourcePixelSize.width;
  final height = _sourcePixelSize.height * frameCount;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final rgba = _sourceRgba(x, y);
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        Paint()
          ..color = Color.fromARGB(
            rgba[3],
            rgba[0],
            rgba[1],
            rgba[2],
          ),
      );
    }
  }
  final image = await recorder.endRecording().toImage(width, height);
  return (
    image: image,
    runtimeImage: RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: <RuntimeTilesetChunk>[
        RuntimeTilesetChunk(top: 0, height: height, width: width),
      ],
      width: width,
      height: height,
    ),
  );
}

List<int> _sourceRgba(int x, int y) {
  return <int>[
    20 + x * 11,
    25 + y * 23,
    (40 + x * 7 + y * 13) % 256,
    255,
  ];
}

List<int> _rgbaAt(
  ByteData bytes, {
  required int imageWidth,
  required int x,
  required int y,
}) {
  final offset = (y * imageWidth + x) * 4;
  return <int>[
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
}

int _alphaAt(
  ByteData bytes, {
  required int imageWidth,
  required int x,
  required int y,
}) {
  return _rgbaAt(bytes, imageWidth: imageWidth, x: x, y: y)[3];
}
