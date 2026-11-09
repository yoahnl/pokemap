part of 'local_resource_adapter.dart';

Future<ResourceMutationReceipt> _prepareResourceIndexes(
  LocalResourceAdapter adapter, String expectedRevision,
) => adapter.mapAdapter.withResourceMutation(() async {
  adapter._requireAvailable();
  if (!adapter.resourceIndexPreparationAvailable) {
    throw const ResourceFailure('Ce projet n’utilise pas de catalogue de travail.');
  }
  adapter._resourceMutationActive = true;
  try {
    final before = await adapter.mapAdapter.resourceBaseline(adapter.session);
    if (before.revision != expectedRevision) {
      throw const ResourceFailure('Le projet a changé. Relisez-le avant de préparer les usages.');
    }
    final context = await adapter._requireMutationContext();
    await context.attach();
    await context.api.prepareWorkshopCatalog(context.opened.projectHandle, scope: 'resourceIndexes');
    final revision = await adapter.mapAdapter.resourceRevision(adapter.session);
    final receipt = ResourceMutationReceipt(
      before: before.manifest, manifest: before.manifest,
      beforeRevision: before.revision, revision: revision,
      changedPaths: revision == before.revision ? const [] : const [CatalogStorageStore.headStorageKey],
    );
    await adapter.mapAdapter.acceptResourceMutation(adapter.session, receipt);
    return receipt;
  } finally {
    adapter._resourceMutationActive = false;
  }
});
