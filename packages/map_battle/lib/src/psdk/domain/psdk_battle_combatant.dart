import '../../domain/battler/battle_combatant_history.dart';
import '../../domain/battler/battle_transform_state.dart';
import '../../domain/battle/battle_slot.dart';
import '../../domain/effect/battle_effect.dart';
import '../../domain/effect/battle_effect_hooks.dart';
import '../../domain/effect/ability/ability_effect_registry.dart';
import '../../domain/effect/battle_effect_registry.dart';
import '../../domain/effect/battle_effect_stack.dart';
import '../../domain/effect/item/item_effect_registry.dart';
import '../../domain/move/battle_move_data.dart';
import '../../domain/move/battle_move_prevention.dart';
import 'psdk_battle_move.dart';
import 'psdk_battle_slots.dart';
import 'psdk_battle_state.dart';

/// Minimal type pair carried by the PSDK lane.
///
/// Types are present because PSDK data has them, but this foundation lot does
/// not yet claim type effectiveness parity. Damage currently uses raw stats and
/// power only; type processing belongs to a later explicit lot.
class PsdkBattleTypes {
  const PsdkBattleTypes({
    required this.primary,
    this.secondary,
  });

  final String primary;
  final String? secondary;
}

enum PsdkBattleGender {
  unknown,
  male,
  female,
}

const Object _unchanged = Object();

/// Resolved combat stats used by the first PSDK smoke engine.
class PsdkBattleStats {
  const PsdkBattleStats({
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  int valueOf(String stat) {
    return switch (_normalizeStat(stat)) {
      'attack' => attack,
      'defense' => defense,
      'specialAttack' => specialAttack,
      'specialDefense' => specialDefense,
      'speed' => speed,
      final normalized => throw ArgumentError.value(
          stat,
          'stat',
          'unsupported PSDK stat "$normalized"',
        ),
    };
  }
}

class PsdkBattleStatStages {
  PsdkBattleStatStages({
    Map<String, int> values = const <String, int>{},
  }) : _values = Map<String, int>.unmodifiable(
          values.map(
            (key, value) => MapEntry(
              _normalizeStat(key),
              value.clamp(-6, 6).toInt(),
            ),
          ),
        );

  factory PsdkBattleStatStages.neutral() {
    return PsdkBattleStatStages();
  }

  final Map<String, int> _values;

  int valueOf(String stat) {
    return _values[_normalizeStat(stat)] ?? 0;
  }

  PsdkBattleStatStages apply({
    required String stat,
    required int stages,
  }) {
    final normalized = _normalizeStat(stat);
    final next = Map<String, int>.from(_values);
    next[normalized] = (valueOf(normalized) + stages).clamp(-6, 6).toInt();
    return PsdkBattleStatStages(values: next);
  }

  Map<String, int> get values => Map<String, int>.unmodifiable(_values);

  int effectiveValue({
    required String stat,
    required int baseValue,
    bool ignorePositiveStage = false,
    bool ignoreNegativeStage = false,
    bool ignoreAllStages = false,
  }) {
    var stage = valueOf(stat);
    if (ignoreAllStages ||
        (stage > 0 && ignorePositiveStage) ||
        (stage < 0 && ignoreNegativeStage)) {
      stage = 0;
    }
    return _applyRegularStageMultiplier(baseValue, stage);
  }
}

class PsdkBattleMoveHistoryEntry {
  PsdkBattleMoveHistoryEntry({
    required String moveId,
    required this.turn,
    required List<PsdkBattleSlotRef> targets,
    this.attackOrder = 0,
  })  : moveId = _requireNonBlank(moveId, 'moveId'),
        targets = List<PsdkBattleSlotRef>.unmodifiable(targets);

  final String moveId;
  final int turn;
  final int attackOrder;
  final List<PsdkBattleSlotRef> targets;
}

class PsdkBattleMoveHistory {
  PsdkBattleMoveHistory({
    List<PsdkBattleMoveHistoryEntry> attempts =
        const <PsdkBattleMoveHistoryEntry>[],
    List<PsdkBattleMoveHistoryEntry> successes =
        const <PsdkBattleMoveHistoryEntry>[],
  })  : _attempts = List<PsdkBattleMoveHistoryEntry>.unmodifiable(attempts),
        _successes = List<PsdkBattleMoveHistoryEntry>.unmodifiable(successes);

  factory PsdkBattleMoveHistory.empty() {
    return PsdkBattleMoveHistory();
  }

  final List<PsdkBattleMoveHistoryEntry> _attempts;
  final List<PsdkBattleMoveHistoryEntry> _successes;

  List<PsdkBattleMoveHistoryEntry> get attempts =>
      List<PsdkBattleMoveHistoryEntry>.unmodifiable(_attempts);

  List<PsdkBattleMoveHistoryEntry> get successes =>
      List<PsdkBattleMoveHistoryEntry>.unmodifiable(_successes);

  String? get lastMoveId => _attempts.isEmpty ? null : _attempts.last.moveId;

  String? get lastSuccessfulMoveId =>
      _successes.isEmpty ? null : _successes.last.moveId;

  List<String> get usedMoveIds {
    return _attempts.map((entry) => entry.moveId).toList(growable: false);
  }

  List<String> get successfulMoveIds {
    return _successes.map((entry) => entry.moveId).toList(growable: false);
  }

  PsdkBattleMoveHistory recordAttempt({
    required String moveId,
    required int turn,
    required List<PsdkBattleSlotRef> targets,
    int attackOrder = 0,
  }) {
    return PsdkBattleMoveHistory(
      attempts: <PsdkBattleMoveHistoryEntry>[
        ..._attempts,
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: turn,
          targets: targets,
          attackOrder: attackOrder,
        ),
      ],
      successes: _successes,
    );
  }

  PsdkBattleMoveHistory recordSuccess({
    required String moveId,
    required int turn,
    required List<PsdkBattleSlotRef> targets,
    int attackOrder = 0,
  }) {
    return PsdkBattleMoveHistory(
      attempts: _attempts,
      successes: <PsdkBattleMoveHistoryEntry>[
        ..._successes,
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: turn,
          targets: targets,
          attackOrder: attackOrder,
        ),
      ],
    );
  }
}

final class PsdkBattleEffectIds {
  const PsdkBattleEffectIds._();

  static const String aquaRing = 'aqua_ring';
  static const String batonPass = 'baton_pass';
  static const String bind = 'bind';
  static const String cantSwitch = 'cant_switch';
  static const String centerOfAttention = 'center_of_attention';
  static const String confusion = 'confusion';
  static const String curse = 'curse';
  static const String endure = 'endure';
  static const String flinch = 'flinch';
  static const String forceNextMoveBase = 'force_next_move_base';
  static const String foresight = 'foresight';
  static const String ingrain = 'ingrain';
  static const String leechSeed = 'leech_seed';
  static const String mudSport = 'mud_sport';
  static const String protect = 'protect';
  static const String preventTargetsMove = 'prevent_targets_move';
  static const String twoTurnCharge = 'two_turn_charge';
  static const String waterSport = 'water_sport';
}

/// Immutable PSDK-lane effect id stack owned by one combatant.
///
/// This is intentionally still just ids, not arbitrary effect objects. Lot 14
/// only needs a stable place for `Protect` to live between two actions of the
/// same turn; richer counters, owners and callbacks should become explicit
/// contracts when those Pokemon SDK effects are ported.
class PsdkBattleEffectStack {
  PsdkBattleEffectStack({
    Iterable<String> values = const <String>[],
    Iterable<BattleEffect> effects = const <BattleEffect>[],
  }) : _stack = BattleEffectObjectStack(
          effects: <BattleEffect>[
            ...effects,
            for (final value in values)
              const BattleEffectRegistry().fromId(_requireEffectId(value)),
          ],
        );

  const PsdkBattleEffectStack.empty()
      : _stack = const BattleEffectObjectStack.empty();

  final BattleEffectObjectStack _stack;

  List<String> get values {
    return _stack.effects.map((effect) => effect.id).toList(growable: false);
  }

  List<BattleEffect> get effects => _stack.effects;

  bool contains(String effectId) => _stack.contains(_requireEffectId(effectId));

  PsdkBattleEffectStack add(String effectId) {
    final normalized = _requireEffectId(effectId);
    return addEffect(BattleEffectRegistry().fromId(normalized));
  }

  PsdkBattleEffectStack addEffect(BattleEffect effect) {
    final next = _stack.addOrReplace(effect);
    if (identical(next, _stack)) {
      return this;
    }
    return PsdkBattleEffectStack(effects: next.effects);
  }

  PsdkBattleEffectStack addEffects(Iterable<BattleEffect> effects) {
    final next = _stack.addAll(effects);
    if (identical(next, _stack)) {
      return this;
    }
    return PsdkBattleEffectStack(effects: next.effects);
  }

  PsdkBattleEffectStack remove(String effectId) {
    final normalized = _requireEffectId(effectId);
    if (!_stack.contains(normalized)) {
      return this;
    }
    return PsdkBattleEffectStack(effects: _stack.remove(normalized).effects);
  }

  PsdkBattleEffectStack withoutAbilityEffects() {
    return PsdkBattleEffectStack(
      effects: _stack.effects.where(
        (effect) => !effect.id.startsWith('ability:'),
      ),
    );
  }

  PsdkBattleEffectStack withoutItemEffects() {
    return PsdkBattleEffectStack(
      effects: _stack.effects.where(
        (effect) => !effect.id.startsWith('item:'),
      ),
    );
  }

  PsdkBattleEffectStack clearTurnScopedEffects() {
    return PsdkBattleEffectStack(
      effects: _stack.clearTurnScopedEffects().effects,
    );
  }

  BattleEffectVolatileStatusChangeResult dispatchPostVolatileStatusChange(
    BattleEffectVolatileStatusChangeContext context,
  ) {
    return _stack.dispatchPostVolatileStatusChange(context);
  }

  PsdkBattleEffectStack batonPassTransferEffects({
    required PsdkBattleSlotRef source,
    required PsdkBattleSlotRef target,
  }) {
    return PsdkBattleEffectStack(
      effects: _stack
          .batonPassTransferEffects(
            BattleEffectBatonPassContext(source: source, target: target),
          )
          .effects,
    );
  }

  PsdkBattleEffectStack withoutBatonPassTransferableEffects({
    required PsdkBattleSlotRef source,
    required PsdkBattleSlotRef target,
  }) {
    return PsdkBattleEffectStack(
      effects: _stack
          .withoutBatonPassTransferableEffects(
            BattleEffectBatonPassContext(source: source, target: target),
          )
          .effects,
    );
  }

  String? switchPreventionReason(BattleEffectSwitchPreventionContext context) {
    return _stack.switchPreventionReason(context);
  }

  bool switchPassthrough(BattleEffectSwitchPreventionContext context) {
    return _stack.switchPassthrough(context);
  }

  BattleEffectSwitchEventResult dispatchSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    return _stack.dispatchSwitchEvent(context);
  }

  BattleEffectSwitchOutResult dispatchSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    return _stack.dispatchSwitchOut(context);
  }

  String? statChangePreventionReason(
    BattleEffectStatChangePreventionContext context,
  ) {
    return _stack.statChangePreventionReason(context);
  }

  int resolveStatChange(BattleEffectStatChangeContext context) {
    return _stack.resolveStatChange(context);
  }

  BattleEffectStatChangeRedirectResult? statChangeRedirect(
    BattleEffectStatChangeContext context,
  ) {
    return _stack.statChangeRedirect(context);
  }

  BattleEffectStatChangePostResult dispatchStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    return _stack.dispatchStatChangePost(context);
  }

  String? statusPreventionReason(
    BattleEffectStatusPreventionContext context,
  ) {
    return _stack.statusPreventionReason(context);
  }

  BattleEffectStatusChangeResult dispatchPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    return _stack.dispatchPostStatusChange(context);
  }

  String? weatherPreventionReason(
    BattleEffectWeatherPreventionContext context,
  ) {
    return _stack.weatherPreventionReason(context);
  }

  BattleEffectFieldChangeResult dispatchPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    return _stack.dispatchPostWeatherChange(context);
  }

  String? terrainPreventionReason(
    BattleEffectTerrainPreventionContext context,
  ) {
    return _stack.terrainPreventionReason(context);
  }

  BattleEffectFieldChangeResult dispatchPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    return _stack.dispatchPostTerrainChange(context);
  }

  BattleEffectEndTurnResult dispatchEndTurn(
    BattleEffectEndTurnContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    return _stack.dispatchEndTurn(context, where: where);
  }

  BattleEffectDamagePreventionResult? dispatchDamagePrevention(
    BattleEffectDamagePreventionContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    return _stack.dispatchDamagePrevention(context, where: where);
  }

  BattleEffectPostDamageResult dispatchPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    return _stack.dispatchPostDamage(context);
  }

  BattleEffectPostActionResult dispatchPostAction(
    BattleEffectPostActionContext context,
  ) {
    return _stack.dispatchPostAction(context);
  }

  BattleEffectItemChangeResult dispatchPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    return _stack.dispatchPostItemChange(context);
  }

  BattleEffectLifecycleResult dispatchLifecycle(
    BattleEffectLifecycleContext context,
  ) {
    return _stack.dispatchLifecycle(context);
  }

  BattleMoveFailureReason? targetMovePreventionReason({
    required BattlePositionRef user,
    required BattlePositionRef target,
    required BattleMoveDefinition move,
    bool Function(BattleEffect effect)? where,
  }) {
    final context = BattleEffectMoveContext(
      user: user,
      target: target,
      move: move,
    );
    return _stack.targetMovePreventionReason(context, where: where);
  }

  BattleEffectUserMovePreventionResult? userMovePrevention(
    BattleEffectUserMovePreventionContext context, {
    bool Function(BattleEffect effect)? where,
  }) {
    return _stack.userMovePrevention(context, where: where);
  }

  BattleMoveSelectionPreventionResult? moveSelectionPrevention({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
  }) {
    return _stack.moveSelectionPrevention(
      BattleMoveSelectionPreventionContext(
        state: state,
        user: user,
        target: target,
        move: move,
      ),
    );
  }
}

/// Setup-time combatant DTO for the PSDK lane.
///
/// This mirrors PSDK import vocabulary where useful while staying a pure battle
/// contract. No runtime asset lookup or editor authoring behavior belongs here.
class PsdkBattleCombatantSetup {
  PsdkBattleCombatantSetup({
    required this.id,
    required this.speciesId,
    required this.displayName,
    required this.level,
    required this.maxHp,
    required this.currentHp,
    required this.types,
    required this.stats,
    required List<PsdkBattleMoveData> moves,
    int form = 0,
    this.abilityId,
    this.gender = PsdkBattleGender.unknown,
    this.dislikedFlavor,
    this.loyalty = 255,
    int ivHp = 31,
    int ivAttack = 31,
    int ivDefense = 31,
    int ivSpeed = 31,
    int ivSpecialAttack = 31,
    int ivSpecialDefense = 31,
    this.heldItemId,
    this.consumedItemId,
    this.itemConsumed = false,
    this.sleepTurns = 0,
    this.toxicCounter = 0,
    this.battleTurnCount = 0,
    this.lastBattleTurn,
    this.lastSentTurn,
    this.lastHitByMoveId,
    this.koCount = 0,
    this.switching = false,
    this.hasJustShifted = false,
    this.type3,
    List<String> temporaryTypes = const <String>[],
    this.transformState = const PsdkBattleTransformState(),
    this.majorStatus,
    this.statStages,
    this.moveHistory,
    this.damageHistory = const PsdkBattleDamageHistory.empty(),
    this.statHistory = const PsdkBattleStatHistory.empty(),
    double baseWeightKg = 1,
    double? currentWeightKg,
    PsdkBattleEffectStack? effects,
  })  : baseWeightKg = _requirePositiveWeight(baseWeightKg, 'baseWeightKg'),
        currentWeightKg = _requirePositiveWeight(
          currentWeightKg ?? baseWeightKg,
          'currentWeightKg',
        ),
        form = _checkNonNegativeInt(form, 'form'),
        ivHp = _checkIv(ivHp, 'ivHp'),
        ivAttack = _checkIv(ivAttack, 'ivAttack'),
        ivDefense = _checkIv(ivDefense, 'ivDefense'),
        ivSpeed = _checkIv(ivSpeed, 'ivSpeed'),
        ivSpecialAttack = _checkIv(ivSpecialAttack, 'ivSpecialAttack'),
        ivSpecialDefense = _checkIv(ivSpecialDefense, 'ivSpecialDefense'),
        temporaryTypes = List<String>.unmodifiable(
          temporaryTypes.map((type) => _requireNonBlank(type, 'type')),
        ),
        effects = effects ?? const PsdkBattleEffectStack.empty(),
        _moves = List<PsdkBattleMoveData>.unmodifiable(moves);

  final String id;
  final String speciesId;
  final String displayName;
  final int level;
  final int maxHp;
  final int currentHp;
  final PsdkBattleTypes types;
  final PsdkBattleStats stats;
  final int form;
  final String? abilityId;
  final PsdkBattleGender gender;
  final String? dislikedFlavor;
  final int loyalty;
  final int ivHp;
  final int ivAttack;
  final int ivDefense;
  final int ivSpeed;
  final int ivSpecialAttack;
  final int ivSpecialDefense;
  final String? heldItemId;
  final String? consumedItemId;
  final bool itemConsumed;
  final int sleepTurns;
  final int toxicCounter;
  final int battleTurnCount;
  final int? lastBattleTurn;
  final int? lastSentTurn;
  final String? lastHitByMoveId;
  final int koCount;
  final bool switching;
  final bool hasJustShifted;
  final String? type3;
  final List<String> temporaryTypes;
  final PsdkBattleTransformState transformState;
  final PsdkBattleMajorStatus? majorStatus;
  final PsdkBattleStatStages? statStages;
  final PsdkBattleMoveHistory? moveHistory;
  final PsdkBattleDamageHistory damageHistory;
  final PsdkBattleStatHistory statHistory;

  /// Species/base weight in kilograms for PSDK weight-sensitive moves.
  ///
  /// This stays in the battle package snapshot instead of `map_core` for now:
  /// the migration lot only needs combat-time data, while editor/runtime
  /// import contracts can be wired later without changing this formula seam.
  final double baseWeightKg;

  /// Current battle weight in kilograms after temporary PSDK effects.
  ///
  /// It defaults to [baseWeightKg]. Low Kick and Heavy Slam currently use this
  /// neutral value; future weight-modifying effects can update it through
  /// `copyWith` without changing move formulas.
  final double currentWeightKg;

  final PsdkBattleEffectStack effects;
  final List<PsdkBattleMoveData> _moves;

  /// Immutable view of setup moves.
  ///
  /// Setup objects may be assembled by editor/runtime adapters later, but the
  /// engine must not share a mutable move list with those callers.
  List<PsdkBattleMoveData> get moves =>
      List<PsdkBattleMoveData>.unmodifiable(_moves);
}

/// Current mutable-in-engine combatant state for the PSDK lane.
///
/// The object itself is immutable from the outside: state changes produce new
/// instances. This keeps the engine locally simple while preventing external
/// mutation from corrupting a turn between calls.
class PsdkBattleCombatant {
  PsdkBattleCombatant({
    required this.id,
    required this.speciesId,
    required this.displayName,
    required this.level,
    required this.maxHp,
    required this.currentHp,
    required this.types,
    required this.stats,
    required List<PsdkBattleMoveData> moves,
    int form = 0,
    this.abilityId,
    this.gender = PsdkBattleGender.unknown,
    this.dislikedFlavor,
    this.loyalty = 255,
    int ivHp = 31,
    int ivAttack = 31,
    int ivDefense = 31,
    int ivSpeed = 31,
    int ivSpecialAttack = 31,
    int ivSpecialDefense = 31,
    this.heldItemId,
    this.consumedItemId,
    this.itemConsumed = false,
    this.sleepTurns = 0,
    this.toxicCounter = 0,
    this.battleTurnCount = 0,
    this.lastBattleTurn,
    this.lastSentTurn,
    this.lastHitByMoveId,
    this.koCount = 0,
    this.switching = false,
    this.hasJustShifted = false,
    this.type3,
    List<String> temporaryTypes = const <String>[],
    this.transformState = const PsdkBattleTransformState(),
    this.majorStatus,
    PsdkBattleStatStages? statStages,
    PsdkBattleMoveHistory? moveHistory,
    PsdkBattleDamageHistory? damageHistory,
    PsdkBattleStatHistory? statHistory,
    double baseWeightKg = 1,
    double? currentWeightKg,
    PsdkBattleEffectStack? effects,
  })  : baseWeightKg = _requirePositiveWeight(baseWeightKg, 'baseWeightKg'),
        currentWeightKg = _requirePositiveWeight(
          currentWeightKg ?? baseWeightKg,
          'currentWeightKg',
        ),
        form = _checkNonNegativeInt(form, 'form'),
        ivHp = _checkIv(ivHp, 'ivHp'),
        ivAttack = _checkIv(ivAttack, 'ivAttack'),
        ivDefense = _checkIv(ivDefense, 'ivDefense'),
        ivSpeed = _checkIv(ivSpeed, 'ivSpeed'),
        ivSpecialAttack = _checkIv(ivSpecialAttack, 'ivSpecialAttack'),
        ivSpecialDefense = _checkIv(ivSpecialDefense, 'ivSpecialDefense'),
        statStages = statStages ?? PsdkBattleStatStages.neutral(),
        moveHistory = moveHistory ?? PsdkBattleMoveHistory.empty(),
        damageHistory = damageHistory ?? const PsdkBattleDamageHistory.empty(),
        statHistory = statHistory ?? const PsdkBattleStatHistory.empty(),
        temporaryTypes = List<String>.unmodifiable(
          temporaryTypes.map((type) => _requireNonBlank(type, 'type')),
        ),
        effects = effects ?? const PsdkBattleEffectStack.empty(),
        _moves = List<PsdkBattleMoveData>.unmodifiable(moves);

  factory PsdkBattleCombatant.fromSetup(PsdkBattleCombatantSetup setup) {
    final hp = setup.currentHp.clamp(0, setup.maxHp).toInt();
    return PsdkBattleCombatant(
      id: setup.id,
      speciesId: setup.speciesId,
      displayName: setup.displayName,
      level: setup.level,
      maxHp: setup.maxHp,
      currentHp: hp,
      types: setup.types,
      stats: setup.stats,
      moves: setup.moves,
      form: setup.form,
      abilityId: setup.abilityId,
      gender: setup.gender,
      dislikedFlavor: setup.dislikedFlavor,
      loyalty: setup.loyalty,
      ivHp: setup.ivHp,
      ivAttack: setup.ivAttack,
      ivDefense: setup.ivDefense,
      ivSpeed: setup.ivSpeed,
      ivSpecialAttack: setup.ivSpecialAttack,
      ivSpecialDefense: setup.ivSpecialDefense,
      heldItemId: setup.heldItemId,
      consumedItemId: setup.consumedItemId,
      itemConsumed: setup.itemConsumed,
      sleepTurns: setup.sleepTurns,
      toxicCounter: setup.toxicCounter,
      battleTurnCount: setup.battleTurnCount,
      lastBattleTurn: setup.lastBattleTurn,
      lastSentTurn: setup.lastSentTurn,
      lastHitByMoveId: setup.lastHitByMoveId,
      koCount: setup.koCount,
      switching: setup.switching,
      hasJustShifted: setup.hasJustShifted,
      type3: setup.type3,
      temporaryTypes: setup.temporaryTypes,
      transformState: setup.transformState,
      // Some Pokemon SDK move formulas are status-sensitive before the first
      // action resolves (Facade, Hex, Venoshock). The setup bridge must carry
      // imported save/runtime status into the immutable battle snapshot instead
      // of forcing tests or adapters to fake a previous status move.
      majorStatus: setup.majorStatus,
      statStages: setup.statStages,
      moveHistory: setup.moveHistory,
      damageHistory: setup.damageHistory,
      statHistory: setup.statHistory,
      baseWeightKg: setup.baseWeightKg,
      currentWeightKg: setup.currentWeightKg,
      effects: setup.effects,
    );
  }

  final String id;
  final String speciesId;
  final String displayName;
  final int level;
  final int maxHp;
  final int currentHp;
  final PsdkBattleTypes types;
  final PsdkBattleStats stats;
  final int form;
  final String? abilityId;
  final PsdkBattleGender gender;
  final String? dislikedFlavor;
  final int loyalty;
  final int ivHp;
  final int ivAttack;
  final int ivDefense;
  final int ivSpeed;
  final int ivSpecialAttack;
  final int ivSpecialDefense;
  final String? heldItemId;
  final String? consumedItemId;
  final bool itemConsumed;
  final int sleepTurns;
  final int toxicCounter;
  final int battleTurnCount;
  final int? lastBattleTurn;
  final int? lastSentTurn;
  final String? lastHitByMoveId;
  final int koCount;
  final bool switching;
  final bool hasJustShifted;
  final String? type3;
  final List<String> temporaryTypes;
  final PsdkBattleTransformState transformState;
  final PsdkBattleStatStages statStages;
  final PsdkBattleMoveHistory moveHistory;
  final PsdkBattleDamageHistory damageHistory;
  final PsdkBattleStatHistory statHistory;
  final double baseWeightKg;
  final double currentWeightKg;
  final PsdkBattleEffectStack effects;
  final List<PsdkBattleMoveData> _moves;
  final PsdkBattleMajorStatus? majorStatus;

  /// Immutable observable move list.
  ///
  /// PP changes replace move DTOs through [replaceMoveAt]; callers still cannot
  /// mutate the stored list behind a state snapshot.
  List<PsdkBattleMoveData> get moves => _moves;

  bool get isFainted => currentHp <= 0;

  PsdkBattleCombatant withAbilityEffect(PsdkBattleSlotRef owner) {
    return copyWith(
      effects: AbilityEffectRegistry().hydrateEffects(
        effects: effects,
        abilityId: abilityId,
        owner: owner,
      ),
    );
  }

  PsdkBattleCombatant withItemEffect(PsdkBattleSlotRef owner) {
    return copyWith(
      effects: ItemEffectRegistry().hydrateEffects(
        effects: effects,
        itemId: heldItemId,
        owner: owner,
        itemConsumed: itemConsumed,
      ),
    );
  }

  bool hasType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return types.primary.toLowerCase() == normalized ||
        types.secondary?.toLowerCase() == normalized ||
        type3?.toLowerCase() == normalized ||
        temporaryTypes.any((value) => value.toLowerCase() == normalized);
  }

  int effectiveStat(
    String stat, {
    bool ignorePositiveStage = false,
    bool ignoreNegativeStage = false,
    bool ignoreAllStages = false,
  }) {
    // PSDK custom stat-source moves override only the stat chosen by the
    // formula; the regular stage table still belongs to the battler state.
    // Keeping this helper here prevents each move family from duplicating the
    // PSDK stage aliases and multiplier math.
    return statStages.effectiveValue(
      stat: stat,
      baseValue: stats.valueOf(stat),
      ignorePositiveStage: ignorePositiveStage,
      ignoreNegativeStage: ignoreNegativeStage,
      ignoreAllStages: ignoreAllStages,
    );
  }

  PsdkBattleCombatant copyWith({
    String? speciesId,
    String? displayName,
    PsdkBattleTypes? types,
    PsdkBattleStats? stats,
    int? currentHp,
    int? form,
    Object? abilityId = _unchanged,
    PsdkBattleGender? gender,
    Object? dislikedFlavor = _unchanged,
    int? loyalty,
    int? ivHp,
    int? ivAttack,
    int? ivDefense,
    int? ivSpeed,
    int? ivSpecialAttack,
    int? ivSpecialDefense,
    Object? heldItemId = _unchanged,
    Object? consumedItemId = _unchanged,
    bool? itemConsumed,
    int? sleepTurns,
    int? toxicCounter,
    int? battleTurnCount,
    Object? lastBattleTurn = _unchanged,
    Object? lastSentTurn = _unchanged,
    Object? lastHitByMoveId = _unchanged,
    int? koCount,
    bool? switching,
    bool? hasJustShifted,
    Object? type3 = _unchanged,
    List<String>? temporaryTypes,
    PsdkBattleTransformState? transformState,
    PsdkBattleMajorStatus? majorStatus,
    bool clearMajorStatus = false,
    PsdkBattleStatStages? statStages,
    PsdkBattleMoveHistory? moveHistory,
    PsdkBattleDamageHistory? damageHistory,
    PsdkBattleStatHistory? statHistory,
    double? baseWeightKg,
    double? currentWeightKg,
    PsdkBattleEffectStack? effects,
    List<PsdkBattleMoveData>? moves,
  }) {
    if (clearMajorStatus && majorStatus != null) {
      throw ArgumentError.value(
        majorStatus,
        'majorStatus',
        'cannot be set while clearMajorStatus is true',
      );
    }
    return PsdkBattleCombatant(
      id: id,
      speciesId: speciesId ?? this.speciesId,
      displayName: displayName ?? this.displayName,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp ?? this.currentHp,
      types: types ?? this.types,
      stats: stats ?? this.stats,
      moves: moves ?? this.moves,
      form: form ?? this.form,
      abilityId: identical(abilityId, _unchanged)
          ? this.abilityId
          : abilityId as String?,
      gender: gender ?? this.gender,
      dislikedFlavor: identical(dislikedFlavor, _unchanged)
          ? this.dislikedFlavor
          : dislikedFlavor as String?,
      loyalty: loyalty ?? this.loyalty,
      ivHp: ivHp ?? this.ivHp,
      ivAttack: ivAttack ?? this.ivAttack,
      ivDefense: ivDefense ?? this.ivDefense,
      ivSpeed: ivSpeed ?? this.ivSpeed,
      ivSpecialAttack: ivSpecialAttack ?? this.ivSpecialAttack,
      ivSpecialDefense: ivSpecialDefense ?? this.ivSpecialDefense,
      heldItemId: identical(heldItemId, _unchanged)
          ? this.heldItemId
          : heldItemId as String?,
      consumedItemId: identical(consumedItemId, _unchanged)
          ? this.consumedItemId
          : consumedItemId as String?,
      itemConsumed: itemConsumed ?? this.itemConsumed,
      sleepTurns: sleepTurns ?? this.sleepTurns,
      toxicCounter: toxicCounter ?? this.toxicCounter,
      battleTurnCount: battleTurnCount ?? this.battleTurnCount,
      lastBattleTurn: identical(lastBattleTurn, _unchanged)
          ? this.lastBattleTurn
          : lastBattleTurn as int?,
      lastSentTurn: identical(lastSentTurn, _unchanged)
          ? this.lastSentTurn
          : lastSentTurn as int?,
      lastHitByMoveId: identical(lastHitByMoveId, _unchanged)
          ? this.lastHitByMoveId
          : lastHitByMoveId as String?,
      koCount: koCount ?? this.koCount,
      switching: switching ?? this.switching,
      hasJustShifted: hasJustShifted ?? this.hasJustShifted,
      type3: identical(type3, _unchanged) ? this.type3 : type3 as String?,
      temporaryTypes: temporaryTypes ?? this.temporaryTypes,
      transformState: transformState ?? this.transformState,
      // Nullable copyWith parameters cannot distinguish "leave unchanged" from
      // "clear the value". Keep the common setter terse, and expose an explicit
      // clear flag for future cure/status-removal effects.
      majorStatus: clearMajorStatus ? null : (majorStatus ?? this.majorStatus),
      statStages: statStages ?? this.statStages,
      moveHistory: moveHistory ?? this.moveHistory,
      damageHistory: damageHistory ?? this.damageHistory,
      statHistory: statHistory ?? this.statHistory,
      baseWeightKg: baseWeightKg ?? this.baseWeightKg,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      effects: effects ?? this.effects,
    );
  }

  PsdkBattleCombatant replaceMoveAt(int index, PsdkBattleMoveData move) {
    if (index < 0 || index >= _moves.length) {
      throw RangeError.range(index, 0, _moves.length - 1, 'index');
    }
    final nextMoves = <PsdkBattleMoveData>[..._moves];
    nextMoves[index] = move;
    return copyWith(moves: nextMoves);
  }

  PsdkBattleCombatant recordMoveAttempt({
    required String moveId,
    required int turn,
    required List<PsdkBattleSlotRef> targets,
    int attackOrder = 0,
  }) {
    return copyWith(
      moveHistory: moveHistory.recordAttempt(
        moveId: moveId,
        turn: turn,
        targets: targets,
        attackOrder: attackOrder,
      ),
    );
  }

  PsdkBattleCombatant recordMoveSuccess({
    required String moveId,
    required int turn,
    required List<PsdkBattleSlotRef> targets,
    int attackOrder = 0,
  }) {
    return copyWith(
      moveHistory: moveHistory.recordSuccess(
        moveId: moveId,
        turn: turn,
        targets: targets,
        attackOrder: attackOrder,
      ),
    );
  }

  PsdkBattleCombatant recordDamage({
    required int turn,
    required PsdkBattleSlotRef source,
    required String moveId,
    required int damage,
    required int remainingHp,
    PsdkBattleMoveCategory? moveCategory,
  }) {
    return copyWith(
      lastHitByMoveId: moveId,
      damageHistory: damageHistory.record(
        PsdkBattleDamageHistoryEntry(
          turn: turn,
          source: source,
          moveId: moveId,
          damage: damage,
          remainingHp: remainingHp,
          moveCategory: moveCategory,
        ),
      ),
    );
  }

  PsdkBattleCombatant recordStatChange({
    required int turn,
    required String stat,
    required int delta,
    required int currentStage,
  }) {
    return copyWith(
      statHistory: statHistory.record(
        PsdkBattleStatHistoryEntry(
          turn: turn,
          stat: stat,
          delta: delta,
          currentStage: currentStage,
        ),
      ),
    );
  }
}

String _requireEffectId(String value) {
  return _requireNonBlank(value, 'effectId');
}

double _requirePositiveWeight(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'must be a finite positive weight');
  }
  return value;
}

int _checkNonNegativeInt(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be >= 0');
  }
  return value;
}

int _checkIv(int value, String name) {
  if (value < 0 || value > 31) {
    throw RangeError.range(value, 0, 31, name);
  }
  return value;
}

String _normalizeStat(String stat) {
  final token = stat.trim();
  if (token.isEmpty) {
    throw ArgumentError.value(stat, 'stat', 'must not be blank');
  }
  final normalized = token.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  return switch (normalized) {
    'atk' || 'attack' => 'attack',
    'def' || 'dfe' || 'defense' => 'defense',
    'ats' || 'spa' || 'spatk' || 'specialattack' => 'specialAttack',
    'dfs' || 'spdef' || 'specialdefense' => 'specialDefense',
    // Pokemon SDK's battler scripts use `spd` for speed and `dfs` for special
    // defense. The PSDK lane follows that vocabulary, while still accepting the
    // clearer `speed`/`spe` aliases from editor/runtime adapters.
    'spd' || 'spe' || 'speed' => 'speed',
    'acc' || 'accuracy' => 'accuracy',
    'eva' || 'evasion' => 'evasion',
    _ => token,
  };
}

int _applyRegularStageMultiplier(int baseValue, int stage) {
  final base = baseValue < 1 ? 1 : baseValue;
  final value =
      stage >= 0 ? (base * (2 + stage)) ~/ 2 : (base * 2) ~/ (2 - stage);
  return value < 1 ? 1 : value;
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
