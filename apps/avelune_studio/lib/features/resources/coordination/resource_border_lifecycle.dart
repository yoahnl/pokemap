import 'package:map_core/map_core_domain.dart';

import '../application/resource_border_lifecycle_controller.dart';
import '../domain/resource_mutation_preparation.dart';
import '../domain/resource_usage_port.dart';
import 'resource_border_management.dart';
import 'resource_navigation.dart';
import 'resource_replacement_workflow.dart';

Future<void> runBorderPreparation({
  required ResourceNavigation navigation,
  required Future<void> Function() present,
}) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive) {
    return;
  }
  navigation.beginManagementDialog();
  try {
    await present();
  } finally {
    navigation.endManagementDialog();
  }
}

Future<void> runBorderResourceManagement({
  required ResourceNavigation navigation,
  required BorderBlueprintRecord record,
  required BorderResourceAction action,
  required bool Function() isActive,
  required Future<void> Function(ResourceBorderLifecycleController) present,
  required Future<void> Function(
    ResourceUsageTarget,
    String,
    List<String> Function(),
  )
  presentUsages,
}) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.managementDialogActive) {
    return;
  }
  navigation.beginManagementDialog();
  ResourceMutationPreparation? retained;
  ResourceBorderLifecycleController? controller;
  try {
    if (action == BorderResourceAction.usages) {
      await presentUsages(
        ResourceUsageTarget(family: 'borders', id: record.id),
        record.draft.definition.name,
        () => {
          ...navigation.usageDraftOwners,
          ...navigation.borderManagementOwners('border.blueprint.delete', {
            'blueprintId': record.id,
          }),
        }.toList(),
      );
      return;
    }
    final revision = await navigation.captureResourceRevision();
    if (!isActive() || navigation.isDisposed) return;
    controller = ResourceBorderLifecycleController(
      canPublish: () =>
          isActive() &&
          !navigation.isDisposed &&
          navigation.pendingReceipt == null,
      prepareOperation: () async {
        final previous = retained;
        retained = null;
        if (previous != null) await navigation.releasePreparation(previous);
        return retained = await navigation.prepareOperation(
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
      },
      publish: (preparation) =>
          applyResourceLifecyclePublication(navigation, preparation),
    );
    await present(controller);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    controller?.dispose();
    try {
      await controller?.settle();
    } finally {
      try {
        if (retained != null) await navigation.releasePreparation(retained!);
      } finally {
        navigation.endManagementDialog();
      }
    }
  }
}
