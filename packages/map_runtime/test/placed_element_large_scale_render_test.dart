import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('large placed element rendering', () {
    test('does not visit an element that only touches the viewport boundary',
        () async {
      final atlas = await _largeAtlas();
      addTearDown(atlas.dispose);
      final profiles = <MapLayersRenderProfile>[];
      final component = _component(
        atlas: atlas,
        source: const TilesetSourceRect(
          x: 0,
          y: 0,
          width: 192,
          height: 192,
        ),
        pos: const GridPos(x: 192, y: 0),
        profiles: profiles,
      )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 192, 192));

      final rendered = await _renderRegion(
        component,
        region: const Rect.fromLTWH(0, 0, 192, 192),
      );
      addTearDown(rendered.dispose);

      expect(profiles, hasLength(1));
      expect(profiles.single.placedElementCandidateVisits, 0);
      expect(await _alphaAt(rendered, 191, 96), 0);
    });

    test('renders a partially visible 128x128 atlas source', () async {
      final atlas = await _largeAtlas();
      addTearDown(atlas.dispose);
      final component = _component(
        atlas: atlas,
        source: const TilesetSourceRect(
          x: 64,
          y: 32,
          width: 128,
          height: 128,
        ),
        pos: const GridPos(x: 40, y: 50),
      )..setVisibleLocalRect(const Rect.fromLTWH(120, 110, 4, 4));

      final rendered = await _renderRegion(
        component,
        region: const Rect.fromLTWH(120, 110, 4, 4),
      );
      addTearDown(rendered.dispose);

      expect(await _rgbaAt(rendered, 2, 2), <int>[22, 170, 74, 255]);
    });

    test('culls and renders from the rotated destination footprint', () async {
      final atlas = await _largeAtlas();
      addTearDown(atlas.dispose);
      final profiles = <MapLayersRenderProfile>[];
      final component = _component(
        atlas: atlas,
        source: const TilesetSourceRect(
          x: 64,
          y: 32,
          width: 128,
          height: 64,
        ),
        pos: const GridPos(x: 20, y: 30),
        quarterTurns: 1,
        profiles: profiles,
      )..setVisibleLocalRect(const Rect.fromLTWH(82, 156, 2, 2));

      final rendered = await _renderRegion(
        component,
        region: const Rect.fromLTWH(82, 156, 2, 2),
      );
      addTearDown(rendered.dispose);

      expect(profiles.single.placedElementCandidateVisits, 1);
      expect(await _alphaAt(rendered, 1, 1), 255);
    });
  });
}

MapLayersComponent _component({
  required RuntimeTilesetImage atlas,
  required TilesetSourceRect source,
  required GridPos pos,
  int quarterTurns = 0,
  List<MapLayersRenderProfile>? profiles,
}) {
  return MapLayersComponent(
    bundle: RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Large element test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'atlas',
            name: 'Atlas',
            relativePath: 'atlas.png',
          ),
        ],
        settings: const ProjectSettings(
          tileWidth: 1,
          tileHeight: 1,
          displayScale: 1,
        ),
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'building',
            name: 'Building',
            tilesetId: 'atlas',
            categoryId: 'buildings',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(source: source),
            ],
          ),
        ],
      ),
      map: MapData(
        id: 'large-element-map',
        name: 'Large element map',
        size: const GridSize(width: 512, height: 512),
        layers: const <MapLayer>[
          MapLayer.tile(id: 'decor', name: 'Decor'),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'building-1',
            layerId: 'decor',
            elementId: 'building',
            pos: pos,
            quarterTurns: quarterTurns,
          ),
        ],
      ),
      projectRootDirectory: '/tmp/large-element-test',
      tilesetAbsolutePathsById: const <String, String>{},
    ),
    tileImagesByTilesetId: <String, RuntimeTilesetImage>{'atlas': atlas},
    debugOnRenderProfile: profiles?.add,
  );
}

Future<RuntimeTilesetImage> _largeAtlas() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(64, 32, 128, 128),
    Paint()..color = const Color(0xFF16AA4A),
  );
  final image = await recorder.endRecording().toImage(256, 256);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 256, width: 256),
    ],
    width: 256,
    height: 256,
  );
}

Future<ui.Image> _renderRegion(
  MapLayersComponent component, {
  required Rect region,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..translate(-region.left, -region.top)
    ..clipRect(region);
  component.render(canvas);
  return recorder.endRecording().toImage(
        region.width.ceil(),
        region.height.ceil(),
      );
}

Future<int> _alphaAt(ui.Image image, int x, int y) async =>
    (await _rgbaAt(image, x, y))[3];

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return <int>[
    bytes!.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
}
