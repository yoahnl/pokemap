import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_authoring_session.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_action_contracts.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'read-only actors cannot write ledger metadata during explicit preparation',
      () async {
    final root =
        await Directory.systemTemp.createTemp('catalog-preparation-auth-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'game',
        project:
            ProjectManifest(name: 'Game', maps: const [], tilesets: const []));
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        actor: AuthoringActor(
            actorId: 'reader',
            permissions: [AuthoringPermissionScope.projectRead]),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() async {
      await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    });
    final before = await _ledgerFiles(root);
    await expectLater(
        api.prepareWorkshopDocument(opened.projectHandle),
        throwsA(isA<AuthoringAuthorizationException>().having(
            (error) => error.code, 'code', 'authorization.permission_denied')));
    expect(await _ledgerFiles(root), before);
  });
  test(
      'a failed editing admission can retry and close without leaking its lease',
      () async {
    final parent =
        await Directory.systemTemp.createTemp('catalog-opening-retry-');
    addTearDown(() => parent.delete(recursive: true));
    final canonical = await parent.resolveSymbolicLinks();
    final root = await Directory('$canonical/project').create();
    final initial = await CatalogStorageStore.open(
        projectRoot: root.path,
        trustedAdmissionDirectory: Directory('$canonical/initial-authority'));
    final working = await WorkingProjectCatalog.create(
        store: initial,
        projectId: 'game',
        project:
            ProjectManifest(name: 'Game', maps: const [], tilesets: const []));
    final store = await CatalogStorageStore.open(
        projectRoot: root.path,
        trustedAdmissionDirectory: Directory('$canonical/new-authority'));
    final reader = (await CatalogProjectReader.open(
        store: store,
        descriptor: working.descriptor.toJson(),
        metadataFields: {}))!;
    const files = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: files);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: files,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
    final session = CatalogAuthoringSession(
        reader: reader,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
        actor: AuthoringActor(
            actorId: 'reader',
            permissions: [AuthoringPermissionScope.projectRead]),
        requireActive: () {},
        dispatcher: MapMutationDispatcher.canonical(),
        resolveAction: (_) => catalogDefinitionUpdateDescriptor,
        inspectHistoryReplay: (_, __, ___) async => null,
        loadProject: () async => throw StateError('unused'),
        buildProjectPlan: (_) async => throw StateError('unused'),
        buildScopedProjectPlan: (_, __) async => throw StateError('unused'),
        discardProjectPlan: (_) async {},
        inspectReplay: (_, __) async => null,
        prepareApply: (_, __) async {},
        requirePlanPreconditions: (_) async {},
        projections: null,
        auditOutcome: (_, __, ___, ____, _____) async {},
        clock: DateTime.now,
        limits: const AuthoringSecurityLimits());
    await expectLater(
        session.recoveryStatus('unused'),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_required')));
    expect(await Directory('${root.path}/catalog/leases').list().toList(),
        isEmpty);
    await store.prepareLocalEditing();
    expect((await session.recoveryStatus('unused'))['disposition'], 'notFound');
    await session.close();
    await session.close();
    expect(session.requireRead, throwsStateError);
    expect(await Directory('${root.path}/catalog/leases').list().toList(),
        isEmpty);
  });
}

Future<Map<String, List<int>>> _ledgerFiles(Directory root) async {
  final directory = Directory('${root.path}/.pokemap/authoring');
  if (!await directory.exists()) return {};
  final files = <String, List<int>>{};
  await for (final entity
      in directory.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.contains('/idempotency')) {
      files[entity.path.substring(root.path.length)] =
          await entity.readAsBytes();
    }
  }
  return files;
}
