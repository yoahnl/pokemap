import 'battle_battler.dart';
import 'battle_party.dart';
import 'battle_slot.dart';

/// PSDK bank containing active positions and one or more parties.
final class BattleBank {
  BattleBank({
    required this.index,
    required List<BattleSlot> slots,
    required List<BattleParty> parties,
  })  : _slots = List<BattleSlot>.unmodifiable(slots),
        _parties = List<BattleParty>.unmodifiable(parties) {
    if (index < 0) {
      throw RangeError.range(index, 0, null, 'index');
    }
    final positions = <int>{};
    final partyIds = <int>{};
    for (final slot in _slots) {
      slot.attachToBank(index);
      if (!positions.add(slot.position)) {
        throw ArgumentError(
          'Duplicate slot position ${slot.position} in bank $index.',
        );
      }
      final battler = slot.activeBattler;
      if (battler != null && battler.bank != index) {
        throw ArgumentError(
          'Slot ${slot.position} in bank $index contains battler '
          '${battler.instanceId} from bank ${battler.bank}.',
        );
      }
      if (battler != null && battler.position != slot.position) {
        throw ArgumentError(
          'Slot ${slot.position} in bank $index contains battler '
          '${battler.instanceId} at position ${battler.position}.',
        );
      }
    }
    for (final party in _parties) {
      if (!partyIds.add(party.id)) {
        throw ArgumentError('Duplicate party ${party.id} in bank $index.');
      }
      if (party.id != index) {
        throw ArgumentError(
          'BattleBank $index cannot own party ${party.id}.',
        );
      }
      for (final battler in party.battlers) {
        if (battler.bank != index) {
          throw ArgumentError(
            'BattleBank $index cannot own battler ${battler.instanceId} '
            'from bank ${battler.bank}.',
          );
        }
      }
    }
  }

  final int index;
  final List<BattleSlot> _slots;
  final List<BattleParty> _parties;

  List<BattleSlot> get slots => List<BattleSlot>.unmodifiable(_slots);
  List<BattleParty> get parties => List<BattleParty>.unmodifiable(_parties);

  Iterable<BattleBattler> get activeBattlers sync* {
    for (final slot in _slots) {
      final battler = slot.activeBattler;
      if (battler != null) {
        yield battler;
      }
    }
  }

  BattleSlot? slotAt(int position) {
    for (final slot in _slots) {
      if (slot.position == position) {
        return slot;
      }
    }
    return null;
  }

  Iterable<BattleBattler> replacementCandidatesFor(BattlePositionRef slotRef) {
    if (slotRef.bank != index) {
      return const <BattleBattler>[];
    }
    if (slotAt(slotRef.position) == null) {
      return const <BattleBattler>[];
    }
    final activeIds =
        activeBattlers.map((battler) => battler.instanceId).toSet();
    return _parties
        .expand((party) => party.aliveBattlers)
        .where((battler) => !activeIds.contains(battler.instanceId));
  }

  void placeBattler({
    required BattleBattler battler,
    required int position,
  }) {
    final slot = slotAt(position);
    if (slot == null) {
      throw StateError('No slot $position in bank $index.');
    }
    final currentSlot = _activeSlotOf(battler);
    if (currentSlot != null && currentSlot.position != position) {
      throw StateError(
        'Battler ${battler.instanceId} is already active at bank $index '
        'position ${currentSlot.position}. Use an explicit switch operation.',
      );
    }
    final occupant = slot.activeBattler;
    if (occupant != null && occupant.instanceId != battler.instanceId) {
      throw StateError(
        'Slot $position in bank $index is already occupied by '
        '${occupant.instanceId}. Use an explicit switch operation.',
      );
    }
    slot.place(bank: index, battler: battler);
  }

  BattleSlot? _activeSlotOf(BattleBattler battler) {
    for (final slot in _slots) {
      if (slot.activeBattler?.instanceId == battler.instanceId) {
        return slot;
      }
    }
    return null;
  }
}
