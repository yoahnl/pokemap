import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
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

    test('projects the legacy overworld registry from canonical definitions',
        () {
      const registry = PlayerItemEffectRegistry.mvp();

      expect(registry.effects.keys.toSet(), {
        for (final item in mvpItemCatalog.entries) item.id,
      });
      expect(registry.effectFor('potion')?.amount, 20);
      expect(registry.effectFor('hyper-potion')?.amount, 120);
      expect(registry.effectFor('max-potion')?.amount, 0x7fffffff);
      expect(registry.effectFor('full-heal')?.curesAnyStatus, isTrue);
      expect(registry.effectFor('revive')?.revivePercent, 50);
      expect(registry.effectFor('max-ether')?.amount, 0x7fffffff);
      expect(registry.effectFor('poke-ball')?.ballMultiplier, 1);
      expect(
        registry.effectFor('key-item')?.kind,
        PlayerItemEffectKind.keyItem,
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
