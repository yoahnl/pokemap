import 'package:map_core/map_core.dart';

import 'scene_consequence_runtime_write_result.dart';

enum SceneEventRuntimeHookStatus {
  notHandled,
  completed,
  failed,
}

enum SceneEventRuntimeHookErrorCode {
  sceneTargetMissingScene,
  sceneTargetDiagnosticsFailed,
  sceneTargetRuntimePlanFailed,
  sceneExecutionFailed,
  sceneConsequenceWriteFailed,
}

final class SceneEventRuntimeHookResult {
  const SceneEventRuntimeHookResult._({
    required this.status,
    this.errorCode,
    this.sceneId,
    this.message,
    this.executionResult,
    this.updatedGameState,
    this.consequenceWriteResult,
  });

  const SceneEventRuntimeHookResult.notHandled()
      : this._(status: SceneEventRuntimeHookStatus.notHandled);

  const SceneEventRuntimeHookResult.completed({
    required String sceneId,
    required SceneRuntimeExecutionResult executionResult,
    GameState? updatedGameState,
    SceneConsequenceRuntimeWriteResult? consequenceWriteResult,
  }) : this._(
          status: SceneEventRuntimeHookStatus.completed,
          sceneId: sceneId,
          executionResult: executionResult,
          updatedGameState: updatedGameState,
          consequenceWriteResult: consequenceWriteResult,
        );

  const SceneEventRuntimeHookResult.failed({
    required SceneEventRuntimeHookErrorCode errorCode,
    required String sceneId,
    required String message,
    SceneRuntimeExecutionResult? executionResult,
    SceneConsequenceRuntimeWriteResult? consequenceWriteResult,
  }) : this._(
          status: SceneEventRuntimeHookStatus.failed,
          errorCode: errorCode,
          sceneId: sceneId,
          message: message,
          executionResult: executionResult,
          consequenceWriteResult: consequenceWriteResult,
        );

  final SceneEventRuntimeHookStatus status;
  final SceneEventRuntimeHookErrorCode? errorCode;
  final String? sceneId;
  final String? message;
  final SceneRuntimeExecutionResult? executionResult;
  final GameState? updatedGameState;
  final SceneConsequenceRuntimeWriteResult? consequenceWriteResult;

  bool get handled => status != SceneEventRuntimeHookStatus.notHandled;

  bool get success => status == SceneEventRuntimeHookStatus.completed;
}
