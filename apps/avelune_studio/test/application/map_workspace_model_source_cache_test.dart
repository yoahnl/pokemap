import 'dart:async';
import 'dart:collection';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  test(
    'source receipt survives cached activation and preview definitions',
    () async {
      final port = _SourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final first = controller.active!;
      first.current = first.current.copyWith(name: 'Unsaved draft');
      await controller.activate(port.entries[1]);
      final second = controller.active!;
      await controller.previewMap('preview');
      final before = controller.project!;
      final replacement = _model('tree', 4);
      controller.acceptResources(
        before,
        before.copyWith(models3d: [replacement]),
        changedModels: {'tree': replacement},
      );
      expect(
        controller.previewDefinitionsFor('preview')!.models3d.single,
        same(replacement),
      );
      await controller.activate(port.entries.first);
      expect(controller.project!.models3d.single, same(replacement));
      expect(controller.active, same(first));
      expect(controller.active!.current.name, 'Unsaved draft');
      expect(controller.active!.dirty, isTrue);
      await controller.activate(port.entries[1]);
      expect(controller.project!.models3d.single, same(replacement));
      expect(controller.active, same(second));
      expect(port.selectionReads, ['first', 'second']);
      expect(port.previewReads, ['preview']);
    },
  );

  test(
    'resource family and cached visual composition keep replaced definitions',
    () async {
      final port = _SourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.ensureResourceKind('model3d');
      final beforeVisual = controller.visualProject!;
      final replacement = _model('tree', 4);
      final before = controller.project!;
      controller.acceptResources(
        before,
        before.copyWith(models3d: [replacement, port.other]),
        changedModels: {'tree': replacement},
      );
      expect(controller.visualProject!.models3d.first, same(replacement));
      expect(
        controller.visualProject!.models3d.last,
        same(beforeVisual.models3d.last),
      );
      await controller.activate(port.entries[1]);
      expect(controller.visualProject!.models3d.first, same(replacement));
      await controller.activate(port.entries.first);
      expect(controller.project!.models3d.first, same(replacement));
    },
  );

  for (final unrelated in [0, 2000]) {
    test(
      'source receipt accepts equal distinct projections without reading $unrelated unrelated maps',
      () async {
        final port = _SourcePort(unrelatedMaps: unrelated);
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final loaded = controller.project!;
        final currentMaps = _CountingMapEntries(loaded.maps);
        final receiptMaps = _CountingMapEntries(loaded.maps);
        controller.project = loaded.copyWith(maps: currentMaps);
        final before = loaded.copyWith(maps: receiptMaps);
        expect(identical(controller.project, before), isFalse);
        expect(controller.project, before);
        final replacement = _model('tree', 4);
        final updated = before.copyWith(
          models3d: (before.models3d as ProjectModel3dEntries)
              .replaceSelected([replacement]),
        );
        currentMaps.resetReads();
        receiptMaps.resetReads();
        controller.acceptResources(
          before,
          updated,
          changedModels: {'tree': replacement},
        );
        expect(
          (currentMaps.elementReads, receiptMaps.elementReads),
          (0, 0),
        );
        expect(
          (currentMaps.lengthReads, receiptMaps.lengthReads),
          (0, 0),
        );
        expect(controller.project!.models3d.single, same(replacement));
      },
    );

    test(
      'replacement only visits cached dependencies with $unrelated unrelated maps and definitions',
      () async {
        final port = _SourcePort(unrelatedMaps: unrelated);
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        await controller.activate(port.entries[1]);
        await controller.previewMap('preview');
        for (final entry in port.entries.skip(3)) {
          await controller.activate(entry);
          await controller.previewMap(entry.id);
        }
        await controller.activate(port.entries.first);
        await controller.ensureResourceKind('model3d');
        final builds = controller.visualProjectionBuilds;
        expect(builds, greaterThan(0));
        final beforeVisual = controller.visualProject!;
        final untouched = controller.previewDefinitionsFor('unrelated-0');
        final before = controller.project!;
        final replacement = _model('tree', 4);
        controller.acceptResources(
          before,
          before.copyWith(
            models3d: (before.models3d as ProjectModel3dEntries)
                .replaceSelected([replacement]),
          ),
          changedModels: {'tree': replacement},
        );
        expect(controller.modelSourceSelectionsVisited, 2);
        expect(controller.modelSourcePreviewsVisited, 1);
        expect(controller.modelSourceProjectionLookups, 7);
        final visual = controller.visualProject!;
        expect(controller.visualProjectionBuilds, builds);
        expect(controller.modelSourceProjectionLookups, 7);
        expect(visual.models3d, isA<ProjectModel3dEntries>());
        expect(
          (visual.models3d as ProjectModel3dEntries).lookup('tree'),
          same(replacement),
        );
        expect(
          (visual.models3d as ProjectModel3dEntries).lookup('other'),
          same(
            (beforeVisual.models3d as ProjectModel3dEntries).lookup('other'),
          ),
        );
        expect(
          controller.previewDefinitionsFor('unrelated-0'),
          same(untouched),
        );
        expect(port.selectionReads.length, unrelated + 2);
        expect(port.previewReads.length, unrelated + 1);
      },
    );
  }

  test('source receipt preserves current fields outside its changed models', () async {
    final port = _SourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.ensureResourceKind('model3d');
    final before = controller.project!;
    final replacement = _model('tree', 4);
    final unrelated = port.other.copyWith(name: 'Current unrelated model');
    final currentMaps = _CountingMapEntries([
      for (final map in before.maps) map.copyWith(name: 'Current ${map.name}'),
    ]);
    final current = before.copyWith(
      name: 'Current project',
      maps: currentMaps,
      globalProperties: {'current': true},
      models3d: (before.models3d as ProjectModel3dEntries)
          .replaceSelected([unrelated]),
    );
    controller.project = current;
    currentMaps.resetReads();
    controller.acceptResources(
      before,
      before.copyWith(models3d: (before.models3d as ProjectModel3dEntries)
          .replaceSelected([replacement])),
      changedModels: {'tree': replacement},
    );
    expect((currentMaps.elementReads, currentMaps.lengthReads), (0, 0));
    expect(controller.project!.name, 'Current project');
    expect(controller.project!.maps, current.maps);
    expect(controller.project!.globalProperties, current.globalProperties);
    final models = controller.project!.models3d as ProjectModel3dEntries;
    expect(models.lookup('tree'), same(replacement));
    expect(models.lookup('other'), same(unrelated));
  });

  test('source receipt validates the whole batch before mutating projections', () async {
    final port = _SourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.ensureResourceKind('model3d');
    await controller.previewMap('first');
    final before = controller.project!;
    final preview = controller.previewDefinitionsFor('first');
    final visual = controller.visualProject;
    final current = before.copyWith(
      models3d: (before.models3d as ProjectModel3dEntries)
          .replaceSelected([port.other.copyWith(name: 'Concurrent edit')]),
    );
    controller.project = current;
    port.previewGate = Completer<void>();
    final pending = controller.previewMap('preview');
    var notifications = 0;
    controller.addListener(() => notifications++);
    final replacements = {'tree': _model('tree', 4), 'other': _model('other', 5)};
    expect(
      () => controller.acceptResources(
        before,
        before.copyWith(models3d: (before.models3d as ProjectModel3dEntries)
            .replaceSelected(replacements.values)),
        changedModels: replacements,
      ),
      throwsA(isA<MapWorkspaceFailure>().having(
        (failure) => failure.problem, 'problem', MapWorkspaceProblem.conflict)),
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
    expect(controller.previewDefinitionsFor('preview')!.models3d.single, same(port.tree));
  });

  test('source receipt accepts an already applied retry without restoring old fields', () async {
    final port = _SourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.previewMap('preview');
    final before = controller.project!;
    final replacement = _model('tree', 4);
    final updated = before.copyWith(models3d: (before.models3d as ProjectModel3dEntries)
        .replaceSelected([replacement]));
    controller.acceptResources(before, updated, changedModels: {'tree': replacement});
    final preview = controller.previewDefinitionsFor('preview');
    final current = controller.project!.copyWith(name: 'Current project');
    controller.project = current;
    controller.acceptResources(before, updated, changedModels: {'tree': replacement});
    expect(controller.project, same(current));
    expect(controller.previewDefinitionsFor('preview'), same(preview));
    expect(controller.project!.models3d.single, same(replacement));
  });

  test('source receipt allows a target absent from the active partial projection', () async {
    final port = _SourcePort(unrelatedMaps: 1);
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(port.entries.last);
    await controller.activate(port.entries.first);
    final current = controller.project!;
    final before = current.copyWith(
      models3d: ProjectModel3dEntries.prepare([port.tree, port.other]),
    );
    final replacement = _model('other', 5);
    controller.acceptResources(
      before,
      before.copyWith(models3d: (before.models3d as ProjectModel3dEntries)
          .replaceSelected([replacement])),
      changedModels: {'other': replacement},
    );
    expect(controller.project, same(current));
    expect(controller.project!.models3d.single, same(port.tree));
    await controller.activate(port.entries.last);
    expect(controller.project!.models3d.single, same(replacement));
  });

  test(
    'light then source receipt preserve cache indexes and collision metadata',
    () async {
      final port = _SourcePort();
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
      final replacement = _model(
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
    final port = _SourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final before = controller.project!;
    final replacement = _model('tree', 4);
    controller.acceptResources(
      before,
      before.copyWith(models3d: [replacement]),
      changedModels: {'tree': replacement},
    );
    final canonical = _model(
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
    final port = _SourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    port.previewGate = Completer<void>();
    final pending = controller.previewMap('preview');
    final before = controller.project!;
    final replacement = _model('tree', 4);
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
      final port = _SourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      port.gate = Completer<void>();
      final pending = controller.activate(port.entries[1]);
      final before = controller.project!;
      final replacement = _model('tree', 4);
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

ProjectModel3dEntry _model(String id, double width) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: '$id-source',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: width, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

final class _CountingMapEntries extends ListBase<ProjectMapEntry> {
  _CountingMapEntries(Iterable<ProjectMapEntry> entries)
    : _entries = List.of(entries);

  final List<ProjectMapEntry> _entries;
  int elementReads = 0;
  int lengthReads = 0;

  void resetReads() {
    elementReads = 0;
    lengthReads = 0;
  }

  @override
  int get length {
    lengthReads++;
    return _entries.length;
  }

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  ProjectMapEntry operator [](int index) {
    elementReads++;
    return _entries[index];
  }

  @override
  void operator []=(int index, ProjectMapEntry value) =>
      throw UnsupportedError('immutable');
}

final class _SourcePort extends ScopedTestMapPort
    implements MapWorkspacePreviewSelectionPort {
  _SourcePort({int unrelatedMaps = 0})
    : super(
        metadata: ProjectManifest(
          name: 'Sources',
          maps: [
            for (final id in [
              'first',
              'second',
              'preview',
              for (var i = 0; i < unrelatedMaps; i++) 'unrelated-$i',
            ])
              ProjectMapEntry(id: id, name: id, relativePath: '$id.json'),
          ],
          tilesets: const [],
        ),
      );
  List<ProjectMapEntry> get entries => metadata.maps;
  var tree = _model('tree', 1);
  final other = _model('other', 2);
  final selectionReads = <String>[], previewReads = <String>[];
  Completer<void>? gate;
  Completer<void>? previewGate;

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    selectionReads.add(entry.id);
    final selection = await _selection(session, entry);
    await gate?.future;
    return selection;
  }

  Future<MapWorkspaceSelection> _selection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => MapWorkspaceSelection(
    document: await loadMap(session, entry),
    definitions: metadata.copyWith(
      models3d: [entry.id.startsWith('unrelated-') ? other : tree],
    ),
    catalogRevision: 'catalog-1',
    snapshotRevision: 'snapshot-1',
  );

  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    previewReads.add(entry.id);
    final selection = await _selection(session, entry);
    await previewGate?.future;
    return selection;
  }

  @override
  Future<MapWorkspaceCatalog> loadResourceKind(
    ProjectSession session,
    String canonicalKind,
  ) async => MapWorkspaceCatalog(
    metadata: metadata.copyWith(
      models3d: [
        tree,
        other,
        for (final entry in entries.skip(3)) _model(entry.id, 2),
      ],
    ),
    revision: 'catalog-1',
  );
}
