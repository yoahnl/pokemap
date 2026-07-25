import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('RuntimeDialogueDocument', () {
    test('compiles the supported Yarn subset into deterministic data-only JSON',
        () {
      const source = '''
title: Start
---
Guide: Bienvenue.
-> Explorer
  <<outcome explore>>
  Allons-y.
  <<jump End>>
-> Rester
  <<outcome stay>>
  À bientôt.
===
title: End
---
Fin.
===
''';

      final document = const YarnDialogueCompiler().compile(source);
      final bytes = const RuntimeDialogueDocumentCodec().encodeUtf8(document);
      final decoded = const RuntimeDialogueDocumentCodec().decodeUtf8(bytes);

      expect(decoded, document);
      expect(document.version, 1);
      expect(document.nodes.map((node) => node.title), <String>[
        'Start',
        'End',
      ]);
      final choices =
          document.nodes.first.steps[1] as RuntimeDialogueChoiceBlock;
      expect(choices.choices.map((choice) => choice.outcomeId), <String?>[
        'explore',
        'stay',
      ]);
      expect(
        utf8.decode(bytes),
        canonicalizeNarrativeEventJson(document.toJson()),
      );
      expect(
        const RuntimeDialogueDocumentCodec().encodeUtf8(decoded),
        bytes,
      );
    });

    test('rejects unknown fields and invalid jump targets', () {
      expect(
        () => const RuntimeDialogueDocumentCodec().decodeJson(
          <String, Object?>{
            'format': 1,
            'nodes': <Object?>[
              <String, Object?>{
                'title': 'Start',
                'steps': <Object?>[],
                'widget': 'arbitrary-code',
              },
            ],
          },
        ),
        throwsFormatException,
      );

      expect(
        () => const RuntimeDialogueDocumentCodec().decodeJson(
          <String, Object?>{
            'format': 1,
            'nodes': <Object?>[
              <String, Object?>{
                'title': 'Start',
                'steps': <Object?>[
                  <String, Object?>{
                    'kind': 'jump',
                    'targetNode': 'Missing',
                  },
                ],
              },
            ],
          },
        ),
        throwsFormatException,
      );

      expect(
        () => const RuntimeDialogueDocumentCodec().decodeUtf8(
          utf8.encode('{"format":1,"format":1,"nodes":[]}'),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate node titles and empty documents', () {
      expect(
        () => const RuntimeDialogueDocumentCodec().decodeJson(
          <String, Object?>{'format': 1, 'nodes': <Object?>[]},
        ),
        throwsFormatException,
      );
      expect(
        () => const YarnDialogueCompiler().compile('''
title: Same
---
One.
===
title: Same
---
Two.
===
'''),
        throwsFormatException,
      );
    });

    test('preserves legacy choices that complete without a nested step', () {
      final document = const YarnDialogueCompiler().compile('''
title: Confirm
---
-> Oui
-> Non
===
''');

      final choices =
          document.nodes.single.steps.single as RuntimeDialogueChoiceBlock;
      expect(choices.choices, hasLength(2));
      expect(choices.choices.every((choice) => choice.steps.isEmpty), isTrue);
      expect(
        const RuntimeDialogueDocumentCodec().decodeUtf8(
          const RuntimeDialogueDocumentCodec().encodeUtf8(document),
        ),
        document,
      );
    });
  });
}
