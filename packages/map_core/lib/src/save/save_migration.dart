import 'dart:convert';

import 'game_identity.dart';
import 'save_envelope.dart';
import 'save_envelope_codec.dart';

enum SaveMigrationErrorCode {
  chainUnavailable,
  identityMismatch,
  invalidTimeline,
  invalidSource,
  migrationFailed,
}

final class SaveMigrationException implements Exception {
  const SaveMigrationException(this.code, this.message, {this.cause});

  final SaveMigrationErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'SaveMigrationException(${code.name}): $message';
}

typedef SaveStateMigrationCallback = Map<String, Object?> Function(
  Map<String, Object?> state,
);

/// A trusted engine migration. Packages cannot register these callbacks.
final class SaveStateMigration {
  SaveStateMigration({
    required this.fromFormat,
    required this.toFormat,
    required this.migrate,
  }) {
    if (fromFormat < 0 || toFormat != fromFormat + 1) {
      throw ArgumentError(
        'Save migrations must be a non-negative N -> N+1 step.',
      );
    }
  }

  final int fromFormat;
  final int toFormat;
  final SaveStateMigrationCallback migrate;
}

/// Applies a trusted migration chain to a detached state copy.
final class SaveMigrationEngine {
  SaveMigrationEngine({
    required Iterable<SaveStateMigration> migrations,
    this.codec = const SaveEnvelopeCodec(),
  }) : _migrations = <int, SaveStateMigration>{
          for (final migration in migrations) migration.fromFormat: migration,
        } {
    if (_migrations.length != migrations.length) {
      throw ArgumentError('Only one migration may start at each save format.');
    }
  }

  final Map<int, SaveStateMigration> _migrations;
  final SaveEnvelopeCodec codec;

  bool hasChain({required int fromFormat, required int toFormat}) {
    if (fromFormat > toFormat) return false;
    var current = fromFormat;
    while (current < toFormat) {
      final step = _migrations[current];
      if (step == null || step.toFormat != current + 1) return false;
      current = step.toFormat;
    }
    return true;
  }

  SaveEnvelope migrate({
    required SaveEnvelope source,
    required GameIdentity targetIdentity,
    required String newSaveId,
    required DateTime updatedAt,
  }) {
    if (!codec.verifyChecksum(source)) {
      throw const SaveMigrationException(
        SaveMigrationErrorCode.invalidSource,
        'Migration source checksum is invalid.',
      );
    }
    if (source.gameId != targetIdentity.gameId ||
        source.compatibilityId != targetIdentity.compatibilityId) {
      throw const SaveMigrationException(
        SaveMigrationErrorCode.identityMismatch,
        'Migration target must keep gameId and compatibilityId.',
      );
    }
    if (!updatedAt.isUtc || !updatedAt.isAfter(source.updatedAt)) {
      throw const SaveMigrationException(
        SaveMigrationErrorCode.invalidTimeline,
        'A migration must advance updatedAt with an explicit UTC timestamp.',
      );
    }
    if (!hasChain(
      fromFormat: source.saveFormat,
      toFormat: targetIdentity.saveFormat,
    )) {
      throw SaveMigrationException(
        SaveMigrationErrorCode.chainUnavailable,
        'No complete migration chain from ${source.saveFormat} '
        'to ${targetIdentity.saveFormat}.',
      );
    }

    var currentFormat = source.saveFormat;
    var migratedState = _copyState(source.state);
    try {
      while (currentFormat < targetIdentity.saveFormat) {
        final migration = _migrations[currentFormat]!;
        migratedState = migration.migrate(_copyState(migratedState));
        migratedState = _copyState(migratedState);
        currentFormat = migration.toFormat;
      }
      return codec.create(
        identity: targetIdentity,
        profileId: source.profileId,
        slotId: source.slotId,
        saveId: newSaveId,
        createdAt: source.createdAt,
        updatedAt: updatedAt,
        status: source.status,
        completedAt: source.completedAt,
        playTimeSeconds: source.playTimeSeconds,
        origin: source.origin,
        state: migratedState,
      );
    } on SaveMigrationException {
      rethrow;
    } catch (error) {
      throw SaveMigrationException(
        SaveMigrationErrorCode.migrationFailed,
        'Save migration failed at format $currentFormat.',
        cause: error,
      );
    }
  }
}

Map<String, Object?> _copyState(Map<String, Object?> state) {
  final decoded = jsonDecode(jsonEncode(state));
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Migrated save state must remain an object.');
  }
  return decoded;
}
