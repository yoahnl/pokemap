import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../support/authoring_fingerprint.dart';
import '../../catalog_storage/trusted_catalog_admissions.dart';

abstract final class CatalogNarrativeEventDocuments {
  static final indexKey = CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, 'narrativeEventDocuments');

  static CatalogDefinitionKey recordKey(String id) => CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState,
      jsonEncode(['narrativeEventDocument', id]));

  static List<CatalogDefinitionUnit> initialize(
      Iterable<CatalogDefinitionUnit> units) {
    final byKey = {for (final unit in units) unit.key: unit};
    final raw = _decode(byKey);
    return _project(raw);
  }

  static CatalogDefinitionKey sceneOwnerKey(String sceneId) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['sceneEventOwners', sceneId]));

  static Map<String, Set<String>> _sceneOwners(
      Iterable<NarrativeEventRecord> records) {
    final result = <String, Set<String>>{};
    for (final record in records) {
      final sceneId =
          record.definitionOrNull?.sceneId ?? record.draftOrNull?.sceneId;
      if (sceneId != null && sceneId.isNotEmpty) {
        result.putIfAbsent(sceneId, () => {}).add(record.id);
      }
    }
    return result;
  }

  static Future<void> initializeSceneOwners(
      CatalogSnapshot snapshot, String projectRoot) async {
    final marker = await snapshot.lookup(indexKey);
    if (marker?.payload['sceneOwnersVersion'] == 1 ||
        marker?.payload['present'] == false) {
      return;
    }
    final digest = await _registryDigest(snapshot);
    final cache = TrustedCatalogAdmissions(projectRoot: projectRoot);
    if (await cache.sceneOwnerCacheReady(digest)) return;
    final project = await PortableProjectCatalog.fromSnapshot(snapshot,
        metadataFields: {'eventRegistry'});
    final owners = _sceneOwners(
        project.projectMetadata.eventRegistry?.records ?? const []);
    await cache.publishSceneOwnerCache(digest, owners,
        maximumBytes: snapshot.limits.maxUnitBytes);
  }

  static Future<Set<String>> readSceneOwnerIds(CatalogSnapshot snapshot,
      String projectRoot, Set<String> sceneIds) async {
    final marker = await snapshot.lookup(indexKey);
    if (marker?.payload['present'] == false) return const {};
    final result = <String>{};
    if (marker?.payload['sceneOwnersVersion'] == 1) {
      for (final sceneId in sceneIds) {
        final owner = await snapshot.lookup(sceneOwnerKey(sceneId));
        final ids = owner?.payload['eventIds'] ?? const <String>[];
        if (ids is! List || ids.any((id) => id is! String)) {
          throw const FormatException(
              'catalog.scene_owners: invalid owner ids');
        }
        result.addAll(ids.cast<String>());
      }
    } else {
      final digest = await _registryDigest(snapshot);
      final cache = TrustedCatalogAdmissions(projectRoot: projectRoot);
      for (final sceneId in sceneIds) {
        result.addAll(await cache.readSceneOwnerCache(digest, sceneId,
            maximumBytes: snapshot.limits.maxUnitBytes));
      }
    }
    if (result.length > snapshot.limits.maxClosureNodes) {
      throw const FormatException(
          'catalog.scene_owners: dependency budget exceeded');
    }
    return result;
  }

  static Future<String> _registryDigest(CatalogSnapshot snapshot) async {
    final header =
        await snapshot.lookup(_aggregateKey('projectAggregateHeader'));
    if (header != null) {
      return (header.payload['value'] as Map)['sha256'] as String;
    }
    final shell = await snapshot.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata, 'publication-shell'));
    return crypto.sha256
        .convert(utf8.encode(canonicalAuthoringJson(
            (shell?.payload['value'] as Map?)?['eventRegistry'])))
        .toString();
  }

  static CatalogDefinitionUnit _sceneOwnerUnit(
          String sceneId, Set<String> ids) =>
      CatalogDefinitionUnit(key: sceneOwnerKey(sceneId), payload: {
        'id': sceneOwnerKey(sceneId).id,
        'eventIds': ids.toList()..sort()
      });

  static Future<bool> prepared(CatalogSnapshot snapshot) async =>
      (await snapshot.lookup(indexKey))?.payload['indexVersion'] == 2;

  static Future<NarrativeEventRegistry?> read(
      CatalogSnapshot snapshot, Set<String> ids) async {
    if (ids.length > snapshot.limits.maxClosureNodes) {
      throw const FormatException('catalog.events: dependency budget exceeded');
    }
    final marker = await snapshot.lookup(indexKey);
    if (marker?.payload['indexVersion'] != 2) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Prepare the catalog explicitly before reading narrative event dependencies.');
    }
    if (marker!.payload['present'] != true) return null;
    final records = <NarrativeEventRecord>[];
    var dependencyCount = ids.length + 1;
    for (final id in ids) {
      final unit = await snapshot.lookup(recordKey(id));
      if (unit == null || unit.payload['deleted'] == true) continue;
      if (unit.payload['eventId'] != id) {
        throw const FormatException('catalog.events: invalid record identity');
      }
      final count = unit.payload['chunkCount'] as int;
      dependencyCount += count;
      if (count < 0 ||
          count > 512 ||
          dependencyCount > snapshot.limits.maxClosureNodes) {
        throw const FormatException(
            'catalog.events: record dependency budget exceeded');
      }
      final parts = <CatalogDefinitionUnit>[];
      for (var i = 0; i < count; i++) {
        final chunk = await snapshot.lookup(_recordChunkKey(id, i));
        if (chunk == null ||
            chunk.payload['eventId'] != id ||
            chunk.payload['position'] != i) {
          throw const FormatException('catalog.events: record chunk missing');
        }
        parts.add(chunk);
      }
      final record = NarrativeEventRecord.fromJson(
          jsonDecode(utf8.decode(_recordBytes(unit, parts))));
      if (record.id != id) {
        throw const FormatException('catalog.events: invalid record identity');
      }
      records.add(record);
    }
    return NarrativeEventRegistry(
        schemaVersion: marker.payload['schemaVersion'] as int,
        mode: EventSystemMode.values.byName(marker.payload['mode'] as String),
        records: records,
        legacyClaims: const []);
  }

  static Future<List<CatalogDefinitionUnit>> maintain({
    required Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey)
        lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) async {
    final pending = {for (final unit in upserts) unit.key: unit};
    final removed = removals.toSet();
    if (!await registryChanged(lookup, pending, removed)) return const [];
    if ((await lookup(indexKey))?.payload['indexVersion'] != 2) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Prepare narrative event indexes explicitly before changing their registry.');
    }
    final before = _decode(await _capture(lookup, pending, removed, false));
    final after = _decode(await _capture(lookup, pending, removed, true));
    final beforeRegistry =
        before == null ? null : NarrativeEventRegistry.fromJson(before);
    final afterRegistry =
        after == null ? null : NarrativeEventRegistry.fromJson(after);
    final next = <CatalogDefinitionUnit>[];
    final index = _indexUnit(after);
    if (jsonEncode(_indexUnit(before).payload) != jsonEncode(index.payload)) {
      next.add(index);
    }
    final beforeRaw = before?['records'] as List? ?? const [];
    final previous = <String, String>{
      for (var i = 0; i < beforeRaw.length; i++)
        beforeRegistry!.records[i].id: jsonEncode(beforeRaw[i]),
    };
    final afterRaw = after?['records'] as List? ?? const [];
    final afterIds = <String>{};
    for (var i = 0; i < afterRaw.length; i++) {
      final id = afterRegistry!.records[i].id;
      afterIds.add(id);
      if (previous[id] != jsonEncode(afterRaw[i])) {
        next.addAll(_recordUnits(afterRaw[i]));
      }
    }
    for (final id in previous.keys) {
      if (!afterIds.contains(id)) {
        next.add(CatalogDefinitionUnit(
            key: recordKey(id),
            payload: {'id': recordKey(id).id, 'eventId': id, 'deleted': true}));
      }
    }
    final previousOwners = _sceneOwners(beforeRegistry?.records ?? const []);
    final nextOwners = _sceneOwners(afterRegistry?.records ?? const []);
    for (final sceneId in {...previousOwners.keys, ...nextOwners.keys}) {
      final owners = nextOwners[sceneId] ?? const <String>{};
      final prior = previousOwners[sceneId] ?? const <String>{};
      if (owners.length != prior.length || !owners.containsAll(prior)) {
        next.add(_sceneOwnerUnit(sceneId, owners));
      }
    }
    return next;
  }

  static final _shellKey = CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata, 'publication-shell');

  static Map<String, Object?>? decodeRegistry(
          Iterable<CatalogDefinitionUnit> units) =>
      _decode({for (final unit in units) unit.key: unit});

  static Future<Iterable<CatalogDefinitionUnit>> registryUnits(
          Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey) lookup,
          {Map<CatalogDefinitionKey, CatalogDefinitionUnit> pending = const {},
          Set<CatalogDefinitionKey> removed = const {},
          bool after = false}) async =>
      (await _capture(lookup, pending, removed, after)).values;

  static Future<bool> registryChanged(
      Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey) lookup,
      Map<CatalogDefinitionKey, CatalogDefinitionUnit> pending,
      Set<CatalogDefinitionKey> removed) async {
    if ([...pending.keys, ...removed].any(_registryUnit)) return true;
    final nextShell = pending[_shellKey];
    if (nextShell == null) return false;
    final oldShell = await lookup(_shellKey);
    return jsonEncode((nextShell.payload['value'] as Map)['eventRegistry']) !=
        jsonEncode((oldShell?.payload['value'] as Map?)?['eventRegistry']);
  }

  static Future<Map<CatalogDefinitionKey, CatalogDefinitionUnit>> _capture(
      Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey) lookup,
      Map<CatalogDefinitionKey, CatalogDefinitionUnit> pending,
      Set<CatalogDefinitionKey> removed,
      bool after) async {
    final values = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
    Future<CatalogDefinitionUnit?> read(CatalogDefinitionKey key) async {
      final unit = after && removed.contains(key)
          ? null
          : after && pending.containsKey(key)
              ? pending[key]
              : await lookup(key);
      if (unit != null) values[key] = unit;
      return unit;
    }

    await read(_shellKey);
    final header = await read(_aggregateKey('projectAggregateHeader'));
    if (header != null) {
      final count = (header.payload['value'] as Map)['chunkCount'] as int;
      if (count < 1 || count > 512) {
        throw const FormatException('catalog.events: invalid aggregate size');
      }
      for (var i = 0; i < count; i++) {
        await read(_aggregateKey('projectAggregateChunk', i));
      }
    }
    final boundary = header == null
        ? 0
        : (header.payload['value'] as Map)['chunkCount'] as int;
    await read(_aggregateKey('projectAggregateChunk', boundary));
    if (after) {
      for (final entry in pending.entries) {
        if (_registryUnit(entry.key) && !removed.contains(entry.key)) {
          values[entry.key] = entry.value;
        }
      }
    }
    return values;
  }

  static Future<
      ({
        List<CatalogDefinitionUnit> upserts,
        List<CatalogDefinitionKey> removals
      })> settle(
    Iterable<CatalogDefinitionUnit> units,
    Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey) lookup,
  ) async {
    final upserts = <CatalogDefinitionUnit>[];
    final removals = <CatalogDefinitionKey>[];
    for (final unit in units) {
      if (isRecordKey(unit.key) && unit.payload['deleted'] == true) {
        final previous = await lookup(unit.key);
        if (previous == null) continue;
        removals.add(unit.key);
        final count = previous.payload['chunkCount'];
        if (count is int) {
          final id = unit.payload['eventId'] as String;
          for (var i = 0; i < count; i++) {
            removals.add(_recordChunkKey(id, i));
          }
        }
        continue;
      }
      if (_isSceneOwnerKey(unit.key) &&
          (unit.payload['eventIds'] as List).isEmpty) {
        if (await lookup(unit.key) != null) removals.add(unit.key);
        continue;
      }
      upserts.add(unit);
    }
    return (upserts: upserts, removals: removals);
  }

  static bool _isSceneOwnerKey(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      key.id.startsWith('["sceneEventOwners",');

  static CatalogDefinitionUnit _indexUnit(Map<String, Object?>? raw) =>
      CatalogDefinitionUnit(key: indexKey, payload: {
        'indexVersion': 2,
        'sceneOwnersVersion': 1,
        'present': raw != null,
        if (raw != null) 'schemaVersion': raw['schemaVersion'],
        if (raw != null) 'mode': raw['mode'],
      });

  static List<CatalogDefinitionUnit> _project(Map<String, Object?>? raw) {
    if (raw != null) NarrativeEventRegistry.fromJson(raw);
    return [
      _indexUnit(raw),
      for (final record in raw?['records'] as List? ?? const [])
        ..._recordUnits(record),
      for (final entry in _sceneOwners([
        for (final record in raw?['records'] as List? ?? const [])
          NarrativeEventRecord.fromJson(record)
      ]).entries)
        _sceneOwnerUnit(entry.key, entry.value),
    ];
  }

  static Map<String, Object?>? _decode(
      Map<CatalogDefinitionKey, CatalogDefinitionUnit> units) {
    final shell = units[CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata, 'publication-shell')];
    return PortableCatalogPublication.decodeProjectMetadataAggregate(
        field: 'eventRegistry',
        shellValue: (shell?.payload['value'] as Map?)?['eventRegistry'],
        units: units.values.where((unit) => _registryUnit(unit.key)));
  }

  static List<CatalogDefinitionUnit> _recordUnits(Object? record) {
    final id = _recordId(record);
    final bytes = utf8.encode(jsonEncode(record));
    final chunks = bytes.length <= 8192 ? 0 : (bytes.length + 65535) ~/ 65536;
    return [
      CatalogDefinitionUnit(key: recordKey(id), payload: {
        'id': recordKey(id).id,
        'eventId': id,
        'byteLength': bytes.length,
        'sha256': crypto.sha256.convert(bytes).toString(),
        'chunkCount': chunks,
        if (chunks == 0) 'data': base64Encode(bytes),
      }),
      for (var i = 0; i < chunks; i++)
        CatalogDefinitionUnit(key: _recordChunkKey(id, i), payload: {
          'id': _recordChunkKey(id, i).id,
          'eventId': id,
          'position': i,
          'data': base64Encode(bytes.sublist(
              i * 65536, ((i + 1) * 65536).clamp(0, bytes.length))),
        }),
    ];
  }

  static bool isRecordKey(CatalogDefinitionKey key) {
    if (key.kind != CatalogDefinitionKind.workspaceState) return false;
    try {
      final id = jsonDecode(key.id);
      return id is List &&
          id.length == 2 &&
          id.first == 'narrativeEventDocument';
    } on FormatException {
      return false;
    }
  }

  static Future<NarrativeEventRecord?> readRecordUnit(
      CatalogDefinitionUnit? unit,
      Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey)
          lookup) async {
    if (unit == null || unit.payload['deleted'] == true) return null;
    final id = unit.payload['eventId'] as String;
    final chunks = <CatalogDefinitionUnit>[];
    final count = unit.payload['chunkCount'] as int;
    if (count < 0 || count > 512)
      throw const FormatException(
          'catalog.events: invalid record dependency budget');
    for (var i = 0; i < count; i++) {
      final chunk = await lookup(_recordChunkKey(id, i));
      if (chunk == null)
        throw const FormatException('catalog.events: missing record chunk');
      chunks.add(chunk);
    }
    return NarrativeEventRecord.fromJson(
        jsonDecode(utf8.decode(_recordBytes(unit, chunks))));
  }

  static List<int> _recordBytes(
      CatalogDefinitionUnit unit, List<CatalogDefinitionUnit> parts) {
    final length = unit.payload['byteLength'] as int;
    final count = unit.payload['chunkCount'] as int;
    if (length < 1 ||
        length > 33554432 ||
        count != (length <= 8192 ? 0 : (length + 65535) ~/ 65536) ||
        parts.length != count) {
      throw const FormatException('catalog.events: invalid record bounds');
    }
    final data = count == 0
        ? [unit.payload['data']]
        : [for (final part in parts) part.payload['data']];
    final bytes = <int>[];
    for (var i = 0; i < data.length; i++) {
      final encoded = data[i] as String;
      final chunk = base64Decode(encoded);
      final expected = count == 0
          ? length
          : i == count - 1
              ? length - i * 65536
              : 65536;
      if (base64Encode(chunk) != encoded || chunk.length != expected) {
        throw const FormatException('catalog.events: invalid record chunk');
      }
      bytes.addAll(chunk);
    }
    if (crypto.sha256.convert(bytes).toString() != unit.payload['sha256']) {
      throw const FormatException('catalog.events: record digest mismatch');
    }
    return bytes;
  }

  static CatalogDefinitionKey _recordChunkKey(String id, int position) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['narrativeEventDocumentChunk', id, position]));

  static String _recordId(Object? value) =>
      NarrativeEventRecord.fromJson(value).id;

  static CatalogDefinitionKey _aggregateKey(String type, [int? position]) =>
      CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
          jsonEncode([type, 'eventRegistry', if (position != null) position]));

  static bool _registryUnit(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.catalogMetadata &&
      (key == _aggregateKey('projectAggregateHeader') ||
          key.id.startsWith('["projectAggregateChunk","eventRegistry",'));
}
