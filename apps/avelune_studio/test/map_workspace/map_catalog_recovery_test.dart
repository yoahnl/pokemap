import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  test(
    'empty project receives its first map without fabricating resources',
    () async {
      final fixture = await MapCatalogFixture.create(empty: true);
      addTearDown(fixture.dispose);
      expect(fixture.controller.active, isNull);
      final result = await fixture.createMap('first');
      expect(result.integrated, isTrue);
      expect(fixture.controller.project!.settings.tileWidth, 48);
      expect(fixture.controller.project!.tilesets, isEmpty);
      await fixture.controller.activate(
        fixture.controller.project!.maps.single,
      );
      expect(fixture.controller.active!.current.tilesetId, isEmpty);
    },
  );

  test(
    'failed refresh keeps a published receipt and retries only integration',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      fixture.catalog.failRefresh = true;
      final result = await fixture.createMap('retained');
      expect(result.published, isTrue);
      expect(result.integrated, isFalse);
      expect(result.error, contains('Publication effectuée'));
      expect(
        await File(p.join(fixture.root.path, 'maps/retained.json')).exists(),
        isTrue,
      );
      expect(fixture.controller.pendingCatalogReceipt, same(result.receipt));
      expect((await fixture.createMap('duplicate')).published, isFalse);
      fixture.catalog.failRefresh = false;
      final retried = await fixture.controller.retryCatalogRefresh();
      expect(retried.integrated, isTrue);
      expect(fixture.catalog.mutations, 1);
      expect(
        fixture.controller.project!.maps.where(
          (entry) => entry.id == 'retained',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'late publication remains on disk without updating a disposed owner',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      fixture.catalog.publicationReady = Completer();
      fixture.catalog.publicationGate = Completer();
      final initial = fixture.controller.project;
      final operation = fixture.createMap('late');
      await fixture.catalog.publicationReady!.future;
      expect(fixture.controller.catalogBusy, isTrue);
      expect((await fixture.createMap('double')).published, isFalse);
      fixture.controller.dispose();
      fixture.catalog.publicationGate!.complete();
      final result = await operation;
      expect(result.published, isTrue);
      expect(result.integrated, isFalse);
      expect(fixture.controller.project, same(initial));
      expect(fixture.catalog.refreshes, 0);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.project!.maps.any((entry) => entry.id == 'late'), isTrue);
    },
  );
}
