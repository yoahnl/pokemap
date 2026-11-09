import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectItemEffectDefinition', () {
    test('legacy PP restoration retains its exact default encoding', () {
      final json = <String, dynamic>{
        'kind': 'restore_pp',
        'mode': 'flat',
        'amount': 10,
      };
      expect(ProjectItemEffectDefinition.fromJson(json).toJson(), json);
    });

    test('all-move PP restoration survives strict catalog serialization', () {
      final json = <String, dynamic>{
        'schemaVersion': 1,
        'entries': [
          {
            'id': 'elixir',
            'displayName': 'Élixir',
            'pocketId': 'medicine',
            'uses': [
              {
                'contexts': ['overworld', 'battle'],
                'target': 'party_member',
                'consumption': 'on_applied',
                'effect': {
                  'kind': 'restore_pp',
                  'mode': 'flat',
                  'amount': 10,
                  'scope': 'all_moves',
                },
              },
            ],
          },
        ],
      };
      final catalog = decodeProjectItemCatalog(json);
      expect(catalog.entries.single.uses.single.effect.toJson()['scope'], 'all_moves');
      expect(decodeProjectItemCatalog(encodeProjectItemCatalog(catalog)), catalog);
      expect(validateProjectItemCatalog(catalog, capabilityTruth: itemSystemV1CapabilityTruth).hasBlockingDiagnostics, isFalse);
    });

    test('PP scope is a closed enum rather than ignored data', () {
      for (final scope in ['unknown', 1, true]) {
        expect(() => ProjectItemEffectDefinition.fromJson({
          'kind': 'restore_pp', 'mode': 'flat', 'amount': 10, 'scope': scope,
        }), throwsA(anything));
      }
    });

    test('round-trips every effect kind', () {
      final effects = <ProjectItemEffectDefinition>[
        const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
        const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.full,
        ),
        const ProjectItemEffectDefinition.cureStatus(
          mode: ProjectItemStatusCureMode.listed,
          statusIds: {'burn', 'poison'},
        ),
        const ProjectItemEffectDefinition.cureStatus(
          mode: ProjectItemStatusCureMode.all,
        ),
        const ProjectItemEffectDefinition.revive(
          rateNumerator: 1,
          rateDenominator: 2,
        ),
        const ProjectItemEffectDefinition.restorePp(
          mode: ProjectItemAmountMode.flat,
          amount: 10,
        ),
        const ProjectItemEffectDefinition.restorePp(
          mode: ProjectItemAmountMode.full,
        ),
        const ProjectItemEffectDefinition.repel(steps: 200),
        const ProjectItemEffectDefinition.semanticAction(
          actionId: 'world.escape',
        ),
      ];

      for (final effect in effects) {
        expect(ProjectItemEffectDefinition.fromJson(effect.toJson()), effect);
      }
    });

    test('enforces amount mode invariants', () {
      expect(
        () => const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
        ).normalized(),
        throwsStateError,
      );
      expect(
        () => const ProjectItemEffectDefinition.restorePp(
          mode: ProjectItemAmountMode.full,
          amount: 10,
        ).normalized(),
        throwsStateError,
      );
    });

    test('enforces status cure mode invariants', () {
      expect(
        () => const ProjectItemEffectDefinition.cureStatus(
          mode: ProjectItemStatusCureMode.listed,
        ).normalized(),
        throwsStateError,
      );
      expect(
        () => const ProjectItemEffectDefinition.cureStatus(
          mode: ProjectItemStatusCureMode.all,
          statusIds: {'burn'},
        ).normalized(),
        throwsStateError,
      );
    });

    test('reduces revive ratios and rejects non-positive ratios', () {
      expect(
        const ProjectItemEffectDefinition.revive(
          rateNumerator: 2,
          rateDenominator: 4,
        ).normalized(),
        const ProjectItemEffectDefinition.revive(
          rateNumerator: 1,
          rateDenominator: 2,
        ),
      );
      expect(
        () => const ProjectItemEffectDefinition.revive(
          rateNumerator: 0,
          rateDenominator: 2,
        ).normalized(),
        throwsStateError,
      );
    });

    test('accepts semantic actions only from the declared registry', () {
      const effect = ProjectItemEffectDefinition.semanticAction(
        actionId: ' world.escape ',
      );
      final normalized = effect.normalized();

      expect(
        normalized.requireDeclaredSemanticAction({'world.escape'}),
        normalized,
      );
      expect(
        () => normalized.requireDeclaredSemanticAction({'world.teleport'}),
        throwsStateError,
      );
    });
  });
}
