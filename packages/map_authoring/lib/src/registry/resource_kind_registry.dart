import '../contracts/json_contract_support.dart';

/// Public description of one resource kind accepted by authoring contracts.
final class AuthoringResourceKindDescriptor {
  AuthoringResourceKindDescriptor({
    required String id,
    required int version,
    required String displayName,
    required String summary,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        displayName = _nonBlank(displayName, 'displayName'),
        summary = _nonBlank(summary, 'summary'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringResourceKindDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringResourceKindDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        displayName: requireContractString(json['displayName'], 'displayName'),
        summary: requireContractString(json['summary'], 'summary'),
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
    'displayName',
    'summary',
    'extensions',
  };

  final String id;
  final int version;
  final String displayName;
  final String summary;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'displayName': displayName,
      'summary': summary,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

final class DuplicateAuthoringResourceKindException implements Exception {
  const DuplicateAuthoringResourceKindException(this.kindId, this.version);

  final String kindId;
  final int version;

  @override
  String toString() => 'Duplicate authoring resource kind: $kindId v$version';
}

final class IncompatibleAuthoringResourceKindVersionException
    implements Exception {
  IncompatibleAuthoringResourceKindVersionException(
    this.kindId,
    Iterable<int> versions,
  ) : versions = List.unmodifiable(versions.toSet().toList()..sort());

  final String kindId;
  final List<int> versions;

  @override
  String toString() {
    return 'Incompatible resource kind versions for $kindId: '
        '${versions.join(', ')}';
  }
}

final class UnknownAuthoringResourceKindException implements Exception {
  const UnknownAuthoringResourceKindException(this.kindId);

  final String kindId;

  @override
  String toString() => 'Unknown authoring resource kind: $kindId';
}

/// Immutable registry of resource kinds, sorted by stable identifier.
final class AuthoringResourceKindRegistry {
  AuthoringResourceKindRegistry(
    Iterable<AuthoringResourceKindDescriptor> descriptors,
  ) : resourceKinds = _validateAndSort(descriptors) {
    _byId = Map.unmodifiable({
      for (final descriptor in resourceKinds) descriptor.id: descriptor,
    });
  }

  factory AuthoringResourceKindRegistry.canonicalMinimal() {
    return AuthoringResourceKindRegistry([
      AuthoringResourceKindDescriptor(
        id: 'project',
        version: 1,
        displayName: 'Project',
        summary: 'PokeMap project manifest and project-owned content',
      ),
      AuthoringResourceKindDescriptor(
        id: 'map',
        version: 1,
        displayName: 'Map',
        summary: 'Editable PokeMap map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'layer',
        version: 1,
        displayName: 'Layer',
        summary: 'Ordered layer owned by a map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'region',
        version: 1,
        displayName: 'Region',
        summary: 'Named or bounded spatial region in a map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'asset',
        version: 1,
        displayName: 'Asset',
        summary: 'Content-addressed project asset',
      ),
      AuthoringResourceKindDescriptor(
        id: 'assetCatalog',
        version: 1,
        displayName: 'Asset catalog',
        summary: 'Project-owned asset identity and usage registry',
      ),
      AuthoringResourceKindDescriptor(
        id: 'assetBlob',
        version: 1,
        displayName: 'Asset blob',
        summary: 'Content-addressed immutable asset bytes',
      ),
    ]);
  }

  factory AuthoringResourceKindRegistry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'formatVersion', 'resourceKinds'});
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported resource registry formatVersion: '
        '${json['formatVersion']}',
      );
    }
    final rawKinds = json['resourceKinds'];
    if (rawKinds is! List) {
      throw const FormatException('resourceKinds must be a JSON list');
    }
    return AuthoringResourceKindRegistry(
      rawKinds.map((rawKind) {
        if (rawKind is! Map) {
          throw const FormatException('resource kind must be a JSON object');
        }
        return AuthoringResourceKindDescriptor.fromJson(
          Map<String, dynamic>.from(rawKind),
        );
      }),
    );
  }

  final List<AuthoringResourceKindDescriptor> resourceKinds;
  late final Map<String, AuthoringResourceKindDescriptor> _byId;

  AuthoringResourceKindDescriptor? find(String kindId) => _byId[kindId];

  AuthoringResourceKindDescriptor require(String kindId) {
    return find(kindId) ??
        (throw UnknownAuthoringResourceKindException(kindId));
  }

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'resourceKinds': resourceKinds
          .map((descriptor) => descriptor.toJson())
          .toList(growable: false),
    };
  }

  static List<AuthoringResourceKindDescriptor> _validateAndSort(
    Iterable<AuthoringResourceKindDescriptor> descriptors,
  ) {
    final byId = <String, AuthoringResourceKindDescriptor>{};
    for (final descriptor in descriptors) {
      final existing = byId[descriptor.id];
      if (existing != null) {
        if (existing.version == descriptor.version) {
          throw DuplicateAuthoringResourceKindException(
            descriptor.id,
            descriptor.version,
          );
        }
        throw IncompatibleAuthoringResourceKindVersionException(
          descriptor.id,
          [existing.version, descriptor.version],
        );
      }
      byId[descriptor.id] = descriptor;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
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
