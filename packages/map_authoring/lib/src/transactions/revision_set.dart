import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';
import 'change_set.dart';

final class AuthoringResourceRevision {
  AuthoringResourceRevision({
    required this.resource,
    required String? revision,
  }) : revision = _optionalRevision(revision) {
    if (resource.revision != null && resource.revision != this.revision) {
      throw ArgumentError.value(
        resource.revision,
        'resource.revision',
        'must match the explicit resource revision',
      );
    }
  }

  factory AuthoringResourceRevision.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !const {'resource', 'revision'}.contains(key))) {
      throw const FormatException('Unknown resource revision field.');
    }
    final rawResource = json['resource'];
    if (rawResource is! Map || !json.containsKey('revision')) {
      throw const FormatException(
        'resource must be an object and revision must be present.',
      );
    }
    final rawRevision = json['revision'];
    if (rawRevision != null && rawRevision is! String) {
      throw const FormatException('revision must be a string or null.');
    }
    try {
      return AuthoringResourceRevision(
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(rawResource),
        ),
        revision: rawRevision as String?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringResourceRef resource;

  /// Null is an explicit, compareable "resource is absent" revision.
  final String? revision;

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'revision': revision,
      };
}

final class AuthoringRevisionConflictEntry {
  const AuthoringRevisionConflictEntry({
    required this.resource,
    required this.expectedKnown,
    required this.expectedRevision,
    required this.currentKnown,
    required this.currentRevision,
  });

  final AuthoringResourceRef resource;
  final bool expectedKnown;
  final String? expectedRevision;
  final bool currentKnown;
  final String? currentRevision;

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'expectedKnown': expectedKnown,
        'expectedRevision': expectedRevision,
        'currentKnown': currentKnown,
        'currentRevision': currentRevision,
      };
}

final class AuthoringRevisionConflict implements Exception {
  AuthoringRevisionConflict(Iterable<AuthoringRevisionConflictEntry> conflicts)
      : conflicts = List.unmodifiable(conflicts);

  final String code = 'revision.conflict';
  final List<AuthoringRevisionConflictEntry> conflicts;
  final List<String> remediation = const [
    'Reload the touched resources and create a new mutation plan.',
  ];

  @override
  String toString() =>
      'AuthoringRevisionConflict($code): ${conflicts.length} resource(s)';
}

/// Exact expected/current revisions for a touched resource set.
final class AuthoringRevisionSet {
  AuthoringRevisionSet(Iterable<AuthoringResourceRevision> entries)
      : entries = _sortedEntries(entries) {
    final byKey = <String, AuthoringResourceRevision>{};
    for (final entry in this.entries) {
      final key = _resourceKey(entry.resource);
      if (byKey.containsKey(key)) {
        throw ArgumentError.value(
          entry.resource.toJson(),
          'entries',
          'resource revisions must be unique',
        );
      }
      byKey[key] = entry;
    }
    _byKey = Map.unmodifiable(byKey);
    fingerprint = computeAuthoringJsonFingerprint(
      [for (final entry in this.entries) entry.toJson()],
      logicalName: 'revision-set.json',
    );
  }

  factory AuthoringRevisionSet.beforeChangeSet(AuthoringChangeSet changeSet) {
    return AuthoringRevisionSet([
      for (final change in changeSet.changes)
        AuthoringResourceRevision(
          resource: change.resource,
          revision: change.beforeRevision,
        ),
    ]);
  }

  factory AuthoringRevisionSet.afterChangeSet(AuthoringChangeSet changeSet) {
    return AuthoringRevisionSet([
      for (final change in changeSet.changes)
        AuthoringResourceRevision(
          resource: change.resource,
          revision: change.afterRevision,
        ),
    ]);
  }

  factory AuthoringRevisionSet.fromJson(Map<String, dynamic> json) {
    if (json.keys
        .any((key) => !const {'entries', 'fingerprint'}.contains(key))) {
      throw const FormatException('Unknown revision set field.');
    }
    final rawEntries = json['entries'];
    final rawFingerprint = json['fingerprint'];
    if (rawEntries is! List || rawFingerprint is! String) {
      throw const FormatException(
        'entries must be a list and fingerprint must be a string.',
      );
    }
    final set = AuthoringRevisionSet(rawEntries.map((rawEntry) {
      if (rawEntry is! Map) {
        throw const FormatException('revision entry must be an object.');
      }
      return AuthoringResourceRevision.fromJson(
        Map<String, dynamic>.from(rawEntry),
      );
    }));
    if (set.fingerprint != rawFingerprint) {
      throw const FormatException('revision set fingerprint does not match.');
    }
    return set;
  }

  final List<AuthoringResourceRevision> entries;
  late final Map<String, AuthoringResourceRevision> _byKey;
  late final String fingerprint;

  bool contains(AuthoringResourceRef resource) =>
      _byKey.containsKey(_resourceKey(resource));

  String? revisionOf(AuthoringResourceRef resource) =>
      _byKey[_resourceKey(resource)]?.revision;

  void requireMatches(AuthoringRevisionSet current) {
    final conflicts = <AuthoringRevisionConflictEntry>[];
    final keys = {..._byKey.keys, ...current._byKey.keys}.toList()..sort();
    for (final key in keys) {
      final expectedEntry = _byKey[key];
      final currentEntry = current._byKey[key];
      if (expectedEntry == null ||
          currentEntry == null ||
          expectedEntry.revision != currentEntry.revision) {
        conflicts.add(
          AuthoringRevisionConflictEntry(
            resource: expectedEntry?.resource ?? currentEntry!.resource,
            expectedKnown: expectedEntry != null,
            expectedRevision: expectedEntry?.revision,
            currentKnown: currentEntry != null,
            currentRevision: currentEntry?.revision,
          ),
        );
      }
    }
    if (conflicts.isNotEmpty) {
      throw AuthoringRevisionConflict(conflicts);
    }
  }

  T guard<T>(AuthoringRevisionSet current, T Function() mutation) {
    requireMatches(current);
    return mutation();
  }

  Map<String, Object?> toJson() => {
        'entries': [for (final entry in entries) entry.toJson()],
        'fingerprint': fingerprint,
      };
}

List<AuthoringResourceRevision> _sortedEntries(
  Iterable<AuthoringResourceRevision> entries,
) {
  final sorted = entries.toList()
    ..sort((left, right) =>
        _resourceKey(left.resource).compareTo(_resourceKey(right.resource)));
  return List.unmodifiable(sorted);
}

String? _optionalRevision(String? value) {
  if (value != null && !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'revision',
      'must be null or a lowercase SHA-256 fingerprint',
    );
  }
  return value;
}

String _resourceKey(AuthoringResourceRef resource) =>
    '${resource.kind}\u0000${resource.id}';
