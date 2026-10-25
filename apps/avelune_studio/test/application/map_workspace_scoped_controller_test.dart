import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  test('working initialization opens the configured new game map', () async {
    final port = ScopedTestMapPort(
      metadata: scopedMapMetadata.copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'second',
          startSpawnId: 'start',
        ),
      ),
    );
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.active!.current.id, 'second');
    expect(port.selections, ['second']);
    expect(port.fullReads, 0);
  });

  test('working initialization and map activation retain only the active selection', () async {
    final port = ScopedTestMapPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(port.fullReads, 0);
    expect(controller.projectScope, MapWorkspaceProjectScope.mapSelection);
    expect(controller.project!.tilesets.map((e) => e.id), ['first']);
    await controller.activate(secondScopedMap);
    expect(controller.project!.tilesets.map((e) => e.id), ['second']);
    await controller.activate(firstScopedMap);
    expect(controller.project!.tilesets.map((e) => e.id), ['first']);
    expect(port.selections, ['first', 'second']);
    expect(controller.hasCompleteProject, isFalse);
  });

  test('resource family loading preserves map dependencies and only registers its closure', () async {
    final port = ScopedTestMapPort(
      resourceDefinitions: {
        'tileset': scopedMapMetadata.copyWith(
          tilesets: [scopedMapTilesets.last],
        ),
        'model3d': scopedMapMetadata,
      },
    );
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final mapVisuals = controller.visualProject;
    await controller.ensureWorkshop(MapWorkspaceWorkshop.story);
    expect(controller.visualProject, same(mapVisuals));
    await controller.ensureResourceKind('tileset');
    expect(controller.project!.tilesets.map((value) => value.id), [
      'first',
      'second',
    ]);
    expect(controller.visualProject!.tilesets.map((value) => value.id), [
      'first',
      'second',
    ]);
    final visual = controller.visualProject;
    expect(controller.visualProject, same(visual));
    await controller.ensureResourceKind('model3d');
    expect(controller.project!.tilesets.map((value) => value.id), ['first']);
    await controller.activate(secondScopedMap);
    expect(controller.project!.tilesets.map((value) => value.id), ['second']);
    expect(port.resourceKinds, ['tileset', 'model3d']);
    expect(port.fullReads, 0);
  });

  test(
    'returning to the loaded family supersedes an older delayed family',
    () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      final port = ScopedTestMapPort(
        resourceDefinitions: {
          'tileset': scopedMapMetadata.copyWith(
            tilesets: [scopedMapTilesets.last],
          ),
        },
        beforeResourceRead: (kind) async {
          if (kind == 'model3d') {
            started.complete();
            await gate.future;
          }
        },
      );
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.ensureResourceKind('tileset');
      final older = controller.ensureResourceKind('model3d');
      await started.future;
      final latest = controller.ensureResourceKind('tileset');
      gate.complete();
      await Future.wait([older, latest]);
      expect(controller.hasResourceKind('tileset'), isTrue);
      expect(controller.project!.tilesets.map((value) => value.id), [
        'first',
        'second',
      ]);
      expect(port.resourceKinds, ['tileset', 'model3d', 'tileset']);
    },
  );

  test('complete workshops are an explicit materialization which retains map drafts', () async {
    final port = ScopedTestMapPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final active = controller.active!;
    active.current = active.current.copyWith(name: 'Brouillon conservé');
    await controller.materializeProject();
    expect(port.fullReads, 1);
    expect(controller.hasCompleteProject, isTrue);
    expect(controller.project!.tilesets, hasLength(2));
    expect(controller.active, same(active));
    expect(controller.active!.current.name, 'Brouillon conservé');
  });
  test(
    'library refresh retains drafts and refreshes cached map selections lazily',
    () async {
      final port = ScopedTestMapPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final first = controller.active!;
      first.current = first.current.copyWith(name: 'Brouillon première');
      await controller.activate(secondScopedMap);
      final second = controller.active!;
      second.current = second.current.copyWith(name: 'Brouillon seconde');
      await controller.refreshCatalogSelection();
      expect(controller.active, same(second));
      expect(controller.active!.current.name, 'Brouillon seconde');
      expect(port.selections, ['first', 'second', 'second']);
      await controller.activate(firstScopedMap);
      expect(controller.active, same(first));
      expect(controller.active!.current.name, 'Brouillon première');
      expect(controller.project!.tilesets.map((entry) => entry.id), ['first']);
      expect(port.selections, ['first', 'second', 'second', 'first']);
      expect(port.fullReads, 0);
    },
  );
}
