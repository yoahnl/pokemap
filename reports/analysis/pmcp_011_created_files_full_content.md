# PMCP-011 — Full created-file contents

This appendix is part of the PMCP-011 Evidence Pack and reproduces every production and test file created by the lot. The report and appendix exclude themselves to avoid self-reference.

## `packages/map_authoring/lib/src/workspace/project_snapshot.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

import 'workspace_handle_store.dart';

final class ProjectSnapshotException implements Exception {
  const ProjectSnapshotException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectSnapshotException($code): $message';
}

/// Immutable, path-free view of one coherently read PokeMap project revision.
final class ProjectSnapshot {
  ProjectSnapshot({
    required this.projectHandle,
    required this.revision,
    required this.manifest,
    required Iterable<MapData> maps,
    required Map<String, String> resourceFingerprints,
  })  : maps = List.unmodifiable(
          maps.toList()..sort((left, right) => left.id.compareTo(right.id)),
        ),
        resourceFingerprints = Map.unmodifiable(
          Map.fromEntries(
            (resourceFingerprints.entries.toList()
                  ..sort((left, right) => left.key.compareTo(right.key)))
                .map((entry) => MapEntry(entry.key, entry.value)),
          ),
        ) {
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(revision)) {
      throw ArgumentError.value(
        revision,
        'revision',
        'must be a lowercase SHA-256 fingerprint',
      );
    }
    final mapIds = <String>{};
    for (final map in this.maps) {
      if (map.id.trim().isEmpty || !mapIds.add(map.id)) {
        throw ArgumentError.value(
          map.id,
          'maps',
          'map identities must be nonblank and unique',
        );
      }
    }
    for (final entry in this.resourceFingerprints.entries) {
      if (entry.key.trim().isEmpty ||
          !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(entry.value)) {
        throw ArgumentError.value(
          entry,
          'resourceFingerprints',
          'keys must be nonblank and values must be SHA-256 fingerprints',
        );
      }
    }
    _mapsById = Map.unmodifiable({
      for (final map in this.maps) map.id: map,
    });
  }

  final ProjectHandle projectHandle;
  final String revision;
  final ProjectManifest manifest;
  final List<MapData> maps;
  final Map<String, String> resourceFingerprints;
  late final Map<String, MapData> _mapsById;

  MapData? mapById(String id) => _mapsById[id];
}
~~~~~~~~

## `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import 'project_snapshot.dart';
import 'workspace_handle_store.dart';

/// Loads every manifest-declared map twice to reject mixed disk revisions.
///
/// The double read cannot make unrelated filesystem operations atomic, but it
/// ensures this API never claims a coherent snapshot after observing a change
/// in any resource that contributes to the returned revision.
final class ProjectSnapshotLoader {
  const ProjectSnapshotLoader({
    required WorkspaceHandleStore handles,
  }) : _handles = handles;

  final WorkspaceHandleStore _handles;

  Future<ProjectSnapshot> load(ProjectHandle projectHandle) async {
    final access = _handles.resolveProject(projectHandle);
    final manifestBytes = await access.readBytes('project.json');
    final manifest = _decodeManifest(manifestBytes);
    final entries = _validatedMapEntries(manifest.maps);
    final resources = <_LoadedProjectResource>[
      _LoadedProjectResource(
        relativePath: 'project.json',
        identity: 'project',
        bytes: manifestBytes,
      ),
    ];
    final maps = <MapData>[];
    for (final entry in entries) {
      final bytes = await access.readBytes(entry.relativePath);
      final map = _decodeMap(bytes);
      if (map.id != entry.id) {
        throw const ProjectSnapshotException(
          'project.map_identity_mismatch',
          'A map document identity differs from its manifest entry.',
        );
      }
      maps.add(map);
      resources.add(
        _LoadedProjectResource(
          relativePath: entry.relativePath,
          identity: 'map:${entry.id}',
          bytes: bytes,
        ),
      );
    }
    resources.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    for (final resource in resources) {
      final reread = await access.readBytes(resource.relativePath);
      if (!_bytesEqual(resource.bytes, reread)) {
        throw const ProjectSnapshotException(
          'project.changed_during_snapshot',
          'A project resource changed while the snapshot was loading.',
        );
      }
    }
    final revision = computeNarrativeProjectFingerprint([
      for (final resource in resources)
        NarrativeProjectFingerprintEntry(
          relativePath: resource.relativePath,
          bytes: resource.bytes,
        ),
    ]);
    final resourceFingerprints = <String, String>{
      for (final resource in resources)
        resource.identity: computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
            relativePath: resource.relativePath,
            bytes: resource.bytes,
          ),
        ]),
    };
    return ProjectSnapshot(
      projectHandle: projectHandle,
      revision: revision,
      manifest: manifest,
      maps: maps,
      resourceFingerprints: resourceFingerprints,
    );
  }
}

List<ProjectMapEntry> _validatedMapEntries(List<ProjectMapEntry> entries) {
  final seenIds = <String>{};
  final seenPaths = <String>{};
  final validated = <ProjectMapEntry>[];
  for (final entry in entries) {
    final id = entry.id.trim();
    if (id.isEmpty) {
      throw const ProjectSnapshotException(
        'project.map_id_required',
        'Every manifest map entry requires an identity.',
      );
    }
    if (!seenIds.add(id)) {
      throw const ProjectSnapshotException(
        'project.duplicate_map_id',
        'Manifest map identities must be unique.',
      );
    }
    final normalizedPath =
        validateProjectRelativePath(entry.relativePath).join('/');
    if (!seenPaths.add(normalizedPath)) {
      throw const ProjectSnapshotException(
        'project.duplicate_map_path',
        'Manifest map resource paths must be unique.',
      );
    }
    validated.add(entry.copyWith(id: id, relativePath: normalizedPath));
  }
  validated.sort((left, right) {
    final pathOrder = left.relativePath.compareTo(right.relativePath);
    return pathOrder != 0 ? pathOrder : left.id.compareTo(right.id);
  });
  return List.unmodifiable(validated);
}

ProjectManifest _decodeManifest(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected an object.');
    }
    return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  } on ProjectSnapshotException {
    rethrow;
  } on Object {
    throw const ProjectSnapshotException(
      'project.manifest_invalid',
      'The project manifest is not valid PokeMap JSON.',
    );
  }
}

MapData _decodeMap(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected an object.');
    }
    return MapData.fromJson(Map<String, dynamic>.from(decoded));
  } on ProjectSnapshotException {
    rethrow;
  } on Object {
    throw const ProjectSnapshotException(
      'project.map_invalid',
      'A declared map is not valid PokeMap JSON.',
    );
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _LoadedProjectResource {
  _LoadedProjectResource({
    required this.relativePath,
    required this.identity,
    required List<int> bytes,
  }) : bytes = List.unmodifiable(bytes);

  final String relativePath;
  final String identity;
  final List<int> bytes;
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/query_request.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'json_contract_support.dart';

enum AuthoringQueryOperation {
  list('list'),
  get('get'),
  batchGet('batch_get'),
  search('search'),
  summary('summary');

  const AuthoringQueryOperation(this.wireName);

  final String wireName;

  static AuthoringQueryOperation fromWireName(String value) {
    return AuthoringQueryOperation.values.firstWhere(
      (operation) => operation.wireName == value,
      orElse: () => throw FormatException('Unknown query operation: $value'),
    );
  }
}

enum AuthoringQueryView {
  summary('summary'),
  detail('detail');

  const AuthoringQueryView(this.wireName);

  final String wireName;

  static AuthoringQueryView fromWireName(String value) {
    return AuthoringQueryView.values.firstWhere(
      (view) => view.wireName == value,
      orElse: () => throw FormatException('Unknown query view: $value'),
    );
  }
}

final class AuthoringQuerySort {
  const AuthoringQuerySort({
    required this.field,
    this.descending = false,
  });

  factory AuthoringQuerySort.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    return AuthoringQuerySort(
      field: requireContractString(json['field'], 'sort.field'),
      descending: requireContractBool(
        json['descending'],
        'sort.descending',
      ),
    );
  }

  static const Set<String> _reservedKeys = {'field', 'descending'};

  final String field;
  final bool descending;

  Map<String, Object?> toJson() => {
        'field': field,
        'descending': descending,
      };
}

/// Canonical, cursor-aware query request shared by direct and CLI reads.
final class AuthoringQueryRequest {
  AuthoringQueryRequest({
    required String resourceKind,
    required this.operation,
    this.view = AuthoringQueryView.summary,
    Iterable<String> ids = const [],
    String? searchTerm,
    Iterable<String> fieldMask = const [],
    Map<String, Object?> filters = const {},
    Iterable<AuthoringQuerySort> sort = const [],
    this.pageSize = 50,
    String? cursor,
    Map<String, Object?> extensions = const {},
  })  : resourceKind = _resourceKind(resourceKind),
        ids = normalizedContractStrings(ids, 'ids'),
        searchTerm = _optionalTrimmed(searchTerm),
        fieldMask = _fieldPaths(fieldMask, 'fieldMask'),
        filters = _filters(filters),
        sort = _sortFields(sort),
        cursor = _optionalTrimmed(cursor),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        ) {
    if (pageSize < 1 || pageSize > 200) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be from 1 to 200');
    }
    switch (operation) {
      case AuthoringQueryOperation.get:
        if (this.ids.length != 1) {
          throw ArgumentError.value(ids, 'ids', 'get requires exactly one ID');
        }
      case AuthoringQueryOperation.batchGet:
        if (this.ids.isEmpty) {
          throw ArgumentError.value(ids, 'ids', 'batch_get requires IDs');
        }
      case AuthoringQueryOperation.search:
        if (this.searchTerm == null) {
          throw ArgumentError.value(
            searchTerm,
            'searchTerm',
            'search requires a term',
          );
        }
        if (this.ids.isNotEmpty) {
          throw ArgumentError.value(ids, 'ids', 'search does not accept IDs');
        }
      case AuthoringQueryOperation.list:
      case AuthoringQueryOperation.summary:
        if (this.ids.isNotEmpty) {
          throw ArgumentError.value(
              ids, 'ids', 'operation does not accept IDs');
        }
    }
  }

  factory AuthoringQueryRequest.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawIds = json['ids'];
    final rawFieldMask = json['fieldMask'];
    final rawFilters = json['filters'];
    final rawSort = json['sort'];
    if (rawIds is! List ||
        rawIds.any((item) => item is! String) ||
        rawFieldMask is! List ||
        rawFieldMask.any((item) => item is! String) ||
        rawFilters is! Map ||
        rawSort is! List) {
      throw const FormatException('Invalid query collection field.');
    }
    try {
      return AuthoringQueryRequest(
        resourceKind: requireContractString(
          json['resourceKind'],
          'resourceKind',
        ),
        operation: AuthoringQueryOperation.fromWireName(
          requireContractString(json['operation'], 'operation'),
        ),
        view: AuthoringQueryView.fromWireName(
          requireContractString(json['view'], 'view'),
        ),
        ids: rawIds.cast<String>(),
        searchTerm: readOptionalContractString(
          json['searchTerm'],
          'searchTerm',
        ),
        fieldMask: rawFieldMask.cast<String>(),
        filters: Map<String, Object?>.from(rawFilters),
        sort: rawSort.map((item) {
          if (item is! Map) {
            throw const FormatException('sort entries must be objects');
          }
          return AuthoringQuerySort.fromJson(
            Map<String, dynamic>.from(item),
          );
        }),
        pageSize: json['pageSize'] is int
            ? json['pageSize']! as int
            : throw const FormatException('pageSize must be an integer'),
        cursor: readOptionalContractString(json['cursor'], 'cursor'),
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
    'resourceKind',
    'operation',
    'view',
    'ids',
    'searchTerm',
    'fieldMask',
    'filters',
    'sort',
    'pageSize',
    'cursor',
    'extensions',
  };

  final String resourceKind;
  final AuthoringQueryOperation operation;
  final AuthoringQueryView view;
  final List<String> ids;
  final String? searchTerm;
  final List<String> fieldMask;
  final Map<String, Object?> filters;
  final List<AuthoringQuerySort> sort;
  final int pageSize;
  final String? cursor;
  final Map<String, Object?> extensions;

  /// Stable hash of every query semantic except the continuation cursor.
  String get signature {
    final json = toJson()..remove('cursor');
    return computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'query.json',
        bytes: utf8.encode(jsonEncode(json)),
      ),
    ]);
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'resourceKind': resourceKind,
      'operation': operation.wireName,
      'view': view.wireName,
      'ids': ids,
      if (searchTerm != null) 'searchTerm': searchTerm,
      'fieldMask': fieldMask,
      'filters': filters,
      'sort': sort.map((field) => field.toJson()).toList(growable: false),
      'pageSize': pageSize,
      if (cursor != null) 'cursor': cursor,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _resourceKind(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^[a-z][A-Za-z0-9_]*$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'resourceKind',
      'must be a canonical resource kind',
    );
  }
  return normalized;
}

String? _optionalTrimmed(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

List<String> _fieldPaths(Iterable<String> values, String field) {
  final paths = normalizedContractStrings(values, field);
  for (final path in paths) {
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$')
        .hasMatch(path)) {
      throw ArgumentError.value(path, field, 'must be a dotted field path');
    }
  }
  return paths;
}

Map<String, Object?> _filters(Map<String, Object?> values) {
  _fieldPaths(values.keys, 'filters');
  return freezeContractJsonObject(values, field: 'filters');
}

List<AuthoringQuerySort> _sortFields(
  Iterable<AuthoringQuerySort> values,
) {
  final result = <AuthoringQuerySort>[];
  final seen = <String>{};
  for (final value in values) {
    final field = _fieldPaths([value.field], 'sort.field').single;
    if (!seen.add(field)) {
      throw ArgumentError.value(field, 'sort', 'fields must be unique');
    }
    result.add(
      AuthoringQuerySort(field: field, descending: value.descending),
    );
  }
  return List.unmodifiable(result);
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/query_page.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

final class AuthoringQueryPage {
  AuthoringQueryPage({
    required this.snapshotRevision,
    required Iterable<Map<String, Object?>> items,
    required this.totalAvailable,
    this.nextCursor,
  }) : items = List.unmodifiable([
          for (final item in items)
            freezeContractJsonObject(item, field: 'items'),
        ]) {
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(snapshotRevision)) {
      throw ArgumentError.value(
        snapshotRevision,
        'snapshotRevision',
        'must be a lowercase SHA-256 fingerprint',
      );
    }
    if (totalAvailable < this.items.length) {
      throw ArgumentError.value(
        totalAvailable,
        'totalAvailable',
        'cannot be smaller than returned items',
      );
    }
  }

  factory AuthoringQueryPage.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawItems = json['items'];
    final rawReturned = json['returned'];
    if (rawItems is! List || rawReturned is! int) {
      throw const FormatException(
        'items must be a list and returned must be an integer',
      );
    }
    try {
      final page = AuthoringQueryPage(
        snapshotRevision: requireContractString(
          json['snapshotRevision'],
          'snapshotRevision',
        ),
        items: rawItems.map((item) {
          if (item is! Map) {
            throw const FormatException('query item must be an object');
          }
          return Map<String, Object?>.from(item);
        }),
        totalAvailable: json['totalAvailable'] is int
            ? json['totalAvailable']! as int
            : throw const FormatException(
                'totalAvailable must be an integer',
              ),
        nextCursor: readOptionalContractString(
          json['nextCursor'],
          'nextCursor',
        ),
      );
      if (rawReturned != page.returned) {
        throw const FormatException(
          'returned must equal the number of query items',
        );
      }
      return page;
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'snapshotRevision',
    'items',
    'returned',
    'totalAvailable',
    'nextCursor',
  };

  final String snapshotRevision;
  final List<Map<String, Object?>> items;
  final int totalAvailable;
  final String? nextCursor;

  int get returned => items.length;

  Map<String, Object?> toJson() => {
        'snapshotRevision': snapshotRevision,
        'items': items,
        'returned': returned,
        'totalAvailable': totalAvailable,
        if (nextCursor != null) 'nextCursor': nextCursor,
      };
}
~~~~~~~~

## `packages/map_authoring/lib/src/workspace/project_query_service.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import 'project_snapshot.dart';

final class AuthoringQueryException implements Exception {
  const AuthoringQueryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringQueryException($code): $message';
}

/// Deterministic generic reads over one immutable [ProjectSnapshot].
final class ProjectQueryService {
  const ProjectQueryService();

  AuthoringQueryPage query(
    ProjectSnapshot snapshot,
    AuthoringQueryRequest request,
  ) {
    var records = _records(snapshot, request.resourceKind);
    records = _applyOperation(records, request);
    records = records
        .where((record) => _matchesFilters(record.detail, request.filters))
        .toList(growable: false);
    final ordered = records.toList()..sort(_comparator(request.sort));
    final offset = _cursorOffset(snapshot, request);
    if (offset > ordered.length) {
      throw const AuthoringQueryException(
        'query.cursor_invalid',
        'The query cursor offset is invalid.',
      );
    }
    final end = (offset + request.pageSize).clamp(0, ordered.length);
    final pageRecords = ordered.sublist(offset, end);
    final useDetail = request.operation != AuthoringQueryOperation.summary &&
        request.view == AuthoringQueryView.detail;
    final items = [
      for (final record in pageRecords)
        _applyFieldMask(
          useDetail ? record.detail : record.summary,
          request.fieldMask,
        ),
    ];
    final nextCursor = end < ordered.length
        ? _encodeCursor(
            revision: snapshot.revision,
            signature: request.signature,
            offset: end,
          )
        : null;
    return AuthoringQueryPage(
      snapshotRevision: snapshot.revision,
      items: items,
      totalAvailable: ordered.length,
      nextCursor: nextCursor,
    );
  }
}

List<_QueryRecord> _records(ProjectSnapshot snapshot, String resourceKind) {
  switch (resourceKind) {
    case 'project':
      return [
        _QueryRecord(
          summary: _projectSummary(snapshot),
          detail: _projectDetail(snapshot),
        ),
      ];
    case 'map':
      return [
        for (final map in snapshot.maps)
          _QueryRecord(
            summary: _mapSummary(map),
            detail: _mapDetail(map),
          ),
      ];
    default:
      throw const AuthoringQueryException(
        'query.resource_kind_unsupported',
        'The requested resource kind is not readable in this phase.',
      );
  }
}

List<_QueryRecord> _applyOperation(
  List<_QueryRecord> records,
  AuthoringQueryRequest request,
) {
  switch (request.operation) {
    case AuthoringQueryOperation.list:
    case AuthoringQueryOperation.summary:
      return records;
    case AuthoringQueryOperation.get:
      final matches = records
          .where((record) => record.id == request.ids.single)
          .toList(growable: false);
      if (matches.isEmpty) {
        throw const AuthoringQueryException(
          'query.resource_not_found',
          'The requested resource was not found.',
        );
      }
      return matches;
    case AuthoringQueryOperation.batchGet:
      final ids = request.ids.toSet();
      return records
          .where((record) => ids.contains(record.id))
          .toList(growable: false);
    case AuthoringQueryOperation.search:
      final term = request.searchTerm!.toLowerCase();
      return records
          .where(
            (record) =>
                record.id.toLowerCase().contains(term) ||
                record.name.toLowerCase().contains(term),
          )
          .toList(growable: false);
  }
}

Map<String, Object?> _projectSummary(ProjectSnapshot snapshot) => {
      'id': 'project',
      'name': snapshot.manifest.name,
      'resourceKind': 'project',
      'version': snapshot.manifest.version.name,
      'mapCount': snapshot.maps.length,
      'groupCount': snapshot.manifest.groups.length,
      'tilesetCount': snapshot.manifest.tilesets.length,
    };

Map<String, Object?> _projectDetail(ProjectSnapshot snapshot) {
  final detail = _jsonObject(snapshot.manifest.toJson());
  final settings = detail['settings'];
  if (settings is Map<String, Object?>) {
    final sanitizedSettings = Map<String, Object?>.from(settings)
      ..remove('mistralApiKey');
    detail['settings'] = sanitizedSettings;
  }
  final maps = detail['maps'];
  if (maps is List) {
    detail['maps'] = [
      for (final rawMap in maps)
        if (rawMap is Map)
          Map<String, Object?>.from(rawMap)..remove('relativePath'),
    ];
  }
  detail
    ..['id'] = 'project'
    ..['resourceKind'] = 'project';
  return detail;
}

Map<String, Object?> _mapSummary(MapData map) => {
      'id': map.id,
      'name': map.name,
      'resourceKind': 'map',
      'version': map.version.name,
      'size': {
        'width': map.size.width,
        'height': map.size.height,
      },
      'layerCount': map.layers.length,
      'entityCount': map.entities.length,
      'placedElementCount': map.placedElements.length,
      'eventCount': map.events.length,
    };

Map<String, Object?> _mapDetail(MapData map) =>
    _jsonObject(map.toJson())..['resourceKind'] = 'map';

Map<String, Object?> _jsonObject(Map<String, dynamic> value) =>
    Map<String, Object?>.from(value);

bool _matchesFilters(
  Map<String, Object?> source,
  Map<String, Object?> filters,
) {
  for (final entry in filters.entries) {
    final resolved = _readPath(source, entry.key);
    if (identical(resolved, _missingValue) ||
        !_jsonValuesEqual(resolved, entry.value)) {
      return false;
    }
  }
  return true;
}

bool _jsonValuesEqual(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_jsonValuesEqual(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !_jsonValuesEqual(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}

Comparator<_QueryRecord> _comparator(List<AuthoringQuerySort> sort) {
  final effectiveSort = sort.isEmpty
      ? const [AuthoringQuerySort(field: 'id')]
      : [...sort, const AuthoringQuerySort(field: 'id')];
  return (left, right) {
    for (final field in effectiveSort) {
      final leftValue = _readPath(left.detail, field.field);
      final rightValue = _readPath(right.detail, field.field);
      var order = _compareJsonValues(leftValue, rightValue);
      if (field.descending) order = -order;
      if (order != 0) return order;
    }
    return 0;
  };
}

int _compareJsonValues(Object? left, Object? right) {
  if (identical(left, right)) return 0;
  if (identical(left, _missingValue)) return 1;
  if (identical(right, _missingValue)) return -1;
  if (left == null) return -1;
  if (right == null) return 1;
  if (left is num && right is num) return left.compareTo(right);
  if (left is bool && right is bool) {
    return (left ? 1 : 0).compareTo(right ? 1 : 0);
  }
  return left.toString().compareTo(right.toString());
}

Map<String, Object?> _applyFieldMask(
  Map<String, Object?> source,
  List<String> fieldMask,
) {
  if (fieldMask.isEmpty) {
    return freezeContractJsonObject(source, field: 'query.item');
  }
  final selected = <String, Object?>{
    'id': source['id'],
    'name': source['name'],
    'resourceKind': source['resourceKind'],
  };
  for (final path in fieldMask) {
    final value = _readPath(source, path);
    if (identical(value, _missingValue)) {
      throw const AuthoringQueryException(
        'query.field_mask_unknown',
        'A requested field mask does not exist on this resource.',
      );
    }
    _writePath(selected, path, value);
  }
  return freezeContractJsonObject(selected, field: 'query.item');
}

Object? _readPath(Map<String, Object?> source, String path) {
  Object? current = source;
  for (final segment in path.split('.')) {
    if (current is! Map || !current.containsKey(segment)) {
      return _missingValue;
    }
    current = current[segment];
  }
  return current;
}

void _writePath(
  Map<String, Object?> target,
  String path,
  Object? value,
) {
  final segments = path.split('.');
  var current = target;
  for (var index = 0; index < segments.length - 1; index++) {
    final segment = segments[index];
    final child = current[segment];
    if (child is Map<String, Object?>) {
      current = child;
    } else {
      final created = <String, Object?>{};
      current[segment] = created;
      current = created;
    }
  }
  current[segments.last] = freezeContractJsonValue(
    value,
    field: 'fieldMask.$path',
  );
}

int _cursorOffset(
  ProjectSnapshot snapshot,
  AuthoringQueryRequest request,
) {
  final cursor = request.cursor;
  if (cursor == null) return 0;
  final decoded = _decodeCursor(cursor);
  if (decoded.revision != snapshot.revision) {
    throw const AuthoringQueryException(
      'query.cursor_stale',
      'The query cursor belongs to another project revision.',
    );
  }
  if (decoded.signature != request.signature) {
    throw const AuthoringQueryException(
      'query.cursor_mismatch',
      'The query cursor belongs to another normalized query.',
    );
  }
  return decoded.offset;
}

String _encodeCursor({
  required String revision,
  required String signature,
  required int offset,
}) {
  final bytes = utf8.encode(
    jsonEncode({
      'version': 1,
      'revision': revision,
      'signature': signature,
      'offset': offset,
    }),
  );
  return base64Url.encode(bytes).replaceAll('=', '');
}

_QueryCursor _decodeCursor(String value) {
  try {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(value))),
    );
    if (decoded is! Map ||
        decoded['version'] != 1 ||
        decoded['revision'] is! String ||
        decoded['signature'] is! String ||
        decoded['offset'] is! int ||
        (decoded['offset']! as int) < 0) {
      throw const FormatException('Invalid cursor payload.');
    }
    return _QueryCursor(
      revision: decoded['revision']! as String,
      signature: decoded['signature']! as String,
      offset: decoded['offset']! as int,
    );
  } on Object {
    throw const AuthoringQueryException(
      'query.cursor_invalid',
      'The query cursor is malformed.',
    );
  }
}

final class _QueryRecord {
  const _QueryRecord({
    required this.summary,
    required this.detail,
  });

  final Map<String, Object?> summary;
  final Map<String, Object?> detail;

  String get id => detail['id']! as String;
  String get name => detail['name']! as String;
}

final class _QueryCursor {
  const _QueryCursor({
    required this.revision,
    required this.signature,
    required this.offset,
  });

  final String revision;
  final String signature;
  final int offset;
}

const Object _missingValue = Object();
~~~~~~~~

## `packages/map_authoring/lib/src/domains/maps/map_region_query.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/json_contract_support.dart';

final class MapRegionQueryException implements Exception {
  const MapRegionQueryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'MapRegionQueryException($code): $message';
}

final class MapRegionQuery {
  const MapRegionQuery({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory MapRegionQuery.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    if (json['x'] is! int ||
        json['y'] is! int ||
        json['width'] is! int ||
        json['height'] is! int) {
      throw const FormatException('Map region coordinates must be integers.');
    }
    return MapRegionQuery(
      x: json['x']! as int,
      y: json['y']! as int,
      width: json['width']! as int,
      height: json['height']! as int,
    );
  }

  static const Set<String> _reservedKeys = {'x', 'y', 'width', 'height'};

  final int x;
  final int y;
  final int width;
  final int height;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      other is MapRegionQuery &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

final class MapRegionResult {
  MapRegionResult(Map<String, Object?> json)
      : _json = freezeContractJsonObject(json, field: 'mapRegion');

  final Map<String, Object?> _json;

  Map<String, Object?> toJson() => _json;
}

/// Returns a bounded spatial projection and never serializes the complete map.
MapRegionResult queryMapRegion(MapData map, MapRegionQuery query) {
  _validateBounds(map, query);
  final entities = map.entities
      .where(
        (entity) => _intersects(
          query,
          x: entity.pos.x,
          y: entity.pos.y,
          width: entity.size.width,
          height: entity.size.height,
        ),
      )
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final placedElements = map.placedElements
      .where(
        (element) => _containsPoint(query, element.pos.x, element.pos.y),
      )
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final warps = map.warps
      .where((warp) => _containsPoint(query, warp.pos.x, warp.pos.y))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final triggers = map.triggers
      .where((trigger) => _intersectsRect(query, trigger.area))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final gameplayZones = map.gameplayZones
      .where((zone) => _intersectsRect(query, zone.area))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return MapRegionResult({
    'mapId': map.id,
    'mapName': map.name,
    'resourceKind': 'region',
    'bounds': query.toJson(),
    'layers': [
      for (final layer in map.layers)
        _sliceLayer(layer, mapWidth: map.size.width, query: query),
    ],
    'entities': [
      for (final entity in entities) _jsonObject(entity.toJson()),
    ],
    'placedElements': [
      for (final element in placedElements) _jsonObject(element.toJson()),
    ],
    'warps': [
      for (final warp in warps) _jsonObject(warp.toJson()),
    ],
    'triggers': [
      for (final trigger in triggers) _jsonObject(trigger.toJson()),
    ],
    'gameplayZones': [
      for (final zone in gameplayZones) _jsonObject(zone.toJson()),
    ],
    'nonSpatialConnectionCount': map.connections.length,
    'nonSpatialEventCount': map.events.length,
  });
}

Map<String, Object?> _sliceLayer(
  MapLayer layer, {
  required int mapWidth,
  required MapRegionQuery query,
}) {
  final base = <String, Object?>{
    'id': layer.id,
    'name': layer.name,
    'isVisible': layer.isVisible,
    'opacity': layer.opacity,
  };
  return switch (layer) {
    TileLayer() => {
        ...base,
        'type': 'tile',
        'encoding': 'grid_rows',
        if (layer.tilesetId != null) 'tilesetId': layer.tilesetId,
        'rows': _sliceFlat(
          layer.tiles,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    CollisionLayer() => {
        ...base,
        'type': 'collision',
        'encoding': 'grid_rows',
        'rows': _sliceFlat(
          layer.collisions,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    TerrainLayer() => {
        ...base,
        'type': 'terrain',
        'encoding': 'grid_rows',
        'rows': _sliceFlat(
          layer.terrains,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value.name,
        ),
      },
    PathLayer() => {
        ...base,
        'type': 'path',
        'encoding': 'grid_rows',
        'presetId': layer.presetId,
        'rows': _sliceFlat(
          layer.cells,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    SurfaceLayer() => {
        ...base,
        'type': 'surface',
        'encoding': 'placements',
        'placements': _surfacePlacements(layer, query),
      },
    SmartTileLayer() => {
        ...base,
        'type': 'smart_tile',
        'encoding': 'grid_rows',
        'presetId': layer.presetId,
        'rows': _sliceFlat(
          layer.materialCells,
          mapWidth: mapWidth,
          query: query,
          encode: (value) => value,
        ),
      },
    ObjectLayer() => {
        ...base,
        'type': 'object',
        'encoding': 'metadata_only',
      },
    EnvironmentLayer() => {
        ...base,
        'type': 'environment',
        'encoding': 'metadata_only',
      },
    BorderLayer() => {
        ...base,
        'type': 'border',
        'encoding': 'metadata_only',
      },
  };
}

List<Map<String, Object?>> _surfacePlacements(
  SurfaceLayer layer,
  MapRegionQuery query,
) {
  final placements = layer.placements
      .where(
        (placement) => _containsPoint(query, placement.x, placement.y),
      )
      .toList()
    ..sort((left, right) {
      final yOrder = left.y.compareTo(right.y);
      if (yOrder != 0) return yOrder;
      final xOrder = left.x.compareTo(right.x);
      if (xOrder != 0) return xOrder;
      return left.surfacePresetId.compareTo(right.surfacePresetId);
    });
  return [
    for (final placement in placements) _jsonObject(placement.toJson()),
  ];
}

List<List<Object?>> _sliceFlat<T>(
  List<T> values, {
  required int mapWidth,
  required MapRegionQuery query,
  required Object? Function(T value) encode,
}) {
  return [
    for (var row = 0; row < query.height; row++)
      [
        for (var column = 0; column < query.width; column++)
          if (((query.y + row) * mapWidth) + query.x + column < values.length)
            encode(
              values[((query.y + row) * mapWidth) + query.x + column],
            )
          else
            null,
      ],
  ];
}

void _validateBounds(MapData map, MapRegionQuery query) {
  if (query.width <= 0 || query.height <= 0) {
    throw const MapRegionQueryException(
      'map.region_size_invalid',
      'Map region dimensions must be positive.',
    );
  }
  if (query.x < 0 ||
      query.y < 0 ||
      query.x + query.width > map.size.width ||
      query.y + query.height > map.size.height) {
    throw const MapRegionQueryException(
      'map.region_out_of_bounds',
      'The requested map region is outside the map bounds.',
    );
  }
}

bool _containsPoint(MapRegionQuery query, int x, int y) =>
    x >= query.x &&
    y >= query.y &&
    x < query.x + query.width &&
    y < query.y + query.height;

bool _intersectsRect(MapRegionQuery query, MapRect rect) => _intersects(
      query,
      x: rect.pos.x,
      y: rect.pos.y,
      width: rect.size.width,
      height: rect.size.height,
    );

bool _intersects(
  MapRegionQuery query, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  return x < query.x + query.width &&
      x + width > query.x &&
      y < query.y + query.height &&
      y + height > query.y;
}

Map<String, Object?> _jsonObject(Map<String, dynamic> value) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
~~~~~~~~

## `packages/map_authoring/test/workspace/project_snapshot_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSnapshotLoader', () {
    test('loads the manifest and maps from the real fixture', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
      );
      final opened = await harness.openService.openProject(fixture.path);

      final snapshot = await harness.loader.load(opened.projectHandle);

      expect(snapshot.manifest.name, 'P3 Narrative Smoke Slice');
      expect(snapshot.maps, hasLength(1));
      expect(snapshot.maps.single.id, 'p3_narrative_smoke_map');
      expect(
          snapshot.mapById('p3_narrative_smoke_map'), same(snapshot.maps[0]));
      expect(snapshot.revision, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(
        snapshot.resourceFingerprints.keys,
        ['map:p3_narrative_smoke_map', 'project'],
      );
      expect(
        snapshot.resourceFingerprints.values,
        everyElement(matches(r'^sha256:[0-9a-f]{64}$')),
      );
    });

    test('returns the same revision and deterministic map order on reload',
        () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_order_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [
          _mapEntry('z-map', 'maps/z.json'),
          _mapEntry('a-map', 'maps/a.json'),
        ],
        maps: [
          _mapJson('z-map'),
          _mapJson('a-map'),
        ],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      final first = await harness.loader.load(opened.projectHandle);
      final second = await harness.loader.load(opened.projectHandle);

      expect(second.revision, first.revision);
      expect(first.maps.map((map) => map.id), ['a-map', 'z-map']);
      expect(
        () => first.maps.add(first.maps.first),
        throwsUnsupportedError,
      );
      expect(
        () => first.resourceFingerprints['project'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects a resource changed during the two-pass load', () async {
      final fixture = _realFixtureDirectory();
      final reader = _ChangingProjectReader(
        delegate: const LocalProjectFileReader(),
        changeProjectJsonOnRead: 3,
      );
      final harness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
        reader: reader,
      );
      final opened = await harness.openService.openProject(fixture.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.changed_during_snapshot',
          ),
        ),
      );
    });

    test('rejects duplicate manifest map IDs', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_duplicate_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [
          _mapEntry('same', 'maps/first.json'),
          _mapEntry('same', 'maps/second.json'),
        ],
        maps: [
          _mapJson('same'),
          _mapJson('same'),
        ],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.duplicate_map_id',
          ),
        ),
      );
    });

    test('rejects a map whose document ID differs from the manifest', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_snapshot_mismatch_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await _writeProject(
        sandbox,
        mapEntries: [_mapEntry('expected', 'maps/field.json')],
        maps: [_mapJson('actual')],
      );
      final harness = await _SnapshotHarness.create(allowedRoot: sandbox);
      final opened = await harness.openService.openProject(project.path);

      await expectLater(
        () => harness.loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.map_identity_mismatch',
          ),
        ),
      );
    });

    test('rejects an unknown project handle', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _SnapshotHarness.create(
        allowedRoot: fixture.parent,
      );

      await expectLater(
        () => harness.loader.load(const ProjectHandle('prj_unknown')),
        throwsA(isA<WorkspaceHandleException>()),
      );
    });

    test('rejects duplicate direct snapshot maps and invalid fingerprints', () {
      final map = MapData(
        id: 'same',
        name: 'Same',
        size: const GridSize(width: 1, height: 1),
        layers: const [],
      );
      final manifest = ProjectManifest(
        name: 'Direct Snapshot',
        maps: const [],
        tilesets: const [],
      );

      expect(
        () => ProjectSnapshot(
          projectHandle: const ProjectHandle('prj_direct'),
          revision: 'sha256:${List.filled(64, 'a').join()}',
          manifest: manifest,
          maps: [map, map],
          resourceFingerprints: {
            'project': 'sha256:${List.filled(64, 'b').join()}',
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => ProjectSnapshot(
          projectHandle: const ProjectHandle('prj_direct'),
          revision: 'sha256:${List.filled(64, 'a').join()}',
          manifest: manifest,
          maps: const [],
          resourceFingerprints: const {'project': 'not-a-fingerprint'},
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _SnapshotHarness {
  const _SnapshotHarness({
    required this.openService,
    required this.loader,
  });

  static Future<_SnapshotHarness> create({
    required Directory allowedRoot,
    ProjectFileReader reader = const LocalProjectFileReader(),
  }) async {
    var token = 0;
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [allowedRoot.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 7, 31, 12),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    return _SnapshotHarness(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      loader: ProjectSnapshotLoader(handles: handles),
    );
  }

  final ProjectOpenService openService;
  final ProjectSnapshotLoader loader;
}

final class _ChangingProjectReader implements ProjectFileReader {
  _ChangingProjectReader({
    required this.delegate,
    required this.changeProjectJsonOnRead,
  });

  final ProjectFileReader delegate;
  final int changeProjectJsonOnRead;
  int _projectJsonReads = 0;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final bytes = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (relativePath == 'project.json') {
      _projectJsonReads++;
      if (_projectJsonReads == changeProjectJsonOnRead) {
        return [...bytes, ...utf8.encode(' ')];
      }
    }
    return bytes;
  }
}

Future<Directory> _writeProject(
  Directory sandbox, {
  required List<Map<String, Object?>> mapEntries,
  required List<Map<String, Object?>> maps,
}) async {
  final project = await Directory(_join(sandbox.path, 'project')).create();
  final mapsDirectory =
      await Directory(_join(project.path, 'maps')).create(recursive: true);
  final manifest = {
    'name': 'Snapshot Test',
    'version': 'v1',
    'maps': mapEntries,
    'tilesets': <Object?>[],
  };
  await File(_join(project.path, 'project.json'))
      .writeAsString(jsonEncode(manifest));
  for (var index = 0; index < mapEntries.length; index++) {
    final fileName =
        (mapEntries[index]['relativePath']! as String).split('/').last;
    await File(_join(mapsDirectory.path, fileName))
        .writeAsString(jsonEncode(maps[index]));
  }
  return project;
}

Map<String, Object?> _mapEntry(String id, String relativePath) => {
      'id': id,
      'name': id,
      'relativePath': relativePath,
      'role': 'exterior',
      'sortOrder': 0,
    };

Map<String, Object?> _mapJson(String id) => {
      'id': id,
      'name': id,
      'size': {'width': 2, 'height': 2},
      'version': 'v1',
      'layers': <Object?>[],
    };

Directory _realFixtureDirectory() {
  return Directory(
    _join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
]) =>
    [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ].join(Platform.pathSeparator);
~~~~~~~~

## `packages/map_authoring/test/contracts/query_pagination_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringQueryRequest', () {
    test('round-trips strict canonical JSON', () {
      final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.search,
        view: AuthoringQueryView.detail,
        searchTerm: ' field ',
        fieldMask: const ['size.width', 'name', 'name'],
        filters: const {'version': 'v1'},
        sort: const [
          AuthoringQuerySort(field: 'name', descending: true),
        ],
        pageSize: 2,
      );

      final decoded = AuthoringQueryRequest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(request.toJson())) as Map,
        ),
      );

      expect(decoded.toJson(), request.toJson());
      expect(decoded.searchTerm, 'field');
      expect(decoded.fieldMask, ['name', 'size.width']);
      expect(decoded.signature, request.signature);
    });

    test('rejects unknown fields and operation-specific invalid input', () {
      expect(
        () => AuthoringQueryRequest.fromJson({
          'resourceKind': 'map',
          'operation': 'list',
          'view': 'summary',
          'ids': <Object?>[],
          'fieldMask': <Object?>[],
          'filters': <String, Object?>{},
          'sort': <Object?>[],
          'pageSize': 10,
          'unknown': true,
        }),
        throwsFormatException,
      );
      expect(
        () => AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: ' ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProjectQueryService pagination', () {
    test('paginates deterministically across a frozen snapshot', () {
      final snapshot = _snapshot();
      final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.list,
        pageSize: 1,
      );

      final first = const ProjectQueryService().query(snapshot, request);
      final second = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
          cursor: first.nextCursor,
        ),
      );
      final third = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
          cursor: second.nextCursor,
        ),
      );

      expect(
        [
          first.items.single['id'],
          second.items.single['id'],
          third.items.single['id']
        ],
        ['a-map', 'b-map', 'c-map'],
      );
      expect(first.snapshotRevision, snapshot.revision);
      expect(first.totalAvailable, 3);
      expect(third.nextCursor, isNull);
    });

    test('rejects a cursor bound to another revision', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();
      final first = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
        ),
      );
      final changed = _snapshot(revisionDigit: 'b');

      expect(
        () => service.query(
          changed,
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.list,
            pageSize: 1,
            cursor: first.nextCursor,
          ),
        ),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.cursor_stale',
          ),
        ),
      );
    });

    test('rejects a cursor reused with a different normalized query', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();
      final first = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'map',
          pageSize: 1,
        ),
      );

      expect(
        () => service.query(
          snapshot,
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.search,
            searchTerm: 'bravo',
            pageSize: 1,
            cursor: first.nextCursor,
          ),
        ),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.cursor_mismatch',
          ),
        ),
      );
    });
  });

  group('ProjectQueryService operations', () {
    test('supports get, batch_get, search, and project summary', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();

      final get = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: ['b-map'],
        ),
      );
      final batch = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.batchGet,
          ids: ['c-map', 'a-map'],
        ),
      );
      final search = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'bravo',
        ),
      );
      final summary = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.summary,
        ),
      );

      expect(get.items.single['id'], 'b-map');
      expect(batch.items.map((item) => item['id']), ['a-map', 'c-map']);
      expect(search.items.single['name'], 'Bravo Field');
      expect(summary.items.single, containsPair('mapCount', 3));
    });

    test('applies filters, descending sort, and dotted field masks', () {
      final page = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          filters: {'size.width': 2},
          sort: [
            AuthoringQuerySort(field: 'name', descending: true),
          ],
          fieldMask: ['size.width'],
        ),
      );

      expect(page.items.map((item) => item['id']), ['c-map', 'b-map']);
      expect(page.items.first.keys, ['id', 'name', 'resourceKind', 'size']);
      expect(page.items.first['size'], {'width': 2});
    });

    test('compares composite JSON filter values deeply', () {
      final page = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          filters: {
            'properties.tags': ['forest', 'day'],
          },
        ),
      );

      expect(page.items.map((item) => item['id']), ['a-map']);
    });

    test('summary is smaller than detail without losing identity', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();
      final summary = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: ['a-map'],
        ),
      );
      final detail = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: ['a-map'],
          view: AuthoringQueryView.detail,
        ),
      );
      final summaryJson = jsonEncode(summary.toJson());
      final detailJson = jsonEncode(detail.toJson());

      expect(summary.items.single['id'], detail.items.single['id']);
      expect(summary.items.single['name'], detail.items.single['name']);
      expect(summary.items.single['resourceKind'], 'map');
      expect(summaryJson.length, lessThan(detailJson.length));
    });

    test('does not expose manifest paths or the persisted editor API key', () {
      final page = const ProjectQueryService().query(
        _snapshot(withApiKey: true),
        AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.get,
          ids: ['project'],
          view: AuthoringQueryView.detail,
        ),
      );
      final encoded = jsonEncode(page.toJson());

      expect(encoded, isNot(contains('relativePath')));
      expect(encoded, isNot(contains('mistralApiKey')));
      expect(encoded, isNot(contains('super-secret')));
    });
  });

  group('AuthoringQueryPage', () {
    test('rejects a serialized returned count that does not match items', () {
      final page = const ProjectQueryService()
          .query(
            _snapshot(),
            AuthoringQueryRequest(
              resourceKind: 'map',
              operation: AuthoringQueryOperation.list,
              pageSize: 1,
            ),
          )
          .toJson();

      expect(
        () => AuthoringQueryPage.fromJson({...page, 'returned': 99}),
        throwsFormatException,
      );
    });

    test('rejects a malformed continuation cursor', () {
      expect(
        () => const ProjectQueryService().query(
          _snapshot(),
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.list,
            cursor: 'not-base64-json',
          ),
        ),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.cursor_invalid',
          ),
        ),
      );
    });
  });
}

ProjectSnapshot _snapshot({
  String revisionDigit = 'a',
  bool withApiKey = false,
}) {
  final maps = [
    _map(
      id: 'c-map',
      name: 'Charlie Field',
      width: 2,
      tiles: const [1, 2, 3, 4],
    ),
    _map(
      id: 'a-map',
      name: 'Alpha Field',
      width: 3,
      tiles: const [1, 2, 3, 4, 5, 6],
    ),
    _map(
      id: 'b-map',
      name: 'Bravo Field',
      width: 2,
      tiles: const [7, 8, 9, 10],
    ),
  ];
  final manifest = ProjectManifest(
    name: 'Query Project',
    version: ProjectVersion.v1,
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: const [],
    settings: ProjectSettings(
      mistralApiKey: withApiKey ? 'super-secret' : null,
    ),
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_query'),
    revision: 'sha256:${List.filled(64, revisionDigit).join()}',
    manifest: manifest,
    maps: maps,
    resourceFingerprints: {
      'project': 'sha256:${List.filled(64, '1').join()}',
      for (final map in maps)
        'map:${map.id}':
            'sha256:${List.filled(64, map.id.codeUnitAt(0).isEven ? '2' : '3').join()}',
    },
  );
}

MapData _map({
  required String id,
  required String name,
  required int width,
  required List<int> tiles,
}) {
  return MapData(
    id: id,
    name: name,
    size: GridSize(width: width, height: 2),
    version: ProjectVersion.v1,
    layers: [
      MapLayer.tile(
        id: '$id-ground',
        name: 'Ground',
        tiles: tiles,
      ),
    ],
    properties: {
      'description': 'A detailed projection carries this field.',
      'tags': id == 'a-map' ? ['forest', 'day'] : ['city'],
    },
  );
}
~~~~~~~~

## `packages/map_authoring/test/domains/maps/map_region_query_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('queryMapRegion', () {
    test('returns clipped grid rows and intersecting spatial resources', () {
      final result = queryMapRegion(
        _map(),
        const MapRegionQuery(x: 1, y: 1, width: 2, height: 2),
      );
      final json = result.toJson();
      final layers = (json['layers']! as List).cast<Map<String, Object?>>();

      expect(json['mapId'], 'region-map');
      expect(json['bounds'], {
        'x': 1,
        'y': 1,
        'width': 2,
        'height': 2,
      });
      expect(layers[0]['rows'], [
        [5, 6],
        [9, 10],
      ]);
      expect(layers[1]['rows'], [
        [false, true],
        [true, false],
      ]);
      expect(
        (json['entities']! as List)
            .cast<Map<String, Object?>>()
            .map((entity) => entity['id']),
        ['inside-entity'],
      );
      expect(
        (json['placedElements']! as List)
            .cast<Map<String, Object?>>()
            .map((element) => element['id']),
        ['inside-element'],
      );
      expect(
        (json['warps']! as List)
            .cast<Map<String, Object?>>()
            .map((warp) => warp['id']),
        ['inside-warp'],
      );
      expect(
        (json['triggers']! as List)
            .cast<Map<String, Object?>>()
            .map((trigger) => trigger['id']),
        ['inside-trigger'],
      );
      expect(
        (json['gameplayZones']! as List)
            .cast<Map<String, Object?>>()
            .map((zone) => zone['id']),
        ['inside-zone'],
      );
    });

    test('returns surface placements and metadata-only object layers', () {
      final result = queryMapRegion(
        _map(),
        const MapRegionQuery(x: 1, y: 1, width: 2, height: 2),
      );
      final layers =
          (result.toJson()['layers']! as List).cast<Map<String, Object?>>();
      final surface = layers.singleWhere((layer) => layer['type'] == 'surface');
      final object = layers.singleWhere((layer) => layer['type'] == 'object');

      expect(
        (surface['placements']! as List)
            .cast<Map<String, Object?>>()
            .map((placement) => [placement['x'], placement['y']]),
        [
          [2, 1],
          [1, 2],
        ],
      );
      expect(object['encoding'], 'metadata_only');
      expect(object, isNot(contains('content')));
    });

    test('is materially smaller than the full map detail', () {
      final map = _map();
      final result = queryMapRegion(
        map,
        const MapRegionQuery(x: 1, y: 1, width: 1, height: 1),
      );

      expect(
        jsonEncode(result.toJson()).length,
        lessThan(jsonEncode(map.toJson()).length),
      );
    });

    test('rejects non-positive and out-of-bounds regions', () {
      expect(
        () => queryMapRegion(
          _map(),
          const MapRegionQuery(x: 0, y: 0, width: 0, height: 1),
        ),
        throwsA(
          isA<MapRegionQueryException>().having(
            (error) => error.code,
            'code',
            'map.region_size_invalid',
          ),
        ),
      );
      expect(
        () => queryMapRegion(
          _map(),
          const MapRegionQuery(x: 3, y: 2, width: 2, height: 2),
        ),
        throwsA(
          isA<MapRegionQueryException>().having(
            (error) => error.code,
            'code',
            'map.region_out_of_bounds',
          ),
        ),
      );
    });

    test('round-trips the strict region request JSON', () {
      const query = MapRegionQuery(x: 1, y: 2, width: 3, height: 4);

      expect(MapRegionQuery.fromJson(query.toJson()), query);
      expect(
        () => MapRegionQuery.fromJson({
          ...query.toJson(),
          'unknown': true,
        }),
        throwsFormatException,
      );
    });
  });
}

MapData _map() {
  return MapData(
    id: 'region-map',
    name: 'Region Map',
    size: const GridSize(width: 4, height: 3),
    version: ProjectVersion.v1,
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tiles: List.generate(12, (index) => index),
      ),
      const MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: [
          false,
          false,
          false,
          false,
          false,
          false,
          true,
          false,
          false,
          true,
          false,
          false,
        ],
      ),
      const MapLayer.surface(
        id: 'surface',
        name: 'Surface',
        placements: [
          SurfaceCellPlacement(
            x: 1,
            y: 2,
            surfacePresetId: 'flowers',
          ),
          SurfaceCellPlacement(
            x: 2,
            y: 1,
            surfacePresetId: 'grass',
          ),
          SurfaceCellPlacement(
            x: 0,
            y: 0,
            surfacePresetId: 'water',
          ),
        ],
      ),
      const MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: const [
      MapEntity(
        id: 'inside-entity',
        name: 'Inside',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 2),
      ),
      MapEntity(
        id: 'outside-entity',
        name: 'Outside',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'inside-element',
        layerId: 'objects',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
      MapPlacedElement(
        id: 'outside-element',
        layerId: 'objects',
        elementId: 'rock',
        pos: GridPos(x: 0, y: 0),
      ),
    ],
    warps: const [
      MapWarp(
        id: 'inside-warp',
        pos: GridPos(x: 2, y: 1),
        targetMapId: 'other',
        targetPos: GridPos(x: 0, y: 0),
      ),
      MapWarp(
        id: 'outside-warp',
        pos: GridPos(x: 0, y: 0),
        targetMapId: 'other',
        targetPos: GridPos(x: 0, y: 0),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: 'inside-trigger',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      ),
      MapTrigger(
        id: 'outside-trigger',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
    gameplayZones: const [
      MapGameplayZone(
        id: 'inside-zone',
        kind: GameplayZoneKind.custom,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 2, height: 1),
        ),
      ),
      MapGameplayZone(
        id: 'outside-zone',
        kind: GameplayZoneKind.custom,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
  );
}
~~~~~~~~
