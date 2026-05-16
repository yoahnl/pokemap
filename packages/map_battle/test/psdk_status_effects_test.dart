import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK major status effect hooks', () {
    test('burn and poison deal residual damage from their effect hooks', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(status: PsdkBattleMajorStatus.burn),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'poisoned', status: PsdkBattleMajorStatus.poison),
          ),
        },
      );

      final burn = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 4,
              owner: psdkPlayerSlot,
            ),
          );
      final poison =
          burn.state.battlerAt(psdkOpponentSlot).effects.dispatchEndTurn(
                BattleEffectEndTurnContext(
                  state: burn.state,
                  rng: burn.rng,
                  turn: 4,
                  owner: psdkOpponentSlot,
                ),
              );

      expect(burn.state.battlerAt(psdkPlayerSlot).currentHp, 84);
      expect(poison.state.battlerAt(psdkOpponentSlot).currentHp, 84);
      expect(
        poison.events.whereType<PsdkBattleDamageEvent>().map((event) {
          return event.moveId;
        }),
        containsAll(<String>['status:poison']),
      );
    });

    test('toxic increments its counter and scales residual damage', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(status: PsdkBattleMajorStatus.toxic, toxicCounter: 1),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(_combatant()),
        },
      );

      final result = state.battlerAt(psdkPlayerSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 4,
              owner: psdkPlayerSlot,
            ),
          );

      expect(result.state.battlerAt(psdkPlayerSlot).toxicCounter, 2);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 84);
      expect(
        result.events.whereType<PsdkBattleDamageEvent>().single.moveId,
        'status:toxic',
      );
    });

    test('sleep effect prevents regular moves then cures after two turns', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(status: PsdkBattleMajorStatus.sleep),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(_combatant()),
        },
      );

      final first = state.battlerAt(psdkPlayerSlot).effects.userMovePrevention(
            BattleEffectUserMovePreventionContext(
              state: state,
              rng: _rng(),
              turn: 1,
              user: psdkPlayerSlot,
              target: psdkOpponentSlot,
              move: _moveDefinition(id: 'tackle'),
            ),
          );
      final second =
          first!.state.battlerAt(psdkPlayerSlot).effects.userMovePrevention(
                BattleEffectUserMovePreventionContext(
                  state: first.state,
                  rng: first.rng,
                  turn: 2,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: _moveDefinition(id: 'tackle'),
                ),
              );
      final third =
          second!.state.battlerAt(psdkPlayerSlot).effects.userMovePrevention(
                BattleEffectUserMovePreventionContext(
                  state: second.state,
                  rng: second.rng,
                  turn: 3,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: _moveDefinition(id: 'tackle'),
                ),
              );

      expect(first.prevented, isTrue);
      expect(first.state.battlerAt(psdkPlayerSlot).sleepTurns, 1);
      expect(second.prevented, isTrue);
      expect(second.state.battlerAt(psdkPlayerSlot).sleepTurns, 2);
      expect(third!.prevented, isFalse);
      expect(third.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(third.state.battlerAt(psdkPlayerSlot).effects.contains('sleep'),
          isFalse);
    });

    test('paralysis and freeze can prevent moves through effect hooks', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(status: PsdkBattleMajorStatus.paralysis),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'frozen', status: PsdkBattleMajorStatus.freeze),
          ),
        },
      );

      final paralysis =
          state.battlerAt(psdkPlayerSlot).effects.userMovePrevention(
                BattleEffectUserMovePreventionContext(
                  state: state,
                  rng: _rng(genericSeed: 4),
                  turn: 1,
                  user: psdkPlayerSlot,
                  target: psdkOpponentSlot,
                  move: _moveDefinition(id: 'tackle'),
                ),
              );
      final freeze =
          state.battlerAt(psdkOpponentSlot).effects.userMovePrevention(
                BattleEffectUserMovePreventionContext(
                  state: state,
                  rng: _rng(genericSeed: 4),
                  turn: 1,
                  user: psdkOpponentSlot,
                  target: psdkPlayerSlot,
                  move: _moveDefinition(id: 'tackle'),
                ),
              );

      expect(paralysis!.prevented, isTrue);
      expect(freeze!.prevented, isTrue);
      expect(
        freeze.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.freeze,
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  String id = 'combatant',
  PsdkBattleMajorStatus? status,
  int toxicCounter = 0,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 96,
    currentHp: 96,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[_psdkMove(id: 'tackle')],
    majorStatus: status,
    toxicCounter: toxicCounter,
    effects: status == null
        ? const PsdkBattleEffectStack.empty()
        : PsdkBattleEffectStack(
            effects: <BattleMajorStatusEffect>[
              const StatusEffectRegistry().create(
                status: status,
                target: id == 'frozen' ? psdkOpponentSlot : psdkPlayerSlot,
                toxicCounter: toxicCounter,
              ),
            ],
          ),
  );
}

PsdkBattleMoveData _psdkMove({
  required String id,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

BattleMoveDefinition _moveDefinition({required String id}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

BattleRngStreams _rng({int genericSeed = 5}) {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: genericSeed,
  );
}
