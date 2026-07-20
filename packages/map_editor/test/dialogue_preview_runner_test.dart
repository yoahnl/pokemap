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

    test('evaluates true and false conditions from controlled initial state',
        () {
      const yarn = r'''
title: Start
---
<<if $has_pass>>
Guide: Passage autorisé.
<<else>>
Guide: Passage refusé.
<<endif>>
===
''';

      final allowed = DialoguePreviewSession(
        parseYarnToDocument(yarn),
        initialState: const {'has_pass': true},
      );
      final refused = DialoguePreviewSession(
        parseYarnToDocument(yarn),
        initialState: const {'has_pass': false},
      );

      expect(
        allowed.transcript.whereType<DialoguePreviewLine>().single.displayText,
        'Guide: Passage autorisé.',
      );
      expect(
        refused.transcript.whereType<DialoguePreviewLine>().single.displayText,
        'Guide: Passage refusé.',
      );
      expect(
        allowed.transcript.whereType<DialoguePreviewTrace>().first.kind,
        DialoguePreviewTraceKind.condition,
      );
    });

    test('applies supported set commands and traces resulting state', () {
      const yarn = r'''
title: Start
---
<<set $coins to 200>>
<<if $coins == 200>>
Guide: Bourse prête.
<<endif>>
===
''';

      final session = DialoguePreviewSession(parseYarnToDocument(yarn));

      expect(session.state['coins'], 200);
      expect(
        session.transcript.whereType<DialoguePreviewLine>().single.displayText,
        'Guide: Bourse prête.',
      );
      expect(
        session.transcript
            .whereType<DialoguePreviewTrace>()
            .where((trace) => trace.kind == DialoguePreviewTraceKind.command),
        hasLength(1),
      );
    });

    test('halts honestly on an unsupported command', () {
      const yarn = '''
title: Start
---
<<open_shop selbrume_market>>
Guide: Cette ligne ne doit pas être atteinte.
===
''';

      final session = DialoguePreviewSession(parseYarnToDocument(yarn));

      expect(session.transcript.whereType<DialoguePreviewLine>(), isEmpty);
      expect(
        session.transcript.whereType<DialoguePreviewTrace>().single.kind,
        DialoguePreviewTraceKind.unsupported,
      );
      expect(
        session.transcript.whereType<DialoguePreviewEnded>().single.reason,
        contains('non supportée'),
      );
    });
  });
}
