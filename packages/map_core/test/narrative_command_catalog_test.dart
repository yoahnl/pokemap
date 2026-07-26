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

  test('canonical gameplay consequences are fully authorable', () {
    final catalog = NarrativeCommandCatalog.canonical();
    for (final id in [
      NarrativeCommandIds.healParty,
      NarrativeCommandIds.awardBadge,
      NarrativeCommandIds.unlockFieldAbility,
      NarrativeCommandIds.setNpcPresence,
    ]) {
      final command = catalog.byId(id)!;
      expect(command.isPublishable, isTrue);
      expect(
        command.capabilities.model,
        NarrativeCommandCapabilityStatus.supported,
      );
      expect(
        command.capabilities.runtime,
        NarrativeCommandCapabilityStatus.supported,
      );
      expect(
        command.capabilities.editor,
        NarrativeCommandCapabilityStatus.supported,
      );
      expect(command.capabilities.reason, isNull);
    }

    expect(
      catalog.byId(NarrativeCommandIds.awardBadge)!.parameters.single.kind,
      NarrativeCommandParameterKind.badge,
    );
    expect(
      catalog
          .byId(NarrativeCommandIds.unlockFieldAbility)!
          .parameters
          .single
          .kind,
      NarrativeCommandParameterKind.fieldAbility,
    );

    final moveNpc = catalog.byId(NarrativeCommandIds.moveNpc)!;
    expect(moveNpc.isPublishable, isTrue);
    expect(
      moveNpc.capabilities.runtime,
      NarrativeCommandCapabilityStatus.supported,
    );
  });

  test('Finish Game is publishable after RM-012 runtime wiring', () {
    final command = NarrativeCommandCatalog.canonical().byId(
      NarrativeCommandIds.finishGame,
    )!;

    expect(command.backend, NarrativeCommandBackend.sceneConsequence);
    expect(command.wireId, 'SceneConsequence.finishGame');
    expect(command.isPersistent, isTrue);
    expect(
      command.capabilities.model,
      NarrativeCommandCapabilityStatus.supported,
    );
    expect(
      command.capabilities.editor,
      NarrativeCommandCapabilityStatus.supported,
    );
    expect(
      command.capabilities.runtime,
      NarrativeCommandCapabilityStatus.supported,
    );
    expect(command.isPublishable, isTrue);
    expect(
      command.parameters.map((parameter) => parameter.id),
      isNot(contains('endingId')),
    );
    expect(
      command.parameters
          .singleWhere((parameter) => parameter.id == 'outcome')
          .kind,
      NarrativeCommandParameterKind.completionOutcome,
    );
    expect(
      command.parameters
          .singleWhere((parameter) => parameter.id == 'postGamePolicy')
          .kind,
      NarrativeCommandParameterKind.postGamePolicy,
    );
  });

  test('canonical gameplay commands carry the corrected FG references', () {
    final catalog = NarrativeCommandCatalog.canonical();
    expect(catalog.byId(NarrativeCommandIds.healParty)!.fgLotId, 'FG-085');
    expect(catalog.byId(NarrativeCommandIds.awardBadge)!.fgLotId, 'FG-089');
    expect(
      catalog.byId(NarrativeCommandIds.unlockFieldAbility)!.fgLotId,
      'FG-089',
    );
    expect(catalog.byId(NarrativeCommandIds.warp)!.fgLotId, 'FG-090');
    expect(catalog.byId(NarrativeCommandIds.openShop)!.fgLotId, 'FG-091');
    expect(catalog.byId(NarrativeCommandIds.openHeal)!.fgLotId, 'FG-071');
    expect(catalog.byId(NarrativeCommandIds.openPc)!.fgLotId, 'FG-091');
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
