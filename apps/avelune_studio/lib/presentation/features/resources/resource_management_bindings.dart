import 'package:flutter/material.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';
import 'resource_container_dialog.dart';
import 'resource_container_manager.dart';
import 'resource_containers.dart';
import 'resource_information_dialog.dart';
import 'resource_navigation.dart';
import 'resource_usage_dialog.dart';

Future<void> openResourceInformation(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) async {
  navigation.beginManagementDialog();
  try {
    final revision = await navigation.captureResourceRevision();
    final fingerprint = await navigation.resourceFingerprint(item.id, revision);
    if (!context.mounted) return;
    await showResourceInformation(
      context,
      item: item,
      project: navigation.workspace.project!,
      fingerprint: fingerprint,
      imageDimensions: navigation.visuals is ResourceImageDimensionsVisuals
          ? (navigation.visuals as ResourceImageDimensionsVisuals)
                .cachedImageDimensions(item.id)
          : null,
      save: (name, folder) => _save(
        navigation,
        revision,
        'tileset.metadata.update',
        {'tilesetId': item.id, 'name': name, 'folderId': folder},
        reveal: item,
      ),
    );
  } on Object catch (failure) {
    navigation.setImportError('$failure');
  } finally {
    navigation.endManagementDialog();
  }
}

Future<void> moveResource(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) async {
  navigation.beginManagementDialog();
  try {
    final revision = await navigation.captureResourceRevision();
    if (!context.mounted) return;
    await showResourceMove(
      context,
      item: item,
      containers: resourceContainers(navigation.workspace.project!, item.kind),
      save: (action, parameters) =>
          _save(navigation, revision, action, parameters, reveal: item),
    );
  } on Object catch (failure) {
    navigation.setImportError('$failure');
  } finally {
    navigation.endManagementDialog();
  }
}

Future<void> manageResourceContainers(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceKind family,
) async {
  navigation.beginManagementDialog();
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ResourceContainerManager(
        family: family,
        project: () => navigation.workspace.project!,
        onSelect: (id) {
          navigation.library.kind = family;
          navigation.library.category = id;
          navigation.showLibrary();
        },
        onEdit: (initial) async {
          final revision = await navigation.captureResourceRevision();
          if (!dialogContext.mounted) return;
          await showResourceContainerEditor(
            dialogContext,
            family: family,
            containers: resourceContainers(
              navigation.workspace.project!,
              family,
            ),
            initial: initial,
            save: (action, parameters) =>
                _save(navigation, revision, action, parameters),
          );
        },
        onDelete: (entry) async {
          final revision = await navigation.captureResourceRevision();
          final error = await _save(
            navigation,
            revision,
            containerAction(family, 'delete'),
            {
              family == ResourceKind.images ? 'folderId' : 'categoryId':
                  entry.id,
            },
            destructive: true,
          );
          if (error == null &&
              navigation.library.kind == family &&
              navigation.library.category == entry.id) {
            navigation.library.category = '';
            navigation.showLibrary();
          }
          return error;
        },
      ),
    );
  } finally {
    navigation.endManagementDialog();
  }
}

Future<String?> _save(
  ResourceNavigation navigation,
  String revision,
  String action,
  Map<String, Object?> parameters, {
  ResourceItem? reveal,
  bool destructive = false,
}) async {
  try {
    final preparation = await navigation.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    final project = await navigation.applyPrepared(
      preparation,
      confirmDestructive: destructive,
    );
    if (reveal != null) {
      final current = resourceCatalog(
        project,
      ).where((entry) => entry.identity == reveal.identity).firstOrNull;
      if (current != null) {
        navigation.library.reveal(current);
        navigation.library.revealPending = false;
        navigation.showLibrary();
      }
    }
    return null;
  } on Object catch (failure) {
    return '$failure';
  }
}

Future<void> openResourceUsages(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => ResourceUsageDialog(
    item: item,
    port: navigation.usages,
    changes: navigation,
    dirtyOwners: () => navigation.usageDraftOwners,
    onOpen: navigation.openUsageOwner,
    canOpen: navigation.canOpenUsageOwner,
  ),
);
