import '../../player/runtime_presentation_execution_controller.dart';

enum ScenePresentationCinematicRuntimeAwaitableStatus {
  completed,
  skipped,
  cancelled,
  failed,
}

enum ScenePresentationCinematicRuntimeAwaitableErrorCode {
  missingPresentationCinematicId,
  unknownPresentationCinematicId,
  playerFailed,
  cancelled,
  playbackFailed,
}

final class ScenePresentationCinematicRuntimeAwaitableResult {
  const ScenePresentationCinematicRuntimeAwaitableResult._({
    required this.status,
    this.errorCode,
    this.message,
    this.diagnosticCode,
    this.cancellationReason,
  });

  const ScenePresentationCinematicRuntimeAwaitableResult.completed()
      : this._(
          status: ScenePresentationCinematicRuntimeAwaitableStatus.completed,
        );

  const ScenePresentationCinematicRuntimeAwaitableResult.skipped()
      : this._(
          status: ScenePresentationCinematicRuntimeAwaitableStatus.skipped,
        );

  const ScenePresentationCinematicRuntimeAwaitableResult.cancelled({
    required RuntimePresentationCancellationReason cancellationReason,
  }) : this._(
          status: ScenePresentationCinematicRuntimeAwaitableStatus.cancelled,
          errorCode:
              ScenePresentationCinematicRuntimeAwaitableErrorCode.cancelled,
          message: 'Presentation cinematic playback was cancelled.',
          cancellationReason: cancellationReason,
        );

  const ScenePresentationCinematicRuntimeAwaitableResult.failed({
    required ScenePresentationCinematicRuntimeAwaitableErrorCode errorCode,
    required String message,
    String? diagnosticCode,
  }) : this._(
          status: ScenePresentationCinematicRuntimeAwaitableStatus.failed,
          errorCode: errorCode,
          message: message,
          diagnosticCode: diagnosticCode,
        );

  final ScenePresentationCinematicRuntimeAwaitableStatus status;
  final ScenePresentationCinematicRuntimeAwaitableErrorCode? errorCode;
  final String? message;
  final String? diagnosticCode;
  final RuntimePresentationCancellationReason? cancellationReason;

  bool get success =>
      status == ScenePresentationCinematicRuntimeAwaitableStatus.completed ||
      status == ScenePresentationCinematicRuntimeAwaitableStatus.skipped;

  String? get scenePortId => success ? 'completed' : null;
}
