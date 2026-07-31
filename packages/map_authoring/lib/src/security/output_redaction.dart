import 'authorization_policy.dart';

final class AuthoringRedactedError {
  const AuthoringRedactedError({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

/// Recursive output sanitizer used by audit and future transport adapters.
final class AuthoringOutputRedactor {
  const AuthoringOutputRedactor({this.maxDepth = 32});

  final int maxDepth;

  Object? redact(Object? value) => _redact(value, 0);

  AuthoringRedactedError redactError(Object error) {
    if (error case AuthoringAuthorizationException(:final code)) {
      return AuthoringRedactedError(
        code: _safeCode(code),
        message: code.startsWith('authorization.') ||
                code.startsWith('confirmation.')
            ? 'The operation was denied safely.'
            : 'The operation failed safely.',
      );
    }
    return const AuthoringRedactedError(
      code: 'internal.error',
      message: 'The operation failed safely.',
    );
  }

  Object? _redact(Object? value, int depth) {
    if (depth > maxDepth) return '[REDACTED]';
    if (value == null || value is num || value is bool) return value;
    if (value is String) return _redactString(value);
    if (value is Map) {
      final output = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) continue;
        output[key] = _secretLikeKey(key)
            ? '[REDACTED]'
            : _redact(entry.value, depth + 1);
      }
      return Map<String, Object?>.unmodifiable(output);
    }
    if (value is Iterable) {
      return List<Object?>.unmodifiable(
        value.map((item) => _redact(item, depth + 1)),
      );
    }
    return '[REDACTED]';
  }
}

String _redactString(String value) {
  var redacted = value.replaceAllMapped(
    _bearerCredential,
    (match) => '${match.group(1) ?? ''}Bearer [REDACTED]',
  );
  redacted = redacted.replaceAll(_windowsAbsolutePath, '<absolute-path>');
  return redacted.replaceAllMapped(
    _posixAbsolutePath,
    (match) => '${match.group(1) ?? ''}<absolute-path>',
  );
}

bool _secretLikeKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  return const [
    'password',
    'passwd',
    'secret',
    'token',
    'credential',
    'authorization',
    'apikey',
    'privatekey',
    'accesskey',
    'cookie',
    'sessionid',
    'idempotencykey',
  ].any(normalized.contains);
}

String _safeCode(String value) =>
    _safeCodePattern.hasMatch(value) ? value : 'internal.error';

final RegExp _safeCodePattern = RegExp(r'^[a-z][a-z0-9_.-]*$');
final RegExp _bearerCredential = RegExp(
  r'(^|\b)Bearer[ \t]+[a-zA-Z0-9._~+/=-]+',
  caseSensitive: false,
);
final RegExp _windowsAbsolutePath = RegExp(
  r'[a-zA-Z]:\\(?:[^\\\s]+\\)*[^\\\s,;)\]}]+',
);
final RegExp _posixAbsolutePath = RegExp(
  r'(^|[\s(=:])/(?!/)[^\s,;)\]}]+',
  multiLine: true,
);
