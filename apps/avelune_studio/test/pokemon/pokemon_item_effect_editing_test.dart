import 'package:avelune_studio/features/pokemon/application/pokemon_item_effect_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

ProjectItemUseDefinition _use() =>
    PokemonItemEffectEditing.defaultUse(ProjectItemUseContext.overworld)
        .copyWith(
          friendshipLoss: const ProjectItemFriendshipLoss(
            low: 5,
            medium: 5,
            high: 10,
          ),
        );

void main() {
  test('recognized item effect defaults keep their typed canonical kind and values', () {
    for (final kind in [
      'heal',
      'vitamin',
      'battle_boost',
      'focus_energy',
      'mist',
      'full_restore',
      'repel',
      'escape_rope',
      'bicycle',
      'fishing',
      'cure',
      'revive',
      'pp',
    ]) {
      final effect = PokemonItemEffectEditing.effect(kind).normalized();
      expect(PokemonItemEffectEditing.kind(effect), kind);
    }
    final use = PokemonItemEffectEditing.defaultUse(
      ProjectItemUseContext.battle,
    );
    expect(use.contexts, {ProjectItemUseContext.battle});
    expect(use.target, ProjectItemTargetKind.partyMember);
    expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
    expect((use.effect as ProjectItemHealHpEffectDefinition).amount, 20);
    expect(
      (PokemonItemEffectEditing.effect(
        'repel',
      ) as ProjectItemRepelEffectDefinition).steps,
      100,
    );
  });

  test('replacing one use context preserves other contexts and their friendship loss', () {
    final shared = _use().copyWith(
      contexts: {ProjectItemUseContext.overworld, ProjectItemUseContext.battle},
    );
    final item = ProjectItemDefinition(
      id: 'medicine',
      displayName: 'Médicament',
      pocketId: 'medicine',
      uses: [shared],
    );
    final replacement = PokemonItemEffectEditing.changeKind(_use(), 'revive');
    final edited = PokemonItemEffectEditing.replace(
      item,
      ProjectItemUseContext.overworld,
      replacement,
    );
    expect(edited.uses, hasLength(2));
    final battle = PokemonItemEffectEditing.use(
      edited,
      ProjectItemUseContext.battle,
    )!;
    expect(battle.contexts, {ProjectItemUseContext.battle});
    expect(battle.effect, shared.effect);
    expect(battle.friendshipLoss, shared.friendshipLoss);
    expect(
      PokemonItemEffectEditing.use(
        edited,
        ProjectItemUseContext.overworld,
      )!.effect,
      isA<ProjectItemReviveEffectDefinition>(),
    );
    final removed = PokemonItemEffectEditing.replace(
      edited,
      ProjectItemUseContext.overworld,
      null,
    );
    expect(removed.uses.single, battle);
    expect(item.uses.single.contexts, hasLength(2));
  });

  test('bicycle and fishing defaults remain reusable world key items without friendship loss', () {
    const item = ProjectItemDefinition(
      id: 'tool',
      displayName: 'Outil',
      pocketId: 'items',
      tags: {'tool'},
    );
    for (final kind in ['bicycle', 'fishing']) {
      final use = PokemonItemEffectEditing.changeKind(_use(), kind);
      expect(use.target, ProjectItemTargetKind.world);
      expect(use.consumption, ProjectItemConsumptionPolicy.never);
      expect(use.friendshipLoss, isNull);
      expect(
        PokemonItemEffectEditing.replace(
          item,
          ProjectItemUseContext.overworld,
          use,
        ).tags,
        {'tool', 'key-item'},
      );
    }
    expect(item.tags, {'tool'});
  });

  test('world consumables clear friendship loss while full restore retains the bitter medicine contract', () {
    for (final kind in ['repel', 'escape_rope']) {
      final use = PokemonItemEffectEditing.changeKind(_use(), kind);
      expect(use.target, ProjectItemTargetKind.world);
      expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
      expect(use.friendshipLoss, isNull);
    }
    final full = PokemonItemEffectEditing.changeKind(_use(), 'full_restore');
    expect(full.target, ProjectItemTargetKind.partyMember);
    expect(full.consumption, ProjectItemConsumptionPolicy.onApplied);
    expect(full.friendshipLoss, _use().friendshipLoss);
  });

  test('friendship loss toggles and tier edits preserve the explicit consumption contract', () {
    final initial = _use().copyWith(
      consumption: ProjectItemConsumptionPolicy.never,
    );
    final enabled = PokemonItemEffectEditing.toggleFriendshipLoss(
      initial,
      true,
    );
    expect(enabled.consumption, ProjectItemConsumptionPolicy.onApplied);
    expect(enabled.friendshipLoss!.toJson(), {
      'low': 5,
      'medium': 5,
      'high': 10,
    });
    final edited = PokemonItemEffectEditing.editFriendshipLoss(
      enabled,
      'medium',
      12,
    );
    expect(edited.friendshipLoss!.toJson(), {
      'low': 5,
      'medium': 12,
      'high': 10,
    });
    final disabled = PokemonItemEffectEditing.toggleFriendshipLoss(
      edited,
      false,
    );
    expect(disabled.friendshipLoss, isNull);
    expect(disabled.consumption, ProjectItemConsumptionPolicy.onApplied);
    expect(initial.consumption, ProjectItemConsumptionPolicy.never);
  });

  test(
    'amount and structured numeric edits preserve all other use settings',
    () {
      final initial = _use();
      final fullPp = PokemonItemEffectEditing.restoreMode(
        initial,
        pp: true,
        full: true,
      );
      expect(
        (fullPp.effect as ProjectItemRestorePpEffectDefinition).mode,
        ProjectItemAmountMode.full,
      );
      expect(
        (fullPp.effect as ProjectItemRestorePpEffectDefinition).amount,
        isNull,
      );
      final flat = PokemonItemEffectEditing.restoreMode(
        fullPp,
        pp: true,
        full: false,
      );
      expect((flat.effect as ProjectItemRestorePpEffectDefinition).amount, 10);
      expect(
        (PokemonItemEffectEditing.setAmount(
                  initial,
                  pp: false,
                  amount: 50,
                ).effect
                as ProjectItemHealHpEffectDefinition)
            .amount,
        50,
      );
      final vitamin = PokemonItemEffectEditing.changeKind(initial, 'vitamin');
      final updated = PokemonItemEffectEditing.setInteger(
        vitamin,
        'maximumPerStat',
        150,
      );
      expect(
        (updated.effect as ProjectItemVitaminEffectDefinition).maximumPerStat,
        150,
      );
      expect((updated.effect as ProjectItemVitaminEffectDefinition).amount, 10);
      expect(updated.friendshipLoss, initial.friendshipLoss);
    },
  );
}
