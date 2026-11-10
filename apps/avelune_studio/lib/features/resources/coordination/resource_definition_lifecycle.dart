import 'dart:math';

import '../application/resource_catalog.dart';
import '../application/resource_lifecycle_publication.dart';
import '../application/resource_removal_controller.dart';
import '../domain/resource_mutation_preparation.dart';
import 'resource_navigation.dart';
import 'resource_replacement_workflow.dart';

Future<bool> saveResourceDecorOwnerBeforeOperation({
  required ResourceNavigation navigation,
  required ResourceItem item,
  required Future<bool> Function() confirmSave,
}) async {
  if (item.element == null || navigation.decorDraftFor(item.id) == null) {
    return true;
  }
  return await confirmSave() && await navigation.saveDecorOwner(item.id);
}

class ResourceDuplicateSession {
  ResourceDuplicateSession({
    required this.item,
    required this.canPublish,
    required this.publish,
  }) : name = '${item.name} — copie',
       categoryId = item.category;

  final ResourceItem item;
  final bool Function() canPublish;
  final Future<ResourceLifecyclePublicationResult> Function(String, String)
  publish;
  String name, categoryId;
  bool applying = false;
  bool _closed = false, _published = false;
  Future<String?>? _pending;
  Future<String?>? get pending => applying ? _pending : null;

  bool get canApply =>
      !_closed &&
      !_published &&
      !applying &&
      canPublish() &&
      name.trim().isNotEmpty &&
      categoryId.isNotEmpty;

  Future<String?> apply() {
    if (!canApply) {
      return Future.value('Choisissez un nom et une catégorie pour la copie.');
    }
    applying = true;
    return _pending = () async {
      try {
        final result = await publish(name, categoryId);
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

Future<void> runResourceDefinitionDuplicate({
  required ResourceNavigation navigation,
  required ResourceItem item,
  required bool Function() isActive,
  required Future<bool> Function() confirmOwnerSave,
  required Future<void> Function(ResourceDuplicateSession) present,
}) async {
  if (navigation.isDisposed ||
      navigation.managementDialogActive ||
      navigation.busy) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceDuplicateSession? session;
  ResourceItem? copied;
  try {
    if (!await saveResourceDecorOwnerBeforeOperation(
          navigation: navigation,
          item: item,
          confirmSave: confirmOwnerSave,
        ) ||
        !isActive()) {
      return;
    }
    final source = resourceCatalog(navigation.workspace.project!)
        .firstWhere((entry) => entry.identity == item.identity);
    final revision = await navigation.captureResourceRevision();
    final newId =
        'decor-copy-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    if (!isActive()) return;
    session = ResourceDuplicateSession(
      item: source,
      canPublish: () =>
          isActive() &&
          !navigation.isDisposed &&
          navigation.pendingReceipt == null,
      publish: (name, category) async {
        ResourceMutationPreparation? preparation;
        var committed = false;
        try {
          preparation = await navigation.prepareOperation('element.duplicate', {
            'sourceElementId': item.id,
            'newElementId': newId,
            'name': name,
            'categoryId': category,
          }, expectedSnapshotRevision: revision);
          final result = await applyResourceLifecyclePublication(
            navigation,
            preparation,
            confirmDestructive: preparation.confirmationRequired,
          );
          committed = result.publicationCommitted;
          if (result.error != null) return result;
          copied = resourceCatalog(result.project!).firstWhere(
            (entry) => entry.kind == ResourceKind.decors && entry.id == newId,
          );
          navigation.library.reveal(copied!);
          navigation.library.revealPending = false;
          return result;
        } on Object catch (failure) {
          return ResourceLifecyclePublicationResult(
            error: '$failure',
            publicationCommitted: committed,
          );
        } finally {
          if (preparation != null) {
            await navigation.releasePreparation(preparation);
          }
        }
      },
    );
    await present(session);
    await session.pending;
    if (copied != null && !navigation.isDisposed) {
      try {
        navigation.edit(copied!);
      } on Object catch (failure) {
        navigation.showLibrary(copied);
        navigation.setImportError(
          'La copie existe. Rouvrez « ${copied!.name} » pour poursuivre : $failure',
        );
      }
    }
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    session?.dispose();
    try {
      await session?.pending;
    } finally {
      navigation.endManagementDialog();
    }
  }
}

Future<void> runResourceDefinitionRemoval({
  required ResourceNavigation navigation,
  required ResourceItem item,
  required bool Function() isActive,
  required Future<bool> Function() confirmOwnerSave,
  required Future<void> Function(ResourceRemovalController) present,
  Future<void> Function()? openUsages,
}) async {
  if (navigation.isDisposed ||
      navigation.managementDialogActive ||
      navigation.busy) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? preparation;
  Future<ResourceMutationPreparation>? pendingPreparation;
  ResourceRemovalController? controller;
  try {
    if (!await saveResourceDecorOwnerBeforeOperation(
          navigation: navigation,
          item: item,
          confirmSave: confirmOwnerSave,
        ) ||
        !isActive()) {
      return;
    }
    controller = ResourceRemovalController(
      item: item,
      dirtyOwners: () => navigation.lifecycleDraftOwners(
        item.tileset == null ? 'element.delete' : 'tileset.remove',
        item,
      ),
      canPublish: () =>
          isActive() &&
          !navigation.isDisposed &&
          navigation.pendingReceipt == null,
      prepareOperation: (removeSource) async {
        final old = preparation;
        preparation = null;
        if (old != null) await navigation.releasePreparation(old);
        pendingPreparation = navigation.prepareOperation(
          item.tileset == null ? 'element.delete' : 'tileset.remove',
          item.tileset == null
              ? {'elementId': item.id}
              : {'tilesetId': item.id, 'removeSource': removeSource},
        );
        return preparation = await pendingPreparation!;
      },
      publish: (plan) => applyResourceLifecyclePublication(navigation, plan),
    );
    await present(controller);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    controller?.dispose();
    try {
      await controller?.settle();
      if (pendingPreparation != null) {
        try {
          preparation = await pendingPreparation;
        } on Object {
          preparation = null;
        }
      }
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
  if (controller?.usagesRequested == true && isActive()) {
    await openUsages?.call();
  }
}
