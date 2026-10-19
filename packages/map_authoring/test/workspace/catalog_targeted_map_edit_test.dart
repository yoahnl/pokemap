import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_targeted_map_edit.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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
}
