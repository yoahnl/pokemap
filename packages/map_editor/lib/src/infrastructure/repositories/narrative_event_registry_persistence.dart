import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

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
      final verification = verifyNarrativeEventAuthoringResult(
        context: request.authoringContext,
        result: request.authoringResult,
      );
      if (verification != null) {
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.rejected,
          code: verification.code,
          message: verification.message,
        );
      }
      return await withProjectManifestWriteLock(
        request.projectPath,
        () => _writeTransition(
          projectPath: request.projectPath,
          operationId: request.operationId,
          expectedProjectRevision: request.expectedProjectRevision,
          previousRegistry: request.previousRegistry,
          nextRegistry: request.nextRegistry,
          mutation: request.mutation,
          eventIds: request.eventIds,
        ),
      );
    } on FileSystemException catch (error) {
      return _ioFailure(error);
    }
  }

  Future<List<NarrativeEventRegistryPersistenceResult>> recoverProject(
    String projectPath,
  ) async {
    try {
      return await withProjectManifestWriteLock(
        projectPath,
        () => _recoverProjectLocked(projectPath),
      );
    } on FileSystemException catch (error) {
      return [_ioFailure(error)];
    }
  }

  Future<List<NarrativeEventRegistryPersistenceResult>> _recoverProjectLocked(
    String projectPath,
  ) async {
    final qualifiedProjectPath = _qualified(projectPath);
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
          name.endsWith('$journalSuffix.rewrite.tmp')) {
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
    for (final rewritePath in rewritePaths) {
      final finalPath = rewritePath.substring(
        0,
        rewritePath.length - '.rewrite.tmp'.length,
      );
      if (journals.containsKey(finalPath)) {
        final rewriteFile = File(rewritePath);
        if (await rewriteFile.exists()) await rewriteFile.delete();
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
        () => _recoverJournalLocked(journalPath),
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
        () => _undoEntry(undoPath, entry),
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
      if (liveHash != beforeHash) {
        journal = journal.withState(
          NarrativeEventRegistryJournalState.recovered,
          _clock().toUtc(),
        );
        await _writeJournal(journal);
        await _safeCleanup(journal);
        return NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.staleRevision,
          code: 'staleRevisionBeforeRename',
          message: 'Le projet a changé pendant la préparation.',
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
    if (journal.tempPath != expected.tempPath ||
        journal.backupPath != expected.backupPath) {
      return;
    }
    for (final path in [journal.tempPath, journal.backupPath]) {
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
