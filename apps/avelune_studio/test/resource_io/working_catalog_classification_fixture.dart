import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

final class ClassificationFixture {
  ClassificationFixture(this.root, this.sessions, this.session);

  final Directory root;
  final LocalProjectSessionAdapter sessions;
  ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late MapWorkspaceController workspace;
  late LocalResourceAdapter resources;
  final phases = <String>[];
  bool _workspaceOpen = false;

  static Future<ClassificationFixture> create({int unrelated = 0}) async {
    final qa = Directory(
      '/Users/karim/Library/Caches/AveluneQA/resource-inverse-index/tests',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('studio_classification_catalog_');
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final extra = [
      for (var index = 0; index < unrelated; index++)
        original.elements.last.copyWith(
          id: 'decor_${index.toString().padLeft(4, '0')}',
          name: 'Décor $index',
        ),
    ];
    final source = original.copyWith(
      elements: [...original.elements, ...extra],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          for (final id in ['arbre', 'rocher'])
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: id,
              familyId: 'props',
            ),
          for (final element in extra)
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: element.id,
              familyId: 'buildings',
              description: element.name,
            ),
        ],
      ),
    );
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-classification-test',
      project: source,
    );
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    return ClassificationFixture(root, sessions, session);
  }

  Future<void> openWorkspace() async {
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    expect(workspace.error, isNull);
    final entry = workspace.project!.maps.firstWhere(
      (entry) => entry.id == 'jardin',
    );
    await workspace.activate(entry);
    expect(workspace.error, isNull);
    resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      mutationPhaseObserver: phases.add,
    );
    _workspaceOpen = true;
  }

  Future<void> classify(String kind, String id, String familyId) => mutate(
    'resource.classify',
    {'resourceKind': kind, 'resourceId': id, 'familyId': familyId},
  );

  Future<void> mutate(String action, Map<String, Object?> parameters) async {
    final revision = await resources.captureResourceRevision();
    final preparation = await resources.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    final receipt = await resources.applyPrepared(preparation);
    accept(receipt);
  }

  void accept(ResourceMutationReceipt receipt) {
    workspace.acceptResources(receipt.before, receipt.manifest);
  }

  Future<ResourceLibraryCatalog> readPersistedCatalog() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final catalog = await WorkingProjectCatalog.open(
      store: store,
      descriptor: WorkingProjectCatalogDescriptor(
        projectId: 'studio-classification-test',
      ),
    );
    try {
      final project = await catalog.exportProject();
      return project.resourceLibraryCatalog;
    } finally {
      await catalog.close();
    }
  }

  Future<void> reopen() async {
    await _closeWorkspace();
    await sessions.close(session);
    session = await sessions.open(await root.resolveSymbolicLinks());
    await openWorkspace();
  }

  Future<void> _closeWorkspace() async {
    if (!_workspaceOpen) return;
    _workspaceOpen = false;
    await resources.dispose();
    workspace.dispose();
  }

  Future<void> dispose() async {
    await _closeWorkspace();
    await sessions.close(session);
    await root.delete(recursive: true);
  }
}
