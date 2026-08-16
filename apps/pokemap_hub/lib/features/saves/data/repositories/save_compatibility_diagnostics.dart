import 'package:map_core/map_core.dart';

import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';

SaveStorageDiagnostic compatibilityDiagnostic(
  SaveCompatibilityCode code, {
  int? detectedSaveFormat,
  int? expectedSaveFormat,
}) =>
    switch (code) {
      SaveCompatibilityCode.saveGameMismatch => SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveGameMismatch,
          'Save belongs to another game.',
          detectedSaveFormat: detectedSaveFormat,
          expectedSaveFormat: expectedSaveFormat,
          recommendedActions: const <SaveRecoveryAction>[
            SaveRecoveryAction.returnToTitle,
          ],
        ),
      SaveCompatibilityCode.saveCompatibilityMismatch => SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveCompatibilityMismatch,
          'Save compatibility identifier does not match this game.',
          detectedSaveFormat: detectedSaveFormat,
          expectedSaveFormat: expectedSaveFormat,
          recommendedActions: const <SaveRecoveryAction>[
            SaveRecoveryAction.returnToTitle,
          ],
        ),
      SaveCompatibilityCode.saveFormatFuture => SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveFormatFuture,
          'Save was written by a future unsupported format.',
          detectedSaveFormat: detectedSaveFormat,
          expectedSaveFormat: expectedSaveFormat,
          recommendedActions: const <SaveRecoveryAction>[
            SaveRecoveryAction.returnToTitle,
          ],
        ),
      SaveCompatibilityCode.saveMigrationRequired => SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationRequired,
          'Save requires migration.',
          detectedSaveFormat: detectedSaveFormat,
          expectedSaveFormat: expectedSaveFormat,
          recommendedActions: const <SaveRecoveryAction>[
            SaveRecoveryAction.migrate,
            SaveRecoveryAction.returnToTitle,
          ],
        ),
      SaveCompatibilityCode.saveMigrationUnavailable => SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationUnavailable,
          'No migration chain is available for this save.',
          detectedSaveFormat: detectedSaveFormat,
          expectedSaveFormat: expectedSaveFormat,
          recommendedActions: const <SaveRecoveryAction>[
            SaveRecoveryAction.returnToTitle,
          ],
        ),
      SaveCompatibilityCode.migrationFailed => SaveStorageDiagnostic(
          SaveStorageDiagnosticCode.saveMigrationUnavailable,
          'Save migration failed.',
          detectedSaveFormat: detectedSaveFormat,
          expectedSaveFormat: expectedSaveFormat,
          recommendedActions: const <SaveRecoveryAction>[
            SaveRecoveryAction.retry,
            SaveRecoveryAction.returnToTitle,
          ],
        ),
    };

SaveStorageDiagnostic primaryCorruptDiagnostic({
  required bool recoverableFromBackup,
  int? expectedSaveFormat,
}) =>
    recoverableFromBackup
        ? SaveStorageDiagnostic(
            SaveStorageDiagnosticCode.primaryCorrupt,
            'The primary save is corrupt and was quarantined.',
            expectedSaveFormat: expectedSaveFormat,
            recommendedActions: const <SaveRecoveryAction>[
              SaveRecoveryAction.restoreBackup,
              SaveRecoveryAction.returnToTitle,
            ],
          )
        : SaveStorageDiagnostic(
            SaveStorageDiagnosticCode.primaryCorrupt,
            'The primary save is corrupt and was quarantined.',
            expectedSaveFormat: expectedSaveFormat,
            recommendedActions: const <SaveRecoveryAction>[
              SaveRecoveryAction.retry,
              SaveRecoveryAction.deleteSave,
              SaveRecoveryAction.returnToTitle,
            ],
          );

SaveStorageDiagnostic backupUsedDiagnostic({
  int? detectedSaveFormat,
  int? expectedSaveFormat,
}) =>
    SaveStorageDiagnostic(
      SaveStorageDiagnosticCode.backupUsed,
      'A valid backup is available; promotion requires confirmation.',
      detectedSaveFormat: detectedSaveFormat,
      expectedSaveFormat: expectedSaveFormat,
      recommendedActions: const <SaveRecoveryAction>[
        SaveRecoveryAction.restoreBackup,
        SaveRecoveryAction.returnToTitle,
      ],
    );

SaveStorageDiagnostic missingSlotDiagnostic({int? expectedSaveFormat}) =>
    SaveStorageDiagnostic(
      SaveStorageDiagnosticCode.missing,
      'No save exists for this slot.',
      expectedSaveFormat: expectedSaveFormat,
      recommendedActions: const <SaveRecoveryAction>[
        SaveRecoveryAction.returnToTitle,
      ],
    );
