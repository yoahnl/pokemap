import 'package:avelune_studio/features/pokemon/application/pokemon_item_effect_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_item_effects_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_shop_editing.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m3_story_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';
import '../support/pokemon_commerce_owner_fixture.dart';

void main() {
  const overworld = ProjectItemUseContext.overworld;
  const battle = ProjectItemUseContext.battle;

  Future<(PokemonAuthoringFixture, PokemonItemEffectsController)> openPotion({
    Future<void> Function(M3StoryFixture)? seed,
  }) async {
    final host = await PokemonAuthoringFixture.create(
      prepareSource: seed ?? seedPokemonGoldenItems,
    );
    addTearDown(host.dispose);
    expect(await host.view(PokemonWorkspaceView.items), isTrue);
    final potion = host.commerce.snapshot!.catalog!.entries.singleWhere(
      (item) => item.id == 'potion',
    );
    expect(host.commerce.selectItem(potion), isTrue);
    return (host, PokemonItemEffectsController(host.commerce));
  }

  Future<ProjectItemDefinition> reopenedPotion(
    PokemonAuthoringFixture host,
  ) async =>
      (await reopenPokemonCommerce(host)).catalog!.entries
          .singleWhere((item) => item.id == 'potion');

  test('Studio authors and reloads Full Restore in both contexts', () async {
    final (host, effects) = await openPotion();
    for (final context in [overworld, battle]) {
      effects.selectEffect(context, 'full_restore');
    }
    for (final context in [overworld, battle]) {
      final use = pokemonItemUse(host.commerce.item!, context);
      expect(use.effect, const ProjectItemEffectDefinition.fullRestore());
      expect(use.target, ProjectItemTargetKind.partyMember);
      expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
    }
    expect(await host.commerce.save(), isTrue);
    expect(host.commerce.error, isNull);
    expect(host.commerce.dirty, isFalse);
    final item = await reopenedPotion(host);
    expect(item.uses, hasLength(2));
    expect(
      item.uses.every(
        (use) => use.effect == const ProjectItemEffectDefinition.fullRestore(),
      ),
      isTrue,
    );
  });

  test(
    'Studio authors vitamins and battle boosts and cold reloads typed settings',
    () async {
      final (host, effects) = await openPotion();
      effects.selectEffect(overworld, 'vitamin');
      effects.selectEffect(battle, 'battle_boost');
      expect(
        pokemonItemUse(host.commerce.item!, overworld).effect,
        const ProjectItemEffectDefinition.vitamin(
          stat: ProjectItemVitaminStat.hp,
          amount: 10,
          maximumPerStat: 100,
          friendshipGainLow: 5,
          friendshipGainMedium: 3,
          friendshipGainHigh: 2,
        ),
      );
      expect(
        pokemonItemUse(host.commerce.item!, battle).effect,
        const ProjectItemEffectDefinition.battleBoost(
          stat: ProjectItemBattleStat.attack,
          stages: 1,
        ),
      );
      for (final context in [overworld, battle]) {
        final use = pokemonItemUse(host.commerce.item!, context);
        expect(use.target, ProjectItemTargetKind.partyMember);
        expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
      }
      expect(await host.commerce.save(), isTrue);
      expect(host.commerce.dirty, isFalse);
      final item = await reopenedPotion(host);
      expect(item.uses, hasLength(2));
      expect(
        pokemonItemUse(item, overworld).effect,
        isA<ProjectItemVitaminEffectDefinition>(),
      );
      expect(
        pokemonItemUse(item, battle).effect,
        isA<ProjectItemBattleBoostEffectDefinition>(),
      );
    },
  );

  test('Corde Sortie authors a typed consumable world effect', () async {
    final (host, effects) = await openPotion();
    expect(
      PokemonItemEffectEditing.kindOptions(overworld),
      contains('escape_rope'),
    );
    effects.selectEffect(overworld, 'escape_rope');
    final use = pokemonItemUse(host.commerce.item!, overworld);
    expect(use.target, ProjectItemTargetKind.world);
    expect(use.consumption, ProjectItemConsumptionPolicy.onApplied);
    expect(use.effect, const ProjectItemEffectDefinition.escapeRope());
    expect(await host.commerce.save(), isTrue);
    expect(host.commerce.error, isNull);
    expect(host.commerce.dirty, isFalse);
    expect(
      pokemonItemUse(await reopenedPotion(host), overworld).effect,
      const ProjectItemEffectDefinition.escapeRope(),
    );
    host.commerce.editItem((item) => item.copyWith(tags: {'key-item'}));
    expect(await host.commerce.save(), isFalse);
    expect(host.commerce.dirty, isTrue);
    expect(host.commerce.error, contains('objet clé'));
  });

  test(
    'Repousse authors world target and editable positive step count',
    () async {
      final (host, effects) = await openPotion();
      effects.selectEffect(overworld, 'repel');
      ProjectItemUseDefinition use() =>
          pokemonItemUse(host.commerce.item!, overworld);
      expect(use().target, ProjectItemTargetKind.world);
      expect(use().effect, const ProjectItemEffectDefinition.repel(steps: 100));
      void steps(String raw) => host.commerce.setIntegerInput(
        fieldId: 'item-effect-potion-overworld',
        value: raw,
        minimum: 1,
        optional: false,
        onChanged: (value) => effects.setUse(
          overworld,
          PokemonItemEffectEditing.setRepelSteps(use(), value!),
        ),
      );
      steps('0');
      expect(host.commerce.fieldErrors, isNotEmpty);
      expect(use().effect, const ProjectItemEffectDefinition.repel(steps: 100));
      steps('250');
      expect(use().effect, const ProjectItemEffectDefinition.repel(steps: 250));
      expect(await host.commerce.save(), isTrue);
      expect(host.commerce.error, isNull);
      expect(host.commerce.dirty, isFalse);
      expect(
        pokemonItemUse(await reopenedPotion(host), overworld).effect,
        const ProjectItemEffectDefinition.repel(steps: 250),
      );
    },
  );

  test('objects and shops persist through the real workspace', () async {
    final (host, _) = await openPotion(seed: seedPokemonGoldenItemsAndShop);
    final commerce = host.commerce;
    commerce.editItem((item) => item.copyWith(displayName: 'Potion du quai'));
    expect(await commerce.save(), isTrue);
    expect(commerce.dirty, isFalse);
    expect(await host.view(PokemonWorkspaceView.shops), isTrue);
    final shop = commerce.snapshot!.shops.singleWhere(
      (shop) => shop.id == 'gare',
    );
    expect(commerce.selectShop(shop), isTrue);
    final candidate = PokemonShopEditing.candidates(
      commerce.shop!,
      commerce.snapshot!.catalog!.entries,
    ).singleWhere((item) => item.displayName == 'Potion du quai');
    commerce.editShop((current) => PokemonShopEditing.add(current, candidate));
    expect(await commerce.save(), isTrue);
    expect(commerce.error, isNull);
    expect(commerce.dirty, isFalse);
    final reopened = await reopenPokemonCommerce(host);
    expect(
      reopened.catalog!.entries
          .firstWhere((item) => item.id == 'potion')
          .displayName,
      'Potion du quai',
    );
    expect(
      reopened.shops
          .singleWhere((shop) => shop.id == 'gare')
          .entries
          .single
          .itemId,
      'potion',
    );
  });

  test(
    'creates an item with a battle effect and a shop through Studio',
    () async {
      final host = await PokemonAuthoringFixture.create(
        prepareSource: seedPokemonGoldenItems,
      );
      addTearDown(host.dispose);
      final commerce = host.commerce;
      expect(await host.view(PokemonWorkspaceView.items), isTrue);
      expect(commerce.createItem('billet'), isTrue);
      commerce.editItem(
        (item) => item.copyWith(displayName: 'Billet du train'),
      );
      PokemonItemEffectsController(commerce).add(battle);
      expect(await commerce.save(), isTrue);
      expect(commerce.error, isNull);
      expect(commerce.dirty, isFalse);
      expect(
        commerce.snapshot!.catalog!.entries.any((item) => item.id == 'billet'),
        isTrue,
      );
      expect(await host.view(PokemonWorkspaceView.shops), isTrue);
      expect(commerce.createShop('quai'), isTrue);
      final billet = PokemonShopEditing.candidates(
        commerce.shop!,
        commerce.snapshot!.catalog!.entries,
      ).singleWhere((item) => item.displayName == 'Billet du train');
      commerce.editShop((current) => PokemonShopEditing.add(current, billet));
      expect(await commerce.save(), isTrue);
      final reopened = await reopenPokemonCommerce(host);
      final item = reopened.catalog!.entries.singleWhere(
        (value) => value.id == 'billet',
      );
      expect(item.displayName, 'Billet du train');
      expect(item.uses, isNotEmpty);
      expect(
        reopened.shops
            .singleWhere((shop) => shop.id == 'quai')
            .entries
            .single
            .itemId,
        'billet',
      );
    },
  );
}
