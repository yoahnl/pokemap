import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('validateProjectItemCatalog', () {
    test('marks fully wired items runtime-ready', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            _item(
              id: 'potion',
              use: const ProjectItemUseDefinition(
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
            ),
          ],
        ),
        capabilityTruth: _truth(),
      );

      expect(report.hasBlockingDiagnostics, isFalse);
      expect(
        report.assessmentFor('potion')?.readiness,
        ItemCapabilityReadiness.runtimeReady,
      );
    });

    test('keeps passive and unsupported states distinct', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'key-item',
              displayName: 'Key Item',
              pocketId: '',
              tags: const {'passive'},
            ),
            _item(
              id: 'repel',
              use: const ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.repel(steps: 100),
              ),
            ),
          ],
        ),
        capabilityTruth: _truth(
          supportedEffects: {ProjectItemEffectCapability.healHp},
        ),
      );

      expect(
        report.assessmentFor('key-item'),
        isA<ItemCapabilityAssessment>()
            .having(
              (assessment) => assessment.readiness,
              'readiness',
              ItemCapabilityReadiness.passive,
            )
            .having(
              (assessment) => assessment.presentationPocketId,
              'presentationPocketId',
              'items',
            ),
      );
      expect(
        report.assessmentFor('repel')?.readiness,
        ItemCapabilityReadiness.unsupported,
      );
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          ProjectItemCatalogDiagnosticCode.passiveWithoutPrice,
          ProjectItemCatalogDiagnosticCode.emptyPocketFallback,
          ProjectItemCatalogDiagnosticCode.unsupportedCapability,
        }),
      );
    });

    test('item system V1 rejects unsupported context effect combinations', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: <ProjectItemDefinition>[
            _item(
              id: 'battle-ether',
              use: const ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
                target: ProjectItemTargetKind.partyMove,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.restorePp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 10,
                ),
              ),
            ),
            _item(
              id: 'repel',
              use: const ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{
                  ProjectItemUseContext.overworld,
                },
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.repel(steps: 100),
              ),
            ),
          ],
        ),
        capabilityTruth: itemSystemV1CapabilityTruth,
      );

      expect(report.hasBlockingDiagnostics, isTrue);
      expect(
        report.assessmentFor('battle-ether')?.readiness,
        ItemCapabilityReadiness.unsupported,
      );
      expect(
        report.assessmentFor('repel')?.readiness,
        ItemCapabilityReadiness.unsupported,
      );
      expect(
        report.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code ==
                  ProjectItemCatalogDiagnosticCode.unsupportedCapability,
            )
            .length,
        2,
      );
    });

    test('item system V1 accepts only registered held effects', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: const <ProjectItemDefinition>[
            ProjectItemDefinition(
              id: 'supported-held',
              displayName: 'Supported Held',
              pocketId: 'held',
              heldEffectId: 'leftovers',
            ),
            ProjectItemDefinition(
              id: 'unknown-held',
              displayName: 'Unknown Held',
              pocketId: 'held',
              heldEffectId: 'never_registered_effect',
            ),
          ],
        ),
        capabilityTruth: itemSystemV1CapabilityTruth,
      );

      expect(
        report.assessmentFor('supported-held')?.readiness,
        ItemCapabilityReadiness.runtimeReady,
      );
      expect(
        report.assessmentFor('unknown-held')?.readiness,
        ItemCapabilityReadiness.unsupported,
      );
    });

    test('blocks duplicate item ids and invalid ratios', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            _item(id: 'duplicate'),
            _item(id: ' duplicate '),
            ProjectItemDefinition(
              id: 'broken-ball',
              displayName: 'Broken Ball',
              pocketId: 'balls',
              capture: const ProjectCaptureItemDefinition(
                rateNumerator: 0,
                rateDenominator: 1,
                allowedEncounterKinds: {EncounterKind.walk},
              ),
            ),
          ],
        ),
        capabilityTruth: _truth(),
      );

      expect(report.hasBlockingDiagnostics, isTrue);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          ProjectItemCatalogDiagnosticCode.duplicateItemId,
          ProjectItemCatalogDiagnosticCode.invalidRatio,
        }),
      );
      expect(
        report.assessmentFor('duplicate')?.readiness,
        ItemCapabilityReadiness.unsupported,
      );
      expect(
        report.assessmentFor('broken-ball')?.readiness,
        ItemCapabilityReadiness.unsupported,
      );
    });

    test('blocks incompatible targets and undeclared runtime references', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            _item(
              id: 'wrong-target',
              use: const ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.healHp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 20,
                ),
              ),
            ),
            ProjectItemDefinition(
              id: 'unknown-held',
              displayName: 'Unknown Held',
              pocketId: 'held',
              heldEffectId: 'battle.unknown',
            ),
            ProjectItemDefinition(
              id: 'missing-move',
              displayName: 'Missing Move',
              pocketId: 'machines',
              machine: const ProjectMoveMachineItemDefinition(
                moveId: ' ',
                kind: ProjectMoveMachineKind.tm,
                consumable: true,
              ),
            ),
            _item(
              id: 'unknown-action',
              use: const ProjectItemUseDefinition(
                contexts: {ProjectItemUseContext.overworld},
                target: ProjectItemTargetKind.world,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.semanticAction(
                  actionId: 'world.unknown',
                ),
              ),
            ),
          ],
        ),
        capabilityTruth: _truth(
          supportedSemanticActionIds: {'world.escape'},
          supportedHeldEffectIds: {'battle.leftovers'},
        ),
      );

      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          ProjectItemCatalogDiagnosticCode.incompatibleTarget,
          ProjectItemCatalogDiagnosticCode.unknownHeldEffect,
          ProjectItemCatalogDiagnosticCode.missingMoveId,
          ProjectItemCatalogDiagnosticCode.unknownSemanticAction,
        }),
      );
      for (final itemId in [
        'wrong-target',
        'unknown-held',
        'missing-move',
        'unknown-action',
      ]) {
        expect(
          report.assessmentFor(itemId)?.readiness,
          ItemCapabilityReadiness.unsupported,
        );
      }
    });

    test('reports unconsumed external fields without blocking readiness', () {
      final report = validateProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [_item(id: 'imported-passive', buyPrice: 100)],
        ),
        capabilityTruth: _truth(),
        unconsumedExternalFieldsByItemId: const {
          'imported-passive': {'fling_power', 'generation'},
        },
      );

      expect(report.hasBlockingDiagnostics, isFalse);
      expect(
        report.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code ==
                  ProjectItemCatalogDiagnosticCode.unconsumedExternalField,
            )
            .length,
        2,
      );
      expect(
        report.assessmentFor('imported-passive')?.readiness,
        ItemCapabilityReadiness.passive,
      );
    });
  });

  group('validateProjectItemCatalogJson', () {
    test('maps unknown schema versions and effect kinds to diagnostics', () {
      final unsupportedVersion = validateProjectItemCatalogJson({
        'schemaVersion': 2,
        'entries': <Object?>[],
      }, capabilityTruth: _truth());
      final unknownKind = validateProjectItemCatalogJson({
        'schemaVersion': 1,
        'entries': [
          {
            'id': 'unknown-kind',
            'displayName': 'Unknown Kind',
            'pocketId': 'items',
            'uses': [
              {
                'contexts': ['overworld'],
                'target': 'world',
                'consumption': 'on_applied',
                'effect': {'kind': 'unknown'},
              },
            ],
          },
        ],
      }, capabilityTruth: _truth());

      expect(
        unsupportedVersion.diagnostics.single.code,
        ProjectItemCatalogDiagnosticCode.unsupportedSchemaVersion,
      );
      expect(
        unknownKind.diagnostics.single,
        isA<ProjectItemCatalogDiagnostic>()
            .having(
              (diagnostic) => diagnostic.code,
              'code',
              ProjectItemCatalogDiagnosticCode.unknownKind,
            )
            .having((diagnostic) => diagnostic.entryIndex, 'entryIndex', 0)
            .having(
              (diagnostic) => diagnostic.itemId,
              'itemId',
              'unknown-kind',
            ),
      );
      expect(unsupportedVersion.hasBlockingDiagnostics, isTrue);
      expect(unknownKind.hasBlockingDiagnostics, isTrue);
    });
  });
}

ItemCapabilityTruth _truth({
  Set<ProjectItemEffectCapability> supportedEffects =
      const <ProjectItemEffectCapability>{
        ProjectItemEffectCapability.healHp,
        ProjectItemEffectCapability.cureStatus,
        ProjectItemEffectCapability.revive,
        ProjectItemEffectCapability.restorePp,
        ProjectItemEffectCapability.repel,
        ProjectItemEffectCapability.semanticAction,
      },
  Set<String> supportedSemanticActionIds = const {'world.escape'},
  Set<String> supportedHeldEffectIds = const {'battle.leftovers'},
}) {
  return ItemCapabilityTruth(
    supportedUses: <ItemUseCapability>{
      for (final context in ProjectItemUseContext.values)
        for (final effect in supportedEffects)
          ItemUseCapability(context: context, effect: effect),
    },
    supportedSemanticActionIds: supportedSemanticActionIds,
    supportedHeldEffectIds: supportedHeldEffectIds,
    supportsCapture: true,
    supportsMoveMachines: true,
    presentationPocketFallback: 'items',
  );
}

ProjectItemDefinition _item({
  required String id,
  ProjectItemUseDefinition? use,
  int? buyPrice,
}) {
  return ProjectItemDefinition(
    id: id,
    displayName: id,
    pocketId: 'items',
    buyPrice: buyPrice,
    uses: use == null ? const [] : [use],
  );
}
