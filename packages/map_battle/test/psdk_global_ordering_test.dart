import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK global battle ordering', () {
    test('battle end short-circuits end-turn field progression after a KO', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'attacker',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(id: 'decisive_hit', power: 250),
            ],
          ),
          opponent: _combatant(
            id: 'target',
            hp: 8,
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'too_late', power: 1),
            ],
          ),
          field: const PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.rain,
              remainingTurns: 1,
            ),
            terrain: PsdkBattleTerrainState(
              id: PsdkBattleTerrainId.grassyTerrain,
              remainingTurns: 1,
            ),
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 14,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.outcome?.kind, PsdkBattleOutcomeKind.victory);
      expect(result.state.field.weather?.id, PsdkBattleWeatherId.rain);
      expect(
        result.state.field.terrain?.id,
        PsdkBattleTerrainId.grassyTerrain,
      );
      expect(
        result.timeline.events.whereType<PsdkBattleWeatherChangedEvent>(),
        isEmpty,
      );
      expect(
        result.timeline.events.whereType<PsdkBattleTerrainChangedEvent>(),
        isEmpty,
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  int hp = 100,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 100,
      defense: 50,
      specialAttack: 100,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 10,
    priority: 0,
    criticalRate: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
