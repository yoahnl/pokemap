import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _playerSlot = PsdkBattleSlotRef(bank: 0, position: 0);

void main() {
  group('PSDK side and slot condition stacks', () {
    test('side condition persists when the active battler changes', () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final bench = _battler('bench', bank: 0, position: -1, partyIndex: 1);
      final bank = BattleBank(
        index: 0,
        slots: <BattleSlot>[BattleSlot(position: 0, activeBattler: active)],
        parties: <BattleParty>[
          BattleParty(id: 0, battlers: <BattleBattler>[active, bench]),
        ],
        sideConditions: SideConditionStack.empty(bank: 0).addOrReplace(
          const GenericBattleEffect(
            id: 'reflect',
            scope: BankBattleEffectScope(0),
            remainingTurns: 5,
          ),
        ),
      );

      bank.slotAt(0)!.clear();
      bank.placeBattler(battler: bench, position: 0);

      expect(bank.sideConditions.contains('reflect'), isTrue);
      expect(bank.activeBattlers.single.instanceId, 'bench');
    });

    test('slot condition follows the position instead of the outgoing battler',
        () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final bench = _battler('bench', bank: 0, position: -1, partyIndex: 1);
      final slot = BattleSlot(position: 0, activeBattler: active);
      final bank = BattleBank(
        index: 0,
        slots: <BattleSlot>[slot],
        parties: <BattleParty>[
          BattleParty(id: 0, battlers: <BattleBattler>[active, bench]),
        ],
      );
      slot.replaceSlotConditions(
        slot.slotConditions.addOrReplace(
          const GenericBattleEffect(
            id: 'future_sight',
            scope: SlotBattleEffectScope(_playerSlot),
            remainingTurns: 2,
          ),
        ),
      );

      slot.clear();
      bank.placeBattler(battler: bench, position: 0);

      expect(slot.slotConditions.contains('future_sight'), isTrue);
      expect(slot.activeBattler!.instanceId, 'bench');
      expect(active.position, 0);
      expect(bench.position, 0);
    });

    test('side and slot conditions tick durations and expire at zero', () {
      final side = SideConditionStack.empty(bank: 0)
          .addOrReplace(
            const GenericBattleEffect(
              id: 'mist',
              scope: BankBattleEffectScope(0),
              remainingTurns: 2,
            ),
          )
          .addOrReplace(
            const GenericBattleEffect(
              id: 'lucky_chant',
              scope: BankBattleEffectScope(0),
              remainingTurns: 1,
            ),
          );
      final slot = SlotConditionStack.empty(slot: _playerSlot)
          .addOrReplace(
            const GenericBattleEffect(
              id: 'doom_desire',
              scope: SlotBattleEffectScope(_playerSlot),
              remainingTurns: 2,
            ),
          )
          .addOrReplace(
            const GenericBattleEffect(
              id: 'pledge_sea',
              scope: SlotBattleEffectScope(_playerSlot),
              remainingTurns: 1,
            ),
          );

      final tickedSide = side.tickDurations();
      final tickedSlot = slot.tickDurations();

      expect(tickedSide.stack.contains('mist'), isTrue);
      expect(tickedSide.stack.effect('mist')!.remainingTurns, 1);
      expect(tickedSide.stack.contains('lucky_chant'), isFalse);
      expect(tickedSide.expired.map((effect) => effect.id), <String>[
        'lucky_chant',
      ]);
      expect(tickedSlot.stack.contains('doom_desire'), isTrue);
      expect(tickedSlot.stack.effect('doom_desire')!.remainingTurns, 1);
      expect(tickedSlot.stack.contains('pledge_sea'), isFalse);
      expect(tickedSlot.expired.map((effect) => effect.id), <String>[
        'pledge_sea',
      ]);
    });

    test('condition stacks reject effects scoped to another owner', () {
      expect(
        () => SideConditionStack.empty(bank: 0).addOrReplace(
          const GenericBattleEffect(
            id: 'reflect',
            scope: BankBattleEffectScope(1),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SlotConditionStack.empty(slot: _playerSlot).addOrReplace(
          const GenericBattleEffect(
            id: 'future_sight',
            scope: SlotBattleEffectScope(PsdkBattleSlotRef(
              bank: 1,
              position: 0,
            )),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

BattleBattler _battler(
  String id, {
  required int bank,
  required int position,
  required int partyIndex,
}) {
  return BattleBattler(
    instanceId: id,
    speciesId: id,
    displayName: id,
    bank: bank,
    position: position,
    partyId: bank,
    partyIndex: partyIndex,
    level: 10,
    types: const BattleTypes(primary: 'normal'),
    stats: const BattleComputedStats(
      attack: 10,
      defense: 10,
      specialAttack: 10,
      specialDefense: 10,
      speed: 10,
    ),
    hp: 40,
    maxHp: 40,
    moves: <BattleMoveInstance>[
      BattleMoveInstance(
        id: 'tackle',
        dbSymbol: 'tackle',
        pp: 35,
        maxPp: 35,
      ),
    ],
  );
}
