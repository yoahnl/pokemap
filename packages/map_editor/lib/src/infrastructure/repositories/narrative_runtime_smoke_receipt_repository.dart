import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

enum NarrativeRuntimeReceiptState {
  freshPass,
  freshFail,
  absent,
  stale,
  profileMismatch,
  incompleteSuites,
  invalid,
}

final class NarrativeRuntimeSmokeReceiptResolution {
  const NarrativeRuntimeSmokeReceiptResolution({
    required this.state,
    required this.reason,
    this.receipt,
  });

  final NarrativeRuntimeReceiptState state;
  final String reason;
  final NarrativeRuntimeSmokeReceipt? receipt;

  NarrativeValidationStatus get validationStatus => switch (state) {
        NarrativeRuntimeReceiptState.freshPass =>
          NarrativeValidationStatus.pass,
        NarrativeRuntimeReceiptState.freshFail =>
          NarrativeValidationStatus.fail,
        NarrativeRuntimeReceiptState.absent ||
        NarrativeRuntimeReceiptState.stale ||
        NarrativeRuntimeReceiptState.profileMismatch ||
        NarrativeRuntimeReceiptState.incompleteSuites ||
        NarrativeRuntimeReceiptState.invalid =>
          NarrativeValidationStatus.notRun,
      };
}

final class NarrativeRuntimeSmokeReceiptRepository {
  const NarrativeRuntimeSmokeReceiptRepository();

  static const relativeReceiptPath =
      '.pokemap/validation/narrative_runtime_smoke_receipt.json';

  Future<String> computeProjectFingerprint(String projectRoot) async {
    final root = Directory(p.normalize(p.absolute(projectRoot)));
    if (!await root.exists()) {
      throw FileSystemException('Project root does not exist.', root.path);
    }
    final files = <({File file, String relativePath})>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.posix.normalize(
        p.relative(entity.path, from: root.path).replaceAll('\\', '/'),
      );
      if (_ignoredFingerprintPath(relative)) continue;
      files.add((file: entity, relativePath: relative));
    }
    files.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    final builder = NarrativeProjectFingerprintBuilder();
    for (final entry in files) {
      final handle = await entry.file.open();
      try {
        final byteLength = await handle.length();
        builder.startEntry(
          relativePath: entry.relativePath,
          byteLength: byteLength,
        );
        var bytesRead = 0;
        while (bytesRead < byteLength) {
          final remaining = byteLength - bytesRead;
          final chunk = await handle.read(
            remaining < _fingerprintChunkSize
                ? remaining
                : _fingerprintChunkSize,
          );
          if (chunk.isEmpty) {
            throw FileSystemException(
              'Project file changed while its fingerprint was computed.',
              entry.file.path,
            );
          }
          builder.addBytes(chunk);
          bytesRead += chunk.length;
        }
        if (await handle.length() != byteLength) {
          throw FileSystemException(
            'Project file changed while its fingerprint was computed.',
            entry.file.path,
          );
        }
        builder.endEntry();
      } finally {
        await handle.close();
      }
    }
    return builder.close();
  }

  Future<NarrativeRuntimeSmokeReceiptResolution> read({
    required String projectRoot,
    required String expectedFingerprint,
    required NarrativeRuntimeSmokeProfile profile,
  }) async {
    final file = File(p.join(projectRoot, relativeReceiptPath));
    if (!await file.exists()) {
      return const NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.absent,
        reason: 'Aucun smoke runtime n’a été exécuté pour ce snapshot.',
      );
    }
    NarrativeRuntimeSmokeReceipt receipt;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Receipt must be an object.');
      }
      receipt = NarrativeRuntimeSmokeReceipt.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on Object catch (error) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.invalid,
        reason: 'Le receipt runtime est invalide : $error',
      );
    }
    if (receipt.projectFingerprint != expectedFingerprint) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.stale,
        reason: 'Le receipt appartient à un ancien snapshot du projet.',
        receipt: receipt,
      );
    }
    if (receipt.profileId != profile.id ||
        receipt.profileVersion != profile.version) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.profileMismatch,
        reason: 'Le receipt ne correspond pas au profil ${profile.id}.',
        receipt: receipt,
      );
    }
    if (!profile.acceptsSuites(receipt.suiteIds)) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.incompleteSuites,
        reason: 'Le receipt ne couvre pas toutes les suites obligatoires.',
        receipt: receipt,
      );
    }
    return NarrativeRuntimeSmokeReceiptResolution(
      state: receipt.result == NarrativeRuntimeSmokeResult.pass
          ? NarrativeRuntimeReceiptState.freshPass
          : NarrativeRuntimeReceiptState.freshFail,
      reason: receipt.result == NarrativeRuntimeSmokeResult.pass
          ? 'Smoke runtime frais et complet.'
          : 'Le smoke runtime frais a échoué.',
      receipt: receipt,
    );
  }
}

const _fingerprintChunkSize = 64 * 1024;

bool _ignoredFingerprintPath(String relativePath) {
  return relativePath ==
          NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath ||
      relativePath.startsWith('.pokemap/validation/') ||
      relativePath.endsWith('.tmp') ||
      relativePath == '.DS_Store';
}
