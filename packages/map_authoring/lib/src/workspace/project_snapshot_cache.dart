import '../ports/project_file_reader.dart';
import '../transactions/change_set.dart';
import 'project_snapshot.dart';
import 'project_snapshot_map_projector.dart';
import 'workspace_handle_store.dart';

enum ProjectSnapshotCacheValidation { canonical, session }

enum ProjectSnapshotCacheAdmission {
  admitted,
  incompleteSnapshot,
  authoringBudgetExceeded,
  assetBudgetExceeded,
}

final class ProjectSnapshotCacheBudget {
  const ProjectSnapshotCacheBudget({
    this.maximumAuthoringBytes = 64 << 20,
    this.maximumAssetBlobBytes = 256 << 20,
  });

  final int maximumAuthoringBytes;
  final int maximumAssetBlobBytes;

  ProjectSnapshotCacheAdmission classify({
    required int authoringBytes,
    required int assetBlobBytes,
  }) {
    if (authoringBytes > maximumAuthoringBytes) {
      return ProjectSnapshotCacheAdmission.authoringBudgetExceeded;
    }
    if (assetBlobBytes > maximumAssetBlobBytes) {
      return ProjectSnapshotCacheAdmission.assetBudgetExceeded;
    }
    return ProjectSnapshotCacheAdmission.admitted;
  }
}

/// Bounded cache of complete, immutable project snapshots.
final class ProjectSnapshotCache {
  ProjectSnapshotCache({
    this.maximumProjects = 2,
    this.maximumBytes = 64 << 20,
    this.maximumAssetBlobBytes = 256 << 20,
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
    if (maximumAssetBlobBytes <= 0) {
      throw ArgumentError.value(
        maximumAssetBlobBytes,
        'maximumAssetBlobBytes',
        'must be positive',
      );
    }
  }

  final int maximumProjects;
  final int maximumBytes;
  final int maximumAssetBlobBytes;
  final Map<String, _ProjectSnapshotCacheEntry> _entries = {};
  final Map<ProjectHandle, String> _scopesByHandle = {};
  final Map<String, int> _nextSessionRevisions = {};
  var _storedAuthoringBytes = 0;
  var _storedAssetBlobBytes = 0;

  int hits = 0;
  int misses = 0;
  int canonicalHits = 0;
  int sessionHits = 0;
  int identityReads = 0;
  int invalidations = 0;
  int servedBytes = 0;

  /// Mutations projected onto the cached snapshot without reloading it.
  int adoptions = 0;

  /// Mutations that could not be projected and forced a reload instead.
  int adoptionRejections = 0;
  int authoringBudgetRejections = 0;
  int assetBudgetRejections = 0;

  int get projectCount => _entries.length;
  int get storedBytes => _storedAuthoringBytes + _storedAssetBlobBytes;
  int get storedAuthoringBytes => _storedAuthoringBytes;
  int get storedAssetBlobBytes => _storedAssetBlobBytes;

  ProjectSnapshotCacheBudget get budget => ProjectSnapshotCacheBudget(
        maximumAuthoringBytes: maximumBytes,
        maximumAssetBlobBytes: maximumAssetBlobBytes,
      );

  int? sessionRevisionFor(ProjectHandle projectHandle) =>
      _entryForHandle(projectHandle)?.sessionRevision;

  Future<ProjectSnapshot?> lookup(
    ProjectWorkspaceAccess access,
    ProjectHandle projectHandle, {
    ProjectSnapshotCacheValidation validation =
        ProjectSnapshotCacheValidation.canonical,
  }) async {
    if (validation == ProjectSnapshotCacheValidation.session) {
      final entry = _entryForHandle(projectHandle);
      if (entry == null) {
        misses += 1;
        return null;
      }
      hits += 1;
      sessionHits += 1;
      servedBytes += entry.byteLength;
      return entry.snapshot.rebind(projectHandle);
    }
    if (!access.canReuseSnapshots) {
      misses += 1;
      return null;
    }
    final manifestIdentity = await _readIdentity(access, 'project.json');
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
    canonicalHits += 1;
    servedBytes += entry.byteLength;
    _scopesByHandle[projectHandle] = manifestIdentity.scope;
    return entry.snapshot.rebind(projectHandle);
  }

  ProjectSnapshotCacheAdmission store({
    required ProjectSnapshot snapshot,
    required Map<String, ProjectResourceIdentity> identities,
    Iterable<String> absentResourcePaths = const [],
  }) {
    if (snapshot.loadDiagnostics.isNotEmpty || identities.isEmpty) {
      return ProjectSnapshotCacheAdmission.incompleteSnapshot;
    }
    final expectedPaths = snapshot.resourceStorageKeys.values.toSet();
    if (identities.keys.toSet().length != expectedPaths.length ||
        !identities.keys.toSet().containsAll(expectedPaths) ||
        !expectedPaths.containsAll(identities.keys)) {
      return ProjectSnapshotCacheAdmission.incompleteSnapshot;
    }
    final scopes = identities.values.map((identity) => identity.scope).toSet();
    if (scopes.length != 1 || !identities.containsKey('project.json')) {
      return ProjectSnapshotCacheAdmission.incompleteSnapshot;
    }
    final scope = scopes.single;
    var authoringBytes = 0;
    var assetBlobBytes = 0;
    for (final identity in snapshot.resourceStorageKeys.keys) {
      final length = snapshot.resourceBytes(identity).length;
      if (identity.startsWith('assetBlob:')) {
        assetBlobBytes += length;
      } else {
        authoringBytes += length;
      }
    }
    final admission = budget.classify(
      authoringBytes: authoringBytes,
      assetBlobBytes: assetBlobBytes,
    );
    if (admission == ProjectSnapshotCacheAdmission.authoringBudgetExceeded) {
      authoringBudgetRejections += 1;
      invalidateScope(scope);
      return admission;
    }
    if (admission == ProjectSnapshotCacheAdmission.assetBudgetExceeded) {
      assetBudgetRejections += 1;
      invalidateScope(scope);
      return admission;
    }
    _removeScope(scope, countInvalidation: false);
    final sessionRevision = (_nextSessionRevisions[scope] ?? 0) + 1;
    _nextSessionRevisions[scope] = sessionRevision;
    final entry = _ProjectSnapshotCacheEntry(
      snapshot: snapshot,
      identities: Map.unmodifiable(Map.of(identities)),
      absentResourcePaths: Set.unmodifiable(absentResourcePaths.toSet()),
      authoringBytes: authoringBytes,
      assetBlobBytes: assetBlobBytes,
      sessionRevision: sessionRevision,
    );
    _entries[scope] = entry;
    _scopesByHandle[snapshot.projectHandle] = scope;
    _storedAuthoringBytes += authoringBytes;
    _storedAssetBlobBytes += assetBlobBytes;
    while (_entries.length > maximumProjects ||
        _storedAuthoringBytes > maximumBytes ||
        _storedAssetBlobBytes > maximumAssetBlobBytes) {
      invalidateScope(_entries.keys.first);
    }
    return ProjectSnapshotCacheAdmission.admitted;
  }

  Future<ProjectSnapshot?> adoptAppliedChanges(
    ProjectWorkspaceAccess access,
    ProjectHandle projectHandle, {
    required String baseRevision,
    required Iterable<AuthoringResourceChange> changes,
  }) async {
    if (!access.canReuseSnapshots) return _rejectAdoption();
    final entry = _entryForHandle(projectHandle);
    if (entry == null || entry.snapshot.revision != baseRevision) return _rejectAdoption();
    final scope = entry.identities['project.json']!.scope;
    final frozenChanges = changes.toList(growable: false);
    final projected = const ProjectSnapshotMapProjector().project(
      entry.snapshot.rebind(projectHandle),
      frozenChanges,
    );
    if (projected == null) return _rejectAdoption();

    final identities = Map<String, ProjectResourceIdentity>.of(
      entry.identities,
    );
    for (final change in frozenChanges) {
      final afterBytes = change.afterBytes;
      if (afterBytes == null) {
        invalidateScope(scope);
        return _rejectAdoption();
      }
      try {
        final identityBefore = await _readIdentity(access, change.storageKey);
        if (identityBefore == null || identityBefore.scope != scope) {
          invalidateScope(scope);
          return _rejectAdoption();
        }
        final matchesCommittedBytes = await access.matchesResourceBytes(
          change.storageKey,
          afterBytes,
        );
        final identityAfter = await _readIdentity(access, change.storageKey);
        if (!matchesCommittedBytes || identityAfter != identityBefore) {
          invalidateScope(scope);
          return _rejectAdoption();
        }
        identities[change.storageKey] = identityAfter!;
      } on Exception {
        invalidateScope(scope);
        return _rejectAdoption();
      }
    }
    var authoringBytes = 0;
    var assetBlobBytes = 0;
    for (final identity in projected.resourceStorageKeys.keys) {
      final length = projected.resourceBytes(identity).length;
      if (identity.startsWith('assetBlob:')) {
        assetBlobBytes += length;
      } else {
        authoringBytes += length;
      }
    }
    final candidate = _ProjectSnapshotCacheEntry(
      snapshot: projected,
      identities: Map.unmodifiable(identities),
      absentResourcePaths: entry.absentResourcePaths,
      authoringBytes: authoringBytes,
      assetBlobBytes: assetBlobBytes,
      sessionRevision: entry.sessionRevision,
    );
    if (!await _matches(access, candidate) ||
        !await _matches(access, candidate)) {
      invalidateScope(scope);
      return _rejectAdoption();
    }
    final admission = store(
      snapshot: projected,
      identities: identities,
      absentResourcePaths: candidate.absentResourcePaths,
    );
    if (admission != ProjectSnapshotCacheAdmission.admitted) {
      return _rejectAdoption();
    }
    adoptions += 1;
    return projected;
  }

  Null _rejectAdoption() {
    adoptionRejections += 1;
    return null;
  }

  void invalidateScope(String scope) {
    _removeScope(scope, countInvalidation: true);
  }

  void _removeScope(String scope, {required bool countInvalidation}) {
    final removed = _entries.remove(scope);
    if (removed == null) return;
    _storedAuthoringBytes -= removed.authoringBytes;
    _storedAssetBlobBytes -= removed.assetBlobBytes;
    _scopesByHandle.removeWhere((_, entryScope) => entryScope == scope);
    if (countInvalidation) invalidations += 1;
  }

  void clear() {
    invalidations += _entries.length;
    _entries.clear();
    _scopesByHandle.clear();
    _nextSessionRevisions.clear();
    _storedAuthoringBytes = 0;
    _storedAssetBlobBytes = 0;
  }

  Future<bool> _matches(
    ProjectWorkspaceAccess access,
    _ProjectSnapshotCacheEntry entry,
  ) async {
    for (final expected in entry.identities.entries) {
      final observed = await _readIdentity(access, expected.key);
      if (observed != expected.value) return false;
    }
    for (final relativePath in entry.absentResourcePaths) {
      if (await _readIdentity(access, relativePath) != null) return false;
    }
    return true;
  }

  Future<ProjectResourceIdentity?> _readIdentity(
    ProjectWorkspaceAccess access,
    String relativePath,
  ) {
    identityReads += 1;
    return access.readResourceIdentity(relativePath);
  }

  _ProjectSnapshotCacheEntry? _entryForHandle(ProjectHandle projectHandle) {
    final scope = _scopesByHandle[projectHandle];
    return scope == null ? null : _entries[scope];
  }
}

final class _ProjectSnapshotCacheEntry {
  const _ProjectSnapshotCacheEntry({
    required this.snapshot,
    required this.identities,
    required this.absentResourcePaths,
    required this.authoringBytes,
    required this.assetBlobBytes,
    required this.sessionRevision,
  });

  final ProjectSnapshot snapshot;
  final Map<String, ProjectResourceIdentity> identities;
  final Set<String> absentResourcePaths;
  final int authoringBytes;
  final int assetBlobBytes;
  final int sessionRevision;

  int get byteLength => authoringBytes + assetBlobBytes;
}
