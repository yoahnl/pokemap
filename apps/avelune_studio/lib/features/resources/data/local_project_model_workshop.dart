part of 'local_resource_adapter.dart';

mixin _LocalProjectModelWorkshop
    implements ProjectModelWorkshopPort, ProjectModelReplacementProvider {
  LocalResourceAdapter get _modelWorkshopAdapter;

  @override
  late final _LocalProjectModelReplacement modelReplacement =
      _LocalProjectModelReplacement(_modelWorkshopAdapter);

  @override
  Future<ProjectModelWorkshopRead> readWorkshopModel(String modelId) async {
    final adapter = _modelWorkshopAdapter;
    adapter._requireAvailable();
    final catalog = adapter.mapAdapter;
    final session = adapter.session;
    if (session.storage == ProjectSessionStorage.manifest) {
      final baseline = await catalog.resourceBaseline(session);
      return (
        model: (baseline.manifest.models3d as ProjectModel3dEntries).lookup(
          modelId,
        ),
        revision: baseline.revision,
      );
    }
    final selection = await catalog.readResourcePreviewWithRevision(
      session,
      'model3d',
      modelId,
    );
    return (
      model: selection.project.models3d
          .where((model) => model.id == modelId)
          .firstOrNull,
      revision: selection.revision,
    );
  }

  @override
  Future<ResourceMutationReceipt> saveModelShadow(
    String modelId, {
    required bool castsShadows,
    required String expectedRevision,
  }) => _modelWorkshopAdapter._run(
    'model3d.configure',
    (_) => {'modelId': modelId, 'castsShadowsByDefault': castsShadows},
    expectedBeforeRevision: expectedRevision,
  );

  @override
  Future<void> reconcileModelShadow(ResourceMutationReceipt receipt) =>
      _modelWorkshopAdapter.reconcileReceipt(receipt);
}
