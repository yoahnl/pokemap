import 'package:map_core/map_core.dart';

final class SaveItemSchemaGuardResult {
  const SaveItemSchemaGuardResult._({
    required this.state,
    required this.saveData,
    required this.diagnostic,
  });

  const SaveItemSchemaGuardResult.accepted({
    required GameState state,
    required SaveData saveData,
  }) : this._(state: state, saveData: saveData, diagnostic: null);

  const SaveItemSchemaGuardResult.rejected({
    required GameState originalState,
    required UnsupportedSaveSchema diagnostic,
  }) : this._(
          state: originalState,
          saveData: null,
          diagnostic: diagnostic,
        );

  final GameState state;
  final SaveData? saveData;
  final UnsupportedSaveSchema? diagnostic;

  bool get isAccepted => diagnostic == null;
}

final class SaveItemSchemaGuard {
  const SaveItemSchemaGuard();

  SaveItemSchemaGuardResult decode(
    Object? json, {
    required GameState originalState,
  }) {
    if (json is! Map<String, dynamic>) {
      return SaveItemSchemaGuardResult.rejected(
        originalState: originalState,
        diagnostic: const UnsupportedSaveSchema(
          schemaVersion: null,
          expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
          path: r'$',
        ),
      );
    }

    try {
      final saveData = SaveData.fromJson(json).normalized();
      return SaveItemSchemaGuardResult.accepted(
        state: gameStateFromSaveData(saveData),
        saveData: saveData,
      );
    } on UnsupportedSaveSchema catch (diagnostic) {
      return SaveItemSchemaGuardResult.rejected(
        originalState: originalState,
        diagnostic: diagnostic,
      );
    }
  }
}
