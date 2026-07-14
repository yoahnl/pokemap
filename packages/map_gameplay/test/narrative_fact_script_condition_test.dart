import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const evaluator = ScriptConditionEvaluator();

  group('Narrative Fact ScriptCondition context', () {
    test('uses canonical override alias and default precedence', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_false',
          label: 'False',
        ),
        NarrativeFactDefinition(
          id: 'fact_true',
          label: 'True',
          defaultValue: true,
        ),
        NarrativeFactDefinition(
          id: 'fact_alias',
          label: 'Alias',
          legacyFlagName: 'legacy_alias',
        ),
        NarrativeFactDefinition(
          id: 'fact_override_false',
          label: 'Override false',
          defaultValue: true,
          legacyFlagName: 'legacy_override_false',
        ),
        NarrativeFactDefinition(
          id: 'fact_override_true',
          label: 'Override true',
        ),
      ]);
      final context = ScriptEvaluationContext(
        narrativeFactResolver: resolver,
      );
      final state = GameState(
        saveId: 'script_fact_matrix',
        storyFlags: const StoryFlags(
          activeFlags: {'legacy_alias', 'legacy_override_false'},
        ),
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_override_false': false,
            'fact_override_true': true,
          },
        ),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_false'),
          state,
          context: context,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_true'),
          state,
          context: context,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_alias'),
          state,
          context: context,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_override_false'),
          state,
          context: context,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsUnset('fact_override_false'),
          state,
          context: context,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_override_true'),
          state,
          context: context,
        ),
        isTrue,
      );
    });

    test('keeps raw flag behavior without a canonical context', () {
      final state = GameState(
        saveId: 'script_fact_raw',
        storyFlags: const StoryFlags(activeFlags: {'raw_flag'}),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('raw_flag'),
          state,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_default_true'),
          state,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsUnset('fact_default_true'),
          state,
        ),
        isTrue,
      );
    });

    test('falls back to raw behavior for an unknown contextual reference', () {
      final context = ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
      );
      const state = GameState(
        saveId: 'script_fact_unknown',
        storyFlags: StoryFlags(activeFlags: {'raw_flag'}),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('raw_flag'),
          state,
          context: context,
        ),
        isTrue,
      );
    });

    test('fails closed for an ambiguous canonical catalog', () {
      final context = ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
          NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
          NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
        ]),
      );
      const state = GameState(
        saveId: 'script_fact_ambiguous',
        storyFlags: StoryFlags(activeFlags: {'fact_dup'}),
      );

      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsSet('fact_dup'),
          state,
          context: context,
        ),
        isFalse,
      );
      expect(
        evaluator.evaluate(
          ScriptConditionFactory.flagIsUnset('fact_dup'),
          state,
          context: context,
        ),
        isFalse,
      );
    });
  });
}
