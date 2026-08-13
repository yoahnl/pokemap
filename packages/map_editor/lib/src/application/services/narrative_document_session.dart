import 'dart:async';

import 'package:flutter/foundation.dart';

import 'narrative_undo_stack.dart';

/// Product-visible lifecycle for one Narrative Studio authoring document.
///
/// There is deliberately no optimistic `saved` alias: the state reaches
/// [saved] only after the gateway returned the exact durable revision.
enum NarrativeDocumentSessionStatus {
  dirty,
  saving,
  saved,
  failed,
  conflicted,
  recovered,
}

@immutable
final class NarrativeDocumentVersion<T> {
  const NarrativeDocumentVersion({
    required this.revision,
    required this.document,
  });

  final String revision;
  final T document;
}

sealed class NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaveResult();

  const factory NarrativeDocumentSaveResult.saved(
    NarrativeDocumentVersion<T> version,
  ) = NarrativeDocumentSaved<T>;

  const factory NarrativeDocumentSaveResult.failed({
    required String code,
    required String message,
  }) = NarrativeDocumentSaveFailed<T>;

  const factory NarrativeDocumentSaveResult.conflicted({
    required String code,
    required String message,
    required NarrativeDocumentVersion<T> external,
  }) = NarrativeDocumentSaveConflicted<T>;
}

final class NarrativeDocumentSaved<T> extends NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaved(this.version);

  final NarrativeDocumentVersion<T> version;
}

final class NarrativeDocumentSaveFailed<T>
    extends NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaveFailed({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

final class NarrativeDocumentSaveConflicted<T>
    extends NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaveConflicted({
    required this.code,
    required this.message,
    required this.external,
  });

  final String code;
  final String message;
  final NarrativeDocumentVersion<T> external;
}

/// Compare-and-swap boundary used by the document session.
abstract interface class NarrativeDocumentGateway<T> {
  Future<NarrativeDocumentVersion<T>> read();

  Future<NarrativeDocumentSaveResult<T>> save({
    required String expectedRevision,
    required T before,
    required T after,
    required String operationId,
  });
}

/// Durable crash-recovery envelope.
///
/// The full before/current/history snapshots make recovery deterministic. The
/// infrastructure codec is responsible for validating the concrete document.
@immutable
final class NarrativeDocumentRecoveryRecord<T> {
  const NarrativeDocumentRecoveryRecord({
    this.schemaVersion = 1,
    required this.documentId,
    required this.baseRevision,
    required this.baseline,
    required this.document,
    this.undoEntries = const [],
    this.redoEntries = const [],
  });

  final int schemaVersion;
  final String documentId;
  final String baseRevision;
  final T baseline;
  final T document;
  final List<NarrativeUndoEntry<T>> undoEntries;
  final List<NarrativeUndoEntry<T>> redoEntries;
}

abstract interface class NarrativeDocumentRecoveryStore<T> {
  Future<NarrativeDocumentRecoveryRecord<T>?> read();
  Future<void> write(NarrativeDocumentRecoveryRecord<T> record);
  Future<void> clear();
}

abstract interface class NarrativeDocumentAutosaveHandle {
  void cancel();
}

typedef NarrativeDocumentAutosaveScheduler = NarrativeDocumentAutosaveHandle
    Function(
  Duration delay,
  Future<void> Function() callback,
);

typedef NarrativeDocumentPersistenceGuard<T> = String? Function(T document);

@immutable
final class NarrativeDocumentComparison<T> {
  const NarrativeDocumentComparison({
    required this.baseline,
    required this.local,
    required this.external,
  });

  final T baseline;
  final T local;
  final T external;
}

@immutable
final class NarrativeDocumentSessionState<T> {
  const NarrativeDocumentSessionState({
    required this.documentId,
    required this.document,
    required this.baseline,
    required this.baselineRevision,
    required this.status,
    required this.history,
    required this.autosaveEnabled,
    required this.isInitialized,
    this.externalVersion,
    this.code,
    this.message,
  });

  final String documentId;
  final T document;
  final T baseline;
  final String? baselineRevision;
  final NarrativeDocumentSessionStatus status;
  final NarrativeUndoStack<T> history;
  final bool autosaveEnabled;
  final bool isInitialized;
  final NarrativeDocumentVersion<T>? externalVersion;
  final String? code;
  final String? message;

  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;
  bool get isDirty => document != baseline;

  /// Navigation must not silently discard an in-flight, failed or recovered
  /// edit even when an unusual failure left the snapshots equal.
  bool get blocksNavigation => status != NarrativeDocumentSessionStatus.saved;

  NarrativeDocumentSessionState<T> copyWith({
    T? document,
    T? baseline,
    Object? baselineRevision = _notProvided,
    NarrativeDocumentSessionStatus? status,
    NarrativeUndoStack<T>? history,
    bool? autosaveEnabled,
    bool? isInitialized,
    Object? externalVersion = _notProvided,
    Object? code = _notProvided,
    Object? message = _notProvided,
  }) {
    return NarrativeDocumentSessionState<T>(
      documentId: documentId,
      document: document ?? this.document,
      baseline: baseline ?? this.baseline,
      baselineRevision: identical(baselineRevision, _notProvided)
          ? this.baselineRevision
          : baselineRevision as String?,
      status: status ?? this.status,
      history: history ?? this.history,
      autosaveEnabled: autosaveEnabled ?? this.autosaveEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
      externalVersion: identical(externalVersion, _notProvided)
          ? this.externalVersion
          : externalVersion as NarrativeDocumentVersion<T>?,
      code: identical(code, _notProvided) ? this.code : code as String?,
      message:
          identical(message, _notProvided) ? this.message : message as String?,
    );
  }
}

const Object _notProvided = Object();

/// Stateful coordinator for safe Narrative Studio document editing.
///
/// Publication ordering is the central invariant:
/// 1. write/flush recovery evidence;
/// 2. publish the local document;
/// 3. persist through compare-and-swap;
/// 4. clear recovery only after the exact durable revision is confirmed.
final class NarrativeDocumentSession<T> extends ChangeNotifier {
  NarrativeDocumentSession({
    required String documentId,
    required T initialDocument,
    required NarrativeDocumentGateway<T> gateway,
    required NarrativeDocumentRecoveryStore<T> recoveryStore,
    this.autosaveDelay = const Duration(seconds: 3),
    NarrativeDocumentAutosaveScheduler? autosaveScheduler,
    NarrativeDocumentPersistenceGuard<T>? persistenceGuard,
    bool autosaveEnabled = false,
    int historyCapacity = 100,
  })  : assert(historyCapacity > 0),
        _gateway = gateway,
        _recoveryStore = recoveryStore,
        _historyCapacity = historyCapacity,
        _autosaveScheduler = autosaveScheduler ?? _scheduleWithTimer,
        _persistenceGuard = persistenceGuard,
        _state = NarrativeDocumentSessionState<T>(
          documentId: _requiredText(documentId, 'documentId'),
          document: initialDocument,
          baseline: initialDocument,
          baselineRevision: null,
          status: NarrativeDocumentSessionStatus.saved,
          history: NarrativeUndoStack<T>(capacity: historyCapacity),
          autosaveEnabled: autosaveEnabled,
          isInitialized: false,
        );

  final NarrativeDocumentGateway<T> _gateway;
  final NarrativeDocumentRecoveryStore<T> _recoveryStore;
  final int _historyCapacity;
  final NarrativeDocumentAutosaveScheduler _autosaveScheduler;
  NarrativeDocumentPersistenceGuard<T>? _persistenceGuard;
  final Duration autosaveDelay;

  NarrativeDocumentSessionState<T> _state;
  NarrativeDocumentAutosaveHandle? _autosaveHandle;
  Future<void>? _initialization;
  bool _disposed = false;
  int _operationGeneration = 0;
  int _autosaveSequence = 0;

  NarrativeDocumentSessionState<T> get state => _state;

  NarrativeDocumentComparison<T>? get comparison {
    final external = _state.externalVersion;
    if (external == null) return null;
    return NarrativeDocumentComparison<T>(
      baseline: _state.baseline,
      local: _state.document,
      external: external.document,
    );
  }

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final generation = _operationGeneration;
    try {
      final disk = await _gateway.read();
      final recovery = await _recoveryStore.read();
      if (!_canAdopt(generation)) return;

      if (recovery == null) {
        _publish(
          _state.copyWith(
            document: disk.document,
            baseline: disk.document,
            baselineRevision: disk.revision,
            status: NarrativeDocumentSessionStatus.saved,
            history: NarrativeUndoStack<T>(capacity: _historyCapacity),
            isInitialized: true,
            externalVersion: null,
            code: null,
            message: null,
          ),
        );
        return;
      }
      if (recovery.schemaVersion != 1 ||
          recovery.documentId.trim() != _state.documentId) {
        _publishFailure(
          code: 'invalidRecoveryRecord',
          message: 'The recovery journal does not belong to this document.',
          initialized: true,
        );
        return;
      }

      final history = NarrativeUndoStack<T>(
        undoEntries: recovery.undoEntries,
        redoEntries: recovery.redoEntries,
        capacity: _historyCapacity,
      );
      if (recovery.baseRevision == disk.revision) {
        _publish(
          _state.copyWith(
            document: recovery.document,
            baseline: recovery.baseline,
            baselineRevision: recovery.baseRevision,
            status: NarrativeDocumentSessionStatus.recovered,
            history: history,
            isInitialized: true,
            externalVersion: null,
            code: 'recoveryRestored',
            message: 'Recovered unsaved narrative changes.',
          ),
        );
        _scheduleAutosaveIfNeeded();
        return;
      }
      if (recovery.document == disk.document) {
        await _recoveryStore.clear();
        if (!_canAdopt(generation)) return;
        _publish(
          _state.copyWith(
            document: disk.document,
            baseline: disk.document,
            baselineRevision: disk.revision,
            status: NarrativeDocumentSessionStatus.saved,
            history: NarrativeUndoStack<T>(capacity: _historyCapacity),
            isInitialized: true,
            externalVersion: null,
            code: null,
            message: null,
          ),
        );
        return;
      }

      _publish(
        _state.copyWith(
          document: recovery.document,
          baseline: recovery.baseline,
          baselineRevision: recovery.baseRevision,
          status: NarrativeDocumentSessionStatus.conflicted,
          history: history,
          isInitialized: true,
          externalVersion: disk,
          code: 'externalRevisionConflict',
          message: 'The project changed after the local recovery snapshot.',
        ),
      );
    } on Object catch (error) {
      if (!_canAdopt(generation)) return;
      _publishFailure(
        code: 'sessionInitializationFailed',
        message: 'The narrative document session could not start: $error',
        initialized: true,
      );
    }
  }

  Future<bool> apply({
    required String operationId,
    required String label,
    required T document,
  }) async {
    if (!_state.isInitialized ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted ||
        _disposed) {
      return false;
    }
    if (document == _state.document) return true;

    late final NarrativeUndoStack<T> history;
    try {
      history = _state.history.record(
        operationId: operationId,
        label: label,
        before: _state.document,
        after: document,
      );
    } on Object catch (error) {
      _publishFailure(
        code: 'invalidEditIntent',
        message: 'The edit intention is invalid: $error',
      );
      return false;
    }
    final candidate = _state.copyWith(
      document: document,
      status: NarrativeDocumentSessionStatus.dirty,
      history: history,
      externalVersion: null,
      code: null,
      message: 'Narrative changes are waiting to be saved.',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> undo() async {
    if (!_canMutateHistory()) return false;
    late final NarrativeUndoTransition<T>? transition;
    try {
      transition = _state.history.undo(_state.document);
    } on Object catch (error) {
      _publishFailure(
        code: 'undoDocumentDrift',
        message: 'Undo was blocked because the document drifted: $error',
      );
      return false;
    }
    if (transition == null) return false;
    final candidate = _state.copyWith(
      document: transition.document,
      status: transition.document == _state.baseline
          ? NarrativeDocumentSessionStatus.saved
          : NarrativeDocumentSessionStatus.dirty,
      history: transition.stack,
      externalVersion: null,
      code: null,
      message: 'Undo: ${transition.entry.label}',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> redo() async {
    if (!_canMutateHistory()) return false;
    late final NarrativeUndoTransition<T>? transition;
    try {
      transition = _state.history.redo(_state.document);
    } on Object catch (error) {
      _publishFailure(
        code: 'redoDocumentDrift',
        message: 'Redo was blocked because the document drifted: $error',
      );
      return false;
    }
    if (transition == null) return false;
    final candidate = _state.copyWith(
      document: transition.document,
      status: transition.document == _state.baseline
          ? NarrativeDocumentSessionStatus.saved
          : NarrativeDocumentSessionStatus.dirty,
      history: transition.stack,
      externalVersion: null,
      code: null,
      message: 'Redo: ${transition.entry.label}',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> save({required String operationId}) async {
    if (!_state.isInitialized ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted) {
      return false;
    }
    final baselineRevision = _state.baselineRevision;
    if (baselineRevision == null) return false;
    if (!_state.isDirty) {
      if (_state.status == NarrativeDocumentSessionStatus.recovered) {
        try {
          await _recoveryStore.clear();
          _publish(_state.copyWith(
            status: NarrativeDocumentSessionStatus.saved,
            code: null,
            message: null,
          ));
        } on Object catch (error) {
          _publishFailure(
            code: 'recoveryCleanupFailed',
            message: 'The stale recovery journal could not be cleared: $error',
          );
          return false;
        }
      }
      return true;
    }

    final persistenceIssue = _persistenceGuard?.call(_state.document);
    if (persistenceIssue != null) {
      _publish(
        _state.copyWith(
          status: NarrativeDocumentSessionStatus.dirty,
          code: 'persistenceValidationFailed',
          message: persistenceIssue,
        ),
      );
      return false;
    }

    final normalizedOperationId = _requiredText(operationId, 'operationId');
    _cancelAutosave();
    final generation = ++_operationGeneration;
    final savingSnapshot = _state;
    _publish(
      _state.copyWith(
        status: NarrativeDocumentSessionStatus.saving,
        code: null,
        message: 'Saving narrative changes…',
      ),
    );
    try {
      final result = await _gateway.save(
        expectedRevision: baselineRevision,
        before: savingSnapshot.baseline,
        after: savingSnapshot.document,
        operationId: normalizedOperationId,
      );
      if (!_canAdopt(generation)) return false;
      return switch (result) {
        NarrativeDocumentSaved<T>(:final version) =>
          await _adoptSaved(version, savingSnapshot),
        NarrativeDocumentSaveFailed<T>(:final code, :final message) =>
          _adoptSaveFailure(
            savingSnapshot,
            code: code,
            message: message,
          ),
        NarrativeDocumentSaveConflicted<T>(
          :final code,
          :final message,
          :final external,
        ) =>
          _adoptConflict(
            savingSnapshot,
            code: code,
            message: message,
            external: external,
          ),
      };
    } on Object catch (error) {
      if (!_canAdopt(generation)) return false;
      return _adoptSaveFailure(
        savingSnapshot,
        code: 'unexpectedSaveFailure',
        message: 'The narrative document could not be saved: $error',
      );
    }
  }

  Future<bool> refreshBaseline() async {
    if (!_state.isInitialized ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted) {
      return false;
    }
    _cancelAutosave();
    final generation = ++_operationGeneration;
    try {
      final external = await _gateway.read();
      if (!_canAdopt(generation)) return false;
      if (external.document != _state.baseline) {
        return _adoptConflict(
          _state,
          code: 'staleDocumentRevision',
          message: 'The durable document changed while the session was open.',
          external: external,
        );
      }
      if (external.revision == _state.baselineRevision) {
        _scheduleAutosaveIfNeeded();
        return true;
      }
      return await _commitLocalCandidate(
        _state.copyWith(
          baseline: external.document,
          baselineRevision: external.revision,
          status: _state.document == external.document
              ? NarrativeDocumentSessionStatus.saved
              : NarrativeDocumentSessionStatus.dirty,
          externalVersion: null,
          code: null,
          message: 'The durable revision was refreshed.',
        ),
      );
    } on Object catch (error) {
      if (_canAdopt(generation)) {
        _publishFailure(
          code: 'baselineRefreshFailed',
          message: 'The durable document could not be refreshed: $error',
        );
      }
      return false;
    }
  }

  Future<bool> _adoptSaved(
    NarrativeDocumentVersion<T> version,
    NarrativeDocumentSessionState<T> savingSnapshot,
  ) async {
    if (version.document != savingSnapshot.document) {
      return _adoptSaveFailure(
        savingSnapshot,
        code: 'savedDocumentMismatch',
        message: 'The durable document does not match the requested snapshot.',
      );
    }
    final saved = savingSnapshot.copyWith(
      document: version.document,
      baseline: version.document,
      baselineRevision: version.revision,
      status: NarrativeDocumentSessionStatus.saved,
      externalVersion: null,
      code: null,
      message: 'Narrative changes saved.',
    );
    try {
      // Recovery is cleared only after the durable revision above is known.
      await _recoveryStore.clear();
      _publish(saved);
      return true;
    } on Object catch (error) {
      _publish(
        saved.copyWith(
          status: NarrativeDocumentSessionStatus.recovered,
          code: 'recoveryCleanupFailed',
          message: 'The document is durable but its recovery journal remains: '
              '$error',
        ),
      );
      return false;
    }
  }

  bool _adoptSaveFailure(
    NarrativeDocumentSessionState<T> savingSnapshot, {
    required String code,
    required String message,
  }) {
    _publish(
      savingSnapshot.copyWith(
        status: NarrativeDocumentSessionStatus.failed,
        code: code,
        message: message,
      ),
    );
    return false;
  }

  bool _adoptConflict(
    NarrativeDocumentSessionState<T> savingSnapshot, {
    required String code,
    required String message,
    required NarrativeDocumentVersion<T> external,
  }) {
    _publish(
      savingSnapshot.copyWith(
        status: NarrativeDocumentSessionStatus.conflicted,
        externalVersion: external,
        code: code,
        message: message,
      ),
    );
    return false;
  }

  Future<bool> keepLocal() async {
    final external = _state.externalVersion;
    if (_state.status != NarrativeDocumentSessionStatus.conflicted ||
        external == null ||
        _disposed) {
      return false;
    }
    final candidate = _state.copyWith(
      baseline: external.document,
      baselineRevision: external.revision,
      status: NarrativeDocumentSessionStatus.dirty,
      externalVersion: null,
      code: null,
      message: 'Local changes kept on top of the external revision.',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> rebaseConflict({
    required T Function(T local, T external) merge,
    required String operationId,
    required String label,
  }) async {
    final external = _state.externalVersion;
    if (_state.status != NarrativeDocumentSessionStatus.conflicted ||
        external == null ||
        _disposed) {
      return false;
    }
    final document = merge(_state.document, external.document);
    var history = NarrativeUndoStack<T>(capacity: _historyCapacity);
    if (document != external.document) {
      history = history.record(
        operationId: _requiredText(operationId, 'operationId'),
        label: _requiredText(label, 'label'),
        before: external.document,
        after: document,
      );
    }
    final candidate = _state.copyWith(
      document: document,
      baseline: external.document,
      baselineRevision: external.revision,
      status: document == external.document
          ? NarrativeDocumentSessionStatus.saved
          : NarrativeDocumentSessionStatus.dirty,
      history: history,
      externalVersion: null,
      code: null,
      message: document == external.document
          ? 'External version kept.'
          : 'Local changes kept on top of the external revision.',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> reloadExternal() async {
    final external = _state.externalVersion;
    if (_state.status != NarrativeDocumentSessionStatus.conflicted ||
        external == null ||
        _disposed) {
      return false;
    }
    final history = _state.history.record(
      operationId: 'reload_external_${++_autosaveSequence}',
      label: 'Recharger la version externe',
      before: _state.document,
      after: external.document,
    );
    try {
      await _recoveryStore.clear();
    } on Object catch (error) {
      _publishFailure(
        code: 'recoveryCleanupFailed',
        message: 'The external version could not be adopted safely: $error',
      );
      return false;
    }
    _publish(
      _state.copyWith(
        document: external.document,
        baseline: external.document,
        baselineRevision: external.revision,
        status: NarrativeDocumentSessionStatus.saved,
        history: history,
        externalVersion: null,
        code: null,
        message: 'External narrative version reloaded.',
      ),
    );
    return true;
  }

  Future<bool> discard() async {
    if (!_state.isInitialized ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving) {
      return false;
    }
    final external = _state.externalVersion;
    var baseline = external?.document ?? _state.baseline;
    var revision = external?.revision ?? _state.baselineRevision;
    if (revision == null) {
      // Initialization may have failed while decoding the recovery journal,
      // before a durable revision could be adopted. Explicit discard is the
      // user's authorization to clear that evidence and restart from disk.
      try {
        final disk = await _gateway.read();
        if (_disposed) return false;
        baseline = disk.document;
        revision = disk.revision;
      } on Object catch (error) {
        _publishFailure(
          code: 'discardReloadFailed',
          message: 'The durable narrative document could not be reloaded: '
              '$error',
        );
        return false;
      }
    }
    try {
      await _recoveryStore.clear();
    } on Object catch (error) {
      _publishFailure(
        code: 'recoveryCleanupFailed',
        message: 'Local changes could not be discarded safely: $error',
      );
      return false;
    }
    _cancelAutosave();
    _publish(
      _state.copyWith(
        document: baseline,
        baseline: baseline,
        baselineRevision: revision,
        status: NarrativeDocumentSessionStatus.saved,
        history: NarrativeUndoStack<T>(capacity: _historyCapacity),
        externalVersion: null,
        code: null,
        message: 'Local narrative changes discarded.',
      ),
    );
    return true;
  }

  void setAutosaveEnabled(bool enabled) {
    if (_disposed || _state.autosaveEnabled == enabled) return;
    if (!enabled) _cancelAutosave();
    _publish(_state.copyWith(autosaveEnabled: enabled));
    if (enabled) _scheduleAutosaveIfNeeded();
  }

  void setPersistenceGuard(
    NarrativeDocumentPersistenceGuard<T>? persistenceGuard,
  ) {
    if (_disposed || identical(_persistenceGuard, persistenceGuard)) return;
    _cancelAutosave();
    _persistenceGuard = persistenceGuard;
    _scheduleAutosaveIfNeeded();
  }

  void reevaluatePersistenceGuard() {
    if (_disposed) return;
    _cancelAutosave();
    _scheduleAutosaveIfNeeded();
  }

  bool _canMutateHistory() {
    return _state.isInitialized &&
        !_disposed &&
        _state.status != NarrativeDocumentSessionStatus.saving &&
        _state.status != NarrativeDocumentSessionStatus.conflicted;
  }

  Future<bool> _commitLocalCandidate(
    NarrativeDocumentSessionState<T> candidate,
  ) async {
    _cancelAutosave();
    try {
      if (candidate.document == candidate.baseline) {
        await _recoveryStore.clear();
      } else {
        await _recoveryStore.write(_recordFor(candidate));
      }
      if (_disposed) return false;
      _publish(candidate);
      _scheduleAutosaveIfNeeded();
      return true;
    } on Object catch (error) {
      if (!_disposed) {
        _publishFailure(
          code: 'recoveryWriteFailed',
          message: 'The edit was not published because recovery evidence '
              'could not be written: $error',
        );
      }
      return false;
    }
  }

  NarrativeDocumentRecoveryRecord<T> _recordFor(
    NarrativeDocumentSessionState<T> candidate,
  ) {
    final revision = candidate.baselineRevision;
    if (revision == null) {
      throw StateError('Cannot journal a document without a base revision.');
    }
    return NarrativeDocumentRecoveryRecord<T>(
      documentId: candidate.documentId,
      baseRevision: revision,
      baseline: candidate.baseline,
      document: candidate.document,
      undoEntries: candidate.history.undoEntries,
      redoEntries: candidate.history.redoEntries,
    );
  }

  void _scheduleAutosaveIfNeeded() {
    if (!_state.autosaveEnabled ||
        !_state.isDirty ||
        _persistenceGuard?.call(_state.document) != null ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted) {
      return;
    }
    _cancelAutosave();
    final sequence = ++_autosaveSequence;
    _autosaveHandle = _autosaveScheduler(autosaveDelay, () async {
      _autosaveHandle = null;
      if (_disposed || sequence != _autosaveSequence) return;
      await save(
        operationId: 'autosave_${_state.documentId}_$sequence',
      );
    });
  }

  void _cancelAutosave() {
    _autosaveHandle?.cancel();
    _autosaveHandle = null;
  }

  bool _canAdopt(int generation) {
    return !_disposed && generation == _operationGeneration;
  }

  void _publishFailure({
    required String code,
    required String message,
    bool? initialized,
  }) {
    _publish(
      _state.copyWith(
        status: NarrativeDocumentSessionStatus.failed,
        isInitialized: initialized,
        code: code,
        message: message,
      ),
    );
  }

  void _publish(NarrativeDocumentSessionState<T> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operationGeneration++;
    _cancelAutosave();
    super.dispose();
  }
}

NarrativeDocumentAutosaveHandle _scheduleWithTimer(
  Duration delay,
  Future<void> Function() callback,
) {
  return _TimerAutosaveHandle(Timer(delay, () => unawaited(callback())));
}

final class _TimerAutosaveHandle implements NarrativeDocumentAutosaveHandle {
  const _TimerAutosaveHandle(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}
