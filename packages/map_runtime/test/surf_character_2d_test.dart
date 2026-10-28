import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/field_move_dialogue.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disabled Surf has no prompt', () {
    expect(surfEvaluationToYarnNode(const SurfDisabled()), isNull);
  });

  test('Surf player uses Character idle and moving clips', () async {
    final player = _player(MovementMode.surf);
    await player.onLoad();
    expect(player.debugAnimationSource?.sourceRect.left, 32);
    player.startStep(
      _state(MovementMode.surf, x: 1),
      animationState: CharacterAnimationState.surf,
    );
    expect(player.debugAnimationSource?.sourceRect.left, 64);
    player.update(.25);
    expect(player.debugAnimationSource?.sourceRect.left, 32);
  });

  test(
    'Surf entry and exit clips complete once despite state synchronization',
    () async {
      final player = _player(MovementMode.walk);
      await player.onLoad();
      player.syncState(_state(MovementMode.surf));
      expect(player.debugAnimationSource?.sourceRect.left, 96);
      player.syncState(_state(MovementMode.surf));
      expect(player.debugAnimationSource?.sourceRect.left, 96);
      player.syncState(_state(MovementMode.walk));
      expect(player.debugAnimationSource?.sourceRect.left, 128);
      final actor = OverworldActorComponent(
        character: _character(),
        tileImages: _images,
        tileWidth: 16,
        tileHeight: 16,
        cellWidth: 16,
        cellHeight: 16,
      );
      actor.setMotion(EntityFacing.south, CharacterAnimationState.surfEnter);
      actor.update(.11);
      expect(actor.debugAnimationSource?.sourceRect.left, 32);
      actor.setMotion(EntityFacing.south, CharacterAnimationState.surfExit);
      actor.update(.11);
      expect(actor.debugAnimationSource?.sourceRect.left, 0);
    },
  );

  test(
    'legacy characters keep walk and idle fallbacks while surfing',
    () async {
      final player = _player(MovementMode.surf, legacy: true);
      await player.onLoad();
      expect(player.debugAnimationSource?.sourceRect.left, 0);
      player.startStep(
        _state(MovementMode.surf, x: 1),
        animationState: CharacterAnimationState.surf,
      );
      expect(player.debugAnimationSource?.sourceRect.left, 16);
    },
  );

  test('restoring base cancels a pending Surf presentation transition', () {
    final actor = OverworldActorComponent(
      character: _character(),
      tileImages: _images,
      tileWidth: 16,
      tileHeight: 16,
      cellWidth: 16,
      cellHeight: 16,
    );
    actor.setMotion(EntityFacing.south, CharacterAnimationState.surfEnter);
    actor.restoreBase(EntityFacing.south);
    actor.update(.11);
    expect(actor.debugAnimationSource?.sourceRect.left, 0);
  });

  test('Surf animation phase survives adjacent move and idle transitions', () {
    final actor = OverworldActorComponent(
      character: _character(),
      tileImages: _images,
      tileWidth: 16,
      tileHeight: 16,
      cellWidth: 16,
      cellHeight: 16,
    );
    actor.setMotion(EntityFacing.south, CharacterAnimationState.surf);
    actor.update(.06);
    actor.setMotion(EntityFacing.south, CharacterAnimationState.surfIdle);
    actor.setMotion(EntityFacing.south, CharacterAnimationState.surf);
    actor.update(.06);
    expect(actor.debugAnimationSource?.sourceRect.left, 80);
  });
}

final _images = {
  characterAnimationRuntimeImageId('hero'): RuntimeTilesetImage(
    images: const [],
    chunks: const [],
    width: 512,
    height: 64,
  ),
};

ProjectCharacterEntry _character({bool legacy = false}) =>
    ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'hero',
      animations: [
        for (final entry in <CharacterAnimationState, int>{
          CharacterAnimationState.idle: 0,
          CharacterAnimationState.walk: 16,
          if (!legacy) ...{
            CharacterAnimationState.surfIdle: 32,
            CharacterAnimationState.surf: 64,
            CharacterAnimationState.surfEnter: 96,
            CharacterAnimationState.surfExit: 128,
          },
        }.entries)
          CharacterAnimation(
            state: entry.key,
            direction: EntityFacing.south,
            sourceAssetId: 'hero',
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(
                  x: entry.value,
                  y: 0,
                  width: 16,
                  height: 16,
                ),
                durationMs: 100,
              ),
              if (entry.key == CharacterAnimationState.surf)
                const CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 80, y: 0, width: 16, height: 16),
                  durationMs: 100,
                ),
            ],
          ),
      ],
    );

GameplayPlayerState _state(MovementMode mode, {int x = 0}) =>
    GameplayPlayerState.fromGridSpawn(
      cell: GridPos(x: x, y: 0),
      facing: Direction.south,
      tileWidthPx: 16,
      tileHeightPx: 16,
      mapWidthCells: 8,
      mapHeightCells: 8,
    ).copyWith(movementMode: mode);

PlayerComponent _player(MovementMode mode, {bool legacy = false}) =>
    PlayerComponent(
      bundle: RuntimeMapBundle(
        manifest: const ProjectManifest(name: 'Surf', maps: [], tilesets: []),
        map: const MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 8, height: 8),
        ),
        projectRootDirectory: '/Users/karim/Library/Caches/AveluneQA/surf-v1',
        tilesetAbsolutePathsById: const {},
      ),
      state: _state(mode),
      characterEntry: _character(legacy: legacy),
      tileImages: _images,
      mapOrigin: Vector2.zero(),
    );
