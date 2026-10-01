import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  setUp(() async => fixture = await MapCatalogFixture.create());
  tearDown(() => fixture.dispose());

  test(
    'duplicate publishes an independent copy while retaining the source',
    () async {
      final source = fixture.controller.active!;
      final result = await fixture.controller.mutateCatalog('map.duplicate', {
        'sourceMapId': source.base.mapId,
        'targetMapId': 'jardin-copy',
        'name': 'Jardin — copie',
      });
      expect(result.integrated, isTrue, reason: result.error);
      expect(result.receipt!.createdMapId, 'jardin-copy');
      expect(fixture.controller.active, same(source));
      final copyEntry = fixture.controller.project!.maps.last;
      await fixture.controller.activate(copyEntry);
      final copy = fixture.controller.active!;
      copy.commit(copy.current.copyWith(properties: {'copyOnly': true}));
      expect(await fixture.controller.save(copy), isTrue);
      expect(source.current.properties.containsKey('copyOnly'), isFalse);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      await reopened.activate(copyEntry);
      expect(reopened.active!.current.properties['copyOnly'], isTrue);
      expect(
        reopened.project!.settings.tileWidth,
        fixture.controller.project!.settings.tileWidth,
      );
    },
  );

  test(
    'resize adopts the published content and retires obsolete geometry history',
    () async {
      final document = fixture.controller.active!;
      document.commit(document.current.copyWith(properties: {'saved': true}));
      expect(await fixture.controller.save(document), isTrue);
      expect(document.canUndo, isTrue);
      final selected = document.current.placedElements.firstOrNull?.id;
      document.selectedId = selected;
      final width = document.current.size.width + 3;
      final height = document.current.size.height + 2;
      final result = await fixture.controller.mutateCatalog(
        'map.resize_apply',
        {'mapId': document.base.mapId, 'width': width, 'height': height},
      );
      expect(result.integrated, isTrue, reason: result.error);
      expect(fixture.controller.active, same(document));
      expect(document.current.size.width, width);
      expect(document.current.size.height, height);
      expect(document.dirty, isFalse);
      expect(document.canUndo, isFalse);
      expect(document.selectedId, selected);
      final entry = fixture.controller.project!.maps.first;
      final disk = MapData.fromJson(
        jsonDecode(
          await File(
            p.join(fixture.root.path, entry.relativePath),
          ).readAsString(),
        ),
      );
      expect(disk, document.current);
    },
  );

  test(
    'deleting the active map selects a deterministic surviving map',
    () async {
      await fixture.controller.activate(fixture.controller.project!.maps.last);
      final removed = fixture.controller.active!;
      final result = await fixture.controller.mutateCatalog(
        'map.delete_apply',
        {'mapId': removed.base.mapId},
        confirmDestructive: true,
      );
      expect(result.integrated, isTrue, reason: result.error);
      expect(
        fixture.controller.active!.base.mapId,
        fixture.controller.project!.maps.first.id,
      );
      removed.commit(removed.current.copyWith(properties: {'obsolete': true}));
      expect(await fixture.controller.save(removed), isFalse);
      expect(
        await File(
          p.join(fixture.root.path, 'maps/${removed.base.mapId}.json'),
        ).exists(),
        isFalse,
      );
    },
  );
}
