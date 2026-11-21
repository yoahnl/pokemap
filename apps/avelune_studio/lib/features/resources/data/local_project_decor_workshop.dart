part of 'local_resource_adapter.dart';

const _decorWorkshopAction = 'element.upsert';
const _decorResourceKind = 'element';

mixin _LocalProjectDecorWorkshop
    implements ProjectDecorWorkshopPort, ResourcePort {
  LocalResourceAdapter get _decorWorkshopAdapter =>
      this as LocalResourceAdapter;

  @override
  bool get decorEditingAvailable =>
      _decorWorkshopAdapter.session.storage ==
      ProjectSessionStorage.workingCatalog;

  @override
  Future<ResourceMutationReceipt> saveElement(ProjectElementEntry element) =>
      _saveResourceElement(_decorWorkshopAdapter, element);

  @override
  Future<ProjectDecorWorkshopRead> readWorkshopDecor(
    String kind,
    String id,
  ) async {
    final adapter = _decorWorkshopAdapter;
    adapter._requireAvailable();
    if (adapter.session.storage == ProjectSessionStorage.manifest) {
      final baseline = await adapter.mapAdapter.resourceBaseline(
        adapter.session,
      );
      return (project: baseline.manifest, revision: baseline.revision);
    }
    return adapter.mapAdapter.readResourcePreviewWithRevision(
      adapter.session,
      kind,
      id,
      includeElementCategories: kind == 'tileset',
    );
  }

  @override
  Future<ProjectLibraryEdit> publishDecor(
    ProjectElementEntry decor, {
    required String expectedRevision,
  }) async {
    final adapter = _decorWorkshopAdapter;
    final receipt = await adapter._publishLibraryDefinition(
      _decorWorkshopAction,
      {'element': decor.toJson()},
      expectedRevision,
      decorId: decor.id,
    );
    return adapter._readLibraryEdit(_decorResourceKind, decor.id, receipt);
  }

  @override
  Future<ProjectLibraryEdit> reconcileDecor(ResourceMutationReceipt receipt) {
    final adapter = _decorWorkshopAdapter;
    return adapter.mapAdapter.withResourceMutation(() async {
      adapter._requireLibraryEditing();
      final decor = receipt.changedElement;
      if (receipt.actionId != _decorWorkshopAction || decor == null) {
        throw const ResourceFailure('Cette publication est indisponible.');
      }
      await _verifyWorkshopDecor(adapter, decor, receipt.revision);
      adapter._requireAvailable();
      await adapter.mapAdapter.acceptResourceMutation(adapter.session, receipt);
      return adapter._readLibraryEdit(_decorResourceKind, decor.id, receipt);
    });
  }
}

Future<void> _verifyWorkshopDecor(
  LocalResourceAdapter adapter,
  ProjectElementEntry decor,
  String revision,
) async {
  final actual = await adapter.mapAdapter.readResourcePreviewWithRevision(
    adapter.session,
    _decorResourceKind,
    decor.id,
  );
  if (actual.revision != revision ||
      actual.project.elements.singleOrNull != decor) {
    throw const ResourceFailure(
      'Le catalogue a changé. Rouvrez le projet pour relire ce décor.',
    );
  }
}
