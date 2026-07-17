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
    final factWriter = NarrativeFactRuntimeWriter(
      NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    for (final consequence in consequences) {
      final step = _apply(nextState, consequence, factWriter);
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
    NarrativeFactRuntimeWriter factWriter,
  ) {
    return switch (consequence.kind) {
      SceneConsequenceKind.setFact => _applySetFact(
          gameState,
          consequence as SceneSetFactConsequence,
          factWriter,
        ),
      SceneConsequenceKind.markEventConsumed => _applyMarkEventConsumed(
          gameState,
          consequence as SceneMarkEventConsumedConsequence,
        ),
      SceneConsequenceKind.completeStoryStep => _applyCompleteStoryStep(
          gameState,
          consequence as SceneCompleteStoryStepConsequence,
        ),
    };
  }

  _SceneConsequenceRuntimeWriteStep _applySetFact(
    GameState gameState,
    SceneSetFactConsequence consequence,
    NarrativeFactRuntimeWriter factWriter,
  ) {
    final result = factWriter.setFact(
      gameState: gameState,
      factId: consequence.factId,
      value: consequence.value,
    );
    if (result is NarrativeFactRuntimeWriteRejected) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        switch (result.errorCode) {
          NarrativeFactRuntimeWriteErrorCode.unknownFact =>
            SceneConsequenceRuntimeWriteErrorCode.unknownFact,
          NarrativeFactRuntimeWriteErrorCode.ambiguousFact =>
            SceneConsequenceRuntimeWriteErrorCode.ambiguousFact,
          NarrativeFactRuntimeWriteErrorCode.invalidRuntimeKey =>
            SceneConsequenceRuntimeWriteErrorCode.invalidFactRuntimeKey,
        },
        result.message,
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(result.gameState);
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

  _SceneConsequenceRuntimeWriteStep _applyCompleteStoryStep(
    GameState gameState,
    SceneCompleteStoryStepConsequence consequence,
  ) {
    final matches = <StorylineStep>[
      for (final storyline in project.storylines)
        for (final chapter in storyline.chapters)
          for (final step in chapter.steps)
            if (step.id == consequence.stepId) step,
    ];
    if (matches.isEmpty) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownStoryStep,
        'Scene consequence completeStoryStep references unknown Story Step '
        '"${consequence.stepId}".',
      );
    }
    if (matches.length > 1) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.ambiguousStoryStep,
        'Scene consequence completeStoryStep references ambiguous Story Step '
        '"${consequence.stepId}".',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.completeStep(gameState, consequence.stepId),
    );
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
