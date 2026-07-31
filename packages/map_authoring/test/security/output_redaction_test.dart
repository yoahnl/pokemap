import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringOutputRedactor', () {
    const redactor = AuthoringOutputRedactor();

    test('recursively removes secret fields credentials and absolute paths',
        () {
      final redacted = redactor.redact({
        'name': 'safe',
        'password': 'super-secret',
        'nested': [
          {
            'apiToken': 'token-value',
            'message': 'Authorization: Bearer abc.def.ghi',
          },
          'read /Users/alice/private/project.json before retrying',
          r'failure at C:\Users\alice\project\main.dart:42',
        ],
        'relativePath': 'maps/route_01.json',
        'url': 'https://example.invalid/v1/maps',
        'jsonPath': r'$.events[0].commands',
      });
      final encoded = jsonEncode(redacted);

      expect(encoded, isNot(contains('super-secret')));
      expect(encoded, isNot(contains('token-value')));
      expect(encoded, isNot(contains('abc.def.ghi')));
      expect(encoded, isNot(contains('/Users/alice')));
      expect(encoded, isNot(contains(r'C:\Users\alice')));
      expect(encoded, contains('[REDACTED]'));
      expect(encoded, contains('<absolute-path>'));
      expect(encoded, contains('maps/route_01.json'));
      expect(encoded, contains('https://example.invalid/v1/maps'));
      expect(encoded, contains(r'$.events[0].commands'));
    });

    test('maps internal exceptions to stable path-free public errors', () {
      final safe = redactor.redactError(
        StateError(
          'database password=hunter2 failed at '
          '/private/tmp/pokemap/internal.dart:9',
        ),
      );
      final encoded = jsonEncode(safe.toJson());

      expect(safe.code, 'internal.error');
      expect(safe.message, 'The operation failed safely.');
      expect(encoded, isNot(contains('hunter2')));
      expect(encoded, isNot(contains('/private/tmp')));
      expect(encoded, isNot(contains('StateError')));
    });

    test('preserves a stable safe error code without copying raw messages', () {
      const error = AuthoringAuthorizationException(
        code: 'authorization.permission_denied',
        message: 'unsafe detail /Users/alice/project',
      );
      final safe = redactor.redactError(error);

      expect(safe.code, 'authorization.permission_denied');
      expect(safe.message, 'The operation was denied safely.');
      expect(jsonEncode(safe.toJson()), isNot(contains('/Users/alice')));
    });
  });
}
