import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class ContactDeviceActions {
  const ContactDeviceActions();

  static final descriptor = AuthoringActionDescriptor(
    id: 'contact_device.configure',
    version: 1,
    summary:
        'Configure a story-acquired device with persistent contacts and authored conversations',
    inputSchemaId: 'pokemap.authoring.contact_device.configure.input.v1',
    outputSchemaId: 'pokemap.authoring.contact_device.configure.output.v1',
    riskLevel: AuthoringRiskLevel.medium,
    resourceKinds: const ['project', 'contactDeviceConfiguration'],
    capabilityIds: const [
      'authoring.contact_device',
      ProjectContactDeviceConfig.capabilityId
    ],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable
    ],
    extensions: const {
      'projectDimensions': ['threeD'],
      'parameterNames': ['configuration'],
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['configuration'],
        'properties': {
          'configuration': {
            'oneOf': [
              {'type': 'null'},
              {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'id',
                  'label',
                  'acquiredFactId',
                  'emptyMessage',
                  'contacts'
                ],
                'properties': {
                  'id': {'type': 'string', 'minLength': 1},
                  'label': {'type': 'string', 'minLength': 1},
                  'acquiredFactId': {'type': 'string', 'minLength': 1},
                  'emptyMessage': {'type': 'string', 'minLength': 1},
                  'contacts': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'additionalProperties': false,
                      'required': [
                        'id',
                        'label',
                        'registeredFactId',
                        'sceneId',
                        'unavailableSceneId'
                      ],
                      'properties': {
                        'id': {'type': 'string', 'minLength': 1},
                        'label': {'type': 'string', 'minLength': 1},
                        'registeredFactId': {'type': 'string', 'minLength': 1},
                        'availableFactId': {'type': 'string', 'minLength': 1},
                        'sceneId': {'type': 'string', 'minLength': 1},
                        'unavailableSceneId': {
                          'type': 'string',
                          'minLength': 1
                        },
                        'characterId': {'type': 'string', 'minLength': 1},
                      }
                    }
                  },
                }
              },
            ]
          }
        },
      },
      'acquisition': 'declaredBooleanFact',
      'registration': 'distinctDeclaredBooleanFactPerContact',
      'persistence': 'canonicalNarrativeFacts',
      'network': false,
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (parameters.length != 1 || !parameters.containsKey('configuration')) {
      throw const FormatException(
          'Only the complete contact device configuration is accepted.');
    }
    final raw = parameters['configuration'];
    if (raw != null && raw is! Map) {
      throw const FormatException(
          'Contact device configuration must be an object or null.');
    }
    final config = raw == null
        ? null
        : ProjectContactDeviceConfig.fromJson(
            Map<String, dynamic>.from(raw as Map));
    final manifest = context.snapshot.manifest;
    final errors = config?.referenceErrors(
            facts: manifest.facts,
            sceneIds: manifest.scenes.map((s) => s.id).toSet(),
            characterIds: manifest.characters.map((c) => c.id).toSet()) ??
        const <String>[];
    if (errors.isNotEmpty) throw FormatException(errors.join(' | '));
    final projected = manifest.copyWith(contactDevice: config);
    ProjectValidator.validate(projected);
    return buildVisualManifestDraft(context.snapshot, projected,
        operation: descriptor.id,
        path: '/contactDevice',
        before: manifest.contactDevice?.toJson(),
        after: config?.toJson());
  }
}
