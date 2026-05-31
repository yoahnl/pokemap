import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_consequence_runtime_write_result.dart';

final class SceneConsequenceRuntimeWriter {
  const SceneConsequenceRuntimeWriter({
    required this.project,
    this.mapsById = const <String, MapData>{},
    this.mutations = const GameStateMutations(),
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final GameStateMutations mutations;

  SceneConsequenceRuntimeWriteResult applyAll(
    GameState gameState,
    List<SceneConsequence> consequences,
  ) {
    var nextState = gameState;
    final applied = <SceneConsequence>[];
    for (final consequence in consequences) {
      final step = _apply(nextState, consequence);
      if (step.errorCode != null) {
        return SceneConsequenceRuntimeWriteResult.failed(
          gameState: gameState,
          errorCode: step.errorCode!,
          message: step.message!,
          failedConsequence: consequence,
          appliedConsequences: const <SceneConsequence>[],
        );
      }
      nextState = step.gameState!;
      applied.add(consequence);
    }
    return SceneConsequenceRuntimeWriteResult.applied(
      gameState: nextState,
      appliedConsequences: applied,
    );
  }

  _SceneConsequenceRuntimeWriteStep _apply(
    GameState gameState,
    SceneConsequence consequence,
  ) {
    return switch (consequence.kind) {
      SceneConsequenceKind.setFact => _applySetFact(
          gameState,
          consequence as SceneSetFactConsequence,
        ),
      SceneConsequenceKind.markEventConsumed => _applyMarkEventConsumed(
          gameState,
          consequence as SceneMarkEventConsumedConsequence,
        ),
    };
  }

  _SceneConsequenceRuntimeWriteStep _applySetFact(
    GameState gameState,
    SceneSetFactConsequence consequence,
  ) {
    final fact = _findFact(consequence.factId);
    if (fact == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownFact,
        'Scene consequence setFact references unknown Fact '
        '"${consequence.factId}".',
      );
    }
    final runtimeKey = fact.legacyFlagName ?? fact.id;
    final nextState = consequence.value
        ? mutations.setFlag(gameState, runtimeKey)
        : mutations.clearFlag(gameState, runtimeKey);
    return _SceneConsequenceRuntimeWriteStep.applied(nextState);
  }

  _SceneConsequenceRuntimeWriteStep _applyMarkEventConsumed(
    GameState gameState,
    SceneMarkEventConsumedConsequence consequence,
  ) {
    final projectHasMap =
        project.maps.any((map) => map.id == consequence.mapId);
    final mapData = mapsById[consequence.mapId];
    if (!projectHasMap || mapData == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
        'Scene consequence markEventConsumed references unknown map '
        '"${consequence.mapId}".',
      );
    }
    final hasEvent =
        mapData.events.any((event) => event.id == consequence.eventId);
    if (!hasEvent) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
        'Scene consequence markEventConsumed references unknown event '
        '"${consequence.eventId}" on map "${consequence.mapId}".',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.markEventConsumed(gameState, consequence.eventId),
    );
  }

  NarrativeFactDefinition? _findFact(String factId) {
    for (final fact in project.facts) {
      if (fact.id == factId) {
        return fact;
      }
    }
    return null;
  }
}

final class _SceneConsequenceRuntimeWriteStep {
  const _SceneConsequenceRuntimeWriteStep._({
    this.gameState,
    this.errorCode,
    this.message,
  });

  const _SceneConsequenceRuntimeWriteStep.applied(GameState gameState)
      : this._(gameState: gameState);

  const _SceneConsequenceRuntimeWriteStep.failed(
    SceneConsequenceRuntimeWriteErrorCode errorCode,
    String message,
  ) : this._(
          errorCode: errorCode,
          message: message,
        );

  final GameState? gameState;
  final SceneConsequenceRuntimeWriteErrorCode? errorCode;
  final String? message;
}
