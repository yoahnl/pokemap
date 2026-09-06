import '../contracts/authoring_diff.dart';
import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';

/// Frozen before/after payloads for one opaque resource mutation.
///
/// [storageKey] is an internal project-relative capability used by the future
/// transaction gateway. It is deliberately omitted from public JSON so a
/// resource reference never becomes a filesystem API.
final class AuthoringResourceChange {
  AuthoringResourceChange({
    required this.resource,
    required String storageKey,
    required Iterable<int>? beforeBytes,
    required Iterable<int>? afterBytes,
    String? beforeRevision,
    String? afterRevision,
  })  : storageKey = _safeStorageKey(storageKey),
        beforeBytes = _freezeOptionalBytes(beforeBytes, 'beforeBytes'),
        afterBytes = _freezeOptionalBytes(afterBytes, 'afterBytes') {
    if (this.beforeBytes == null && this.afterBytes == null) {
      throw ArgumentError.value(
        null,
        'beforeBytes/afterBytes',
        'at least one resource image must exist',
      );
    }
    if (this.beforeBytes != null &&
        this.afterBytes != null &&
        _bytesEqual(this.beforeBytes!, this.afterBytes!)) {
      throw ArgumentError.value(
        afterBytes,
        'afterBytes',
        'must differ from beforeBytes',
      );
    }
    final computedBefore = this.beforeBytes == null
        ? null
        : computeAuthoringBytesFingerprint(
            this.beforeBytes!,
            logicalName: this.storageKey,
          );
    final computedAfter = this.afterBytes == null
        ? null
        : computeAuthoringBytesFingerprint(
            this.afterBytes!,
            logicalName: this.storageKey,
          );
    this.beforeRevision = _verifiedOptionalRevision(
      beforeRevision,
      computedBefore,
      'beforeRevision',
    );
    this.afterRevision = _verifiedOptionalRevision(
      afterRevision,
      computedAfter,
      'afterRevision',
    );
    if (resource.revision != null && resource.revision != this.beforeRevision) {
      throw ArgumentError.value(
        resource.revision,
        'resource.revision',
        'must match the frozen before revision',
      );
    }
  }

  final AuthoringResourceRef resource;
  final String storageKey;
  final List<int>? beforeBytes;
  final List<int>? afterBytes;
  late final String? beforeRevision;
  late final String? afterRevision;

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeByteLength': beforeBytes?.length,
        'afterByteLength': afterBytes?.length,
      };
}

/// Deterministically ordered resource payloads plus their structured diff.
final class AuthoringChangeSet {
  AuthoringChangeSet.noChanges()
      : changes = const [],
        diff = AuthoringDiff(const []) {
    affectedResources = const [];
    projectedRevision = computeAuthoringJsonFingerprint(
      const [],
      logicalName: 'projected-change-set.json',
    );
  }

  AuthoringChangeSet({
    required Iterable<AuthoringResourceChange> changes,
    required this.diff,
  }) : changes = _sortedChanges(changes) {
    if (this.changes.isEmpty) {
      throw ArgumentError.value(changes, 'changes', 'must not be empty');
    }
    final resources = <String>{};
    final storageKeys = <String>{};
    for (final change in this.changes) {
      if (!resources.add(_resourceKey(change.resource))) {
        throw ArgumentError.value(
          change.resource.toJson(),
          'changes',
          'resource changes must be unique',
        );
      }
      if (!storageKeys.add(change.storageKey)) {
        throw ArgumentError.value(
          change.storageKey,
          'changes',
          'storage keys must be unique',
        );
      }
    }
    final diffResources = {
      for (final resource in diff.affectedResources) _resourceKey(resource),
    };
    if (!_setsEqual(resources, diffResources)) {
      throw ArgumentError.value(
        diff.toJson(),
        'diff',
        'must describe every changed resource and no others',
      );
    }
    affectedResources = List.unmodifiable([
      for (final change in this.changes) change.resource,
    ]);
    // This revision covers the post-images of touched resources. It is a
    // deterministic preview identity, not a claim of multi-file atomicity.
    projectedRevision = computeAuthoringJsonFingerprint(
      [
        for (final change in this.changes)
          {
            'resource': change.resource.toJson(),
            'afterRevision': change.afterRevision,
          },
      ],
      logicalName: 'projected-change-set.json',
    );
  }

  final List<AuthoringResourceChange> changes;
  final AuthoringDiff diff;
  late final List<AuthoringResourceRef> affectedResources;
  late final String projectedRevision;

  Map<String, Object?> toJson() => {
        'changes': [for (final change in changes) change.toJson()],
        'diff': diff.toJson(),
        'projectedRevision': projectedRevision,
      };
}

List<AuthoringResourceChange> _sortedChanges(
  Iterable<AuthoringResourceChange> changes,
) {
  final sorted = changes.toList()
    ..sort((left, right) {
      final resourceOrder =
          _resourceKey(left.resource).compareTo(_resourceKey(right.resource));
      return resourceOrder != 0
          ? resourceOrder
          : left.storageKey.compareTo(right.storageKey);
    });
  return List.unmodifiable(sorted);
}

String _safeStorageKey(String value) {
  final normalized = value.trim();
  final segments = normalized.split('/');
  if (normalized.isEmpty ||
      normalized != value ||
      normalized.startsWith('/') ||
      normalized.startsWith('./') ||
      RegExp(r'^[a-zA-Z]:/').hasMatch(normalized) ||
      normalized.contains('://') ||
      normalized.contains(r'\') ||
      normalized.contains('\u0000') ||
      segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..') ||
      segments.first == '.pokemap') {
    throw ArgumentError.value(
      value,
      'storageKey',
      'must be a safe project-relative resource key',
    );
  }
  return normalized;
}

List<int>? _freezeOptionalBytes(Iterable<int>? values, String field) {
  if (values == null) return null;
  final bytes = values.toList(growable: false);
  if (bytes.any((value) => value < 0 || value > 255)) {
    throw ArgumentError.value(values, field, 'must contain bytes');
  }
  return List.unmodifiable(bytes);
}

String? _verifiedOptionalRevision(
  String? supplied,
  String? computed,
  String field,
) {
  if (computed == null && supplied != null) {
    throw ArgumentError.value(
      supplied,
      field,
      'must be null when the resource image is absent',
    );
  }
  if (supplied != null && supplied != computed) {
    throw ArgumentError.value(
      supplied,
      field,
      'does not match the frozen resource bytes',
    );
  }
  return computed;
}

String _resourceKey(AuthoringResourceRef resource) =>
    '${resource.kind}\u0000${resource.id}';

bool _setsEqual(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
