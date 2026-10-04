import '../../../features/resources/domain/resource_port.dart';
import 'resource_navigation.dart';

extension ResourceBorderManagement on ResourceNavigation {
  List<String> borderManagementOwners(
    String action,
    Map<String, Object?> parameters,
  ) {
    final id = parameters['blueprintId'];
    if (id is! String) return const [];
    final name = workspace.project?.borderCatalog.records
        .where((record) => record.id == id)
        .firstOrNull
        ?.draft
        .definition
        .name;
    final drawing = borderDrawingOwner?.call(id);
    return [
      if (borderEditorOwners[id]?.call() ?? false)
        'Bordure ${name ?? id} · préparation en cours dans Ressources',
      ?drawing,
    ];
  }

  void reconcileBorderManagement(ResourceMutationReceipt receipt) {
    if (receipt.actionId == 'border.blueprint.delete' ||
        receipt.actionId == 'border.blueprint.set_deprecated') {
      changed();
    }
  }
}
