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
