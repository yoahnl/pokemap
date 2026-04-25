import 'battle_battler.dart';

/// Bank/position coordinate used by the clean PSDK topology.
///
/// The migration report used the name `BattleSlotRef`, but the legacy engine
/// already exports that name for side/slotIndex. `BattlePositionRef` keeps the
/// PSDK bank/position semantics explicit without breaking existing imports.
final class BattlePositionRef {
  const BattlePositionRef({
    required this.bank,
    required this.position,
  });

  final int bank;
  final int position;

  @override
  bool operator ==(Object other) {
    return other is BattlePositionRef &&
        other.bank == bank &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(bank, position);

  @override
  String toString() {
    return 'BattlePositionRef(bank: $bank, position: $position)';
  }
}

/// Active battle slot inside one PSDK bank.
final class BattleSlot {
  BattleSlot({
    required this.position,
    BattleBattler? activeBattler,
  }) : activeBattler = activeBattler {
    if (position < 0) {
      throw RangeError.range(position, 0, null, 'position');
    }
  }

  final int position;
  BattleBattler? activeBattler;
  int? _bank;

  bool get isEmpty => activeBattler == null;

  BattlePositionRef get ref {
    final bank = _bank;
    if (bank == null) {
      throw StateError(
        'BattleSlot.position $position is not attached to a bank yet.',
      );
    }
    return BattlePositionRef(bank: bank, position: position);
  }

  BattlePositionRef refForBank(int bank) {
    return BattlePositionRef(bank: bank, position: position);
  }

  void attachToBank(int bank) {
    _bank ??= bank;
    if (_bank != bank) {
      throw StateError(
        'BattleSlot.position $position is already attached to bank $_bank.',
      );
    }
  }

  void place({
    required int bank,
    required BattleBattler battler,
  }) {
    if (battler.bank != bank) {
      throw ArgumentError(
        'Cannot place battler ${battler.instanceId} from bank '
        '${battler.bank} into bank $bank.',
      );
    }
    battler.position = position;
    activeBattler = battler;
  }

  BattleBattler? clear() {
    final previous = activeBattler;
    activeBattler = null;
    return previous;
  }
}
