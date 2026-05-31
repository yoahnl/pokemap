enum SceneBattleRuntimeOutcomeStatus {
  completed,
  failed,
}

enum SceneBattleRuntimeOutcomePort {
  victory,
  defeat,
}

enum SceneBattleRuntimeOutcomeErrorCode {
  missingTrainerId,
  missingNpcEntityId,
  unsupportedBattleKind,
  launcherFailed,
  unsupportedOutcome,
}

final class SceneBattleRuntimeOutcomeResult {
  const SceneBattleRuntimeOutcomeResult._({
    required this.status,
    this.port,
    this.errorCode,
    this.message,
  });

  const SceneBattleRuntimeOutcomeResult.completed({
    required SceneBattleRuntimeOutcomePort port,
  }) : this._(
          status: SceneBattleRuntimeOutcomeStatus.completed,
          port: port,
        );

  const SceneBattleRuntimeOutcomeResult.failed({
    required SceneBattleRuntimeOutcomeErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneBattleRuntimeOutcomeStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneBattleRuntimeOutcomeStatus status;
  final SceneBattleRuntimeOutcomePort? port;
  final SceneBattleRuntimeOutcomeErrorCode? errorCode;
  final String? message;

  bool get success => status == SceneBattleRuntimeOutcomeStatus.completed;

  String? get scenePortId {
    return switch (port) {
      SceneBattleRuntimeOutcomePort.victory => 'victory',
      SceneBattleRuntimeOutcomePort.defeat => 'defeat',
      null => null,
    };
  }
}
