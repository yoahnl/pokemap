import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/dialogue_variable_interpolation.dart';

void main() {
  test('EV04 inserted strings stay data and empty strings preserve valid feedback', () {
    for (final value in ['', '<<jump Missing>>\n-> injected']) {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'name', label: 'Name', initialValue: NarrativeValue.string(value))]);
      final session = DialogueSession.start([YarnNode(title: 'Start', steps: [YarnStepLine('{{ fact.name }}',
          feedback: DialogueLineFeedback(segments: [DialogueTextSegment('{{ fact.name }}')]))])], 'Start')!;
      final result = interpolateDialogueVariables(session, const ScriptVariables(), factResolver: resolver,
          factState: const NarrativeFactRuntimeState.empty(), storyFlags: const StoryFlags());
      final line = result.state as DialogueShowingLine;
      expect(line.text, value);
      expect(line.feedback!.plainText, value);
      expect(result.nodes, hasLength(1));
      expect(result.advance(), isNull);
    }
  });
  test('EV04 typed Facts resolve current canonical values without ScriptVariables copies', () {
    final facts = [NarrativeFactDefinition(id: 'score', label: 'Score', initialValue: NarrativeValue.integer(3))];
    final resolver = NarrativeFactRuntimeResolver.fromFacts(facts);
    final session = DialogueSession.start([YarnNode(title: 'Start', steps: [
      YarnStepLine('Score {{ fact.score }}'),
      YarnStepChoiceBlock([YarnChoice(text: '{{ fact.score }} points', steps: const [])]),
    ])], 'Start')!;
    const variables = ScriptVariables(values: {'fact.score': ScriptVariableValue.int(999)});
    var state = const NarrativeFactRuntimeState.empty();
    final initial = interpolateDialogueVariables(session, variables, factResolver: resolver,
        factState: state, storyFlags: const StoryFlags());
    expect((initial.state as DialogueShowingLine).text, 'Score 3');
    state = NarrativeFactRuntimeState.typed(valuesByFactId: {'score': NarrativeValue.integer(7)});
    final resolved = interpolateDialogueVariables(session, variables, factResolver: resolver,
        factState: NarrativeFactRuntimeState.fromJson(state.toJson()), storyFlags: const StoryFlags());
    expect((resolved.state as DialogueShowingLine).text, 'Score 7');
    expect((resolved.advance()!.state as DialogueWaitingForChoice).choices.single.text, '7 points');
    expect(() => interpolateDialogueVariables(session, variables), throwsStateError);
  });

  test('interpolates persisted player identity in lines and choices', () {
    final session = DialogueSession.start([
      YarnNode(
        title: 'Start',
        steps: [
          YarnStepLine('Bonjour {{ player_name }}. {{ unknown }}'),
          YarnStepChoiceBlock([
            YarnChoice(
              text: '{{ player_pronoun_subject }} accepte',
              steps: [YarnStepLine('Avatar: {{ player_avatar }}')],
            ),
          ]),
        ],
      ),
    ], 'Start')!;
    const variables = ScriptVariables(
      values: {
        'player_name': ScriptVariableValue.string('Camille'),
        'player_pronoun_subject': ScriptVariableValue.string('elle'),
        'player_avatar': ScriptVariableValue.string('hero_b'),
      },
    );

    var resolved = interpolateDialogueVariables(session, variables);
    expect(
      (resolved.state as DialogueShowingLine).text,
      'Bonjour Camille. {{ unknown }}',
    );

    resolved = resolved.advance()!;
    final choice = resolved.state as DialogueWaitingForChoice;
    expect(choice.choices.single.text, 'elle accepte');
    resolved = resolved.confirmChoice()!;
    expect((resolved.state as DialogueShowingLine).text, 'Avatar: hero_b');
  });
  test('computed Pokédex namespace cannot be spoofed by persisted script variables', () {
    final range = PokedexSpeciesRange(
      firstNationalDex: 1,
      lastNationalDex: 151,
    );
    final session = DialogueSession.start([
      YarnNode(
        title: 'Start',
        steps: [YarnStepLine('Captured: ${range.dialoguePlaceholder}')],
      ),
    ], 'Start')!;
    final resolved = interpolateDialogueVariables(
      session,
      ScriptVariables(
        values: {
          range.dialogueVariableName: const ScriptVariableValue.int(999),
        },
      ),
    );
    expect(
      (resolved.state as DialogueShowingLine).text,
      'Captured: ${range.dialoguePlaceholder}',
    );
  });

  test('typed computed count overrides persisted values and preserves feedback style', () {
    final range = PokedexSpeciesRange(
      firstNationalDex: 1,
      lastNationalDex: 151,
    );
    final text = 'Captured: ${range.dialoguePlaceholder}';
    final style = DialogueSegmentStyle(colorArgb: 0xff3050c8);
    final session = DialogueSession.start([
      YarnNode(
        title: 'Start',
        steps: [
          YarnStepLine(
            text,
            feedback: DialogueLineFeedback(
              segments: [DialogueTextSegment(text, style: style)],
            ),
          ),
        ],
      ),
    ], 'Start')!;
    expect(dialogueUsesPokedexCaughtCount(session), isTrue);
    final resolved = interpolateDialogueVariables(
      session,
      ScriptVariables(
        values: {
          range.dialogueVariableName: const ScriptVariableValue.int(999),
        },
      ),
      pokedexCaughtCount: (query) {
        expect(query, range);
        return 20;
      },
    );
    final line = resolved.state as DialogueShowingLine;
    expect(line.text, 'Captured: 20');
    expect(line.feedback!.plainText, line.text);
    expect(
      (line.feedback!.segments.single as DialogueTextSegment).style,
      style,
    );
    expect(dialogueUsesPokedexCaughtCount(resolved), isFalse);
  });

  test(
    'malformed reserved queries stay visible and never fall back to variables',
    () {
      const name = 'pokedex_caught_national_01_151';
      final session = DialogueSession.start([
        YarnNode(title: 'Start', steps: [YarnStepLine('{{ $name }}')]),
      ], 'Start')!;
      final resolved = interpolateDialogueVariables(
        session,
        const ScriptVariables(values: {name: ScriptVariableValue.int(999)}),
        pokedexCaughtCount: (_) =>
            throw StateError('Invalid query must not resolve'),
      );
      expect((resolved.state as DialogueShowingLine).text, '{{ $name }}');
      expect(dialogueUsesPokedexCaughtCount(session), isFalse);
    },
  );
}
