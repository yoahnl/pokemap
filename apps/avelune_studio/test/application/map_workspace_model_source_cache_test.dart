import 'dart:collection';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/scoped_map_workspace_port.dart';
import 'map_workspace_model_source_cache_fakes.dart';

void main() {
  test(
    'source receipt survives cached activation and preview definitions',
    () async {
      final port = ModelSourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final first = controller.active!;
      first.current = first.current.copyWith(name: 'Unsaved draft');
      await controller.activate(port.entries[1]);
      final second = controller.active!;
      await controller.previewMap('preview');
      final before = controller.project!;
      final replacement = sourceModel('tree', 4);
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
      final port = ModelSourcePort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.ensureResourceKind('model3d');
      final beforeVisual = controller.visualProject!;
      final replacement = sourceModel('tree', 4);
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
        final port = ModelSourcePort(unrelatedMaps: unrelated);
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
        final replacement = sourceModel('tree', 4);
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
        final port = ModelSourcePort(unrelatedMaps: unrelated);
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
        final replacement = sourceModel('tree', 4);
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
    final port = ModelSourcePort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.ensureResourceKind('model3d');
    final before = controller.project!;
    final replacement = sourceModel('tree', 4);
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
}

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
