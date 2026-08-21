enum EvaluationCommandAvailability {
  runtime,
  attachedPlayerShell,
}

enum EvaluationCommandSequenceKind {
  explicitUserAction,
  diagnosticProbe,
}

final class EvaluationCommandDefinition {
  const EvaluationCommandDefinition({
    required this.operation,
    required this.requiredKeys,
    this.optionalKeys = const <String>{},
    this.probeOnly = false,
    this.availability = EvaluationCommandAvailability.runtime,
    EvaluationCommandSequenceKind? sequenceKind,
  }) : sequenceKind = sequenceKind ??
            (probeOnly
                ? EvaluationCommandSequenceKind.diagnosticProbe
                : EvaluationCommandSequenceKind.explicitUserAction);

  final String operation;
  final Set<String> requiredKeys;
  final Set<String> optionalKeys;
  final bool probeOnly;
  final EvaluationCommandAvailability availability;
  final EvaluationCommandSequenceKind sequenceKind;

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
  'movement.enterGameplayZone': EvaluationCommandDefinition(
    operation: 'movement.enterGameplayZone',
    requiredKeys: <String>{'zoneId'},
  ),
  'world.interact': EvaluationCommandDefinition(
    operation: 'world.interact',
    requiredKeys: <String>{'entityId'},
  ),
  'world.enterTrigger': EvaluationCommandDefinition(
    operation: 'world.enterTrigger',
    requiredKeys: <String>{'triggerId'},
    optionalKeys: <String>{'expectBattle'},
  ),
  'world.enterWarp': EvaluationCommandDefinition(
    operation: 'world.enterWarp',
    requiredKeys: <String>{'warpId'},
  ),
  'world.enterEncounter': EvaluationCommandDefinition(
    operation: 'world.enterEncounter',
    requiredKeys: <String>{},
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
  'battle.resolve': EvaluationCommandDefinition(
    operation: 'battle.resolve',
    requiredKeys: <String>{'strategy'},
  ),
  'service.shop.inspect': EvaluationCommandDefinition(
    operation: 'service.shop.inspect',
    requiredKeys: <String>{},
  ),
  'service.shop.buy': EvaluationCommandDefinition(
    operation: 'service.shop.buy',
    requiredKeys: <String>{'itemId', 'quantity'},
  ),
  'service.shop.sell': EvaluationCommandDefinition(
    operation: 'service.shop.sell',
    requiredKeys: <String>{
      'shopId',
      'expectedStateId',
      'itemId',
      'quantity',
    },
  ),
  'service.heal': EvaluationCommandDefinition(
    operation: 'service.heal',
    requiredKeys: <String>{},
  ),
  'service.pc.withdraw': EvaluationCommandDefinition(
    operation: 'service.pc.withdraw',
    requiredKeys: <String>{'pokemonId'},
  ),
  'service.pc.deposit': EvaluationCommandDefinition(
    operation: 'service.pc.deposit',
    requiredKeys: <String>{'partyIndex'},
    optionalKeys: <String>{'boxId'},
  ),
  'service.pc.withdrawSlot': EvaluationCommandDefinition(
    operation: 'service.pc.withdrawSlot',
    requiredKeys: <String>{'boxId', 'boxIndex'},
  ),
  'service.pc.swap': EvaluationCommandDefinition(
    operation: 'service.pc.swap',
    requiredKeys: <String>{'partyIndex', 'boxId', 'boxIndex'},
  ),
  'party.swap': EvaluationCommandDefinition(
    operation: 'party.swap',
    requiredKeys: <String>{'firstIndex', 'secondIndex'},
  ),
  'party.setLead': EvaluationCommandDefinition(
    operation: 'party.setLead',
    requiredKeys: <String>{'partyIndex'},
  ),
  // The bag probes write the bag directly, so they are diagnostic probes and
  // never an explicit player action. BETA-ITM-030 and BETA-ITM-031 added them
  // to the dispatcher without declaring them here.
  'bag.give': EvaluationCommandDefinition(
    operation: 'bag.give',
    requiredKeys: <String>{'itemId', 'quantity'},
    probeOnly: true,
  ),
  'bag.consume': EvaluationCommandDefinition(
    operation: 'bag.consume',
    requiredKeys: <String>{'itemId', 'quantity'},
    probeOnly: true,
  ),
  'bag.use': EvaluationCommandDefinition(
    operation: 'bag.use',
    requiredKeys: <String>{'itemId', 'partyIndex'},
    optionalKeys: <String>{'moveId'},
  ),
  'battle.switch': EvaluationCommandDefinition(
    operation: 'battle.switch',
    requiredKeys: <String>{'partyIndex'},
  ),
  'battle.chooseProgression': EvaluationCommandDefinition(
    operation: 'battle.chooseProgression',
    requiredKeys: <String>{'decisionIndex'},
  ),
  'battle.startTrainer': EvaluationCommandDefinition(
    operation: 'battle.startTrainer',
    requiredKeys: <String>{'trainerId', 'npcEntityId'},
  ),
  'battle.startStatic': EvaluationCommandDefinition(
    operation: 'battle.startStatic',
    requiredKeys: <String>{'battleId', 'opponentProfileId', 'entityId'},
  ),
  'player.pause': EvaluationCommandDefinition(
    operation: 'player.pause',
    requiredKeys: <String>{},
    availability: EvaluationCommandAvailability.attachedPlayerShell,
  ),
  'player.resume': EvaluationCommandDefinition(
    operation: 'player.resume',
    requiredKeys: <String>{},
    availability: EvaluationCommandAvailability.attachedPlayerShell,
  ),
  'player.openOptions': EvaluationCommandDefinition(
    operation: 'player.openOptions',
    requiredKeys: <String>{},
    availability: EvaluationCommandAvailability.attachedPlayerShell,
  ),
  'player.openPokedex': EvaluationCommandDefinition(
    operation: 'player.openPokedex',
    requiredKeys: <String>{},
    availability: EvaluationCommandAvailability.attachedPlayerShell,
  ),
  'player.saveSlot': EvaluationCommandDefinition(
    operation: 'player.saveSlot',
    requiredKeys: <String>{},
    availability: EvaluationCommandAvailability.attachedPlayerShell,
  ),
  'player.loadSlot': EvaluationCommandDefinition(
    operation: 'player.loadSlot',
    requiredKeys: <String>{'profileId', 'slotId'},
    availability: EvaluationCommandAvailability.attachedPlayerShell,
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

final class EvaluationUnavailableCommandCapability {
  const EvaluationUnavailableCommandCapability({required this.reason});

  final String reason;
}

const evaluationUnavailableCommandCapabilities =
    <String, EvaluationUnavailableCommandCapability>{
  'battle.chooseTarget': EvaluationUnavailableCommandCapability(
    reason: 'Runtime V1 battles are single-target; no target choice exists.',
  ),
};
