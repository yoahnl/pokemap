import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK terrain-powered move families', () {
    test('s_terrain_boosting boosts Psyblade only on Electric Terrain', () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'psyblade',
          type: 'psychic',
          power: 80,
          battleEngineMethod: 's_terrain_boosting',
        ),
      );
      final electricTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'psyblade',
          type: 'psychic',
          power: 80,
          battleEngineMethod: 's_terrain_boosting',
        ),
      );
      final grassyTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'psyblade',
          type: 'psychic',
          power: 80,
          battleEngineMethod: 's_terrain_boosting',
        ),
      );

      expect(
        _damage(electricTerrain, moveId: 'psyblade'),
        greaterThan(_damage(noTerrain, moveId: 'psyblade')),
      );
      expect(
        _damage(grassyTerrain, moveId: 'psyblade'),
        _damage(noTerrain, moveId: 'psyblade'),
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleFieldState field,
  required PsdkBattleMoveData playerMove,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
      field: field,
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
