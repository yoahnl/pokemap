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
    final shellKey = CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata, 'publication-shell');
    var changed = [...pending.keys, ...removed].any(_registryUnit);
    final nextShell = pending[shellKey];
    if (!changed && nextShell != null) {
      final oldShell = await lookup(shellKey);
      changed = jsonEncode(
              (nextShell.payload['value'] as Map)['eventRegistry']) !=
          jsonEncode((oldShell?.payload['value'] as Map?)?['eventRegistry']);
    }
    if (!changed) return const [];
    if ((await lookup(indexKey))?.payload['indexVersion'] != 2) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Prepare narrative event indexes explicitly before changing their registry.');
    }
    Future<Map<CatalogDefinitionKey, CatalogDefinitionUnit>> capture(
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

      await read(shellKey);
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

    final before = _decode(await capture(false));
    final after = _decode(await capture(true));
    final next = _project(after);
    final afterIds = {
      for (final raw in after?['records'] as List? ?? const []) _recordId(raw)
    };
    for (final raw in before?['records'] as List? ?? const []) {
      final id = _recordId(raw);
      if (!afterIds.contains(id)) {
        next.add(CatalogDefinitionUnit(
            key: recordKey(id),
            payload: {'id': recordKey(id).id, 'eventId': id, 'deleted': true}));
      }
    }
    final previousOwners = _sceneOwners([
      for (final record in before?['records'] as List? ?? const [])
        NarrativeEventRecord.fromJson(record)
    ]);
    final nextOwners = _sceneOwners([
      for (final record in after?['records'] as List? ?? const [])
        NarrativeEventRecord.fromJson(record)
    ]);
    for (final sceneId in previousOwners.keys
        .where((sceneId) => !nextOwners.containsKey(sceneId))) {
      next.add(_sceneOwnerUnit(sceneId, const {}));
    }
    return next;
  }

  static List<CatalogDefinitionUnit> _project(Map<String, Object?>? raw) {
    if (raw != null) NarrativeEventRegistry.fromJson(raw);
    return [
      CatalogDefinitionUnit(key: indexKey, payload: {
        'indexVersion': 2,
        'sceneOwnersVersion': 1,
        'present': raw != null,
        if (raw != null) 'schemaVersion': raw['schemaVersion'],
        if (raw != null) 'mode': raw['mode'],
      }),
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
