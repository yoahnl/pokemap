import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_positions.dart';
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

  test(
      'initialization retries a matching generation and prepares local indexes',
      () async {
    final directory = await Directory.systemTemp.createTemp('working-retry-');
    addTearDown(() => directory.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final project =
        ProjectManifest(name: 'Game', maps: const [], tilesets: const []);
    final build = PortableCatalogPublication.encodeProject(project);
    await store.publish(build.storage, expectedRootRevision: null);
    final reopened = await WorkingProjectCatalog.create(
        store: store, projectId: 'game', project: project);
    expect(reopened.root, isNot(build.storage.root));
    expect((await reopened.exportProject()).toJson(), project.toJson());
    final marker = await reopened.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.workspaceState,
        jsonEncode(['metadataField', 'facts'])));
    expect(marker!.payload['valid'], isTrue);
    expect(await File('${directory.path}/project.json').exists(), isTrue);
  });
  test('creation writes the resource slots so the first preparation keeps HEAD',
      () async {
    final directory = await Directory.systemTemp.createTemp('working-slots-');
    addTearDown(() => directory.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'game', project: _slotProject());
    final created = (await store.openRoot(working.root)).snapshot;
    expect(await CatalogResourcePositions.prepareSlots(created), isEmpty);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path, incrementalWrites: true);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        incrementalHistory: true,
        history: history);
    try {
      await session.prepareMetadataDocuments();
      expect(session.snapshot.root, working.root);
      expect(await store.readHead(), working.root);
      expect(await history.latestLocalEntry(projectId: 'game'), isNull);
    } finally {
      await session.close();
    }
  });

  test('a catalog initialized before resource slots still prepares them',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('working-legacy-slots-');
    addTearDown(() => directory.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: directory.path);
    final legacy = await _publishWithoutResourceSlots(store, _slotProject());
    expect(await CatalogResourcePositions.prepareSlots(legacy), isNotEmpty);
    await expectLater(
        CatalogResourcePositions.readSlot(
            legacy, CatalogDefinitionKind.resourceLibraryEntry, 0),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', 'catalog.resource_positions.slots_preparation_required')));
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        incrementalHistory: true,
        history: await FileAuthoringHistoryStore.open(
            projectRoot: directory.path, incrementalWrites: true));
    try {
      await session.prepareMetadataDocuments();
      expect(session.snapshot.root, isNot(legacy.root));
      expect(
          await CatalogResourcePositions.prepareSlots(session.snapshot), isEmpty);
    } finally {
      await session.close();
    }

    final retryDirectory =
        await Directory.systemTemp.createTemp('working-legacy-retry-');
    addTearDown(() => retryDirectory.delete(recursive: true));
    final retryStore =
        await CatalogStorageStore.open(projectRoot: retryDirectory.path);
    await _publishWithoutResourceSlots(retryStore, _slotProject());
    final working = await WorkingProjectCatalog.create(
        store: retryStore, projectId: 'game', project: _slotProject());
    expect(
        await CatalogResourcePositions.prepareSlots(
            (await retryStore.openRoot(working.root)).snapshot),
        isEmpty);
    expect((await working.exportProject()).toJson(), _slotProject().toJson());
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

  test(
      'a reopened catalog rereads no index page until another writer moves HEAD',
      () async {
    final directory = await Directory.systemTemp.createTemp('working-shared-');
    addTearDown(() => directory.delete(recursive: true));
    final project = ProjectManifest(name: 'Game', maps: const [], tilesets: [
      for (var index = 0; index < 300; index++)
        ProjectTilesetEntry(
            id: 'tile-$index', name: 'Tile $index', relativePath: 't$index.png')
    ]);
    final descriptor = WorkingProjectCatalogDescriptor(projectId: 'game');
    await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: directory.path),
        projectId: 'game',
        project: project);
    Future<CatalogStorageStore> observedStore(_CountingReader reader) async =>
        CatalogStorageStore(
            projectRoot: directory.path,
            reader: reader,
            gateway: await LocalTransactionFileGateway.open(
                projectRoot: directory.path));
    Future<List<String>> tileNames(WorkingProjectCatalog catalog) async => [
          for (var index = 0; index < 300; index += 70)
            ((await catalog.lookup(CatalogDefinitionKey(
                    CatalogDefinitionKind.tileset, 'tile-$index')))!
                .payload['value']! as Map)['name']! as String
        ];
    Iterable<String> objects(_CountingReader reader) =>
        reader.paths.where((path) => path.startsWith('catalog/objects/'));
    bool unit(String path) => File('${directory.path}/$path')
        .readAsStringSync()
        .startsWith('{"key":');

    final first = _CountingReader();
    final opened = await WorkingProjectCatalog.open(
        store: await observedStore(first), descriptor: descriptor);
    final names = await tileNames(opened);
    expect(objects(first), isNotEmpty);

    final second = _CountingReader();
    final reopened = await WorkingProjectCatalog.open(
        store: await observedStore(second), descriptor: descriptor);
    expect(await tileNames(reopened), names);
    expect(objects(second), isNotEmpty);
    expect(objects(second).every(unit), isTrue,
        reason: 'definitions are reread and verified, index pages are not');
    expect(second.paths, contains(CatalogStorageStore.headStorageKey));
    expect(second.paths, contains('catalog/IDENTITY.json'));

    final before = await _objectFiles(directory);
    final writer = await CatalogEditingSession.open(
        store: await CatalogStorageStore.open(projectRoot: directory.path),
        projectId: 'game',
        actorId: 'other-process');
    final current = (await writer.snapshot.lookup(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile-140')))!;
    await writer.apply(await writer.planPatch(upserts: [
      reopened.replaceDefinitionValue(current, {
        ...Map<String, Object?>.from(current.payload['value']! as Map),
        'name': 'Renamed elsewhere',
      })
    ], idempotencyKey: 'external'));
    await writer.close();
    final written = (await _objectFiles(directory)).difference(before);
    expect(written, isNotEmpty);

    await expectLater(
        tileNames(reopened),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.revision_conflict')));
    final third = _CountingReader();
    final fresh = await WorkingProjectCatalog.open(
        store: await observedStore(third), descriptor: descriptor);
    expect(fresh.root, isNot(reopened.root));
    expect(await tileNames(fresh), [...names]..[2] = 'Renamed elsewhere');
    expect(
        objects(third).where((path) => !unit(path) && !written.contains(path)),
        isEmpty,
        reason: 'only index pages of the new generation are read');
  });
}

Future<Set<String>> _objectFiles(Directory root) async => {
      await for (final file in Directory('${root.path}/catalog/objects').list())
        if (file is File) 'catalog/objects/${file.uri.pathSegments.last}',
    };

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}

Future<Map<String, String>> _inventory(Directory root) async => {
      await for (final file in root.list(recursive: true))
        if (file is File) file.path: base64Encode(await file.readAsBytes()),
    };

ProjectManifest _slotProject() =>
    ProjectManifest(name: 'Game', maps: const [], tilesets: const [
      ProjectTilesetEntry(id: 'first', name: 'First', relativePath: 'a.png'),
      ProjectTilesetEntry(id: 'second', name: 'Second', relativePath: 'b.png'),
    ]);

Future<CatalogSnapshot> _publishWithoutResourceSlots(
    CatalogStorageStore store, ProjectManifest project) async {
  final build = PortableCatalogPublication.encodeProject(project);
  final units = CatalogSnapshot.readAllSync(
          root: build.storage.root,
          readObject: (reference) => build.storage.objects[reference.sha256]!,
          limits: store.limits)
      .units;
  final storage = CatalogStorageBuilder(limits: store.limits)
      .build([...units, ...CatalogMetadataDocuments.initialize(units)]);
  final published = await store.publish(storage, expectedRootRevision: null);
  return published.snapshot;
}
