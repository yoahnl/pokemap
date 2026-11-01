import '../../contracts/periodic_reward_choices.dart';
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';
import '../../editing/environment_editing.dart';
import 'map_action_examples.dart';

final class SpatialMapActions {
  const SpatialMapActions();
  static const int maximumInstancesPerBatch = 50;
  static const _fields = {
    'map3d.terrain.set_levels': 'cells',
    'map3d.terrain.configure_height': 'levelHeight',
    'map3d.terrain.configure_appearance': 'cliffFrame',
    'map3d.instance.visibility.set': 'visibilityCondition',
    'map3d.instance.upsert': 'instance',
    'map3d.instance.configure_field_obstacle': 'fieldObstacle',
    'map3d.instance.upsert_batch': 'instances',
    'map3d.instance.delete': 'instanceId',
    'map3d.instance.delete_batch': 'instanceIds',
    'map3d.camera.configure': 'camera',
    'map3d.day_night.configure': 'cycle',
    'map3d.navigation.configure': 'navigation',
    'map3d.ledge.configure': 'ledges',
  };
  static final descriptors = [
    for (final entry in _fields.entries)
      AuthoringActionDescriptor(
        id: entry.key,
        version: 1,
        summary: switch (entry.value) {
          'visibilityCondition' =>
            'Set a native 3D model visibility condition without changing its anchor or collision',
          'fieldObstacle' =>
            'Configure Cut, Strength or Rock Smash on a selected static blocking 3D model',
          'cells' => 'Set discrete terrain levels on a 3D map',
          'levelHeight' =>
            'Configure physical terrain level height and preserve instance offsets',
          'cliffFrame' =>
            'Configure terrain cliff texture and generated wall visibility',
          'instance' => 'Place or replace a 3D model instance',
          'instances' =>
            'Place or replace bounded 3D instances atomically on one map',
          'instanceId' => 'Delete a 3D model instance',
          'instanceIds' => 'Delete bounded 3D instances atomically on one map',
          'navigation' => 'Configure spawn, ramps and exploration movement',
          'ledges' =>
            'Configure one-way native ledge jumps and their landing cells',
          'cycle' =>
            'Configure or disable a visual day/night cycle without changing gameplay time',
          _ => 'Configure a fixed 3D map camera',
        },
        inputSchemaId: 'schema.${entry.key}.input.v1',
        outputSchemaId: 'schema.map.semantic_mutation.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const ['map'],
        requiredPermissions: const [AuthoringPermission.projectWrite],
        guarantees: [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
          AuthoringGuarantee.atomic,
        ],
        extensions: {
          if (entry.value == 'visibilityCondition') 'periodicRewardAvailable': periodicRewardConditionChoiceContract,
          if (mapActionInputExample(entry.key) case final example?)
            'inputExample': example,
          if (entry.value == 'visibilityCondition')
            'visibility': {
              'capability': 'map3d.conditional-visibility@1',
              'sourceChoices': ['periodicRewardScene', 'periodicRewardNode'],
              'condition': 'NarrativeEventConditionExpression',
              'preserves': [
                'entityId',
                'position',
                'rotationDegrees',
                'scale',
                'blocksMovement'
              ],
              'automaticEnvironment': 'promotePreservingIdentityAndPose',
            },
          if (entry.value == 'navigation')
            'fishingDrop': {
              'capability': SpatialNavigationProfile.fishingDropCapabilityId,
              'default':
                  SpatialNavigationProfile.defaultMaximumFishingDropWorld,
              'units': 'world',
              'maximumRiseWorld': .25
            },
          if (entry.value == 'ledges')
            'directionalTraversal': {
              'capability': SpatialLedge.capabilityId,
              'coordinateOrigin': 'source_cell',
              'landing': 'source_plus_direction_times_distance',
              'blockedReverse': true
            },
          if (entry.value == 'cycle')
            'visualClock': {
              'gameplayClockIndependent': true,
              'capability': 'map3d.day-night@1',
              'disabled': null,
              'durationUnits': 'seconds_per_full_day',
            },
          if (entry.value == 'camera') ...{
            'projections': ['perspective', 'orthographic'],
            'orthographicHeightUnits': 'world_cells_full_vertical_extent',
            'orthographicCapability':
                SpatialCameraProfile.orthographicCapabilityId,
          },
          if (entry.value == 'instance' || entry.value == 'instances')
            'entityBinding': {
              'field': 'entityId',
              'capability': SpatialModelInstance.entityBindingCapabilityId,
              'manualEnvironmentCapability':
                  SpatialModelInstance.manualEnvironmentEntityBindingCapabilityId,
              'ownership': 'authored_or_unique_spatial_manual_environment',
              'manualOwnerRequiredLists': ['generatedPlacementIds', 'manualPlacementIds'],
              'automaticOrAmbiguousOwner': 'reject',
              'scope': 'same_map_non_npc',
              'unique': true,
              'empty': null
            },
          if (entry.value == 'instance' || entry.value == 'instances')
            'shadowCasting': {
              'field': 'castsShadows',
              'default': null,
              'inherits': 'model3d.castsShadowsByDefault',
              'replacementSemantics': true
            },
          if (entry.value == 'instance' || entry.value == 'instances')
            'model3dClip': {
              'field': 'clip',
              'capability': SpatialModelClipCapabilities.capabilityId,
              'coordinates': ['left', 'top', 'right', 'bottom'],
              'units': 'cells_relative_to_instance_pivot_before_rotation',
              'sourceAdmission':
                  'inspected_static_glb_without_node_or_material_animations',
              'blocksMovement': false,
              'animationIndex': null,
              'attachedRamp': 'unsupported',
              'mapBoundsReference': 'rotated_clip_center',
            },
          if (entry.value == 'instances' || entry.value == 'instanceIds') ...{
            'maximumInstanceCount': maximumInstancesPerBatch,
            'batchAtomicity': 'all_or_nothing',
            'undoBoundary': 'batch',
            'duplicateInstanceIds': 'reject',
          },
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'mapId',
              entry.value,
              if (const {'fieldObstacle', 'visibilityCondition'}
                  .contains(entry.value)) 'instanceId'
            ],
            'properties': {
              'mapId': {'type': 'string', 'minLength': 1},
              entry.value: _schema(entry.value),
              if (const {'fieldObstacle', 'visibilityCondition'}
                  .contains(entry.value))
                'instanceId': _schema('instanceId'),
              if (entry.value == 'cliffFrame')
                'generateCliffs': {'type': 'boolean'},
            }
          }
        },
      ),
  ];

  MapData setInstanceVisibility(MapData map,
      {required ProjectManifest project,
      required String instanceId,
      required NarrativeEventConditionExpression? condition,
      List<MapData> maps = const [],
      PeriodicRewardSceneLookup? lookupRewardScenes}) {
    if (map.spatialScene == null ||
        project.settings.dimension != ProjectDimension.threeD) {
      throw semanticFailure('map3d.dimension_required',
          'Visibility requires a 3D project and map.');
    }
    final instances = map.spatialScene!.instances
        .where((item) => item.id == instanceId)
        .toList();
    if (instances.length != 1)
      throw semanticFailure(
          'map3d.instance_missing', 'Select one existing model instance.');
    _requireAuthoredInstance(map, instanceId,
        requireExisting: true,
        allowManualEnvironment: true,
        allowAutomaticEnvironment: true);
    for (final leaf in condition?.leaves ?? const <NarrativeEventCondition>[]) {
      leaf.whenTyped<void>(periodicRewardAvailable: (reference, _) {
        if (!resolvePeriodicRewardReference(
                reference: reference,
                lookupScenes: lookupRewardScenes ?? (_) => const [])
            .isResolved) {
          throw semanticFailure('map3d.visibility_reward_reference_invalid',
              'Choose a published reward action that still exists.');
        }
      }, fact: (id, operator, expected) {
        if (project.facts
                .where(
                    (fact) => fact.id == id && fact.valueKind == expected.kind)
                .length !=
            1) {
          throw semanticFailure('map3d.visibility_fact_invalid',
              'The selected world state is unavailable or has changed type.');
        }
      }, narrativeEventConsumed: (id, _) {
        if (project.eventRegistry?.records
                .where((record) => record.id == id)
                .length !=
            1) {
          throw semanticFailure('map3d.visibility_event_invalid',
              'The selected event is unavailable.');
        }
      }, mapEventInstanceBoolean: (mapId, eventId, key, expected) {
        final candidates = mapId == map.id
            ? [map]
            : maps.where((item) => item.id == mapId).toList();
        if (project.settings.mapInstanceRetentionPolicy == null ||
            candidates.length != 1 ||
            candidates.single.entities
                    .where((entity) => entity.id == eventId)
                    .length !=
                1) {
          throw semanticFailure('map3d.visibility_instance_owner_invalid',
              'The selected entity state requires a valid map owner and retention policy.');
        }
      });
    }
    var result = map;
    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      for (final area in layer.content.areas) {
        if (area.generatedPlacementIds.contains(instanceId) &&
            !area.manualPlacementIds.contains(instanceId)) {
          result = const EnvironmentEditing().promoteSpatialPlacement(result,
              layerId: layer.id, areaId: area.id, placementId: instanceId);
        }
      }
    }
    return result.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
      for (final instance in map.spatialScene!.instances)
        if (instance.id == instanceId)
          instance.copyWith(visibilityCondition: condition, clearVisibilityCondition: condition == null)
        else
          instance,
    ]));
  }

  MapData configureFieldObstacle(
    MapData map, {
    required ProjectManifest project,
    required String instanceId,
    required MapEntityFieldObstacleData? fieldObstacle,
  }) {
    if (map.spatialScene == null ||
        project.settings.dimension != ProjectDimension.threeD) {
      throw semanticFailure('map3d.dimension_required',
          'Field obstacles require a 3D project and map.');
    }
    _requireAuthoredInstance(map, instanceId, requireExisting: true);
    final instance = map.spatialScene!.instances
        .singleWhere((item) => item.id == instanceId);
    final existing = map.entities
        .where((entity) => entity.id == instance.entityId)
        .firstOrNull;
    if (fieldObstacle == null) {
      if (existing == null || existing.fieldObstacle == null) return map;
      return map.copyWith(entities: [
        for (final entity in map.entities)
          if (entity.id == existing.id)
            entity.copyWith(fieldObstacle: null)
          else
            entity
      ]);
    }
    final model = project.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
    if (model == null ||
        model.inspection.animations.isNotEmpty ||
        model.rampProfile != null ||
        existing != null && existing.kind != MapEntityKind.custom ||
        instance.entityId != null && existing == null) {
      throw semanticFailure('entity.field_obstacle_invalid',
          'Choose an independent static blocking model with no other gameplay role.');
    }
    var id = existing?.id ?? 'field_';
    if (existing == null) {
      final base =
          'field_${instance.id}'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      id = base.length > 116 ? base.substring(0, 116) : base;
      var suffix = 1;
      final ids = map.entities.map((entity) => entity.id).toSet();
      while (ids.contains(id)) {
        id = '${base.length > 116 ? base.substring(0, 116) : base}_${suffix++}';
      }
    }
    final entity = (existing ??
            MapEntity(
                id: id,
                name: model.name,
                kind: MapEntityKind.custom,
                pos: GridPos(
                    x: instance.position.x.floor(),
                    y: instance.position.z.floor()),
                blocksMovement: true))
        .copyWith(fieldObstacle: fieldObstacle);
    final after = map.copyWith(
        entities: [
          for (final item in map.entities)
            if (item.id == id) entity else item,
          if (existing == null) entity,
        ],
        spatialScene: map.spatialScene!.copyWith(instances: [
          for (final item in map.spatialScene!.instances)
            if (item.id == instanceId) item.copyWith(entityId: id) else item,
        ]));
    if (!isValidSpatialFieldObstacle(after, entity)) {
      throw semanticFailure('entity.field_obstacle_invalid',
          'A Cut, Strength or Rock Smash obstacle requires exactly one static blocking model and a blocking custom object on the same cell.');
    }
    return after;
  }

  AuthoringMutationDraft build(AuthoringPlanningContext planning) =>
      project(planning).finalize();

  SemanticMapProjection project(
    AuthoringPlanningContext planning, {
    MapData? projectedMap,
    bool deferFinalization = false,
  }) {
    final action = planning.request.actionId;
    final field = _fields[action];
    if (field == null) {
      throw semanticFailure(
          'map3d.action_unsupported', 'Unsupported spatial map action.');
    }
    final context = SemanticMapActionContext.read(planning,
        projectedMap: projectedMap,
        deferFinalization: deferFinalization,
        allowedParameters: {
          field,
          if (const {'fieldObstacle', 'visibilityCondition'}.contains(field)) 'instanceId',
          if (field == 'cliffFrame') 'generateCliffs',
        });
    if (context.manifest.settings.dimension != ProjectDimension.threeD ||
        context.map.spatialScene == null) {
      throw semanticFailure('map3d.dimension_required',
          'This operation requires a 3D project and map.');
    }
    if (field == 'visibilityCondition') {
      if (!context.parameters.contains(field))
        throw invalidSemanticField(
            field, 'a condition expression or explicit null');
      final raw = context.parameters.value(field);
      final condition =
          raw == null ? null : NarrativeEventConditionExpression.fromJson(raw);
      final id = context.parameters.string('instanceId');
      final after = setInstanceVisibility(context.map,
          project: context.manifest,
          instanceId: id,
          condition: condition,
          maps: planning.snapshot.maps,
          lookupRewardScenes: planning.snapshot.lookupRewardScenes);
      return SemanticMapProjection(
          map: after,
          operation: planning.request.actionId,
          changedItems: 1,
          preview: {'instanceId': id, 'preserveSpatialPreview': true},
          finalize: () =>
              context.draftInstanceVisibility(after: after, instanceId: id));
    }
    if (field == 'cells' && context.parameters.list(field).length > 65536) {
      throw semanticFailure('map3d.parameters_invalid',
          'A terrain operation supports at most 65536 cells.');
    }
    if (!context.parameters.contains(field)) {
      throw semanticFailure('map3d.parameters_invalid',
          'The spatial action requires its configuration field.');
    }
    if (field == 'instanceId') {
      final instanceId = context.parameters.string(field);
      _requireAuthoredInstance(context.map, instanceId, requireExisting: true);
      final index = buildNarrativeDependencyIndex(
          project: context.manifest, maps: planning.snapshot.maps);
      final usages = index.usagesFor(NarrativeDependencyKey.mapSource(
          mapId: context.map.id,
          sourceKind: 'modelInstance',
          sourceId: instanceId));
      if (usages.isNotEmpty) {
        throw semanticFailure('map3d.instance_referenced',
            'The 3D instance is still referenced and cannot be deleted.',
            details: {
              'instanceId': instanceId,
              'references': usages.map((usage) => usage.path).toList()..sort(),
            });
      }
    }
    const operations = SpatialMapOperations();
    try {
      final after = switch (field) {
        'fieldObstacle' => configureFieldObstacle(context.map,
            project: context.manifest,
            instanceId: context.parameters.string('instanceId'),
            fieldObstacle: context.parameters.value(field) == null
                ? null
                : MapEntityFieldObstacleData.fromJson(_object(
                    context.parameters.value(field), {'kind', 'resetPolicy'}))),
        'instances' => _upsertInstances(context),
        'instanceIds' => _deleteInstances(context, planning.snapshot.maps),
        'levelHeight' =>
          _configureTerrainHeight(context.map, context.parameters.value(field)),
        'cliffFrame' => operations.configureTerrainAppearance(context.map,
            generateCliffs: context.parameters.value('generateCliffs') as bool?,
            cliffFrame: context.parameters.value(field) == null
                ? null
                : SmartTileFrameRef.fromJson(_object(
                    context.parameters.value(field),
                    {'atlasId', 'column', 'row', 'columnSpan', 'rowSpan'}))),
        'cells' => operations.setLevels(
            context.map,
            context.parameters.list(field).map((value) {
              final cell = _object(value, {'x', 'z', 'level'});
              return SpatialCellLevel(
                  x: cell['x'] as int,
                  z: cell['z'] as int,
                  level: cell['level'] as int);
            }).toList()),
        'instance' => _upsertInstance(context),
        'navigation' => _configureNavigation(context),
        'ledges' => operations.configureNavigation(
            context.map,
            context.map.spatialScene!.navigation.copyWith(
                ledges: context.parameters.list('ledges').map((value) =>
                    SpatialLedge.fromJson(_object(value, {
                      'id',
                      'x',
                      'z',
                      'direction',
                      'distance',
                      'durationMs',
                      'height'
                    })))),
            models: context.manifest.models3d),
        'cycle' => operations.configureDayNightCycle(
            context.map,
            context.parameters.value(field) == null
                ? null
                : SpatialDayNightCycle.fromJson(_object(
                    context.parameters.value(field),
                    {'durationSeconds', 'startMinuteOfDay'}))),
        'instanceId' => operations.deleteInstance(
            context.map, context.parameters.string(field)),
        _ => operations.configureCamera(
            context.map,
            SpatialCameraProfile.fromJson(
                _object(context.parameters.object(field), {
              'mode',
              'projection',
              'pitchDegrees',
              'yawDegrees',
              'fieldOfViewDegrees',
              'distance',
              'orthographicHeight'
            }))),
      };
      return context.projectMap(
          validateProjectReferences: field != 'fieldObstacle' &&
              (field != 'camera' ||
                  !planning.snapshot.materializedCatalogProject ||
                  planning.snapshot.availableProjectSections == null),
          after: after,
          operation: action,
          changedItems: switch (field) {
            'cells' =>
              _changedCells(context.map.spatialScene!, after.spatialScene!),
            'instances' =>
              _changedInstances(context.map.spatialScene!, after.spatialScene!),
            'instanceIds' => context.parameters.list(field).length,
            _ => 1,
          },
          preview: field == 'instances' || field == 'instanceIds'
              ? {
                  'instanceIds': field == 'instanceIds'
                      ? context.parameters.list(field)
                      : context.parameters
                          .list(field)
                          .map((item) => (item as Map)['id'])
                          .toList(),
                  'instanceCount': context.parameters.list(field).length,
                  'changedInstanceCount': field == 'instanceIds'
                      ? context.parameters.list(field).length
                      : _changedInstances(
                          context.map.spatialScene!, after.spatialScene!),
                  'batchAtomicity': 'all_or_nothing',
                  'undoBoundary': 'batch',
                }
              : {'spatialScene': after.spatialScene!.toJson()});
    } on FormatException catch (error) {
      throw semanticFailure('map3d.parameters_invalid', error.message);
    } on ValidationException catch (error) {
      throw semanticFailure(
          error.code ?? 'map3d.parameters_invalid', error.message,
          details: error.details);
    } on TypeError {
      throw semanticFailure('map3d.parameters_invalid',
          'The spatial action parameters have invalid types or missing fields.');
    }
  }
}

MapData _upsertInstance(SemanticMapActionContext context) {
  final instance = _decodeUpsertInstance(
      context, context.parameters.object('instance'));
  _requireAuthoredInstance(context.map, instance.id,
      allowManualEnvironment: true);
  final model = context.manifest.models3d
      .where((model) => model.id == instance.modelId)
      .firstOrNull;
  _requireStaticClip(instance, model);
  return const SpatialMapOperations()
      .upsertInstance(context.map, instance, model: model);
}

SpatialModelInstance _decodeUpsertInstance(
    SemanticMapActionContext context, Object? value) {
  final raw = _object(value, {
    'id',
    'modelId',
    'position',
    'rotationDegrees',
    'scale',
    'animationIndex',
    'animationLoop',
    'animationSpeed',
    'blocksMovement',
    'castsShadows',
    'entityId',
    'clip',
    'visibilityCondition',
  });
  final instance = SpatialModelInstance.fromJson(raw);
  final existing = context.map.spatialScene!.instances
      .where((value) => value.id == instance.id)
      .firstOrNull;
  if (raw.containsKey('visibilityCondition') &&
      instance.visibilityCondition != existing?.visibilityCondition) {
    throw semanticFailure('map3d.instance.visibility_requires_setter',
        'Change visibility through map3d.instance.visibility.set after creating the instance.',
        details: {
          'instanceId': instance.id,
          'actionId': 'map3d.instance.visibility.set',
        });
  }
  return raw.containsKey('visibilityCondition')
      ? instance
      : instance.copyWith(visibilityCondition: existing?.visibilityCondition);
}

MapData _configureNavigation(SemanticMapActionContext context) {
  final navigation = SpatialNavigationProfile.fromJson(_object(
    context.parameters.object('navigation'),
    {
      'spawn',
      'allowDiagonalMovement',
      'ramps',
      'blockedAreas',
      'ledges',
      'maximumFishingDropWorld'
    },
  ));
  for (final ramp in navigation.ramps) {
    final surfaceId = ramp.surfaceInstanceId;
    if (surfaceId != null) _requireAuthoredInstance(context.map, surfaceId);
  }
  return const SpatialMapOperations().configureNavigation(
      context.map, navigation,
      models: context.manifest.models3d);
}

void _requireAuthoredInstance(MapData map, String id,
    {bool requireExisting = false, bool allowManualEnvironment = false,
    bool allowAutomaticEnvironment = false}) {
  if (id.startsWith('smt_')) {
    throw semanticFailure('map3d.instance.generated',
        'Smart Tile models must be edited through their painted layer.');
  }
  for (final layer in map.layers) {
    if (layer is EnvironmentLayer) {
      for (final area in layer.content.areas) {
        if (!allowAutomaticEnvironment &&
            area.generatedPlacementIds.contains(id) &&
            (!allowManualEnvironment ||
                !area.manualPlacementIds.contains(id))) {
          throw semanticFailure('map3d.instance.owned',
              'Environment instances must be edited through their area.',
              details: {
                'instanceId': id,
                'layerId': layer.id,
                'areaId': area.id
              });
        }
      }
    } else if (layer is BorderLayer) {
      for (final feature in layer.content.features) {
        if (feature.generatedPlacementIds.contains(id)) {
          throw semanticFailure('map3d.instance.owned',
              'Border instances must be edited through their feature.',
              details: {
                'instanceId': id,
                'layerId': layer.id,
                'featureId': feature.id
              });
        }
      }
    }
  }
  if (requireExisting &&
      !map.spatialScene!.instances.any((instance) => instance.id == id)) {
    throw semanticFailure(
        'map3d.instance.not_found', 'The spatial instance does not exist.',
        details: {'instanceId': id});
  }
}

MapData _deleteInstances(SemanticMapActionContext context, List<MapData> maps) {
  final raw = context.parameters.list('instanceIds');
  if (raw.isEmpty) {
    throw const FormatException(
        'A deletion batch requires at least one instance ID.');
  }
  if (raw.length > SpatialMapActions.maximumInstancesPerBatch) {
    throw semanticFailure('map3d.instance.batch_too_large',
        'An instance batch supports at most fifty instances.',
        details: {
          'instanceCount': raw.length,
          'maximumInstanceCount': SpatialMapActions.maximumInstancesPerBatch
        });
  }
  final ids = <String>{};
  for (final value in raw) {
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw const FormatException(
          'Deletion instance IDs must be nonempty strings without surrounding whitespace.');
    }
    if (!ids.add(value)) {
      throw semanticFailure('map3d.instance.batch_duplicate',
          'An instance batch cannot repeat an instance identity.',
          details: {'instanceId': value});
    }
    _requireAuthoredInstance(context.map, value,
        requireExisting: !context.deferFinalization);
  }
  final index =
      buildNarrativeDependencyIndex(project: context.manifest, maps: maps);
  for (final id in ids) {
    final usages = index.usagesFor(NarrativeDependencyKey.mapSource(
        mapId: context.map.id, sourceKind: 'modelInstance', sourceId: id));
    if (usages.isNotEmpty) {
      throw semanticFailure('map3d.instance_referenced',
          'The 3D instance is still referenced and cannot be deleted.',
          details: {
            'instanceId': id,
            'references': usages.map((usage) => usage.path).toList()..sort()
          });
    }
  }
  final scene = context.map.spatialScene!;
  final projected = context.map.copyWith(
      spatialScene: scene.copyWith(
          instances:
              scene.instances.where((instance) => !ids.contains(instance.id)),
          navigation: scene.navigation.copyWith(
              ramps: scene.navigation.ramps
                  .where((ramp) => !ids.contains(ramp.surfaceInstanceId)))));
  validateSpatialMapStructure(projected);
  return projected;
}

MapData _upsertInstances(SemanticMapActionContext context) {
  final raw = context.parameters.list('instances');
  if (raw.isEmpty) {
    throw const FormatException(
        'An instance batch requires at least one instance.');
  }
  if (raw.length > SpatialMapActions.maximumInstancesPerBatch) {
    throw semanticFailure('map3d.instance.batch_too_large',
        'An instance batch supports at most fifty instances.',
        details: {
          'instanceCount': raw.length,
          'maximumInstanceCount': SpatialMapActions.maximumInstancesPerBatch
        });
  }
  final instances = <SpatialModelInstance>[];
  final ids = <String>{};
  final models = {
    for (final model in context.manifest.models3d) model.id: model
  };
  for (final value in raw) {
    final instance = _decodeUpsertInstance(context, value);
    _requireAuthoredInstance(context.map, instance.id,
        allowManualEnvironment: true);
    if (!ids.add(instance.id)) {
      throw semanticFailure('map3d.instance.batch_duplicate',
          'An instance batch cannot repeat an instance identity.',
          details: {'instanceId': instance.id});
    }
    final model = models[instance.modelId];
    if (model == null) {
      throw semanticFailure('map3d.instance.model_not_found',
          'The instance source model does not exist in the project.',
          details: {'instanceId': instance.id, 'modelId': instance.modelId});
    }
    if (instance.animationIndex != null &&
        !model.inspection.animations
            .any((clip) => clip.index == instance.animationIndex)) {
      throw semanticFailure('map3d.instance.animation_invalid',
          'The instance animation is absent from the inspected source model.',
          details: {
            'instanceId': instance.id,
            'modelId': instance.modelId,
            'animationIndex': instance.animationIndex
          });
    }
    _requireStaticClip(instance, model);
    instances.add(instance);
  }
  return const SpatialMapOperations().upsertInstances(context.map, instances,
      models: context.manifest.models3d);
}

void _requireStaticClip(
    SpatialModelInstance instance, ProjectModel3dEntry? model) {
  if (instance.clip == null) return;
  if (model == null) {
    throw semanticFailure('map3d.instance.model_not_found',
        'A clipped instance requires an existing model.',
        details: {'modelId': instance.modelId});
  }
  if (model.inspection.animations.isNotEmpty) {
    throw semanticFailure('map3d.instance.clip_animated_model',
        'Clipped instances require a static GLB without node or material animations.',
        details: {'modelId': model.id, 'instanceId': instance.id});
  }
  if (model.rampProfile != null) {
    throw semanticFailure('map3d.instance.clip_ramp_model',
        'Clipped instances cannot use an attached ramp profile.',
        details: {'modelId': model.id});
  }
}

int _changedInstances(MapSpatialScene before, MapSpatialScene after) {
  final existing = {
    for (final instance in before.instances) instance.id: instance
  };
  return after.instances
      .where((instance) => existing[instance.id] != instance)
      .length;
}

MapData _configureTerrainHeight(MapData map, Object? value) {
  if (value is! num || !value.isFinite || value <= 0 || value > 16) {
    throw const FormatException(
        'Terrain level height must be finite, greater than 0 and at most 16.');
  }
  return const SpatialMapOperations()
      .configureLevelHeight(map, value.toDouble());
}

Map<String, dynamic> _object(Object? value, Set<String> allowed) {
  if (value is! Map || value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Invalid spatial object fields.');
  }
  return Map<String, dynamic>.from(value);
}

int _changedCells(MapSpatialScene before, MapSpatialScene after) {
  var count = 0;
  for (var i = 0; i < before.heightLevels.length; i++) {
    if (before.heightLevels[i] != after.heightLevels[i]) count++;
  }
  return count;
}

Map<String, Object?> _schema(String field) => switch (field) {
      'visibilityCondition' => {
          'type': ['object', 'null']
        },
      'fieldObstacle' => {
          'type': ['object', 'null'],
          'additionalProperties': false,
          'required': ['kind', 'resetPolicy'],
          'properties': {
            'kind': {
              'enum': ['cutTree', 'strengthBoulder', 'rockSmashRock']
            },
            'resetPolicy': {
              'enum': ['mapInstance', 'persistent']
            }
          },
        },
      'cycle' => {
          'type': ['object', 'null'],
          'additionalProperties': false,
          'properties': {
            'durationSeconds': {
              'type': 'number',
              'minimum': 10,
              'maximum': 86400,
              'default': 600
            },
            'startMinuteOfDay': {
              'type': 'integer',
              'minimum': 0,
              'maximum': 1439,
              'default': 720
            },
          },
        },
      'instanceIds' => {
          'type': 'array',
          'minItems': 1,
          'maxItems': SpatialMapActions.maximumInstancesPerBatch,
          'uniqueItems': true,
          'items': {'type': 'string', 'minLength': 1},
        },
      'instances' => {
          'type': 'array',
          'minItems': 1,
          'maxItems': SpatialMapActions.maximumInstancesPerBatch,
          'items': _schema('instance'),
        },
      'levelHeight' => {
          'type': 'number',
          'exclusiveMinimum': 0,
          'maximum': 16,
        },
      'cliffFrame' => {
          'type': ['object', 'null'],
          'additionalProperties': false,
          'required': ['atlasId', 'column', 'row'],
          'properties': {
            'atlasId': {'type': 'string', 'minLength': 1},
            'column': {'type': 'integer', 'minimum': 0},
            'row': {'type': 'integer', 'minimum': 0},
            'columnSpan': {'type': 'integer', 'minimum': 1},
            'rowSpan': {'type': 'integer', 'minimum': 1},
          },
        },
      'ledges' => {
          'type': 'array',
          'maxItems': 4096,
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['id', 'x', 'z', 'direction'],
            'properties': {
              'id': {'type': 'string', 'pattern': r'^[a-zA-Z0-9_-]{1,128}$'},
              'x': {'type': 'integer', 'minimum': 0, 'maximum': 255},
              'z': {'type': 'integer', 'minimum': 0, 'maximum': 255},
              'direction': {
                'enum': ['north', 'south', 'east', 'west']
              },
              'distance': {'type': 'integer', 'minimum': 2, 'maximum': 4},
              'durationMs': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 2000
              },
              'height': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 4},
            }
          }
        },
      'navigation' => {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'spawn',
            'allowDiagonalMovement',
            'ramps',
            'blockedAreas'
          ],
          'properties': {
            'spawn': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['x', 'z'],
              'properties': {
                'x': {'type': 'number', 'minimum': 0, 'exclusiveMaximum': 256},
                'z': {'type': 'number', 'minimum': 0, 'exclusiveMaximum': 256}
              }
            },
            'ledges': _schema('ledges'),
            'allowDiagonalMovement': {'type': 'boolean'},
            'maximumFishingDropWorld': {
              'type': 'number',
              'minimum': 0,
              'maximum': 4,
              'default': .25,
              'description':
                  'Maximum downward fishing cast height in world units; upward limit remains 0.25.'
            },
            'ramps': {
              'type': 'array',
              'maxItems': 256,
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'id',
                  'x',
                  'z',
                  'width',
                  'depth',
                  'lowLevel',
                  'highLevel',
                  'direction'
                ],
                'properties': {
                  ..._rectangleProperties,
                  'id': {
                    'type': 'string',
                    'pattern': r'^[a-zA-Z0-9_-]{1,128}$'
                  },
                  'lowLevel': {
                    'type': 'number',
                    'minimum': 0,
                    'exclusiveMaximum': MapSpatialScene.maximumTerrainLevel
                  },
                  'highLevel': {
                    'type': 'number',
                    'exclusiveMinimum': 0,
                    'maximum': MapSpatialScene.maximumTerrainLevel
                  },
                  'direction': {
                    'enum': ['north', 'south', 'east', 'west']
                  },
                  'surfaceInstanceId': {
                    'type': ['string', 'null'],
                    'pattern': r'^[a-zA-Z0-9_-]{1,128}$',
                    'description':
                        'Existing walkable authored model instance that replaces the painted ramp surface; null restores terrain.',
                  },
                }
              }
            },
            'blockedAreas': {
              'type': 'array',
              'maxItems': 4096,
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['x', 'z', 'width', 'depth'],
                'properties': _rectangleProperties
              }
            }
          }
        },
      'instanceId' => {'type': 'string', 'minLength': 1},
      'cells' => {
          'type': 'array',
          'maxItems': 65536,
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['x', 'z', 'level'],
            'properties': {
              'x': {'type': 'integer', 'minimum': 0, 'maximum': 255},
              'z': {'type': 'integer', 'minimum': 0, 'maximum': 255},
              'level': {
                'type': 'integer',
                'minimum': 0,
                'maximum': MapSpatialScene.maximumTerrainLevel
              }
            }
          }
        },
      'instance' => {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'id',
            'modelId',
            'position',
            'rotationDegrees',
            'scale',
            'blocksMovement'
          ],
          'properties': {
            'id': {'type': 'string'},
            'modelId': {'type': 'string'},
            'position': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['x', 'y', 'z'],
              'properties': {
                for (final axis in ['x', 'y', 'z']) axis: {'type': 'number'}
              }
            },
            'rotationDegrees': {'type': 'number'},
            'scale': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 1000},
            'animationIndex': {
              'type': ['integer', 'null'],
              'minimum': 0
            },
            'animationLoop': {'type': 'boolean'},
            'animationSpeed': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 16
            },
            'blocksMovement': {'type': 'boolean'},
            'entityId': {
              'type': ['string', 'null'],
              'pattern': r'^[a-zA-Z0-9_-]{1,128}$'
            },
            'castsShadows': {
              'type': ['boolean', 'null'],
              'description':
                  'Overrides the model shadow default; null or omission inherits it.',
            },
            'visibilityCondition': {
              ..._schema('visibilityCondition'),
              'description':
                  'An identical condition is accepted; omission preserves the existing condition. Use map3d.instance.visibility.set to change or clear it, including after creating an instance.',
            },
            'clip': {
              'type': ['object', 'null'],
              'additionalProperties': false,
              'required': ['left', 'top', 'right', 'bottom'],
              'properties': {
                for (final coordinate in ['left', 'top', 'right', 'bottom'])
                  coordinate: {'type': 'number'}
              }
            }
          }
        },
      _ => {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'mode',
            'pitchDegrees',
            'yawDegrees',
            'fieldOfViewDegrees',
            'distance'
          ],
          'properties': {
            'mode': {
              'enum': ['fixed']
            },
            'projection': {
              'type': 'string',
              'enum': ['perspective', 'orthographic']
            },
            'orthographicHeight': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 10000
            },
            'pitchDegrees': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'exclusiveMaximum': 90
            },
            'yawDegrees': {'type': 'number'},
            'fieldOfViewDegrees': {
              'type': 'number',
              'exclusiveMinimum': 1,
              'exclusiveMaximum': 120
            },
            'distance': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 10000
            }
          },
          'allOf': [
            {
              'if': {
                'properties': {
                  'projection': {'const': 'orthographic'}
                },
                'required': ['projection'],
              },
              'then': {
                'required': ['orthographicHeight']
              },
            },
          ],
        },
    };

const _rectangleProperties = <String, Object?>{
  'x': {'type': 'number', 'minimum': 0, 'maximum': 256},
  'z': {'type': 'number', 'minimum': 0, 'maximum': 256},
  'width': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 256},
  'depth': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 256},
};
