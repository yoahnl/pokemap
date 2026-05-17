import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Runtime occlusion visual smoke', () {
    test('playable runtime building occlusion smoke renders without exception',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/runtime-occlusion-visual-smoke/project.json',
        runtimeTilesetImageLoader: _loadRuntimeImages,
      );

      game.onGameResize(Vector2(256, 192));
      await game.onLoad();
      game.update(0);

      final patches = game.world.children
          .whereType<PlacedElementOcclusionPatchComponent>()
          .toList(growable: false);
      final players = game.world.children
          .whereType<PlayerComponent>()
          .toList(growable: false);

      expect(patches, hasLength(1));
      expect(players, hasLength(1));
      expect(patches.single.priority, patches.single.instruction.flamePriority);
      expect(
        patches.single.priority,
        (1000 + patches.single.instruction.depthSortY).round(),
      );
      expect(
        players.single.priority,
        1000 + players.single.footPoint.y.round(),
      );

      final image = await _renderGame(game, width: 256, height: 192);

      expect(image.width, 256);
      expect(image.height, 192);
    });
  });
}

const _tileSize = 16;
const _buildingWidthTiles = 6;
const _buildingHeightTiles = 7;
const _buildingWidthPx = _buildingWidthTiles * _tileSize;
const _buildingHeightPx = _buildingHeightTiles * _tileSize;
const _roofHeightPx = 3 * _tileSize;

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Occlusion Visual Smoke',
      maps: const <ProjectMapEntry>[],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
        ProjectTilesetEntry(
          id: 'building',
          name: 'Building',
          relativePath: 'tilesets/building.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: _tileSize,
        tileHeight: _tileSize,
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
      elementCategories: const [
        ProjectElementCategory(id: 'buildings', name: 'Buildings'),
      ],
      elements: [
        ProjectElementEntry(
          id: 'visual-smoke-house',
          name: 'Visual Smoke House',
          tilesetId: 'building',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: _buildingWidthTiles,
                height: _buildingHeightTiles,
              ),
            ),
          ],
          collisionProfile: ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            collisionMask: _baseCollisionMask(),
            occlusionMask: _roofOcclusionMask(),
          ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'runtime-occlusion-visual-smoke-map',
      name: 'Runtime Occlusion Visual Smoke Map',
      size: GridSize(width: 10, height: 10),
      layers: [
        MapLayer.object(id: 'buildings', name: 'Buildings'),
      ],
      entities: [
        MapEntity(
          id: 'player-start',
          name: 'Player Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 3, y: 5),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'visual-smoke-house-1',
          layerId: 'buildings',
          elementId: 'visual-smoke-house',
          pos: GridPos(x: 1, y: 1),
          applyCollision: true,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'player-start'),
    ),
    projectRootDirectory: '/tmp/runtime-occlusion-visual-smoke',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'building': '/tmp/building.png',
    },
  );
}

Future<Map<String, RuntimeTilesetImage>> _loadRuntimeImages(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  final images = <String, RuntimeTilesetImage>{};
  if (absolutePathByTilesetId.containsKey('player')) {
    images['player'] = await _solidRuntimeTilesetImage(
      width: 16,
      height: 32,
      color: const Color(0xFF2060FF),
    );
  }
  if (absolutePathByTilesetId.containsKey('building')) {
    images['building'] = await _solidRuntimeTilesetImage(
      width: _buildingWidthPx,
      height: _buildingHeightPx,
      color: const Color(0xFFFFD830),
    );
  }
  return images;
}

Future<ui.Image> _renderGame(
  PlayableMapGame game, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  game.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

ElementCollisionPixelMask _roofOcclusionMask() {
  return _mask(
    widthPx: _buildingWidthPx,
    heightPx: _buildingHeightPx,
    isSolid: (_, y) => y < _roofHeightPx,
  );
}

ElementCollisionPixelMask _baseCollisionMask() {
  return _mask(
    widthPx: _buildingWidthPx,
    heightPx: _buildingHeightPx,
    isSolid: (_, y) => y >= 5 * _tileSize,
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  required bool Function(int x, int y) isSolid,
}) {
  final bits = List<bool>.filled(widthPx * heightPx, false);
  for (var y = 0; y < heightPx; y++) {
    for (var x = 0; x < widthPx; x++) {
      bits[y * widthPx + x] = isSolid(x, y);
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: bits,
    ),
  );
}

Future<RuntimeTilesetImage> _solidRuntimeTilesetImage({
  required int width,
  required int height,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()
      ..isAntiAlias = false
      ..color = color,
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
