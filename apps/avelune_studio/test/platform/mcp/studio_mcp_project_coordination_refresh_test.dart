import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../support/scoped_map_workspace_port.dart';
import 'studio_mcp_project_coordination_fakes.dart';

void main() {
  for (final field in ['surf', 'fieldAbilities', 'audio']) {
    test(
      'external $field replaces only its accepted overlay across map activation',
      () async {
        final port = CoordinationPort();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        const surf = ProjectSurfSettings(enabled: true);
        final abilities = ProjectFieldAbilitiesSettings.fromIds(['cut']);
        final audio = ProjectAudioSettings();
        controller.acceptSurfConfiguration(surf);
        controller.acceptFieldAbilities(abilities);
        controller.acceptAudio(audio);
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Human draft'));
        final undo = a.undoToken;
        port.externalMetadata = scopedMapMetadata.copyWith(
          settings: ProjectSettings(
            surf: const ProjectSurfSettings(enabled: false),
            fieldAbilities: null,
            audio: null,
          ),
        );
        await controller.acceptExternalMutation({
          (kind: 'project', id: 'project'),
          (kind: 'projectSettings', id: field),
        });
        expect(controller.error, isNull);
        expect(controller.active, same(a));
        expect(a.undoToken, same(undo));
        expect(a.current.name, 'Human draft');
        await controller.activate(secondScopedMap);
        final settings = controller.project!.settings;
        expect(settings.surf?.enabled, field == 'surf' ? isFalse : isTrue);
        expect(
          settings.fieldAbilities,
          field == 'fieldAbilities' ? isNull : same(abilities),
        );
        expect(settings.audio, field == 'audio' ? isNull : same(audio));
      },
    );
  }

  test('mutation refreshes A without reading or invalidating B', () async {
    final port = CoordinationPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(secondScopedMap);
    final b = controller.active;
    final previewB = controller.previewMap(secondScopedMap.id);
    await previewB;
    port.selections.clear();
    port.revision = 'map-external';
    await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
    expect(controller.documents['first']!.base.revision, 'map-external');
    expect(controller.documents['first']!.current.name, 'Externe');
    expect(controller.documents['second'], same(b));
    expect(controller.previewMap(secondScopedMap.id), same(previewB));
    expect(port.selections, ['first']);
    expect(port.fullReads, 0);
    expect(port.baselines, 1);
  });

  test(
    'a changed dependency refreshes only selections using that resource',
    () async {
      final port = CoordinationPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.activate(secondScopedMap);
      final b = controller.active;
      port.selections.clear();
      await controller.acceptExternalMutation({(kind: 'tileset', id: 'first')});
      expect(port.selections, ['first']);
      expect(controller.documents['second'], same(b));
    },
  );

  test(
    'typing during a refresh retains the new draft and its original baseline',
    () async {
      final port = CoordinationPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      final started = Completer<void>();
      final release = Completer<void>();
      port.beforeLoad = () {
        started.complete();
        return release.future;
      };
      final refresh = controller.acceptExternalMutation({
        (kind: 'map', id: 'first'),
      });
      await started.future;
      a.commit(a.current.copyWith(name: 'New keystroke'));
      release.complete();
      await refresh;
      expect(controller.active, same(a));
      expect(a.current.name, 'New keystroke');
      expect(a.base.revision, 'map-1');
      expect(a.canUndo, isTrue);
      expect(a.error, contains('externe'));
    },
  );

  test('changed character invalidates its workshops without reading an unrelated workshop', () async {
    final port = CoordinationPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.ensureWorkshop(MapWorkspaceWorkshop.dialogue);
    await controller.ensureWorkshop(MapWorkspaceWorkshop.regionalMap);
    await controller.acceptExternalMutation({
      (kind: 'character', id: 'changed'),
    });
    expect(controller.hasWorkshop(MapWorkspaceWorkshop.dialogue), isFalse);
    expect(controller.hasWorkshop(MapWorkspaceWorkshop.regionalMap), isTrue);
    expect(port.workshops, [
      MapWorkspaceWorkshop.dialogue,
      MapWorkspaceWorkshop.regionalMap,
    ]);
    expect(port.fullReads, 0);
  });

  for (final savedHistory in [false, true]) {
    test(
      'identical map replay preserves ${savedHistory ? 'saved history' : 'dirty geometry'} until bytes really change',
      () async {
        final port = CoordinationPort();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        port.revision = 'accepted-publication';
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Human draft'));
        if (savedHistory) a.acceptSave(a.current, a.base.revision);
        final base = a.base;
        final undo = a.undoToken;
        final preview = controller.previewMap('first');
        await preview;
        port.selections.clear();
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        expect(controller.active, same(a));
        expect(a.current.name, 'Human draft');
        expect(a.base, same(base));
        expect(a.undoToken, same(undo));
        expect(a.error, isNull);
        expect(controller.error, isNull);
        expect(controller.previewMap('first'), same(preview));
        expect(port.selections, isEmpty);
        port.revision = 'new-durable-write';
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        expect(controller.active, same(a));
        expect(a.current.name, 'Human draft');
        expect(a.base, same(base));
        expect(a.undoToken, same(undo));
        expect(a.error, contains('externe'));
        expect(await controller.save(a), isFalse);
      },
    );
  }

  for (final operation in ['field', 'traversal', 'order']) {
    test(
      'an in-flight native map operation retains its owner on external change: $operation',
      () async {
        final port = CoordinationPort();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final a = controller.active!;
        switch (operation) {
          case 'field':
            a.spatialFieldObstacleSaving = true;
          case 'traversal':
            a.fieldTraversalSaving = true;
          case 'order':
            a.elementOrderSaving = true;
        }
        port.revision = 'new-durable-write';
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        expect(controller.active, same(a));
        expect(controller.documents['first'], same(a));
        expect(a.base.revision, 'map-1');
        expect(a.error, contains('externe'));
      },
    );
  }
}
