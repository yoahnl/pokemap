import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/resource_border_lifecycle_controller.dart';
import '../../../features/resources/coordination/resource_border_lifecycle.dart';
import '../../../features/resources/coordination/resource_navigation.dart';
import 'border_creation_dialog.dart';
import 'resource_border_confirmation_dialog.dart';
import 'resource_management_dialog.dart';
import 'resource_usage_dialog.dart';

Future<void> openBorderPreparation(
  BuildContext context,
  ResourceNavigation navigation, [
  BorderBlueprintRecord? record,
]) => runBorderPreparation(
  navigation: navigation,
  present: () => showResourceManagementRoute(
    context,
    (_) => BorderCreationDialog(
      navigation: navigation,
      project: navigation.workspace.project!,
      visuals: navigation.visuals,
      initialRecord: record,
    ),
  ),
);

Future<void> manageBorderResource(
  BuildContext context,
  ResourceNavigation navigation,
  BorderBlueprintRecord record,
  BorderResourceAction action,
) => runBorderResourceManagement(
  navigation: navigation,
  record: record,
  action: action,
  isActive: () => context.mounted,
  presentUsages: (target, name, dirtyOwners) => showResourceManagementRoute(
    context,
    (_) => ResourceUsageDialog(
      target: target,
      name: name,
      port: navigation.usages,
      changes: navigation,
      dirtyOwners: dirtyOwners,
      onOpen: navigation.openUsageOwner,
      canOpen: navigation.canOpenUsageOwner,
    ),
  ),
  present: (controller) {
    final title = switch (action) {
      BorderResourceAction.deleteDraft => 'Retirer la préparation',
      BorderResourceAction.deprecate => 'Déprécier la bordure',
      BorderResourceAction.reactivate => 'Réactiver la bordure',
      BorderResourceAction.usages => 'Usages',
    };
    return showResourceManagementRoute(
      context,
      (_) => ResourceBorderConfirmationDialog(
        controller: controller,
        title: title,
        name: record.draft.definition.name,
        description: action == BorderResourceAction.deleteDraft
            ? 'Cette préparation jamais publiée sera retirée. Les décors sources et leurs images restent conservés.'
            : action == BorderResourceAction.deprecate
            ? 'La bordure sera masquée pour les nouveaux traits. Ses traits déjà placés, ses versions publiées, ses sources et son brouillon restent conservés. Le brouillon reste modifiable.'
            : 'La même bordure redevient disponible pour les nouveaux traits, sans modifier les versions déjà placées.',
      ),
    );
  },
);
