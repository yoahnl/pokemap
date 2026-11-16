import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

String literal(String text, {String? speaker}) =>
    '<<line_v1 ${jsonEncode({'text': text, 'speaker': speaker})}>>';

void main() {
  const compiler = YarnDialogueCompiler();

  test('explicit line literals keep exact text, portrait and choice scope', () {
    const body = '(Une réplique : {{ fact.name }}\n<<jump End>>)';
    final document = compiler.compile(
      'title: Start\n---\n'
      '<<portrait hero happy>>\n${literal(body)}\n'
      '-> Oui\n  <<outcome yes>>\n  <<speaker hero>>\n'
      '  ${literal(body, speaker: 'Luth')}\n===\n',
    );
    final steps = document.nodes.single.steps;
    final first = steps.first as RuntimeDialogueLine;
    expect(first.text, body);
    expect(first.characterId, 'hero');
    expect(first.portraitStateId, 'happy');
    final choice = (steps.last as RuntimeDialogueChoiceBlock).choices.single;
    expect(choice.outcomeId, 'yes');
    final branch = choice.steps.single as RuntimeDialogueLine;
    expect(branch.text, 'Luth: $body');
    expect(branch.characterId, 'hero');
    expect(branch.portraitStateId, isNull);
    final codec = const RuntimeDialogueDocumentCodec();
    expect(codec.decodeUtf8(codec.encodeUtf8(document)), document);
  });

  test('historical literals and unknown commands keep their semantics', () {
    final document = compiler.compile(
      'title: Start\n---\n'
      '<<custom legacy>>\n\\"(Le vent souffle.)"\n'
      '\\"Luth: Bonsoir"\n===\n',
    );
    expect(
      document.nodes.single.steps.cast<RuntimeDialogueLine>().map(
        (line) => line.text,
      ),
      ['(Le vent souffle.)', 'Luth: Bonsoir'],
    );
  });

  test(
    'malformed explicit lines report their location instead of being ignored',
    () {
      for (final payload in [
        '{}',
        '[]',
        '{"text":42,"speaker":null}',
        '{"text":"","speaker":null}',
        '{"text":"bonjour","speaker":42}',
        '{"text":"bonjour","speaker":null,"extra":true}',
        '{"text":"bonjour","speaker":null',
      ]) {
        expect(
          () => compiler.compile(
            'title: Start\n---\n'
            'Bonjour\n<<line_v1 $payload>>\n===\n',
          ),
          throwsA(
            isA<YarnDialogueFormatException>().having(
              (error) => error.lineNumber,
              'line',
              4,
            ),
          ),
          reason: payload,
        );
      }
    },
  );
}
