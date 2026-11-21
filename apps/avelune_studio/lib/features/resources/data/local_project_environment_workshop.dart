part of 'local_resource_adapter.dart';

const _environmentWorkshopAction = 'environment.preset.upsert';
const _environmentResourceKind = 'environmentPreset';

mixin _LocalProjectEnvironmentWorkshop
    implements ProjectEnvironmentWorkshopPort {
  LocalResourceAdapter get _environmentWorkshopAdapter;

  @override
  bool get environmentEditingAvailable =>
      _environmentWorkshopAdapter.session.storage ==
      ProjectSessionStorage.workingCatalog;

  @override
  Future<ProjectLibraryEdit> publishEnvironment(
    EnvironmentPreset preset, {
    required String expectedRevision,
  }) async {
    final adapter = _environmentWorkshopAdapter;
    final receipt = await adapter._publishLibraryDefinition(
      _environmentWorkshopAction,
      {'preset': encodeEnvironmentPreset(preset)},
      expectedRevision,
      environmentId: preset.id,
    );
    return adapter._readLibraryEdit(
      _environmentResourceKind,
      preset.id,
      receipt,
    );
  }

  @override
  Future<ProjectLibraryEdit> reconcileEnvironment(
    EnvironmentPreset preset,
    ResourceMutationReceipt receipt,
  ) {
    final adapter = _environmentWorkshopAdapter;
    return adapter.mapAdapter.withResourceMutation(() async {
      adapter._requireLibraryEditing();
      if (receipt.actionId != _environmentWorkshopAction ||
          findProjectEnvironmentPresetById(receipt.manifest, preset.id) !=
              preset) {
        throw const ResourceFailure('Cette publication est indisponible.');
      }
      await _verifyWorkshopEnvironment(adapter, preset, receipt.revision);
      adapter._requireAvailable();
      await adapter.mapAdapter.acceptResourceMutation(
        adapter.session,
        receipt,
        changedEnvironment: preset,
      );
      return adapter._readLibraryEdit(
        _environmentResourceKind,
        preset.id,
        receipt,
      );
    });
  }
}

Future<void> _verifyWorkshopEnvironment(
  LocalResourceAdapter adapter,
  EnvironmentPreset preset,
  String revision,
) async {
  final actual = await adapter.mapAdapter.readResourcePreviewWithRevision(
    adapter.session,
    _environmentResourceKind,
    preset.id,
  );
  if (actual.revision != revision ||
      actual.project.environmentPresets.singleOrNull != preset) {
    throw const ResourceFailure(
      'Le catalogue a changé. Rouvrez le projet pour relire cet environnement.',
    );
  }
}
