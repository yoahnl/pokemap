import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../support/authoring_fingerprint.dart';

abstract interface class ProjectManifestBootstrapWriter {
  Future<void> replaceManifest({
    required String projectRoot,
    required List<int> expectedBytes,
    required List<int> replacementBytes,
  });
}

final class ProjectManifestBootstrapWriteException implements Exception {
  const ProjectManifestBootstrapWriteException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'ProjectManifestBootstrapWriteException($code): $message';
}

final class LocalProjectManifestBootstrapWriter
    implements ProjectManifestBootstrapWriter {
  const LocalProjectManifestBootstrapWriter();

  @override
  Future<void> replaceManifest({
    required String projectRoot,
    required List<int> expectedBytes,
    required List<int> replacementBytes,
  }) async {
    RandomAccessFile? lock;
    File? temporary;
    try {
      final canonicalRoot = await Directory(projectRoot).resolveSymbolicLinks();
      final manifest = File('$canonicalRoot/project.json');
      final qualifiedManifest = await manifest.resolveSymbolicLinks();
      final pathHash = narrativeEventBytesFingerprint(
        utf8.encode(qualifiedManifest),
      ).substring(7, 23);
      final internal = Directory('$canonicalRoot/.pokemap');
      await internal.create(recursive: true);
      lock = await File('$canonicalRoot/.pokemap-project-$pathHash.lock').open(
        mode: FileMode.append,
      );
      await lock.lock(FileLock.exclusive);
      final currentBytes = await manifest.readAsBytes();
      if (!_bytesEqual(currentBytes, expectedBytes)) {
        throw const ProjectManifestBootstrapWriteException(
          'project.ruleset_repair_revision_conflict',
          'The project manifest changed after the repair preview.',
        );
      }
      final revision = computeAuthoringBytesFingerprint(
        expectedBytes,
        logicalName: 'project.json',
      ).substring('sha256:'.length);
      final backups = Directory('${internal.path}/backups');
      await backups.create(recursive: true);
      final backup = File('${backups.path}/project-$revision.json');
      if (!await backup.exists()) {
        final stagedBackup = File('${backup.path}.tmp');
        await stagedBackup.writeAsBytes(expectedBytes, flush: true);
        await stagedBackup.rename(backup.path);
      }
      temporary = File(
        '$canonicalRoot/.project.json.ruleset-${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      await temporary.writeAsBytes(replacementBytes, flush: true);
      await temporary.rename(manifest.path);
      temporary = null;
    } on ProjectManifestBootstrapWriteException {
      rethrow;
    } on Object {
      throw const ProjectManifestBootstrapWriteException(
        'project.ruleset_repair_io',
        'The project manifest repair failed safely.',
      );
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (lock != null) {
        try {
          await lock.unlock();
        } on Object catch (error) {
          _ignoreUnlockFailure(error);
        }
        await lock.close();
      }
    }
  }
}

void _ignoreUnlockFailure(Object _) {}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
