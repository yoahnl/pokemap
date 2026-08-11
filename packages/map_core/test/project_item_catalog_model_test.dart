import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectItemCatalog', () {
    test('round-trips the canonical item contracts', () {
      final catalog = ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'potion',
            displayName: 'Potion',
            aliases: const ['Potion'],
            pocketId: 'medicine',
            description: 'Restores HP.',
            buyPrice: 300,
            sellPrice: 150,
            tags: const {'healing'},
            uses: const [
              ProjectItemUseDefinition(
                contexts: {
                  ProjectItemUseContext.overworld,
                  ProjectItemUseContext.battle,
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.healHp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 20,
                ),
              ),
            ],
          ),
          ProjectItemDefinition(
            id: 'poke-ball',
            displayName: 'Poké Ball',
            pocketId: 'balls',
            capture: const ProjectCaptureItemDefinition(
              rateNumerator: 1,
              rateDenominator: 1,
              allowedEncounterKinds: {EncounterKind.walk, EncounterKind.surf},
            ),
          ),
          ProjectItemDefinition(
            id: 'cut-hm',
            displayName: 'HM Cut',
            pocketId: 'machines',
            machine: const ProjectMoveMachineItemDefinition(
              moveId: 'cut',
              kind: ProjectMoveMachineKind.hm,
              consumable: false,
            ),
          ),
        ],
      ).normalized();

      expect(ProjectItemCatalog.fromJson(catalog.toJson()), catalog);
    });

    test('normalizes identifiers, aliases, pockets, and tags', () {
      final item = ProjectItemDefinition(
        id: ' potion ',
        displayName: ' Potion ',
        aliases: const [' Potion ', '', 'Potion'],
        pocketId: ' medicine ',
        tags: const {' healing ', '', 'healing'},
      ).normalized();

      expect(item.id, 'potion');
      expect(item.displayName, 'Potion');
      expect(item.aliases, ['Potion']);
      expect(item.pocketId, 'medicine');
      expect(item.tags, {'healing'});
    });

    test('forbids uses without contexts', () {
      expect(
        () => const ProjectItemUseDefinition(
          contexts: {},
          target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: ProjectItemEffectDefinition.healHp(
            mode: ProjectItemAmountMode.flat,
            amount: 20,
          ),
        ).normalized(),
        throwsStateError,
      );
    });

    test('forbids overlapping use contexts for one item', () {
      expect(
        () => ProjectItemDefinition(
          id: 'potion',
          displayName: 'Potion',
          pocketId: 'medicine',
          uses: const [
            ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.overworld},
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.healHp(
                mode: ProjectItemAmountMode.flat,
                amount: 20,
              ),
            ),
            ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.overworld},
              target: ProjectItemTargetKind.none,
              consumption: ProjectItemConsumptionPolicy.never,
              effect: ProjectItemEffectDefinition.semanticAction(
                actionId: 'world.escape',
              ),
            ),
          ],
        ).normalized(),
        throwsStateError,
      );
    });

    test('reduces capture ratios and rejects invalid ratios', () {
      expect(
        const ProjectCaptureItemDefinition(
          rateNumerator: 4,
          rateDenominator: 2,
          allowedEncounterKinds: {EncounterKind.walk},
        ).normalized(),
        const ProjectCaptureItemDefinition(
          rateNumerator: 2,
          rateDenominator: 1,
          allowedEncounterKinds: {EncounterKind.walk},
        ),
      );
      expect(
        () => const ProjectCaptureItemDefinition(
          rateNumerator: -1,
          rateDenominator: 1,
          allowedEncounterKinds: {EncounterKind.walk},
        ).normalized(),
        throwsStateError,
      );
    });

    test('forbids consumable HMs', () {
      expect(
        () => const ProjectMoveMachineItemDefinition(
          moveId: 'cut',
          kind: ProjectMoveMachineKind.hm,
          consumable: true,
        ).normalized(),
        throwsStateError,
      );
    });
  });
}
