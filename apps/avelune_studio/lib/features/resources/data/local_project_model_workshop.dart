part of 'local_resource_adapter.dart';

mixin _LocalProjectModelWorkshop
    implements
        ProjectModelWorkshopPort,
        ProjectModelReplacementProvider,
        ModelResourcePort {
  LocalResourceAdapter get _modelWorkshopAdapter;

  @override
  late final _LocalProjectModelReplacement modelReplacement =
      _LocalProjectModelReplacement(_modelWorkshopAdapter);

  @override
  Future<ResourceMutationReceipt> importModel({
    required String sourcePath,
    required String name,
  }) => _modelWorkshopAdapter._run(
    'model3d.import',
    (_) => {
      'modelId': _modelWorkshopAdapter._identity('model'),
      'name': name.trim(),
    },
    sourcePath: sourcePath,
    sourceMediaType: 'model/gltf-binary',
  );

  @override
  Future<ResourceMutationReceipt> replaceModelSource({
    required String modelId,
    required String sourcePath,
  }) => _modelWorkshopAdapter._run(
    'model3d.source.replace',
    (_) => {'modelId': modelId},
    sourcePath: sourcePath,
    sourceMediaType: 'model/gltf-binary',
  );

  @override
  Future<ResourceMutationReceipt> deleteModel(String modelId) =>
      _modelWorkshopAdapter._run(
        'model3d.delete',
        (_) => {'modelId': modelId},
        confirmDestructive: true,
      );

  @override
  Future<Uint8List> readModel(String modelId) {
    final adapter = _modelWorkshopAdapter;
    final session = adapter.session;
    if (session.storage == ProjectSessionStorage.workingCatalog) {
      return _readCatalogModelSource(adapter, modelId);
    }
    return _readResourceSnapshot(adapter, (snapshot, _) async {
      final model = snapshot.manifest.models3d
          .where((entry) => entry.id == modelId)
          .firstOrNull;
      if (model == null) throw const ResourceFailure('Modèle introuvable.');
      final bytes = await const LocalProjectFileReader().readBytes(
        projectRoot: session.directoryPath,
        relativePath: model.relativePath,
      );
      return Uint8List.fromList(bytes);
    });
  }

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
