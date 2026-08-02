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
