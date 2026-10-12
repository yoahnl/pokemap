import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

import 'approved_asset_library.dart';
import 'literal_tile_composer.dart';
import 'source_semantic_study_composer.dart';
import 'local_asset_proposer.dart';
import 'macos_source_tree.dart';
import 'native_project_writer.dart';
import 'snapshot_source_files.dart';

enum ConverterWorkflowPhase {
  scan,
  verifySource,
  normalize,
  compose,
  writeNative,
  verifyNative,
}

enum ConverterWorkflowEventKind {
  changed,
  progress,
  completed,
  cancelled,
  failed,
}

typedef ConverterWorkflowCheckpoint = FutureOr<void> Function(
    ConverterWorkflowPhase phase, ConverterId jobId, int sessionRevision);

final class ConverterSourceSelection {
  factory ConverterSourceSelection({
    required String rootPath,
    required ConverterId logicalProjectNamespace,
    SourceScanPolicy? policy,
  }) {
    _workflowPath(rootPath);
    return ConverterSourceSelection._(path.normalize(rootPath),
        logicalProjectNamespace, policy ?? SourceScanPolicy());
  }

  const ConverterSourceSelection._(
      this.rootPath, this.logicalProjectNamespace, this.policy);

  final String rootPath;
  final ConverterId logicalProjectNamespace;
  final SourceScanPolicy policy;

  Sha256Hash get canonicalHash => canonicalHashOf({
        'rootPath': rootPath,
        'logicalProjectNamespace': logicalProjectNamespace.value,
        'policyHash': policy.canonicalHash.value,
      });
}

final class SourceStudyAcknowledgement {
  factory SourceStudyAcknowledgement({
    required Sha256Hash sourceSnapshotHash,
    required Sha256Hash profileEvidenceHash,
    required bool humanConfirmed,
    required String reason,
  }) {
    if (reason.length > 1024 ||
        reason.contains('\u0000') ||
        (humanConfirmed && reason.trim().isEmpty)) {
      throw const ConverterWorkflowFailure('workflow.profile_ack',
          'A bounded explicit study acknowledgement is required.');
    }
    return SourceStudyAcknowledgement._(
        sourceSnapshotHash, profileEvidenceHash, humanConfirmed, reason.trim());
  }

  const SourceStudyAcknowledgement._(this.sourceSnapshotHash,
      this.profileEvidenceHash, this.humanConfirmed, this.reason);

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash profileEvidenceHash;
  final bool humanConfirmed;
  final String reason;

  Map<String, Object?> toJson() => {
        'kind': 'sourceStudyAcknowledgement',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileEvidenceHash': profileEvidenceHash.value,
        'humanConfirmed': humanConfirmed,
        'reason': reason,
      };

  Sha256Hash get canonicalHash => canonicalHashOf(toJson());
}

final class ConverterStudySettings {
  factory ConverterStudySettings({
    required String projectName,
    required String parentPath,
    required String folderName,
    required List<int> selectedSourceMapIds,
    required SourceStudyAcknowledgement profileAcknowledgement,
    List<LiteralDependencyDecision> dependencyDecisions = const [],
    bool allowFirstFrameAutotiles = false,
    AssetOutputMode assetOutputMode = AssetOutputMode.sharedAtlas,
    AssetReviewSession? reviewSession,
    SourceNormalizationLimits normalizationLimits =
        const SourceNormalizationLimits(),
    NativeWriteLimits writeLimits = const NativeWriteLimits(),
  }) {
    writeLimits.validate();
    _validateNormalizationLimits(normalizationLimits);
    _workflowPath(parentPath);
    if (projectName.trim().isEmpty ||
        projectName.length > 256 ||
        projectName.contains('\u0000') ||
        folderName.length > 255 ||
        folderName.isEmpty ||
        folderName.trim() != folderName ||
        folderName == '.' ||
        folderName == '..' ||
        RegExp(r'[\\/<>:"|?*\x00-\x1f]').hasMatch(folderName) ||
        folderName.endsWith('.') ||
        RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
                caseSensitive: false)
            .hasMatch(folderName)) {
      throw const ConverterWorkflowFailure(
          'workflow.destination.invalid', 'Invalid project name or folder.');
    }
    if (selectedSourceMapIds.isEmpty ||
        selectedSourceMapIds.length > writeLimits.maxMutations ||
        selectedSourceMapIds.length > normalizationLimits.maxMaps ||
        dependencyDecisions.length > writeLimits.maxMutations) {
      throw const ConverterWorkflowFailure('workflow.quota.selection',
          'Selection or dependency budget exceeded.');
    }
    final selected = <int>{};
    for (final id in selectedSourceMapIds) {
      if (id <= 0 || id > 2147483647 || !selected.add(id)) {
        throw const ConverterWorkflowFailure('workflow.selection.invalid',
            'Map IDs must be positive and unique.');
      }
    }
    canonicalJsonOf(dependencyDecisions.map((value) => value.toJson()).toList(),
        limits: writeLimits.jsonLimits);
    if (assetOutputMode == AssetOutputMode.packedObjects) {
      throw const ConverterWorkflowFailure('workflow.asset_output.invalid',
          'Choose a supported asset output mode.');
    }
    final ids = selected.toList()..sort();
    if (reviewSession != null &&
        (reviewSession.outputMode != assetOutputMode ||
            canonicalJsonOf(
                    reviewSession.selectedSourceMapIds.toList()..sort()) !=
                canonicalJsonOf(ids))) {
      throw const ConverterWorkflowFailure('workflow.review_session.stale',
          'The review session and the selected study context differ.');
    }
    final decisions = dependencyDecisions.toList()
      ..sort((a, b) => a.canonicalHash.value.compareTo(b.canonicalHash.value));
    return ConverterStudySettings._(
        projectName.trim(),
        path.normalize(parentPath),
        folderName,
        List.unmodifiable(ids),
        profileAcknowledgement,
        List.unmodifiable(decisions),
        allowFirstFrameAutotiles,
        assetOutputMode,
        reviewSession,
        normalizationLimits,
        writeLimits);
  }

  const ConverterStudySettings._(
      this.projectName,
      this.parentPath,
      this.folderName,
      this.selectedSourceMapIds,
      this.profileAcknowledgement,
      this.dependencyDecisions,
      this.allowFirstFrameAutotiles,
      this.assetOutputMode,
      this.reviewSession,
      this.normalizationLimits,
      this.writeLimits);

  final String projectName;
  final String parentPath;
  final String folderName;
  final List<int> selectedSourceMapIds;
  final SourceStudyAcknowledgement profileAcknowledgement;
  final List<LiteralDependencyDecision> dependencyDecisions;
  final bool allowFirstFrameAutotiles;
  final AssetOutputMode assetOutputMode;
  final AssetReviewSession? reviewSession;
  final SourceNormalizationLimits normalizationLimits;
  final NativeWriteLimits writeLimits;

  Map<String, Object?> toJson() => {
        'kind': 'converterStudySettings',
        'version': 1,
        'projectName': projectName,
        'parentPath': parentPath,
        'folderName': folderName,
        'selectedSourceMapIds': selectedSourceMapIds,
        'profileAcknowledgement': profileAcknowledgement.toJson(),
        'dependencyDecisions':
            dependencyDecisions.map((value) => value.toJson()).toList(),
        'allowFirstFrameAutotiles': allowFirstFrameAutotiles,
        'assetOutputMode': assetOutputMode.name,
        'reviewSession': reviewSession?.toJson(),
        'normalizationLimits': _normalizationLimitsJson(normalizationLimits),
        'writeLimits': _writeLimitsJson(writeLimits),
      };

  Sha256Hash get canonicalHash =>
      canonicalHashOf(toJson(), limits: writeLimits.jsonLimits);
}

final class PreparedStudy {
  const PreparedStudy._({
    required this.sessionRevision,
    required this.preparationHash,
    required this.sourceSnapshotHash,
    required this.profileEvidenceHash,
    required this.settings,
    required this.normalizedSource,
    required this.composition,
    required this.assetProposals,
    required this.assetProposalDiagnostics,
    required this.assetCandidates,
    required this.assetLibrary,
    required this.reviewDecisions,
    required this.approvedCandidateHashes,
    required this.nativeDraft,
    required this.previewPlan,
    required this.targetCapabilities,
    required this.canApprove,
    this.reviewSession,
  });

  final int sessionRevision;
  final Sha256Hash preparationHash;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash profileEvidenceHash;
  final ConverterStudySettings settings;
  final NormalizedSourceProject normalizedSource;
  final LiteralTileComposition composition;
  final LocalAssetProposalSet? assetProposals;
  final List<LocalAssetProposalDiagnostic> assetProposalDiagnostics;
  final List<AssetCandidate> assetCandidates;
  final ApprovedAssetLibraryComposition? assetLibrary;
  final ReviewDecisions reviewDecisions;
  final Map<ConverterId, Sha256Hash> approvedCandidateHashes;
  final NativeProjectDraft? nativeDraft;
  final ConversionPlan? previewPlan;
  final TargetCapabilities targetCapabilities;
  final bool canApprove;
  final AssetReviewSession? reviewSession;
}

final class StudyApproval {
  const StudyApproval._({
    required this.sessionRevision,
    required this.preparationHash,
    required this.approvedPlan,
    required this.approvedPlanHash,
  });

  final int sessionRevision;
  final Sha256Hash preparationHash;
  final ConversionPlan approvedPlan;
  final Sha256Hash approvedPlanHash;
}

final class ConverterStudyResult {
  const ConverterStudyResult._({
    required this.receipt,
    required this.sourceSnapshotHash,
    required this.preparationHash,
    required this.approvedPlanHash,
    required this.sessionRevision,
    required this.sourceUnchanged,
  });

  final NativeWriteReceipt receipt;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash preparationHash;
  final Sha256Hash approvedPlanHash;
  final int sessionRevision;
  final bool sourceUnchanged;
  bool get published => false;
  bool get playableCertified => false;
}

final class ConverterWorkflowFailure implements Exception {
  const ConverterWorkflowFailure(this.code, this.message,
      {this.locator, this.stagingPath, this.retryable = true});

  final String code;
  final String message;
  final String? locator;
  final String? stagingPath;
  final bool retryable;

  @override
  String toString() => '$code: $message';
}

final class ConverterWorkflowState {
  const ConverterWorkflowState._({
    this.revision = 1,
    this.source,
    this.snapshot,
    this.availableSourceMapIds = const [],
    this.settings,
    this.prepared,
    this.approval,
    this.result,
    this.job,
    this.jobId,
    this.progress,
    this.phase,
    this.cancellationRequested = false,
    this.failure,
    this.isBusy = false,
  });

  final int revision;
  final ConverterSourceSelection? source;
  final SourceSnapshot? snapshot;
  final List<int> availableSourceMapIds;
  final ConverterStudySettings? settings;
  final PreparedStudy? prepared;
  final StudyApproval? approval;
  final ConverterStudyResult? result;
  final ConversionJob? job;
  final ConverterId? jobId;
  final JobProgress? progress;
  final ConverterWorkflowPhase? phase;
  final bool cancellationRequested;
  final ConverterWorkflowFailure? failure;
  final bool isBusy;

  ConverterWorkflowState _copy({
    int? revision,
    Object? source = _keep,
    Object? snapshot = _keep,
    List<int>? availableSourceMapIds,
    Object? settings = _keep,
    Object? prepared = _keep,
    Object? approval = _keep,
    Object? result = _keep,
    Object? job = _keep,
    Object? jobId = _keep,
    Object? progress = _keep,
    Object? phase = _keep,
    bool? cancellationRequested,
    Object? failure = _keep,
    bool? isBusy,
  }) =>
      ConverterWorkflowState._(
        revision: revision ?? this.revision,
        source: identical(source, _keep)
            ? this.source
            : source as ConverterSourceSelection?,
        snapshot: identical(snapshot, _keep)
            ? this.snapshot
            : snapshot as SourceSnapshot?,
        availableSourceMapIds:
            availableSourceMapIds ?? this.availableSourceMapIds,
        settings: identical(settings, _keep)
            ? this.settings
            : settings as ConverterStudySettings?,
        prepared: identical(prepared, _keep)
            ? this.prepared
            : prepared as PreparedStudy?,
        approval: identical(approval, _keep)
            ? this.approval
            : approval as StudyApproval?,
        result: identical(result, _keep)
            ? this.result
            : result as ConverterStudyResult?,
        job: identical(job, _keep) ? this.job : job as ConversionJob?,
        jobId: identical(jobId, _keep) ? this.jobId : jobId as ConverterId?,
        progress: identical(progress, _keep)
            ? this.progress
            : progress as JobProgress?,
        phase: identical(phase, _keep)
            ? this.phase
            : phase as ConverterWorkflowPhase?,
        cancellationRequested:
            cancellationRequested ?? this.cancellationRequested,
        failure: identical(failure, _keep)
            ? this.failure
            : failure as ConverterWorkflowFailure?,
        isBusy: isBusy ?? this.isBusy,
      );
}

final class ConverterWorkflowEvent {
  const ConverterWorkflowEvent({required this.kind, required this.state});

  final ConverterWorkflowEventKind kind;
  final ConverterWorkflowState state;
}

final class ConverterWorkflow {
  ConverterWorkflow({this.checkpoint, this.nativeWriteCheckpoint})
      : _sessionId = ConverterId(
            'converter-workflow:${DateTime.now().microsecondsSinceEpoch}:${_workflowSequence++}');

  final ConverterWorkflowCheckpoint? checkpoint;
  final NativeWriteCheckpoint? nativeWriteCheckpoint;
  final StreamController<ConverterWorkflowEvent> _events =
      StreamController.broadcast();
  ConverterWorkflowState _state = const ConverterWorkflowState._();
  final ConverterId _sessionId;
  _WorkflowRun? _active;
  bool _disposed = false;
  int _attemptOrdinal = 0;

  ConverterWorkflowState get state => _state;
  Stream<ConverterWorkflowEvent> get events => _events.stream;

  Future<SourceSnapshot> scanSource(ConverterSourceSelection source) async {
    _requireIdle();
    _state = ConverterWorkflowState._(
        revision: _nextRevision(), source: source, isBusy: true);
    _emit(ConverterWorkflowEventKind.changed);
    try {
      final outcome = await _execute(_WorkerRequest(
          kind: _WorkerKind.scan,
          sessionId: _sessionId,
          revision: _state.revision,
          source: source));
      final snapshot = outcome.snapshot!;
      final complete = snapshot.state == SourceScanState.complete;
      _state = _state._copy(
          snapshot: snapshot,
          availableSourceMapIds:
              complete ? _availableMapIds(snapshot) : const [],
          isBusy: false,
          failure: complete
              ? null
              : const ConverterWorkflowFailure('workflow.incomplete',
                  'The source inventory is incomplete; review its diagnostics.'));
      _emit(complete
          ? ConverterWorkflowEventKind.completed
          : ConverterWorkflowEventKind.failed);
      return snapshot;
    } catch (error) {
      throw _recordFailure(error);
    }
  }

  void updateSettings(ConverterStudySettings settings) {
    _requireIdle();
    final snapshot = _requireSource();
    _checkAcknowledgement(snapshot, settings.profileAcknowledgement);
    if (_state.settings?.canonicalHash == settings.canonicalHash) return;
    _state = _state._copy(
        revision: _nextRevision(),
        settings: settings,
        prepared: null,
        approval: null,
        result: null,
        job: null,
        jobId: null,
        progress: null,
        phase: null,
        cancellationRequested: false,
        failure: null);
    _emit(ConverterWorkflowEventKind.changed);
  }

  void invalidatePrepared() {
    _requireIdle();
    if (_state.prepared == null && _state.approval == null) return;
    _state = _state._copy(
        revision: _nextRevision(),
        prepared: null,
        approval: null,
        result: null);
    _emit(ConverterWorkflowEventKind.changed);
  }

  Future<PreparedStudy> prepareStudy() async {
    _requireIdle();
    final snapshot = _requireSource();
    final settings = _state.settings;
    if (settings == null) {
      throw const ConverterWorkflowFailure(
          'workflow.no_settings', 'Choose the maps and destination first.');
    }
    _checkAcknowledgement(snapshot, settings.profileAcknowledgement);
    _state = _state._copy(
        prepared: null,
        approval: null,
        result: null,
        job: null,
        jobId: null,
        progress: null,
        phase: null,
        failure: null,
        cancellationRequested: false,
        isBusy: true);
    _emit(ConverterWorkflowEventKind.changed);
    try {
      final outcome = await _execute(_WorkerRequest(
          kind: _WorkerKind.prepare,
          sessionId: _sessionId,
          revision: _state.revision,
          source: _state.source!,
          snapshot: snapshot,
          settings: settings));
      final prepared = outcome.prepared!;
      _state = _state._copy(prepared: prepared, isBusy: false, failure: null);
      _emit(ConverterWorkflowEventKind.completed);
      return prepared;
    } catch (error) {
      throw _recordFailure(error);
    }
  }

  StudyApproval approvePrepared({
    required int sessionRevision,
    required Sha256Hash preparationHash,
    required bool humanConfirmed,
  }) {
    _requireIdle();
    final prepared = _state.prepared;
    if (prepared == null ||
        prepared.sessionRevision != sessionRevision ||
        _state.revision != sessionRevision ||
        prepared.preparationHash != preparationHash) {
      throw const ConverterWorkflowFailure('workflow.stale_approval',
          'Prepare and review the current exact draft.');
    }
    if (!humanConfirmed) {
      throw const ConverterWorkflowFailure('workflow.approval_required',
          'Explicit human approval of the exact draft is required.');
    }
    _checkAcknowledgement(
        _requireSource(), prepared.settings.profileAcknowledgement);
    if (!prepared.settings.profileAcknowledgement.humanConfirmed) {
      throw const ConverterWorkflowFailure('workflow.profile_ack',
          'Acknowledge the observed study profile first.');
    }
    final preview = prepared.previewPlan;
    if (!prepared.canApprove ||
        prepared.nativeDraft == null ||
        preview == null) {
      throw const ConverterWorkflowFailure('workflow.blocked',
          'Resolve the blocking diagnostics before approval.');
    }
    final json = preview.toJson();
    final approved = ConversionPlan.fromJson({
      ...json,
      'state': 'ready',
      'approvedByHuman': true,
    }, limits: prepared.settings.writeLimits.jsonLimits);
    admitPlan(approved, _planContext(prepared, approved, _sessionId));
    final approval = StudyApproval._(
        sessionRevision: sessionRevision,
        preparationHash: preparationHash,
        approvedPlan: approved,
        approvedPlanHash: approved.canonicalHash);
    _state = _state._copy(approval: approval, failure: null);
    _emit(ConverterWorkflowEventKind.changed);
    return approval;
  }

  Future<ConverterStudyResult> writeApproved(StudyApproval approval) async {
    _requireIdle();
    final prepared = _state.prepared;
    if (!identical(_state.approval, approval) ||
        prepared == null ||
        approval.sessionRevision != _state.revision ||
        approval.preparationHash != prepared.preparationHash ||
        approval.approvedPlanHash != approval.approvedPlan.canonicalHash) {
      throw const ConverterWorkflowFailure('workflow.stale_approval',
          'This approval is absent, stale, or consumed.');
    }
    admitPlan(approval.approvedPlan,
        _planContext(prepared, approval.approvedPlan, _sessionId));
    _state = _state._copy(
        approval: null,
        result: null,
        job: null,
        jobId: null,
        progress: null,
        phase: null,
        failure: null,
        cancellationRequested: false,
        isBusy: true);
    _emit(ConverterWorkflowEventKind.changed);
    try {
      final outcome = await _execute(_WorkerRequest(
          kind: _WorkerKind.write,
          sessionId: _sessionId,
          revision: _state.revision,
          source: _state.source!,
          snapshot: _state.snapshot!,
          settings: prepared.settings,
          prepared: prepared,
          approval: approval));
      final result = outcome.result!;
      _state = _state._copy(result: result, isBusy: false, failure: null);
      _emit(ConverterWorkflowEventKind.completed);
      return result;
    } catch (error) {
      throw _recordFailure(error);
    }
  }

  void cancelCurrentJob() {
    if (_disposed || !_state.isBusy || _state.cancellationRequested) return;
    _state = _state._copy(cancellationRequested: true);
    _active?.control?.send(const _WorkerControl.cancel());
    _emit(ConverterWorkflowEventKind.changed);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    cancelCurrentJob();
    _disposed = true;
    final run = _active;
    if (run != null) {
      try {
        await run.done.future;
      } catch (_) {}
    }
    await _events.close();
  }

  int _nextRevision() {
    if (_state.revision >= 2147483647) {
      throw const ConverterWorkflowFailure('workflow.revision_limit',
          'The session revision budget is exhausted.',
          retryable: false);
    }
    return _state.revision + 1;
  }

  void _requireIdle() {
    if (_disposed) {
      throw const ConverterWorkflowFailure(
          'workflow.disposed', 'The workflow is closed.',
          retryable: false);
    }
    if (_state.isBusy) {
      throw const ConverterWorkflowFailure(
          'workflow.busy', 'Wait for the current job or request cancellation.');
    }
  }

  SourceSnapshot _requireSource() {
    final snapshot = _state.snapshot;
    if (_state.source == null || snapshot == null) {
      throw const ConverterWorkflowFailure(
          'workflow.no_source', 'Scan a source directory first.');
    }
    if (snapshot.state != SourceScanState.complete) {
      throw const ConverterWorkflowFailure(
          'workflow.incomplete', 'The source inventory is incomplete.');
    }
    return snapshot;
  }

  void _emit(ConverterWorkflowEventKind kind) {
    if (!_events.isClosed) {
      _events.add(ConverterWorkflowEvent(kind: kind, state: _state));
    }
  }

  ConverterWorkflowFailure _recordFailure(Object error) {
    final failure = _workflowFailure(error);
    final cancelled = failure.code == 'workflow.cancelled';
    final job = _state.job;
    final terminal = job != null &&
            (job.state == JobState.running || job.state == JobState.queued)
        ? job.applyUpdate(
            jobId: job.jobId,
            sessionRevision: job.session.revision,
            state: cancelled ? JobState.cancelled : JobState.failed,
            progress: job.progress)
        : job;
    _state = _state._copy(
        isBusy: false,
        job: terminal,
        approval: null,
        prepared:
            failure.code == 'workflow.source_changed' ? null : _state.prepared,
        result: null,
        failure: failure);
    _emit(cancelled
        ? ConverterWorkflowEventKind.cancelled
        : ConverterWorkflowEventKind.failed);
    return failure;
  }

  Future<_WorkerOutcome> _execute(_WorkerRequest request) async {
    final run = _WorkflowRun(request);
    _active = run;
    final receive = ReceivePort();
    final subscription = receive.listen((message) {
      if (!identical(_active, run)) return;
      if (message == null) {
        run.exited = true;
        if (run.outcome == null && !run.done.isCompleted) {
          run.done.completeError(const ConverterWorkflowFailure(
              'workflow.worker_failed', 'The worker exited without a result.'));
        } else if (!run.done.isCompleted) {
          run.done.complete(run.outcome!);
        }
      } else if (message is _WorkerReady) {
        run.control = message.port;
        if (_state.cancellationRequested) {
          run.control!.send(const _WorkerControl.cancel());
        }
      } else if (message is _WorkerPhase) {
        final snapshot = request.snapshot;
        ConversionJob? job;
        if (snapshot != null) {
          final queued = ConversionJob(
              jobId: message.jobId,
              session: ConversionSession(
                  sessionId: request.sessionId,
                  revision: request.revision,
                  logicalProjectNamespace:
                      request.source.logicalProjectNamespace,
                  sourceSnapshotHash: snapshot.canonicalHash),
              progress: message.progress);
          job = queued.applyUpdate(
              jobId: queued.jobId,
              sessionRevision: request.revision,
              state: JobState.running,
              progress: message.progress);
        }
        _state = _state._copy(
            job: job,
            jobId: message.jobId,
            phase: message.phase,
            progress: message.progress);
        _emit(ConverterWorkflowEventKind.changed);
      } else if (message is _WorkerProgress &&
          message.jobId == _state.jobId &&
          request.revision == _state.revision) {
        final job = _state.job;
        _state = _state._copy(
            progress: message.progress,
            job: job?.applyUpdate(
                jobId: message.jobId,
                sessionRevision: request.revision,
                state: message.complete ? JobState.succeeded : JobState.running,
                progress: message.progress));
        _emit(ConverterWorkflowEventKind.progress);
      } else if (message is _WorkerCheckpoint) {
        unawaited(_handleCheckpoint(run, message));
      } else if (message is _WorkerOutcome) {
        run.outcome = message;
      } else if (message is List && !run.done.isCompleted) {
        run.outcome = _WorkerOutcome(
            failure: ConverterWorkflowFailure(
                'workflow.worker_failed', message.first.toString()));
      }
    });
    try {
      await Isolate.spawn(_converterWorker,
          _WorkerLaunch(request, receive.sendPort, ++_attemptOrdinal),
          onExit: receive.sendPort, onError: receive.sendPort);
      final outcome = await run.done.future;
      if (outcome.failure != null) throw outcome.failure!;
      return outcome;
    } finally {
      await subscription.cancel();
      receive.close();
      if (identical(_active, run)) _active = null;
    }
  }

  Future<void> _handleCheckpoint(
      _WorkflowRun run, _WorkerCheckpoint message) async {
    ConverterWorkflowFailure? failure;
    try {
      if (message.stage == null) {
        await checkpoint?.call(
            message.phase, message.jobId, run.request.revision);
      } else {
        await nativeWriteCheckpoint?.call(
            message.stage!, message.stagingRoot, message.projectPath);
      }
    } catch (error) {
      failure = _workflowFailure(error);
    }
    if (identical(_active, run) && !run.exited) {
      run.control?.send(_WorkerControl.ack(message.ackId, failure));
    }
  }
}

const _keep = Object();
int _workflowSequence = 0;
const _converterVersion = 'avelune-converter-ac12-study-v1';

enum _WorkerKind { scan, prepare, write }

final class _WorkerRequest {
  const _WorkerRequest({
    required this.kind,
    required this.sessionId,
    required this.revision,
    required this.source,
    this.snapshot,
    this.settings,
    this.prepared,
    this.approval,
  });
  final _WorkerKind kind;
  final ConverterId sessionId;
  final int revision;
  final ConverterSourceSelection source;
  final SourceSnapshot? snapshot;
  final ConverterStudySettings? settings;
  final PreparedStudy? prepared;
  final StudyApproval? approval;
}

final class _WorkflowRun {
  _WorkflowRun(this.request);
  final _WorkerRequest request;
  final Completer<_WorkerOutcome> done = Completer();
  SendPort? control;
  _WorkerOutcome? outcome;
  bool exited = false;
}

final class _WorkerLaunch {
  const _WorkerLaunch(this.request, this.parent, this.attemptOrdinal);
  final _WorkerRequest request;
  final SendPort parent;
  final int attemptOrdinal;
}

final class _WorkerReady {
  const _WorkerReady(this.port);
  final SendPort port;
}

final class _WorkerControl {
  const _WorkerControl.cancel()
      : ackId = null,
        failure = null;
  const _WorkerControl.ack(this.ackId, this.failure);
  final int? ackId;
  final ConverterWorkflowFailure? failure;
}

final class _WorkerPhase {
  const _WorkerPhase(this.jobId, this.phase, this.progress);
  final ConverterId jobId;
  final ConverterWorkflowPhase phase;
  final JobProgress progress;
}

final class _WorkerProgress {
  const _WorkerProgress(this.jobId, this.progress, {this.complete = false});
  final ConverterId jobId;
  final JobProgress progress;
  final bool complete;
}

final class _WorkerCheckpoint {
  const _WorkerCheckpoint({
    required this.ackId,
    required this.jobId,
    required this.phase,
    this.stage,
    this.stagingRoot,
    this.projectPath,
  });
  final int ackId;
  final ConverterId jobId;
  final ConverterWorkflowPhase phase;
  final NativeWriteStage? stage;
  final String? stagingRoot;
  final String? projectPath;
}

final class _WorkerOutcome {
  const _WorkerOutcome(
      {this.snapshot, this.prepared, this.result, this.failure});
  final SourceSnapshot? snapshot;
  final PreparedStudy? prepared;
  final ConverterStudyResult? result;
  final ConverterWorkflowFailure? failure;
}

final class _WorkerRelay {
  _WorkerRelay(this.launch, this.port) {
    subscription = port.listen((message) {
      if (message is! _WorkerControl) return;
      if (message.ackId == null) {
        cancellation.cancel();
        for (final waiter in waiters.values.toList()) {
          if (!waiter.isCompleted) {
            waiter.completeError(const ConverterWorkflowFailure(
                'workflow.cancelled', 'The job was cancelled.'));
          }
        }
      } else {
        final waiter = waiters[message.ackId];
        if (waiter != null && !waiter.isCompleted) {
          if (message.failure == null) {
            waiter.complete();
          } else {
            waiter.completeError(message.failure!);
          }
        }
      }
    });
    launch.parent.send(_WorkerReady(port.sendPort));
  }
  final _WorkerLaunch launch;
  final ReceivePort port;
  final ScanCancellation cancellation = ScanCancellation();
  final Map<int, Completer<void>> waiters = {};
  late final StreamSubscription<dynamic> subscription;
  int phaseIndex = 0;
  int ackIndex = 0;
  late ConverterId jobId;
  late ConverterWorkflowPhase phase;
  late JobProgress progress;

  Future<void> start(ConverterWorkflowPhase next, JobUnit unit,
      {int? total}) async {
    cancellation.check();
    phase = next;
    phaseIndex++;
    jobId = ConverterId(
        '${launch.request.sessionId.value}.r${launch.request.revision}.a${launch.attemptOrdinal}.j$phaseIndex');
    progress = JobProgress(done: 0, total: total, unit: unit);
    launch.parent.send(_WorkerPhase(jobId, phase, progress));
    await checkpoint();
  }

  void update(JobProgress next) {
    progress = next;
    launch.parent.send(_WorkerProgress(jobId, progress));
  }

  void finish({int? done}) {
    if (done != null) {
      progress =
          JobProgress(done: done, total: progress.total, unit: progress.unit);
    }
    launch.parent.send(_WorkerProgress(jobId, progress, complete: true));
  }

  Future<void> checkpoint(
      {NativeWriteStage? stage,
      String? stagingRoot,
      String? projectPath}) async {
    cancellation.check();
    final ackId = ++ackIndex;
    final waiter = Completer<void>();
    waiters[ackId] = waiter;
    launch.parent.send(_WorkerCheckpoint(
        ackId: ackId,
        jobId: jobId,
        phase: phase,
        stage: stage,
        stagingRoot: stagingRoot,
        projectPath: projectPath));
    try {
      await waiter.future;
      cancellation.check();
    } finally {
      waiters.remove(ackId);
    }
  }

  Future<void> close() async {
    await subscription.cancel();
    port.close();
  }
}

Future<void> _converterWorker(_WorkerLaunch launch) async {
  final relay = _WorkerRelay(launch, ReceivePort());
  final request = launch.request;
  MacOsSourceTree? tree;
  NativeWriteReceipt? receipt;
  late _WorkerOutcome outcome;
  try {
    if (request.kind == _WorkerKind.write) {
      admitPlan(
          request.approval!.approvedPlan,
          _planContext(request.prepared!, request.approval!.approvedPlan,
              request.sessionId));
    }
    await relay.start(
        request.kind == _WorkerKind.scan
            ? ConverterWorkflowPhase.scan
            : ConverterWorkflowPhase.verifySource,
        JobUnit.files);
    tree = await MacOsSourceTree.open(request.source.rootPath);
    relay.cancellation.check();
    final source = _CooperativeSourceTree(tree);
    final snapshot = await SourceScanner().scan(
        source: source,
        logicalProjectNamespace: request.source.logicalProjectNamespace,
        policy: request.source.policy,
        cancellation: relay.cancellation,
        onProgress: relay.update);
    if (snapshot.state == SourceScanState.cancelled) {
      throw const ConverterWorkflowFailure(
          'workflow.cancelled', 'The source scan was cancelled.');
    }
    relay.cancellation.check();
    if (request.kind == _WorkerKind.scan) {
      if (snapshot.state == SourceScanState.complete) relay.finish();
      outcome = _WorkerOutcome(snapshot: snapshot);
    } else {
      if (snapshot.state != SourceScanState.complete) {
        throw const ConverterWorkflowFailure(
            'workflow.incomplete', 'The fresh source inventory is incomplete.');
      }
      if (snapshot.canonicalHash != request.snapshot!.canonicalHash ||
          snapshot.policyHash != request.snapshot!.policyHash ||
          snapshot.logicalProjectNamespace !=
              request.snapshot!.logicalProjectNamespace) {
        throw const ConverterWorkflowFailure('workflow.source_changed',
            'Source bytes changed; scan and prepare a new exact draft.');
      }
      relay.finish();
      final files = await SnapshotSourceFiles.bind(
          source: source,
          snapshot: snapshot,
          policy: request.source.policy,
          cancellation: relay.cancellation);
      if (request.kind == _WorkerKind.prepare) {
        final settings = request.settings!;
        _checkAcknowledgement(snapshot, settings.profileAcknowledgement);
        await _guardPreparationDestination(settings, tree.rootPath);
        final wanted = settings.selectedSourceMapIds.toSet();
        for (final decision in settings.dependencyDecisions) {
          if (decision.decision == LiteralDependencyDisposition.include) {
            wanted.add(decision.targetSourceMapId);
          }
        }
        if (wanted.length > settings.normalizationLimits.maxMaps ||
            wanted.length > settings.writeLimits.maxMutations ||
            !wanted.every(_availableMapIds(snapshot).contains)) {
          throw const ConverterWorkflowFailure('workflow.selection.invalid',
              'The selected or included map is missing or exceeds the budget.');
        }
        await relay.start(ConverterWorkflowPhase.normalize, JobUnit.maps);
        final normalized = await const RmxpSourceNormalizer().normalize(
            snapshot: snapshot,
            files: files,
            limits: settings.normalizationLimits,
            cancellation: relay.cancellation,
            selectedMapIds: wanted);
        relay.finish(done: normalized.maps.length);
        await relay.start(ConverterWorkflowPhase.compose, JobUnit.assets);
        final composition = await const LiteralTileComposer().compose(
            source: normalized,
            files: files,
            selectedSourceMapIds: settings.selectedSourceMapIds,
            projectName: settings.projectName,
            parentPath: settings.parentPath,
            folderName: settings.folderName,
            sourceRootPath: tree.rootPath,
            dependencyDecisions: settings.dependencyDecisions,
            allowFirstFrameAutotiles: settings.allowFirstFrameAutotiles,
            limits: settings.writeLimits,
            cancellation: relay.cancellation);
        LocalAssetProposalSet? proposals;
        final proposalDiagnostics = <LocalAssetProposalDiagnostic>[];
        if (composition.canWrite) {
          try {
            proposals = await const LocalAssetProposer().propose(
                source: normalized,
                files: files,
                literal: composition,
                outputMode: settings.reviewSession?.frames.first.outputMode ??
                    settings.assetOutputMode,
                limits: LocalAssetProposalLimits(
                    maxSourceImages:
                        settings.writeLimits.maxArtifacts.clamp(1, 32),
                    maxSourceBytes: settings.writeLimits.maxTotalArtifactBytes
                        .clamp(1, 67108864),
                    maxPixels: settings.writeLimits.maxImagePixels,
                    maxMapCells:
                        settings.writeLimits.maxMapCells.clamp(1, 1048576),
                    maxCandidates:
                        settings.writeLimits.maxMutations.clamp(1, 256),
                    jsonLimits: ContractLimits(
                      maxDepth: settings.writeLimits.jsonLimits.maxDepth,
                      maxNodes: settings.writeLimits.jsonLimits.maxNodes
                          .clamp(1, 1000000),
                      maxStringCodeUnits:
                          settings.writeLimits.jsonLimits.maxStringCodeUnits,
                      maxTextCodeUnits: settings
                          .writeLimits.jsonLimits.maxTextCodeUnits
                          .clamp(1, 4194304),
                    )),
                cancellation: relay.cancellation);
            proposalDiagnostics.addAll(proposals.diagnostics);
          } on ContractError catch (error) {
            if (error.code != 'asset.proposal.quota') rethrow;
            proposalDiagnostics.add(LocalAssetProposalDiagnostic(error.code,
                'Local recognition exceeded its budget; no partial proposals were retained. Literal map conversion remains available.'));
          }
        }
        AssetReviewSession? reviewSession;
        if (proposals != null) {
          final seedMode = settings.reviewSession?.frames.first.outputMode ??
              settings.assetOutputMode;
          final generationHash = _reviewProposalGenerationHash(
              proposals, settings.selectedSourceMapIds, seedMode);
          final supplied = settings.reviewSession;
          if (supplied != null) {
            if (supplied.sourceSnapshotHash != snapshot.canonicalHash ||
                supplied.logicalProjectNamespace !=
                    snapshot.logicalProjectNamespace ||
                supplied.proposalGenerationHash != generationHash ||
                canonicalHashOf({
                      for (final c in proposals.candidates)
                        c.candidateId.value: c.canonicalHash.value
                    }) !=
                    canonicalHashOf({
                      for (final e in supplied.baseProposalHashes.entries)
                        e.key.value: e.value.value
                    })) {
              throw const ConverterWorkflowFailure(
                  'workflow.review_session.stale',
                  'The stored review seed does not match the fresh source proposals.');
            }
            supplied.validatePlacements(normalized.maps);
            for (final candidate in supplied.activeCandidates) {
              const LocalAssetProposer().validatePlacementClaims(
                  source: normalized,
                  literal: composition,
                  candidate: candidate,
                  claims:
                      supplied.frame.placementClaims[candidate.candidateId] ??
                          const []);
            }
            reviewSession = supplied;
          } else {
            reviewSession = AssetReviewSession.create(
                sessionId: ConverterId(
                    '${request.sessionId.value}.review${request.revision}'),
                logicalProjectNamespace: snapshot.logicalProjectNamespace,
                sourceSnapshotHash: snapshot.canonicalHash,
                selectedSourceMapIds: settings.selectedSourceMapIds,
                outputMode: settings.assetOutputMode,
                proposalGenerationHash: generationHash,
                candidates: proposals.candidates,
                placementClaims: proposals.placementClaims,
                sourceMaps: normalized.maps);
          }
        } else if (settings.reviewSession != null) {
          throw const ConverterWorkflowFailure('workflow.review_session.stale',
              'The fresh proposal generation is unavailable for review attestation.');
        }
        final candidates =
            reviewSession?.activeCandidates ?? const <AssetCandidate>[];
        final decisions = ReviewDecisions.fromJson({
          'schemaVersion': '1.0',
          'kind': 'reviewDecisions',
          'exampleOnly': false,
          'sessionId': request.sessionId.value,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'revision': request.revision,
          'decisions': reviewSession?.activeDecisions.toJson()['decisions'] ??
              const <Object?>[],
        });
        final approvedCandidateHashes = <ConverterId, Sha256Hash>{
          for (final candidate in candidates)
            if (candidate.state == CandidateState.approved)
              candidate.candidateId: candidate.canonicalHash,
        };
        final library = approvedCandidateHashes.isEmpty
            ? null
            : await const ApprovedAssetLibraryComposer().compose(
                source: normalized,
                files: files,
                candidates: candidates
                    .where((c) =>
                        approvedCandidateHashes.containsKey(c.candidateId))
                    .toList(),
                approvedCandidateHashes: approvedCandidateHashes,
                decisions: decisions,
                outputMode: settings.assetOutputMode,
                limits: settings.writeLimits,
                cancellation: relay.cancellation);
        final semantic = await const SourceSemanticStudyComposer().compose(
            source: normalized,
            base: composition,
            files: files,
            limits: settings.writeLimits,
            cancellation: relay.cancellation);
        final draft = _mergeAssetLibrary(semantic ?? composition.draft, library,
            limits: settings.writeLimits);
        relay.finish(
            done: composition.crops
                .map((crop) => crop.imageFileId)
                .toSet()
                .length);
        await relay.start(ConverterWorkflowPhase.verifySource, JobUnit.files);
        await files.verifyUnchanged();
        relay.cancellation.check();
        relay.finish();
        final capabilities = _nativeCapabilities();
        final plan = _previewPlan(request, normalized, composition,
            capabilities, draft, decisions, proposalDiagnostics, library);
        final hash = canonicalHashOf({
          'kind': 'preparedConverterStudy',
          'version': 1,
          'sessionId': request.sessionId.value,
          'sessionRevision': request.revision,
          'sourceSelectionHash': request.source.canonicalHash.value,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'profileEvidenceHash': snapshot.profile.evidenceHash.value,
          'settingsHash': settings.canonicalHash.value,
          'normalizedSourceHash': normalized.canonicalHash.value,
          'compositionHash': composition.compositionHash.value,
          'assetProposalHash': proposals?.canonicalHash.value,
          'assetProposalDiagnostics':
              proposalDiagnostics.map((d) => d.toJson()).toList(),
          'candidateHashes':
              candidates.map((c) => c.canonicalHash.value).toList(),
          'assetLibraryHash': library?.compositionHash.value,
          'decisionsHash': decisions.canonicalHash.value,
          'nativeDraftHash': draft?.canonicalHash.value,
          'targetProfileHash': capabilities.canonicalHash.value,
          'previewPlanHash': plan?.canonicalHash.value,
        }, limits: settings.writeLimits.jsonLimits);
        outcome = _WorkerOutcome(
            prepared: PreparedStudy._(
                sessionRevision: request.revision,
                preparationHash: hash,
                sourceSnapshotHash: snapshot.canonicalHash,
                profileEvidenceHash: snapshot.profile.evidenceHash,
                settings: settings,
                normalizedSource: normalized,
                composition: composition,
                assetProposals: proposals,
                assetProposalDiagnostics:
                    List.unmodifiable(proposalDiagnostics),
                assetCandidates: List.unmodifiable(candidates),
                assetLibrary: library,
                reviewDecisions: decisions,
                approvedCandidateHashes:
                    Map.unmodifiable(approvedCandidateHashes),
                nativeDraft: draft,
                previewPlan: plan,
                targetCapabilities: capabilities,
                reviewSession: reviewSession,
                canApprove: normalized.canPlan &&
                    draft != null &&
                    settings.profileAcknowledgement.humanConfirmed &&
                    plan != null &&
                    !plan.findings.any((finding) => finding.blocksStudy)));
      } else {
        final prepared = request.prepared!;
        final draft = prepared.nativeDraft!;
        final approval = request.approval!;
        var applied = 0;
        await relay.start(
            ConverterWorkflowPhase.writeNative, JobUnit.operations,
            total: draft.mutations.length);
        final writer = NativeProjectWriter(
            checkpoint: (stage, stagingRoot, projectPath) async {
          try {
            if (stage == NativeWriteStage.beforeNativeVerify) {
              relay.finish();
              await relay.start(
                  ConverterWorkflowPhase.verifyNative, JobUnit.files);
            }
            await relay.checkpoint(
                stage: stage,
                stagingRoot: stagingRoot,
                projectPath: projectPath);
          } on ConverterWorkflowFailure catch (failure) {
            throw NativeWriteException(
                failure.code == 'workflow.cancelled'
                    ? 'native.cancelled'
                    : failure.code,
                failure.message,
                stagingPath: stagingRoot);
          }
          if (stage == NativeWriteStage.afterMutation) {
            relay.update(JobProgress(
                done: ++applied,
                total: draft.mutations.length,
                unit: JobUnit.operations));
          }
        });
        receipt = await writer.write(
            approval.approvedPlan,
            _planContext(prepared, approval.approvedPlan, request.sessionId),
            draft,
            limits: prepared.settings.writeLimits,
            cancellation: relay.cancellation);
        relay.finish(
            done: receipt.mapHashes.length + receipt.assetHashes.length);
        await relay.start(ConverterWorkflowPhase.verifySource, JobUnit.files);
        await files.verifyUnchanged();
        relay.cancellation.check();
        relay.finish();
        outcome = _WorkerOutcome(
            result: ConverterStudyResult._(
                receipt: receipt,
                sourceSnapshotHash: snapshot.canonicalHash,
                preparationHash: prepared.preparationHash,
                approvedPlanHash: approval.approvedPlanHash,
                sessionRevision: request.revision,
                sourceUnchanged: true));
      }
    }
  } catch (error) {
    outcome = _WorkerOutcome(
        failure: _workflowFailure(error, stagingPath: receipt?.stagingRoot));
  } finally {
    await tree?.close();
    await relay.close();
  }
  launch.parent.send(outcome);
}

void _workflowPath(String value) {
  if (!path.isAbsolute(value) ||
      value.length > 4096 ||
      value.contains('\u0000')) {
    throw const ConverterWorkflowFailure('workflow.destination.invalid',
        'An absolute bounded path is required.');
  }
}

final class _CooperativeSourceTree implements SourceTreePort {
  const _CooperativeSourceTree(this.source);
  final SourceTreePort source;

  @override
  Stream<SourceNode> walk({
    required SourceScanPolicy policy,
    required ScanCancellation cancellation,
  }) async* {
    await for (final node
        in source.walk(policy: policy, cancellation: cancellation)) {
      await Future<void>.delayed(Duration.zero);
      cancellation.check();
      yield node;
    }
  }

  @override
  Stream<List<int>> read(
    SourceNode node, {
    required int maxBytes,
    required ScanCancellation cancellation,
  }) async* {
    await for (final chunk
        in source.read(node, maxBytes: maxBytes, cancellation: cancellation)) {
      await Future<void>.delayed(Duration.zero);
      cancellation.check();
      yield chunk;
    }
  }
}

void _validateNormalizationLimits(SourceNormalizationLimits limits) {
  final bounds = [
    (limits.maxMaps, 100000),
    (limits.maxTotalCells, 67108864),
    (limits.maxEvents, 1000000),
    (limits.maxCommands, 2000000),
    (limits.maxParameterNodes, 4000000),
    (limits.maxDiagnostics, 100000),
    (limits.maxTotalBytes, 268435456),
    (limits.maxMetadataCells, 8388608),
    (limits.maxTotalIrNodes, 16000000),
    (limits.maxTotalTextCodeUnits, 67108864),
    (limits.maxDiagnosticTextCodeUnits, 4194304),
  ];
  if (bounds.any((entry) => entry.$1 <= 0 || entry.$1 > entry.$2)) {
    throw const ConverterWorkflowFailure('workflow.invalid_limits',
        'Normalization budgets must be positive and bounded.');
  }
}

Map<String, Object?> _normalizationLimitsJson(
        SourceNormalizationLimits limits) =>
    {
      'maxMaps': limits.maxMaps,
      'maxTotalCells': limits.maxTotalCells,
      'maxEvents': limits.maxEvents,
      'maxCommands': limits.maxCommands,
      'maxParameterNodes': limits.maxParameterNodes,
      'maxDiagnostics': limits.maxDiagnostics,
      'maxTotalBytes': limits.maxTotalBytes,
      'maxMetadataCells': limits.maxMetadataCells,
      'maxTotalIrNodes': limits.maxTotalIrNodes,
      'maxTotalTextCodeUnits': limits.maxTotalTextCodeUnits,
      'maxDiagnosticTextCodeUnits': limits.maxDiagnosticTextCodeUnits,
    };

Map<String, Object?> _writeLimitsJson(NativeWriteLimits limits) => {
      'maxArtifacts': limits.maxArtifacts,
      'maxMutations': limits.maxMutations,
      'maxArtifactBytes': limits.maxArtifactBytes,
      'maxTotalArtifactBytes': limits.maxTotalArtifactBytes,
      'maxImagePixels': limits.maxImagePixels,
      'maxMapCells': limits.maxMapCells,
      'jsonLimits': {
        'maxDepth': limits.jsonLimits.maxDepth,
        'maxNodes': limits.jsonLimits.maxNodes,
        'maxStringCodeUnits': limits.jsonLimits.maxStringCodeUnits,
        'maxTextCodeUnits': limits.jsonLimits.maxTextCodeUnits,
      },
    };

void _checkAcknowledgement(
    SourceSnapshot snapshot, SourceStudyAcknowledgement acknowledgement) {
  if (acknowledgement.sourceSnapshotHash != snapshot.canonicalHash ||
      acknowledgement.profileEvidenceHash != snapshot.profile.evidenceHash) {
    throw const ConverterWorkflowFailure('workflow.profile_ack',
        'The study acknowledgement belongs to different source bytes or evidence.');
  }
}

List<int> _availableMapIds(SourceSnapshot snapshot) {
  final names = RegExp(r'^Data/Map([0-9]+)\.rxdata$', caseSensitive: false);
  final ids = <int>{};
  for (final entry in snapshot.entries) {
    if (entry.kind != SourceNodeKind.file) continue;
    final match = names.firstMatch(entry.relativePath);
    if (match == null) continue;
    final id = int.tryParse(match.group(1)!);
    if (id != null && id > 0 && id <= 2147483647) ids.add(id);
  }
  return List.unmodifiable(ids.toList()..sort());
}

Future<void> _guardPreparationDestination(
    ConverterStudySettings settings, String sourceRoot) async {
  final String parent;
  try {
    parent = await Directory(settings.parentPath).resolveSymbolicLinks();
  } on FileSystemException {
    throw const ConverterWorkflowFailure('workflow.destination.invalid',
        'The destination parent must be an existing directory.');
  }
  if (await FileSystemEntity.type(parent, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw const ConverterWorkflowFailure('workflow.destination.invalid',
        'The destination parent is not a directory.');
  }
  if (path.equals(parent, sourceRoot) ||
      path.isWithin(sourceRoot, parent) ||
      path.isWithin(parent, sourceRoot)) {
    throw const ConverterWorkflowFailure('native.source.overlap',
        'The destination must be isolated from the source.');
  }
  final destination = path.join(parent, settings.folderName);
  if (await FileSystemEntity.type(destination, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw const ConverterWorkflowFailure(
        'native.destination.exists', 'The destination folder must be new.');
  }
}

ConverterWorkflowFailure _workflowFailure(Object error, {String? stagingPath}) {
  if (error is ConverterWorkflowFailure) {
    return ConverterWorkflowFailure(error.code, error.message,
        locator: error.locator,
        stagingPath: error.stagingPath ?? stagingPath,
        retryable: error.retryable);
  }
  String code;
  String message;
  String? locator;
  if (error is NativeWriteException) {
    code = error.code;
    message = error.message;
    stagingPath = error.stagingPath ?? stagingPath;
  } else if (error is ContractError) {
    code = error.code;
    message = error.message;
    locator = error.path;
  } else {
    return ConverterWorkflowFailure('workflow.failed', error.toString(),
        stagingPath: stagingPath);
  }
  if (code == 'source.cancelled' || code == 'native.cancelled') {
    code = 'workflow.cancelled';
  } else if (code.startsWith('source.') && code.contains('changed')) {
    code = 'workflow.source_changed';
  }
  return ConverterWorkflowFailure(code, message,
      locator: locator, stagingPath: stagingPath);
}

Sha256Hash _studyRulesHash() => canonicalHashOf({
      'kind': 'converterStudyRules',
      'version': 1,
      'converterVersion': _converterVersion,
      'sourceFormat': 'rmxp-marshal-4.8',
      'tilePolicy': 'literal-32px-stored-autotile-variant',
      'autotileAnimation':
          'attested-source-clock-or-explicit-first-frame-study',
      'assetLibrary': 'human-reviewed-static-parts-with-original-png-witnesses',
      'assetPlacements': 'attested-static-priority-elements',
      'sourceSemantics': 'kanto-profile-walking-cardinal-closed-unqualified',
      'sourcePlayer': 'attested-original-pixels-padded-without-resampling',
      'dimension': 'twoD',
      'template': 'empty',
      'tileSize': 32,
      'requestedMode': 'study',
      'events': 'sourceArchiveOnlyInactive',
      'gameplayMetadata': 'sourceArchiveOnly',
      'publication': false,
    });

Sha256Hash _reviewProposalGenerationHash(LocalAssetProposalSet proposals,
        List<int> selectedSourceMapIds, AssetOutputMode seedMode) =>
    canonicalHashOf({
      'kind': 'reviewProposalGeneration',
      'version': 1,
      'sourceSnapshotHash': proposals.sourceSnapshotHash.value,
      'normalizedSourceHash': proposals.normalizedSourceHash.value,
      'selectedSourceMapIds': selectedSourceMapIds,
      'outputMode': seedMode.name,
      'candidateHashes':
          proposals.candidates.map((c) => c.canonicalHash.value).toList(),
      'placementClaims': {
        for (final e in proposals.placementClaims.entries)
          e.key.value: e.value.map((claim) => claim.toJson()).toList(),
      },
      'sourceImages': proposals.sourceImages.map((s) => s.toJson()).toList(),
      'diagnostics': proposals.diagnostics.map((d) => d.toJson()).toList(),
    });

NativeProjectDraft? _mergeAssetLibrary(
    NativeProjectDraft? literal, ApprovedAssetLibraryComposition? library,
    {required NativeWriteLimits limits}) {
  if (literal == null || library == null) return literal;
  if (!library.canExport) return null;
  final draft = NativeProjectDraft(
      source: literal.source,
      projectName: literal.projectName,
      parentPath: literal.parentPath,
      folderName: literal.folderName,
      mapIds: literal.mapIds,
      artifacts: {
        for (final artifact in [...literal.artifacts, ...library.artifacts])
          artifact.handle: artifact,
      }.values.toList(),
      sourceArtifacts: {
        for (final artifact in [
          ...literal.sourceArtifacts,
          ...library.sourceArtifacts
        ])
          artifact.handle: artifact,
      }.values.toList(),
      mutations: [...literal.mutations, ...library.mutations],
      compositionEvidence: {
        ...literal.compositionEvidence,
        'assetLibrary': library.evidence,
      },
      sourceRootPath: literal.sourceRootPath,
      defaultMapWidth: literal.defaultMapWidth,
      defaultMapHeight: literal.defaultMapHeight,
      limits: limits);
  draft.validateResourceBudget(limits: limits);
  return draft;
}

const _nativeStudyActions = [
  'tileset.import_image',
  'tileset.upsert',
  'map.create',
  'map.save',
  'element_category.upsert',
  'element.upsert',
  'asset.import',
  'characterStudio.character.create',
  'characterStudio.animationClip.upsert',
  'characterStudio.character.setDefault',
];

TargetCapabilities _nativeCapabilities() => TargetCapabilities.fromJson({
      'schemaVersion': '1.0',
      'kind': 'targetCapabilities',
      'exampleOnly': false,
      'profileId': 'avelune-converter-native-study-ac12-v1',
      'repository': 'yoahnl/pokemap',
      'revision': '3a1209a6f8344d9826f0d5abbc509989ad4acab5',
      'capabilities': [
        for (final action in _nativeStudyActions)
          {
            'capabilityId': 'native.study.$action',
            'status': 'supported',
            'scope':
                'Canonical $action in verified empty twoD 32px native study staging projects.',
            'evidence': [
              {
                'type': 'test',
                'summary':
                    'AC-05 original PNG import, canonical create/save, strict fresh reopen and retained blob verification.',
                'reference':
                    'git:010297e9808c8e6c0a4e1b003eb4702adc78d9c9:documentation/reports/converter/AC-05/commands.json',
              },
              {
                'type': 'test',
                'summary':
                    'AC-06 ordinary source tiles, three native layers, strict native staging reopen and current Studio edit/save/reopen.',
                'reference':
                    'git:bc4706ae767621f3e6f806a193b590770026c66e:documentation/reports/converter/AC-06/commands.json',
              },
              {
                'type': 'test',
                'summary':
                    'AC-07 exact native animation upsert, immutable atlas geometry and strict timeline readback.',
                'reference':
                    'repo:packages/avelune_converter_adapters/test/native_project_writer_test.dart:AC-07',
              },
              {
                'type': 'test',
                'summary':
                    'AC-08 current human-reviewed library assets, exact source raster witnesses and canonical native definitions; map placements unchanged.',
                'reference':
                    'repo:packages/avelune_converter_adapters/test/approved_asset_library_test.dart:AC-08',
              },
            ],
            'limitations': [
              'Study staging only; published=false and playableCertified=false.',
              'Native events and complete gameplay remain uncertified. Static passages and occlusion require the admitted AC-12 source profile.',
              'Library anchors and disjoint parts are preserved in companion metadata; native placement replacement is not certified.',
              'Autotile animation requires source clock attestation; a first-frame study is explicitly degraded.',
              'The source profile remains observed or requires confirmation; acknowledging study does not confirm a version.',
            ],
          }
      ],
    });

ConversionPlan? _previewPlan(
    _WorkerRequest request,
    NormalizedSourceProject normalized,
    LiteralTileComposition composition,
    TargetCapabilities capabilities,
    NativeProjectDraft? draft,
    ReviewDecisions decisions,
    List<LocalAssetProposalDiagnostic> proposalDiagnostics,
    ApprovedAssetLibraryComposition? library) {
  final settings = request.settings!;
  if (draft == null || draft.mutations.isEmpty) return null;
  final findings = <Map<String, Object?>>[];
  void add(String code, String message, bool blocked,
      {Map<String, Object?>? locator,
      String cause = 'converterUnsupported',
      String family = 'maps',
      String? disposition}) {
    final index = findings.length;
    findings.add({
      'diagnosticId': 'study-finding-$index',
      'code': code,
      'severity': blocked ? 'error' : 'warning',
      'cause': cause,
      'family': family,
      'sourceLocator': locator,
      'message': message.length <= 2000 ? message : message.substring(0, 2000),
      'disposition': disposition ?? (blocked ? 'unresolved' : 'preservedOnly'),
      'blocksStudy': blocked,
      'blocksPlayableSlice': true,
      'acceptedByDecisionId': null,
    });
  }

  for (final diagnostic in normalized.diagnostics) {
    add(diagnostic.code, diagnostic.message, diagnostic.blocksPlanning,
        locator: diagnostic.locator.toJson(), cause: 'sourceInvalid');
  }
  for (final diagnostic in composition.diagnostics) {
    add(diagnostic.code, diagnostic.message, diagnostic.blocksPlanning,
        locator: _planLocator(normalized, diagnostic.locator),
        family: diagnostic.code.contains('profile') ? 'files' : 'maps',
        cause: diagnostic.code.contains('profile')
            ? 'ambiguous'
            : 'converterUnsupported',
        disposition: diagnostic.code.contains('excluded') ? 'excluded' : null);
  }
  for (final diagnostic in proposalDiagnostics) {
    add(diagnostic.code, diagnostic.message, false,
        locator: _planLocator(normalized, diagnostic.toJson()),
        cause: 'ambiguous',
        family: 'assets');
  }
  for (final diagnostic
      in library?.diagnostics ?? <ApprovedAssetLibraryDiagnostic>[]) {
    add(diagnostic.code, diagnostic.message, diagnostic.blocksExport,
        locator: diagnostic.locator?.toJson(), family: 'assets');
  }
  if (!settings.profileAcknowledgement.humanConfirmed) {
    add(
        'workflow.profile_ack',
        'The unconfirmed source profile has not been acknowledged for study.',
        true,
        cause: 'policy',
        family: 'files');
  }
  add(
      'workflow.study.gameplay',
      'Events and gameplay metadata are retained in the extracted source archive; native gameplay is not certified.',
      false,
      family: 'events');
  add(
      'workflow.study.publication',
      'The native result is verified staging; project publication requires a separate reviewed step.',
      false,
      cause: 'policy',
      family: 'publication',
      disposition: 'excluded');
  return ConversionPlan.fromJson({
    'schemaVersion': '1.0',
    'kind': 'conversionPlan',
    'exampleOnly': false,
    'planId': '${request.sessionId.value}.plan${request.revision}',
    'state': 'draft',
    'sourceSnapshotHash': normalized.snapshot.canonicalHash.value,
    'targetProfileHash': capabilities.canonicalHash.value,
    'rulesHash': _studyRulesHash().value,
    'decisionsHash': decisions.canonicalHash.value,
    'decisionRevision': request.revision,
    'converterVersion': _converterVersion,
    'logicalProjectNamespace':
        normalized.snapshot.logicalProjectNamespace.value,
    'requestedMode': 'study',
    'selectedSourceMapIds': settings.selectedSourceMapIds,
    'dependencySourceMapIds': composition.includedSourceMapIds,
    'outputPolicy': {
      'destinationFolderName': settings.folderName,
      'destinationMustBeNew': true,
      'offline': true,
      'assetOutputMode': settings.assetOutputMode.name,
    },
    'operations': [
      for (final mutation in draft.mutations)
        {
          'operationId': mutation.operationId.value,
          'domain': _mutationDomain(mutation.actionId),
          'sourceEntityIds':
              mutation.sourceEntityIds.map((id) => id.value).toList(),
          'targetEntityIds':
              mutation.targetEntityIds.map((id) => id.value).toList(),
          'targetActionId': mutation.actionId,
          'status': 'planned',
          'evidenceRefs': [
            draft.bindingEvidence,
            'source-study-ack-sha256:${settings.profileAcknowledgement.canonicalHash.value}',
            'study-settings-sha256:${settings.canonicalHash.value}',
          ],
        }
    ],
    'findings': findings,
    'approvedByHuman': false,
  }, limits: settings.writeLimits.jsonLimits);
}

Map<String, Object?>? _planLocator(
    NormalizedSourceProject source, Map<String, Object?> input) {
  String? file = input['file'] as String?;
  final fileId = input['fileId'];
  if (file == null && fileId is String) {
    for (final entry in source.snapshot.entries) {
      if (entry.fileId.value == fileId) file = entry.relativePath;
    }
  }
  if (file == null && input['mapId'] is int) {
    for (final map in source.maps) {
      if (map.map.sourceMapId == input['mapId']) {
        for (final entry in source.snapshot.entries) {
          if (entry.fileId == map.map.sourceFileId) file = entry.relativePath;
        }
      }
    }
  }
  if (file == null || file.isEmpty || file.length > 2048) return null;
  return {
    'file': file,
    for (final key in [
      'mapId',
      'eventId',
      'pageIndex',
      'commandIndex',
      'tileId',
      'line'
    ])
      key: input[key] is int ? input[key] : null,
  };
}

PlanContext _planContext(
    PreparedStudy prepared, ConversionPlan plan, ConverterId sessionId) {
  final source = prepared.normalizedSource;
  final mutations = prepared.nativeDraft!.mutations;
  return PlanContext(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      sourceSnapshotHash: prepared.sourceSnapshotHash,
      sessionId: sessionId,
      targetCapabilities: prepared.targetCapabilities,
      rulesHash: _studyRulesHash(),
      decisions: prepared.reviewDecisions,
      candidates: prepared.assetCandidates,
      converterVersion: _converterVersion,
      approvedPlanHash: plan.canonicalHash,
      sourceMapIds: source.selectedSourceMapIds.toSet(),
      sourceEntityIds:
          mutations.expand((value) => value.sourceEntityIds).toSet(),
      targetEntityIds:
          mutations.expand((value) => value.targetEntityIds).toSet(),
      actionCapabilities: {
        for (final action in _nativeStudyActions)
          action: ConverterId('native.study.$action'),
      },
      approvedCandidateHashes: prepared.approvedCandidateHashes);
}

String _mutationDomain(String action) =>
    action.startsWith('map.') ? 'maps' : 'assets';
