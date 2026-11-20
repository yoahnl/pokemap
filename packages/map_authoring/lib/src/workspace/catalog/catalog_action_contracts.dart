import '../../contracts/action_descriptor.dart';
import 'catalog_project_reader.dart';

const catalogLibraryCopyKinds = {
  'tileset',
  'element',
  'character',
  'environmentPreset',
  'smartTilePreset',
};

final catalogDefinitionDuplicateDescriptor = _libraryDefinitionAction(
  'duplicate',
  'Copy one library definition and its classification using the existing sources.',
  catalogLibraryCopyKinds,
  AuthoringRiskLevel.medium,
);

final catalogDefinitionDeleteDescriptor = _libraryDefinitionAction(
  'delete',
  'Remove one unused library definition and its classification, retaining its source files.',
  {
    ...catalogLibraryCopyKinds,
    'model3d',
    'borderBlueprint',
  },
  AuthoringRiskLevel.high,
);

AuthoringActionDescriptor _libraryDefinitionAction(
  String action,
  String summary,
  Set<String> kinds,
  AuthoringRiskLevel risk,
) =>
    AuthoringActionDescriptor(
        id: 'catalog.definition.$action',
        version: 1,
        summary: summary,
        inputSchemaId: 'catalog.definition.$action.input.v1',
        outputSchemaId: 'authoring.receipt.v1',
        riskLevel: risk,
        resourceKinds: [
          ...kinds,
          'resourceLibraryEntry'
        ],
        capabilityIds: const [
          'authoring.visual_library'
        ],
        requiredPermissions: const [
          AuthoringPermission.projectRead,
          AuthoringPermission.projectWrite
        ],
        guarantees: const [
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ],
        extensions: {
          'storageFormat': 'avelune.working-catalog',
          if (action == 'delete') 'preparationScope': 'resourceIndexes',
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'resourceKind',
              'id',
              if (action == 'duplicate') ...['targetId', 'name']
            ],
            'properties': {
              'resourceKind': {'type': 'string', 'enum': kinds.toList()},
              'id': {'type': 'string', 'minLength': 1},
              if (action == 'duplicate') ...{
                'targetId': {
                  'type': 'string',
                  'pattern': r'^[a-zA-Z0-9_-]{1,128}$'
                },
                'name': {'type': 'string', 'minLength': 1, 'maxLength': 256},
              },
            },
          },
        });

final catalogDefinitionUpdateDescriptor = AuthoringActionDescriptor(
  id: 'catalog.definition.update',
  version: 1,
  summary: 'Update metadata of one existing typed catalog definition.',
  inputSchemaId: 'catalog.definition.update.input.v1',
  outputSchemaId: 'authoring.receipt.v1',
  riskLevel: AuthoringRiskLevel.low,
  resourceKinds: catalogResourceKinds.keys,
  requiredPermissions: const [
    AuthoringPermission.projectRead,
    AuthoringPermission.projectWrite
  ],
  guarantees: const [
    AuthoringGuarantee.dryRun,
    AuthoringGuarantee.idempotent,
    AuthoringGuarantee.revisionChecked,
    AuthoringGuarantee.undoable
  ],
  extensions: {
    'parameters': {
      'resourceKind': 'existing query resource kind',
      'id': 'existing identity',
      'name': 'optional string',
      'description': 'optional string or null',
      'tags': 'optional string array',
      'placementContext': 'optional interior, exterior, both or null',
      'category':
          'optional vegetation, ground, path, water, relief, building, furniture, object or null'
    },
    'storageFormat': 'avelune.working-catalog',
    'metadataOnly': true
  },
);

final projectCatalogPartitionDescriptor = AuthoringActionDescriptor(
  id: 'project.catalog.partition',
  version: 1,
  summary:
      'Partition an existing project catalog with one recoverable transaction; reopen the project afterward.',
  inputSchemaId: 'project.catalog.partition.input.v1',
  outputSchemaId: 'authoring.receipt.v1',
  riskLevel: AuthoringRiskLevel.medium,
  resourceKinds: const ['project'],
  requiredPermissions: const [
    AuthoringPermission.projectRead,
    AuthoringPermission.projectWrite
  ],
  guarantees: const [
    AuthoringGuarantee.dryRun,
    AuthoringGuarantee.idempotent,
    AuthoringGuarantee.revisionChecked
  ],
  extensions: const {
    'parameters': {},
    'undoable': false,
    'requiresReopen': true,
    'targetFormat': 'avelune.working-catalog.v1'
  },
);
