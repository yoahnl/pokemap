import 'dart:async';

import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_atmosphere_controller_fakes.dart';

void main() {
  test('refreshing saved map bytes retains the admitted clean atmosphere controller', () async {
    final port = AtmosphereWorkspacePort();
    final workspace = MapWorkspaceController(atmosphereSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final before = workspace.active!;
    final atmosphere = before.atmosphere!;
    atmosphere.edit(atmosphere.current.copyWith(waterAnimated: true));
    expect(await atmosphere.save(), isTrue);
    await workspace.refreshSavedMaps({'a'});
    expect(workspace.active, isNot(same(before)));
    expect(workspace.active!.atmosphere, same(atmosphere));
    expect(workspace.active!.atmosphere!.current.waterAnimated, isTrue);
    expect(workspace.active!.atmosphere!.dirty, isFalse);
    expect(port.loads, 1);
    expect(port.mapReads, 2);
  });

  test('refreshing only map bytes preserves atmosphere edits and an in-flight save', () async {
    final port = AtmosphereWorkspacePort();
    final workspace = MapWorkspaceController(atmosphereSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final atmosphere = workspace.active!.atmosphere!;
    atmosphere.edit(atmosphere.current.copyWith(waterAnimated: true));
    port.pending = Completer<void>();
    final save = atmosphere.save();
    atmosphere.edit(atmosphere.current.copyWith(windowsLit: true));
    await workspace.refreshSavedMaps({'a'});
    expect(workspace.active!.atmosphere, same(atmosphere));
    expect(workspace.active!.atmosphere!.saving, isTrue);
    expect(workspace.active!.atmosphere!.current.windowsLit, isTrue);
    port.pending!.complete();
    expect(await save, isTrue);
    expect(workspace.active!.atmosphere!.saving, isFalse);
    expect(workspace.active!.atmosphere!.dirty, isTrue);
    expect(workspace.active!.atmosphere!.current.windowsLit, isTrue);
    expect(port.loads, 1);
    expect(port.mapReads, 2);
  });

  test('global narrative publication saves atmosphere through the targeted boundary first', () async {
    final port = AtmosphereWorkspacePort();
    final workspace = MapWorkspaceController(atmosphereSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final publication = AtmosphereNarrativePort(workspace, port);
    final narrative = NarrativeWorkspaceController(
      workspace,
      publication,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    narrative.addFact('Village visité');
    final atmosphere = workspace.active!.atmosphere!;
    atmosphere.edit(atmosphere.current.copyWith(fireflies: true));
    expect(await narrative.save(document: workspace.active), isTrue);
    expect(port.saves.single.fireflies, isTrue);
    expect(publication.publications, 1);
    expect(publication.atmosphereWasSavedFirst, isTrue);
    expect(narrative.pendingFacts, isEmpty);
    expect(atmosphere.dirty, isFalse);
    expect(port.mapReads, 1);
    expect(port.mapWrites, 0);
    expect(port.loads, 1);
  });

  test('atmosphere failure blocks global publication while both drafts remain editable', () async {
    final port = AtmosphereWorkspacePort();
    final workspace = MapWorkspaceController(atmosphereSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final publication = AtmosphereNarrativePort(workspace, port);
    final narrative = NarrativeWorkspaceController(
      workspace,
      publication,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    narrative.addFact('Village visité');
    final atmosphere = workspace.active!.atmosphere!;
    atmosphere.edit(atmosphere.current.copyWith(fireflies: true));
    port.failure = StateError('Conflit ambiance');
    expect(await narrative.save(document: workspace.active), isFalse);
    expect(publication.publications, 0);
    expect(narrative.pendingFacts, hasLength(1));
    expect(atmosphere.dirty, isTrue);
    expect(atmosphere.saving, isFalse);
    expect(narrative.saving, isFalse);
    expect(workspace.active!.saving, isFalse);
    expect(atmosphere.error, contains('Conflit ambiance'));
    atmosphere.edit(atmosphere.current.copyWith(fireflyDensity: .6));
    expect(atmosphere.error, isNull);
    port.failure = null;
    expect(await narrative.save(document: workspace.active), isTrue);
    expect(publication.publications, 1);
    expect(narrative.pendingFacts, isEmpty);
    expect(atmosphere.dirty, isFalse);
    expect(port.mapReads, 1);
    expect(port.mapWrites, 0);
  });

  test('workspace opens the sidecar once and saves it without saving or reloading the map', () async {
    final port = AtmosphereWorkspacePort();
    final workspace = MapWorkspaceController(atmosphereSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final atmosphere = document.atmosphere!;
    expect(port.loads, 1);
    atmosphere.edit(atmosphere.current.copyWith(waterAnimated: true));
    expect(workspace.dirty, isTrue);
    expect(document.dirty, isFalse);
    expect(await workspace.saveAll(), isTrue);
    expect(port.loads, 1);
    expect(port.mapReads, 1);
    expect(port.mapWrites, 0);
    expect(workspace.dirty, isFalse);
    await workspace.activate(port.entry);
    expect(port.loads, 1);
    expect(workspace.active!.atmosphere, same(atmosphere));
  });

  test('overlapping activation shares the initial atmosphere load', () async {
    final port = AtmosphereWorkspacePort()..pendingLoad = Completer<void>();
    final workspace = MapWorkspaceController(atmosphereSession, port)
      ..project = port.manifest;
    addTearDown(workspace.dispose);
    final first = workspace.activate(port.entry);
    final second = workspace.activate(port.entry);
    await Future<void>.delayed(Duration.zero);
    expect(port.loads, 1);
    port.pendingLoad!.complete();
    await Future.wait([first, second]);
    expect(port.loads, 1);
    expect(workspace.active!.atmosphere, isNotNull);
  });

  test(
    'edits stay local and first save persists only the atmosphere draft',
    () async {
      final port = AtmospherePort();
      final controller = await MapAtmosphereController.open(
        atmosphereSession,
        'river',
        port,
      );
      addTearDown(controller.dispose);
      var notices = 0;
      controller.addListener(() => notices++);
      controller.edit(controller.current.copyWith(waterAnimated: true));
      expect(controller.dirty, isTrue);
      expect(port.loads, 1);
      expect(port.saves, isEmpty);
      expect(notices, 1);
      expect(await controller.save(), isTrue);
      expect(controller.dirty, isFalse);
      expect(port.loads, 1);
      expect(port.saves.single.waterAnimated, isTrue);
      expect(port.revisions, ['r0']);
      controller.edit(controller.current.copyWith(windowsLit: true));
      controller.undo();
      expect(controller.current.windowsLit, isFalse);
      controller.redo();
      expect(controller.current.windowsLit, isTrue);
      expect(await controller.save(), isTrue);
      expect(port.revisions, ['r0', 'r1']);
    },
  );

  test(
    'an edit during persistence remains dirty and a failed save stays editable',
    () async {
      final port = AtmospherePort();
      final controller = await MapAtmosphereController.open(
        atmosphereSession,
        'river',
        port,
      );
      addTearDown(controller.dispose);
      controller.edit(controller.current.copyWith(fireflies: true));
      port.pending = Completer<void>();
      final saving = controller.save();
      expect(controller.saving, isTrue);
      controller.edit(controller.current.copyWith(fireflyDensity: .5));
      port.pending!.complete();
      expect(await saving, isTrue);
      expect(controller.dirty, isTrue);
      expect(controller.current.fireflyDensity, .5);
      port.failure = StateError('Conflit concurrent');
      expect(await controller.save(), isFalse);
      expect(controller.saving, isFalse);
      expect(controller.dirty, isTrue);
      expect(controller.error, contains('Conflit concurrent'));
      controller.edit(controller.current.copyWith(fireflyDensity: .7));
      expect(controller.error, isNull);
    },
  );
}
