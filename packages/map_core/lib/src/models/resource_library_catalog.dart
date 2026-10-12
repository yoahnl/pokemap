final class ResourceFamily {
  ResourceFamily({required String id, required String name, String? parentId})
    : id = _identifier(id, 'family.id'),
      name = _identifier(name, 'family.name'),
      parentId = _optionalIdentifier(parentId, 'family.parentId');

  const ResourceFamily._(this.id, this.name) : parentId = null;

  factory ResourceFamily.fromJson(Map<String, Object?> json) {
    _keys(json, const {'id', 'name', 'parentId'});
    return ResourceFamily(
      id: _string(json['id'], 'family.id'),
      name: _string(json['name'], 'family.name'),
      parentId: _optionalString(json['parentId'], 'family.parentId'),
    );
  }

  final String id;
  final String name;
  final String? parentId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (parentId != null) 'parentId': parentId,
  };

  @override
  bool operator ==(Object other) =>
      other is ResourceFamily &&
      id == other.id &&
      name == other.name &&
      parentId == other.parentId;

  @override
  int get hashCode => Object.hash(id, name, parentId);
}

enum ResourceLibraryRole { standard, component }

final class ResourceLibraryEntry {
  ResourceLibraryEntry({
    required String resourceKind,
    required String resourceId,
    String? familyId,
    String? mapId,
    this.role = ResourceLibraryRole.standard,
  }) : resourceKind = _identifier(resourceKind, 'entry.resourceKind'),
       resourceId = _identifier(resourceId, 'entry.resourceId'),
       familyId = _optionalIdentifier(familyId, 'entry.familyId'),
       mapId = _optionalIdentifier(mapId, 'entry.mapId') {
    if (!ResourceLibraryCatalog.resourceKinds.contains(resourceKind)) {
      throw ArgumentError.value(
        resourceKind,
        'resourceKind',
        'unsupported resource kind',
      );
    }
  }

  factory ResourceLibraryEntry.fromJson(Map<String, Object?> json) {
    _keys(json, const {
      'resourceKind',
      'resourceId',
      'familyId',
      'mapId',
      'role',
    });
    return ResourceLibraryEntry(
      resourceKind: _string(json['resourceKind'], 'entry.resourceKind'),
      resourceId: _string(json['resourceId'], 'entry.resourceId'),
      familyId: _optionalString(json['familyId'], 'entry.familyId'),
      mapId: _optionalString(json['mapId'], 'entry.mapId'),
      role: json.containsKey('role')
          ? ResourceLibraryRole.values.byName(
              _string(json['role'], 'entry.role'),
            )
          : ResourceLibraryRole.standard,
    );
  }

  final String resourceKind;
  final String resourceId;
  final String? familyId;
  final String? mapId;
  final ResourceLibraryRole role;
  String get identity => '$resourceKind:$resourceId';

  Map<String, Object?> toJson() => {
    'resourceKind': resourceKind,
    'resourceId': resourceId,
    if (familyId != null) 'familyId': familyId,
    if (mapId != null) 'mapId': mapId,
    if (role != ResourceLibraryRole.standard) 'role': role.name,
  };

  @override
  bool operator ==(Object other) =>
      other is ResourceLibraryEntry &&
      resourceKind == other.resourceKind &&
      resourceId == other.resourceId &&
      familyId == other.familyId &&
      mapId == other.mapId &&
      role == other.role;

  @override
  int get hashCode =>
      Object.hash(resourceKind, resourceId, familyId, mapId, role);
}

final class ResourceLibraryCatalog {
  factory ResourceLibraryCatalog({
    Iterable<ResourceFamily> families = const [],
    Iterable<ResourceLibraryEntry> entries = const [],
  }) {
    final orderedFamilies = families.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final orderedEntries = entries.toList()
      ..sort((a, b) => a.identity.compareTo(b.identity));
    final byId = {for (final family in predefinedFamilies) family.id: family};
    for (final family in orderedFamilies) {
      if (byId.containsKey(family.id)) {
        throw ArgumentError.value(
          family.id,
          'families',
          'duplicate or predefined family',
        );
      }
      byId[family.id] = family;
    }
    for (final family in orderedFamilies) {
      final visited = <String>{family.id};
      var parentId = family.parentId;
      while (parentId != null) {
        final parent = byId[parentId];
        if (parent == null || !visited.add(parentId)) {
          throw ArgumentError.value(
            parentId,
            'families',
            'unknown parent or cycle',
          );
        }
        parentId = parent.parentId;
      }
    }
    final identities = <String>{};
    for (final entry in orderedEntries) {
      if (!identities.add(entry.identity) ||
          entry.familyId != null && !byId.containsKey(entry.familyId)) {
        throw ArgumentError.value(
          entry.identity,
          'entries',
          'duplicate identity or unknown family',
        );
      }
    }
    return ResourceLibraryCatalog._(
      List.unmodifiable(orderedFamilies),
      List.unmodifiable(orderedEntries),
    );
  }

  const ResourceLibraryCatalog.empty()
    : families = const [],
      entries = const [];
  const ResourceLibraryCatalog._(this.families, this.entries);

  factory ResourceLibraryCatalog.fromJson(Map<String, Object?> json) {
    _keys(json, const {'formatVersion', 'families', 'entries'});
    if (json['formatVersion'] != currentFormatVersion) {
      throw const FormatException(
        'resourceLibraryCatalog.formatVersion: expected 1',
      );
    }
    try {
      return ResourceLibraryCatalog(
        families: _objects(json['families'], ResourceFamily.fromJson),
        entries: _objects(json['entries'], ResourceLibraryEntry.fromJson),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const currentFormatVersion = 1;
  static const resourceKinds = <String>{
    'element',
    'model3d',
    'smartTilePreset',
    'tileset',
    'borderBlueprint',
    'environmentPreset',
    'character',
  };
  static const predefinedFamilies = <ResourceFamily>[
    ResourceFamily._('trees', 'Arbres'),
    ResourceFamily._('vegetation', 'Végétation'),
    ResourceFamily._('buildings', 'Bâtiments'),
    ResourceFamily._('props', 'Objets'),
    ResourceFamily._('fences', 'Clôtures'),
    ResourceFamily._('ground', 'Sols'),
    ResourceFamily._('water', 'Eau'),
    ResourceFamily._('relief', 'Relief'),
    ResourceFamily._('characters', 'Personnages'),
  ];

  final List<ResourceFamily> families;
  final List<ResourceLibraryEntry> entries;
  int get formatVersion => currentFormatVersion;
  bool get isEmpty => families.isEmpty && entries.isEmpty;
  List<ResourceFamily> get effectiveFamilies =>
      List.unmodifiable([...predefinedFamilies, ...families]);

  ResourceLibraryEntry? entryFor(String resourceKind, String resourceId) {
    for (final entry in entries) {
      if (entry.resourceKind == resourceKind &&
          entry.resourceId == resourceId) {
        return entry;
      }
    }
    return null;
  }

  bool availableForMap(String resourceKind, String resourceId, String mapId) {
    final ownerMapId = entryFor(resourceKind, resourceId)?.mapId;
    return ownerMapId == null || ownerMapId == mapId;
  }

  Set<String> descendantFamilyIds(String familyId) {
    if (!effectiveFamilies.any((family) => family.id == familyId)) {
      throw ArgumentError.value(familyId, 'familyId', 'unknown family');
    }
    final result = <String>{familyId};
    var previousSize = 0;
    while (result.length != previousSize) {
      previousSize = result.length;
      for (final family in families) {
        if (result.contains(family.parentId)) result.add(family.id);
      }
    }
    return Set.unmodifiable(result);
  }

  Map<String, Object?> toJson() => {
    'formatVersion': currentFormatVersion,
    'families': [for (final family in families) family.toJson()],
    'entries': [for (final entry in entries) entry.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ResourceLibraryCatalog &&
      _listEquals(families, other.families) &&
      _listEquals(entries, other.entries);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(families), Object.hashAll(entries));
}

String _identifier(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return value;
}

String? _optionalIdentifier(String? value, String field) =>
    value == null ? null : _identifier(value, field);
String _string(Object? value, String field) {
  if (value is! String) throw FormatException('$field: expected string');
  return value;
}

String? _optionalString(Object? value, String field) =>
    value == null ? null : _string(value, field);
void _keys(Map<String, Object?> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('resourceLibraryCatalog: unknown field');
  }
}

Iterable<T> _objects<T>(Object? value, T Function(Map<String, Object?>) read) {
  if (value is! List || value.any((entry) => entry is! Map)) {
    throw const FormatException('resourceLibraryCatalog: expected object list');
  }
  return value.map((entry) => read(Map<String, Object?>.from(entry as Map)));
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
