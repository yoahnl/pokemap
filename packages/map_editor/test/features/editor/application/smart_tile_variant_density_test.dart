import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/smart_tile_variant_density.dart';

ProjectSmartTilePreset _presetWithTwoRules() => const ProjectSmartTilePreset(
      id: 'eau',
      name: 'Eau',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.wangCorner4,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'eau',
      allowedMaterialIds: <String>['eau'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'rule-0',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(id: 'r0-c0', weight: 1000),
            SmartTileCandidate(id: 'r0-c1', weight: 1000),
            SmartTileCandidate(id: 'r0-c2', weight: 1000),
          ],
        ),
        SmartTileRule(
          id: 'rule-1',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(id: 'r1-c0', weight: 1000),
          ],
        ),
      ],
    );

void main() {
  group('normaliseSmartTileVariantWeights', () {
    test('ramène le total à 1000 sans changer les proportions', () {
      final result = normaliseSmartTileVariantWeights(
        <String, int>{'a': 1000, 'b': 1000, 'c': 1000, 'd': 1000},
      );
      expect(
        result.values.reduce((a, b) => a + b),
        kSmartTileVariantWeightTotal,
      );
      expect(result, <String, int>{'a': 250, 'b': 250, 'c': 250, 'd': 250});
    });

    test('répartit le reste au plus fort reste quand la division tombe mal',
        () {
      final result = normaliseSmartTileVariantWeights(
        <String, int>{'a': 1, 'b': 1, 'c': 1},
      );
      expect(
        result.values.reduce((a, b) => a + b),
        kSmartTileVariantWeightTotal,
      );
      expect(result.values.toList()..sort(), <int>[333, 333, 334]);
    });

    test('laisse un poids nul à zéro', () {
      final result = normaliseSmartTileVariantWeights(
        <String, int>{'a': 1000, 'b': 0, 'c': 1000},
      );
      expect(result['b'], 0);
      expect(result['a']! + result['c']!, kSmartTileVariantWeightTotal);
    });
  });

  group('rescaleSmartTileVariantWeights', () {
    test('pose la cible et repartage le reste en conservant les rapports', () {
      final result = rescaleSmartTileVariantWeights(
        weights: <String, int>{
          'eau1': 250,
          'eau2': 250,
          'eau3': 250,
          'roc': 250,
        },
        targetId: 'roc',
        targetPermille: 10,
      );
      expect(result['roc'], 10);
      expect(result['eau1'], result['eau2']);
      expect(result['eau2'], result['eau3']);
      expect(
        result.values.reduce((a, b) => a + b),
        kSmartTileVariantWeightTotal,
      );
    });

    test('une cible à zéro sort de la redistribution', () {
      final result = rescaleSmartTileVariantWeights(
        weights: <String, int>{'a': 500, 'roc': 500},
        targetId: 'roc',
        targetPermille: 0,
      );
      expect(result['roc'], 0);
      expect(result['a'], kSmartTileVariantWeightTotal);
    });

    test('borne la cible pour garder un point à chaque variante vivante', () {
      // 990 est inatteignable : il faut 1 pour mille à chacune des 40 autres
      // variantes positives, sinon « rare » devient « jamais » par arrondi.
      // La cible est donc ramenée à 1000 - 40 = 960.
      final weights = <String, int>{'gros': 1000};
      for (var i = 0; i < 40; i += 1) {
        weights['petit$i'] = 1;
      }
      final result = rescaleSmartTileVariantWeights(
        weights: weights,
        targetId: 'gros',
        targetPermille: 990,
      );
      expect(result['gros'], 960);
      for (var i = 0; i < 40; i += 1) {
        expect(result['petit$i'], 1);
      }
      expect(
        result.values.reduce((a, b) => a + b),
        kSmartTileVariantWeightTotal,
      );
    });

    test('la seule variante positive reste à 1000 quoi qu\'on demande', () {
      // Il n'y a rien pour compenser : baisser l'unique variante vivante
      // casserait la somme sans rendre quoi que ce soit plus fréquent.
      final result = rescaleSmartTileVariantWeights(
        weights: <String, int>{'seul': 1000, 'mort': 0},
        targetId: 'seul',
        targetPermille: 300,
      );
      expect(result['seul'], kSmartTileVariantWeightTotal);
      expect(result['mort'], 0);
    });

    test('refuse une cible hors bornes', () {
      expect(
        () => rescaleSmartTileVariantWeights(
          weights: <String, int>{'a': 1000},
          targetId: 'a',
          targetPermille: 1001,
        ),
        throwsArgumentError,
      );
    });

    test('refuse un identifiant absent', () {
      expect(
        () => rescaleSmartTileVariantWeights(
          weights: <String, int>{'a': 1000},
          targetId: 'inconnu',
          targetPermille: 500,
        ),
        throwsArgumentError,
      );
    });
  });

  group('applySmartTileVariantWeights', () {
    test('réécrit les poids de la règle visée et laisse les autres', () {
      final preset = _presetWithTwoRules();
      final updated = applySmartTileVariantWeights(
        preset: preset,
        ruleId: 'rule-0',
        weights: const <String, int>{'r0-c0': 900, 'r0-c1': 50, 'r0-c2': 50},
      );

      expect(
        updated.rules
            .firstWhere((rule) => rule.id == 'rule-0')
            .candidates
            .map((candidate) => candidate.weight),
        <int>[900, 50, 50],
      );
      expect(
        updated.rules.firstWhere((rule) => rule.id == 'rule-1'),
        preset.rules.firstWhere((rule) => rule.id == 'rule-1'),
      );
    });

    test('laisse intact un candidat absent de la table', () {
      final preset = _presetWithTwoRules();
      final updated = applySmartTileVariantWeights(
        preset: preset,
        ruleId: 'rule-0',
        weights: const <String, int>{'r0-c0': 900},
      );
      expect(
        updated.rules
            .firstWhere((rule) => rule.id == 'rule-0')
            .candidates
            .last
            .weight,
        1000,
      );
    });
  });

  group('smartTileFillRuleOf', () {
    test('retient la règle qui porte le plus de variantes', () {
      expect(smartTileFillRuleOf(_presetWithTwoRules())?.id, 'rule-0');
    });

    test('rend null pour un preset sans règles', () {
      final bare = _presetWithTwoRules().copyWith(
        rules: const <SmartTileRule>[],
      );
      expect(smartTileFillRuleOf(bare), isNull);
    });
  });
}
