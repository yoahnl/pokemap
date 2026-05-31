import 'package:map_core/map_core.dart';

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
}

final class SceneEventRuntimeHookResult {
  const SceneEventRuntimeHookResult._({
    required this.status,
    this.errorCode,
    this.sceneId,
    this.message,
    this.executionResult,
  });

  const SceneEventRuntimeHookResult.notHandled()
      : this._(status: SceneEventRuntimeHookStatus.notHandled);

  const SceneEventRuntimeHookResult.completed({
    required String sceneId,
    required SceneRuntimeExecutionResult executionResult,
  }) : this._(
          status: SceneEventRuntimeHookStatus.completed,
          sceneId: sceneId,
          executionResult: executionResult,
        );

  const SceneEventRuntimeHookResult.failed({
    required SceneEventRuntimeHookErrorCode errorCode,
    required String sceneId,
    required String message,
    SceneRuntimeExecutionResult? executionResult,
  }) : this._(
          status: SceneEventRuntimeHookStatus.failed,
          errorCode: errorCode,
          sceneId: sceneId,
          message: message,
          executionResult: executionResult,
        );

  final SceneEventRuntimeHookStatus status;
  final SceneEventRuntimeHookErrorCode? errorCode;
  final String? sceneId;
  final String? message;
  final SceneRuntimeExecutionResult? executionResult;

  bool get handled => status != SceneEventRuntimeHookStatus.notHandled;

  bool get success => status == SceneEventRuntimeHookStatus.completed;
}
