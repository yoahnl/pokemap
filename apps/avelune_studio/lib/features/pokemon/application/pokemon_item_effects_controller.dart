import 'package:map_core/map_core_domain.dart';

import 'pokemon_commerce_controller.dart';

class PokemonItemEffectsController {
  PokemonItemEffectsController(this.commerce);

  final PokemonCommerceController commerce;

  ProjectItemUseDefinition? useFor(ProjectItemUseContext context) {
    for (final value in commerce.item!.uses) {
      if (value.contexts.contains(context)) return value;
    }
    return null;
  }

  void setUse(
    ProjectItemUseContext context,
    ProjectItemUseDefinition? replacement,
  ) {
    commerce.setFieldError(
      'item-effect-${commerce.item!.id}-${context.name}',
      null,
    );
    commerce.editItem(
      (item) => item.copyWith(
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
      ),
    );
  }

  ProjectItemUseDefinition defaultUse(ProjectItemUseContext context) =>
      ProjectItemUseDefinition(
        contexts: {context},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      );

  ProjectItemEffectDefinition effectForKind(String kind) => switch (kind) {
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

  String kindOf(ProjectItemEffectDefinition effect) => switch (effect) {
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

  void add(ProjectItemUseContext context) =>
      setUse(context, defaultUse(context));

  void remove(ProjectItemUseContext context) => setUse(context, null);

  void selectEffect(ProjectItemUseContext context, String kind) {
    final use = useFor(context);
    if (use == null) return;
    setUse(
      context,
      use.copyWith(
        effect: effectForKind(kind),
        consumption: kind == 'bicycle' || kind == 'fishing'
            ? ProjectItemConsumptionPolicy.never
            : kind == 'escape_rope' || kind == 'full_restore'
            ? ProjectItemConsumptionPolicy.onApplied
            : use.consumption,
        target:
            kind == 'repel' ||
                kind == 'escape_rope' ||
                kind == 'bicycle' ||
                kind == 'fishing'
            ? ProjectItemTargetKind.world
            : kind == 'pp'
            ? ProjectItemTargetKind.partyMove
            : ProjectItemTargetKind.partyMember,
      ),
    );
  }

  void setInteger(ProjectItemUseContext context, String field, int value) {
    final use = useFor(context);
    if (use == null) return;
    setUse(
      context,
      use.copyWith(
        effect: ProjectItemEffectDefinition.fromJson({
          ...use.effect.toJson(),
          field: value,
        }).normalized(),
      ),
    );
  }
}
