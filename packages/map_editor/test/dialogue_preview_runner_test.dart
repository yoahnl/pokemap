import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_preview_runner.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_yarn_codec.dart';

void main() {
  group('Dialogue preview runner', () {
    test('shows line then choice', () {
      const yarn = '''
title: Start
---
hero: Hi
-> Yes
  <<jump Next>>
-> No
  <<jump Next>>
===
title: Next
---
prof: Bye
===
''';
      final doc = parseYarnToDocument(yarn);
      final session = DialoguePreviewSession(doc);
      expect(session.transcript.whereType<DialoguePreviewLine>().length, 1);
      expect(session.transcript.whereType<DialoguePreviewChoicePrompt>().length,
          1);
      session.choose(0);
      expect(
        session.transcript.whereType<DialoguePreviewLine>().length,
        greaterThan(1),
      );
    });

    test('exposes the stable outcome selected by the preview player', () {
      const yarn = '''
title: Start
---
-> Répondre avec assurance
  <<outcome confident>>
  Joueur: Je peux aider.
  <<jump Next>>
-> Rester prudent
  <<outcome hesitant>>
  Joueur: Je dois réfléchir.
===
title: Next
---
Lysa: Très bien.
===
''';

      final session = DialoguePreviewSession(parseYarnToDocument(yarn));
      expect(session.selectedOutcomeId, isNull);

      session.choose(0);

      expect(session.selectedOutcomeId, 'confident');
      expect(
        session.transcript.whereType<DialoguePreviewEnded>().last.outcomeId,
        'confident',
      );
    });
  });
}
