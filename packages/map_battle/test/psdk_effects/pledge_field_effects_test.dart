import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK pledge field effects', () {
    test('Sea of Fire damages non-Fire battlers on the affected bank', () {
      final state = _state(
        opponent: _combatant(
          id: 'opponent',
          currentHp: 100,
          effects: const PsdkBattleEffectStack.empty().addEffect(
            SeaOfFirePledgeEffect(scope: BankBattleEffectScope(1)),
          ),
        ),
      );

      final result = state.battlerAt(psdkOpponentSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 2,
              owner: psdkOpponentSlot,
            ),
          );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(
        result.events,
        contains(
          isA<PsdkBattleDamageEvent>()
              .having(
                (event) => event.moveId,
                'moveId',
                'effect:sea_of_fire',
              )
              .having((event) => event.damage, 'damage', 12),
        ),
      );
    });

    test('Sea of Fire ignores Fire-type battlers', () {
      final state = _state(
        opponent: _combatant(
          id: 'opponent',
          currentHp: 100,
          types: const PsdkBattleTypes(primary: 'fire'),
          effects: const PsdkBattleEffectStack.empty().addEffect(
            SeaOfFirePledgeEffect(scope: BankBattleEffectScope(1)),
          ),
        ),
      );

      final result = state.battlerAt(psdkOpponentSlot).effects.dispatchEndTurn(
            BattleEffectEndTurnContext(
              state: state,
              rng: _rng(),
              turn: 2,
              owner: psdkOpponentSlot,
            ),
          );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(
        result.events.whereType<PsdkBattleDamageEvent>(),
        isEmpty,
      );
    });

    test('Swamp quarters action speed for battlers on the affected bank', () {
      final state = _state(
        player: _combatant(
          id: 'player',
          speed: 100,
          effects: const PsdkBattleEffectStack.empty().addEffect(
            SwampPledgeEffect(scope: BankBattleEffectScope(0)),
          ),
        ),
        opponent: _combatant(id: 'opponent', speed: 40),
      );

      final action = const PsdkBattleActionDecisionMapper().map(
        state: state,
        user: psdkPlayerSlot,
        decision: const BattleFightDecision(moveSlot: 0),
      );

      expect((action as PsdkBattleFightAction).speed, 25);
    });

    test('effect registry hydrates pledge field effects from ids', () {
      final effects = PsdkBattleEffectStack(
        values: const <String>[
          'pledge_rainbow',
          'pledge_sea_of_fire',
          'pledge_swamp',
        ],
      ).effects;

      expect(effects[0], isA<RainbowPledgeEffect>());
      expect(effects[1], isA<SeaOfFirePledgeEffect>());
      expect(effects[2], isA<SwampPledgeEffect>());
    });

    test('Rainbow doubles non-flinch secondary effect chances', () {
      final state = _state(
        player: _combatant(
          id: 'player',
          effects: const PsdkBattleEffectStack.empty().addEffect(
            RainbowPledgeEffect(scope: BankBattleEffectScope(0)),
          ),
        ),
      );

      final result = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: _rng(genericSeed: 99),
        user: psdkPlayerSlot,
        target: psdkOpponentSlot,
        move: BattleMoveDefinition.fromPsdk(
          _move(
            id: 'status_move',
            effectChance: 50,
            statuses: <PsdkBattleMoveStatus>[
              PsdkBattleMoveStatus(
                status: PsdkBattleMajorStatus.burn,
                chance: 100,
              ),
            ],
          ),
        ),
        turn: 2,
      );

      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
    });

    test('Rainbow does not double flinch secondary effect chances', () {
      final state = _state(
        player: _combatant(
          id: 'player',
          effects: const PsdkBattleEffectStack.empty().addEffect(
            RainbowPledgeEffect(scope: BankBattleEffectScope(0)),
          ),
        ),
      );

      final result = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: _rng(genericSeed: 99),
        user: psdkPlayerSlot,
        target: psdkOpponentSlot,
        move: BattleMoveDefinition.fromPsdk(
          _move(
            id: 'flinch_move',
            effectChance: 50,
            statuses: <PsdkBattleMoveStatus>[
              PsdkBattleMoveStatus.volatile(
                status: PsdkBattleVolatileStatus.flinch,
                chance: 100,
              ),
            ],
          ),
        ),
        turn: 2,
      );

      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains('flinch'),
        isFalse,
      );
    });
  });
}

PsdkBattleState _state({
  PsdkBattleCombatantSetup? player,
  PsdkBattleCombatantSetup? opponent,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        player ?? _combatant(id: 'player'),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        opponent ?? _combatant(id: 'opponent'),
      ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int currentHp = 100,
  int speed = 50,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: currentHp,
    types: types,
    stats: PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: speed,
    ),
    effects: effects,
    moves: <PsdkBattleMoveData>[_move(id: '${id}_move')],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int? effectChance,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
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
    effectChance: effectChance,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    statuses: statuses,
  );
}

BattleRngStreams _rng({int genericSeed = 4}) {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: genericSeed,
  );
}
