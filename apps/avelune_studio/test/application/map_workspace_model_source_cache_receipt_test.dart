import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';
import 'map_workspace_model_source_cache_fakes.dart';

void main() {
  test(
    'source receipt validates the whole batch before mutating projections',
    () async {
      final port = ModelSourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.ensureResourceKind('model3d');
      await controller.previewMap('first');
      final before = controller.project!;
      final preview = controller.previewDefinitionsFor('first');
      final visual = controller.visualProject;
      final current = before.copyWith(
        models3d: (before.models3d as ProjectModel3dEntries).replaceSelected([
          port.other.copyWith(name: 'Concurrent edit'),
        ]),
      );
      controller.project = current;
      port.previewGate = Completer<void>();
      final pending = controller.previewMap('preview');
      var notifications = 0;
      controller.addListener(() => notifications++);
      final replacements = {
        'tree': sourceModel('tree', 4),
        'other': sourceModel('other', 5),
      };
      expect(
        () => controller.acceptResources(
          before,
          before.copyWith(
            models3d: (before.models3d as ProjectModel3dEntries)
                .replaceSelected(replacements.values),
          ),
          changedModels: replacements,
        ),
        throwsA(
          isA<MapWorkspaceFailure>().having(
            (failure) => failure.problem,
            'problem',
            MapWorkspaceProblem.conflict,
          ),
        ),
      );
      expect(controller.project, same(current));
      expect(controller.previewDefinitionsFor('first'), same(preview));
      expect(controller.visualProject, same(visual));
      expect(controller.modelSourceSelectionsVisited, 0);
      expect(controller.modelSourcePreviewsVisited, 0);
      expect(controller.modelSourceProjectionLookups, 0);
      expect(notifications, 0);
      port.previewGate!.complete();
      await pending;
      expect(
        controller.previewDefinitionsFor('preview')!.models3d.single,
        same(port.tree),
      );
    },
  );

  test('source receipt accepts an already applied retry without restoring old fields', () async {
    final port = ModelSourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.previewMap('preview');
    final before = controller.project!;
    final replacement = sourceModel('tree', 4);
    final updated = before.copyWith(
      models3d: (before.models3d as ProjectModel3dEntries).replaceSelected([
        replacement,
      ]),
    );
    controller.acceptResources(
      before,
      updated,
      changedModels: {'tree': replacement},
    );
    final preview = controller.previewDefinitionsFor('preview');
    final current = controller.project!.copyWith(name: 'Current project');
    controller.project = current;
    controller.acceptResources(
      before,
      updated,
      changedModels: {'tree': replacement},
    );
    expect(controller.project, same(current));
    expect(controller.previewDefinitionsFor('preview'), same(preview));
    expect(controller.project!.models3d.single, same(replacement));
  });

  test(
    'source receipt allows a target absent from the active partial projection',
    () async {
      final port = ModelSourcePort(unrelatedMaps: 1);
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.activate(port.entries.last);
      await controller.activate(port.entries.first);
      final current = controller.project!;
      final before = current.copyWith(
        models3d: ProjectModel3dEntries.prepare([port.tree, port.other]),
      );
      final replacement = sourceModel('other', 5);
      controller.acceptResources(
        before,
        before.copyWith(
          models3d: (before.models3d as ProjectModel3dEntries).replaceSelected([
            replacement,
          ]),
        ),
        changedModels: {'other': replacement},
      );
      expect(controller.project, same(current));
      expect(controller.project!.models3d.single, same(port.tree));
      await controller.activate(port.entries.last);
      expect(controller.project!.models3d.single, same(replacement));
    },
  );

  test(
    'light then source receipt preserve cache indexes and collision metadata',
    () async {
      final port = ModelSourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.activate(port.entries[1]);
      await controller.previewMap('preview');
      final light = Model3dPointLight(localPosition: Model3dVector3.zero);
      await controller.acceptModelLight(
        port.tree.copyWith(light: light),
        'before',
        'after',
      );
      expect(
        controller.previewDefinitionsFor('preview')!.models3d.single.light,
        same(light),
      );
      final replacement = sourceModel(
        'tree',
        4,
      ).copyWith(light: light, collisionBounds: port.tree.inspection.bounds);
      final before = controller.project!;
      controller.acceptResources(
        before,
        before.copyWith(
          models3d: (before.models3d as ProjectModel3dEntries).replaceSelected([
            replacement,
          ]),
        ),
        changedModels: {'tree': replacement},
      );
      await controller.activate(port.entries.first);
      expect(controller.project!.models3d.single, same(replacement));
      expect(
        controller.project!.models3d.single.collisionBounds,
        port.tree.inspection.bounds,
      );
      expect(port.selectionReads, ['first', 'second']);
      expect(controller.modelSourceSelectionsVisited, 4);
    },
  );

  test('fresh canonical loads after a source receipt are not overwritten by its old definition', () async {
    final port = ModelSourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final before = controller.project!;
    final replacement = sourceModel('tree', 4);
    controller.acceptResources(
      before,
      before.copyWith(models3d: [replacement]),
      changedModels: {'tree': replacement},
    );
    final canonical = sourceModel(
      'tree',
      7,
    ).copyWith(name: 'Canonical edit', scale: 3);
    port.tree = canonical;
    await controller.previewMap('preview');
    expect(
      controller.previewDefinitionsFor('preview')!.models3d.single,
      same(canonical),
    );
    await controller.activate(port.entries[1]);
    expect(controller.project!.models3d.single, same(canonical));
    await controller.ensureResourceKind('model3d');
    expect(
      (controller.visualProject!.models3d as ProjectModel3dEntries).lookup(
        'tree',
      ),
      same(canonical),
    );
  });

  test('a preview started before a source receipt receives only its newer override', () async {
    final port = ModelSourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    port.previewGate = Completer<void>();
    final pending = controller.previewMap('preview');
    final before = controller.project!;
    final replacement = sourceModel('tree', 4);
    controller.acceptResources(
      before,
      before.copyWith(models3d: [replacement]),
      changedModels: {'tree': replacement},
    );
    port.previewGate!.complete();
    await pending;
    expect(
      controller.previewDefinitionsFor('preview')!.models3d.single,
      same(replacement),
    );
  });

  test(
    'a delayed selection cannot restore definitions from before a receipt',
    () async {
      final port = ModelSourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      port.gate = Completer<void>();
      final pending = controller.activate(port.entries[1]);
      final before = controller.project!;
      final replacement = sourceModel('tree', 4);
      controller.acceptResources(
        before,
        before.copyWith(models3d: [replacement]),
        changedModels: {'tree': replacement},
      );
      port.gate!.complete();
      await pending;
      expect(controller.project!.models3d.single, same(replacement));
    },
  );
}
