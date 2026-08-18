import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'trainer_spot_map';
const _trainerId = 'trainer_spot_001';
const _entityId = 'npc_trainer_spot';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BETA-TRN-001 a trainer spots the player before fighting', () {
    test('the exclamation precedes the approach, which precedes the battle',
        () async {
      final game = await _loadGame(_bundle());

      expect(
        _emoteOverlay(game),
        isNull,
        reason: 'nothing hangs over the trainer before it spots anyone',
      );

      await _stepRight(game);

      // La ligne de vue ne déclenche plus le combat directement : le dresseur
      // signale d'abord qu'il a vu le joueur. Flame monte le composant au tick
      // suivant, mais bien avant la fin de l'exclamation.
      await _pumpUntil(game, () => _emoteOverlay(game) != null, maxTicks: 30);
      expect(
        _trainerPos(game),
        const GridPos(x: 4, y: 1),
        reason: 'the trainer has not moved yet',
      );
      expect(game.debugPendingBattleRequest, isNull);

      await _pumpUntil(game, () => _emoteOverlay(game) == null);
      await _pumpUntil(
        game,
        () => _trainerPos(game) == const GridPos(x: 2, y: 1),
        maxTicks: 900,
      );

      // Le dresseur s'arrête sur la case voisine du joueur, puis seulement le
      // combat part.
      await _pumpUntil(game, () => game.debugPendingBattleRequest != null);
    });

    test('the player cannot move or act while the trainer walks over', () async {
      final game = await _loadGame(_bundle());
      await _stepRight(game);

      final playerPos = game.gameStateSnapshot.playerPosition;
      expect(
        game.inputAuthoritySnapshot.acceptsOverworldInput,
        isFalse,
        reason: 'a spotted player watches, they do not keep walking',
      );

      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      );
      await _pumpFrames(game, 60);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );

      expect(game.gameStateSnapshot.playerPosition, playerPos);
    });

    test('a trainer already next to the player reacts without walking',
        () async {
      // Le dresseur posté juste à côté n'a aucune case à rejoindre. Il doit
      // quand même marquer le repérage puis engager, sans rester coincé à
      // attendre un déplacement qui n'aura pas lieu.
      final game = await _loadGame(_bundle(trainerAt: const GridPos(x: 2, y: 1)));
      await _stepRight(game);

      await _pumpUntil(game, () => _emoteOverlay(game) != null, maxTicks: 30);
      await _pumpUntil(
        game,
        () => game.debugPendingBattleRequest != null,
        maxTicks: 900,
      );

      expect(
        _trainerPos(game),
        const GridPos(x: 2, y: 1),
        reason: 'it was already in place',
      );
    });

    test('the encounter always gives the input back', () async {
      // Le verrou joueur est dérivé de la séquence : quand elle se termine,
      // par un combat comme par un abandon, plus rien ne doit le retenir.
      final game = await _loadGame(_bundle());
      await _stepRight(game);
      await _pumpUntil(
        game,
        () => game.debugPendingBattleRequest != null,
        maxTicks: 900,
      );

      expect(
        game.debugInputLockSnapshot.isOwnedBy(
          RuntimeInputLockOwner.trainerEncounter,
        ),
        isFalse,
        reason: 'the trainer lock must not outlive the sequence',
      );
    });
  });
}

PositionComponent? _emoteOverlay(PlayableMapGame game) {
  for (final child in game.world.children) {
    if (child is PositionComponent && child.priority == 200000) {
      return child;
    }
  }
  return null;
}

GridPos _trainerPos(PlayableMapGame game) {
  final pos = game.debugMapEntityPosition(_entityId);
  if (pos == null) fail('the trainer entity vanished from the map');
  return pos;
}

RuntimeMapBundle _bundle({GridPos trainerAt = const GridPos(x: 4, y: 1)}) {
  final manifest = ProjectManifest(
    name: 'BETA-TRN-001 trainer spot',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: _mapId,
        relativePath: 'maps/$_mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'char_spot',
        name: 'Dresseur guetteur',
        tilesetId: 'tileset_spot',
      ),
    ],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'Dresseur guetteur',
        trainerClass: 'Dresseur',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'pikachu', level: 5),
        ],
      ),
    ],
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: MapData(
      id: _mapId,
      name: _mapId,
      size: const GridSize(width: 6, height: 3),
      layers: const <MapLayer>[MapLayer.object(id: 'objects', name: 'Objects')],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        MapEntity(
          id: _entityId,
          name: 'Dresseur guetteur',
          kind: MapEntityKind.npc,
          pos: trainerAt,
          npc: const MapEntityNpcData(
            displayName: 'Dresseur guetteur',
            trainerId: _trainerId,
            characterId: 'char_spot',
            facing: EntityFacing.west,
            lineOfSightRange: 4,
          ),
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/beta_trn_001_trainer_spot',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

final class _TestGame extends PlayableMapGame {
  _TestGame({required super.bundle, required super.projectFilePath});

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

Future<PlayableMapGame> _loadGame(RuntimeMapBundle bundle) async {
  final game = _TestGame(
    bundle: bundle,
    projectFilePath: '${bundle.projectRootDirectory}/project.json',
  );
  game.onGameResize(Vector2(640, 480));
  await game.onLoad().timeout(const Duration(seconds: 5));
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  return game;
}

Future<void> _stepRight(PlayableMapGame game) async {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.right),
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.right),
  );
  for (var i = 0; i < 180; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping) return;
  }
  fail('Timed out waiting for the movement step to settle.');
}

Future<void> _pumpFrames(PlayableMapGame game, int count) async {
  for (var i = 0; i < count; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the trainer spot sequence.');
}
