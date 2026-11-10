import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../map_workspace/map_catalog_fixture.dart';

void main() {
  test(
    'renaming an inactive map does not activate it or open its document',
    () async {
      final parent = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
      );
      await parent.create(recursive: true);
      final fixture = await MapCatalogFixture.create(parent: parent);
      addTearDown(fixture.dispose);
      final controller = fixture.controller;
      final active = controller.active!;
      final target = controller.project!.maps.firstWhere(
        (entry) => entry.id != active.current.id,
      );
      expect(controller.documents.containsKey(target.id), isFalse);
      final rename = WorkspaceMapRename(controller, target)
        ..name = 'Carte renommée';
      expect(await rename.submit(), isNull);
      expect(controller.active, same(active));
      expect(controller.documents.containsKey(target.id), isFalse);
      expect(
        controller.project!.maps
            .singleWhere((entry) => entry.id == target.id)
            .name,
        'Carte renommée',
      );
      expect(fixture.catalog.mutations, 1);
    },
  );
}
