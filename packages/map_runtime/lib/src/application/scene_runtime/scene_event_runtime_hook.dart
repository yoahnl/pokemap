import 'package:map_core/map_core.dart';

import 'scene_consequence_runtime_writer.dart';
import 'scene_runtime_host_callbacks.dart';
import 'scene_runtime_hook_result.dart';

final class SceneEventRuntimeHook {
  SceneEventRuntimeHook({
    required this.callbacks,
    this.maxSteps = 100,
  }) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'SceneEventRuntimeHook requires maxSteps >= 1.',
      );
    }
  }

  final SceneRuntimeHostCallbacks callbacks;
  final int maxSteps;

  Future<SceneEventRuntimeHookResult> runForEventPage({
    required ProjectManifest project,
    required MapData map,
    required MapEventDefinition event,
    required MapEventPage page,
    GameState? gameState,
  }) async {
    final sceneTarget = page.sceneTarget;
    if (sceneTarget == null) {
      return const SceneEventRuntimeHookResult.notHandled();
    }

    final sceneId = sceneTarget.sceneId;
    final scene = _findScene(project, sceneId);
    if (scene == null) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetMissingScene,
        sceneId: sceneId,
        message: 'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" was not found.',
      );
    }

    final diagnostics = diagnoseSceneAgainstProject(
      scene,
      project,
      mapsById: {map.id: map},
    );
    if (diagnostics.hasErrors) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetDiagnosticsFailed,
        sceneId: sceneId,
        message: 'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" has blocking diagnostics.',
      );
    }

    final planResult = buildSceneRuntimePlan(scene);
    if (!planResult.canBuild) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetRuntimePlanFailed,
        sceneId: sceneId,
        message: 'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" cannot build a runtime plan.',
      );
    }

    final pendingConsequences = <SceneConsequence>[];
    final executionResult = await SceneRuntimeExecutor(
      callbacks: callbacks.toExecutionCallbacks(
        applyConsequence: (consequence) {
          pendingConsequences.add(consequence);
          return 'completed';
        },
      ),
      maxSteps: maxSteps,
    ).execute(planResult.plan!);

    if (executionResult.status == SceneRuntimeExecutionStatus.completed) {
      if (pendingConsequences.isEmpty) {
        return SceneEventRuntimeHookResult.completed(
          sceneId: sceneId,
          executionResult: executionResult,
        );
      }

      if (gameState == null) {
        return SceneEventRuntimeHookResult.failed(
          errorCode: SceneEventRuntimeHookErrorCode.sceneConsequenceWriteFailed,
          sceneId: sceneId,
          message: 'Scene V1 "$sceneId" produced consequences but no '
              'GameState was provided for a controlled commit.',
          executionResult: executionResult,
        );
      }

      final writeResult = SceneConsequenceRuntimeWriter(
        project: project,
        mapsById: {map.id: map},
      ).applyAll(gameState, pendingConsequences);
      if (!writeResult.success) {
        return SceneEventRuntimeHookResult.failed(
          errorCode: SceneEventRuntimeHookErrorCode.sceneConsequenceWriteFailed,
          sceneId: sceneId,
          message: writeResult.message ??
              'Scene V1 "$sceneId" consequence commit failed.',
          executionResult: executionResult,
          consequenceWriteResult: writeResult,
        );
      }

      return SceneEventRuntimeHookResult.completed(
        sceneId: sceneId,
        executionResult: executionResult,
        updatedGameState: writeResult.gameState,
        consequenceWriteResult: writeResult,
      );
    }

    return SceneEventRuntimeHookResult.failed(
      errorCode: SceneEventRuntimeHookErrorCode.sceneExecutionFailed,
      sceneId: sceneId,
      message: executionResult.message ??
          'Scene V1 "$sceneId" referenced by event "${event.id}" '
              'on map "${map.id}" failed during execution.',
      executionResult: executionResult,
    );
  }
}

SceneAsset? _findScene(ProjectManifest project, String sceneId) {
  for (final scene in project.scenes) {
    if (scene.id == sceneId) {
      return scene;
    }
  }
  return null;
}
