import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';
import 'smart_tile_draft_persistence_state.dart';

abstract interface class SmartTileDraftDebounceTimer {
  bool get isActive;

  void cancel();
}

abstract interface class SmartTileDraftDebounceScheduler {
  SmartTileDraftDebounceTimer schedule(
    Duration delay,
    void Function() callback,
  );
}

final class DartSmartTileDraftDebounceScheduler
    implements SmartTileDraftDebounceScheduler {
  const DartSmartTileDraftDebounceScheduler();

  @override
  SmartTileDraftDebounceTimer schedule(
    Duration delay,
    void Function() callback,
  ) =>
      _DartSmartTileDraftDebounceTimer(Timer(delay, callback));
}

final class _DartSmartTileDraftDebounceTimer
    implements SmartTileDraftDebounceTimer {
  const _DartSmartTileDraftDebounceTimer(this._timer);

  final Timer _timer;

  @override
  bool get isActive => _timer.isActive;

  @override
  void cancel() => _timer.cancel();
}

final class SmartTileDraftPersistenceApplyResult {
  const SmartTileDraftPersistenceApplyResult({
    required this.snapshotRevision,
  });

  final String snapshotRevision;
}

final class SmartTileDraftCanonicalSnapshot {
  const SmartTileDraftCanonicalSnapshot({
    required this.snapshotRevision,
    required this.manifest,
    required this.draft,
  });

  final String snapshotRevision;
  final ProjectManifest manifest;
  final ProjectSmartTileAuthoringDraft? draft;
}

abstract interface class SmartTileDraftPersistenceGateway {
  Future<SmartTileDraftPersistenceApplyResult> upsert({
    required String projectRootPath,
    required ProjectSmartTileAuthoringDraft draft,
    required String expectedRevision,
    required String idempotencyKey,
    required String operationId,
  });

  Future<SmartTileDraftCanonicalSnapshot> load({
    required String projectRootPath,
    required String draftId,
  });
}

/// Thin editor transport over the canonical map_authoring plan/apply/query API.
final class CanonicalSmartTileDraftPersistenceGateway
    implements SmartTileDraftPersistenceGateway {
  const CanonicalSmartTileDraftPersistenceGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  @override
  Future<SmartTileDraftPersistenceApplyResult> upsert({
    required String projectRootPath,
    required ProjectSmartTileAuthoringDraft draft,
    required String expectedRevision,
    required String idempotencyKey,
    required String operationId,
  }) async {
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: 'smart_tile.preset.draft.upsert',
      parameters: <String, Object?>{'draft': draft.toJson()},
      idempotencyKey: idempotencyKey,
      requestId: idempotencyKey,
      expectedRevision: expectedRevision,
    );
    final applied = await _mutations.apply(
      plan,
      operationId: operationId,
    );
    return SmartTileDraftPersistenceApplyResult(
      snapshotRevision: applied.snapshotRevision,
    );
  }

  @override
  Future<SmartTileDraftCanonicalSnapshot> load({
    required String projectRootPath,
    required String draftId,
  }) async {
    final session = await _queries.open(projectRootPath);
    final draft = session.manifest.smartTileCatalog.drafts
        .where((candidate) => candidate.id == draftId)
        .firstOrNull;
    return SmartTileDraftCanonicalSnapshot(
      snapshotRevision: session.snapshotRevision,
      manifest: session.manifest,
      draft: draft,
    );
  }
}

typedef SmartTileDraftPersistenceListener = void Function(
  SmartTileDraftPersistenceState state,
);
typedef SmartTileDraftCanonicalSnapshotListener = void Function(
  SmartTileDraftCanonicalSnapshot snapshot,
);

/// Serial, latest-wins autosave for one durable Studio draft.
///
/// This class performs no filesystem IO. It only invokes a canonical gateway,
/// making debounce, generation handling, CAS, retry and reopen deterministic
/// in unit tests.
final class SmartTileDraftPersistenceCoordinator {
  SmartTileDraftPersistenceCoordinator({
    required this.projectRootPath,
    required ProjectSmartTileAuthoringDraft initialDraft,
    required String initialSnapshotRevision,
    required SmartTileDraftPersistenceGateway gateway,
    SmartTileDraftDebounceScheduler scheduler =
        const DartSmartTileDraftDebounceScheduler(),
    Duration debounce = const Duration(milliseconds: 500),
    SmartTileDraftPersistenceListener? onStateChanged,
    SmartTileDraftCanonicalSnapshotListener? onCanonicalSnapshot,
    bool initiallySaved = false,
  })  : _draft = initialDraft,
        _gateway = gateway,
        _scheduler = scheduler,
        _debounce = debounce,
        _onStateChanged = onStateChanged,
        _onCanonicalSnapshot = onCanonicalSnapshot,
        _savedFingerprint = initiallySaved
            ? smartTileDraftCanonicalFingerprint(initialDraft)
            : null,
        _state = SmartTileDraftPersistenceState(
          phase: initiallySaved
              ? SmartTileDraftPersistencePhase.saved
              : SmartTileDraftPersistencePhase.localOnly,
          generation: 0,
          persistedGeneration: 0,
          snapshotRevision: initialSnapshotRevision,
          fingerprint: initiallySaved
              ? smartTileDraftCanonicalFingerprint(initialDraft)
              : null,
        ) {
    if (debounce <= Duration.zero) {
      throw ArgumentError.value(debounce, 'debounce', 'must be positive');
    }
  }

  static Future<SmartTileDraftPersistenceCoordinator> reopen({
    required String projectRootPath,
    required String draftId,
    required SmartTileDraftPersistenceGateway gateway,
    SmartTileDraftDebounceScheduler scheduler =
        const DartSmartTileDraftDebounceScheduler(),
    Duration debounce = const Duration(milliseconds: 500),
    SmartTileDraftPersistenceListener? onStateChanged,
    SmartTileDraftCanonicalSnapshotListener? onCanonicalSnapshot,
  }) async {
    final snapshot = await gateway.load(
      projectRootPath: projectRootPath,
      draftId: draftId,
    );
    final draft = snapshot.draft;
    if (draft == null) {
      throw StateError('Unknown canonical Smart Tile draft "$draftId".');
    }
    onCanonicalSnapshot?.call(snapshot);
    return SmartTileDraftPersistenceCoordinator(
      projectRootPath: projectRootPath,
      initialDraft: draft,
      initialSnapshotRevision: snapshot.snapshotRevision,
      gateway: gateway,
      scheduler: scheduler,
      debounce: debounce,
      onStateChanged: onStateChanged,
      onCanonicalSnapshot: onCanonicalSnapshot,
      initiallySaved: true,
    );
  }

  static Future<SmartTileDraftPersistenceCoordinator> attach({
    required String projectRootPath,
    required ProjectSmartTileAuthoringDraft localDraft,
    required SmartTileDraftPersistenceGateway gateway,
    SmartTileDraftDebounceScheduler scheduler =
        const DartSmartTileDraftDebounceScheduler(),
    Duration debounce = const Duration(milliseconds: 500),
    SmartTileDraftPersistenceListener? onStateChanged,
    SmartTileDraftCanonicalSnapshotListener? onCanonicalSnapshot,
  }) async {
    final snapshot = await gateway.load(
      projectRootPath: projectRootPath,
      draftId: localDraft.id,
    );
    onCanonicalSnapshot?.call(snapshot);
    return SmartTileDraftPersistenceCoordinator(
      projectRootPath: projectRootPath,
      initialDraft: snapshot.draft ?? localDraft,
      initialSnapshotRevision: snapshot.snapshotRevision,
      gateway: gateway,
      scheduler: scheduler,
      debounce: debounce,
      onStateChanged: onStateChanged,
      onCanonicalSnapshot: onCanonicalSnapshot,
      initiallySaved: snapshot.draft != null,
    );
  }

  final String projectRootPath;
  final SmartTileDraftPersistenceGateway _gateway;
  final SmartTileDraftDebounceScheduler _scheduler;
  final Duration _debounce;
  final SmartTileDraftPersistenceListener? _onStateChanged;
  final SmartTileDraftCanonicalSnapshotListener? _onCanonicalSnapshot;

  ProjectSmartTileAuthoringDraft _draft;
  SmartTileDraftPersistenceState _state;
  String? _savedFingerprint;
  SmartTileDraftDebounceTimer? _timer;
  Future<void>? _drainFuture;
  bool _closed = false;

  ProjectSmartTileAuthoringDraft get draft => _draft;
  SmartTileDraftPersistenceState get state => _state;

  void updateDraft(ProjectSmartTileAuthoringDraft draft) {
    _requireOpen();
    if (draft.id != _draft.id) {
      throw ArgumentError.value(
        draft.id,
        'draft.id',
        'a coordinator owns exactly one draft id',
      );
    }
    final fingerprint = smartTileDraftCanonicalFingerprint(draft);
    _draft = draft;
    final generation = _state.generation + 1;
    if (_drainFuture == null && fingerprint == _savedFingerprint) {
      _cancelTimer();
      _emit(
        _state.copyWith(
          phase: SmartTileDraftPersistencePhase.saved,
          generation: generation,
          persistedGeneration: generation,
          fingerprint: fingerprint,
          clearError: true,
        ),
      );
      return;
    }
    final blocked = _state.phase == SmartTileDraftPersistencePhase.conflict ||
        _state.phase == SmartTileDraftPersistencePhase.failed;
    _emit(
      _state.copyWith(
        phase: blocked ? _state.phase : SmartTileDraftPersistencePhase.dirty,
        generation: generation,
        fingerprint: fingerprint,
        clearError: !blocked,
      ),
    );
    if (!blocked) _schedule();
  }

  Future<SmartTileDraftPersistenceState> flush() async {
    _requireOpen();
    _cancelTimer();
    if (_state.phase == SmartTileDraftPersistencePhase.dirty ||
        _state.phase == SmartTileDraftPersistencePhase.saving) {
      await _drain();
    }
    return _state;
  }

  Future<SmartTileDraftPersistenceState> retry({
    String? expectedRevision,
  }) async {
    _requireOpen();
    if (!_state.canRetry) {
      throw StateError('The Smart Tile draft is not waiting for a retry.');
    }
    if (_state.phase == SmartTileDraftPersistencePhase.conflict &&
        (expectedRevision == null || expectedRevision.trim().isEmpty)) {
      throw ArgumentError(
        'A fresh snapshot revision is required after a CAS conflict.',
      );
    }
    _emit(
      _state.copyWith(
        phase: SmartTileDraftPersistencePhase.dirty,
        snapshotRevision: expectedRevision?.trim(),
        clearError: true,
      ),
    );
    return flush();
  }

  Future<void> close() async {
    if (_closed) return;
    await flush();
    _cancelTimer();
    _closed = true;
  }

  void _schedule() {
    _cancelTimer();
    _timer = _scheduler.schedule(_debounce, () {
      _timer = null;
      unawaited(_drain());
    });
  }

  Future<void> _drain() {
    final active = _drainFuture;
    if (active != null) return active;
    final completer = Completer<void>();
    _drainFuture = completer.future;
    unawaited(_runDrainLoop(completer));
    return completer.future;
  }

  Future<void> _runDrainLoop(Completer<void> completer) async {
    try {
      while (_state.phase == SmartTileDraftPersistencePhase.dirty) {
        final generation = _state.generation;
        final draft = _draft;
        final fingerprint = smartTileDraftCanonicalFingerprint(draft);
        final expectedRevision = _state.snapshotRevision;
        _emit(
          _state.copyWith(
            phase: SmartTileDraftPersistencePhase.saving,
            fingerprint: fingerprint,
            clearError: true,
          ),
        );
        try {
          final applied = await _gateway.upsert(
            projectRootPath: projectRootPath,
            draft: draft,
            expectedRevision: expectedRevision,
            idempotencyKey: 'smart-tile-draft:${draft.id}:$fingerprint',
            operationId: 'smart-tile-draft-apply:${draft.id}:$fingerprint',
          );
          final canonical = await _gateway.load(
            projectRootPath: projectRootPath,
            draftId: draft.id,
          );
          final canonicalDraft = canonical.draft;
          if (canonicalDraft == null) {
            throw StateError(
              'The canonical Smart Tile draft disappeared after apply.',
            );
          }
          _onCanonicalSnapshot?.call(canonical);
          if (_state.generation == generation) {
            _draft = canonicalDraft;
            _savedFingerprint =
                smartTileDraftCanonicalFingerprint(canonicalDraft);
            _emit(
              _state.copyWith(
                phase: SmartTileDraftPersistencePhase.saved,
                persistedGeneration: generation,
                snapshotRevision: canonical.snapshotRevision,
                fingerprint: _savedFingerprint,
                clearError: true,
              ),
            );
          } else {
            _emit(
              _state.copyWith(
                phase: SmartTileDraftPersistencePhase.dirty,
                persistedGeneration: generation,
                snapshotRevision: applied.snapshotRevision,
                fingerprint: smartTileDraftCanonicalFingerprint(_draft),
                clearError: true,
              ),
            );
          }
        } on Object catch (error) {
          final failure = EditorAuthoringMutationFailure.capture(error);
          final conflict = _isRevisionConflict(failure.code);
          _emit(
            _state.copyWith(
              phase: conflict
                  ? SmartTileDraftPersistencePhase.conflict
                  : SmartTileDraftPersistencePhase.failed,
              errorCode: failure.code,
              errorMessage: failure.message,
            ),
          );
        }
      }
    } finally {
      _drainFuture = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _emit(SmartTileDraftPersistenceState next) {
    _state = next;
    _onStateChanged?.call(next);
  }

  void _requireOpen() {
    if (_closed) {
      throw StateError('The Smart Tile draft coordinator is closed.');
    }
  }
}

String smartTileDraftCanonicalFingerprint(
  ProjectSmartTileAuthoringDraft draft,
) =>
    sha256
        .convert(utf8.encode(canonicalAuthoringJson(draft.toJson())))
        .toString();

bool _isRevisionConflict(String code) =>
    code.contains('conflict') ||
    code.contains('stale') ||
    code.contains('revision');
