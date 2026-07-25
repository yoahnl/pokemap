import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'hub_save_store.dart';
import 'save_storage_diagnostic.dart';

enum LegacySaveImportErrorCode {
  sourceMissing,
  sourceTooLarge,
  invalidLegacySave,
  confirmationRequired,
  overwriteConfirmationRequired,
  sourceChanged,
}

final class LegacySaveImportException implements Exception {
  const LegacySaveImportException(this.code, this.message, {this.cause});

  final LegacySaveImportErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'LegacySaveImportException(${code.name}): $message';
}

typedef LegacySaveStateDecoder = Map<String, Object?> Function(
  Map<String, Object?> legacyJson,
);

final class LegacySavePreview {
  const LegacySavePreview._({
    required this.sourceFile,
    required this.sourceBytes,
    required this.sourceSha256,
    required this.state,
  });

  final File sourceFile;
  final int sourceBytes;
  final String sourceSha256;
  final Map<String, Object?> state;
}

/// Explicit import assistant for the historical global game_save.json.
///
/// It never infers a game identity and never moves or edits the source file.
final class LegacyGlobalSaveImporter {
  const LegacyGlobalSaveImporter({
    required this.store,
    this.maxSourceBytes = 64 * 1024 * 1024,
  });

  final HubSaveStore store;
  final int maxSourceBytes;

  Future<LegacySavePreview> inspect({
    required File sourceFile,
    required LegacySaveStateDecoder decoder,
  }) async {
    if (!await sourceFile.exists()) {
      throw const LegacySaveImportException(
        LegacySaveImportErrorCode.sourceMissing,
        'The selected historical save does not exist.',
      );
    }
    final length = await sourceFile.length();
    if (length > maxSourceBytes) {
      throw LegacySaveImportException(
        LegacySaveImportErrorCode.sourceTooLarge,
        'Historical save exceeds the $maxSourceBytes byte limit.',
      );
    }
    try {
      final bytes = await sourceFile.readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Legacy save root must be an object.');
      }
      final projected = decoder(decoded);
      final detached = jsonDecode(jsonEncode(projected));
      if (detached is! Map<String, dynamic>) {
        throw const FormatException('Imported state must remain an object.');
      }
      return LegacySavePreview._(
        sourceFile: sourceFile,
        sourceBytes: bytes.length,
        sourceSha256: sha256.convert(bytes).toString(),
        state: Map<String, Object?>.unmodifiable(detached),
      );
    } catch (error) {
      if (error is LegacySaveImportException) rethrow;
      throw LegacySaveImportException(
        LegacySaveImportErrorCode.invalidLegacySave,
        'Historical save could not be decoded safely.',
        cause: error,
      );
    }
  }

  Future<SaveEnvelope> import({
    required LegacySavePreview preview,
    required SaveSlotAddress address,
    required String saveId,
    required DateTime importedAt,
    required bool confirmed,
    bool overwriteConfirmed = false,
  }) async {
    if (!confirmed) {
      throw const LegacySaveImportException(
        LegacySaveImportErrorCode.confirmationRequired,
        'Legacy import requires an explicit preview confirmation.',
      );
    }
    final currentBytes = await preview.sourceFile.readAsBytes();
    if (currentBytes.length != preview.sourceBytes ||
        sha256.convert(currentBytes).toString() != preview.sourceSha256) {
      throw const LegacySaveImportException(
        LegacySaveImportErrorCode.sourceChanged,
        'Historical save changed after preview; inspect it again.',
      );
    }
    final existing = await store.read(address);
    if (existing.status != SaveSlotReadStatus.missing && !overwriteConfirmed) {
      throw const LegacySaveImportException(
        LegacySaveImportErrorCode.overwriteConfirmationRequired,
        'The target slot is not empty and needs separate confirmation.',
      );
    }
    final envelope = store.codec.create(
      identity: store.identity,
      profileId: address.profileId,
      slotId: address.slotId,
      saveId: saveId,
      createdAt: importedAt,
      updatedAt: importedAt,
      status: SaveStatus.active,
      playTimeSeconds: 0,
      state: preview.state,
      origin: SaveOrigin(
        kind: SaveOriginKind.legacyGlobalSave,
        importedAt: importedAt,
      ),
    );
    try {
      await store.write(envelope);
      return envelope;
    } on SaveStorageException catch (error) {
      throw LegacySaveImportException(
        LegacySaveImportErrorCode.invalidLegacySave,
        'Historical save could not be committed to the selected slot.',
        cause: error,
      );
    }
  }
}
