import 'package:avelune_studio/features/resources/coordination/resource_replacement_workflow.dart';

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../features/resources/domain/resource_mutation_preparation.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_management_bindings.dart';
import 'resource_management_dialog.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import 'resource_preview.dart';
import 'resource_removal_dialog.dart';
import 'resource_duplicate_dialog.dart';
import 'resource_lifecycle_owner_guard.dart';

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
    final source = resourceCatalog(project)
        .firstWhere((entry) => entry.identity == item.identity);
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
        apply: (plan) => applyResourceLifecycleChange(navigation, plan),
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
