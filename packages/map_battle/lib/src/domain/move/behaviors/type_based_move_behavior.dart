import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_data.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _TypeBasedMoveKind {
  auraWheel,
  hiddenPower,
  ivyCudgel,
  judgment,
  multiAttack,
  revelationDance,
}

/// Ports PSDK move families whose effective type is not the catalog type.
final class TypeBasedMoveBehavior implements BattleMoveUserPreventionBehavior {
  const TypeBasedMoveBehavior.auraWheel()
      : battleEngineMethod = 's_aura_wheel',
        _kind = _TypeBasedMoveKind.auraWheel;

  const TypeBasedMoveBehavior.hiddenPower()
      : battleEngineMethod = 's_hidden_power',
        _kind = _TypeBasedMoveKind.hiddenPower;

  const TypeBasedMoveBehavior.ivyCudgel()
      : battleEngineMethod = 's_ivy_cudgel',
        _kind = _TypeBasedMoveKind.ivyCudgel;

  const TypeBasedMoveBehavior.judgment()
      : battleEngineMethod = 's_judgment',
        _kind = _TypeBasedMoveKind.judgment;

  const TypeBasedMoveBehavior.multiAttack()
      : battleEngineMethod = 's_multi_attack',
        _kind = _TypeBasedMoveKind.multiAttack;

  const TypeBasedMoveBehavior.revelationDance()
      : battleEngineMethod = 's_revelation_dance',
        _kind = _TypeBasedMoveKind.revelationDance;

  @override
  final String battleEngineMethod;
  final _TypeBasedMoveKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    return switch (_kind) {
      _TypeBasedMoveKind.auraWheel => _canUseAuraWheel(user)
          ? null
          : const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            ),
      _ => null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
      );
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final move = _moveWithEffectiveType(context.move, user);
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
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
      moveCategory: move.category,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  BattleMoveDefinition _moveWithEffectiveType(
    BattleMoveDefinition move,
    PsdkBattleCombatant user,
  ) {
    return _copyMove(
      move,
      type: switch (_kind) {
        _TypeBasedMoveKind.auraWheel => _auraWheelType(user),
        _TypeBasedMoveKind.hiddenPower => _hiddenPowerType(user),
        _TypeBasedMoveKind.ivyCudgel =>
          _typeFromItem(user.heldItemId, _ivyCudgelTable, 'grass'),
        _TypeBasedMoveKind.judgment =>
          _typeFromItem(user.heldItemId, _judgmentTable, 'normal'),
        _TypeBasedMoveKind.multiAttack =>
          _typeFromItem(user.heldItemId, _memoryTable, 'normal'),
        _TypeBasedMoveKind.revelationDance => user.types.primary,
      },
    );
  }

  bool _canUseAuraWheel(PsdkBattleCombatant user) {
    return user.speciesId == 'morpeko';
  }
}

const _ivyCudgelTable = <String, String>{
  'wellspring_mask': 'water',
  'hearthflame_mask': 'fire',
  'cornerstone_mask': 'rock',
};

const _judgmentTable = <String, String>{
  'flame_plate': 'fire',
  'splash_plate': 'water',
  'zap_plate': 'electric',
  'meadow_plate': 'grass',
  'icicle_plate': 'ice',
  'fist_plate': 'fighting',
  'toxic_plate': 'poison',
  'earth_plate': 'ground',
  'sky_plate': 'flying',
  'mind_plate': 'psychic',
  'insect_plate': 'bug',
  'stone_plate': 'rock',
  'spooky_plate': 'ghost',
  'draco_plate': 'dragon',
  'iron_plate': 'steel',
  'dread_plate': 'dark',
  'pixie_plate': 'fairy',
};

const _memoryTable = <String, String>{
  'fire_memory': 'fire',
  'water_memory': 'water',
  'electric_memory': 'electric',
  'grass_memory': 'grass',
  'ice_memory': 'ice',
  'fighting_memory': 'fighting',
  'poison_memory': 'poison',
  'ground_memory': 'ground',
  'flying_memory': 'flying',
  'psychic_memory': 'psychic',
  'bug_memory': 'bug',
  'rock_memory': 'rock',
  'ghost_memory': 'ghost',
  'dragon_memory': 'dragon',
  'steel_memory': 'steel',
  'dark_memory': 'dark',
  'fairy_memory': 'fairy',
};

String _typeFromItem(
  String? heldItemId,
  Map<String, String> table,
  String fallback,
) {
  return table[heldItemId] ?? fallback;
}

String _auraWheelType(PsdkBattleCombatant user) {
  if (user.speciesId != 'morpeko') {
    return 'electric';
  }
  return switch (user.form) {
    1 => 'dark',
    _ => 'electric',
  };
}

String _hiddenPowerType(PsdkBattleCombatant user) {
  var index = 0;
  final bits = <int>[
    user.ivHp & 1,
    user.ivAttack & 1,
    user.ivDefense & 1,
    user.ivSpeed & 1,
    user.ivSpecialAttack & 1,
    user.ivSpecialDefense & 1,
  ];
  for (var i = 0; i < bits.length; i++) {
    index += bits[i] << i;
  }
  final tableIndex = (index * (_hiddenPowerTypes.length - 1) / 63).floor();
  return _hiddenPowerTypes[tableIndex];
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

const _hiddenPowerTypes = <String>[
  'fighting',
  'flying',
  'poison',
  'ground',
  'rock',
  'bug',
  'ghost',
  'steel',
  'fire',
  'water',
  'grass',
  'electric',
  'psychic',
  'ice',
  'dragon',
  'dark',
];
