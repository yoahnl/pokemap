import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_trainer_ball_items.dart';

void main() {
  test(
    'trainer Balls follow individual lineup indices for identical species',
    () {
      final result = resolveRuntimeTrainerBallItems(
        request: _request(),
        manifest: _manifest(),
      );
      expect(result, {0: 'first-orb', 1: 'reserve-orb'});
      expect(() => result[0] = 'changed', throwsUnsupportedError);
    },
  );

  test('missing trainer or ambiguous definition cannot assign a Ball', () {
    final trainer = _trainer();
    for (final trainers in [
      <ProjectTrainerEntry>[],
      [trainer, trainer],
    ]) {
      expect(
        resolveRuntimeTrainerBallItems(
          request: _request(),
          manifest: _manifest().copyWith(trainers: trainers),
        ),
        isEmpty,
      );
    }
  });

  test('static opponents never inherit Balls from their trainer profile', () {
    expect(
      resolveRuntimeTrainerBallItems(
        request: const StaticBattleStartRequest(
          requestId: 'static',
          createdAtEpochMs: 0,
          returnContext: _returnContext,
          battleId: 'static',
          opponentProfileId: 'trainer',
          entityId: 'npc',
          mapId: 'map',
          playerPos: GridPos(x: 0, y: 0),
        ),
        manifest: _manifest(),
      ),
      isEmpty,
    );
  });
}

const _returnContext = OverworldReturnContext(
  mapId: 'map',
  playerPos: GridPos(x: 0, y: 0),
  playerFacing: Direction.east,
);

TrainerBattleStartRequest _request() => const TrainerBattleStartRequest(
  requestId: 'trainer',
  createdAtEpochMs: 0,
  returnContext: _returnContext,
  trainerId: 'trainer',
  npcEntityId: 'npc',
  mapId: 'map',
  playerPos: GridPos(x: 0, y: 0),
);

ProjectTrainerEntry _trainer() => ProjectTrainerEntry(
  id: 'trainer',
  name: 'Trainer',
  trainerClass: 'Class',
  team: [
    ProjectTrainerPokemonEntry.fromJson({
      'speciesId': 'species',
      'level': 5,
      'ballItemId': 'first-orb',
    }),
    ProjectTrainerPokemonEntry.fromJson({
      'speciesId': 'species',
      'level': 5,
      'ballItemId': 'reserve-orb',
    }),
    ProjectTrainerPokemonEntry.fromJson({'speciesId': 'species', 'level': 5}),
  ],
);

ProjectManifest _manifest() => ProjectManifest(
  name: 'Project',
  maps: const [],
  tilesets: const [],
  trainers: [_trainer()],
);
