import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/items/item_capability_resolver.dart';
import 'package:map_gameplay/src/items/item_catalog_snapshot.dart';
import 'package:map_gameplay/src/items/mvp_item_catalog.dart';
import 'package:test/test.dart';

void main() {
  group('mvpItemCatalog', () {
    test('contains every currently supported MVP item as canonical data', () {
      expect(mvpItemCatalog.schemaVersion, 1);
      expect(mvpItemCatalog.normalized(), mvpItemCatalog);
      expect(
        mvpItemCatalog.entries.map((item) => item.id).toSet(),
        {
          'potion',
          'super-potion',
          'hyper-potion',
          'max-potion',
          'antidote',
          'awakening',
          'paralyze-heal',
          'burn-heal',
          'ice-heal',
          'full-heal',
          'revive',
          'ether',
          'max-ether',
          'poke-ball',
          'key-item',
        },
      );
    });

    test('owns potion, revive, PP, and capture values', () {
      expect(_effect('potion'), _flatHp(20));
      expect(_effect('super-potion'), _flatHp(50));
      expect(_effect('hyper-potion'), _flatHp(120));
      expect(
        _effect('max-potion'),
        const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.full,
        ),
      );
      expect(
        _effect('revive'),
        const ProjectItemEffectDefinition.revive(
          rateNumerator: 1,
          rateDenominator: 2,
        ),
      );
      expect(
        _effect('ether'),
        const ProjectItemEffectDefinition.restorePp(
          mode: ProjectItemAmountMode.flat,
          amount: 10,
        ),
      );
      expect(
        _effect('max-ether'),
        const ProjectItemEffectDefinition.restorePp(
          mode: ProjectItemAmountMode.full,
        ),
      );
      expect(
        _item('poke-ball').capture,
        const ProjectCaptureItemDefinition(
          rateNumerator: 1,
          rateDenominator: 1,
          allowedEncounterKinds: {
            EncounterKind.walk,
            EncounterKind.surf,
            EncounterKind.headbutt,
            EncounterKind.oldRod,
            EncounterKind.goodRod,
            EncounterKind.superRod,
            EncounterKind.special,
          },
        ),
      );
    });

    test('resolves canonical definitions without a projected registry', () {
      final snapshot = ItemCatalogSnapshot.fromCatalog(mvpItemCatalog);
      final resolver = ItemCapabilityResolver(snapshot);

      expect(snapshot.definitions.map((item) => item.id).toSet(), {
        for (final item in mvpItemCatalog.entries) item.id,
      });
      expect(snapshot.definitionFor('poke-ball')?.capture?.rateNumerator, 1);
      expect(snapshot.definitionFor('key-item')?.tags, contains('key-item'));
      expect(
        resolver
            .resolveUse(
              itemId: 'potion',
              context: ProjectItemUseContext.overworld,
            )
            .use
            ?.effect,
        _flatHp(20),
      );
    });
  });
}

ProjectItemDefinition _item(String itemId) {
  return mvpItemCatalog.entries.singleWhere((item) => item.id == itemId);
}

ProjectItemEffectDefinition _effect(String itemId) {
  return _item(itemId).uses.single.effect;
}

ProjectItemEffectDefinition _flatHp(int amount) {
  return ProjectItemEffectDefinition.healHp(
    mode: ProjectItemAmountMode.flat,
    amount: amount,
  );
}
