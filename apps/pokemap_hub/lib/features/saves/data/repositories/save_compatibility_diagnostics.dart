import 'package:map_core/map_core.dart';

import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';

/// Maps a compatibility verdict onto the diagnostic the player is shown.
SaveStorageDiagnostic compatibilityDiagnostic(
  SaveCompatibilityCode code,
) =>
    switch (code) {
      SaveCompatibilityCode.saveGameMismatch => const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveGameMismatch,
          'Save belongs to another game.',
        ),
      SaveCompatibilityCode.saveCompatibilityMismatch =>
        const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveCompatibilityMismatch,
          'Save compatibility identifier does not match this game.',
        ),
      SaveCompatibilityCode.saveFormatFuture => const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveFormatFuture,
          'Save was written by a future unsupported format.',
        ),
      SaveCompatibilityCode.saveMigrationRequired =>
        const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationRequired,
          'Save requires migration.',
        ),
      SaveCompatibilityCode.saveMigrationUnavailable =>
        const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationUnavailable,
          'No migration chain is available for this save.',
        ),
      SaveCompatibilityCode.migrationFailed => const SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationUnavailable,
          'Save migration failed.',
        ),
    };
