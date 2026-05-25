import '../../psdk/domain/psdk_battle_move.dart';

/// Clean PSDK move catalog entry.
///
/// The legacy package already exports `BattleMoveData`, so the clean migration
/// uses `BattleMoveDefinition` for the imported PSDK move data.
final class BattleMoveDefinition {
  BattleMoveDefinition({
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
    this.criticalRate = 1,
    this.effectChance,
    required String battleEngineMethod,
    required this.target,
    BattleMoveFlags flags = const BattleMoveFlags(),
    this.heal = false,
    this.charge = false,
    this.recharge = false,
    this.mirrorMoveAffected = true,
    this.snatchable = false,
    this.magicCoatAffected = false,
    List<BattleStageMod> stageMods = const <BattleStageMod>[],
    List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
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
        battleEngineMethod =
            _requireNonBlank(battleEngineMethod, 'battleEngineMethod'),
        flags = flags,
        _stageMods = List<BattleStageMod>.unmodifiable(stageMods),
        _statuses = List<PsdkBattleMoveStatus>.unmodifiable(statuses) {
    if (criticalRate < 0) {
      throw RangeError.range(criticalRate, 0, null, 'criticalRate');
    }
    if (effectChance != null) {
      _checkRange(effectChance!, min: 1, max: 100, name: 'effectChance');
    }
  }

  factory BattleMoveDefinition.fromPsdk(PsdkBattleMoveData move) {
    return BattleMoveDefinition(
      id: move.id,
      dbSymbol: move.dbSymbol,
      name: move.name,
      type: move.type,
      category: move.category,
      power: move.power,
      accuracy: move.accuracy,
      pp: move.pp,
      currentPp: move.currentPp,
      priority: move.priority,
      criticalRate: move.criticalRate,
      effectChance: move.effectChance,
      battleEngineMethod: move.battleEngineMethod,
      target: move.target,
      heal: move.heal,
      flags: BattleMoveFlags(
        contact: move.contact,
        protectable: move.protectable,
        sound: move.sound,
        bite: move.bite,
        pulse: move.pulse,
        wind: move.wind,
        ballistics: move.ballistics,
        kingRockUtility: move.kingRockUtility,
      ),
      charge: move.charge,
      recharge: move.recharge,
      mirrorMoveAffected: move.mirrorMoveAffected,
      snatchable: move.snatchable,
      magicCoatAffected: move.magicCoatAffected,
      stageMods: move.stageMods
          .map(
            (mod) => BattleStageMod(
              stat: mod.stat,
              stages: mod.stages,
              chance: mod.chance,
            ),
          )
          .toList(growable: false),
      statuses: move.statuses,
    );
  }

  final String id;
  final String dbSymbol;
  final String name;
  final String type;
  final PsdkBattleMoveCategory category;
  final int power;
  final int accuracy;
  final int pp;
  final int currentPp;
  final int priority;
  final int criticalRate;
  final int? effectChance;
  final String battleEngineMethod;
  final PsdkBattleMoveTarget target;
  final BattleMoveFlags flags;
  final bool heal;
  final bool charge;
  final bool recharge;
  final bool mirrorMoveAffected;
  final bool snatchable;
  final bool magicCoatAffected;
  final List<BattleStageMod> _stageMods;
  final List<PsdkBattleMoveStatus> _statuses;

  List<BattleStageMod> get stageMods =>
      List<BattleStageMod>.unmodifiable(_stageMods);

  List<PsdkBattleMoveStatus> get statuses =>
      List<PsdkBattleMoveStatus>.unmodifiable(_statuses);

  BattleMoveDefinition copyWith({
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
    BattleMoveFlags? flags,
    bool? heal,
    bool? charge,
    bool? recharge,
    bool? mirrorMoveAffected,
    bool? snatchable,
    bool? magicCoatAffected,
    List<BattleStageMod>? stageMods,
    List<PsdkBattleMoveStatus>? statuses,
  }) {
    return BattleMoveDefinition(
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
      flags: flags ?? this.flags,
      heal: heal ?? this.heal,
      charge: charge ?? this.charge,
      recharge: recharge ?? this.recharge,
      mirrorMoveAffected: mirrorMoveAffected ?? this.mirrorMoveAffected,
      snatchable: snatchable ?? this.snatchable,
      magicCoatAffected: magicCoatAffected ?? this.magicCoatAffected,
      stageMods: stageMods ?? this.stageMods,
      statuses: statuses ?? this.statuses,
    );
  }

  PsdkBattleMoveData get psdkMove {
    return PsdkBattleMoveData(
      id: id,
      dbSymbol: dbSymbol,
      name: name,
      type: type,
      category: category,
      power: power,
      accuracy: accuracy,
      pp: pp,
      currentPp: currentPp,
      priority: priority,
      criticalRate: criticalRate,
      effectChance: effectChance,
      battleEngineMethod: battleEngineMethod,
      target: target,
      contact: flags.contact,
      protectable: flags.protectable,
      sound: flags.sound,
      bite: flags.bite,
      pulse: flags.pulse,
      wind: flags.wind,
      ballistics: flags.ballistics,
      kingRockUtility: flags.kingRockUtility,
      heal: heal,
      charge: charge,
      recharge: recharge,
      mirrorMoveAffected: mirrorMoveAffected,
      snatchable: snatchable,
      magicCoatAffected: magicCoatAffected,
      stageMods: stageMods
          .map(
            (mod) => PsdkBattleMoveStageMod(
              stat: mod.stat,
              stages: mod.stages,
              chance: mod.chance,
            ),
          )
          .toList(growable: false),
      statuses: statuses,
    );
  }
}

final class BattleMoveFlags {
  const BattleMoveFlags({
    this.contact = false,
    this.protectable = true,
    this.sound = false,
    this.punch = false,
    this.powder = false,
    this.slicing = false,
    this.bite = false,
    this.pulse = false,
    this.wind = false,
    this.ballistics = false,
    this.kingRockUtility = false,
  });

  final bool contact;
  final bool protectable;
  final bool sound;
  final bool punch;
  final bool powder;
  final bool slicing;
  final bool bite;
  final bool pulse;
  final bool wind;
  final bool ballistics;
  final bool kingRockUtility;
}

final class BattleStageMod {
  const BattleStageMod({
    required this.stat,
    required this.stages,
    this.chance,
  });

  final String stat;
  final int stages;
  final int? chance;
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
