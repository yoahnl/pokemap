import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../domain/models/map_document_persistence.dart';
import 'map_document_write_lock.dart';

enum AtomicMapDocumentWriteCheckpoint {
  afterInitialRead,
  afterTempFlushed,
  afterJournalPrepared,
  beforeSecondCompareAndSwap,
  afterMapRenamed,
  beforeCommitVerification,
}

final class AtomicMapDocumentWriteContext {
  const AtomicMapDocumentWriteContext({
    required this.targetPath,
    required this.tempPath,
    required this.journalPath,
    required this.beforeRevision,
    required this.expectedAfterRevision,
  });

  final String targetPath;
  final String tempPath;
  final String journalPath;
  final String? beforeRevision;
  final String expectedAfterRevision;
}

typedef AtomicMapDocumentFaultInjector = FutureOr<void> Function(
  AtomicMapDocumentWriteCheckpoint checkpoint,
  AtomicMapDocumentWriteContext context,
);

/// Fault-injection sentinel that models process termination.
///
/// Unlike ordinary injected failures, this deliberately leaves durable
/// artifacts in place so a subsequent repository instance exercises recovery.
final class AtomicMapDocumentSimulatedCrash implements Exception {
  const AtomicMapDocumentSimulatedCrash();
}

final class AtomicMapDocumentBytes {
  AtomicMapDocumentBytes({
    required List<int> bytes,
    required String revision,
  })  : bytes = List<int>.unmodifiable(bytes),
        revision = requireMapDocumentRevision(revision);

  final List<int> bytes;
  final String revision;
}

/// Single-map byte store with a recoverable prepared-write protocol.
///
/// The journal and flushed payload are siblings of the final map so the final
/// rename stays on one filesystem. Multi-file map + manifest atomicity is
/// intentionally outside this DS-03 boundary and belongs to DS-05.
final class AtomicMapDocumentPersistence {
  const AtomicMapDocumentPersistence({this.faultInjector});

  final AtomicMapDocumentFaultInjector? faultInjector;

  Future<AtomicMapDocumentBytes> read(String targetPath) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      return _readRequired(canonicalTargetPath);
    });
  }

  Future<String> replaceLatest(
    String targetPath,
    List<int> bytes,
  ) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      final currentRevision = await _currentRevision(canonicalTargetPath);
      final precondition = currentRevision == null
          ? const MapDocumentWritePrecondition.absent()
          : MapDocumentWritePrecondition.revision(currentRevision);
      return _writeLocked(
        canonicalTargetPath,
        bytes,
        precondition,
      );
    });
  }

  Future<String> write(
    String targetPath,
    List<int> bytes, {
    required MapDocumentWritePrecondition precondition,
  }) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      return _writeLocked(canonicalTargetPath, bytes, precondition);
    });
  }

  Future<void> deleteLatest(String targetPath) {
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      final file = File(canonicalTargetPath);
      if (await file.exists()) {
        await file.delete();
      }
    });
  }

  Future<void> delete(
    String targetPath, {
    required String expectedRevision,
  }) {
    final normalizedRevision = requireMapDocumentRevision(expectedRevision);
    return withMapDocumentWriteLock(targetPath, (canonicalTargetPath) async {
      await _recoverLocked(canonicalTargetPath);
      final currentRevision = await _currentRevision(canonicalTargetPath);
      if (currentRevision != normalizedRevision) {
        throw const EditorConflictException(
          'The map changed outside the editor before deletion.',
        );
      }
      final file = File(canonicalTargetPath);
      if (!await file.exists()) {
        throw const EditorConflictException(
          'The map disappeared before deletion.',
        );
      }
      await file.delete();
      if (await file.exists()) {
        throw const EditorPersistenceException(
          'The map remained visible after deletion.',
        );
      }
    });
  }

  Future<MapDocumentRecoveryResult> recover(String targetPath) {
    return withMapDocumentWriteLock(
      targetPath,
      _recoverLocked,
    );
  }

  Future<String> _writeLocked(
    String canonicalTargetPath,
    List<int> bytes,
    MapDocumentWritePrecondition precondition,
  ) async {
    final afterBytes = List<int>.unmodifiable(bytes);
    final afterRevision = narrativeEventBytesFingerprint(afterBytes);
    final paths = _artifactPaths(canonicalTargetPath);
    final beforeRevision = await _currentRevision(canonicalTargetPath);
    final context = AtomicMapDocumentWriteContext(
      targetPath: canonicalTargetPath,
      tempPath: paths.tempPath,
      journalPath: paths.journalPath,
      beforeRevision: beforeRevision,
      expectedAfterRevision: afterRevision,
    );
    await _checkpoint(
      AtomicMapDocumentWriteCheckpoint.afterInitialRead,
      context,
    );
    _requirePrecondition(precondition, beforeRevision);

    final tempFile = File(paths.tempPath);
    var renameVisible = false;
    try {
      await _writeFlushed(tempFile, afterBytes);
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.afterTempFlushed,
        context,
      );
      final tempRevision = narrativeEventBytesFingerprint(
        await tempFile.readAsBytes(),
      );
      if (tempRevision != afterRevision) {
        throw const EditorPersistenceException(
          'The flushed temporary map does not match the requested bytes.',
        );
      }

      final journal = _MapDocumentWriteJournal(
        targetPath: canonicalTargetPath,
        tempPath: paths.tempPath,
        expectedRevision: switch (precondition) {
          MapDocumentMustBeAbsent() => null,
          MapDocumentMustMatchRevision(:final revision) => revision,
        },
        expectAbsent: precondition is MapDocumentMustBeAbsent,
        afterRevision: afterRevision,
      );
      await _writeJournal(paths, journal);
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.afterJournalPrepared,
        context,
      );

      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.beforeSecondCompareAndSwap,
        context,
      );
      // Recheck immediately before rename. Cooperative writers are also held
      // by the shared OS lock; this second CAS catches non-cooperative changes
      // observed after the initial snapshot.
      _requirePrecondition(
        precondition,
        await _currentRevision(canonicalTargetPath),
      );

      await tempFile.rename(canonicalTargetPath);
      // From this point an exception is not automatically a failed save: the
      // new bytes may already be the visible committed document.
      renameVisible = true;
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.afterMapRenamed,
        context,
      );
      await _checkpoint(
        AtomicMapDocumentWriteCheckpoint.beforeCommitVerification,
        context,
      );
      final committedRevision = await _currentRevision(canonicalTargetPath);
      if (committedRevision != afterRevision) {
        throw const EditorPersistenceException(
          'The committed map revision cannot be verified.',
        );
      }
      await _cleanup(paths);
      return afterRevision;
    } on AtomicMapDocumentSimulatedCrash {
      rethrow;
    } on EditorConflictException {
      if (!renameVisible) await _cleanup(paths);
      rethrow;
    } on Object catch (error) {
      if (!renameVisible) {
        await _cleanup(paths);
        if (error is EditorPersistenceException) rethrow;
        throw EditorPersistenceException(
          'The map was not replaced atomically: $error',
        );
      }
      try {
        final committedRevision = await _currentRevision(canonicalTargetPath);
        if (committedRevision == afterRevision) {
          await _cleanup(paths);
          return afterRevision;
        }
      } on Object {
        // The journal remains the recovery evidence for an ambiguous commit.
      }
      throw EditorPersistenceException(
        'The map replacement is ambiguous and requires recovery: $error',
      );
    }
  }

  Future<MapDocumentRecoveryResult> _recoverLocked(
    String canonicalTargetPath,
  ) async {
    final paths = _artifactPaths(canonicalTargetPath);
    await _requireSafeArtifactType(paths.tempPath);
    await _requireSafeArtifactType(paths.journalPath);
    await _requireSafeArtifactType(paths.journalRewritePath);

    final journalFile = File(paths.journalPath);
    final tempFile = File(paths.tempPath);
    final rewriteFile = File(paths.journalRewritePath);
    final journalExists = await journalFile.exists();
    if (!journalExists) {
      // A payload without its flushed intent is never safe to promote.
      final discarded = await tempFile.exists() || await rewriteFile.exists();
      await _deleteIfExists(tempFile);
      await _deleteIfExists(rewriteFile);
      return MapDocumentRecoveryResult(
        status: discarded
            ? MapDocumentRecoveryStatus.discardedIncompleteWrite
            : MapDocumentRecoveryStatus.clear,
        targetPath: canonicalTargetPath,
        revision: await _currentRevision(canonicalTargetPath),
      );
    }

    late final _MapDocumentWriteJournal journal;
    try {
      journal = _MapDocumentWriteJournal.fromJson(
        jsonDecode(await journalFile.readAsString()),
      );
      journal.requireMatches(
        targetPath: canonicalTargetPath,
        tempPath: paths.tempPath,
      );
    } on Object catch (error) {
      throw EditorConflictException(
        'Map recovery is blocked by an invalid write journal: $error',
      );
    }
    await _deleteIfExists(rewriteFile);

    final currentRevision = await _currentRevision(canonicalTargetPath);
    if (currentRevision == journal.afterRevision) {
      // The rename committed before interruption; recovery only removes the
      // stable evidence files and never rewrites the final map.
      await _cleanup(paths);
      return MapDocumentRecoveryResult(
        status: MapDocumentRecoveryStatus.cleanedCommittedWrite,
        targetPath: canonicalTargetPath,
        revision: currentRevision,
      );
    }

    if (!await tempFile.exists()) {
      if (journal.matchesBefore(currentRevision)) {
        await _cleanup(paths);
        return MapDocumentRecoveryResult(
          status: MapDocumentRecoveryStatus.discardedIncompleteWrite,
          targetPath: canonicalTargetPath,
          revision: currentRevision,
        );
      }
      throw const EditorConflictException(
        'Map recovery is blocked because the target changed and the prepared '
        'temporary map is missing.',
      );
    }

    final tempRevision = narrativeEventBytesFingerprint(
      await tempFile.readAsBytes(),
    );
    if (tempRevision != journal.afterRevision) {
      throw const EditorConflictException(
        'Map recovery is blocked because the prepared temporary map is '
        'corrupted.',
      );
    }
    if (!journal.matchesBefore(currentRevision)) {
      throw const EditorConflictException(
        'Map recovery is blocked because the target changed after the '
        'interrupted write.',
      );
    }

    await tempFile.rename(canonicalTargetPath);
    final recoveredRevision = await _currentRevision(canonicalTargetPath);
    if (recoveredRevision != journal.afterRevision) {
      throw const EditorConflictException(
        'Map recovery renamed the temporary file but could not verify it.',
      );
    }
    await _cleanup(paths);
    return MapDocumentRecoveryResult(
      status: MapDocumentRecoveryStatus.completedInterruptedWrite,
      targetPath: canonicalTargetPath,
      revision: recoveredRevision,
    );
  }

  Future<void> _checkpoint(
    AtomicMapDocumentWriteCheckpoint checkpoint,
    AtomicMapDocumentWriteContext context,
  ) async {
    await faultInjector?.call(checkpoint, context);
  }
}

final class _MapDocumentWriteJournal {
  const _MapDocumentWriteJournal({
    this.schemaVersion = 1,
    required this.targetPath,
    required this.tempPath,
    required this.expectedRevision,
    required this.expectAbsent,
    required this.afterRevision,
  });

  factory _MapDocumentWriteJournal.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Map write journal must be an object.');
    }
    final json = <String, Object?>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    if (json.length != value.length) {
      throw const FormatException('Map write journal keys must be strings.');
    }
    final schemaVersion = json['schemaVersion'];
    final targetPath = json['targetPath'];
    final tempPath = json['tempPath'];
    final expectedRevision = json['expectedRevision'];
    final expectAbsent = json['expectAbsent'];
    final afterRevision = json['afterRevision'];
    if (schemaVersion != 1 ||
        targetPath is! String ||
        tempPath is! String ||
        expectAbsent is! bool ||
        afterRevision is! String ||
        (expectedRevision != null && expectedRevision is! String)) {
      throw const FormatException('Map write journal fields are invalid.');
    }
    return _MapDocumentWriteJournal(
      schemaVersion: schemaVersion as int,
      targetPath: targetPath,
      tempPath: tempPath,
      expectedRevision: expectedRevision as String?,
      expectAbsent: expectAbsent,
      afterRevision: requireMapDocumentRevision(afterRevision),
    );
  }

  final int schemaVersion;
  final String targetPath;
  final String tempPath;
  final String? expectedRevision;
  final bool expectAbsent;
  final String afterRevision;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'targetPath': targetPath,
        'tempPath': tempPath,
        'expectedRevision': expectedRevision,
        'expectAbsent': expectAbsent,
        'afterRevision': afterRevision,
      };

  void requireMatches({
    required String targetPath,
    required String tempPath,
  }) {
    if (p.normalize(this.targetPath) != p.normalize(targetPath) ||
        p.normalize(this.tempPath) != p.normalize(tempPath) ||
        expectAbsent == (expectedRevision != null)) {
      throw const FormatException(
        'Map write journal does not match its target artifacts.',
      );
    }
    if (expectedRevision != null) {
      requireMapDocumentRevision(expectedRevision!);
    }
  }

  bool matchesBefore(String? currentRevision) {
    if (expectAbsent) return currentRevision == null;
    return currentRevision == expectedRevision;
  }
}

typedef _MapDocumentArtifactPaths = ({
  String tempPath,
  String journalPath,
  String journalRewritePath,
});

_MapDocumentArtifactPaths _artifactPaths(String canonicalTargetPath) {
  final identity = narrativeEventBytesFingerprint(
    utf8.encode(p.normalize(canonicalTargetPath)),
  ).substring(7, 31);
  final prefix = p.join(
    p.dirname(canonicalTargetPath),
    '.pokemap-map-$identity',
  );
  return (
    tempPath: '$prefix.after.tmp',
    journalPath: '$prefix.journal.json',
    journalRewritePath: '$prefix.journal.rewrite.tmp',
  );
}

Future<void> _writeJournal(
  _MapDocumentArtifactPaths paths,
  _MapDocumentWriteJournal journal,
) async {
  final bytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(journal.toJson()),
  );
  final rewrite = File(paths.journalRewritePath);
  await _writeFlushed(rewrite, bytes);
  await rewrite.rename(paths.journalPath);
}

Future<void> _writeFlushed(File file, List<int> bytes) async {
  await file.parent.create(recursive: true);
  final handle = await file.open(mode: FileMode.write);
  try {
    await handle.writeFrom(bytes);
    await handle.flush();
  } finally {
    await handle.close();
  }
}

Future<AtomicMapDocumentBytes> _readRequired(String targetPath) async {
  final file = File(targetPath);
  if (!await file.exists()) {
    throw EditorNotFoundException('Map file not found: $targetPath');
  }
  final bytes = await file.readAsBytes();
  return AtomicMapDocumentBytes(
    bytes: bytes,
    revision: narrativeEventBytesFingerprint(bytes),
  );
}

Future<String?> _currentRevision(String targetPath) async {
  final type = await FileSystemEntity.type(targetPath, followLinks: false);
  if (type == FileSystemEntityType.notFound) return null;
  if (type != FileSystemEntityType.file) {
    throw EditorConflictException(
      'The map target is no longer a regular file: $targetPath',
    );
  }
  return narrativeEventBytesFingerprint(
    await File(targetPath).readAsBytes(),
  );
}

void _requirePrecondition(
  MapDocumentWritePrecondition precondition,
  String? currentRevision,
) {
  switch (precondition) {
    case MapDocumentMustBeAbsent():
      if (currentRevision != null) {
        throw const EditorConflictException(
          'A map already exists at the requested path.',
        );
      }
    case MapDocumentMustMatchRevision(:final revision):
      if (currentRevision != revision) {
        throw const EditorConflictException(
          'The map changed outside the editor.',
        );
      }
  }
}

Future<void> _requireSafeArtifactType(String path) async {
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.notFound ||
      type == FileSystemEntityType.file) {
    return;
  }
  throw EditorConflictException(
    'Map recovery artifact is not a regular file: $path',
  );
}

Future<void> _cleanup(_MapDocumentArtifactPaths paths) async {
  await _deleteIfExists(File(paths.tempPath));
  await _deleteIfExists(File(paths.journalRewritePath));
  await _deleteIfExists(File(paths.journalPath));
}

Future<void> _deleteIfExists(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Cleanup remains retryable because target-addressed artifacts are stable.
  }
}
