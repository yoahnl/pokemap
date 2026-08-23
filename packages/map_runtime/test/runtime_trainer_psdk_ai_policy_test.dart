import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/presentation/flame/runtime_trainer_battle_overrides.dart';

void main() {
  group('runtime trainer PSDK AI policy', () {
    test('maps authored low and high difficulties to distinct PSDK policies',
        () {
      final manifest = _manifest(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'basic',
            name: 'Basic',
            trainerClass: 'Rookie',
            battleDifficulty: 2,
          ),
          ProjectTrainerEntry(
            id: 'advanced',
            name: 'Advanced',
            trainerClass: 'Ace',
            battleDifficulty: 9,
          ),
        ],
      );

      final basic = resolveRuntimeTrainerPsdkAi(
        request: _trainerRequest('basic'),
        manifest: manifest,
      );
      final advanced = resolveRuntimeTrainerPsdkAi(
        request: _trainerRequest('advanced'),
        manifest: manifest,
      );

      expect(basic.level, 1);
      expect(basic.canSwitch, isFalse);
      expect(basic.canUseItem, isFalse);
      expect(basic.canFlee, isFalse);

      expect(advanced.level, 3);
      expect(advanced.canSwitch, isTrue);
      expect(advanced.canUseItem, isFalse);
      expect(advanced.canFlee, isFalse);
    });

    test('enables advanced items only when authored options are provided', () {
      final ai = resolveRuntimeTrainerPsdkAi(
        request: _trainerRequest('advanced'),
        manifest: _manifest(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'advanced',
              name: 'Advanced',
              trainerClass: 'Ace',
              battleDifficulty: 10,
            ),
          ],
        ),
        itemOptions: const <PsdkBattleAiItemOption>[
          PsdkBattleAiItemOption.hpHeal(
            itemId: 'potion',
            amount: 20,
          ),
        ],
      );

      expect(ai.canUseItem, isTrue);
      expect(ai.itemOptions.single.itemId, 'potion');
    });

    test('keeps wild PSDK battles on their historical neutral AI', () {
      final ai = resolveRuntimeTrainerPsdkAi(
        request: const WildBattleStartRequest(
          requestId: 'wild',
          createdAtEpochMs: 1,
          returnContext: OverworldReturnContext(
            mapId: 'field',
            playerPos: GridPos(x: 1, y: 1),
            playerFacing: Direction.south,
          ),
          mapId: 'field',
          encounterSourceId: 'grass',
          encounterSourceKind: EncounterSourceKind.gameplayZone,
          tableId: 'grass-table',
          encounterKind: EncounterKind.walk,
          speciesId: 'sproutle',
          level: 5,
          minLevel: 5,
          maxLevel: 5,
          weight: 1,
          playerPos: GridPos(x: 1, y: 1),
        ),
        manifest: _manifest(),
      );

      expect(ai.level, 2);
      expect(ai.canSwitch, isFalse);
      expect(ai.canUseItem, isFalse);
      expect(ai.canFlee, isFalse);
    });
  });
}

ProjectManifest _manifest({
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
}) {
  return ProjectManifest(
    name: 'runtime-ai-policy',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
  );
}

TrainerBattleStartRequest _trainerRequest(String trainerId) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-$trainerId',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc-$trainerId',
    mapId: 'field',
    playerPos: const GridPos(x: 1, y: 1),
  );
}
