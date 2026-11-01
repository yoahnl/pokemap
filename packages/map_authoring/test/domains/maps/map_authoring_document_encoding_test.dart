import 'dart:convert';

import 'package:map_authoring/src/domains/maps/map_lifecycle_adapter.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('map bytes retain two-space indentation and insertion order', () {
    final map = _map(properties: {
      'zeta': 1,
      'alpha': 2,
      'nested': {'β': true, 'a': null},
      'emptyMap': <String, Object?>{},
      'emptyList': <Object?>[],
    });
    final bytes = encodeMapAuthoringDocument(map);
    expect(bytes, _legacyBytes(map));
    expect(utf8.decode(bytes), contains('''"properties": {
    "zeta": 1,
    "alpha": 2,
    "nested": {
      "β": true,
      "a": null
    },
    "emptyMap": {},
    "emptyList": []
  }'''));
    expect(bytes.last, 125);
    expect(
        MapData.fromJson(
            jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>),
        map);
  });

  final strings = <String, String>{
    'ASCII': 'a/z A-Z 0123',
    'Unicode': 'été 灯 😀 𝄞',
    'surrogate-pair': '\ud83d\ude00',
    'lone-high-surrogate': '\ud800',
    'lone-low-surrogate': '\udc00',
    'embedded-lone-surrogates': 'a\ud800b\udc00c',
    'control-characters': '\u0000\u0001\b\f\n\r\t\u001f"\\',
    'line-separators': '\u2028\u2029\u007f',
  };
  for (final entry in strings.entries) {
    test('map bytes retain ${entry.key} encoding', () {
      final map = _map(name: entry.value, properties: {
        'text': entry.value,
        entry.value: [entry.value]
      });
      expect(encodeMapAuthoringDocument(map), _legacyBytes(map));
    });
  }

  final numbers = <String, num>{
    'negative-zero': -0.0,
    'zero': 0,
    'integral-double': 1.0,
    'negative-int': -17,
    'large-int': 9223372036854775807,
    'small-int': -9223372036854775808,
    'large-double': 1.7976931348623157e308,
    'small-double': 5e-324,
    'large-exponent': 1e200,
    'small-exponent': 1e-200,
  };
  for (final entry in numbers.entries) {
    test('map bytes retain ${entry.key} spelling', () {
      final map = _map(properties: {'number': entry.value});
      expect(encodeMapAuthoringDocument(map), _legacyBytes(map));
    });
  }

  test('large nested map properties keep their canonical byte sequence', () {
    final map = _map(properties: {
      'rows': [
        for (var i = 0; i < 1024; i++)
          {
            'id': i,
            'value': 'été 灯 😀',
            'enabled': i.isEven,
            'values': [i, -i, i / 7, null]
          }
      ],
    });
    expect(encodeMapAuthoringDocument(map), _legacyBytes(map));
  });

  test('default toEncodable converts a value exactly once per encoder', () {
    final value = _JsonValue(() => {
          'é': ['灯😀', -0.0]
        });
    final map = _map(properties: {'value': value});
    final expected = _legacyBytes(map);
    expect(value.calls, 1);
    value.calls = 0;
    expect(encodeMapAuthoringDocument(map), expected);
    expect(value.calls, 1);
  });

  for (final entry in <String, Object>{
    'plain-object': Object(),
    'big-int': BigInt.from(17),
    'NaN': double.nan,
    'positive-infinity': double.infinity,
    'negative-infinity': double.negativeInfinity,
    'non-string-map-key': <Object, Object>{17: 'bad'},
  }.entries) {
    test(
        'map encoding preserves ${entry.key} rejection identity and diagnostics',
        () {
      final map = _map(properties: {'prefix': 'été', 'bad': entry.value});
      _sameRejection(map);
    });
  }

  for (final kind in ['list', 'map', 'indirect']) {
    test('map encoding rejects a $kind cycle with the same offending object',
        () {
      final list = <Object?>[];
      final nested = <String, Object?>{};
      switch (kind) {
        case 'list':
          list.add(list);
        case 'map':
          nested['self'] = nested;
        case 'indirect':
          list.add(nested);
          nested['list'] = list;
      }
      final map = _map(properties: {'cycle': kind == 'map' ? nested : list});
      final error = _sameRejection(map);
      expect(error, isA<JsonCyclicError>());
    });
  }

  test(
      'throwing default toEncodable preserves the original cause without retry',
      () {
    final cause = StateError('encoding sentinel');
    final value = _JsonValue(() => throw cause);
    final map = _map(properties: {'value': value});
    final expected = _rejection(() => _legacyBytes(map));
    expect(value.calls, 1);
    value.calls = 0;
    final actual = _rejection(() => encodeMapAuthoringDocument(map));
    expect(value.calls, 1);
    expect(actual.runtimeType, expected.runtimeType);
    expect(actual.unsupportedObject, same(value));
    expect(actual.cause, same(cause));
    expect(actual.toString(), expected.toString());
  });

  test('non-JSON toEncodable result remains rejected without retry', () {
    final unsupported = Object();
    final value = _JsonValue(() => unsupported);
    final map = _map(properties: {'value': value});
    final expected = _rejection(() => _legacyBytes(map));
    expect(value.calls, 1);
    value.calls = 0;
    final actual = _rejection(() => encodeMapAuthoringDocument(map));
    expect(value.calls, 1);
    expect(actual.runtimeType, expected.runtimeType);
    expect(actual.unsupportedObject, same(expected.unsupportedObject));
    _sameCause(actual.cause, expected.cause);
    expect(actual.toString(), expected.toString());
  });
}

MapData _map(
        {String name = 'Encoding',
        Map<String, dynamic> properties = const {}}) =>
    MapData(
        id: 'encoding',
        name: name,
        size: const GridSize(width: 2, height: 2),
        properties: properties);

List<int> _legacyBytes(MapData map) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(map.toJson()));

JsonUnsupportedObjectError _rejection(void Function() encode) {
  try {
    encode();
  } on JsonUnsupportedObjectError catch (error) {
    return error;
  }
  throw StateError('Expected JSON rejection.');
}

JsonUnsupportedObjectError _sameRejection(MapData map) {
  final expected = _rejection(() => _legacyBytes(map));
  final actual = _rejection(() => encodeMapAuthoringDocument(map));
  expect(actual.runtimeType, expected.runtimeType);
  expect(actual.unsupportedObject, same(expected.unsupportedObject));
  expect(actual.cause.runtimeType, expected.cause.runtimeType);
  expect(actual.cause?.toString(), expected.cause?.toString());
  expect(actual.toString(), expected.toString());
  return actual;
}

void _sameCause(Object? actual, Object? expected) {
  expect(actual.runtimeType, expected.runtimeType);
  if (actual is JsonUnsupportedObjectError &&
      expected is JsonUnsupportedObjectError) {
    expect(actual.unsupportedObject, same(expected.unsupportedObject));
    expect(actual.toString(), expected.toString());
    _sameCause(actual.cause, expected.cause);
  } else {
    expect(actual?.toString(), expected?.toString());
  }
}

final class _JsonValue {
  _JsonValue(this.convert);
  final Object? Function() convert;
  var calls = 0;
  Object? toJson() {
    calls++;
    return convert();
  }
}
