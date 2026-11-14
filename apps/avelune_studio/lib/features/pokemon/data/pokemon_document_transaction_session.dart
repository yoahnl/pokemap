part of 'pokemon_document_transaction.dart';

extension _PokemonDocumentTransactionSession on PokemonDocumentTransaction {
  Future<
    ({
      WorkspaceHandleStore handles,
      OpenedProject opened,
      ProjectSnapshotLoader snapshots,
      LocalMapAuthoringMutationApi api,
    })
  >
  _openTransaction(bool mediaOnly) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      workshopScope: mediaOnly,
      initializeSceneOwners: !mediaOnly,
      catalogMetadataFields:
          session.storage == ProjectSessionStorage.workingCatalog
          ? const {}
          : null,
    );
    final gateway = mediaOnly
        ? await LocalTransactionFileGateway.open(
            projectRoot: session.directoryPath,
          )
        : null;
    final opened = gateway == null
        ? await opener.openProject(session.directoryPath)
        : await gateway.withExclusiveWriteLock(() async {
            await readPendingTransactionJournals(
              gateway,
              requirePrepared: true,
            );
            return opener.openProject(session.directoryPath);
          });
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      catalogFileReader: reader,
    );
    return (handles: handles, opened: opened, snapshots: snapshots, api: api);
  }

  void _requireSnapshotDependencies(
    ProjectSnapshot snapshot,
    List<PokemonDocumentReadDependency> dependencies,
  ) {
    for (final dependency in dependencies) {
      if (snapshot.resourceStorageKeys[dependency.resourceIdentity] !=
              dependency.relativePath ||
          !_sameBytes(
            snapshot.findResourceBytes(dependency.resourceIdentity),
            dependency.beforeBytes,
          )) {
        throw PokemonWorkspaceFailure(
          '${dependency.relativePath} a changé depuis l’aperçu. '
          'Reprévisualisez.',
        );
      }
    }
  }

  Future<
    ({
      Map<String, String> gifHandles,
      Map<String, String> pngHandles,
      String? cryHandle,
    })
  >
  _putArtifacts(
    LocalMapAuthoringMutationApi api, {
    required Map<String, List<int>> battleGifs,
    required Map<String, List<int>> pokemonPngs,
    required ({List<int> bytes, String mediaType})? battleCry,
  }) async {
    final gifHandles = <String, String>{};
    for (final entry in battleGifs.entries) {
      gifHandles[entry.key] = (await api.artifacts.put(
        entry.value,
        declaredMediaType: 'image/gif',
      )).reference.handle;
    }
    final pngHandles = <String, String>{};
    for (final entry in pokemonPngs.entries) {
      pngHandles[entry.key] = (await api.artifacts.put(
        entry.value,
        declaredMediaType: 'image/png',
      )).reference.handle;
    }
    final cryHandle = battleCry == null
        ? null
        : (await api.artifacts.put(
            battleCry.bytes,
            declaredMediaType: battleCry.mediaType,
          )).reference.handle;
    return (
      gifHandles: gifHandles,
      pngHandles: pngHandles,
      cryHandle: cryHandle,
    );
  }
}
