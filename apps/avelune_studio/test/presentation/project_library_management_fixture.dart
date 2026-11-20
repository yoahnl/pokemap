part of 'project_library_management_test.dart';

Future<(MapWorkspaceController, _LibraryEditor)> _open(
  WidgetTester tester,
  _LibraryPort port, {
  PickedProjectLibraryFile? file,
}) async {
  tester.view.physicalSize = const Size(1500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final maps = MapWorkspaceController(scopedMapSession, port);
  addTearDown(maps.dispose);
  await maps.initialize();
  final editor = _LibraryEditor(maps.project!);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: ProjectLibraryPage(
          active: true,
          maps: maps,
          visuals: null,
          management: (editor: editor, pickFile: () async => file),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (maps, editor);
}

class _LibraryPort extends ScopedTestMapPort
    implements ProjectResourceLibraryPort, ProjectResourceLibraryMapUsagesPort {
  int libraryReads = 0;
  final usages = Completer<Map<String, Set<String>>?>();

  @override
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  }) => usages.future;

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async {
    libraryReads++;
    return ProjectResourceLibrary(ResourceLibraryCatalog(), [
      ProjectLibraryItem(kind: 'element', id: 'tree', name: 'Arbre'),
    ], revision: 'library-r0');
  }
}

class _DimensionLibraryPort extends _LibraryPort
    implements ProjectResourceLibraryDimensionsPort {
  final firstDimensions = Completer<Map<String, Set<ProjectDimension>>?>();
  final updatedDimensions = Completer<Map<String, Set<ProjectDimension>>?>();
  final dimensionRevisions = <String>[];

  @override
  Future<ProjectResourceLibrary> readResourceLibraryIndex(
    ProjectSession session,
  ) async {
    final library = await super.readResourceLibrary(session);
    return ProjectResourceLibrary(library.catalog, [
      ...library.items,
      ProjectLibraryItem(
        kind: 'environmentPreset',
        id: 'woodland',
        name: 'Bosquet',
      ),
    ], revision: library.revision);
  }

  @override
  Future<Map<String, Set<ProjectDimension>>?> readResourceLibraryDimensions(
    ProjectSession session, {
    required String revision,
  }) {
    dimensionRevisions.add(revision);
    return revision == 'library-r0'
        ? firstDimensions.future
        : updatedDimensions.future;
  }
}

class _LibraryEditor implements ProjectLibraryEditor {
  _LibraryEditor(this.manifest);

  final ProjectManifest manifest;
  final revisions = <String>[];
  late ResourceMutationReceipt receipt;
  ResourceLibraryRole? role;
  LibraryImageSize? importTileSize;
  ResourceFailure? failure;
  int renameAttempts = 0;
  int deletions = 0;
  int released = 0;
  bool used = false;

  ProjectLibraryEdit _edit(ProjectLibraryItem item, String revision) {
    revisions.add(revision);
    receipt = ResourceMutationReceipt(
      before: manifest,
      manifest: manifest,
      beforeRevision: revision,
      revision: 'library-r${revisions.length}',
      changedPaths: const ['catalog/HEAD.json'],
    );
    return (item: item, receipt: receipt);
  }

  @override
  Future<ProjectLibraryEdit> importResource(
    PickedProjectLibraryFile file, {
    required String name,
    required LibraryImageSize? tileSize,
    required String expectedRevision,
  }) async {
    importTileSize = tileSize;
    return _edit(
      ProjectLibraryItem(kind: 'tileset', id: 'imported', name: name),
      expectedRevision,
    );
  }

  @override
  Future<ProjectLibraryEdit> renameResource(
    ProjectLibraryItem item, {
    required String name,
    required String expectedRevision,
  }) async {
    renameAttempts++;
    if (failure case final problem?) throw problem;
    return _edit(
      ProjectLibraryItem(kind: item.kind, id: item.id, name: name),
      expectedRevision,
    );
  }

  @override
  Future<ProjectLibraryEdit> classifyResource(
    ProjectLibraryItem item, {
    required String? familyId,
    required ResourceLibraryRole role,
    required String expectedRevision,
  }) async {
    this.role = role;
    return _edit(
      ProjectLibraryItem(
        kind: item.kind,
        id: item.id,
        name: item.name,
        familyId: familyId,
        role: role,
      ),
      expectedRevision,
    );
  }

  @override
  Future<ProjectLibraryEdit> modifyLibraryResource(
    ProjectLibraryItem item, {
    required String? description,
    required ResourcePlacementContext? placementContext,
    required String expectedRevision,
  }) async => _edit(
    ProjectLibraryItem(
      kind: item.kind,
      id: item.id,
      name: item.name,
      description: description,
      placementContext: placementContext,
    ),
    expectedRevision,
  );

  @override
  Future<ProjectLibraryEdit> duplicateLibraryResource(
    ProjectLibraryItem item, {
    required String name,
    required String expectedRevision,
  }) async => _edit(
    ProjectLibraryItem(
      kind: item.kind,
      id: '${item.id}-copy',
      name: name,
      description: item.description,
    ),
    expectedRevision,
  );

  @override
  bool libraryDraftUses(
    ProjectLibraryItem item,
    Iterable<Map<String, Object?>> drafts,
  ) => false;

  @override
  Future<ResourceMutationPreparation> prepareLibraryDeletion(
    ProjectLibraryItem item, {
    required String expectedRevision,
  }) async {
    if (used) {
      throw const ResourceFailure('Cette ressource est encore utilisée.');
    }
    return ResourceMutationPreparation(
      sessionId: scopedMapSession.sessionId,
      actionId: 'catalog.definition.delete',
      parameters: {'resourceKind': item.kind, 'id': item.id},
      manifestRevision: expectedRevision,
      snapshotRevision: expectedRevision,
      changedPaths: const ['catalog/HEAD.json'],
      confirmationRequired: true,
    );
  }

  @override
  Future<ResourceMutationReceipt> applyPrepared(
    ResourceMutationPreparation preparation, {
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  }) async {
    expect(confirmDestructive, isTrue);
    expect(validateBeforeApply?.call(), isNull);
    deletions++;
    return _edit(
      ProjectLibraryItem(
        kind: 'element',
        id: preparation.parameters['id'] as String,
        name: '',
      ),
      preparation.manifestRevision,
    ).receipt;
  }

  @override
  Future<void> releasePreparation(
    ResourceMutationPreparation preparation,
  ) async {
    released++;
  }

  @override
  Future<ResourceMutationReceipt> prepareResourceIndexes({
    required String expectedSnapshotRevision,
  }) => throw UnimplementedError();
}
