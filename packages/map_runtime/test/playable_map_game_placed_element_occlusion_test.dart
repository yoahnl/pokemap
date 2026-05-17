import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame placed element occlusion patches', () {
    test(
        'mounts static occlusion patches for placed elements with occlusionMask',
        () async {
      final game = _game(bundle: _bundle());

      await _load(game);

      final patches = _occlusionPatches(game);
      expect(patches, hasLength(1));
      expect(patches.single.priority, 1064);
      expect(patches.single.position.x, 32);
      expect(patches.single.position.y, 32);
    });

    test('does not mount occlusion patch when occlusionMask is absent',
        () async {
      final game = _game(
        bundle: _bundle(includeOcclusionMask: false),
      );

      await _load(game);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('mounts occlusion patch even when applyCollision is false', () async {
      final game = _game(
        bundle: _bundle(applyCollision: false),
      );

      await _load(game);

      expect(_occlusionPatches(game), hasLength(1));
    });

    test('skips occlusion patch when RuntimeTilesetImage is missing', () async {
      final game = _game(
        bundle: _bundle(),
        includeElementTilesetImage: false,
      );

      await _load(game);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('removes occlusion patches when loaded map is unmounted', () async {
      final game = _game(bundle: _bundle());
      await _load(game);

      expect(_occlusionPatches(game), hasLength(1));

      game.debugUnmountLoadedMapForTest('occlusion-map');
      game.update(0);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('repositions occlusion patches with loaded map origin changes',
        () async {
      final game = _game(bundle: _bundle());
      await _load(game);

      game.debugRepositionLoadedMapForTest(
        mapId: 'occlusion-map',
        originCellX: 1,
        originCellY: 0,
      );
      game.update(0);

      var patch = _occlusionPatches(game).single;
      expect(patch.position.x, 64);
      expect(patch.position.y, 32);
      expect(patch.priority, 1064);

      game.debugRepositionLoadedMapForTest(
        mapId: 'occlusion-map',
        originCellX: 2,
        originCellY: 1,
      );
      game.update(0);

      patch = _occlusionPatches(game).single;
      expect(patch.position.x, 96);
      expect(patch.position.y, 64);
      expect(patch.priority, 1096);
    });
  });
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
  bool includeElementTilesetImage = true,
}) {
  return PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/occlusion-project.json',
    runtimeTilesetImageLoader: (
      absolutePathByTilesetId, {
      transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
    }) async {
      final out = <String, RuntimeTilesetImage>{};
      if (absolutePathByTilesetId.containsKey('player')) {
        out['player'] = await _runtimeTilesetImage(
          width: 16,
          height: 32,
          color: const Color(0xFF4070FF),
        );
      }
      if (includeElementTilesetImage &&
          absolutePathByTilesetId.containsKey('entity')) {
        out['entity'] = await _runtimeTilesetImage(
          width: 16,
          height: 16,
          color: const Color(0xFFFF0000),
        );
      }
      return out;
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(128, 128));
  await game.onLoad();
  game.update(0);
}

List<PlacedElementOcclusionPatchComponent> _occlusionPatches(
  PlayableMapGame game,
) {
  return game.world.children
      .whereType<PlacedElementOcclusionPatchComponent>()
      .toList(growable: false);
}

RuntimeMapBundle _bundle({
  bool includeOcclusionMask = true,
  bool applyCollision = true,
}) {
  final occlusionMask = includeOcclusionMask ? _mask() : null;
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Playable Occlusion Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
        ProjectTilesetEntry(
          id: 'entity',
          name: 'Entity',
          relativePath: 'tilesets/entity.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 1,
          frameHeight: 2,
        ),
      ],
      elements: [
        ProjectElementEntry(
          id: 'house',
          name: 'House',
          tilesetId: 'entity',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
          collisionProfile: occlusionMask == null
              ? null
              : ElementCollisionProfile(
                  source: ElementCollisionProfileSource.manual,
                  occlusionMask: occlusionMask,
                ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: MapData(
      id: 'occlusion-map',
      name: 'Occlusion Map',
      size: const GridSize(width: 4, height: 4),
      layers: const [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: const [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'house-1',
          layerId: 'objects',
          elementId: 'house',
          pos: const GridPos(x: 1, y: 1),
          applyCollision: applyCollision,
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/occlusion-runtime-test',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'entity': '/tmp/entity.png',
    },
  );
}

ElementCollisionPixelMask _mask() {
  final bits = List<bool>.filled(16 * 16, false);
  bits[0] = true;
  return ElementCollisionPixelMask(
    widthPx: 16,
    heightPx: 16,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 16,
      heightPx: 16,
      solidPixels: bits,
    ),
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage({
  required int width,
  required int height,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(top: 0, height: height, width: width),
    ],
    width: width,
    height: height,
  );
}
