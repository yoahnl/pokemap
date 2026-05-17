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
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Building runtime occlusion golden slice', () {
    test(
      'building runtime occlusion draws roof patch above player when player is behind',
      () async {
        final patch = PlacedElementOcclusionPatchComponent(
          instruction: _buildingRoofInstruction(flamePriority: 1112),
          tilesetImage: await _solidRuntimeTilesetImage(
            width: _buildingSourceWidthPx,
            height: _buildingSourceHeightPx,
            color: _roofColor,
          ),
        );
        final player = _PlayerProbeComponent(
          priority: 1088,
          position: Vector2(40, 24),
        );

        expect(patch.priority, greaterThan(player.priority));

        final image = await _renderByPriority(
          [player, patch],
          width: _buildingSourceWidthPx,
          height: _buildingSourceHeightPx,
        );

        expect(await pixelAt(image, 44, 32), rgba(255, 216, 48, 255));
      },
    );

    test(
      'building runtime occlusion lets player render above roof patch when player is in front',
      () async {
        final patch = PlacedElementOcclusionPatchComponent(
          instruction: _buildingRoofInstruction(flamePriority: 1112),
          tilesetImage: await _solidRuntimeTilesetImage(
            width: _buildingSourceWidthPx,
            height: _buildingSourceHeightPx,
            color: _roofColor,
          ),
        );
        final player = _PlayerProbeComponent(
          priority: 1128,
          position: Vector2(40, 24),
        );

        expect(player.priority, greaterThan(patch.priority));

        final image = await _renderByPriority(
          [patch, player],
          width: _buildingSourceWidthPx,
          height: _buildingSourceHeightPx,
        );

        expect(await pixelAt(image, 44, 32), rgba(32, 96, 255, 255));
      },
    );

    test(
      'PlayableMapGame mounts a building roof occlusion patch with actor depth priority',
      () async {
        final game = _game(bundle: _buildingBundle());

        await _load(game);

        final patches = _occlusionPatches(game);
        expect(patches, hasLength(1));

        final patch = patches.single;
        expect(patch.instruction.placedElementId, 'blue-roof-house-1');
        expect(patch.instruction.elementId, 'blue-roof-house');
        expect(patch.instruction.occlusionMask.widthPx, _buildingSourceWidthPx);
        expect(
          patch.instruction.occlusionMask.heightPx,
          _buildingSourceHeightPx,
        );
        expect(patch.debugDrawRunCount, _roofMaskHeightPx);
        expect(patch.priority, patch.instruction.flamePriority);
        expect(patch.priority, (1000 + patch.instruction.depthSortY).round());
        expect(
          patch.instruction.depthSortY,
          patch.position.y + patch.size.y,
        );

        final player = _players(game).single;
        expect(player.priority, 1000 + player.footPoint.y.round());
      },
    );
  });
}

const _tileSize = 16;
const _buildingSourceWidthTiles = 6;
const _buildingSourceHeightTiles = 7;
const _buildingSourceWidthPx = _buildingSourceWidthTiles * _tileSize;
const _buildingSourceHeightPx = _buildingSourceHeightTiles * _tileSize;
const _roofMaskHeightPx = 3 * _tileSize;
const _roofColor = Color(0xFFFFD830);
const _playerColor = Color(0xFF2060FF);

StaticPlacedElementOcclusionPatchInstruction _buildingRoofInstruction({
  required int flamePriority,
}) {
  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: 'building-runtime-map',
    placedElementId: 'blue-roof-house-1',
    elementId: 'blue-roof-house',
    layerId: 'buildings',
    tilesetId: 'building',
    sourceLeftPx: 0,
    sourceTopPx: 0,
    sourceWidthPx: _buildingSourceWidthPx,
    sourceHeightPx: _buildingSourceHeightPx,
    worldLeft: 0,
    worldTop: 0,
    visualWidth: _buildingSourceWidthPx.toDouble(),
    visualHeight: _buildingSourceHeightPx.toDouble(),
    depthSortY: _buildingSourceHeightPx.toDouble(),
    flamePriority: flamePriority,
    opacity: 1,
    occlusionMask: _roofOcclusionMask(),
  );
}

Future<ui.Image> _renderByPriority(
  List<PositionComponent> components, {
  required int width,
  required int height,
}) {
  final ordered = [...components]
    ..sort((a, b) => a.priority.compareTo(b.priority));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (final component in ordered) {
    canvas.save();
    canvas.translate(component.position.x, component.position.y);
    component.render(canvas);
    canvas.restore();
  }
  return recorder.endRecording().toImage(width, height);
}

class _PlayerProbeComponent extends PositionComponent {
  _PlayerProbeComponent({
    required int priority,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(12, 24),
        ) {
    this.priority = priority;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..isAntiAlias = false
        ..color = _playerColor,
    );
  }
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
}) {
  return PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/building-runtime-occlusion-project.json',
    runtimeTilesetImageLoader: (
      absolutePathByTilesetId, {
      transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
    }) async {
      final out = <String, RuntimeTilesetImage>{};
      if (absolutePathByTilesetId.containsKey('player')) {
        out['player'] = await _solidRuntimeTilesetImage(
          width: 16,
          height: 32,
          color: _playerColor,
        );
      }
      if (absolutePathByTilesetId.containsKey('building')) {
        out['building'] = await _solidRuntimeTilesetImage(
          width: _buildingSourceWidthPx,
          height: _buildingSourceHeightPx,
          color: _roofColor,
        );
      }
      return out;
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(256, 256));
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

List<PlayerComponent> _players(PlayableMapGame game) {
  return game.world.children.whereType<PlayerComponent>().toList(
        growable: false,
      );
}

RuntimeMapBundle _buildingBundle() {
  final occlusionMask = _roofOcclusionMask();
  final collisionMask = _baseCollisionMask();
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Building Runtime Occlusion Golden Slice',
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
          id: 'blue-roof-house',
          name: 'Blue Roof House',
          tilesetId: 'building',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: _buildingSourceWidthTiles,
                height: _buildingSourceHeightTiles,
              ),
            ),
          ],
          collisionProfile: ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            collisionMask: collisionMask,
            occlusionMask: occlusionMask,
          ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'building-runtime-map',
      name: 'Building Runtime Map',
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
          id: 'blue-roof-house-1',
          layerId: 'buildings',
          elementId: 'blue-roof-house',
          pos: GridPos(x: 1, y: 1),
          applyCollision: true,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'player-start'),
    ),
    projectRootDirectory: '/tmp/building-runtime-occlusion-test',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'building': '/tmp/building.png',
    },
  );
}

ElementCollisionPixelMask _roofOcclusionMask() {
  return _mask(
    widthPx: _buildingSourceWidthPx,
    heightPx: _buildingSourceHeightPx,
    isSolid: (_, y) => y < _roofMaskHeightPx,
  );
}

ElementCollisionPixelMask _baseCollisionMask() {
  return _mask(
    widthPx: _buildingSourceWidthPx,
    heightPx: _buildingSourceHeightPx,
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
