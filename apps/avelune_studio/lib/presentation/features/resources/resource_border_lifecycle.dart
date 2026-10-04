import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../../features/resources/domain/resource_usage_port.dart';
import 'border_creation_dialog.dart';
import 'resource_border_confirmation_dialog.dart';
import 'resource_border_management.dart';
import 'resource_border_draft_bar.dart';
import 'resource_management_dialog.dart';
import 'resource_navigation.dart';
import 'resource_usage_dialog.dart';

Future<void> openBorderPreparation(
  BuildContext context,
  ResourceNavigation navigation, [
  BorderBlueprintRecord? record,
]) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive) {
    return;
  }
  navigation.beginManagementDialog();
  try {
    await showResourceManagementRoute(
      context,
      (_) => BorderCreationDialog(
        navigation: navigation,
        project: navigation.workspace.project!,
        visuals: navigation.visuals,
        initialRecord: record,
      ),
    );
  } finally {
    navigation.endManagementDialog();
  }
}

Future<void> manageBorderResource(
  BuildContext context,
  ResourceNavigation navigation,
  BorderBlueprintRecord record,
  BorderResourceAction action,
) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive) {
    return;
  }
  navigation.beginManagementDialog();
  Future<ResourceMutationPreparation>? pending;
  ResourceMutationPreparation? retained;
  try {
    if (action == BorderResourceAction.usages) {
      await showResourceManagementRoute(
        context,
        (_) => ResourceUsageDialog(
          target: ResourceUsageTarget(family: 'borders', id: record.id),
          name: record.draft.definition.name,
          port: navigation.usages,
          changes: navigation,
          dirtyOwners: () => {
            ...navigation.usageDraftOwners,
            ...navigation.borderManagementOwners('border.blueprint.delete', {
              'blueprintId': record.id,
            }),
          }.toList(),
          onOpen: navigation.openUsageOwner,
          canOpen: navigation.canOpenUsageOwner,
        ),
      );
      return;
    }
    final revision = await navigation.captureResourceRevision();
    if (!context.mounted || navigation.isDisposed) return;
    final title = switch (action) {
      BorderResourceAction.deleteDraft => 'Retirer la préparation',
      BorderResourceAction.deprecate => 'Déprécier la bordure',
      BorderResourceAction.reactivate => 'Réactiver la bordure',
      BorderResourceAction.usages => 'Usages',
    };
    await showResourceManagementRoute(
      context,
      (_) => ResourceBorderConfirmationDialog(
        title: title,
        name: record.draft.definition.name,
        description: action == BorderResourceAction.deleteDraft
            ? 'Cette préparation jamais publiée sera retirée. Les décors sources et leurs images restent conservés.'
            : action == BorderResourceAction.deprecate
            ? 'La bordure sera masquée pour les nouveaux traits. Ses traits déjà placés, ses versions publiées, ses sources et son brouillon restent conservés. Le brouillon reste modifiable.'
            : 'La même bordure redevient disponible pour les nouveaux traits, sans modifier les versions déjà placées.',
        canApply: () =>
            !navigation.isDisposed && navigation.pendingReceipt == null,
        prepare: () async {
          if (retained != null) await navigation.releasePreparation(retained!);
          retained = null;
          pending = navigation.prepareOperation(
            action == BorderResourceAction.deleteDraft
                ? 'border.blueprint.delete'
                : 'border.blueprint.set_deprecated',
            {
              'blueprintId': record.id,
              if (action != BorderResourceAction.deleteDraft)
                'isDeprecated': action == BorderResourceAction.deprecate,
            },
            expectedSnapshotRevision: revision,
          );
          return retained = await pending!;
        },
        apply: (preparation) async {
          try {
            await navigation.applyPrepared(
              preparation!,
              confirmDestructive: true,
            );
            return null;
          } on Object catch (failure) {
            return navigation.pendingReceipt != null
                ? 'L’opération est publiée. Fermez puis relisez le résultat ; ne rejouez pas la modification.'
                : '$failure';
          }
        },
      ),
    );
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    if (pending != null) {
      try {
        retained = await pending;
      } on Object {
        retained = null;
      }
    }
    try {
      if (retained != null) await navigation.releasePreparation(retained!);
    } finally {
      navigation.endManagementDialog();
    }
  }
}
