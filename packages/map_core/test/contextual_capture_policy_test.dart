import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> policyJson() => {
  'policyId': 'pokemap-contextual-capture-v1',
  'rateRules': [
    {
      'when': {
        'kind': 'numeric',
        'left': {'field': 'targetBaseSpeed'},
        'comparison': 'greaterThanOrEqual',
        'right': {'literal': 100},
      },
      'adjustment': {'kind': 'multiply', 'numerator': 4, 'denominator': 1},
    },
  ],
  'successEffects': [
    {'kind': 'setFriendship', 'value': 200},
  ],
};

Map<String, dynamic> catalogJson({bool contextual = true}) => {
  'schemaVersion': 1,
  'entries': [
    {
      'id': 'synthetic-orb',
      'displayName': 'Synthetic Orb',
      'pocketId': 'balls',
      'capture': {
        'rateNumerator': 1,
        'rateDenominator': 1,
        'allowedEncounterKinds': ['walk'],
        if (contextual) 'contextualPolicy': policyJson(),
      },
    },
  ],
};

void main() {
  test('runtime truth admits contextual rules only for the explicit profile', () {
    for (final profile in [PokemonRulesetProfile.pokeMapBetaV1, PokemonRulesetProfile.standardV1, PokemonRulesetProfile.contextualV1]) {
      final report = validateProjectItemCatalog(decodeProjectItemCatalog(catalogJson()),
        capabilityTruth: itemCapabilityTruthForRuleset(profile));
      expect(report.hasBlockingDiagnostics, profile != PokemonRulesetProfile.contextualV1);
    }
  });
  test('contextual policy survives the strict item catalog boundary', () {
    final source = catalogJson();
    final result = decodeProjectItemCatalog(source);
    final encoded = encodeProjectItemCatalog(result);
    final entry = (encoded['entries'] as List).single as Map;
    expect((entry['capture'] as Map)['contextualPolicy'], policyJson());
    expect(decodeProjectItemCatalog(encoded), result);
  });

  test('legacy item and ruleset JSON remain unchanged and have no opt-in', () {
    final legacy = decodeProjectItemCatalog(catalogJson(contextual: false));
    final encoded = encodeProjectItemCatalog(legacy);
    final reread = decodeProjectItemCatalog(jsonDecode(jsonEncode(encoded)));
    expect(encodeProjectItemCatalog(reread), encoded);
    final capture =
        ((encoded['entries'] as List).single as Map)['capture'] as Map;
    expect(capture.containsKey('contextualPolicy'), isFalse);
    final profile = PokemonRulesetProfile.standardV1;
    expect(PokemonRulesetProfile.fromJson(profile.toJson()), profile);
    expect(profile.capturePolicyId, 'pokemap-capture-mvp-v1');
  });

  test(
    'existing runtime truth refuses contextual items rather than flattening',
    () {
      final catalog = decodeProjectItemCatalog(catalogJson());
      final report = validateProjectItemCatalog(
        catalog,
        capabilityTruth: itemSystemV1CapabilityTruth,
      );
      expect(report.hasBlockingDiagnostics, isTrue);
      expect(
        report.assessmentFor('synthetic-orb')!.readiness,
        ItemCapabilityReadiness.unsupported,
      );
    },
  );
  test(
    'algorithm capability accepts any valid definition with synthetic identities',
    () {
      final report = validateProjectItemCatalog(
        decodeProjectItemCatalog(catalogJson()),
        capabilityTruth: ItemCapabilityTruth(
          supportsCapture: true,
          supportedContextualCapturePolicyIds: {
            ProjectContextualCapturePolicy.algorithmId,
          },
        ),
      );
      expect(report.hasBlockingDiagnostics, isFalse);
    },
  );

  test('strict policy codecs reject unknown and malformed semantics', () {
    final invalidPolicies = <Map<String, dynamic>>[
      {...policyJson(), 'policyId': 'future-capture-v2'},
      {...policyJson(), 'expression': 'target.speed >= 100'},
      {...policyJson(), 'rateRules': null},
      {
        ...policyJson(),
        'successEffects': [
          {'kind': 'setFriendship', 'value': 256},
        ],
      },
      {
        ...policyJson(),
        'successEffects': [
          {'kind': 'unknown', 'value': 1},
        ],
      },
      {
        ...policyJson(),
        'successEffects': [
          {'kind': 'setFriendship', 'value': 1},
          {'kind': 'setFriendship', 'value': 2},
        ],
      },
    ];
    for (final policy in invalidPolicies) {
      expect(
        () => ProjectContextualCapturePolicy.fromJson(policy),
        throwsA(anything),
      );
    }
    final invalidConditions = <Map<String, dynamic>>[
      {
        'kind': 'numeric',
        'left': {'literal': 1.5},
        'comparison': 'equal',
        'right': {'literal': 1},
      },
      {
        'kind': 'numeric',
        'left': {'field': 'unknown'},
        'comparison': 'equal',
        'right': {'literal': 1},
      },
      {
        'kind': 'numeric',
        'left': {'field': 'attackerLevel', 'divisor': 0},
        'comparison': 'equal',
        'right': {'literal': 1},
      },
      {
        'kind': 'numeric',
        'left': {'field': 'attackerLevel', 'literal': 1},
        'comparison': 'equal',
        'right': {'literal': 1},
      },
      {'kind': 'all', 'conditions': []},
      {
        'kind': 'match',
        'field': 'targetSpecies',
        'values': ['a', 'a'],
      },
      {
        'kind': 'match',
        'field': 'targetSpecies',
        'values': [' a'],
      },
      {
        'kind': 'match',
        'field': 'encounterOrigin',
        'values': ['invented'],
      },
      {'kind': 'relation', 'relation': 'differentSex', 'ignored': true},
      {'kind': 'expression', 'value': 'true'},
    ];
    for (final condition in invalidConditions) {
      expect(
        () => ProjectCaptureCondition.fromJson(condition),
        throwsA(anything),
      );
    }
    for (final adjustment in [
      {'kind': 'multiply', 'numerator': 4, 'denominator': 0},
      {'kind': 'multiply', 'numerator': 0, 'denominator': 1},
      {'kind': 'add', 'amount': -65536},
      {'kind': 'add', 'amount': 1, 'ignored': true},
    ]) {
      expect(
        () => ProjectCaptureRateAdjustment.fromJson(adjustment),
        throwsA(anything),
      );
    }
  });

  test(
    'conditions, rules and success effects are deeply immutable and bounded',
    () {
      final values = <String>{'synthetic-species'};
      final condition = ProjectCaptureMatchCondition(
        field: ProjectCaptureMatchField.targetSpecies,
        values: values,
      );
      values.clear();
      expect(condition.values, {'synthetic-species'});
      expect(() => condition.values.clear(), throwsUnsupportedError);
      final rules = <ProjectCaptureRateRule>[
        ProjectCaptureRateRule(
          when: condition,
          adjustment: ProjectCaptureRateAdd(-20),
        ),
      ];
      final effects = <ProjectCaptureSuccessEffect>[
        ProjectCaptureSetFriendship(200),
      ];
      final policy = ProjectContextualCapturePolicy(
        rateRules: rules,
        successEffects: effects,
      );
      rules.clear();
      effects.clear();
      expect(policy.rateRules, hasLength(1));
      expect(policy.successEffects, hasLength(1));
      expect(() => policy.rateRules.clear(), throwsUnsupportedError);
      expect(
        ProjectContextualCapturePolicy.fromJson(policy.toJson()).toJson(),
        policy.toJson(),
      );
      var nested = <String, dynamic>{'kind': 'always'};
      for (var depth = 0; depth < 9; depth++) {
        nested = {
          'kind': 'all',
          'conditions': [nested],
        };
      }
      expect(() => ProjectCaptureCondition.fromJson(nested), throwsA(anything));
    },
  );
}
