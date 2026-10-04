import 'dart:math';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/resources/domain/resource_lifecycle_port.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import 'resource_catalog.dart';
import 'resource_image_import.dart';
import 'resource_management_bindings.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';
import 'resource_preview.dart';
import 'resource_replacement_dialog.dart';
import 'resource_removal_dialog.dart';
import 'resource_duplicate_dialog.dart';
import 'resource_lifecycle_owner_guard.dart';

Future<void> replaceResourceImage(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
  PickResourceImage picker,
) async {
  if (navigation.isDisposed ||
      navigation.managementDialogActive ||
      navigation.busy) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? preparation;
  try {
    final image = await picker();
    if (image == null || !context.mounted || navigation.isDisposed) return;
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
    if (!context.mounted || navigation.isDisposed) return;
    await showResourceReplacement(
      context,
      item: item,
      before: preview.beforeBytes,
      candidate: preview.candidateBytes,
      width: preview.width,
      height: preview.height,
      projectTileWidth: navigation.workspace.project!.settings.tileWidth,
      projectTileHeight: navigation.workspace.project!.settings.tileHeight,
      impacts: _replacementImpacts(
        preview.impact,
        navigation.workspace.project!,
      ),
      noChange: preparation.noChange,
      apply: () => _apply(navigation, preparation!),
      canApply: () => navigation.pendingReceipt == null,
    );
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    try {
      if (preparation != null) await navigation.releasePreparation(preparation);
    } finally {
      navigation.endManagementDialog();
    }
  }
}

Future<void> duplicateResourceDefinition(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) async {
  if (navigation.isDisposed ||
      navigation.managementDialogActive ||
      navigation.busy) {
    return;
  }
  navigation.beginManagementDialog();
  try {
    if (!await resolveResourceDecorOwner(
          context,
          navigation,
          item,
          duplicate: true,
        ) ||
        !context.mounted) {
      return;
    }
    final project = navigation.workspace.project!;
    final source = resourceCatalog(
      project,
    ).firstWhere((entry) => entry.identity == item.identity);
    final revision = await navigation.captureResourceRevision();
    final newId =
        'decor-copy-${DateTime.now().microsecondsSinceEpoch}-'
        '${Random.secure().nextInt(1 << 32)}';
    ResourceItem? copied;
    if (!context.mounted) return;
    await showResourceDuplicate(
      context,
      item: source,
      project: project,
      canApply: () => navigation.pendingReceipt == null,
      save: (name, category) async {
        ResourceMutationPreparation? preparation;
        try {
          preparation = await navigation.prepareOperation('element.duplicate', {
            'sourceElementId': item.id,
            'newElementId': newId,
            'name': name,
            'categoryId': category,
          }, expectedSnapshotRevision: revision);
          final updated = await navigation.applyPrepared(
            preparation,
            confirmDestructive: preparation.confirmationRequired,
          );
          copied = resourceCatalog(updated).firstWhere(
            (entry) => entry.kind == ResourceKind.decors && entry.id == newId,
          );
          navigation.library.reveal(copied!);
          navigation.library.revealPending = false;
          return null;
        } on Object catch (failure) {
          return '$failure';
        } finally {
          if (preparation != null) {
            await navigation.releasePreparation(preparation);
          }
        }
      },
    );
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
    navigation.endManagementDialog();
  }
}

Future<void> removeResourceDefinition(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) async {
  if (navigation.isDisposed ||
      navigation.managementDialogActive ||
      navigation.busy) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? preparation;
  Future<ResourceMutationPreparation>? pendingPreparation;
  var usagesRequested = false;
  try {
    if (!await resolveResourceDecorOwner(context, navigation, item) ||
        !context.mounted) {
      return;
    }
    await showResourceManagementRoute(
      context,
      (dialogContext) => ResourceRemovalDialog(
        item: item,
        preview: resourcePreview(
          item,
          navigation.workspace.project!,
          navigation.visuals,
          size: 140,
        ),
        dirtyOwners: () => navigation.lifecycleDraftOwners(
          item.tileset == null ? 'element.delete' : 'tileset.remove',
          item,
        ),
        canApply: () => navigation.pendingReceipt == null,
        prepare: (removeSource) async {
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
        apply: (plan) => _apply(navigation, plan),
        openUsages: () {
          usagesRequested = true;
          Navigator.pop(dialogContext);
        },
      ),
    );
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    if (pendingPreparation != null) {
      try {
        preparation = await pendingPreparation;
      } on Object {
        preparation = null;
      }
    }
    try {
      if (preparation != null) {
        await navigation.releasePreparation(preparation!);
      }
    } finally {
      navigation.endManagementDialog();
    }
  }
  if (usagesRequested && context.mounted) {
    await openResourceUsages(context, navigation, item);
  }
}

Future<String?> _apply(
  ResourceNavigation navigation,
  ResourceMutationPreparation preparation,
) async {
  try {
    await navigation.applyPrepared(preparation, confirmDestructive: true);
    return null;
  } on Object catch (failure) {
    return navigation.pendingReceipt == null
        ? '$failure'
        : 'Publication effectuée, mais l’interface doit être relue. '
              'Fermez ce dialogue puis utilisez « Relire le résultat ». '
              'Ne relancez pas la mutation.';
  }
}

List<String> _replacementImpacts(
  Map<String, Object?> impact,
  ProjectManifest project,
) => [
  if (impact['mutableOwners'] case final List owners)
    'Consommateurs actualisés : ${owners.map((owner) => _ownerLabel('$owner', project)).join(' · ')}',
  if (impact['after'] case final Map after)
    if (after['logicalPath'] case final String path)
      'Source après publication : $path',
  if (impact['transparencyPolicy'] is String)
    'Les collisions manuelles et ombres restent inchangées. Vérifiez les '
        'masques dérivés depuis leur préparateur.',
  if (impact['oldBlobPreserved'] == true)
    'Les anciens pixels encore référencés sont conservés.',
  if (impact['immutableVersionsPreserved'] == true)
    'Les versions immuables ne sont pas republiées.',
];

String _ownerLabel(String owner, ProjectManifest project) {
  final separator = owner.indexOf(':');
  if (separator < 0) return owner;
  final kind = owner.substring(0, separator);
  final id = owner.substring(separator + 1);
  return switch (kind) {
    'tileset' =>
      project.tilesets.where((entry) => entry.id == id).firstOrNull?.name ??
          owner,
    'element' =>
      project.elements.where((entry) => entry.id == id).firstOrNull?.name ??
          owner,
    'character' =>
      project.characters.where((entry) => entry.id == id).firstOrNull?.name ??
          owner,
    _ => owner,
  };
}
