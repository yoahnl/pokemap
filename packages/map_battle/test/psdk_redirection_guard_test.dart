import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _playerLeft = PsdkBattleSlotRef(bank: 0, position: 0);
const _playerRight = PsdkBattleSlotRef(bank: 0, position: 1);
const _opponentLeft = PsdkBattleSlotRef(bank: 1, position: 0);
const _opponentRight = PsdkBattleSlotRef(bank: 1, position: 1);

void main() {
  group('PSDK redirection and doubles guard effects', () {
    test('Follow Me redirects eligible single-target foe moves', () {
      final state = _state(
        opponentRightEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            GenericBattleEffect(
              id: PsdkBattleEffectIds.centerOfAttention,
              scope: BattlerBattleEffectScope(_opponentRight),
              remainingTurns: 0,
            ),
          ],
        ),
      );
      final execution = _execution(
        state: state,
        user: _playerLeft,
        target: _opponentLeft,
        move: _move(target: PsdkBattleMoveTarget.adjacentFoe),
      );

      final targets = const BattleTargetResolver().resolve(execution);

      expect(targets, <BattlePositionRef>[
        const BattlePositionRef(bank: 1, position: 1),
      ]);
    });

    test('Stalwart and Propeller Tail bypass Follow Me redirection', () {
      for (final abilityId in <String>['stalwart', 'propeller_tail']) {
        final state = _state(
          playerLeftAbilityId: abilityId,
          opponentRightEffects: PsdkBattleEffectStack(
            effects: const <BattleEffect>[
              GenericBattleEffect(
                id: PsdkBattleEffectIds.centerOfAttention,
                scope: BattlerBattleEffectScope(_opponentRight),
                remainingTurns: 0,
              ),
            ],
          ),
        );
        final execution = _execution(
          state: state,
          user: _playerLeft,
          target: _opponentLeft,
          move: _move(target: PsdkBattleMoveTarget.adjacentFoe),
        );

        expect(
          const BattleTargetResolver().resolve(execution),
          <BattlePositionRef>[const BattlePositionRef(bank: 1, position: 0)],
          reason: abilityId,
        );
      }
    });

    test('Wide Guard blocks spread moves against the protected bank', () {
      final state = _state(
        opponentLeftEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            WideGuardEffect(scope: BankBattleEffectScope(1)),
          ],
        ),
      );
      final execution = _execution(
        state: state,
        user: _playerLeft,
        target: _opponentLeft,
        move: _move(
          id: 'surf',
          target: PsdkBattleMoveTarget.allAdjacentFoes,
        ),
      );
      final resolved = const BattleTargetResolver().resolve(execution);

      final precheck = const BattleMoveImmunityResolver().precheck(
        execution,
        resolved,
      );

      expect(resolved, <BattlePositionRef>[
        const BattlePositionRef(bank: 1, position: 0),
        const BattlePositionRef(bank: 1, position: 1),
      ]);
      expect(precheck.targets, isEmpty);
      expect(precheck.reason, BattleMoveFailureReason.protected);
    });

    test('Quick Guard blocks positive-priority moves against the bank', () {
      final execution = _execution(
        state: _state(
          opponentLeftEffects: PsdkBattleEffectStack(
            effects: const <BattleEffect>[
              QuickGuardEffect(scope: BankBattleEffectScope(1)),
            ],
          ),
        ),
        user: _playerLeft,
        target: _opponentLeft,
        move: _move(id: 'quick_attack', priority: 1),
      );

      final precheck = const BattleMoveImmunityResolver().precheck(
        execution,
        const <BattlePositionRef>[BattlePositionRef(bank: 1, position: 0)],
      );

      expect(precheck.targets, isEmpty);
      expect(precheck.reason, BattleMoveFailureReason.protected);
    });

    test('Crafty Shield blocks status moves against allies only', () {
      final execution = _execution(
        state: _state(
          playerLeftEffects: PsdkBattleEffectStack(
            effects: const <BattleEffect>[
              CraftyShieldEffect(scope: BankBattleEffectScope(0)),
            ],
          ),
        ),
        user: _opponentLeft,
        target: _playerRight,
        move: _move(
          id: 'spore',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
      );

      final precheck = const BattleMoveImmunityResolver().precheck(
        execution,
        const <BattlePositionRef>[BattlePositionRef(bank: 0, position: 1)],
      );

      expect(precheck.targets, isEmpty);
      expect(precheck.reason, BattleMoveFailureReason.protected);
    });

    test('Mat Block blocks damaging moves but lets status moves through', () {
      final state = _state(
        playerLeftEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            MatBlockEffect(scope: BankBattleEffectScope(0)),
          ],
        ),
      );
      final damagingExecution = _execution(
        state: state,
        user: _opponentLeft,
        target: _playerLeft,
        move: _move(id: 'tackle'),
      );
      final statusExecution = _execution(
        state: state,
        user: _opponentLeft,
        target: _playerLeft,
        move: _move(
          id: 'growl',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
      );

      final damagingPrecheck = const BattleMoveImmunityResolver().precheck(
        damagingExecution,
        const <BattlePositionRef>[BattlePositionRef(bank: 0, position: 0)],
      );
      final statusPrecheck = const BattleMoveImmunityResolver().precheck(
        statusExecution,
        const <BattlePositionRef>[BattlePositionRef(bank: 0, position: 0)],
      );

      expect(damagingPrecheck.targets, isEmpty);
      expect(damagingPrecheck.reason, BattleMoveFailureReason.protected);
      expect(statusPrecheck.targets, <BattlePositionRef>[
        const BattlePositionRef(bank: 0, position: 0),
      ]);
    });

    test('Ally Switch swaps the user with its only adjacent ally', () {
      final result =
          createStaticBasicMoveRegistry().resolve('s_ally_switch').resolve(
                BattleMoveBehaviorContext(
                  state: _state(),
                  rng: _rng(),
                  turn: 1,
                  user: _playerLeft,
                  target: _playerLeft,
                  move: _move(
                    id: 'ally_switch',
                    category: PsdkBattleMoveCategory.status,
                    power: 0,
                    accuracy: 0,
                    battleEngineMethod: 's_ally_switch',
                    target: PsdkBattleMoveTarget.self,
                  ),
                ),
              );

      expect(result.successful, isTrue);
      expect(result.state.battlerAt(_playerLeft).id, 'player-right');
      expect(result.state.battlerAt(_playerRight).id, 'player-left');
      expect(
        result.state.battlerAt(_playerLeft).effects.contains('ally_switch'),
        isFalse,
      );
    });
  });
}

BattleMoveProcedureExecution _execution({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
}) {
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: state,
      rng: _rng(),
      turn: 1,
      user: user,
      target: target,
      move: move,
    ),
    timeline: BattleTimelineBuilder(),
    user: BattlePositionRef(bank: user.bank, position: user.position),
    move: move,
    requestedTarget: BattlePositionRef(
      bank: target.bank,
      position: target.position,
    ),
  );
}

PsdkBattleState _state({
  String? playerLeftAbilityId,
  String? playerRightAbilityId,
  String? opponentLeftAbilityId,
  String? opponentRightAbilityId,
  PsdkBattleEffectStack? playerLeftEffects,
  PsdkBattleEffectStack? playerRightEffects,
  PsdkBattleEffectStack? opponentLeftEffects,
  PsdkBattleEffectStack? opponentRightEffects,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      _playerLeft: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player-left',
          abilityId: playerLeftAbilityId,
          effects: playerLeftEffects,
        ),
      ),
      _playerRight: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player-right',
          abilityId: playerRightAbilityId,
          effects: playerRightEffects,
        ),
      ),
      _opponentLeft: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent-left',
          abilityId: opponentLeftAbilityId,
          effects: opponentLeftEffects,
        ),
      ),
      _opponentRight: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent-right',
          abilityId: opponentRightAbilityId,
          effects: opponentRightEffects,
        ),
      ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? abilityId,
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    abilityId: abilityId,
    moves: <PsdkBattleMoveData>[_move().psdkMove],
    effects: effects,
  );
}

BattleMoveDefinition _move({
  String id = 'tackle',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  int power = 40,
  int accuracy = 100,
  int priority = 0,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 20,
    priority: priority,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
