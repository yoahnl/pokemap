import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/dialogue_variable_interpolation.dart';

void main() {
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
