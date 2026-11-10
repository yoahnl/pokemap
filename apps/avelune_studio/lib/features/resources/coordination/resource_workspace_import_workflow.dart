import 'package:map_core/map_core_domain.dart';

import '../domain/resource_image_picker.dart';
import '../domain/resource_port.dart';
import 'resource_navigation.dart';

class ResourceWorkspaceImportWorkflow {
  ResourceWorkspaceImportWorkflow({
    required this.navigation,
    required this.isActive,
  });

  final ResourceNavigation navigation;
  final bool Function() isActive;
  bool choosing = false;

  bool get active => isActive() && !navigation.isDisposed;

  Future<bool> importImage({
    required PickResourceImage picker,
    required Future<ResourceImageImport?> Function(
      PickedResourceImage,
      ProjectManifest,
    )
    confirm,
    ResourceImportIntent intent = ResourceImportIntent.source,
  }) async {
    if (!active ||
        choosing ||
        navigation.busy ||
        navigation.managementDialogActive) {
      return false;
    }
    if (navigation.pendingReceipt != null) {
      navigation.setImportError(
        'Relisez la publication précédente avant d’importer une image.',
      );
      return false;
    }
    choosing = true;
    navigation.beginManagementDialog();
    try {
      final image = await picker();
      if (!active || image == null) return false;
      final request = await confirm(image, navigation.workspace.project!);
      if (!active ||
          request == null ||
          navigation.busy ||
          navigation.pendingReceipt != null) {
        return false;
      }
      await navigation.import(request, intent: intent);
      return active &&
          navigation.error == null &&
          navigation.pendingReceipt == null;
    } on Object catch (failure) {
      if (active) {
        navigation.setImportError('$failure');
        navigation.showLibrary();
      }
      return false;
    } finally {
      choosing = false;
      navigation.endManagementDialog();
    }
  }
}
