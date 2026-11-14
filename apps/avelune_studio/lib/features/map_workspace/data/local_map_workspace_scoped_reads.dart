part of 'local_map_workspace_adapter.dart';

extension _LocalScopedCatalogReads on LocalMapWorkspaceAdapter {
  Future<CatalogTargetedMapSelection> _readCanonicalMapSelection(
    ProjectSession session,
    String mapId,
  ) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
      catalogMetadataFields: _mapCatalogMetadataFields.difference({'maps'}),
    );
    final opened = await service.openProject(session.directoryPath);
    try {
      final reader = await service.catalogProject(opened.projectHandle);
      if (reader == null) throw const FormatException();
      return await CatalogTargetedMapSelection.read(
        reader: reader,
        mapId: mapId,
      );
    } finally {
      service.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<T> _readScopedCatalog<T>(
    ProjectSession session,
    Future<T> Function(PortableProjectCatalog catalog, String revision)
    action, {
    Set<String> metadataFields = _mapCatalogMetadataFields,
  }) => _readScopedCatalogWith(
    _reader,
    session,
    action,
    metadataFields: metadataFields,
  );
}

Future<T> _readScopedCatalogWith<T>(
  ProjectFileReader reader,
  ProjectSession session,
  Future<T> Function(PortableProjectCatalog catalog, String revision) action, {
  Set<String> metadataFields = _mapCatalogMetadataFields,
}) async {
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [session.directoryPath],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final service = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    catalogMetadataFields: metadataFields,
  );
  final opened = await service.openProject(session.directoryPath);
  try {
    final source = await service.catalogProject(opened.projectHandle);
    if (source == null) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Ce projet ne possède pas de catalogue partitionné.',
      );
    }
    return await source.read((catalog) async {
      final descriptor = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final head = session.storage == ProjectSessionStorage.workingCatalog
          ? await reader.readBytes(
              projectRoot: session.directoryPath,
              relativePath: CatalogStorageStore.headStorageKey,
            )
          : null;
      final revision = studioProjectDocumentRevision(
        descriptorBytes: descriptor,
        headBytes: head,
      );
      final result = await action(catalog, revision);
      final observedDescriptor = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final observedHead = head == null
          ? null
          : await reader.readBytes(
              projectRoot: session.directoryPath,
              relativePath: CatalogStorageStore.headStorageKey,
            );
      if (studioProjectDocumentRevision(
            descriptorBytes: observedDescriptor,
            headBytes: observedHead,
          ) !=
          revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé pendant sa lecture.',
        );
      }
      return result;
    });
  } finally {
    service.closeWorkspace(opened.workspaceHandle);
  }
}

const _mapCatalogMetadataFields = <String>{
  'maps',
  'groups',
  'settings',
  'newGame',
  'scenes',
  'eventRegistry',
  'cinematics',
  'trainers',
  'scenarios',
  'pokemon',
};
