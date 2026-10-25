import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/resource_information_document.dart';
import '../assets/tileset_actions.dart';

final class ActorContactShadowActions {
  const ActorContactShadowActions();

  static const actionId = 'project.actor_contact_shadows.configure';

  static final descriptor = AuthoringActionDescriptor(
    id: actionId,
    version: 1,
    summary: 'Configure the inherited contact shadow default for 3D characters',
    inputSchemaId: 'pokemap.authoring.$actionId.input.v1',
    outputSchemaId: 'pokemap.authoring.$actionId.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['project', 'characterStudioCharacter'],
    capabilityIds: const ['authoring.actor_contact_shadows'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {
      'parameterNames': ['enabled'],
      'field': 'settings.actorContactShadowsByDefault',
      'default': false,
      'scope': 'threeD',
      'projectedCharacterShadows': false,
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['enabled'],
        'properties': {
          'enabled': {'type': 'boolean'}
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow(const {'enabled'});
    final enabled = context.request.parameters['enabled'];
    if (enabled is! bool) {
      throw const FormatException('enabled must be a boolean.');
    }
    final manifest = context.snapshot.manifest;
    final next = manifest.copyWith(
        settings: manifest.settings.copyWith(
      actorContactShadowsByDefault: enabled,
    ));
    return buildVisualManifestDraft(
      context.snapshot,
      next,
      operation: actionId,
      encodedManifest:
          encodeResourceInformationDocument(context.snapshot, next),
      path: '/settings/actorContactShadowsByDefault',
      before: manifest.settings.actorContactShadowsByDefault,
      after: enabled,
    );
  }
}
