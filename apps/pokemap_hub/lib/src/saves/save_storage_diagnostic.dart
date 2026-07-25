import 'package:map_core/map_core.dart';

enum SaveStorageErrorCode {
  outOfScope,
  pathEscapesRoot,
  invalidEnvelope,
  ioFailure,
  writeInterrupted,
  snapshotMissing,
}

final class SaveStorageException implements Exception {
  const SaveStorageException(this.code, this.message, {this.cause});

  final SaveStorageErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'SaveStorageException(${code.name}): $message';
}

enum SaveStorageDiagnosticCode {
  primaryCorrupt,
  backupUsed,
  saveGameMismatch,
  saveCompatibilityMismatch,
  saveFormatFuture,
  saveMigrationRequired,
  saveMigrationUnavailable,
  missing,
}

final class SaveStorageDiagnostic {
  const SaveStorageDiagnostic(this.code, this.message);

  final SaveStorageDiagnosticCode code;
  final String message;
}

enum SaveSlotReadStatus {
  valid,
  recoveredFromBackup,
  migrationRequired,
  incompatible,
  corrupt,
  missing,
}

enum SaveSlotSource { current, backup, pendingBackup }

final class SaveSlotRead {
  const SaveSlotRead({
    required this.address,
    required this.status,
    required this.diagnostics,
    this.envelope,
    this.source,
  });

  final SaveSlotAddress address;
  final SaveSlotReadStatus status;
  final SaveEnvelope? envelope;
  final SaveSlotSource? source;
  final List<SaveStorageDiagnostic> diagnostics;

  bool get canContinue =>
      status == SaveSlotReadStatus.valid ||
      status == SaveSlotReadStatus.recoveredFromBackup;
}

final class SaveSlotSummary {
  const SaveSlotSummary({
    required this.address,
    required this.status,
    required this.updatedAt,
    required this.playTimeSeconds,
  });

  final SaveSlotAddress address;
  final SaveSlotReadStatus status;
  final DateTime? updatedAt;
  final int? playTimeSeconds;
}
