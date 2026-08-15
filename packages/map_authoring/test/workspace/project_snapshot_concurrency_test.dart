import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSnapshotLoader concurrent observations', () {
    test(
      'rejects a map changed between its first and second observation',
      () async {
        final fixture = _CanonicalSnapshotFixture.create();
        final harness = await _SnapshotHarness.open(fixture);
        harness.reader.onRead = (relativePath, observation, canonicalBytes) {
          if (relativePath == 'maps/zeta.json' && observation == 2) {
            // The second payload remains valid map JSON. This proves rejection
            // comes from coherence checking rather than from decode failure.
            return _mapBytes('zeta', name: 'Zeta changed concurrently');
          }
          return canonicalBytes;
        };

        await expectLater(
          () => harness.loader.load(harness.opened.projectHandle),
          throwsA(
            isA<ProjectSnapshotException>().having(
              (error) => error.code,
              'code',
              'project.changed_during_snapshot',
            ),
          ),
        );

        expect(harness.reader.readCount('maps/zeta.json'), 2);
      },
    );

    test('fails closed when a map disappears before its second observation',
        () async {
      final fixture = _CanonicalSnapshotFixture.create();
      final harness = await _SnapshotHarness.open(fixture);
      harness.reader.onRead = (relativePath, observation, canonicalBytes) {
        if (relativePath == 'maps/zeta.json' && observation == 2) {
          throw const WorkspaceAccessException(
            'workspace.file_unavailable',
            'The requested project resource is unavailable.',
          );
        }
        return canonicalBytes;
      };

      await expectLater(
        () => harness.loader.load(harness.opened.projectHandle),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.file_unavailable',
          ),
        ),
      );

      expect(harness.reader.readCount('maps/zeta.json'), 2);
    });

    test(
      'preserves canonical bytes, fingerprints, order, and two reads',
      () async {
        final fixture = _CanonicalSnapshotFixture.create();
        final harness = await _SnapshotHarness.open(fixture);

        final snapshot =
            await harness.loader.load(harness.opened.projectHandle);

        final canonicalResources = fixture.resourcesByIdentity.entries
            .map(
              (entry) => NarrativeProjectFingerprintEntry(
                relativePath: entry.value.relativePath,
                bytes: entry.value.bytes,
              ),
            )
            .toList(growable: false);
        expect(
          snapshot.revision,
          computeNarrativeProjectFingerprint(canonicalResources),
        );
        for (final entry in fixture.resourcesByIdentity.entries) {
          final identity = entry.key;
          final resource = entry.value;
          expect(
            snapshot.resourceFingerprints[identity],
            computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                relativePath: resource.relativePath,
                bytes: resource.bytes,
              ),
            ]),
            reason: 'fingerprint for $identity must use its canonical bytes',
          );
          expect(
            snapshot.resourceBytes(identity),
            resource.bytes,
            reason: 'pre-image for $identity must be byte-identical',
          );
          expect(
            snapshot.resourceStorageKeys[identity],
            resource.relativePath,
          );
        }

        // Manifest order is deliberately zeta then alpha. Public projections
        // remain deterministic independently of that authoring order.
        expect(snapshot.maps.map((map) => map.id), ['alpha', 'zeta']);
        expect(
          snapshot.resourceFingerprints.keys,
          [
            assetCatalogResourceIdentity,
            dialogueSourceResourceIdentity('intro'),
            'map:alpha',
            'map:zeta',
            'project',
          ],
        );
        expect(
          snapshot.resourceStorageKeys.keys,
          snapshot.resourceFingerprints.keys,
        );

        // The successful loader contract is exactly two observations of each
        // returned resource. Opening the handle happened before counters were
        // reset, so its independent manifest read is intentionally excluded.
        expect(harness.reader.readLog, hasLength(10));
        for (final resource in fixture.resourcesByIdentity.values) {
          expect(
            harness.reader.readCount(resource.relativePath),
            2,
            reason: '${resource.relativePath} must be observed exactly twice',
          );
        }
      },
    );

    test('performs the second observation concurrently', () async {
      final fixture = _CanonicalSnapshotFixture.create();
      final harness = await _SnapshotHarness.open(fixture);
      var activeSecondReads = 0;
      var maximumConcurrentSecondReads = 0;
      harness.reader.onRead = (
        relativePath,
        observation,
        canonicalBytes,
      ) async {
        if (observation == 2) {
          activeSecondReads++;
          if (activeSecondReads > maximumConcurrentSecondReads) {
            maximumConcurrentSecondReads = activeSecondReads;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
          activeSecondReads--;
        }
        return canonicalBytes;
      };

      await harness.loader.load(harness.opened.projectHandle);

      expect(maximumConcurrentSecondReads, greaterThan(1));
    });

    test('bounds second-observation concurrency for large catalogs', () async {
      final fixture = _CanonicalSnapshotFixture.withMapCount(20);
      final harness = await _SnapshotHarness.open(
        fixture,
        maxConcurrentSecondObservations: 4,
      );
      var activeSecondReads = 0;
      var maximumConcurrentSecondReads = 0;
      harness.reader.onRead = (
        relativePath,
        observation,
        canonicalBytes,
      ) async {
        if (observation == 2) {
          activeSecondReads++;
          if (activeSecondReads > maximumConcurrentSecondReads) {
            maximumConcurrentSecondReads = activeSecondReads;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
          activeSecondReads--;
        }
        return canonicalBytes;
      };

      await harness.loader.load(harness.opened.projectHandle);

      expect(maximumConcurrentSecondReads, greaterThan(1));
      expect(maximumConcurrentSecondReads, lessThanOrEqualTo(4));
    });

    test('offloads large structured resource decoding through the executor',
        () async {
      final worker = _CountingDecodeWorker();
      final harness = await _SnapshotHarness.open(
        _CanonicalSnapshotFixture.create(),
        decodeExecutor: ProjectSnapshotDecodeExecutor(
          offloadThresholdBytes: 0,
          workerRunner: worker.run,
        ),
      );

      final snapshot = await harness.loader.load(harness.opened.projectHandle);

      expect(snapshot.maps, hasLength(2));
      expect(worker.calls, 4);
    });
  });
}

final class _CountingDecodeWorker {
  var calls = 0;

  Future<T> run<T>(T Function() operation) async {
    calls++;
    return operation();
  }
}

typedef _ReadInterceptor = FutureOr<List<int>> Function(
  String relativePath,
  int observation,
  List<int> canonicalBytes,
);

final class _SnapshotHarness {
  const _SnapshotHarness({
    required this.reader,
    required this.loader,
    required this.opened,
  });

  static Future<_SnapshotHarness> open(
    _CanonicalSnapshotFixture fixture, {
    int maxConcurrentSecondObservations = 8,
    ProjectSnapshotDecodeExecutor? decodeExecutor,
  }) async {
    final reader = _MemoryProjectFileReader(
      allowedRoot: fixture.allowedRoot,
      projectRoot: fixture.projectRoot,
      resources: fixture.resourcesByPath,
    );
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.allowedRoot],
      fileReader: reader,
    );
    var token = 0;
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 8, 2, 12),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final openService = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await openService.openProject(fixture.projectRoot);

    // Snapshot read counts must not accidentally include ProjectOpenService's
    // own manifest validation read.
    reader.resetObservations();
    return _SnapshotHarness(
      reader: reader,
      loader: ProjectSnapshotLoader(
        handles: handles,
        maxConcurrentSecondObservations: maxConcurrentSecondObservations,
        decodeExecutor: decodeExecutor,
      ),
      opened: opened,
    );
  }

  final _MemoryProjectFileReader reader;
  final ProjectSnapshotLoader loader;
  final OpenedProject opened;
}

/// Complete in-memory implementation of the filesystem port used by the real
/// workspace policy, open service, handle store, and snapshot loader.
///
/// The fake only controls what each disk observation returns; assertions stay
/// focused on the production snapshot contract rather than fake interactions.
final class _MemoryProjectFileReader implements ProjectFileReader {
  _MemoryProjectFileReader({
    required this.allowedRoot,
    required this.projectRoot,
    required Map<String, List<int>> resources,
  }) : _resources = {
          for (final entry in resources.entries)
            entry.key: List<int>.unmodifiable(entry.value),
        };

  final String allowedRoot;
  final String projectRoot;
  final Map<String, List<int>> _resources;
  final List<String> readLog = [];
  final Map<String, int> _readCounts = {};
  _ReadInterceptor? onRead;

  @override
  Future<String> canonicalizeDirectory(String path) async {
    if (path == allowedRoot || path == projectRoot) return path;
    throw const WorkspaceAccessException(
      'workspace.directory_unavailable',
      'The requested workspace root is unavailable.',
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (projectRoot != this.projectRoot) {
      throw const WorkspaceAccessException(
        'workspace.path_outside_project',
        'The requested project resource resolves outside the project.',
      );
    }
    final bytes = _resources[relativePath];
    if (bytes == null) {
      throw const WorkspaceAccessException(
        'workspace.file_unavailable',
        'The requested project resource is unavailable.',
      );
    }
    final observation = (_readCounts[relativePath] ?? 0) + 1;
    _readCounts[relativePath] = observation;
    readLog.add(relativePath);
    final observed =
        await (onRead?.call(relativePath, observation, bytes) ?? bytes);
    return List<int>.unmodifiable(observed);
  }

  int readCount(String relativePath) => _readCounts[relativePath] ?? 0;

  void resetObservations() {
    readLog.clear();
    _readCounts.clear();
  }
}

final class _CanonicalSnapshotFixture {
  const _CanonicalSnapshotFixture({
    required this.allowedRoot,
    required this.projectRoot,
    required this.resourcesByIdentity,
  });

  factory _CanonicalSnapshotFixture.create() {
    final allowedRoot = '${Platform.pathSeparator}workspace';
    final manifestBytes = utf8.encode(
      jsonEncode({
        'name': 'Snapshot Concurrency Characterization',
        'version': 'v6',
        'pokemon': ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ).toJson(),
        'maps': [
          _mapEntry('zeta', 'maps/zeta.json'),
          _mapEntry('alpha', 'maps/alpha.json'),
        ],
        'tilesets': <Object?>[],
        'dialogues': const [
          {
            'id': 'intro',
            'name': 'Intro',
            'relativePath': 'dialogues/intro.yarn',
          },
        ],
      }),
    );
    return _CanonicalSnapshotFixture(
      allowedRoot: allowedRoot,
      projectRoot: '$allowedRoot${Platform.pathSeparator}project',
      resourcesByIdentity: {
        'project': _CanonicalResource('project.json', manifestBytes),
        'map:zeta': _CanonicalResource(
          'maps/zeta.json',
          _mapBytes('zeta'),
        ),
        'map:alpha': _CanonicalResource(
          'maps/alpha.json',
          _mapBytes('alpha'),
        ),
        dialogueSourceResourceIdentity('intro'): _CanonicalResource(
          'dialogues/intro.yarn',
          utf8.encode('title: Start\n---\nBonjour\n===\n'),
        ),
        assetCatalogResourceIdentity: _CanonicalResource(
          assetCatalogStorageKey,
          utf8.encode(jsonEncode({'schemaVersion': 1, 'records': []})),
        ),
      },
    );
  }

  factory _CanonicalSnapshotFixture.withMapCount(int mapCount) {
    final allowedRoot = '${Platform.pathSeparator}workspace';
    final mapEntries = <Map<String, Object?>>[];
    final resources = <String, _CanonicalResource>{};
    for (var index = 0; index < mapCount; index++) {
      final id = 'map_$index';
      final relativePath = 'maps/$id.json';
      mapEntries.add(_mapEntry(id, relativePath));
      resources['map:$id'] = _CanonicalResource(
        relativePath,
        _mapBytes(id),
      );
    }
    final manifestBytes = utf8.encode(
      jsonEncode({
        'name': 'Bounded Snapshot Concurrency',
        'version': 'v6',
        'pokemon': ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ).toJson(),
        'maps': mapEntries,
        'tilesets': <Object?>[],
      }),
    );
    return _CanonicalSnapshotFixture(
      allowedRoot: allowedRoot,
      projectRoot: '$allowedRoot${Platform.pathSeparator}project',
      resourcesByIdentity: <String, _CanonicalResource>{
        'project': _CanonicalResource('project.json', manifestBytes),
        ...resources,
        assetCatalogResourceIdentity: _CanonicalResource(
          assetCatalogStorageKey,
          utf8.encode(jsonEncode({'schemaVersion': 1, 'records': []})),
        ),
      },
    );
  }

  final String allowedRoot;
  final String projectRoot;
  final Map<String, _CanonicalResource> resourcesByIdentity;

  Map<String, List<int>> get resourcesByPath => {
        for (final resource in resourcesByIdentity.values)
          resource.relativePath: resource.bytes,
      };
}

final class _CanonicalResource {
  const _CanonicalResource(this.relativePath, this.bytes);

  final String relativePath;
  final List<int> bytes;
}

Map<String, Object?> _mapEntry(String id, String relativePath) => {
      'id': id,
      'name': id,
      'relativePath': relativePath,
      'role': 'exterior',
      'sortOrder': 0,
    };

List<int> _mapBytes(String id, {String? name}) => utf8.encode(
      jsonEncode({
        'id': id,
        'name': name ?? id,
        'size': {'width': 2, 'height': 2},
        'version': 'v6',
        'layers': <Object?>[],
      }),
    );
