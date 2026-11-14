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
import 'map_catalog_mutation_regional_fixture.dart';

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

  test('published catalogue metadata keeps map music in the draft history', () {
    final document = fixture.controller.active!;
    final saved = document.saved;
    document.acceptCatalogMetadata(
      MapWorkspaceDocument(
        map: saved.copyWith(
          mapMetadata: saved.mapMetadata.copyWith(allowEscapeRope: false),
        ),
        revision: 'published',
        mapId: document.base.mapId,
      ),
    );
    final before = document.current;
    document.commit(
      before.copyWith(
        mapMetadata: before.mapMetadata.copyWith(
          musicPath: 'assets/audio/theme.wav',
          musicVolume: .5,
        ),
      ),
    );
    document.restore(redo: false);
    expect(document.current.mapMetadata.musicPath, isNull);
    expect(document.current.mapMetadata.allowEscapeRope, isFalse);
    document.restore(redo: true);
    expect(document.current.mapMetadata.musicPath, 'assets/audio/theme.wav');
    expect(document.current.mapMetadata.musicVolume, .5);
    expect(document.current.mapMetadata.allowEscapeRope, isFalse);
  });

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
      final controller = await regionalController(fixture);
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
        final controller = await regionalController(fixture);
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
              field: field == 'u'
                  ? 0.75
                  : {'mapId': before.maps.last.id, 'spawnId': 'depart'},
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
}
