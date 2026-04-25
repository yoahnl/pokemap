import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_setup.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import 'battle_bank.dart';
import 'battle_battler.dart';
import 'battle_party.dart';
import 'battle_slot.dart';

/// PSDK-style battle topology based on banks and positions.
///
/// Lot 5 keeps this model additive. The legacy `BattleState` still owns the
/// runtime path, while this topology gives the clean engine the vocabulary PSDK
/// handlers need for target resolution, switches and side effects.
final class BattleTopology {
  BattleTopology({
    required List<BattleBank> banks,
  }) : _banks = List<BattleBank>.unmodifiable(banks) {
    final bankIds = <int>{};
    for (final bank in _banks) {
      if (!bankIds.add(bank.index)) {
        throw ArgumentError('Duplicate bank ${bank.index}.');
      }
    }
  }

  factory BattleTopology.fromPsdkSetup(PsdkBattleSetup setup) {
    return BattleTopology(
      banks: <BattleBank>[
        _bankFromPsdkSetup(
          bank: psdkPlayerSlot.bank,
          position: psdkPlayerSlot.position,
          setup: setup.player,
        ),
        _bankFromPsdkSetup(
          bank: psdkOpponentSlot.bank,
          position: psdkOpponentSlot.position,
          setup: setup.opponent,
        ),
      ],
    );
  }

  factory BattleTopology.fromPsdkState(PsdkBattleState state) {
    final sortedEntries = state.combatants.entries.toList()
      ..sort((left, right) {
        final bankCompare = left.key.bank.compareTo(right.key.bank);
        if (bankCompare != 0) {
          return bankCompare;
        }
        return left.key.position.compareTo(right.key.position);
      });

    final slotsByBank = <int, List<BattleSlot>>{};
    final battlersByBank = <int, List<BattleBattler>>{};
    for (final entry in sortedEntries) {
      final slot = entry.key;
      final battler = BattleBattler.fromPsdkCombatant(
        bank: slot.bank,
        position: slot.position,
        partyId: slot.bank,
        partyIndex: slot.position,
        combatant: entry.value,
      );
      slotsByBank
          .putIfAbsent(slot.bank, () => <BattleSlot>[])
          .add(BattleSlot(position: slot.position, activeBattler: battler));
      battlersByBank.putIfAbsent(slot.bank, () => <BattleBattler>[]).add(
            battler,
          );
    }

    final banks = <BattleBank>[
      for (final bankIndex in slotsByBank.keys)
        BattleBank(
          index: bankIndex,
          slots: slotsByBank[bankIndex]!,
          parties: <BattleParty>[
            BattleParty(id: bankIndex, battlers: battlersByBank[bankIndex]!),
          ],
        ),
    ]..sort(
        (left, right) => left.index.compareTo(right.index),
      );
    return BattleTopology(banks: banks);
  }

  final List<BattleBank> _banks;

  List<BattleBank> get banks => List<BattleBank>.unmodifiable(_banks);

  BattleBank? bankAt(int index) {
    for (final bank in _banks) {
      if (bank.index == index) {
        return bank;
      }
    }
    return null;
  }

  BattleSlot? slotAt(BattlePositionRef ref) => bankAt(ref.bank)?.slotAt(
        ref.position,
      );

  BattleBattler? battlerAt(BattlePositionRef ref) {
    return slotAt(ref)?.activeBattler;
  }

  Iterable<BattleSlot> get emptySlots sync* {
    for (final bank in _banks) {
      for (final slot in bank.slots) {
        if (slot.isEmpty) {
          yield slot;
        }
      }
    }
  }

  Iterable<BattleBattler> get activeBattlers sync* {
    for (final bank in _banks) {
      yield* bank.activeBattlers;
    }
  }

  Iterable<BattleBattler> get aliveBattlers =>
      activeBattlers.where((battler) => battler.isAlive);

  Iterable<BattleBattler> alliesOf(BattleBattler battler) {
    return aliveBattlers.where(
      (other) =>
          other.bank == battler.bank && other.instanceId != battler.instanceId,
    );
  }

  Iterable<BattleBattler> foesOf(BattleBattler battler) {
    return aliveBattlers.where((other) => other.bank != battler.bank);
  }

  Iterable<BattleBattler> adjacentFoesOf(BattleBattler battler) {
    return foesOf(battler).where(
      (other) => (other.position - battler.position).abs() <= 1,
    );
  }

  Iterable<BattleBattler> replacementsFor(BattlePositionRef slot) {
    return bankAt(slot.bank)?.replacementCandidatesFor(slot) ??
        const <BattleBattler>[];
  }

  void placeBattler({
    required BattleBattler battler,
    required BattlePositionRef slot,
  }) {
    final bank = bankAt(slot.bank);
    if (bank == null) {
      throw StateError('No bank ${slot.bank}.');
    }
    bank.placeBattler(battler: battler, position: slot.position);
  }
}

BattleBank _bankFromPsdkSetup({
  required int bank,
  required int position,
  required PsdkBattleCombatantSetup setup,
}) {
  final battler = BattleBattler.fromPsdkSetup(
    bank: bank,
    position: position,
    partyId: bank,
    partyIndex: 0,
    setup: setup,
  );
  return BattleBank(
    index: bank,
    slots: <BattleSlot>[
      BattleSlot(position: position, activeBattler: battler),
    ],
    parties: <BattleParty>[
      BattleParty(id: bank, battlers: <BattleBattler>[battler]),
    ],
  );
}
