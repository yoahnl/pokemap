import 'dart:async';
import 'dart:io';

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

    test('the player cannot move or act while the trainer walks over',
        () async {
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
      final game =
          await _loadGame(_bundle(trainerAt: const GridPos(x: 2, y: 1)));
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

    test('a spotted trainer approaches, speaks and starts its authored battle',
        () async {
      final releaseBattle = Completer<void>();
      final game = await _loadGame(
        _narrativeBundle(withDialogue: true),
        beforeBattleHandoffPreparation: () => releaseBattle.future,
      );
      await _stepRight(game);
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue',
          maxTicks: 900);
      expect(_trainerPos(game), const GridPos(x: 2, y: 1));
      expect(game.debugHasPendingSceneBattle, isFalse);
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(game, () => game.debugHasPendingSceneBattle,
          maxTicks: 900);

      expect(_trainerPos(game), const GridPos(x: 2, y: 1));
      expect(game.debugHasPendingSceneBattle, isTrue);
      expect(game.debugFlowPhaseName, 'battleTransition');
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
      releaseBattle.complete();
      await _pumpUntil(game, () => !game.debugHasPendingSceneBattle);
    });

    test('an ineligible authored Event never falls back to a direct battle',
        () async {
      final game = await _loadGame(_narrativeBundle(enabled: false));
      await _stepRight(game);
      await _pumpFrames(game, 900);

      expect(game.debugPendingBattleRequest, isNull);
      expect(game.debugHasPendingSceneBattle, isFalse);
      expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
    });

    test('a defeated team variant does not spot the player again', () async {
      final game = await _loadGame(_narrativeBundle());
      game.debugMarkTrainerAsDefeated('trainer_spot_variant');
      await _stepRight(game);
      await _pumpFrames(game, 900);

      expect(_trainerPos(game), const GridPos(x: 4, y: 1));
      expect(_emoteOverlay(game), isNull);
      expect(game.debugPendingBattleRequest, isNull);
    });

    test('an inactive legacy Event cannot suppress a native trainer', () async {
      final game = await _loadGame(
          _narrativeBundle(eventMode: EventSystemMode.legacyOnly));
      game.debugMarkTrainerAsDefeated('trainer_spot_variant');
      await _stepRight(game);
      await _pumpUntil(game, () => game.debugPendingBattleRequest != null,
          maxTicks: 900);
      expect(game.debugPendingBattleRequest!.toJson()['trainerId'], _trainerId);
    });
  });
}

RuntimeMapBundle _narrativeBundle({
  bool enabled = true,
  bool withDialogue = false,
  EventSystemMode eventMode = EventSystemMode.v2Only,
}) {
  final base = _bundle();
  final manifest = base.manifest.toJson();
  var projectRoot = base.projectRootDirectory;
  if (withDialogue) {
    final directory = Directory.systemTemp.createTempSync('trainer-spot-');
    projectRoot = directory.path;
    addTearDown(() => directory.deleteSync(recursive: true));
    File('$projectRoot/challenge.yarn').writeAsStringSync('''
title: Challenge
---
Dresseur: Tu as croisé mon regard. Je te défie !
===
''');
    manifest['dialogues'] = [
      const ProjectDialogueEntry(
        id: 'trainer_challenge',
        name: 'Défi',
        relativePath: 'challenge.yarn',
        defaultStartNode: 'Challenge',
      ).toJson(),
    ];
  }
  manifest['trainers'] = [
    ...base.manifest.trainers.map((trainer) => trainer.toJson()),
    base.manifest.trainers.first.copyWith(id: 'trainer_spot_variant').toJson(),
  ];
  manifest['scenes'] = [
    {
      'id': 'trainer_spot_scene',
      'name': 'Défi du dresseur',
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          if (withDialogue)
            {
              'id': 'challenge',
              'kind': 'yarnDialogue',
              'payload': {
                'kind': 'yarnDialogue',
                'dialogueId': 'trainer_challenge',
                'yarnNodeName': 'Challenge',
                'expectedOutcomes': [],
                'speakerHints': [],
              },
            },
          {
            'id': 'battle',
            'kind': 'battle',
            'payload': {
              'kind': 'battle',
              'battleKind': 'trainer',
              'trainerId': 'trainer_spot_variant',
              'declaredOutcomes': ['victory', 'defeat'],
            },
          },
          {
            'id': 'end',
            'kind': 'end',
            'payload': {
              'kind': 'end',
              'sceneOutcomeId': 'completed',
              'outcomePolicy': 'progression',
            },
          },
        ],
        'edges': [
          {
            'id': 'begin',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': withDialogue ? 'challenge' : 'battle',
            'kind': 'default',
          },
          if (withDialogue)
            {
              'id': 'challenged',
              'fromNodeId': 'challenge',
              'fromPortId': 'completed',
              'toNodeId': 'battle',
              'kind': 'default',
            },
          for (final outcome in ['victory', 'defeat'])
            {
              'id': outcome,
              'fromNodeId': 'battle',
              'fromPortId': outcome,
              'toNodeId': 'end',
              'kind': outcome == 'victory' ? 'battleVictory' : 'battleDefeat',
            },
        ],
      },
      'declaredOutcomes': [
        {'id': 'completed', 'label': 'Terminé'},
      ],
    },
  ];
  manifest['eventRegistry'] = {
    'schemaVersion': 1,
    'mode': eventMode.name,
    'legacyClaims': [],
    'records': [
      {
        'state': 'configured',
        'enabled': enabled,
        'definition': {
          'id': 'evt_019abcde-7000-7000-8000-000000000061',
          'name': 'Défi du dresseur',
          'source': {
            'kind': 'entityInteract',
            'mapId': _mapId,
            'entityId': _entityId,
          },
          'conditions': [],
          'sceneId': 'trainer_spot_scene',
          'reusePolicy': 'reusable',
          'priority': 50,
          'order': 0,
        },
      },
    ],
  };
  return RuntimeMapBundle(
    manifest: ProjectManifest.fromJson(manifest),
    map: base.map,
    projectRootDirectory: projectRoot,
    tilesetAbsolutePathsById: base.tilesetAbsolutePathsById,
  );
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
  _TestGame({
    required super.bundle,
    required super.projectFilePath,
    super.beforeBattleHandoffPreparation,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

Future<PlayableMapGame> _loadGame(
  RuntimeMapBundle bundle, {
  Future<void> Function()? beforeBattleHandoffPreparation,
}) async {
  final game = _TestGame(
    bundle: bundle,
    projectFilePath: '${bundle.projectRootDirectory}/project.json',
    beforeBattleHandoffPreparation: beforeBattleHandoffPreparation,
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
