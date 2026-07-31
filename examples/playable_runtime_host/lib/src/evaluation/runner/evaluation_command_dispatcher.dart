import '../driver/evaluation_driver.dart';

typedef EvaluationCommandEvidenceCapture = Future<void> Function({
  required String stepId,
  String? name,
});

/// Single dispatcher shared by scenario runs and Authoring API playtests.
///
/// Keeping this switch unique prevents an API command from claiming support
/// while PokeMap Eval exercises a different or synthetic code path.
final class EvaluationCommandDispatcher {
  const EvaluationCommandDispatcher();

  static const supportedOperations = <String>{
    'game.new',
    'save.write',
    'save.reload',
    'movement.navigate',
    'movement.crossConnection',
    'movement.enterGameplayZone',
    'world.interact',
    'world.enterTrigger',
    'world.enterWarp',
    'world.enterEncounter',
    'world.waitForFact',
    'dialogue.advance',
    'dialogue.choose',
    'battle.chooseMove',
    'battle.useItem',
    'battle.capture',
    'battle.run',
    'battle.completePostBattle',
    'battle.resolve',
    'battle.switch',
    'battle.chooseProgression',
    'battle.startTrainer',
    'battle.startStatic',
    'service.shop.inspect',
    'service.shop.buy',
    'service.shop.sell',
    'service.heal',
    'service.pc.withdraw',
    'service.pc.deposit',
    'service.pc.withdrawSlot',
    'service.pc.swap',
    'party.swap',
    'party.setLead',
    'bag.use',
    'player.pause',
    'player.resume',
    'player.openOptions',
    'player.openPokedex',
    'player.saveSlot',
    'player.loadSlot',
    'evidence.checkpoint',
    'evidence.snapshot',
    'probe.loadCheckpoint',
    'probe.goto',
    'probe.overrideFact',
    'probe.setMoney',
    'probe.seedBag',
    'probe.seedParty',
  };

  Future<void> execute({
    required EvaluationDriver driver,
    required String commandId,
    required String operation,
    required Map<String, Object?> arguments,
    EvaluationCommandEvidenceCapture? evidenceCapture,
  }) async {
    final values = EvaluationCommandArguments(arguments);
    await switch (operation) {
      'game.new' => driver.startNewGame(),
      'save.write' => driver.save(),
      'save.reload' => driver.saveAndReload(),
      'movement.navigate' => driver.navigateTo(
          values.requireInt('x'),
          values.requireInt('y'),
        ),
      'movement.crossConnection' => driver.crossConnection(
          values.requireString('direction'),
          preferredAxis: values.optionalInt('preferredAxis'),
        ),
      'movement.enterGameplayZone' => driver.enterGameplayZone(
          values.requireString('zoneId'),
        ),
      'world.interact' => driver.interact(values.requireString('entityId')),
      'world.enterTrigger' => driver.enterTrigger(
          values.requireString('triggerId'),
          expectBattle: values.optionalBool('expectBattle') ?? false,
        ),
      'world.enterWarp' => driver.enterWarp(values.requireString('warpId')),
      'world.enterEncounter' => driver.enterWildEncounter(),
      'world.waitForFact' => driver.waitForFact(
          values.requireString('factId'),
          timeout: values.optionalDuration('timeoutMilliseconds'),
        ),
      'dialogue.advance' => driver.advanceDialogue(),
      'dialogue.choose' => driver.chooseDialogue(
          values.requireNonNegativeInt('choiceIndex'),
          linesBeforeChoice: values.optionalNonNegativeInt('linesBeforeChoice'),
        ),
      'battle.chooseMove' => driver.chooseBattleMove(
          values.requireNonNegativeInt('moveIndex'),
        ),
      'battle.useItem' => driver.useBattleItem(
          values.requireString('itemId'),
        ),
      'battle.capture' => driver.attemptCapture(),
      'battle.run' => driver.runFromBattle(),
      'battle.completePostBattle' => driver.completePostBattle(),
      'battle.resolve' => driver.resolveBattle(
          values.requireString('strategy'),
        ),
      'battle.switch' => _battle(driver, operation).switchBattlePokemon(
          values.requireNonNegativeInt('partyIndex'),
        ),
      'battle.chooseProgression' =>
        _battle(driver, operation).chooseBattleProgression(
          values.requireNonNegativeInt('decisionIndex'),
        ),
      'battle.startTrainer' => _battle(driver, operation).startTrainerBattle(
          values.requireString('trainerId'),
          values.requireString('npcEntityId'),
        ),
      'battle.startStatic' => _battle(driver, operation).startStaticBattle(
          values.requireString('battleId'),
          values.requireString('opponentProfileId'),
          values.requireString('entityId'),
        ),
      'service.shop.inspect' => driver.inspectShop(),
      'service.shop.buy' => driver.buy(
          values.requireString('itemId'),
          values.requirePositiveInt('quantity'),
        ),
      'service.shop.sell' => _roster(driver, operation).sell(
          values.requireString('shopId'),
          values.requireString('expectedStateId'),
          values.requireString('itemId'),
          values.requirePositiveInt('quantity'),
        ),
      'service.heal' => driver.healParty(),
      'service.pc.withdraw' => driver.withdrawFromPc(
          values.requireString('pokemonId'),
        ),
      'service.pc.deposit' => _roster(driver, operation).depositPartyPokemon(
          values.requireNonNegativeInt('partyIndex'),
          boxId: values.optionalString('boxId'),
        ),
      'service.pc.withdrawSlot' => _roster(driver, operation).withdrawPcSlot(
          values.requireString('boxId'),
          values.requireNonNegativeInt('boxIndex'),
        ),
      'service.pc.swap' => _roster(driver, operation).swapPartyWithPc(
          values.requireNonNegativeInt('partyIndex'),
          values.requireString('boxId'),
          values.requireNonNegativeInt('boxIndex'),
        ),
      'party.swap' => _roster(driver, operation).swapPartyMembers(
          values.requireNonNegativeInt('firstIndex'),
          values.requireNonNegativeInt('secondIndex'),
        ),
      'party.setLead' => _roster(driver, operation).setLeadPokemon(
          values.requireNonNegativeInt('partyIndex'),
        ),
      'bag.use' => _roster(driver, operation).useBagItem(
          values.requireString('itemId'),
          values.requireNonNegativeInt('partyIndex'),
          moveId: values.optionalString('moveId'),
        ),
      'player.pause' => _shell(driver, operation).pause(),
      'player.resume' => _shell(driver, operation).resume(),
      'player.openOptions' => _shell(driver, operation).openOptions(),
      'player.openPokedex' => _shell(driver, operation).openPokedex(),
      'player.saveSlot' => _shell(driver, operation).saveSlot(),
      'player.loadSlot' => _shell(driver, operation).loadSlot(
          values.requireString('profileId'),
          values.requireString('slotId'),
        ),
      'evidence.checkpoint' => driver.createCheckpoint(
          values.requireString('checkpointId'),
        ),
      'evidence.snapshot' => evidenceCapture == null
          ? Future<void>.value()
          : evidenceCapture(
              stepId: commandId,
              name: values.optionalString('name'),
            ),
      'probe.loadCheckpoint' => driver.probeLoadCheckpoint(
          values.requireString('checkpointId'),
        ),
      'probe.goto' => driver.probeGoto(
          values.requireString('mapId'),
          values.requireInt('x'),
          values.requireInt('y'),
        ),
      'probe.overrideFact' => driver.probeOverrideFact(
          values.requireString('factId'),
          values.requireBool('value'),
        ),
      'probe.setMoney' => driver.probeSetMoney(
          values.requireNonNegativeInt('value'),
        ),
      'probe.seedBag' => driver.probeSeedBag(
          values.requireIntMap('quantities'),
        ),
      'probe.seedParty' => driver.probeSeedParty(
          values.requireMapList('pokemon'),
        ),
      final unsupported => throw EvaluationScenarioExecutionError(
          'Operation "$unsupported" has no runtime dispatcher.',
        ),
    };
  }

  EvaluationRosterAutomation _roster(
    EvaluationDriver driver,
    String operation,
  ) {
    if (driver is EvaluationRosterAutomation) {
      return driver as EvaluationRosterAutomation;
    }
    throw EvaluationScenarioExecutionError(
      'Operation "$operation" requires roster runtime automation.',
    );
  }

  EvaluationBattleAutomation _battle(
    EvaluationDriver driver,
    String operation,
  ) {
    if (driver is EvaluationBattleAutomation) {
      return driver as EvaluationBattleAutomation;
    }
    throw EvaluationScenarioExecutionError(
      'Operation "$operation" requires battle runtime automation.',
    );
  }

  EvaluationPlayerShellAutomation _shell(
    EvaluationDriver driver,
    String operation,
  ) {
    if (driver case EvaluationPlayerShellProvider(:final playerShell?)) {
      return playerShell;
    }
    throw EvaluationScenarioExecutionError(
      'Operation "$operation" requires an attached player shell.',
    );
  }
}

final class EvaluationScenarioExecutionError implements Exception {
  const EvaluationScenarioExecutionError(this.message);

  final String message;

  @override
  String toString() => 'Invalid evaluation command: $message';
}

final class EvaluationCommandArguments {
  const EvaluationCommandArguments(this.values);

  final Map<String, Object?> values;

  String requireString(String key) {
    final value = values[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be a non-blank string.',
    );
  }

  int requireInt(String key) {
    final value = values[key];
    if (value is int) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be an integer.',
    );
  }

  int requireNonNegativeInt(String key) {
    final value = requireInt(key);
    if (value >= 0) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be non-negative.',
    );
  }

  int requirePositiveInt(String key) {
    final value = requireInt(key);
    if (value > 0) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be positive.',
    );
  }

  int? optionalInt(String key) {
    if (!values.containsKey(key)) return null;
    return requireInt(key);
  }

  String? optionalString(String key) {
    if (!values.containsKey(key)) return null;
    return requireString(key);
  }

  int? optionalNonNegativeInt(String key) {
    if (!values.containsKey(key)) return null;
    return requireNonNegativeInt(key);
  }

  Duration? optionalDuration(String key) {
    if (!values.containsKey(key)) return null;
    return Duration(milliseconds: requirePositiveInt(key));
  }

  bool requireBool(String key) {
    final value = values[key];
    if (value is bool) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be a boolean.',
    );
  }

  bool? optionalBool(String key) {
    if (!values.containsKey(key)) return null;
    return requireBool(key);
  }

  Map<String, int> requireIntMap(String key) {
    final value = values[key];
    if (value is! Map) {
      throw EvaluationScenarioExecutionError(
        'Argument "$key" must be an integer map.',
      );
    }
    final result = <String, int>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! int || entry.value < 0) {
        throw EvaluationScenarioExecutionError(
          'Argument "$key" must contain non-negative integer quantities.',
        );
      }
      result[entry.key as String] = entry.value as int;
    }
    return result;
  }

  List<Map<String, Object?>> requireMapList(String key) {
    final value = values[key];
    if (value is! List) {
      throw EvaluationScenarioExecutionError(
        'Argument "$key" must be a list of objects.',
      );
    }
    final result = <Map<String, Object?>>[];
    for (final item in value) {
      if (item is! Map) {
        throw EvaluationScenarioExecutionError(
          'Argument "$key" must contain only objects.',
        );
      }
      result.add(Map<String, Object?>.from(item));
    }
    return result;
  }
}
