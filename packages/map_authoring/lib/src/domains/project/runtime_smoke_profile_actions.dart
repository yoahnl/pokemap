import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class RuntimeSmokeProfileActions {
  const RuntimeSmokeProfileActions();

  static const actionId = 'validation.runtime_smoke_profile.configure';
  static final descriptor = AuthoringActionDescriptor(
    id: actionId,
    version: 1,
    summary: 'Configure or remove the expected runtime verification policy',
    inputSchemaId: 'pokemap.authoring.$actionId.input.v1',
    outputSchemaId: 'pokemap.authoring.$actionId.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['project', 'runtimeSmokeProfile'],
    capabilityIds: const ['authoring.validation.runtime_smoke_profile'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
    extensions: const {
      'parameterNames': ['profile'],
      'nullProfile': 'remove policy; runtime verification remains notRun',
      'policySource': 'project manifest; never inferred from a receipt',
      'inputSchema': {
        'type': 'object',
        'required': ['profile'],
        'additionalProperties': false,
        'properties': {
          'profile': {
            'type': ['object', 'null'],
            'additionalProperties': false,
            'required': ['id', 'version', 'requiredSuiteIds'],
            'properties': {
              'id': {'type': 'string', 'minLength': 1},
              'version': {'type': 'integer', 'minimum': 1},
              'requiredSuiteIds': {
                'type': 'array',
                'minItems': 1,
                'uniqueItems': true,
                'items': {'type': 'string', 'minLength': 1},
              },
            },
          },
        },
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (parameters.length != 1 || !parameters.containsKey('profile')) {
      throw const FormatException(
          'Expected only the required profile parameter.');
    }
    final profile = parameters['profile'] == null
        ? null
        : NarrativeRuntimeSmokeProfile.fromJson(parameters['profile']);
    final previous = context.snapshot.manifest.runtimeSmokeProfile;
    return buildVisualManifestDraft(
      context.snapshot,
      context.snapshot.manifest.copyWith(runtimeSmokeProfile: profile),
      operation: actionId,
      path: '/runtimeSmokeProfile',
      before: previous?.toJson(),
      after: profile?.toJson(),
    );
  }
}
