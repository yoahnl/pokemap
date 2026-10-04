import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  late MapWorkspaceController controller;

  setUp(() async {
    fixture = await MapCatalogFixture.create();
    final project = fixture.controller.project!;
    final animated = project.copyWith(
      elements: [
        for (final element in project.elements)
          element.copyWith(frames: [...element.frames, element.frames.first]),
      ],
    );
    await File(
      p.join(fixture.root.path, 'project.json'),
    ).writeAsString(jsonEncode(animated.toJson()));
    fixture.controller.dispose();
    controller = MapWorkspaceController(
      fixture.session,
      fixture.adapter,
      catalogPort: fixture.catalog,
    );
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await fixture.dispose();
  });

  test(
    'undo refuses a deleted decor destination and retains other history',
    () async {
      final created = await controller.mutateCatalog('map.create', {
        'mapId': 'history-destination',
        'name': 'Destination historique',
        'width': 7,
        'height': 5,
      });
      expect(created.integrated, isTrue, reason: created.error);
      final target = controller.project!.maps.last;
      final document = controller.active!;
      final before = document.current;
      final withPassage = before.copyWith(
        placedElements: [
          before.placedElements.first.copyWith(
            behaviors: const [
              MapPlacedElementBehavior(
                id: 'decor-passage',
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.traverseWarp,
                  targetMapId: 'history-destination',
                  targetPos: GridPos(x: 1, y: 1),
                ),
              ),
            ],
          ),
          ...before.placedElements.skip(1),
        ],
      );
      document.commit(withPassage);
      expect(await controller.save(document), isTrue, reason: document.error);
      document.commit(before);
      expect(await controller.save(document), isTrue, reason: document.error);
      controller.restore(redo: false);
      expect(document.current, withPassage);
      controller.restore(redo: true);
      expect(document.current, before);
      expect(document.dirty, isFalse);

      final removed = await controller.mutateCatalog('map.delete_apply', {
        'mapId': target.id,
      }, confirmDestructive: true);
      expect(removed.integrated, isTrue, reason: removed.error);
      final retainedHistory = document.undoCount;
      controller.restore(redo: false);
      expect(document.current, before);
      expect(document.dirty, isFalse);
      expect(document.undoCount, retainedHistory);
      expect(document.error, contains('destination supprimée'));
      expect(
        await File(p.join(fixture.root.path, target.relativePath)).exists(),
        isFalse,
      );

      final ordinaryEdit = before.copyWith(properties: {'unrelated': true});
      document.commit(ordinaryEdit);
      controller.restore(redo: false);
      expect(document.current, before);
      expect(document.error, isNull);
      controller.restore(redo: true);
      expect(document.current, ordinaryEdit);
      controller.restore(redo: false);
      controller.restore(redo: false);
      expect(document.current, before);
      expect(document.undoCount, retainedHistory);
      expect(document.error, contains('destination supprimée'));

      final reopened = MapWorkspaceController(fixture.session, fixture.adapter);
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.active!.current, before);
      expect(
        reopened.project!.maps.any((entry) => entry.id == target.id),
        isFalse,
      );
    },
  );
}
