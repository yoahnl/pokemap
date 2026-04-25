import '../battle/battle_slot.dart';
import 'battle_move_data.dart';

/// Move instance owned by a battler in the clean PSDK topology.
///
/// PSDK battle scripts mutate PP per battler move instance. Keeping this object
/// mutable avoids pretending the imported move catalog entry itself changes.
final class BattleMoveInstance {
  BattleMoveInstance({
    required String id,
    required String dbSymbol,
    required int pp,
    required int maxPp,
    BattleMoveDefinition? data,
    this.used = false,
    this.consecutiveUseCount = 0,
    this.damageDealt = 0,
    List<BattlePositionRef> originalTargets = const <BattlePositionRef>[],
  })  : id = _requireNonBlank(id, 'id'),
        dbSymbol = _requireNonBlank(dbSymbol, 'dbSymbol'),
        maxPp = _checkNonNegative(maxPp, 'maxPp'),
        pp = _checkPp(pp, maxPp),
        data = data,
        originalTargets = List<BattlePositionRef>.unmodifiable(
          originalTargets,
        );

  factory BattleMoveInstance.fromDefinition(BattleMoveDefinition data) {
    return BattleMoveInstance(
      id: data.id,
      dbSymbol: data.dbSymbol,
      pp: data.currentPp,
      maxPp: data.pp,
      data: data,
    );
  }

  final String id;
  final String dbSymbol;
  final BattleMoveDefinition? data;
  int pp;
  final int maxPp;
  bool used;
  int consecutiveUseCount;
  int damageDealt;
  List<BattlePositionRef> originalTargets;

  bool get hasPp => pp > 0;

  bool spendPp([int amount = 1]) {
    if (amount <= 0) {
      throw RangeError.range(amount, 1, null, 'amount');
    }
    if (pp < amount) {
      pp = 0;
      return false;
    }
    pp -= amount;
    return true;
  }

  void restorePp(int amount) {
    if (amount <= 0) {
      throw RangeError.range(amount, 1, null, 'amount');
    }
    pp = (pp + amount).clamp(0, maxPp).toInt();
  }

  void markUsed({
    bool decreasePp = true,
    int damageDealt = 0,
    List<BattlePositionRef> originalTargets = const <BattlePositionRef>[],
  }) {
    used = true;
    consecutiveUseCount += 1;
    this.damageDealt += _checkNonNegative(damageDealt, 'damageDealt');
    this.originalTargets = List<BattlePositionRef>.unmodifiable(
      originalTargets,
    );
    if (decreasePp && pp > 0) {
      pp -= 1;
    }
  }

  void resetConsecutiveUse() {
    consecutiveUseCount = 0;
  }
}

int _checkNonNegative(int value, String name) {
  if (value < 0) {
    throw RangeError.range(value, 0, null, name);
  }
  return value;
}

int _checkPp(int pp, int maxPp) {
  if (pp < 0 || pp > maxPp) {
    throw RangeError.range(pp, 0, maxPp, 'pp');
  }
  return pp;
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
