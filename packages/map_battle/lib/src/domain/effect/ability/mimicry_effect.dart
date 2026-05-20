import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

const _mimicrySnapshotEffectId = 'mimicry:original_typing';

final class MimicryEffect extends BattleAbilityEffect {
  const MimicryEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'mimicry', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MimicryEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != context.replacement) {
      return null;
    }
    final type = _typeForTerrain(context.state.field.terrain?.id);
    if (type == null) {
      return null;
    }
    final change = _applyTerrainType(
      state: context.state,
      owner: context.owner,
      type: type,
      turn: context.turn,
    );
    if (!change.applied) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: change.state,
      rng: context.rng,
      events: change.events,
    );
  }

  @override
  BattleEffectFieldChangeResult? onPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    final type = _typeForTerrain(context.terrain);
    final change = type == null
        ? _restoreOriginalTyping(
            state: context.state,
            owner: context.owner,
            turn: context.turn,
            reason: 'terrain_cleared',
          )
        : _applyTerrainType(
            state: context.state,
            owner: context.owner,
            type: type,
            turn: context.turn,
          );
    if (!change.applied) {
      return null;
    }
    return BattleEffectFieldChangeResult(
      state: change.state,
      rng: context.rng,
      events: change.events,
    );
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    final change = _restoreOriginalTyping(
      state: context.state,
      owner: context.owner,
      turn: context.turn,
      reason: 'switch_out',
    );
    if (!change.applied) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: change.state,
      rng: context.rng,
      events: change.events,
    );
  }
}

final class _MimicryOriginalTypingEffect extends BattleEffect {
  const _MimicryOriginalTypingEffect({
    required BattleEffectScope scope,
    required this.types,
    required this.type3,
    required this.temporaryTypes,
  }) : super(id: _mimicrySnapshotEffectId, scope: scope);

  final PsdkBattleTypes types;
  final String? type3;
  final List<String> temporaryTypes;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return _MimicryOriginalTypingEffect(
      scope: scope,
      types: types,
      type3: type3,
      temporaryTypes: temporaryTypes,
    );
  }
}

typedef _MimicryTypingChange = ({
  bool applied,
  PsdkBattleState state,
  List<PsdkBattleEvent> events,
});

_MimicryTypingChange _applyTerrainType({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required String type,
  required int turn,
}) {
  final battler = state.battlerAt(owner);
  final snapshot = _snapshotFor(battler);
  if (snapshot == null &&
      battler.types.primary == type &&
      battler.types.secondary == null &&
      battler.type3 == null &&
      battler.temporaryTypes.isEmpty) {
    return (applied: false, state: state, events: const <PsdkBattleEvent>[]);
  }
  if (snapshot != null &&
      battler.types.primary == type &&
      battler.types.secondary == null &&
      battler.type3 == null &&
      battler.temporaryTypes.isEmpty) {
    return (applied: false, state: state, events: const <PsdkBattleEvent>[]);
  }

  final nextEffects = snapshot == null
      ? battler.effects.addEffect(
          _MimicryOriginalTypingEffect(
            scope: BattlerBattleEffectScope(owner),
            types: battler.types,
            type3: battler.type3,
            temporaryTypes: battler.temporaryTypes,
          ),
        )
      : battler.effects;
  final nextBattler = battler.copyWith(
    types: PsdkBattleTypes(primary: type),
    type3: null,
    temporaryTypes: const <String>[],
    effects: nextEffects,
  );
  return (
    applied: true,
    state: state.replaceBattler(owner, nextBattler),
    events: <PsdkBattleEvent>[
      PsdkBattleEffectEvent.added(
        turn: turn,
        target: owner,
        effectId: 'mimicry:type:$type',
        reason: 'ability:mimicry',
      ),
    ],
  );
}

_MimicryTypingChange _restoreOriginalTyping({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required int turn,
  required String reason,
}) {
  final battler = state.battlerAt(owner);
  final snapshot = _snapshotFor(battler);
  if (snapshot == null) {
    return (applied: false, state: state, events: const <PsdkBattleEvent>[]);
  }
  final nextBattler = battler.copyWith(
    types: snapshot.types,
    type3: snapshot.type3,
    temporaryTypes: snapshot.temporaryTypes,
    effects: battler.effects.remove(_mimicrySnapshotEffectId),
  );
  return (
    applied: true,
    state: state.replaceBattler(owner, nextBattler),
    events: <PsdkBattleEvent>[
      PsdkBattleEffectEvent.removed(
        turn: turn,
        target: owner,
        effectId: 'mimicry',
        reason: 'ability:mimicry:$reason',
      ),
    ],
  );
}

_MimicryOriginalTypingEffect? _snapshotFor(PsdkBattleCombatant battler) {
  for (final effect in battler.effects.effects) {
    if (effect is _MimicryOriginalTypingEffect) {
      return effect;
    }
  }
  return null;
}

String? _typeForTerrain(PsdkBattleTerrainId? terrain) {
  return switch (terrain) {
    PsdkBattleTerrainId.electricTerrain => 'electric',
    PsdkBattleTerrainId.grassyTerrain => 'grass',
    PsdkBattleTerrainId.mistyTerrain => 'fairy',
    PsdkBattleTerrainId.psychicTerrain => 'psychic',
    null => null,
  };
}
