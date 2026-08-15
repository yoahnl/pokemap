enum CinematicLibraryFamily {
  world,
  presentation;

  factory CinematicLibraryFamily.fromJson(Object? value) {
    return switch (value) {
      'world' => CinematicLibraryFamily.world,
      'presentation' => CinematicLibraryFamily.presentation,
      _ => throw FormatException(
        'cinematicLibrary.family: unsupported value $value',
      ),
    };
  }

  String toJson() => name;
}

final class CinematicLibraryFolder {
  CinematicLibraryFolder({
    required String id,
    required this.family,
    required String name,
    String? parentFolderId,
    required this.sortOrder,
    this.isArchived = false,
  }) : id = _requiredString(id, 'folder.id'),
       name = _requiredString(name, 'folder.name'),
       parentFolderId = _optionalIdentifier(
         parentFolderId,
         'folder.parentFolderId',
       ) {
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder', 'must be non-negative');
    }
  }

  factory CinematicLibraryFolder.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'id',
      'family',
      'name',
      'parentFolderId',
      'sortOrder',
      'isArchived',
    }, 'cinematicLibrary.folder');
    try {
      return CinematicLibraryFolder(
        id: _readString(json['id'], 'folder.id'),
        family: CinematicLibraryFamily.fromJson(json['family']),
        name: _readString(json['name'], 'folder.name'),
        parentFolderId: _readOptionalString(
          json['parentFolderId'],
          'folder.parentFolderId',
        ),
        sortOrder: _readInt(json['sortOrder'], 'folder.sortOrder'),
        isArchived: _readOptionalBool(json['isArchived'], 'folder.isArchived'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;
  final CinematicLibraryFamily family;
  final String name;
  final String? parentFolderId;
  final int sortOrder;
  final bool isArchived;

  CinematicLibraryFolder copyWith({
    String? name,
    Object? parentFolderId = _unset,
    int? sortOrder,
    bool? isArchived,
  }) {
    return CinematicLibraryFolder(
      id: id,
      family: family,
      name: name ?? this.name,
      parentFolderId: identical(parentFolderId, _unset)
          ? this.parentFolderId
          : parentFolderId as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'family': family.toJson(),
    'name': name,
    if (parentFolderId != null) 'parentFolderId': parentFolderId,
    'sortOrder': sortOrder,
    if (isArchived) 'isArchived': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicLibraryFolder &&
          other.id == id &&
          other.family == family &&
          other.name == name &&
          other.parentFolderId == parentFolderId &&
          other.sortOrder == sortOrder &&
          other.isArchived == isArchived;

  @override
  int get hashCode =>
      Object.hash(id, family, name, parentFolderId, sortOrder, isArchived);
}

final class CinematicLibraryEntry {
  CinematicLibraryEntry({
    required this.family,
    required String cinematicId,
    String? folderId,
    required this.sortOrder,
    this.isArchived = false,
  }) : cinematicId = _requiredString(cinematicId, 'entry.cinematicId'),
       folderId = _optionalIdentifier(folderId, 'entry.folderId') {
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder', 'must be non-negative');
    }
  }

  factory CinematicLibraryEntry.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'family',
      'cinematicId',
      'folderId',
      'sortOrder',
      'isArchived',
    }, 'cinematicLibrary.entry');
    try {
      return CinematicLibraryEntry(
        family: CinematicLibraryFamily.fromJson(json['family']),
        cinematicId: _readString(json['cinematicId'], 'entry.cinematicId'),
        folderId: _readOptionalString(json['folderId'], 'entry.folderId'),
        sortOrder: _readInt(json['sortOrder'], 'entry.sortOrder'),
        isArchived: _readOptionalBool(json['isArchived'], 'entry.isArchived'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final CinematicLibraryFamily family;
  final String cinematicId;
  final String? folderId;
  final int sortOrder;
  final bool isArchived;

  CinematicLibraryEntry copyWith({
    Object? folderId = _unset,
    int? sortOrder,
    bool? isArchived,
  }) {
    return CinematicLibraryEntry(
      family: family,
      cinematicId: cinematicId,
      folderId: identical(folderId, _unset)
          ? this.folderId
          : folderId as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, Object?> toJson() => {
    'family': family.toJson(),
    'cinematicId': cinematicId,
    if (folderId != null) 'folderId': folderId,
    'sortOrder': sortOrder,
    if (isArchived) 'isArchived': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicLibraryEntry &&
          other.family == family &&
          other.cinematicId == cinematicId &&
          other.folderId == folderId &&
          other.sortOrder == sortOrder &&
          other.isArchived == isArchived;

  @override
  int get hashCode =>
      Object.hash(family, cinematicId, folderId, sortOrder, isArchived);
}

final class CinematicLibraryCatalog {
  factory CinematicLibraryCatalog({
    Iterable<CinematicLibraryFolder> folders = const [],
    Iterable<CinematicLibraryEntry> entries = const [],
  }) {
    final sortedFolders = folders.toList(growable: false)
      ..sort(_compareFolders);
    final sortedEntries = entries.toList(growable: false)
      ..sort(_compareEntries);
    _validateFolders(sortedFolders);
    _validateEntries(sortedFolders, sortedEntries);
    return CinematicLibraryCatalog._(
      List.unmodifiable(sortedFolders),
      List.unmodifiable(sortedEntries),
    );
  }

  const CinematicLibraryCatalog.empty()
    : folders = const [],
      entries = const [];

  const CinematicLibraryCatalog._(this.folders, this.entries);

  factory CinematicLibraryCatalog.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'schemaVersion',
      'folders',
      'entries',
    }, 'cinematicLibrary');
    final schemaVersion = _readInt(
      json['schemaVersion'],
      'cinematicLibrary.schemaVersion',
    );
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'cinematicLibrary.schemaVersion: expected $currentSchemaVersion, '
        'got $schemaVersion',
      );
    }
    try {
      return CinematicLibraryCatalog(
        folders: _readObjects(
          json['folders'],
          'cinematicLibrary.folders',
          CinematicLibraryFolder.fromJson,
        ),
        entries: _readObjects(
          json['entries'],
          'cinematicLibrary.entries',
          CinematicLibraryEntry.fromJson,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const currentSchemaVersion = 1;

  final List<CinematicLibraryFolder> folders;
  final List<CinematicLibraryEntry> entries;

  bool get isEmpty => folders.isEmpty && entries.isEmpty;

  CinematicLibraryFolder requireFolder(String folderId) {
    for (final folder in folders) {
      if (folder.id == folderId) return folder;
    }
    throw ArgumentError.value(folderId, 'folderId', 'is unknown');
  }

  CinematicLibraryEntry? entryFor(
    CinematicLibraryFamily family,
    String cinematicId,
  ) {
    for (final entry in entries) {
      if (entry.family == family && entry.cinematicId == cinematicId) {
        return entry;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'folders': [for (final folder in folders) folder.toJson()],
    'entries': [for (final entry in entries) entry.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicLibraryCatalog &&
          _listEquals(other.folders, folders) &&
          _listEquals(other.entries, entries);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(folders), Object.hashAll(entries));
}

const Object _unset = Object();

void _validateFolders(List<CinematicLibraryFolder> folders) {
  final byId = <String, CinematicLibraryFolder>{};
  final siblingNames = <String>{};
  for (final folder in folders) {
    if (byId[folder.id] != null) {
      throw ArgumentError.value(folder.id, 'folders', 'duplicate folder id');
    }
    byId[folder.id] = folder;
    final siblingKey =
        '${folder.family.name}|${folder.parentFolderId ?? ''}|'
        '${folder.name.toLowerCase()}';
    if (!siblingNames.add(siblingKey)) {
      throw ArgumentError.value(
        folder.name,
        'folders',
        'duplicate sibling name in ${folder.family.name}',
      );
    }
  }
  for (final folder in folders) {
    final parentId = folder.parentFolderId;
    if (parentId == null) continue;
    final parent = byId[parentId];
    if (parent == null) {
      throw ArgumentError.value(parentId, 'parentFolderId', 'is unknown');
    }
    if (parent.family != folder.family) {
      throw ArgumentError.value(
        parentId,
        'parentFolderId',
        'must belong to ${folder.family.name}',
      );
    }
    final visited = <String>{folder.id};
    var cursor = parent;
    while (!visited.add(cursor.id)) {
      throw ArgumentError.value(folder.id, 'folders', 'cycle detected');
    }
    while (cursor.parentFolderId != null) {
      cursor = byId[cursor.parentFolderId!]!;
      if (!visited.add(cursor.id)) {
        throw ArgumentError.value(folder.id, 'folders', 'cycle detected');
      }
    }
  }
  _validateContiguousOrders(
    folders,
    groupKey: (folder) =>
        '${folder.family.name}|${folder.parentFolderId ?? ''}',
    sortOrder: (folder) => folder.sortOrder,
    field: 'folders',
  );
}

void _validateEntries(
  List<CinematicLibraryFolder> folders,
  List<CinematicLibraryEntry> entries,
) {
  final foldersById = {for (final folder in folders) folder.id: folder};
  final identities = <String>{};
  for (final entry in entries) {
    final identity = '${entry.family.name}|${entry.cinematicId}';
    if (!identities.add(identity)) {
      throw ArgumentError.value(identity, 'entries', 'duplicate placement');
    }
    final folderId = entry.folderId;
    if (folderId == null) continue;
    final folder = foldersById[folderId];
    if (folder == null) {
      throw ArgumentError.value(folderId, 'folderId', 'is unknown');
    }
    if (folder.family != entry.family) {
      throw ArgumentError.value(
        folderId,
        'folderId',
        'must belong to ${entry.family.name}',
      );
    }
  }
  _validateContiguousOrders(
    entries,
    groupKey: (entry) => '${entry.family.name}|${entry.folderId ?? ''}',
    sortOrder: (entry) => entry.sortOrder,
    field: 'entries',
  );
}

void _validateContiguousOrders<T>(
  Iterable<T> values, {
  required String Function(T value) groupKey,
  required int Function(T value) sortOrder,
  required String field,
}) {
  final groups = <String, List<int>>{};
  for (final value in values) {
    groups.putIfAbsent(groupKey(value), () => []).add(sortOrder(value));
  }
  for (final entry in groups.entries) {
    final orders = entry.value..sort();
    for (var index = 0; index < orders.length; index++) {
      if (orders[index] != index) {
        throw ArgumentError.value(
          orders,
          field,
          'sortOrder must be contiguous inside sibling group ${entry.key}',
        );
      }
    }
  }
}

int _compareFolders(CinematicLibraryFolder left, CinematicLibraryFolder right) {
  final family = left.family.index.compareTo(right.family.index);
  if (family != 0) return family;
  final parent = (left.parentFolderId ?? '').compareTo(
    right.parentFolderId ?? '',
  );
  if (parent != 0) return parent;
  final order = left.sortOrder.compareTo(right.sortOrder);
  if (order != 0) return order;
  return left.id.compareTo(right.id);
}

int _compareEntries(CinematicLibraryEntry left, CinematicLibraryEntry right) {
  final family = left.family.index.compareTo(right.family.index);
  if (family != 0) return family;
  final folder = (left.folderId ?? '').compareTo(right.folderId ?? '');
  if (folder != 0) return folder;
  final order = left.sortOrder.compareTo(right.sortOrder);
  if (order != 0) return order;
  return left.cinematicId.compareTo(right.cinematicId);
}

String _requiredString(String value, String field) {
  if (value.trim() != value || value.isEmpty) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return value;
}

String? _optionalIdentifier(String? value, String field) {
  if (value == null) return null;
  return _requiredString(value, field);
}

String _readString(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field: expected a string');
  }
  return value;
}

String? _readOptionalString(Object? value, String field) {
  if (value == null) return null;
  return _readString(value, field);
}

int _readInt(Object? value, String field) {
  if (value is! int) {
    throw FormatException('$field: expected an integer');
  }
  return value;
}

bool _readOptionalBool(Object? value, String field) {
  if (value == null) return false;
  if (value is! bool) {
    throw FormatException('$field: expected a boolean');
  }
  return value;
}

List<T> _readObjects<T>(
  Object? value,
  String field,
  T Function(Map<String, Object?> json) decode,
) {
  if (value is! List) {
    throw FormatException('$field: expected an array');
  }
  return [
    for (var index = 0; index < value.length; index++)
      decode(_readObject(value[index], '$field[$index]')),
  ];
}

Map<String, Object?> _readObject(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field: expected an object');
  }
  return Map<String, Object?>.from(value);
}

void _rejectUnknownKeys(
  Map<String, Object?> json,
  Set<String> allowed,
  String field,
) {
  final unknown = json.keys.toSet().difference(allowed);
  if (unknown.isNotEmpty) {
    final sorted = unknown.toList()..sort();
    throw FormatException('$field: unknown fields ${sorted.join(', ')}');
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
