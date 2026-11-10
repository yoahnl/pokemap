import 'package:flutter/material.dart';

import '../../../features/resources/application/resource_catalog.dart';
import '../../../features/resources/coordination/resource_definition_lifecycle.dart';
import '../../../features/resources/coordination/resource_navigation.dart';
import 'resource_duplicate_dialog.dart';
import 'resource_lifecycle_owner_guard.dart';
import 'resource_management_bindings.dart';
import 'resource_management_dialog.dart';
import 'resource_preview.dart';
import 'resource_removal_dialog.dart';

Future<void> duplicateResourceDefinition(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) => runResourceDefinitionDuplicate(
  navigation: navigation,
  item: item,
  isActive: () => context.mounted,
  confirmOwnerSave: () =>
      confirmResourceDecorOwnerSave(context, item, duplicate: true),
  present: (session) => showResourceDuplicate(
    context,
    session: session,
    project: navigation.workspace.project!,
  ),
);

Future<void> removeResourceDefinition(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) => runResourceDefinitionRemoval(
  navigation: navigation,
  item: item,
  isActive: () => context.mounted,
  confirmOwnerSave: () => confirmResourceDecorOwnerSave(context, item),
  present: (controller) => showResourceManagementRoute(
    context,
    (dialogContext) => ResourceRemovalDialog(
      controller: controller,
      preview: resourcePreview(
        item,
        navigation.workspace.project!,
        navigation.visuals,
        size: 140,
      ),
      openUsages: () {
        controller.requestUsages();
        Navigator.pop(dialogContext);
      },
    ),
  ),
  openUsages: () => openResourceUsages(context, navigation, item),
);
