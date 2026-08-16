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
      NarrativeCommandIds.setFact,
      NarrativeCommandIds.markEventConsumed,
      NarrativeCommandIds.completeStoryStep,
      NarrativeCommandIds.giveItem,
      NarrativeCommandIds.takeItem,
      NarrativeCommandIds.giveMoney,
      NarrativeCommandIds.givePokemon,
      NarrativeCommandIds.giveConfiguredStarter,
      NarrativeCommandIds.warp,
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
      NarrativeCommandIds.playCharacterAnimation,
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

  test('interactive commands match the runtime command kinds exactly', () {
    final declared =
        withBackend(NarrativeCommandBackend.interactiveRuntimeCommand)
            .map((command) => command.id)
            .toSet();

    expect(
      declared,
      SceneInteractiveCommandKind.values.map((kind) => kind.name).toSet(),
      reason: 'the interactive catalog and the runtime kinds must not drift',
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
