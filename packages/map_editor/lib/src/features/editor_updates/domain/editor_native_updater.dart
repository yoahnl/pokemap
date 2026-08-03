import 'editor_update_models.dart';

enum EditorNativeUpdateEventKind {
  cancelled,
  noUpdate,
  installing,
  restartRequested,
  failed,
}

final class EditorNativeUpdateEvent {
  const EditorNativeUpdateEvent._({
    required this.kind,
    required this.operationId,
    this.failure,
  });

  factory EditorNativeUpdateEvent.cancelled(String operationId) {
    return EditorNativeUpdateEvent._(
      kind: EditorNativeUpdateEventKind.cancelled,
      operationId: operationId,
    );
  }

  factory EditorNativeUpdateEvent.noUpdate(String operationId) {
    return EditorNativeUpdateEvent._(
      kind: EditorNativeUpdateEventKind.noUpdate,
      operationId: operationId,
    );
  }

  factory EditorNativeUpdateEvent.installing(String operationId) {
    return EditorNativeUpdateEvent._(
      kind: EditorNativeUpdateEventKind.installing,
      operationId: operationId,
    );
  }

  factory EditorNativeUpdateEvent.restartRequested(String operationId) {
    return EditorNativeUpdateEvent._(
      kind: EditorNativeUpdateEventKind.restartRequested,
      operationId: operationId,
    );
  }

  factory EditorNativeUpdateEvent.failed(
    String operationId,
    EditorUpdateFailure failure,
  ) {
    return EditorNativeUpdateEvent._(
      kind: EditorNativeUpdateEventKind.failed,
      operationId: operationId,
      failure: failure,
    );
  }

  final EditorNativeUpdateEventKind kind;
  final String operationId;
  final EditorUpdateFailure? failure;
}

abstract interface class EditorNativeUpdater {
  bool get isSupported;
  EditorNativeUpdaterCapabilities get capabilities;
  Stream<EditorNativeUpdateEvent> get events;
  Stream<void> get manualCheckRequests;

  Future<void> openUpdateFlow({
    required String operationId,
    required EditorUpdateRelease release,
  });

  Future<void> respondToRestart({
    required String operationId,
    required bool canRestart,
  });

  Future<void> dispose();
}
