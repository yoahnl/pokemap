import 'json_contract_support.dart';

enum AuthoringErrorCode {
  invalidRequest('invalid_request'),
  notFound('not_found'),
  validationFailed('validation_failed'),
  permissionDenied('permission_denied'),
  revisionConflict('revision_conflict'),
  unsupported('unsupported'),
  internal('internal');

  const AuthoringErrorCode(this.wireName);

  final String wireName;

  static AuthoringErrorCode fromWireName(String value) {
    return AuthoringErrorCode.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown error code: $value'),
    );
  }
}

/// Safe, structured error intended for external authoring clients.
///
/// Raw exceptions, stack traces, and machine-local paths must be logged behind
/// the adapter boundary instead of being serialized here.
final class AuthoringError {
  AuthoringError({
    required this.code,
    required String message,
    required this.retryable,
    String? fieldPath,
    Iterable<String> remediation = const [],
    Map<String, Object?> details = const {},
    Map<String, Object?> extensions = const {},
  })  : message = _safeText(message, 'message'),
        fieldPath =
            fieldPath == null ? null : _safeText(fieldPath, 'fieldPath'),
        remediation = List.unmodifiable(
          remediation.map((item) => _safeText(item, 'remediation')),
        ),
        details = freezeContractJsonObject(details, field: 'details'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        ) {
    _rejectUnsafeJson(this.details, 'details');
    _rejectUnsafeJson(this.extensions, 'extensions');
  }

  factory AuthoringError.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawRemediation = json['remediation'];
    final rawDetails = json['details'];
    if (rawRemediation is! List ||
        rawRemediation.any((item) => item is! String)) {
      throw const FormatException('remediation must be a list of strings');
    }
    if (rawDetails is! Map) {
      throw const FormatException('details must be a JSON object');
    }
    try {
      return AuthoringError(
        code: AuthoringErrorCode.fromWireName(
          requireContractString(json['code'], 'code'),
        ),
        message: requireContractString(json['message'], 'message'),
        retryable: requireContractBool(json['retryable'], 'retryable'),
        fieldPath: readOptionalContractString(json['fieldPath'], 'fieldPath'),
        remediation: rawRemediation.cast<String>(),
        details: Map<String, Object?>.from(rawDetails),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'code',
    'message',
    'retryable',
    'fieldPath',
    'remediation',
    'details',
    'extensions',
  };

  final AuthoringErrorCode code;
  final String message;
  final bool retryable;
  final String? fieldPath;
  final List<String> remediation;
  final Map<String, Object?> details;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'code': code.wireName,
      'message': message,
      'retryable': retryable,
      if (fieldPath != null) 'fieldPath': fieldPath,
      'remediation': remediation,
      'details': details,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _safeText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  if (_machinePathPattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must not contain a machine-local path',
    );
  }
  if (normalized.toLowerCase().contains('stack trace')) {
    throw ArgumentError.value(value, field, 'must not contain a stack trace');
  }
  if (RegExp(r'(?:^|\n)\s*#\d+\s').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must not contain a stack trace');
  }
  return normalized;
}

void _rejectUnsafeJson(Object? value, String field) {
  if (value is String) {
    _safeText(value, field);
    return;
  }
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      _rejectUnsafeJson(value[index], '$field[$index]');
    }
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      final normalizedKey =
          entry.key.toString().replaceAll(RegExp(r'[_\-\s]'), '').toLowerCase();
      if (normalizedKey == 'stack' ||
          normalizedKey == 'trace' ||
          normalizedKey == 'stacktrace') {
        throw ArgumentError.value(
          entry.key,
          field,
          'must not expose stack traces',
        );
      }
      _rejectUnsafeJson(entry.value, '$field.${entry.key}');
    }
  }
}

final RegExp _machinePathPattern = RegExp(
  r'(?:/Users/|/home/|/private/|/tmp/|/var/folders/|'
  r'/workspace/|'
  r'[A-Za-z]:\\(?:Users|Documents and Settings)\\)',
  caseSensitive: false,
);
