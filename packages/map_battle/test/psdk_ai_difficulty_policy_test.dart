import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK trainer difficulty policy', () {
    test('maps product difficulty to three explicit deterministic profiles',
        () {
      final basic = psdkBattleAiPolicyForDifficulty(2);
      final tactical = psdkBattleAiPolicyForDifficulty(6);
      final advanced = psdkBattleAiPolicyForDifficulty(9);

      expect(basic.profileId, 'basic');
      expect(basic.aiLevel, 1);
      expect(basic.switchPolicy, PsdkBattleAiSwitchPolicy.never);
      expect(basic.itemPolicy, PsdkBattleAiItemPolicy.disabled);

      expect(tactical.profileId, 'tactical');
      expect(tactical.aiLevel, 2);
      expect(tactical.switchPolicy, PsdkBattleAiSwitchPolicy.tactical);
      expect(
        tactical.itemPolicy,
        PsdkBattleAiItemPolicy.authoredOptionsOnly,
      );

      expect(advanced.profileId, 'advanced');
      expect(advanced.aiLevel, 3);
      expect(advanced.switchPolicy, PsdkBattleAiSwitchPolicy.tactical);
      expect(
        advanced.itemPolicy,
        PsdkBattleAiItemPolicy.authoredOptionsOnly,
      );
    });

    test('keeps default and out-of-range inputs bounded', () {
      expect(psdkBattleAiPolicyForDifficulty(null).productDifficulty, isNull);
      expect(psdkBattleAiPolicyForDifficulty(null).profileId, 'basic');
      expect(psdkBattleAiPolicyForDifficulty(-1).productDifficulty, 1);
      expect(psdkBattleAiPolicyForDifficulty(99).productDifficulty, 10);
    });

    test('allows only explicitly provided trainer item options', () {
      final advanced = psdkBattleAiPolicyForDifficulty(9);

      expect(advanced.createAi().canUseItem, isFalse);
      expect(
        advanced
            .createAi(
              itemOptions: const <PsdkBattleAiItemOption>[
                PsdkBattleAiItemOption.hpHeal(
                  itemId: 'potion',
                  amount: 20,
                ),
              ],
            )
            .canUseItem,
        isTrue,
      );
      expect(
        psdkBattleAiPolicyForDifficulty(2)
            .createAi(
              itemOptions: const <PsdkBattleAiItemOption>[
                PsdkBattleAiItemOption.hpHeal(
                  itemId: 'potion',
                  amount: 20,
                ),
              ],
            )
            .canUseItem,
        isFalse,
      );
    });

    test('basic and advanced profiles produce distinct switch decisions', () {
      final state = _switchPressureState();
      final basic = psdkBattleAiPolicyForDifficulty(2).createAi();
      final advanced = psdkBattleAiPolicyForDifficulty(9).createAi();

      final basicDecision = basic.chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );
      final advancedDecision = advanced.chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(basicDecision, isA<BattleFightDecision>());
      expect(advancedDecision, isA<BattleSwitchDecision>());
      expect((advancedDecision as BattleSwitchDecision).partyIndex, 1);
      expect(
        advanced.chooseDecision(
          state: state,
          user: psdkOpponentSlot,
          target: psdkPlayerSlot,
        ),
        isA<BattleSwitchDecision>().having(
          (decision) => decision.partyIndex,
          'partyIndex',
          1,
        ),
      );
    });
  });
}

PsdkBattleState _switchPressureState() {
  final active = PsdkBattleCombatant.fromSetup(
    _combatant(
      id: 'opponent-active',
      type: 'normal',
      moves: <PsdkBattleMoveData>[
        _move(id: 'tackle', type: 'normal', power: 80),
      ],
    ),
  );
  final reserve = PsdkBattleCombatant.fromSetup(
    _combatant(
      id: 'opponent-reserve',
      type: 'ghost',
      moves: <PsdkBattleMoveData>[
        _move(id: 'shadow-claw', type: 'ghost', power: 70),
      ],
    ),
  );
  final player = PsdkBattleCombatant.fromSetup(
    _combatant(id: 'player', type: 'ghost'),
  );
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkOpponentSlot: active,
      psdkPlayerSlot: player,
    },
    parties: <int, List<PsdkBattleCombatant>>{
      psdkOpponentSlot.bank: <PsdkBattleCombatant>[active, reserve],
      psdkPlayerSlot.bank: <PsdkBattleCombatant>[player],
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String type,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: PsdkBattleTypes(primary: type),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: moves ??
        <PsdkBattleMoveData>[
          _move(id: 'wait', type: 'normal', power: 0),
        ],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: power <= 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 15,
    priority: 0,
    battleEngineMethod: power <= 0 ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
