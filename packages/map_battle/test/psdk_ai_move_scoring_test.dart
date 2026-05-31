import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/disable_effect.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle AI move scoring', () {
    test('AI picks a KO move over weaker damage', () {
      final state = _state(
        user: _combatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'water'),
          moves: <PsdkBattleMoveData>[
            _move(id: 'bubble', type: 'water', power: 20),
            _move(id: 'aqua_tail', type: 'water', power: 90),
          ],
        ),
        target: _combatant(
          id: 'player',
          hp: 35,
          types: const PsdkBattleTypes(primary: 'fire'),
        ),
      );

      final choice = const PsdkBattleAi().chooseMove(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(choice.moveSlot, 1);
      expect(choice.move.id, 'aqua_tail');
      expect(choice.score.isKo, isTrue);
    });

    test('AI avoids an immune target when a damaging alternative exists', () {
      final state = _state(
        user: _combatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(id: 'tackle', type: 'normal', power: 80),
            _move(id: 'shadow_claw', type: 'ghost', power: 70),
          ],
        ),
        target: _combatant(
          id: 'player',
          types: const PsdkBattleTypes(primary: 'ghost'),
        ),
      );

      final scores = const PsdkBattleAi().scoreMoves(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );
      final choice = const PsdkBattleAi().chooseMove(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(
        scores.singleWhere((score) => score.move.id == 'tackle').isImmune,
        isTrue,
      );
      expect(choice.move.id, 'shadow_claw');
    });

    test('AI uses utility when damage is poor', () {
      final state = _state(
        user: _combatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(id: 'scratch', type: 'normal', power: 10),
            _move(
              id: 'thunder_wave',
              type: 'electric',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              statuses: <PsdkBattleMoveStatus>[
                PsdkBattleMoveStatus(
                  status: PsdkBattleMajorStatus.paralysis,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
        target: _combatant(
          id: 'player',
          hp: 140,
          types: const PsdkBattleTypes(primary: 'water'),
        ),
      );

      final choice = const PsdkBattleAi().chooseMove(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(choice.moveSlot, 1);
      expect(choice.move.id, 'thunder_wave');
      expect(choice.score.utilityScore, greaterThan(0));
    });

    test('AI respects PP and disabled moves', () {
      final state = _state(
        user: _combatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'normal'),
          effects: const PsdkBattleEffectStack.empty().addEffect(
            DisableEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
              disabledMoveId: 'slash',
            ),
          ),
          moves: <PsdkBattleMoveData>[
            _move(id: 'empty_blast', type: 'normal', power: 150, currentPp: 0),
            _move(id: 'slash', type: 'normal', power: 90),
            _move(id: 'quick_attack', type: 'normal', power: 40),
          ],
        ),
        target: _combatant(
          id: 'player',
          types: const PsdkBattleTypes(primary: 'normal'),
        ),
      );

      final scores = const PsdkBattleAi().scoreMoves(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );
      final choice = const PsdkBattleAi().chooseMove(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(
        scores.where((score) => !score.isUsable).map((score) => score.move.id),
        containsAll(<String>['empty_blast', 'slash']),
      );
      expect(choice.move.id, 'quick_attack');
    });

    test('BattleEngine can use PSDK AI for the opponent move choice', () {
      final engine = BattleEngine(
        setup: BattleEngineSetup.singles(
          player: _setupCombatant(
            id: 'player',
            hp: 120,
            types: const PsdkBattleTypes(primary: 'ghost'),
            moves: <PsdkBattleMoveData>[
              _move(id: 'wait', type: 'normal', power: 0),
            ],
          ),
          opponent: _setupCombatant(
            id: 'opponent',
            types: const PsdkBattleTypes(primary: 'normal'),
            moves: <PsdkBattleMoveData>[
              _move(id: 'tackle', type: 'normal', power: 100),
              _move(id: 'shadow_claw', type: 'ghost', power: 70),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
        opponentAi: const PsdkBattleAi(),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events
            .whereType<BattleMoveDeclaredTimelineEvent>()
            .map((event) => event.moveId),
        contains('shadow_claw'),
      );
    });

    test('BattleSessionFacade can use PSDK AI for the opponent move choice',
        () {
      final setup = PsdkBattleSetup.singles(
        player: _setupCombatant(
          id: 'player',
          hp: 120,
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(
              id: 'wait',
              type: 'normal',
              category: PsdkBattleMoveCategory.status,
              power: 0,
            ),
          ],
        ),
        opponent: _setupCombatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(
              id: 'growl',
              type: 'normal',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(stat: 'attack', stages: -1),
              ],
            ),
            _move(id: 'tackle', type: 'normal', power: 40),
          ],
        ),
        rngSeeds: const PsdkBattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 1,
          generic: 1,
        ),
      );
      final facade = BattleSessionFacade.fromPsdkSetup(
        setup: setup,
        opponentAi: const PsdkBattleAi(level: 2),
      );

      final result = facade.submit(const BattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events
            .whereType<BattleMoveDeclaredTimelineEvent>()
            .where((event) =>
                event.user.bank == psdkOpponentSlot.bank &&
                event.user.position == psdkOpponentSlot.position)
            .map((event) => event.moveId),
        contains('tackle'),
      );
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(120));
    });
  });
}

PsdkBattleState _state({
  required PsdkBattleCombatantSetup user,
  required PsdkBattleCombatantSetup target,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(user),
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(target),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  int hp = 100,
  List<PsdkBattleMoveData> moves = const <PsdkBattleMoveData>[],
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return _setupCombatant(
    id: id,
    hp: hp,
    types: types,
    moves: moves.isEmpty
        ? <PsdkBattleMoveData>[_move(id: 'wait', type: 'normal', power: 0)]
        : moves,
    effects: effects,
  );
}

PsdkBattleCombatantSetup _setupCombatant({
  required String id,
  required PsdkBattleTypes types,
  int hp = 100,
  List<PsdkBattleMoveData> moves = const <PsdkBattleMoveData>[],
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: hp,
    types: types,
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: moves,
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  int pp = 15,
  int? currentPp,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod:
        category == PsdkBattleMoveCategory.status ? 's_status' : 's_basic',
    target: category == PsdkBattleMoveCategory.status
        ? PsdkBattleMoveTarget.adjacentFoe
        : PsdkBattleMoveTarget.adjacentFoe,
    statuses: statuses,
    stageMods: stageMods,
  );
}
