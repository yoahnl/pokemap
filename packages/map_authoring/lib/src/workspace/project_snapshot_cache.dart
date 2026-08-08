import '../ports/project_file_reader.dart';
import '../transactions/change_set.dart';
import 'project_snapshot.dart';
import 'project_snapshot_map_projector.dart';
import 'workspace_handle_store.dart';

/// Bounded cache of complete, immutable project snapshots.
///
/// Reuse is allowed only through an identity reader that explicitly guarantees
/// generation semantics. Every expected resource and every known-absent
/// optional resource is observed twice before cached bytes are returned.
final class ProjectSnapshotCache {
  ProjectSnapshotCache({
    this.maximumProjects = 2,
    this.maximumBytes = 64 << 20,
  }) {
    if (maximumProjects <= 0) {
      throw ArgumentError.value(
        maximumProjects,
        'maximumProjects',
        'must be positive',
      );
    }
    if (maximumBytes <= 0) {
      throw ArgumentError.value(
        maximumBytes,
        'maximumBytes',
        'must be positive',
      );
    }
  }

  final int maximumProjects;
  final int maximumBytes;
  final Map<String, _ProjectSnapshotCacheEntry> _entries = {};
  var _storedBytes = 0;

  int hits = 0;
  int misses = 0;

  int get projectCount => _entries.length;
  int get storedBytes => _storedBytes;

  Future<ProjectSnapshot?> lookup(
    ProjectWorkspaceAccess access,
    ProjectHandle projectHandle,
  ) async {
    if (!access.canReuseSnapshots) {
      misses += 1;
      return null;
    }
    final manifestIdentity = await access.readResourceIdentity('project.json');
    if (manifestIdentity == null) {
      misses += 1;
      return null;
    }
    final entry = _entries[manifestIdentity.scope];
    if (entry == null ||
        entry.identities['project.json'] != manifestIdentity ||
        !await _matches(access, entry) ||
        !await _matches(access, entry)) {
      misses += 1;
      if (entry != null) invalidateScope(manifestIdentity.scope);
      return null;
    }
    _entries
      ..remove(manifestIdentity.scope)
      ..[manifestIdentity.scope] = entry;
    hits += 1;
    return entry.snapshot.rebind(projectHandle);
  }

  void store({
    required ProjectSnapshot snapshot,
    required Map<String, ProjectResourceIdentity> identities,
    Iterable<String> absentResourcePaths = const [],
  }) {
    if (snapshot.loadDiagnostics.isNotEmpty || identities.isEmpty) return;
    final expectedPaths = snapshot.resourceStorageKeys.values.toSet();
    if (identities.keys.toSet().length != expectedPaths.length ||
        !identities.keys.toSet().containsAll(expectedPaths) ||
        !expectedPaths.containsAll(identities.keys)) {
      return;
    }
    final scopes = identities.values.map((identity) => identity.scope).toSet();
    if (scopes.length != 1 || !identities.containsKey('project.json')) return;
    final byteLength = snapshot.resourceByteLength;
    if (byteLength > maximumBytes) return;
    final scope = scopes.single;
    invalidateScope(scope);
    final entry = _ProjectSnapshotCacheEntry(
      snapshot: snapshot,
      identities: Map.unmodifiable(Map.of(identities)),
      absentResourcePaths: Set.unmodifiable(absentResourcePaths.toSet()),
      byteLength: byteLength,
    );
    _entries[scope] = entry;
    _storedBytes += byteLength;
    while (_entries.length > maximumProjects || _storedBytes > maximumBytes) {
      invalidateScope(_entries.keys.first);
    }
  }

  Future<ProjectSnapshot?> adoptAppliedChanges(
    ProjectWorkspaceAccess access,
    ProjectHandle projectHandle, {
    required String baseRevision,
    required Iterable<AuthoringResourceChange> changes,
  }) async {
    if (!access.canReuseSnapshots) return null;
    final manifestIdentity = await access.readResourceIdentity('project.json');
    if (manifestIdentity == null) return null;
    final entry = _entries[manifestIdentity.scope];
    if (entry == null || entry.snapshot.revision != baseRevision) return null;
    final frozenChanges = changes.toList(growable: false);
    final projected = const ProjectSnapshotMapProjector().project(
      entry.snapshot.rebind(projectHandle),
      frozenChanges,
    );
    if (projected == null) return null;

    final identities = Map<String, ProjectResourceIdentity>.of(
      entry.identities,
    );
    for (final change in frozenChanges) {
      final afterBytes = change.afterBytes;
      if (afterBytes == null) {
        invalidateScope(manifestIdentity.scope);
        return null;
      }
      try {
        final identityBefore =
            await access.readResourceIdentity(change.storageKey);
        if (identityBefore == null ||
            identityBefore.scope != manifestIdentity.scope) {
          invalidateScope(manifestIdentity.scope);
          return null;
        }
        final matchesCommittedBytes = await access.matchesResourceBytes(
          change.storageKey,
          afterBytes,
        );
        final identityAfter =
            await access.readResourceIdentity(change.storageKey);
        if (!matchesCommittedBytes || identityAfter != identityBefore) {
          invalidateScope(manifestIdentity.scope);
          return null;
        }
        identities[change.storageKey] = identityAfter!;
      } on Exception {
        invalidateScope(manifestIdentity.scope);
        return null;
      }
    }
    final candidate = _ProjectSnapshotCacheEntry(
      snapshot: projected,
      identities: Map.unmodifiable(identities),
      absentResourcePaths: entry.absentResourcePaths,
      byteLength: projected.resourceByteLength,
    );
    if (!await _matches(access, candidate) ||
        !await _matches(access, candidate)) {
      invalidateScope(manifestIdentity.scope);
      return null;
    }
    store(
      snapshot: projected,
      identities: identities,
      absentResourcePaths: candidate.absentResourcePaths,
    );
    return projected;
  }

  void invalidateScope(String scope) {
    final removed = _entries.remove(scope);
    if (removed != null) _storedBytes -= removed.byteLength;
  }

  void clear() {
    _entries.clear();
    _storedBytes = 0;
  }

  Future<bool> _matches(
    ProjectWorkspaceAccess access,
    _ProjectSnapshotCacheEntry entry,
  ) async {
    for (final expected in entry.identities.entries) {
      final observed = await access.readResourceIdentity(expected.key);
      if (observed != expected.value) return false;
    }
    for (final relativePath in entry.absentResourcePaths) {
      if (await access.readResourceIdentity(relativePath) != null) return false;
    }
    return true;
  }
}

final class _ProjectSnapshotCacheEntry {
  const _ProjectSnapshotCacheEntry({
    required this.snapshot,
    required this.identities,
    required this.absentResourcePaths,
    required this.byteLength,
  });

  final ProjectSnapshot snapshot;
  final Map<String, ProjectResourceIdentity> identities;
  final Set<String> absentResourcePaths;
  final int byteLength;
}
