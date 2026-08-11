import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const evaluator = ScriptConditionEvaluator();

  GameState state({
    List<String> completedStepIds = const <String>[],
    List<String> badgeIds = const <String>[],
    List<BagEntry> bagEntries = const <BagEntry>[],
    int money = 0,
    NarrativeFactRuntimeState narrativeFacts =
        const NarrativeFactRuntimeState.empty(),
  }) =>
      GameState(
        saveId: 'script-condition-evaluator',
        progression: PlayerProgression(
          completedStepIds: completedStepIds,
        ),
        trainerProfile: TrainerProfile(
          name: 'Karim',
          badgeIds: badgeIds,
          money: money,
        ),
        bag: Bag(entries: bagEntries),
        narrativeFactRuntimeState: narrativeFacts,
      );

  group('ScriptConditionEvaluator progression sources', () {
    test('stepCompleted reads completed Story Steps', () {
      final condition = ScriptConditionFactory.stepCompleted('step_lysa');

      expect(
        evaluator.evaluate(
          condition,
          state(completedStepIds: const <String>['step_lysa']),
        ),
        isTrue,
      );
      expect(evaluator.evaluate(condition, state()), isFalse);
    });

    test('badgeOwned reads the trainer profile', () {
      final condition = ScriptConditionFactory.badgeOwned('badge_brisants');

      expect(
        evaluator.evaluate(
          condition,
          state(badgeIds: const <String>['badge_brisants']),
        ),
        isTrue,
      );
      expect(evaluator.evaluate(condition, state()), isFalse);
    });

    test('itemQuantityAtLeast reads and aggregates bag entries', () {
      final condition = ScriptConditionFactory.itemQuantityAtLeast('potion', 2);

      expect(
        evaluator.evaluate(
          condition,
          state(
            bagEntries: const <BagEntry>[
              BagEntry(
                itemId: 'potion',
                quantity: 1,
              ),
              BagEntry(
                itemId: 'potion',
                quantity: 1,
              ),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          condition,
          state(
            bagEntries: const <BagEntry>[
              BagEntry(
                itemId: 'potion',
                quantity: 1,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('moneyAtLeast reads the trainer money', () {
      final condition = ScriptConditionFactory.moneyAtLeast(500);

      expect(evaluator.evaluate(condition, state(money: 500)), isTrue);
      expect(evaluator.evaluate(condition, state(money: 499)), isFalse);
    });

    test('factEquals reads the authored default and runtime override', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts(
        <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'fact_lysa_defeated',
            label: 'Lysa vaincue',
            initialValue: const NarrativeValue.boolean(true),
          ),
        ],
      );
      final context = ScriptEvaluationContext(
        narrativeFactResolver: resolver,
      );
      final condition = ScriptConditionFactory.factEquals(
        'fact_lysa_defeated',
        const NarrativeValue.boolean(true),
      );

      expect(
        evaluator.evaluate(condition, state(), context: context),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          condition,
          state(
            narrativeFacts: NarrativeFactRuntimeState.typed(
              valuesByFactId: const <String, NarrativeValue>{
                'fact_lysa_defeated': NarrativeValue.boolean(false),
              },
            ),
          ),
          context: context,
        ),
        isFalse,
      );
    });

    test('factEquals fails closed for missing or malformed Fact context', () {
      final condition = ScriptConditionFactory.factEquals(
        'fact_lysa_defeated',
        const NarrativeValue.boolean(true),
      );
      const malformed = ScriptCondition(
        type: ScriptConditionType.factEquals,
        params: <String, String>{
          ScriptConditionParams.factId: 'fact_lysa_defeated',
          ScriptConditionParams.valueType: 'int',
          ScriptConditionParams.value: 'not-an-int',
        },
      );

      expect(evaluator.evaluate(condition, state()), isFalse);
      expect(
        evaluator.evaluate(
          malformed,
          state(),
          context: ScriptEvaluationContext(
            narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
              <NarrativeFactDefinition>[
                NarrativeFactDefinition(
                  id: 'fact_lysa_defeated',
                  label: 'Lysa vaincue',
                ),
              ],
            ),
          ),
        ),
        isFalse,
      );
    });
  });
}
