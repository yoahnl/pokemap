import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_working_catalog_adapter.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  late ResourceFixture fixture;
  late ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late LocalResourceAdapter resources;

  setUp(() async {
    fixture = await ResourceFixture.create();
    final project = ProjectManifest.fromJson(
      jsonDecode(await fixture.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    await fixture.manifestFile.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: fixture.root.path),
      projectId: 'studio-map-working',
      project: project.copyWith(
        tilesets: [
          const ProjectTilesetEntry(
            id: 'existing',
            name: 'Existing',
            relativePath: 'existing.png',
          ),
        ],
      ),
    );
    session = ProjectSession(
      sessionId: 'working',
      name: project.name,
      directoryPath: fixture.root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    maps = LocalMapWorkspaceAdapter();
    resources = LocalResourceAdapter(session: session, mapAdapter: maps);
  });

  tearDown(() async {
    await resources.dispose();
    await fixture.dispose();
  });

  test('a crashed transaction reopens in recovery and resumes through the Studio catalogue port', () async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final service = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await service.openProject(fixture.root.path);
    final crash = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
      faultInjector: (context) {
        if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted &&
            context.storageKey == CatalogStorageStore.headStorageKey) {
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    await crash.attachProject(
      projectRootPath: fixture.root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final before = await loader.load(opened.projectHandle);
    final plan = await crash.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: 'crash',
        actionId: 'map.create',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: before.revision,
        idempotencyKey: 'crash',
        parameters: const {'mapId': 'recovered', 'width': 4, 'height': 4},
      ),
    );
    await expectLater(
      crash.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: 'interrupted-map',
      ),
      throwsA(isA<AuthoringTransactionSimulatedCrash>()),
    );
    await crash.detachWorkspace(opened.workspaceHandle);
    service.closeWorkspace(opened.workspaceHandle);
    final sessions = LocalProjectSessionAdapter();
    final reopened = await sessions.open(fixture.root.path);
    expect(reopened.storage, ProjectSessionStorage.workingCatalog);
    expect(reopened.recoveryOperationIds, ['interrupted-map']);
    final port = LocalWorkingCatalogAdapter(reopened);
    final controller = WorkingCatalogController(
      port,
      recoveryOperationIds: reopened.recoveryOperationIds,
    );
    addTearDown(controller.dispose);
    await controller.search('');
    expect(controller.items, isEmpty);
    await controller.recover();
    expect(controller.error, isNull);
    expect(controller.recoveryOperationIds, isEmpty);
    expect(
      (await LocalMapWorkspaceAdapter().loadProject(reopened)).maps
          .map((map) => map.id),
      contains('recovered'),
    );
    await port.close();
    await sessions.close(reopened);
  });

  test('scoped opening reads metadata and the selected map without unrelated definitions', () async {
    final store = await CatalogStorageStore.open(
      projectRoot: fixture.root.path,
    );
    final working = await WorkingProjectCatalog.open(
      store: store,
      descriptor: WorkingProjectCatalogDescriptor(
        projectId: 'studio-map-working',
      ),
    );
    final unused = await working.catalog.snapshot.indexEntry(
      CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'existing'),
    );
    final path = File(
      '${fixture.root.path}/catalog/objects/${unused!.reference.sha256}.json',
    );
    final bytes = await path.readAsBytes();
    await path.writeAsString('unrelated unreadable definition');
    try {
      final catalog = await maps.loadCatalog(session);
      expect(catalog.metadata.tilesets, isEmpty);
      expect(catalog.metadata.maps, [ResourceFixture.entry]);
      final selection = await maps.loadMapSelection(
        session,
        ResourceFixture.entry,
      );
      expect(selection.document.map.id, ResourceFixture.entry.id);
      expect(selection.definitions.tilesets, isEmpty);
      await expectLater(
        maps.resourceBaseline(session),
        throwsA(
          isA<MapWorkspaceFailure>().having(
            (failure) => failure.problem,
            'problem',
            MapWorkspaceProblem.unavailable,
          ),
        ),
      );
      await expectLater(maps.materializeProject(session), throwsA(anything));
    } finally {
      await path.writeAsBytes(bytes);
    }
  });

  test(
    'scoped map save uses its root and preserves a partial definition context',
    () async {
      await maps.loadCatalog(session);
      final selection = await maps.loadMapSelection(
        session,
        ResourceFixture.entry,
      );
      final descriptor = await fixture.manifestFile.readAsBytes();
      await maps.saveMap(
        session,
        selection.document,
        selection.document.map.copyWith(name: 'Ciblée'),
      );
      expect(await fixture.manifestFile.readAsBytes(), descriptor);
      await expectLater(
        maps.resourceBaseline(session),
        throwsA(isA<MapWorkspaceFailure>()),
      );
      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadCatalog(session);
      expect(
        (await reopened.loadMapSelection(
          session,
          ResourceFixture.entry,
        )).document.map.name,
        'Ciblée',
      );
    },
  );

  test('scoped map version changes independently from HEAD and rejects stale map bytes', () async {
    await maps.loadCatalog(session);
    final first = await maps.loadMapSelection(session, ResourceFixture.entry);
    await fixture.mapFile.writeAsString(
      jsonEncode(
        first.document.map.copyWith(name: 'Modification externe').toJson(),
      ),
    );
    final external = await fixture.mapFile.readAsBytes();
    final second = await maps.loadMapSelection(session, ResourceFixture.entry);
    expect(second.catalogRevision, first.catalogRevision);
    expect(second.snapshotRevision, isNot(first.snapshotRevision));
    await expectLater(
      maps.saveMap(
        session,
        first.document,
        first.document.map.copyWith(name: 'Brouillon ancien'),
      ),
      throwsA(
        isA<MapWorkspaceFailure>().having(
          (failure) => failure.problem,
          'problem',
          MapWorkspaceProblem.conflict,
        ),
      ),
    );
    expect(await fixture.mapFile.readAsBytes(), external);
  });

  test(
    'working map save commits map and HEAD and reopens the authored map',
    () async {
      final project = await maps.loadProject(session);
      expect(project.tilesets.single.id, 'existing');
      final descriptor = await fixture.manifestFile.readAsBytes();
      final head = await File(
        '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
      ).readAsBytes();
      final base = await maps.loadMap(session, ResourceFixture.entry);
      await maps.saveMap(
        session,
        base,
        base.map.copyWith(name: 'Carte enregistrée'),
      );
      expect(await fixture.manifestFile.readAsBytes(), descriptor);
      expect(
        await File('${fixture.root.path}/${CatalogStorageStore.headStorageKey}')
            .readAsBytes(),
        isNot(head),
      );
      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadProject(session);
      expect(
        (await reopened.loadMap(session, ResourceFixture.entry)).map.name,
        'Carte enregistrée',
      );
    },
  );

  test('image import and decor publication preserve the map and refresh canonical receipts', () async {
    await maps.loadProject(session);
    final mapBytes = await fixture.mapFile.readAsBytes();
    final descriptor = await fixture.manifestFile.readAsBytes();
    final receipt = await resources.importImage(
      ResourceImageImport(
        sourcePath: fixture.source.path,
        name: 'Arbres',
        tileWidth: 16,
        tileHeight: 24,
      ),
    );
    expect(receipt.manifest.tilesets, hasLength(2));
    expect(receipt.revision, isNot(receipt.beforeRevision));
    final tileset = receipt.manifest.tilesets.firstWhere(
      (item) => item.name == 'Arbres',
    );
    final decor = fixture
        .element(tileset.id)
        .copyWith(categoryId: 'studio_decors');
    final saved = await resources.saveElement(decor);
    expect(saved.manifest.elements.single, decor);
    expect(await fixture.mapFile.readAsBytes(), mapBytes);
    expect(await fixture.manifestFile.readAsBytes(), descriptor);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(session);
    expect(reopened.elements.single, decor);
    expect(reopened.tilesets, hasLength(2));
  });

  test(
    'a changed catalog HEAD rejects map save without overwriting the map',
    () async {
      await maps.loadProject(session);
      final base = await maps.loadMap(session, ResourceFixture.entry);
      final before = await fixture.mapFile.readAsBytes();
      final catalog = LocalWorkingCatalogAdapter(session);
      addTearDown(catalog.close);
      final page = await catalog.query(kind: 'tileset', text: 'Existing');
      final detail = await catalog.open(page.items.single);
      await catalog.save(
        detail.entry,
        WorkingCatalogDraft.fromEntry(detail.entry)
            .copyWith(name: 'Changed elsewhere'),
        revision: detail.revision,
      );
      await expectLater(
        maps.saveMap(session, base, base.map.copyWith(name: 'À préserver')),
        throwsA(
          isA<MapWorkspaceFailure>().having(
            (failure) => failure.problem,
            'problem',
            MapWorkspaceProblem.conflict,
          ),
        ),
      );
      expect(await fixture.mapFile.readAsBytes(), before);
    },
  );

  test(
    'map creation uses a complete projected receipt and survives reopening',
    () async {
      await maps.loadProject(session);
      final adapter = LocalMapCatalogAdapter(maps);
      final receipt = await adapter.mutate(session, 'map.create', {
        'mapId': 'new_map',
        'name': 'Nouvelle carte',
        'width': 4,
        'height': 4,
      });
      expect(receipt.createdMapId, 'new_map');
      expect(receipt.manifest.maps, hasLength(2));
      await maps.acceptCatalogMutation(session, receipt);
      final reopened = LocalMapWorkspaceAdapter();
      final manifest = await reopened.loadProject(session);
      expect(manifest.maps, hasLength(2));
      expect(
        (await reopened.loadMap(
          session,
          manifest.maps.firstWhere((map) => map.id == 'new_map'),
        )).map.name,
        'Nouvelle carte',
      );
    },
  );

  test('a committed import with failed reconciliation can be reread without reapplying', () async {
    await maps.loadProject(session);
    await resources.dispose();
    resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      beforeReconciliation: () async {
        throw StateError('Relecture interrompue');
      },
    );
    ResourceMutationReceipt? receipt;
    try {
      await resources.importImage(
        ResourceImageImport(
          sourcePath: fixture.source.path,
          name: 'Arbres',
          tileWidth: 16,
          tileHeight: 24,
        ),
      );
      fail('The reconciliation interruption must be surfaced.');
    } on ResourceFailure catch (failure) {
      receipt = failure.partialReceipt;
    }
    expect(receipt, isNotNull);
    expect(receipt!.manifest.tilesets, hasLength(2));
    await resources.reconcileReceipt(receipt);
    expect(
      (await maps.resourceBaseline(session)).manifest.tilesets,
      hasLength(2),
    );
    expect(
      (await LocalMapWorkspaceAdapter().loadProject(session)).tilesets,
      hasLength(2),
    );
  });
}
