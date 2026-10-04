import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_catalog_fixture.dart';

void main() {
  test(
    'undo refuses removed definitions without erasing unrelated history',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.controller;
      final document = controller.active!;
      final project = controller.project!;
      final element = project.elements.first;
      final withDecor = document.current;
      document.commit(
        withDecor.copyWith(
          placedElements: [
            for (final placed in withDecor.placedElements)
              if (placed.elementId != element.id) placed,
          ],
        ),
      );
      final before = document.current;
      final history = document.undoCount;
      controller.acceptResources(
        project,
        project.copyWith(
          elements: [
            for (final entry in project.elements)
              if (entry.id != element.id) entry,
          ],
        ),
      );
      controller.restore(redo: false);
      expect(document.current, before);
      expect(document.undoCount, history);
      expect(document.error, contains('décor supprimé'));
      document.commit(before.copyWith(properties: {'ordinary': true}));
      controller.restore(redo: false);
      expect(document.current, before);
      expect(document.error, isNull);
      controller.restore(redo: true);
      expect(document.current.properties['ordinary'], true);
    },
  );

  test('a stale decor brush cannot place a removed definition', () async {
    final fixture = await MapCatalogFixture.create();
    addTearDown(fixture.dispose);
    final controller = fixture.controller;
    final document = controller.active!;
    final project = controller.project!;
    final stale = project.elements.first;
    final updated = project.copyWith(elements: []);
    controller.acceptResources(project, updated);
    final before = document.current;
    final result = MapEditingCommands(
      document,
      updated,
    ).place(stale, const GridPos(x: 2, y: 2));
    expect(result, isNull);
    expect(document.current, before);
    expect(document.error, contains('plus disponible'));
  });
}
