import '../contracts/evaluation_state_snapshot.dart';

abstract interface class EvaluationDriver {
  EvaluationStateSnapshot snapshot();

  Future<void> startNewGame();

  Future<void> navigateTo(int x, int y);

  Future<void> crossConnection(
    String direction, {
    int? preferredAxis,
  });

  Future<void> enterGameplayZone(String zoneId);

  Future<void> interact(String entityId);

  Future<void> enterTrigger(
    String triggerId, {
    bool expectBattle = false,
  });

  Future<void> enterWarp(String warpId);

  Future<void> enterWildEncounter();

  Future<void> waitForFact(
    String factId, {
    Duration? timeout,
  });

  Future<void> advanceDialogue();

  Future<void> chooseDialogue(
    int choiceIndex, {
    int? linesBeforeChoice,
  });

  Future<void> chooseBattleMove(int moveIndex);

  Future<void> useBattleItem(String itemId);

  Future<void> attemptCapture();

  Future<void> runFromBattle();

  Future<void> completePostBattle();

  Future<void> resolveBattle(String strategy);

  Future<void> inspectShop();

  Future<void> buy(String itemId, int quantity);

  Future<void> healParty();

  Future<void> withdrawFromPc(String pokemonId);

  Future<void> save();

  Future<void> saveAndReload();

  Future<void> createCheckpoint(String checkpointId);

  Future<void> probeLoadCheckpoint(String checkpointId);

  Future<void> probeGoto(String mapId, int x, int y);

  Future<void> probeOverrideFact(String factId, bool value);

  Future<void> probeSetMoney(int value);

  Future<void> probeSeedBag(Map<String, int> quantities);

  Future<void> probeSeedParty(List<Map<String, Object?>> pokemon);

  Future<void> dispose();
}

abstract interface class EvaluationPlayerServiceAutomation {
  Future<void> inspectShop();

  Future<void> buy(String itemId, int quantity);

  Future<void> healParty();

  Future<void> withdrawFromPc(String pokemonId);
}

abstract interface class EvaluationVisiblePlayerServiceAutomation
    implements EvaluationPlayerServiceAutomation {
  String? get activeServiceName;

  Future<void> closeActiveService();
}

final class EvaluationDriverFailure implements Exception {
  const EvaluationDriverFailure({
    required this.operation,
    required this.message,
    required this.snapshot,
  });

  final String operation;
  final String message;
  final EvaluationStateSnapshot snapshot;

  @override
  String toString() => 'EvaluationDriverFailure($operation): $message';
}
