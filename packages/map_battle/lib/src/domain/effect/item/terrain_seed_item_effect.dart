import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class TerrainSeedItemEffect extends BattleItemEffect {
  const TerrainSeedItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.terrain,
    required this.stat,
  }) : super(itemId: itemId, scope: scope);

  const TerrainSeedItemEffect.defense({
    required String itemId,
    required BattleEffectScope scope,
    required PsdkBattleTerrainId terrain,
  }) : this(
          itemId: itemId,
          scope: scope,
          terrain: terrain,
          stat: 'defense',
        );

  const TerrainSeedItemEffect.specialDefense({
    required String itemId,
    required BattleEffectScope scope,
    required PsdkBattleTerrainId terrain,
  }) : this(
          itemId: itemId,
          scope: scope,
          terrain: terrain,
          stat: 'specialDefense',
        );

  final PsdkBattleTerrainId terrain;
  final String stat;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.replacement != owner ||
        context.state.field.terrain?.id != terrain) {
      return null;
    }
    return _use(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    )?.toSwitchEventResult();
  }

  @override
  BattleEffectFieldChangeResult? onPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    final owner = this.owner;
    if (owner == null || context.owner != owner || context.terrain != terrain) {
      return null;
    }
    return _use(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    )?.toFieldChangeResult();
  }

  BattleEffectStatChangePostResult? _use({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (!_canUse(battler)) {
      return null;
    }

    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
      stat: stat,
      stages: 1,
    );
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: changed.state,
        rng: changed.rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }
    return BattleEffectStatChangePostResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        ...changed.events,
        ...consumed.events,
      ],
      applied: changed.applied || consumed.applied,
    );
  }

  bool _canUse(PsdkBattleCombatant battler) {
    return !battler.isFainted &&
        battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed;
  }
}

extension on BattleEffectStatChangePostResult {
  BattleEffectSwitchEventResult toSwitchEventResult() {
    return BattleEffectSwitchEventResult(
      state: state,
      rng: rng,
      events: events,
      applied: applied,
    );
  }

  BattleEffectFieldChangeResult toFieldChangeResult() {
    return BattleEffectFieldChangeResult(
      state: state,
      rng: rng,
      events: events,
      applied: applied,
    );
  }
}
