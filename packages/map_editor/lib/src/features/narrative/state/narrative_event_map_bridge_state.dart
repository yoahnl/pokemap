import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers/core/repository_providers.dart';
import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../../application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import '../../../application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import '../../../application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_state.dart';

typedef ApplyPersistedNarrativeEventRegistry = bool Function({
  required String expectedProjectRootPath,
  required NarrativeEventRegistry? expectedPreviousRegistry,
  required NarrativeEventRegistry nextRegistry,
});
typedef LoadNarrativeEventMapSnapshot = Future<MapData?> Function(String mapId);
typedef ActivateNarrativeEventMapSnapshot = bool Function(MapData map);
typedef ApplyNarrativeEventMapFocus = bool Function(
  NarrativeEditorFocusTarget focus,
);
typedef OpenExactNarrativeEvent = void Function({
  required String eventId,
  required NarrativeEventGroupContext groupContext,
});
typedef AdoptPersistedNarrativeEventSourceProposal = bool Function(
  NarrativeEventCreatedSourceProposal proposal,
);
typedef AdoptPersistedNarrativeEventSourceCleanup = Future<bool> Function({
  required String expectedProjectRootPath,
  required MapData expectedActiveMap,
  required NarrativeEventSpatialLinkJournal journal,
});
typedef BeginNarrativeEventSourceCleanupInterlock = bool Function({
  required String expectedProjectRootPath,
  required MapData expectedActiveMap,
  required NarrativeEventSpatialLinkJournal journal,
});
typedef ReleaseNarrativeEventSourceCleanupInterlock = void Function({
  required String expectedProjectRootPath,
  required NarrativeEventSpatialLinkJournal journal,
});
typedef _SourceCreationInspectionIdentity = ({
  String projectRootPath,
  int projectSessionToken,
  int operationEpoch,
  String requestId,
  String eventId,
  String mapId,
});

enum _SourceCreationBusyKind { inspection, mutation }

@immutable
final class NarrativeEventMapBridgeRecovery {
  const NarrativeEventMapBridgeRecovery({
    required this.projectRootPath,
    required this.result,
  });

  final String projectRootPath;
  final NarrativeEventMapCreationResult result;
}

@immutable
final class NarrativeEventMapBridgeState {
  const NarrativeEventMapBridgeState({
    this.projectRootPath,
    this.projectSessionToken = 0,
    this.pendingIntent,
    this.isSubmitting = false,
    this.isLinkingSource = false,
    this.isSourceCreationBusy = false,
    this.linkedEvents = const [],
    this.linkedEventsIntent,
    this.isAdditionalEventRequest = false,
    this.selectedNarrativeEventV2Id,
    this.selectedGroupContext,
    this.pendingReturn,
    this.focusRequest,
    this.navigationMode,
    this.lastNavigationResult,
    this.lastSourceLinkResult,
    this.sourceCreationKind,
    this.sourceCreationProposal,
    this.lastSourceCreationResult,
    this.cleanupConfirmationRequested = false,
    this.lastResult,
    this.recovery,
  });

  final String? projectRootPath;
  final int projectSessionToken;
  final NarrativeEventMapCreationIntent? pendingIntent;
  final bool isSubmitting;
  final bool isLinkingSource;
  final bool isSourceCreationBusy;
  final List<NarrativeEventMapLinkedEvent> linkedEvents;
  final NarrativeEventMapCreationIntent? linkedEventsIntent;
  final bool isAdditionalEventRequest;

  /// Event V2 selection. It is deliberately unrelated to legacy MapEvent IDs.
  final String? selectedNarrativeEventV2Id;
  final NarrativeEventGroupContext? selectedGroupContext;
  final NarrativeEventMapReturnToken? pendingReturn;
  final NarrativeEventMapFocusRequest? focusRequest;
  final NarrativeEventMapNavigationMode? navigationMode;
  final NarrativeEventMapNavigationResult? lastNavigationResult;
  final NarrativeEventSpatialSourceLinkResult? lastSourceLinkResult;
  final NarrativeEventPhysicalSourceKind? sourceCreationKind;
  final NarrativeEventCreatedSourceProposal? sourceCreationProposal;
  final NarrativeEventExplicitSourceCreationResult? lastSourceCreationResult;
  final bool cleanupConfirmationRequested;
  final NarrativeEventMapCreationResult? lastResult;
  final NarrativeEventMapBridgeRecovery? recovery;

  NarrativeEventMapBridgeState copyWith({
    Object? projectRootPath = _unset,
    int? projectSessionToken,
    Object? pendingIntent = _unset,
    bool? isSubmitting,
    bool? isLinkingSource,
    bool? isSourceCreationBusy,
    List<NarrativeEventMapLinkedEvent>? linkedEvents,
    Object? linkedEventsIntent = _unset,
    bool? isAdditionalEventRequest,
    Object? selectedNarrativeEventV2Id = _unset,
    Object? selectedGroupContext = _unset,
    Object? pendingReturn = _unset,
    Object? focusRequest = _unset,
    Object? navigationMode = _unset,
    Object? lastNavigationResult = _unset,
    Object? lastSourceLinkResult = _unset,
    Object? sourceCreationKind = _unset,
    Object? sourceCreationProposal = _unset,
    Object? lastSourceCreationResult = _unset,
    bool? cleanupConfirmationRequested,
    Object? lastResult = _unset,
    Object? recovery = _unset,
  }) {
    return NarrativeEventMapBridgeState(
      projectRootPath: identical(projectRootPath, _unset)
          ? this.projectRootPath
          : projectRootPath as String?,
      projectSessionToken: projectSessionToken ?? this.projectSessionToken,
      pendingIntent: identical(pendingIntent, _unset)
          ? this.pendingIntent
          : pendingIntent as NarrativeEventMapCreationIntent?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLinkingSource: isLinkingSource ?? this.isLinkingSource,
      isSourceCreationBusy: isSourceCreationBusy ?? this.isSourceCreationBusy,
      linkedEvents: linkedEvents ?? this.linkedEvents,
      linkedEventsIntent: identical(linkedEventsIntent, _unset)
          ? this.linkedEventsIntent
          : linkedEventsIntent as NarrativeEventMapCreationIntent?,
      isAdditionalEventRequest:
          isAdditionalEventRequest ?? this.isAdditionalEventRequest,
      selectedNarrativeEventV2Id: identical(selectedNarrativeEventV2Id, _unset)
          ? this.selectedNarrativeEventV2Id
          : selectedNarrativeEventV2Id as String?,
      selectedGroupContext: identical(selectedGroupContext, _unset)
          ? this.selectedGroupContext
          : selectedGroupContext as NarrativeEventGroupContext?,
      pendingReturn: identical(pendingReturn, _unset)
          ? this.pendingReturn
          : pendingReturn as NarrativeEventMapReturnToken?,
      focusRequest: identical(focusRequest, _unset)
          ? this.focusRequest
          : focusRequest as NarrativeEventMapFocusRequest?,
      navigationMode: identical(navigationMode, _unset)
          ? this.navigationMode
          : navigationMode as NarrativeEventMapNavigationMode?,
      lastNavigationResult: identical(lastNavigationResult, _unset)
          ? this.lastNavigationResult
          : lastNavigationResult as NarrativeEventMapNavigationResult?,
      lastSourceLinkResult: identical(lastSourceLinkResult, _unset)
          ? this.lastSourceLinkResult
          : lastSourceLinkResult as NarrativeEventSpatialSourceLinkResult?,
      sourceCreationKind: identical(sourceCreationKind, _unset)
          ? this.sourceCreationKind
          : sourceCreationKind as NarrativeEventPhysicalSourceKind?,
      sourceCreationProposal: identical(sourceCreationProposal, _unset)
          ? this.sourceCreationProposal
          : sourceCreationProposal as NarrativeEventCreatedSourceProposal?,
      lastSourceCreationResult: identical(lastSourceCreationResult, _unset)
          ? this.lastSourceCreationResult
          : lastSourceCreationResult
              as NarrativeEventExplicitSourceCreationResult?,
      cleanupConfirmationRequested:
          cleanupConfirmationRequested ?? this.cleanupConfirmationRequested,
      lastResult: identical(lastResult, _unset)
          ? this.lastResult
          : lastResult as NarrativeEventMapCreationResult?,
      recovery: identical(recovery, _unset)
          ? this.recovery
          : recovery as NarrativeEventMapBridgeRecovery?,
    );
  }
}

const Object _unset = Object();

final class NarrativeEventMapBridgeController
    extends StateNotifier<NarrativeEventMapBridgeState> {
  NarrativeEventMapBridgeController({
    required CreateNarrativeEventFromMapSourceUseCase useCase,
    String? projectRootPath,
    String Function()? requestIdFactory,
    NarrativeEventSpatialSourceLinkUseCase? sourceLinkUseCase,
    NarrativeEventExplicitSourceCreationUseCase? explicitSourceCreationUseCase,
  })  : _useCase = useCase,
        _sourceLinkUseCase = sourceLinkUseCase,
        _explicitSourceCreationUseCase = explicitSourceCreationUseCase,
        _requestIdFactory = requestIdFactory ?? _defaultMapRequestId,
        super(
          NarrativeEventMapBridgeState(
            projectRootPath: _normalizedProjectRoot(projectRootPath),
          ),
        );

  final CreateNarrativeEventFromMapSourceUseCase _useCase;
  final NarrativeEventSpatialSourceLinkUseCase? _sourceLinkUseCase;
  final NarrativeEventExplicitSourceCreationUseCase?
      _explicitSourceCreationUseCase;
  final String Function() _requestIdFactory;
  int _operationEpoch = 0;
  int _sourceCreationBusyGeneration = 0;
  int? _sourceCreationBusyOwner;
  _SourceCreationBusyKind? _sourceCreationBusyKind;
  Object? _boundProjectIdentity;
  bool _hasProjectBinding = false;
  final _pendingSourceCreationInspections = <_SourceCreationInspectionIdentity,
      Future<NarrativeEventExplicitSourceCreationResult?>>{};

  void bindProjectRootPath(String? projectRootPath) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (normalized == state.projectRootPath) return;
    _boundProjectIdentity = null;
    _hasProjectBinding = true;
    _operationEpoch++;
    state = NarrativeEventMapBridgeState(
      projectRootPath: normalized,
      projectSessionToken: state.projectSessionToken + 1,
    );
  }

  /// Binds async bridge work to one concrete editor project session.
  ///
  /// Object identity is intentional: reloading an equal manifest at the same
  /// root must still invalidate a delayed map snapshot. Expected in-flight
  /// writes keep their token until they can report a durable outcome.
  void bindProjectSession({
    required String? projectRootPath,
    required ProjectManifest? project,
  }) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (_hasProjectBinding &&
        normalized == state.projectRootPath &&
        identical(project, _boundProjectIdentity)) {
      return;
    }
    final rootChanged = normalized != state.projectRootPath;
    _hasProjectBinding = true;
    _boundProjectIdentity = project;
    _operationEpoch++;
    final nextSessionToken = state.projectSessionToken + 1;
    if (rootChanged) {
      state = NarrativeEventMapBridgeState(
        projectRootPath: normalized,
        projectSessionToken: nextSessionToken,
      );
      return;
    }
    state = state.copyWith(
      projectRootPath: normalized,
      projectSessionToken: nextSessionToken,
    );
  }

  Future<NarrativeEventMapNavigationResult> openMapForEvent({
    required String eventId,
    required NarrativeEventGroupContext groupContext,
    required NarrativeEventMapNavigationMode mode,
    required ProjectManifest project,
    required MapData? activeMap,
    required bool mapDirty,
    required LoadNarrativeEventMapSnapshot loadMapSnapshot,
    required ActivateNarrativeEventMapSnapshot activateMapSnapshot,
    required ApplyNarrativeEventMapFocus applyFocus,
  }) async {
    final record = _uniqueEventRecord(project.eventRegistry, eventId);
    if (record == null) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.eventMissing,
        'L’Event sélectionné n’existe plus.',
      );
    }
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    if (source == null ||
        source.kind == NarrativeEventSourceKind.outcomeReceived) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Cet Event n’a pas de source spatiale à afficher sur une map.',
      );
    }
    final sourceMapId = _spatialMapId(source);
    if (groupContext.kind != NarrativeEventGroupContextKind.map ||
        groupContext.mapId != sourceMapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.sourceMismatch,
        'Le groupe Event et la source ne ciblent pas la même map.',
      );
    }

    final sameMap = activeMap?.id == sourceMapId;
    if (!sameMap && mapDirty) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.blockedDirtyMap,
        'Enregistrez la map active avant d’en ouvrir une autre.',
      );
    }

    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final targetMap = sameMap ? activeMap! : await loadMapSnapshot(sourceMapId);
    if (operationEpoch != _operationEpoch ||
        projectSessionToken != state.projectSessionToken) {
      return const NarrativeEventMapNavigationResult(
        status: NarrativeEventMapNavigationStatus.unavailable,
        message: 'Le projet a changé pendant la navigation.',
      );
    }
    if (targetMap == null || targetMap.id != sourceMapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Les données de la map source sont indisponibles.',
      );
    }

    final navigation = buildNarrativeEventNavigationIndex(
      project: project,
      maps: [targetMap],
    ).mapNavigationForSource(source);
    final focus = navigation.focusTarget;
    if (!navigation.available || focus == null || focus.mapId != sourceMapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        navigation.absenceReason ?? 'La source ne peut pas être localisée.',
        navigation: navigation,
      );
    }
    if (!sameMap && !activateMapSnapshot(targetMap)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.activationFailed,
        'La map source n’a pas pu être activée.',
      );
    }
    if (!applyFocus(focus)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.focusFailed,
        'La source a changé avant de pouvoir être sélectionnée.',
      );
    }

    final requestId = _requestIdFactory();
    final returnToken = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: eventId,
      groupContext: groupContext,
      expectedSource: source,
    );
    final result = NarrativeEventMapNavigationResult(
      status: NarrativeEventMapNavigationStatus.ready,
      message: mode == NarrativeEventMapNavigationMode.view
          ? 'Source affichée sur la map.'
          : 'Choisissez une source existante sur cette map.',
      navigation: navigation,
    );
    state = state.copyWith(
      selectedNarrativeEventV2Id: eventId,
      selectedGroupContext: groupContext,
      pendingReturn: returnToken,
      focusRequest: NarrativeEventMapFocusRequest(
        requestId: requestId,
        navigation: navigation,
        returnToken: returnToken,
        source: source,
        mode: mode,
      ),
      navigationMode: mode,
      lastNavigationResult: result,
      lastSourceLinkResult: null,
    );
    return result;
  }

  Future<NarrativeEventMapNavigationResult> openMapForMissingSource({
    required String eventId,
    required NarrativeEventGroupContext groupContext,
    required ProjectManifest project,
    required MapData? activeMap,
    required bool mapDirty,
    required LoadNarrativeEventMapSnapshot loadMapSnapshot,
    required ActivateNarrativeEventMapSnapshot activateMapSnapshot,
  }) async {
    final record = _uniqueEventRecord(project.eventRegistry, eventId);
    if (record?.draftOrNull == null || record!.draftOrNull!.source != null) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Seul un draft Event sans source peut créer un élément sur la map.',
      );
    }
    final mapId = groupContext.mapId;
    if (groupContext.kind != NarrativeEventGroupContextKind.map ||
        mapId == null ||
        !_projectContainsMap(project, mapId)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.sourceMismatch,
        'Le groupe Event doit cibler une map réelle du projet.',
      );
    }
    final sameMap = activeMap?.id == mapId;
    if (!sameMap && mapDirty) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.blockedDirtyMap,
        'Enregistrez la map active avant d’en ouvrir une autre.',
      );
    }

    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final targetMap = sameMap ? activeMap! : await loadMapSnapshot(mapId);
    if (!_isCurrentNavigationOperation(
      operationEpoch: operationEpoch,
      projectSessionToken: projectSessionToken,
    )) {
      return const NarrativeEventMapNavigationResult(
        status: NarrativeEventMapNavigationStatus.unavailable,
        message: 'Le projet a changé pendant la navigation.',
      );
    }
    if (targetMap == null || targetMap.id != mapId) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.unavailable,
        'Les données de la map du groupe sont indisponibles.',
      );
    }
    if (!sameMap && !activateMapSnapshot(targetMap)) {
      return _navigationFailure(
        NarrativeEventMapNavigationStatus.activationFailed,
        'La map du groupe n’a pas pu être activée.',
      );
    }

    final requestId = _requestIdFactory();
    final token = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: eventId,
      groupContext: groupContext,
      expectedSource: null,
    );
    const result = NarrativeEventMapNavigationResult(
      status: NarrativeEventMapNavigationStatus.ready,
      message: 'Choisissez le type puis placez la source sur cette map.',
    );
    state = state.copyWith(
      selectedNarrativeEventV2Id: eventId,
      selectedGroupContext: groupContext,
      pendingReturn: token,
      focusRequest: null,
      navigationMode: NarrativeEventMapNavigationMode.create,
      sourceCreationKind: null,
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
      lastNavigationResult: result,
      lastSourceLinkResult: null,
    );
    return result;
  }

  bool selectPhysicalSourceKind(NarrativeEventPhysicalSourceKind kind) {
    if (state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery ||
        state.pendingReturn == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.create) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationKind: kind,
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  bool previewSourceCreationProposal(
    NarrativeEventCreatedSourceProposal proposal,
  ) {
    final token = state.pendingReturn;
    if (state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery ||
        token == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.create ||
        state.sourceCreationKind != proposal.physicalKind ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != proposal.beforeMap.id ||
        proposal.beforeMap.id != proposal.afterMap.id ||
        narrativeEventSpatialSourceMapId(proposal.source) !=
            proposal.beforeMap.id) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationProposal: proposal,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  bool cancelSourceCreationProposal() {
    if (state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery ||
        state.sourceCreationProposal == null) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  Future<NarrativeEventExplicitSourceCreationResult?> confirmSourceCreation({
    required String? projectRootPath,
    required ProjectManifest project,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required AdoptPersistedNarrativeEventSourceProposal adoptPersistedMap,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    final token = state.pendingReturn;
    final proposal = state.sourceCreationProposal;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (state.isSourceCreationBusy) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.blocked,
        code: 'sourceCreationInProgress',
        message: 'Une création de source est déjà en cours.',
      );
    }
    if (useCase == null ||
        token == null ||
        proposal == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.create ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath) {
      return null;
    }
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.mutation,
    );
    state = state.copyWith(
      isSourceCreationBusy: true,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
    late final NarrativeEventExplicitSourceCreationResult rawResult;
    try {
      rawResult = await useCase.createAndLink(
        projectPath: p.join(normalizedRoot, 'project.json'),
        eventId: token.eventId,
        proposal: proposal,
        mapDirty: mapDirty,
        projectDirty: projectDirty,
        saving: saving,
      );
    } on Object catch (error) {
      rawResult = NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'unexpectedSourceCreationFailure',
        message: 'La création de source a échoué: $error',
      );
    }
    final result = _bindSourceCreationResultToToken(rawResult, token);
    if (!_isCurrentOperation(
      projectRootPath: normalizedRoot,
      projectSessionToken: projectSessionToken,
      operationEpoch: operationEpoch,
    )) {
      final stale =
          result.status == NarrativeEventExplicitSourceCreationStatus.committed
              ? _sourceCreationOutOfSync(result, 'projectChangedAfterCommit')
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isSourceCreationBusy: _busyAfterRelease(busyOwner),
          sourceCreationProposal:
              stale.journal == null ? state.sourceCreationProposal : null,
          lastSourceCreationResult: stale,
        );
      }
      return stale;
    }
    if (result.journal != null && state.sourceCreationProposal != null) {
      state = state.copyWith(sourceCreationProposal: null);
    }
    return _finishCommittedSourceCreation(
      result: result,
      proposal: proposal,
      durableMap: proposal.afterMap,
      source: proposal.source,
      token: token,
      project: project,
      adoptPersistedMap: adoptPersistedMap,
      applyPersistedRegistry: applyPersistedRegistry,
      busyOwner: busyOwner,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult?>
      inspectPendingSourceCreation({
    required String? projectRootPath,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) {
    final identity = _sourceCreationInspectionIdentity(projectRootPath);
    if (identity == null) {
      return Future<NarrativeEventExplicitSourceCreationResult?>.value();
    }
    final pending = _pendingSourceCreationInspections[identity];
    if (pending != null) return pending;
    late final Future<NarrativeEventExplicitSourceCreationResult?> tracked;
    tracked = _inspectPendingSourceCreation(
      identity: identity,
      token: state.pendingReturn!,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    ).whenComplete(() {
      if (identical(_pendingSourceCreationInspections[identity], tracked)) {
        _pendingSourceCreationInspections.remove(identity);
      }
    });
    _pendingSourceCreationInspections[identity] = tracked;
    return tracked;
  }

  Future<NarrativeEventExplicitSourceCreationResult?>
      _inspectPendingSourceCreation({
    required _SourceCreationInspectionIdentity identity,
    required NarrativeEventMapReturnToken token,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    if (useCase == null ||
        state.navigationMode == null ||
        (state.isSourceCreationBusy &&
            _sourceCreationBusyKind != _SourceCreationBusyKind.inspection)) {
      return null;
    }
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.inspection,
    );
    state = state.copyWith(isSourceCreationBusy: true);
    final previousRecovery = state.lastSourceCreationResult;
    final inspected = await useCase.inspect(
      projectPath: p.join(identity.projectRootPath, 'project.json'),
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    final result = _bindSourceCreationResultToToken(inspected, token);
    if (!_sourceCreationInspectionIsCurrent(identity)) {
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
      );
      return result;
    }
    final stateResult = _preserveTransientSourceRecovery(
      previousRecovery,
      result,
    );
    state = state.copyWith(
      isSourceCreationBusy: _busyAfterRelease(busyOwner),
      sourceCreationProposal:
          stateResult.journal == null ? state.sourceCreationProposal : null,
      lastSourceCreationResult:
          stateResult.status == NarrativeEventExplicitSourceCreationStatus.clear
              ? null
              : stateResult,
    );
    return result;
  }

  Future<NarrativeEventExplicitSourceCreationResult?> retrySourceCreation({
    required String? projectRootPath,
    required ProjectManifest project,
    required MapData activeMap,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required AdoptPersistedNarrativeEventSourceProposal adoptPersistedMap,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    final token = state.pendingReturn;
    final proposal = state.sourceCreationProposal;
    final journal = state.lastSourceCreationResult?.journal;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (useCase == null ||
        token == null ||
        (proposal == null && journal == null) ||
        state.isSourceCreationBusy ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath) {
      return null;
    }
    if (journal != null && !_journalMatchesToken(journal, token)) {
      final mismatch = _pendingJournalMismatch(
        state.lastSourceCreationResult!,
      );
      state = state.copyWith(
        lastSourceCreationResult: mismatch,
        cleanupConfirmationRequested: false,
      );
      return mismatch;
    }
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final previousRecovery = state.lastSourceCreationResult;
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.mutation,
    );
    state = state.copyWith(
      isSourceCreationBusy: true,
      sourceCreationProposal: journal == null ? proposal : null,
      cleanupConfirmationRequested: false,
    );
    final retried = await useCase.retry(
      projectPath: p.join(normalizedRoot, 'project.json'),
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    final result = _preserveTransientSourceRecovery(
      previousRecovery,
      _bindSourceCreationResultToToken(retried, token),
    );
    if (!_isCurrentOperation(
      projectRootPath: normalizedRoot,
      projectSessionToken: projectSessionToken,
      operationEpoch: operationEpoch,
    )) {
      final stale =
          result.status == NarrativeEventExplicitSourceCreationStatus.committed
              ? _sourceCreationOutOfSync(result, 'projectChangedAfterRetry')
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isSourceCreationBusy: _busyAfterRelease(busyOwner),
          sourceCreationProposal:
              stale.journal == null ? state.sourceCreationProposal : null,
          lastSourceCreationResult: stale,
        );
      }
      return stale;
    }
    if (result.status != NarrativeEventExplicitSourceCreationStatus.committed) {
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        sourceCreationProposal:
            result.journal == null ? state.sourceCreationProposal : null,
        lastSourceCreationResult:
            result.status == NarrativeEventExplicitSourceCreationStatus.clear
                ? null
                : result,
      );
      return result;
    }
    final durableJournal = result.journal;
    final proposalForAdoption = durableJournal == null ? proposal : null;
    if (durableJournal != null && state.sourceCreationProposal != null) {
      state = state.copyWith(sourceCreationProposal: null);
    }
    return _finishCommittedSourceCreation(
      result: result,
      proposal: proposalForAdoption,
      durableMap: proposalForAdoption?.afterMap ?? activeMap,
      source: durableJournal?.source ?? proposal!.source,
      token: token,
      project: project,
      adoptPersistedMap: adoptPersistedMap,
      applyPersistedRegistry: applyPersistedRegistry,
      busyOwner: busyOwner,
    );
  }

  bool requestSourceCleanupConfirmation() {
    final result = state.lastSourceCreationResult;
    final token = state.pendingReturn;
    if (state.isSourceCreationBusy ||
        token == null ||
        result?.status !=
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
        result?.journal == null ||
        !_journalMatchesToken(result!.journal!, token)) {
      return false;
    }
    state = state.copyWith(cleanupConfirmationRequested: true);
    return true;
  }

  bool cancelSourceCleanupConfirmation() {
    if (state.isSourceCreationBusy || !state.cleanupConfirmationRequested) {
      return false;
    }
    state = state.copyWith(cleanupConfirmationRequested: false);
    return true;
  }

  Future<NarrativeEventExplicitSourceCreationResult?> cleanupCreatedSource({
    required String? projectRootPath,
    required MapData activeMap,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required BeginNarrativeEventSourceCleanupInterlock beginCleanupInterlock,
    required ReleaseNarrativeEventSourceCleanupInterlock
        releaseCleanupInterlock,
    required AdoptPersistedNarrativeEventSourceCleanup adoptPersistedCleanup,
  }) async {
    final useCase = _explicitSourceCreationUseCase;
    final pending = state.lastSourceCreationResult;
    final journal = pending?.journal;
    final token = state.pendingReturn;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (useCase == null ||
        journal == null ||
        token == null ||
        !_journalMatchesToken(journal, token) ||
        activeMap.id != journal.mapId ||
        !state.cleanupConfirmationRequested ||
        state.isSourceCreationBusy ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath) {
      return null;
    }
    var cleanupInterlockArmed = false;
    try {
      cleanupInterlockArmed = beginCleanupInterlock(
        expectedProjectRootPath: normalizedRoot,
        expectedActiveMap: activeMap,
        journal: journal,
      );
    } on Object {
      cleanupInterlockArmed = false;
    }
    if (!cleanupInterlockArmed) {
      final blocked = NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        code: 'cleanupInterlockUnavailable',
        message: 'La suppression n’a pas démarré car la map active ne peut '
            'pas être protégée contre une sauvegarde concurrente.',
        journal: journal,
        inspection: pending?.inspection,
        previousRegistry: pending?.previousRegistry,
        nextRegistry: pending?.nextRegistry,
        persistenceResult: pending?.persistenceResult,
      );
      state = state.copyWith(
        lastSourceCreationResult: blocked,
        cleanupConfirmationRequested: false,
      );
      return blocked;
    }
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    final busyOwner = _claimSourceCreationBusy(
      _SourceCreationBusyKind.mutation,
    );
    state = state.copyWith(isSourceCreationBusy: true);
    final rawResult = await useCase.cleanup(
      projectPath: p.join(normalizedRoot, 'project.json'),
      operationId: journal.operationId,
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId,
      confirmed: true,
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    final result = _preserveTransientSourceRecovery(
      pending,
      _bindSourceCreationResultToToken(rawResult, token),
      preserveAnyRecoveryWithoutIdentity: true,
    );
    if (!_mustRetainCleanupInterlock(result)) {
      try {
        releaseCleanupInterlock(
          expectedProjectRootPath: normalizedRoot,
          journal: journal,
        );
      } on Object {
        // Keeping a stale-map barrier is safer than risking resurrection.
      }
    }
    if (!_isCurrentOperation(
      projectRootPath: normalizedRoot,
      projectSessionToken: projectSessionToken,
      operationEpoch: operationEpoch,
    )) {
      final stale =
          result.status == NarrativeEventExplicitSourceCreationStatus.cleaned
              ? _sourceCleanupOutOfSync(result)
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isSourceCreationBusy: _busyAfterRelease(busyOwner),
          sourceCreationProposal:
              stale.journal == null ? state.sourceCreationProposal : null,
          lastSourceCreationResult: stale,
          cleanupConfirmationRequested: false,
        );
      }
      return stale;
    }
    var stateResult = result;
    if (result.status == NarrativeEventExplicitSourceCreationStatus.cleaned) {
      final cleanedJournal = result.journal;
      var adopted = false;
      if (cleanedJournal != null) {
        try {
          adopted = await adoptPersistedCleanup(
            expectedProjectRootPath: normalizedRoot,
            expectedActiveMap: activeMap,
            journal: cleanedJournal,
          );
        } on Object {
          adopted = false;
        }
      }
      if (!adopted ||
          !_isCurrentOperation(
            projectRootPath: normalizedRoot,
            projectSessionToken: projectSessionToken,
            operationEpoch: operationEpoch,
          )) {
        stateResult = _sourceCleanupOutOfSync(result);
      }
    }
    state = state.copyWith(
      isSourceCreationBusy: _busyAfterRelease(busyOwner),
      sourceCreationProposal: stateResult.journal != null ||
              stateResult.status ==
                  NarrativeEventExplicitSourceCreationStatus.cleaned
          ? null
          : state.sourceCreationProposal,
      lastSourceCreationResult: stateResult,
      cleanupConfirmationRequested: false,
    );
    return stateResult;
  }

  static bool _mustRetainCleanupInterlock(
    NarrativeEventExplicitSourceCreationResult result,
  ) {
    if (result.status == NarrativeEventExplicitSourceCreationStatus.cleaned ||
        result.code == 'cleanupException') {
      return true;
    }
    final journal = result.journal ?? result.inspection?.journal;
    return journal?.cleanupMarker ==
        NarrativeEventSpatialLinkCleanupMarker.requested;
  }

  bool completeSourceCleanupReload({
    required String? projectRootPath,
    required MapData activeMap,
  }) {
    final recovery = state.lastSourceCreationResult;
    final journal = recovery?.journal;
    final token = state.pendingReturn;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (state.isSourceCreationBusy ||
        recovery?.status !=
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
        recovery?.code != 'cleanedMapOutOfSync' ||
        journal == null ||
        token == null ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath ||
        !_journalMatchesToken(journal, token) ||
        activeMap.id != journal.mapId ||
        _mapOwnsSource(activeMap, journal.source)) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      sourceCreationProposal: null,
      lastSourceCreationResult: NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.cleaned,
        code: 'cleanupReloaded',
        message: 'La map nettoyée a été rechargée dans l’éditeur.',
        journal: journal,
        inspection: recovery!.inspection,
      ),
      cleanupConfirmationRequested: false,
    );
    return true;
  }

  bool returnToEvent({
    required ProjectManifest project,
    required OpenExactNarrativeEvent openExactEvent,
  }) {
    if (state.isLinkingSource ||
        state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery) {
      return false;
    }
    final token = state.pendingReturn;
    if (token == null) return false;
    final record = _uniqueEventRecord(project.eventRegistry, token.eventId);
    if (record == null) {
      _operationEpoch++;
      state = state.copyWith(
        selectedNarrativeEventV2Id: null,
        selectedGroupContext: null,
        lastNavigationResult: const NarrativeEventMapNavigationResult(
          status: NarrativeEventMapNavigationStatus.eventMissing,
          message: 'L’Event a été supprimé pendant l’aller-retour carte.',
        ),
      );
      return false;
    }
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    final sourceMatchesReturnGroup = source == null
        ? token.expectedSource == null &&
            state.navigationMode == NarrativeEventMapNavigationMode.create &&
            token.groupContext.kind == NarrativeEventGroupContextKind.map &&
            token.groupContext.mapId != null &&
            _projectContainsMap(project, token.groupContext.mapId!)
        : _sourceMatchesGroup(source, token.groupContext);
    if (source != token.expectedSource || !sourceMatchesReturnGroup) {
      _operationEpoch++;
      state = state.copyWith(
        lastNavigationResult: const NarrativeEventMapNavigationResult(
          status: NarrativeEventMapNavigationStatus.sourceMismatch,
          message: 'La source de l’Event a changé pendant la navigation.',
        ),
      );
      return false;
    }
    openExactEvent(
      eventId: token.eventId,
      groupContext: token.groupContext,
    );
    _operationEpoch++;
    state = state.copyWith(
      selectedNarrativeEventV2Id: token.eventId,
      selectedGroupContext: token.groupContext,
      pendingReturn: null,
      focusRequest: null,
      navigationMode: null,
      lastNavigationResult: null,
    );
    return true;
  }

  Future<NarrativeEventSpatialSourceLinkResult?> linkChosenSource({
    required String? projectRootPath,
    required ProjectManifest project,
    required MapData activeMap,
    required NarrativeEventSourceRef source,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    if (state.isLinkingSource) {
      return const NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.blocked,
        code: 'linkInProgress',
        message: 'Une liaison de source est déjà en cours.',
      );
    }
    final inspectionIdentity =
        _sourceCreationInspectionIdentity(projectRootPath);
    final pendingInspection = inspectionIdentity == null
        ? null
        : _pendingSourceCreationInspections[inspectionIdentity];
    if (pendingInspection != null) {
      state = state.copyWith(isLinkingSource: true);
      await pendingInspection;
      state = state.copyWith(isLinkingSource: false);
      if (_hasBlockingSourceCreationRecovery) {
        return const NarrativeEventSpatialSourceLinkResult(
          status: NarrativeEventSpatialSourceLinkStatus.blocked,
          code: 'sourceCreationRecoveryRequired',
          message: 'La récupération de la source durable doit être terminée '
              'avant de changer la liaison.',
        );
      }
    }
    final useCase = _sourceLinkUseCase;
    final token = state.pendingReturn;
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    if (useCase == null ||
        token == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.choose ||
        normalizedRoot == null ||
        normalizedRoot != state.projectRootPath ||
        source.kind == NarrativeEventSourceKind.outcomeReceived ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != activeMap.id ||
        _spatialMapId(source) != activeMap.id) {
      return null;
    }
    final navigation = buildNarrativeEventNavigationIndex(
      project: project,
      maps: [activeMap],
    ).mapNavigationForSource(source);
    if (!navigation.available ||
        navigation.focusTarget == null ||
        navigation.focusTarget?.mapId != activeMap.id) {
      final rejected = NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'candidateUnavailable',
        message: navigation.absenceReason ??
            'Cette source n’est plus disponible sur la map.',
      );
      state = state.copyWith(lastSourceLinkResult: rejected);
      return rejected;
    }

    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    state = state.copyWith(
      isLinkingSource: true,
      lastSourceLinkResult: null,
    );
    late final NarrativeEventSpatialSourceLinkResult result;
    try {
      result = await useCase(
        projectPath: p.join(normalizedRoot, 'project.json'),
        eventId: token.eventId,
        source: source,
        mapDirty: mapDirty,
        projectDirty: projectDirty,
        saving: saving,
      );
    } on Object {
      result = const NarrativeEventSpatialSourceLinkResult(
        status: NarrativeEventSpatialSourceLinkStatus.rejected,
        code: 'unexpectedLinkFailure',
        message: 'La liaison de source a échoué de façon inattendue.',
      );
    }
    if (operationEpoch != _operationEpoch ||
        projectSessionToken != state.projectSessionToken) {
      final staleResult =
          result.status == NarrativeEventSpatialSourceLinkStatus.committed
              ? _committedSourceLinkOutOfSync(result)
              : result;
      if (state.projectRootPath == normalizedRoot) {
        state = state.copyWith(
          isLinkingSource: false,
          lastSourceLinkResult: staleResult,
        );
      }
      return staleResult;
    }
    if (result.status == NarrativeEventSpatialSourceLinkStatus.committed) {
      var applied = false;
      try {
        applied = applyPersistedRegistry(
          expectedProjectRootPath: normalizedRoot,
          expectedPreviousRegistry: result.previousRegistry,
          nextRegistry: result.nextRegistry!,
        );
      } on Object {
        applied = false;
      }
      if (!applied) {
        final outOfSync = _committedSourceLinkOutOfSync(result);
        state = state.copyWith(
          isLinkingSource: false,
          lastSourceLinkResult: outOfSync,
        );
        return outOfSync;
      }
    }
    if (result.status == NarrativeEventSpatialSourceLinkStatus.committed ||
        result.status == NarrativeEventSpatialSourceLinkStatus.noOp) {
      final requestId = _requestIdFactory();
      final nextToken = NarrativeEventMapReturnToken(
        requestId: requestId,
        eventId: token.eventId,
        groupContext: token.groupContext,
        expectedSource: source,
      );
      state = state.copyWith(
        isLinkingSource: false,
        pendingReturn: nextToken,
        focusRequest: NarrativeEventMapFocusRequest(
          requestId: requestId,
          navigation: navigation,
          returnToken: nextToken,
          source: source,
          mode: NarrativeEventMapNavigationMode.choose,
        ),
        lastSourceLinkResult: result,
      );
      return result;
    }
    state = state.copyWith(
      isLinkingSource: false,
      lastSourceLinkResult: result,
    );
    return result;
  }

  bool previewChosenSource({
    required ProjectManifest project,
    required MapData map,
    required NarrativeEventSourceRef source,
  }) {
    final token = state.pendingReturn;
    if (state.isLinkingSource ||
        token == null ||
        state.navigationMode != NarrativeEventMapNavigationMode.choose ||
        source.kind == NarrativeEventSourceKind.outcomeReceived ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != map.id ||
        _spatialMapId(source) != map.id) {
      return false;
    }
    final navigation = buildNarrativeEventNavigationIndex(
      project: project,
      maps: [map],
    ).mapNavigationForSource(source);
    if (!navigation.available || navigation.focusTarget == null) return false;
    final requestId = _requestIdFactory();
    final nextToken = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: token.eventId,
      groupContext: token.groupContext,
      expectedSource: token.expectedSource,
    );
    _operationEpoch++;
    state = state.copyWith(
      pendingReturn: nextToken,
      focusRequest: NarrativeEventMapFocusRequest(
        requestId: requestId,
        navigation: navigation,
        returnToken: nextToken,
        source: source,
        mode: NarrativeEventMapNavigationMode.choose,
      ),
      lastNavigationResult: null,
      lastSourceLinkResult: null,
    );
    return true;
  }

  void cancelMapNavigation() {
    if (state.isLinkingSource ||
        state.isSourceCreationBusy ||
        _hasBlockingSourceCreationRecovery) {
      return;
    }
    if (state.pendingReturn == null && state.focusRequest == null) return;
    _operationEpoch++;
    state = state.copyWith(
      pendingReturn: null,
      focusRequest: null,
      navigationMode: null,
      lastNavigationResult: null,
      lastSourceLinkResult: null,
      sourceCreationKind: null,
      sourceCreationProposal: null,
      lastSourceCreationResult: null,
      cleanupConfirmationRequested: false,
    );
  }

  bool markFocusCameraApplied(String requestId) {
    final focusRequest = state.focusRequest;
    if (focusRequest == null ||
        focusRequest.requestId != requestId ||
        focusRequest.cameraApplied) {
      return false;
    }
    state = state.copyWith(focusRequest: focusRequest.markCameraApplied());
    return true;
  }

  Future<NarrativeEventExplicitSourceCreationResult>
      _finishCommittedSourceCreation({
    required NarrativeEventExplicitSourceCreationResult result,
    required NarrativeEventCreatedSourceProposal? proposal,
    required MapData durableMap,
    required NarrativeEventSourceRef source,
    required NarrativeEventMapReturnToken token,
    required ProjectManifest project,
    required AdoptPersistedNarrativeEventSourceProposal adoptPersistedMap,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
    required int busyOwner,
  }) async {
    if (result.status != NarrativeEventExplicitSourceCreationStatus.committed) {
      final stateResult = _preserveTransientSourceRecovery(
        state.lastSourceCreationResult,
        result,
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        sourceCreationProposal:
            stateResult.journal == null ? state.sourceCreationProposal : null,
        lastSourceCreationResult: stateResult,
      );
      return stateResult;
    }
    final nextRegistry = result.nextRegistry;
    if (nextRegistry == null) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedRegistryMissing',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    var mapApplied = proposal == null && _mapOwnsSource(durableMap, source);
    if (proposal != null) {
      try {
        mapApplied = adoptPersistedMap(proposal);
      } on Object {
        mapApplied = false;
      }
    }
    if (!mapApplied) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedMapOutOfSync',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    var registryApplied = false;
    try {
      registryApplied = applyPersistedRegistry(
        expectedProjectRootPath: state.projectRootPath!,
        expectedPreviousRegistry: result.previousRegistry,
        nextRegistry: nextRegistry,
      );
    } on Object {
      registryApplied = false;
    }
    if (!registryApplied) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedRegistryOutOfSync',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    final navigation = buildNarrativeEventNavigationIndex(
      project: project.copyWith(eventRegistry: nextRegistry),
      maps: [durableMap],
    ).mapNavigationForSource(source);
    if (!navigation.available || navigation.focusTarget == null) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedSourceUnavailable',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    final journal = result.journal;
    if (journal == null || !_journalMatchesToken(journal, token)) {
      final outOfSync = _sourceCreationOutOfSync(
        result,
        'committedJournalMissing',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }
    final acknowledgementIdentity =
        _sourceCreationInspectionIdentity(state.projectRootPath);
    final acknowledgementBelongsToToken = acknowledgementIdentity != null &&
        acknowledgementIdentity.requestId == token.requestId &&
        acknowledgementIdentity.eventId == token.eventId &&
        acknowledgementIdentity.mapId == token.groupContext.mapId;
    final acknowledged = await _explicitSourceCreationUseCase!.acknowledge(
      projectPath: journal.projectPath,
      operationId: journal.operationId,
      expectedEventId: token.eventId,
      expectedMapId: token.groupContext.mapId!,
    );
    if (!acknowledgementBelongsToToken ||
        !_sourceCreationInspectionIsCurrent(acknowledgementIdentity)) {
      final stale = _sourceCreationOutOfSync(
        result,
        'projectChangedAfterAcknowledgement',
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
      );
      return stale;
    }
    if (acknowledged.status !=
        NarrativeEventExplicitSourceCreationStatus.committed) {
      final outOfSync = NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        code: acknowledged.code,
        message: acknowledged.message,
        journal: acknowledged.journal ?? journal,
        inspection: acknowledged.inspection,
        previousRegistry: result.previousRegistry,
        nextRegistry: result.nextRegistry,
        persistenceResult: result.persistenceResult,
      );
      state = state.copyWith(
        isSourceCreationBusy: _busyAfterRelease(busyOwner),
        lastSourceCreationResult: outOfSync,
      );
      return outOfSync;
    }

    final requestId = _requestIdFactory();
    final nextToken = NarrativeEventMapReturnToken(
      requestId: requestId,
      eventId: token.eventId,
      groupContext: token.groupContext,
      expectedSource: source,
    );
    state = state.copyWith(
      isSourceCreationBusy: _busyAfterRelease(busyOwner),
      pendingReturn: nextToken,
      focusRequest: NarrativeEventMapFocusRequest(
        requestId: requestId,
        navigation: navigation,
        returnToken: nextToken,
        source: source,
        mode: state.navigationMode ?? NarrativeEventMapNavigationMode.create,
      ),
      sourceCreationProposal: null,
      lastSourceCreationResult: result,
      cleanupConfirmationRequested: false,
    );
    return result;
  }

  NarrativeEventExplicitSourceCreationResult _sourceCreationOutOfSync(
    NarrativeEventExplicitSourceCreationResult committed,
    String code,
  ) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: code,
      message: 'La source est durable, mais l’éditeur doit être resynchronisé '
          'avant de continuer.',
      journal: committed.journal,
      inspection: committed.inspection,
      previousRegistry: committed.previousRegistry,
      nextRegistry: committed.nextRegistry,
      persistenceResult: committed.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _sourceCleanupOutOfSync(
    NarrativeEventExplicitSourceCreationResult cleaned,
  ) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: 'cleanedMapOutOfSync',
      message: 'La source est supprimée sur disque, mais la map active doit '
          'être rechargée avant de continuer.',
      journal: cleaned.journal,
      inspection: cleaned.inspection,
      previousRegistry: cleaned.previousRegistry,
      nextRegistry: cleaned.nextRegistry,
      persistenceResult: cleaned.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _preserveTransientSourceRecovery(
    NarrativeEventExplicitSourceCreationResult? previous,
    NarrativeEventExplicitSourceCreationResult incoming, {
    bool preserveAnyRecoveryWithoutIdentity = false,
  }) {
    final resultWithoutIdentity = incoming.journal == null &&
        incoming.inspection?.journal == null &&
        (const {
              'inspectionException',
              'sourceInspectionException',
              'registryInspectionException',
              'registryRecoveryException',
              'cleanupException',
              'mapDirty',
              'projectDirty',
              'saveInProgress',
            }.contains(incoming.code) ||
            preserveAnyRecoveryWithoutIdentity &&
                incoming.status ==
                    NarrativeEventExplicitSourceCreationStatus
                        .recoveryRequired);
    if (!resultWithoutIdentity ||
        previous?.status !=
            NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
        previous?.journal == null) {
      return incoming;
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: incoming.code,
      message: incoming.message,
      journal: previous!.journal,
      inspection: previous.inspection,
      previousRegistry: incoming.previousRegistry ?? previous.previousRegistry,
      nextRegistry: incoming.nextRegistry ?? previous.nextRegistry,
      persistenceResult:
          incoming.persistenceResult ?? previous.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _bindSourceCreationResultToToken(
    NarrativeEventExplicitSourceCreationResult result,
    NarrativeEventMapReturnToken token,
  ) {
    final normalized = _normalizeSourceCreationResultJournal(result);
    final journal = normalized.journal;
    if (journal == null || _journalMatchesToken(journal, token)) {
      return normalized;
    }
    return _pendingJournalMismatch(normalized);
  }

  NarrativeEventExplicitSourceCreationResult
      _normalizeSourceCreationResultJournal(
    NarrativeEventExplicitSourceCreationResult result,
  ) {
    final journal = result.journal ?? result.inspection?.journal;
    if (journal == null || identical(journal, result.journal)) return result;
    return NarrativeEventExplicitSourceCreationResult(
      status: result.status,
      code: result.code,
      message: result.message,
      journal: journal,
      inspection: result.inspection,
      previousRegistry: result.previousRegistry,
      nextRegistry: result.nextRegistry,
      persistenceResult: result.persistenceResult,
    );
  }

  NarrativeEventExplicitSourceCreationResult _pendingJournalMismatch(
    NarrativeEventExplicitSourceCreationResult result,
  ) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.rejected,
      code: 'pendingJournalMismatch',
      message: 'La récupération durable appartient à un autre Event ou à une '
          'autre map. Ouvrez l’Event exact pour continuer.',
      inspection: result.inspection,
    );
  }

  int _claimSourceCreationBusy(_SourceCreationBusyKind kind) {
    final owner = ++_sourceCreationBusyGeneration;
    _sourceCreationBusyOwner = owner;
    _sourceCreationBusyKind = kind;
    return owner;
  }

  bool _busyAfterRelease(int owner) {
    if (_sourceCreationBusyOwner != owner) {
      return state.isSourceCreationBusy;
    }
    _sourceCreationBusyOwner = null;
    _sourceCreationBusyKind = null;
    return false;
  }

  bool _journalMatchesToken(
    NarrativeEventSpatialLinkJournal journal,
    NarrativeEventMapReturnToken token,
  ) {
    return token.eventId == journal.eventId &&
        token.groupContext.kind == NarrativeEventGroupContextKind.map &&
        token.groupContext.mapId == journal.mapId;
  }

  _SourceCreationInspectionIdentity? _sourceCreationInspectionIdentity(
    String? projectRootPath,
  ) {
    final normalizedRoot = _normalizedProjectRoot(projectRootPath);
    final token = state.pendingReturn;
    final mapId = token?.groupContext.mapId;
    if (normalizedRoot == null ||
        normalizedRoot != state.projectRootPath ||
        token == null ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        mapId == null ||
        state.navigationMode == null) {
      return null;
    }
    return (
      projectRootPath: normalizedRoot,
      projectSessionToken: state.projectSessionToken,
      operationEpoch: _operationEpoch,
      requestId: token.requestId,
      eventId: token.eventId,
      mapId: mapId,
    );
  }

  bool _sourceCreationInspectionIsCurrent(
    _SourceCreationInspectionIdentity identity,
  ) {
    final token = state.pendingReturn;
    return identity.projectRootPath == state.projectRootPath &&
        identity.projectSessionToken == state.projectSessionToken &&
        identity.operationEpoch == _operationEpoch &&
        token?.requestId == identity.requestId &&
        token?.eventId == identity.eventId &&
        token?.groupContext.kind == NarrativeEventGroupContextKind.map &&
        token?.groupContext.mapId == identity.mapId;
  }

  bool get _hasBlockingSourceCreationRecovery =>
      state.lastSourceCreationResult?.status ==
      NarrativeEventExplicitSourceCreationStatus.recoveryRequired;

  bool _isCurrentNavigationOperation({
    required int operationEpoch,
    required int projectSessionToken,
  }) {
    return operationEpoch == _operationEpoch &&
        projectSessionToken == state.projectSessionToken;
  }

  NarrativeEventMapNavigationResult _navigationFailure(
    NarrativeEventMapNavigationStatus status,
    String message, {
    NarrativeEventNavigationIntent? navigation,
  }) {
    final result = NarrativeEventMapNavigationResult(
      status: status,
      message: message,
      navigation: navigation,
    );
    state = state.copyWith(lastNavigationResult: result);
    return result;
  }

  NarrativeEventSpatialSourceLinkResult _committedSourceLinkOutOfSync(
    NarrativeEventSpatialSourceLinkResult committed,
  ) {
    return NarrativeEventSpatialSourceLinkResult(
      status: NarrativeEventSpatialSourceLinkStatus.committedOutOfSync,
      code: 'committedOutOfSync',
      message: 'La source est enregistrée sur disque, mais le projet doit être '
          'rechargé avant de continuer.',
      previousRegistry: committed.previousRegistry,
      nextRegistry: committed.nextRegistry,
      authoringResult: committed.authoringResult,
      persistenceResult: committed.persistenceResult,
    );
  }

  bool request(
    NarrativeEventMapCreationIntent intent, {
    required String? projectRootPath,
  }) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (state.isSubmitting ||
        normalized == null ||
        normalized != state.projectRootPath) {
      return false;
    }
    _operationEpoch++;
    state = state.copyWith(
      pendingIntent: intent,
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      lastResult: null,
      recovery: null,
    );
    return true;
  }

  void cancel() {
    if (state.isSubmitting) return;
    _operationEpoch++;
    if (state.isAdditionalEventRequest) {
      state = state.copyWith(
        pendingIntent: null,
        isAdditionalEventRequest: false,
      );
      return;
    }
    state = state.copyWith(
      pendingIntent: null,
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      lastResult: null,
    );
  }

  void requestAdditionalEvent() {
    final intent = state.linkedEventsIntent;
    if (state.isSubmitting || state.linkedEvents.isEmpty || intent == null) {
      return;
    }
    _operationEpoch++;
    state = state.copyWith(
      pendingIntent: intent,
      isAdditionalEventRequest: true,
      lastResult: null,
    );
  }

  Future<NarrativeEventMapCreationResult?> confirm({
    required String? projectRootPath,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
    required ApplyPersistedNarrativeEventRegistry applyPersistedRegistry,
  }) async {
    final normalizedProjectRoot = _normalizedProjectRoot(projectRootPath);
    final intent = state.pendingIntent;
    if (intent == null ||
        state.isSubmitting ||
        normalizedProjectRoot == null ||
        normalizedProjectRoot != state.projectRootPath) {
      return null;
    }
    final allowAdditionalEvent = state.isAdditionalEventRequest;
    final operationEpoch = ++_operationEpoch;
    final projectSessionToken = state.projectSessionToken;
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await _useCase(
        projectPath: p.join(normalizedProjectRoot, 'project.json'),
        intent: intent,
        mapDirty: mapDirty,
        projectDirty: projectDirty,
        saving: saving,
        allowAdditionalEvent: allowAdditionalEvent,
      );

      if (!_isCurrentOperation(
        projectRootPath: normalizedProjectRoot,
        projectSessionToken: projectSessionToken,
        operationEpoch: operationEpoch,
      )) {
        if (state.projectRootPath == normalizedProjectRoot) {
          if (result.status == NarrativeEventMapCreationStatus.committed) {
            final outOfSync =
                NarrativeEventMapCreationResult.committedOutOfSync(result);
            state = state.copyWith(
              pendingIntent: null,
              isSubmitting: false,
              linkedEvents: const [],
              linkedEventsIntent: null,
              isAdditionalEventRequest: false,
              selectedNarrativeEventV2Id: null,
              lastResult: outOfSync,
              recovery: NarrativeEventMapBridgeRecovery(
                projectRootPath: normalizedProjectRoot,
                result: outOfSync,
              ),
            );
            return outOfSync;
          }
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            linkedEvents: const [],
            linkedEventsIntent: null,
            isAdditionalEventRequest: false,
            selectedNarrativeEventV2Id: null,
            lastResult: result,
          );
        }
        return result;
      }

      switch (result.status) {
        case NarrativeEventMapCreationStatus.existingLinks:
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            linkedEvents: result.linkedEvents,
            linkedEventsIntent: intent,
            isAdditionalEventRequest: false,
            selectedNarrativeEventV2Id: result.linkedEvents.length == 1
                ? result.linkedEvents.single.eventId
                : null,
            lastResult: result,
          );
          return result;
        case NarrativeEventMapCreationStatus.committed:
          final registry = result.nextRegistry!;
          var applied = false;
          try {
            applied = applyPersistedRegistry(
              expectedProjectRootPath: normalizedProjectRoot,
              expectedPreviousRegistry: result.previousRegistry,
              nextRegistry: registry,
            );
          } on Object {
            applied = false;
          }
          if (!applied) {
            final outOfSync =
                NarrativeEventMapCreationResult.committedOutOfSync(result);
            state = state.copyWith(
              pendingIntent: null,
              isSubmitting: false,
              linkedEvents: const [],
              linkedEventsIntent: null,
              isAdditionalEventRequest: false,
              selectedNarrativeEventV2Id: null,
              lastResult: outOfSync,
              recovery: NarrativeEventMapBridgeRecovery(
                projectRootPath: normalizedProjectRoot,
                result: outOfSync,
              ),
            );
            return outOfSync;
          }
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            linkedEvents: const [],
            linkedEventsIntent: null,
            isAdditionalEventRequest: false,
            selectedNarrativeEventV2Id: result.eventId,
            lastResult: result,
            recovery: null,
          );
          return result;
        case NarrativeEventMapCreationStatus.committedOutOfSync:
          state = state.copyWith(
            pendingIntent: null,
            isSubmitting: false,
            selectedNarrativeEventV2Id: null,
            lastResult: result,
            recovery: NarrativeEventMapBridgeRecovery(
              projectRootPath: normalizedProjectRoot,
              result: result,
            ),
          );
          return result;
        case NarrativeEventMapCreationStatus.blocked:
        case NarrativeEventMapCreationStatus.authoringRejected:
        case NarrativeEventMapCreationStatus.persistenceRejected:
        case NarrativeEventMapCreationStatus.preflightRejected:
          state = state.copyWith(
            isSubmitting: false,
            lastResult: result,
          );
          return result;
      }
    } on Object {
      final failure = NarrativeEventMapCreationResult.unexpectedBridgeFailure();
      if (_isCurrentOperation(
        projectRootPath: normalizedProjectRoot,
        projectSessionToken: projectSessionToken,
        operationEpoch: operationEpoch,
      )) {
        state = state.copyWith(lastResult: failure);
      }
      return failure;
    } finally {
      if (_isCurrentOperation(
            projectRootPath: normalizedProjectRoot,
            projectSessionToken: projectSessionToken,
            operationEpoch: operationEpoch,
          ) &&
          state.isSubmitting) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  bool _isCurrentOperation({
    required String projectRootPath,
    required int projectSessionToken,
    required int operationEpoch,
  }) {
    return state.projectRootPath == projectRootPath &&
        state.projectSessionToken == projectSessionToken &&
        _operationEpoch == operationEpoch;
  }

  void selectLinkedEvent(String eventId) {
    if (!state.linkedEvents.any((event) => event.eventId == eventId)) return;
    state = state.copyWith(selectedNarrativeEventV2Id: eventId);
  }

  bool selectNarrativeEventV2(
    ProjectManifest project,
    String eventId, {
    NarrativeEventGroupContext? groupContext,
  }) {
    final record = _uniqueEventRecord(project.eventRegistry, eventId);
    if (record == null) return false;
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    final resolvedGroup = switch (source?.kind) {
      null => groupContext,
      NarrativeEventSourceKind.outcomeReceived =>
        const NarrativeEventGroupContext.global(),
      _ => NarrativeEventGroupContext.map(_spatialMapId(source!)),
    };
    if (groupContext != null && resolvedGroup != groupContext) return false;
    if (resolvedGroup?.kind == NarrativeEventGroupContextKind.map &&
        !_projectContainsMap(project, resolvedGroup!.mapId!)) {
      return false;
    }
    state = state.copyWith(
      selectedNarrativeEventV2Id: eventId,
      selectedGroupContext: resolvedGroup,
      lastNavigationResult: null,
      lastSourceLinkResult: null,
    );
    return true;
  }

  void clearLinkedEvents() {
    if (state.isSubmitting) return;
    _operationEpoch++;
    state = state.copyWith(
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      lastResult: null,
    );
  }

  void dismissRecovery({required String? projectRootPath}) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    if (state.isSubmitting ||
        normalized == null ||
        normalized != state.projectRootPath ||
        state.recovery?.projectRootPath != normalized) {
      return;
    }
    _operationEpoch++;
    state = state.copyWith(
      pendingIntent: null,
      linkedEvents: const [],
      linkedEventsIntent: null,
      isAdditionalEventRequest: false,
      selectedNarrativeEventV2Id: null,
      lastResult: null,
      recovery: null,
    );
  }

  bool finishRecoveryReload({
    required String? projectRootPath,
    required NarrativeEventRegistry? loadedRegistry,
  }) {
    final normalized = _normalizedProjectRoot(projectRootPath);
    final recovery = state.recovery;
    if (state.isSubmitting ||
        normalized == null ||
        normalized != state.projectRootPath ||
        recovery?.projectRootPath != normalized ||
        recovery?.result.nextRegistry != loadedRegistry) {
      return false;
    }
    _operationEpoch++;
    state = NarrativeEventMapBridgeState(
      projectRootPath: normalized,
      projectSessionToken: state.projectSessionToken,
    );
    return true;
  }
}

bool _projectContainsMap(ProjectManifest project, String mapId) {
  return project.maps.any((entry) => entry.id == mapId);
}

final createNarrativeEventFromMapSourceUseCaseProvider =
    Provider<CreateNarrativeEventFromMapSourceUseCase>((ref) {
  return CreateNarrativeEventFromMapSourceUseCase(
    persistenceGateway:
        ref.watch(narrativeEventRegistryPersistenceGatewayProvider),
  );
});

final narrativeEventSpatialSourceLinkUseCaseProvider =
    Provider<NarrativeEventSpatialSourceLinkUseCase>((ref) {
  return NarrativeEventSpatialSourceLinkUseCase(
    persistenceGateway:
        ref.watch(narrativeEventRegistryPersistenceGatewayProvider),
  );
});

final narrativeEventExplicitSourceCreationUseCaseProvider =
    Provider<NarrativeEventExplicitSourceCreationUseCase>((ref) {
  return NarrativeEventExplicitSourceCreationUseCase(
    sourceGateway:
        ref.watch(narrativeEventSpatialSourceCreationGatewayProvider),
    registryGateway:
        ref.watch(narrativeEventRegistryPersistenceGatewayProvider),
  );
});

final narrativeEventMapBridgeControllerProvider = StateNotifierProvider<
    NarrativeEventMapBridgeController, NarrativeEventMapBridgeState>((ref) {
  final controller = NarrativeEventMapBridgeController(
    useCase: ref.watch(createNarrativeEventFromMapSourceUseCaseProvider),
    sourceLinkUseCase:
        ref.watch(narrativeEventSpatialSourceLinkUseCaseProvider),
    explicitSourceCreationUseCase:
        ref.watch(narrativeEventExplicitSourceCreationUseCaseProvider),
  );
  ref.listen<EditorState>(
    editorNotifierProvider,
    (previous, next) {
      if (previous == null ||
          previous.projectRootPath != next.projectRootPath ||
          !identical(previous.project, next.project)) {
        controller.bindProjectSession(
          projectRootPath: next.projectRootPath,
          project: next.project,
        );
      }
    },
    fireImmediately: true,
  );
  return controller;
});

String? _normalizedProjectRoot(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return p.normalize(trimmed);
}

NarrativeEventRecord? _uniqueEventRecord(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String _spatialMapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => throw StateError(
      'A non-spatial source does not own a map.',
    ),
  );
}

bool _sourceMatchesGroup(
  NarrativeEventSourceRef? source,
  NarrativeEventGroupContext group,
) {
  if (source == null) return false;
  if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
    return group.kind == NarrativeEventGroupContextKind.global;
  }
  return group.kind == NarrativeEventGroupContextKind.map &&
      group.mapId == _spatialMapId(source);
}

bool _mapOwnsSource(MapData map, NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, entityId) =>
        mapId == map.id &&
        map.entities.where((entity) => entity.id == entityId).length == 1,
    triggerEnter: (mapId, triggerId) =>
        mapId == map.id &&
        map.triggers.where((trigger) => trigger.id == triggerId).length == 1,
    mapEnter: (_) => false,
    outcomeReceived: (_) => false,
  );
}

String _defaultMapRequestId() {
  return 'v2_24_${DateTime.now().microsecondsSinceEpoch}';
}
