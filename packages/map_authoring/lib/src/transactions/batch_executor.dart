import '../contracts/authoring_diff.dart';
import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';
import 'change_set.dart';

final class AuthoringBatchException implements Exception {
  const AuthoringBatchException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringBatchException($code): $message';
}

/// Pure deterministic composition for independently planned mutations.
final class AuthoringBatchExecutor {
  const AuthoringBatchExecutor();

  AuthoringChangeSet combine(Iterable<AuthoringChangeSet> changeSets) {
    final inputs = changeSets.toList(growable: false);
    if (inputs.isEmpty) {
      throw const AuthoringBatchException(
        'batch.empty',
        'A mutation batch must contain at least one change set.',
      );
    }

    final changesByResource = <String, AuthoringResourceChange>{};
    final changesByStorageKey = <String, AuthoringResourceChange>{};
    final diffSignatureByResource = <String, String>{};
    final diffByIdentity = <String, AuthoringDiffEntry>{};
    for (final input in inputs) {
      final currentDiffByResource = <String, List<AuthoringDiffEntry>>{};
      for (final entry in input.diff.entries) {
        currentDiffByResource
            .putIfAbsent(_resourceKey(entry.resource), () => [])
            .add(entry);
      }
      for (final change in input.changes) {
        final resourceKey = _resourceKey(change.resource);
        final resourceOverlap = changesByResource[resourceKey];
        final storageOverlap = changesByStorageKey[change.storageKey];
        final diffSignature = canonicalAuthoringJson([
          for (final entry in currentDiffByResource[resourceKey]!)
            entry.toJson(),
        ]);
        if ((resourceOverlap != null &&
                !_sameChange(resourceOverlap, change)) ||
            (storageOverlap != null && !_sameChange(storageOverlap, change)) ||
            (diffSignatureByResource[resourceKey] != null &&
                diffSignatureByResource[resourceKey] != diffSignature)) {
          throw const AuthoringBatchException(
            'batch.overlap_conflict',
            'A batch contains incompatible overlapping resource changes.',
          );
        }
        changesByResource[resourceKey] = change;
        changesByStorageKey[change.storageKey] = change;
        diffSignatureByResource[resourceKey] = diffSignature;
      }
      for (final entry in input.diff.entries) {
        final identity = canonicalAuthoringJson(entry.toJson());
        diffByIdentity[identity] = entry;
      }
    }

    return AuthoringChangeSet(
      changes: changesByResource.values,
      diff: AuthoringDiff(diffByIdentity.values),
    );
  }
}

String _resourceKey(AuthoringResourceRef resource) =>
    '${resource.kind}\u0000${resource.id}';

bool _sameChange(
  AuthoringResourceChange left,
  AuthoringResourceChange right,
) {
  return _resourceKey(left.resource) == _resourceKey(right.resource) &&
      canonicalAuthoringJson(left.resource.toJson()) ==
          canonicalAuthoringJson(right.resource.toJson()) &&
      left.storageKey == right.storageKey &&
      left.beforeRevision == right.beforeRevision &&
      left.afterRevision == right.afterRevision &&
      _sameBytes(left.beforeBytes, right.beforeBytes) &&
      _sameBytes(left.afterBytes, right.afterBytes);
}

bool _sameBytes(List<int>? left, List<int>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
