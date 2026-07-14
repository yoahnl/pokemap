import 'package:map_core/map_core.dart';
import 'package:map_core/src/operations/border_json_codec_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('Border JSON paths', () {
    test('build property and index paths without losing the parent path', () {
      expect(borderJsonPropertyPath(r'$.catalog', 'blueprints'),
          r'$.catalog.blueprints');
      expect(borderJsonIndexPath(r'$.catalog.blueprints', 3),
          r'$.catalog.blueprints[3]');
    });
  });

  group('Border JSON structural requirements', () {
    test('requireObject accepts a raw String-keyed Map and copies it', () {
      final source = <Object?, Object?>{'name': 'coast'};

      final decoded = borderJsonRequireObject(source, r'$.blueprint');
      source['name'] = 'changed';

      expect(decoded, <String, Object?>{'name': 'coast'});
      expect(identical(decoded, source), isFalse);
    });

    test('requireObject eagerly rejects every non-String key', () {
      final source = <Object?, Object?>{'valid': true, 7: 'invalid'};

      expect(
        () => borderJsonRequireObject(source, r'$.blueprint'),
        _formatExceptionAt(r'$.blueprint'),
      );
    });

    test('requireObject rejects non-objects without coercion', () {
      for (final value in <Object?>[null, <Object?>[], 'object', 1, true]) {
        expect(
          () => borderJsonRequireObject(value, r'$.blueprint'),
          _formatExceptionAt(r'$.blueprint'),
          reason: 'value: $value',
        );
      }
    });

    test('requireList accepts only List values and copies them', () {
      final source = <Object?>['first'];

      final decoded = borderJsonRequireList(source, r'$.frames');
      source[0] = 'changed';

      expect(decoded, <Object?>['first']);
      expect(identical(decoded, source), isFalse);
      expect(
        () => borderJsonRequireList(<String, Object?>{}, r'$.frames'),
        _formatExceptionAt(r'$.frames'),
      );
    });

    test('exact keys reject unknown keys first in lexical order', () {
      final json = <String, Object?>{'zeta': 1, 'alpha': 2};

      expect(
        () => borderJsonRequireExactKeys(
          json,
          path: r'$.blueprint',
          requiredKeys: const {'missing'},
        ),
        _formatExceptionAt(r'$.blueprint.alpha'),
      );
    });

    test('exact keys reject missing required keys in lexical order', () {
      expect(
        () => borderJsonRequireExactKeys(
          const <String, Object?>{},
          path: r'$.blueprint',
          requiredKeys: const {'zeta', 'alpha'},
        ),
        _formatExceptionAt(r'$.blueprint.alpha'),
      );
    });

    test('exact keys accept all required and optional keys', () {
      expect(
        () => borderJsonRequireExactKeys(
          const <String, Object?>{'id': 'coast', 'description': null},
          path: r'$.blueprint',
          requiredKeys: const {'id'},
          optionalKeys: const {'description'},
        ),
        returnsNormally,
      );
    });

    test('required field distinguishes an absent key from explicit null', () {
      expect(
        borderJsonRequireField(
          const <String, Object?>{'description': null},
          'description',
          r'$.blueprint',
        ),
        isNull,
      );
      expect(
        () => borderJsonRequireField(
          const <String, Object?>{},
          'description',
          r'$.blueprint',
        ),
        _formatExceptionAt(r'$.blueprint.description'),
      );
    });
  });

  group('Border JSON scalar requirements', () {
    test('string values are returned verbatim without trimming', () {
      expect(borderJsonRequireString(' coast ', r'$.name'), ' coast ');
      for (final value in <Object?>[null, 1, true, <Object?>[]]) {
        expect(
          () => borderJsonRequireString(value, r'$.name'),
          _formatExceptionAt(r'$.name'),
          reason: 'value: $value',
        );
      }
    });

    test('int accepts only a JSON integer represented as int', () {
      expect(borderJsonRequireInt(7, r'$.rank'), 7);
      for (final value in <Object?>[null, 7.0, '7', true]) {
        expect(
          () => borderJsonRequireInt(value, r'$.rank'),
          _formatExceptionAt(r'$.rank'),
          reason: 'value: $value',
        );
      }
    });

    test('bool accepts only bool', () {
      expect(borderJsonRequireBool(false, r'$.suppressed'), isFalse);
      for (final value in <Object?>[null, 0, 'false']) {
        expect(
          () => borderJsonRequireBool(value, r'$.suppressed'),
          _formatExceptionAt(r'$.suppressed'),
          reason: 'value: $value',
        );
      }
    });
  });

  group('canonical signed 64-bit decimal strings', () {
    test('decodes and canonically encodes the inclusive signed bounds', () {
      final values = <BorderSignedInt64>[
        BorderSignedInt64.minimum,
        BorderSignedInt64.fromInt(-1),
        BorderSignedInt64.zero,
        BorderSignedInt64.fromInt(1),
        BorderSignedInt64.maximum,
      ];

      for (final value in values) {
        final encoded = borderJsonEncodeSignedInt64(value);
        expect(encoded, value.toString());
        expect(borderJsonDecodeSignedInt64(encoded, r'$.seed'), value);
      }
    });

    test('rejects non-canonical, non-string, and out-of-range values', () {
      final invalidValues = <Object?>[
        '-0',
        '+1',
        '01',
        '-01',
        ' 1',
        '1 ',
        '1.0',
        '1e2',
        '',
        '9223372036854775808',
        '-9223372036854775809',
        1,
        1.0,
        true,
        null,
      ];

      for (final value in invalidValues) {
        expect(
          () => borderJsonDecodeSignedInt64(value, r'$.feature.seed'),
          _formatExceptionAt(r'$.feature.seed'),
          reason: 'value: $value',
        );
      }
    });

    test('rejects an attacker-sized decimal payload at the same field path',
        () {
      final attackerSizedValue = List<String>.filled(100000, '9').join();

      expect(
        () => borderJsonDecodeSignedInt64(
          attackerSizedValue,
          r'$.feature.seed',
        ),
        _formatExceptionAt(r'$.feature.seed'),
      );
    });
  });

  group('domain constructor translation', () {
    test('prefixes ValidationException with the supplied JSONPath', () {
      expect(
        () => borderJsonConstructAtPath<int>(r'$.blueprint.params', () {
          throw const ValidationException('params are invalid');
        }),
        allOf(
          _formatExceptionAt(r'$.blueprint.params'),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('params are invalid'),
            ),
          ),
        ),
      );
    });

    test('prefixes ArgumentError with the supplied JSONPath', () {
      expect(
        () => borderJsonConstructAtPath<int>(r'$.frame.sourceRect', () {
          throw ArgumentError('width must be positive');
        }),
        allOf(
          _formatExceptionAt(r'$.frame.sourceRect'),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('width must be positive'),
            ),
          ),
        ),
      );
    });

    test('does not swallow unrelated exceptions', () {
      final failure = StateError('unrelated failure');

      expect(
        () => borderJsonConstructAtPath<int>(r'$.blueprint', () {
          throw failure;
        }),
        throwsA(same(failure)),
      );
    });
  });
}

Matcher _formatExceptionAt(String path) {
  return throwsA(
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      contains(path),
    ),
  );
}
