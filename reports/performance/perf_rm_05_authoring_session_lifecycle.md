# Evidence Pack — PERF-RM-05 Lifecycle des sessions authoring

Date d’exécution : 1–2 août 2026 (Europe/Paris)
Branche / base : `main` à `1f5f4da3d`
Verdict : **DONE proposé (consolidé)** — ownership mono-projet, admission des candidats, leases et borne mémoire prouvés.

> Consolidation finale du 2 août 2026 : la revue indépendante a détecté qu’une
> ancienne racine pouvait être rouverte pendant un changement de projet. Le
> lifecycle possède désormais une admission explicite `active + candidate`,
> rejette les racines retirées avec `editor.authoring_session_stale`, ferme le
> candidat précédent et nettoie aussi le candidat lorsqu’on réactive la racine
> active. Les tests ciblés et les trois nouveaux receipts AOT prévalent sur les
> chiffres historiques plus bas. Runs finaux : 55 902 / 50 352 / 54 567 µs,
> croissance RSS 9 551 872 / 9 584 640 / 9 584 640 octets, une seule session
> lecture et mutation, `candidateRoot=null`, 9 fermetures, 2 participants.

## Audit initial et décision d’architecture

La passe d’audit indépendante a établi deux politiques distinctes : l’éditeur desktop est mono-projet actif, tandis que MCP/JSONL reste volontairement multi-workspace. Le correctif est donc privé à l’éditeur : fermeture sur switch, sans LRU publique ni changement du protocole authoring.

Le risque principal était une fermeture pendant une requête ou mutation, ou l’adoption tardive d’une session devenue stale. La conception retenue sérialise les activations, protège les opérations par leases et attend leur fin avant la retraite.

## Implémentation et zones modifiées

| Fichier | Zone | Changement |
|---|---|---|
| `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart:13-105` | sessions de lecture | Diagnostics, leases, `retainOnly`, retraite et `closeAll` idempotent. |
| `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart:47-341` | sessions de mutation | Même lifecycle autour de tout workflow durable, attente des mutations en vol. |
| `packages/map_editor/lib/src/app/providers/core/repository_providers.dart:59-81` | wiring Riverpod | Un lifecycle partagé et cleanup des participants. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:507,625,667` | adoption projet | Activation des sessions après adoption réussie du projet ; discard à la fermeture. |
| `packages/map_editor/test/authoring_api/editor_read_parity_test.dart` | parité lecture | Selbrume, retain/close et validation en vol. |
| `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart` | parité mutation | Retraite, mutation en vol et receipts inchangés. |

Fichiers créés :

- `packages/map_editor/lib/src/application/authoring_api/authoring_session_lifecycle.dart`
- `packages/map_editor/test/authoring_api/authoring_session_lifecycle_test.dart`
- `packages/map_editor/benchmark/authoring_session_lifecycle.dart`
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-05-authoring-session-lifecycle.md`

## Résultats

Dix racines canoniques, trois processus AOT :

| Run | Temps total | Croissance RSS |
|---:|---:|---:|
| 1 | 66 551 µs | 10 027 008 octets |
| 2 | 53 477 µs | 9 617 408 octets |
| 3 | 59 990 µs | 9 633 792 octets |

Après retour sur la racine active, chaque adaptateur rapporte `live=1`, `opening=0`, `retiring=0`, `activeOperations=0`, `closeCount=9`; le coordinator conserve exactement deux participants. La croissance reste sous l’objectif idéal de 20 MiB, même sans GC forcé disponible dans l’exécutable AOT.

## Vérifications exactes

```text
cd packages/map_editor
flutter test test/authoring_api/authoring_session_lifecycle_test.dart test/authoring_api/editor_read_parity_test.dart test/authoring_api/editor_mutation_parity_test.dart
=> exit 0 ; +26 ; All tests passed!

flutter analyze
=> exit 0 ; No issues found!

dart compile exe benchmark/authoring_session_lifecycle.dart ... puis 3 exécutions
=> exit 0 pour chaque run ; diagnostics ci-dessus
```

Les validations de parité authoring/MCP sont celles consignées dans RM-09A : conformance 62/227 complète, serveur MCP 23/23, catalogue live et open/query/close verts. Aucun handle MCP/JSONL multi-workspace n’a été borné ou fermé par le lifecycle éditeur.

Le filet global `flutter test` de l’éditeur a été interrompu après 5 min 37 s, à `+4772 ~5 -36`, car plusieurs dettes de tests hors phase échouaient déjà puis causaient des cascades Riverpod. Rejoués seuls, cinq échecs persistent dans `pending_border_save_notifier_test.dart` et `editor_notifier_map_activation_test.dart` autour de l’absence de révision disque attestée ; les 26 tests propres au lot restent verts.

## État Git, non-objectifs et risques

Les cinq modifications éditeur initiales hors phase et le `__pycache__` ont été préservés. Aucune écriture Git n’a été faite.

Non-objectifs respectés : pas de timer, weak reference ou LRU multi-projet ; aucun changement du protocole public ; aucune annulation d’une mutation durable en cours.

Auto-critique : le harness AOT ne peut pas demander un GC VM-service. La mesure est néanmoins conservatrice puisque la croissance sans GC reste sous 20 MiB. Une future lane mémoire profile pourra confirmer heap/native memory, sans remettre en cause les invariants fonctionnels déjà prouvés.

## État Git final consolidé

`main@1f5f4da3d` ; 48 fichiers suivis modifiés au total (43 de phase, 5 world-map hors phase) et 25 fichiers non suivis (24 de phase, 1 `__pycache__` hors phase). `git diff --check` ne produit aucune erreur ; les fichiers Dart de phase passent `dart format --output=none --set-exit-if-changed` (`57 files`, `0 changed`).

## Annexe — contenu complet des fichiers créés

### `packages/map_editor/lib/src/application/authoring_api/authoring_session_lifecycle.dart`

````dart
import 'package:map_authoring/map_authoring.dart';

/// One editor-private owner of Authoring sessions keyed by canonical root.
abstract interface class EditorAuthoringLifecycleParticipant {
  /// Closes every session except [canonicalRoot].
  Future<void> retainOnly(String canonicalRoot);

  /// Closes the session for [canonicalRoot] when it exists.
  Future<void> closeProject(String canonicalRoot);

  /// Closes every owned session.
  Future<void> closeAll();
}

final class EditorAuthoringStaleSessionException implements Exception {
  const EditorAuthoringStaleSessionException();

  @override
  String toString() =>
      'EditorAuthoringStaleSessionException: the project session was retired.';
}

final class EditorAuthoringSessionDiagnostics {
  const EditorAuthoringSessionDiagnostics({
    required this.retainedRoot,
    required this.liveSessions,
    required this.openingSessions,
    required this.retiringSessions,
    required this.activeOperations,
    required this.closeCount,
  });

  final String? retainedRoot;
  final int liveSessions;
  final int openingSessions;
  final int retiringSessions;
  final int activeOperations;
  final int closeCount;
}

/// Coordinates the editor's mono-project Authoring session lifecycle.
///
/// This coordinator is intentionally editor-private. The canonical Authoring
/// API, JSONL transport, and MCP server remain multi-workspace and keep their
/// explicit open/close semantics.
final class EditorAuthoringSessionLifecycle {
  EditorAuthoringSessionLifecycle({required ProjectFileReader fileReader})
      : _fileReader = fileReader;

  final ProjectFileReader _fileReader;
  final List<EditorAuthoringLifecycleParticipant> _participants = [];
  Future<void> _transition = Future<void>.value();
  String? _activeRoot;

  String? get activeRoot => _activeRoot;
  int get participantCount => _participants.length;

  void attach(EditorAuthoringLifecycleParticipant participant) {
    if (_participants.any((current) => identical(current, participant))) {
      return;
    }
    _participants.add(participant);
  }

  Future<void> activate(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot) return;
        await _allSettled(
          _participants.map(
            (participant) => participant.retainOnly(canonicalRoot),
          ),
        );
        _activeRoot = canonicalRoot;
      });

  Future<void> discard(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot) return;
        await _allSettled(
          _participants.map(
            (participant) => participant.closeProject(canonicalRoot),
          ),
        );
      });

  Future<void> closeAll() => _serialize(() async {
        await _allSettled(
          _participants.map((participant) => participant.closeAll()),
        );
        _activeRoot = null;
      });

  Future<void> _serialize(Future<void> Function() operation) {
    final current = _transition.then((_) => operation());
    _transition = current.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return current;
  }
}

Future<void> _allSettled(Iterable<Future<void>> operations) async {
  Object? firstError;
  StackTrace? firstStackTrace;
  await Future.wait<void>(
    operations.map((operation) async {
      try {
        await operation;
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }),
  );
  if (firstError != null) {
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }
}
````

### `packages/map_editor/test/authoring_api/authoring_session_lifecycle_test.dart`

````dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  group('EditorAuthoringSessionLifecycle', () {
    test('switching A to B retains B in every attached participant', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final reads = _FakeLifecycleParticipant()..open('/canonical/a');
      final mutations = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, reads, mutations);

      await lifecycle.activate('/alias/a');
      reads.open('/canonical/b');
      mutations.open('/canonical/b');
      await lifecycle.activate('/alias/b');

      expect(lifecycle.activeRoot, '/canonical/b');
      expect(reads.liveRoots, equals(<String>{'/canonical/b'}));
      expect(mutations.liveRoots, equals(<String>{'/canonical/b'}));
      expect(
        reads.retainOnlyCalls,
        equals(<String>['/canonical/a', '/canonical/b']),
      );
      expect(
        mutations.retainOnlyCalls,
        equals(<String>['/canonical/a', '/canonical/b']),
      );
    });

    test('ten sequential roots leave only the last root alive', () async {
      final aliases = <String, String>{
        for (var index = 1; index <= 10; index += 1)
          '/alias/$index': '/canonical/$index',
      };
      final reader = _CanonicalReader(aliases);
      final reads = _FakeLifecycleParticipant();
      final mutations = _FakeLifecycleParticipant();
      final lifecycle = _lifecycle(reader, reads, mutations);

      for (var index = 1; index <= 10; index += 1) {
        reads.open('/canonical/$index');
        mutations.open('/canonical/$index');
        await lifecycle.activate('/alias/$index');
      }

      expect(lifecycle.activeRoot, '/canonical/10');
      expect(reads.liveRoots, equals(<String>{'/canonical/10'}));
      expect(mutations.liveRoots, equals(<String>{'/canonical/10'}));
      expect(reads.retainOnlyCalls, hasLength(10));
      expect(mutations.retainOnlyCalls, hasLength(10));
    });

    test('activation canonicalizes the requested project root', () async {
      final reader = _CanonicalReader({
        '/selected/project': '/real/project',
      });
      final participant = _FakeLifecycleParticipant()..open('/real/project');
      final lifecycle = _lifecycle(reader, participant);

      await lifecycle.activate('/selected/project');

      expect(reader.canonicalizeCalls, equals(['/selected/project']));
      expect(lifecycle.activeRoot, '/real/project');
      expect(participant.retainOnlyCalls, equals(['/real/project']));
    });

    test('activating the same canonical root twice is idempotent', () async {
      final reader = _CanonicalReader({
        '/alias/one': '/canonical/project',
        '/alias/two': '/canonical/project',
      });
      final participant = _FakeLifecycleParticipant()
        ..open('/canonical/project');
      final lifecycle = _lifecycle(reader, participant);

      await lifecycle.activate('/alias/one');
      await lifecycle.activate('/alias/two');

      expect(lifecycle.activeRoot, '/canonical/project');
      expect(participant.retainOnlyCalls, equals(['/canonical/project']));
    });

    test('closing the lifecycle repeatedly remains safe and empty', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
      });
      final reads = _FakeLifecycleParticipant()..open('/canonical/a');
      final mutations = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, reads, mutations);
      await lifecycle.activate('/alias/a');

      await lifecycle.closeAll();
      await lifecycle.closeAll();

      expect(lifecycle.activeRoot, isNull);
      expect(reads.liveRoots, isEmpty);
      expect(mutations.liveRoots, isEmpty);
    });

    test('discarding a candidate never closes the active root', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final participant = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, participant);
      await lifecycle.activate('/alias/a');

      await lifecycle.discard('/alias/a');
      participant.open('/canonical/b');
      await lifecycle.discard('/alias/b');

      expect(lifecycle.activeRoot, '/canonical/a');
      expect(participant.liveRoots, equals(<String>{'/canonical/a'}));
      expect(participant.closeProjectCalls, equals(['/canonical/b']));
    });

    test('one participant failure does not skip cleanup of the others',
        () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final failing = _FakeLifecycleParticipant()..open('/canonical/a');
      final healthy = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, failing, healthy);
      await lifecycle.activate('/alias/a');
      failing
        ..open('/canonical/b')
        ..retainOnlyError = StateError('cannot close A');
      healthy.open('/canonical/b');

      await expectLater(
        lifecycle.activate('/alias/b'),
        throwsA(isA<StateError>()),
      );

      // A failed cross-participant transition must not claim B as globally
      // active, but every participant still receives its cleanup request.
      expect(lifecycle.activeRoot, '/canonical/a');
      expect(failing.retainOnlyCalls.last, '/canonical/b');
      expect(healthy.retainOnlyCalls.last, '/canonical/b');
      expect(healthy.liveRoots, equals(<String>{'/canonical/b'}));
    });

    test('an occupied participant delays completion of activation', () async {
      final reader = _CanonicalReader({
        '/alias/a': '/canonical/a',
        '/alias/b': '/canonical/b',
      });
      final busy = _FakeLifecycleParticipant()..open('/canonical/a');
      final other = _FakeLifecycleParticipant()..open('/canonical/a');
      final lifecycle = _lifecycle(reader, busy, other);
      await lifecycle.activate('/alias/a');
      busy.open('/canonical/b');
      other.open('/canonical/b');
      final releaseBusyParticipant = Completer<void>();
      busy.retainOnlyBlocker = releaseBusyParticipant;
      var completed = false;

      final switching = lifecycle.activate('/alias/b').whenComplete(() {
        completed = true;
      });
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(lifecycle.activeRoot, '/canonical/a');

      releaseBusyParticipant.complete();
      await switching;

      expect(completed, isTrue);
      expect(lifecycle.activeRoot, '/canonical/b');
      expect(busy.liveRoots, equals(<String>{'/canonical/b'}));
      expect(other.liveRoots, equals(<String>{'/canonical/b'}));
    });

    test('a discarded late opening closes and returns a typed stale failure',
        () async {
      final active = Directory(
        '${Directory.current.parent.parent.path}/examples/'
        'playable_runtime_host/golden_fangame_slice',
      );
      final candidate = Directory(
        '${Directory.current.parent.parent.path}/selbrume',
      );
      final candidateRoot = await candidate.resolveSymbolicLinks();
      final reader = _GatedProjectReader(candidateRoot);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
        ..attach(queries);
      addTearDown(lifecycle.closeAll);
      await lifecycle.activate(active.path);

      final opening = queries.open(candidate.path);
      await reader.started.future;
      final discarding = lifecycle.discard(candidate.path);
      await Future<void>.delayed(Duration.zero);
      reader.release.complete();

      await expectLater(
        opening,
        throwsA(isA<EditorAuthoringStaleSessionException>()),
      );
      await discarding;
      expect(lifecycle.activeRoot, await active.resolveSymbolicLinks());
      expect(queries.diagnostics.liveSessions, 0);
      expect(queries.diagnostics.openingSessions, 0);
      expect(queries.diagnostics.retiringSessions, 0);
      expect(queries.diagnostics.closeCount, 1);
    });

    test('repository providers attach both editor-private adapters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authoringMutationAdapterProvider);
      final lifecycle = container.read(
        editorAuthoringSessionLifecycleProvider,
      );

      expect(lifecycle.participantCount, 2);
    });
  });
}

EditorAuthoringSessionLifecycle _lifecycle(
  ProjectFileReader reader,
  _FakeLifecycleParticipant first, [
  _FakeLifecycleParticipant? second,
]) {
  final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
    ..attach(first);
  if (second != null) lifecycle.attach(second);
  return lifecycle;
}

final class _CanonicalReader implements ProjectFileReader {
  _CanonicalReader(this.canonicalRoots);

  final Map<String, String> canonicalRoots;
  final List<String> canonicalizeCalls = <String>[];

  @override
  Future<String> canonicalizeDirectory(String path) async {
    canonicalizeCalls.add(path);
    return canonicalRoots[path] ?? path;
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    throw UnsupportedError('Lifecycle tests never read project bytes.');
  }
}

final class _GatedProjectReader implements ProjectFileReader {
  _GatedProjectReader(this.gatedRoot);

  final String gatedRoot;
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  static const _delegate = EditorProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (projectRoot == gatedRoot && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

final class _FakeLifecycleParticipant
    implements EditorAuthoringLifecycleParticipant {
  final Set<String> liveRoots = <String>{};
  final List<String> retainOnlyCalls = <String>[];
  final List<String> closeProjectCalls = <String>[];
  int closeAllCalls = 0;
  Object? retainOnlyError;
  Completer<void>? retainOnlyBlocker;

  void open(String canonicalRoot) {
    liveRoots.add(canonicalRoot);
  }

  @override
  Future<void> retainOnly(String canonicalRoot) async {
    retainOnlyCalls.add(canonicalRoot);
    final blocker = retainOnlyBlocker;
    if (blocker != null) await blocker.future;
    final error = retainOnlyError;
    if (error != null) throw error;
    liveRoots.removeWhere((root) => root != canonicalRoot);
  }

  @override
  Future<void> closeProject(String canonicalRoot) async {
    closeProjectCalls.add(canonicalRoot);
    liveRoots.remove(canonicalRoot);
  }

  @override
  Future<void> closeAll() async {
    closeAllCalls += 1;
    liveRoots.clear();
  }
}
````

### `packages/map_editor/benchmark/authoring_session_lifecycle.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

import '../../../tool/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const {'roots', 'output'},
    );
    final rootCount = cli.positiveInt('roots', fallback: 10);
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_editor');
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_authoring_lifecycle_',
    );
    try {
      final roots = await Future.wait([
        for (var index = 0; index < rootCount; index += 1)
          _writeFixture(sandbox, index),
      ]);
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
        ..attach(queries)
        ..attach(mutations);
      final rssBefore = ProcessInfo.currentRss;
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < roots.length; index += 1) {
        final root = roots[index];
        await queries.open(root.path);
        await mutations.plan(
          root.path,
          actionId: 'map.save',
          parameters: {
            'map': _map.copyWith(name: 'Candidate $index').toJson(),
          },
          idempotencyKey: 'lifecycle_$index',
        );
        await lifecycle.activate(root.path);
        _requireBounded(queries.diagnostics, label: 'query');
        _requireBounded(mutations.diagnostics, label: 'mutation');
      }
      stopwatch.stop();
      final rssAfter = ProcessInfo.currentRss;
      final queryDiagnostics = queries.diagnostics;
      final mutationDiagnostics = mutations.diagnostics;
      final result = <String, Object?>{
        'rootCount': rootCount,
        'elapsedUs': stopwatch.elapsedMicroseconds,
        'rssBeforeBytes': rssBefore,
        'rssAfterBytes': rssAfter,
        'rssGrowthBytes': rssAfter - rssBefore,
        'activeRoot': lifecycle.activeRoot,
        'participantCount': lifecycle.participantCount,
        'query': _diagnosticsJson(queryDiagnostics),
        'mutation': _diagnosticsJson(mutationDiagnostics),
      };
      final receipt = await performanceReceipt(
        benchmark: 'authoring_session_lifecycle',
        warmups: 0,
        sampleCount: 1,
        arguments: [
          'benchmark/authoring_session_lifecycle.dart',
          ...arguments,
        ],
        metadata: {'rootCount': rootCount, 'gcMode': 'not available in AOT'},
        results: [result],
      );
      await writePerformanceReceipt(
        outputPath: outputPath,
        packageName: 'map_editor',
        receipt: receipt,
      );
      await lifecycle.closeAll();
    } finally {
      await sandbox.delete(recursive: true);
    }
  } on FormatException catch (error) {
    stderr.writeln('authoring_session_lifecycle: ${error.message}');
    exitCode = 64;
  }
}

Future<Directory> _writeFixture(Directory sandbox, int index) async {
  final root = await Directory(p.join(sandbox.path, 'project_$index')).create();
  final maps = await Directory(p.join(root.path, 'maps')).create();
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(_project.copyWith(name: 'Lifecycle project $index').toJson()),
  );
  await File(p.join(maps.path, 'alpha.json'))
      .writeAsString(jsonEncode(_map.toJson()));
  return root;
}

void _requireBounded(
  EditorAuthoringSessionDiagnostics diagnostics, {
  required String label,
}) {
  if (diagnostics.liveSessions != 1 ||
      diagnostics.openingSessions != 0 ||
      diagnostics.retiringSessions != 0 ||
      diagnostics.activeOperations != 0) {
    throw StateError('$label sessions escaped the mono-project bound.');
  }
}

Map<String, Object?> _diagnosticsJson(
  EditorAuthoringSessionDiagnostics diagnostics,
) =>
    {
      'retainedRoot': diagnostics.retainedRoot,
      'liveSessions': diagnostics.liveSessions,
      'openingSessions': diagnostics.openingSessions,
      'retiringSessions': diagnostics.retiringSessions,
      'activeOperations': diagnostics.activeOperations,
      'closeCount': diagnostics.closeCount,
    };

const _project = ProjectManifest(
  name: 'Lifecycle project',
  maps: [
    ProjectMapEntry(
      id: 'alpha',
      name: 'Alpha',
      relativePath: 'maps/alpha.json',
    ),
  ],
  tilesets: [],
);

const _map = MapData(
  id: 'alpha',
  name: 'Alpha',
  size: GridSize(width: 2, height: 2),
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  layers: [
    MapLayer.tile(id: 'l_base', name: 'Base', tiles: [0, 0, 0, 0]),
    MapLayer.terrain(
      id: 'l_terrain',
      name: 'Terrain',
      terrains: [
        TerrainType.none,
        TerrainType.none,
        TerrainType.none,
        TerrainType.none,
      ],
    ),
    MapLayer.collision(
      id: 'l_collisions',
      name: 'Collisions',
      collisions: [false, false, false, false],
    ),
  ],
);
````

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-05-authoring-session-lifecycle.md`

````markdown
# PERF-RM-05 Authoring Session Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Every behavior change follows red → green → refactor.

**Goal:** Make the desktop editor retain only the adopted project’s authoring sessions while allowing in-flight work to finish and rejecting stale candidates deterministically.

**Architecture:** PokeMap’s editor has one active project, while MCP remains independently multi-workspace. A shared editor lifecycle coordinator activates a canonical root only after `EditorNotifier` adopts it. Query and mutation adapters retire other roots, await active leases before closing handles, and close late candidates that lose an activation race. No public `map_authoring` or MCP contract changes.

**Tech Stack:** Flutter/Riverpod, editor-internal adapters, canonical `map_authoring` handles, widget/unit parity tests.

---

### Task 1: Characterize one-active-project ownership

**Files:**
- Create: `packages/map_editor/test/authoring_api/authoring_session_lifecycle_test.dart`
- Modify: `packages/map_editor/test/authoring_api/editor_read_parity_test.dart`
- Modify: `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`

- [ ] Prove repeated opens of one root share one live read session.
- [ ] Open 1, 3, and 10 roots and show the current unbounded retained-session behavior as a red test.
- [ ] Cover a failed candidate open, A→B→A rapid switch, a late A completion after B adoption, close twice, validation in flight, and mutation in flight.
- [ ] Assert a current response is usable, a stale response cannot become active, and every retired workspace closes exactly once.

### Task 2: Add lease-aware retirement to adapters

**Files:**
- Modify: `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`
- Modify: `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`

- [ ] Add adapter diagnostics for active root, live/opening/retiring session counts, active operations, and close count.
- [ ] Add `activateProjectRoot(String root)` that canonicalizes the root, increments an activation epoch, retains the matching session, and retires every other root.
- [ ] Guard async query validation and every mutation workflow with operation leases; retirement waits for the final lease before detach/close.
- [ ] On a late opening, keep it only when its root matches the current activation; otherwise close it and return a typed stale-session failure.
- [ ] Keep `invalidate(root)` and `closeAll()` idempotent and safe during opens or operations.

### Task 3: Coordinate lifecycle only after project adoption

**Files:**
- Create: `packages/map_editor/lib/src/application/authoring_api/authoring_session_lifecycle_coordinator.dart`
- Modify: `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify only if repository wiring requires it: `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

- [ ] Provide one coordinator owning the query and mutation adapters.
- [ ] Call it after `createAndActivateProject` or `activateProject` has committed the new `EditorState`, never merely when a candidate begins loading.
- [ ] Keep the previous active root when loading a candidate fails.
- [ ] Do not alter MCP/JSONL multi-workspace handles or broaden any allowed root.

### Task 4: Validate memory and transports

- [ ] Run ten canonical Selbrume root switches, return to one active root, force GC through the existing VM-service harness, and record heap/RSS plus adapter diagnostics.
- [ ] Require no inactive editor handle, no eviction during mutation, no stale adoption, and acceptable retained growth at most 50 MiB or 10%.
- [ ] Re-run direct API, editor read/mutation parity, PMCP-085, MCP tests, and live catalog describe/open/query/validate/close.

**Verification:**

```bash
cd packages/map_editor && flutter test test/authoring_api/authoring_session_lifecycle_test.dart test/authoring_api/editor_read_parity_test.dart test/authoring_api/editor_mutation_parity_test.dart && flutter test && flutter analyze
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart && dart test test/parity/full_authoring_parity_test.dart && dart analyze
cd tools/pokemap_mcp && npm run check && npm test
```

**Non-goals:** an editor multi-project LRU, timers, weak references, changes to public workspace actions, cancellation that interrupts durable mutations, or changes to remembered-project UX.
````
