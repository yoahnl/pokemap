import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class ProjectIdentityActions {
  const ProjectIdentityActions();

  static const actionId = 'project.rename';

  static final descriptor = AuthoringActionDescriptor(
    id: actionId,
    version: 1,
    summary: 'Rename the project while preserving its content and identifiers',
    inputSchemaId: 'pokemap.authoring.project.rename.input.v1',
    outputSchemaId: 'pokemap.authoring.project.rename.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['project'],
    capabilityIds: const ['authoring.project_identity'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {
      'parameterNames': ['name'],
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['name'],
        'properties': {
          'name': {'type': 'string', 'minLength': 1},
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow(const {'name'});
    final value = context.request.parameters['name'];
    if (value is! String ||
        value.trim().isEmpty ||
        RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(value)) {
      throw const FormatException(
          'Project name must be non-blank text without control characters.');
    }
    final manifest = context.snapshot.manifest;
    final name = value.trim();
    return buildVisualManifestDraft(
      context.snapshot,
      manifest.copyWith(name: name),
      operation: actionId,
      path: '/name',
      before: manifest.name,
      after: name,
    );
  }
}
