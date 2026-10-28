import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_storage_store.dart';
import '../../catalog_storage/working_project_catalog.dart';
import '../../contracts/query_page.dart';
import '../../contracts/query_request.dart';
import '../project_query_service.dart';
import 'catalog_metadata_documents.dart';

const catalogResourceKinds = <String, CatalogDefinitionKind>{
  'tileset': CatalogDefinitionKind.tileset,
  'element': CatalogDefinitionKind.element,
  'model3d': CatalogDefinitionKind.model3d,
  'character': CatalogDefinitionKind.character,
  'environmentPreset': CatalogDefinitionKind.environmentPreset,
  'smartTileAtlas': CatalogDefinitionKind.smartTileAtlas,
  'smartTileMaterial': CatalogDefinitionKind.smartTileMaterial,
  'smartTilePattern': CatalogDefinitionKind.smartTilePattern,
  'smartTileAnimation': CatalogDefinitionKind.smartTileAnimation,
  'smartTilePreset': CatalogDefinitionKind.smartTilePreset,
  'borderBlueprint': CatalogDefinitionKind.borderRecord,
  'borderSnapshot': CatalogDefinitionKind.borderVisualSnapshot,
  'resourceFamily': CatalogDefinitionKind.resourceFamily,
  'resourceLibraryEntry': CatalogDefinitionKind.resourceLibraryEntry,
  'elementCategory': CatalogDefinitionKind.elementCategory,
  'tilesetFolder': CatalogDefinitionKind.tilesetFolder,
};

final class CatalogProjectReader {
  CatalogProjectReader._(
      this.store, this.descriptor, this._working, this._portable,
      {WorkingProjectCatalogIdentity? recoveryIdentity,
      Set<String>? metadataFields})
      : _recoveryIdentity = recoveryIdentity,
        _metadataFields =
            metadataFields == null ? null : Set.unmodifiable(metadataFields);

  static Future<CatalogProjectReader?> open(
      {required CatalogStorageStore store,
      required Map<String, Object?> descriptor,
      bool allowRecoveryBootstrap = false,
      Set<String>? metadataFields}) async {
    if (descriptor['format'] == 'avelune.working-catalog') {
      final parsed = WorkingProjectCatalogDescriptor.fromJson(descriptor);
      try {
        final working = await WorkingProjectCatalog.open(
            store: store, descriptor: parsed, metadataFields: metadataFields);
        return CatalogProjectReader._(store, descriptor, working, null,
            metadataFields: metadataFields);
      } on CatalogStorageException catch (error) {
        if (!allowRecoveryBootstrap ||
            error.code != 'catalog.recovery_required') {
          rethrow;
        }
        final identity = await WorkingProjectCatalog.inspectIdentity(
            store: store, descriptor: parsed);
        return CatalogProjectReader._(store, descriptor, null, null,
            recoveryIdentity: identity, metadataFields: metadataFields);
      }
    }
    if (descriptor['format'] == 'avelune.portable-catalog') {
      final portable = await PortableProjectCatalog.open(descriptor,
          readObject: store.readObject, metadataFields: metadataFields);
      return CatalogProjectReader._(store, descriptor, null, portable,
          metadataFields: metadataFields);
    }
    return null;
  }

  final CatalogStorageStore store;
  final Map<String, Object?> descriptor;
  final WorkingProjectCatalog? _working;
  final PortableProjectCatalog? _portable;
  final WorkingProjectCatalogIdentity? _recoveryIdentity;
  final Set<String>? _metadataFields;
  bool get recoveryRequired => _recoveryIdentity != null;
  bool get readOnly => descriptor['format'] == 'avelune.portable-catalog';
  String get projectId =>
      WorkingProjectCatalogDescriptor.fromJson(descriptor).projectId;
  PortableProjectCatalog get catalog {
    if (recoveryRequired) {
      throw const CatalogStorageException('catalog.recovery_required',
          'Recover the pending catalog transaction before reading project content.');
    }
    return _working?.catalog ?? _portable!;
  }

  String get revision =>
      'sha256:${_recoveryIdentity?.root.sha256 ?? catalog.snapshot.root.sha256}';
  String get name => _recoveryIdentity?.name ?? catalog.projectMetadata.name;

  Future<T> read<T>(
      Future<T> Function(PortableProjectCatalog catalog) action) async {
    if (recoveryRequired) {
      throw const CatalogStorageException('catalog.recovery_required',
          'Recover the pending catalog transaction before reading project content.');
    }
    final working = _working;
    return working == null ? action(_portable!) : working.readCatalog(action);
  }

  Future<CatalogProjectReader> withMetadataFields(Set<String> fields) async {
    if (recoveryRequired) {
      return read((_) async => this);
    }
    final loaded = _metadataFields;
    if (loaded == null || loaded.containsAll(fields)) {
      return read((_) async => this);
    }
    final selected = {...loaded, ...fields};
    final working = _working;
    if (working != null) {
      return CatalogProjectReader._(
          store, descriptor, await working.withMetadataFields(selected), null,
          metadataFields: selected);
    }
    final portable = await PortableProjectCatalog.fromSnapshot(catalog.snapshot,
        metadataFields: selected);
    return CatalogProjectReader._(store, descriptor, null, portable,
        metadataFields: selected);
  }

  Future<ProjectManifest> readMetadata(Set<String> fields) async {
    final scoped = await withMetadataFields(fields);
    return scoped.read((catalog) async => catalog.projectMetadata);
  }

  Future<AuthoringQueryPage> queryMaps(AuthoringQueryRequest request,
          {required Future<({MapData map, String revision})> Function(String id)
              readMap}) =>
      read((catalog) async {
        if (request.extensions.isNotEmpty) {
          throw const AuthoringQueryException(
              'query.catalog_extension_unsupported',
              'Targeted map queries accept the generic query contract only.');
        }
        if (request.sort.any((sort) => sort.field != 'id' || sort.descending)) {
          throw const AuthoringQueryException('query.catalog_sort_unsupported',
              'Catalog maps support ascending identity order only.');
        }
        if (request.filters.keys.any((field) =>
            !const {'id', 'name', 'groupId', 'relativePath'}.contains(field))) {
          throw const AuthoringQueryException(
              'query.catalog_filter_unsupported',
              'Catalog map filters accept project map metadata only.');
        }
        final revision = 'sha256:${catalog.snapshot.root.sha256}';
        final rows = [
          for (final entry in catalog.projectMetadata.maps)
            {'resourceKind': 'map', ...entry.toJson()}
        ]..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
        final matching = rows
            .where((row) =>
                (request.ids.isEmpty || request.ids.contains(row['id'])) &&
                (request.searchTerm == null ||
                    '${row['id']} ${row['name']}'
                        .toLowerCase()
                        .contains(request.searchTerm!.toLowerCase())) &&
                request.filters.entries.every(
                    (filter) => _matchesFilter(row, filter.key, filter.value)))
            .toList();
        if (request.ids.isNotEmpty &&
            request.ids.any((id) => !rows.any((row) => row['id'] == id))) {
          throw const AuthoringQueryException(
              'query.resource_not_found', 'A requested map was not found.');
        }
        if (request.operation == AuthoringQueryOperation.get &&
            matching.isEmpty) {
          throw const AuthoringQueryException('query.resource_not_found',
              'The requested map does not match the query.');
        }
        final offset = _offset(request, revision);
        if (offset > matching.length) {
          throw const AuthoringQueryException(
              'query.cursor_invalid', 'The query cursor offset is invalid.');
        }
        final end = (offset + request.pageSize).clamp(0, matching.length);
        final selected = <Map<String, Object?>>[];
        final tokens = <String, String>{};
        for (final row in matching.sublist(offset, end)) {
          final detail = request.view == AuthoringQueryView.detail &&
              request.operation != AuthoringQueryOperation.summary;
          final id = row['id'] as String;
          final map =
              detail || request.ids.isNotEmpty ? await readMap(id) : null;
          if (map != null) tokens[id] = map.revision;
          selected.add(_mask(
              detail
                  ? {
                      'resourceKind': 'map',
                      ...map!.map.toJson(),
                      'revision': map.revision
                    }
                  : {...row, if (map != null) 'revision': map.revision},
              request.fieldMask));
        }
        return AuthoringQueryPage(
            snapshotRevision: request.ids.length == 1 && tokens.length == 1
                ? tokens.values.single
                : revision,
            items: selected,
            totalAvailable: matching.length,
            nextCursor: end < matching.length
                ? base64Url
                    .encode(utf8.encode(jsonEncode({
                      'version': 1,
                      'revision': revision,
                      'signature': request.signature,
                      'offset': end
                    })))
                    .replaceAll('=', '')
                : null);
      });

  Future<AuthoringQueryPage> queryFacts(AuthoringQueryRequest request) => read((catalog) async {
    if (request.extensions.isNotEmpty || request.filters.isNotEmpty || request.sort.isNotEmpty ||
        !const {AuthoringQueryOperation.list, AuthoringQueryOperation.summary, AuthoringQueryOperation.get, AuthoringQueryOperation.batchGet}.contains(request.operation)) {
      throw const AuthoringQueryException('query.catalog_fact_scope_unsupported', 'Catalog facts support bounded pages or direct identity selection.');
    }
    await store.requireMetadataIndexAdmission(catalog.snapshot);
    final rootRevision = 'sha256:${catalog.snapshot.root.sha256}';
    final records = <Map<String, dynamic>>[];
    var total = 0;
    var offset = 0;
    String? next;
    if (request.ids.isNotEmpty) {
      final selected = await CatalogMetadataDocuments.readDocuments(snapshot: catalog.snapshot, project: catalog.projectMetadata, ids: {'facts': request.ids.toSet()});
      records.addAll(selected.project.facts.map((fact) => fact.toJson()));
      total = records.length;
      if (records.length != request.ids.length) throw const AuthoringQueryException('query.resource_missing', 'A requested Fact does not exist.');
    } else {
      if (request.cursor != null) {
        try {
          final cursor = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(request.cursor!)))) as Map;
          if (cursor['revision'] != rootRevision || cursor['kind'] != 'fact') throw const FormatException();
          offset = cursor['offset'] as int;
        } catch (_) {
          throw const AuthoringQueryException('query.cursor_invalid', 'The Fact page cursor is invalid or stale.');
        }
      }
      final page = await CatalogMetadataDocuments.readPage(snapshot: catalog.snapshot, field: 'facts', offset: offset, limit: request.pageSize);
      records.addAll(page.records);
      total = page.total;
      if (offset + records.length < total) next = base64Url.encode(utf8.encode(jsonEncode({'revision': rootRevision, 'kind': 'fact', 'offset': offset + records.length}))).replaceAll('=', '');
    }
    return AuthoringQueryPage(snapshotRevision: rootRevision, items: [for (final value in records)
      _mask(request.view == AuthoringQueryView.detail ? {'resourceKind': 'fact', ...value} : {
        'resourceKind': 'fact', 'id': value['id'], 'name': value['label'],
        'category': value['category'], 'valueKind': NarrativeFactDefinition.fromJson(value).valueKind.wireName,
      }, request.fieldMask)], totalAvailable: total, nextCursor: next);
  });

  Future<AuthoringQueryPage> query(AuthoringQueryRequest request) =>
      read((catalog) async {
        if (request.extensions.isNotEmpty) {
          throw const AuthoringQueryException('query.action_resource_mismatch',
              'Catalog queries do not accept query actions.');
        }
        final rootRevision = 'sha256:${catalog.snapshot.root.sha256}';
        if (request.resourceKind == 'project') {
          const fields = {
            'id',
            'name',
            'resourceKind',
            'version',
            'mapCount',
            'groupCount',
            'tilesetCount',
            'definitionCount',
            'catalogStorage',
            'readOnly'
          };
          if (request.view == AuthoringQueryView.detail ||
              request.fieldMask.any((field) => !fields.contains(field))) {
            throw const AuthoringQueryException(
                'query.catalog_materialization_required',
                'Full project reads require explicit catalog materialization.');
          }
          var tilesetCount = 0;
          String? cursor;
          do {
            final page = await catalog.snapshot.page(
                kind: CatalogDefinitionKind.tileset,
                limit: catalog.snapshot.limits.indexPageSize,
                cursor: cursor);
            tilesetCount += page.items.length;
            cursor = page.nextCursor;
          } while (cursor != null);
          final row = <String, Object?>{
            'id': 'project',
            'name': catalog.projectMetadata.name,
            'resourceKind': 'project',
            'version': catalog.projectMetadata.version.name,
            'mapCount': catalog.projectMetadata.maps.length,
            'groupCount': catalog.projectMetadata.groups.length,
            'tilesetCount': tilesetCount,
            'definitionCount': catalog.snapshot.definitionCount,
            'catalogStorage': true,
            'readOnly': readOnly
          };
          final idsMatch =
              request.ids.isEmpty || request.ids.contains('project');
          final term = request.searchTerm?.toLowerCase();
          final searchMatch =
              request.operation != AuthoringQueryOperation.search ||
                  'project'.contains(term!) ||
                  catalog.projectMetadata.name.toLowerCase().contains(term);
          final matches = idsMatch &&
              searchMatch &&
              request.filters.entries.every(
                  (entry) => _matchesFilter(row, entry.key, entry.value));
          if (request.operation == AuthoringQueryOperation.get && !matches) {
            throw const AuthoringQueryException('query.resource_not_found',
                'The requested project was not found.');
          }
          final total = matches ? 1 : 0;
          final offset = _offset(request, rootRevision);
          if (offset > total) {
            throw const AuthoringQueryException(
                'query.cursor_invalid', 'The query cursor offset is invalid.');
          }
          return AuthoringQueryPage(
              snapshotRevision: rootRevision,
              items: matches && offset == 0
                  ? [_mask(row, request.fieldMask)]
                  : const [],
              totalAvailable: total);
        }
        final kind = catalogResourceKinds[request.resourceKind];
        if (kind == null) {
          throw const AuthoringQueryException(
              'query.catalog_resource_unsupported',
              'This resource requires explicit catalog materialization.');
        }
        if (request.sort.any((sort) => sort.field != 'id' || sort.descending)) {
          throw const AuthoringQueryException('query.catalog_sort_unsupported',
              'Catalog queries support ascending identity order only.');
        }
        const fields = {
          'id',
          'name',
          'description',
          'tags',
          'familyId',
          'placementContext',
          'mapId',
          'role',
          'resourceKind',
          'revision',
          'kind'
        };
        if (request.filters.keys.any((field) => !fields.contains(field))) {
          throw const AuthoringQueryException(
              'query.catalog_filter_unsupported',
              'Catalog filters accept indexed summary fields only.');
        }
        final offset = _offset(request, rootRevision);
        final selected = <({
          CatalogIndexEntry entry,
          Map<String, Object?> summary,
        })>[];
        final classifications = request.ids.isEmpty &&
                ResourceLibraryCatalog.resourceKinds
                    .contains(request.resourceKind)
            ? _CatalogClassificationCursor(
                catalog.snapshot, request.resourceKind)
            : null;
        final directEntries = <CatalogIndexEntry>[];
        if (request.ids.isNotEmpty) {
          for (final id in request.ids) {
            final entry = await catalog.snapshot
                .indexEntry(CatalogDefinitionKey(kind, id));
            if (entry != null) directEntries.add(entry);
          }
          directEntries.sort((a, b) => a.key.compareTo(b.key));
        }
        var total = 0;
        String? cursor;
        do {
          final direct = request.ids.isNotEmpty;
          final page = direct
              ? null
              : await catalog.snapshot.page(
                  kind: kind,
                  limit: catalog.snapshot.limits.indexPageSize,
                  cursor: cursor);
          final entries = direct ? directEntries : page!.items;
          for (final entry in entries) {
            final row = classifications == null
                ? await _effectiveSummary(catalog, entry, request.resourceKind)
                : _classifiedSummary(entry, request.resourceKind,
                    await classifications.find(entry.key.id));
            if (request.ids.isNotEmpty && !request.ids.contains(entry.key.id)) {
              continue;
            }
            if (request.operation == AuthoringQueryOperation.search) {
              final term = request.searchTerm!.toLowerCase();
              if (!entry.key.id.toLowerCase().contains(term) &&
                  ![
                    row['name'],
                    row['description'],
                    ...(row['tags'] as List? ?? const [])
                  ].any((value) =>
                      value is String && value.toLowerCase().contains(term))) {
                continue;
              }
            }
            if (!request.filters.entries.every(
                (filter) => _matchesFilter(row, filter.key, filter.value))) {
              continue;
            }
            if (total >= offset && selected.length < request.pageSize) {
              selected.add((entry: entry, summary: row));
            }
            total++;
          }
          cursor = page?.nextCursor;
        } while (cursor != null);
        if (request.operation == AuthoringQueryOperation.get && total == 0) {
          throw const AuthoringQueryException('query.resource_not_found',
              'The requested catalog definition was not found.');
        }
        if (offset > total) {
          throw const AuthoringQueryException(
              'query.cursor_invalid', 'The query cursor offset is invalid.');
        }
        final items = <Map<String, Object?>>[];
        for (final selectedEntry in selected) {
          final entry = selectedEntry.entry;
          var row = selectedEntry.summary;
          if (request.view == AuthoringQueryView.detail &&
              request.operation != AuthoringQueryOperation.summary &&
              (request.fieldMask.isEmpty ||
                  request.fieldMask.any((field) => !fields.contains(field)))) {
            final unit = await catalog.lookup(entry.key);
            if (unit == null) {
              throw const AuthoringQueryException('query.resource_not_found',
                  'The requested catalog definition was not found.');
            }
            final value = unit.payload['value'];
            if (value is! Map<String, Object?>) {
              throw const FormatException(
                  'catalog.project: invalid definition value');
            }
            row = {...value, ...row, 'definition': value};
          }
          items.add(_mask(row, request.fieldMask));
        }
        final end = offset + selected.length;
        return AuthoringQueryPage(
            snapshotRevision: rootRevision,
            items: items,
            totalAvailable: total,
            nextCursor: end < total
                ? base64Url.encode(utf8.encode(jsonEncode({
                    'version': 1,
                    'revision': rootRevision,
                    'signature': request.signature,
                    'offset': end
                  })))
                : null);
      });
}

final class _CatalogClassificationCursor {
  _CatalogClassificationCursor(this.snapshot, this.resourceKind);

  final CatalogSnapshot snapshot;
  final String resourceKind;
  List<CatalogIndexEntry> _entries = const [];
  int _offset = 0;
  String? _nextCursor;
  bool _started = false;

  Future<CatalogDefinitionSummary?> find(String id) async {
    final identity = '$resourceKind:$id';
    while (true) {
      if (_offset == _entries.length) {
        if (_started && _nextCursor == null) return null;
        final page = await snapshot.page(
          kind: CatalogDefinitionKind.resourceLibraryEntry,
          limit: snapshot.limits.indexPageSize,
          cursor: _nextCursor,
        );
        _entries = page.items;
        _nextCursor = page.nextCursor;
        _offset = 0;
        _started = true;
        if (_entries.isEmpty) return null;
      }
      final entry = _entries[_offset];
      final comparison = entry.key.id.compareTo(identity);
      if (comparison >= 0) return comparison == 0 ? entry.summary : null;
      _offset++;
    }
  }
}

Future<Map<String, Object?>> _effectiveSummary(PortableProjectCatalog catalog,
    CatalogIndexEntry entry, String resourceKind) async {
  CatalogDefinitionSummary? classification;
  if (ResourceLibraryCatalog.resourceKinds.contains(resourceKind)) {
    final classified = await catalog.snapshot.indexEntry(CatalogDefinitionKey(
        CatalogDefinitionKind.resourceLibraryEntry,
        '$resourceKind:${entry.key.id}'));
    classification = classified?.summary;
  }
  return _classifiedSummary(entry, resourceKind, classification);
}

Map<String, Object?> _classifiedSummary(CatalogIndexEntry entry,
    String resourceKind, CatalogDefinitionSummary? classification) {
  final row = _summary(entry, resourceKind);
  if (classification != null) {
    row.addAll({
      'description': classification.description,
      'familyId': classification.familyId,
      'mapId': classification.mapId,
      'role': classification.role ?? 'standard',
      'placementContext': classification.placementContext
    });
  }
  return row;
}

Map<String, Object?> _summary(CatalogIndexEntry entry, String resourceKind) => {
      'id': entry.key.id,
      'resourceKind': resourceKind,
      'kind': entry.key.kind.name,
      ...entry.summary.toJson(),
      'revision': 'sha256:${entry.reference.sha256}'
    };

int _offset(AuthoringQueryRequest request, String revision) {
  if (request.cursor == null) return 0;
  try {
    if (request.cursor!.length > 4096) throw const FormatException();
    final source =
        utf8.decode(base64Url.decode(base64Url.normalize(request.cursor!)));
    final value = jsonDecode(source);
    if (value is! Map ||
        value.length != 4 ||
        value['version'] is! int ||
        value['version'] != 1 ||
        value['offset'] is! int ||
        (value['offset'] as int) < 0 ||
        jsonEncode(value) != source) {
      throw const FormatException();
    }
    if (value['revision'] != revision) {
      throw const AuthoringQueryException('query.cursor_stale',
          'The query cursor belongs to another catalog revision.');
    }
    if (value['signature'] != request.signature) {
      throw const AuthoringQueryException('query.cursor_mismatch',
          'The query cursor belongs to another query.');
    }
    return value['offset'] as int;
  } on AuthoringQueryException {
    rethrow;
  } on Object {
    throw const AuthoringQueryException(
        'query.cursor_invalid', 'The query cursor is malformed.');
  }
}

Map<String, Object?> _mask(Map<String, Object?> row, List<String> mask) {
  if (mask.isEmpty) return row;
  final result = <String, Object?>{
    for (final key in ['id', 'resourceKind'])
      if (row.containsKey(key)) key: row[key]
  };
  for (final path in mask) {
    if (mask.any((parent) => parent != path && path.startsWith('$parent.'))) {
      continue;
    }
    final parts = path.split('.');
    Object? source = row;
    var found = true;
    for (final part in parts) {
      if (source is Map && source.containsKey(part)) {
        source = source[part];
      } else {
        found = false;
        break;
      }
    }
    if (!found) continue;
    Map<String, Object?> target = result;
    for (final part in parts.take(parts.length - 1)) {
      target = (target[part] ??= <String, Object?>{}) as Map<String, Object?>;
    }
    target[parts.last] = source;
  }
  return result;
}

bool _matchesFilter(Map<String, Object?> row, String field, Object? value) {
  if (field == 'placementContext' &&
      const {'interior', 'exterior'}.contains(value)) {
    return row[field] == value || row[field] == 'both';
  }
  return jsonEncode(row[field]) == jsonEncode(value);
}
