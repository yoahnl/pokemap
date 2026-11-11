import 'package:map_core/map_core_domain.dart';

class PokemonItemEffectEditing {
  static ProjectItemUseDefinition? use(
    ProjectItemDefinition item,
    ProjectItemUseContext context,
  ) => item.uses.where((value) => value.contexts.contains(context)).firstOrNull;

  static ProjectItemDefinition replace(
    ProjectItemDefinition item,
    ProjectItemUseContext context,
    ProjectItemUseDefinition? replacement,
  ) => item.copyWith(
    tags:
        replacement?.effect is ProjectItemBicycleEffectDefinition ||
            replacement?.effect is ProjectItemFishingEffectDefinition
        ? {...item.tags, 'key-item'}
        : item.tags,
    uses: [
      for (final value in item.uses)
        if (!value.contexts.contains(context))
          value
        else if (value.contexts.length > 1)
          value.copyWith(contexts: {...value.contexts}..remove(context)),
      if (replacement != null) replacement.copyWith(contexts: {context}),
    ],
  );

  static ProjectItemUseDefinition defaultUse(ProjectItemUseContext context) =>
      ProjectItemUseDefinition(
        contexts: {context},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      );

  static ProjectItemEffectDefinition effect(String kind) => switch (kind) {
    'vitamin' => const ProjectItemEffectDefinition.vitamin(
      stat: ProjectItemVitaminStat.hp,
      amount: 10,
      maximumPerStat: 100,
      friendshipGainLow: 5,
      friendshipGainMedium: 3,
      friendshipGainHigh: 2,
    ),
    'battle_boost' => const ProjectItemEffectDefinition.battleBoost(
      stat: ProjectItemBattleStat.attack,
      stages: 1,
    ),
    'focus_energy' => const ProjectItemEffectDefinition.battlePreparation(
      effect: ProjectItemBattlePreparationKind.focusEnergy,
    ),
    'mist' => const ProjectItemEffectDefinition.battlePreparation(
      effect: ProjectItemBattlePreparationKind.mist,
      turns: 5,
    ),
    'full_restore' => const ProjectItemEffectDefinition.fullRestore(),
    'repel' => const ProjectItemEffectDefinition.repel(steps: 100),
    'escape_rope' => const ProjectItemEffectDefinition.escapeRope(),
    'bicycle' => const ProjectItemEffectDefinition.bicycle(),
    'fishing' => const ProjectItemEffectDefinition.fishing(
      rodKind: ProjectFishingRodKind.oldRod,
    ),
    'cure' => const ProjectItemEffectDefinition.cureStatus(
      mode: ProjectItemStatusCureMode.all,
    ),
    'revive' => const ProjectItemEffectDefinition.revive(
      rateNumerator: 1,
      rateDenominator: 2,
    ),
    'pp' => const ProjectItemEffectDefinition.restorePp(
      mode: ProjectItemAmountMode.flat,
      amount: 10,
    ),
    _ => const ProjectItemEffectDefinition.healHp(
      mode: ProjectItemAmountMode.flat,
      amount: 20,
    ),
  };

  static String kind(ProjectItemEffectDefinition effect) => switch (effect) {
    ProjectItemVitaminEffectDefinition() => 'vitamin',
    ProjectItemBattleBoostEffectDefinition() => 'battle_boost',
    ProjectItemBattlePreparationEffectDefinition(:final effect) =>
      effect == ProjectItemBattlePreparationKind.mist ? 'mist' : 'focus_energy',
    ProjectItemFullRestoreEffectDefinition() => 'full_restore',
    ProjectItemHealHpEffectDefinition() => 'heal',
    ProjectItemCureStatusEffectDefinition() => 'cure',
    ProjectItemReviveEffectDefinition() => 'revive',
    ProjectItemRestorePpEffectDefinition() => 'pp',
    ProjectItemRepelEffectDefinition() => 'repel',
    ProjectItemEscapeRopeEffectDefinition() => 'escape_rope',
    ProjectItemBicycleEffectDefinition() => 'bicycle',
    ProjectItemFishingEffectDefinition() => 'fishing',
    _ => 'imported',
  };

  static ProjectItemUseDefinition changeKind(
    ProjectItemUseDefinition use,
    String value,
  ) => use.copyWith(
    effect: effect(value),
    friendshipLoss:
        {'repel', 'escape_rope', 'bicycle', 'fishing'}.contains(value)
        ? null
        : use.friendshipLoss,
    consumption: value == 'bicycle' || value == 'fishing'
        ? ProjectItemConsumptionPolicy.never
        : value == 'escape_rope' || value == 'full_restore'
        ? ProjectItemConsumptionPolicy.onApplied
        : use.consumption,
    target:
        value == 'repel' ||
            value == 'escape_rope' ||
            value == 'bicycle' ||
            value == 'fishing'
        ? ProjectItemTargetKind.world
        : value == 'pp'
        ? ProjectItemTargetKind.partyMove
        : ProjectItemTargetKind.partyMember,
  );

  static ProjectItemUseDefinition restoreMode(
    ProjectItemUseDefinition use, {
    required bool pp,
    required bool full,
  }) => use.copyWith(
    effect: pp
        ? ProjectItemEffectDefinition.restorePp(
            mode: full
                ? ProjectItemAmountMode.full
                : ProjectItemAmountMode.flat,
            amount: full ? null : 10,
          )
        : ProjectItemEffectDefinition.healHp(
            mode: full
                ? ProjectItemAmountMode.full
                : ProjectItemAmountMode.flat,
            amount: full ? null : 20,
          ),
  );

  static ProjectItemUseDefinition setAmount(
    ProjectItemUseDefinition use, {
    required bool pp,
    required int amount,
  }) => use.copyWith(
    effect: pp
        ? ProjectItemEffectDefinition.restorePp(
            mode: ProjectItemAmountMode.flat,
            amount: amount,
          )
        : ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: amount,
          ),
  );

  static ProjectItemUseDefinition setInteger(
    ProjectItemUseDefinition use,
    String field,
    int? value,
  ) => use.copyWith(
    effect: ProjectItemEffectDefinition.fromJson({
      ...use.effect.toJson(),
      field: value,
    }).normalized(),
  );

  static ProjectItemUseDefinition toggleFriendshipLoss(
    ProjectItemUseDefinition use,
    bool enabled,
  ) => use.copyWith(
    consumption: ProjectItemConsumptionPolicy.onApplied,
    friendshipLoss: enabled
        ? const ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10)
        : null,
  );

  static ProjectItemUseDefinition editFriendshipLoss(
    ProjectItemUseDefinition use,
    String tier,
    int? value,
  ) => use.copyWith(
    friendshipLoss: ProjectItemFriendshipLoss.fromJson({
      ...use.friendshipLoss!.toJson(),
      tier: value,
    }),
  );

  static Map<String, String> kindOptions(ProjectItemUseContext context) => {
    'heal': 'Soigner les PV',
    'full_restore': 'Soin Total',
    'cure': 'Guérir les statuts',
    'revive': 'Réanimer',
    if (context == ProjectItemUseContext.overworld)
      'vitamin': 'Vitamine (EV et bonheur)',
    if (context == ProjectItemUseContext.battle) ...{
      'battle_boost': 'Augmenter une statistique',
      'focus_energy': 'Muscle + (critiques)',
      'mist': 'Défense Spéciale (Brume)',
    },
    if (context == ProjectItemUseContext.overworld) ...{
      'pp': 'Restaurer les PP',
      'repel': 'Repousse',
      'escape_rope': 'Corde Sortie',
      'bicycle': 'Vélo',
      'fishing': 'Pêche',
    },
  };

  static bool editable(ProjectItemUseContext context, String kind) =>
      kind != 'imported' &&
      (context != ProjectItemUseContext.battle ||
          !{'pp', 'repel', 'escape_rope', 'bicycle', 'fishing'}.contains(kind));

  static ({int minimum, int maximum}) integerBounds(String field) => (
    minimum: field.startsWith('friendship') ? 0 : 1,
    maximum: switch (field) {
      'stages' => 6,
      'maximumTotal' => 1530,
      'maximumPerStat' => 252,
      _ => 255,
    },
  );

  static bool consumptionLocked(ProjectItemUseDefinition use) =>
      use.friendshipLoss != null ||
      {'escape_rope', 'bicycle', 'fishing'}.contains(kind(use.effect));

  static ProjectItemUseDefinition setConsumed(
    ProjectItemUseDefinition use,
    bool consumed,
  ) => consumptionLocked(use)
      ? use
      : use.copyWith(
          consumption: consumed
              ? ProjectItemConsumptionPolicy.onApplied
              : ProjectItemConsumptionPolicy.never,
        );

  static ProjectItemUseDefinition setCuresConfusion(
    ProjectItemUseDefinition use,
    bool enabled,
  ) => switch (use.effect) {
    final ProjectItemCureStatusEffectDefinition cure => use.copyWith(
      effect: cure.copyWith(curesConfusion: enabled),
    ),
    _ => use,
  };

  static ProjectItemUseDefinition setTrainedStat(
    ProjectItemUseDefinition use,
    String stat,
  ) => switch (use.effect) {
    final ProjectItemVitaminEffectDefinition vitamin => use.copyWith(
      effect: vitamin.copyWith(
        stat: ProjectItemVitaminStat.values.byName(stat),
      ),
    ),
    final ProjectItemBattleBoostEffectDefinition boost => use.copyWith(
      effect: boost.copyWith(stat: ProjectItemBattleStat.values.byName(stat)),
    ),
    _ => use,
  };

  static ProjectItemUseDefinition setRodKind(
    ProjectItemUseDefinition use,
    String rodKind,
  ) => use.effect is ProjectItemFishingEffectDefinition
      ? use.copyWith(
          effect: ProjectItemEffectDefinition.fishing(
            rodKind: ProjectFishingRodKind.values.byName(rodKind),
          ),
        )
      : use;

  static ProjectItemUseDefinition setRepelSteps(
    ProjectItemUseDefinition use,
    int steps,
  ) => use.effect is ProjectItemRepelEffectDefinition
      ? use.copyWith(effect: ProjectItemEffectDefinition.repel(steps: steps))
      : use;
}
