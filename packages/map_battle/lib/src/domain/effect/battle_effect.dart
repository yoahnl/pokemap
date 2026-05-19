import '../move/battle_move_prevention.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_effect_hooks.dart';
import 'battle_effect_scope.dart';

/// Base class for PSDK-lane effects.
///
/// The default implementation is intentionally inert. That lets the engine
/// carry effects such as `gravity` before their dedicated FIGHT-07/FIGHT-09
/// behavior exists, while still making any active hook opt-in and testable.
abstract class BattleEffect {
  const BattleEffect({
    required this.id,
    required this.scope,
    this.remainingTurns,
  });

  final String id;
  final BattleEffectScope scope;

  /// `0` means "clear at the end of the current turn".
  ///
  /// PSDK Protect initializes with one counter turn. The Dart lane models the
  /// same one-turn lifetime as a turn-scoped effect because cleanup happens
  /// after all actions in the turn have observed it.
  final int? remainingTurns;

  bool get isTurnScoped => remainingTurns == 0;

  /// PSDK marker used by effects such as Focus Punch while a move is charging.
  bool get preparingAttack => false;

  BattleEffect copyWithRemainingTurns(int remainingTurns);

  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    return null;
  }

  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    return null;
  }

  BattleMoveSelectionPreventionResult? onMoveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    return null;
  }

  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    return null;
  }

  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    return null;
  }

  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    return null;
  }

  BattleEffectItemChangeResult? onPostItemChange(
    BattleEffectItemChangeContext context,
  ) {
    return null;
  }

  BattleEffectLifecycleResult? onLifecycle(
    BattleEffectLifecycleContext context,
  ) {
    return null;
  }

  BattleEffect? onBatonPassTransfer(BattleEffectBatonPassContext context) {
    return null;
  }

  bool onSwitchPassthrough(BattleEffectSwitchPreventionContext context) {
    return false;
  }

  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    return null;
  }

  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    return null;
  }

  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    return null;
  }

  String? onStatIncreasePrevention(
    BattleEffectStatChangePreventionContext context,
  ) {
    return null;
  }

  String? onStatDecreasePrevention(
    BattleEffectStatChangePreventionContext context,
  ) {
    return null;
  }

  int? onStatChange(BattleEffectStatChangeContext context) {
    return null;
  }

  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    return null;
  }

  String? onStatusPrevention(
    BattleEffectStatusPreventionContext context,
  ) {
    return null;
  }

  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    return null;
  }

  String? onWeatherPrevention(
    BattleEffectWeatherPreventionContext context,
  ) {
    return null;
  }

  BattleEffectFieldChangeResult? onPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    return null;
  }

  String? onTerrainPrevention(
    BattleEffectTerrainPreventionContext context,
  ) {
    return null;
  }

  BattleEffectFieldChangeResult? onPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    return null;
  }
}

/// Passive effect used when legacy/setup code only knows an effect id.
///
/// It preserves state and future dependency checks without inventing behavior.
final class GenericBattleEffect extends BattleEffect {
  const GenericBattleEffect({
    required String id,
    BattleEffectScope scope = const LocalBattleEffectScope(),
    int? remainingTurns,
  }) : super(id: id, scope: scope, remainingTurns: remainingTurns);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GenericBattleEffect(
      id: id,
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }

    final nextRemainingTurns = turns - 1;
    final nextEffects = nextRemainingTurns <= 0
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(nextRemainingTurns));
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        if (nextRemainingTurns <= 0)
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: 0,
            reason: 'expired',
          )
        else
          PsdkBattleEffectEvent.ticked(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: nextRemainingTurns,
            reason: 'duration_tick',
          ),
      ],
    );
  }
}
