import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/bestow_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _ItemDependentMoveKind {
  belch,
  bestow,
  fling,
  knockOff,
  naturalGift,
  pluck,
  recycle,
  technoBlast,
  thief,
}

/// Ports local PSDK move families whose rules depend on held/consumed items.
///
/// This slice deliberately uses a small battle-local item table instead of a
/// full item database. Richer PSDK `can_lose_item?`, berry effects and trainer
/// battle persistence rules remain separate parity work.
final class ItemDependentMoveBehavior implements BattleMoveBehavior {
  const ItemDependentMoveBehavior.belch()
      : battleEngineMethod = 's_belch',
        _kind = _ItemDependentMoveKind.belch;

  const ItemDependentMoveBehavior.bestow()
      : battleEngineMethod = 's_bestow',
        _kind = _ItemDependentMoveKind.bestow;

  const ItemDependentMoveBehavior.fling()
      : battleEngineMethod = 's_fling',
        _kind = _ItemDependentMoveKind.fling;

  const ItemDependentMoveBehavior.knockOff()
      : battleEngineMethod = 's_knock_off',
        _kind = _ItemDependentMoveKind.knockOff;

  const ItemDependentMoveBehavior.naturalGift()
      : battleEngineMethod = 's_natural_gift',
        _kind = _ItemDependentMoveKind.naturalGift;

  const ItemDependentMoveBehavior.pluck()
      : battleEngineMethod = 's_pluck',
        _kind = _ItemDependentMoveKind.pluck;

  const ItemDependentMoveBehavior.recycle()
      : battleEngineMethod = 's_recycle',
        _kind = _ItemDependentMoveKind.recycle;

  const ItemDependentMoveBehavior.technoBlast()
      : battleEngineMethod = 's_techno_blast',
        _kind = _ItemDependentMoveKind.technoBlast;

  const ItemDependentMoveBehavior.thief()
      : battleEngineMethod = 's_thief',
        _kind = _ItemDependentMoveKind.thief;

  @override
  final String battleEngineMethod;
  final _ItemDependentMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    return switch (_kind) {
      _ItemDependentMoveKind.bestow => _resolveBestow(context),
      _ItemDependentMoveKind.recycle => _resolveRecycle(context),
      _ => _resolveDamaging(context),
    };
  }

  BattleMoveBehaviorResolution _resolveBestow(
      BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    if (!_canGiveItem(user, target)) {
      return _failed(
        state: prepared.state,
        rng: prepared.rng,
        events: prepared.events,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
      );
    }

    final itemId = user.heldItemId!;
    final given = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: targetSlot,
      heldItemId: itemId,
      move: context.move,
      launcher: context.user,
    );
    final removed = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: given.state,
        rng: given.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.user,
      heldItemId: null,
      move: context.move,
      launcher: context.user,
    );
    final marked = removed.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          BestowEffect(
            scope: BattlerBattleEffectScope(context.user),
            giver: context.user,
            receiver: targetSlot,
            itemId: itemId,
          ),
        ),
      ),
    );
    return BattleMoveBehaviorResolution(
      state: marked,
      rng: removed.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...given.events,
        ...removed.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveRecycle(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final target = prepared.state.battlerAt(targetSlot);
    if (!target.itemConsumed || target.consumedItemId == null) {
      return _failed(
        state: prepared.state,
        rng: prepared.rng,
        events: prepared.events,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
      );
    }

    return BattleMoveBehaviorResolution(
      state: prepared.state.updateBattler(
        targetSlot,
        (battler) => battler
            .copyWith(
              heldItemId: battler.consumedItemId,
              consumedItemId: null,
              itemConsumed: false,
            )
            .withItemEffect(targetSlot),
      ),
      rng: prepared.rng,
      events: prepared.events,
    );
  }

  BattleMoveBehaviorResolution _resolveDamaging(
    BattleMoveBehaviorContext context,
  ) {
    final userBeforePrepare = context.state.battlerAt(context.user);
    final gateReason = _gateFailureReason(userBeforePrepare);
    if (gateReason != null) {
      return _failed(
        state: context.state,
        rng: context.rng,
        events: const <PsdkBattleEvent>[],
        user: context.user,
        target: context.target,
        moveId: context.move.id,
        reason: gateReason,
      );
    }

    final move = _effectiveMove(context.move, userBeforePrepare);
    final prepared = prepareBattleMove(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: move,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final power = _effectivePower(move.power, user, target);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: move,
        rng: prepared.rng,
        field: prepared.state.field,
        state: prepared.state,
        userSlot: context.user,
        targetSlot: targetSlot,
        overrides: BattleMoveDamageOverrides(power: power),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyMoveTargetDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
      move: move,
      targetCount: prepared.psdkTargets.length,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: move,
      turn: context.turn,
    );
    final itemEffect = _applySuccessfulItemEffect(
      state: secondary.state,
      rng: secondary.rng,
      turn: context.turn,
      userSlot: context.user,
      targetSlot: targetSlot,
      moveId: context.move.id,
    );

    return BattleMoveBehaviorResolution(
      state: itemEffect.state,
      rng: itemEffect.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...applied.events,
        ...secondary.events,
        ...itemEffect.events,
      ],
    );
  }

  String? _gateFailureReason(PsdkBattleCombatant user) {
    final unusable = BattleMoveFailureReason.unusableByUser.jsonName;
    return switch (_kind) {
      _ItemDependentMoveKind.belch =>
        _isBerry(user.consumedItemId) && user.itemConsumed ? null : unusable,
      _ItemDependentMoveKind.fling =>
        _flingPower(user.heldItemId) > 0 ? null : unusable,
      _ItemDependentMoveKind.naturalGift =>
        _berryData(user.heldItemId) == null ? unusable : null,
      _ItemDependentMoveKind.technoBlast =>
        user.speciesId == 'genesect' ? null : unusable,
      _ => null,
    };
  }

  BattleMoveDefinition _effectiveMove(
    BattleMoveDefinition move,
    PsdkBattleCombatant user,
  ) {
    return switch (_kind) {
      _ItemDependentMoveKind.naturalGift => _copyMove(
          move,
          type: _berryData(user.heldItemId)?.type ?? move.type,
        ),
      _ItemDependentMoveKind.technoBlast => _copyMove(
          move,
          type: _driveType(user.heldItemId) ?? move.type,
        ),
      _ => move,
    };
  }

  int _effectivePower(
    int movePower,
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    return switch (_kind) {
      _ItemDependentMoveKind.fling => _flingPower(user.heldItemId),
      _ItemDependentMoveKind.knockOff =>
        _canLoseItem(target) ? (movePower * 1.5).floor() : movePower,
      _ItemDependentMoveKind.naturalGift =>
        _berryData(user.heldItemId)?.power ?? movePower,
      _ => movePower,
    };
  }

  _ItemDependentMoveEffectResult _applySuccessfulItemEffect({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
  }) {
    return switch (_kind) {
      _ItemDependentMoveKind.fling => _applyFlingEffect(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
        ),
      _ItemDependentMoveKind.knockOff =>
        _canLoseItem(state.battlerAt(targetSlot))
            ? _itemEffectResult(_removeHeldItem(state, targetSlot), rng)
            : _itemEffectResult(state, rng),
      _ItemDependentMoveKind.naturalGift =>
        _itemEffectResult(_consumeHeldItem(state, userSlot), rng),
      _ItemDependentMoveKind.pluck => _applyPluckEffect(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
        ),
      _ItemDependentMoveKind.thief =>
        _itemEffectResult(_stealHeldItem(state, userSlot, targetSlot), rng),
      _ => _itemEffectResult(state, rng),
    };
  }
}

_ItemDependentMoveEffectResult _applyFlingEffect({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef userSlot,
  required PsdkBattleSlotRef targetSlot,
  required String moveId,
}) {
  final itemId = state.battlerAt(userSlot).heldItemId;
  final status = _flingStatus(itemId);
  var nextState = state;
  var nextRng = rng;
  final events = <PsdkBattleEvent>[];
  if (status != null) {
    final statusResult = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: nextState,
        rng: nextRng,
        turn: turn,
        user: userSlot,
      ),
      target: targetSlot,
      moveId: moveId,
      status: status,
    );
    nextState = statusResult.state;
    nextRng = statusResult.rng;
    events.addAll(statusResult.events);
  }
  return _ItemDependentMoveEffectResult(
    state: _consumeHeldItem(nextState, userSlot),
    rng: nextRng,
    events: events,
  );
}

_ItemDependentMoveEffectResult _applyPluckEffect({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef userSlot,
  required PsdkBattleSlotRef targetSlot,
  required String moveId,
}) {
  final berryId = state.battlerAt(targetSlot).heldItemId;
  if (!_isBerry(berryId)) {
    return _itemEffectResult(state, rng);
  }

  var nextState = state;
  var nextRng = rng;
  final events = <PsdkBattleEvent>[];
  final healAmount = _pluckBerryHealAmount(
    berryId,
    nextState.battlerAt(userSlot).maxHp,
  );
  if (healAmount > 0) {
    final healed = applyDirectHeal(
      state: nextState,
      rng: nextRng,
      turn: turn,
      user: userSlot,
      target: userSlot,
      moveId: moveId,
      amount: healAmount,
    );
    nextState = healed.state;
    nextRng = healed.rng;
    if (healed.event != null) {
      events.add(healed.event!);
    }
  }

  return _ItemDependentMoveEffectResult(
    state: _consumeHeldItem(nextState, targetSlot),
    rng: nextRng,
    events: events,
  );
}

_ItemDependentMoveEffectResult _itemEffectResult(
  PsdkBattleState state,
  BattleRngStreams rng,
) {
  return _ItemDependentMoveEffectResult(
    state: state,
    rng: rng,
    events: const <PsdkBattleEvent>[],
  );
}

final class _ItemDependentMoveEffectResult {
  const _ItemDependentMoveEffectResult({
    required this.state,
    required this.rng,
    required this.events,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}

BattleMoveBehaviorResolution _failed({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required List<PsdkBattleEvent> events,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
  String? reason,
}) {
  return BattleMoveBehaviorResolution(
    state: state,
    rng: rng,
    events: <PsdkBattleEvent>[
      ...events,
      PsdkBattleMoveFailedEvent(
        user: user,
        target: target,
        moveId: moveId,
        reason: reason ?? BattleMoveFailureReason.unusableByUser.jsonName,
      ),
    ],
    successful: false,
  );
}

bool _canGiveItem(PsdkBattleCombatant user, PsdkBattleCombatant target) {
  return _canLoseItem(user) &&
      target.heldItemId == null &&
      !_speciesHasProtectedItems(target.speciesId);
}

bool _canLoseItem(PsdkBattleCombatant battler) {
  final itemId = _normalizedNullableId(battler.heldItemId);
  return itemId != null &&
      !battler.isFainted &&
      !_protectedItems.contains(itemId) &&
      !(_protectedPokemonItems[_normalizedId(battler.speciesId)]
              ?.contains(itemId) ??
          false);
}

PsdkBattleState _setHeldItem(
  PsdkBattleState state, {
  required PsdkBattleSlotRef slot,
  required String? heldItemId,
}) {
  return state.updateBattler(
    slot,
    (battler) => battler
        .copyWith(
          heldItemId: heldItemId,
          consumedItemId: null,
          itemConsumed: false,
        )
        .withItemEffect(slot),
  );
}

PsdkBattleState _removeHeldItem(PsdkBattleState state, PsdkBattleSlotRef slot) {
  return _setHeldItem(state, slot: slot, heldItemId: null);
}

PsdkBattleState _consumeHeldItem(
    PsdkBattleState state, PsdkBattleSlotRef slot) {
  final item = state.battlerAt(slot).heldItemId;
  if (item == null) {
    return state;
  }
  return state.updateBattler(
    slot,
    (battler) => battler
        .copyWith(
          heldItemId: null,
          consumedItemId: item,
          itemConsumed: true,
        )
        .withItemEffect(slot),
  );
}

PsdkBattleState _stealHeldItem(
  PsdkBattleState state,
  PsdkBattleSlotRef userSlot,
  PsdkBattleSlotRef targetSlot,
) {
  final user = state.battlerAt(userSlot);
  final target = state.battlerAt(targetSlot);
  if (user.heldItemId != null || target.heldItemId == null) {
    return state;
  }
  final item = target.heldItemId;
  return _setHeldItem(
    _setHeldItem(state, slot: targetSlot, heldItemId: null),
    slot: userSlot,
    heldItemId: item,
  );
}

BattleMoveDefinition _copyMove(
  BattleMoveDefinition move, {
  required String type,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: type,
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
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}

String? _driveType(String? itemId) {
  return switch (itemId) {
    'douse_drive' => 'water',
    'shock_drive' => 'electric',
    'burn_drive' => 'fire',
    'chill_drive' => 'ice',
    _ => null,
  };
}

bool _isBerry(String? itemId) => _berryData(itemId) != null;

({String type, int power})? _berryData(String? itemId) {
  return _naturalGiftBerries[itemId];
}

int _flingPower(String? itemId) {
  return _flingPowers[itemId] ?? (_isBerry(itemId) ? 10 : 0);
}

PsdkBattleMajorStatus? _flingStatus(String? itemId) {
  return switch (itemId) {
    'flame_orb' => PsdkBattleMajorStatus.burn,
    'light_ball' => PsdkBattleMajorStatus.paralysis,
    'poison_barb' => PsdkBattleMajorStatus.poison,
    'toxic_orb' => PsdkBattleMajorStatus.toxic,
    _ => null,
  };
}

int _pluckBerryHealAmount(String? itemId, int maxHp) {
  return switch (itemId) {
    'oran_berry' => 10,
    'sitrus_berry' => _atLeastOne(maxHp ~/ 4),
    _ => 0,
  };
}

int _atLeastOne(int value) => value < 1 ? 1 : value;

bool _speciesHasProtectedItems(String speciesId) {
  return _protectedPokemonItems.containsKey(_normalizedId(speciesId));
}

String? _normalizedNullableId(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = _normalizedId(value);
  return normalized.isEmpty ? null : normalized;
}

String _normalizedId(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_');
}

const _protectedItems = <String>{
  'exp_share',
  'lucky_egg',
  'amulet_coin',
  'oak_s_letter',
  'gram_1',
  'gram_2',
  'gram_3',
  'prof_s_letter',
  'letter',
  'greet_mail',
  'favored_mail',
  'rsvp_mail',
  'thanks_mail',
  'inquiry_mail',
  'like_mail',
  'reply_mail',
  'bridge_mail_s',
  'bridge_mail_d',
  'bridge_mail_t',
  'bridge_mail_v',
  'bridge_mail_m',
};

const _protectedPokemonItems = <String, Set<String>>{
  'giratina': {'griseous_orb'},
  'arceus': {
    'flame_plate',
    'splash_plate',
    'zap_plate',
    'meadow_plate',
    'icicle_plate',
    'fist_plate',
    'toxic_plate',
    'earth_plate',
    'sky_plate',
    'mind_plate',
    'insect_plate',
    'stone_plate',
    'spooky_plate',
    'draco_plate',
    'dread_plate',
    'iron_plate',
    'pixie_plate',
  },
  'genesect': {'shock_drive', 'burn_drive', 'chill_drive', 'douse_drive'},
  'kyogre': {'blue_orb'},
  'groudon': {'red_orb'},
  'zacian': {'rusted_sword'},
  'zamazenta': {'rusted_shield'},
  'ogerpon': {'wellspring_mask', 'hearthflame_mask', 'cornerstone_mask'},
};

const _naturalGiftBerries = <String, ({String type, int power})>{
  'aguav_berry': (type: 'dragon', power: 80),
  'apicot_berry': (type: 'ground', power: 100),
  'aspear_berry': (type: 'ice', power: 80),
  'babiri_berry': (type: 'steel', power: 80),
  'belue_berry': (type: 'electric', power: 100),
  'bluk_berry': (type: 'fire', power: 90),
  'charti_berry': (type: 'rock', power: 80),
  'cheri_berry': (type: 'fire', power: 80),
  'chesto_berry': (type: 'water', power: 80),
  'chilan_berry': (type: 'normal', power: 80),
  'chople_berry': (type: 'fighting', power: 80),
  'coba_berry': (type: 'flying', power: 80),
  'colbur_berry': (type: 'dark', power: 80),
  'cornn_berry': (type: 'bug', power: 90),
  'custap_berry': (type: 'ghost', power: 100),
  'durin_berry': (type: 'water', power: 100),
  'enigma_berry': (type: 'bug', power: 100),
  'figy_berry': (type: 'bug', power: 80),
  'ganlon_berry': (type: 'ice', power: 100),
  'grepa_berry': (type: 'flying', power: 90),
  'haban_berry': (type: 'dragon', power: 80),
  'hondew_berry': (type: 'ground', power: 90),
  'iapapa_berry': (type: 'dark', power: 80),
  'jaboca_berry': (type: 'dragon', power: 100),
  'kasib_berry': (type: 'ghost', power: 80),
  'kebia_berry': (type: 'poison', power: 80),
  'kee_berry': (type: 'fairy', power: 100),
  'kelpsy_berry': (type: 'fighting', power: 90),
  'lansat_berry': (type: 'flying', power: 100),
  'leppa_berry': (type: 'fighting', power: 80),
  'liechi_berry': (type: 'grass', power: 100),
  'lum_berry': (type: 'flying', power: 80),
  'magost_berry': (type: 'rock', power: 90),
  'mago_berry': (type: 'ghost', power: 80),
  'maranga_berry': (type: 'dark', power: 100),
  'micle_berry': (type: 'rock', power: 100),
  'nanab_berry': (type: 'water', power: 90),
  'nomel_berry': (type: 'dragon', power: 90),
  'occa_berry': (type: 'fire', power: 80),
  'oran_berry': (type: 'poison', power: 80),
  'pamtre_berry': (type: 'steel', power: 90),
  'passho_berry': (type: 'water', power: 80),
  'payapa_berry': (type: 'psychic', power: 80),
  'pecha_berry': (type: 'electric', power: 80),
  'persim_berry': (type: 'ground', power: 80),
  'petaya_berry': (type: 'poison', power: 100),
  'pinap_berry': (type: 'grass', power: 90),
  'pomeg_berry': (type: 'ice', power: 90),
  'qualot_berry': (type: 'poison', power: 90),
  'rabuta_berry': (type: 'ghost', power: 90),
  'rawst_berry': (type: 'grass', power: 80),
  'razz_berry': (type: 'steel', power: 80),
  'rindo_berry': (type: 'grass', power: 80),
  'roseli_berry': (type: 'fairy', power: 80),
  'rowap_berry': (type: 'dark', power: 100),
  'salac_berry': (type: 'fighting', power: 100),
  'shuca_berry': (type: 'ground', power: 80),
  'sitrus_berry': (type: 'psychic', power: 80),
  'spelon_berry': (type: 'dark', power: 90),
  'starf_berry': (type: 'psychic', power: 100),
  'tanga_berry': (type: 'bug', power: 80),
  'tamato_berry': (type: 'psychic', power: 90),
  'wacan_berry': (type: 'electric', power: 80),
  'watmel_berry': (type: 'fire', power: 100),
  'wepear_berry': (type: 'electric', power: 90),
  'wiki_berry': (type: 'rock', power: 80),
  'yache_berry': (type: 'ice', power: 80),
};

const _flingPowers = <String, int>{
  'air_balloon': 10,
  'black_sludge': 30,
  'burn_drive': 70,
  'chill_drive': 70,
  'choice_band': 10,
  'choice_scarf': 10,
  'choice_specs': 10,
  'douse_drive': 70,
  'draco_plate': 90,
  'dread_plate': 90,
  'earth_plate': 90,
  'eject_button': 30,
  'electric_memory': 50,
  'expert_belt': 10,
  'fire_memory': 50,
  'fist_plate': 90,
  'flame_orb': 30,
  'flame_plate': 90,
  'grass_memory': 50,
  'icicle_plate': 90,
  'iron_ball': 130,
  'iron_plate': 90,
  'leftovers': 10,
  'light_ball': 30,
  'loaded_dice': 10,
  'meadow_plate': 90,
  'mind_plate': 90,
  'pixie_plate': 90,
  'poison_barb': 70,
  'shock_drive': 70,
  'splash_plate': 90,
  'spooky_plate': 90,
  'stone_plate': 90,
  'terrain_extender': 30,
  'toxic_orb': 30,
  'toxic_plate': 90,
  'zap_plate': 90,
};
