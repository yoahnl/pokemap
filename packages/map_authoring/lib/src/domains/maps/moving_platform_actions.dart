import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

final class MovingPlatformActions {
  const MovingPlatformActions();

  static final descriptors = [
    for (final action in ['map.platform.upsert', 'map.platform.delete'])
      AuthoringActionDescriptor(
          id: action,
          version: 1,
          summary: action.endsWith('upsert')
              ? 'Create or replace a 2D moving platform with native orientation variants'
              : 'Delete an unreferenced 2D moving platform and retain its placed visual',
          inputSchemaId: 'schema.$action.input.v1',
          outputSchemaId: 'schema.map.semantic_mutation.output.v1',
          riskLevel: AuthoringRiskLevel.low,
          resourceKinds: const [
            'map'
          ],
          requiredPermissions: const [
            AuthoringPermission.projectWrite
          ],
          guarantees: const [
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable
          ],
          extensions: {
            'terrainSupport': 'nominatedTileAndSmartTileLayersOnly',
            'smartTileSupport': 'occupiedSemanticCells',
            'preciseTerrainSupport': 'explicitLatticeCellsByLayer',
            'sharedTerrainGeometry': 'identicalAcrossPlatforms',
            'independentCollisionLayers': 'alwaysBlocking',
            'maximumTranslationPixels': maxMovingPlatformTranslationPixels,
            'controls': 'automaticPlayerEntryWithRotationAndCarrySuppression',
            'motionOutcomes': [
              'moved',
              'blocked',
              'notRiding',
              'rotationRequiresPivot'
            ],
            'inputSchema': {
              'type': 'object',
              'additionalProperties': false,
              'required': [
                'mapId',
                action.endsWith('upsert') ? 'platform' : 'platformId'
              ],
              'properties': {
                'mapId': {'type': 'string', 'minLength': 1},
                if (action.endsWith('upsert')) 'platform': _definitionSchema,
                if (action.endsWith('delete'))
                  'platformId': {'type': 'string', 'minLength': 1},
              },
            },
          }),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final upsert = planning.request.actionId == 'map.platform.upsert';
    final context = SemanticMapActionContext.read(planning,
        allowedParameters: {upsert ? 'platform' : 'platformId'});
    try {
      final platform = upsert
          ? MovingPlatformDefinition.fromJson(
              Map<String, dynamic>.from(context.parameters.object('platform')))
          : null;
      final id = platform?.id ?? context.parameters.string('platformId');
      if (!upsert) {
        if (!context.map.movingPlatforms.any((value) => value.id == id)) {
          throw semanticFailure(
              'map.platform_not_found', 'The moving platform does not exist.');
        }
        final dependencies = buildNarrativeDependencyIndex(
            project: context.manifest, maps: planning.snapshot.maps);
        final usages = dependencies.usagesFor(NarrativeDependencyKey.mapSource(
            mapId: context.map.id, sourceKind: 'movingPlatform', sourceId: id));
        if (usages.isNotEmpty) {
          throw semanticFailure(
              'map.platform_referenced', 'The platform is used by a Scene.',
              details: {
                'references': usages.map((usage) => usage.path).toList()
              });
        }
      }
      final after = context.map.copyWith(movingPlatforms: [
        for (final existing in context.map.movingPlatforms)
          if (existing.id != id) existing,
        if (platform != null) platform,
      ]);
      validateMovingPlatformDefinitions(
          map: after,
          project: context.manifest,
          tileSize: PixelSize(
              width: context.manifest.settings.tileWidth,
              height: context.manifest.settings.tileHeight));
      return context.draftMap(
          after: after,
          operation: planning.request.actionId,
          changedItems: 1,
          preview: {'platformId': id});
    } on FormatException catch (error) {
      throw semanticFailure('map.platform_invalid', error.message.toString());
    }
  }
}

const _pointSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['x', 'y'],
  'properties': {
    'x': {'type': 'integer'},
    'y': {'type': 'integer'}
  }
};
const _cellsSchema = {
  'type': 'array',
  'minItems': 1,
  'maxItems': 4096,
  'items': _pointSchema
};
const _definitionSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'id',
    'placedElementId',
    'initialPose',
    'lattice',
    'translationDistanceCells',
    'variants',
    'terrainLayerIds',
    'travelCells'
  ],
  'properties': {
    'id': {'type': 'string', 'minLength': 1},
    'placedElementId': {'type': 'string', 'minLength': 1},
    'initialPose': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['leftPx', 'topPx', 'quarterTurns'],
      'properties': {
        'leftPx': {'type': 'number', 'minimum': 0},
        'topPx': {'type': 'number', 'minimum': 0},
        'quarterTurns': {'type': 'integer', 'minimum': 0, 'maximum': 3}
      }
    },
    'lattice': {
      'type': 'object',
      'additionalProperties': false,
      'required': [
        'widthPx',
        'heightPx',
        'originLeftPx',
        'originTopPx',
        'cellOffsetLeftPx',
        'cellOffsetTopPx'
      ],
      'properties': {
        'widthPx': {'type': 'number', 'minimum': 1, 'maximum': 4096},
        'heightPx': {'type': 'number', 'minimum': 1, 'maximum': 4096},
        'originLeftPx': {'type': 'number'},
        'originTopPx': {'type': 'number'},
        'cellOffsetLeftPx': {'type': 'number'},
        'cellOffsetTopPx': {'type': 'number'}
      }
    },
    'translationDistanceCells': {
      'type': 'integer',
      'minimum': 1,
      'maximum': 256
    },
    'controls': {
      'type': 'array',
      'maxItems': 64,
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['id', 'cell', 'motion'],
        'properties': {
          'id': {'type': 'string', 'minLength': 1},
          'cell': _pointSchema,
          'motion': {'type': 'string', 'enum': ['forward', 'backward', 'rotateClockwise']},
        },
      },
    },
    'terrainCellsByLayer': {
      'type': 'object',
      'additionalProperties': {
        'type': 'array',
        'maxItems': 65536,
        'items': _pointSchema,
      },
    },
    'terrainLayerIds': {
      'type': 'array',
      'minItems': 1,
      'uniqueItems': true,
      'items': {'type': 'string', 'minLength': 1}
    },
    'travelCells': {
      'type': 'array',
      'minItems': 1,
      'maxItems': 65536,
      'items': _pointSchema
    },
    'variants': {
      'type': 'array',
      'minItems': 4,
      'maxItems': 4,
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'elementId',
          'anchorOffsetPx',
          'supportCells',
          'clearanceCells',
          'forwardClearanceCells',
          'backwardClearanceCells',
          'rotationClearanceCells'
        ],
        'properties': {
          'elementId': {'type': 'string', 'minLength': 1},
          'anchorOffsetPx': _pointSchema,
          'supportCells': _cellsSchema,
          'clearanceCells': _cellsSchema,
          'forwardClearanceCells': _cellsSchema,
          'backwardClearanceCells': _cellsSchema,
          'rotationClearanceCells': _cellsSchema
        },
      }
    },
  },
};
