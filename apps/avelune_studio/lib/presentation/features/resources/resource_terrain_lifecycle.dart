import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/coordination/resource_terrain_lifecycle.dart';
export '../../../features/resources/coordination/resource_terrain_lifecycle.dart'
    show terrainPreparationStatus;

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_lifecycle_bindings.dart';
import 'resource_management_bindings.dart';
import 'resource_management_dialog.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_management_copy.dart';

import 'resource_terrain_deletion_dialog.dart';

import 'resource_terrain_management_dialog.dart';
import 'resource_terrain_owner_guard.dart';

void manageTerrainItem(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
  TerrainResourceAction action,
) => manageTerrainResource(
  context,
  navigation,
  action,
  name: item.name,
  presetId: item.id,
);

Future<void> manageTerrainResource(
  BuildContext context,
  ResourceNavigation navigation,
  TerrainResourceAction action, {
  required String name,
  String? presetId,
  String? draftId,
}) => runTerrainResourceManagement(
  navigation: navigation,
  action: action,
  name: name,
  presetId: presetId,
  draftId: draftId,
  isActive: () => context.mounted,
  confirmOwnerSave: (owners) => resolveTerrainManagementOwner(context, owners),
  present: (controller) => showResourceManagementRoute(
    context,
    (_) => controller.removing
        ? ResourceTerrainDeletionDialog(
            name: name,
            draft: draftId != null,
            controller: controller,
          )
        : ResourceTerrainManagementDialog(
            title: terrainManagementTitle(duplicate: controller.duplicate),
            controller: controller,
            description: terrainManagementDescription(
              duplicate: controller.duplicate,
              draft: draftId != null,
              name: name,
            ),
          ),
  ),
);

void duplicateResourceOrTerrain(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) {
  if (item.terrain != null) {
    manageTerrainItem(
      context,
      navigation,
      item,
      TerrainResourceAction.duplicate,
    );
  } else {
    duplicateResourceDefinition(context, navigation, item);
  }
}

void removeResourceOrTerrain(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) {
  if (item.terrain != null) {
    manageTerrainItem(
      context,
      navigation,
      item,
      TerrainResourceAction.deleteDraft,
    );
  } else {
    removeResourceDefinition(context, navigation, item);
  }
}

void manageTerrainPreparation(
  BuildContext context,
  ResourceNavigation navigation,
  ProjectSmartTileAuthoringDraft draft,
  TerrainResourceAction action,
) {
  runTerrainPreparationAction(
    navigation: navigation,
    draft: draft,
    action: action,
    openUsages: (publication) =>
        openResourceUsages(context, navigation, publication),
    manage: ({required name, required draftId}) => manageTerrainResource(
      context,
      navigation,
      action,
      name: name,
      draftId: draftId,
    ),
  );
}
