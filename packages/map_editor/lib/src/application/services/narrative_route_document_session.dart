import 'package:flutter/foundation.dart';

import '../models/narrative_document_route.dart';
import 'narrative_document_session.dart';

enum NarrativeDocumentExitDecision { cancel, discard, save }

enum NarrativeDocumentExitStatus {
  exited,
  decisionRequired,
  cancelled,
  conflicted,
  failed,
}

enum NarrativeDocumentConflictAction { compare, saveAsNew, reloadExternal }

@immutable
final class NarrativeDocumentExitResult {
  const NarrativeDocumentExitResult({
    required this.status,
    this.source,
    this.code,
  });

  final NarrativeDocumentExitStatus status;
  final NarrativeDocumentSourceContext? source;
  final String? code;
}

typedef NarrativeDocumentSaveAsNew<T> =
    Future<NarrativeDocumentRoute?> Function(
      T document,
      NarrativeDocumentSourceContext source,
    );

final class NarrativeRouteDocumentSession<T> extends ChangeNotifier {
  NarrativeRouteDocumentSession({
    required this.route,
    required NarrativeDocumentSession<T> session,
    NarrativeDocumentRouteStore? routeStore,
  }) : _session = session,
       _routeStore = routeStore {
    if (_session.state.documentId != route.sessionDocumentId) {
      throw ArgumentError.value(
        _session.state.documentId,
        'session',
        'must own ${route.sessionDocumentId}',
      );
    }
    _session.addListener(_onSessionChanged);
  }

  final NarrativeDocumentRoute route;
  final NarrativeDocumentSession<T> _session;
  final NarrativeDocumentRouteStore? _routeStore;
  bool _disposed = false;

  NarrativeDocumentSessionState<T> get state => _session.state;
  NarrativeDocumentComparison<T>? get comparison => _session.comparison;

  Set<NarrativeDocumentConflictAction> get conflictActions =>
      state.status == NarrativeDocumentSessionStatus.conflicted
      ? const {
          NarrativeDocumentConflictAction.compare,
          NarrativeDocumentConflictAction.saveAsNew,
          NarrativeDocumentConflictAction.reloadExternal,
        }
      : const {};

  Future<void> initialize() async {
    await _session.initialize();
    await _routeStore?.write(route);
  }

  Future<bool> apply({
    required T document,
    required String operationId,
    required String label,
  }) => _session.apply(
    operationId: operationId,
    label: label,
    document: document,
  );

  Future<bool> undo() => _session.undo();

  Future<bool> redo() => _session.redo();

  Future<bool> save({required String operationId}) =>
      _session.save(operationId: operationId);

  void setAutosaveEnabled(bool enabled) {
    _session.setAutosaveEnabled(enabled);
  }

  Future<bool> reloadExternal() => _session.reloadExternal();

  Future<NarrativeDocumentRoute?> saveConflictAsNew(
    NarrativeDocumentSaveAsNew<T> saveAsNew,
  ) async {
    if (state.status != NarrativeDocumentSessionStatus.conflicted) return null;
    final nextRoute = await saveAsNew(state.document, route.source);
    if (nextRoute != null) await _routeStore?.write(nextRoute);
    return nextRoute;
  }

  Future<NarrativeDocumentExitResult> requestExit({
    NarrativeDocumentExitDecision? decision,
    String? operationId,
  }) async {
    if (!state.blocksNavigation) return _finishExit();
    if (decision == null) {
      return const NarrativeDocumentExitResult(
        status: NarrativeDocumentExitStatus.decisionRequired,
      );
    }
    switch (decision) {
      case NarrativeDocumentExitDecision.cancel:
        return const NarrativeDocumentExitResult(
          status: NarrativeDocumentExitStatus.cancelled,
        );
      case NarrativeDocumentExitDecision.discard:
        if (!await _session.discard()) {
          return NarrativeDocumentExitResult(
            status: state.status == NarrativeDocumentSessionStatus.conflicted
                ? NarrativeDocumentExitStatus.conflicted
                : NarrativeDocumentExitStatus.failed,
            code: state.code,
          );
        }
        return _finishExit();
      case NarrativeDocumentExitDecision.save:
        if (state.status == NarrativeDocumentSessionStatus.conflicted) {
          return NarrativeDocumentExitResult(
            status: NarrativeDocumentExitStatus.conflicted,
            code: state.code,
          );
        }
        final normalizedOperationId = operationId?.trim();
        if (normalizedOperationId == null || normalizedOperationId.isEmpty) {
          return const NarrativeDocumentExitResult(
            status: NarrativeDocumentExitStatus.failed,
            code: 'missingSaveOperationId',
          );
        }
        if (!await _session.save(operationId: normalizedOperationId)) {
          return NarrativeDocumentExitResult(
            status: state.status == NarrativeDocumentSessionStatus.conflicted
                ? NarrativeDocumentExitStatus.conflicted
                : NarrativeDocumentExitStatus.failed,
            code: state.code,
          );
        }
        return _finishExit();
    }
  }

  Future<NarrativeDocumentExitResult> _finishExit() async {
    try {
      await _routeStore?.clear();
      return NarrativeDocumentExitResult(
        status: NarrativeDocumentExitStatus.exited,
        source: route.source,
      );
    } on Object {
      return const NarrativeDocumentExitResult(
        status: NarrativeDocumentExitStatus.failed,
        code: 'routeRestorationCleanupFailed',
      );
    }
  }

  void _onSessionChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }
}
