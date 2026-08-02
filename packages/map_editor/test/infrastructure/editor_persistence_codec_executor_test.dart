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

  test('offloads when a small existing project grows beyond the threshold',
      () async {
    final sourceBytes = utf8.encode(jsonEncode(before.toJson()));
    final expanded = ProjectManifest(
      name: 'Expanded',
      maps: const [],
      tilesets: const [],
      eventRegistry: registry,
      globalProperties: <String, Object?>{
        'payload': 'x' * (2 * 1024 * 1024),
      },
    );
    final workerRunner = _RecordingWorkerRunner();
    final executor = EditorPersistenceCodecExecutor(
      workerRunner: workerRunner.call,
    );

    final update = await executor.prepareExistingProjectUpdate(
      currentBytes: sourceBytes,
      project: expanded,
    );

    expect(update.bytes.length, greaterThan(2 * 1024 * 1024));
    expect(workerRunner.calls, 1);
    expect(executor.diagnostics.workerOperations, 1);
  });

  test('forced local and worker paths compare project bytes exactly', () async {
    final expected = List<int>.filled(2 * 1024 * 1024, 7);
    final changed = List<int>.of(expected)..[expected.length - 1] = 8;
    final local = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 1 << 30,
    );
    final workerRunner = _RecordingWorkerRunner();
    final worker = EditorPersistenceCodecExecutor(
      offloadThresholdBytes: 0,
      workerRunner: workerRunner.call,
    );

    expect(
        await local.projectBytesMatch(expected, List<int>.of(expected)), true);
    expect(await worker.projectBytesMatch(expected, changed), false);
    expect(await worker.projectBytesMatch(expected, [...expected, 7]), false);
    expect(workerRunner.calls, 2);
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
