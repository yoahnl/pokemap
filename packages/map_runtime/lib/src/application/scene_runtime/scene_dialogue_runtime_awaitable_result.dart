enum SceneDialogueRuntimeAwaitableStatus {
  completed,
  failed,
}

enum SceneDialogueRuntimeAwaitableErrorCode {
  missingDialogueId,
  launcherFailed,
  cancelled,
  unsupportedOutcome,
}

final class SceneDialogueRuntimeAwaitableResult {
  const SceneDialogueRuntimeAwaitableResult._({
    required this.status,
    this.outcomeId,
    this.errorCode,
    this.message,
  });

  const SceneDialogueRuntimeAwaitableResult.completed({String? outcomeId})
      : this._(
          status: SceneDialogueRuntimeAwaitableStatus.completed,
          outcomeId: outcomeId,
        );

  const SceneDialogueRuntimeAwaitableResult.failed({
    required SceneDialogueRuntimeAwaitableErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneDialogueRuntimeAwaitableStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneDialogueRuntimeAwaitableStatus status;
  final String? outcomeId;
  final SceneDialogueRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get success => status == SceneDialogueRuntimeAwaitableStatus.completed;

  String? get scenePortId {
    return switch (status) {
      SceneDialogueRuntimeAwaitableStatus.completed => outcomeId ?? 'completed',
      SceneDialogueRuntimeAwaitableStatus.failed => null,
    };
  }
}
