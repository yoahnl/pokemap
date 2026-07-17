import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_registry_persistence_models.dart';
import '../models/narrative_event_spatial_link_journal_models.dart';
import '../models/narrative_event_spatial_source_creation_models.dart';
import '../ports/narrative_event_registry_persistence_gateway.dart';
import '../ports/narrative_event_spatial_source_creation_gateway.dart';

typedef PrepareNarrativeEventExplicitSourceSession
    = Future<NarrativeEventAuthoringSession> Function(String projectPath);

enum NarrativeEventExplicitSourceCreationStatus {
  blocked,
  committed,
  recoveryRequired,
  cleaned,
  clear,
  rejected,
}

final class NarrativeEventExplicitSourceCreationResult {
  const NarrativeEventExplicitSourceCreationResult({
    required this.status,
    required this.code,
    required this.message,
    this.journal,
    this.inspection,
    this.previousRegistry,
    this.nextRegistry,
    this.persistenceResult,
  });

  final NarrativeEventExplicitSourceCreationStatus status;
  final String code;
  final String message;
  final NarrativeEventSpatialLinkJournal? journal;
  final NarrativeEventSpatialLinkInspection? inspection;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;
}

final class NarrativeEventExplicitSourceCreationUseCase {
  NarrativeEventExplicitSourceCreationUseCase({
    required NarrativeEventSpatialSourceCreationGateway sourceGateway,
    required NarrativeEventRegistryPersistenceGateway registryGateway,
    PrepareNarrativeEventExplicitSourceSession? prepareSession,
    String Function()? operationIdFactory,
  })  : _sourceGateway = sourceGateway,
        _registryGateway = registryGateway,
        _prepareSession =
            prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventSpatialSourceCreationGateway _sourceGateway;
  final NarrativeEventRegistryPersistenceGateway _registryGateway;
  final PrepareNarrativeEventExplicitSourceSession _prepareSession;
  final String Function() _operationIdFactory;

  Future<NarrativeEventExplicitSourceCreationResult> inspect({
    required String projectPath,
    String? expectedEventId,
    String? expectedMapId,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    try {
      final inspection = await _sourceGateway.inspectProject(projectPath);
      final mismatch = _journalBindingMismatch(
        inspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
      );
      if (mismatch != null) return mismatch;
      if (inspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.clear) {
        return NarrativeEventExplicitSourceCreationResult(
          status: NarrativeEventExplicitSourceCreationStatus.clear,
          code: 'clear',
          message: 'Aucune création de source à récupérer.',
          inspection: inspection,
        );
      }
      return _recovery(
        code: inspection.issues.firstOrNull?.code ?? inspection.status.name,
        message: inspection.issues.firstOrNull?.message ??
            'Une création de source Event doit être récupérée.',
        journal: inspection.journal,
        inspection: inspection,
      );
    } on Object catch (error) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'inspectionException',
        message: 'La récupération ne peut pas être inspectée: $error',
      );
    }
  }

  Future<NarrativeEventExplicitSourceCreationResult> createAndLink({
    required String projectPath,
    required String eventId,
    required NarrativeEventCreatedSourceProposal proposal,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    final proposalIssue = _proposalIssue(proposal);
    if (proposalIssue != null) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'invalidProposal',
        message: proposalIssue,
      );
    }

    late final NarrativeEventAuthoringSession initialSession;
    try {
      initialSession = await _prepareSession(projectPath);
    } on Object catch (error) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'preflightRejected',
        message: 'La session Event ne peut pas être préparée: $error',
      );
    }
    final initialRecord = _uniqueEventRecord(
      initialSession.context.registryOrNull,
      eventId,
    );
    if (initialRecord?.draftOrNull == null ||
        initialRecord!.draftOrNull!.source != null) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: 'sourceLessDraftRequired',
        message: 'Seul un draft Event sans source peut créer une source.',
      );
    }

    final operationId = _operationIdFactory();
    late final NarrativeEventSpatialLinkOperationResult mapCommit;
    try {
      mapCommit = await _sourceGateway.commitMap(
        NarrativeEventSpatialLinkMapCommitRequest(
          projectPath: initialSession.projectPath,
          projectRevision: initialSession.projectRevision,
          operationId: operationId,
          eventId: eventId,
          eventRecordFingerprintBefore:
              narrativeEventRecordCanonicalFingerprint(initialRecord),
          beforeMap: proposal.beforeMap,
          afterMap: proposal.afterMap,
          source: proposal.source,
          sourceOwnerJson: proposal.ownerJson,
          sourceOwnerFingerprint: proposal.ownerFingerprint,
        ),
      );
    } on Object catch (error) {
      return _afterMapCommitException(
        projectPath: initialSession.projectPath,
        error: error,
      );
    }
    final durableJournal = mapCommit.journal ?? mapCommit.inspection?.journal;
    if (mapCommit.status !=
            NarrativeEventSpatialLinkOperationStatus.mapCommitted ||
        durableJournal == null) {
      if (durableJournal != null) {
        return _recovery(
          code: mapCommit.code,
          message: mapCommit.message,
          journal: durableJournal,
          inspection: mapCommit.inspection,
        );
      }
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.rejected,
        code: mapCommit.code,
        message: mapCommit.message,
        inspection: mapCommit.inspection,
      );
    }

    return _commitEventFromJournal(
      projectPath: initialSession.projectPath,
      journal: durableJournal,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> retry({
    required String projectPath,
    String? expectedEventId,
    String? expectedMapId,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;

    late NarrativeEventSpatialLinkInspection sourceInspection;
    try {
      sourceInspection = await _sourceGateway.inspectProject(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'sourceInspectionException',
        message: 'La source durable ne peut pas être inspectée: $error',
      );
    }
    final initialMismatch = _journalBindingMismatch(
      sourceInspection,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
    );
    if (initialMismatch != null) return initialMismatch;
    if (sourceInspection.status ==
        NarrativeEventSpatialLinkInspectionStatus.clear) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.clear,
        code: 'noPendingCreation',
        message: 'Aucune création de source à réessayer.',
        inspection: sourceInspection,
      );
    }

    final registryRecovery = await _recoverRegistryBeforeRetry(projectPath);
    if (registryRecovery != null) {
      return NarrativeEventExplicitSourceCreationResult(
        status: registryRecovery.status,
        code: registryRecovery.code,
        message: registryRecovery.message,
        journal: registryRecovery.journal ?? sourceInspection.journal,
        inspection: registryRecovery.inspection ?? sourceInspection,
        previousRegistry: registryRecovery.previousRegistry,
        nextRegistry: registryRecovery.nextRegistry,
        persistenceResult: registryRecovery.persistenceResult,
      );
    }

    if (sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.blocked &&
        sourceInspection.issues.firstOrNull?.code ==
            'eventRegistryRecoveryRequired') {
      try {
        sourceInspection = await _sourceGateway.inspectProject(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'sourceReinspectionException',
          message: 'La source récupérée ne peut pas être réinspectée: $error',
          journal: sourceInspection.journal,
          inspection: sourceInspection,
        );
      }
      final registryRecoveredMismatch = _journalBindingMismatch(
        sourceInspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
      );
      if (registryRecoveredMismatch != null) {
        return registryRecoveredMismatch;
      }
    }

    if (sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent ||
        sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent) {
      late final NarrativeEventSpatialLinkOperationResult recovered;
      final inspectedJournal = sourceInspection.journal!;
      try {
        recovered = await _sourceGateway.recoverProject(
          projectPath: projectPath,
          expectedOperationId: inspectedJournal.operationId,
          expectedEventId: inspectedJournal.eventId,
          expectedMapId: inspectedJournal.mapId,
          expectedSource: inspectedJournal.source,
        );
      } on Object catch (error) {
        return _recovery(
          code: 'sourceRecoveryException',
          message: 'La récupération du commit map a échoué: $error',
          journal: sourceInspection.journal,
          inspection: sourceInspection,
        );
      }
      if (!recovered.succeeded) {
        return _recovery(
          code: recovered.code,
          message: recovered.message,
          journal: recovered.journal ?? sourceInspection.journal,
          inspection: recovered.inspection ?? sourceInspection,
        );
      }
      try {
        sourceInspection = await _sourceGateway.inspectProject(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'sourceReinspectionException',
          message: 'La source récupérée ne peut pas être réinspectée: $error',
          journal: recovered.journal ?? sourceInspection.journal,
          inspection: recovered.inspection ?? sourceInspection,
        );
      }
      final recoveredMismatch = _journalBindingMismatch(
        sourceInspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
      );
      if (recoveredMismatch != null) return recoveredMismatch;
      if (sourceInspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.clear) {
        return NarrativeEventExplicitSourceCreationResult(
          status: NarrativeEventExplicitSourceCreationStatus.clear,
          code: recovered.code,
          message: recovered.message,
          journal: recovered.journal,
          inspection: sourceInspection,
        );
      }
    }
    if (sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.blocked ||
        sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.cleanupPending ||
        sourceInspection.status ==
            NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted) {
      return _recovery(
        code: sourceInspection.issues.firstOrNull?.code ??
            sourceInspection.status.name,
        message: sourceInspection.issues.firstOrNull?.message ??
            'La création ne peut pas être réessayée automatiquement.',
        journal: sourceInspection.journal,
        inspection: sourceInspection,
      );
    }

    final journal = sourceInspection.journal;
    if (journal == null) {
      return _recovery(
        code: 'journalMissing',
        message: 'Le journal de création est introuvable.',
        inspection: sourceInspection,
      );
    }

    return _commitEventFromJournal(
      projectPath: projectPath,
      journal: journal,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult?>
      _recoverRegistryBeforeRetry(String projectPath) async {
    late final NarrativeEventRegistryRecoveryInspection registryInspection;
    try {
      registryInspection = await _registryGateway.inspectRecovery(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'registryInspectionException',
        message: 'Le registre Event ne peut pas être inspecté: $error',
      );
    }
    if (registryInspection.status ==
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked) {
      return _recovery(
        code: registryInspection.issues.firstOrNull?.code ??
            'registryRecoveryBlocked',
        message: registryInspection.issues.firstOrNull?.message ??
            'La récupération du registre Event est bloquée.',
      );
    }
    if (registryInspection.status ==
        NarrativeEventRegistryRecoveryGateStatus.recoveryRequired) {
      late final List<NarrativeEventRegistryPersistenceResult> recovered;
      try {
        recovered = await _registryGateway.recover(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'registryRecoveryException',
          message: 'La récupération du registre Event a échoué: $error',
        );
      }
      final failure =
          recovered.where((result) => !result.succeeded).firstOrNull;
      if (failure != null) {
        return _recovery(
          code: failure.code,
          message: failure.message,
          persistenceResult: failure,
        );
      }
    }
    return null;
  }

  Future<NarrativeEventExplicitSourceCreationResult> cleanup({
    required String projectPath,
    required String operationId,
    String? expectedEventId,
    String? expectedMapId,
    required bool confirmed,
    required bool mapDirty,
    required bool projectDirty,
    required bool saving,
  }) async {
    final blocked = _dirtyGate(
      mapDirty: mapDirty,
      projectDirty: projectDirty,
      saving: saving,
    );
    if (blocked != null) return blocked;
    if (!confirmed) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.blocked,
        code: 'confirmationRequired',
        message: 'Confirmez une seconde fois la suppression de la source.',
      );
    }

    if (expectedEventId != null || expectedMapId != null) {
      late final NarrativeEventSpatialLinkInspection inspection;
      try {
        inspection = await _sourceGateway.inspectProject(projectPath);
      } on Object catch (error) {
        return _recovery(
          code: 'sourceInspectionException',
          message: 'La source à nettoyer ne peut pas être inspectée: $error',
        );
      }
      final mismatch = _journalBindingMismatch(
        inspection,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
        expectedOperationId: operationId,
      );
      if (mismatch != null) return mismatch;
    }

    late final NarrativeEventSpatialLinkOperationResult result;
    try {
      result = await _sourceGateway.cleanupSource(
        projectPath: projectPath,
        operationId: operationId,
        confirmed: true,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'cleanupException',
        message: 'Le nettoyage de la source a échoué: $error',
      );
    }
    if (result.status == NarrativeEventSpatialLinkOperationStatus.cleaned) {
      return NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.cleaned,
        code: result.code,
        message: result.message,
        journal: result.journal,
        inspection: result.inspection,
      );
    }
    return _recovery(
      code: result.code,
      message: result.message,
      journal: result.journal,
      inspection: result.inspection,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> acknowledge({
    required String projectPath,
    required String operationId,
    required String expectedEventId,
    required String expectedMapId,
  }) async {
    late final NarrativeEventSpatialLinkInspection inspection;
    try {
      inspection = await _sourceGateway.inspectProject(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'acknowledgementInspectionException',
        message: 'Le journal finalisé ne peut pas être inspecté: $error',
      );
    }
    if (inspection.status == NarrativeEventSpatialLinkInspectionStatus.clear) {
      return const NarrativeEventExplicitSourceCreationResult(
        status: NarrativeEventExplicitSourceCreationStatus.committed,
        code: 'eventCommitAlreadyAcknowledged',
        message: 'La liaison Event était déjà acquittée.',
      );
    }
    final mismatch = _journalBindingMismatch(
      inspection,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
      expectedOperationId: operationId,
    );
    if (mismatch != null) return mismatch;
    final journal = inspection.journal;
    if (journal == null ||
        journal.state != NarrativeEventSpatialLinkJournalState.eventCommitted ||
        inspection.status !=
            NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked) {
      return _recovery(
        code: inspection.issues.firstOrNull?.code ??
            'eventCommitNotReadyForAcknowledgement',
        message: inspection.issues.firstOrNull?.message ??
            'La liaison durable n’est pas prête à être acquittée.',
        journal: journal,
        inspection: inspection,
      );
    }

    late final NarrativeEventSpatialLinkOperationResult acknowledged;
    try {
      acknowledged = await _sourceGateway.acknowledgeEventCommitted(
        projectPath: projectPath,
        operationId: operationId,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'acknowledgementException',
        message: 'La liaison est durable, mais son acquittement a échoué: '
            '$error',
        journal: journal,
        inspection: inspection,
      );
    }
    if (acknowledged.status !=
        NarrativeEventSpatialLinkOperationStatus.eventCommitted) {
      return _recovery(
        code: acknowledged.code,
        message: acknowledged.message,
        journal: acknowledged.journal ?? journal,
        inspection: acknowledged.inspection ?? inspection,
      );
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.committed,
      code: acknowledged.code,
      message: acknowledged.message,
      journal: acknowledged.journal ?? journal,
      inspection: acknowledged.inspection ?? inspection,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> _commitEventFromJournal({
    required String projectPath,
    required NarrativeEventSpatialLinkJournal journal,
  }) async {
    late final NarrativeEventAuthoringSession session;
    try {
      session = await _prepareSession(projectPath);
    } on Object catch (error) {
      return _recovery(
        code: 'freshSessionRejected',
        message: 'La source est enregistrée, mais la session Event a échoué: '
            '$error',
        journal: journal,
      );
    }
    final record = _uniqueEventRecord(
      session.context.registryOrNull,
      journal.eventId,
    );
    if (record == null) {
      return _recovery(
        code: 'eventMissing',
        message: 'La source est enregistrée, mais l’Event est introuvable.',
        journal: journal,
      );
    }
    final currentSource =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    if (currentSource == journal.source) {
      return _finalizeAlreadyLinked(
        projectPath: projectPath,
        journal: journal,
        registry: session.context.registryOrNull,
      );
    }
    if (narrativeEventRecordCanonicalFingerprint(record) !=
            journal.eventRecordFingerprintBefore ||
        record.draftOrNull == null ||
        record.draftOrNull!.source != null) {
      return _recovery(
        code: 'eventModified',
        message: 'L’Event a changé après la création de la source. '
            'Aucune liaison automatique n’a été écrite.',
        journal: journal,
      );
    }

    final authoring = selectNarrativeEventSource(
      context: session.context,
      expectedRevision: session.projectRevision,
      eventId: journal.eventId,
      source: journal.source,
    );
    if (authoring.status != NarrativeEventAuthoringStatus.applied ||
        authoring.nextRegistry == null) {
      return _recovery(
        code: authoring.rejectionCode ?? authoring.status.name,
        message: authoring.humanReason ??
            'La source est enregistrée, mais la liaison Event a été refusée.',
        journal: journal,
        previousRegistry: authoring.previousRegistry,
        nextRegistry: authoring.nextRegistry,
      );
    }
    final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
      session: session,
      operationId: '${journal.operationId}_event',
      result: authoring,
    );
    late final NarrativeEventRegistryPersistenceResult persistence;
    try {
      persistence = await _registryGateway.persist(request);
    } on Object catch (error) {
      return _recovery(
        code: 'registryPersistenceException',
        message: 'La source est enregistrée, mais le registre Event n’a pas '
            'pu être écrit: $error',
        journal: journal,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
      );
    }
    if (!persistence.succeeded) {
      return _recovery(
        code: persistence.code,
        message: persistence.message,
        journal: journal,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        persistenceResult: persistence,
      );
    }

    late final NarrativeEventSpatialLinkOperationResult finalized;
    try {
      finalized = await _sourceGateway.markEventCommitted(
        projectPath: projectPath,
        operationId: journal.operationId,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'journalFinalizeException',
        message: 'L’Event est lié, mais le journal doit être récupéré: $error',
        journal: journal,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        persistenceResult: persistence,
      );
    }
    if (finalized.status !=
        NarrativeEventSpatialLinkOperationStatus.eventCommitted) {
      return _recovery(
        code: finalized.code,
        message: finalized.message,
        journal: finalized.journal ?? journal,
        inspection: finalized.inspection,
        previousRegistry: request.previousRegistry,
        nextRegistry: request.nextRegistry,
        persistenceResult: persistence,
      );
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.committed,
      code: finalized.code,
      message: finalized.message,
      journal: finalized.journal ?? journal,
      previousRegistry: request.previousRegistry,
      nextRegistry: request.nextRegistry,
      persistenceResult: persistence,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> _finalizeAlreadyLinked({
    required String projectPath,
    required NarrativeEventSpatialLinkJournal journal,
    required NarrativeEventRegistry? registry,
  }) async {
    late final NarrativeEventSpatialLinkOperationResult finalized;
    try {
      finalized = await _sourceGateway.markEventCommitted(
        projectPath: projectPath,
        operationId: journal.operationId,
      );
    } on Object catch (error) {
      return _recovery(
        code: 'journalFinalizeException',
        message: 'L’Event est lié, mais le journal doit être récupéré: $error',
        journal: journal,
        previousRegistry: registry,
        nextRegistry: registry,
      );
    }
    if (finalized.status !=
        NarrativeEventSpatialLinkOperationStatus.eventCommitted) {
      return _recovery(
        code: finalized.code,
        message: finalized.message,
        journal: finalized.journal ?? journal,
        inspection: finalized.inspection,
        previousRegistry: registry,
        nextRegistry: registry,
      );
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.committed,
      code: 'alreadyLinkedFinalized',
      message: 'La liaison déjà écrite a été finalisée.',
      journal: finalized.journal ?? journal,
      previousRegistry: registry,
      nextRegistry: registry,
    );
  }

  Future<NarrativeEventExplicitSourceCreationResult> _afterMapCommitException({
    required String projectPath,
    required Object error,
  }) async {
    try {
      final inspection = await _sourceGateway.inspectProject(projectPath);
      final durable = inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.clear &&
          inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent;
      if (durable) {
        return _recovery(
          code: 'mapCommitInterrupted',
          message: 'La création a été interrompue après une écriture possible '
              'de la source: $error',
          journal: inspection.journal,
          inspection: inspection,
        );
      }
    } on Object {
      // The original failure remains the useful pre-commit diagnostic.
    }
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.rejected,
      code: 'mapCommitException',
      message: 'La source n’a pas pu être enregistrée: $error',
    );
  }

  NarrativeEventExplicitSourceCreationResult _recovery({
    required String code,
    required String message,
    NarrativeEventSpatialLinkJournal? journal,
    NarrativeEventSpatialLinkInspection? inspection,
    NarrativeEventRegistry? previousRegistry,
    NarrativeEventRegistry? nextRegistry,
    NarrativeEventRegistryPersistenceResult? persistenceResult,
  }) {
    return NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      code: code,
      message: message,
      journal: journal ?? inspection?.journal,
      inspection: inspection,
      previousRegistry: previousRegistry,
      nextRegistry: nextRegistry,
      persistenceResult: persistenceResult,
    );
  }
}

NarrativeEventExplicitSourceCreationResult? _dirtyGate({
  required bool mapDirty,
  required bool projectDirty,
  required bool saving,
}) {
  if (saving) {
    return const NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.blocked,
      code: 'saveInProgress',
      message: 'Attendez la fin de la sauvegarde.',
    );
  }
  if (mapDirty) {
    return const NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.blocked,
      code: 'mapDirty',
      message: 'Enregistrez la map avant de créer cette source.',
    );
  }
  if (projectDirty) {
    return const NarrativeEventExplicitSourceCreationResult(
      status: NarrativeEventExplicitSourceCreationStatus.blocked,
      code: 'projectDirty',
      message: 'Enregistrez le projet avant de créer cette source.',
    );
  }
  return null;
}

NarrativeEventExplicitSourceCreationResult? _journalBindingMismatch(
  NarrativeEventSpatialLinkInspection inspection, {
  required String? expectedEventId,
  required String? expectedMapId,
  String? expectedOperationId,
}) {
  final journal = inspection.journal;
  if (journal == null ||
      (expectedEventId == null &&
          expectedMapId == null &&
          expectedOperationId == null) ||
      (expectedEventId == null || journal.eventId == expectedEventId) &&
          (expectedMapId == null || journal.mapId == expectedMapId) &&
          (expectedOperationId == null ||
              journal.operationId == expectedOperationId)) {
    return null;
  }
  return NarrativeEventExplicitSourceCreationResult(
    status: NarrativeEventExplicitSourceCreationStatus.rejected,
    code: 'pendingJournalMismatch',
    message: 'La récupération durable appartient à un autre Event ou à une '
        'autre map. Ouvrez l’Event exact pour continuer.',
    inspection: inspection,
  );
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

String? _proposalIssue(NarrativeEventCreatedSourceProposal proposal) {
  if (proposal.beforeMap.id != proposal.afterMap.id) {
    return 'Les snapshots avant/après ne ciblent pas la même map.';
  }
  final sourceMapId = narrativeEventSpatialSourceMapId(proposal.source);
  if (sourceMapId == null || sourceMapId != proposal.beforeMap.id) {
    return 'La source créée ne cible pas la map des snapshots.';
  }
  final fingerprint = narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(proposal.ownerJson),
  );
  if (fingerprint != proposal.ownerFingerprint) {
    return 'L’empreinte du propriétaire créé est invalide.';
  }

  return proposal.source.when(
    entityInteract: (_, entityId) {
      if (proposal.physicalKind == NarrativeEventPhysicalSourceKind.zone1x1) {
        return 'Une zone doit être matérialisée par un trigger.';
      }
      final beforeOwners = proposal.beforeMap.entities
          .where((candidate) => candidate.id == entityId)
          .toList();
      final afterOwners = proposal.afterMap.entities
          .where((candidate) => candidate.id == entityId)
          .toList();
      if (beforeOwners.isNotEmpty || afterOwners.length != 1) {
        return 'Le propriétaire entity doit être absent avant et unique après.';
      }
      final owner = afterOwners.single;
      final expectedKind = switch (proposal.physicalKind) {
        NarrativeEventPhysicalSourceKind.npc => MapEntityKind.npc,
        NarrativeEventPhysicalSourceKind.sign => MapEntityKind.sign,
        NarrativeEventPhysicalSourceKind.item => MapEntityKind.item,
        NarrativeEventPhysicalSourceKind.invisible => MapEntityKind.custom,
        NarrativeEventPhysicalSourceKind.zone1x1 => null,
      };
      if (owner.kind != expectedKind ||
          (proposal.physicalKind ==
                  NarrativeEventPhysicalSourceKind.invisible &&
              owner.blocksMovement)) {
        return 'Le type physique ne correspond pas au propriétaire entity.';
      }
      final exactBounds = MapRect(pos: owner.pos, size: owner.size);
      if (proposal.bounds != exactBounds) {
        return 'Les bounds ne correspondent pas au propriétaire entity.';
      }
      final expectedEnvelope = <String, Object?>{
        'schemaVersion': 1,
        'ownerKind': 'mapEntity',
        'mapId': proposal.afterMap.id,
        'sourceId': entityId,
        'owner': _jsonSafeObject(owner.toJson()),
      };
      if (!_sameCanonicalJson(proposal.ownerJson, expectedEnvelope)) {
        return 'L’enveloppe ne correspond pas au propriétaire entity exact.';
      }
      final withoutOwner = proposal.afterMap.copyWith(
        entities: proposal.afterMap.entities
            .where((candidate) => candidate.id != entityId)
            .toList(),
      );
      if (!_sameCanonicalJson(
        proposal.beforeMap.toJson(),
        withoutOwner.toJson(),
      )) {
        return 'La proposition modifie autre chose que le propriétaire entity.';
      }
      return null;
    },
    triggerEnter: (_, triggerId) {
      if (proposal.physicalKind != NarrativeEventPhysicalSourceKind.zone1x1) {
        return 'Seule une zone peut être matérialisée par un trigger.';
      }
      final beforeOwners = proposal.beforeMap.triggers
          .where((candidate) => candidate.id == triggerId)
          .toList();
      final afterOwners = proposal.afterMap.triggers
          .where((candidate) => candidate.id == triggerId)
          .toList();
      if (beforeOwners.isNotEmpty || afterOwners.length != 1) {
        return 'Le propriétaire trigger doit être absent avant et unique après.';
      }
      final owner = afterOwners.single;
      if (owner.type != TriggerType.event ||
          owner.area.size != const GridSize(width: 1, height: 1) ||
          proposal.bounds != owner.area) {
        return 'La zone créée doit être un trigger Event 1×1 exact.';
      }
      final expectedEnvelope = <String, Object?>{
        'schemaVersion': 1,
        'ownerKind': 'mapTrigger',
        'mapId': proposal.afterMap.id,
        'sourceId': triggerId,
        'owner': _jsonSafeObject(owner.toJson()),
      };
      if (!_sameCanonicalJson(proposal.ownerJson, expectedEnvelope)) {
        return 'L’enveloppe ne correspond pas au propriétaire trigger exact.';
      }
      final withoutOwner = proposal.afterMap.copyWith(
        triggers: proposal.afterMap.triggers
            .where((candidate) => candidate.id != triggerId)
            .toList(),
      );
      if (!_sameCanonicalJson(
        proposal.beforeMap.toJson(),
        withoutOwner.toJson(),
      )) {
        return 'La proposition modifie autre chose que le propriétaire trigger.';
      }
      return null;
    },
    mapEnter: (_) => 'Une création explicite ne peut pas créer une map.',
    outcomeReceived: (_) =>
        'Une création explicite ne peut pas créer un résultat narratif.',
  );
}

bool _sameCanonicalJson(Object? left, Object? right) {
  return narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(_jsonSafeValue(left)),
      ) ==
      narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(_jsonSafeValue(right)),
      );
}

Map<String, Object?> _jsonSafeObject(Map<String, dynamic> value) {
  return Map<String, Object?>.from(
    (_jsonSafeValue(value) as Map).cast<String, Object?>(),
  );
}

Object? _jsonSafeValue(Object? value) => jsonDecode(jsonEncode(value));

String _defaultOperationId() {
  return 'v2_25_${DateTime.now().microsecondsSinceEpoch}';
}
