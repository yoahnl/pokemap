import 'dart:convert';

import 'package:map_core/src/models/battle_recipe_json.dart';
import 'package:test/test.dart';

void main() {
  Object? decode(String text, {int depth = 8}) => decodeBoundedBattleJson(
    utf8.encode(text),
    maxDepth: depth,
    label: 'Test',
  );

  test('rejects duplicate keys even when their escapes differ', () {
    expect(() => decode(r'{"id":1,"\u0069d":2}'), throwsFormatException);
    expect(() => decode(r'{"x":[{"a":1,"a":2}]}'), throwsFormatException);
  });

  test(
    'allows the same key in different objects and escaped string values',
    () {
      expect(
        decode(r'{"a":{"id":1},"b":[{"id":2}],"value":"id,\\\"id\\\""}'),
        isA<Map>(),
      );
    },
  );

  test('still rejects excessive nesting and malformed UTF-8', () {
    expect(() => decode('{"a":[{}]}', depth: 2), throwsFormatException);
    expect(
      () => decodeBoundedBattleJson([0xff], maxDepth: 4, label: 'Test'),
      throwsFormatException,
    );
    expect(
      () => decodeBoundedBattleJson(
        [0xef, 0xbb, 0xbf, ...utf8.encode('{}')],
        maxDepth: 4,
        label: 'Test',
      ),
      throwsFormatException,
    );
  });

  test('checks integer tokens only for the selected root schema', () {
    Object? decodeVersioned(String text) => decodeBoundedBattleJson(
      utf8.encode(text),
      maxDepth: 8,
      label: 'Test',
      integerNumbersOnlyForSchemaVersion: 2,
    );

    final text = jsonEncode({
      'schemaVersion': 2,
      'values': [0, -1, 1],
      'unicode': 'Pokémon 🔥 1.0 1e0 "quoted" \\u0031.0',
      'nested': {
        '1e0': ['1.0', '2e0'],
      },
    });
    expect(decodeVersioned(text), isA<Map>());
    for (final token in ['1.0', '1e0', '1E+0', '-0.0']) {
      expect(
        () => decodeVersioned('{"schemaVersion":2,"values":[$token]}'),
        throwsFormatException,
        reason: token,
      );
    }
    for (final version in ['2.0', '2e0']) {
      expect(
        () => decodeVersioned('{"schemaVersion":$version,"value":1}'),
        throwsFormatException,
        reason: version,
      );
    }
    expect(decodeVersioned('{"schemaVersion":1,"value":1.0}'), isA<Map>());
    expect(decodeVersioned('{"schemaVersion":1,"value":1e0}'), isA<Map>());
    for (final invalid in [
      '{"schemaVersion":2,"value":01}',
      '{"schemaVersion":2,"value":1e}',
      r'{"schemaVersion":2,"id":1,"\u0069d":2}',
    ]) {
      expect(() => decodeVersioned(invalid), throwsFormatException);
    }
  });
}
