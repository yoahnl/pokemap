import 'json_contract_support.dart';

/// Versioned reference to a canonical request or result JSON Schema.
final class AuthoringSchemaDescriptor {
  AuthoringSchemaDescriptor({
    required String id,
    required int version,
    required String uri,
    required String sha256,
    String? description,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        uri = _nonBlank(uri, 'uri'),
        sha256 = _nonBlank(sha256, 'sha256'),
        description =
            description == null ? null : _nonBlank(description, 'description'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringSchemaDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringSchemaDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        uri: requireContractString(json['uri'], 'uri'),
        sha256: requireContractString(json['sha256'], 'sha256'),
        description:
            readOptionalContractString(json['description'], 'description'),
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
    'id',
    'version',
    'uri',
    'sha256',
    'description',
    'extensions',
  };

  final String id;
  final int version;
  final String uri;
  final String sha256;
  final String? description;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'uri': uri,
      'sha256': sha256,
      if (description != null) 'description': description,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}
