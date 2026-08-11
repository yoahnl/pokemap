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
    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert(strictGameStateSaveJson(state));
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
