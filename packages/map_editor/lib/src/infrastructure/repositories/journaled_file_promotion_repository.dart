import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'project_manifest_write_lock.dart';

typedef JournaledPromotionFaultInjector = Future<void> Function(
  int renamedFileCount,
);

typedef JournaledPromotionBeforeReplaceHook = Future<void> Function(
  int fileIndex,
  String sourcePath,
  String destinationPath,
);

typedef JournaledPromotionCheckpointFaultInjector = Future<void> Function(
  int checkpointedFileCount,
);

enum JournaledFilePromotionStatus {
  promoted,
  noOp,
  restored,
  recoveryRequired,
  blocked,
  ioFailure,
}

final class JournaledFilePromotionResult {
  const JournaledFilePromotionResult({
    required this.status,
    required this.code,
    required this.message,
    required this.journalPath,
  });

  final JournaledFilePromotionStatus status;
  final String code;
  final String message;
  final String journalPath;

  bool get succeeded =>
      status == JournaledFilePromotionStatus.promoted ||
      status == JournaledFilePromotionStatus.noOp ||
      status == JournaledFilePromotionStatus.restored;
}

/// Promotes a frozen, hash-pinned list of files with a durable checkpoint.
///
/// The operation is atomic per file. A prepared journal and exact before/after
/// hashes make an interrupted multi-file sequence resumable without guessing.
final class JournaledFilePromotionRepository {
  JournaledFilePromotionRepository({
    required String repositoryRoot,
    required String manifestPath,
    required Set<String> allowedDestinations,
    String? journalPath,
    this.faultInjector,
    this.beforeReplaceHook,
    this.checkpointFaultInjector,
  })  : repositoryRoot = p.normalize(p.absolute(repositoryRoot)),
        manifestPath = p.normalize(p.absolute(manifestPath)),
        allowedDestinations = Set<String>.unmodifiable(
          allowedDestinations.map(_normalizeRelative),
        ),
        journalPath = p.normalize(
          p.absolute(
            journalPath ??
                p.join(
                  repositoryRoot,
                  'selbrume',
                  '.pokemap-event-v2-phase-j-promotion.json',
                ),
          ),
        ),
        projectManifestPath = p.normalize(
          p.absolute(repositoryRoot, 'selbrume', 'project.json'),
        );

  final String repositoryRoot;
  final String manifestPath;
  final Set<String> allowedDestinations;
  final String journalPath;
  final String projectManifestPath;
  final JournaledPromotionFaultInjector? faultInjector;
  final JournaledPromotionBeforeReplaceHook? beforeReplaceHook;
  final JournaledPromotionCheckpointFaultInjector? checkpointFaultInjector;

  String get checkpointDirectoryPath => '$journalPath.checkpoint';

  Future<JournaledFilePromotionResult> promote() async {
    try {
      return await withProjectManifestWriteLock(
        projectManifestPath,
        _promoteLocked,
      );
    } on _PromotionRejected catch (error) {
      return _result(
        JournaledFilePromotionStatus.blocked,
        error.code,
        error.message,
      );
    } on Object catch (error) {
      return _result(
        await File(journalPath).exists()
            ? JournaledFilePromotionStatus.recoveryRequired
            : JournaledFilePromotionStatus.ioFailure,
        await File(journalPath).exists()
            ? 'promotionInterrupted'
            : 'promotionIoFailure',
        'La promotion a été interrompue: $error',
      );
    }
  }

  Future<JournaledFilePromotionResult> _promoteLocked() async {
    final plan = await _loadPlan();
    final journalFile = File(journalPath);
    if (await journalFile.exists()) {
      final journal = await _loadJournal(plan);
      return await _resume(plan, journal);
    }

    final states = await _classifyDestinations(plan);
    if (states.every((state) => state == _DestinationState.after)) {
      return _result(
        JournaledFilePromotionStatus.noOp,
        'promotionAlreadyApplied',
        'Tous les fichiers correspondent déjà au manifeste figé.',
      );
    }
    if (states.asMap().entries.any(
          (state) => !_isBeforeCompatible(plan.entries[state.key], state.value),
        )) {
      throw const _PromotionRejected(
        'destinationRevisionMismatch',
        'Au moins une destination ne correspond ni au checkpoint ni à la cible.',
      );
    }
    if (await Directory(checkpointDirectoryPath).exists()) {
      throw const _PromotionRejected(
        'orphanPromotionCheckpoint',
        'Un checkpoint sans journal existe déjà; aucune écriture n’est autorisée.',
      );
    }
    final journal = _newPreparedJournal(plan);
    await _writeJournal(journal);
    await _prepareCheckpoint(plan);
    await faultInjector?.call(0);
    return await _resume(plan, journal);
  }

  /// Restores the exact pre-promotion checkpoint while all hash guards match.
  Future<JournaledFilePromotionResult> restoreCheckpoint() async {
    try {
      return await withProjectManifestWriteLock(
        projectManifestPath,
        _restoreCheckpointLocked,
      );
    } on _PromotionRejected catch (error) {
      return _result(
        JournaledFilePromotionStatus.blocked,
        error.code,
        error.message,
      );
    } on Object catch (error) {
      return _result(
        JournaledFilePromotionStatus.recoveryRequired,
        'checkpointRestoreInterrupted',
        'La restauration a été interrompue: $error',
      );
    }
  }

  Future<JournaledFilePromotionResult> _restoreCheckpointLocked() async {
    final plan = await _loadPlan();
    if (!await File(journalPath).exists()) {
      throw const _PromotionRejected(
        'promotionJournalMissing',
        'Aucun journal de promotion ne peut être restauré.',
      );
    }
    var journal = await _loadJournal(plan);
    final states = await _classifyDestinations(plan);
    if (states.any((state) => state == _DestinationState.diverged)) {
      throw const _PromotionRejected(
        'promotionOwnershipDiverged',
        'Une destination a divergé; le checkpoint est conservé sans réécriture.',
      );
    }
    await _ensureCheckpoint(plan, states);
    for (var index = plan.entries.length - 1; index >= 0; index--) {
      final entry = plan.entries[index];
      final destination = File(entry.destinationPath(repositoryRoot));
      final state = await _classifyDestination(entry);
      if (state == _DestinationState.before) {
        journal = journal.withFileState(index, 'restored');
        await _writeJournal(journal);
        continue;
      }
      if (entry.beforeExists) {
        final backup = File(_backupPath(entry));
        final backupBytes = await backup.readAsBytes();
        if (_fingerprint(backupBytes) != entry.beforeSha256) {
          throw _PromotionRejected(
            'promotionCheckpointDiverged',
            'Le checkpoint de ${entry.destination} a changé avant restauration.',
          );
        }
        if (await _classifyDestination(entry) != _DestinationState.after) {
          throw _PromotionRejected(
            'promotionDestinationChangedBeforeRestore',
            'La destination ${entry.destination} a changé avant restauration.',
          );
        }
        await _replaceAtomically(destination, backupBytes);
      } else {
        if (await _classifyDestination(entry) != _DestinationState.after) {
          throw _PromotionRejected(
            'promotionDestinationChangedBeforeRestore',
            'La destination ${entry.destination} a changé avant restauration.',
          );
        }
        await destination.delete();
      }
      if (await _classifyDestination(entry) != _DestinationState.before) {
        throw _PromotionRejected(
          'checkpointRestoreHashMismatch',
          'La restauration a échoué pour ${entry.destination}.',
        );
      }
      journal = journal.withFileState(index, 'restored');
      await _writeJournal(journal);
    }
    await _cleanupPromotionArtifacts(plan);
    return _result(
      JournaledFilePromotionStatus.restored,
      'promotionCheckpointRestored',
      'Le checkpoint pré-promotion a été restauré exactement.',
    );
  }

  Future<JournaledFilePromotionResult> _resume(
    _PromotionPlan plan,
    _PromotionJournal initialJournal,
  ) async {
    var journal = initialJournal;
    final initialStates = await _classifyDestinations(plan);
    if (initialStates.any((state) => state == _DestinationState.diverged)) {
      throw const _PromotionRejected(
        'promotionOwnershipDiverged',
        'Une destination a divergé; le journal est conservé sans réécriture.',
      );
    }
    await _ensureCheckpoint(plan, initialStates);
    if (initialStates.every((state) => state == _DestinationState.after)) {
      await _cleanupPromotionArtifacts(plan);
      return _result(
        JournaledFilePromotionStatus.promoted,
        'promotionRecovered',
        'La promotion déjà écrite a été vérifiée et finalisée.',
      );
    }
    for (var index = 0; index < plan.entries.length; index++) {
      final states = await _classifyDestinations(plan);
      if (states.any((state) => state == _DestinationState.diverged)) {
        throw const _PromotionRejected(
          'promotionOwnershipDiverged',
          'Une destination a changé pendant la reprise.',
        );
      }
      final entry = plan.entries[index];
      if (states[index] == _DestinationState.after) {
        journal = journal.withFileState(index, 'promoted');
        await _writeJournal(journal);
        continue;
      }
      final sourcePath = entry.sourcePath(plan.fixtureRoot);
      final source = File(sourcePath);
      final destination = File(entry.destinationPath(repositoryRoot));
      await beforeReplaceHook?.call(index, sourcePath, destination.path);
      final sourceBytes = await source.readAsBytes();
      if (_fingerprint(sourceBytes) != entry.afterSha256) {
        throw _PromotionRejected(
          'promotionSourceChangedBeforeWrite',
          'La source ${entry.source} a changé avant son écriture.',
        );
      }
      if (await _classifyDestination(entry) != _DestinationState.before) {
        throw _PromotionRejected(
          'promotionDestinationChangedBeforeWrite',
          'La destination ${entry.destination} a changé avant son écriture.',
        );
      }
      await _replaceAtomically(destination, sourceBytes);
      if (await _classifyDestination(entry) != _DestinationState.after) {
        throw _PromotionRejected(
          'promotedFileHashMismatch',
          'Le hash promu ne correspond pas pour ${entry.destination}.',
        );
      }
      await faultInjector?.call(index + 1);
      journal = journal.withFileState(index, 'promoted');
      await _writeJournal(journal);
    }
    await _cleanupPromotionArtifacts(plan);
    return _result(
      JournaledFilePromotionStatus.promoted,
      'promotionCommitted',
      'Les quatre fichiers Selbrume ont été promus et vérifiés.',
    );
  }

  _PromotionJournal _newPreparedJournal(_PromotionPlan plan) {
    return _PromotionJournal(
      manifestSha256: plan.manifestSha256,
      ownerFingerprint: plan.ownerFingerprint,
      state: 'prepared',
      files: <_PromotionJournalFile>[
        for (final entry in plan.entries)
          _PromotionJournalFile(
            destination: entry.destination,
            beforeSha256: entry.beforeSha256,
            afterSha256: entry.afterSha256,
            state: 'pending',
          ),
      ],
    );
  }

  Future<void> _prepareCheckpoint(_PromotionPlan plan) async {
    final checkpointDirectory = Directory(checkpointDirectoryPath);
    if (await checkpointDirectory.exists()) {
      await checkpointDirectory.delete(recursive: true);
    }
    await checkpointDirectory.create(recursive: true);
    for (var index = 0; index < plan.entries.length; index++) {
      final entry = plan.entries[index];
      final backup = File(_backupPath(entry));
      if (entry.beforeExists) {
        final destination = File(entry.destinationPath(repositoryRoot));
        final bytes = await destination.readAsBytes();
        if (_fingerprint(bytes) != entry.beforeSha256) {
          throw _PromotionRejected(
            'checkpointSourceChanged',
            'La destination ${entry.destination} a changé avant le checkpoint.',
          );
        }
        await _writeNewFile(backup, bytes);
        if (_fingerprint(await backup.readAsBytes()) != entry.beforeSha256) {
          throw _PromotionRejected(
            'checkpointHashMismatch',
            'Le checkpoint de ${entry.destination} est invalide.',
          );
        }
      }
      await checkpointFaultInjector?.call(index + 1);
    }
    await _validateCheckpoint(plan);
  }

  Future<void> _ensureCheckpoint(
    _PromotionPlan plan,
    List<_DestinationState> states,
  ) async {
    try {
      await _validateCheckpoint(plan);
    } on _PromotionRejected {
      if (states.asMap().entries.any(
            (state) =>
                !_isBeforeCompatible(plan.entries[state.key], state.value),
          )) {
        rethrow;
      }
      await _prepareCheckpoint(plan);
    }
  }

  bool _isBeforeCompatible(
    _PromotionEntry entry,
    _DestinationState state,
  ) {
    return state == _DestinationState.before ||
        (state == _DestinationState.after &&
            entry.beforeExists &&
            entry.beforeSha256 == entry.afterSha256);
  }

  Future<void> _validateCheckpoint(_PromotionPlan plan) async {
    for (final entry in plan.entries.where((entry) => entry.beforeExists)) {
      final backup = File(_backupPath(entry));
      if (!await backup.exists() ||
          _fingerprint(await backup.readAsBytes()) != entry.beforeSha256) {
        throw _PromotionRejected(
          'promotionCheckpointDiverged',
          'Le checkpoint de ${entry.destination} est absent ou divergent.',
        );
      }
    }
  }

  Future<List<_DestinationState>> _classifyDestinations(
    _PromotionPlan plan,
  ) async {
    return Future.wait(plan.entries.map(_classifyDestination));
  }

  Future<_DestinationState> _classifyDestination(
    _PromotionEntry entry,
  ) async {
    final destinationPath = entry.destinationPath(repositoryRoot);
    await _assertSafePath(repositoryRoot, destinationPath);
    final file = File(destinationPath);
    if (!await file.exists()) {
      return entry.beforeExists
          ? _DestinationState.diverged
          : _DestinationState.before;
    }
    final hash = _fingerprint(await file.readAsBytes());
    if (hash == entry.afterSha256) return _DestinationState.after;
    if (entry.beforeExists && hash == entry.beforeSha256) {
      return _DestinationState.before;
    }
    return _DestinationState.diverged;
  }

  Future<_PromotionPlan> _loadPlan() async {
    await _assertSafePath(p.dirname(manifestPath), manifestPath);
    final manifestFile = File(manifestPath);
    final manifestBytes = await manifestFile.readAsBytes();
    final root = _jsonObject(jsonDecode(utf8.decode(manifestBytes)));
    if (root['schemaVersion'] != 1 || root['state'] != 'frozenForJ5') {
      throw const _PromotionRejected(
        'promotionManifestNotFrozen',
        'Le manifeste J4 n’est pas figé pour J5.',
      );
    }
    final rawEntries = _jsonObjects(root['orderedFiles']);
    final entries = <_PromotionEntry>[];
    for (final raw in rawEntries) {
      final order = raw['order'];
      final source = raw['source'];
      final destination = raw['destination'];
      final beforeExists = raw['beforeExists'];
      final beforeSha256 = raw['beforeSha256'];
      final afterSha256 = raw['afterSha256'] ?? raw['sha256'];
      if (order is! int ||
          source is! String ||
          destination is! String ||
          beforeExists is! bool ||
          (beforeSha256 != null && beforeSha256 is! String) ||
          afterSha256 is! String) {
        throw const _PromotionRejected(
          'invalidPromotionManifest',
          'Une entrée du manifeste de promotion est invalide.',
        );
      }
      entries.add(
        _PromotionEntry(
          order: order,
          source: _normalizeRelative(source),
          destination: _normalizeRelative(destination),
          beforeExists: beforeExists,
          beforeSha256: beforeSha256 as String?,
          afterSha256: afterSha256,
        ),
      );
    }
    entries.sort((a, b) => a.order.compareTo(b.order));
    if (entries.length != allowedDestinations.length ||
        entries.asMap().entries.any(
              (entry) => entry.value.order != entry.key + 1,
            ) ||
        entries.map((entry) => entry.destination).toSet().length !=
            entries.length ||
        entries
            .map((entry) => entry.destination)
            .toSet()
            .difference(
              allowedDestinations,
            )
            .isNotEmpty ||
        allowedDestinations
            .difference(
              entries.map((entry) => entry.destination).toSet(),
            )
            .isNotEmpty) {
      throw const _PromotionRejected(
        'promotionScopeMismatch',
        'Le manifeste ne correspond pas exactement aux destinations autorisées.',
      );
    }
    final fixtureRoot = p.dirname(manifestPath);
    for (final entry in entries) {
      final sourcePath = entry.sourcePath(fixtureRoot);
      await _assertSafePath(fixtureRoot, sourcePath);
      if (await FileSystemEntity.type(sourcePath, followLinks: false) !=
          FileSystemEntityType.file) {
        throw _PromotionRejected(
          'promotionSourceNotRegularFile',
          'La source ${entry.source} n’est pas un fichier régulier.',
        );
      }
      if (_fingerprint(await File(sourcePath).readAsBytes()) !=
          entry.afterSha256) {
        throw _PromotionRejected(
          'promotionSourceHashMismatch',
          'La source ${entry.source} ne correspond pas au manifeste.',
        );
      }
      if (entry.beforeExists != (entry.beforeSha256 != null)) {
        throw _PromotionRejected(
          'invalidBeforeRevision',
          'La révision initiale de ${entry.destination} est incohérente.',
        );
      }
    }
    final manifestSha256 = _fingerprint(manifestBytes);
    final ownerFingerprint = _fingerprint(
      utf8.encode(
        jsonEncode(<Object?>[
          manifestSha256,
          for (final entry in entries) entry.toJson(),
        ]),
      ),
    );
    return _PromotionPlan(
      fixtureRoot: fixtureRoot,
      manifestSha256: manifestSha256,
      ownerFingerprint: ownerFingerprint,
      entries: entries,
    );
  }

  Future<_PromotionJournal> _loadJournal(_PromotionPlan plan) async {
    await _assertSafePath(repositoryRoot, journalPath);
    final root = _jsonObject(
      jsonDecode(await File(journalPath).readAsString()),
    );
    final journal = _PromotionJournal.fromJson(root);
    if (journal.manifestSha256 != plan.manifestSha256 ||
        journal.ownerFingerprint != plan.ownerFingerprint ||
        journal.files.length != plan.entries.length ||
        journal.files.asMap().entries.any((entry) {
          final expected = plan.entries[entry.key];
          final actual = entry.value;
          return actual.destination != expected.destination ||
              actual.beforeSha256 != expected.beforeSha256 ||
              actual.afterSha256 != expected.afterSha256;
        })) {
      throw const _PromotionRejected(
        'promotionJournalOwnershipMismatch',
        'Le journal ne possède pas les preuves du manifeste courant.',
      );
    }
    return journal;
  }

  Future<void> _writeJournal(_PromotionJournal journal) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent(' ').convert(journal.toJson()),
    );
    await _replaceAtomically(File(journalPath), bytes);
  }

  Future<void> _cleanupPromotionArtifacts(_PromotionPlan plan) async {
    for (final entry in plan.entries) {
      final temp = File(_destinationTempPath(entry));
      if (await temp.exists()) await temp.delete();
    }
    final checkpoint = Directory(checkpointDirectoryPath);
    if (await checkpoint.exists()) await checkpoint.delete(recursive: true);
    final journal = File(journalPath);
    if (await journal.exists()) await journal.delete();
    final rewriteTemp = File('$journalPath.rewrite.tmp');
    if (await rewriteTemp.exists()) await rewriteTemp.delete();
  }

  String _backupPath(_PromotionEntry entry) {
    final prefix = entry.order.toString().padLeft(2, '0');
    return p.join(
      checkpointDirectoryPath,
      '$prefix-${p.basename(entry.destination)}.before',
    );
  }

  String _destinationTempPath(_PromotionEntry entry) {
    final destination = entry.destinationPath(repositoryRoot);
    return p.join(
      p.dirname(destination),
      '.${p.basename(destination)}.phase-j-promotion.tmp',
    );
  }

  Future<void> _replaceAtomically(File destination, List<int> bytes) async {
    await destination.parent.create(recursive: true);
    await _assertSafePath(repositoryRoot, destination.path);
    final tempPath = destination.path == journalPath
        ? '$journalPath.rewrite.tmp'
        : p.join(
            destination.parent.path,
            '.${p.basename(destination.path)}.phase-j-promotion.tmp',
          );
    await _assertSafePath(repositoryRoot, tempPath);
    final temp = File(tempPath);
    if (await temp.exists()) await temp.delete();
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(destination.path);
  }

  Future<void> _writeNewFile(File file, List<int> bytes) async {
    await file.parent.create(recursive: true);
    await _assertSafePath(repositoryRoot, file.path);
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw _PromotionRejected(
        'checkpointAlreadyExists',
        'Le checkpoint ${file.path} existe déjà.',
      );
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  JournaledFilePromotionResult _result(
    JournaledFilePromotionStatus status,
    String code,
    String message,
  ) {
    return JournaledFilePromotionResult(
      status: status,
      code: code,
      message: message,
      journalPath: journalPath,
    );
  }
}

enum _DestinationState { before, after, diverged }

final class _PromotionPlan {
  const _PromotionPlan({
    required this.fixtureRoot,
    required this.manifestSha256,
    required this.ownerFingerprint,
    required this.entries,
  });

  final String fixtureRoot;
  final String manifestSha256;
  final String ownerFingerprint;
  final List<_PromotionEntry> entries;
}

final class _PromotionEntry {
  const _PromotionEntry({
    required this.order,
    required this.source,
    required this.destination,
    required this.beforeExists,
    required this.beforeSha256,
    required this.afterSha256,
  });

  final int order;
  final String source;
  final String destination;
  final bool beforeExists;
  final String? beforeSha256;
  final String afterSha256;

  String sourcePath(String fixtureRoot) => p.join(fixtureRoot, source);
  String destinationPath(String repositoryRoot) =>
      p.join(repositoryRoot, destination);

  Map<String, Object?> toJson() => <String, Object?>{
        'order': order,
        'source': source,
        'destination': destination,
        'beforeExists': beforeExists,
        'beforeSha256': beforeSha256,
        'afterSha256': afterSha256,
      };
}

final class _PromotionJournal {
  const _PromotionJournal({
    required this.manifestSha256,
    required this.ownerFingerprint,
    required this.state,
    required this.files,
  });

  final String manifestSha256;
  final String ownerFingerprint;
  final String state;
  final List<_PromotionJournalFile> files;

  factory _PromotionJournal.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1 ||
        json['manifestSha256'] is! String ||
        json['ownerFingerprint'] is! String ||
        json['state'] is! String) {
      throw const _PromotionRejected(
        'invalidPromotionJournal',
        'Le journal de promotion est invalide.',
      );
    }
    return _PromotionJournal(
      manifestSha256: json['manifestSha256']! as String,
      ownerFingerprint: json['ownerFingerprint']! as String,
      state: json['state']! as String,
      files: _jsonObjects(json['files'])
          .map(_PromotionJournalFile.fromJson)
          .toList(growable: false),
    );
  }

  _PromotionJournal withFileState(int index, String nextState) {
    return _PromotionJournal(
      manifestSha256: manifestSha256,
      ownerFingerprint: ownerFingerprint,
      state: state,
      files: <_PromotionJournalFile>[
        for (var candidate = 0; candidate < files.length; candidate++)
          candidate == index
              ? files[candidate].withState(nextState)
              : files[candidate],
      ],
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'manifestSha256': manifestSha256,
        'ownerFingerprint': ownerFingerprint,
        'state': state,
        'files': files.map((entry) => entry.toJson()).toList(growable: false),
      };
}

final class _PromotionJournalFile {
  const _PromotionJournalFile({
    required this.destination,
    required this.beforeSha256,
    required this.afterSha256,
    required this.state,
  });

  final String destination;
  final String? beforeSha256;
  final String afterSha256;
  final String state;

  factory _PromotionJournalFile.fromJson(Map<String, Object?> json) {
    final destination = json['destination'];
    final beforeSha256 = json['beforeSha256'];
    final afterSha256 = json['afterSha256'];
    final state = json['state'];
    if (destination is! String ||
        (beforeSha256 != null && beforeSha256 is! String) ||
        afterSha256 is! String ||
        state is! String) {
      throw const _PromotionRejected(
        'invalidPromotionJournalFile',
        'Une entrée du journal de promotion est invalide.',
      );
    }
    return _PromotionJournalFile(
      destination: destination,
      beforeSha256: beforeSha256 as String?,
      afterSha256: afterSha256,
      state: state,
    );
  }

  _PromotionJournalFile withState(String nextState) => _PromotionJournalFile(
        destination: destination,
        beforeSha256: beforeSha256,
        afterSha256: afterSha256,
        state: nextState,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'destination': destination,
        'beforeSha256': beforeSha256,
        'afterSha256': afterSha256,
        'state': state,
      };
}

final class _PromotionRejected implements Exception {
  const _PromotionRejected(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

String _normalizeRelative(String value) {
  final portable = value.replaceAll('\\', '/');
  final normalized = p.posix.normalize(portable);
  if (p.posix.isAbsolute(normalized) ||
      normalized == '.' ||
      normalized == '..' ||
      normalized.startsWith('../')) {
    throw const _PromotionRejected(
      'unsafePromotionPath',
      'Le manifeste contient un chemin non relatif ou traversant.',
    );
  }
  return normalized;
}

Future<void> _assertSafePath(String root, String candidate) async {
  final normalizedRoot = p.normalize(p.absolute(root));
  final normalizedCandidate = p.normalize(p.absolute(candidate));
  if (normalizedCandidate != normalizedRoot &&
      !p.isWithin(normalizedRoot, normalizedCandidate)) {
    throw const _PromotionRejected(
      'unsafePromotionPath',
      'Un chemin de promotion sort de sa racine autorisée.',
    );
  }
  final relative = p.relative(normalizedCandidate, from: normalizedRoot);
  var cursor = normalizedRoot;
  for (final segment in p.split(relative)) {
    if (segment == '.') continue;
    cursor = p.join(cursor, segment);
    if (await FileSystemEntity.type(cursor, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const _PromotionRejected(
        'promotionSymlinkRefused',
        'Les liens symboliques sont refusés pendant la promotion.',
      );
    }
  }
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) {
    throw const _PromotionRejected(
      'invalidPromotionJson',
      'Un document de promotion n’est pas un objet JSON.',
    );
  }
  return value.cast<String, Object?>();
}

List<Map<String, Object?>> _jsonObjects(Object? value) {
  if (value is! List) {
    throw const _PromotionRejected(
      'invalidPromotionJsonList',
      'Une liste du document de promotion est invalide.',
    );
  }
  return value.map(_jsonObject).toList(growable: false);
}

String _fingerprint(List<int> bytes) => narrativeEventBytesFingerprint(bytes);
