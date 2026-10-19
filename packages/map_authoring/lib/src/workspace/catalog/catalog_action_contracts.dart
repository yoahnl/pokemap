import '../../contracts/action_descriptor.dart';
import 'catalog_project_reader.dart';

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
      'placementContext': 'optional interior, exterior, both or null'
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
