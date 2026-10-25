import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

enum CatalogDefinitionKind {
  tileset,
  element,
  model3d,
  character,
  environmentPreset,
  smartTileCategory,
  smartTileAtlas,
  smartTileMaterial,
  smartTilePattern,
  smartTileAnimation,
  smartTilePreset,
  borderRecord,
  borderVisualSnapshot,
  resourceFamily,
  resourceLibraryEntry,
  elementCategory,
  tilesetFolder,
  characterStudioDefinition,
  fileBinding,
  provenance,
  catalogMetadata,
  workspaceState,
}

final class CatalogDefinitionKey implements Comparable<CatalogDefinitionKey> {
  CatalogDefinitionKey(this.kind, this.id) {
    if (id.isEmpty ||
        id.length > 512 ||
        id.trim() != id ||
        id.runes.any((r) => r < 32 || r == 127)) {
      throw const FormatException('catalog.key: invalid id');
    }
  }

  factory CatalogDefinitionKey.fromJson(Map<String, Object?> json) {
    _keys(json, {'kind', 'id'});
    final name = json['kind'];
    final kind = CatalogDefinitionKind.values.where((k) => k.name == name);
    if (kind.isEmpty || json['id'] is! String) {
      throw const FormatException('catalog.key: unsupported kind or id');
    }
    return CatalogDefinitionKey(kind.single, json['id']! as String);
  }

  final CatalogDefinitionKind kind;
  final String id;
  Map<String, Object?> toJson() => {'kind': kind.name, 'id': id};
  @override
  int compareTo(CatalogDefinitionKey other) {
    final byKind = kind.name.compareTo(other.kind.name);
    return byKind == 0 ? id.compareTo(other.id) : byKind;
  }

  @override
  bool operator ==(Object other) =>
      other is CatalogDefinitionKey && kind == other.kind && id == other.id;
  @override
  int get hashCode => Object.hash(kind, id);
  @override
  String toString() => '${kind.name}:$id';
}

final class CatalogObjectReference {
  CatalogObjectReference({required this.sha256, required this.byteLength}) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256) ||
        byteLength < 1 ||
        byteLength > 1048576) {
      throw const FormatException('catalog.reference: invalid digest or size');
    }
  }
  factory CatalogObjectReference.fromJson(Map<String, Object?> json) {
    _keys(json, {'sha256', 'byteLength'});
    if (json['sha256'] is! String || json['byteLength'] is! int) {
      throw const FormatException('catalog.reference: invalid types');
    }
    return CatalogObjectReference(
      sha256: json['sha256']! as String,
      byteLength: json['byteLength']! as int,
    );
  }
  final String sha256;
  final int byteLength;
  Map<String, Object?> toJson() => {'sha256': sha256, 'byteLength': byteLength};
  @override
  bool operator ==(Object other) =>
      other is CatalogObjectReference &&
      sha256 == other.sha256 &&
      byteLength == other.byteLength;
  @override
  int get hashCode => Object.hash(sha256, byteLength);
}

final class CatalogStorageLimits {
  CatalogStorageLimits({
    this.maxUnitBytes = 1048576,
    this.maxIndexBytes = 262144,
    this.indexPageSize = 128,
    this.maxDefinitions = 1000000,
    this.maxJsonDepth = 64,
    this.maxJsonValues = 100000,
    this.maxReferencesPerUnit = 4096,
    this.maxIndexDepth = 32,
    this.maxClosureNodes = 100000,
    this.maxClosureDepth = 128,
    this.maxStoredBytes = 1073741824,
  }) {
    for (final (value, ceiling) in [
      (maxUnitBytes, 1048576),
      (maxIndexBytes, 262144),
      (indexPageSize, 128),
      (maxDefinitions, 1000000),
      (maxJsonDepth, 64),
      (maxJsonValues, 100000),
      (maxReferencesPerUnit, 4096),
      (maxIndexDepth, 32),
      (maxClosureNodes, 100000),
      (maxClosureDepth, 128),
      (maxStoredBytes, 1073741824),
    ]) {
      if (value < 1 || value > ceiling) {
        throw ArgumentError(
          'catalog.limits: can only lower immutable ceilings',
        );
      }
    }
    if (indexPageSize < 2) {
      throw ArgumentError('catalog.indexPageSize: at least two');
    }
  }
  final int maxUnitBytes;
  final int maxIndexBytes;
  final int indexPageSize;
  final int maxDefinitions;
  final int maxJsonDepth;
  final int maxJsonValues;
  final int maxReferencesPerUnit;
  final int maxIndexDepth;
  final int maxClosureNodes;
  final int maxClosureDepth;
  final int maxStoredBytes;
}

final class CatalogDefinitionUnit {
  CatalogDefinitionUnit({
    required this.key,
    required Map<String, Object?> payload,
    Iterable<CatalogDefinitionKey> references = const [],
  }) : payload =
           _freeze(payload, CatalogStorageLimits()) as Map<String, Object?>,
       references = List.unmodifiable(references.toList()..sort()) {
    if (payload.containsKey('id') && payload['id'] != key.id) {
      throw const FormatException('catalog.unit: payload id differs from key');
    }
    _ordered(this.references);
    if (this.references.length > 4096) {
      throw const FormatException('catalog.unit: reference limit');
    }
  }
  final CatalogDefinitionKey key;
  final Map<String, Object?> payload;
  final List<CatalogDefinitionKey> references;
  Map<String, Object?> toJson() => {
    'type': 'unit',
    'version': 2,
    'key': key.toJson(),
    'payload': payload,
    'references': references.map((r) => r.toJson()).toList(),
  };
}

final class CatalogDefinitionSummary {
  static const _maxMetadataBytes = 8192;

  CatalogDefinitionSummary({
    required this.name,
    this.description,
    Iterable<String> tags = const [],
    this.familyId,
    this.mapId,
    this.role,
    this.placementContext,
  }) : tags = List.unmodifiable(tags) {
    for (final value in [name, familyId, mapId, role, placementContext]) {
      if (value != null && (value.isEmpty || value.length > 512)) {
        throw const FormatException('catalog.summary: invalid string');
      }
    }
    if ((description?.length ?? 0) > 2000 ||
        this.tags.any((tag) => tag.isEmpty || tag.length > 128) ||
        utf8.encode(jsonEncode(toJson())).length > _maxMetadataBytes) {
      throw const FormatException('catalog.summary: metadata budget');
    }
  }

  factory CatalogDefinitionSummary.fromUnit(CatalogDefinitionUnit unit) {
    final value = unit.payload['value'];
    var data = value is Map ? _map(value) : unit.payload;
    if (unit.key.kind == CatalogDefinitionKind.borderRecord) {
      final draft = data['draft'];
      if (draft is Map && draft['definition'] is Map) {
        data = _map(draft['definition']);
      }
    }
    String? string(String field) {
      final value = data[field];
      if (value != null && value is! String) {
        throw const FormatException('catalog.summary: invalid metadata type');
      }
      return value as String?;
    }

    final rawTags = data['tags'];
    if (rawTags != null &&
        (rawTags is! List || rawTags.any((tag) => tag is! String))) {
      throw const FormatException('catalog.summary: invalid tags');
    }
    return CatalogDefinitionSummary(
      name: string('name') ?? string('resourceId') ?? unit.key.id,
      description: string('description'),
      tags: (rawTags as List?)?.cast<String>() ?? const [],
      familyId: string('familyId'),
      mapId: string('mapId'),
      role:
          string('role') ??
          (unit.key.kind == CatalogDefinitionKind.resourceLibraryEntry
              ? 'standard'
              : null),
      placementContext: string('placementContext'),
    );
  }

  factory CatalogDefinitionSummary.fromJson(Map<String, Object?> json) {
    _keys(json, {
      'name',
      'description',
      'tags',
      'familyId',
      'mapId',
      'role',
      'placementContext',
    });
    for (final field in [
      'name',
      'description',
      'familyId',
      'mapId',
      'role',
      'placementContext',
    ]) {
      if ((field == 'name' && json[field] is! String) ||
          (json[field] != null && json[field] is! String)) {
        throw const FormatException('catalog.summary: invalid metadata type');
      }
    }
    final tags = _list(json['tags'], _maxMetadataBytes);
    if (tags.any((tag) => tag is! String)) {
      throw const FormatException('catalog.summary: invalid tags');
    }
    return CatalogDefinitionSummary(
      name: json['name'] as String,
      description: json['description'] as String?,
      tags: tags.cast<String>(),
      familyId: json['familyId'] as String?,
      mapId: json['mapId'] as String?,
      role: json['role'] as String?,
      placementContext: json['placementContext'] as String?,
    );
  }

  final String name;
  final String? description;
  final List<String> tags;
  final String? familyId;
  final String? mapId;
  final String? role;
  final String? placementContext;

  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'tags': tags,
    'familyId': familyId,
    'mapId': mapId,
    'role': role,
    'placementContext': placementContext,
  };

  bool matches(String text) => [
    name,
    description ?? '',
    ...tags,
  ].any((value) => value.toLowerCase().contains(text));
}

final class CatalogIndexEntry {
  CatalogIndexEntry({
    required this.key,
    required this.reference,
    required this.summary,
  });
  final CatalogDefinitionKey key;
  final CatalogObjectReference reference;
  final CatalogDefinitionSummary summary;
  Map<String, Object?> toJson() => {
    'key': key.toJson(),
    'reference': reference.toJson(),
    'summary': summary.toJson(),
  };
}

void _verifySummary(CatalogIndexEntry entry, CatalogDefinitionUnit unit) {
  if (jsonEncode(entry.summary.toJson()) !=
      jsonEncode(CatalogDefinitionSummary.fromUnit(unit).toJson())) {
    throw const FormatException('catalog.summary: definition mismatch');
  }
}

final class CatalogStorageBuild {
  CatalogStorageBuild._(
    this.root,
    Map<String, List<int>> objects,
    this.definitionCount,
  ) : objects = Map.unmodifiable(
        objects.map((k, v) => MapEntry(k, List<int>.unmodifiable(v))),
      );
  final CatalogObjectReference root;
  final Map<String, List<int>> objects;
  final int definitionCount;
}

Iterable<List<CatalogIndexEntry>> _indexGroups(
  List<CatalogIndexEntry> entries,
  CatalogStorageLimits limits,
) sync* {
  final overhead = _encode({
    'type': 'leaf',
    'version': 2,
    'entries': [],
  }).length;
  var group = <CatalogIndexEntry>[];
  var bytes = overhead;
  for (final entry in entries) {
    final size = _encode(entry.toJson()).length;
    if (overhead + size > limits.maxIndexBytes) {
      throw const FormatException('catalog.index: entry byte limit');
    }
    if (group.isNotEmpty &&
        (group.length == limits.indexPageSize ||
            bytes + size + 1 > limits.maxIndexBytes)) {
      yield group;
      group = [];
      bytes = overhead;
    }
    bytes += size + (group.isEmpty ? 0 : 1);
    group.add(entry);
  }
  if (group.isNotEmpty) yield group;
}

final class CatalogStorageBuilder {
  CatalogStorageBuilder({CatalogStorageLimits? limits})
    : limits = limits ?? CatalogStorageLimits();
  final CatalogStorageLimits limits;

  CatalogStorageBuild build(Iterable<CatalogDefinitionUnit> definitions) {
    final units = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
    for (final unit in definitions) {
      if (units.length >= limits.maxDefinitions ||
          units.containsKey(unit.key)) {
        throw const FormatException(
          'catalog.build: duplicate key or definition limit',
        );
      }
      if (unit.references.length > limits.maxReferencesPerUnit) {
        throw const FormatException('catalog.build: reference limit');
      }
      units[unit.key] = unit;
    }
    for (final unit in units.values) {
      if (unit.references.any((r) => !units.containsKey(r))) {
        throw const FormatException('catalog.build: missing dependency');
      }
    }
    final objects = <String, List<int>>{};
    var storedBytes = 0;
    CatalogObjectReference put(Map<String, Object?> value, int byteLimit) {
      _freeze(value, limits);
      final bytes = _encode(value);
      if (bytes.length > byteLimit) {
        throw const FormatException('catalog.build: object byte limit');
      }
      final ref = CatalogObjectReference(
        sha256: crypto.sha256.convert(bytes).toString(),
        byteLength: bytes.length,
      );
      if (!objects.containsKey(ref.sha256)) {
        storedBytes += bytes.length;
        if (storedBytes > limits.maxStoredBytes) {
          throw const FormatException('catalog.build: total byte limit');
        }
      }
      objects[ref.sha256] = bytes;
      return ref;
    }

    final entries = (units.keys.toList()..sort())
        .map(
          (key) => CatalogIndexEntry(
            key: key,
            reference: put(units[key]!.toJson(), limits.maxUnitBytes),
            summary: CatalogDefinitionSummary.fromUnit(units[key]!),
          ),
        )
        .toList();
    final nodes = <_Node>[];
    for (final group in _indexGroups(entries, limits)) {
      final ref = put({
        'type': 'leaf',
        'version': 2,
        'entries': group.map((e) => e.toJson()).toList(),
      }, limits.maxIndexBytes);
      nodes.add(_Node(group.first.key, group.last.key, group.length, 0, ref));
    }
    var level = nodes;
    while (level.length > 1) {
      final next = <_Node>[];
      for (var i = 0; i < level.length; i += limits.indexPageSize) {
        final group = level.sublist(
          i,
          (i + limits.indexPageSize).clamp(0, level.length),
        );
        final height = group.first.height + 1;
        if (height > limits.maxIndexDepth) {
          throw const FormatException('catalog.build: index depth');
        }
        final ref = put({
          'type': 'branch',
          'version': 2,
          'children': group.map((n) => n.toJson()).toList(),
        }, limits.maxIndexBytes);
        next.add(
          _Node(
            group.first.first,
            group.last.last,
            group.fold(0, (n, e) => n + e.count),
            height,
            ref,
          ),
        );
      }
      level = next;
    }
    final root = put({
      'type': 'root',
      'version': 2,
      'definitionCount': units.length,
      'index': level.isEmpty ? null : level.single.toJson(),
    }, limits.maxIndexBytes);
    return CatalogStorageBuild._(root, objects, units.length);
  }
}

final class CatalogDefinitionPage {
  CatalogDefinitionPage._(Iterable<CatalogIndexEntry> items, this.nextCursor)
    : items = List.unmodifiable(items);
  final List<CatalogIndexEntry> items;
  final String? nextCursor;
}

final class CatalogSearchPage {
  CatalogSearchPage({
    required Iterable<CatalogIndexEntry> items,
    required this.totalAvailable,
    this.nextCursor,
  }) : items = List.unmodifiable(items);
  final List<CatalogIndexEntry> items;
  final int totalAvailable;
  final String? nextCursor;
}

typedef CatalogObjectReader =
    Future<List<int>> Function(CatalogObjectReference reference);

typedef CatalogObjectReaderSync =
    List<int> Function(CatalogObjectReference reference);

final class CatalogStorageRead {
  CatalogStorageRead._(
    Iterable<CatalogDefinitionUnit> units,
    Iterable<CatalogObjectReference> references,
    this.storedBytes,
  ) : units = List.unmodifiable(units),
      objectReferences = List.unmodifiable(references);
  final List<CatalogDefinitionUnit> units;
  final List<CatalogObjectReference> objectReferences;
  final int storedBytes;
}

final class CatalogStoragePatch {
  CatalogStoragePatch._(
    this.beforeRoot,
    this.root,
    this.definitionCount,
    Map<String, List<int>> objects,
    this._limits,
    this._storedBytes,
  ) : objects = Map.unmodifiable(
        objects.map(
          (key, value) => MapEntry(key, List<int>.unmodifiable(value)),
        ),
      );

  final CatalogObjectReference beforeRoot;
  final CatalogObjectReference root;
  final int definitionCount;
  final Map<String, List<int>> objects;
  final CatalogStorageLimits _limits;
  final int _storedBytes;
  bool get isEmpty => beforeRoot == root;

  Future<CatalogSnapshot> nextSnapshot({
    required CatalogObjectReader readObject,
  }) async {
    final snapshot = await CatalogSnapshot.open(
      root: root,
      readObject: readObject,
      limits: _limits,
    );
    snapshot._admittedStoredBytes = _storedBytes;
    return snapshot;
  }
}

final class CatalogSnapshot {
  CatalogSnapshot._(
    this.root,
    this._readObject,
    this.limits,
    this.definitionCount,
    this._index,
  );
  static Future<CatalogSnapshot> open({
    required CatalogObjectReference root,
    required CatalogObjectReader readObject,
    CatalogStorageLimits? limits,
  }) async {
    final effective = limits ?? CatalogStorageLimits();
    final json = await _read(
      root,
      readObject,
      effective,
      effective.maxIndexBytes,
    );
    _envelope(json, 'root', {'definitionCount', 'index'});
    final count = _integer(
      json['definitionCount'],
      0,
      effective.maxDefinitions,
    );
    final index = json['index'] == null
        ? null
        : _Node.fromJson(_map(json['index']), effective);
    if ((count == 0) != (index == null) ||
        (index != null && index.count != count)) {
      throw const FormatException('catalog.root: count mismatch');
    }
    return CatalogSnapshot._(root, readObject, effective, count, index);
  }

  static CatalogStorageRead readAllSync({
    required CatalogObjectReference root,
    required CatalogObjectReaderSync readObject,
    CatalogStorageLimits? limits,
  }) {
    final effective = limits ?? CatalogStorageLimits();
    final references = <String, CatalogObjectReference>{};
    var storedBytes = 0;
    Map<String, Object?> read(CatalogObjectReference reference, int maximum) {
      if (reference.byteLength > maximum) {
        throw const FormatException('catalog.object: byte limit');
      }
      final previous = references[reference.sha256];
      if (previous != null && previous != reference) {
        throw const FormatException(
          'catalog.validate: conflicting object reference',
        );
      }
      if (previous == null) {
        references[reference.sha256] = reference;
        storedBytes += reference.byteLength;
        if (storedBytes > effective.maxStoredBytes) {
          throw const FormatException('catalog.validate: total byte limit');
        }
      }
      return _decodeObject(
        reference,
        readObject(reference),
        effective,
        maximum,
      );
    }

    final json = read(root, effective.maxIndexBytes);
    _envelope(json, 'root', {'definitionCount', 'index'});
    final count = _integer(
      json['definitionCount'],
      0,
      effective.maxDefinitions,
    );
    final index = json['index'] == null
        ? null
        : _Node.fromJson(_map(json['index']), effective);
    if ((count == 0) != (index == null) ||
        (index != null && index.count != count)) {
      throw const FormatException('catalog.root: count mismatch');
    }
    final entries = <CatalogIndexEntry>[];
    final seen = <String>{root.sha256};
    void visit(_Node node) {
      if (!seen.add(node.reference.sha256)) {
        throw const FormatException('catalog.index: cycle or repeated node');
      }
      final value = read(node.reference, effective.maxIndexBytes);
      if (node.height == 0) {
        _envelope(value, 'leaf', {'entries'});
        final page = _list(value['entries'], effective.indexPageSize).map((
          item,
        ) {
          final entry = _map(item);
          _keys(entry, {'key', 'reference', 'summary'});
          return CatalogIndexEntry(
            key: CatalogDefinitionKey.fromJson(_map(entry['key'])),
            reference: CatalogObjectReference.fromJson(
              _map(entry['reference']),
            ),
            summary: CatalogDefinitionSummary.fromJson(_map(entry['summary'])),
          );
        }).toList();
        _ordered(page.map((entry) => entry.key).toList());
        if (page.isEmpty ||
            page.length != node.count ||
            page.first.key != node.first ||
            page.last.key != node.last) {
          throw const FormatException('catalog.leaf: invalid range or count');
        }
        if (entries.length + page.length > effective.maxDefinitions) {
          throw const FormatException('catalog.validate: definition limit');
        }
        entries.addAll(page);
      } else {
        _envelope(value, 'branch', {'children'});
        final children = _list(
          value['children'],
          effective.indexPageSize,
        ).map((v) => _Node.fromJson(_map(v), effective)).toList();
        if (children.isEmpty ||
            children.first.first != node.first ||
            children.last.last != node.last ||
            children.fold<int>(0, (sum, child) => sum + child.count) !=
                node.count ||
            children.any((child) => child.height != node.height - 1)) {
          throw const FormatException(
            'catalog.branch: invalid range count or height',
          );
        }
        for (var i = 1; i < children.length; i++) {
          if (children[i - 1].last.compareTo(children[i].first) >= 0) {
            throw const FormatException('catalog.branch: unordered ranges');
          }
        }
        for (final child in children) {
          visit(child);
        }
      }
    }

    if (index != null) {
      visit(index);
    }
    if (entries.length != count) {
      throw const FormatException(
        'catalog.validate: definition count mismatch',
      );
    }
    _ordered(entries.map((entry) => entry.key).toList());
    final keys = entries.map((entry) => entry.key).toSet();
    final units = <CatalogDefinitionUnit>[];
    for (final entry in entries) {
      final value = read(entry.reference, effective.maxUnitBytes);
      _envelope(value, 'unit', {'key', 'payload', 'references'});
      final key = CatalogDefinitionKey.fromJson(_map(value['key']));
      if (key != entry.key) {
        throw const FormatException('catalog.unit: indexed key mismatch');
      }
      final dependencies = _list(
        value['references'],
        effective.maxReferencesPerUnit,
      ).map((v) => CatalogDefinitionKey.fromJson(_map(v))).toList();
      _ordered(dependencies);
      if (dependencies.any((key) => !keys.contains(key))) {
        throw const FormatException('catalog.validate: missing dependency');
      }
      final unit = CatalogDefinitionUnit(
        key: key,
        payload: _map(value['payload']),
        references: dependencies,
      );
      _verifySummary(entry, unit);
      units.add(unit);
    }
    return CatalogStorageRead._(units, references.values, storedBytes);
  }

  final CatalogObjectReference root;
  final CatalogObjectReader _readObject;
  final CatalogStorageLimits limits;
  final int definitionCount;
  final _Node? _index;
  int? _admittedStoredBytes;
  int? get admittedStoredBytes => _admittedStoredBytes;

  void restoreTrustedIndexAdmission({required int storedBytes}) {
    if (storedBytes < root.byteLength || storedBytes > limits.maxStoredBytes) {
      throw const FormatException('catalog.admission: invalid stored bytes');
    }
    _admittedStoredBytes = storedBytes;
  }

  final _indexPages = <CatalogObjectReference, Future<_CatalogIndexPage>>{};
  var _indexPageBytes = 0;

  Future<_CatalogIndexPage> _indexPage(
    CatalogObjectReference reference, {
    required bool reuse,
  }) {
    if (reference.byteLength > limits.maxIndexBytes) {
      throw const FormatException('catalog.object: byte limit');
    }
    if (!reuse) return _loadIndexPage(reference);
    final existing = _indexPages.remove(reference);
    if (existing != null) {
      _indexPages[reference] = existing;
      return existing;
    }
    final future = _loadIndexPage(reference);
    final maximum = limits.maxStoredBytes < 4 * 1024 * 1024
        ? limits.maxStoredBytes
        : 4 * 1024 * 1024;
    if (reference.byteLength > maximum) return future;
    _indexPages[reference] = future;
    _indexPageBytes += reference.byteLength;
    while (_indexPageBytes > maximum || _indexPages.length > 256) {
      final first = _indexPages.keys.first;
      _indexPages.remove(first);
      _indexPageBytes -= first.byteLength;
    }
    future.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (identical(_indexPages[reference], future)) {
          _indexPages.remove(reference);
          _indexPageBytes -= reference.byteLength;
        }
      },
    );
    return future;
  }

  Future<_CatalogIndexPage> _loadIndexPage(
    CatalogObjectReference reference,
  ) async {
    final json = await _read(
      reference,
      _readObject,
      limits,
      limits.maxIndexBytes,
    );
    if (json['type'] == 'leaf') {
      _envelope(json, 'leaf', {'entries'});
      final entries = _list(json['entries'], limits.indexPageSize).map((value) {
        final map = _map(value);
        _keys(map, {'key', 'reference', 'summary'});
        return CatalogIndexEntry(
          key: CatalogDefinitionKey.fromJson(_map(map['key'])),
          reference: CatalogObjectReference.fromJson(_map(map['reference'])),
          summary: CatalogDefinitionSummary.fromJson(_map(map['summary'])),
        );
      }).toList();
      _ordered(entries.map((entry) => entry.key).toList());
      return _CatalogIndexPage.leaf(entries);
    }
    _envelope(json, 'branch', {'children'});
    return _CatalogIndexPage.branch(
      _list(
        json['children'],
        limits.indexPageSize,
      ).map((value) => _Node.fromJson(_map(value), limits)),
    );
  }

  Future<CatalogStoragePatch> patch({
    Iterable<CatalogDefinitionUnit> upserts = const [],
    Iterable<CatalogDefinitionKey> removals = const [],
  }) async {
    final changed = <CatalogDefinitionKey, CatalogDefinitionUnit?>{};
    for (final unit in upserts) {
      if (changed.containsKey(unit.key) ||
          changed.length >= limits.maxDefinitions ||
          unit.references.length > limits.maxReferencesPerUnit) {
        throw const FormatException(
          'catalog.patch: duplicate key or reference limit',
        );
      }
      changed[unit.key] = unit;
    }
    var removalCount = 0;
    for (final key in removals) {
      if (changed.containsKey(key) || ++removalCount > limits.maxDefinitions) {
        throw const FormatException('catalog.patch: duplicate mutation key');
      }
      changed[key] = null;
    }
    if (_admittedStoredBytes == null) {
      await validate();
    }
    final dependencies = <CatalogDefinitionKey>{};
    for (final unit in changed.values.whereType<CatalogDefinitionUnit>()) {
      for (final key in unit.references) {
        if ((changed.containsKey(key) && changed[key] == null) ||
            (!changed.containsKey(key) &&
                dependencies.add(key) &&
                await lookup(key) == null)) {
          throw const FormatException('catalog.patch: missing dependency');
        }
      }
    }
    if (changed.values.any((unit) => unit == null)) {
      final entries = await _collect(
        after: null,
        take: limits.maxDefinitions + 1,
      );
      for (final entry in entries) {
        if (changed.containsKey(entry.key)) {
          continue;
        }
        final unit = await _unit(entry);
        if (unit.references.any(
          (key) => changed.containsKey(key) && changed[key] == null,
        )) {
          throw const FormatException(
            'catalog.patch: removed dependency remains referenced',
          );
        }
      }
    }
    return _CatalogPatchBuilder(this).build(changed);
  }

  Future<CatalogDefinitionUnit?> lookup(CatalogDefinitionKey key) async {
    final entry = await indexEntry(key);
    return entry == null ? null : _unit(entry);
  }

  Future<CatalogIndexEntry?> indexEntry(CatalogDefinitionKey key) async {
    final index = _index;
    if (index == null || !_contains(index, key)) {
      return null;
    }
    final entries = await _collect(
      after: null,
      kind: key.kind,
      exact: key,
      take: 1,
    );
    return entries.isEmpty ? null : entries.single;
  }

  Future<CatalogDefinitionPage> page({
    CatalogDefinitionKind? kind,
    int limit = 50,
    String? cursor,
  }) async {
    if (limit < 1 || limit > limits.indexPageSize) {
      throw ArgumentError('catalog.page: invalid page size');
    }
    CatalogDefinitionKey? after;
    if (cursor != null) {
      if (cursor.length > 4096) {
        throw const FormatException('catalog.cursor: byte limit');
      }
      Map<String, Object?> parsed;
      String source;
      try {
        source = utf8.decode(base64Url.decode(base64Url.normalize(cursor)));
        parsed = _map(jsonDecode(source));
      } catch (_) {
        throw const FormatException('catalog.cursor: invalid encoding');
      }
      if (utf8.decode(_encode(parsed)) != source) {
        throw const FormatException('catalog.cursor: non canonical JSON');
      }
      _keys(parsed, {'root', 'kind', 'after', 'version'});
      if (parsed['version'] is! int ||
          parsed['version'] != 2 ||
          parsed['root'] != root.sha256 ||
          parsed['kind'] != kind?.name) {
        throw const FormatException(
          'catalog.cursor: snapshot or filter mismatch',
        );
      }
      after = CatalogDefinitionKey.fromJson(_map(parsed['after']));
      if (kind != null && after.kind != kind) {
        throw const FormatException('catalog.cursor: key filter mismatch');
      }
    }
    final found = await _collect(after: after, kind: kind, take: limit + 1);
    final items = found.take(limit).toList();
    final next = found.length > limit
        ? base64Url.encode(
            _encode({
              'root': root.sha256,
              'kind': kind?.name,
              'after': items.last.key.toJson(),
              'version': 2,
            }),
          )
        : null;
    return CatalogDefinitionPage._(items, next);
  }

  Future<List<CatalogDefinitionUnit>> closure(
    Iterable<CatalogDefinitionKey> roots,
  ) async {
    var bytes = root.byteLength;
    final objects = <String>{root.sha256};
    if (bytes > limits.maxStoredBytes) {
      throw const FormatException('catalog.closure: total byte limit');
    }
    final bounded = CatalogSnapshot._(
      root,
      (reference) async {
        if (objects.add(reference.sha256)) {
          bytes += reference.byteLength;
          if (bytes > limits.maxStoredBytes) {
            throw const FormatException('catalog.closure: total byte limit');
          }
        }
        return _readObject(reference);
      },
      limits,
      definitionCount,
      _index,
    );
    final seen = <CatalogDefinitionKey>{};
    final result = <CatalogDefinitionUnit>[];
    Future<void> visit(CatalogDefinitionKey key, int depth) async {
      if (seen.contains(key)) {
        return;
      }
      if (depth > limits.maxClosureDepth ||
          seen.length >= limits.maxClosureNodes) {
        throw const FormatException('catalog.closure: budget exceeded');
      }
      seen.add(key);
      final unit = await bounded.lookup(key);
      if (unit == null) {
        throw const FormatException('catalog.closure: missing dependency');
      }
      result.add(unit);
      for (final reference in unit.references) {
        await visit(reference, depth + 1);
      }
    }

    for (final key in roots) {
      await visit(key, 0);
    }
    return List.unmodifiable(result);
  }

  Future<CatalogSearchPage> search({
    CatalogDefinitionKind? kind,
    String text = '',
    int limit = 50,
    String? cursor,
    String? familyId,
    String? placementContext,
  }) async {
    if (limit < 1 ||
        limit > limits.indexPageSize ||
        text.length > 512 ||
        (familyId?.length ?? 0) > 512 ||
        (placementContext?.length ?? 0) > 512) {
      throw ArgumentError('catalog.search: invalid search budget');
    }
    final normalized = text.trim().toLowerCase();
    final signature = jsonEncode([
      kind?.name,
      normalized,
      familyId,
      placementContext,
    ]);
    CatalogDefinitionKey? after;
    if (cursor != null) {
      if (cursor.length > 4096) {
        throw const FormatException('catalog.cursor: byte limit');
      }
      try {
        final source = utf8.decode(
          base64Url.decode(base64Url.normalize(cursor)),
        );
        final data = _map(jsonDecode(source));
        if (utf8.decode(_encode(data)) != source) {
          throw const FormatException('catalog.cursor: non canonical JSON');
        }
        _keys(data, {'version', 'root', 'query', 'after'});
        if (data['version'] is! int ||
            data['version'] != 2 ||
            data['root'] != root.sha256 ||
            data['query'] != signature) {
          throw const FormatException('catalog.cursor: query mismatch');
        }
        after = CatalogDefinitionKey.fromJson(_map(data['after']));
        if (kind != null && after.kind != kind) {
          throw const FormatException('catalog.cursor: kind mismatch');
        }
      } catch (_) {
        throw const FormatException('catalog.cursor: invalid search cursor');
      }
    }
    var total = 0;
    final selected = <CatalogIndexEntry>[];
    String? indexCursor;
    do {
      final current = await page(
        kind: kind,
        limit: limits.indexPageSize,
        cursor: indexCursor,
      );
      for (final entry in current.items) {
        final summary = entry.summary;
        if (!summary.matches(normalized) ||
            (familyId != null && summary.familyId != familyId) ||
            (placementContext != null &&
                summary.placementContext != placementContext)) {
          continue;
        }
        total++;
        if ((after == null || entry.key.compareTo(after) > 0) &&
            selected.length <= limit) {
          selected.add(entry);
        }
      }
      indexCursor = current.nextCursor;
    } while (indexCursor != null);
    final more = selected.length > limit;
    final items = selected.take(limit).toList();
    return CatalogSearchPage(
      items: items,
      totalAvailable: total,
      nextCursor: more
          ? base64Url.encode(
              _encode({
                'version': 2,
                'root': root.sha256,
                'query': signature,
                'after': items.last.key.toJson(),
              }),
            )
          : null,
    );
  }

  Future<void> validate() async {
    await objectReferences();
  }

  Future<void> admitIndex() async {
    await _inspectObjectReferences(validateUnits: false);
  }

  Future<List<CatalogObjectReference>> objectReferences() =>
      _inspectObjectReferences(validateUnits: true);

  Future<List<CatalogDefinitionUnit>> readAllUnits() async {
    final units = <CatalogDefinitionUnit>[];
    await _inspectObjectReferences(validateUnits: true, onUnit: units.add);
    return List.unmodifiable(units);
  }

  Future<List<CatalogObjectReference>> _inspectObjectReferences({
    required bool validateUnits,
    void Function(CatalogDefinitionUnit)? onUnit,
  }) async {
    await _read(root, _readObject, limits, limits.maxIndexBytes);
    var bytes = root.byteLength;
    final objects = <String, CatalogObjectReference>{root.sha256: root};
    void admit(CatalogObjectReference ref) {
      final existing = objects[ref.sha256];
      if (existing == null) {
        objects[ref.sha256] = ref;
        bytes += ref.byteLength;
      } else if (existing != ref) {
        throw const FormatException(
          'catalog.validate: conflicting object reference',
        );
      }
      if (bytes > limits.maxStoredBytes) {
        throw const FormatException('catalog.validate: total byte limit');
      }
    }

    admit(root);
    final entries = await _collect(
      after: null,
      take: limits.maxDefinitions + 1,
      onNode: admit,
    );
    if (entries.length != definitionCount) {
      throw const FormatException(
        'catalog.validate: definition count mismatch',
      );
    }
    for (final entry in entries) {
      admit(entry.reference);
    }
    if (validateUnits) {
      final keys = entries.map((e) => e.key).toSet();
      for (final entry in entries) {
        final unit = await _unit(entry);
        if (unit.references.any((k) => !keys.contains(k))) {
          throw const FormatException('catalog.validate: missing dependency');
        }
        onUnit?.call(unit);
      }
    }
    _admittedStoredBytes = bytes;
    return List.unmodifiable(objects.values);
  }

  Future<CatalogDefinitionUnit> _unit(CatalogIndexEntry entry) async {
    final json = await _read(
      entry.reference,
      _readObject,
      limits,
      limits.maxUnitBytes,
    );
    _envelope(json, 'unit', {'key', 'payload', 'references'});
    final key = CatalogDefinitionKey.fromJson(_map(json['key']));
    if (key != entry.key) {
      throw const FormatException('catalog.unit: indexed key mismatch');
    }
    final refs = _list(
      json['references'],
      limits.maxReferencesPerUnit,
    ).map((r) => CatalogDefinitionKey.fromJson(_map(r))).toList();
    _ordered(refs);
    final unit = CatalogDefinitionUnit(
      key: key,
      payload: _map(json['payload']),
      references: refs,
    );
    _verifySummary(entry, unit);
    return unit;
  }

  Future<List<CatalogIndexEntry>> _collect({
    required CatalogDefinitionKey? after,
    CatalogDefinitionKind? kind,
    CatalogDefinitionKey? exact,
    required int take,
    void Function(CatalogObjectReference)? onNode,
  }) async {
    final found = <CatalogIndexEntry>[];
    final seen = <String>{};
    bool shouldVisit(_Node node) =>
        found.length < take &&
        (after == null || node.last.compareTo(after) > 0) &&
        (kind == null ||
            (node.first.kind.name.compareTo(kind.name) <= 0 &&
                node.last.kind.name.compareTo(kind.name) >= 0)) &&
        (exact == null || _contains(node, exact));

    Future<void> visit(_Node node) async {
      if (!shouldVisit(node)) return;
      if (!seen.add(node.reference.sha256)) {
        throw const FormatException('catalog.index: cycle or repeated node');
      }
      onNode?.call(node.reference);
      final page = await _indexPage(node.reference, reuse: onNode == null);
      if (node.height == 0) {
        final entries = page.entries;
        if (entries == null) {
          throw const FormatException('catalog.leaf: expected leaf page');
        }
        if (entries.isEmpty ||
            entries.length != node.count ||
            entries.first.key != node.first ||
            entries.last.key != node.last) {
          throw const FormatException('catalog.leaf: invalid range or count');
        }
        for (final entry in entries) {
          if ((after == null || entry.key.compareTo(after) > 0) &&
              (kind == null || entry.key.kind == kind) &&
              (exact == null || entry.key == exact)) {
            found.add(entry);
          }
          if (found.length >= take) {
            return;
          }
        }
      } else {
        final children = page.children;
        if (children == null) {
          throw const FormatException('catalog.branch: expected branch page');
        }
        if (children.isEmpty ||
            children.first.first != node.first ||
            children.last.last != node.last ||
            children.fold<int>(0, (n, c) => n + c.count) != node.count ||
            children.any((c) => c.height != node.height - 1)) {
          throw const FormatException(
            'catalog.branch: invalid range count or height',
          );
        }
        for (var i = 1; i < children.length; i++) {
          if (children[i - 1].last.compareTo(children[i].first) >= 0) {
            throw const FormatException('catalog.branch: unordered ranges');
          }
        }
        for (final child in children) {
          if (shouldVisit(child)) await visit(child);
        }
      }
    }

    if (_index != null) {
      await visit(_index);
    }
    return found;
  }
}

final class _CatalogPatchBuilder {
  _CatalogPatchBuilder(this.snapshot);

  final CatalogSnapshot snapshot;
  final _objects = <String, List<int>>{};
  final _removed = <String, CatalogObjectReference>{};
  CatalogStorageLimits get limits => snapshot.limits;

  CatalogObjectReference _put(Map<String, Object?> value, int maxBytes) {
    _freeze(value, limits);
    final bytes = _encode(value);
    if (bytes.length > maxBytes) {
      throw const FormatException('catalog.patch: object byte limit');
    }
    final reference = CatalogObjectReference(
      sha256: crypto.sha256.convert(bytes).toString(),
      byteLength: bytes.length,
    );
    _objects[reference.sha256] = bytes;
    return reference;
  }

  _Node _leaf(List<CatalogIndexEntry> entries) {
    final reference = _put({
      'type': 'leaf',
      'version': 2,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    }, limits.maxIndexBytes);
    return _Node(
      entries.first.key,
      entries.last.key,
      entries.length,
      0,
      reference,
    );
  }

  _Node _branch(List<_Node> children) {
    final height = children.first.height + 1;
    if (height > limits.maxIndexDepth) {
      throw const FormatException('catalog.patch: index depth');
    }
    final reference = _put({
      'type': 'branch',
      'version': 2,
      'children': children.map((child) => child.toJson()).toList(),
    }, limits.maxIndexBytes);
    return _Node(
      children.first.first,
      children.last.last,
      children.fold(0, (sum, child) => sum + child.count),
      height,
      reference,
    );
  }

  List<_Node> _leaves(List<CatalogIndexEntry> entries) => [
    for (final group in _indexGroups(entries, limits)) _leaf(group),
  ];

  List<_Node> _branches(List<_Node> children) => [
    for (var i = 0; i < children.length; i += limits.indexPageSize)
      _branch(
        children.sublist(
          i,
          (i + limits.indexPageSize).clamp(0, children.length),
        ),
      ),
  ];

  Future<List<_Node>> _apply(
    _Node? node,
    Map<CatalogDefinitionKey, CatalogDefinitionUnit?> changes,
  ) async {
    if (changes.isEmpty) {
      return node == null ? [] : [node];
    }
    if (node == null || node.height == 0) {
      final entries = <CatalogDefinitionKey, CatalogIndexEntry>{};
      if (node != null) {
        final json = await _read(
          node.reference,
          snapshot._readObject,
          limits,
          limits.maxIndexBytes,
        );
        _envelope(json, 'leaf', {'entries'});
        for (final item in _list(json['entries'], limits.indexPageSize)) {
          final value = _map(item);
          _keys(value, {'key', 'reference', 'summary'});
          final key = CatalogDefinitionKey.fromJson(_map(value['key']));
          entries[key] = CatalogIndexEntry(
            key: key,
            reference: CatalogObjectReference.fromJson(
              _map(value['reference']),
            ),
            summary: CatalogDefinitionSummary.fromJson(_map(value['summary'])),
          );
        }
      }
      var modified = false;
      for (final mutation in changes.entries) {
        final previous = entries[mutation.key];
        final unit = mutation.value;
        if (unit == null) {
          if (previous != null) {
            _removed[previous.reference.sha256] = previous.reference;
            entries.remove(mutation.key);
            modified = true;
          }
        } else {
          final reference = _put(unit.toJson(), limits.maxUnitBytes);
          if (previous?.reference != reference) {
            if (previous != null) {
              _removed[previous.reference.sha256] = previous.reference;
            }
            entries[mutation.key] = CatalogIndexEntry(
              key: mutation.key,
              reference: reference,
              summary: CatalogDefinitionSummary.fromUnit(unit),
            );
            modified = true;
          } else {
            _objects.remove(reference.sha256);
          }
        }
      }
      if (!modified) {
        return node == null ? [] : [node];
      }
      if (node != null) {
        _removed[node.reference.sha256] = node.reference;
      }
      final ordered = entries.keys.toList()..sort();
      return _leaves(ordered.map((key) => entries[key]!).toList());
    }
    final json = await _read(
      node.reference,
      snapshot._readObject,
      limits,
      limits.maxIndexBytes,
    );
    _envelope(json, 'branch', {'children'});
    final children = _list(
      json['children'],
      limits.indexPageSize,
    ).map((value) => _Node.fromJson(_map(value), limits)).toList();
    final partitioned =
        <int, Map<CatalogDefinitionKey, CatalogDefinitionUnit?>>{};
    for (final mutation in changes.entries) {
      var index = children.indexWhere(
        (child) => mutation.key.compareTo(child.last) <= 0,
      );
      if (index < 0) {
        index = children.length - 1;
      }
      (partitioned[index] ??= {})[mutation.key] = mutation.value;
    }
    final next = <_Node>[];
    var modified = false;
    for (var index = 0; index < children.length; index++) {
      final replacements = await _apply(
        children[index],
        partitioned[index] ?? {},
      );
      next.addAll(replacements);
      if (replacements.length != 1 ||
          replacements.single.reference != children[index].reference) {
        modified = true;
      }
    }
    if (!modified) {
      return [node];
    }
    _removed[node.reference.sha256] = node.reference;
    return _branches(next);
  }

  Future<CatalogStoragePatch> build(
    Map<CatalogDefinitionKey, CatalogDefinitionUnit?> changes,
  ) async {
    var nodes = await _apply(snapshot._index, changes);
    while (nodes.length > 1) {
      nodes = _branches(nodes);
    }
    var index = nodes.isEmpty ? null : nodes.single;
    while (index != null &&
        index.height > 0 &&
        _objects.containsKey(index.reference.sha256)) {
      final json = _map(
        jsonDecode(utf8.decode(_objects[index.reference.sha256]!)),
      );
      final children = _list(json['children'], limits.indexPageSize);
      if (children.length != 1) {
        break;
      }
      index = _Node.fromJson(_map(children.single), limits);
    }
    final count = index?.count ?? 0;
    if (count > limits.maxDefinitions) {
      throw const FormatException('catalog.patch: definition limit');
    }
    if (index?.reference == snapshot._index?.reference) {
      return CatalogStoragePatch._(
        snapshot.root,
        snapshot.root,
        snapshot.definitionCount,
        {},
        limits,
        snapshot._admittedStoredBytes!,
      );
    }
    final root = _put({
      'type': 'root',
      'version': 2,
      'definitionCount': count,
      'index': index?.toJson(),
    }, limits.maxIndexBytes);
    _removed[snapshot.root.sha256] = snapshot.root;
    final reachable = <String, List<int>>{};
    void visit(CatalogObjectReference reference) {
      final bytes = _objects[reference.sha256];
      if (bytes == null || reachable.containsKey(reference.sha256)) {
        return;
      }
      reachable[reference.sha256] = bytes;
      final json = _map(jsonDecode(utf8.decode(bytes)));
      if (json['type'] == 'root') {
        if (json['index'] != null) {
          visit(_Node.fromJson(_map(json['index']), limits).reference);
        }
      } else if (json['type'] == 'branch') {
        for (final child in _list(json['children'], limits.indexPageSize)) {
          visit(_Node.fromJson(_map(child), limits).reference);
        }
      } else if (json['type'] == 'leaf') {
        for (final entry in _list(json['entries'], limits.indexPageSize)) {
          visit(
            CatalogObjectReference.fromJson(_map(_map(entry)['reference'])),
          );
        }
      }
    }

    visit(root);
    final removedBytes = _removed.values.fold(
      0,
      (sum, ref) => sum + ref.byteLength,
    );
    final addedBytes = reachable.values.fold(
      0,
      (sum, bytes) => sum + bytes.length,
    );
    final storedBytes =
        snapshot._admittedStoredBytes! - removedBytes + addedBytes;
    if (storedBytes > limits.maxStoredBytes) {
      throw const FormatException('catalog.patch: total byte limit');
    }
    return CatalogStoragePatch._(
      snapshot.root,
      root,
      count,
      reachable,
      limits,
      storedBytes,
    );
  }
}

final class _CatalogIndexPage {
  _CatalogIndexPage.leaf(Iterable<CatalogIndexEntry> values)
    : entries = List.unmodifiable(values),
      children = null;

  _CatalogIndexPage.branch(Iterable<_Node> values)
    : entries = null,
      children = List.unmodifiable(values);

  final List<CatalogIndexEntry>? entries;
  final List<_Node>? children;
}

final class _Node {
  _Node(this.first, this.last, this.count, this.height, this.reference);
  factory _Node.fromJson(
    Map<String, Object?> json,
    CatalogStorageLimits limits,
  ) {
    _keys(json, {'first', 'last', 'count', 'height', 'reference'});
    final first = CatalogDefinitionKey.fromJson(_map(json['first']));
    final last = CatalogDefinitionKey.fromJson(_map(json['last']));
    if (first.compareTo(last) > 0) {
      throw const FormatException('catalog.index: reversed range');
    }
    return _Node(
      first,
      last,
      _integer(json['count'], 1, limits.maxDefinitions),
      _integer(json['height'], 0, limits.maxIndexDepth),
      CatalogObjectReference.fromJson(_map(json['reference'])),
    );
  }
  final CatalogDefinitionKey first;
  final CatalogDefinitionKey last;
  final int count;
  final int height;
  final CatalogObjectReference reference;
  Map<String, Object?> toJson() => {
    'first': first.toJson(),
    'last': last.toJson(),
    'count': count,
    'height': height,
    'reference': reference.toJson(),
  };
}

bool _contains(_Node node, CatalogDefinitionKey key) =>
    node.first.compareTo(key) <= 0 && node.last.compareTo(key) >= 0;
void _ordered(List<CatalogDefinitionKey> keys) {
  for (var i = 1; i < keys.length; i++) {
    if (keys[i - 1].compareTo(keys[i]) >= 0) {
      throw const FormatException('catalog: duplicate or unordered keys');
    }
  }
}

int _integer(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('catalog: integer outside bounds');
  }
  return value;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('catalog: expected object');
  }
  return value;
}

List<Object?> _list(Object? value, int max) {
  if (value is! List<Object?> || value.length > max) {
    throw const FormatException('catalog: expected bounded list');
  }
  return value;
}

void _keys(Map<String, Object?> json, Set<String> expected) {
  if (json.length != expected.length ||
      json.keys.any((k) => !expected.contains(k))) {
    throw const FormatException('catalog: unknown or missing field');
  }
}

void _envelope(Map<String, Object?> json, String type, Set<String> fields) {
  _keys(json, {'type', 'version', ...fields});
  if (json['type'] != type || json['version'] is! int || json['version'] != 2) {
    throw const FormatException('catalog: unsupported object type or version');
  }
}

Object? _freeze(Object? value, CatalogStorageLimits limits) {
  var count = 0;
  Object? visit(Object? item, int depth) {
    if (++count > limits.maxJsonValues || depth > limits.maxJsonDepth) {
      throw const FormatException('catalog.json: value or depth limit');
    }
    if (item == null || item is bool || item is String || item is int) {
      return item;
    }
    if (item is double && item.isFinite) {
      return item;
    }
    if (item is List) {
      return List<Object?>.unmodifiable(item.map((e) => visit(e, depth + 1)));
    }
    if (item is Map<String, Object?>) {
      final keys = item.keys.toList()..sort();
      return Map<String, Object?>.unmodifiable({
        for (final key in keys) key: visit(item[key], depth + 1),
      });
    }
    throw const FormatException('catalog.json: non JSON value');
  }

  return visit(value, 0);
}

List<int> _encode(Map<String, Object?> json) =>
    utf8.encode(jsonEncode(_freeze(json, CatalogStorageLimits())));

Future<Map<String, Object?>> _read(
  CatalogObjectReference ref,
  CatalogObjectReader reader,
  CatalogStorageLimits limits,
  int maxBytes,
) async {
  if (ref.byteLength > maxBytes) {
    throw const FormatException('catalog.object: byte limit');
  }
  return _decodeObject(ref, await reader(ref), limits, maxBytes);
}

Map<String, Object?> _decodeObject(
  CatalogObjectReference ref,
  List<int> bytes,
  CatalogStorageLimits limits,
  int maxBytes,
) {
  if (ref.byteLength > maxBytes) {
    throw const FormatException('catalog.object: byte limit');
  }
  if (bytes.length != ref.byteLength ||
      bytes.any((b) => b < 0 || b > 255) ||
      crypto.sha256.convert(bytes).toString() != ref.sha256) {
    throw const FormatException('catalog.object: size or digest mismatch');
  }
  String source;
  try {
    source = utf8.decode(bytes);
  } catch (_) {
    throw const FormatException('catalog.object: invalid UTF8');
  }
  var depth = 0;
  var quoted = false;
  var escaped = false;
  var tokens = 0;
  for (final c in source.codeUnits) {
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (c == 92) {
        escaped = true;
      } else if (c == 34) {
        quoted = false;
      }
      continue;
    }
    if (c == 34) {
      quoted = true;
      tokens++;
    }
    if (c == 123 || c == 91) {
      depth++;
      tokens++;
      if (depth > limits.maxJsonDepth + 1) {
        throw const FormatException(
          'catalog.object: depth limit before decode',
        );
      }
    }
    if (c == 125 || c == 93) {
      depth--;
    }
    if (c == 44 || c == 58) {
      tokens++;
    }
    if (tokens > limits.maxJsonValues * 4) {
      throw const FormatException('catalog.object: value limit before decode');
    }
  }
  final json = _map(jsonDecode(source));
  _freeze(json, limits);
  if (jsonEncode(_freeze(json, limits)) != source) {
    throw const FormatException('catalog.object: non canonical JSON');
  }
  return json;
}
