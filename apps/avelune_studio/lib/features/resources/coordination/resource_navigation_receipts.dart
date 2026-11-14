part of 'resource_navigation.dart';

Future<ProjectManifest> _acceptResourceReceipt(
  ResourceNavigation navigation,
  ResourceMutationReceipt receipt,
) async {
  navigation.pendingReceipt = receipt;
  try {
    if (navigation._disposed || navigation.workspace.isDisposed) {
      throw const ResourceFailure(
        'Le projet a été fermé après la publication.',
      );
    }
    if (receipt.changedPaths.isEmpty &&
        identical(receipt.before, receipt.manifest) &&
        receipt.beforeRevision == receipt.revision) {
      navigation.pendingReceipt = null;
      navigation.changed();
      return navigation.workspace.project ?? receipt.manifest;
    }
    navigation.workspace.acceptResourceMaps({
      for (final entry in receipt.changedMaps.entries)
        entry.key: MapWorkspaceDocument(
          map: entry.value,
          revision: receipt.mapRevisions[entry.key]!,
          mapId: entry.key,
        ),
    }, replaceContent: receipt.actionId == 'resource.usages.replace');
    if (receipt.changedModels.isNotEmpty
        ? !identical(navigation.workspace.project, receipt.manifest)
        : navigation.workspace.project != receipt.manifest) {
      navigation.workspace.acceptResources(
        receipt.before,
        receipt.manifest,
        changedModels: receipt.changedModels,
      );
    }
    if (receipt.changedPaths.isEmpty &&
        receipt.before == receipt.manifest &&
        receipt.beforeRevision == receipt.revision) {
      navigation.pendingReceipt = null;
      navigation.changed();
      return receipt.manifest;
    }
    if (receipt.changedModels.isNotEmpty &&
        navigation.visuals is SpatialModelSourceWorkspaceVisuals) {
      await (navigation.visuals as SpatialModelSourceWorkspaceVisuals)
          .updateModelSources(
            navigation.workspace.project!,
            receipt.changedModels,
            receipt.modelSourceRevisions,
          );
    } else {
      navigation.characters.refreshClean();
      navigation.reconcileCharacterManagement(receipt);
      if (receipt.actionId == 'characterStudio.character.delete') {
        navigation.characterSourcesChanged?.call({
          for (final entry in receipt.before.dialogues)
            if (receipt.changedPaths.contains(entry.relativePath)) entry.id,
        });
      }
      navigation.reconcileTerrainManagement(receipt);
      navigation.reconcileBorderManagement(receipt);
      for (final model in navigation.terrains.values) {
        model.manifest = receipt.manifest;
      }
      if (navigation.visuals case final ResourceWorkspaceVisuals resources) {
        await resources.updateCatalog(
          receipt.manifest,
          changedRelativePaths: receipt.changedPaths.toSet(),
        );
      }
    }
    if (navigation._disposed) {
      throw const ResourceFailure(
        'Le projet a été fermé après la publication.',
      );
    }
    navigation.pendingReceipt = null;
    navigation.changed();
    return receipt.changedModels.isEmpty
        ? receipt.manifest
        : navigation.workspace.project!;
  } on Object catch (failure) {
    throw ResourceFailure(
      'La publication a réussi, mais l’interface n’a pas pu être actualisée. Relisez sans relancer la mutation. $failure',
      partialReceipt: receipt,
    );
  }
}

String? _characterPublicationProblem(
  ResourceNavigation navigation,
  ResourceMutationPreparation preparation,
) {
  if (preparation.actionId != 'characterStudio.character.delete') return null;
  return navigation.characterSourceProblem?.call({
    for (final entry in navigation.workspace.project!.dialogues)
      if (preparation.changedPaths.contains(entry.relativePath)) entry.id,
  });
}

Future<ProjectManifest> _mutateResources(
  ResourceNavigation navigation,
  String action,
  Map<String, Object?> parameters,
) async {
  final wasBusy = navigation.busy;
  navigation.busy = true;
  navigation.changed();
  try {
    return await navigation.accept(
      await navigation.port.mutate(action, parameters),
    );
  } on ResourceFailure catch (failure) {
    if (failure.partialReceipt != null) {
      navigation.pendingReceipt = failure.partialReceipt;
    }
    navigation.error = failure.message;
    rethrow;
  } finally {
    navigation.busy = wasBusy;
    navigation.changed();
  }
}
