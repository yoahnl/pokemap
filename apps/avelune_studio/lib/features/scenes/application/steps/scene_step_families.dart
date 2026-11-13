import 'package:map_core/map_core_domain.dart';

enum SceneStepFamily {
  rememberFact,
  talk,
  showOrHide,
  musicAndSound,
  battle,
  giveItem,
  conditions,
  other,
}

const Map<String, SceneStepFamily> sceneStepCommandFamilies = {
  NarrativeCommandIds.setFact: SceneStepFamily.rememberFact,
  NarrativeCommandIds.adjustIntegerFact: SceneStepFamily.rememberFact,
  NarrativeCommandIds.calculateIntegerFacts: SceneStepFamily.rememberFact,
  NarrativeCommandIds.inputIntegerToFact: SceneStepFamily.rememberFact,
  NarrativeCommandIds.inputTextToFact: SceneStepFamily.rememberFact,
  NarrativeCommandIds.setMapEventInstanceBoolean: SceneStepFamily.rememberFact,
  NarrativeCommandIds.markEventConsumed: SceneStepFamily.rememberFact,
  NarrativeCommandIds.completeStoryStep: SceneStepFamily.rememberFact,
  NarrativeCommandIds.dialogue: SceneStepFamily.talk,
  NarrativeCommandIds.setNpcPresence: SceneStepFamily.showOrHide,
  NarrativeCommandIds.actorVisibility: SceneStepFamily.showOrHide,
  NarrativeCommandIds.playSoundEffect: SceneStepFamily.musicAndSound,
  NarrativeCommandIds.stopSoundEffects: SceneStepFamily.musicAndSound,
  NarrativeCommandIds.playMusicEffect: SceneStepFamily.musicAndSound,
  NarrativeCommandIds.sceneMusic: SceneStepFamily.musicAndSound,
  NarrativeCommandIds.trainerBattle: SceneStepFamily.battle,
  NarrativeCommandIds.staticEncounter: SceneStepFamily.battle,
  NarrativeCommandIds.whiteOut: SceneStepFamily.battle,
  NarrativeCommandIds.giveItem: SceneStepFamily.giveItem,
  NarrativeCommandIds.giveItemGift: SceneStepFamily.giveItem,
  NarrativeCommandIds.takeItem: SceneStepFamily.giveItem,
  NarrativeCommandIds.claimPeriodicReward: SceneStepFamily.giveItem,
  NarrativeCommandIds.giveMoney: SceneStepFamily.giveItem,
  NarrativeCommandIds.adjustMoney: SceneStepFamily.giveItem,
  NarrativeCommandIds.tryPayMoney: SceneStepFamily.giveItem,
  NarrativeCommandIds.grantRailCurrency: SceneStepFamily.giveItem,
  NarrativeCommandIds.grantRailStamp: SceneStepFamily.giveItem,
  NarrativeCommandIds.givePokemon: SceneStepFamily.giveItem,
  NarrativeCommandIds.giveConfiguredStarter: SceneStepFamily.giveItem,
  NarrativeCommandIds.givePokemonFromCatalog: SceneStepFamily.giveItem,
  NarrativeCommandIds.receivePokemonFromCatalog: SceneStepFamily.giveItem,
  NarrativeCommandIds.awardBadge: SceneStepFamily.giveItem,
  NarrativeCommandIds.healParty: SceneStepFamily.other,
  NarrativeCommandIds.openHeal: SceneStepFamily.other,
  NarrativeCommandIds.warp: SceneStepFamily.other,
  NarrativeCommandIds.wait: SceneStepFamily.other,
  NarrativeCommandIds.waitForActorRoutes: SceneStepFamily.other,
  NarrativeCommandIds.worldTone: SceneStepFamily.other,
  NarrativeCommandIds.worldPresentation: SceneStepFamily.other,
  NarrativeCommandIds.actorRoute: SceneStepFamily.other,
  NarrativeCommandIds.moveNpc: SceneStepFamily.other,
  NarrativeCommandIds.setNpcPose: SceneStepFamily.other,
  NarrativeCommandIds.setPropState: SceneStepFamily.other,
  NarrativeCommandIds.movePlatform: SceneStepFamily.other,
  NarrativeCommandIds.playCharacterAnimation: SceneStepFamily.other,
  NarrativeCommandIds.playModelAnimation: SceneStepFamily.other,
  NarrativeCommandIds.cinematic: SceneStepFamily.other,
  NarrativeCommandIds.openImagePuzzle: SceneStepFamily.other,
  NarrativeCommandIds.openCrafting: SceneStepFamily.other,
  NarrativeCommandIds.openShop: SceneStepFamily.other,
  NarrativeCommandIds.openPc: SceneStepFamily.other,
  NarrativeCommandIds.openRegionalMap: SceneStepFamily.other,
  NarrativeCommandIds.openPartyTrade: SceneStepFamily.other,
  NarrativeCommandIds.openNpcTrade: SceneStepFamily.other,
  NarrativeCommandIds.finishGame: SceneStepFamily.other,
  NarrativeCommandIds.setPlayerAvatar: SceneStepFamily.other,
  NarrativeCommandIds.setPauseMenuEntryVisibility: SceneStepFamily.other,
  NarrativeCommandIds.railJourney: SceneStepFamily.other,
  NarrativeCommandIds.markPokemonSeen: SceneStepFamily.other,
  NarrativeCommandIds.unlockFieldAbility: SceneStepFamily.other,
};

SceneStepFamily? sceneStepFamilyOfCommand(String commandId) =>
    sceneStepCommandFamilies[commandId];

String? sceneStepCommandIdOf(SceneNode node) => switch (node.payload) {
  SceneYarnDialoguePayload() => NarrativeCommandIds.dialogue,
  SceneCinematicPayload() => NarrativeCommandIds.cinematic,
  SceneBattlePayload(:final battleKind) => switch (battleKind) {
    'trainer' => NarrativeCommandIds.trainerBattle,
    'static' => NarrativeCommandIds.staticEncounter,
    _ => null,
  },
  SceneActionPayload(:final interactiveCommand?) =>
    NarrativeCommandIds.forInteractiveCommand(interactiveCommand),
  SceneActionPayload(:final consequence?) => NarrativeCommandIds.forConsequence(
    consequence,
  ),
  _ => null,
};

SceneStepFamily sceneStepFamilyOfNode(SceneNode node) {
  if (node.kind == SceneNodeKind.condition) return SceneStepFamily.conditions;
  if (node.kind == SceneNodeKind.battle) return SceneStepFamily.battle;
  final commandId = sceneStepCommandIdOf(node);
  return (commandId == null ? null : sceneStepFamilyOfCommand(commandId)) ??
      SceneStepFamily.other;
}

bool sceneStepIsAdvanced(SceneNode node) {
  if (node.kind == SceneNodeKind.condition) return false;
  final commandId = sceneStepCommandIdOf(node);
  return commandId == null || sceneStepFamilyOfCommand(commandId) == null;
}
