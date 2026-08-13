import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSnapshotCacheBudget', () {
    const mib = 1024 * 1024;
    const budget = ProjectSnapshotCacheBudget();

    test('admits authoring data through the 64 MiB boundary', () {
      expect(
        budget.classify(
          authoringBytes: 64 * mib,
          assetBlobBytes: 0,
        ),
        ProjectSnapshotCacheAdmission.admitted,
      );
      expect(
        budget.classify(
          authoringBytes: 64 * mib + 1,
          assetBlobBytes: 0,
        ),
        ProjectSnapshotCacheAdmission.authoringBudgetExceeded,
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
  });
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
