import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  late MapWorkspaceController controller;
  late MapWorkspaceConnectionActions links;
  setUp(() async {
    fixture = await MapCatalogFixture.create();
    controller = fixture.controller;
    links = MapWorkspaceConnectionActions(
      controller: controller,
      port: LocalMapConnectionAdapter(fixture.adapter),
      isActive: () => true,
      changed: () {},
    );
  });
  tearDown(() => fixture.dispose());

  Future<Map<String, String>> maps() async => {
    for (final id in ['jardin', 'clairiere'])
      id: await File(p.join(fixture.root.path, 'maps', '$id.json'))
          .readAsString(),
  };

  MapConnection? east() => controller.active!.current.connections
      .where((entry) => entry.direction == MapConnectionDirection.east)
      .firstOrNull;

  test(
    'updating a connection is undone and redone on both maps without Save',
    () async {
      expect(controller.active!.base.mapId, 'jardin');
      await links.link(MapConnectionDirection.east, 'clairiere', 0);
      expect(links.error, isNull);
      final linked = await maps();

      await links.link(MapConnectionDirection.east, 'clairiere', 3);
      expect(links.error, isNull);
      expect(east()!.offset, 3);
      final updated = await maps();
      expect(controller.dirty, isFalse);
      expect(controller.canStepHistory(redo: false), isTrue);

      await controller.stepHistory(redo: false);
      expect(controller.active!.error, isNull);
      expect(east()!.offset, 0);
      expect(await maps(), linked);
      expect(controller.dirty, isFalse);

      await controller.stepHistory(redo: true);
      expect(controller.active!.error, isNull);
      expect(east()!.offset, 3);
      expect(await maps(), updated);

      await controller.stepHistory(redo: false);
      expect(controller.active!.error, isNull);
      expect(east()!.offset, 0);
      expect(await maps(), linked);
      await controller.stepHistory(redo: false);
      expect(controller.active!.error, isNull);
      expect(east(), isNull);
    },
  );

  test(
    'an unsaved edit on the other map blocks the undo and is kept',
    () async {
      await links.link(MapConnectionDirection.east, 'clairiere', 0);
      final before = await maps();
      await controller.activate(
        controller.project!.maps.firstWhere((entry) => entry.id == 'clairiere'),
      );
      final other = controller.active!;
      other.commit(other.current.copyWith(name: 'Brouillon'));
      await controller.activate(
        controller.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
      );
      expect(controller.canStepHistory(redo: false), isTrue);

      await controller.stepHistory(redo: false);
      expect(controller.active!.error, contains('Brouillon'));
      expect(other.current.name, 'Brouillon');
      expect(other.dirty, isTrue);
      expect(east(), isNotNull);
      expect(await maps(), before);
    },
  );
}
