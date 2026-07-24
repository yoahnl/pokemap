final class EvaluationCommandDefinition {
  const EvaluationCommandDefinition({
    required this.operation,
    required this.requiredKeys,
    this.optionalKeys = const <String>{},
    this.probeOnly = false,
  });

  final String operation;
  final Set<String> requiredKeys;
  final Set<String> optionalKeys;
  final bool probeOnly;

  Set<String> get allowedKeys => <String>{
        ...requiredKeys,
        ...optionalKeys,
      };
}

const evaluationCommandCatalog = <String, EvaluationCommandDefinition>{
  'game.new': EvaluationCommandDefinition(
    operation: 'game.new',
    requiredKeys: <String>{},
  ),
  'save.write': EvaluationCommandDefinition(
    operation: 'save.write',
    requiredKeys: <String>{},
  ),
  'save.reload': EvaluationCommandDefinition(
    operation: 'save.reload',
    requiredKeys: <String>{},
  ),
  'movement.navigate': EvaluationCommandDefinition(
    operation: 'movement.navigate',
    requiredKeys: <String>{'x', 'y'},
  ),
  'movement.crossConnection': EvaluationCommandDefinition(
    operation: 'movement.crossConnection',
    requiredKeys: <String>{'direction'},
    optionalKeys: <String>{'preferredAxis'},
  ),
  'world.interact': EvaluationCommandDefinition(
    operation: 'world.interact',
    requiredKeys: <String>{'entityId'},
  ),
  'world.enterTrigger': EvaluationCommandDefinition(
    operation: 'world.enterTrigger',
    requiredKeys: <String>{'triggerId'},
  ),
  'world.enterWarp': EvaluationCommandDefinition(
    operation: 'world.enterWarp',
    requiredKeys: <String>{'warpId'},
  ),
  'world.waitForFact': EvaluationCommandDefinition(
    operation: 'world.waitForFact',
    requiredKeys: <String>{'factId'},
    optionalKeys: <String>{'timeoutMilliseconds'},
  ),
  'dialogue.advance': EvaluationCommandDefinition(
    operation: 'dialogue.advance',
    requiredKeys: <String>{},
  ),
  'dialogue.choose': EvaluationCommandDefinition(
    operation: 'dialogue.choose',
    requiredKeys: <String>{'choiceIndex'},
    optionalKeys: <String>{'linesBeforeChoice'},
  ),
  'battle.chooseMove': EvaluationCommandDefinition(
    operation: 'battle.chooseMove',
    requiredKeys: <String>{'moveIndex'},
  ),
  'battle.useItem': EvaluationCommandDefinition(
    operation: 'battle.useItem',
    requiredKeys: <String>{'itemId'},
  ),
  'battle.capture': EvaluationCommandDefinition(
    operation: 'battle.capture',
    requiredKeys: <String>{},
  ),
  'battle.run': EvaluationCommandDefinition(
    operation: 'battle.run',
    requiredKeys: <String>{},
  ),
  'battle.completePostBattle': EvaluationCommandDefinition(
    operation: 'battle.completePostBattle',
    requiredKeys: <String>{},
  ),
  'service.shop.inspect': EvaluationCommandDefinition(
    operation: 'service.shop.inspect',
    requiredKeys: <String>{},
  ),
  'service.shop.buy': EvaluationCommandDefinition(
    operation: 'service.shop.buy',
    requiredKeys: <String>{'itemId', 'quantity'},
  ),
  'service.heal': EvaluationCommandDefinition(
    operation: 'service.heal',
    requiredKeys: <String>{},
  ),
  'service.pc.withdraw': EvaluationCommandDefinition(
    operation: 'service.pc.withdraw',
    requiredKeys: <String>{'pokemonId'},
  ),
  'evidence.checkpoint': EvaluationCommandDefinition(
    operation: 'evidence.checkpoint',
    requiredKeys: <String>{'checkpointId'},
  ),
  'evidence.snapshot': EvaluationCommandDefinition(
    operation: 'evidence.snapshot',
    requiredKeys: <String>{},
    optionalKeys: <String>{'name'},
  ),
  'probe.loadCheckpoint': EvaluationCommandDefinition(
    operation: 'probe.loadCheckpoint',
    requiredKeys: <String>{'checkpointId'},
    probeOnly: true,
  ),
  'probe.goto': EvaluationCommandDefinition(
    operation: 'probe.goto',
    requiredKeys: <String>{'mapId', 'x', 'y'},
    probeOnly: true,
  ),
  'probe.overrideFact': EvaluationCommandDefinition(
    operation: 'probe.overrideFact',
    requiredKeys: <String>{'factId', 'value'},
    probeOnly: true,
  ),
  'probe.setMoney': EvaluationCommandDefinition(
    operation: 'probe.setMoney',
    requiredKeys: <String>{'value'},
    probeOnly: true,
  ),
  'probe.seedBag': EvaluationCommandDefinition(
    operation: 'probe.seedBag',
    requiredKeys: <String>{'quantities'},
    probeOnly: true,
  ),
  'probe.seedParty': EvaluationCommandDefinition(
    operation: 'probe.seedParty',
    requiredKeys: <String>{'pokemon'},
    probeOnly: true,
  ),
};
