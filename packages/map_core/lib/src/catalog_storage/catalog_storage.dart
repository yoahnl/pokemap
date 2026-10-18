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
    'version': 1,
    'key': key.toJson(),
    'payload': payload,
    'references': references.map((r) => r.toJson()).toList(),
  };
}

final class CatalogIndexEntry {
  CatalogIndexEntry({required this.key, required this.reference});
  final CatalogDefinitionKey key;
  final CatalogObjectReference reference;
  Map<String, Object?> toJson() => {
    'key': key.toJson(),
    'reference': reference.toJson(),
  };
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
          ),
        )
        .toList();
    final nodes = <_Node>[];
    for (var i = 0; i < entries.length; i += limits.indexPageSize) {
      final group = entries.sublist(
        i,
        (i + limits.indexPageSize).clamp(0, entries.length),
      );
      final ref = put({
        'type': 'leaf',
        'version': 1,
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
          'version': 1,
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
      'version': 1,
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

typedef CatalogObjectReader =
    Future<List<int>> Function(CatalogObjectReference reference);

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
    snapshot._validatedStoredBytes = _storedBytes;
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

  final CatalogObjectReference root;
  final CatalogObjectReader _readObject;
  final CatalogStorageLimits limits;
  final int definitionCount;
  final _Node? _index;
  int? _validatedStoredBytes;

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
    if (_validatedStoredBytes == null) {
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
    return entries.isEmpty ? null : _unit(entries.single);
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
          parsed['version'] != 1 ||
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
              'version': 1,
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

  Future<void> validate() async {
    await objectReferences();
  }

  Future<List<CatalogObjectReference>> objectReferences() async {
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
    final keys = entries.map((e) => e.key).toSet();
    for (final entry in entries) {
      admit(entry.reference);
    }
    for (final entry in entries) {
      final unit = await _unit(entry);
      if (unit.references.any((k) => !keys.contains(k))) {
        throw const FormatException('catalog.validate: missing dependency');
      }
    }
    _validatedStoredBytes = bytes;
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
    return CatalogDefinitionUnit(
      key: key,
      payload: _map(json['payload']),
      references: refs,
    );
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
    Future<void> visit(_Node node) async {
      if (found.length >= take ||
          (after != null && node.last.compareTo(after) <= 0) ||
          (kind != null &&
              (node.first.kind.name.compareTo(kind.name) > 0 ||
                  node.last.kind.name.compareTo(kind.name) < 0)) ||
          (exact != null && !_contains(node, exact))) {
        return;
      }
      if (!seen.add(node.reference.sha256)) {
        throw const FormatException('catalog.index: cycle or repeated node');
      }
      onNode?.call(node.reference);
      final json = await _read(
        node.reference,
        _readObject,
        limits,
        limits.maxIndexBytes,
      );
      if (node.height == 0) {
        _envelope(json, 'leaf', {'entries'});
        final values = _list(json['entries'], limits.indexPageSize);
        final entries = values.map((v) {
          final map = _map(v);
          _keys(map, {'key', 'reference'});
          return CatalogIndexEntry(
            key: CatalogDefinitionKey.fromJson(_map(map['key'])),
            reference: CatalogObjectReference.fromJson(_map(map['reference'])),
          );
        }).toList();
        _ordered(entries.map((e) => e.key).toList());
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
        _envelope(json, 'branch', {'children'});
        final children = _list(
          json['children'],
          limits.indexPageSize,
        ).map((v) => _Node.fromJson(_map(v), limits)).toList();
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
          await visit(child);
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
      'version': 1,
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
      'version': 1,
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
    for (var i = 0; i < entries.length; i += limits.indexPageSize)
      _leaf(
        entries.sublist(i, (i + limits.indexPageSize).clamp(0, entries.length)),
      ),
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
          _keys(value, {'key', 'reference'});
          final key = CatalogDefinitionKey.fromJson(_map(value['key']));
          entries[key] = CatalogIndexEntry(
            key: key,
            reference: CatalogObjectReference.fromJson(
              _map(value['reference']),
            ),
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
        snapshot._validatedStoredBytes!,
      );
    }
    final root = _put({
      'type': 'root',
      'version': 1,
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
        snapshot._validatedStoredBytes! - removedBytes + addedBytes;
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
  if (json['type'] != type || json['version'] is! int || json['version'] != 1) {
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
  final bytes = await reader(ref);
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
