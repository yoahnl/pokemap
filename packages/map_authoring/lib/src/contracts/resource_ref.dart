import 'json_contract_support.dart';

/// Typed, opaque reference to a PokeMap authoring resource.
///
/// Callers may compare and transport [id], but must not interpret it as a
/// filesystem path.
final class AuthoringResourceRef {
  AuthoringResourceRef({
    required String kind,
    required String id,
    String? revision,
    Map<String, Object?> extensions = const {},
  })  : kind = _validateResourceKind(kind),
        id = _validateNonBlank(id, 'id'),
        revision =
            revision == null ? null : _validateNonBlank(revision, 'revision'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringResourceRef.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringResourceRef(
        kind: requireContractString(json['kind'], 'kind'),
        id: requireContractString(json['id'], 'id'),
        revision: readOptionalContractString(json['revision'], 'revision'),
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
    'kind',
    'id',
    'revision',
    'extensions',
  };

  final String kind;
  final String id;
  final String? revision;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'kind': kind,
      'id': id,
      if (revision != null) 'revision': revision,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _validateResourceKind(String value) {
  final normalized = _validateNonBlank(value, 'kind');
  if (!RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'kind',
      'must be a stable lower-camel identifier',
    );
  }
  return normalized;
}

String _validateNonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}
