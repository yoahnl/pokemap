import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK status cure move families', () {
    test('s_take_heart cures the user and raises special stats', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            majorStatus: PsdkBattleMajorStatus.burn,
            move: _move(
              id: 'take_heart',
              battleEngineMethod: 's_take_heart',
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(
                  stat: 'specialAttack',
                  stages: 1,
                  chance: 100,
                ),
                PsdkBattleMoveStageMod(
                  stat: 'specialDefense',
                  stages: 1,
                  chance: 100,
                ),
              ],
            ),
          ),
          opponent: _combatant(id: 'opponent', move: _move(id: 'splash')),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.majorStatus, isNull);
      expect(player.statStages.valueOf('specialAttack'), 1);
      expect(player.statStages.valueOf('specialDefense'), 1);
      expect(
        result.timeline.events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'status_cure',
          'stat_stage_change',
          'stat_stage_change',
        ]),
      );
    });

    test('s_heal_bell is blocked by Soundproof before curing the user', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            abilityId: 'soundproof',
            majorStatus: PsdkBattleMajorStatus.poison,
            move: _move(
              id: 'heal_bell',
              battleEngineMethod: 's_heal_bell',
              sound: true,
            ),
          ),
          opponent: _combatant(id: 'opponent', move: _move(id: 'splash')),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.majorStatus, PsdkBattleMajorStatus.poison);
      expect(
        result.timeline.events.whereType<PsdkBattleStatusCureEvent>(),
        isEmpty,
      );
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'heal_bell')
            .having((event) => event.reason, 'reason', 'immunity'),
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? abilityId,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[move],
    abilityId: abilityId,
    majorStatus: majorStatus,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String battleEngineMethod = 's_splash',
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
  bool sound = false,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.user,
    stageMods: stageMods,
    sound: sound,
  );
}
