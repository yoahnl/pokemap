import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final catalog = NarrativeCommandCatalog.canonical();

  Iterable<NarrativeCommandDescriptor> withBackend(
    NarrativeCommandBackend backend,
  ) =>
      catalog.commands.where((command) => command.backend == backend);

  test('every catalog id is a declared command constant', () {
    const declared = <String>{
      NarrativeCommandIds.setMapEventInstanceBoolean,
      NarrativeCommandIds.setFact,
      NarrativeCommandIds.markEventConsumed,
      NarrativeCommandIds.completeStoryStep,
      NarrativeCommandIds.giveItem,
      NarrativeCommandIds.giveItemGift,
      NarrativeCommandIds.takeItem,
      NarrativeCommandIds.giveMoney,
      NarrativeCommandIds.grantRailCurrency,
      NarrativeCommandIds.grantRailStamp,
      NarrativeCommandIds.givePokemon,
      NarrativeCommandIds.giveConfiguredStarter,
      NarrativeCommandIds.warp,
      NarrativeCommandIds.worldTone,
      NarrativeCommandIds.playSoundEffect,
      NarrativeCommandIds.actorRoute,
      NarrativeCommandIds.actorVisibility,
      NarrativeCommandIds.openShop,
      NarrativeCommandIds.openHeal,
      NarrativeCommandIds.openPc,
      NarrativeCommandIds.dialogue,
      NarrativeCommandIds.trainerBattle,
      NarrativeCommandIds.staticEncounter,
      NarrativeCommandIds.cinematic,
      NarrativeCommandIds.healParty,
      NarrativeCommandIds.awardBadge,
      NarrativeCommandIds.unlockFieldAbility,
      NarrativeCommandIds.finishGame,
      NarrativeCommandIds.setNpcPresence,
      NarrativeCommandIds.setPauseMenuEntryVisibility,
      NarrativeCommandIds.moveNpc,
      NarrativeCommandIds.movePlatform,
      NarrativeCommandIds.playCharacterAnimation,
      NarrativeCommandIds.playModelAnimation,
      NarrativeCommandIds.railJourney,
    };

    expect(
      catalog.commands.map((command) => command.id).toSet(),
      declared,
      reason: 'a command may not exist without its published identifier',
    );
  });

  test('every scene consequence command is executed by a consequence kind', () {
    final executed = SceneConsequenceKind.values.map((kind) => kind.name).toSet();

    for (final command in withBackend(NarrativeCommandBackend.sceneConsequence)) {
      expect(
        executed,
        contains(command.id),
        reason: '${command.id} claims a consequence backend with no executor',
      );
      expect(command.wireId, 'SceneConsequence.${command.id}');
    }
  });

  test('every consequence kind is published as a catalog command', () {
    final published = withBackend(NarrativeCommandBackend.sceneConsequence)
        .map((command) => command.id)
        .toSet();

    for (final kind in SceneConsequenceKind.values) {
      expect(
        published,
        contains(kind.name),
        reason: 'consequence ${kind.name} is executable but unauthorable',
      );
    }
  });

  test('interactive command wires match the runtime kinds exactly', () {
    final published = {
      for (final command
          in withBackend(NarrativeCommandBackend.interactiveRuntimeCommand))
        command.id: command.wireId,
    };

    expect(published, {
      NarrativeCommandIds.giveItemGift: 'SceneInteractiveCommand.giveItem',
      NarrativeCommandIds.warp: 'SceneInteractiveCommand.warp',
      NarrativeCommandIds.worldTone: 'SceneInteractiveCommand.worldTone',
      NarrativeCommandIds.playSoundEffect:
          'SceneInteractiveCommand.playSoundEffect',
      NarrativeCommandIds.actorRoute: 'SceneInteractiveCommand.actorRoute',
      NarrativeCommandIds.actorVisibility:
          'SceneInteractiveCommand.actorVisibility',
      NarrativeCommandIds.moveNpc: 'SceneInteractiveCommand.moveNpc',
      NarrativeCommandIds.movePlatform: 'SceneInteractiveCommand.movePlatform',
      NarrativeCommandIds.openShop: 'SceneInteractiveCommand.openShop',
      NarrativeCommandIds.openHeal: 'SceneInteractiveCommand.openHeal',
      NarrativeCommandIds.openPc: 'SceneInteractiveCommand.openPc',
      NarrativeCommandIds.playCharacterAnimation:
          'SceneInteractiveCommand.playCharacterAnimation',
      NarrativeCommandIds.playModelAnimation:
          'SceneInteractiveCommand.playModelAnimation',
      NarrativeCommandIds.railJourney: 'SceneInteractiveCommand.railJourney',
    });
    expect(
      published.values.toSet(),
      SceneInteractiveCommandKind.values
          .map((kind) => 'SceneInteractiveCommand.${kind.name}')
          .toSet(),
      reason: 'the interactive wires and the runtime kinds must not drift',
    );
  });

  test('dedicated scene nodes stay an explicit, reviewed set', () {
    final nodes = <String, String>{
      for (final command
          in withBackend(NarrativeCommandBackend.dedicatedSceneNode))
        command.id: command.wireId,
    };

    expect(nodes, <String, String>{
      NarrativeCommandIds.dialogue: 'SceneNode.yarnDialogue',
      NarrativeCommandIds.trainerBattle: 'SceneNode.battle.trainer',
      NarrativeCommandIds.staticEncounter: 'SceneNode.battle.static',
      NarrativeCommandIds.cinematic: 'SceneNode.cinematic',
    });
  });

  test('a beta command is publishable or names why it is not', () {
    for (final command in catalog.commands) {
      if (command.capabilities.isPublishable) continue;
      expect(
        command.capabilities.reason,
        isNotNull,
        reason: '${command.id} is unpublishable without a stated reason',
      );
    }
  });
}
