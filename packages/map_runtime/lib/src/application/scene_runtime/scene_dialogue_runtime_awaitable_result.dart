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
    this.errorCode,
    this.message,
  });

  const SceneDialogueRuntimeAwaitableResult.completed()
      : this._(status: SceneDialogueRuntimeAwaitableStatus.completed);

  const SceneDialogueRuntimeAwaitableResult.failed({
    required SceneDialogueRuntimeAwaitableErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneDialogueRuntimeAwaitableStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneDialogueRuntimeAwaitableStatus status;
  final SceneDialogueRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get success => status == SceneDialogueRuntimeAwaitableStatus.completed;

  String? get scenePortId {
    return switch (status) {
      SceneDialogueRuntimeAwaitableStatus.completed => 'completed',
      SceneDialogueRuntimeAwaitableStatus.failed => null,
    };
  }
}
