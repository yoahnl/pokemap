import '../contracts/evaluation_state_snapshot.dart';

/// Runtime authority shared by scenario runs and Authoring API playtests.
///
/// `EvaluationPlaytestDriver` deliberately wraps this interface instead of
/// adding filesystem or API concerns to every concrete evaluator.
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

  Map<String, Object?>? get lastShopSnapshot;

  Future<void> closeActiveService();
}

abstract interface class EvaluationBagMutationAutomation {
  Future<void> giveBagItem(String itemId, int quantity);

  Future<void> consumeBagItem(String itemId, int quantity);
}

/// Explicit party, Bag, PC and Shop actions backed by gameplay/runtime ports.
abstract interface class EvaluationRosterAutomation {
  Future<void> swapPartyMembers(int firstIndex, int secondIndex);

  Future<void> setLeadPokemon(int partyIndex);

  Future<void> useBagItem(
    String itemId,
    int partyIndex, {
    String? moveId,
  });

  Future<void> depositPartyPokemon(int partyIndex, {String? boxId});

  Future<void> withdrawPcSlot(String boxId, int boxIndex);

  Future<void> swapPartyWithPc(
    int partyIndex,
    String boxId,
    int boxIndex,
  );

  Future<void> sell(
    String shopId,
    String expectedStateId,
    String itemId,
    int quantity,
  );
}

/// Explicit battle actions that cannot be represented by `battle.resolve`.
abstract interface class EvaluationBattleAutomation {
  Future<void> switchBattlePokemon(int partyIndex);

  Future<void> chooseBattleProgression(int decisionIndex);

  Future<void> startTrainerBattle(String trainerId, String npcEntityId);

  Future<void> startStaticBattle(
    String battleId,
    String opponentProfileId,
    String entityId,
  );
}

/// Runtime-player-shell actions. A headless Flame driver does not pretend to
/// own this surface; hosts attach this capability when a coordinator exists.
abstract interface class EvaluationPlayerShellAutomation {
  Future<void> pause();

  Future<void> resume();

  Future<void> openOptions();

  Future<void> openPokedex();

  Future<void> saveSlot();

  Future<void> loadSlot(String profileId, String slotId);
}

abstract interface class EvaluationPlayerShellProvider {
  EvaluationPlayerShellAutomation? get playerShell;
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
