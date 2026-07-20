import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('canonical catalog has unique ids, backends and wires', () {
    final catalog = NarrativeCommandCatalog.canonical();

    expect(diagnoseNarrativeCommandCatalog(catalog), isEmpty);
    expect(catalog.commands.map((command) => command.id).toSet().length,
        catalog.commands.length);
    expect(
      catalog.publishable.map((command) => command.wireId).toSet().length,
      catalog.publishable.length,
    );
  });

  test(
      'persistent effects reuse SceneConsequence and dedicated flows stay nodes',
      () {
    final catalog = NarrativeCommandCatalog.canonical();
    for (final id in [
      NarrativeCommandIds.setFact,
      NarrativeCommandIds.markEventConsumed,
      NarrativeCommandIds.completeStoryStep,
      NarrativeCommandIds.giveItem,
      NarrativeCommandIds.takeItem,
      NarrativeCommandIds.giveMoney,
      NarrativeCommandIds.givePokemon,
    ]) {
      final command = catalog.byId(id)!;
      expect(command.backend, NarrativeCommandBackend.sceneConsequence);
      expect(command.isPersistent, isTrue);
      expect(command.wireId, 'SceneConsequence.$id');
    }
    expect(
      catalog.byId(NarrativeCommandIds.dialogue)!.backend,
      NarrativeCommandBackend.dedicatedSceneNode,
    );
    expect(
      catalog.byId(NarrativeCommandIds.trainerBattle)!.wireId,
      'SceneNode.battle.trainer',
    );
  });

  test('unproved mechanics are visible but cannot be published', () {
    final catalog = NarrativeCommandCatalog.canonical();
    for (final id in [
      NarrativeCommandIds.healParty,
      NarrativeCommandIds.awardBadge,
      NarrativeCommandIds.unlockFieldAbility,
      NarrativeCommandIds.setNpcPresence,
    ]) {
      final command = catalog.byId(id)!;
      expect(command.isPublishable, isFalse);
      expect(command.capabilities.reason, isNotEmpty);
      expect(catalog.publishable, isNot(contains(command)));
    }
  });

  test('consumed Event command requests both map and Event identities', () {
    final descriptor = NarrativeCommandCatalog.canonical().byId(
      NarrativeCommandIds.markEventConsumed,
    )!;

    expect(
      descriptor.parameters.map((parameter) => parameter.id),
      ['mapId', 'eventId'],
    );
  });

  test('interactive diagnostics block an unknown destination map', () {
    const project = ProjectManifest(
      name: 'Commands',
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
      maps: [],
      tilesets: [],
    );
    final diagnostics = diagnoseInteractiveCommand(
      command: SceneInteractiveCommand.warp(
        destinationMapId: 'map.missing',
        warpId: 'warp.arrival',
      ),
      project: project,
    );

    expect(diagnostics.single.code,
        NarrativeCommandDiagnosticCode.unknownDestinationMap);
  });
}
