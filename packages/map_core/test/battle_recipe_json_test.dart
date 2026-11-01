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
}
