import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_model.dart';
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
      expect(session.transcript.whereType<DialoguePreviewChoicePrompt>().length, 1);
      session.choose(0);
      expect(
        session.transcript.whereType<DialoguePreviewLine>().length,
        greaterThan(1),
      );
    });
  });
}
