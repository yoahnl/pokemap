import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import 'project_manifest_write_lock.dart';

final class NarrativeEventRegistryPersistence {
  NarrativeEventRegistryPersistence({
    DateTime Function()? clock,
    this.faultInjector,
  }) : _clock = clock ?? DateTime.now;

  static const journalPrefix = '.pokemap-event-registry-';
  static const journalSuffix = '.journal.json';
  static const backupSuffix = '.before.json';
  static const tempSuffix = '.after.tmp';
  static const undoSuffix = '.undo.json';

  final DateTime Function() _clock;
  final NarrativeEventRegistryFaultInjector? faultInjector;

  Future<NarrativeEventRegistryPersistenceResult> write(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    try {
      return await withProjectManifestWriteLock(
        request.projectPath,
        () async {
          final recoveryInspection =
              await inspectProjectAlreadyLocked(request.projectPath);
          if (recoveryInspection.status !=
              NarrativeEventRegistryRecoveryGateStatus.clear) {
            return _recoveryGateResult(recoveryInspection);
          }
          late final NarrativeEventAuthoringSession freshSession;
          try {
            freshSession = await NarrativeEventAuthoringSession.prepare(
              request.projectPath,
            );
          } on NarrativeEventAuthoringSessionException catch (error) {
            return NarrativeEventRegistryPersistenceResult(
              status: NarrativeEventRegistryPersistenceStatus
                  .staleAuthoringSnapshot,
              code: 'staleAuthoringSnapshot',
              message: error.message,
              beforeRevision: request.expectedProjectRevision,
            );
          }
          if (!request.session.hasSameAttestation(freshSession)) {
            final mapChanged = !_stringMapEquals(
                  request.session.mapManifestPaths,
                  freshSession.mapManifestPaths,
                ) ||
                !_stringMapEquals(
                  request.session.mapPaths,
                  freshSession.mapPaths,
                ) ||
                !_stringMapEquals(
                  request.session.mapByteHashes,
                  freshSession.mapByteHashes,
                );
            return NarrativeEventRegistryPersistenceResult(
              status: NarrativeEventRegistryPersistenceStatus
                  .staleAuthoringSnapshot,
              code: mapChanged ? 'staleMapRevision' : 'staleAuthoringSnapshot',
              message: mapChanged
                  ? 'Une map a changé depuis la préparation de l’authoring.'
                  : 'Le projet a changé depuis la préparation de l’authoring.',
              beforeRevision: request.expectedProjectRevision,
              afterRevision: freshSession.projectRevision,
            );
          }
          final verification = verifyNarrativeEventAuthoringResult(
            context: freshSession.context,
            result: request.authoringResult,
          );
          if (verification != null) {
            return NarrativeEventRegistryPersistenceResult(
              status: NarrativeEventRegistryPersistenceStatus.rejected,
              code: verification.code,
              message: verification.message,
            );
          }
          return _writeTransition(
            projectPath: request.projectPath,
            operationId: request.operationId,
            expectedProjectRevision: request.expectedProjectRevision,
            previousRegistry: request.previousRegistry,
            nextRegistry: request.nextRegistry,
            mutation: request.mutation,
            eventIds: request.eventIds,
            attestedMapManifestPaths: freshSession.mapManifestPaths,
            attestedMapPaths: freshSession.mapPaths,
            attestedMapByteHashes: freshSession.mapByteHashes,
          );
        },
      );
    } on FileSystemException catch (error) {
      return _ioFailure(error);
    }
  }

  Future<List<NarrativeEventRegistryPersistenceResult>> recoverProject(
    String projectPath,
  ) async {
    try {
      final qualifiedProjectPath = await _canonicalProjectPath(projectPath);
      return await withProjectManifestWriteLock(
        qualifiedProjectPath,
        () async {
          final inspection =
              await inspectProjectAlreadyLocked(qualifiedProjectPath);
          if (inspection.status ==
              NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked) {
            return [_recoveryGateResult(inspection)];
          }
          return _recoverProjectLocked(qualifiedProjectPath);
        },
      );
    } on FileSystemException catch (error) {
      return [_ioFailure(error)];
    }
  }

  Future<NarrativeEventRegistryRecoveryInspection> inspectProject(
    String projectPath,
  ) {
    return withProjectManifestWriteLock(
      projectPath,
      () => inspectProjectAlreadyLocked(projectPath),
    );
  }

  Future<NarrativeEventRegistryRecoveryInspection> inspectProjectAlreadyLocked(
      String projectPath) async {
    final qualifiedProjectPath = await _canonicalProjectPath(projectPath);
    final directory = Directory(p.dirname(qualifiedProjectPath));
    if (!await directory.exists()) {
      return NarrativeEventRegistryRecoveryInspection(
        status: NarrativeEventRegistryRecoveryGateStatus.clear,
        issues: const [],
      );
    }
    final artifactPrefix = _projectArtifactPrefix(qualifiedProjectPath);
    final journalPaths = <String>[];
    final backupPaths = <String>[];
    final tempPaths = <String>[];
    final undoPaths = <String>[];
    final rewritePaths = <String>[];
    final linkPaths = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      final path = _qualified(entity.path);
      final name = p.basename(path);
      if (!name.startsWith(artifactPrefix)) continue;
      if (entity is Link) {
        linkPaths.add(path);
        continue;
      }
      if (entity is! File) continue;
      if (name.endsWith('$journalSuffix.rewrite.tmp') ||
          name.endsWith('$undoSuffix.rewrite.tmp')) {
        rewritePaths.add(path);
      } else if (name.endsWith(journalSuffix)) {
        journalPaths.add(path);
      } else if (name.endsWith(backupSuffix)) {
        backupPaths.add(path);
      } else if (name.endsWith(tempSuffix)) {
        tempPaths.add(path);
      } else if (name.endsWith(undoSuffix)) {
        undoPaths.add(path);
      }
    }
    for (final paths in [
      journalPaths,
      backupPaths,
      tempPaths,
      undoPaths,
      rewritePaths,
      linkPaths,
    ]) {
      paths.sort(compareNarrativeEventUtf16);
    }
    final blocked = <NarrativeEventRegistryRecoveryIssue>[];
    final required = <NarrativeEventRegistryRecoveryIssue>[];
    final journals = <String, NarrativeEventRegistryWriteJournal>{};
    final safeJournalPaths = <String>{};
    for (final path in journalPaths) {
      try {
        final journal = await _readJournal(path);
        journals[path] = journal;
        final pathIssue = _journalPathIssue(journal, path);
        if (pathIssue != null) {
          blocked.add(NarrativeEventRegistryRecoveryIssue(
            code: pathIssue.code,
            message: pathIssue.message,
            path: path,
          ));
        } else {
          safeJournalPaths.add(path);
        }
      } on Object {
        blocked.add(NarrativeEventRegistryRecoveryIssue(
          code: 'invalidJournal',
          message: 'Un journal Event est illisible et exige une intervention.',
          path: path,
        ));
      }
    }
    final prepared = journals.entries
        .where((entry) =>
            entry.value.state == NarrativeEventRegistryJournalState.prepared)
        .toList();
    if (prepared.length > 1) {
      blocked.add(NarrativeEventRegistryRecoveryIssue(
        code: 'multiplePreparedJournals',
        message: 'Plusieurs écritures Event préparées sont en attente.',
      ));
    }
    for (final entry in prepared) {
      if (!safeJournalPaths.contains(entry.key)) continue;
      final prerequisiteIssues = await _inspectPreparedRecoveryPrerequisites(
        entry.value,
        qualifiedProjectPath,
        entry.key,
      );
      if (prerequisiteIssues.isNotEmpty) {
        blocked.addAll(prerequisiteIssues);
      } else if (prepared.length == 1) {
        required.add(NarrativeEventRegistryRecoveryIssue(
          code: 'preparedJournal',
          message: _recoveryRequiredMessage,
          path: entry.key,
        ));
      }
    }
    final knownBackups = <String>{};
    final knownTemps = <String>{};
    final knownUndos = <String>{};
    final knownRewrites = <String>{};
    for (final entry in journals.entries) {
      final path = entry.key;
      final journal = entry.value;
      final expected = _pathsFor(journal.projectPath, journal.operationId);
      knownBackups.add(expected.backupPath);
      knownTemps.add(expected.tempPath);
      knownUndos.add(expected.undoPath);
      knownRewrites.add('${expected.journalPath}.rewrite.tmp');
      knownRewrites.add('${expected.undoPath}.rewrite.tmp');
      final hasPendingFiles = await File(expected.backupPath).exists() ||
          await File(expected.tempPath).exists() ||
          await File('${expected.journalPath}.rewrite.tmp').exists() ||
          await File('${expected.undoPath}.rewrite.tmp').exists();
      final undoFile = File(expected.undoPath);
      if (journal.state != NarrativeEventRegistryJournalState.committed &&
          await undoFile.exists()) {
        blocked.add(NarrativeEventRegistryRecoveryIssue(
          code: journal.state == NarrativeEventRegistryJournalState.recovered
              ? 'unexpectedRecoveredUndo'
              : 'unexpectedPreparedUndo',
          message:
              'Un undo existe pour une écriture Event qui n’a pas été committée.',
          path: expected.undoPath,
        ));
      }
      if (journal.state == NarrativeEventRegistryJournalState.committed) {
        if (await undoFile.exists()) {
          try {
            final undo = await _readUndo(expected.undoPath);
            if (!_undoMatchesJournal(undo, journal)) {
              blocked.add(NarrativeEventRegistryRecoveryIssue(
                code: 'inconsistentUndo',
                message: 'L’undo ne correspond pas au journal committé.',
                path: expected.undoPath,
              ));
            }
          } on Object {
            blocked.add(NarrativeEventRegistryRecoveryIssue(
              code: 'invalidUndo',
              message: 'L’undo du journal committé est illisible.',
              path: expected.undoPath,
            ));
          }
        } else {
          final projectFile = File(qualifiedProjectPath);
          final projectHash = await projectFile.exists()
              ? narrativeEventBytesFingerprint(await projectFile.readAsBytes())
              : null;
          if (projectHash == journal.expectedAfterHash) {
            required.add(NarrativeEventRegistryRecoveryIssue(
              code: 'committedUndoRecoveryRequired',
              message: _recoveryRequiredMessage,
              path: path,
            ));
          } else {
            blocked.add(NarrativeEventRegistryRecoveryIssue(
              code: 'committedProjectMismatch',
              message: 'Le journal committé ne correspond pas au projet.',
              path: path,
            ));
          }
        }
      }
      if (journal.state != NarrativeEventRegistryJournalState.prepared &&
          hasPendingFiles) {
        required.add(NarrativeEventRegistryRecoveryIssue(
          code: 'journalCleanupRequired',
          message: _recoveryRequiredMessage,
          path: path,
        ));
      }
    }
    for (final path in backupPaths) {
      if (!knownBackups.contains(path)) {
        blocked.add(NarrativeEventRegistryRecoveryIssue(
          code: 'orphanBackup',
          message: 'Un backup Event orphelin exige une intervention.',
          path: path,
        ));
      }
    }
    for (final path in tempPaths) {
      if (!knownTemps.contains(path)) {
        blocked.add(NarrativeEventRegistryRecoveryIssue(
          code: 'orphanTemp',
          message:
              'Un fichier temporaire Event orphelin exige une intervention.',
          path: path,
        ));
      }
    }
    for (final path in undoPaths) {
      if (!knownUndos.contains(path)) {
        blocked.add(NarrativeEventRegistryRecoveryIssue(
          code: 'orphanUndo',
          message: 'Un undo Event orphelin exige une intervention.',
          path: path,
        ));
      }
    }
    for (final path in rewritePaths) {
      if (!knownRewrites.contains(path)) {
        blocked.add(NarrativeEventRegistryRecoveryIssue(
          code: 'orphanJournalRewrite',
          message: 'Un rewrite Event orphelin exige une intervention.',
          path: path,
        ));
      }
    }
    for (final path in linkPaths) {
      blocked.add(NarrativeEventRegistryRecoveryIssue(
        code: 'unsafeArtifactLink',
        message: 'Un artefact Event est un lien symbolique non sûr.',
        path: path,
      ));
    }
    final issues = blocked.isNotEmpty ? blocked : required;
    return NarrativeEventRegistryRecoveryInspection(
      status: blocked.isNotEmpty
          ? NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked
          : required.isNotEmpty
              ? NarrativeEventRegistryRecoveryGateStatus.recoveryRequired
              : NarrativeEventRegistryRecoveryGateStatus.clear,
      issues: issues,
    );
  }

  Future<List<NarrativeEventRegistryPersistenceResult>> _recoverProjectLocked(
    String projectPath,
  ) async {
    final qualifiedProjectPath = await _canonicalProjectPath(projectPath);
    final directory = Directory(p.dirname(qualifiedProjectPath));
    if (!await directory.exists()) return const [];
    final artifactPrefix = _projectArtifactPrefix(qualifiedProjectPath);
    final journalPaths = <String>[];
    final backupPaths = <String>[];
    final rewritePaths = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith(artifactPrefix) && name.endsWith(journalSuffix)) {
        journalPaths.add(_qualified(entity.path));
      } else if (name.startsWith(artifactPrefix) &&
          name.endsWith(backupSuffix)) {
        backupPaths.add(_qualified(entity.path));
      } else if (name.startsWith(artifactPrefix) &&
          (name.endsWith('$journalSuffix.rewrite.tmp') ||
              name.endsWith('$undoSuffix.rewrite.tmp'))) {
        rewritePaths.add(_qualified(entity.path));
      }
    }
    journalPaths.sort(compareNarrativeEventUtf16);
    backupPaths.sort(compareNarrativeEventUtf16);
    rewritePaths.sort(compareNarrativeEventUtf16);
    final results = <NarrativeEventRegistryPersistenceResult>[];
    final journals = <String, NarrativeEventRegistryWriteJournal>{};
    for (final path in journalPaths) {
      try {
        journals[path] = await _readJournal(path);
      } on Object {
        results.add(await _recoverJournalLocked(path));
      }
    }
    final preparedCount = journals.values
        .where(
          (journal) =>
              journal.state == NarrativeEventRegistryJournalState.prepared,
        )
        .length;
    if (preparedCount > 1) {
      results.add(_blocked(
        'multiplePreparedJournals',
        'Plusieurs écritures préparées exigent une intervention manuelle.',
      ));
      return List.unmodifiable(results);
    }
    for (final path in journals.keys) {
      results.add(await _recoverJournalLocked(path));
    }
    final knownBackups = {
      for (final journal in journals.values) journal.backupPath,
      for (final journalPath in journalPaths)
        journalPath.substring(0, journalPath.length - journalSuffix.length) +
            backupSuffix,
    };
    for (final backupPath in backupPaths) {
      if (knownBackups.contains(backupPath)) continue;
      results.add(await _recoverOrphanBackup(
        qualifiedProjectPath,
        backupPath,
      ));
    }
    final knownRewrites = {
      for (final journal in journals.values)
        '${_pathsFor(journal.projectPath, journal.operationId).journalPath}.rewrite.tmp',
      for (final journal in journals.values)
        '${_pathsFor(journal.projectPath, journal.operationId).undoPath}.rewrite.tmp',
    };
    for (final rewritePath in rewritePaths) {
      final rewriteFile = File(rewritePath);
      if (!await rewriteFile.exists()) continue;
      if (knownRewrites.contains(rewritePath)) {
        await rewriteFile.delete();
      } else {
        results.add(_blocked(
          'orphanJournalRewrite',
          'Un journal partiellement publié exige une intervention manuelle.',
        ));
      }
    }
    return List.unmodifiable(results);
  }

  Future<NarrativeEventRegistryPersistenceResult> recoverJournal(
    String journalPath,
  ) async {
    try {
      final journal = await _readJournal(journalPath);
      return await withProjectManifestWriteLock(
        journal.projectPath,
        () async {
          final inspection =
              await inspectProjectAlreadyLocked(journal.projectPath);
          if (inspection.status ==
              NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked) {
            return _recoveryGateResult(inspection);
          }
          return _recoverJournalLocked(journalPath);
        },
      );
    } on FileSystemException catch (error) {
      return _ioFailure(error);
    } on FormatException catch (error) {
      return _blocked('invalidJournal', 'Le journal est invalide: $error');
    } on ArgumentError catch (error) {
      return _blocked('invalidJournal', 'Le journal est invalide: $error');
    }
  }

  Future<NarrativeEventRegistryPersistenceResult> _recoverJournalLocked(
    String journalPath,
  ) async {
    try {
      final journal = await _readJournal(journalPath);
      final pathIssue = _journalPathIssue(journal, journalPath);
      if (pathIssue != null) return pathIssue;
      final projectFile = File(journal.projectPath);
      if (!await projectFile.exists()) {
        return _blocked('projectMissing', 'Le projet du journal est absent.');
      }
      final undoFile = File(_pathsFor(
        journal.projectPath,
        journal.operationId,
      ).undoPath);
      if (journal.state == NarrativeEventRegistryJournalState.recovered) {
        await _safeCleanup(journal);
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.noOp,
          code: 'alreadyRecovered',
          message: 'Le journal a déjà été récupéré.',
          journal: journal,
        );
      }
      if (journal.state == NarrativeEventRegistryJournalState.committed &&
          await undoFile.exists()) {
        late final NarrativeEventRegistryUndoEntry undoEntry;
        try {
          undoEntry = await _readUndo(undoFile.path);
        } on FormatException catch (error) {
          return _blocked('invalidUndo', 'L’undo est invalide: $error');
        } on ArgumentError catch (error) {
          return _blocked('invalidUndo', 'L’undo est invalide: $error');
        }
        if (!_undoMatchesJournal(undoEntry, journal)) {
          return _blocked(
            'inconsistentUndo',
            'L’undo ne correspond pas au journal committé.',
          );
        }
        await _safeCleanup(journal);
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.noOp,
          code: 'alreadyCommitted',
          message: 'Le journal est déjà finalisé.',
          beforeRevision: journal.beforeHash,
          afterRevision: journal.expectedAfterHash,
          journal: journal,
          undoEntry: undoEntry,
        );
      }

      final projectBytes = await projectFile.readAsBytes();
      final projectHash = narrativeEventBytesFingerprint(projectBytes);
      if (journal.state == NarrativeEventRegistryJournalState.committed) {
        if (projectHash != journal.expectedAfterHash) {
          return _blocked(
            'committedProjectMismatch',
            'Le projet ne correspond plus au commit sans undo.',
          );
        }
        final undoEntry = _undoFromJournal(journal, _clock().toUtc());
        await _writeUndo(undoFile.path, undoEntry);
        await _safeCleanup(journal);
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.recovered,
          code: 'committedUndoRecovered',
          message: 'L’undo manquant a été restauré.',
          beforeRevision: journal.beforeHash,
          afterRevision: journal.expectedAfterHash,
          journal: journal,
          undoEntry: undoEntry,
        );
      }

      final backupIssue = await _validateBackup(journal);
      if (backupIssue != null) return backupIssue;
      if (projectHash == journal.beforeHash) {
        final recovered = journal.withState(
          NarrativeEventRegistryJournalState.recovered,
          _clock().toUtc(),
        );
        await _writeJournal(recovered);
        await _safeCleanup(recovered);
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.recovered,
          code: 'rolledBackBeforeCommit',
          message:
              'Aucun commit n’était visible; les fichiers temporaires ont été retirés.',
          beforeRevision: journal.beforeHash,
          afterRevision: journal.beforeHash,
          journal: recovered,
        );
      }
      if (projectHash == journal.expectedAfterHash) {
        final tempIssue = await _validateTempWhenPresent(journal);
        if (tempIssue != null) return tempIssue;
        final committed = journal.withState(
          NarrativeEventRegistryJournalState.committed,
          _clock().toUtc(),
        );
        await _writeJournal(committed);
        final undoEntry = _undoFromJournal(committed, _clock().toUtc());
        await _writeUndo(undoFile.path, undoEntry);
        await _safeCleanup(committed);
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.recovered,
          code: 'commitFinalized',
          message:
              'Le rename était visible; le commit et son undo ont été finalisés.',
          beforeRevision: committed.beforeHash,
          afterRevision: committed.expectedAfterHash,
          journal: committed,
          undoEntry: undoEntry,
        );
      }
      return _blocked(
        'unknownProjectRevision',
        'Le projet ne correspond ni à la version avant ni à la version après.',
      );
    } on FileSystemException catch (error) {
      return _ioFailure(error);
    } on FormatException catch (error) {
      return _blocked('invalidJournal', 'Le journal est invalide: $error');
    } on ArgumentError catch (error) {
      return _blocked('invalidJournal', 'Le journal est invalide: $error');
    }
  }

  Future<NarrativeEventRegistryPersistenceResult> undo(
    String undoPath,
  ) async {
    try {
      final entry = await _readUndo(undoPath);
      return await withProjectManifestWriteLock(
        entry.projectPath,
        () async {
          final inspection =
              await inspectProjectAlreadyLocked(entry.projectPath);
          if (inspection.status !=
              NarrativeEventRegistryRecoveryGateStatus.clear) {
            return _recoveryGateResult(inspection);
          }
          return _undoEntry(undoPath, entry);
        },
      );
    } on FileSystemException catch (error) {
      return _ioFailure(error);
    } on FormatException catch (error) {
      return _blocked('invalidUndo', 'L’undo est invalide: $error');
    } on ArgumentError catch (error) {
      return _blocked('invalidUndo', 'L’undo est invalide: $error');
    }
  }

  Future<NarrativeEventRegistryPersistenceResult> _undoEntry(
    String undoPath,
    NarrativeEventRegistryUndoEntry entry,
  ) async {
    final qualifiedProjectPath = _qualified(entry.projectPath);
    final expectedUndoPath = narrativeEventRegistryUndoPath(
      entry.projectPath,
      entry.operationId,
    );
    if (qualifiedProjectPath != entry.projectPath ||
        _qualified(undoPath) != expectedUndoPath) {
      return _blocked(
        'unsafeUndoPath',
        'Le chemin projet ou le chemin fichier de l’undo est invalide.',
      );
    }
    final currentBytes = await File(entry.projectPath).readAsBytes();
    final currentHash = narrativeEventBytesFingerprint(currentBytes);
    if (currentHash != entry.afterRevision) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.staleUndo,
        code: 'staleUndo',
        message: 'Le projet a changé depuis cette opération.',
        beforeRevision: entry.afterRevision,
        afterRevision: currentHash,
        undoEntry: entry,
      );
    }
    final operationHash = narrativeEventCanonicalSha256({
      'operationId': entry.operationId,
      'afterRevision': entry.afterRevision,
    }).substring(0, 20);
    final result = await _writeTransition(
      projectPath: entry.projectPath,
      operationId: 'undo_$operationHash',
      expectedProjectRevision: entry.afterRevision,
      previousRegistry: entry.nextRegistry,
      nextRegistry: entry.previousRegistry,
      mutation: 'undo:${entry.operationId}',
      eventIds: entry.eventIds,
    );
    if (result.status ==
        NarrativeEventRegistryPersistenceStatus.staleRevision) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.staleUndo,
        code: 'staleUndo',
        message: 'Le projet a changé pendant l’undo.',
        beforeRevision: entry.afterRevision,
        afterRevision: result.afterRevision,
        undoEntry: entry,
      );
    }
    return result;
  }

  Future<NarrativeEventRegistryPersistenceResult> _writeTransition({
    required String projectPath,
    required String operationId,
    required String expectedProjectRevision,
    required NarrativeEventRegistry? previousRegistry,
    required NarrativeEventRegistry? nextRegistry,
    required String mutation,
    required List<String> eventIds,
    Map<String, String> attestedMapManifestPaths = const {},
    Map<String, String> attestedMapPaths = const {},
    Map<String, String> attestedMapByteHashes = const {},
  }) async {
    final qualifiedProjectPath = _qualified(projectPath);
    final paths = _pathsFor(qualifiedProjectPath, operationId);
    final beforeBytes = await File(qualifiedProjectPath).readAsBytes();
    final beforeHash = narrativeEventBytesFingerprint(beforeBytes);
    if (beforeHash != expectedProjectRevision) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.staleRevision,
        code: 'staleRevision',
        message: 'Le projet a changé avant l’écriture.',
        beforeRevision: expectedProjectRevision,
        afterRevision: beforeHash,
      );
    }
    final initialMapIssue = await _attestedMapRevisionIssue(
      manifestPaths: attestedMapManifestPaths,
      canonicalPaths: attestedMapPaths,
      expectedHashes: attestedMapByteHashes,
    );
    if (initialMapIssue != null) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
        code: initialMapIssue.code,
        message: initialMapIssue.message,
        beforeRevision: expectedProjectRevision,
        afterRevision: beforeHash,
      );
    }
    final reusableRecoveredJournal = await _matchingRecoveredJournal(
      paths: paths,
      expectedProjectRevision: expectedProjectRevision,
      previousRegistry: previousRegistry,
      nextRegistry: nextRegistry,
      mutation: mutation,
      eventIds: eventIds,
    );
    if (reusableRecoveredJournal != null) {
      await File(paths.journalPath).delete();
    } else {
      final existingArtifact = await _firstExistingArtifact(paths);
      if (existingArtifact != null) {
        return _blocked(
          'operationAlreadyExists',
          'Un artefact existe déjà pour cette opération: $existingArtifact.',
        );
      }
    }
    final preflight = _preflight(beforeBytes);
    if (preflight.rejection case final rejection?) return rejection;
    final snapshot = preflight.snapshot!;
    if (!_registryEquals(snapshot.registry, previousRegistry)) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.staleRevision,
        code: 'registryMismatch',
        message: 'Le registry courant ne correspond pas à la version attendue.',
        beforeRevision: expectedProjectRevision,
        afterRevision: beforeHash,
      );
    }
    final ownershipIssue = _ownershipIssue(snapshot.registry, nextRegistry);
    if (ownershipIssue != null) return ownershipIssue;
    try {
      if (nextRegistry != null) narrativeEventRegistryFingerprint(nextRegistry);
    } on FormatException {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.invalidRegistry,
        code: 'invalidNextRegistry',
        message: 'Le registry suivant ne peut pas être encodé exactement.',
      );
    }
    if (_registryEquals(snapshot.registry, nextRegistry)) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.noOp,
        code: 'noChange',
        message: 'Le registry demandé est déjà enregistré.',
        beforeRevision: beforeHash,
        afterRevision: beforeHash,
      );
    }
    final root = Map<String, Object?>.from(snapshot.root);
    if (nextRegistry == null) {
      root.remove('eventRegistry');
    } else {
      root['eventRegistry'] = nextRegistry.toJson();
    }
    late final List<int> afterBytes;
    try {
      afterBytes = canonicalizeNarrativeEventJsonUtf8(root);
    } on FormatException catch (error) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.invalidRegistry,
        code: 'projectNotCanonical',
        message:
            'Le projet suivant n’est pas un document I-JSON valide: $error',
      );
    }
    final afterHash = narrativeEventBytesFingerprint(afterBytes);
    if (afterHash == beforeHash) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.noOp,
        code: 'noChange',
        message: 'Le registry demandé est déjà enregistré.',
        beforeRevision: beforeHash,
        afterRevision: afterHash,
      );
    }
    final afterPreflight = _preflight(afterBytes);
    if (afterPreflight.rejection case final rejection?) return rejection;
    if (!_registryEquals(afterPreflight.snapshot!.registry, nextRegistry)) {
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.invalidRegistry,
        code: 'projectedRegistryMismatch',
        message: 'Le registry projeté ne peut pas être relu à l’identique.',
      );
    }

    final preparedAt = _clock().toUtc();
    var journal = NarrativeEventRegistryWriteJournal(
      schemaVersion: 1,
      operationId: operationId,
      projectPath: qualifiedProjectPath,
      journalPath: paths.journalPath,
      beforeHash: beforeHash,
      expectedAfterHash: afterHash,
      tempPath: paths.tempPath,
      backupPath: paths.backupPath,
      state: NarrativeEventRegistryJournalState.prepared,
      preparedAt: preparedAt,
      eventIds: eventIds,
      mutation: mutation,
      previousRegistryHash: _registryHash(previousRegistry),
      nextRegistryHash: _registryHash(nextRegistry),
      previousRegistry: previousRegistry,
      nextRegistry: nextRegistry,
    );
    var renameVisible = false;
    try {
      await _checkpoint(NarrativeEventRegistryWriteCheckpoint.beforeBackup);
      await _writeBytesFlushed(paths.backupPath, beforeBytes);
      final backupBytes = await File(paths.backupPath).readAsBytes();
      if (narrativeEventBytesFingerprint(backupBytes) != beforeHash) {
        return _blocked('backupHashMismatch',
            'Le backup ne correspond pas au projet courant.');
      }
      await _checkpoint(NarrativeEventRegistryWriteCheckpoint.afterBackup);
      await _writeJournal(journal);
      await _checkpoint(
        NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared,
      );
      final tempFile = File(paths.tempPath);
      final tempHandle = await tempFile.open(mode: FileMode.write);
      try {
        await tempHandle.writeFrom(afterBytes);
        await _checkpoint(
          NarrativeEventRegistryWriteCheckpoint.afterTempWrite,
        );
        await tempHandle.flush();
        await _checkpoint(
          NarrativeEventRegistryWriteCheckpoint.afterTempFlush,
        );
      } finally {
        await tempHandle.close();
      }
      final tempBytes = await tempFile.readAsBytes();
      if (narrativeEventBytesFingerprint(tempBytes) != afterHash) {
        return _blocked(
            'tempHashMismatch', 'Le fichier temporaire est invalide.');
      }
      await _checkpoint(NarrativeEventRegistryWriteCheckpoint.beforeRename);
      final liveHash = narrativeEventBytesFingerprint(
        await File(qualifiedProjectPath).readAsBytes(),
      );
      final finalMapIssue = liveHash == beforeHash
          ? await _attestedMapRevisionIssue(
              manifestPaths: attestedMapManifestPaths,
              canonicalPaths: attestedMapPaths,
              expectedHashes: attestedMapByteHashes,
            )
          : null;
      if (liveHash != beforeHash || finalMapIssue != null) {
        journal = journal.withState(
          NarrativeEventRegistryJournalState.recovered,
          _clock().toUtc(),
        );
        await _writeJournal(journal);
        await _safeCleanup(journal);
        return NarrativeEventRegistryPersistenceResult(
          status: finalMapIssue == null
              ? NarrativeEventRegistryPersistenceStatus.staleRevision
              : NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
          code: finalMapIssue?.code ?? 'staleRevisionBeforeRename',
          message: finalMapIssue?.message ??
              'Le projet a changé pendant la préparation.',
          beforeRevision: beforeHash,
          afterRevision: liveHash,
          journal: journal,
        );
      }
      await tempFile.rename(qualifiedProjectPath);
      renameVisible = true;
      await _checkpoint(NarrativeEventRegistryWriteCheckpoint.afterRename);
      final committedBytes = await File(qualifiedProjectPath).readAsBytes();
      final committedHash = narrativeEventBytesFingerprint(committedBytes);
      if (committedHash != afterHash) {
        return _blocked('projectHashMismatch',
            'Le projet écrit ne correspond pas au hash attendu.');
      }
      await _checkpoint(
        NarrativeEventRegistryWriteCheckpoint.afterHashVerify,
      );
      await _checkpoint(
        NarrativeEventRegistryWriteCheckpoint.beforeCommitted,
      );
      journal = journal.withState(
        NarrativeEventRegistryJournalState.committed,
        _clock().toUtc(),
      );
      await _writeJournal(journal);
      await _checkpoint(
        NarrativeEventRegistryWriteCheckpoint.afterCommittedBeforeCleanup,
      );
      final undoEntry = _undoFromJournal(journal, _clock().toUtc());
      await _writeUndo(paths.undoPath, undoEntry);
      await _safeCleanup(journal);
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.committed,
        code: 'committed',
        message: 'Le registry Event a été enregistré.',
        beforeRevision: beforeHash,
        afterRevision: afterHash,
        journal: journal,
        undoEntry: undoEntry,
      );
    } on FileSystemException catch (error) {
      if (!renameVisible) rethrow;
      return NarrativeEventRegistryPersistenceResult(
        status: NarrativeEventRegistryPersistenceStatus.recoveryRequired,
        code: 'recoveryRequired',
        message:
            'Le manifest peut être committé mais la finalisation a échoué: ${error.message}',
        beforeRevision: beforeHash,
        afterRevision: afterHash,
      );
    }
  }

  Future<_AttestedMapRevisionIssue?> _attestedMapRevisionIssue({
    required Map<String, String> manifestPaths,
    required Map<String, String> canonicalPaths,
    required Map<String, String> expectedHashes,
  }) async {
    if (!_sameStringKeys(manifestPaths, canonicalPaths) ||
        !_sameStringKeys(canonicalPaths, expectedHashes)) {
      return const _AttestedMapRevisionIssue(
        code: 'staleMapInventory',
        message: 'L’inventaire des maps attestées est incohérent.',
      );
    }
    final mapIds = canonicalPaths.keys.toList()
      ..sort(compareNarrativeEventUtf16);
    for (final mapId in mapIds) {
      final manifestPath = manifestPaths[mapId]!;
      final expectedCanonicalPath = canonicalPaths[mapId]!;
      final file = File(manifestPath);
      if (!await file.exists()) {
        return _AttestedMapRevisionIssue(
          code: 'staleMapRevision',
          message: 'La map $mapId a disparu pendant la préparation.',
        );
      }
      late final String canonicalPath;
      try {
        canonicalPath = p.normalize(await file.resolveSymbolicLinks());
      } on FileSystemException {
        return _AttestedMapRevisionIssue(
          code: 'staleMapRevision',
          message: 'La map $mapId ne peut plus être vérifiée.',
        );
      }
      if (canonicalPath != expectedCanonicalPath) {
        return _AttestedMapRevisionIssue(
          code: 'staleMapRevision',
          message: 'Le chemin canonique de la map $mapId a changé.',
        );
      }
      final currentHash = narrativeEventBytesFingerprint(
        await file.readAsBytes(),
      );
      late final String verifiedCanonicalPath;
      try {
        verifiedCanonicalPath = p.normalize(await file.resolveSymbolicLinks());
      } on FileSystemException {
        return _AttestedMapRevisionIssue(
          code: 'staleMapRevision',
          message: 'La map $mapId ne peut plus être vérifiée.',
        );
      }
      if (verifiedCanonicalPath != expectedCanonicalPath) {
        return _AttestedMapRevisionIssue(
          code: 'staleMapRevision',
          message: 'Le chemin canonique de la map $mapId a changé.',
        );
      }
      if (currentHash != expectedHashes[mapId]) {
        return _AttestedMapRevisionIssue(
          code: 'staleMapRevision',
          message: 'La map $mapId a changé pendant la préparation.',
        );
      }
    }
    return null;
  }

  _ProjectPreflight _preflight(List<int> bytes) {
    final result = preflightProjectManifestJson(bytes);
    final registryStatus = result.eventRegistry.when(
      absent: () => null,
      decoded: (_) => null,
      unsupported: (_, __) =>
          NarrativeEventRegistryPersistenceStatus.unsupportedRegistry,
      invalid: (_, __) =>
          NarrativeEventRegistryPersistenceStatus.invalidRegistry,
    );
    if (registryStatus != null) {
      return _ProjectPreflight.rejected(
        NarrativeEventRegistryPersistenceResult(
          status: registryStatus,
          code: registryStatus ==
                  NarrativeEventRegistryPersistenceStatus.unsupportedRegistry
              ? 'unsupportedRegistry'
              : 'invalidRegistry',
          message: result.diagnostics.isEmpty
              ? 'Le registry du projet est en lecture seule.'
              : result.diagnostics.join(' '),
        ),
      );
    }
    if (!result.writable || result.manifest == null) {
      return _ProjectPreflight.rejected(
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.invalidRegistry,
          code: 'invalidProject',
          message: result.diagnostics.isEmpty
              ? 'Le projet ne peut pas être décodé.'
              : result.diagnostics.join(' '),
        ),
      );
    }
    try {
      ProjectValidator.validate(result.manifest!);
      final decoded = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException('Project root must be an object.');
      }
      final root = <String, Object?>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String) {
          throw const FormatException('Project keys must be strings.');
        }
        root[entry.key as String] = entry.value;
      }
      return _ProjectPreflight.accepted(
        _ProjectSnapshot(
          root: root,
          registry: result.eventRegistry.registryOrNull,
        ),
      );
    } on Object catch (error) {
      return _ProjectPreflight.rejected(
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.invalidRegistry,
          code: 'invalidProject',
          message: 'Le projet ne peut pas être écrit: $error',
        ),
      );
    }
  }

  NarrativeEventRegistryPersistenceResult? _ownershipIssue(
    NarrativeEventRegistry? current,
    NarrativeEventRegistry? next,
  ) {
    if (current == null) {
      if (next == null ||
          (next.schemaVersion == 1 &&
              next.mode == EventSystemMode.legacyOnly &&
              next.legacyClaims.isEmpty)) {
        return null;
      }
      return _rejectedOwnership();
    }
    if (next == null) {
      return current.schemaVersion == 1 &&
              current.mode == EventSystemMode.legacyOnly &&
              current.legacyClaims.isEmpty
          ? null
          : _rejectedOwnership();
    }
    if (current.schemaVersion != next.schemaVersion ||
        current.mode != next.mode ||
        canonicalizeNarrativeEventJson(
              [for (final claim in current.legacyClaims) claim.toJson()],
            ) !=
            canonicalizeNarrativeEventJson(
              [for (final claim in next.legacyClaims) claim.toJson()],
            )) {
      return _rejectedOwnership();
    }
    return null;
  }

  NarrativeEventRegistryPersistenceResult _rejectedOwnership() {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.rejected,
      code: 'registryOwnershipViolation',
      message: 'L’authoring normal ne peut modifier ni le mode ni les claims.',
    );
  }

  Future<NarrativeEventRegistryPersistenceResult?> _validateBackup(
    NarrativeEventRegistryWriteJournal journal,
  ) async {
    final file = File(journal.backupPath);
    if (!await file.exists()) {
      return _blocked('backupMissing', 'Le backup requis est absent.');
    }
    final hash = narrativeEventBytesFingerprint(await file.readAsBytes());
    if (hash != journal.beforeHash) {
      return _blocked(
          'backupCorrupt', 'Le backup ne correspond pas au hash avant.');
    }
    return null;
  }

  Future<List<NarrativeEventRegistryRecoveryIssue>>
      _inspectPreparedRecoveryPrerequisites(
    NarrativeEventRegistryWriteJournal journal,
    String projectPath,
    String journalPath,
  ) async {
    final issues = <NarrativeEventRegistryRecoveryIssue>[];
    try {
      final backupIssue = await _validateBackup(journal);
      if (backupIssue != null) {
        issues.add(NarrativeEventRegistryRecoveryIssue(
          code: backupIssue.code,
          message: backupIssue.message,
          path: journalPath,
        ));
      }
      final projectFile = File(projectPath);
      if (!await projectFile.exists()) {
        issues.add(NarrativeEventRegistryRecoveryIssue(
          code: 'projectMissing',
          message: 'Le projet du journal est absent.',
          path: journalPath,
        ));
        return issues;
      }
      final projectHash = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      if (projectHash != journal.beforeHash &&
          projectHash != journal.expectedAfterHash) {
        issues.add(NarrativeEventRegistryRecoveryIssue(
          code: 'unknownProjectRevision',
          message:
              'Le projet ne correspond ni à la version avant ni à la version après.',
          path: journalPath,
        ));
      } else if (projectHash == journal.expectedAfterHash) {
        final tempIssue = await _validateTempWhenPresent(journal);
        if (tempIssue != null) {
          issues.add(NarrativeEventRegistryRecoveryIssue(
            code: tempIssue.code,
            message: tempIssue.message,
            path: journalPath,
          ));
        }
      }
    } on FileSystemException catch (error) {
      issues.add(NarrativeEventRegistryRecoveryIssue(
        code: 'recoveryInspectionIoFailure',
        message: 'L’inspection de récupération a échoué: ${error.message}',
        path: journalPath,
      ));
    }
    return issues;
  }

  Future<NarrativeEventRegistryPersistenceResult> _recoverOrphanBackup(
    String projectPath,
    String backupPath,
  ) async {
    final projectFile = File(projectPath);
    final backupFile = File(backupPath);
    if (!await projectFile.exists() || !await backupFile.exists()) {
      return _blocked(
        'orphanBackupMissingPeer',
        'Le backup orphelin ne peut pas être vérifié.',
      );
    }
    final projectHash = narrativeEventBytesFingerprint(
      await projectFile.readAsBytes(),
    );
    final backupHash = narrativeEventBytesFingerprint(
      await backupFile.readAsBytes(),
    );
    if (projectHash != backupHash) {
      return _blocked(
        'orphanBackupConflict',
        'Le backup orphelin ne correspond pas au projet courant.',
      );
    }
    await backupFile.delete();
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.recovered,
      code: 'orphanBackupRemoved',
      message: 'Le backup créé avant publication du journal a été retiré.',
      beforeRevision: projectHash,
      afterRevision: projectHash,
    );
  }

  Future<NarrativeEventRegistryPersistenceResult?> _validateTempWhenPresent(
    NarrativeEventRegistryWriteJournal journal,
  ) async {
    final file = File(journal.tempPath);
    if (!await file.exists()) return null;
    final hash = narrativeEventBytesFingerprint(await file.readAsBytes());
    if (hash != journal.expectedAfterHash) {
      return _blocked('tempCorrupt', 'Le fichier temporaire est corrompu.');
    }
    return null;
  }

  NarrativeEventRegistryPersistenceResult? _journalPathIssue(
    NarrativeEventRegistryWriteJournal journal,
    String actualJournalPath,
  ) {
    final expected = _pathsFor(journal.projectPath, journal.operationId);
    if (_qualified(journal.projectPath) != journal.projectPath ||
        _qualified(actualJournalPath) != expected.journalPath ||
        journal.journalPath != expected.journalPath ||
        journal.tempPath != expected.tempPath ||
        journal.backupPath != expected.backupPath) {
      return _blocked(
        'unsafeJournalPaths',
        'Les chemins du journal ne correspondent pas à son opération.',
      );
    }
    return null;
  }

  Future<void> _safeCleanup(
    NarrativeEventRegistryWriteJournal journal,
  ) async {
    final expected = _pathsFor(journal.projectPath, journal.operationId);
    if (journal.journalPath != expected.journalPath ||
        journal.tempPath != expected.tempPath ||
        journal.backupPath != expected.backupPath) {
      return;
    }
    for (final path in [
      journal.tempPath,
      journal.backupPath,
      '${expected.journalPath}.rewrite.tmp',
      '${expected.undoPath}.rewrite.tmp',
    ]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _checkpoint(
    NarrativeEventRegistryWriteCheckpoint checkpoint,
  ) async {
    await faultInjector?.call(checkpoint);
  }

  Future<void> _writeBytesFlushed(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  Future<void> _writeJsonAtomically(
    String path,
    Map<String, Object?> json,
  ) async {
    final rewritePath = '$path.rewrite.tmp';
    await _writeBytesFlushed(
      rewritePath,
      canonicalizeNarrativeEventJsonUtf8(json),
    );
    await File(rewritePath).rename(path);
  }

  Future<void> _writeJournal(
    NarrativeEventRegistryWriteJournal journal,
  ) {
    return _writeJsonAtomically(journal.journalPath, journal.toJson());
  }

  Future<void> _writeUndo(
    String path,
    NarrativeEventRegistryUndoEntry entry,
  ) {
    return _writeJsonAtomically(path, entry.toJson());
  }

  Future<NarrativeEventRegistryWriteJournal> _readJournal(String path) async {
    final decoded = decodeNarrativeEventJsonStrict(
      await File(path).readAsString(),
    );
    return NarrativeEventRegistryWriteJournal.fromJson(_jsonObject(decoded));
  }

  Future<NarrativeEventRegistryUndoEntry> _readUndo(String path) async {
    final decoded = decodeNarrativeEventJsonStrict(
      await File(path).readAsString(),
    );
    return NarrativeEventRegistryUndoEntry.fromJson(_jsonObject(decoded));
  }

  NarrativeEventRegistryUndoEntry _undoFromJournal(
    NarrativeEventRegistryWriteJournal journal,
    DateTime createdAt,
  ) {
    return NarrativeEventRegistryUndoEntry(
      schemaVersion: 1,
      operationId: journal.operationId,
      projectPath: journal.projectPath,
      beforeRevision: journal.beforeHash,
      afterRevision: journal.expectedAfterHash,
      previousRegistry: journal.previousRegistry,
      nextRegistry: journal.nextRegistry,
      previousRegistryHash: journal.previousRegistryHash,
      nextRegistryHash: journal.nextRegistryHash,
      eventIds: journal.eventIds,
      createdAt: createdAt,
    );
  }

  bool _undoMatchesJournal(
    NarrativeEventRegistryUndoEntry undo,
    NarrativeEventRegistryWriteJournal journal,
  ) {
    return undo.operationId == journal.operationId &&
        undo.projectPath == journal.projectPath &&
        undo.beforeRevision == journal.beforeHash &&
        undo.afterRevision == journal.expectedAfterHash &&
        undo.previousRegistryHash == journal.previousRegistryHash &&
        undo.nextRegistryHash == journal.nextRegistryHash &&
        _registryEquals(undo.previousRegistry, journal.previousRegistry) &&
        _registryEquals(undo.nextRegistry, journal.nextRegistry) &&
        canonicalizeNarrativeEventJson(undo.eventIds) ==
            canonicalizeNarrativeEventJson(journal.eventIds) &&
        !undo.createdAt.isBefore(journal.preparedAt);
  }

  Future<String?> _firstExistingArtifact(_PersistencePaths paths) async {
    for (final path in [
      paths.journalPath,
      paths.backupPath,
      paths.tempPath,
      paths.undoPath,
      '${paths.journalPath}.rewrite.tmp',
      '${paths.undoPath}.rewrite.tmp',
    ]) {
      if (await File(path).exists()) return path;
    }
    return null;
  }

  Future<NarrativeEventRegistryWriteJournal?> _matchingRecoveredJournal({
    required _PersistencePaths paths,
    required String expectedProjectRevision,
    required NarrativeEventRegistry? previousRegistry,
    required NarrativeEventRegistry? nextRegistry,
    required String mutation,
    required List<String> eventIds,
  }) async {
    final journalFile = File(paths.journalPath);
    if (!await journalFile.exists()) return null;
    NarrativeEventRegistryWriteJournal journal;
    try {
      journal = await _readJournal(paths.journalPath);
    } on Object {
      return null;
    }
    if (_journalPathIssue(journal, paths.journalPath) != null ||
        journal.state != NarrativeEventRegistryJournalState.recovered ||
        journal.beforeHash != expectedProjectRevision ||
        journal.mutation != mutation ||
        !_registryEquals(journal.previousRegistry, previousRegistry) ||
        !_registryEquals(journal.nextRegistry, nextRegistry) ||
        canonicalizeNarrativeEventJson(journal.eventIds) !=
            canonicalizeNarrativeEventJson(eventIds)) {
      return null;
    }
    for (final path in [
      paths.backupPath,
      paths.tempPath,
      paths.undoPath,
      '${paths.journalPath}.rewrite.tmp',
      '${paths.undoPath}.rewrite.tmp',
    ]) {
      if (await File(path).exists()) return null;
    }
    return journal;
  }

  NarrativeEventRegistryPersistenceResult _blocked(
    String code,
    String message,
  ) {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.blocked,
      code: code,
      message: message,
    );
  }

  NarrativeEventRegistryPersistenceResult _recoveryGateResult(
    NarrativeEventRegistryRecoveryInspection inspection,
  ) {
    final issue = inspection.issues.first;
    return NarrativeEventRegistryPersistenceResult(
      status: inspection.status ==
              NarrativeEventRegistryRecoveryGateStatus.recoveryRequired
          ? NarrativeEventRegistryPersistenceStatus.recoveryRequired
          : NarrativeEventRegistryPersistenceStatus.blocked,
      code: issue.code,
      message: issue.message,
      recoveryInspection: inspection,
    );
  }

  NarrativeEventRegistryPersistenceResult _ioFailure(
    FileSystemException error,
  ) {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.ioFailure,
      code: 'ioFailure',
      message: 'L’opération filesystem a échoué: ${error.message}',
    );
  }
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

bool _sameStringKeys(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      left.keys.every(right.containsKey) &&
      right.keys.every(left.containsKey);
}

String narrativeEventRegistryProjectRevision(List<int> projectBytes) {
  return narrativeEventBytesFingerprint(projectBytes);
}

String narrativeEventRegistryJournalPath(
  String projectPath,
  String operationId,
) {
  return _pathsFor(_qualified(projectPath), operationId).journalPath;
}

String narrativeEventRegistryUndoPath(
  String projectPath,
  String operationId,
) {
  return _pathsFor(_qualified(projectPath), operationId).undoPath;
}

String _registryHash(NarrativeEventRegistry? registry) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(registry?.toJson()),
  );
}

bool _registryEquals(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('JSON object keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _qualified(String path) => p.normalize(File(path).absolute.path);

Future<String> _canonicalProjectPath(String path) async {
  final file = File(path);
  return p.normalize(
    await file.exists()
        ? await file.resolveSymbolicLinks()
        : file.absolute.path,
  );
}

const _recoveryRequiredMessage =
    'Une écriture d’événements interrompue doit être récupérée avant '
    'd’ouvrir ou d’enregistrer ce projet.';

String _projectArtifactPrefix(String projectPath) {
  final projectKey = narrativeEventCanonicalSha256({
    'projectPath': _qualified(projectPath),
  }).substring(0, 16);
  return '${NarrativeEventRegistryPersistence.journalPrefix}$projectKey-';
}

_PersistencePaths _pathsFor(String projectPath, String operationId) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(operationId) ||
      operationId.length > 96) {
    throw ArgumentError.value(operationId, 'operationId', 'must be path-safe');
  }
  final directory = p.dirname(projectPath);
  final stem = '${_projectArtifactPrefix(projectPath)}$operationId';
  return _PersistencePaths(
    journalPath: _qualified(p.join(
      directory,
      '$stem${NarrativeEventRegistryPersistence.journalSuffix}',
    )),
    backupPath: _qualified(p.join(
      directory,
      '$stem${NarrativeEventRegistryPersistence.backupSuffix}',
    )),
    tempPath: _qualified(p.join(
      directory,
      '$stem${NarrativeEventRegistryPersistence.tempSuffix}',
    )),
    undoPath: _qualified(p.join(
      directory,
      '$stem${NarrativeEventRegistryPersistence.undoSuffix}',
    )),
  );
}

final class _PersistencePaths {
  const _PersistencePaths({
    required this.journalPath,
    required this.backupPath,
    required this.tempPath,
    required this.undoPath,
  });

  final String journalPath;
  final String backupPath;
  final String tempPath;
  final String undoPath;
}

final class _ProjectSnapshot {
  const _ProjectSnapshot({required this.root, required this.registry});

  final Map<String, Object?> root;
  final NarrativeEventRegistry? registry;
}

final class _ProjectPreflight {
  const _ProjectPreflight.accepted(this.snapshot) : rejection = null;
  const _ProjectPreflight.rejected(this.rejection) : snapshot = null;

  final _ProjectSnapshot? snapshot;
  final NarrativeEventRegistryPersistenceResult? rejection;
}

final class _AttestedMapRevisionIssue {
  const _AttestedMapRevisionIssue({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}
