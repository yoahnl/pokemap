import 'dart:async';

import 'package:meta/meta.dart' show immutable;

import '../models/scene_structured_interaction.dart';

abstract interface class SceneStructuredInteractionPort {
  Stream<SceneInteractionRequest> get requests;

  Future<SceneInteractionResult> request(SceneInteractionRequest request);

  SceneInteractionResolution resolve(SceneInteractionResult result);

  SceneInteractionResolution cancel({
    required String requestId,
    required int revision,
    required SceneInteractionCancellationReason reason,
  });

  void close();
}

enum SceneInteractionResolutionStatus {
  accepted,
  unknownRequest,
  staleRevision,
  alreadyTerminal,
  kindMismatch,
  invalidResult,
}

@immutable
final class SceneInteractionResolution {
  SceneInteractionResolution({
    required this.status,
    List<SceneInteractionValidationIssue> validationIssues =
        const <SceneInteractionValidationIssue>[],
  }) : validationIssues = List<SceneInteractionValidationIssue>.unmodifiable(
         validationIssues,
       );

  final SceneInteractionResolutionStatus status;
  final List<SceneInteractionValidationIssue> validationIssues;

  bool get isAccepted => status == SceneInteractionResolutionStatus.accepted;
}

enum SceneInteractionPortErrorCode {
  activeRequestExists,
  staleRequestRevision,
  portClosed,
}

final class SceneInteractionPortException implements Exception {
  const SceneInteractionPortException(this.code);

  final SceneInteractionPortErrorCode code;

  @override
  String toString() => 'SceneInteractionPortException(${code.name})';
}

final class HeadlessSceneInteractionPort
    implements SceneStructuredInteractionPort {
  final StreamController<SceneInteractionRequest> _requestsController =
      StreamController<SceneInteractionRequest>.broadcast(sync: true);
  final Map<String, _PendingSceneInteraction> _pending =
      <String, _PendingSceneInteraction>{};
  final Map<String, int> _latestRevisionByRequestId = <String, int>{};
  bool _closed = false;

  @override
  Stream<SceneInteractionRequest> get requests => _requestsController.stream;

  List<SceneInteractionRequest> get pendingRequests =>
      List<SceneInteractionRequest>.unmodifiable(
        _pending.values.map((entry) => entry.request),
      );

  bool get isClosed => _closed;

  @override
  Future<SceneInteractionResult> request(SceneInteractionRequest request) {
    if (_closed) {
      return Future<SceneInteractionResult>.error(
        const SceneInteractionPortException(
          SceneInteractionPortErrorCode.portClosed,
        ),
      );
    }
    if (_pending.containsKey(request.requestId)) {
      return Future<SceneInteractionResult>.error(
        const SceneInteractionPortException(
          SceneInteractionPortErrorCode.activeRequestExists,
        ),
      );
    }
    final latestRevision = _latestRevisionByRequestId[request.requestId];
    if (latestRevision != null && request.revision <= latestRevision) {
      return Future<SceneInteractionResult>.error(
        const SceneInteractionPortException(
          SceneInteractionPortErrorCode.staleRequestRevision,
        ),
      );
    }

    final completer = Completer<SceneInteractionResult>();
    final timeout = request.timeout;
    final timer = timeout == null
        ? null
        : Timer(
            timeout,
            () => cancel(
              requestId: request.requestId,
              revision: request.revision,
              reason: SceneInteractionCancellationReason.timeout,
            ),
          );
    _pending[request.requestId] = _PendingSceneInteraction(
      request: request,
      completer: completer,
      timer: timer,
    );
    _latestRevisionByRequestId[request.requestId] = request.revision;
    _requestsController.add(request);
    return completer.future;
  }

  @override
  SceneInteractionResolution resolve(SceneInteractionResult result) {
    final pending = _pending[result.requestId];
    if (pending == null) {
      final latestRevision = _latestRevisionByRequestId[result.requestId];
      if (latestRevision == null || result.revision > latestRevision) {
        return SceneInteractionResolution(
          status: SceneInteractionResolutionStatus.unknownRequest,
        );
      }
      return SceneInteractionResolution(
        status: result.revision == latestRevision
            ? SceneInteractionResolutionStatus.alreadyTerminal
            : SceneInteractionResolutionStatus.staleRevision,
      );
    }
    if (result.revision != pending.request.revision) {
      return SceneInteractionResolution(
        status: SceneInteractionResolutionStatus.staleRevision,
      );
    }

    final issues = pending.request.validateResult(result);
    if (issues.isNotEmpty) {
      final isKindMismatch = issues.any(
        (issue) =>
            issue.code ==
            SceneInteractionValidationIssueCode.resultKindMismatch,
      );
      return SceneInteractionResolution(
        status: isKindMismatch
            ? SceneInteractionResolutionStatus.kindMismatch
            : SceneInteractionResolutionStatus.invalidResult,
        validationIssues: issues,
      );
    }

    _pending.remove(result.requestId);
    pending.timer?.cancel();
    pending.completer.complete(result);
    return SceneInteractionResolution(
      status: SceneInteractionResolutionStatus.accepted,
    );
  }

  @override
  SceneInteractionResolution cancel({
    required String requestId,
    required int revision,
    required SceneInteractionCancellationReason reason,
  }) {
    return resolve(
      SceneInteractionResult.cancelled(
        requestId: requestId,
        revision: revision,
        reason: reason,
      ),
    );
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    final requests = pendingRequests;
    for (final request in requests) {
      cancel(
        requestId: request.requestId,
        revision: request.revision,
        reason: SceneInteractionCancellationReason.disposed,
      );
    }
    _requestsController.close();
  }
}

final class _PendingSceneInteraction {
  const _PendingSceneInteraction({
    required this.request,
    required this.completer,
    required this.timer,
  });

  final SceneInteractionRequest request;
  final Completer<SceneInteractionResult> completer;
  final Timer? timer;
}
