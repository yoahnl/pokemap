import 'json_contract_support.dart';
import 'resource_ref.dart';

enum AuthoringDiffOperation {
  add('add'),
  remove('remove'),
  replace('replace'),
  move('move'),
  link('link'),
  unlink('unlink');

  const AuthoringDiffOperation(this.wireName);

  final String wireName;

  static AuthoringDiffOperation fromWireName(String value) {
    return AuthoringDiffOperation.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown diff operation: $value'),
    );
  }
}

/// One deterministic change against one typed resource.
final class AuthoringDiffEntry {
  factory AuthoringDiffEntry({
    required AuthoringDiffOperation operation,
    required AuthoringResourceRef resource,
    required String path,
    Object? before = _absentJsonValue,
    Object? after = _absentJsonValue,
    Map<String, Object?> extensions = const {},
  }) {
    return AuthoringDiffEntry._(
      operation: operation,
      resource: resource,
      path: _nonBlank(path, 'path'),
      hasBefore: !identical(before, _absentJsonValue),
      before: identical(before, _absentJsonValue)
          ? null
          : freezeContractJsonValue(before, field: 'before'),
      hasAfter: !identical(after, _absentJsonValue),
      after: identical(after, _absentJsonValue)
          ? null
          : freezeContractJsonValue(after, field: 'after'),
      extensions: validateContractExtensions(
        extensions,
        reservedKeys: _reservedKeys,
      ),
    );
  }

  AuthoringDiffEntry._({
    required this.operation,
    required this.resource,
    required this.path,
    required this.hasBefore,
    required this.before,
    required this.hasAfter,
    required this.after,
    required this.extensions,
  });

  factory AuthoringDiffEntry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawResource = json['resource'];
    if (rawResource is! Map) {
      throw const FormatException('resource must be a JSON object');
    }
    try {
      return AuthoringDiffEntry(
        operation: AuthoringDiffOperation.fromWireName(
          requireContractString(json['operation'], 'operation'),
        ),
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(rawResource),
        ),
        path: requireContractString(json['path'], 'path'),
        before: json.containsKey('before') ? json['before'] : _absentJsonValue,
        after: json.containsKey('after') ? json['after'] : _absentJsonValue,
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
    'operation',
    'resource',
    'path',
    'before',
    'after',
    'extensions',
  };

  final AuthoringDiffOperation operation;
  final AuthoringResourceRef resource;
  final String path;
  final bool hasBefore;
  final Object? before;
  final bool hasAfter;
  final Object? after;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'operation': operation.wireName,
      'resource': resource.toJson(),
      'path': path,
      if (hasBefore) 'before': before,
      if (hasAfter) 'after': after,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

const Object _absentJsonValue = Object();

/// Sorted diff plus the exact set of resources it affects.
final class AuthoringDiff {
  AuthoringDiff(Iterable<AuthoringDiffEntry> changes)
      : entries = _sortedEntries(changes) {
    final byKey = <String, AuthoringResourceRef>{};
    for (final entry in entries) {
      byKey[_resourceKey(entry.resource)] = entry.resource;
    }
    affectedResources = List.unmodifiable(
      byKey.values.toList()
        ..sort(
            (left, right) => _resourceKey(left).compareTo(_resourceKey(right))),
    );
  }

  factory AuthoringDiff.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'entries'});
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('entries must be a JSON list');
    }
    return AuthoringDiff(
      rawEntries.map((rawEntry) {
        if (rawEntry is! Map) {
          throw const FormatException('diff entry must be a JSON object');
        }
        return AuthoringDiffEntry.fromJson(
          Map<String, dynamic>.from(rawEntry),
        );
      }),
    );
  }

  final List<AuthoringDiffEntry> entries;
  late final List<AuthoringResourceRef> affectedResources;

  Map<String, Object?> toJson() {
    return {
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  static List<AuthoringDiffEntry> _sortedEntries(
    Iterable<AuthoringDiffEntry> changes,
  ) {
    final sorted = changes.toList()
      ..sort((left, right) {
        final resourceComparison =
            _resourceKey(left.resource).compareTo(_resourceKey(right.resource));
        if (resourceComparison != 0) return resourceComparison;
        final pathComparison = left.path.compareTo(right.path);
        if (pathComparison != 0) return pathComparison;
        return left.operation.wireName.compareTo(right.operation.wireName);
      });
    return List.unmodifiable(sorted);
  }
}

String _resourceKey(AuthoringResourceRef resource) {
  return '${resource.kind}\u0000${resource.id}\u0000${resource.revision ?? ''}';
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}
