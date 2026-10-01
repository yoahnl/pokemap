import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  setUp(() async => fixture = await MapCatalogFixture.create());
  tearDown(() => fixture.dispose());

  test(
    'double launch is rejected while a preparation remains active',
    () async {
      fixture.catalog.preparationReady = Completer();
      fixture.catalog.preparationGate = Completer();
      final parameters = {
        'sourceMapId': fixture.controller.active!.base.mapId,
        'name': 'Copie',
      };
      final pending = fixture.controller.prepareCatalog(
        'map.duplicate',
        parameters,
      );
      await fixture.catalog.preparationReady!.future;
      expect(fixture.controller.catalogBusy, isTrue);
      await expectLater(
        fixture.controller.prepareCatalog('map.duplicate', parameters),
        throwsA(isA<MapWorkspaceFailure>()),
      );
      fixture.catalog.preparationGate!.complete();
      expect((await pending).canApply, isTrue);
      expect(fixture.controller.catalogBusy, isFalse);
      expect(fixture.catalog.mutations, 0);
    },
  );

  test('disposal before application writes no copy or late success', () async {
    final prepared = await fixture.controller.prepareCatalog('map.duplicate', {
      'sourceMapId': fixture.controller.active!.base.mapId,
      'targetMapId': 'never-created',
      'name': 'Copie',
    });
    fixture.catalog.applicationReady = Completer();
    fixture.catalog.applicationGate = Completer();
    final original = fixture.controller.project;
    final pending = fixture.controller.applyPreparedCatalog(prepared);
    await fixture.catalog.applicationReady!.future;
    fixture.controller.dispose();
    fixture.catalog.applicationGate!.complete();
    final result = await pending;
    expect(result.published, isFalse, reason: result.error);
    expect(result.integrated, isFalse);
    expect(fixture.controller.project, same(original));
    expect(
      await File(p.join(fixture.root.path, 'maps/never-created.json')).exists(),
      isFalse,
    );
  });

  test(
    'a narrative draft appearing during preparation blocks the writer',
    () async {
      final target = fixture.controller.project!.maps.last.id;
      final prepared = await fixture.controller.prepareCatalog(
        'map.delete_apply',
        {'mapId': target},
      );
      expect(prepared.canApply, isTrue);
      fixture.catalog.applicationReady = Completer();
      fixture.catalog.applicationGate = Completer();
      var narrativeDirty = false;
      fixture.controller.catalogDependencyFailure = (_, _) =>
          narrativeDirty ? 'Brouillon Histoire à résoudre.' : null;
      final pending = fixture.controller.applyPreparedCatalog(
        prepared,
        confirmDestructive: true,
      );
      await fixture.catalog.applicationReady!.future;
      narrativeDirty = true;
      fixture.catalog.applicationGate!.complete();
      final result = await pending;
      expect(result.published, isFalse);
      expect(result.error, contains('Brouillon Histoire'));
      expect(
        await File(p.join(fixture.root.path, 'maps/$target.json')).exists(),
        isTrue,
      );
    },
  );

  test(
    'failed refresh retains the duplicate receipt and never replays publication',
    () async {
      final prepared = await fixture.controller
          .prepareCatalog('map.duplicate', {
            'sourceMapId': fixture.controller.active!.base.mapId,
            'targetMapId': 'retained-copy',
            'name': 'Copie',
          });
      fixture.catalog.failRefresh = true;
      final result = await fixture.controller.applyPreparedCatalog(prepared);
      expect(result.published, isTrue);
      expect(result.integrated, isFalse);
      expect(result.receipt!.createdMapId, 'retained-copy');
      expect(
        (await fixture.controller.applyPreparedCatalog(prepared)).published,
        isFalse,
      );
      fixture.catalog.failRefresh = false;
      expect(
        (await fixture.controller.retryCatalogRefresh()).integrated,
        isTrue,
      );
      expect(fixture.catalog.mutations, 1);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(
        reopened.project!.maps.where((entry) => entry.id == 'retained-copy'),
        hasLength(1),
      );
    },
  );

  test(
    'an unrelated neighbour draft survives resizing the active map',
    () async {
      final target = fixture.controller.active!;
      await fixture.controller.activate(fixture.controller.project!.maps.last);
      final neighbour = fixture.controller.active!;
      neighbour.commit(
        neighbour.current.copyWith(properties: {'unsavedNeighbour': true}),
      );
      final current = neighbour.current;
      final prepared = await fixture.controller
          .prepareCatalog('map.resize_apply', {
            'mapId': target.base.mapId,
            'width': target.current.size.width + 1,
            'height': target.current.size.height + 1,
          });
      expect(
        (await fixture.controller.applyPreparedCatalog(prepared)).integrated,
        isTrue,
      );
      expect(fixture.controller.active, same(neighbour));
      expect(neighbour.current, same(current));
      expect(neighbour.dirty, isTrue);
      expect(neighbour.canUndo, isTrue);
      expect(target.dirty, isFalse);
    },
  );

  test(
    'same map identity in another project never accepts a prepared operation',
    () async {
      final prepared = await fixture.controller
          .prepareCatalog('map.duplicate', {
            'sourceMapId': fixture.controller.active!.base.mapId,
            'targetMapId': 'foreign-copy',
            'name': 'Copie',
          });
      final other = await MapCatalogFixture.create();
      addTearDown(other.dispose);
      final before = other.controller.project;
      final active = other.controller.active;
      final result = await other.controller.applyPreparedCatalog(prepared);
      expect(result.published, isFalse);
      expect(other.catalog.mutations, 0);
      expect(other.controller.project, same(before));
      expect(other.controller.active, same(active));
      expect(
        await File(p.join(other.root.path, 'maps/foreign-copy.json')).exists(),
        isFalse,
      );
    },
  );
}
