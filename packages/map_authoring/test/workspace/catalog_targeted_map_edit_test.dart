import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_targeted_map_edit.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final portable in [false, true]) {
    test('trainer selection follows projected bindings and verifies appearances '
        '(portable: $portable)', () async {
      final root = await Directory.systemTemp.createTemp('trainer-selection-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final project = ProjectManifest(name: 'Trainers', maps: const [
        ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
      ], tilesets: const [
        ProjectTilesetEntry(id: 'sheet', name: 'Sheet', relativePath: 'sheet.png'),
      ], characters: [
        for (final id in ['first', 'second']) ProjectCharacterEntry(
            id: id, name: id, tilesetId: 'sheet'),
      ], elements: [
        for (final id in ['first', 'second']) ProjectElementEntry(
            id: 'portrait-$id', name: id, tilesetId: 'sheet', categoryId: 'art',
            frames: const [TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))]),
      ], elementCategories: const [ProjectElementCategory(id: 'art', name: 'Art')],
      trainers: [for (final id in ['first', 'second']) ProjectTrainerEntry(
          id: id, name: id, trainerClass: 'Trainer', characterId: id,
          portraitElementId: 'portrait-$id')]);
      final Map<String, Object?> descriptor;
      if (portable) {
        final build = PortableCatalogPublication.encodeProject(project);
        await store.publish(build.storage, expectedRootRevision: null);
        descriptor = build.descriptor;
      } else {
        final working = await WorkingProjectCatalog.create(
            store: store, projectId: 'trainers', project: project);
        await store.prepareLocalEditing();
        descriptor = working.descriptor.toJson();
      }
      MapData map(String trainerId) => MapData(id: 'room', name: 'Room',
          size: const GridSize(width: 4, height: 4), tilesetId: 'sheet', entities: [
        MapEntity(id: 'npc', kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(trainerId: trainerId)),
      ]);
      final file = File('${root.path}/maps/room.json');
      await file.parent.create(recursive: true);
      final before = utf8.encode(jsonEncode(map('first').toJson()));
      await file.writeAsBytes(before);
      final head = await File('${root.path}/catalog/HEAD.json').readAsBytes();
      final reader = (await CatalogProjectReader.open(store: store,
          descriptor: descriptor, metadataFields: catalogMapValidationMetadataFields))!;
      expect(reader.readOnly, portable);
      expect(reader.catalog.projectMetadata.trainers, isEmpty);
      for (final id in ['first', 'second']) {
        final selected = await CatalogTargetedMapSelection.read(
            reader: reader, mapId: 'room', projectedMap: map(id));
        expect(selected.definitions.trainers.map((value) => value.id), [id]);
        expect(selected.definitions.characters.map((value) => value.id), [id]);
        expect(selected.definitions.elements.map((value) => value.id), ['portrait-$id']);
      }
      await expectLater(CatalogTargetedMapSelection.read(reader: reader,
          mapId: 'room', projectedMap: map('missing')),
          throwsA(isA<ValidationException>().having(
              (error) => error.message, 'message', contains('missing'))));
      final appearance = (await reader.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.element, 'portrait-second')))!;
      await File('${root.path}/catalog/objects/${appearance.reference.sha256}.json')
          .writeAsString('corrupt portrait');
      await expectLater(CatalogTargetedMapSelection.read(reader: reader,
          mapId: 'room', projectedMap: map('second')), throwsFormatException);
      expect(await file.readAsBytes(), before);
      expect(await File('${root.path}/catalog/HEAD.json').readAsBytes(), head);
    });
  }
  test('targeted saves reject a resource reserved for another map', () async {
    final root = await Directory.systemTemp.createTemp('scoped-map-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'scoped',
        project: ProjectManifest(
          name: 'Scoped',
          version: ProjectVersion.v8,
          maps: [
            for (final id in ['garden', 'house'])
              ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
          ],
          tilesets: [
            for (final id in ['public', 'private'])
              ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
          ],
          resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
            ResourceLibraryEntry(
                resourceKind: 'tileset', resourceId: 'private', mapId: 'house'),
          ]),
        ));
    final map = MapData(
        id: 'garden',
        name: 'Garden',
        size: const GridSize(width: 8, height: 8),
        tilesetId: 'public');
    final file = File('${root.path}/maps/garden.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    final reader = (await CatalogProjectReader.open(
        store: store, descriptor: working.descriptor.toJson()))!;
    final selected =
        await CatalogTargetedMapSelection.read(reader: reader, mapId: 'garden');
    await expectLater(
        CatalogTargetedMapEdit.prepare(
            reader: reader,
            request: AuthoringRequest(
                requestId: 'scope',
                actionId: 'map.save',
                actionVersion: 1,
                workspaceHandle: 'workspace',
                expectedRevision: selected.snapshotRevision,
                idempotencyKey: 'scope',
                parameters: {
                  'map': map.copyWith(tilesetId: 'private').toJson()
                })),
        throwsA(isA<VisualLibraryException>()
            .having((e) => e.code, 'code', 'resource_library.scope_conflict')));
    expect(
        MapData.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>),
        map);
  });
  test(
      'targeted map preparation reads only its typed selection and preserves the descriptor',
      () async {
    final root = await Directory.systemTemp.createTemp('targeted-map-');
    addTearDown(() => root.delete(recursive: true));
    final project =
        ProjectManifest(name: 'Targeted', version: ProjectVersion.v8, maps: [
      ProjectMapEntry(
          id: 'garden', name: 'Garden', relativePath: 'maps/garden.json')
    ], tilesets: [
      for (var i = 0; i < 256; i++)
        ProjectTilesetEntry(
            id: 'sheet-$i', name: 'Sheet $i', relativePath: '$i.png'),
    ]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'targeted', project: project);
    final map = MapData(
        id: 'garden',
        name: 'Garden',
        size: const GridSize(width: 8, height: 8),
        tilesetId: 'sheet-0');
    final mapFile = File('${root.path}/maps/garden.json');
    await mapFile.parent.create(recursive: true);
    final beforeBytes = utf8.encode(jsonEncode(map.toJson()));
    await mapFile.writeAsBytes(beforeBytes);
    final descriptor = await File('${root.path}/project.json').readAsBytes();
    final unread = (await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'sheet-255')))!;
    final unusedFile =
        File('${root.path}/catalog/objects/${unread.reference.sha256}.json');
    final unusedBytes = await unusedFile.readAsBytes();
    await unusedFile.delete();
    final reader = (await CatalogProjectReader.open(
        store: store, descriptor: working.descriptor.toJson()))!;
    final selection =
        await CatalogTargetedMapSelection.read(reader: reader, mapId: 'garden');
    expect(selection.definitions.tilesets.map((t) => t.id), ['sheet-0']);
    final updated =
        map.copyWith(tilesetId: 'sheet-1', properties: {'note': 'saved'});
    final request = AuthoringRequest(
        requestId: 'targeted',
        actionId: 'map.save',
        actionVersion: 1,
        workspaceHandle: 'workspace',
        expectedRevision: selection.snapshotRevision,
        idempotencyKey: 'targeted',
        parameters: {'map': updated.toJson()});
    final external = map.copyWith(properties: {'external': 'preserved'});
    await mapFile.writeAsString(jsonEncode(external.toJson()));
    await expectLater(
        CatalogTargetedMapEdit.prepare(reader: reader, request: request),
        throwsA(isA<AuthoringPlanException>()
            .having((e) => e.code, 'code', 'plan.stale')));
    expect(
        MapData.fromJson(
            jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>),
        external);
    await mapFile.writeAsBytes(beforeBytes);
    final edit =
        await CatalogTargetedMapEdit.prepare(reader: reader, request: request);
    expect(edit.selection.definitions.tilesets.map((t) => t.id), ['sheet-1']);
    expect(edit.draft.changeSet.changes.single.storageKey, 'maps/garden.json');
    expect(edit.draft.changeSet.changes.single.beforeBytes, beforeBytes);
    expect(edit.diff.entries.map((e) => e.resource.kind).toSet(),
        {'map', 'catalogHead'});
    expect(await mapFile.readAsBytes(), beforeBytes);
    expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
    await unusedFile.writeAsBytes(unusedBytes);
    final editing = await CatalogEditingSession.open(
        store: store, projectId: 'targeted', actorId: 'actor');
    try {
      final planned = await editing.planPatch(
          additionalChanges: edit.draft.changeSet.changes,
          workspaceFingerprint: edit.workspaceFingerprint,
          publicBaseRevision: edit.selection.snapshotRevision,
          publicDiff: edit.diff,
          currentProjectRevision: () async =>
              (await CatalogTargetedMapSelection.read(
                      reader: (await CatalogProjectReader.open(
                          store: store,
                          descriptor: working.descriptor.toJson()))!,
                      mapId: 'garden'))
                  .snapshotRevision,
          request: request,
          idempotencyKey: 'targeted');
      await editing.apply(planned);
      final reopened = (await CatalogProjectReader.open(
          store: store, descriptor: working.descriptor.toJson()))!;
      final after = await CatalogTargetedMapSelection.read(
          reader: reopened, mapId: 'garden');
      expect(after.map, updated);
      expect(after.definitions.tilesets.map((t) => t.id), ['sheet-1']);
      expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
      await expectLater(
          CatalogTargetedMapEdit.prepare(reader: reopened, request: request),
          throwsA(isA<AuthoringPlanException>()
              .having((e) => e.code, 'code', 'plan.stale')));
    } finally {
      await editing.close();
    }
  });

  test('a targeted save still refuses removing the arrival of a regional destination', () async {
    final root = await Directory.systemTemp.createTemp('regional-map-save-');
    addTearDown(() => root.delete(recursive: true));
    const spawn = MapEntity(id: 'arrival', kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 2), spawn: MapEntitySpawnData(spawnKey: 'gate'));
    const map = MapData(id: 'town', name: 'Town', version: ProjectVersion.v8,
        size: GridSize(width: 5, height: 5), entities: [spawn]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(store: store, projectId: 'regional',
        project: ProjectManifest(name: 'Regional', version: ProjectVersion.v8, maps: [
          const ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json'),
          const ProjectMapEntry(id: 'route', name: 'Route', relativePath: 'maps/route.json'),
        ], tilesets: const [], regionalMap: ProjectRegionalMapCatalog(
          regions: [ProjectRegionDefinition(id: 'r', label: 'R')],
          pointsOfInterest: [ProjectRegionPointOfInterest(id: 'town', regionId: 'r', label: 'Town',
              u: .5, v: .5, mapIds: ['town'],
              destination: ProjectRegionDestination(mapId: 'town', spawnId: 'gate'))])));
    final file = File('${root.path}/maps/town.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    final reader = (await CatalogProjectReader.open(store: store,
        descriptor: working.descriptor.toJson(),
        metadataFields: catalogMapValidationMetadataFields))!;
    final selected = await CatalogTargetedMapSelection.readRevision(reader: reader, mapId: 'town');
    AuthoringRequest request(MapData value) => AuthoringRequest(requestId: 'regional',
        actionId: 'map.save', actionVersion: 1, workspaceHandle: 'workspace',
        expectedRevision: selected.snapshotRevision, idempotencyKey: 'regional',
        parameters: {'map': value.toJson()});
    await expectLater(
        CatalogTargetedMapEdit.prepare(reader: reader,
            request: request(map.copyWith(entities: const []))),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code',
            'regional_map.destination_spawn_missing')));
    final kept = await CatalogTargetedMapEdit.prepare(reader: reader,
        request: request(map.copyWith(name: 'Bourg')));
    expect(kept.draft.changeSet.changes.single.storageKey, 'maps/town.json');
  });

  test('a targeted save reads the scenes its events name and refuses a missing one', () async {
    final root = await Directory.systemTemp.createTemp('scene-map-save-');
    addTearDown(() => root.delete(recursive: true));
    SceneAsset scene(String id) => SceneAsset(id: id, name: id, graph: SceneGraph(
        startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [SceneEdge(id: 'go', fromNodeId: 'start', fromPortId: 'completed',
            toNodeId: 'end', kind: SceneEdgeKind.defaultFlow)]));
    MapData map(String sceneId) => MapData(id: 'town', name: 'Town',
        version: ProjectVersion.v8, size: const GridSize(width: 5, height: 5),
        layers: [TileLayer(id: 'ground', name: 'Ground', cells: List.filled(25, 0))],
        events: [MapEventDefinition(id: 'sign', title: 'Sign',
            position: const EventPosition(layerId: 'ground', x: 1, y: 1),
            type: MapEventType.object,
            pages: [MapEventPage(pageNumber: 0,
                sceneTarget: MapEventSceneTarget(sceneId: sceneId))])]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(store: store, projectId: 'scenes',
        project: ProjectManifest(name: 'Scenes', version: ProjectVersion.v8, maps: const [
          ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json'),
        ], tilesets: const [], scenes: [scene('welcome'), for (var i = 0; i < 40; i++) scene('other-$i')]));
    final file = File('${root.path}/maps/town.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map('welcome').toJson()));
    await CatalogEditingSession.open(store: store, projectId: 'scenes', actorId: 'actor')
        .then((editing) => editing.close());
    final reader = (await CatalogProjectReader.open(store: store,
        descriptor: working.descriptor.toJson(),
        metadataFields: catalogMapValidationMetadataFields))!;
    final selected = await CatalogTargetedMapSelection.readRevision(reader: reader, mapId: 'town');
    AuthoringRequest request(MapData value) => AuthoringRequest(requestId: 'scenes',
        actionId: 'map.save', actionVersion: 1, workspaceHandle: 'workspace',
        expectedRevision: selected.snapshotRevision, idempotencyKey: 'scenes',
        parameters: {'map': value.toJson()});
    final kept = await CatalogTargetedMapEdit.prepare(reader: reader,
        request: request(map('welcome').copyWith(name: 'Bourg')));
    expect(kept.selection.definitions.scenes.map((scene) => scene.id), ['welcome']);
    await expectLater(
        CatalogTargetedMapEdit.prepare(reader: reader, request: request(map('missing'))),
        throwsA(isA<ValidationException>()));
  });
}
