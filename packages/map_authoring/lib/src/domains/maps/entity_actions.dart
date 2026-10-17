import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

final class EntityActions {
  const EntityActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const <(String, String)>[
      ('entity.create', 'Create a typed map entity'),
      ('entity.update', 'Replace a typed map entity'),
      ('entity.upsert', 'Create or replace a typed map entity'),
      ('entity.clone', 'Clone a typed map entity'),
      ('entity.move', 'Move a map entity'),
      ('entity.batch_move', 'Move map entities atomically'),
      ('entity.resize', 'Resize a map entity footprint'),
      ('entity.delete', 'Delete a map entity'),
      ('entity.set_npc_payload', 'Set a typed NPC payload'),
      ('entity.set_sign_payload', 'Set a typed sign payload'),
      ('entity.set_item_payload', 'Set a typed item payload'),
      ('entity.set_spawn_payload', 'Set a typed spawn payload'),
      ('entity.clear_payload', 'Reset the payload for an entity kind'),
      ('entity.set_visual', 'Set a typed entity editor visual'),
      ('entity.clear_visual', 'Clear an entity editor visual'),
      ('entity.set_blocks_movement', 'Set entity movement blocking'),
      ('entity.patch_properties', 'Patch entity string properties'),
      ('npc.set_facing', 'Set NPC facing'),
      ('npc.set_character', 'Set NPC character identity'),
      ('npc.set_trainer', 'Set NPC trainer identity'),
      ('npc.set_dialogue', 'Set or clear NPC dialogue'),
      ('npc.set_defeat_dialogue', 'Set or clear NPC defeat dialogue'),
      ('npc.set_visibility_rule', 'Set or clear NPC visibility rule'),
      ('npc.conditional_dialogue_add', 'Add conditional NPC dialogue'),
      ('npc.conditional_dialogue_update', 'Update conditional NPC dialogue'),
      ('npc.conditional_dialogue_remove', 'Remove conditional NPC dialogue'),
      ('npc.waypoint_add', 'Add an NPC patrol waypoint'),
      ('npc.waypoint_move', 'Move an NPC patrol waypoint'),
      ('npc.waypoint_reorder', 'Reorder an NPC patrol waypoint'),
      ('npc.waypoint_remove', 'Remove an NPC patrol waypoint'),
      ('npc.waypoint_clear', 'Clear NPC patrol waypoints'),
    ])
      semanticActionDescriptor(entry.$1, entry.$2),
    AuthoringActionDescriptor(
      id: 'npc.set_movement_mode', version: 1,
      summary: 'Set typed NPC movement, direct autonomous steps and instance suspension atomically',
      inputSchemaId: 'schema.npc.set_movement_mode.input.v1',
      outputSchemaId: 'schema.map.semantic_mutation.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const ['map','preset'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [AuthoringGuarantee.dryRun, AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked, AuthoringGuarantee.undoable],
      extensions: const {
        'semanticIds':true,'rawTilesetRequired':false,
        'npcMovement': {
          'modes':['idle','patrol','scriptedOnly','fixedRoute'],
          'parameters':['mapId','entityId','mode','routeSteps','suspendWhenInstanceBoolean',
            'loop','pauseDurationMs','stepDurationMs'],
          'fixedRoute': {
            'mapMode':'2d','stepKinds':['move','face','randomFacing'],
            'directions':['north','south','east','west'],'maximumSteps':256,
            'skippable':false,'pathfinding':false,'initialPause':true,
            'pauseAfterCompletionOrObstruction':true,
            'suspensionScope':'ownNpcCurrentMapInstanceBoolean',
          },
          'routeStepFields': {
            'move':['kind','direction'],'face':['kind','direction'],'randomFacing':['kind'],
          },
          'suspendWhenInstanceBoolean': {'optional':true,'fields':['key','value'],
            'maximumKeyLength':128,'owner':'currentNpc','scope':'currentMapInstance'},
          'fixedRouteTimingLimits': {'pauseDurationMs':[0,3600000],'stepDurationMs':[1,60000]},
        },
      },
    ),
    AuthoringActionDescriptor(
      id: 'entity.set_field_obstacle',
      version: 1,
      summary: 'Set or clear a typed field obstacle on an existing map object',
      inputSchemaId: 'schema.entity.set_field_obstacle.input.v1',
      outputSchemaId: 'schema.map.semantic_mutation.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: const {
        'semanticIds': true,
        'rawTilesetRequired': false,
        'fieldObstacle': {
          'kinds': ['cutTree', 'strengthBoulder', 'rockSmashRock'],
          'resetPolicies': ['mapInstance'],
          'entityKind': 'custom',
          'blocksMovement': true,
          'footprint': {'width': 1, 'height': 1},
          'mapMode': '2d',
          'visual': 'existingProjectElement',
          'clearValue': null,
          'parameters': ['mapId', 'entityId', 'fieldObstacle'],
        },
      },
    ),
    AuthoringActionDescriptor(
      id: 'entity.set_interactive_encounter', version: 1,
      summary: 'Set or clear a native Headbutt or after Rock Smash encounter',
      inputSchemaId: 'schema.entity.set_interactive_encounter.input.v1',
      outputSchemaId: 'schema.map.semantic_mutation.output.v1',
      riskLevel: AuthoringRiskLevel.low, resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [AuthoringGuarantee.dryRun, AuthoringGuarantee.idempotent, AuthoringGuarantee.revisionChecked, AuthoringGuarantee.undoable],
      extensions: const {'semanticIds': true, 'rawTilesetRequired': false,
        'interactiveEncounter': {'triggers': ['headbutt','afterRockSmash'], 'tableKinds': {'headbutt':'headbutt','afterRockSmash':'special'},
          'reusePolicies': ['repeatable','oncePerMapInstance'], 'mapMode': '2d', 'visual': 'existingProjectElement',
          'headbuttRequires': 'partyHasUsableMove:headbutt', 'chancePerAttemptField': 'chancePerStep',
          'conditions': 'ScriptCondition', 'consumption': 'battlePrepared', 'clearValue': null,
          'parameters': ['mapId','entityId','interactiveEncounter']}},
    ),
    AuthoringActionDescriptor(
      id: 'entity.set_healing_display',
      version: 1,
      summary: 'Set or clear six native party-healing display variants',
      inputSchemaId: 'schema.entity.set_healing_display.input.v1',
      outputSchemaId: 'schema.map.semantic_mutation.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: const {
        'semanticIds': true,
        'rawTilesetRequired': false,
        'healingDisplay': {
          'variantCount': 6,
          'variantReference': 'projectElement',
          'entityKind': 'custom',
          'blocksMovement': false,
          'footprint': {'width': 1, 'height': 1},
          'mapMode': '2d',
          'clearValue': null,
          'parameters': ['mapId', 'entityId', 'healingDisplay'],
        },
      },
    ),
    AuthoringActionDescriptor(
      id: 'npc.set_counter_interaction_sides',
      version: 1,
      summary:
          'Set NPC sides allowing interaction across one blocking counter cell',
      inputSchemaId: 'schema.npc.set_counter_interaction_sides.input.v1',
      outputSchemaId: 'schema.map.semantic_mutation.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: const {
        'semanticIds': true,
        'rawTilesetRequired': false,
        'counterInteraction': {
          'relativeTo': 'npc',
          'directions': ['north', 'south', 'east', 'west'],
          'distanceCells': 2,
          'intermediateCell': 'blockingAndWithoutEntity',
          'npcFootprint': {'width': 1, 'height': 1},
          'mapMode': '2d',
          'parameters': ['mapId', 'entityId', 'sides'],
        },
      },
    ),
  ]);

  MapData create(MapData map, MapEntity entity) {
    _assertStrictPayload(entity);
    try {
      return addEntityToMap(map, entity: entity);
    } on Object catch (error) {
      throw _entityFailure(error);
    }
  }

  MapData moveBatch(MapData map, Map<String, GridPos> destinations) {
    if (destinations.isEmpty) {
      throw semanticFailure(
        'entity.batch_empty',
        'An entity batch move must contain at least one destination.',
      );
    }
    var projected = map;
    try {
      final ids = destinations.keys.toList()..sort();
      for (final id in ids) {
        projected = moveEntityOnMap(
          projected,
          entityId: id,
          pos: destinations[id]!,
        );
      }
      return projected;
    } on Object catch (error) {
      throw _entityFailure(error, code: 'entity.batch_move_invalid');
    }
  }

  List<GridPos> previewNpcRoute(MapData map, String entityId) {
    final entity = _npcEntity(map, entityId);
    final movement = entity.npc!.movement;
    if (movement.mode != MapEntityNpcMovementMode.fixedRoute) {
      return List.unmodifiable([entity.pos, ...movement.waypoints]);
    }
    final positions = <GridPos>[entity.pos];
    for (final step in movement.routeSteps) {
      if (step is! MapEntityNpcMoveStep) {
        continue;
      }
      final (dx,dy) = switch (step.direction) {
        EntityFacing.north => (0,-1), EntityFacing.south => (0,1),
        EntityFacing.east => (1,0), EntityFacing.west => (-1,0),
      };
      final current = positions.last;
      positions.add(GridPos(x:current.x+dx,y:current.y+dy));
    }
    return List.unmodifiable(positions);
  }

  MapData setMovementConfiguration(MapData map, {
    required String entityId, required MapEntityNpcMovementConfig movement,
  }) {
    final entity = _npcEntity(map,entityId);
    try {
      assertValidMapEntityNpcMovementConfig(movement);
      return updateEntityOnMap(map, entityId:entity.id, npc:entity.npc!.copyWith(
        movement:movement.copyWith(routeSteps:List.unmodifiable(movement.routeSteps),
          waypoints:List.unmodifiable(movement.waypoints))));
    } on MapAuthoringException {
      rethrow;
    } on Object catch (error) {
      throw _entityFailure(error,code:'npc.movement_invalid');
    }
  }

  MapData setCounterInteractionSides(
    MapData map, {
    required String entityId,
    required List<EntityFacing> sides,
  }) {
    final entity = _npcEntity(map, entityId);
    if (sides.toSet().length != sides.length ||
        sides.length > 4 ||
        (sides.isNotEmpty &&
            (entity.size.width != 1 ||
                entity.size.height != 1 ||
                map.spatialScene != null ||
                map.version == ProjectVersion.v9))) {
      throw semanticFailure('npc.counter_interaction_invalid',
          'Counter interaction requires unique cardinal sides and a 1x1 NPC on a 2D map.');
    }
    return updateEntityOnMap(map,
        entityId: entityId,
        npc: entity.npc!.copyWith(
            counterInteractionSides: List<EntityFacing>.unmodifiable(sides)));
  }

  MapData setFieldObstacle(
    MapData map, {
    required ProjectManifest project,
    required String entityId,
    required MapEntityFieldObstacleData? fieldObstacle,
  }) {
    final entity = _entityById(map, entityId);
    if (fieldObstacle != null) {
      _assertFieldObstacleTarget(map, project, entity);
    }
    return updateEntityOnMap(map,
        entityId: entityId, fieldObstacle: fieldObstacle);
  }

  MapData setInteractiveEncounter(MapData map, {required ProjectManifest project, required String entityId, required MapEntityInteractiveEncounterData? interactiveEncounter}) {
    try {
      final updated = updateEntityOnMap(map, entityId: entityId, interactiveEncounter: interactiveEncounter);
      _assertInteractiveEncounterTarget(updated, project, _entityById(updated, entityId));
      return updated;
    } on MapAuthoringException { rethrow; } on Object {
      throw semanticFailure('entity.interactive_encounter_invalid', 'Interactive encounters require a matching native table and visual on a blocking 1x1 custom 2D object.');
    }
  }

  MapData setHealingDisplay(
    MapData map, {
    required ProjectManifest project,
    required String entityId,
    required MapEntityHealingDisplayData? healingDisplay,
  }) {
    _entityById(map, entityId);
    try {
      final updated = updateEntityOnMap(map,
          entityId: entityId, healingDisplay: healingDisplay);
      if (healingDisplay != null) {
        _assertHealingDisplayTarget(updated, project, _entityById(updated, entityId));
      }
      return updated;
    } on MapAuthoringException {
      rethrow;
    } on Object {
      throw semanticFailure('entity.healing_display_invalid',
          'Healing display requires six valid native elements on a nonblocking 1x1 custom object in 2D.');
    }
  }

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'entity.create' || 'entity.upsert' => const {'entity'},
      'entity.update' => const {'entityId', 'entity'},
      'entity.clone' => const {'entityId', 'newId', 'x', 'y'},
      'entity.move' => const {'entityId', 'x', 'y'},
      'entity.batch_move' => const {'moves'},
      'entity.resize' => const {'entityId', 'width', 'height'},
      'entity.delete' ||
      'entity.clear_payload' ||
      'entity.clear_visual' ||
      'npc.waypoint_clear' =>
        const {'entityId'},
      'entity.set_npc_payload' ||
      'entity.set_sign_payload' ||
      'entity.set_item_payload' ||
      'entity.set_spawn_payload' ||
      'entity.set_visual' =>
        const {'entityId', 'payload'},
      'entity.set_field_obstacle' => const {'entityId', 'fieldObstacle'},
      'entity.set_interactive_encounter' => const {'entityId', 'interactiveEncounter'},
      'entity.set_healing_display' => const {'entityId', 'healingDisplay'},
      'entity.set_blocks_movement' => const {'entityId', 'blocksMovement'},
      'entity.patch_properties' => const {'entityId', 'patch'},
      'npc.set_facing' => const {'entityId', 'facing'},
      'npc.set_counter_interaction_sides' => const {'entityId', 'sides'},
      'npc.set_character' => const {'entityId', 'characterId'},
      'npc.set_trainer' => const {'entityId', 'trainerId'},
      'npc.set_dialogue' || 'npc.set_defeat_dialogue' => const {
          'entityId',
          'dialogue',
        },
      'npc.set_visibility_rule' => const {'entityId', 'visibilityRule'},
      'npc.conditional_dialogue_add' => const {
          'entityId',
          'conditionalDialogue',
          'index',
        },
      'npc.conditional_dialogue_update' => const {
          'entityId',
          'conditionalDialogue',
          'index',
        },
      'npc.conditional_dialogue_remove' || 'npc.waypoint_remove' => const {
          'entityId',
          'index',
        },
      'npc.set_movement_mode' => const {
          'entityId',
          'mode',
          'routeSteps',
          'suspendWhenInstanceBoolean',
          'loop',
          'pauseDurationMs',
          'stepDurationMs',
        },
      'npc.waypoint_add' => const {'entityId', 'x', 'y', 'index'},
      'npc.waypoint_move' => const {'entityId', 'index', 'x', 'y'},
      'npc.waypoint_reorder' => const {
          'entityId',
          'index',
          'newIndex',
        },
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested entity action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    late MapData updated;
    var changedItems = 1;

    try {
      switch (actionId) {
        case 'entity.create':
          updated = create(context.map, _entity(parameters.object('entity')));
        case 'entity.upsert':
          final entity = _entity(parameters.object('entity'));
          _assertStrictPayload(entity);
          updated = context.map.entities.any((value) => value.id == entity.id)
              ? _replaceEntity(context.map, entity.id, entity)
              : create(context.map, entity);
        case 'entity.update':
          final entity = _entity(parameters.object('entity'));
          _assertStrictPayload(entity);
          updated = _replaceEntity(
            context.map,
            parameters.string('entityId'),
            entity,
          );
        case 'entity.clone':
          final source = _entityById(
            context.map,
            parameters.string('entityId'),
          );
          updated = create(
            context.map,
            source.copyWith(
              id: parameters.string('newId'),
              pos: GridPos(
                x: parameters.integer('x'),
                y: parameters.integer('y'),
              ),
            ),
          );
        case 'entity.move':
          updated = moveEntityOnMap(
            context.map,
            entityId: parameters.string('entityId'),
            pos: GridPos(
              x: parameters.integer('x'),
              y: parameters.integer('y'),
            ),
          );
        case 'entity.batch_move':
          final raw = parameters.list('moves');
          final moves = <String, GridPos>{};
          for (var index = 0; index < raw.length; index++) {
            final move = _object(raw[index], 'moves[$index]');
            _exactKeys(move, const {'entityId', 'x', 'y'}, 'moves[$index]');
            final id = _jsonString(move, 'entityId', 'moves[$index]');
            if (moves.containsKey(id)) {
              throw semanticFailure(
                'entity.batch_duplicate',
                'An entity appears more than once in the batch.',
                details: {'entityId': id},
              );
            }
            moves[id] = GridPos(
              x: _jsonInt(move, 'x', 'moves[$index]'),
              y: _jsonInt(move, 'y', 'moves[$index]'),
            );
          }
          updated = moveBatch(context.map, moves);
          changedItems = moves.length;
        case 'entity.resize':
          updated = resizeEntityOnMap(
            context.map,
            entityId: parameters.string('entityId'),
            size: GridSize(
              width: parameters.integer('width'),
              height: parameters.integer('height'),
            ),
          );
        case 'entity.delete':
          updated = removeEntityFromMap(
            context.map,
            entityId: parameters.string('entityId'),
          );
        case 'entity.set_npc_payload':
          updated = _setTypedPayload(
            context.map,
            parameters.string('entityId'),
            MapEntityKind.npc,
            parameters.object('payload'),
          );
        case 'entity.set_sign_payload':
          updated = _setTypedPayload(
            context.map,
            parameters.string('entityId'),
            MapEntityKind.sign,
            parameters.object('payload'),
          );
        case 'entity.set_item_payload':
          updated = _setTypedPayload(
            context.map,
            parameters.string('entityId'),
            MapEntityKind.item,
            parameters.object('payload'),
          );
        case 'entity.set_spawn_payload':
          updated = _setTypedPayload(
            context.map,
            parameters.string('entityId'),
            MapEntityKind.spawn,
            parameters.object('payload'),
          );
        case 'entity.clear_payload':
          final entity = _entityById(
            context.map,
            parameters.string('entityId'),
          );
          updated = _replaceEntity(
            context.map,
            entity.id,
            entity.copyWith(
                npc: null,
                sign: null,
                item: null,
                spawn: null,
                fieldObstacle: null,
                healingDisplay: null,
                interactiveEncounter: null),
          );
        case 'entity.set_visual':
          updated = updateEntityOnMap(
            context.map,
            entityId: parameters.string('entityId'),
            editorVisual: MapEntityEditorVisual.fromJson(
              parameters.object('payload').cast<String, dynamic>(),
            ),
          );
        case 'entity.clear_visual':
          updated = updateEntityOnMap(
            context.map,
            entityId: parameters.string('entityId'),
            editorVisual: null,
          );
        case 'entity.set_field_obstacle':
          if (!parameters.contains('fieldObstacle')) {
            throw invalidSemanticField(
                'fieldObstacle', 'a typed payload or explicit null');
          }
          final rawObstacle = parameters.value('fieldObstacle');
          MapEntityFieldObstacleData? obstacle;
          if (rawObstacle != null) {
            try {
              obstacle = MapEntityFieldObstacleData.fromJson(
                  _object(rawObstacle, 'fieldObstacle')
                      .cast<String, dynamic>());
            } on Object {
              throw semanticFailure('entity.field_obstacle_invalid',
                  'The field obstacle payload is unsupported.');
            }
          }
          updated = setFieldObstacle(context.map,
              project: context.manifest,
              entityId: parameters.string('entityId'),
              fieldObstacle: obstacle);
        case 'entity.set_interactive_encounter':
          if (!parameters.contains('interactiveEncounter')) throw invalidSemanticField('interactiveEncounter', 'a typed payload or explicit null');
          final raw = parameters.value('interactiveEncounter');
          MapEntityInteractiveEncounterData? payload;
          try {
            payload = raw == null ? null : MapEntityInteractiveEncounterData.fromJson(_object(raw, 'interactiveEncounter').cast<String,dynamic>());
          } on Object { throw semanticFailure('entity.interactive_encounter_invalid', 'Unsupported interactive encounter payload.'); }
          updated = setInteractiveEncounter(context.map, project: context.manifest, entityId: parameters.string('entityId'), interactiveEncounter: payload);
        case 'entity.set_healing_display':
          if (!parameters.contains('healingDisplay')) {
            throw invalidSemanticField(
                'healingDisplay', 'a typed payload or explicit null');
          }
          final rawDisplay = parameters.value('healingDisplay');
          MapEntityHealingDisplayData? display;
          if (rawDisplay != null) {
            try {
              display = MapEntityHealingDisplayData.fromJson(
                  _object(rawDisplay, 'healingDisplay').cast<String, dynamic>());
            } on Object {
              throw semanticFailure('entity.healing_display_invalid',
                  'The healing display payload is unsupported.');
            }
          }
          updated = setHealingDisplay(context.map,
              project: context.manifest,
              entityId: parameters.string('entityId'),
              healingDisplay: display);
        case 'entity.set_blocks_movement':
          updated = updateEntityOnMap(
            context.map,
            entityId: parameters.string('entityId'),
            blocksMovement: parameters.boolean('blocksMovement'),
          );
        case 'entity.patch_properties':
          final entity = _entityById(
            context.map,
            parameters.string('entityId'),
          );
          updated = updateEntityOnMap(
            context.map,
            entityId: entity.id,
            properties: _patchedProperties(
              entity.properties,
              parameters.object('patch'),
            ),
          );
        case 'npc.set_facing':
          updated = _patchNpcJson(
            context.map,
            parameters.string('entityId'),
            {'facing': parameters.string('facing')},
          );
        case 'npc.set_counter_interaction_sides':
          final sides = parameters.list('sides');
          if (sides.any((side) =>
              side is! String ||
              !EntityFacing.values
                  .any((direction) => direction.name == side))) {
            throw invalidSemanticField(
                'sides', 'a list of cardinal direction names');
          }
          updated = setCounterInteractionSides(context.map,
              entityId: parameters.string('entityId'),
              sides: [
                for (final side in sides)
                  EntityFacing.values.byName(side as String)
              ]);
        case 'npc.set_character':
          updated = _patchNpcJson(
            context.map,
            parameters.string('entityId'),
            {'characterId': parameters.value('characterId')},
          );
        case 'npc.set_trainer':
          updated = _patchNpcJson(
            context.map,
            parameters.string('entityId'),
            {'trainerId': parameters.value('trainerId')},
          );
        case 'npc.set_dialogue':
          updated = _patchNpcJson(
            context.map,
            parameters.string('entityId'),
            {'dialogue': parameters.value('dialogue')},
          );
        case 'npc.set_defeat_dialogue':
          updated = _patchNpcJson(
            context.map,
            parameters.string('entityId'),
            {'defeatDialogueRef': parameters.value('dialogue')},
          );
        case 'npc.set_visibility_rule':
          updated = _patchNpcJson(
            context.map,
            parameters.string('entityId'),
            {'visibilityRule': parameters.value('visibilityRule')},
          );
        case 'npc.conditional_dialogue_add':
        case 'npc.conditional_dialogue_update':
        case 'npc.conditional_dialogue_remove':
          updated = _editConditionalDialogue(
            context.map,
            entityId: parameters.string('entityId'),
            actionId: actionId,
            index: parameters.contains('index')
                ? parameters.integer('index')
                : null,
            raw: parameters.value('conditionalDialogue'),
          );
        case 'npc.set_movement_mode':
          final entity = _npcEntity(
            context.map,
            parameters.string('entityId'),
          );
          final movement = entity.npc!.movement.toJson();
          movement['mode'] = parameters.string('mode');
          final fixedRoute = movement['mode'] == MapEntityNpcMovementMode.fixedRoute.name;
          if (fixedRoute) {
            movement['waypoints'] = <Object>[];
            if (parameters.contains('routeSteps')) {
              movement['routeSteps'] = parameters.list('routeSteps');
            }
            if (parameters.contains('suspendWhenInstanceBoolean')) {
              movement['suspendWhenInstanceBoolean'] = parameters.value('suspendWhenInstanceBoolean');
            }
          } else {
            if ((parameters.contains('routeSteps') && parameters.list('routeSteps').isNotEmpty) ||
                (parameters.contains('suspendWhenInstanceBoolean') && parameters.value('suspendWhenInstanceBoolean') != null)) {
              throw semanticFailure('npc.movement_invalid','Autonomous steps and suspension require fixedRoute.');
            }
            movement['routeSteps'] = <Object>[];
            movement['suspendWhenInstanceBoolean'] = null;
          }
          if (parameters.contains('loop')) {
            movement['loop'] = parameters.boolean('loop');
          }
          if (parameters.contains('pauseDurationMs')) {
            movement['pauseDurationMs'] = parameters.integer('pauseDurationMs');
          }
          if (parameters.contains('stepDurationMs')) {
            movement['stepDurationMs'] = parameters.integer('stepDurationMs');
          }
          updated = setMovementConfiguration(context.map, entityId:entity.id,
            movement:MapEntityNpcMovementConfig.fromJson(movement));
        case 'npc.waypoint_add':
        case 'npc.waypoint_move':
        case 'npc.waypoint_reorder':
        case 'npc.waypoint_remove':
        case 'npc.waypoint_clear':
          updated = _editWaypoints(
            context.map,
            entityId: parameters.string('entityId'),
            actionId: actionId,
            index: parameters.contains('index')
                ? parameters.integer('index')
                : null,
            newIndex: parameters.contains('newIndex')
                ? parameters.integer('newIndex')
                : null,
            pos: parameters.contains('x')
                ? GridPos(
                    x: parameters.integer('x'),
                    y: parameters.integer('y'),
                  )
                : null,
          );
        default:
          throw StateError('unreachable entity action');
      }
    } on MapAuthoringException {
      rethrow;
    } on Object catch (error) {
      throw _entityFailure(error);
    }

    for (final entity
        in updated.entities.where((entity) => entity.fieldObstacle != null)) {
      _assertFieldObstacleTarget(updated, context.manifest, entity);
    }

    for (final entity
        in updated.entities.where((entity) => entity.healingDisplay != null)) {
      _assertHealingDisplayTarget(updated, context.manifest, entity);
    }

    for (final entity in updated.entities.where((entity) => entity.interactiveEncounter != null)) {
      _assertInteractiveEncounterTarget(updated, context.manifest, entity);
    }

    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: changedItems,
    );
  }
}

void _assertHealingDisplayTarget(
    MapData map, ProjectManifest project, MapEntity entity) {
  try {
    if (resolveHealingDisplayEntity(map, entity.id) != entity) {
      throw const ValidationException('Invalid healing display target.');
    }
    assertHealingDisplayVisualsAgainstProject(entity, project);
  } on Object {
    throw semanticFailure('entity.healing_display_invalid',
        'Healing display requires six valid native elements on a nonblocking 1x1 custom object in 2D.');
  }
}

void _assertFieldObstacleTarget(
    MapData map, ProjectManifest project, MapEntity entity) {
  if (map.spatialScene != null ||
      map.version == ProjectVersion.v9 ||
      project.settings.dimension != ProjectDimension.twoD ||
      entity.kind != MapEntityKind.custom ||
      !entity.blocksMovement ||
      entity.size.width != 1 ||
      entity.size.height != 1 ||
      entity.npc != null ||
      entity.sign != null ||
      entity.item != null ||
      entity.spawn != null ||
      entity.editorVisual == null ||
      project.elements
              .where((element) => element.id == entity.editorVisual!.elementId)
              .length !=
          1) {
    throw semanticFailure('entity.field_obstacle_invalid',
        'A field obstacle requires a blocking 1x1 custom object with an existing project visual on a 2D map.');
  }
}

MapEntity _entity(Map<String, Object?> value) {
  try {
    return MapEntity.fromJson(value.cast<String, dynamic>());
  } on Object catch (error) {
    throw _entityFailure(error, code: 'entity.payload_invalid');
  }
}

void _assertStrictPayload(MapEntity entity) {
  final matches = switch (entity.kind) {
    MapEntityKind.npc =>
      entity.sign == null && entity.item == null && entity.spawn == null,
    MapEntityKind.sign =>
      entity.npc == null && entity.item == null && entity.spawn == null,
    MapEntityKind.item =>
      entity.npc == null && entity.sign == null && entity.spawn == null,
    MapEntityKind.spawn =>
      entity.npc == null && entity.sign == null && entity.item == null,
    MapEntityKind.custom => entity.npc == null &&
        entity.sign == null &&
        entity.item == null &&
        entity.spawn == null,
  };
  if (!matches) {
    throw semanticFailure(
      'entity.payload_kind_mismatch',
      'The typed entity payload is incompatible with the entity kind.',
      details: {'entityId': entity.id, 'kind': entity.kind.name},
    );
  }
}

MapData _replaceEntity(MapData map, String entityId, MapEntity replacement) {
  _assertStrictPayload(replacement);
  return updateEntityOnMap(
    map,
    entityId: entityId,
    id: replacement.id,
    name: replacement.name,
    kind: replacement.kind,
    pos: replacement.pos,
    size: replacement.size,
    properties: replacement.properties,
    blocksMovement: replacement.blocksMovement,
    npc: replacement.npc,
    sign: replacement.sign,
    item: replacement.item,
    spawn: replacement.spawn,
    fieldObstacle: replacement.fieldObstacle,
    healingDisplay: replacement.healingDisplay,
    interactiveEncounter: replacement.interactiveEncounter,
    editorVisual: replacement.editorVisual,
  );
}

MapEntity _entityById(MapData map, String entityId) {
  final entity = findEntityById(map, entityId);
  if (entity == null) {
    throw semanticFailure(
      'entity.not_found',
      'The requested map entity does not exist.',
      details: {'entityId': entityId},
    );
  }
  return entity;
}

MapEntity _npcEntity(MapData map, String entityId) {
  final entity = _entityById(map, entityId);
  if (entity.kind != MapEntityKind.npc) {
    throw semanticFailure(
      'npc.kind_required',
      'The requested entity is not an NPC.',
      details: {'entityId': entityId, 'kind': entity.kind.name},
    );
  }
  return entity.npc == null
      ? entity.copyWith(npc: const MapEntityNpcData())
      : entity;
}

MapData _setTypedPayload(
  MapData map,
  String entityId,
  MapEntityKind expected,
  Map<String, Object?> raw,
) {
  final entity = _entityById(map, entityId);
  if (entity.kind != expected) {
    throw semanticFailure(
      'entity.payload_kind_mismatch',
      'The payload action is incompatible with the entity kind.',
      details: {
        'entityId': entityId,
        'expectedKind': expected.name,
        'actualKind': entity.kind.name,
      },
    );
  }
  return switch (expected) {
    MapEntityKind.npc => updateEntityOnMap(
        map,
        entityId: entityId,
        npc: MapEntityNpcData.fromJson(raw.cast<String, dynamic>()),
      ),
    MapEntityKind.sign => updateEntityOnMap(
        map,
        entityId: entityId,
        sign: MapEntitySignData.fromJson(raw.cast<String, dynamic>()),
      ),
    MapEntityKind.item => updateEntityOnMap(
        map,
        entityId: entityId,
        item: MapEntityItemData.fromJson(raw.cast<String, dynamic>()),
      ),
    MapEntityKind.spawn => updateEntityOnMap(
        map,
        entityId: entityId,
        spawn: MapEntitySpawnData.fromJson(raw.cast<String, dynamic>()),
      ),
    MapEntityKind.custom => throw semanticFailure(
        'entity.payload_kind_mismatch',
        'Custom entities do not accept a typed payload.',
      ),
  };
}

MapData _patchNpcJson(
  MapData map,
  String entityId,
  Map<String, Object?> patch,
) {
  final entity = _npcEntity(map, entityId);
  final json = entity.npc!.toJson()..addAll(patch);
  return updateEntityOnMap(
    map,
    entityId: entityId,
    npc: MapEntityNpcData.fromJson(json),
  );
}

MapData _editConditionalDialogue(
  MapData map, {
  required String entityId,
  required String actionId,
  required int? index,
  required Object? raw,
}) {
  final entity = _npcEntity(map, entityId);
  final values = List<MapEntityConditionalDialogue>.from(
    entity.npc!.conditionalDialogues,
  );
  if (actionId == 'npc.conditional_dialogue_add') {
    final entry = _conditionalDialogue(raw);
    final target = index ?? values.length;
    if (target < 0 || target > values.length) {
      throw invalidSemanticField('index', 'an insertion index in range');
    }
    values.insert(target, entry);
  } else {
    if (index == null || index < 0 || index >= values.length) {
      throw invalidSemanticField('index', 'an existing dialogue index');
    }
    if (actionId == 'npc.conditional_dialogue_update') {
      values[index] = _conditionalDialogue(raw);
    } else {
      values.removeAt(index);
    }
  }
  return updateEntityOnMap(
    map,
    entityId: entityId,
    npc: entity.npc!.copyWith(conditionalDialogues: values),
  );
}

MapEntityConditionalDialogue _conditionalDialogue(Object? raw) {
  final value = _object(raw, 'conditionalDialogue');
  return MapEntityConditionalDialogue.fromJson(value.cast<String, dynamic>());
}

MapData _editWaypoints(
  MapData map, {
  required String entityId,
  required String actionId,
  required int? index,
  required int? newIndex,
  required GridPos? pos,
}) {
  final entity = _npcEntity(map, entityId);
  final movement = entity.npc!.movement;
  final waypoints = List<GridPos>.from(movement.waypoints);
  if (actionId == 'npc.waypoint_clear') {
    waypoints.clear();
  } else if (actionId == 'npc.waypoint_add') {
    final target = index ?? waypoints.length;
    if (target < 0 || target > waypoints.length || pos == null) {
      throw invalidSemanticField('index', 'a valid waypoint insertion');
    }
    waypoints.insert(target, pos);
  } else {
    if (index == null || index < 0 || index >= waypoints.length) {
      throw invalidSemanticField('index', 'an existing waypoint index');
    }
    if (actionId == 'npc.waypoint_move') {
      if (pos == null) throw invalidSemanticField('position', 'x and y');
      waypoints[index] = pos;
    } else if (actionId == 'npc.waypoint_reorder') {
      if (newIndex == null || newIndex < 0 || newIndex >= waypoints.length) {
        throw invalidSemanticField('newIndex', 'an existing waypoint index');
      }
      final waypoint = waypoints.removeAt(index);
      waypoints.insert(newIndex, waypoint);
    } else {
      waypoints.removeAt(index);
    }
  }
  _requireWaypointsInBounds(map, waypoints);
  return updateEntityOnMap(
    map,
    entityId: entityId,
    npc: entity.npc!.copyWith(
      movement: movement.copyWith(waypoints: waypoints),
    ),
  );
}

void _requireWaypointsInBounds(MapData map, List<GridPos> waypoints) {
  for (final pos in waypoints) {
    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= map.size.width ||
        pos.y >= map.size.height) {
      throw semanticFailure(
        'npc.waypoint_out_of_bounds',
        'An NPC waypoint is outside map bounds.',
        details: {'x': pos.x, 'y': pos.y},
      );
    }
  }
}

Map<String, String> _patchedProperties(
  Map<String, String> current,
  Map<String, Object?> patch,
) {
  final result = Map<String, String>.from(current);
  for (final entry in patch.entries) {
    if (entry.key.isEmpty || entry.key.trim() != entry.key) {
      throw invalidSemanticField('patch', 'trimmed nonblank keys');
    }
    final value = entry.value;
    if (value == null) {
      result.remove(entry.key);
    } else if (value is String) {
      result[entry.key] = value;
    } else {
      throw invalidSemanticField('patch.${entry.key}', 'a string or null');
    }
  }
  return result;
}

Map<String, Object?> _object(Object? raw, String field) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw invalidSemanticField(field, 'a JSON object');
  }
  return Map<String, Object?>.from(raw);
}

void _exactKeys(
  Map<String, Object?> value,
  Set<String> allowed,
  String field,
) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw invalidSemanticField(field, 'only ${allowed.join(', ')}');
  }
}

String _jsonString(Map<String, Object?> value, String key, String field) {
  final raw = value[key];
  if (raw is! String || raw.isEmpty || raw.trim() != raw) {
    throw invalidSemanticField('$field.$key', 'a trimmed nonblank string');
  }
  return raw;
}

int _jsonInt(Map<String, Object?> value, String key, String field) {
  final raw = value[key];
  if (raw is! int) throw invalidSemanticField('$field.$key', 'an integer');
  return raw;
}

MapAuthoringException _entityFailure(
  Object error, {
  String code = 'entity.mutation_invalid',
}) =>
    semanticFailure(
      code,
      'The entity mutation is invalid.',
      details: {'validationType': error.runtimeType.toString()},
    );

void _assertInteractiveEncounterTarget(MapData map, ProjectManifest project, MapEntity entity) {
  if (entity.interactiveEncounter == null) return;
  try {
    if (map.version != ProjectVersion.v8 || map.spatialScene != null) throw StateError('Interactive encounters require 2D.');
    assertEntityInteractiveEncounterAgainstProject(entity, project);
  } on Object { throw semanticFailure('entity.interactive_encounter_invalid', 'Interactive encounters require a matching native table and visual on a blocking 1x1 custom 2D object.'); }
}
