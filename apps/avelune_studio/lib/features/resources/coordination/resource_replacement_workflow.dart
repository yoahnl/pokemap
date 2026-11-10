import '../application/resource_usage_replacement_controller.dart';
import '../domain/resource_usage_port.dart';
import '../application/resource_lifecycle_publication.dart';
import '../application/resource_catalog.dart';
import '../domain/resource_image_picker.dart';
import '../domain/resource_lifecycle_port.dart';
import '../domain/resource_mutation_preparation.dart';
import '../domain/resource_port.dart';
import 'resource_navigation.dart';

class ResourceReplacementSession {
  ResourceReplacementSession({
    required this.preview,
    required this.canPublish,
    required this.publish,
  });

  final ResourceReplacementPreview preview;
  final bool Function() canPublish;
  final Future<ResourceLifecyclePublicationResult> Function() publish;
  bool confirmed = false, applying = false;
  bool _closed = false, _published = false;
  Future<String?>? _pending;
  Future<String?>? get pending => applying ? _pending : null;

  bool get canApply =>
      !_closed &&
      !_published &&
      !applying &&
      canPublish() &&
      (confirmed || preview.preparation.noChange);

  void confirm(bool value) {
    if (_closed || applying) return;
    confirmed = value;
  }

  Future<String?> apply() {
    if (!canApply) {
      return Future.value(
        'Le remplacement doit être confirmé avant publication.',
      );
    }
    applying = true;
    return _pending = () async {
      try {
        final result = await publish();
        if (result.error == null || result.publicationCommitted) {
          _published = true;
        }
        return result.error;
      } finally {
        applying = false;
      }
    }();
  }

  void dispose() => _closed = true;
}

Future<void> runResourceImageReplacement({
  required ResourceNavigation navigation,
  required ResourceItem item,
  required PickResourceImage picker,
  required bool Function() isActive,
  required Future<void> Function(ResourceReplacementSession session) present,
}) async {
  if (navigation.isDisposed ||
      navigation.managementDialogActive ||
      navigation.busy) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? preparation;
  ResourceReplacementSession? session;
  try {
    final image = await picker();
    if (image == null || !isActive() || navigation.isDisposed) return;
    navigation.setImportBusy(true);
    late final ResourceReplacementPreview preview;
    try {
      preview = await navigation.prepareReplacement(
        ResourceReplacementRequest(
          tilesetId: item.id,
          sourcePath: image.path,
          bytes: image.bytes,
        ),
      );
    } finally {
      if (!navigation.isDisposed) navigation.setImportBusy(false);
    }
    preparation = preview.preparation;
    if (!isActive() || navigation.isDisposed) return;
    session = ResourceReplacementSession(
      preview: preview,
      canPublish: () =>
          isActive() &&
          !navigation.isDisposed &&
          navigation.pendingReceipt == null,
      publish: () =>
          applyResourceLifecyclePublication(navigation, preparation!),
    );
    await present(session);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    session?.dispose();
    try {
      await session?.pending;
    } on Object catch (failure) {
      if (!navigation.isDisposed) navigation.setImportError('$failure');
    }
    try {
      if (preparation != null) await navigation.releasePreparation(preparation);
    } finally {
      navigation.endManagementDialog();
    }
  }
}

Future<String?> applyResourceLifecycleChange(
  ResourceNavigation navigation,
  ResourceMutationPreparation preparation,
) async =>
    (await applyResourceLifecyclePublication(navigation, preparation)).error;

Future<ResourceLifecyclePublicationResult> applyResourceLifecyclePublication(
  ResourceNavigation navigation,
  ResourceMutationPreparation preparation, {
  bool confirmDestructive = true,
}) async {
  try {
    final project = await navigation.applyPrepared(
      preparation,
      confirmDestructive: confirmDestructive,
    );
    return ResourceLifecyclePublicationResult(
      error: null,
      publicationCommitted: !preparation.noChange,
      project: project,
    );
  } on Object catch (failure) {
    final published =
        failure is ResourceFailure && failure.partialReceipt != null ||
        navigation.pendingReceipt != null;
    return ResourceLifecyclePublicationResult(
      error: published
          ? 'Publication effectuée, mais l’interface doit être relue. '
                'Fermez ce dialogue puis utilisez « Relire le résultat ». '
                'Ne relancez pas la mutation.'
          : '$failure',
      publicationCommitted: published,
    );
  }
}

Future<String?> runResourceUsageReplacement({
  required ResourceNavigation navigation,
  required ResourceUsageTarget target,
  required String name,
  required bool Function() isActive,
  required Future<void> Function(ResourceUsageReplacementController) present,
}) async {
  final project = navigation.workspace.project;
  if (project == null ||
      navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive ||
      !const {'decors', 'models3d'}.contains(target.family)) {
    return null;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? preparation;
  ResourceUsageReplacementController? controller;
  try {
    final kind = target.family == 'models3d' ? 'model3d' : 'element';
    final choices = [
      for (final item in resourceCatalog(project))
        if (item.canonicalKind == kind && item.id != target.id) item,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    controller = ResourceUsageReplacementController(
      name: name,
      spatial: target.family == 'models3d',
      choices: choices,
      canPublish: () =>
          isActive() &&
          !navigation.isDisposed &&
          navigation.pendingReceipt == null &&
          navigation.usageDraftOwners.isEmpty,
      prepareOperation: (replacementId) async {
        final previous = preparation;
        preparation = null;
        if (previous != null) await navigation.releasePreparation(previous);
        return preparation = await navigation.prepareOperation(
          'resource.usages.replace',
          {
            'family': target.family,
            'resourceId': target.id,
            'replacementId': replacementId,
          },
        );
      },
      publish: (prepared) =>
          applyResourceLifecyclePublication(navigation, prepared),
    );
    await present(controller);
    return controller.notice;
  } finally {
    controller?.dispose();
    try {
      await controller?.settle();
    } finally {
      try {
        if (preparation != null) {
          await navigation.releasePreparation(preparation!);
        }
      } finally {
        navigation.endManagementDialog();
      }
    }
  }
}
