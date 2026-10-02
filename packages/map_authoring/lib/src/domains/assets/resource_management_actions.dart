import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'resource_information_actions.dart';
import 'tileset_actions.dart';
import 'visual_organization_actions.dart';

final class ResourceManagementActions {
  const ResourceManagementActions();

  static final Set<String> actionIds = Set.unmodifiable([
    for (final descriptor in ResourceInformationActions.descriptors)
      descriptor.id,
    'tileset_folder.upsert',
    'tileset_folder.delete',
    'element_category.upsert',
    'element_category.delete',
  ]);

  AuthoringMutationDraft analyze(AuthoringPlanningContext context) {
    final action = context.request.actionId;
    if (!actionIds.contains(action)) {
      throw VisualLibraryException('visual.action_unsupported',
          'This operation is outside resource metadata and organization.');
    }
    if (ResourceInformationActions.descriptors
        .any((entry) => entry.id == action)) {
      return const ResourceInformationActions().build(context);
    }
    return const VisualOrganizationActions().build(context);
  }
}
