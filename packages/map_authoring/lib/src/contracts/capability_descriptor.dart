import 'json_contract_support.dart';

/// Versioned grouping of related authoring actions and resource kinds.
final class AuthoringCapabilityDescriptor {
  AuthoringCapabilityDescriptor({
    required String id,
    required int version,
    required String summary,
    Iterable<String> resourceKinds = const [],
    Iterable<String> actionIds = const [],
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        summary = _nonBlank(summary, 'summary'),
        resourceKinds = normalizedContractStrings(
          resourceKinds,
          'resourceKinds',
        ),
        actionIds = normalizedContractStrings(actionIds, 'actionIds'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringCapabilityDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringCapabilityDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        summary: requireContractString(json['summary'], 'summary'),
        resourceKinds:
            readContractStringList(json['resourceKinds'], 'resourceKinds'),
        actionIds: readContractStringList(json['actionIds'], 'actionIds'),
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
    'summary',
    'resourceKinds',
    'actionIds',
    'extensions',
  };

  final String id;
  final int version;
  final String summary;
  final List<String> resourceKinds;
  final List<String> actionIds;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'summary': summary,
      'resourceKinds': resourceKinds,
      'actionIds': actionIds,
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
