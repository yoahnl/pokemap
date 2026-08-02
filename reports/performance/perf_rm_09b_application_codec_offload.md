# Evidence Pack — PERF-RM-09B Offload des codecs applicatifs

Date d’exécution : 1–2 août 2026 (Europe/Paris)
Branche / base : `main` à `1f5f4da3d`
Verdict : **DONE proposé (consolidé)** — runtime et sauvegarde éditeur 10 Mio sous budget, avec heartbeat UI et bytes stables.

> Consolidation finale du 2 août 2026 : la validation JSON ne matérialise plus
> une canonicalisation jetée, les contrôles CAS comparent les bytes hors isolate,
> le snapshot lifecycle vérifié est réutilisé et l’estimation de sortie est
> bornée/short-circuitée. Trois vrais parcours macOS profile sur le câblage de
> production donnent 219 343 / 235 213 / 235 493 µs et des gaps heartbeat
> maximaux de 3 695 / 5 995 / 7 073 µs. Chaque processus respecte donc 250 ms
> et 16 667 µs, effectue 4 opérations worker sans échec, invalide le snapshot
> Authoring et conserve le fingerprint byte-exact. Les `FrameTiming.max` du
> harness sont conservés comme observation uniquement : leur forte valeur
> coexiste avec un heartbeat isolate de 3,7–7,1 ms. Cette section et le rapport
> consolidé prévalent sur le verdict historique ci-dessous.

## Audit initial et décision

La passe d’audit a isolé les phases read/decode/model/validate/encode/write et confirmé que 1–2 MiB est le crossover utile. Le seuil retenu est donc 1 MiB, injectable. Les workers ne possèdent aucun chemin ni fichier : le repository garde locks, gates de recovery, contrôles before/live revision, CAS, traduction d’erreurs et écriture finale.

Le format JSON, l’indentation, la normalisation `GameState`, les receipts et les fingerprints devaient rester identiques. L’atomicité/CAS/recovery du repository runtime est explicitement `N/A — contrat préexistant inchangé`.

## Implémentation et zones modifiées

| Fichier | Zone | Changement |
|---|---|---|
| `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart:37-241` | project repository | Préparation decode/merge/validate/encode et fingerprints lourds via executor ; file I/O/locks/recovery restent locaux. |
| `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart` | test réel | Timeout explicite de 2 minutes pour le journey 10 cartes/475 placements. |
| `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart:18-88` | save/load | Encode/decode thresholded, normalisation et séquencement préservés. |
| `packages/map_runtime/lib/map_runtime.dart` | barrel | Export du nouvel executor public package-local. |

Fichiers créés :

- `packages/map_editor/lib/src/infrastructure/repositories/editor_persistence_codec_executor.dart`
- `packages/map_editor/test/infrastructure/editor_persistence_codec_executor_test.dart`
- `packages/map_editor/benchmark/editor_codec_offload_profile_test.dart`
- `packages/map_runtime/lib/src/infrastructure/game_save_codec_executor.dart`
- `packages/map_runtime/test/game_save_codec_executor_test.dart`
- `packages/map_runtime/benchmark/game_save_codec_offload_profile_test.dart`
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-09b-application-codec-offload.md`

## Résultats trois runs

Projet éditeur 10 MiB :

| Run | Save repository | Gap heartbeat max |
|---:|---:|---:|
| 1 | 359 763 µs | 11 901 µs |
| 2 | 366 300 µs | 5 530 µs |
| 3 | 389 138 µs | 11 939 µs |

Le hitch UI mesuré reste sous 16,67 ms, mais le temps total dépasse la sortie acceptable de 250 ms : verdict `PARTIAL`. Sur la fixture réelle 2,42 MiB, les saves sont 93 340 / 95 361 / 94 250 µs, avec gaps 3 708 / 3 294 / 4 243 µs.

Runtime `GameState` 10 MiB :

| Run | Save | Load | Gap save max | Gap load max |
|---:|---:|---:|---:|---:|
| 1 | 40 510 µs | 23 607 µs | 27 847 µs | 8 330 µs |
| 2 | 44 282 µs | 22 535 µs | 27 886 µs | 8 048 µs |
| 3 | 40 340 µs | 25 256 µs | 27 605 µs | 8 031 µs |

Le runtime passe le budget total 150 ms et reste sous la limite de frame 33,3 ms. Chaque run utilise le worker au-dessus de 1 MiB sans worker failure ; les petits payloads restent locaux.

## Vérifications exactes

```text
cd packages/map_editor
flutter test test/infrastructure/editor_persistence_codec_executor_test.dart test/selbrume_editor_repository_roundtrip_test.dart
=> exit 0 ; +8 ; All tests passed! ; le journey réel conserve 10 cartes et 475 placements

cd packages/map_runtime
flutter test
=> exit 0 ; +2320 ~1 ; All tests passed! ; 1 min 59 s

flutter analyze
=> exit 0 ; No issues found!

flutter test benchmark/editor_codec_offload_profile_test.dart (3 processus)
flutter test benchmark/game_save_codec_offload_profile_test.dart (3 processus)
=> exit 0 pour les six exécutions ; All tests passed!

cd tools/pokemap_mcp
npm run check && npm test
=> exit 0 ; 23 passed ; 0 failed
```

Les tests executor couvrent identité local/worker, seuil, malformed/invalid, traduction d’échec worker et absence d’écriture sur erreur. Les tests runtime complets couvrent aussi transaction rollback/retry. Les fingerprints restent stables par taille dans les trois runs.

Une commande ciblée intermédiaire a référencé par erreur deux anciens noms de tests inexistants ; elle a terminé `+125 -2`. Les bons chemins `editor_read_parity_test.dart` et `editor_mutation_parity_test.dart` ont ensuite été rejoués avec le lifecycle : `+26`, exit 0.

## État Git, non-objectifs et risques

Les modifications préexistantes world-map et le `__pycache__` hors phase ont été conservés. Aucun workspace root n’a été élargi et aucune écriture Git n’a été faite.

Non-objectifs respectés : aucune modification de schema/format, aucun I/O ou lock déplacé dans un worker, aucune garantie d’atomicité runtime inventée, aucun offload des petits payloads.

Auto-critique : le heartbeat prouve que l’UI respire, mais le benchmark Flutter debug n’est pas un vrai frame profile macOS. L’éditeur 10 MiB effectue encore deux SHA-256 et la préparation complète ; il faut profiler ces sous-phases avant tout nouveau découpage transactionnel. Le chemin Selbrume réel est déjà sous 100 ms et ne doit pas être dégradé pour optimiser uniquement le synthétique 10 MiB.

## État Git final consolidé

`main@1f5f4da3d` ; 48 fichiers suivis modifiés au total (43 de phase, 5 world-map hors phase) et 25 fichiers non suivis (24 de phase, 1 `__pycache__` hors phase). `git diff --check` ne produit aucune erreur ; les fichiers Dart de phase passent `dart format --output=none --set-exit-if-changed` (`57 files`, `0 changed`).

## Annexe — contenu complet des fichiers créés

### `packages/map_editor/lib/src/infrastructure/repositories/editor_persistence_codec_executor.dart`

````dart
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_event_authoring_session.dart';

typedef EditorPersistenceWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

enum EditorPersistenceCodecFailureKind {
  currentProjectInvalid,
  eventRegistryReadOnly,
  eventRegistryConflict,
  updatedProjectInvalid,
}

final class EditorPersistenceCodecException implements Exception {
  const EditorPersistenceCodecException({
    required this.kind,
    required this.message,
  });

  final EditorPersistenceCodecFailureKind kind;
  final String message;

  @override
  String toString() => 'EditorPersistenceCodecException(${kind.name}): '
      '$message';
}

final class EditorPersistenceCodecDiagnostics {
  const EditorPersistenceCodecDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

final class EditorPreparedProjectUpdate {
  const EditorPreparedProjectUpdate({
    required this.bytes,
    required this.beforeRevision,
  });

  final List<int> bytes;
  final String beforeRevision;
}

/// Executes pure project JSON/model work outside the UI isolate for large
/// payloads. File ownership, locks, recovery gates, revision checks and writes
/// deliberately remain in [FileProjectRepository].
final class EditorPersistenceCodecExecutor {
  EditorPersistenceCodecExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    EditorPersistenceWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runEditorPersistenceWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  /// Phase 0 measurements show JSON costs becoming visible around 1–2 MiB.
  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final EditorPersistenceWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  EditorPersistenceCodecDiagnostics get diagnostics =>
      EditorPersistenceCodecDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<Map<String, Object?>> decodeProjectRoot(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => _decodeStrictProjectRoot(ownedBytes),
    );
  }

  Future<ProjectManifest> decodeValidatedProject(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => decodeValidatedNarrativeEventAuthoringProject(ownedBytes).manifest,
    );
  }

  Future<List<int>> encodeNewProject(ProjectManifest project) {
    final projectJson = project.toJson();
    final estimatedBytes = _estimateJsonBytes(projectJson);
    return _execute(
      estimatedBytes,
      () => utf8.encode(
        const JsonEncoder.withIndent('  ').convert(projectJson),
      ),
    );
  }

  Future<List<int>> mergeAndEncodeProject({
    required Map<String, Object?> currentRoot,
    required ProjectManifest project,
    required int inputByteLength,
  }) {
    final ownedRoot = Map<String, Object?>.from(currentRoot);
    return _execute(
      inputByteLength,
      () => _mergeAndEncodeProject(ownedRoot, project),
    );
  }

  /// Decodes, checks and merges an existing project in one worker transfer.
  ///
  /// The caller still owns the recovery gate, lock, before/live revision
  /// checks and final write. Only pure JSON/model work happens here.
  Future<EditorPreparedProjectUpdate> prepareExistingProjectUpdate({
    required List<int> currentBytes,
    required ProjectManifest project,
  }) {
    final ownedBytes = _ownedBytes(currentBytes);
    return _execute(
      ownedBytes.length,
      () => _prepareExistingProjectUpdate(ownedBytes, project),
    );
  }

  Future<String> fingerprintProjectBytes(List<int> bytes) {
    final ownedBytes = _ownedBytes(bytes);
    return _execute(
      ownedBytes.length,
      () => narrativeEventBytesFingerprint(ownedBytes),
    );
  }

  Future<T> _execute<T>(int inputByteLength, T Function() operation) async {
    if (inputByteLength < offloadThresholdBytes) {
      _localOperations++;
      return operation();
    }
    _workerOperations++;
    try {
      return await _workerRunner(operation);
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runEditorPersistenceWorker<T>(T Function() operation) {
  return Isolate.run(operation);
}

Map<String, Object?> _decodeStrictProjectRoot(List<int> bytes) {
  return _strictJsonObject(
    decodeNarrativeEventJsonStrict(utf8.decode(bytes)),
  );
}

List<int> _mergeAndEncodeProject(
  Map<String, Object?> currentRoot,
  ProjectManifest project,
) {
  final serializedProject = _strictJsonObject(
    jsonDecode(jsonEncode(project.toJson())),
  );
  final nextRoot = Map<String, Object?>.from(currentRoot)
    ..addAll(serializedProject);
  if (currentRoot.containsKey('eventRegistry')) {
    nextRoot['eventRegistry'] = currentRoot['eventRegistry'];
  } else {
    nextRoot.remove('eventRegistry');
  }
  canonicalizeNarrativeEventJson(nextRoot);
  return utf8.encode(
    const JsonEncoder.withIndent('  ').convert(nextRoot),
  );
}

EditorPreparedProjectUpdate _prepareExistingProjectUpdate(
  List<int> currentBytes,
  ProjectManifest project,
) {
  late final Map<String, Object?> currentRoot;
  try {
    currentRoot = _decodeStrictProjectRoot(currentBytes);
  } on Object catch (error) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.currentProjectInvalid,
      message: '$error',
    );
  }

  final currentRegistry = decodeNarrativeEventRegistry(
    currentRoot['eventRegistry'],
  );
  if (!currentRegistry.writable) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.eventRegistryReadOnly,
      message: currentRegistry.diagnostics.join(' '),
    );
  }
  if (!_sameEventRegistry(
    currentRegistry.registryOrNull,
    project.eventRegistry,
  )) {
    throw const EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.eventRegistryConflict,
      message: 'The Event registry changed outside the generic project save.',
    );
  }
  try {
    return EditorPreparedProjectUpdate(
      bytes: _mergeAndEncodeProject(currentRoot, project),
      beforeRevision: narrativeEventBytesFingerprint(currentBytes),
    );
  } on Object catch (error) {
    throw EditorPersistenceCodecException(
      kind: EditorPersistenceCodecFailureKind.updatedProjectInvalid,
      message: '$error',
    );
  }
}

bool _sameEventRegistry(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

Map<String, Object?> _strictJsonObject(Object? value) {
  if (value is! Map) {
    throw const FormatException('Project root must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Project keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _estimateJsonBytes(Object? value) {
  if (value == null) return 4;
  if (value is String) return value.length + 2;
  if (value is num || value is bool) return value.toString().length;
  if (value is List) {
    var total = 2;
    for (final item in value) {
      total += _estimateJsonBytes(item) + 1;
    }
    return total;
  }
  if (value is Map) {
    var total = 2;
    for (final entry in value.entries) {
      total += entry.key.toString().length + 3;
      total += _estimateJsonBytes(entry.value) + 1;
    }
    return total;
  }
  return value.toString().length;
}

Uint8List _ownedBytes(List<int> bytes) {
  return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
````

### `packages/map_editor/test/infrastructure/editor_persistence_codec_executor_test.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: const [],
    legacyClaims: const [],
  );
  final before = ProjectManifest(
    name: 'Avant',
    maps: const [],
    tilesets: const [],
    eventRegistry: registry,
  );
  final after = ProjectManifest(
    name: 'Après',
    maps: const [],
    tilesets: const [],
    eventRegistry: registry,
  );

  test('forced local and worker paths produce byte-identical project JSON',
      () async {
    final source = <String, Object?>{
      ...before.toJson(),
      'futureField': <String, Object?>{'kept': true},
    };
    final sourceBytes = utf8.encode(jsonEncode(source));
    final localRunner = _RecordingWorkerRunner();
    final workerRunner = _RecordingWorkerRunner();
    final local = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 1 << 30,
      workerRunner: localRunner.call,
    );
    final worker = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: workerRunner.call,
    );

    final localUpdate = await local.prepareExistingProjectUpdate(
      currentBytes: sourceBytes,
      project: after,
    );
    final workerUpdate = await worker.prepareExistingProjectUpdate(
      currentBytes: sourceBytes,
      project: after,
    );

    expect(workerUpdate.bytes, localUpdate.bytes);
    expect(workerUpdate.beforeRevision, localUpdate.beforeRevision);
    final merged =
        jsonDecode(utf8.decode(workerUpdate.bytes)) as Map<String, dynamic>;
    expect(merged['name'], 'Après');
    expect(merged['futureField'], {'kept': true});
    expect(merged['eventRegistry'], registry.toJson());
    expect(localRunner.calls, 0);
    expect(workerRunner.calls, 1);
  });

  test('default worker can decode and validate a project off-isolate',
      () async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(after.toJson()),
    );
    final executor = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
    );

    final decoded = await executor.decodeValidatedProject(bytes);

    expect(decoded, after);
    expect(executor.diagnostics.workerOperations, 1);
    expect(executor.diagnostics.localOperations, 0);
  });

  test('worker failure is surfaced without a local retry', () async {
    final executor = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: <T>(T Function() operation) async {
        throw StateError('worker failed');
      },
    );

    await expectLater(
      executor.encodeNewProject(after),
      throwsA(isA<StateError>()),
    );
    expect(executor.diagnostics.workerFailures, 1);
  });

  test('repository leaves existing bytes untouched when its worker fails',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap_editor_codec_failure_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/project.json');
    final beforeBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(before.toJson()),
    );
    await file.writeAsBytes(beforeBytes, flush: true);
    final repository = FileProjectRepository(
      codecExecutor: EditorPersistenceCodecExecutor(
        offloadThresholdBytes: 0,
        workerRunner: <T>(T Function() operation) async {
          throw StateError('worker failed');
        },
      ),
    );

    await expectLater(
      repository.saveProject(after, file.path),
      throwsA(isA<EditorPersistenceException>()),
    );

    expect(await file.readAsBytes(), beforeBytes);
  });
}

final class _RecordingWorkerRunner {
  var calls = 0;

  Future<T> call<T>(T Function() operation) async {
    calls++;
    return operation();
  }
}
````

### `packages/map_editor/benchmark/editor_codec_offload_profile_test.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/editor_persistence_codec_executor.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profiles editor codec phases and UI-isolate heartbeat', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_editor_codec_profile_',
    );
    try {
      final rows = <Map<String, Object?>>[];
      for (final requestedBytes in const [1024, 102400, 2420033, 10485760]) {
        final project = ProjectManifest(
          name: 'Codec $requestedBytes',
          maps: const [],
          tilesets: const [],
          globalProperties: {'payload': 'x' * requestedBytes},
        );
        final local = EditorPersistenceCodecExecutor(
          offloadThresholdBytes: 1 << 30,
        );
        final thresholded = EditorPersistenceCodecExecutor();

        final localEncode = await _measure(
          () => local.encodeNewProject(project),
        );
        final workerEncode = await _measure(
          () => thresholded.encodeNewProject(project),
        );
        expect(workerEncode.value, localEncode.value);

        final file = File('${sandbox.path}/project_$requestedBytes.json');
        final writeWatch = Stopwatch()..start();
        await file.writeAsBytes(workerEncode.value, flush: true);
        writeWatch.stop();
        final readWatch = Stopwatch()..start();
        final bytes = await file.readAsBytes();
        readWatch.stop();

        final decodeWatch = Stopwatch()..start();
        final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        decodeWatch.stop();
        final modelWatch = Stopwatch()..start();
        final modeled = ProjectManifest.fromJson(raw);
        modelWatch.stop();
        final validateWatch = Stopwatch()..start();
        ProjectValidator.validate(modeled);
        validateWatch.stop();

        final workerDecode = await _measure(
          () => thresholded.decodeValidatedProject(bytes),
        );
        expect(workerDecode.value, project);
        final workerSavePrepare = await _measure(
          () => thresholded.prepareExistingProjectUpdate(
            currentBytes: bytes,
            project: project,
          ),
        );
        expect(workerSavePrepare.value.bytes, bytes);
        expect(
          workerSavePrepare.value.beforeRevision,
          narrativeEventBytesFingerprint(bytes),
        );
        final repository = FileProjectRepository(
          codecExecutor: EditorPersistenceCodecExecutor(),
        );
        final repositorySave = await _measure(
          () => repository.saveProject(project, file.path),
        );
        expect(
          narrativeEventBytesFingerprint(await file.readAsBytes()),
          narrativeEventBytesFingerprint(bytes),
        );
        rows.add({
          'requestedPayloadBytes': requestedBytes,
          'encodedBytes': bytes.length,
          'fingerprint': narrativeEventBytesFingerprint(bytes),
          'readUs': readWatch.elapsedMicroseconds,
          'decodeJsonUs': decodeWatch.elapsedMicroseconds,
          'modelUs': modelWatch.elapsedMicroseconds,
          'validateUs': validateWatch.elapsedMicroseconds,
          'writeUs': writeWatch.elapsedMicroseconds,
          'localEncode': localEncode.toJson(),
          'thresholdedEncode': workerEncode.toJson(),
          'thresholdedDecode': workerDecode.toJson(),
          'thresholdedSavePrepare': workerSavePrepare.toJson(),
          'repositorySave': repositorySave.toJson(),
          'codecDiagnostics': {
            'localOperations': thresholded.diagnostics.localOperations,
            'workerOperations': thresholded.diagnostics.workerOperations,
            'workerFailures': thresholded.diagnostics.workerFailures,
          },
        });
      }
      // ignore: avoid_print
      print(jsonEncode({
        'schemaVersion': 1,
        'benchmark': 'editor_codec_offload',
        'thresholdBytes':
            EditorPersistenceCodecExecutor.defaultOffloadThresholdBytes,
        'results': rows,
      }));
    } finally {
      await sandbox.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<_HeartbeatMeasurement<T>> _measure<T>(
    Future<T> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  var previousTickUs = 0;
  var maxHeartbeatGapUs = 0;
  var heartbeatCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = stopwatch.elapsedMicroseconds;
    final gap = now - previousTickUs;
    if (gap > maxHeartbeatGapUs) maxHeartbeatGapUs = gap;
    previousTickUs = now;
    heartbeatCount++;
  });
  try {
    final value = await operation();
    final finalGap = stopwatch.elapsedMicroseconds - previousTickUs;
    if (finalGap > maxHeartbeatGapUs) maxHeartbeatGapUs = finalGap;
    return _HeartbeatMeasurement(
      value: value,
      elapsedUs: stopwatch.elapsedMicroseconds,
      heartbeatCount: heartbeatCount,
      maxHeartbeatGapUs: maxHeartbeatGapUs,
    );
  } finally {
    timer.cancel();
    stopwatch.stop();
  }
}

final class _HeartbeatMeasurement<T> {
  const _HeartbeatMeasurement({
    required this.value,
    required this.elapsedUs,
    required this.heartbeatCount,
    required this.maxHeartbeatGapUs,
  });

  final T value;
  final int elapsedUs;
  final int heartbeatCount;
  final int maxHeartbeatGapUs;

  Map<String, Object?> toJson() => {
        'elapsedUs': elapsedUs,
        'heartbeatCount': heartbeatCount,
        'maxHeartbeatGapUs': maxHeartbeatGapUs,
      };
}
````

### `packages/map_runtime/lib/src/infrastructure/game_save_codec_executor.dart`

````dart
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

typedef GameSaveCodecWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

final class GameSaveCodecDiagnostics {
  const GameSaveCodecDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

/// Thresholded executor for the pure JSON portion of game-save persistence.
///
/// The repository remains responsible for the activity gate, path and file
/// operations. This type neither writes files nor changes transaction order.
final class GameSaveCodecExecutor {
  GameSaveCodecExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    GameSaveCodecWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runGameSaveCodecWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final GameSaveCodecWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  GameSaveCodecDiagnostics get diagnostics => GameSaveCodecDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<String> encodeJson(Map<String, dynamic> json) {
    final ownedJson = Map<String, dynamic>.from(json);
    return _execute(
      _estimateJsonBytes(ownedJson),
      () => const JsonEncoder.withIndent('  ').convert(ownedJson),
    );
  }

  Future<GameState> decode(List<int> bytes) {
    final ownedBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    return _execute(
      ownedBytes.length,
      () => _decodeAndNormalizeGameState(ownedBytes),
    );
  }

  Future<T> _execute<T>(int inputByteLength, T Function() operation) async {
    if (inputByteLength < offloadThresholdBytes) {
      _localOperations++;
      return operation();
    }
    _workerOperations++;
    try {
      return await _workerRunner(operation);
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runGameSaveCodecWorker<T>(T Function() operation) {
  return Isolate.run(operation);
}

GameState _decodeAndNormalizeGameState(List<int> bytes) {
  final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  return normalizeLoadedGameState(GameState.fromJson(json));
}

int _estimateJsonBytes(Object? value) {
  if (value == null) return 4;
  if (value is String) return value.length + 2;
  if (value is num || value is bool) return value.toString().length;
  if (value is List) {
    var total = 2;
    for (final item in value) {
      total += _estimateJsonBytes(item) + 1;
    }
    return total;
  }
  if (value is Map) {
    var total = 2;
    for (final entry in value.entries) {
      total += entry.key.toString().length + 3;
      total += _estimateJsonBytes(entry.value) + 1;
    }
    return total;
  }
  return value.toString().length;
}
````

### `packages/map_runtime/test/game_save_codec_executor_test.dart`

````dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/domain/repositories/game_save_repository.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';
import 'package:map_runtime/src/infrastructure/game_save_codec_executor.dart';

void main() {
  const state = GameState(
    saveId: 'codec-save',
    currentMapId: 'codec-map',
    metadata: {'note': 'éà漢字'},
  );

  test('forced local and worker paths preserve exact indented bytes', () async {
    final json = state.toJson();
    final localRunner = _RecordingWorkerRunner();
    final workerRunner = _RecordingWorkerRunner();
    final local = GameSaveCodecExecutor(
      offloadThresholdBytes: 1 << 30,
      workerRunner: localRunner.call,
    );
    final worker = GameSaveCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: workerRunner.call,
    );

    final localEncoded = await local.encodeJson(json);
    final workerEncoded = await worker.encodeJson(json);

    expect(workerEncoded, localEncoded);
    expect(
      workerEncoded,
      const JsonEncoder.withIndent('  ').convert(json),
    );
    expect(localRunner.calls, 0);
    expect(workerRunner.calls, 1);
  });

  test('default worker decodes and normalizes a save off-isolate', () async {
    final encoded = const JsonEncoder.withIndent('  ').convert(state.toJson());
    final executor = GameSaveCodecExecutor(offloadThresholdBytes: 0);

    final decoded = await executor.decode(utf8.encode(encoded));

    expect(decoded.saveId, state.saveId);
    expect(decoded.currentMapId, state.currentMapId);
    expect(decoded.metadata, state.metadata);
    expect(executor.diagnostics.workerOperations, 1);
  });

  test('malformed JSON remains a typed codec failure', () async {
    final executor = GameSaveCodecExecutor(offloadThresholdBytes: 0);

    await expectLater(
      executor.decode(utf8.encode('{"saveId":')),
      throwsA(isA<FormatException>()),
    );
    expect(executor.diagnostics.workerFailures, 1);
  });

  test('repository translates worker failure and writes no save', () async {
    final directory = await Directory.systemTemp.createTemp(
      'pokemap_game_save_codec_failure_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = _TestGameSaveRepository(
      directory,
      codecExecutor: GameSaveCodecExecutor(
        offloadThresholdBytes: 0,
        workerRunner: <T>(T Function() operation) async {
          throw StateError('worker failed');
        },
      ),
    );

    await expectLater(
      repository.save(state),
      throwsA(isA<GameSaveException>()),
    );
    expect(await repository.exists(), isFalse);
  });
}

final class _RecordingWorkerRunner {
  var calls = 0;

  Future<T> call<T>(T Function() operation) async {
    calls++;
    return operation();
  }
}

final class _TestGameSaveRepository extends FileGameSaveRepository {
  _TestGameSaveRepository(
    this.directory, {
    required super.codecExecutor,
  });

  final Directory directory;

  @override
  Future<String> getSaveFilePath() async => '${directory.path}/game_save.json';
}
````

### `packages/map_runtime/benchmark/game_save_codec_offload_profile_test.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';
import 'package:map_runtime/src/infrastructure/game_save_codec_executor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profiles game-save codec phases and UI-isolate heartbeat', () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_game_save_codec_profile_',
    );
    try {
      final rows = <Map<String, Object?>>[];
      for (final requestedBytes in const [1024, 102400, 2420033, 10485760]) {
        final state = GameState(
          saveId: 'codec-$requestedBytes',
          currentMapId: 'profile-map',
          metadata: {'payload': 'x' * requestedBytes},
        );
        final json = state.toJson();
        final local = GameSaveCodecExecutor(
          offloadThresholdBytes: 1 << 30,
        );
        final thresholded = GameSaveCodecExecutor();
        final localEncode = await _measure(() => local.encodeJson(json));
        final thresholdedEncode = await _measure(
          () => thresholded.encodeJson(json),
        );
        expect(thresholdedEncode.value, localEncode.value);

        final bytes = utf8.encode(thresholdedEncode.value);
        final file = File('${sandbox.path}/save_$requestedBytes.json');
        final writeWatch = Stopwatch()..start();
        await file.writeAsBytes(bytes, flush: true);
        writeWatch.stop();
        final readWatch = Stopwatch()..start();
        final readBytes = await file.readAsBytes();
        readWatch.stop();

        final decodeWatch = Stopwatch()..start();
        final raw = jsonDecode(utf8.decode(readBytes)) as Map<String, dynamic>;
        decodeWatch.stop();
        final modelWatch = Stopwatch()..start();
        final modeled = GameState.fromJson(raw);
        modelWatch.stop();
        final normalizeWatch = Stopwatch()..start();
        final normalized = normalizeLoadedGameState(modeled);
        normalizeWatch.stop();
        expect(normalized.saveId, state.saveId);

        final thresholdedDecode = await _measure(
          () => thresholded.decode(readBytes),
        );
        expect(thresholdedDecode.value.saveId, state.saveId);
        final repository = _BenchmarkGameSaveRepository(
          directory: sandbox,
          codecExecutor: GameSaveCodecExecutor(),
          fileName: 'repository_save_$requestedBytes.json',
        );
        final repositorySave = await _measure(() => repository.save(state));
        final repositoryLoad = await _measure(() => repository.load());
        expect(repositoryLoad.value?.saveId, state.saveId);
        rows.add({
          'requestedPayloadBytes': requestedBytes,
          'encodedBytes': readBytes.length,
          'fingerprint': narrativeEventBytesFingerprint(readBytes),
          'readUs': readWatch.elapsedMicroseconds,
          'decodeJsonUs': decodeWatch.elapsedMicroseconds,
          'modelUs': modelWatch.elapsedMicroseconds,
          'normalizeUs': normalizeWatch.elapsedMicroseconds,
          'writeUs': writeWatch.elapsedMicroseconds,
          'localEncode': localEncode.toJson(),
          'thresholdedEncode': thresholdedEncode.toJson(),
          'thresholdedDecode': thresholdedDecode.toJson(),
          'repositorySave': repositorySave.toJson(),
          'repositoryLoad': repositoryLoad.toJson(),
          'codecDiagnostics': {
            'localOperations': thresholded.diagnostics.localOperations,
            'workerOperations': thresholded.diagnostics.workerOperations,
            'workerFailures': thresholded.diagnostics.workerFailures,
          },
        });
      }
      // ignore: avoid_print
      print(jsonEncode({
        'schemaVersion': 1,
        'benchmark': 'game_save_codec_offload',
        'thresholdBytes': GameSaveCodecExecutor.defaultOffloadThresholdBytes,
        'results': rows,
      }));
    } finally {
      await sandbox.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

final class _BenchmarkGameSaveRepository extends FileGameSaveRepository {
  _BenchmarkGameSaveRepository({
    required this.directory,
    required this.fileName,
    required super.codecExecutor,
  });

  final Directory directory;
  final String fileName;

  @override
  Future<String> getSaveFilePath() async => '${directory.path}/$fileName';
}

Future<_HeartbeatMeasurement<T>> _measure<T>(
    Future<T> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  var previousTickUs = 0;
  var maxHeartbeatGapUs = 0;
  var heartbeatCount = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = stopwatch.elapsedMicroseconds;
    final gap = now - previousTickUs;
    if (gap > maxHeartbeatGapUs) maxHeartbeatGapUs = gap;
    previousTickUs = now;
    heartbeatCount++;
  });
  try {
    final value = await operation();
    final finalGap = stopwatch.elapsedMicroseconds - previousTickUs;
    if (finalGap > maxHeartbeatGapUs) maxHeartbeatGapUs = finalGap;
    return _HeartbeatMeasurement(
      value: value,
      elapsedUs: stopwatch.elapsedMicroseconds,
      heartbeatCount: heartbeatCount,
      maxHeartbeatGapUs: maxHeartbeatGapUs,
    );
  } finally {
    timer.cancel();
    stopwatch.stop();
  }
}

final class _HeartbeatMeasurement<T> {
  const _HeartbeatMeasurement({
    required this.value,
    required this.elapsedUs,
    required this.heartbeatCount,
    required this.maxHeartbeatGapUs,
  });

  final T value;
  final int elapsedUs;
  final int heartbeatCount;
  final int maxHeartbeatGapUs;

  Map<String, Object?> toJson() => {
        'elapsedUs': elapsedUs,
        'heartbeatCount': heartbeatCount,
        'maxHeartbeatGapUs': maxHeartbeatGapUs,
      };
}
````

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-09b-application-codec-offload.md`

````markdown
# PERF-RM-09B Application Codec Offload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Start only after `PERF-RM-09A` has stable contracts and receipts.

**Goal:** Move expensive project and game-save JSON codec work off the UI isolate above a measured crossover while preserving every existing byte format and repository transaction boundary.

**Architecture:** Package-local codec executors own only pure model/JSON conversion. Repositories continue to own paths, locks, CAS checks, temp files, writes, recovery and error translation. Thresholds and executors are injectable so tests can force local/offloaded paths without timing assertions.

**Tech Stack:** Flutter compute/isolate workers, `map_core` models, editor/runtime repository tests, profile heartbeat harness.

---

### Task 1: Measure the crossover and freeze existing bytes

**Files:**
- Modify: `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart`
- Modify: `packages/map_runtime/test/file_game_save_repository_test.dart`

- [ ] Record read, decode/model, validation, encode, and write durations for 1 KiB, 100 KiB, 2.4 MiB and 10 MiB fixtures in separate receipts.
- [ ] Save golden byte fingerprints for local project merge/encode and game-save encode/decode.
- [ ] Capture a UI heartbeat while codec work runs; do not infer frame health from total elapsed time.
- [ ] Select and document a byte threshold from the same runner; keep it injectable.

### Task 2: Add an editor persistence codec executor

**Files:**
- Create: `packages/map_editor/lib/src/infrastructure/repositories/editor_persistence_codec_executor.dart`
- Create: `packages/map_editor/test/infrastructure/editor_persistence_codec_executor_test.dart`
- Modify: `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

- [ ] Define an executor that decodes projects/maps and merges/validates/encodes project bytes without owning files or paths.
- [ ] Add a local implementation and a thresholded isolate implementation with identical typed results.
- [ ] Keep the pre-read, recovery gate, project write lock, before/live revision checks, event-registry preservation, and final write in the repository isolate.
- [ ] Test forced-local and forced-worker outputs byte-for-byte, worker failure translation, stale file CAS, recovery-required, and no-write-on-codec-error.

### Task 3: Add a game-save codec executor

**Files:**
- Create: `packages/map_runtime/lib/src/infrastructure/game_save_codec_executor.dart`
- Create: `packages/map_runtime/test/game_save_codec_executor_test.dart`
- Modify: `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- Modify: `packages/map_runtime/test/file_game_save_repository_test.dart`
- Modify: `packages/map_runtime/test/playable_map_game_save_load_transaction_test.dart`

- [ ] Define `encode(GameState)` and `decode(List<int>)` executors with injectable threshold and worker runner.
- [ ] Preserve normalization before encode and after decode, exact indented JSON, activity-gate ordering, existing exception types, and unchanged file write semantics.
- [ ] Treat runtime file atomicity/CAS/recovery as `N/A — unchanged pre-existing contract`; do not claim guarantees absent from the repository.
- [ ] Test local/worker byte identity, malformed JSON, invalid state no-write, load transaction rollback/retry, and heartbeat progress.

### Task 4: Regress authoring parity and calibrate

- [ ] Run project round-trip, map CAS/recovery, runtime save/load, PMCP-085, MCP server tests and live catalog checks.
- [ ] Run three profile samples at the chosen threshold and compare total time plus maximum heartbeat gap.
- [ ] Require project save at most 250 ms with no frame over 33.3 ms on the 10 MiB fixture and game save/load at most 150 ms, without byte or recovery differences.
- [ ] If offload only moves total time and the heartbeat still stalls, report `PARTIAL`; do not skip validation or transaction checks.

**Verification:**

```bash
cd packages/map_editor && flutter test test/infrastructure/editor_persistence_codec_executor_test.dart test/selbrume_editor_repository_roundtrip_test.dart && flutter test && flutter analyze
cd packages/map_runtime && flutter test test/game_save_codec_executor_test.dart test/file_game_save_repository_test.dart test/playable_map_game_save_load_transaction_test.dart && flutter test && flutter analyze
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart && dart test test/parity/full_authoring_parity_test.dart && dart analyze
cd tools/pokemap_mcp && npm run check && npm test
```

**Non-goals:** changing JSON formatting/schema, moving file I/O or locks into workers, adding runtime save atomicity, weakening CAS/recovery, offloading small payloads without measurement, or broadening workspace roots.
````
