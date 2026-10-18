import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

import 'approved_asset_library.dart';
import 'converter_asset_review_set.dart';
import 'converter_study_plan_recipe.dart';
import 'literal_tile_composer.dart';
import 'source_semantic_study_composer.dart';
import 'source_event_study_composer.dart';
import 'source_catalog_study_composer.dart';
import 'native_encounter_catalog_bindings.dart';
import 'native_psdk_catalog.dart';
import 'local_asset_proposer.dart';
import 'supplemented_source_tree.dart';
import 'native_project_writer.dart';
import 'native_project_publication.dart';
import 'snapshot_source_files.dart';

enum ConverterWorkflowPhase {
  scan,
  verifySource,
  normalize,
  compose,
  writeNative,
  verifyNative,
  publishNative,
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
    List<String> supplementalRootPaths = const [],
    required ConverterId logicalProjectNamespace,
    SourceScanPolicy? policy,
  }) {
    _workflowPath(rootPath);
    if (supplementalRootPaths.length >
        SupplementedSourceTree.maxSupplementalRoots) {
      throw const ConverterWorkflowFailure('workflow.source_roots.invalid',
          'Choose at most four distinct supplemental folders.');
    }
    String canonical(String value) {
      _workflowPath(value);
      try {
        return Directory(value).resolveSymbolicLinksSync();
      } on FileSystemException {
        return path.normalize(value);
      }
    }

    final primary = canonical(rootPath);
    final roots = supplementalRootPaths.map(canonical).toList();
    if (roots.length > SupplementedSourceTree.maxSupplementalRoots ||
        {primary, ...roots}.length != roots.length + 1) {
      throw const ConverterWorkflowFailure('workflow.source_roots.invalid',
          'Choose at most four distinct supplemental folders.');
    }
    return ConverterSourceSelection._(primary, List.unmodifiable(roots),
        logicalProjectNamespace, policy ?? SourceScanPolicy());
  }

  const ConverterSourceSelection._(this.rootPath, this.supplementalRootPaths,
      this.logicalProjectNamespace, this.policy);

  final String rootPath;
  final List<String> supplementalRootPaths;
  List<String> get sourceRoots =>
      List.unmodifiable([rootPath, ...supplementalRootPaths]);
  final ConverterId logicalProjectNamespace;
  final SourceScanPolicy policy;

  Sha256Hash get canonicalHash => canonicalHashOf({
        'rootPath': rootPath,
        'supplementalRootPaths': supplementalRootPaths,
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
    List<SourceImageBinding> imageBindings = const [],
    bool allowFirstFrameAutotiles = false,
    AssetOutputMode assetOutputMode = AssetOutputMode.sharedAtlas,
    ConverterAssetReviewSet? reviewSet,
    SourceNormalizationLimits normalizationLimits =
        const SourceNormalizationLimits(),
    NativeWriteLimits? writeLimits,
  }) {
    writeLimits ??=
        sourceCatalogStudyWriteLimitsFor(selectedSourceMapIds.length,
            includeNativeCatalog: true);
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
        selectedSourceMapIds.length > writeLimits.maxMaps ||
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
    if (reviewSet != null &&
        (reviewSet.outputMode != assetOutputMode ||
            canonicalJsonOf(reviewSet.selectedSourceMapIds.toList()..sort()) !=
                canonicalJsonOf(ids))) {
      throw const ConverterWorkflowFailure('workflow.review_set.stale',
          'The review session and the selected study context differ.');
    }
    if (reviewSet != null) {
      ConverterAssetReviewSet.fromJson(reviewSet.toJson(),
          admissionLimits: converterAssetReviewSetLimitsFor(writeLimits));
    }
    final decisions = dependencyDecisions.toList()
      ..sort((a, b) => a.canonicalHash.value.compareTo(b.canonicalHash.value));
    final bindings = SourceImageBinding.canonicalize(imageBindings);
    return ConverterStudySettings._(
        projectName.trim(),
        path.normalize(parentPath),
        folderName,
        List.unmodifiable(ids),
        profileAcknowledgement,
        List.unmodifiable(decisions),
        bindings,
        allowFirstFrameAutotiles,
        assetOutputMode,
        reviewSet,
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
      this.imageBindings,
      this.allowFirstFrameAutotiles,
      this.assetOutputMode,
      this.reviewSet,
      this.normalizationLimits,
      this.writeLimits);

  final String projectName;
  final String parentPath;
  final String folderName;
  final List<int> selectedSourceMapIds;
  final SourceStudyAcknowledgement profileAcknowledgement;
  final List<LiteralDependencyDecision> dependencyDecisions;
  final List<SourceImageBinding> imageBindings;
  final bool allowFirstFrameAutotiles;
  final AssetOutputMode assetOutputMode;
  final ConverterAssetReviewSet? reviewSet;
  final SourceNormalizationLimits normalizationLimits;
  final NativeWriteLimits writeLimits;

  Map<String, Object?> toJson() => _json(includeReviewSet: true);

  Map<String, Object?> _json({required bool includeReviewSet}) => {
        'kind': 'converterStudySettings',
        'version': 4,
        'projectName': projectName,
        'parentPath': parentPath,
        'folderName': folderName,
        'selectedSourceMapIds': selectedSourceMapIds,
        'profileAcknowledgement': profileAcknowledgement.toJson(),
        'dependencyDecisions':
            dependencyDecisions.map((value) => value.toJson()).toList(),
        'imageBindings': imageBindings.map((value) => value.toJson()).toList(),
        'allowFirstFrameAutotiles': allowFirstFrameAutotiles,
        'assetOutputMode': assetOutputMode.name,
        if (includeReviewSet) 'reviewSet': reviewSet?.toJson(),
        if (!includeReviewSet) 'reviewSetHash': reviewSet?.canonicalHash.value,
        'normalizationLimits': _normalizationLimitsJson(normalizationLimits),
        'writeLimits': _writeLimitsJson(writeLimits),
      };

  Sha256Hash get canonicalHash =>
      canonicalHashOf(_json(includeReviewSet: false),
          limits: writeLimits.jsonLimits);
}

ConverterAssetReviewSetLimits converterAssetReviewSetLimitsFor(
    NativeWriteLimits limits) {
  limits.validate();
  const defaults = ContractLimits();
  final json = ContractLimits(
      maxDepth: limits.jsonLimits.maxDepth.clamp(1, defaults.maxDepth),
      maxNodes: limits.jsonLimits.maxNodes.clamp(1, defaults.maxNodes),
      maxStringCodeUnits: limits.jsonLimits.maxStringCodeUnits
          .clamp(1, defaults.maxStringCodeUnits),
      maxTextCodeUnits: limits.jsonLimits.maxTextCodeUnits
          .clamp(1, defaults.maxTextCodeUnits));
  return ConverterAssetReviewSetLimits(
      maxTotalCandidates: limits.maxMutations.clamp(1, 1024),
      maxSegments: limits.maxMutations.clamp(1, 256),
      maxJsonBytes: limits.maxTotalDraftJsonBytes.clamp(1, 8388608),
      jsonLimits: json,
      segmentLimits: AssetReviewLimits(jsonLimits: json));
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
    required this.assetProposalsByMap,
    required this.assetProposalDiagnostics,
    required this.assetCandidates,
    required this.assetLibrary,
    required this.reviewDecisions,
    required this.approvedCandidateHashes,
    required this.nativeDraft,
    required this.previewPlan,
    required this.targetCapabilities,
    required this.canApprove,
    this.reviewSet,
  });

  final int sessionRevision;
  final Sha256Hash preparationHash;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash profileEvidenceHash;
  final ConverterStudySettings settings;
  final NormalizedSourceProject normalizedSource;
  final LiteralTileComposition composition;
  final Map<int, LocalAssetProposalSet>? assetProposalsByMap;
  final List<LocalAssetProposalDiagnostic> assetProposalDiagnostics;
  final List<AssetCandidate> assetCandidates;
  final ApprovedAssetLibraryComposition? assetLibrary;
  final ReviewDecisions reviewDecisions;
  final Map<ConverterId, Sha256Hash> approvedCandidateHashes;
  final NativeProjectDraft? nativeDraft;
  final ConversionPlan? previewPlan;
  final TargetCapabilities targetCapabilities;
  final bool canApprove;
  final ConverterAssetReviewSet? reviewSet;
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
    required this.publication,
    required this.sourceSnapshotHash,
    required this.preparationHash,
    required this.approvedPlanHash,
    required this.sessionRevision,
    required this.sourceUnchanged,
    required this.sourceSelection,
    required this.sharedSourceFiles,
  });

  final NativeWriteReceipt receipt;
  final NativePublicationReceipt publication;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash preparationHash;
  final Sha256Hash approvedPlanHash;
  final int sessionRevision;
  final bool sourceUnchanged;
  final ConverterSourceSelection sourceSelection;
  final List<ConverterSharedSourceFile> sharedSourceFiles;
  Map<String, Object?> get sourceProvenanceReceipt => {
        'kind': 'converterSourceProvenance',
        'version': 2,
        'sourceSelectionHash': sourceSelection.canonicalHash.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'preparationHash': preparationHash.value,
        'approvedPlanHash': approvedPlanHash.value,
        'nativeDraftHash': publication.draftHash.value,
        'nativeInventoryHash': publication.inventoryHash.value,
        'sourceRootPath': sourceSelection.rootPath,
        'supplementalRootPaths': sourceSelection.supplementalRootPaths,
        'sharedSourceFiles':
            sharedSourceFiles.map((file) => file.toJson()).toList(),
      };
  String get projectPath => publication.projectPath;
  bool get published => publication.published;
  bool get playableCertified => false;
}

final class ConverterWorkflowFailure implements Exception {
  const ConverterWorkflowFailure(this.code, this.message,
      {this.locator,
      this.stagingPath,
      this.journalPath,
      this.destinationPath,
      this.promotionMayHaveOccurred = false,
      this.retryable = true});

  final String code;
  final String message;
  final String? locator;
  final String? stagingPath;
  final String? journalPath;
  final String? destinationPath;
  final bool promotionMayHaveOccurred;
  final bool retryable;

  @override
  String toString() => '$code: $message';
}

final class ConverterWorkflowState {
  const ConverterWorkflowState._({
    this.revision = 1,
    this.source,
    this.snapshot,
    this.sourceCatalog,
    this.sharedSourceFiles = const [],
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
  final NormalizedSourceProject? sourceCatalog;
  final List<ConverterSharedSourceFile> sharedSourceFiles;
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
    Object? sourceCatalog = _keep,
    List<ConverterSharedSourceFile>? sharedSourceFiles,
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
        sourceCatalog: identical(sourceCatalog, _keep)
            ? this.sourceCatalog
            : sourceCatalog as NormalizedSourceProject?,
        sharedSourceFiles: sharedSourceFiles ?? this.sharedSourceFiles,
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
  ConverterWorkflow(
      {this.checkpoint, this.nativeWriteCheckpoint, this.publicationCheckpoint})
      : _sessionId = ConverterId(
            'converter-workflow:${DateTime.now().microsecondsSinceEpoch}:${_workflowSequence++}');

  final ConverterWorkflowCheckpoint? checkpoint;
  final NativeWriteCheckpoint? nativeWriteCheckpoint;
  final NativePublicationCheckpoint? publicationCheckpoint;
  final StreamController<ConverterWorkflowEvent> _events =
      StreamController.broadcast();
  ConverterWorkflowState _state = const ConverterWorkflowState._();
  ConverterId _sessionId;
  bool _restoringRecipe = false;
  _WorkflowRun? _active;
  bool _disposed = false;
  int _attemptOrdinal = 0;

  ConverterWorkflowState get state => _state;
  Stream<ConverterWorkflowEvent> get events => _events.stream;

  bool get canRestoreStudyPlanRecipe =>
      !_disposed &&
      !_restoringRecipe &&
      !_state.isBusy &&
      _state.source == null &&
      _state.revision == 1 &&
      _attemptOrdinal == 0;

  ConverterStudyPlanRecipe exportStudyPlanRecipe() {
    _requireIdle();
    final prepared = _state.prepared;
    if (prepared == null ||
        prepared.sessionRevision != _state.revision ||
        !prepared.canApprove ||
        prepared.nativeDraft == null ||
        prepared.previewPlan == null) {
      throw const ConverterWorkflowFailure('workflow.recipe.unavailable',
          'Prepare a current, reviewable study plan before exporting its recipe.');
    }
    return _studyPlanRecipe(prepared);
  }

  ConverterStudyPlanRecipe _studyPlanRecipe(PreparedStudy prepared) {
    final approved = _approvedPreview(prepared);
    return ConverterStudyPlanRecipe(
        sessionId: _sessionId,
        sessionRevision: prepared.sessionRevision,
        sourceSelection: _state.source!,
        sharedSourceFiles: _state.sharedSourceFiles,
        settings: prepared.settings,
        sourceSnapshotHash: prepared.sourceSnapshotHash,
        profileEvidenceHash: prepared.profileEvidenceHash,
        settingsHash: prepared.settings.canonicalHash,
        nativeDraftHash: prepared.nativeDraft!.canonicalHash,
        preparationHash: prepared.preparationHash,
        previewPlanHash: prepared.previewPlan!.canonicalHash,
        approvedPlanHash: approved.canonicalHash,
        targetCapabilitiesHash: prepared.targetCapabilities.canonicalHash,
        rulesHash: _studyRulesHash(),
        converterVersion: _converterVersion);
  }

  Future<PreparedStudy> restoreStudyPlanRecipe(
      ConverterStudyPlanRecipe recipe) async {
    _requireIdle();
    if (!canRestoreStudyPlanRecipe) {
      throw const ConverterWorkflowFailure('workflow.recipe.not_fresh',
          'Restore requires a new, unused workflow.');
    }
    if (recipe.converterVersion != _converterVersion ||
        recipe.rulesHash != _studyRulesHash() ||
        recipe.targetCapabilitiesHash != _nativeCapabilities().canonicalHash) {
      throw const ConverterWorkflowFailure('workflow.recipe.stale',
          'This recipe belongs to a different converter or target contract.');
    }
    _restoringRecipe = true;
    _sessionId = recipe.sessionId;
    _state = ConverterWorkflowState._(revision: recipe.sessionRevision - 2);
    try {
      final snapshot =
          await _scanSource(recipe.sourceSelection, restoringRecipe: true);
      if (_state.cancellationRequested) {
        throw const ConverterWorkflowFailure(
            'workflow.cancelled', 'Recipe restoration was cancelled.');
      }
      if (snapshot.state != SourceScanState.complete ||
          snapshot.canonicalHash != recipe.sourceSnapshotHash ||
          snapshot.profile.evidenceHash != recipe.profileEvidenceHash) {
        throw const ConverterWorkflowFailure('workflow.source_changed',
            'The fresh source inventory or profile differs from the saved recipe.');
      }
      if (canonicalHashOf(
              recipe.sharedSourceFiles.map((file) => file.toJson()).toList()) !=
          canonicalHashOf(
              _state.sharedSourceFiles.map((file) => file.toJson()).toList())) {
        throw const ConverterWorkflowFailure(
            'workflow.source_provenance_changed',
            'Source file origins differ from the saved recipe.');
      }
      _updateSettings(recipe.settings, restoringRecipe: true);
      final prepared = await _prepareStudy(restoringRecipe: true);
      if (_state.cancellationRequested) {
        throw const ConverterWorkflowFailure(
            'workflow.cancelled', 'Recipe restoration was cancelled.');
      }
      if (!prepared.canApprove ||
          prepared.nativeDraft == null ||
          prepared.previewPlan == null ||
          _studyPlanRecipe(prepared).canonicalHash != recipe.canonicalHash) {
        _state = _state._copy(prepared: null, approval: null);
        throw const ConverterWorkflowFailure('workflow.recipe.stale',
            'Fresh composition does not reproduce the exact saved study plan.');
      }
      _state = _state._copy(prepared: prepared, approval: null);
      return prepared;
    } catch (error) {
      _state = _state._copy(prepared: null, approval: null);
      throw _recordFailure(error);
    } finally {
      _restoringRecipe = false;
      _emit(ConverterWorkflowEventKind.changed);
    }
  }

  Future<SourceSnapshot> scanSource(ConverterSourceSelection source) =>
      _scanSource(source);

  Future<SourceSnapshot> _scanSource(ConverterSourceSelection source,
      {bool restoringRecipe = false}) async {
    _requireIdle(restoringRecipe: restoringRecipe);
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
          sourceCatalog: outcome.sourceCatalog,
          sharedSourceFiles: outcome.sharedSourceFiles,
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

  void updateSettings(ConverterStudySettings settings) =>
      _updateSettings(settings);

  void _updateSettings(ConverterStudySettings settings,
      {bool restoringRecipe = false}) {
    _requireIdle(restoringRecipe: restoringRecipe);
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

  Future<PreparedStudy> prepareStudy() => _prepareStudy();

  Future<PreparedStudy> _prepareStudy({bool restoringRecipe = false}) async {
    _requireIdle(restoringRecipe: restoringRecipe);
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
          sharedSourceFiles: _state.sharedSourceFiles,
          settings: settings));
      final prepared = outcome.prepared!;
      _state = _state._copy(
          prepared: restoringRecipe ? null : prepared,
          isBusy: false,
          failure: null);
      _emit(ConverterWorkflowEventKind.completed);
      return prepared;
    } catch (error) {
      throw _recordFailure(error);
    }
  }

  ConversionPlan _approvedPreview(PreparedStudy prepared) =>
      ConversionPlan.fromJson({
        ...prepared.previewPlan!.toJson(),
        'state': 'ready',
        'approvedByHuman': true,
      }, limits: prepared.settings.writeLimits.jsonLimits);

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
    final approved = _approvedPreview(prepared);
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
          sharedSourceFiles: _state.sharedSourceFiles,
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
    if (_disposed ||
        (!_state.isBusy && !_restoringRecipe) ||
        _state.cancellationRequested) {
      return;
    }
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

  void _requireIdle({bool restoringRecipe = false}) {
    if (_disposed) {
      throw const ConverterWorkflowFailure(
          'workflow.disposed', 'The workflow is closed.',
          retryable: false);
    }
    if (_state.isBusy || (_restoringRecipe && !restoringRecipe)) {
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
          run.done.completeError(ConverterWorkflowFailure(
              'workflow.worker_failed', 'The worker exited without a result.',
              stagingPath: run.stagingRoot,
              journalPath: run.journalPath,
              destinationPath: run.destinationPath,
              promotionMayHaveOccurred: run.promotionMayHaveOccurred));
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
        run.stagingRoot = message.stagingRoot ?? run.stagingRoot;
        run.journalPath = message.journalPath ?? run.journalPath;
        run.destinationPath = message.destinationPath ?? run.destinationPath;
        if (message.publicationStage ==
                NativePublicationStage.publishIntentDurable ||
            message.publicationStage ==
                NativePublicationStage.promotedBeforeReceipt) {
          run.promotionMayHaveOccurred = true;
        }
        unawaited(_handleCheckpoint(run, message));
      } else if (message is _WorkerContextRequest) {
        _replyCurrentContext(run, message);
      } else if (message is _WorkerOutcome) {
        run.outcome = message;
      } else if (message is List && !run.done.isCompleted) {
        run.outcome = _WorkerOutcome(
            failure: ConverterWorkflowFailure(
                'workflow.worker_failed', message.first.toString(),
                stagingPath: run.stagingRoot,
                journalPath: run.journalPath,
                destinationPath: run.destinationPath,
                promotionMayHaveOccurred: run.promotionMayHaveOccurred));
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
      if (message.publicationStage != null) {
        await publicationCheckpoint?.call(message.publicationStage!);
      } else if (message.stage == null) {
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

  void _replyCurrentContext(_WorkflowRun run, _WorkerContextRequest message) {
    PlanContext? context;
    ConverterWorkflowFailure? failure;
    try {
      final prepared = _state.prepared;
      final approval = run.request.approval;
      if (_disposed ||
          _state.cancellationRequested ||
          prepared == null ||
          approval == null ||
          _state.revision != run.request.revision ||
          _state.settings?.canonicalHash != prepared.settings.canonicalHash ||
          approval.approvedPlanHash != approval.approvedPlan.canonicalHash ||
          prepared.preparationHash != approval.preparationHash ||
          _state.snapshot?.canonicalHash != prepared.sourceSnapshotHash ||
          _state.source?.logicalProjectNamespace !=
              prepared.normalizedSource.snapshot.logicalProjectNamespace) {
        throw const ConverterWorkflowFailure('workflow.stale_publication',
            'The active session no longer admits this publication.');
      }
      context = _planContext(prepared, approval.approvedPlan, _sessionId,
          targetCapabilities: _nativeCapabilities());
      admitPlan(approval.approvedPlan, context);
    } catch (error) {
      failure = _workflowFailure(error);
    }
    if (identical(_active, run) && !run.exited) {
      run.control
          ?.send(_WorkerControl.context(message.ackId, context, failure));
    }
  }
}

const _keep = Object();
int _workflowSequence = 0;
const _converterVersion = 'avelune-converter-ac16-study-v2';

enum _WorkerKind { scan, prepare, write }

final class _WorkerRequest {
  const _WorkerRequest({
    required this.kind,
    required this.sessionId,
    required this.revision,
    required this.source,
    this.sharedSourceFiles = const [],
    this.snapshot,
    this.settings,
    this.prepared,
    this.approval,
  });
  final _WorkerKind kind;
  final ConverterId sessionId;
  final int revision;
  final ConverterSourceSelection source;
  final List<ConverterSharedSourceFile> sharedSourceFiles;
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
  String? stagingRoot;
  String? journalPath;
  String? destinationPath;
  bool promotionMayHaveOccurred = false;
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
        failure = null,
        context = null;
  const _WorkerControl.ack(this.ackId, this.failure) : context = null;
  const _WorkerControl.context(this.ackId, this.context, this.failure);
  final int? ackId;
  final ConverterWorkflowFailure? failure;
  final PlanContext? context;
}

final class _WorkerContextRequest {
  const _WorkerContextRequest(this.ackId);
  final int ackId;
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
    this.publicationStage,
    this.journalPath,
    this.destinationPath,
  });
  final int ackId;
  final ConverterId jobId;
  final ConverterWorkflowPhase phase;
  final NativeWriteStage? stage;
  final String? stagingRoot;
  final String? projectPath;
  final NativePublicationStage? publicationStage;
  final String? journalPath;
  final String? destinationPath;
}

final class _WorkerOutcome {
  const _WorkerOutcome(
      {this.snapshot,
      this.sourceCatalog,
      this.sharedSourceFiles = const [],
      this.prepared,
      this.result,
      this.failure});
  final SourceSnapshot? snapshot;
  final NormalizedSourceProject? sourceCatalog;
  final List<ConverterSharedSourceFile> sharedSourceFiles;
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
        for (final waiter in contextWaiters.values.toList()) {
          if (!waiter.isCompleted) {
            waiter.completeError(const ConverterWorkflowFailure(
                'workflow.cancelled', 'The job was cancelled.'));
          }
        }
      } else {
        final contextWaiter = contextWaiters[message.ackId];
        if (contextWaiter != null && !contextWaiter.isCompleted) {
          if (message.failure != null) {
            contextWaiter.completeError(message.failure!);
          } else if (message.context != null) {
            contextWaiter.complete(message.context!);
          } else {
            contextWaiter.completeError(const ConverterWorkflowFailure(
                'workflow.context_missing', 'The active context is missing.'));
          }
        }
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
  final Map<int, Completer<PlanContext>> contextWaiters = {};
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
      String? projectPath,
      NativePublicationStage? publicationStage,
      String? journalPath,
      String? destinationPath}) async {
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
        projectPath: projectPath,
        publicationStage: publicationStage,
        journalPath: journalPath,
        destinationPath: destinationPath));
    try {
      await waiter.future;
      cancellation.check();
    } finally {
      waiters.remove(ackId);
    }
  }

  Future<PlanContext> readCurrentContext() async {
    cancellation.check();
    final ackId = ++ackIndex;
    final waiter = Completer<PlanContext>();
    contextWaiters[ackId] = waiter;
    launch.parent.send(_WorkerContextRequest(ackId));
    try {
      final context = await waiter.future;
      cancellation.check();
      return context;
    } finally {
      contextWaiters.remove(ackId);
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
  SupplementedSourceTree? tree;
  NativeWriteReceipt? receipt;
  NativePublicationJob? publicationJob;
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
    tree = await SupplementedSourceTree.open(request.source.rootPath,
        supplementalRootPaths: request.source.supplementalRootPaths);
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
      NormalizedSourceProject? catalog;
      if (snapshot.state == SourceScanState.complete) {
        final files = await SnapshotSourceFiles.bind(
            source: source,
            snapshot: snapshot,
            policy: request.source.policy,
            cancellation: relay.cancellation);
        catalog = await const RmxpSourceNormalizer().inspectMapHierarchy(
            snapshot: snapshot, files: files, cancellation: relay.cancellation);
        relay.cancellation.check();
      }
      if (snapshot.state == SourceScanState.complete) relay.finish();
      outcome = _WorkerOutcome(
          snapshot: snapshot,
          sourceCatalog: catalog,
          sharedSourceFiles: tree.sharedSourceFilesFor(snapshot));
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
      final boundTree = tree;
      void verifyProvenance() {
        final expected = canonicalHashOf(
            request.sharedSourceFiles.map((file) => file.toJson()).toList());
        final observed = canonicalHashOf(boundTree
            .sharedSourceFilesFor(snapshot)
            .map((file) => file.toJson())
            .toList());
        if (expected != observed) {
          throw const ConverterWorkflowFailure(
              'workflow.source_provenance_changed',
              'Source file origins changed; scan and prepare a new exact draft.');
        }
      }

      verifyProvenance();
      relay.finish();
      final files = await SnapshotSourceFiles.bind(
          source: source,
          snapshot: snapshot,
          policy: request.source.policy,
          cancellation: relay.cancellation);
      verifyProvenance();
      Future<void> verifySourceUnchanged() async {
        await files.verifyUnchanged();
        verifyProvenance();
      }

      if (request.kind == _WorkerKind.prepare) {
        final settings = request.settings!;
        _checkAcknowledgement(snapshot, settings.profileAcknowledgement);
        await _guardPreparationDestination(settings, tree.sourceRoots);
        final wanted = settings.selectedSourceMapIds.toSet();
        for (final decision in settings.dependencyDecisions) {
          if (decision.decision == LiteralDependencyDisposition.include) {
            final target = decision.targetSourceMapId;
            if (target == null) {
              throw const ConverterWorkflowFailure('workflow.selection.invalid',
                  'A dynamic transfer cannot include an unknown destination');
            }
            wanted.add(target);
          }
        }
        if (wanted.length > settings.normalizationLimits.maxMaps ||
            wanted.length > settings.writeLimits.maxMaps ||
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
            selectedMapIds: wanted,
            imageBindings: settings.imageBindings,
            includeEventSystem: true,
            includeConnections: snapshot.entries.any((entry) =>
                entry.kind == SourceNodeKind.file &&
                sourcePathCollisionKey(entry.relativePath) ==
                    'data/map_connections.dat'));
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
        Map<int, LocalAssetProposalSet>? proposals;
        final proposalDiagnostics = <LocalAssetProposalDiagnostic>[];
        final reviewLimits =
            converterAssetReviewSetLimitsFor(settings.writeLimits);
        final seedMode =
            settings.reviewSet?.seedOutputMode ?? settings.assetOutputMode;
        if (composition.canWrite) {
          try {
            proposals = await const LocalAssetProposer().proposeByMap(
                source: normalized,
                files: files,
                literal: composition,
                outputMode: seedMode,
                limits: LocalAssetProposalLimits(
                    maxSourceImages:
                        settings.writeLimits.maxArtifacts.clamp(1, 32),
                    maxSourceBytes: settings.writeLimits.maxTotalArtifactBytes
                        .clamp(1, 67108864),
                    maxPixels: settings.writeLimits.maxImagePixels,
                    maxMapCells:
                        settings.writeLimits.maxMapCells.clamp(1, 1048576),
                    maxCandidates: reviewLimits.maxTotalCandidates,
                    jsonLimits: reviewLimits.jsonLimits),
                cancellation: relay.cancellation);
            proposalDiagnostics
                .addAll(proposals.values.expand((p) => p.diagnostics));
          } on ContractError catch (error) {
            if (error.code != 'asset.proposal.quota') rethrow;
            proposalDiagnostics.add(LocalAssetProposalDiagnostic(error.code,
                '${error.toString()} No partial proposals were retained. Literal map conversion remains available.'));
          }
        }
        ConverterAssetReviewSet? reviewSet;
        if (proposals != null) {
          final supplied = settings.reviewSet;
          final proposalIds = proposals.keys.toList()..sort();
          if (supplied != null &&
              (supplied.sourceSnapshotHash != snapshot.canonicalHash ||
                  supplied.logicalProjectNamespace !=
                      snapshot.logicalProjectNamespace ||
                  supplied.normalizedSourceHash != normalized.canonicalHash ||
                  canonicalJsonOf(supplied.proposalSourceMapIds) !=
                      canonicalJsonOf(proposalIds))) {
            throw const ConverterWorkflowFailure('workflow.review_set.stale',
                'The review set does not match the fresh normalized map scope.');
          }
          final segments = <int, AssetReviewSession>{};
          for (final entry in proposals.entries) {
            final generationHash = _reviewProposalGenerationHash(
                entry.key,
                entry.value,
                settings.selectedSourceMapIds,
                seedMode,
                reviewLimits.jsonLimits);
            final child = supplied?.segments[entry.key];
            if (child != null) {
              if (child.proposalGenerationHash != generationHash ||
                  _reviewSeedHash(
                          child.frames.first.candidates,
                          child.frames.first.placementClaims,
                          child.frames.first.outputMode,
                          reviewLimits.jsonLimits) !=
                      _reviewSeedHash(
                          entry.value.candidates,
                          entry.value.placementClaims,
                          seedMode,
                          reviewLimits.jsonLimits) ||
                  child.frames.first.decisions.isNotEmpty ||
                  child.frames.first.approvedCandidateHashes.isNotEmpty ||
                  child.frames.first.visionProposals.isNotEmpty ||
                  canonicalHashOf({
                        for (final c in entry.value.candidates)
                          c.candidateId.value: c.canonicalHash.value
                      }, limits: reviewLimits.jsonLimits) !=
                      canonicalHashOf({
                        for (final e in child.baseProposalHashes.entries)
                          e.key.value: e.value.value
                      }, limits: reviewLimits.jsonLimits)) {
                throw const ConverterWorkflowFailure(
                    'workflow.review_set.stale',
                    'A stored review segment seed differs from its fresh source proposals.');
              }
              const LocalAssetProposer().validatePlacementClaimsBatch(
                  source: normalized,
                  literal: composition,
                  candidates: child.activeCandidates,
                  placementClaims: child.frame.placementClaims);
              segments[entry.key] = child;
            } else {
              segments[entry.key] = AssetReviewSession.create(
                  sessionId: ConverterId(
                      '${request.sessionId.value}.review${request.revision}.map${entry.key}'),
                  logicalProjectNamespace: snapshot.logicalProjectNamespace,
                  sourceSnapshotHash: snapshot.canonicalHash,
                  selectedSourceMapIds: settings.selectedSourceMapIds,
                  outputMode: settings.assetOutputMode,
                  proposalGenerationHash: generationHash,
                  candidates: entry.value.candidates,
                  placementClaims: entry.value.placementClaims,
                  sourceMaps: normalized.maps,
                  limits: reviewLimits.segmentLimits);
            }
          }
          reviewSet = supplied ??
              ConverterAssetReviewSet.create(
                  sessionId: ConverterId(
                      '${request.sessionId.value}.review${request.revision}'),
                  logicalProjectNamespace: snapshot.logicalProjectNamespace,
                  sourceSnapshotHash: snapshot.canonicalHash,
                  normalizedSourceHash: normalized.canonicalHash,
                  selectedSourceMapIds: settings.selectedSourceMapIds,
                  proposalSourceMapIds: proposalIds,
                  segments: segments,
                  limits: reviewLimits);
          reviewSet.validatePlacements(normalized.maps);
        } else if (settings.reviewSet != null) {
          throw const ConverterWorkflowFailure('workflow.review_set.stale',
              'The fresh proposal generation is unavailable for review attestation.');
        }
        final candidates =
            reviewSet?.activeCandidates ?? const <AssetCandidate>[];
        final decisions = ReviewDecisions.fromJson({
          'schemaVersion': '1.0',
          'kind': 'reviewDecisions',
          'exampleOnly': false,
          'sessionId': request.sessionId.value,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'revision': request.revision,
          'decisions': reviewSet?.activeDecisions.toJson()['decisions'] ??
              const <Object?>[],
        }, limits: reviewLimits.jsonLimits);
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
        final encounters = await NativeEncounterCatalogQualification.prepareAutomatic(
            source: normalized, files: files,
            selectedSourceMapIds: settings.selectedSourceMapIds,
            cancellation: relay.cancellation);
        final semantic = await SourceSemanticStudyComposer(
            includeNativeSurfTraversal: encounters != null).compose(
            source: normalized,
            base: composition,
            files: files,
            limits: settings.writeLimits,
            cancellation: relay.cancellation);
        final events = semantic == null
            ? null
            : await SourceEventStudyComposer(nativeEncounterQualification: encounters).compose(
                source: normalized,
                base: semantic,
                files: files,
                limits: settings.writeLimits,
                cancellation: relay.cancellation);
        final preceding = events?.draft ?? semantic ?? composition.draft;
        final catalogs = preceding == null
            ? null
            : await SourceCatalogStudyComposer(nativeEncounterQualification: encounters,
                nativeTrainerQualification: events?.trainerQualification,
                nativeTrainerCatalog: events?.pokemonGiftCatalog,
                includeNativeEncounterConsumers: encounters != null).compose(
                source: normalized,
                base: preceding,
                files: files,
                limits: settings.writeLimits,
                cancellation: relay.cancellation);
        final draft = _mergeAssetLibrary(catalogs?.draft ?? preceding, library,
            limits: settings.writeLimits);
        relay.finish(
            done: composition.crops
                .map((crop) => crop.imageFileId)
                .toSet()
                .length);
        await relay.start(ConverterWorkflowPhase.verifySource, JobUnit.files);
        await verifySourceUnchanged();
        relay.cancellation.check();
        relay.finish();
        final capabilities = _nativeCapabilities();
        final plan = _previewPlan(request, normalized, composition,
            capabilities, draft, decisions, proposalDiagnostics, library);
        final hash = canonicalHashOf({
          'kind': 'preparedConverterStudy',
          'version': 2,
          'sessionId': request.sessionId.value,
          'sharedSourceFiles':
              request.sharedSourceFiles.map((file) => file.toJson()).toList(),
          'sessionRevision': request.revision,
          'sourceSelectionHash': request.source.canonicalHash.value,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'profileEvidenceHash': snapshot.profile.evidenceHash.value,
          'settingsHash': settings.canonicalHash.value,
          'normalizedSourceHash': normalized.canonicalHash.value,
          'compositionHash': composition.compositionHash.value,
          'assetProposalHashes': proposals == null
              ? null
              : {
                  for (final entry in proposals.entries)
                    entry.key.toString(): entry.value.canonicalHash.value,
                },
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
                assetProposalsByMap: proposals,
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
                reviewSet: reviewSet,
                canApprove: normalized.canPlan &&
                    draft != null &&
                    (events?.projection
                            .allEnabledOriginalEventsHaveExecutionContext ??
                        true) &&
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
        final context =
            _planContext(prepared, approval.approvedPlan, request.sessionId);
        Future<void> publicationCheckpoint(NativePublicationStage? stage,
            String? journalPath, String? destinationPath) async {
          try {
            await relay.checkpoint(
                publicationStage: stage,
                journalPath: journalPath,
                destinationPath: destinationPath);
          } on ConverterWorkflowFailure catch (failure) {
            throw NativePublicationException(failure.code, failure.message,
                journalPath: journalPath,
                destinationPath: destinationPath,
                promotionMayHaveOccurred: failure.promotionMayHaveOccurred);
          }
        }

        publicationJob = await NativeProjectPublication(
            reservationCheckpoint: (journalPath, destinationPath) =>
                publicationCheckpoint(null, journalPath, destinationPath),
            checkpoint: (stage) => publicationCheckpoint(
                stage,
                publicationJob?.journalPath,
                path.join(draft.parentPath, draft.folderName))).begin(
            approval.approvedPlan, context, draft,
            policy: NativePublicationPolicy(
                allowedParentRoots: [draft.parentPath],
                sourceRoots: tree.sourceRoots),
            cancellation: relay.cancellation);
        await relay.checkpoint(
            journalPath: publicationJob.journalPath,
            destinationPath: path.join(draft.parentPath, draft.folderName));
        final writer = NativeProjectWriter(stagingFactory: () async {
          try {
            return await publicationJob!.createStaging();
          } on NativePublicationException catch (failure) {
            throw NativeWriteException(
                failure.code == 'workflow.cancelled'
                    ? 'native.cancelled'
                    : failure.code,
                failure.message);
          }
        }, checkpoint: (stage, stagingRoot, projectPath) async {
          try {
            await publicationJob!
                .recordWriteCheckpoint(stage, stagingRoot, projectPath);
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
          } on NativePublicationException catch (failure) {
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
        receipt = await writer.write(approval.approvedPlan, context, draft,
            limits: prepared.settings.writeLimits,
            cancellation: relay.cancellation);
        relay.finish(
            done: receipt.mapHashes.length +
                receipt.assetHashes.length +
                receipt.borderSnapshotFiles.length);
        await relay.start(ConverterWorkflowPhase.verifySource, JobUnit.files);
        await verifySourceUnchanged();
        relay.cancellation.check();
        relay.finish();
        await relay.start(ConverterWorkflowPhase.publishNative, JobUnit.files);
        Future<T> publicationCallback<T>(Future<T> Function() callback) async {
          try {
            return await callback();
          } catch (error) {
            final failure = _workflowFailure(error);
            throw NativePublicationException(failure.code, failure.message,
                journalPath: publicationJob?.journalPath,
                destinationPath: publicationJob?.destinationPath,
                promotionMayHaveOccurred: failure.promotionMayHaveOccurred);
          }
        }

        final publication = await publicationJob.publish(
            stagedReceipt: receipt,
            readCurrentContext: () =>
                publicationCallback(relay.readCurrentContext),
            verifySourceUnchanged: () =>
                publicationCallback(verifySourceUnchanged),
            cancellation: relay.cancellation);
        relay.finish();
        outcome = _WorkerOutcome(
            result: ConverterStudyResult._(
                receipt: receipt,
                publication: publication,
                sourceSnapshotHash: snapshot.canonicalHash,
                preparationHash: prepared.preparationHash,
                approvedPlanHash: approval.approvedPlanHash,
                sessionRevision: request.revision,
                sourceUnchanged: true,
                sourceSelection: request.source,
                sharedSourceFiles: tree.sharedSourceFilesFor(snapshot)));
      }
    }
  } catch (error) {
    outcome = _WorkerOutcome(
        failure: _workflowFailure(error,
            stagingPath: receipt?.stagingRoot,
            journalPath: publicationJob?.journalPath,
            destinationPath: publicationJob?.destinationPath));
  } finally {
    await publicationJob?.close();
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
    (limits.maxConnections, 65536),
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
      'maxConnections': limits.maxConnections,
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
      'maxTotalDraftJsonBytes': limits.maxTotalDraftJsonBytes,
      'maxImagePixels': limits.maxImagePixels,
      'maxTotalImagePixels': limits.maxTotalImagePixels,
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
    ConverterStudySettings settings, List<String> sourceRoots) async {
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
  if (sourceRoots.any((sourceRoot) =>
      path.equals(parent, sourceRoot) ||
      path.isWithin(sourceRoot, parent) ||
      path.isWithin(parent, sourceRoot))) {
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

ConverterWorkflowFailure _workflowFailure(Object error,
    {String? stagingPath, String? journalPath, String? destinationPath}) {
  if (error is ConverterWorkflowFailure) {
    return ConverterWorkflowFailure(error.code, error.message,
        locator: error.locator,
        stagingPath: error.stagingPath ?? stagingPath,
        journalPath: error.journalPath ?? journalPath,
        destinationPath: error.destinationPath ?? destinationPath,
        promotionMayHaveOccurred: error.promotionMayHaveOccurred,
        retryable: error.retryable);
  }
  String code;
  String message;
  String? locator;
  var promotionMayHaveOccurred = false;
  if (error is NativePublicationException) {
    code = error.code;
    message = error.message;
    journalPath = error.journalPath ?? journalPath;
    destinationPath = error.destinationPath ?? destinationPath;
    promotionMayHaveOccurred = error.promotionMayHaveOccurred;
  } else if (error is NativeWriteException) {
    code = error.code;
    message = error.message;
    stagingPath = error.stagingPath ?? stagingPath;
  } else if (error is ContractError) {
    code = error.code;
    message = error.message;
    locator = error.path;
  } else {
    return ConverterWorkflowFailure('workflow.failed', error.toString(),
        stagingPath: stagingPath,
        journalPath: journalPath,
        destinationPath: destinationPath);
  }
  if (code == 'source.cancelled' ||
      code == 'native.cancelled' ||
      code == 'native.admission.source.cancelled' ||
      code == 'publication.cancelled') {
    code = 'workflow.cancelled';
  } else if (code.startsWith('source.') && code.contains('changed')) {
    code = 'workflow.source_changed';
  }
  return ConverterWorkflowFailure(code, message,
      locator: locator,
      stagingPath: stagingPath,
      journalPath: journalPath,
      destinationPath: destinationPath,
      promotionMayHaveOccurred: promotionMayHaveOccurred);
}

Sha256Hash _studyRulesHash() => canonicalHashOf({
      'kind': 'converterStudyRules',
      'version': 5,
      'nativeEncounters': {
        'qualification': 'exact-source-full-pbs-selected-map-scope-v2',
        'catalogManifestHash': NativePsdkCatalogManifest.builtinManifestHash,
        'rockSmashProof': 'qualification-evidence-sha256-v2',
        'defaultBudget': _writeLimitsJson(sourceCatalogStudyWriteLimitsFor(1,
            includeNativeCatalog: true)),
      },
      'atlasImageBindings': 'explicit-snapshot-file-sha256-v1',
      'converterVersion': _converterVersion,
      'sourceFormat': 'rmxp-marshal-4.8',
      'tilePolicy': 'literal-32px-stored-autotile-variant',
      'autotileAnimation':
          'attested-source-clock-or-explicit-first-frame-study',
      'assetLibrary':
          'map-segmented-human-reviewed-static-parts-with-original-png-witnesses',
      'assetPlacements': 'attested-static-priority-elements',
      'sourceSemantics': 'kanto-profile-walking-cardinal-closed-unqualified',
      'sourceDirectedJumps':
          'kanto-static-south-ledgeline32-v2-exact-source-replay-with-event-footprint-exclusion',
      'sourceConnections':
          'compiled-complete-graph-unique-opposing-selected-edges',
      'sourcePlayer': 'attested-original-pixels-padded-without-resampling',
      'dimension': 'twoD',
      'template': 'empty',
      'tileSize': 32,
      'requestedMode': 'study',
      'events': 'qualified-static-native-or-whole-event-quarantine',
      'gameplayMetadata': 'sourceArchiveOnly',
      'catalogs':
          'essentials21.1-bounded-data-and-explicit-native-capabilities',
      'battleAuthority': 'aveluneNative',
      'publication': 'verified-study-exclusive-journalled-macos',
    });

Sha256Hash _reviewSeedHash(
        List<AssetCandidate> candidates,
        Map<ConverterId, List<SourcePlacementClaim>> claims,
        AssetOutputMode mode,
        ContractLimits limits) =>
    canonicalHashOf({
      'outputMode': mode.name,
      'candidateHashes': {
        for (final candidate in candidates)
          candidate.candidateId.value: candidate.canonicalHash.value,
      },
      'placementClaimHashes': {
        for (final entry in claims.entries)
          entry.key.value: canonicalHashOf(
                  entry.value.map((claim) => claim.toJson()).toList(),
                  limits: limits)
              .value,
      },
    }, limits: limits);

Sha256Hash _reviewProposalGenerationHash(
        int sourceMapId,
        LocalAssetProposalSet proposals,
        List<int> selectedSourceMapIds,
        AssetOutputMode seedMode,
        ContractLimits limits) =>
    canonicalHashOf({
      'kind': 'reviewProposalGeneration',
      'version': 2,
      'sourceMapId': sourceMapId,
      'sourceSnapshotHash': proposals.sourceSnapshotHash.value,
      'normalizedSourceHash': proposals.normalizedSourceHash.value,
      'selectedSourceMapIds': selectedSourceMapIds,
      'outputMode': seedMode.name,
      'candidateHashes':
          proposals.candidates.map((c) => c.canonicalHash.value).toList(),
      'placementClaimHashes': {
        for (final e in proposals.placementClaims.entries)
          e.key.value: canonicalHashOf(e.value.map((c) => c.toJson()).toList(),
                  limits: limits)
              .value
      },
      'sourceImageHashes': proposals.sourceImages
          .map((s) => canonicalHashOf(s.toJson(), limits: limits).value)
          .toList(),
      'diagnosticsHash': canonicalHashOf(
              proposals.diagnostics.map((d) => d.toJson()).toList(),
              limits: limits)
          .value,
    }, limits: limits);

NativeProjectDraft? _mergeAssetLibrary(
    NativeProjectDraft? literal, ApprovedAssetLibraryComposition? library,
    {required NativeWriteLimits limits}) {
  if (literal == null) return null;
  if (library == null) {
    literal.validateResourceBudget(limits: limits);
    return literal;
  }
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
  'map.audio.update',
  'connection.create_bidirectional_apply',
  'border.blueprint.draft.upsert',
  'border.blueprint.publish',
  'border_layer.feature_create',
  'border_layer.feature_set_replacement',
  'border_layer.materialize_apply',
  'element_category.upsert',
  'element.upsert',
  'element.batch_upsert',
  'asset.import',
  'asset.import_batch',
  'smart_tile.atlas.upsert',
  'smart_tile.material.upsert',
  'smart_tile.preset.publish',
  'characterStudio.character.create',
  'characterStudio.character.update',
  'characterStudio.animationClip.upsert',
  'characterStudio.character.setDefault',
  'event_v2.registry_mode.set',
  'fact.create',
  'entity.upsert',
  'trigger.create',
  'warp.create',
  'dialogue.create',
  'scene.upsert',
  'regionalMap.region.upsert',
  'regionalMap.poi.upsert',
  'world_rule.create',
  'event_v2.record_upsert',
  'event_v2.record_upsert_batch',
  'scene.dialogue.audioMedia.import',
  'pokemon.catalog.write',
  'pokemon.configuration.set_enabled',
  'item.create',
  'pokemon.species.write',
  'pokemon.documents.write',
  'pokemon.learnset.write',
  'pokemon.evolution.write',
  'pokemon.media.write',
  'campaign.encounter_table.upsert',
  'campaign.badge.upsert',
  'entity.set_field_obstacle',
  'entity.set_interactive_encounter',
  'gameplay_zone.create',
  'campaign.trainer.upsert',
];

TargetCapabilities _nativeCapabilities() => TargetCapabilities.fromJson({
      'schemaVersion': '1.0',
      'kind': 'targetCapabilities',
      'exampleOnly': false,
      'profileId': 'avelune-converter-native-study-ac15-border-ledgeline-v1',
      'repository': 'yoahnl/pokemap',
      'revision': 'e02f2559db53ea909c06e786a4fa4c95e79df1bc',
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
              {
                'type': 'test',
                'summary':
                    'AC-13 source-bound event projection, canonical action application, exact dialogue bytes and preserved raw event companions after strict fresh reopen.',
                'reference':
                    'repo:packages/avelune_converter_adapters/test/source_event_study_composer_test.dart:AC-13',
              },
              if (action == 'element.batch_upsert' || action == 'asset.import_batch')
                {
                  'type': 'test',
                  'summary':
                      'Ordered source-derived batches retain every component and its owners, targets and artifacts; canonical limits, pre-stage regeneration and cold single-operation equivalence are verified.',
                  'reference':
                      'repo:packages/avelune_converter_adapters/test/native_mutation_batches_test.dart',
                },
              if (action.startsWith('border.blueprint.') ||
                  action.startsWith('border_layer.'))
                {
                  'type': 'test',
                  'summary':
                      'Exact-source south ledgeLine modules use canonical Border publication, per-edge replacements and materialization after map saves, with full regeneration and strict native reopen; event state and runtime journey are separate.',
                  'reference':
                      'repo:packages/avelune_converter_adapters/test/converter_workflow_test.dart:AC15 workflow publishes native Borders with events and approved assets',
                },
              if (action == 'campaign.badge.upsert' || action == 'entity.set_field_obstacle')
                {
                  'type': 'test',
                  'summary':
                      'Canonical campaign.badge.upsert and entity.set_field_obstacle preserve Settings-derived locked field definitions and typed native objects through strict original-source approval without granting player progress.',
                  'reference':
                      'repo:packages/avelune_converter_adapters/test/source_cut_workflow_admission_test.dart',
                },
              if (action == 'map.audio.update')
                {
                  'type': 'test',
                  'summary':
                      'Attested source BGM import, canonical map audio assignment, exact native gain and publication with strict fresh reopen.',
                  'reference':
                      'repo:packages/avelune_converter_adapters/test/converter_workflow_test.dart:AC13 workflow publishes attested map music and preserves its gain',
                },
              if (action == 'connection.create_bidirectional_apply')
                {
                  'type': 'test',
                  'summary':
                      'Original compiled graph, opposing unique edges, canonical bidirectional action after all map saves and strict source regeneration.',
                  'reference':
                      'repo:packages/avelune_converter_adapters/test/source_connection_study_composer_test.dart',
                },
            ],
            'limitations': [
              'Native study verification; publication requires a committed exclusive-promotion receipt. Gameplay remains uncertified.',
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
      'Qualified static events use native scenes and persistent facts. Unsupported whole events retain their exact source data; complete native gameplay is not certified.',
      false,
      family: 'events');
  final eventEvidence = draft.compositionEvidence['sourceEvents'];
  if (eventEvidence is Map) {
    for (final raw in (eventEvidence['diagnostics'] as List? ?? const []).cast<Map>()) {
      add(raw['code'] as String, raw['message'] as String, false,
          family: 'events', disposition: 'adapted',
          locator: _planLocator(
              normalized, Map<String, Object?>.from(raw['locator'] as Map)));
    }
  }
  final semanticEvidence = draft.compositionEvidence['sourceSemantics'];
  final connectionEvidence =
      semanticEvidence is Map ? semanticEvidence['connections'] : null;
  if (connectionEvidence is Map) {
    for (final raw in (connectionEvidence['diagnostics'] as List).cast<Map>()) {
      add(raw['code'] as String, raw['message'] as String, false,
          family: 'maps',
          locator: _planLocator(
              normalized, Map<String, Object?>.from(raw['locator'] as Map)));
    }
  } else if (!normalized.connectionsExtracted) {
    add(
        'connections.not_requested',
        'Source connectivity was not extracted; regional connectivity is not certified.',
        false,
        family: 'maps');
  } else if (normalized.connections.isNotEmpty) {
    add(
        'connections.source_profile_unqualified',
        'Compiled source connectivity is preserved but lacks qualified source destination passage; native regional connectivity is not activated.',
        false,
        family: 'maps');
  }
  final jumpEvidence =
      semanticEvidence is Map ? semanticEvidence['directedJumps'] : null;
  if (jumpEvidence is Map) {
    final rows = (jumpEvidence['rows'] as List).cast<Map>();
    final sourceAllowed =
        rows.where((row) => row['status'] == 'allowed').length;
    final imported = jumpEvidence['importedJumpCount'] as int;
    final preserved = rows
        .where(
          (row) =>
              row['status'] == 'allowed' && row['nativeStatus'] != 'imported',
        )
        .length;
    add(
      'workflow.jumps.summary',
      '$imported of $sourceAllowed source-allowed directed jumps use native Border ledgeLine modules; $preserved remain inactive with preserved source data. Ordinary cardinal passages are unchanged. Source event state, native animation and runtime journey remain uncertified.',
      false,
      family: 'maps',
      disposition: 'adapted',
    );
    for (final raw in (jumpEvidence['diagnostics'] as List).cast<Map>()) {
      final code = raw['code'] as String;
      final via = raw['via'] as List;
      final reason = switch (code) {
        'jumps.source_event_footprint' =>
          'A source event intersects departure, intermediate or landing cells',
        'jumps.orientation_unqualified' =>
          'The source direction has no qualified native ledge glyph',
        'jumps.source_glyph_unqualified' =>
          'The source glyph does not meet the qualified native module contract',
        _ => code,
      };
      add(
        code,
        '$reason at (${via[0]}, ${via[1]}) toward ${raw['direction']}; the source jump remains inactive and preserved.',
        false,
        family: 'maps',
        locator: _planLocator(normalized, {'mapId': raw['sourceMapId']}),
      );
    }
  }
  if (eventEvidence is Map) {
    final projection = eventEvidence['projection'] as Map;
    final qualified = projection['qualifiedEventCount'] as int;
    final quarantined = projection['quarantinedEventCount'] as int;
    add(
        'workflow.events.summary',
        '$qualified of ${qualified + quarantined} selected source events have qualified static native semantics; $quarantined whole events remain inactive with preserved source bytes. Runtime qualification is separate.',
        false,
        family: 'events',
        disposition: 'adapted');
    for (final event in (projection['events'] as List).cast<Map>()) {
      if (event['status'] != 'quarantinedWholeEvent') continue;
      add(
          'workflow.events.quarantined',
          'Whole source event is inactive: ${(event['gaps'] as List).join(', ')}.',
          false,
          family: 'events',
          locator: _planLocator(
              normalized, Map<String, Object?>.from(event['locator'] as Map)));
    }
  }
  final catalogEvidence = draft.compositionEvidence['sourceCatalogs'];
  if (catalogEvidence is Map) {
    add(
        'workflow.catalogs.summary',
        'Selected source catalogs use stable native identities. Data import, media resolution and runtime readiness remain separate; battles use Avelune rules.',
        false,
        family: 'catalogs',
        disposition: 'adapted');
    for (final raw in (catalogEvidence['diagnostics'] as List).cast<Map>()) {
      add(raw['code'] as String, raw['message'] as String, false,
          family: 'catalogs',
          locator: raw['locator'] is Map
              ? _planLocator(
                  normalized, Map<String, Object?>.from(raw['locator'] as Map))
              : null);
    }
  }
  add(
      'workflow.study.publication',
      'The approved study is written and verified in private staging, then published with a recoverable receipt. Gameplay remains uncertified.',
      false,
      cause: 'policy',
      family: 'publication',
      disposition: 'adapted');
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
          'domain': mutation.domain.name,
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
    PreparedStudy prepared, ConversionPlan plan, ConverterId sessionId,
    {TargetCapabilities? targetCapabilities}) {
  final source = prepared.normalizedSource;
  final mutations = prepared.nativeDraft!.mutations;
  return PlanContext(
      logicalProjectNamespace: source.snapshot.logicalProjectNamespace,
      sourceSnapshotHash: prepared.sourceSnapshotHash,
      sessionId: sessionId,
      targetCapabilities: targetCapabilities ?? prepared.targetCapabilities,
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
