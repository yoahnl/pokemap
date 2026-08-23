import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('static boss request has an explicit non-trainer runtime identity', () {
    const request = StaticBattleStartRequest(
      requestId: 'static:lanturn:1',
      createdAtEpochMs: 1234,
      returnContext: OverworldReturnContext(
        mapId: 'map_sommet_phare',
        playerPos: GridPos(x: 8, y: 8),
        playerFacing: Direction.north,
      ),
      battleId: 'battle_lighthouse_pokemon',
      opponentProfileId: 'trainer_boss_phare_pokemon',
      entityId: 'boss_phare_pokemon',
      mapId: 'map_sommet_phare',
      playerPos: GridPos(x: 8, y: 8),
    );

    expect(request.kind, RuntimeBattleKind.staticEncounter);
    expect(request.source, RuntimeBattleSourceKind.staticEncounter);
    expect(request.allowsPlayerFlee, isFalse);
    expect(request.toJson(), containsPair('kind', 'staticEncounter'));
    expect(
      request.toJson(),
      containsPair('opponentProfileId', 'trainer_boss_phare_pokemon'),
    );
  });

  test('wild and trainer requests preserve their flee semantics', () {
    const returnContext = OverworldReturnContext(
      mapId: 'map_port',
      playerPos: GridPos(x: 3, y: 4),
      playerFacing: Direction.south,
    );
    const wild = WildBattleStartRequest(
      requestId: 'wild:1',
      createdAtEpochMs: 1,
      returnContext: returnContext,
      mapId: 'map_port',
      encounterSourceId: 'zone_grass',
      encounterSourceKind: EncounterSourceKind.gameplayZone,
      tableId: 'table_grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'rattata',
      level: 3,
      minLevel: 2,
      maxLevel: 4,
      weight: 100,
      playerPos: GridPos(x: 3, y: 4),
    );
    const trainer = TrainerBattleStartRequest(
      requestId: 'trainer:1',
      createdAtEpochMs: 2,
      returnContext: returnContext,
      trainerId: 'trainer_lysa',
      npcEntityId: 'npc_lysa',
      mapId: 'map_port',
      playerPos: GridPos(x: 3, y: 4),
    );

    expect(wild.allowsPlayerFlee, isTrue);
    expect(trainer.allowsPlayerFlee, isFalse);
  });
}
