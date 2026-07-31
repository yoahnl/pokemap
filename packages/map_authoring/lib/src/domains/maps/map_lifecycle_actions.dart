import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_adapter.dart';

/// Canonical lifecycle action family registered by the map mutation API.
final class MapLifecycleActions {
  const MapLifecycleActions({
    MapLifecycleAdapter adapter = const MapLifecycleAdapter(),
  }) : _adapter = adapter;

  final MapLifecycleAdapter _adapter;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor(
        'map.create', 'Create a complete map', AuthoringRiskLevel.medium),
    _descriptor(
      'map.delete_apply',
      'Delete an unreferenced map',
      AuthoringRiskLevel.high,
    ),
    _descriptor(
        'map.duplicate', 'Duplicate a complete map', AuthoringRiskLevel.low),
    _descriptor(
        'map.rename', 'Rename an unreferenced map', AuthoringRiskLevel.medium),
    _descriptor('map.resize_apply', 'Resize a map without data loss',
        AuthoringRiskLevel.medium),
    _descriptor(
        'map.save', 'Save a complete validated map', AuthoringRiskLevel.medium),
  ]);

  AuthoringActionDescriptor descriptor(String actionId) {
    for (final descriptor in descriptors) {
      if (descriptor.id == actionId) return descriptor;
    }
    throw MapAuthoringException(
      code: 'map.action_unsupported',
      message: 'The requested map lifecycle action is unsupported.',
      details: {'actionId': actionId},
    );
  }

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionVersion != 1) {
      throw MapAuthoringException(
        code: 'map.action_version_unsupported',
        message: 'The requested map lifecycle action version is unsupported.',
        details: {'actionVersion': context.request.actionVersion},
      );
    }
    return switch (context.request.actionId) {
      'map.create' => _adapter.create(context),
      'map.delete_apply' => _adapter.delete(context),
      'map.duplicate' => _adapter.duplicate(context),
      'map.rename' => _adapter.rename(context),
      'map.resize_apply' => _adapter.resize(context),
      'map.save' => _adapter.save(context),
      _ => throw MapAuthoringException(
          code: 'map.action_unsupported',
          message: 'The requested map lifecycle action is unsupported.',
          details: {'actionId': context.request.actionId},
        ),
    };
  }
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary,
  AuthoringRiskLevel risk,
) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'schema.$id.input.v1',
    outputSchemaId: 'schema.map.mutation.output.v1',
    riskLevel: risk,
    resourceKinds: const ['map', 'project'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {'multiFileGuarantee': 'recoverable'},
  );
}
