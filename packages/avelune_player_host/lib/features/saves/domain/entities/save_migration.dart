import 'dart:io';

import 'package:map_core/map_core.dart';

/// Migration contract types.
///
/// `dart:io` here is an accepted exception: a migration snapshot IS a set of
/// files on disk, and abstracting it behind a byte port would change what the
/// rollback restores. Allowlisted in the lot 23 dependency guards.
final class SaveMigrationSnapshot {
  /// Was a library-private constructor; the type now lives in `domain/` while
  /// the store that captures it stays in `data/`, so it has to be reachable.
  const SaveMigrationSnapshot({
    required this.address,
    required this.sourceGameVersion,
    required this.sourceSaveId,
    required this.primaryFile,
    required this.backupFile,
  });

  final SaveSlotAddress address;
  final String sourceGameVersion;
  final String sourceSaveId;
  final File primaryFile;
  final File backupFile;
}

final class SaveMigrationResult {
  const SaveMigrationResult({
    required this.envelope,
    required this.snapshot,
  });

  final SaveEnvelope envelope;
  final SaveMigrationSnapshot snapshot;
}

/// App-private, game-scoped save storage rooted under PokeMap support data.
