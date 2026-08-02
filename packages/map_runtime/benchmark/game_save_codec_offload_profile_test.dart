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
