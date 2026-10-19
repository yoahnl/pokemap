import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'partition preparation keeps the monolith authoritative until one journal applies',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('working-partition-');
    addTearDown(() => directory.delete(recursive: true));
    final project =
        ProjectManifest(name: 'Game', maps: const [], tilesets: const []);
    final file = File('${directory.path}/project.json');
    await file.writeAsString(jsonEncode(project.toJson()));
    final original = await file.readAsBytes();
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final revision = await store.gateway.readResourceRevision('project.json');
    final preparation = await WorkingProjectCatalog.preparePartition(
        store: store,
        projectId: 'game',
        project: project,
        ownerId: 'partition_plan',
        expectedProjectRevision: revision!);
    expect(await store.readHead(), isNull);
    expect(await store.readProjectId(), isNull);
    expect(await file.readAsBytes(), original);
    expect((await store.openRoot(preparation.root)).snapshot.root,
        preparation.root);
    await store.gateway.withExclusiveWriteLock(
        () => preparation.attachOperationUnderLock('partition_operation'));
    await preparation.close();
    expect(await store.readHead(), isNull);
    expect(await file.readAsBytes(), original);
    expect(await Directory('${directory.path}/catalog/leases').list().toList(),
        isEmpty);
  });

  test('initialization retries an unpublished matching generation', () async {
    final directory = await Directory.systemTemp.createTemp('working-retry-');
    addTearDown(() => directory.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final project =
        ProjectManifest(name: 'Game', maps: const [], tilesets: const []);
    final build = PortableCatalogPublication.encodeProject(project);
    await store.publish(build.storage, expectedRootRevision: null);
    final reopened = await WorkingProjectCatalog.create(
        store: store, projectId: 'game', project: project);
    expect(reopened.root, build.storage.root);
    expect(await File('${directory.path}/project.json').exists(), isTrue);
  });
  test('working reads write nothing and unit edits keep descriptor static',
      () async {
    final directory = await Directory.systemTemp.createTemp('working-catalog-');
    addTearDown(() => directory.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'game',
        project: ProjectManifest(name: 'Game', maps: const [], tilesets: [
          const ProjectTilesetEntry(
              id: 'tile', name: 'Before', relativePath: 'tile.png')
        ]));
    final descriptorFile = File('${directory.path}/project.json');
    final descriptorBytes = await descriptorFile.readAsBytes();
    final before = await _inventory(directory);
    final reopened = await WorkingProjectCatalog.open(
        store: store,
        descriptor: WorkingProjectCatalogDescriptor.fromJson(
            Map<String, Object?>.from(
                jsonDecode(utf8.decode(descriptorBytes)) as Map)));
    final page = await reopened.search(kind: CatalogDefinitionKind.tileset);
    final current = (await reopened.lookup(page.items.single.key))!;
    expect(await _inventory(directory), before);
    final edit = reopened.replaceDefinitionValue(current, {
      ...Map<String, Object?>.from(current.payload['value']! as Map),
      'name': 'After',
    });
    final session = await CatalogEditingSession.open(
        store: store, projectId: 'game', actorId: 'test');
    addTearDown(session.close);
    final identityBefore = await _inventory(directory);
    await expectLater(
        WorkingProjectCatalog.open(
            store: store,
            descriptor: WorkingProjectCatalogDescriptor(projectId: 'other')),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.project_mismatch')));
    expect(await _inventory(directory), identityBefore);
    final request = AuthoringRequest(
        requestId: 'request',
        actionId: 'catalog.definition.update',
        actionVersion: 1,
        workspaceHandle: 'workspace',
        expectedRevision: 'sha256:${working.root.sha256}',
        idempotencyKey: 'edit',
        parameters: {'id': 'tile', 'name': 'After'});
    final plan = await session
        .planPatch(upserts: [edit], idempotencyKey: 'edit', request: request);
    expect(plan.plan.request.actionId, 'catalog.definition.update');
    final receipt = await session.apply(plan, operationId: 'user_operation');
    expect((await session.apply(plan, operationId: 'user_operation')).toJson(),
        receipt.toJson());
    expect(plan.operationId, 'user_operation');
    expect(await descriptorFile.readAsBytes(), descriptorBytes);
    await expectLater(
        working.search(),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.revision_conflict')));
    final fresh = await WorkingProjectCatalog.open(
        store: store, descriptor: working.descriptor);
    expect((await fresh.exportProject()).tilesets.single.name, 'After');
    await session.undo(
        entryId: receipt.receiptId, idempotencyKey: 'undo-public');
    expect(
        (await WorkingProjectCatalog.open(
                store: store, descriptor: working.descriptor))
            .root,
        working.root);
    await session.redo(
        entryId: receipt.receiptId, idempotencyKey: 'redo-public');
  });
}

Future<Map<String, String>> _inventory(Directory root) async => {
      await for (final file in root.list(recursive: true))
        if (file is File) file.path: base64Encode(await file.readAsBytes()),
    };
