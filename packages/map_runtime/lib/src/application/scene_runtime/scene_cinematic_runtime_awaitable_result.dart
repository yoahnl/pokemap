enum SceneCinematicRuntimeAwaitableStatus {
  completed,
  legacyBridgeAcknowledged,
  failed,
}

enum SceneCinematicRuntimeAwaitableErrorCode {
  missingCinematicId,
  unknownCinematicId,
  playerFailed,
}

final class SceneCinematicRuntimeAwaitableResult {
  const SceneCinematicRuntimeAwaitableResult._({
    required this.status,
    this.errorCode,
    this.message,
  });

  const SceneCinematicRuntimeAwaitableResult.completed()
      : this._(status: SceneCinematicRuntimeAwaitableStatus.completed);

  const SceneCinematicRuntimeAwaitableResult.legacyBridgeAcknowledged({
    required String message,
  }) : this._(
          status: SceneCinematicRuntimeAwaitableStatus.legacyBridgeAcknowledged,
          message: message,
        );

  const SceneCinematicRuntimeAwaitableResult.failed({
    required SceneCinematicRuntimeAwaitableErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneCinematicRuntimeAwaitableStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneCinematicRuntimeAwaitableStatus status;
  final SceneCinematicRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get success => status != SceneCinematicRuntimeAwaitableStatus.failed;

  String? get scenePortId {
    return switch (status) {
      SceneCinematicRuntimeAwaitableStatus.completed => 'completed',
      SceneCinematicRuntimeAwaitableStatus.legacyBridgeAcknowledged =>
        'completed',
      SceneCinematicRuntimeAwaitableStatus.failed => null,
    };
  }
}
