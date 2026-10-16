import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  setUp(() async {
    fixture = await MapCatalogFixture.create();
  });
  tearDown(() => fixture.dispose());

  test(
    'Corde metadata publication integrates history and survives cold reopen',
    () async {
      final controller = fixture.controller;
      final organized = await controller.mutateCatalog(
        'map.library.reorganize',
        {
          'groups': [
            const ProjectMapGroup(
              id: 'dungeon',
              name: 'Donjon',
              type: MapGroupType.dungeon,
            ).toJson(),
          ],
          'assignments': <Object?>[],
        },
      );
      expect(organized.integrated, isTrue, reason: organized.error);
      final target = controller.active!;
      final entity = target.current.entities.first;
      MapEntityEditingCommands(
        target,
        controller.project!,
      ).move(entity.id, const GridPos(x: 3, y: 3));
      expect(await controller.save(target), isTrue);
      final historyCount = target.undoCount;
      await controller.activate(controller.project!.maps.last);
      final neighbour = controller.active!;
      neighbour.commit(neighbour.current.copyWith(properties: {'draft': true}));
      final neighbourDraft = neighbour.current;
      final result = await controller.mutateCatalog('map.update_metadata', {
        'mapId': target.base.mapId,
        'name': 'Grotte des essais',
        'escapeRopeDungeonId': 'dungeon',
        'allowEscapeRope': false,
      });
      expect(result.published, isTrue, reason: result.error);
      expect(result.integrated, isTrue, reason: result.error);
      expect(controller.pendingCatalogReceipt, isNull);
      expect(controller.error, isNull);
      expect(target.current.mapMetadata.escapeRopeDungeonId, 'dungeon');
      expect(target.current.mapMetadata.allowEscapeRope, isFalse);
      expect(target.current.name, 'Grotte des essais');
      expect(target.current, target.saved);
      expect(target.saved, target.base.map);
      expect(target.undoCount, historyCount);
      expect(neighbour.current, same(neighbourDraft));
      expect(neighbour.dirty, isTrue);
      await controller.activate(controller.project!.maps.first);
      controller.restore(redo: false);
      expect(target.current.entities.first.pos, entity.pos);
      expect(target.current.mapMetadata, target.saved.mapMetadata);
      expect(target.current.name, 'Grotte des essais');
      controller.restore(redo: true);
      expect(target.current.entities.first.pos, const GridPos(x: 3, y: 3));
      expect(target.current.mapMetadata, target.saved.mapMetadata);
      expect(target.current.name, 'Grotte des essais');
      expect(await controller.save(target), isTrue);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.error, isNull);
      expect(reopened.active!.current, target.saved);
      expect(
        reopened.active!.current.mapMetadata.escapeRopeDungeonId,
        'dungeon',
      );
      expect(reopened.active!.current.mapMetadata.allowEscapeRope, isFalse);
    },
  );

  test(
    'Corde metadata publication refuses a dirty target before writing',
    () async {
      final document = fixture.controller.active!;
      document.commit(document.current.copyWith(properties: {'dirty': true}));
      final files = [
        File(p.join(fixture.root.path, 'project.json')),
        File(
          p.join(
            fixture.root.path,
            fixture.controller.project!.maps.first.relativePath,
          ),
        ),
      ];
      final before = [for (final file in files) await file.readAsBytes()];
      final draft = document.current;
      final result = await fixture.controller.mutateCatalog(
        'map.update_metadata',
        {
          'mapId': document.base.mapId,
          'escapeRopeDungeonId': 'dungeon',
          'allowEscapeRope': false,
        },
      );
      expect(result.published, isFalse);
      expect(fixture.catalog.mutations, 0);
      expect(document.current, same(draft));
      expect(document.dirty, isTrue);
      for (var index = 0; index < files.length; index++) {
        expect(await files[index].readAsBytes(), before[index]);
      }
    },
  );

  test(
    'catalogue metadata acceptance refuses other map content and keeps history',
    () async {
      final document = fixture.controller.active!;
      final original = document.current;
      document.commit(original.copyWith(properties: {'draft': true}));
      document.commit(original);
      final historyCount = document.undoCount;
      final forged = MapWorkspaceDocument(
        map: document.saved.copyWith(
          name: 'Published name',
          mapMetadata: document.saved.mapMetadata.copyWith(
            allowEscapeRope: false,
          ),
          properties: {'unrelated': true},
        ),
        revision: 'forged',
        mapId: document.base.mapId,
      );
      expect(
        () => document.acceptCatalogMetadata(forged),
        throwsA(isA<MapWorkspaceFailure>()),
      );
      expect(document.current, original);
      expect(document.saved, original);
      expect(document.undoCount, historyCount);
      expect(document.canUndo, isTrue);
    },
  );

  test(
    'regional catalogue survives native rename reconcile and cold reopen',
    () async {
      final controller = await _regionalController(fixture);
      addTearDown(controller.dispose);
      final before = controller.project!;
      final target = before.maps.first;
      final result = await controller.mutateCatalog('map.update_metadata', {
        'mapId': target.id,
        'name': 'Regional title',
      });
      expect(result.published, isTrue, reason: result.error);
      expect(result.integrated, isTrue, reason: result.error);
      expect(controller.project!.regionalMap, before.regionalMap);
      expect(controller.pendingCatalogReceipt, isNull);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.error, isNull);
      expect(reopened.project, controller.project);
      expect(reopened.active!.current.name, 'Regional title');
    },
  );

  for (final field in ['u', 'destination']) {
    test(
      'regional catalogue reconciliation refuses a changed $field',
      () async {
        final controller = await _regionalController(fixture);
        addTearDown(controller.dispose);
        final before = controller.project!;
        final receipt = await fixture.catalog.mutate(
          fixture.session,
          'map.update_metadata',
          {'mapId': before.maps.first.id, 'name': 'Native title'},
          expectedManifest: before,
        );
        final regional = receipt.manifest.regionalMap!;
        final poi = regional.pointsOfInterest.single;
        final forgedRegional = ProjectRegionalMapCatalog.fromJson({
          ...regional.toJson(),
          'pointsOfInterest': [
            {
              ...poi.toJson(),
              field: field == 'u' ? 0.75 : {'mapId': before.maps.last.id},
            },
          ],
        });
        final forged = MapCatalogReceipt(
          before: receipt.before,
          manifest: receipt.manifest.copyWith(regionalMap: forgedRegional),
          beforeRevision: receipt.beforeRevision,
          revision: receipt.revision,
          changedPaths: receipt.changedPaths,
          documents: receipt.documents,
        );
        final file = File(p.join(fixture.root.path, 'project.json'));
        final bytes = await file.readAsBytes();
        await expectLater(
          fixture.catalog.reconcile(fixture.session, forged),
          throwsA(
            isA<MapWorkspaceFailure>().having(
              (failure) => failure.problem,
              'problem',
              MapWorkspaceProblem.conflict,
            ),
          ),
        );
        expect(await file.readAsBytes(), bytes);
        await fixture.catalog.reconcile(fixture.session, receipt);
        expect(
          (await fixture.adapter.resourceBaseline(fixture.session)).manifest,
          receipt.manifest,
        );
        expect(await file.readAsBytes(), bytes);
      },
    );
  }

  test('undo refuses an old passage to a canonically removed map', () async {
    expect(
      (await fixture.createMap('obsolete-destination')).integrated,
      isTrue,
    );
    final document = fixture.controller.active!;
    final before = document.current;
    document.commit(
      before.copyWith(
        warps: [
          const MapWarp(
            id: 'historic-warp',
            pos: GridPos(x: 2, y: 2),
            targetMapId: 'obsolete-destination',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );
    document.commit(before);
    expect(document.dirty, isFalse);
    final removed = await fixture.controller.mutateCatalog('map.delete_apply', {
      'mapId': 'obsolete-destination',
    }, confirmDestructive: true);
    expect(removed.integrated, isTrue, reason: removed.error);
    fixture.controller.restore(redo: false);
    expect(document.current.warps, isEmpty);
    expect(document.canUndo, isTrue);
    expect(document.error, contains('destination supprimée'));
  });

  test(
    'creation integrates the manifest and permits immediate editing and saving',
    () async {
      final before = fixture.controller.active!;
      final result = await fixture.createMap('third');
      expect(result.integrated, isTrue, reason: result.error);
      expect(result.receipt!.changedPaths.toSet(), {
        'project.json',
        'maps/third.json',
      });
      expect(fixture.controller.active, same(before));
      final entry = fixture.controller.project!.maps.last;
      await fixture.controller.activate(entry);
      final document = fixture.controller.active!;
      MapEntityEditingCommands(
        document,
        fixture.controller.project!,
      ).place(MapEntityKind.spawn, const GridPos(x: 3, y: 2));
      expect(await fixture.controller.save(document), isTrue);
      final reopened = MapWorkspaceController(
        fixture.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      await reopened.activate(reopened.project!.maps.last);
      expect(
        reopened.active!.current.entities.single.pos,
        const GridPos(x: 3, y: 2),
      );
    },
  );

  test('title mutation preserves identity, dirty neighbour and prior geometry history', () async {
    final controller = fixture.controller;
    final target = controller.active!;
    final originalPath = controller.project!.maps.first.relativePath;
    final entity = target.current.entities.first;
    MapEntityEditingCommands(
      target,
      controller.project!,
    ).move(entity.id, const GridPos(x: 3, y: 3));
    expect(await controller.save(target), isTrue);
    await controller.activate(controller.project!.maps.last);
    final neighbour = controller.active!;
    neighbour.commit(
      neighbour.current.copyWith(properties: {'brouillon': true}),
    );
    final neighbourMap = neighbour.current;
    final result = await controller.mutateCatalog('map.update_metadata', {
      'mapId': target.base.mapId,
      'name': 'Étang des essais',
    });
    expect(result.integrated, isTrue, reason: result.error);
    expect(controller.project!.maps.first.relativePath, originalPath);
    expect(target.current.id, 'jardin');
    expect(target.current.name, 'Étang des essais');
    expect(neighbour.current, same(neighbourMap));
    expect(neighbour.dirty, isTrue);
    await controller.activate(controller.project!.maps.first);
    controller.restore(redo: false);
    expect(target.current.name, 'Étang des essais');
    expect(target.current.entities.first.pos, entity.pos);
    controller.restore(redo: true);
    expect(target.current.name, 'Étang des essais');
    expect(target.current.entities.first.pos, const GridPos(x: 3, y: 3));
    expect(await controller.save(target), isTrue);
    final disk = MapData.fromJson(
      jsonDecode(
        await File(p.join(fixture.root.path, originalPath)).readAsString(),
      ),
    );
    expect(disk.name, controller.project!.maps.first.name);
  });

  test('dirty target is refused without publishing other drafts', () async {
    final document = fixture.controller.active!;
    document.commit(document.current.copyWith(properties: {'dirty': true}));
    final bytes = await File(p.join(fixture.root.path, 'project.json'))
        .readAsBytes();
    final result = await fixture.controller.mutateCatalog(
      'map.update_metadata',
      {'mapId': 'jardin', 'name': 'Refus'},
    );
    expect(result.published, isFalse);
    expect(fixture.catalog.mutations, 0);
    expect(document.dirty, isTrue);
    expect(
      await File(p.join(fixture.root.path, 'project.json')).readAsBytes(),
      bytes,
    );
  });

  test('same normalized title performs no publication', () async {
    final document = fixture.controller.active!;
    final bytes = await File(p.join(fixture.root.path, 'project.json'))
        .readAsBytes();
    final revision = document.base.revision;
    final result = await fixture.controller.mutateCatalog(
      'map.update_metadata',
      {'mapId': 'jardin', 'name': '  ${document.current.name}  '},
    );
    expect(result.integrated, isTrue, reason: result.error);
    expect(result.published, isFalse);
    expect(document.base.revision, revision);
    expect(
      await File(p.join(fixture.root.path, 'project.json')).readAsBytes(),
      bytes,
    );
  });

  test(
    'canonical removal retires loaded maps and refuses stale saves',
    () async {
      await fixture.controller.activate(fixture.controller.project!.maps.last);
      final removed = fixture.controller.active!;
      final staleEntry = fixture.controller.project!.maps.last;
      final result = await fixture.controller.mutateCatalog(
        'map.delete_apply',
        {'mapId': staleEntry.id},
        confirmDestructive: true,
      );
      expect(result.integrated, isTrue, reason: result.error);
      expect(
        fixture.controller.active!.base.mapId,
        fixture.controller.project!.maps.first.id,
      );
      expect(fixture.controller.documents.containsKey(staleEntry.id), isFalse);
      await fixture.controller.activate(staleEntry);
      removed.commit(removed.current.copyWith(properties: {'stale': true}));
      expect(await fixture.controller.save(removed), isFalse);
      expect(await fixture.controller.previewMap(staleEntry.id), isNull);
      expect(
        await File(p.join(fixture.root.path, staleEntry.relativePath)).exists(),
        isFalse,
      );
    },
  );

  test('an externally changed target refuses title publication', () async {
    final document = fixture.controller.active!;
    final path = p.join(
      fixture.root.path,
      fixture.controller.project!.maps.first.relativePath,
    );
    final changed = document.current.copyWith(properties: {'external': true});
    await File(path).writeAsString(jsonEncode(changed.toJson()));
    final result = await fixture.controller.mutateCatalog(
      'map.update_metadata',
      {'mapId': 'jardin', 'name': 'Écrasement'},
    );
    expect(result.published, isFalse);
    expect(
      MapData.fromJson(jsonDecode(await File(path).readAsString())),
      changed,
    );
    expect(document.current, isNot(changed));
  });
}

Future<MapWorkspaceController> _regionalController(
  MapCatalogFixture fixture,
) async {
  final project = fixture.controller.project!;
  final regional = ProjectRegionalMapCatalog(
    regions: [ProjectRegionDefinition(id: 'region', label: 'Region')],
    pointsOfInterest: [
      ProjectRegionPointOfInterest(
        id: 'poi',
        regionId: 'region',
        label: 'Town',
        u: 0.25,
        v: 0.5,
        mapIds: [project.maps.first.id],
        destination: ProjectRegionDestination(mapId: project.maps.first.id),
      ),
    ],
  );
  await File(
    p.join(fixture.root.path, 'project.json'),
  ).writeAsString(jsonEncode(project.copyWith(regionalMap: regional).toJson()));
  final controller = MapWorkspaceController(
    fixture.session,
    fixture.adapter,
    catalogPort: fixture.catalog,
  );
  await controller.initialize();
  expect(controller.error, isNull);
  return controller;
}
