import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

final class NarrativeEventSpatialLinkJournalRepository
    implements NarrativeEventSpatialSourceCreationGateway {
  NarrativeEventSpatialLinkJournalRepository({
    DateTime Function()? clock,
    this.faultInjector,
    NarrativeEventRegistryPersistence? eventRegistryPersistence,
  })  : _clock = clock ?? DateTime.now,
        _eventRegistryPersistence =
            eventRegistryPersistence ?? NarrativeEventRegistryPersistence();

  static const journalPrefix = '.pokemap-event-spatial-link-';
  static const journalSuffix = '.journal.json';
  static const mapTempSuffix = '.map.tmp';

  final DateTime Function() _clock;
  final NarrativeEventSpatialLinkFaultInjector? faultInjector;
  final NarrativeEventRegistryPersistence _eventRegistryPersistence;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    final project = await _qualifyProject(request.projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    return withProjectManifestWriteLock(project.path!, () async {
      final registryGate = await _eventRegistryPersistence
          .inspectProjectAlreadyLocked(project.path!);
      if (registryGate.status !=
          NarrativeEventRegistryRecoveryGateStatus.clear) {
        return _registryRecoveryBlocked(registryGate);
      }
      final existing = await _inspectLocked(project.path!);
      if (existing.status != NarrativeEventSpatialLinkInspectionStatus.clear) {
        return _blocked(
          'pendingSpatialLinkJournal',
          'Une autre liaison spatiale doit être récupérée avant de continuer.',
          inspection: existing,
        );
      }
      return _commitMapLocked(project.path!, request);
    });
  }

  Future<NarrativeEventSpatialLinkOperationResult> _commitMapLocked(
    String projectPath,
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    final projectFile = File(projectPath);
    final projectBytes = await projectFile.readAsBytes();
    final projectRevision = narrativeEventBytesFingerprint(projectBytes);
    if (projectRevision != request.projectRevision) {
      return _conflict(
        'staleProjectRevision',
        'Le projet a changé avant la préparation de la source.',
      );
    }
    late final ValidatedNarrativeEventAuthoringProject project;
    try {
      project = decodeValidatedNarrativeEventAuthoringProject(projectBytes);
    } on Object catch (error) {
      return _blocked(
        'invalidProject',
        'Le manifest du projet est invalide: $error',
      );
    }
    final eventRecord = _eventRecord(
      project.manifest.eventRegistry,
      request.eventId,
    );
    if (eventRecord == null) {
      return _blocked(
        'eventMissing',
        'L’Event ${request.eventId} est absent du registry.',
      );
    }
    if (narrativeEventRecordCanonicalFingerprint(eventRecord) !=
        request.eventRecordFingerprintBefore) {
      return _conflict(
        'eventRecordFingerprintMismatch',
        'L’Event cible a changé depuis la préparation de la création.',
      );
    }
    final mapResolution = await _resolveManifestMap(
      projectPath: projectPath,
      project: project.manifest,
      mapId: request.beforeMap.id,
    );
    if (mapResolution.issue case final issue?) return _blockedIssue(issue);
    final mapPath = mapResolution.path!;
    final beforeBytes = await File(mapPath).readAsBytes();
    final beforeHash = narrativeEventBytesFingerprint(beforeBytes);
    late final MapData diskBefore;
    try {
      diskBefore = decodeValidatedNarrativeEventAuthoringMap(
        beforeBytes,
        mapPath,
      );
    } on Object catch (error) {
      return _blocked('invalidMap', 'La map courante est invalide: $error');
    }
    if (!_sameJson(diskBefore.toJson(), request.beforeMap.toJson())) {
      return _conflict(
        'staleBeforeMap',
        'La map disque ne correspond pas à la proposition préparée.',
      );
    }
    final proposalIssue = _validateExactSourceAddition(request);
    if (proposalIssue != null) return _blockedIssue(proposalIssue);
    late final List<int> afterBytes;
    late final MapData verifiedAfter;
    try {
      afterBytes = _canonicalJsonUtf8(request.afterMap.toJson());
      verifiedAfter = decodeValidatedNarrativeEventAuthoringMap(
        afterBytes,
        mapPath,
      );
    } on Object catch (error) {
      return _blocked(
          'invalidAfterMap', 'La map proposée est invalide: $error');
    }
    final diskOwnerIssue = _exactOwnerIssue(
      map: verifiedAfter,
      source: request.source,
      expectedOwnerJson: request.sourceOwnerJson,
      expectedFingerprint: request.sourceOwnerFingerprint,
    );
    if (diskOwnerIssue != null) return _blockedIssue(diskOwnerIssue);

    final paths = _pathsFor(
      projectPath: projectPath,
      mapPath: mapPath,
      operationId: request.operationId,
    );
    final pathIssue = await _writableArtifactPathIssue(paths);
    if (pathIssue != null) return _blockedIssue(pathIssue);
    final preparedAt = _clock().toUtc();
    var journal = NarrativeEventSpatialLinkJournal(
      schemaVersion: 1,
      operationId: request.operationId,
      projectPath: projectPath,
      projectRevision: projectRevision,
      journalPath: paths.journalPath,
      mapPath: mapPath,
      mapTempPath: paths.mapTempPath,
      mapId: request.beforeMap.id,
      eventId: request.eventId,
      eventRecordFingerprintBefore: request.eventRecordFingerprintBefore,
      source: request.source,
      sourceOwnerJson: request.sourceOwnerJson,
      sourceOwnerFingerprint: request.sourceOwnerFingerprint,
      beforeMapHash: beforeHash,
      afterMapHash: narrativeEventBytesFingerprint(afterBytes),
      state: NarrativeEventSpatialLinkJournalState.prepared,
      preparedAt: preparedAt,
      cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.none,
    );
    await _writeJournal(journal);
    await _checkpoint(
      NarrativeEventSpatialLinkCheckpoint.afterJournalPrepared,
    );
    await _writeBytesFlushed(paths.mapTempPath, afterBytes);
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterMapTempFlush);
    final tempHash = narrativeEventBytesFingerprint(
      await File(paths.mapTempPath).readAsBytes(),
    );
    if (tempHash != journal.afterMapHash) {
      return _blocked(
        'mapTempHashMismatch',
        'Le fichier temporaire de map ne correspond pas au hash attendu.',
        journal: journal,
      );
    }
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.beforeMapRename);
    final renamePathIssue = await _symbolicLinkIssue([
      projectPath,
      mapPath,
      paths.mapTempPath,
    ]);
    if (renamePathIssue != null) {
      await _deleteIfRegular(paths.mapTempPath);
      return _blockedIssue(renamePathIssue, journal: journal);
    }
    final liveProjectRevision = narrativeEventBytesFingerprint(
      await projectFile.readAsBytes(),
    );
    if (liveProjectRevision != projectRevision) {
      await _deleteIfRegular(paths.mapTempPath);
      return _conflict(
        'staleProjectRevisionBeforeMapRename',
        'Le projet a changé pendant la préparation de la map.',
        journal: journal,
      );
    }
    final liveMapHash = narrativeEventBytesFingerprint(
      await File(mapPath).readAsBytes(),
    );
    if (liveMapHash != beforeHash) {
      await _deleteIfRegular(paths.mapTempPath);
      return _conflict(
        'staleMapRevisionBeforeRename',
        'La map a changé pendant la préparation.',
        journal: journal,
      );
    }
    await File(paths.mapTempPath).rename(mapPath);
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterMapRename);
    final committedBytes = await File(mapPath).readAsBytes();
    final committedHash = narrativeEventBytesFingerprint(committedBytes);
    if (committedHash != journal.afterMapHash) {
      return _blocked(
        'committedMapHashMismatch',
        'La map écrite ne correspond pas au hash attendu.',
        journal: journal,
      );
    }
    late final MapData committedMap;
    try {
      committedMap = decodeValidatedNarrativeEventAuthoringMap(
        committedBytes,
        mapPath,
      );
    } on Object catch (error) {
      return _blocked(
        'committedMapInvalid',
        'La map écrite ne peut pas être relue: $error',
        journal: journal,
      );
    }
    final committedOwnerIssue = _exactOwnerIssue(
      map: committedMap,
      source: journal.source,
      expectedOwnerJson: journal.sourceOwnerJson,
      expectedFingerprint: journal.sourceOwnerFingerprint,
    );
    if (committedOwnerIssue != null) {
      return _blockedIssue(committedOwnerIssue, journal: journal);
    }
    await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterMapVerified);
    journal = journal.markMapCommitted(_clock().toUtc());
    await _writeJournal(journal);
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.mapCommitted,
      code: 'mapCommitted',
      message: 'La source physique a été enregistrée sur la map.',
      journal: journal,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) {
      return NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.blocked,
        issues: [issue],
      );
    }
    return withProjectManifestWriteLock(
      project.path!,
      () => _inspectLocked(project.path!),
    );
  }

  Future<NarrativeEventSpatialLinkInspection> _inspectLocked(
    String projectPath,
  ) async {
    final artifacts = await _journalArtifacts(projectPath);
    if (artifacts.rewriteTemps.isNotEmpty) {
      return _inspectionBlocked(
        'orphanJournalTemp',
        'Un temporaire de journal orphelin exige une inspection manuelle.',
        artifacts.rewriteTemps.first,
      );
    }
    if (artifacts.journals.length > 1) {
      return _inspectionBlocked(
        'multipleJournals',
        'Plusieurs journaux de liaison spatiale sont présents.',
        artifacts.journals.first,
      );
    }
    if (artifacts.journals.isEmpty) {
      return NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    }
    final journalPath = artifacts.journals.single;
    if (await FileSystemEntity.type(journalPath, followLinks: false) ==
        FileSystemEntityType.link) {
      return _inspectionBlocked(
        'symbolicLinkRefused',
        'Le journal ne peut pas être un lien symbolique.',
        journalPath,
      );
    }
    late final NarrativeEventSpatialLinkJournal journal;
    try {
      final decoded = decodeNarrativeEventJsonStrict(
        await File(journalPath).readAsString(),
      );
      journal = NarrativeEventSpatialLinkJournal.fromJson(
        _jsonObject(decoded),
      );
    } on Object catch (error) {
      return _inspectionBlocked(
        'invalidJournal',
        'Le journal est invalide: $error',
        journalPath,
      );
    }
    final pathIssue = await _journalPathIssue(
      projectPath: projectPath,
      actualJournalPath: journalPath,
      journal: journal,
    );
    if (pathIssue != null) {
      return NarrativeEventSpatialLinkInspection(
        status: NarrativeEventSpatialLinkInspectionStatus.blocked,
        journal: journal,
        issues: [pathIssue],
      );
    }
    late final List<int> mapBytes;
    late final MapData map;
    try {
      mapBytes = await File(journal.mapPath).readAsBytes();
      map = decodeValidatedNarrativeEventAuthoringMap(
        mapBytes,
        journal.mapPath,
      );
    } on Object catch (error) {
      return _inspectionBlocked(
        'inspectionReadFailure',
        'Le projet ou la map ne peut pas être relu: $error',
        journalPath,
        journal: journal,
      );
    }
    final owner = _ownerState(
      map: map,
      source: journal.source,
      expectedOwnerJson: journal.sourceOwnerJson,
      expectedFingerprint: journal.sourceOwnerFingerprint,
    );
    if (journal.state == NarrativeEventSpatialLinkJournalState.prepared) {
      final mapHash = narrativeEventBytesFingerprint(mapBytes);
      if (owner.kind == _OwnerStateKind.absent &&
          mapHash == journal.beforeMapHash) {
        return NarrativeEventSpatialLinkInspection(
          status:
              NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent,
          journal: journal,
        );
      }
      if (owner.kind == _OwnerStateKind.exact &&
          mapHash == journal.afterMapHash) {
        return NarrativeEventSpatialLinkInspection(
          status:
              NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent,
          journal: journal,
        );
      }
      if (owner.kind == _OwnerStateKind.modified) {
        return _inspectionBlocked(
          'sourceFingerprintMismatch',
          'La source physique a été modifiée depuis sa création.',
          journal.mapPath,
          journal: journal,
        );
      }
      return _inspectionBlocked(
        'unknownPreparedMapRevision',
        'La map ne correspond ni à l’état avant ni à l’état committé.',
        journal.mapPath,
        journal: journal,
      );
    }
    final registryGate = await _eventRegistryPersistence
        .inspectProjectAlreadyLocked(projectPath);
    if (registryGate.status != NarrativeEventRegistryRecoveryGateStatus.clear) {
      final issue = registryGate.issues.firstOrNull;
      return _inspectionBlocked(
        registryGate.status ==
                NarrativeEventRegistryRecoveryGateStatus.recoveryRequired
            ? 'eventRegistryRecoveryRequired'
            : 'eventRegistryRecoveryBlocked',
        issue?.message ??
            'Le registry Event doit être récupéré avant cette liaison.',
        issue?.path ?? projectPath,
        journal: journal,
      );
    }
    late final ValidatedNarrativeEventAuthoringProject project;
    try {
      project = decodeValidatedNarrativeEventAuthoringProject(
        await File(projectPath).readAsBytes(),
      );
    } on Object catch (error) {
      return _inspectionBlocked(
        'inspectionReadFailure',
        'Le projet ne peut pas être relu: $error',
        journalPath,
        journal: journal,
      );
    }
    if (owner.kind == _OwnerStateKind.modified) {
      return _inspectionBlocked(
        'sourceFingerprintMismatch',
        'La source physique a été modifiée depuis sa création.',
        journal.mapPath,
        journal: journal,
      );
    }
    final targetEventRecord =
        _eventRecord(project.manifest.eventRegistry, journal.eventId);
    if (targetEventRecord == null) {
      return _inspectionBlocked(
        'eventRecordMissing',
        'L’Event cible a été supprimé depuis le commit map.',
        projectPath,
        journal: journal,
      );
    }
    final eventSource = _recordSource(targetEventRecord);
    final exactEventLinked = eventSource == journal.source;
    final eventSourceMismatch = eventSource != null && !exactEventLinked;
    if (eventSourceMismatch) {
      return _inspectionBlocked(
        'eventSourceMismatch',
        'L’Event est désormais lié à une autre source.',
        projectPath,
        journal: journal,
      );
    }
    if (!exactEventLinked &&
        narrativeEventRecordCanonicalFingerprint(targetEventRecord) !=
            journal.eventRecordFingerprintBefore) {
      return _inspectionBlocked(
        'eventRecordChanged',
        'L’Event cible a été modifié depuis le commit map.',
        projectPath,
        journal: journal,
      );
    }
    if (journal.cleanupMarker ==
        NarrativeEventSpatialLinkCleanupMarker.requested) {
      return NarrativeEventSpatialLinkInspection(
        status: owner.kind == _OwnerStateKind.absent
            ? NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted
            : NarrativeEventSpatialLinkInspectionStatus.cleanupPending,
        journal: journal,
      );
    }
    switch (journal.state) {
      case NarrativeEventSpatialLinkJournalState.prepared:
        return _inspectionBlocked(
          'invalidPreparedInspectionState',
          'Le journal préparé n’a pas été classifié avant validation Event.',
          journalPath,
          journal: journal,
        );
      case NarrativeEventSpatialLinkJournalState.mapCommitted:
        if (owner.kind == _OwnerStateKind.absent) {
          return _inspectionBlocked(
            'sourceUnexpectedlyAbsent',
            'La source committée est absente sans marqueur de nettoyage.',
            journal.mapPath,
            journal: journal,
          );
        }
        return NarrativeEventSpatialLinkInspection(
          status: exactEventLinked
              ? NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked
              : NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit,
          journal: journal,
        );
      case NarrativeEventSpatialLinkJournalState.eventCommitted:
        if (owner.kind != _OwnerStateKind.exact || !exactEventLinked) {
          return _inspectionBlocked(
            'eventCommittedInvariantMismatch',
            'Le journal finalisé ne correspond plus au projet.',
            journalPath,
            journal: journal,
          );
        }
        return NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked,
          journal: journal,
        );
    }
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(expectedOperationId);
    if (safeOperationId == null ||
        expectedEventId.trim().isEmpty ||
        expectedMapId.trim().isEmpty ||
        narrativeEventSpatialSourceMapId(expectedSource) != expectedMapId) {
      return _blocked(
        'invalidRecoveryIdentity',
        'L’identité attendue pour la récupération est invalide.',
      );
    }
    return withProjectManifestWriteLock(project.path!, () async {
      final inspection = await _inspectLocked(project.path!);
      final journal = inspection.journal;
      if (journal == null ||
          journal.operationId != safeOperationId ||
          journal.eventId != expectedEventId ||
          journal.mapId != expectedMapId ||
          journal.source != expectedSource) {
        return _conflict(
          'recoveryJournalMismatch',
          'Le journal durable a changé depuis son inspection. Aucune '
              'récupération n’a été appliquée.',
          journal: journal,
          inspection: inspection,
        );
      }
      switch (inspection.status) {
        case NarrativeEventSpatialLinkInspectionStatus.clear:
          return NarrativeEventSpatialLinkOperationResult(
            status: NarrativeEventSpatialLinkOperationStatus.noOp,
            code: 'noJournal',
            message: 'Aucun journal spatial à récupérer.',
            inspection: inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.preparedSourceAbsent:
          await _deleteCompletedArtifacts(journal);
          return _recovered(
            'preparedNoOpRemoved',
            'Le journal préparé sans écriture map a été retiré.',
            journal,
            inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.preparedSourcePresent:
          final promoted = journal.markMapCommitted(_clock().toUtc());
          await _writeJournal(promoted);
          final postPromotion = await _inspectLocked(project.path!);
          if (postPromotion.status ==
              NarrativeEventSpatialLinkInspectionStatus.blocked) {
            return _blocked(
              postPromotion.issues.firstOrNull?.code ??
                  'postPromotionValidationBlocked',
              postPromotion.issues.firstOrNull?.message ??
                  'La validation Event après promotion a échoué.',
              journal: promoted,
              inspection: postPromotion,
            );
          }
          return _recovered(
            'preparedPromotedToMapCommitted',
            'Le commit map interrompu a été reconnu.',
            promoted,
            postPromotion,
          );
        case NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked:
          final completed = journal.state ==
                  NarrativeEventSpatialLinkJournalState.eventCommitted
              ? journal
              : journal.markEventCommitted(_clock().toUtc());
          await _writeJournal(completed);
          return _recovered(
            'eventCommitRecovered',
            'La liaison Event déjà durable attend son acquittement éditeur.',
            completed,
            inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted:
          await _deleteCompletedArtifacts(journal);
          return _recovered(
            'cleanupRecovered',
            'Le nettoyage déjà durable a été finalisé.',
            journal,
            inspection,
          );
        case NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit:
        case NarrativeEventSpatialLinkInspectionStatus.cleanupPending:
        case NarrativeEventSpatialLinkInspectionStatus.blocked:
          return _blocked(
            inspection.issues.firstOrNull?.code ?? 'manualActionRequired',
            inspection.issues.firstOrNull?.message ??
                'Une action explicite est requise pour cette liaison.',
            journal: journal,
            inspection: inspection,
          );
      }
    });
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(operationId);
    if (safeOperationId == null) {
      return _blocked('invalidOperationId', 'L’identifiant est invalide.');
    }
    return withProjectManifestWriteLock(project.path!, () async {
      final inspection = await _inspectLocked(project.path!);
      final journal = inspection.journal;
      if (journal == null || journal.operationId != safeOperationId) {
        return _blocked(
          'journalMissing',
          'Le journal de cette opération est absent.',
          inspection: inspection,
        );
      }
      if (inspection.status !=
          NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked) {
        return _blocked(
          inspection.status ==
                  NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit
              ? 'eventNotLinked'
              : inspection.issues.firstOrNull?.code ?? 'eventCommitBlocked',
          inspection.issues.firstOrNull?.message ??
              'L’Event n’est pas lié à la source exacte.',
          journal: journal,
          inspection: inspection,
        );
      }
      final completed =
          journal.state == NarrativeEventSpatialLinkJournalState.eventCommitted
              ? journal
              : journal.markEventCommitted(_clock().toUtc());
      await _writeJournal(completed);
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
        code: 'eventCommitted',
        message: 'La liaison Event a été finalisée.',
        journal: completed,
        inspection: inspection,
      );
    });
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) async {
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(operationId);
    if (safeOperationId == null) {
      return _blocked('invalidOperationId', 'L’identifiant est invalide.');
    }
    return withProjectManifestWriteLock(project.path!, () async {
      final inspection = await _inspectLocked(project.path!);
      if (inspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.clear) {
        return const NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
          code: 'eventCommitAlreadyAcknowledged',
          message: 'La liaison Event était déjà acquittée.',
        );
      }
      final journal = inspection.journal;
      if (journal == null || journal.operationId != safeOperationId) {
        return _blocked(
          'journalMissing',
          'Le journal de cette opération est absent.',
          inspection: inspection,
        );
      }
      if (journal.state !=
              NarrativeEventSpatialLinkJournalState.eventCommitted ||
          inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.eventAlreadyLinked) {
        return _blocked(
          inspection.issues.firstOrNull?.code ?? 'acknowledgementBlocked',
          inspection.issues.firstOrNull?.message ??
              'La liaison exacte doit être durable avant son acquittement.',
          journal: journal,
          inspection: inspection,
        );
      }
      await _deleteCompletedArtifacts(journal);
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
        code: 'eventCommitAcknowledged',
        message: 'La liaison Event durable a été acquittée par l’éditeur.',
        journal: journal,
        inspection: inspection,
      );
    });
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      return _blocked(
        'confirmationRequired',
        'La suppression de la source exige une confirmation explicite.',
      );
    }
    final project = await _qualifyProject(projectPath);
    if (project.issue case final issue?) return _blockedIssue(issue);
    final safeOperationId = _safeOperationId(operationId);
    if (safeOperationId == null) {
      return _blocked('invalidOperationId', 'L’identifiant est invalide.');
    }
    return withProjectManifestWriteLock(project.path!, () async {
      var inspection = await _inspectLocked(project.path!);
      var journal = inspection.journal;
      if (journal == null || journal.operationId != safeOperationId) {
        return _blocked(
          'journalMissing',
          'Le journal de cette opération est absent.',
          inspection: inspection,
        );
      }
      final cleanupProjectBytes = await File(project.path!).readAsBytes();
      final cleanupProjectRevision =
          narrativeEventBytesFingerprint(cleanupProjectBytes);
      final cleanupProject = decodeValidatedNarrativeEventAuthoringProject(
        cleanupProjectBytes,
      ).manifest;
      final referenceIssue = _sourceReferenceIssue(
        cleanupProject.eventRegistry,
        journal,
      );
      if (referenceIssue != null) {
        return _blockedIssue(referenceIssue, journal: journal);
      }
      if (inspection.status ==
          NarrativeEventSpatialLinkInspectionStatus.cleanupCompleted) {
        await _deleteCompletedArtifacts(journal);
        return NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.cleaned,
          code: 'cleanupAlreadyCommitted',
          message: 'La source était déjà supprimée.',
          journal: journal,
          inspection: inspection,
        );
      }
      if (inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.awaitingEventCommit &&
          inspection.status !=
              NarrativeEventSpatialLinkInspectionStatus.cleanupPending) {
        return _blocked(
          inspection.issues.firstOrNull?.code ?? 'cleanupBlocked',
          inspection.issues.firstOrNull?.message ??
              'La source ne peut pas être supprimée en sécurité.',
          journal: journal,
          inspection: inspection,
        );
      }
      final mapBytes = await File(journal.mapPath).readAsBytes();
      final currentMap = decodeValidatedNarrativeEventAuthoringMap(
        mapBytes,
        journal.mapPath,
      );
      final ownerIssue = _exactOwnerIssue(
        map: currentMap,
        source: journal.source,
        expectedOwnerJson: journal.sourceOwnerJson,
        expectedFingerprint: journal.sourceOwnerFingerprint,
      );
      if (ownerIssue != null) {
        return _blockedIssue(ownerIssue, journal: journal);
      }
      if (journal.cleanupMarker ==
          NarrativeEventSpatialLinkCleanupMarker.none) {
        journal = journal.markCleanupRequested(_clock().toUtc());
        await _writeJournal(journal);
        await _checkpoint(
          NarrativeEventSpatialLinkCheckpoint.afterCleanupJournalMarked,
        );
        inspection = NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.cleanupPending,
          journal: journal,
        );
      }
      final cleanedMap = _removeExactOwner(currentMap, journal.source);
      final cleanedBytes = _canonicalJsonUtf8(cleanedMap.toJson());
      decodeValidatedNarrativeEventAuthoringMap(
        cleanedBytes,
        journal.mapPath,
      );
      await _writeBytesFlushed(journal.mapTempPath, cleanedBytes);
      final tempHash = narrativeEventBytesFingerprint(
        await File(journal.mapTempPath).readAsBytes(),
      );
      final expectedCleanedHash = narrativeEventBytesFingerprint(cleanedBytes);
      if (tempHash != expectedCleanedHash) {
        return _blocked(
          'cleanupTempHashMismatch',
          'Le temporaire de nettoyage est invalide.',
          journal: journal,
          inspection: inspection,
        );
      }
      await _checkpoint(
        NarrativeEventSpatialLinkCheckpoint.beforeCleanupRename,
      );
      final cleanupPathIssue = await _symbolicLinkIssue([
        project.path!,
        journal.mapPath,
        journal.mapTempPath,
      ]);
      if (cleanupPathIssue != null) {
        await _deleteIfRegular(journal.mapTempPath);
        return _blockedIssue(cleanupPathIssue, journal: journal);
      }
      final liveProjectBytes = await File(project.path!).readAsBytes();
      final liveProjectHash = narrativeEventBytesFingerprint(liveProjectBytes);
      if (liveProjectHash != cleanupProjectRevision) {
        await _deleteIfRegular(journal.mapTempPath);
        return _conflict(
          'projectChangedDuringCleanup',
          'Le projet a changé pendant le nettoyage de la source.',
          journal: journal,
          inspection: inspection,
        );
      }
      final liveProject = decodeValidatedNarrativeEventAuthoringProject(
        liveProjectBytes,
      );
      final liveReferenceIssue = _sourceReferenceIssue(
        liveProject.manifest.eventRegistry,
        journal,
      );
      if (liveReferenceIssue != null) {
        await _deleteIfRegular(journal.mapTempPath);
        return _conflict(
          liveReferenceIssue.code,
          liveReferenceIssue.message,
          journal: journal,
          inspection: inspection,
        );
      }
      final liveMapHash = narrativeEventBytesFingerprint(
        await File(journal.mapPath).readAsBytes(),
      );
      if (liveMapHash != narrativeEventBytesFingerprint(mapBytes)) {
        await _deleteIfRegular(journal.mapTempPath);
        return _conflict(
          'staleMapRevisionBeforeCleanup',
          'La map a changé pendant le nettoyage.',
          journal: journal,
          inspection: inspection,
        );
      }
      await File(journal.mapTempPath).rename(journal.mapPath);
      await _checkpoint(NarrativeEventSpatialLinkCheckpoint.afterCleanupRename);
      final committedBytes = await File(journal.mapPath).readAsBytes();
      if (narrativeEventBytesFingerprint(committedBytes) !=
          expectedCleanedHash) {
        return _blocked(
          'cleanupMapHashMismatch',
          'La map nettoyée ne correspond pas au hash attendu.',
          journal: journal,
          inspection: inspection,
        );
      }
      final committedMap = decodeValidatedNarrativeEventAuthoringMap(
        committedBytes,
        journal.mapPath,
      );
      if (_ownerState(
            map: committedMap,
            source: journal.source,
            expectedOwnerJson: journal.sourceOwnerJson,
            expectedFingerprint: journal.sourceOwnerFingerprint,
          ).kind !=
          _OwnerStateKind.absent) {
        return _blocked(
          'cleanupOwnerStillPresent',
          'La source est encore présente après le nettoyage.',
          journal: journal,
          inspection: inspection,
        );
      }
      await _deleteCompletedArtifacts(journal);
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.cleaned,
        code: 'sourceCleaned',
        message: 'Seule la source physique inchangée a été supprimée.',
        journal: journal,
        inspection: inspection,
      );
    });
  }

  Future<_PathResolution> _qualifyProject(String projectPath) async {
    final input = File(p.normalize(File(projectPath).absolute.path));
    final type = await FileSystemEntity.type(input.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      return _PathResolution.issue(_issue(
        'symbolicLinkRefused',
        'Le manifest ne peut pas être un lien symbolique.',
        input.path,
      ));
    }
    if (type != FileSystemEntityType.file) {
      return _PathResolution.issue(_issue(
        'projectMissing',
        'Le manifest du projet est introuvable.',
        input.path,
      ));
    }
    return _PathResolution.path(
      p.normalize(await input.resolveSymbolicLinks()),
    );
  }

  Future<_PathResolution> _resolveManifestMap({
    required String projectPath,
    required ProjectManifest project,
    required String mapId,
  }) async {
    final matching = project.maps.where((entry) => entry.id == mapId).toList();
    if (matching.length != 1) {
      return _PathResolution.issue(_issue(
        'mapManifestIdentityMismatch',
        'La map $mapId doit apparaître exactement une fois dans le manifest.',
        projectPath,
      ));
    }
    final relativePath = matching.single.relativePath;
    if (p.isAbsolute(relativePath) ||
        p.split(relativePath).any((part) => part == '..')) {
      return _PathResolution.issue(_issue(
        'unsafeMapPath',
        'Le chemin de map doit rester relatif au projet.',
        relativePath,
      ));
    }
    final projectRoot = p.dirname(projectPath);
    final candidate = p.normalize(p.join(projectRoot, relativePath));
    if (!p.isWithin(projectRoot, candidate)) {
      return _PathResolution.issue(_issue(
        'unsafeMapPath',
        'Le chemin de map sort du projet.',
        candidate,
      ));
    }
    var cursor = projectRoot;
    for (final part in p.split(p.relative(candidate, from: projectRoot))) {
      cursor = p.join(cursor, part);
      final type = await FileSystemEntity.type(cursor, followLinks: false);
      if (type == FileSystemEntityType.link) {
        return _PathResolution.issue(_issue(
          'symbolicLinkRefused',
          'Les liens symboliques sont refusés pour la map.',
          cursor,
        ));
      }
    }
    if (await FileSystemEntity.type(candidate, followLinks: false) !=
        FileSystemEntityType.file) {
      return _PathResolution.issue(_issue(
        'mapMissing',
        'La map $mapId est introuvable.',
        candidate,
      ));
    }
    final canonical = p.normalize(await File(candidate).resolveSymbolicLinks());
    if (!p.isWithin(projectRoot, canonical)) {
      return _PathResolution.issue(_issue(
        'unsafeMapPath',
        'La map résolue sort du projet.',
        canonical,
      ));
    }
    return _PathResolution.path(canonical);
  }

  NarrativeEventSpatialLinkInspectionIssue? _validateExactSourceAddition(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) {
    final beforeOwner = _ownerState(
      map: request.beforeMap,
      source: request.source,
      expectedOwnerJson: request.sourceOwnerJson,
      expectedFingerprint: request.sourceOwnerFingerprint,
    );
    if (beforeOwner.kind != _OwnerStateKind.absent) {
      return _issue(
        'sourceAlreadyPresent',
        'La source existe déjà dans la map avant proposition.',
      );
    }
    final afterOwnerIssue = _exactOwnerIssue(
      map: request.afterMap,
      source: request.source,
      expectedOwnerJson: request.sourceOwnerJson,
      expectedFingerprint: request.sourceOwnerFingerprint,
    );
    if (afterOwnerIssue != null) return afterOwnerIssue;
    final withoutSource = _removeExactOwner(request.afterMap, request.source);
    if (!_sameJson(withoutSource.toJson(), request.beforeMap.toJson())) {
      return _issue(
        'proposalMutatesUnrelatedMapContent',
        'La proposition doit ajouter uniquement sa source physique.',
      );
    }
    return null;
  }

  _OwnerState _ownerState({
    required MapData map,
    required NarrativeEventSourceRef source,
    required Map<String, Object?> expectedOwnerJson,
    required String expectedFingerprint,
  }) {
    final owner = _ownerEnvelope(map, source);
    if (owner == null) return const _OwnerState(_OwnerStateKind.absent);
    final fingerprint = narrativeEventBytesFingerprint(
      _canonicalJsonUtf8(owner),
    );
    if (fingerprint != expectedFingerprint ||
        !_sameJson(owner, expectedOwnerJson)) {
      return _OwnerState(_OwnerStateKind.modified, fingerprint: fingerprint);
    }
    return _OwnerState(_OwnerStateKind.exact, fingerprint: fingerprint);
  }

  NarrativeEventSpatialLinkInspectionIssue? _exactOwnerIssue({
    required MapData map,
    required NarrativeEventSourceRef source,
    required Map<String, Object?> expectedOwnerJson,
    required String expectedFingerprint,
  }) {
    final owner = _ownerState(
      map: map,
      source: source,
      expectedOwnerJson: expectedOwnerJson,
      expectedFingerprint: expectedFingerprint,
    );
    return switch (owner.kind) {
      _OwnerStateKind.exact => null,
      _OwnerStateKind.absent => _issue(
          'sourceUnexpectedlyAbsent',
          'La source physique attendue est absente.',
        ),
      _OwnerStateKind.modified => _issue(
          'sourceFingerprintMismatch',
          'La source physique ne correspond pas à son fingerprint.',
        ),
    };
  }

  Map<String, Object?>? _ownerEnvelope(
    MapData map,
    NarrativeEventSourceRef source,
  ) {
    return source.when(
      entityInteract: (mapId, entityId) {
        if (map.id != mapId) return null;
        final owners = map.entities.where((entity) => entity.id == entityId);
        if (owners.length != 1) return null;
        final owner = owners.single;
        return {
          'schemaVersion': 1,
          'ownerKind': 'mapEntity',
          'mapId': mapId,
          'sourceId': entityId,
          'owner': owner.toJson(),
        };
      },
      triggerEnter: (mapId, triggerId) {
        if (map.id != mapId) return null;
        final owners = map.triggers.where((trigger) => trigger.id == triggerId);
        if (owners.length != 1) return null;
        final owner = owners.single;
        return {
          'schemaVersion': 1,
          'ownerKind': 'mapTrigger',
          'mapId': mapId,
          'sourceId': triggerId,
          'owner': owner.toJson(),
        };
      },
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );
  }

  MapData _removeExactOwner(MapData map, NarrativeEventSourceRef source) {
    return source.when(
      entityInteract: (_, entityId) => map.copyWith(
        entities: [
          for (final entity in map.entities)
            if (entity.id != entityId) entity,
        ],
      ),
      triggerEnter: (_, triggerId) => map.copyWith(
        triggers: [
          for (final trigger in map.triggers)
            if (trigger.id != triggerId) trigger,
        ],
      ),
      mapEnter: (_) => throw ArgumentError.value(source, 'source'),
      outcomeReceived: (_) => throw ArgumentError.value(source, 'source'),
    );
  }

  NarrativeEventRecord? _eventRecord(
    NarrativeEventRegistry? registry,
    String eventId,
  ) {
    final records = registry?.records.where((record) => record.id == eventId) ??
        const <NarrativeEventRecord>[];
    if (records.length != 1) return null;
    return records.single;
  }

  NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) {
    return record.when(
      draft: (draft) => draft.source,
      configured: (definition, _) => definition.source,
    );
  }

  NarrativeEventSpatialLinkInspectionIssue? _sourceReferenceIssue(
    NarrativeEventRegistry? registry,
    NarrativeEventSpatialLinkJournal journal,
  ) {
    if (registry == null) return null;
    final recordIds = <String>[
      for (final record in registry.records)
        if (_recordSource(record) == journal.source) record.id,
    ];
    if (recordIds.any((id) => id != journal.eventId)) {
      return _issue(
        'sourceReferencedByAnotherEvent',
        'Un autre Event référence désormais cette source physique.',
      );
    }
    if (recordIds.isNotEmpty) {
      return _issue(
        'sourceReferencedByTargetEvent',
        'L’Event cible référence déjà cette source physique.',
      );
    }
    if (registry.legacyClaims.any((claim) => claim.source == journal.source)) {
      return _issue(
        'sourceReferencedByLegacyClaim',
        'Un claim legacy référence cette source physique.',
      );
    }
    return null;
  }

  Future<NarrativeEventSpatialLinkInspectionIssue?> _journalPathIssue({
    required String projectPath,
    required String actualJournalPath,
    required NarrativeEventSpatialLinkJournal journal,
  }) async {
    final expected = _pathsFor(
      projectPath: projectPath,
      mapPath: journal.mapPath,
      operationId: journal.operationId,
    );
    if (journal.projectPath != projectPath ||
        p.normalize(actualJournalPath) != expected.journalPath ||
        journal.journalPath != expected.journalPath ||
        journal.mapTempPath != expected.mapTempPath ||
        !p.isWithin(p.dirname(projectPath), journal.mapPath)) {
      return _issue(
        'unsafeJournalPaths',
        'Les chemins du journal ne correspondent pas à son opération.',
        actualJournalPath,
      );
    }
    final projectBytes = await File(projectPath).readAsBytes();
    late final ProjectManifest project;
    try {
      project =
          decodeValidatedNarrativeEventAuthoringProject(projectBytes).manifest;
    } on Object catch (error) {
      return _issue(
        'invalidProject',
        'Le projet du journal est invalide: $error',
        projectPath,
      );
    }
    final resolved = await _resolveManifestMap(
      projectPath: projectPath,
      project: project,
      mapId: journal.mapId,
    );
    if (resolved.issue != null) return resolved.issue;
    if (resolved.path != journal.mapPath) {
      return _issue(
        'unsafeJournalPaths',
        'La map du journal ne correspond plus au manifest.',
        journal.mapPath,
      );
    }
    return null;
  }

  Future<NarrativeEventSpatialLinkInspectionIssue?> _writableArtifactPathIssue(
    _SpatialLinkPaths paths,
  ) async {
    for (final path in [
      paths.journalPath,
      paths.journalRewriteTempPath,
      paths.mapTempPath,
    ]) {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.link) {
        return _issue(
          'symbolicLinkRefused',
          'Un artefact de persistance ne peut pas être un lien symbolique.',
          path,
        );
      }
    }
    return null;
  }

  Future<_JournalArtifacts> _journalArtifacts(String projectPath) async {
    final directory = Directory(p.dirname(projectPath));
    final prefix = _projectArtifactPrefix(projectPath);
    final journals = <String>[];
    final rewriteTemps = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (!name.startsWith(prefix)) continue;
      if (name.endsWith(journalSuffix)) {
        journals.add(p.normalize(entity.path));
      } else if (name.endsWith('$journalSuffix.rewrite.tmp')) {
        rewriteTemps.add(p.normalize(entity.path));
      }
    }
    journals.sort();
    rewriteTemps.sort();
    return _JournalArtifacts(journals, rewriteTemps);
  }

  _SpatialLinkPaths _pathsFor({
    required String projectPath,
    required String mapPath,
    required String operationId,
  }) {
    final safe = _safeOperationId(operationId);
    if (safe == null) {
      throw ArgumentError.value(
          operationId, 'operationId', 'must be path-safe');
    }
    final stem = '${_projectArtifactPrefix(projectPath)}$safe';
    final journalPath = p.normalize(
      p.join(p.dirname(projectPath), '$stem$journalSuffix'),
    );
    return _SpatialLinkPaths(
      journalPath: journalPath,
      journalRewriteTempPath: '$journalPath.rewrite.tmp',
      mapTempPath: p.normalize(
        p.join(p.dirname(mapPath), '$stem$mapTempSuffix'),
      ),
    );
  }

  String _projectArtifactPrefix(String projectPath) {
    final key = narrativeEventCanonicalSha256({
      'projectPath': projectPath,
    }).substring(0, 16);
    return '$journalPrefix$key-';
  }

  Future<void> _writeJournal(
    NarrativeEventSpatialLinkJournal journal,
  ) async {
    final paths = _pathsFor(
      projectPath: journal.projectPath,
      mapPath: journal.mapPath,
      operationId: journal.operationId,
    );
    if (paths.journalPath != journal.journalPath ||
        paths.mapTempPath != journal.mapTempPath) {
      throw StateError('Unsafe spatial link journal paths.');
    }
    final pathIssue = await _symbolicLinkIssue([
      paths.journalPath,
      paths.journalRewriteTempPath,
    ]);
    if (pathIssue != null) {
      throw FileSystemException(pathIssue.message, pathIssue.path);
    }
    final bytes = _canonicalJsonUtf8(journal.toJson());
    await _writeBytesFlushed(paths.journalRewriteTempPath, bytes);
    final verify = await File(paths.journalRewriteTempPath).readAsBytes();
    if (narrativeEventBytesFingerprint(verify) !=
        narrativeEventBytesFingerprint(bytes)) {
      throw const FileSystemException('Journal temp hash mismatch.');
    }
    await File(paths.journalRewriteTempPath).rename(paths.journalPath);
  }

  Future<void> _writeBytesFlushed(String path, List<int> bytes) async {
    final file = File(path);
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw FileSystemException(
        'A symbolic link cannot be used as a persistence temporary.',
        path,
      );
    }
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  Future<void> _deleteCompletedArtifacts(
    NarrativeEventSpatialLinkJournal journal,
  ) async {
    final expected = _pathsFor(
      projectPath: journal.projectPath,
      mapPath: journal.mapPath,
      operationId: journal.operationId,
    );
    if (expected.journalPath != journal.journalPath ||
        expected.mapTempPath != journal.mapTempPath) {
      return;
    }
    for (final path in [
      expected.mapTempPath,
      expected.journalRewriteTempPath,
      expected.journalPath,
    ]) {
      await _deleteIfRegular(path);
    }
  }

  Future<void> _deleteIfRegular(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.file) await File(path).delete();
  }

  Future<void> _checkpoint(
    NarrativeEventSpatialLinkCheckpoint checkpoint,
  ) async {
    await faultInjector?.call(checkpoint);
  }

  Future<NarrativeEventSpatialLinkInspectionIssue?> _symbolicLinkIssue(
    Iterable<String> paths,
  ) async {
    for (final path in paths) {
      if (await FileSystemEntity.type(path, followLinks: false) ==
          FileSystemEntityType.link) {
        return _issue(
          'symbolicLinkRefused',
          'Un chemin de persistance est devenu un lien symbolique.',
          path,
        );
      }
    }
    return null;
  }

  NarrativeEventSpatialLinkOperationResult _blocked(
    String code,
    String message, {
    NarrativeEventSpatialLinkJournal? journal,
    NarrativeEventSpatialLinkInspection? inspection,
  }) {
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.blocked,
      code: code,
      message: message,
      journal: journal,
      inspection: inspection,
    );
  }

  NarrativeEventSpatialLinkOperationResult _blockedIssue(
    NarrativeEventSpatialLinkInspectionIssue issue, {
    NarrativeEventSpatialLinkJournal? journal,
  }) {
    return _blocked(issue.code, issue.message, journal: journal);
  }

  NarrativeEventSpatialLinkOperationResult _conflict(
    String code,
    String message, {
    NarrativeEventSpatialLinkJournal? journal,
    NarrativeEventSpatialLinkInspection? inspection,
  }) {
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.conflict,
      code: code,
      message: message,
      journal: journal,
      inspection: inspection,
    );
  }

  NarrativeEventSpatialLinkOperationResult _recovered(
    String code,
    String message,
    NarrativeEventSpatialLinkJournal journal,
    NarrativeEventSpatialLinkInspection inspection,
  ) {
    return NarrativeEventSpatialLinkOperationResult(
      status: NarrativeEventSpatialLinkOperationStatus.recovered,
      code: code,
      message: message,
      journal: journal,
      inspection: inspection,
    );
  }

  NarrativeEventSpatialLinkOperationResult _registryRecoveryBlocked(
    NarrativeEventRegistryRecoveryInspection inspection,
  ) {
    final issue = inspection.issues.firstOrNull;
    return _blocked(
      inspection.status ==
              NarrativeEventRegistryRecoveryGateStatus.recoveryRequired
          ? 'eventRegistryRecoveryRequired'
          : 'eventRegistryRecoveryBlocked',
      issue?.message ??
          'Le registry Event doit être récupéré avant cette liaison.',
    );
  }

  NarrativeEventSpatialLinkInspection _inspectionBlocked(
    String code,
    String message,
    String path, {
    NarrativeEventSpatialLinkJournal? journal,
  }) {
    return NarrativeEventSpatialLinkInspection(
      status: NarrativeEventSpatialLinkInspectionStatus.blocked,
      journal: journal,
      issues: [_issue(code, message, path)],
    );
  }

  NarrativeEventSpatialLinkInspectionIssue _issue(
    String code,
    String message, [
    String? path,
  ]) {
    return NarrativeEventSpatialLinkInspectionIssue(
      code: code,
      message: message,
      path: path,
    );
  }

  String? _safeOperationId(String value) {
    if (value.length > 96 ||
        !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(value)) {
      return null;
    }
    return value;
  }
}

bool _sameJson(Object? left, Object? right) {
  return canonicalizeNarrativeEventJson(_normalizeJsonValue(left)) ==
      canonicalizeNarrativeEventJson(_normalizeJsonValue(right));
}

List<int> _canonicalJsonUtf8(Object? value) {
  return canonicalizeNarrativeEventJsonUtf8(_normalizeJsonValue(value));
}

Object? _normalizeJsonValue(Object? value) {
  return decodeNarrativeEventJsonStrict(jsonEncode(value));
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('JSON keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

enum _OwnerStateKind { absent, exact, modified }

final class _OwnerState {
  const _OwnerState(this.kind, {this.fingerprint});

  final _OwnerStateKind kind;
  final String? fingerprint;
}

final class _PathResolution {
  const _PathResolution._({this.path, this.issue});

  factory _PathResolution.path(String path) => _PathResolution._(path: path);

  factory _PathResolution.issue(
    NarrativeEventSpatialLinkInspectionIssue issue,
  ) =>
      _PathResolution._(issue: issue);

  final String? path;
  final NarrativeEventSpatialLinkInspectionIssue? issue;
}

final class _SpatialLinkPaths {
  const _SpatialLinkPaths({
    required this.journalPath,
    required this.journalRewriteTempPath,
    required this.mapTempPath,
  });

  final String journalPath;
  final String journalRewriteTempPath;
  final String mapTempPath;
}

final class _JournalArtifacts {
  const _JournalArtifacts(this.journals, this.rewriteTemps);

  final List<String> journals;
  final List<String> rewriteTemps;
}
