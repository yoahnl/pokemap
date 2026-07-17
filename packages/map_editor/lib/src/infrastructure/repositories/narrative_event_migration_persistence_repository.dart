import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_migration_persistence_models.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/ports/narrative_event_migration_persistence_gateway.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

/// Persists one reviewed migration with byte backup and a durable journal.
///
/// Each file is written atomically, but the multi-file sequence is not claimed
/// to be transactional. Recovery inspects the prepared journal, and
/// compensation restores the backup only while every revision, receipt,
/// ownership and semantic fingerprint guard still matches.
final class NarrativeEventMigrationPersistenceRepository
    implements NarrativeEventMigrationPersistenceGateway {
  NarrativeEventMigrationPersistenceRepository({
    this.faultInjector,
    NarrativeEventRegistryPersistence? registryPersistence,
  }) : _registryPersistence =
            registryPersistence ?? NarrativeEventRegistryPersistence();

  final NarrativeEventMigrationFaultInjector? faultInjector;
  final NarrativeEventRegistryPersistence _registryPersistence;

  @override
  Future<NarrativeEventMigrationInspection> inspect(String projectPath) async {
    return withProjectManifestWriteLock(
      projectPath,
      () => _inspectLocked(projectPath),
    );
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> commit(
    NarrativeEventMigrationCommitRequest request,
  ) async {
    final preview = request.preview;
    try {
      return await withProjectManifestWriteLock(preview.projectPath, () async {
        final inspection = await _inspectLocked(preview.projectPath);
        if (inspection.status !=
            NarrativeEventMigrationInspectionStatus.clear) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.blocked,
            'migrationRecoveryGate',
            inspection.message,
            journalPath: inspection.journalPath,
          );
        }
        final projectFile = File(preview.projectPath);
        final beforeBytes = await projectFile.readAsBytes();
        final beforeRevision = narrativeEventBytesFingerprint(beforeBytes);
        final receipt = preview.receipt!;
        if (beforeRevision != preview.projectRevision ||
            beforeRevision != receipt.snapshot.projectRevisionToken) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.staleRevision,
            'staleProjectRevision',
            'Le projet a changé depuis la prévisualisation.',
          );
        }
        final nextRegistry = preview.registryAfter;
        final nextProject = preview.project.copyWith(
          eventRegistry: nextRegistry,
        );
        ProjectValidator.validate(nextProject);
        final expectedManifestHash = _semanticHash(nextProject.toJson());
        final expectedRegistryHash = _semanticHash(nextRegistry.toJson());
        if (expectedManifestHash != receipt.expectedManifestHashAfter ||
            expectedRegistryHash != receipt.expectedRegistryHashAfter) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.rejected,
            'receiptTargetMismatch',
            'Le résultat proposé ne correspond plus au receipt attesté.',
          );
        }

        final currentRoot = _jsonObject(
          decodeNarrativeEventJsonStrict(utf8.decode(beforeBytes)),
        );
        final nextRoot = Map<String, Object?>.from(currentRoot)
          ..['eventRegistry'] = nextRegistry.toJson();
        canonicalizeNarrativeEventJson(nextRoot);
        final nextBytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(nextRoot),
        );
        final paths = _paths(preview.projectPath, receipt.receiptId);
        await Directory(paths.directory).create(recursive: true);
        await _writeAtomic(paths.backup, beforeBytes);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterBackupWritten,
        );
        final receiptBytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(receipt.toJson()),
        );
        await _writeAtomic(paths.receipt, receiptBytes);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterReceiptWritten,
        );
        final journal = _MigrationJournal(
          receiptId: receipt.receiptId,
          projectPath: p.normalize(preview.projectPath),
          state: NarrativeEventMigrationJournalState.prepared,
          beforeRevision: beforeRevision,
          afterRevision: narrativeEventBytesFingerprint(nextBytes),
          backupHash: narrativeEventBytesFingerprint(beforeBytes),
          receiptHash: narrativeEventBytesFingerprint(receiptBytes),
          expectedManifestHashAfter: receipt.expectedManifestHashAfter,
          expectedRegistryHashAfter: receipt.expectedRegistryHashAfter,
          ownerFingerprint: _ownerFingerprint(
            receiptId: receipt.receiptId,
            projectPath: p.normalize(preview.projectPath),
            beforeRevision: beforeRevision,
            expectedManifestHashAfter: receipt.expectedManifestHashAfter,
          ),
        );
        await _writeJournal(paths.journal, journal);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterJournalPrepared,
        );
        if (narrativeEventBytesFingerprint(await projectFile.readAsBytes()) !=
            beforeRevision) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.recoveryRequired,
            'projectChangedAfterJournal',
            'Le projet a changé après la préparation du journal.',
            journalPath: paths.journal,
            receiptPath: paths.receipt,
          );
        }
        await _writeAtomic(preview.projectPath, nextBytes);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterProjectRenamed,
        );
        final committed = journal.withState(
          NarrativeEventMigrationJournalState.committed,
        );
        await _writeJournal(paths.journal, committed);
        await _fault(
          NarrativeEventMigrationWriteCheckpoint.afterJournalCommitted,
        );
        return _result(
          NarrativeEventMigrationPersistenceStatus.committed,
          'migrationCommitted',
          'Les événements V2 et leurs liens sont enregistrés; le mode runtime reste inchangé.',
          journalPath: paths.journal,
          receiptPath: paths.receipt,
        );
      });
    } on Object catch (error) {
      final receiptId = preview.receipt?.receiptId;
      final paths =
          receiptId == null ? null : _paths(preview.projectPath, receiptId);
      final prepared = paths != null && await File(paths.journal).exists();
      return _result(
        prepared
            ? NarrativeEventMigrationPersistenceStatus.recoveryRequired
            : NarrativeEventMigrationPersistenceStatus.ioFailure,
        prepared ? 'preparedMigrationInterrupted' : 'migrationIoFailure',
        'La migration a été interrompue: $error',
        journalPath: paths?.journal,
        receiptPath: paths?.receipt,
      );
    }
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> activateV2(
    NarrativeEventV2ModeActivationRequest request,
  ) async {
    try {
      return await withProjectManifestWriteLock(request.projectPath, () async {
        final inspection = await _inspectLocked(request.projectPath);
        if (inspection.status !=
            NarrativeEventMigrationInspectionStatus.clear) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.blocked,
            'migrationRecoveryGate',
            inspection.message,
            journalPath: inspection.journalPath,
          );
        }

        final projectFile = File(request.projectPath);
        final beforeBytes = await projectFile.readAsBytes();
        final beforeRevision = narrativeEventBytesFingerprint(beforeBytes);
        if (beforeRevision != request.expectedProjectRevision) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.staleRevision,
            'staleProjectRevision',
            'Le projet a changé depuis la vérification d’activation.',
          );
        }

        final currentRoot = _jsonObject(
          decodeNarrativeEventJsonStrict(utf8.decode(beforeBytes)),
        );
        final decodedRegistry = decodeNarrativeEventRegistry(
          currentRoot['eventRegistry'],
        );
        if (!decodedRegistry.writable) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.rejected,
            'unsupportedRegistry',
            'Le registre Event actuel ne peut pas être modifié.',
          );
        }
        final current = decodedRegistry.registryOrNull;
        if (current?.mode == request.targetMode) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.noOp,
            'eventV2AlreadyActive',
            'Event V2 est déjà le mode actif de ce projet.',
          );
        }
        if (current?.mode == EventSystemMode.v2Only ||
            (request.targetMode == EventSystemMode.v2Only &&
                (current?.records.isNotEmpty == true ||
                    current?.legacyClaims.isNotEmpty == true))) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.rejected,
            'legacyOwnershipPresent',
            'Le registre ne peut pas effectuer cette transition de mode.',
          );
        }

        final nextRegistry = NarrativeEventRegistry(
          schemaVersion: 1,
          mode: request.targetMode,
          records: current?.records ?? const <NarrativeEventRecord>[],
          legacyClaims: current?.legacyClaims ?? const <LegacySourceClaim>[],
        );
        final nextRoot = Map<String, Object?>.from(currentRoot)
          ..['eventRegistry'] = nextRegistry.toJson();
        late final List<int> nextBytes;
        try {
          final decodedProject = ProjectManifest.fromJson(
            _jsonObject(jsonDecode(jsonEncode(nextRoot))),
          );
          ProjectValidator.validate(decodedProject);
          canonicalizeNarrativeEventJson(nextRoot);
          nextBytes = utf8.encode(
            const JsonEncoder.withIndent('  ').convert(nextRoot),
          );
        } on Object catch (error) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.rejected,
            'invalidActivationTarget',
            'Le projet activé ne serait pas valide: $error',
          );
        }

        if (narrativeEventBytesFingerprint(await projectFile.readAsBytes()) !=
            beforeRevision) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.staleRevision,
            'projectChangedBeforeActivation',
            'Le projet a changé pendant la préparation de l’activation.',
          );
        }
        await _writeAtomic(request.projectPath, nextBytes);
        return _result(
          NarrativeEventMigrationPersistenceStatus.committed,
          request.targetMode == EventSystemMode.v2Only
              ? 'eventV2Activated'
              : 'eventV2CompatibilityActivated',
          request.targetMode == EventSystemMode.v2Only
              ? 'Event V2 est maintenant actif pour ce projet.'
              : 'Event V2 est actif avec compatibilité historique.',
        );
      });
    } on Object catch (error) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.ioFailure,
        'eventV2ActivationIoFailure',
        'L’activation Event V2 a été interrompue: $error',
      );
    }
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> recover(
    String projectPath,
  ) async {
    try {
      return await withProjectManifestWriteLock(projectPath, () async {
        final registryGate = await _registryRecoveryGate(projectPath);
        if (registryGate != null) return registryGate;
        final journalEntry = await _singleJournal(projectPath);
        if (journalEntry == null) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.noOp,
            'noMigrationRecovery',
            'Aucune migration interrompue n’est présente.',
          );
        }
        final (journalPath, journal) = journalEntry;
        if (journal.state != NarrativeEventMigrationJournalState.prepared) {
          return _result(
            NarrativeEventMigrationPersistenceStatus.noOp,
            'migrationAlreadyTerminal',
            'Le journal de migration est déjà dans un état terminal.',
            journalPath: journalPath,
          );
        }
        if (!_safeReceiptId(journal.receiptId)) {
          return _blocked('invalidReceiptId', journalPath);
        }
        final paths = _paths(projectPath, journal.receiptId);
        final evidenceFailure = await _migrationEvidenceFailure(
          journal: journal,
          paths: paths,
          projectPath: projectPath,
        );
        if (evidenceFailure != null) {
          return _blocked(evidenceFailure, journalPath);
        }
        final currentRevision = narrativeEventBytesFingerprint(
          await File(projectPath).readAsBytes(),
        );
        if (currentRevision == journal.beforeRevision) {
          await _writeJournal(
            journalPath,
            journal.withState(NarrativeEventMigrationJournalState.recovered),
          );
          return _result(
            NarrativeEventMigrationPersistenceStatus.recovered,
            'preparedMigrationRolledBack',
            'La migration interrompue a été refermée sans modifier le projet.',
            journalPath: journalPath,
            receiptPath: paths.receipt,
          );
        }
        if (currentRevision == journal.afterRevision) {
          final currentProject = ProjectManifest.fromJson(
            Map<String, dynamic>.from(
              _jsonObject(
                decodeNarrativeEventJsonStrict(
                  await File(projectPath).readAsString(),
                ),
              ),
            ),
          );
          if (_semanticHash(currentProject.toJson()) !=
                  journal.expectedManifestHashAfter ||
              _semanticHash(currentProject.eventRegistry?.toJson()) !=
                  journal.expectedRegistryHashAfter) {
            return _blocked('migrationFingerprintMismatch', journalPath);
          }
          await _writeJournal(
            journalPath,
            journal.withState(NarrativeEventMigrationJournalState.committed),
          );
          return _result(
            NarrativeEventMigrationPersistenceStatus.recovered,
            'preparedMigrationFinalized',
            'La migration appliquée a été finalisée.',
            journalPath: journalPath,
            receiptPath: paths.receipt,
          );
        }
        return _blocked('projectRevisionDiverged', journalPath);
      });
    } on Object catch (error) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.ioFailure,
        'migrationRecoveryFailure',
        'La récupération a échoué: $error',
      );
    }
  }

  @override
  Future<NarrativeEventMigrationPersistenceResult> compensate(
    NarrativeEventMigrationCompensationRequest request,
  ) async {
    if (!_safeReceiptId(request.receiptId)) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.blocked,
        'invalidReceiptId',
        'Le receipt demandé est invalide.',
      );
    }
    try {
      return await withProjectManifestWriteLock(request.projectPath, () async {
        final registryGate = await _registryRecoveryGate(request.projectPath);
        if (registryGate != null) return registryGate;
        final paths = _paths(request.projectPath, request.receiptId);
        if (!await File(paths.journal).exists()) {
          return _blocked('migrationJournalMissing', paths.journal);
        }
        final journal = await _readJournal(paths.journal);
        if (journal.state != NarrativeEventMigrationJournalState.committed) {
          return _blocked('migrationNotCommitted', paths.journal);
        }
        if (journal.receiptId != request.receiptId) {
          return _blocked('migrationReceiptMismatch', paths.journal);
        }
        final evidenceFailure = await _migrationEvidenceFailure(
          journal: journal,
          paths: paths,
          projectPath: request.projectPath,
        );
        if (evidenceFailure != null) {
          return _blocked(evidenceFailure, paths.journal);
        }
        final backupBytes = await File(paths.backup).readAsBytes();
        final currentBytes = await File(request.projectPath).readAsBytes();
        if (narrativeEventBytesFingerprint(currentBytes) !=
            journal.afterRevision) {
          return _blocked('projectRevisionDiverged', paths.journal);
        }
        final currentProject = ProjectManifest.fromJson(
          Map<String, dynamic>.from(
            _jsonObject(
              decodeNarrativeEventJsonStrict(utf8.decode(currentBytes)),
            ),
          ),
        );
        if (_semanticHash(currentProject.toJson()) !=
                journal.expectedManifestHashAfter ||
            _semanticHash(currentProject.eventRegistry?.toJson()) !=
                journal.expectedRegistryHashAfter) {
          return _blocked('migrationFingerprintMismatch', paths.journal);
        }
        await _writeAtomic(request.projectPath, backupBytes);
        await _writeJournal(
          paths.journal,
          journal.withState(
            NarrativeEventMigrationJournalState.compensated,
          ),
        );
        return _result(
          NarrativeEventMigrationPersistenceStatus.compensated,
          'migrationCompensated',
          'Le projet a été restauré à ses octets antérieurs.',
          journalPath: paths.journal,
          receiptPath: paths.receipt,
        );
      });
    } on Object catch (error) {
      return _result(
        NarrativeEventMigrationPersistenceStatus.blocked,
        'compensationPrerequisiteMissing',
        'La compensation est bloquée: $error',
      );
    }
  }

  Future<NarrativeEventMigrationInspection> _inspectLocked(
    String projectPath,
  ) async {
    try {
      final registryInspection =
          await _registryPersistence.inspectProjectAlreadyLocked(projectPath);
      if (registryInspection.status !=
          NarrativeEventRegistryRecoveryGateStatus.clear) {
        return NarrativeEventMigrationInspection(
          status: NarrativeEventMigrationInspectionStatus.blocked,
          code: 'eventRegistryRecoveryGate',
          message: registryInspection.issues.isEmpty
              ? 'Une écriture Event doit être récupérée avant la migration.'
              : registryInspection.issues.first.message,
          journalPath: registryInspection.issues
              .map((issue) => issue.path)
              .whereType<String>()
              .firstOrNull,
        );
      }
      final entries = await _journalFiles(projectPath);
      if (entries.isEmpty) {
        return const NarrativeEventMigrationInspection(
          status: NarrativeEventMigrationInspectionStatus.clear,
          code: 'clear',
          message: 'Aucun journal de migration en attente.',
        );
      }
      if (entries.length != 1) {
        return NarrativeEventMigrationInspection(
          status: NarrativeEventMigrationInspectionStatus.blocked,
          code: 'multipleMigrationJournals',
          message: 'Plusieurs journaux de migration exigent une inspection.',
          journalPath: entries.first,
        );
      }
      final journal = await _readJournal(entries.single);
      final status = switch (journal.state) {
        NarrativeEventMigrationJournalState.prepared =>
          NarrativeEventMigrationInspectionStatus.recoveryRequired,
        NarrativeEventMigrationJournalState.committed =>
          NarrativeEventMigrationInspectionStatus.committed,
        NarrativeEventMigrationJournalState.recovered ||
        NarrativeEventMigrationJournalState.compensated =>
          NarrativeEventMigrationInspectionStatus.clear,
      };
      return NarrativeEventMigrationInspection(
        status: status,
        code: journal.state.name,
        message:
            status == NarrativeEventMigrationInspectionStatus.recoveryRequired
                ? 'Une migration préparée doit être récupérée.'
                : 'Le journal de migration est ${journal.state.name}.',
        journalPath: entries.single,
      );
    } on Object catch (error) {
      return NarrativeEventMigrationInspection(
        status: NarrativeEventMigrationInspectionStatus.blocked,
        code: 'invalidMigrationJournal',
        message: 'Le journal de migration est illisible: $error',
      );
    }
  }

  Future<(String, _MigrationJournal)?> _singleJournal(
    String projectPath,
  ) async {
    final files = await _journalFiles(projectPath);
    if (files.length != 1) return null;
    return (files.single, await _readJournal(files.single));
  }

  Future<List<String>> _journalFiles(String projectPath) async {
    final root = Directory(
      p.join(p.dirname(projectPath), '.pokemap', 'event-migration'),
    );
    if (!await root.exists()) return const [];
    final result = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path) == 'journal.json') {
        result.add(p.normalize(entity.path));
      }
    }
    result.sort(compareNarrativeEventUtf16);
    return result;
  }

  Future<void> _fault(NarrativeEventMigrationWriteCheckpoint checkpoint) async {
    await faultInjector?.call(checkpoint);
  }

  Future<NarrativeEventMigrationPersistenceResult?> _registryRecoveryGate(
    String projectPath,
  ) async {
    final inspection =
        await _registryPersistence.inspectProjectAlreadyLocked(projectPath);
    if (inspection.status == NarrativeEventRegistryRecoveryGateStatus.clear) {
      return null;
    }
    return _result(
      NarrativeEventMigrationPersistenceStatus.blocked,
      'eventRegistryRecoveryGate',
      inspection.issues.isEmpty
          ? 'Une écriture Event doit être récupérée avant cette opération.'
          : inspection.issues.first.message,
      journalPath: inspection.issues
          .map((issue) => issue.path)
          .whereType<String>()
          .firstOrNull,
    );
  }
}

Future<String?> _migrationEvidenceFailure({
  required _MigrationJournal journal,
  required _MigrationPaths paths,
  required String projectPath,
}) async {
  if (journal.projectPath != p.normalize(projectPath) ||
      journal.ownerFingerprint !=
          _ownerFingerprint(
            receiptId: journal.receiptId,
            projectPath: journal.projectPath,
            beforeRevision: journal.beforeRevision,
            expectedManifestHashAfter: journal.expectedManifestHashAfter,
          )) {
    return 'migrationOwnershipMismatch';
  }
  final receiptBytes = await File(paths.receipt).readAsBytes();
  final receipt =
      decodeNarrativeEventMigrationReceiptStrict(receiptBytes).receiptOrNull;
  if (receipt == null ||
      receipt.receiptId != journal.receiptId ||
      narrativeEventBytesFingerprint(receiptBytes) != journal.receiptHash) {
    return 'migrationReceiptMismatch';
  }
  if (receipt.snapshot.projectRevisionToken != journal.beforeRevision ||
      receipt.expectedManifestHashAfter != journal.expectedManifestHashAfter ||
      receipt.expectedRegistryHashAfter != journal.expectedRegistryHashAfter) {
    return 'migrationReceiptMismatch';
  }
  final backupBytes = await File(paths.backup).readAsBytes();
  final backupRevision = narrativeEventBytesFingerprint(backupBytes);
  if (backupRevision != journal.backupHash ||
      backupRevision != journal.beforeRevision) {
    return 'backupHashMismatch';
  }
  return null;
}

final class _MigrationPaths {
  const _MigrationPaths({
    required this.directory,
    required this.journal,
    required this.receipt,
    required this.backup,
  });

  final String directory;
  final String journal;
  final String receipt;
  final String backup;
}

_MigrationPaths _paths(String projectPath, String receiptId) {
  final directory = p.join(
    p.dirname(projectPath),
    '.pokemap',
    'event-migration',
    receiptId,
  );
  return _MigrationPaths(
    directory: directory,
    journal: p.join(directory, 'journal.json'),
    receipt: p.join(directory, 'receipt.json'),
    backup: p.join(directory, 'project.before.json'),
  );
}

final class _MigrationJournal {
  const _MigrationJournal({
    required this.receiptId,
    required this.projectPath,
    required this.state,
    required this.beforeRevision,
    required this.afterRevision,
    required this.backupHash,
    required this.receiptHash,
    required this.expectedManifestHashAfter,
    required this.expectedRegistryHashAfter,
    required this.ownerFingerprint,
  });

  factory _MigrationJournal.fromJson(Map<String, Object?> json) {
    String value(String key) {
      final result = json[key];
      if (result is! String || result.isEmpty) {
        throw FormatException('Invalid journal field $key.');
      }
      return result;
    }

    return _MigrationJournal(
      receiptId: value('receiptId'),
      projectPath: value('projectPath'),
      state: NarrativeEventMigrationJournalState.values.byName(value('state')),
      beforeRevision: value('beforeRevision'),
      afterRevision: value('afterRevision'),
      backupHash: value('backupHash'),
      receiptHash: value('receiptHash'),
      expectedManifestHashAfter: value('expectedManifestHashAfter'),
      expectedRegistryHashAfter: value('expectedRegistryHashAfter'),
      ownerFingerprint: value('ownerFingerprint'),
    );
  }

  final String receiptId;
  final String projectPath;
  final NarrativeEventMigrationJournalState state;
  final String beforeRevision;
  final String afterRevision;
  final String backupHash;
  final String receiptHash;
  final String expectedManifestHashAfter;
  final String expectedRegistryHashAfter;
  final String ownerFingerprint;

  _MigrationJournal withState(NarrativeEventMigrationJournalState value) {
    return _MigrationJournal(
      receiptId: receiptId,
      projectPath: projectPath,
      state: value,
      beforeRevision: beforeRevision,
      afterRevision: afterRevision,
      backupHash: backupHash,
      receiptHash: receiptHash,
      expectedManifestHashAfter: expectedManifestHashAfter,
      expectedRegistryHashAfter: expectedRegistryHashAfter,
      ownerFingerprint: ownerFingerprint,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'receiptId': receiptId,
        'projectPath': projectPath,
        'state': state.name,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'backupHash': backupHash,
        'receiptHash': receiptHash,
        'expectedManifestHashAfter': expectedManifestHashAfter,
        'expectedRegistryHashAfter': expectedRegistryHashAfter,
        'ownerFingerprint': ownerFingerprint,
      };
}

Future<_MigrationJournal> _readJournal(String path) async {
  return _MigrationJournal.fromJson(
    _jsonObject(
      decodeNarrativeEventJsonStrict(await File(path).readAsString()),
    ),
  );
}

Future<void> _writeJournal(String path, _MigrationJournal journal) {
  return _writeAtomic(
    path,
    utf8.encode(const JsonEncoder.withIndent('  ').convert(journal.toJson())),
  );
}

Future<void> _writeAtomic(String path, List<int> bytes) async {
  final target = File(path);
  await target.parent.create(recursive: true);
  final temp = File('$path.rewrite.tmp');
  if (await temp.exists()) await temp.delete();
  await temp.writeAsBytes(bytes, flush: true);
  await temp.rename(path);
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object.');
  return <String, Object?>{
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

String _semanticHash(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(value)}';

String _ownerFingerprint({
  required String receiptId,
  required String projectPath,
  required String beforeRevision,
  required String expectedManifestHashAfter,
}) =>
    _semanticHash({
      'receiptId': receiptId,
      'projectPath': projectPath,
      'beforeRevision': beforeRevision,
      'expectedManifestHashAfter': expectedManifestHashAfter,
    });

bool _safeReceiptId(String value) =>
    RegExp(r'^evmr_[0-9a-f-]+$').hasMatch(value) && p.basename(value) == value;

NarrativeEventMigrationPersistenceResult _blocked(
  String code,
  String journalPath,
) {
  return _result(
    NarrativeEventMigrationPersistenceStatus.blocked,
    code,
    'La précondition de compensation « $code » n’est plus satisfaite.',
    journalPath: journalPath,
  );
}

NarrativeEventMigrationPersistenceResult _result(
  NarrativeEventMigrationPersistenceStatus status,
  String code,
  String message, {
  String? journalPath,
  String? receiptPath,
}) {
  return NarrativeEventMigrationPersistenceResult(
    status: status,
    code: code,
    message: message,
    journalPath: journalPath,
    receiptPath: receiptPath,
  );
}
