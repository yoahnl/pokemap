import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ScriptCondition progression factories', () {
    test('round-trips typed Fact values without inferring their kind', () {
      final conditions = <ScriptCondition>[
        ScriptConditionFactory.factEquals(
          ' fact.bool ',
          const NarrativeValue.boolean(true),
        ),
        ScriptConditionFactory.factEquals(
          ' fact.int ',
          NarrativeValue.integer(42),
        ),
        ScriptConditionFactory.factEquals(
          ' fact.string.true ',
          const NarrativeValue.string('true'),
        ),
        ScriptConditionFactory.factEquals(
          ' fact.string.number ',
          const NarrativeValue.string('42'),
        ),
      ];

      final restored = conditions
          .map((condition) => ScriptCondition.fromJson(condition.toJson()))
          .toList(growable: false);

      expect(
        restored.map((condition) => condition.params),
        <Map<String, String>>[
          <String, String>{
            ScriptConditionParams.factId: 'fact.bool',
            ScriptConditionParams.valueType: 'bool',
            ScriptConditionParams.value: 'true',
          },
          <String, String>{
            ScriptConditionParams.factId: 'fact.int',
            ScriptConditionParams.valueType: 'int',
            ScriptConditionParams.value: '42',
          },
          <String, String>{
            ScriptConditionParams.factId: 'fact.string.true',
            ScriptConditionParams.valueType: 'string',
            ScriptConditionParams.value: 'true',
          },
          <String, String>{
            ScriptConditionParams.factId: 'fact.string.number',
            ScriptConditionParams.valueType: 'string',
            ScriptConditionParams.value: '42',
          },
        ],
      );
    });

    test('round-trips guided progression conditions', () {
      final conditions = <ScriptCondition>[
        ScriptConditionFactory.stepCompleted(' step.port '),
        ScriptConditionFactory.badgeOwned(' badge.brisants '),
        ScriptConditionFactory.itemQuantityAtLeast(' potion ', 2),
        ScriptConditionFactory.moneyAtLeast(500),
      ];

      final restored = conditions
          .map((condition) => ScriptCondition.fromJson(condition.toJson()))
          .toList(growable: false);

      expect(restored, conditions);
      expect(restored[0].params[ScriptConditionParams.stepId], 'step.port');
      expect(
        restored[1].params[ScriptConditionParams.badgeId],
        'badge.brisants',
      );
      expect(restored[2].params, <String, String>{
        ScriptConditionParams.itemId: 'potion',
        ScriptConditionParams.quantity: '2',
      });
      expect(restored[3].params, <String, String>{
        ScriptConditionParams.amount: '500',
      });
    });

    test('rejects empty references and negative thresholds', () {
      expect(
        () => ScriptConditionFactory.factEquals(
          ' ',
          const NarrativeValue.boolean(true),
        ),
        throwsArgumentError,
      );
      expect(
        () => ScriptConditionFactory.stepCompleted(' '),
        throwsArgumentError,
      );
      expect(
        () => ScriptConditionFactory.badgeOwned(' '),
        throwsArgumentError,
      );
      expect(
        () => ScriptConditionFactory.itemQuantityAtLeast('potion', -1),
        throwsArgumentError,
      );
      expect(
        () => ScriptConditionFactory.moneyAtLeast(-1),
        throwsArgumentError,
      );
    });

    test('project validation accepts valid typed progression conditions', () {
      final condition = ScriptConditionFactory.allOf(<ScriptCondition>[
        ScriptConditionFactory.factEquals(
          'fact.typed',
          const NarrativeValue.string('42'),
        ),
        ScriptConditionFactory.stepCompleted('step.port'),
        ScriptConditionFactory.badgeOwned('badge.port'),
        ScriptConditionFactory.itemQuantityAtLeast('potion', 2),
        ScriptConditionFactory.moneyAtLeast(500),
      ]);

      expect(
        () => ProjectValidator.validate(_projectWithCondition(condition)),
        returnsNormally,
      );
    });

    test('project validation rejects malformed serialized parameters', () {
      final malformed = <ScriptCondition>[
        const ScriptCondition(
          type: ScriptConditionType.factEquals,
          params: <String, String>{
            ScriptConditionParams.factId: 'fact',
            ScriptConditionParams.valueType: 'bool',
            ScriptConditionParams.value: '42',
          },
        ),
        const ScriptCondition(
          type: ScriptConditionType.stepCompleted,
          params: <String, String>{ScriptConditionParams.stepId: ' '},
        ),
        const ScriptCondition(
          type: ScriptConditionType.itemQuantityAtLeast,
          params: <String, String>{
            ScriptConditionParams.itemId: 'potion',
            ScriptConditionParams.quantity: '-1',
          },
        ),
        const ScriptCondition(
          type: ScriptConditionType.moneyAtLeast,
          params: <String, String>{ScriptConditionParams.amount: '0500'},
        ),
      ];

      for (final condition in malformed) {
        expect(
          () => ProjectValidator.validate(_projectWithCondition(condition)),
          throwsA(isA<ValidationException>()),
          reason: condition.type.name,
        );
      }
    });
  });
}

ProjectManifest _projectWithCondition(ScriptCondition condition) {
  return ProjectManifest(
    name: 'Condition validation',
    maps: const <ProjectMapEntry>[],
    tilesets: const [],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'scenario',
        name: 'Scenario',
        entryNodeId: 'start',
        activationCondition: condition,
        nodes: const <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      ),
    ],
  );
}
