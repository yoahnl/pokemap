import 'package:map_core/map_core.dart';

SaveLoadDiagnostic describeGameSaveLoadFailure(Object error) {
  if (error is UnsupportedSaveSchema) {
    final detected = error.schemaVersion;
    return SaveLoadDiagnostic(
      code: SaveLoadFailureCode.unsupportedSchema,
      detectedSchemaVersion: detected is int ? detected : null,
      expectedSchemaVersion: error.expectedSchemaVersion,
      recommendedActions: const <SaveRecoveryAction>[
        SaveRecoveryAction.returnToTitle,
      ],
    );
  }
  if (error is FormatException) {
    return const SaveLoadDiagnostic(
      code: SaveLoadFailureCode.unreadable,
      expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
      recommendedActions: <SaveRecoveryAction>[
        SaveRecoveryAction.retry,
        SaveRecoveryAction.deleteSave,
        SaveRecoveryAction.returnToTitle,
      ],
    );
  }
  return const SaveLoadDiagnostic(
    code: SaveLoadFailureCode.invalidState,
    expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
    recommendedActions: <SaveRecoveryAction>[
      SaveRecoveryAction.retry,
      SaveRecoveryAction.returnToTitle,
    ],
  );
}
