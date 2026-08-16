enum SaveRecoveryAction {
  retry,
  restoreBackup,
  migrate,
  deleteSave,
  returnToTitle,
}

enum SaveLoadFailureCode { unreadable, unsupportedSchema, invalidState }

final class SaveLoadDiagnostic {
  const SaveLoadDiagnostic({
    required this.code,
    this.detectedSchemaVersion,
    this.expectedSchemaVersion,
    this.recommendedActions = const <SaveRecoveryAction>[],
  });

  final SaveLoadFailureCode code;
  final int? detectedSchemaVersion;
  final int? expectedSchemaVersion;
  final List<SaveRecoveryAction> recommendedActions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveLoadDiagnostic &&
          other.code == code &&
          other.detectedSchemaVersion == detectedSchemaVersion &&
          other.expectedSchemaVersion == expectedSchemaVersion &&
          _sameActions(other.recommendedActions);

  bool _sameActions(List<SaveRecoveryAction> other) {
    if (other.length != recommendedActions.length) return false;
    for (var index = 0; index < other.length; index++) {
      if (other[index] != recommendedActions[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        code,
        detectedSchemaVersion,
        expectedSchemaVersion,
        Object.hashAll(recommendedActions),
      );
}
