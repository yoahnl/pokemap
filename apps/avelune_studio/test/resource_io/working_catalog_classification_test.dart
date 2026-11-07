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

void main() {
  test('a working catalog classification survives loading another family and reopening', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'props',
    );

    await fixture.classify('element', 'arbre', 'trees');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );

    final written = await fixture.readPersistedCatalog();
    expect(written.entryFor('element', 'arbre')?.familyId, 'trees');

    await fixture.workspace.ensureResourceKind('tileset');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );

    final persisted = await fixture.readPersistedCatalog();
    expect(persisted.entryFor('element', 'arbre')?.familyId, 'trees');
    expect(persisted.entryFor('element', 'rocher')?.familyId, 'props');

    await fixture.reopen();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'trees',
    );
  });

  test('a new family filled by a batch survives loading another family and reopening', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    await fixture.workspace.ensureResourceKind('element');
    await fixture.mutate('resource.family.create', {
      'familyId': 'family_garden',
      'name': 'Jardin',
      'parentId': null,
    });
    await fixture.mutate('resource.classify_batch', {
      'entries': [
        for (final id in ['arbre', 'caisse'])
          {
            'resourceKind': 'element',
            'resourceId': id,
            'familyId': 'family_garden',
          },
      ],
    });

    await fixture.workspace.ensureResourceKind('character');
    final catalog = fixture.workspace.project!.resourceLibraryCatalog;
    expect(catalog.entryFor('element', 'arbre')?.familyId, 'family_garden');
    expect(catalog.entryFor('element', 'caisse')?.familyId, 'family_garden');
    expect(
      catalog.effectiveFamilies.map((family) => family.id),
      contains('family_garden'),
    );

    final persisted = await fixture.readPersistedCatalog();
    expect(persisted.entryFor('element', 'caisse')?.familyId, 'family_garden');
    expect(persisted.entryFor('element', 'rocher')?.familyId, 'props');

    await fixture.reopen();
    await fixture.workspace.ensureResourceKind('element');
    expect(
      fixture.workspace.project!.resourceLibraryCatalog
          .entryFor('element', 'arbre')
          ?.familyId,
      'family_garden',
    );
  });
}

final class _Fixture {
  _Fixture(this.root, this.sessions, this.session);

  final Directory root;
  final LocalProjectSessionAdapter sessions;
  ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late MapWorkspaceController workspace;
  late LocalResourceAdapter resources;
  bool _workspaceOpen = false;

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'studio_classification_catalog_',
    );
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final source = original.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          for (final id in ['arbre', 'rocher'])
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: id,
              familyId: 'props',
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
    return _Fixture(root, sessions, session);
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
    resources = LocalResourceAdapter(session: session, mapAdapter: maps);
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
    _accept(receipt);
  }

  void _accept(ResourceMutationReceipt receipt) {
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
