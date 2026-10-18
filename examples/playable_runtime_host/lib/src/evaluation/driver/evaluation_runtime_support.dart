import 'dart:convert';
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

final class EvaluationPlayableMapGame extends PlayableMapGame {
  EvaluationPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    required super.encounterRandom,
    super.gameCompletionEmitter,
  });

  @override
  bool get isLoaded => true;
}

/// Forces the production encounter policy to take its encounter branch while
/// leaving table selection, battle setup, and capture RNG untouched.
final class AlwaysEncounterRandom implements math.Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

/// In-memory save repository that deliberately serializes every write.
///
/// Evaluation reloads therefore exercise the same JSON boundary as a real
/// save, instead of returning the object instance previously supplied.
final class SerializedEvaluationSaveRepository implements GameSaveRepository {
  String? _payload;

  @override
  Future<void> save(GameState value) async {
    _payload = jsonEncode(strictGameStateSaveJson(value));
  }

  @override
  Future<GameState?> load() async {
    final payload = _payload;
    if (payload == null) return null;
    return gameStateFromStrictSaveJson(
      jsonDecode(payload) as Map<String, dynamic>,
    );
  }

  @override
  Future<bool> exists() async => _payload != null;

  @override
  Future<void> delete() async => _payload = null;
}
