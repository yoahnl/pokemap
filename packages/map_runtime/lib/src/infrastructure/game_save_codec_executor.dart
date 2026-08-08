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
      _estimateJsonBytes(ownedJson, offloadThresholdBytes),
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

/// Estimation bornée par [budget] : la décision d'offload est uniquement
/// « estimation < seuil », donc le parcours s'arrête dès que le seuil est
/// atteint au lieu de traverser tout l'état (avec un `toString` alloué par
/// scalaire) avant chaque encodage.
int _estimateJsonBytes(Object? value, int budget) {
  var total = 0;
  final stack = <Object?>[value];
  while (stack.isNotEmpty) {
    if (total >= budget) {
      return total;
    }
    final current = stack.removeLast();
    if (current == null) {
      total += 4;
    } else if (current is String) {
      total += current.length + 2;
    } else if (current is bool) {
      total += current ? 4 : 5;
    } else if (current is int) {
      total += _decimalDigitCount(current);
    } else if (current is num) {
      total += 12;
    } else if (current is List) {
      total += 2 + current.length;
      stack.addAll(current);
    } else if (current is Map) {
      total += 2;
      for (final entry in current.entries) {
        total += entry.key.toString().length + 4;
        stack.add(entry.value);
      }
    } else {
      total += current.toString().length;
    }
  }
  return total;
}

int _decimalDigitCount(int value) {
  var count = value < 0 ? 2 : 1;
  var magnitude = value.abs();
  while (magnitude >= 10) {
    count += 1;
    magnitude ~/= 10;
  }
  return count;
}
