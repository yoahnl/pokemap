import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_slot.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/move/snatch_effect.dart';
import 'battle_move_data.dart';

/// Rewrites the effective user/targets after accuracy and before immunity.
///
/// Pokemon SDK performs this step in `proceed_battlers_remap`, mostly for
/// effects such as Snatch/Magic Coat that steal or reflect a move after it was
/// selected. The default implementation is intentionally neutral: FIGHT-11
/// establishes the clean-architecture seam without pretending those effects
/// have all been ported yet.
abstract interface class BattleMoveRemapper {
  BattleMoveRemapResult remap(BattleMoveRemapContext context);
}

final class BattleMoveRemapContext {
  BattleMoveRemapContext({
    required this.state,
    required this.turn,
    required this.user,
    required List<BattlePositionRef> targets,
    required this.move,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final PsdkBattleState state;
  final int turn;
  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
  final BattleMoveDefinition move;
}

final class BattleMoveRemapResult {
  BattleMoveRemapResult({
    required this.state,
    required this.user,
    required List<BattlePositionRef> targets,
    List<PsdkBattleEvent> events = const <PsdkBattleEvent>[],
  })  : targets = List<BattlePositionRef>.unmodifiable(targets),
        events = List<PsdkBattleEvent>.unmodifiable(events);

  final PsdkBattleState state;
  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
  final List<PsdkBattleEvent> events;
}

final class NoopBattleMoveRemapper implements BattleMoveRemapper {
  const NoopBattleMoveRemapper();

  @override
  BattleMoveRemapResult remap(BattleMoveRemapContext context) {
    return BattleMoveRemapResult(
      state: context.state,
      user: context.user,
      targets: context.targets,
    );
  }
}

final class PsdkEffectBattleMoveRemapper implements BattleMoveRemapper {
  const PsdkEffectBattleMoveRemapper();

  @override
  BattleMoveRemapResult remap(BattleMoveRemapContext context) {
    final magicCoat = _remapMagicCoat(context);
    if (_changed(magicCoat, context)) {
      return magicCoat;
    }
    return _remapSnatch(context);
  }

  BattleMoveRemapResult _remapMagicCoat(BattleMoveRemapContext context) {
    if (context.move.category != PsdkBattleMoveCategory.status ||
        !context.move.magicCoatAffected) {
      return _unchanged(context);
    }

    var reflected = false;
    final targets = <BattlePositionRef>[];
    for (final target in context.targets) {
      final slot = _psdkSlot(target);
      final battler = context.state.combatants[slot];
      if (battler != null && battler.effects.contains('magic_coat')) {
        targets.add(context.user);
        reflected = true;
      } else {
        targets.add(target);
      }
    }

    if (!reflected) {
      return _unchanged(context);
    }
    return BattleMoveRemapResult(
      state: context.state,
      user: context.user,
      targets: targets,
    );
  }

  BattleMoveRemapResult _remapSnatch(BattleMoveRemapContext context) {
    if (!context.move.snatchable) {
      return _unchanged(context);
    }

    final snatcher = _fastestSnatcher(context);
    if (snatcher == null) {
      return _unchanged(context);
    }

    final originalUser = _psdkSlot(context.user);
    final snatchedUser = context.state.battlerAt(originalUser);
    final snatcherBattler = context.state.battlerAt(snatcher);
    final nextState = context.state
        .replaceBattler(
          snatcher,
          snatcherBattler.copyWith(
            effects: snatcherBattler.effects.remove('snatch'),
          ),
        )
        .replaceBattler(
          originalUser,
          snatchedUser.copyWith(
            effects: snatchedUser.effects.addEffect(
              SnatchedEffect(scope: BattlerBattleEffectScope(originalUser)),
            ),
          ),
        );

    return BattleMoveRemapResult(
      state: nextState,
      user: _battlePosition(snatcher),
      targets: <BattlePositionRef>[_battlePosition(snatcher)],
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.removed(
          turn: context.turn,
          target: snatcher,
          effectId: 'snatch',
          remainingTurns: 0,
          reason: 'snatch_consumed',
        ),
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: originalUser,
          effectId: 'snatched',
          remainingTurns: 0,
          reason: 'snatch_redirected',
        ),
      ],
    );
  }

  PsdkBattleSlotRef? _fastestSnatcher(BattleMoveRemapContext context) {
    PsdkBattleSlotRef? selected;
    var selectedSpeed = -1;
    for (final slot in context.state.aliveSlots()) {
      if (slot == _psdkSlot(context.user)) {
        continue;
      }
      final battler = context.state.battlerAt(slot);
      if (!battler.effects.contains('snatch')) {
        continue;
      }
      final speed = battler.effectiveStat('speed');
      if (selected == null || speed > selectedSpeed) {
        selected = slot;
        selectedSpeed = speed;
      }
    }
    return selected;
  }

  BattleMoveRemapResult _unchanged(BattleMoveRemapContext context) {
    return BattleMoveRemapResult(
      state: context.state,
      user: context.user,
      targets: context.targets,
    );
  }

  bool _changed(
    BattleMoveRemapResult result,
    BattleMoveRemapContext context,
  ) {
    return result.state != context.state ||
        result.user != context.user ||
        result.targets.length != context.targets.length ||
        result.events.isNotEmpty ||
        !_sameTargets(result.targets, context.targets);
  }
}

bool _sameTargets(List<BattlePositionRef> left, List<BattlePositionRef> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

PsdkBattleSlotRef _psdkSlot(BattlePositionRef slot) {
  return PsdkBattleSlotRef(bank: slot.bank, position: slot.position);
}

BattlePositionRef _battlePosition(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}
