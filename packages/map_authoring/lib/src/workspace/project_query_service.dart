import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../domains/assets/asset_store.dart';
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
    case 'asset':
      final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
      if (bytes == null) return const [];
      final catalog = _decodeAssetCatalog(bytes);
      return [
        for (final asset in catalog.records)
          _QueryRecord(
            summary: _assetSummary(asset),
            detail: _assetDetail(asset),
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

Map<String, Object?> _assetSummary(AssetRecord asset) => {
      'id': asset.id,
      'name': asset.logicalPath,
      'resourceKind': 'asset',
      'mediaType': asset.artifact.mediaType,
      'byteLength': asset.artifact.byteLength,
      'unused': asset.usages.isEmpty,
    };

Map<String, Object?> _assetDetail(AssetRecord asset) => {
      ...asset.toJson(),
      'name': asset.logicalPath,
      'resourceKind': 'asset',
      'unused': asset.usages.isEmpty,
      'preview': {
        'artifactHandle': asset.artifact.handle,
        'mediaType': asset.artifact.mediaType,
      },
    };

AssetCatalog _decodeAssetCatalog(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw const AuthoringQueryException(
      'query.asset_catalog_invalid',
      'The project asset catalog cannot be queried safely.',
    );
  }
}

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
