# Evidence Pack — PERF-RM-09A Snapshot authoring

Date d’exécution : 1–2 août 2026 (Europe/Paris)
Branche / base : `main` à `1f5f4da3d`
Verdict : **DONE proposé (consolidé)** — cohérence inchangée, latence et réduction RSS strictes prouvées sur le vrai Selbrume.

> Consolidation finale du 2 août 2026 : concurrence de seconde observation
> bornée à 8, comparaison byte-exacte sans second conteneur possédé et décodage
> des ressources ≥1 Mio hors isolate appelant. Les trois runs AOT finaux donnent
> des p50 de 369 086 / 374 674 / 372 845 µs et des p95 de
> 373 549 / 386 457 / 376 809 µs. Contre une baseline `git archive HEAD`
> adaptée uniquement au chemin de la même fixture canonique, le pic RSS externe
> moyen passe de 342 125 227 à 197 099 520 octets, soit −42,39 %. Dataset
> `2ab648cc9fa4f5b8` et checksum `82e410fe61aba903` sont identiques. Cette
> section et le rapport consolidé prévalent sur les mesures historiques ci-dessous.

## Audit initial et objectif

La passe d’audit indépendante a confirmé que le vrai projet `selbrume/` contient 10 cartes, 35 ressources observées et 4 753 256 octets. Le chargeur relisait séquentiellement les ressources et multipliait les copies de bytes autour du snapshot et du fingerprint. Le contrat à préserver était strict : deux observations, ordre stable, bytes possédés et immuables, fingerprint identique, refus d’une mutation ou disparition entre les observations.

Critères roadmap : moyenne Selbrume `<400 ms`, p95 `≤1 s`, réduction du pic RSS `≥30 %`, résultat bit-identique et concurrence incohérente rejetée.

## Implémentation et zones modifiées

| Fichier | Zone | Changement |
|---|---|---|
| `packages/map_authoring/lib/src/ports/project_file_reader.dart` | contrat de lecture | Retour compact en `Uint8List`, sans recopie générique. |
| `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart:54` | `ProjectResourceBytes` | Ownership explicite et vue immuable des bytes. |
| `packages/map_authoring/lib/src/workspace/project_snapshot.dart` | construction/validation | Suppression des copies redondantes tout en conservant l’immuabilité exposée. |
| `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart:53-262` | pipeline de snapshot | Première lecture profilée, seconde observation concurrente via `Future.wait`, fingerprint streaming et contrôles d’ordre/disparition/mutation. |
| `packages/map_authoring/benchmark/authoring_snapshot_open.dart` | fixture/profil | Vrai Selbrume, phases détaillées, fingerprint de dataset et receipts reproductibles. |
| `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart` | CLI | Contrat des nouvelles phases et fixture réelle. |
| `packages/map_authoring/test/workspace/project_open_service_test.dart` | ouverture | Compatibilité du nouveau conteneur de bytes. |
| `packages/map_authoring/test/workspace/project_snapshot_test.dart` | snapshot | Ownership, immuabilité et ordre. |

Fichiers créés :

- `packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart`
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-09a-authoring-snapshot.md`

## Résultats before / after

Trois processus AOT, même fixture et mêmes paramètres :

| Mesure Selbrume | Before | After |
|---|---:|---:|
| p50 ouverture | 627 285 / 624 626 / 622 140 µs | 436 030 / 439 202 / 436 713 µs |
| p95 ouverture | 726 658 / 677 532 / 649 595 µs | 440 286 / 444 013 / 441 733 µs |
| RSS au receipt | ~295–298 Mo | ~200,8–208,2 Mo |
| Pic RSS externe | ~329–371 Mo | ~329–336 Mo |

Le p95 passe largement le budget acceptable de 1 s. Le RSS de fin baisse d’environ 30 %, mais le pic externe ne prouve pas une baisse de 30 %. Le p50 reste autour de 437 ms, au-dessus de l’objectif strict de 400 ms. Le checksum reste `82e410fe61aba903` et le fingerprint fixture `2ab648cc9fa4f5b8`.

## Vérifications exactes

```text
cd packages/map_authoring
dart test test/workspace/project_snapshot_test.dart test/workspace/project_snapshot_concurrency_test.dart test/parity/full_authoring_parity_test.dart
=> exit 0 ; +18 ; All tests passed!

dart test
=> exit 0 ; +312 ; All tests passed! ; ~25 s

dart analyze
=> exit 0 ; No issues found!

dart run tool/pmcp085_conformance.dart
=> exit 0 ; 62 resources ; 227 actions ; blocked=0 ; missing=0 ; catalogComplete=true

cd packages/map_core
dart test test/narrative_project_fingerprint_test.dart && dart analyze
=> exit 0 ; +5 ; All tests passed! ; No issues found!
```

Parité transports : API directe, JSONL/CLI, éditeur et MCP ont été rejoués. `tools/pokemap_mcp` passe 23 tests. Le catalogue live expose 62 ressources et 227 actions. Open/query/close sur `/selbrume` passent ; `validate` répond correctement mais `valid:false` à cause de trois diagnostics de données déjà présents, dont `step:p6.selbrume.first_interaction is missing`.

## État Git, non-objectifs et risques

État initial : cinq fichiers éditeur suivis et un `__pycache__` non suivi, tous hors phase ; aucun n’a été repris par ce lot. Aucun `git add`, commit, push, reset, stash ou changement de branche n’a été exécuté.

Non-objectifs respectés : aucune suppression de la seconde observation, aucune modification de format ou de frontière workspace, aucune migration lazy de `resourceBytes`.

Auto-critique : la cohérence est mieux couverte que la clôture performance. Une prochaine itération doit profiler la projection/modélisation restante et mesurer le pic avec un outil mémoire unique et calibré ; elle ne doit pas réduire les garanties de double observation pour gagner les ~37 ms restants.

## État Git final consolidé

`main@1f5f4da3d` ; 48 fichiers suivis modifiés au total (43 de phase, 5 world-map hors phase) et 25 fichiers non suivis (24 de phase, 1 `__pycache__` hors phase). `git diff --check` ne produit aucune erreur ; les fichiers Dart de phase passent `dart format --output=none --set-exit-if-changed` (`57 files`, `0 changed`).

## Annexe — contenu complet des fichiers créés

### `packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart`

````dart
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
  });
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
    _CanonicalSnapshotFixture fixture,
  ) async {
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
      loader: ProjectSnapshotLoader(handles: handles),
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
        'version': 'v1',
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
        'version': 'v1',
        'layers': <Object?>[],
      }),
    );
````

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-09a-authoring-snapshot.md`

````markdown
# PERF-RM-09A Authoring Snapshot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Every production change follows red → green → refactor.

**Goal:** Reduce authoring snapshot latency and transient memory without changing snapshot bytes, fingerprints, diagnostics, ordering, CAS authority, handle lifetime, or workspace security.

**Architecture:** First repair the benchmark so `selbrume` means the canonical root fixture. Then profile the existing two-observation loader, replace copy-producing fingerprint wrappers with the existing streaming builder, and remove redundant byte copies only at internal ownership boundaries. `ProjectSnapshot.resourceBytes` stays eager and exact in Phase A.

**Tech Stack:** Dart 3.12, `map_core`, `map_authoring`, AOT benchmark receipts, PMCP parity tests.

---

### Task 1: Lock the canonical Selbrume benchmark fixture

**Files:**
- Modify: `packages/map_authoring/benchmark/authoring_snapshot_open.dart`
- Modify: `packages/map_authoring/test/benchmark/authoring_snapshot_open_cli_test.dart`

- [ ] Add a CLI regression that runs only `selbrume` and asserts `fixturePath == "selbrume"`, `mapCount == 10`, `resourceCount == 35`, and `resourceBytes == 4753256`.
- [ ] Run `dart test test/benchmark/authoring_snapshot_open_cli_test.dart` and retain the expected red result proving the slice is selected today.
- [ ] Point `_resolveFixture('selbrume')` to the repository-root `selbrume/` directory and make the first allowed root the canonical fixture itself.
- [ ] Populate `resourceCount` and `resourceBytes` from the production `ProjectSnapshot`, not from a parallel filesystem scan.
- [ ] Re-run the CLI regression green and capture three isolated AOT receipts before changing the loader.

### Task 2: Add concurrency and byte-identity characterization

**Files:**
- Create: `packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart`
- Modify: `packages/map_authoring/test/workspace/project_snapshot_test.dart`
- Modify: `packages/map_core/test/narrative_project_fingerprint_test.dart`

- [ ] Add a reader that mutates one map between first and second observation and assert `project.changed_during_snapshot`.
- [ ] Add disappearance, expired-handle, missing-required-resource, editor-projection diagnostic, and exact read-count cases.
- [ ] Compare aggregate and per-resource fingerprints to `computeNarrativeProjectFingerprint` and compare every `resourceBytes(identity)` byte-for-byte.
- [ ] Run the new file and confirm it passes against the pre-optimization implementation.

### Task 3: Instrument production stages without changing the snapshot contract

**Files:**
- Modify: `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- Modify: `packages/map_authoring/benchmark/authoring_snapshot_open.dart`
- Modify: `packages/map_authoring/test/workspace/project_snapshot_test.dart`

- [ ] Add immutable stage metrics for initial reads, decode/model construction, second observation, fingerprinting, projection, total resources, and total resource bytes.
- [ ] Inject an optional metrics sink into `ProjectSnapshotLoader`; the default path must remain allocation-light and behaviorally identical.
- [ ] Emit stage percentiles in the benchmark receipt and test their schema and non-negative accounting.
- [ ] Run targeted tests before moving to optimization.

### Task 4: Stream fingerprints and remove redundant internal copies

**Files:**
- Modify: `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- Modify only when characterization proves necessary: `packages/map_authoring/lib/src/workspace/project_open_service.dart`
- Modify only when ownership remains exact: `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`
- Modify only when the eager API can stay immutable: `packages/map_authoring/lib/src/workspace/project_snapshot.dart`
- Modify only for a synchronous no-copy helper: `packages/map_core/lib/src/operations/narrative_project_fingerprint.dart`

- [ ] Build aggregate and individual fingerprints directly with `NarrativeProjectFingerprintBuilder`; never materialize `NarrativeProjectFingerprintEntry` copies inside the loader.
- [ ] Preserve sorted normalized paths and the canonical `path + length + bytes` framing.
- [ ] Keep exactly two loader observations and all existing rejection diagnostics.
- [ ] Keep one immutable eager pre-image per returned resource; do not introduce lazy `resourceBytes` or a schema/API migration.
- [ ] Re-run fingerprint, snapshot, concurrency, open-service, path-security, stale-plan, and full authoring parity tests.

### Task 5: Calibrate and decide the lot

- [ ] Compile the benchmark once, then run canonical Selbrume alone in three fresh AOT processes before and after.
- [ ] Compare fixture fingerprint, snapshot checksum, stage p50/p95, and externally sampled peak RSS on the same runner.
- [ ] Require mean below 400 ms, p95 at most 1 s, bit-identical fingerprints/bytes, and at least 30% peak-RSS reduction to propose `DONE`.
- [ ] Otherwise report `PARTIAL` with the measured limiting stage; do not weaken coherence or workspace roots.

**Verification:**

```bash
cd packages/map_core && dart test test/narrative_project_fingerprint_test.dart && dart test && dart analyze
cd packages/map_authoring && dart test test/workspace/project_snapshot_test.dart test/workspace/project_snapshot_concurrency_test.dart test/workspace/project_open_service_test.dart test/workspace/workspace_path_security_test.dart test/transactions/stale_plan_test.dart test/benchmark/authoring_snapshot_open_cli_test.dart
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart && dart test test/parity/full_authoring_parity_test.dart && dart test && dart analyze
cd tools/pokemap_mcp && npm run check && npm test
```

**Non-goals:** lazy snapshot bytes, schema changes, removal of the second observation, broader workspace roots, editor state refactors, or codec offload from `RM-09B`.
````
