import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Runtime dialogue portrait metadata', () {
    test('portrait directive annotates only the next root line', () {
      final document = const YarnDialogueCompiler().compile('''
title: Start
---
<<portrait elia surprised>>
Élia: Attends... tu as vu ça ?
Guide: Continuons.
===
''');

      final lines = document.nodes.single.steps
          .whereType<RuntimeDialogueLine>();
      expect(lines, hasLength(2));
      expect(
        lines.first,
        RuntimeDialogueLine(
          'Élia: Attends... tu as vu ça ?',
          characterId: 'elia',
          portraitStateId: 'surprised',
        ),
      );
      expect(lines.last, RuntimeDialogueLine('Guide: Continuons.'));
    });

    test('portrait directive propagates inside a choice branch', () {
      final document = const YarnDialogueCompiler().compile('''
title: Start
---
-> Regarder
  <<portrait elia surprised>>
  Élia: Là !
-> Partir
  Guide: D'accord.
===
''');

      final choices =
          document.nodes.single.steps.single as RuntimeDialogueChoiceBlock;
      expect(
        choices.choices.first.steps.single,
        RuntimeDialogueLine(
          'Élia: Là !',
          characterId: 'elia',
          portraitStateId: 'surprised',
        ),
      );
      expect(
        choices.choices.last.steps.single,
        RuntimeDialogueLine("Guide: D'accord."),
      );
    });

    test('legacy format remains readable and byte stable', () {
      final bytes = utf8.encode(
        '{"format":1,"nodes":[{"steps":[{"kind":"line","text":"Guide: Bonjour."}],"title":"Start"}]}',
      );

      final document = const RuntimeDialogueDocumentCodec().decodeUtf8(bytes);

      expect(document.version, 1);
      expect(
        document.nodes.single.steps.single,
        RuntimeDialogueLine('Guide: Bonjour.'),
      );
      expect(const RuntimeDialogueDocumentCodec().encodeUtf8(document), bytes);
    });

    test('structured metadata round-trips through the runtime codec', () {
      final document = RuntimeDialogueDocument(
        nodes: <RuntimeDialogueNode>[
          RuntimeDialogueNode(
            title: 'Start',
            steps: <RuntimeDialogueStep>[
              RuntimeDialogueLine(
                'Élia: Surprise !',
                characterId: 'elia',
                portraitStateId: 'surprised',
              ),
            ],
          ),
        ],
      );

      final codec = const RuntimeDialogueDocumentCodec();
      final decoded = codec.decodeUtf8(codec.encodeUtf8(document));

      expect(decoded, document);
      expect(document.nodes.single.steps.single.toJson(), <String, Object?>{
        'kind': 'line',
        'text': 'Élia: Surprise !',
        'characterId': 'elia',
        'portraitStateId': 'surprised',
      });
    });

    test('invalid or dangling portrait directive reports its source line', () {
      expect(
        () => const YarnDialogueCompiler().compile('''
title: Start
---
<<portrait elia>>
Élia: Oups.
===
'''),
        throwsA(
          isA<YarnDialogueFormatException>()
              .having((error) => error.lineNumber, 'lineNumber', 3)
              .having(
                (error) => error.message,
                'message',
                contains('portrait'),
              ),
        ),
      );
      expect(
        () => const YarnDialogueCompiler().compile('''
title: Start
---
<<portrait elia surprised>>
===
'''),
        throwsA(
          isA<YarnDialogueFormatException>().having(
            (error) => error.lineNumber,
            'lineNumber',
            3,
          ),
        ),
      );
    });
  });
}
