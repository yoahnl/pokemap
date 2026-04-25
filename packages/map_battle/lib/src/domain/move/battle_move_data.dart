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
      flags: BattleMoveFlags(protectable: move.protectable),
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
  final List<BattleStageMod> _stageMods;
  final List<PsdkBattleMoveStatus> _statuses;

  List<BattleStageMod> get stageMods =>
      List<BattleStageMod>.unmodifiable(_stageMods);

  List<PsdkBattleMoveStatus> get statuses =>
      List<PsdkBattleMoveStatus>.unmodifiable(_statuses);

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
      protectable: flags.protectable,
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
  });

  final bool contact;
  final bool protectable;
  final bool sound;
  final bool punch;
  final bool powder;
  final bool slicing;
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
