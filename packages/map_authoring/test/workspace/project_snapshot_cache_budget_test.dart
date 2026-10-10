import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSnapshotCacheBudget', () {
    const mib = 1024 * 1024;
    const budget = ProjectSnapshotCacheBudget();

    test('admits authoring data through the 256 MiB boundary', () {
      expect(
        budget.classify(
          authoringBytes: 256 * mib,
          assetBlobBytes: 0,
        ),
        ProjectSnapshotCacheAdmission.admitted,
      );
      expect(
        budget.classify(
          authoringBytes: 256 * mib + 1,
          assetBlobBytes: 0,
        ),
        ProjectSnapshotCacheAdmission.authoringBudgetExceeded,
      );
    });

    test('admits the measured native NB2 project without raising blob limits', () {
      final cache = ProjectSnapshotCache();
      expect(
        cache.budget.classify(
          authoringBytes: 71852142,
          assetBlobBytes: 108821639,
        ),
        ProjectSnapshotCacheAdmission.admitted,
      );
      expect(
        cache.budget.classify(
          authoringBytes: 71852142,
          assetBlobBytes: 256 * mib + 1,
        ),
        ProjectSnapshotCacheAdmission.assetBudgetExceeded,
      );
    });

    test('accounts asset blobs independently from authoring data', () {
      expect(
        budget.classify(
          authoringBytes: 4 * mib,
          assetBlobBytes: 65 * mib,
        ),
        ProjectSnapshotCacheAdmission.admitted,
      );
      expect(
        budget.classify(
          authoringBytes: 4 * mib,
          assetBlobBytes: 256 * mib + 1,
        ),
        ProjectSnapshotCacheAdmission.assetBudgetExceeded,
      );
    });

    test('reports rejected snapshots instead of silently dropping them', () {
      final authoringCache = ProjectSnapshotCache(
        maximumBytes: 4,
        maximumAssetBlobBytes: 8,
      );
      final authoringSnapshot = _snapshot(
        projectBytes: const [1, 2, 3, 4, 5],
      );

      expect(
        authoringCache.store(
          snapshot: authoringSnapshot,
          identities: _identities(authoringSnapshot),
        ),
        ProjectSnapshotCacheAdmission.authoringBudgetExceeded,
      );
      expect(authoringCache.authoringBudgetRejections, 1);
      expect(authoringCache.projectCount, 0);

      final assetCache = ProjectSnapshotCache(
        maximumBytes: 8,
        maximumAssetBlobBytes: 8,
      );
      final assetSnapshot = _snapshot(
        projectBytes: const [1, 2],
        assetBytes: List<int>.filled(9, 7),
      );

      expect(
        assetCache.store(
          snapshot: assetSnapshot,
          identities: _identities(assetSnapshot),
        ),
        ProjectSnapshotCacheAdmission.assetBudgetExceeded,
      );
      expect(assetCache.assetBudgetRejections, 1);
      expect(assetCache.projectCount, 0);
    });

    test('removes a previous entry when its replacement exceeds a budget', () {
      final cache = ProjectSnapshotCache(
        maximumBytes: 4,
        maximumAssetBlobBytes: 8,
      );
      final admitted = _snapshot(projectBytes: const [1, 2, 3, 4]);
      final rejected = _snapshot(projectBytes: const [1, 2, 3, 4, 5]);

      expect(
        cache.store(
          snapshot: admitted,
          identities: _identities(admitted),
        ),
        ProjectSnapshotCacheAdmission.admitted,
      );
      expect(cache.projectCount, 1);

      expect(
        cache.store(
          snapshot: rejected,
          identities: _identities(rejected),
        ),
        ProjectSnapshotCacheAdmission.authoringBudgetExceeded,
      );
      expect(cache.projectCount, 0);
      expect(cache.invalidations, 1);
    });

    test('charges aliased binary buffers once to the asset budget', () {
      final snapshot = _modelBufferSnapshot(shared: true);
      final cache = ProjectSnapshotCache(
        maximumBytes: 2,
        maximumAssetBlobBytes: 4,
      );

      expect(
        cache.store(snapshot: snapshot, identities: _identities(snapshot)),
        ProjectSnapshotCacheAdmission.admitted,
      );
      expect(cache.storedAuthoringBytes, 2);
      expect(cache.storedAssetBlobBytes, 4);
      expect(cache.storedBytes, 6);
      expect(snapshot.resourceByteLength, 10);
    });

    test('equal binary payloads in distinct buffers remain separately charged',
        () {
      final snapshot = _modelBufferSnapshot(shared: false);
      final cache = ProjectSnapshotCache(
        maximumBytes: 2,
        maximumAssetBlobBytes: 4,
      );

      expect(
        cache.store(snapshot: snapshot, identities: _identities(snapshot)),
        ProjectSnapshotCacheAdmission.authoringBudgetExceeded,
      );
      expect(cache.projectCount, 0);
      expect(cache.authoringBudgetRejections, 1);
    });
  });
}

ProjectSnapshot _modelBufferSnapshot({required bool shared}) {
  final handles = WorkspaceHandleStore();
  final registered = handles.registerProject(
    projectName: 'Buffer fixture',
    initialFingerprint: 'fixture',
    readBytes: (_) async => const [],
  );
  final access = handles.resolveProject(registered.projectHandle);
  final blob = access.adoptResourceBytes(const [7, 8, 9, 10]);
  final logical =
      shared ? blob : access.adoptResourceBytes(const [7, 8, 9, 10]);
  final snapshot = ProjectSnapshot(
    projectHandle: registered.projectHandle,
    revision: 'sha256:${'a' * 64}',
    manifest:
        const ProjectManifest(name: 'Buffer fixture', maps: [], tilesets: []),
    maps: const [],
    resourceFingerprints: {
      'project': 'sha256:${'b' * 64}',
      'assetLogical:model': 'sha256:${'c' * 64}',
      'assetBlob:fixture': 'sha256:${'d' * 64}',
    },
    ownedResourceBytes: {
      'project': access.adoptResourceBytes(const [1, 2]),
      'assetLogical:model': logical,
      'assetBlob:fixture': blob,
    },
    resourceStorageKeys: const {
      'project': 'project.json',
      'assetLogical:model': 'assets/models3d/model.glb',
      'assetBlob:fixture': 'assets/.pokemap-store/fixture.blob',
    },
  );
  handles.closeWorkspace(registered.workspaceHandle);
  return snapshot;
}

ProjectSnapshot _snapshot({
  required List<int> projectBytes,
  List<int>? assetBytes,
}) {
  final resources = <String, List<int>>{
    'project': projectBytes,
    if (assetBytes != null) 'assetBlob:fixture': assetBytes,
  };
  final storageKeys = <String, String>{
    'project': 'project.json',
    if (assetBytes != null) 'assetBlob:fixture': 'assets/blobs/fixture.bin',
  };
  final entries = storageKeys.entries.toList()
    ..sort((left, right) => left.value.compareTo(right.value));
  String fingerprint(String identity) => computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: storageKeys[identity]!,
          bytes: resources[identity]!,
        ),
      ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('project'),
    revision: computeNarrativeProjectFingerprint([
      for (final entry in entries)
        NarrativeProjectFingerprintEntry(
          relativePath: entry.value,
          bytes: resources[entry.key]!,
        ),
    ]),
    manifest:
        const ProjectManifest(name: 'Cache budget', maps: [], tilesets: []),
    maps: const [],
    resourceFingerprints: {
      for (final identity in resources.keys) identity: fingerprint(identity),
    },
    resourceBytes: resources,
    resourceStorageKeys: storageKeys,
  );
}

Map<String, ProjectResourceIdentity> _identities(ProjectSnapshot snapshot) => {
      for (final entry in snapshot.resourceStorageKeys.entries)
        entry.value: ProjectResourceIdentity(
          scope: '/project',
          relativePath: entry.value,
          byteLength: snapshot.resourceBytes(entry.key).length,
          modifiedAtMicros: 1,
        ),
    };
