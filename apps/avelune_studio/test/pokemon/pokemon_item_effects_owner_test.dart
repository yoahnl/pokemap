import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_item_effect_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_item_effects_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/pokemon_commerce_owner_fixture.dart';

void main() {
  late RecordingItemCommercePort port;
  late PokemonCommerceController commerce;
  late PokemonItemEffectsController effects;
  const overworld = ProjectItemUseContext.overworld;

  setUp(() async {
    port = RecordingItemCommercePort();
    commerce = PokemonCommerceController(port, changed: () {});
    await commerce.load();
    commerce.selectItem(port.item);
    effects = PokemonItemEffectsController(commerce);
  });
  tearDown(() => commerce.dispose());

  ProjectItemUseDefinition use() => effects.useFor(overworld)!;
  void apply(
    ProjectItemUseDefinition Function(ProjectItemUseDefinition) edit,
  ) => effects.setUse(overworld, edit(use()));

  test(
    'guided fishing picker authors three reusable rods and preserves the item',
    () async {
      effects.add(overworld);
      effects.selectEffect(overworld, 'fishing');
      for (final entry in {
        'oldRod': ProjectFishingRodKind.oldRod,
        'goodRod': ProjectFishingRodKind.goodRod,
        'superRod': ProjectFishingRodKind.superRod,
      }.entries) {
        apply((value) => PokemonItemEffectEditing.setRodKind(value, entry.key));
        final item = commerce.item!;
        expect(item.id, 'custom_tool');
        expect(item.pocketId, 'custom');
        expect(item.tags, contains('key-item'));
        expect(
          item.uses.single.effect,
          ProjectItemEffectDefinition.fishing(rodKind: entry.value),
        );
        expect(item.uses.single.target, ProjectItemTargetKind.world);
        expect(
          item.uses.single.consumption,
          ProjectItemConsumptionPolicy.never,
        );
        expect(
          validateProjectItemCatalog(
            ProjectItemCatalog(schemaVersion: 1, entries: [item]),
            capabilityTruth: itemSystemV1CapabilityTruth,
          ).hasBlockingDiagnostics,
          isFalse,
        );
      }
      expect(await commerce.save(), isTrue);
      final reopened = await port.load();
      expect(
        reopened.catalog!.entries.single.uses.single.effect,
        const ProjectItemEffectDefinition.fishing(
          rodKind: ProjectFishingRodKind.superRod,
        ),
      );
    },
  );

  test('guided medicine settings persist friendship and confusion without JSON editing', () async {
    effects.add(overworld);
    effects.toggleFriendshipLoss(overworld, true);
    expect(
      use().friendshipLoss,
      const ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10),
    );
    final bounds = PokemonItemEffectEditing.integerBounds('friendshipLoss');
    commerce.setIntegerInput(
      fieldId: 'friendship-high',
      value: '12',
      minimum: bounds.minimum,
      maximum: bounds.maximum,
      optional: false,
      onChanged: (value) => apply(
        (current) =>
            PokemonItemEffectEditing.editFriendshipLoss(current, 'high', value),
      ),
    );
    effects.selectEffect(overworld, 'cure');
    apply((value) => PokemonItemEffectEditing.setCuresConfusion(value, true));
    expect(use().friendshipLoss!.high, 12);
    expect(
      (use().effect as ProjectItemCureStatusEffectDefinition).curesConfusion,
      isTrue,
    );
    expect(await commerce.save(), isTrue);
    expect(port.item.uses.single.friendshipLoss!.high, 12);
    expect(
      (port.item.uses.single.effect as ProjectItemCureStatusEffectDefinition)
          .curesConfusion,
      isTrue,
    );
  });

  test(
    'effect kinds follow their use context and imported effects stay locked',
    () {
      expect(
        PokemonItemEffectEditing.kindOptions(overworld).keys,
        containsAll([
          'vitamin',
          'pp',
          'repel',
          'escape_rope',
          'bicycle',
          'fishing',
        ]),
      );
      expect(
        PokemonItemEffectEditing.kindOptions(overworld).keys,
        isNot(contains('battle_boost')),
      );
      final battle = PokemonItemEffectEditing.kindOptions(
        ProjectItemUseContext.battle,
      ).keys;
      expect(battle, containsAll(['battle_boost', 'focus_energy', 'mist']));
      expect(battle, isNot(contains('vitamin')));
      expect(battle, isNot(contains('repel')));
      expect(PokemonItemEffectEditing.editable(overworld, 'repel'), isTrue);
      expect(
        PokemonItemEffectEditing.editable(
          ProjectItemUseContext.battle,
          'repel',
        ),
        isFalse,
      );
      expect(PokemonItemEffectEditing.editable(overworld, 'imported'), isFalse);
    },
  );

  test('effect number fields keep their authored bounds', () {
    expect(PokemonItemEffectEditing.integerBounds('stages'), (
      minimum: 1,
      maximum: 6,
    ));
    expect(PokemonItemEffectEditing.integerBounds('maximumTotal'), (
      minimum: 1,
      maximum: 1530,
    ));
    expect(PokemonItemEffectEditing.integerBounds('maximumPerStat'), (
      minimum: 1,
      maximum: 252,
    ));
    expect(PokemonItemEffectEditing.integerBounds('friendshipGainLow'), (
      minimum: 0,
      maximum: 255,
    ));
    expect(PokemonItemEffectEditing.integerBounds('amount'), (
      minimum: 1,
      maximum: 255,
    ));
  });

  test('consumption stays locked by friendship loss and world tools', () {
    effects.add(overworld);
    expect(PokemonItemEffectEditing.consumptionLocked(use()), isFalse);
    apply((value) => PokemonItemEffectEditing.setConsumed(value, false));
    expect(use().consumption, ProjectItemConsumptionPolicy.never);
    effects.toggleFriendshipLoss(overworld, true);
    expect(PokemonItemEffectEditing.consumptionLocked(use()), isTrue);
    apply((value) => PokemonItemEffectEditing.setConsumed(value, false));
    expect(use().consumption, ProjectItemConsumptionPolicy.onApplied);
    for (final kind in ['escape_rope', 'bicycle', 'fishing']) {
      effects.selectEffect(overworld, kind);
      expect(PokemonItemEffectEditing.consumptionLocked(use()), isTrue);
    }
    effects.selectEffect(overworld, 'repel');
    expect(PokemonItemEffectEditing.consumptionLocked(use()), isFalse);
  });

  test('guided stat pickers replace only the trained statistic', () {
    effects.add(overworld);
    effects.selectEffect(overworld, 'vitamin');
    apply((value) => PokemonItemEffectEditing.setTrainedStat(value, 'speed'));
    final vitamin = use().effect as ProjectItemVitaminEffectDefinition;
    expect(vitamin.stat, ProjectItemVitaminStat.speed);
    expect(vitamin.amount, 10);
    effects.add(ProjectItemUseContext.battle);
    effects.selectEffect(ProjectItemUseContext.battle, 'battle_boost');
    final boostUse = effects.useFor(ProjectItemUseContext.battle)!;
    final boosted = PokemonItemEffectEditing.setTrainedStat(
      boostUse,
      'defense',
    );
    expect(
      boosted.effect,
      const ProjectItemEffectDefinition.battleBoost(
        stat: ProjectItemBattleStat.defense,
        stages: 1,
      ),
    );
    expect(PokemonItemEffectEditing.setRepelSteps(boostUse, 50), boostUse);
  });
}
