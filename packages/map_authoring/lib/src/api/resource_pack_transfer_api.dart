import '../contracts/query_request.dart';
import '../contracts/capability_descriptor.dart';
import '../contracts/schema_descriptor.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/workspace_handle_store.dart';

const resourcePackTemporaryKinds = {
  'resourcePackJob',
  'resourcePackInspection',
  'resourcePackEntry',
  'resourcePackSelection',
  'resourcePackPreview',
};

abstract interface class ResourcePackTransferApiPort {
  Future<Map<String, Object?>> transfer(
    ProjectHandle projectHandle, {
    required String verb,
    Map<String, Object?> input = const {},
  });
  Future<Map<String, Object?>> queryTransfer(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  );
  Future<void> closeTransferWorkspace(WorkspaceHandle workspaceHandle);
  Future<void> requireSynchronousOperationAllowed(
    ProjectHandle projectHandle, {
    required String operation,
    String? planId,
    String? operationId,
    String? entryId,
  });
}

final resourcePackTransferContract = <String, Object?>{
  'schemaVersion': 2,
  'protocol': 'pokemap.authoring.resource_pack.v2',
  'capabilityId': 'authoring.resource_packs',
  'actionIds': ['resource_pack.import'],
  'resourceKinds': [
    'resourcePackJob',
    'resourcePackInspection',
    'resourcePackEntry',
    'resourcePackSelection',
    'resourcePackPreview',
  ],
  'verbs': [
    'stage',
    'stage_license',
    'inspect',
    'diagnose',
    'entries',
    'selection.create',
    'selection.patch',
    'selection.select_filtered',
    'prepare',
    'preview',
    'start_apply',
    'start_history',
    'start_recovery',
    'recovery_status',
    'export',
    'get',
    'events',
    'read_payload',
    'cancel',
    'release',
  ],
  'inputSchema': resourcePackTransferInputSchema,
  'schemaDescriptors': [resourcePackTransferSchema.toJson()],
  'capability': resourcePackTransferCapability.toJson(),
  'schemas': {
    'input': 'pokemap.authoring.resource_pack.transfer.input.v2',
    'output': 'pokemap.authoring.resource_pack.transfer.output.v2',
    'additionalProperties': false,
    'nativeReferences': 'kindAndNativeId',
    'archiveReferences': 'kindAndPortableId',
  },
  'nativeSemantics': {
    'entrySectionsScope': 'nativeInventoryAtSelectionRevision',
    'inventoryAttributionScope': 'persistedInstallationDeclarations',
    'previewScope': 'preparedNativeClosure',
    'organizationAcknowledgement': 'exportOnly',
    'publishedSources': 'strict',
    'savedDraftComparison': [
      'equivalent',
      'divergent',
      'notComparable',
      'absent'
    ]
  },
  'limits': {
    'pageRows': 200,
    'responseBytes': 262144,
    'payloadChunkBytes': 131072,
    'selectionPatchRefs': 200,
    'inputBytes': 65536,
  },
  'transports': {
    'directApi': 'test/application/resource_pack_transfer_api_test.dart',
    'cli': 'test/tooling/jsonl_resource_pack_flow_test.dart',
    'mcp': '../../tools/pokemap_mcp/test/resource_pack_stdio.test.ts',
    'editor': 'PARTIAL:P10/P11',
  },
};

final resourcePackTransferCapability = AuthoringCapabilityDescriptor(
  id: 'authoring.resource_packs',
  version: 2,
  summary: 'Scoped asynchronous transfer of native resource packs',
  resourceKinds: resourcePackTemporaryKinds,
  actionIds: const ['resource_pack.import'],
  extensions: const {'editor': 'PARTIAL:P10/P11'},
);

final resourcePackTransferSchema = AuthoringSchemaDescriptor(
  id: 'pokemap.authoring.resource_pack.transfer.input.v2',
  version: 2,
  uri: 'pokemap://schema/resource-pack-transfer/input/v2',
  sha256: computeAuthoringJsonFingerprint(
    resourcePackTransferInputSchema,
    logicalName: 'resource-pack-transfer-schema',
  ).substring(7),
  extensions: {'schema': resourcePackTransferInputSchema},
);

final resourcePackTransferInputSchema = <String, Object?>{
  'oneOf': [
    for (final entry in resourcePackVerbInputSchemas.entries)
      _object(
        ['projectHandle', 'verb', 'input'],
        {
          'projectHandle': _handleSchema,
          'verb': {'const': entry.key, 'type': 'string'},
          'input': entry.value,
        },
      ),
  ],
};

final resourcePackVerbInputSchemas = <String, Map<String, Object?>>{
  'stage': _object(['sourcePath'], {'sourcePath': _textSchema(4096)}),
  'stage_license': _object(['sourcePath'], {'sourcePath': _textSchema(4096)}),
  'inspect': _object(['archiveHandle'], {'archiveHandle': _handleSchema}),
  'diagnose': {
    'oneOf': [
      _object(['expectedRevision'], {'expectedRevision': _revisionSchema}),
      _object(['expectedRevision', 'selectionHandle', 'revision'], {
        'expectedRevision': _revisionSchema,
        ..._selectionSchema,
      }),
    ],
  },
  'entries':
      _object([], {
          'inspectionHandle': _handleSchema,
          'selectionHandle': _handleSchema,
          'section': {'type': 'string', 'enum': ['resources', 'families', 'authors', 'sources'], 'default': 'resources'},
          'filter': _filterSchema,
          ..._pageSchema,
        })
        ..['oneOf'] = [
          {
            'required': ['inspectionHandle'],
            'not': {
              'required': ['selectionHandle'],
            },
          },
          {
            'required': ['selectionHandle'],
            'not': {
              'required': ['inspectionHandle'],
            },
          },
        ],
  'selection.create': {
    'oneOf': [
      _object(
        ['mode', 'inspectionHandle'],
        {
          'mode': {'const': 'archive', 'type': 'string'},
          'inspectionHandle': _handleSchema,
        },
      ),
      _object(
        ['mode'],
        {
          'mode': {'const': 'native', 'type': 'string'},
        },
      ),
    ],
  },
  'selection.patch': _object(
    ['selectionHandle', 'revision'],
    {
      ..._selectionSchema,
      'add': {'type': 'array', 'maxItems': 200, 'items': _refSchema},
      'remove': {'type': 'array', 'maxItems': 200, 'items': _refSchema},
    },
  )..['maxCombinedRefs'] = 200,
  'selection.select_filtered': _object(
    ['selectionHandle', 'revision', 'filter'],
    {..._selectionSchema, 'filter': _filterSchema},
  ),
  'prepare': {
    'oneOf': [
      _object(
        ['selectionHandle', 'revision', 'expectedRevision'],
        {
          ..._selectionSchema,
          'expectedRevision': _revisionSchema,
          'conflictPolicy': {
            'type': 'string',
            'enum': ['preserveProject', 'importCopy'],
            'default': 'preserveProject',
          },
        },
      ),
      _object([
        'selectionHandle',
        'revision',
        'expectedRevision',
        'metadata',
        'author'
      ], {
        ..._selectionSchema,
        'expectedRevision': _revisionSchema,
        'metadata': _metadataSchema,
        'author': _textSchema(128),
        'sourceUrl': {'type': 'string', 'maxLength': 4096},
        'licenseHandles': {
          'type': 'array',
          'maxItems': 200,
          'items': _handleSchema
        },
      }),
    ]
  },
  'preview': _object(
    ['previewHandle'],
    {'previewHandle': _handleSchema, ..._pageSchema},
  ),
  'start_apply': _object(
    ['planId', 'operationId'],
    {
      'planId': _handleSchema,
      'operationId': _handleSchema,
      'confirmationToken': _textSchema(4096),
    },
  ),
  'start_history': _object(
    ['operation', 'entryId', 'operationId', 'expectedRevision'],
    {
      'operation': {
        'type': 'string',
        'enum': ['undo', 'redo', 'revert'],
      },
      'entryId': _handleSchema,
      'operationId': _handleSchema,
      'expectedRevision': _revisionSchema,
      'expectedHeadEntryId': _handleSchema,
    },
  ),
  'start_recovery': _object(['operationId'], {'operationId': _handleSchema}),
  'recovery_status': _object([], {}),
  'export': _object([
    'preparedExportHandle'
  ], {
    'preparedExportHandle': _handleSchema,
    'acknowledgeOrganizationRemoval': {'type': 'boolean'}
  }),
  'get': _object(['jobId'], {'jobId': _handleSchema}),
  'events': _object(
    ['jobId'],
    {
      'jobId': _handleSchema,
      'afterSequence': {'type': 'integer', 'minimum': 0},
      'cursor': _handleSchema,
    },
  ),
  'read_payload': _object(
    ['payloadRef', 'offset', 'length'],
    {
      'payloadRef': _handleSchema,
      'offset': {'type': 'integer', 'minimum': 0},
      'length': {'type': 'integer', 'minimum': 1, 'maximum': 131072},
    },
  ),
  'cancel': _object(['jobId'], {'jobId': _handleSchema}),
  'release': _object(['handle'], {'handle': _handleSchema}),
};

const _handleSchema = {'type': 'string', 'minLength': 1, 'maxLength': 128};
const _revisionSchema = {'type': 'string', 'pattern': r'^sha256:[0-9a-f]{64}$'};
const _kindsSchema = {
  'type': 'string',
  'enum': [
    'tileset',
    'element',
    'model3d',
    'character',
    'environmentPreset',
    'smartTilePreset',
    'smartTilePattern',
    'borderBlueprint',
  ],
};
final _filterSchema = _object([], {
  'kind': _kindsSchema,
  'search': _textSchema(256),
  'selected': {'type': 'boolean'},
  'context': {
    'type': 'string',
    'enum': ['all', 'interior', 'exterior', 'both', 'unspecified'],
    'default': 'all',
  },
  'familyId': _textSchema(512),
});
final _refSchema = _object(
  ['kind', 'id'],
  {'kind': _kindsSchema, 'id': _textSchema(512)},
);
const _selectionSchema = {
  'selectionHandle': _handleSchema,
  'revision': _revisionSchema,
};
const _pageSchema = {
  'cursor': _handleSchema,
  'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200},
};
Map<String, Object?> _object(
  List<String> required,
  Map<String, Object?> properties,
) => {
  'type': 'object',
  'additionalProperties': false,
  'required': required,
  'properties': properties,
};
Map<String, Object?> _textSchema(int max) => {
      'type': 'string',
      'minLength': 1,
      'maxLength': max,
    };

final _metadataSchema = _object(
  [
    'id',
    'version',
    'name',
    'description',
    'universeId',
    'authors',
    'provenance',
  ],
  {
    'id': _textSchema(256),
    'version': _textSchema(128),
    'name': _textSchema(256),
    'description': {'type': 'string', 'maxLength': 4096},
    'universeId': _textSchema(256),
    'authors': {
      'type': 'array',
      'minItems': 1,
      'maxItems': 200,
      'items': _textSchema(128),
    },
    'provenance': _textSchema(4096),
  },
);
