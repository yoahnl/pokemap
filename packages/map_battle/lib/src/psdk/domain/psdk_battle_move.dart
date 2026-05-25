/// Damage category imported from Pokemon SDK Studio move data.
enum PsdkBattleMoveCategory {
  physical,
  special,
  status,
}

enum PsdkBattleMoveTarget {
  adjacentAlly,
  adjacentAllyOrSelf,
  adjacentFoe,
  allAdjacent,
  allAdjacentFoes,
  allBattlers,
  allFoes,
  allAllies,
  anyFoe,
  bank,
  randomFoe,
  self,
  user,
  userSide,
  foeSide,
  none,
}

extension PsdkBattleMoveTargetSemantics on PsdkBattleMoveTarget {
  bool get requiresBattlerTarget {
    return switch (this) {
      PsdkBattleMoveTarget.bank ||
      PsdkBattleMoveTarget.userSide ||
      PsdkBattleMoveTarget.foeSide ||
      PsdkBattleMoveTarget.none =>
        false,
      _ => true,
    };
  }
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

/// Volatile statuses carried by PSDK move data.
enum PsdkBattleVolatileStatus {
  confusion,
  flinch,
}

/// Status rider carried by a PSDK move import.
///
/// The engine currently consumes deterministic or chance-gated major status
/// application plus the first explicit volatile rider needed by Studio data.
class PsdkBattleMoveStatus {
  PsdkBattleMoveStatus({
    required PsdkBattleMajorStatus status,
    required int chance,
  })  : majorStatus = status,
        volatileStatus = null,
        chance = _checkRange(chance, min: 1, max: 100, name: 'chance');

  PsdkBattleMoveStatus.volatile({
    required PsdkBattleVolatileStatus status,
    required int chance,
  })  : majorStatus = null,
        volatileStatus = status,
        chance = _checkRange(chance, min: 1, max: 100, name: 'chance');

  /// Non-volatile status, when this rider represents a major status.
  ///
  /// Kept nullable so Studio volatile statuses such as `CONFUSED` can travel
  /// through the same ordered status rider list without lying as a major
  /// condition.
  final PsdkBattleMajorStatus? majorStatus;
  final PsdkBattleVolatileStatus? volatileStatus;
  final int chance;

  PsdkBattleMajorStatus get status {
    final value = majorStatus;
    if (value == null) {
      throw StateError('This PSDK move status is volatile, not major.');
    }
    return value;
  }
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
    this.contact = false,
    this.protectable = true,
    this.sound = false,
    this.bite = false,
    this.pulse = false,
    this.wind = false,
    this.ballistics = false,
    this.dance = false,
    this.kingRockUtility = false,
    this.heal = false,
    this.charge = false,
    this.recharge = false,
    this.mirrorMoveAffected = true,
    this.snatchable = false,
    this.magicCoatAffected = false,
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
  final bool contact;
  final bool protectable;
  final bool sound;
  final bool bite;
  final bool pulse;
  final bool wind;
  final bool ballistics;
  final bool dance;
  final bool kingRockUtility;
  final bool heal;
  final bool charge;
  final bool recharge;
  final bool mirrorMoveAffected;
  final bool snatchable;
  final bool magicCoatAffected;
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
    bool? contact,
    bool? protectable,
    bool? sound,
    bool? bite,
    bool? pulse,
    bool? wind,
    bool? ballistics,
    bool? dance,
    bool? kingRockUtility,
    bool? heal,
    bool? charge,
    bool? recharge,
    bool? mirrorMoveAffected,
    bool? snatchable,
    bool? magicCoatAffected,
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
      contact: contact ?? this.contact,
      protectable: protectable ?? this.protectable,
      sound: sound ?? this.sound,
      bite: bite ?? this.bite,
      pulse: pulse ?? this.pulse,
      wind: wind ?? this.wind,
      ballistics: ballistics ?? this.ballistics,
      dance: dance ?? this.dance,
      kingRockUtility: kingRockUtility ?? this.kingRockUtility,
      heal: heal ?? this.heal,
      charge: charge ?? this.charge,
      recharge: recharge ?? this.recharge,
      mirrorMoveAffected: mirrorMoveAffected ?? this.mirrorMoveAffected,
      snatchable: snatchable ?? this.snatchable,
      magicCoatAffected: magicCoatAffected ?? this.magicCoatAffected,
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
