/// Damage category imported from Pokemon SDK Studio move data.
enum PsdkBattleMoveCategory {
  physical,
  special,
  status,
}

/// Target shapes supported by the first PSDK foundation slice.
///
/// Only `adjacentFoe` and `user` are exposed because they are consumed by the
/// resolver today. Adding a target here must come with resolver behavior and
/// tests, otherwise the public API would overstate engine support.
enum PsdkBattleMoveTarget {
  adjacentFoe,
  user,
}

/// Major statuses that the first PSDK status behavior can represent.
enum PsdkBattleMajorStatus {
  paralysis,
  burn,
  poison,
  toxic,
  sleep,
  freeze,
}

/// Status rider carried by a PSDK move import.
///
/// The engine currently consumes deterministic or chance-gated major status
/// application. Other PSDK effects should become explicit contracts later,
/// rather than being squeezed into this small status rider.
class PsdkBattleMoveStatus {
  PsdkBattleMoveStatus({
    required this.status,
    required int chance,
  }) : chance = _checkRange(chance, min: 1, max: 100, name: 'chance');

  final PsdkBattleMajorStatus status;
  final int chance;
}

class PsdkBattleMoveStageMod {
  const PsdkBattleMoveStageMod({
    required this.stat,
    required this.stages,
    this.chance,
  });

  final String stat;
  final int stages;
  final int? chance;
}

/// Move DTO for imported PSDK data.
///
/// [battleEngineMethod] is the migration seam to Ruby PSDK scripts (`s_basic`,
/// `s_status`, etc.). Unknown methods throw loudly instead of degrading to a
/// fake damage move, because silent fallback would make imported data look
/// supported when it is not.
class PsdkBattleMoveData {
  PsdkBattleMoveData({
    required String id,
    required String dbSymbol,
    required String name,
    required String type,
    required this.category,
    required int power,
    required int accuracy,
    required int pp,
    int? currentPp,
    required this.priority,
    int criticalRate = 1,
    this.effectChance,
    required String battleEngineMethod,
    required this.target,
    this.protectable = true,
    List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
    List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
  })  : id = _requireNonBlank(id, 'id'),
        dbSymbol = _requireNonBlank(dbSymbol, 'dbSymbol'),
        name = _requireNonBlank(name, 'name'),
        type = _requireNonBlank(type, 'type'),
        power = _checkNonNegative(power, 'power'),
        accuracy = _checkRange(accuracy, min: 0, max: 100, name: 'accuracy'),
        pp = _checkNonNegative(pp, 'pp'),
        currentPp = _checkRange(
          currentPp ?? pp,
          min: 0,
          max: pp,
          name: 'currentPp',
        ),
        criticalRate = _checkNonNegative(criticalRate, 'criticalRate'),
        battleEngineMethod =
            _requireNonBlank(battleEngineMethod, 'battleEngineMethod'),
        _statuses = List<PsdkBattleMoveStatus>.unmodifiable(statuses),
        _stageMods = List<PsdkBattleMoveStageMod>.unmodifiable(stageMods) {
    if (effectChance != null) {
      _checkRange(effectChance!, min: 1, max: 100, name: 'effectChance');
    }
  }

  final String id;
  final String dbSymbol;
  final String name;
  final String type;
  final PsdkBattleMoveCategory category;
  final int power;

  /// Accuracy percentage imported from PSDK Studio.
  ///
  /// PSDK treats `0` as a bypass-accuracy sentinel. The constructor allows it
  /// so later Studio importers can load valid data without normalizing it into
  /// a different meaning.
  final int accuracy;

  final int pp;
  final int currentPp;
  final int priority;
  final int criticalRate;
  final int? effectChance;
  final String battleEngineMethod;
  final PsdkBattleMoveTarget target;
  final bool protectable;
  final List<PsdkBattleMoveStatus> _statuses;
  final List<PsdkBattleMoveStageMod> _stageMods;

  /// Immutable view of PSDK move statuses.
  ///
  /// Future Studio importers can pass plain lists, but consumers cannot mutate
  /// move behavior after the engine has accepted it.
  List<PsdkBattleMoveStatus> get statuses =>
      List<PsdkBattleMoveStatus>.unmodifiable(_statuses);

  List<PsdkBattleMoveStageMod> get stageMods =>
      List<PsdkBattleMoveStageMod>.unmodifiable(_stageMods);

  bool get hasUsablePp => currentPp > 0;

  PsdkBattleMoveData spendPp([int amount = 1]) {
    if (amount <= 0) {
      throw RangeError.range(amount, 1, null, 'amount');
    }
    return copyWith(
      currentPp: (currentPp - amount).clamp(0, pp).toInt(),
    );
  }

  PsdkBattleMoveData copyWith({
    String? id,
    String? dbSymbol,
    String? name,
    String? type,
    PsdkBattleMoveCategory? category,
    int? power,
    int? accuracy,
    int? pp,
    int? currentPp,
    int? priority,
    int? criticalRate,
    int? effectChance,
    String? battleEngineMethod,
    PsdkBattleMoveTarget? target,
    bool? protectable,
    List<PsdkBattleMoveStatus>? statuses,
    List<PsdkBattleMoveStageMod>? stageMods,
  }) {
    return PsdkBattleMoveData(
      id: id ?? this.id,
      dbSymbol: dbSymbol ?? this.dbSymbol,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      power: power ?? this.power,
      accuracy: accuracy ?? this.accuracy,
      pp: pp ?? this.pp,
      currentPp: currentPp ?? this.currentPp,
      priority: priority ?? this.priority,
      criticalRate: criticalRate ?? this.criticalRate,
      effectChance: effectChance ?? this.effectChance,
      battleEngineMethod: battleEngineMethod ?? this.battleEngineMethod,
      target: target ?? this.target,
      protectable: protectable ?? this.protectable,
      statuses: statuses ?? this.statuses,
      stageMods: stageMods ?? this.stageMods,
    );
  }
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}

int _checkNonNegative(int value, String name) {
  if (value < 0) {
    throw RangeError.range(value, 0, null, name);
  }
  return value;
}

int _checkRange(
  int value, {
  required int min,
  required int max,
  required String name,
}) {
  if (value < min || value > max) {
    throw RangeError.range(value, min, max, name);
  }
  return value;
}
