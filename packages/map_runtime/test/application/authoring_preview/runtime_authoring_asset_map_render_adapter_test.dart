import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_asset_map_render_adapter.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';

import '../../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default loader captures NPCs from dedicated character media', () async {
    final root = await Directory.systemTemp.createTemp('pokemap-npc-render-');
    addTearDown(() => root.delete(recursive: true));
    final file = await _writeAtlas(root, 'npc.png', 32, 32, [0, 0, 255, 255]);
    final base = _npcBundle();
    final bundle = base.copyWith(
      projectRootDirectory: root.path,
      characterAnimationAbsolutePathsByAssetId: {'npc-media': file.path},
    );
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => bundle,
    );

    final result = await adapter.render(_request(bundle));
    final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;

    expect(_pixel(bitmap, 16, 16), [0, 0, 255, 255]);
    expect(result.sourceRevision, _revision('c'));
    expect(result.layerIds, ['decor']);
    expect(result.overlayCounts, isEmpty);
  });

  test(
    'default loader captures NPCs from their regular tileset atlas',
    () async {
      final root = await Directory.systemTemp.createTemp('pokemap-npc-atlas-');
      addTearDown(() => root.delete(recursive: true));
      final file = await _writeAtlas(root, 'npc.png', 64, 64, [0, 255, 0, 255]);
      final base = _npcBundle();
      final character = base.manifest.characters.single.copyWith(
        animations: const [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [
              CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
      );
      final bundle = base.copyWith(
        manifest: base.manifest.copyWith(characters: [character]),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: {'npc-atlas': file.path},
      );
      final adapter = RuntimeAuthoringAssetMapRenderAdapter(
        bundleLoader: (_) async => bundle,
      );

      final result = await adapter.render(_request(bundle));
      final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;

      expect(_pixel(bitmap, 16, 16), [0, 255, 0, 255]);
    },
  );

  test(
    'default loader aliases regular atlas images by their asset ID',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-atlas-alias-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = await _writeAtlas(root, 'tile.png', 32, 32, [
        255,
        0,
        0,
        255,
      ]);
      final base = surfaceTestBundle(
        map: const MapData(
          id: 'atlas-alias',
          name: 'Atlas alias',
          size: GridSize(width: 1, height: 1),
          layers: [
            TileLayer(
              id: 'decor',
              name: 'Decor',
              cells: [1],
              palette: [
                TileLayerPaletteEntry(
                  tilesetId: 'logical-atlas',
                  localTileId: 0,
                ),
              ],
            ),
          ],
        ),
      );
      final bundle = base.copyWith(
        manifest: base.manifest.copyWith(
          tilesets: const [
            ProjectTilesetEntry(
              id: 'logical-atlas',
              name: 'Logical atlas',
              relativePath: 'tile.png',
              source: ProjectRegularAtlasTilesetSource(
                assetId: 'atlas-media',
                pixelWidth: 32,
                pixelHeight: 32,
                tileWidth: 32,
                tileHeight: 32,
              ),
            ),
          ],
        ),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: {'logical-atlas': file.path},
      );
      final adapter = RuntimeAuthoringAssetMapRenderAdapter(
        bundleLoader: (_) async => bundle,
      );

      final result = await adapter.render(_request(bundle));
      final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;

      expect(_pixel(bitmap, 16, 16), [255, 0, 0, 255]);
    },
  );

  test('disposes shared image aliases after a successful capture', () async {
    final image = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
    var disposalCount = 0;
    image.addDisposeListener(() => disposalCount++);
    final bundle = _npcBundle();
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => bundle,
      tilesetImageLoader: (_) async => {
        'npc-atlas': image,
        'character-animation:npc-media': image,
      },
    );

    final result = await adapter.render(_request(bundle));

    expect(_pixel(img.decodePng(Uint8List.fromList(result.bytes))!, 16, 16), [0, 0, 255, 255]);
    expect(image.debugDisposed, isTrue);
    expect(disposalCount, 1);
  });

  test('disposes shared image aliases after capture failure', () async {
    final image = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
    final unavailable = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
    unavailable.dispose();
    var disposalCount = 0;
    image.addDisposeListener(() => disposalCount++);
    final bundle = _npcBundle();
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => bundle,
      tilesetImageLoader: (_) async => {
        'npc-atlas': image,
        'atlas-media': image,
        'character-animation:npc-media': unavailable,
      },
    );

    await expectLater(adapter.render(_request(bundle)), throwsStateError);

    expect(image.debugDisposed, isTrue);
    expect(disposalCount, 1);
  });

  for (final invalid in [false, true]) {
    test(
      'preserves strict loading when an image is ${invalid ? 'corrupt' : 'missing'}',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-invalid-image-',
        );
        addTearDown(() => root.delete(recursive: true));
        final file = File('${root.path}/npc.png');
        if (invalid) await file.writeAsBytes([0, 1, 2, 3]);
        final bundle = _npcBundle().copyWith(
          projectRootDirectory: root.path,
          tilesetAbsolutePathsById: {'npc-atlas': file.path},
        );
        final adapter = RuntimeAuthoringAssetMapRenderAdapter(
          bundleLoader: (_) async => bundle,
        );

        await expectLater(
          adapter.render(_request(bundle)),
          throwsA(isA<Exception>()),
        );
      },
    );
  }

  test('returns asset-accurate bytes bound to the requested map revision',
      () async {
    final map = _map('asset-map');
    final bundle = surfaceTestBundle(
      map: map,
      elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'entity',
          categoryId: 'nature',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
            ),
          ],
        ),
      ],
    );
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => bundle,
      tilesetImageLoader: (_) async => {
        'entity': await runtimeTilesetImage(const [Color(0xFF29B34A)]),
      },
    );

    final result = await adapter.render(
      MapRenderRequest(
        mapResource: AuthoringResourceRef(
          kind: 'map',
          id: map.id,
          revision: _revision('a'),
        ),
        manifest: bundle.manifest.copyWith(
          maps: [
            ProjectMapEntry(
              id: map.id,
              name: map.name,
              relativePath: 'maps/${map.id}.json',
            ),
          ],
        ),
        map: map,
        cellPixelSize: 32,
      ),
    );

    final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;
    final center = bitmap.getPixel(16, 16);
    expect(result.sourceRevision, _revision('a'));
    expect(
      [center.r.toInt(), center.g.toInt(), center.b.toInt(), center.a.toInt()],
      [41, 179, 74, 255],
    );
  });

  test('rejects a bundle loaded from a different map revision', () async {
    final requestedMap = _map('requested');
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) async => surfaceTestBundle(map: _map('loaded')),
      tilesetImageLoader: (_) async => const {},
    );

    expect(
      () => adapter.render(
        MapRenderRequest(
          mapResource: AuthoringResourceRef(
            kind: 'map',
            id: requestedMap.id,
            revision: _revision('b'),
          ),
          manifest: ProjectManifest(
            name: 'Revision test',
            maps: [
              ProjectMapEntry(
                id: requestedMap.id,
                name: requestedMap.name,
                relativePath: 'maps/${requestedMap.id}.json',
              ),
            ],
            tilesets: const [],
          ),
          map: requestedMap,
        ),
      ),
      throwsA(
        isA<ProjectSnapshotException>().having(
          (error) => error.code,
          'code',
          'map.render_revision_mismatch',
        ),
      ),
    );
  });
}

RuntimeMapBundle _npcBundle() {
  final base = surfaceTestBundle(
    map: const MapData(
      id: 'npc-render',
      name: 'NPC render',
      size: GridSize(width: 2, height: 2),
      layers: [
        TileLayer(id: 'decor', name: 'Decor', cells: [0, 0, 0, 0]),
      ],
      entities: [
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 1),
          npc: MapEntityNpcData(characterId: 'npc'),
        ),
      ],
    ),
  );
  return base.copyWith(
    manifest: base.manifest.copyWith(
      characters: const [
        ProjectCharacterEntry(
          id: 'npc',
          name: 'NPC',
          tilesetId: 'npc-atlas',
          frameWidth: 2,
          frameHeight: 2,
          animations: [
            CharacterAnimation(
              state: CharacterAnimationState.idle,
              direction: EntityFacing.south,
              sourceAssetId: 'npc-media',
              frames: [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

MapRenderRequest _request(RuntimeMapBundle bundle, {MapRect? region}) =>
    MapRenderRequest(
      mapResource: AuthoringResourceRef(
        kind: 'map',
        id: bundle.map.id,
        revision: _revision('c'),
      ),
      manifest: bundle.manifest.copyWith(
        maps: [
          ProjectMapEntry(
            id: bundle.map.id,
            name: bundle.map.name,
            relativePath: 'maps/${bundle.map.id}.json',
          ),
        ],
      ),
      map: bundle.map,
      region: region,
      cellPixelSize: 32,
    );

Future<File> _writeAtlas(
  Directory root,
  String name,
  int width,
  int height,
  List<int> color,
) async {
  final image = img.Image(width: width, height: height);
  img.fill(
    image,
    color: img.ColorRgba8(color[0], color[1], color[2], color[3]),
  );
  return File('${root.path}/$name').writeAsBytes(img.encodePng(image));
}

List<int> _pixel(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt()];
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 1, height: 1),
      layers: const [
        MapLayer.tile(id: 'decor', name: 'Decor', cells: [0]),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'tree-1',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';
