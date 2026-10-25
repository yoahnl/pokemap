import 'dart:collection';

import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'map edits reuse the resource index without reading unrelated resources',
    () {
      final resources = _CountingList([
        workspaceElement,
        for (var i = 0; i < 1000; i++)
          workspaceElement.copyWith(id: 'unrelated-$i'),
      ]);
      final project = workspaceProject.copyWith(elements: resources);
      final index = MapElementResourceIndex(project);
      expect(resources.reads, greaterThan(1000));
      resources.reads = 0;
      final before = workspaceMap('a');
      final after = before.copyWith(layers: before.layers.reversed.toList());
      MapElementCatalog(before, project, resources: index);
      MapElementCatalog(after, project, resources: index);
      expect(resources.reads, 0);
    },
  );

  test(
    'placed resources retain the library family selected by their author',
    () {
      final project = workspaceProject.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'tree',
              familyId: 'trees',
            ),
          ],
        ),
      );
      final map = workspaceMap('a').copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'tree-a',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      expect(
        MapElementCatalog(map, project).families['Décors · Arbres']!.single.id,
        'tree-a',
      );
    },
  );

  test('duplicate layer names keep independent reorder scopes', () {
    final map = workspaceMap('a').copyWith(
      layers: const [
        MapLayer.tile(id: 'a', name: 'Sol'),
        MapLayer.tile(id: 'b', name: 'Sol'),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'tree-a',
          layerId: 'a',
          elementId: 'tree',
          pos: GridPos(x: 1, y: 1),
        ),
        MapPlacedElement(
          id: 'tree-b',
          layerId: 'b',
          elementId: 'tree',
          pos: GridPos(x: 1, y: 1),
        ),
      ],
    );
    final catalog = MapElementCatalog(map, workspaceProject);
    final decors = catalog.stacking.entries
        .where((entry) => entry.key != 'Calques')
        .toList();
    expect(decors, hasLength(2));
    expect(decors[0].value.single.layerId, 'a');
    expect(decors[1].value.single.layerId, 'b');
    expect(decors[0].key, isNot(decors[1].key));
  });

  test('legacy bottom-to-top storage is displayed front-first', () {
    final map = workspaceMap('a').copyWith(
      layers: const [
        MapLayer.tile(id: 'a', name: 'Sol'),
        MapLayer.tile(id: 'b', name: 'Toit'),
      ],
      properties: {'tileLayerOrder': 'bottom_to_top'},
    );
    expect(
      MapElementCatalog(
        map,
        workspaceProject,
      ).stacking['Calques']!.map((entry) => entry.id),
      ['b', 'a'],
    );
  });
}

final class _CountingList<T> extends ListBase<T> {
  _CountingList(this.values);
  final List<T> values;
  int reads = 0;
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  T operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) => values[index] = value;
}
