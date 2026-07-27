import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/dialogue_variable_interpolation.dart';

void main() {
  test('interpolates persisted player identity in lines and choices', () {
    final session = DialogueSession.start(
      [
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
      ],
      'Start',
    )!;
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
    expect(
      (resolved.state as DialogueShowingLine).text,
      'Avatar: hero_b',
    );
  });
}
