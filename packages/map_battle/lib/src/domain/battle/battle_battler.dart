import '../../psdk/domain/psdk_battle_combatant.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_instance.dart';
import 'battle_slot.dart';
import 'battle_stats.dart';

/// Small mutable effect id stack for the clean battler.
///
/// It is deliberately not a generic effect system yet. Lot 5 only needs a
/// stable ownership place so later handlers can attach real effect objects.
final class BattleEffectStack {
  BattleEffectStack([Iterable<String> initialEffects = const <String>[]])
      : _effects = <String>[...initialEffects];

  final List<String> _effects;

  List<String> get values => List<String>.unmodifiable(_effects);

  bool contains(String effectId) => _effects.contains(effectId);

  void add(String effectId) {
    if (effectId.trim().isEmpty) {
      throw ArgumentError.value(effectId, 'effectId', 'must not be blank');
    }
    _effects.add(effectId);
  }

  bool remove(String effectId) => _effects.remove(effectId);
}

/// Minimal history owned by one battler.
final class BattleBattlerHistory {
  final List<String> _usedMoveIds = <String>[];

  String? get lastMoveId => _usedMoveIds.isEmpty ? null : _usedMoveIds.last;

  List<String> get usedMoveIds => List<String>.unmodifiable(_usedMoveIds);

  void markMoveUsed(String moveId) {
    if (moveId.trim().isEmpty) {
      throw ArgumentError.value(moveId, 'moveId', 'must not be blank');
    }
    _usedMoveIds.add(moveId);
  }
}

/// Mutable PSDK-style battler.
///
/// The clean engine keeps this object internal to the battle domain. Public
/// state still snapshots through immutable container views, but PSDK handlers
/// need a battler that can move slots, lose HP, spend PP and accumulate effects.
final class BattleBattler {
  BattleBattler({
    required String instanceId,
    required String speciesId,
    required String displayName,
    required int bank,
    required int position,
    required int partyId,
    required int partyIndex,
    required int level,
    required this.types,
    required this.stats,
    required int hp,
    required int maxHp,
    required List<BattleMoveInstance> moves,
    this.abilityId,
    this.heldItemId,
    BattleStatStageSet? stages,
    BattleEffectStack? effects,
    BattleBattlerHistory? history,
  })  : maxHp = _checkPositive(maxHp, 'maxHp'),
        instanceId = _requireNonBlank(instanceId, 'instanceId'),
        speciesId = _requireNonBlank(speciesId, 'speciesId'),
        displayName = _requireNonBlank(displayName, 'displayName'),
        bank = _checkNonNegative(bank, 'bank'),
        position = _checkReserveOrActivePosition(position),
        partyId = _checkNonNegative(partyId, 'partyId'),
        partyIndex = _checkNonNegative(partyIndex, 'partyIndex'),
        level = _checkPositive(level, 'level'),
        hp = hp.clamp(0, maxHp).toInt(),
        _moves = List<BattleMoveInstance>.unmodifiable(moves),
        stages = stages ?? BattleStatStageSet.neutral(),
        effects = effects ?? BattleEffectStack(),
        history = history ?? BattleBattlerHistory();

  factory BattleBattler.fromPsdkSetup({
    required int bank,
    required int position,
    required int partyId,
    required int partyIndex,
    required PsdkBattleCombatantSetup setup,
  }) {
    return BattleBattler(
      instanceId: setup.id,
      speciesId: setup.speciesId,
      displayName: setup.displayName,
      bank: bank,
      position: position,
      partyId: partyId,
      partyIndex: partyIndex,
      level: setup.level,
      types: BattleTypes.fromPsdk(setup.types),
      stats: BattleComputedStats.fromPsdk(setup.stats),
      hp: setup.currentHp,
      maxHp: setup.maxHp,
      moves: setup.moves
          .map(BattleMoveDefinition.fromPsdk)
          .map(BattleMoveInstance.fromDefinition)
          .toList(),
      effects: BattleEffectStack(setup.effects.values),
    );
  }

  factory BattleBattler.fromPsdkCombatant({
    required int bank,
    required int position,
    required int partyId,
    required int partyIndex,
    required PsdkBattleCombatant combatant,
  }) {
    return BattleBattler(
      instanceId: combatant.id,
      speciesId: combatant.speciesId,
      displayName: combatant.displayName,
      bank: bank,
      position: position,
      partyId: partyId,
      partyIndex: partyIndex,
      level: combatant.level,
      types: BattleTypes.fromPsdk(combatant.types),
      stats: BattleComputedStats.fromPsdk(combatant.stats),
      hp: combatant.currentHp,
      maxHp: combatant.maxHp,
      moves: combatant.moves
          .map(BattleMoveDefinition.fromPsdk)
          .map(BattleMoveInstance.fromDefinition)
          .toList(),
      effects: BattleEffectStack(combatant.effects.values),
    );
  }

  final String instanceId;
  final String speciesId;
  final String displayName;
  final int bank;
  int position;
  final int partyId;
  final int partyIndex;
  final int level;
  BattleTypes types;
  BattleComputedStats stats;
  int hp;
  final int maxHp;
  final List<BattleMoveInstance> _moves;
  String? abilityId;
  String? heldItemId;
  final BattleStatStageSet stages;
  final BattleEffectStack effects;
  final BattleBattlerHistory history;

  List<BattleMoveInstance> get moves =>
      List<BattleMoveInstance>.unmodifiable(_moves);

  bool get isAlive => hp > 0;
  bool get isKo => hp <= 0;
  BattlePositionRef get slot => BattlePositionRef(
        bank: bank,
        position: position,
      );

  void applyDamage(int amount) {
    if (amount < 0) {
      throw RangeError.range(amount, 0, null, 'amount');
    }
    hp = (hp - amount).clamp(0, maxHp).toInt();
  }

  void heal(int amount) {
    if (amount < 0) {
      throw RangeError.range(amount, 0, null, 'amount');
    }
    hp = (hp + amount).clamp(0, maxHp).toInt();
  }
}

int _checkNonNegative(int value, String name) {
  if (value < 0) {
    throw RangeError.range(value, 0, null, name);
  }
  return value;
}

int _checkPositive(int value, String name) {
  if (value <= 0) {
    throw RangeError.range(value, 1, null, name);
  }
  return value;
}

int _checkReserveOrActivePosition(int value) {
  if (value < -1) {
    throw RangeError.range(value, -1, null, 'position');
  }
  return value;
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
