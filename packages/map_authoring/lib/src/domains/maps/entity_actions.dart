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
      ('npc.set_movement_mode', 'Set NPC movement configuration'),
      ('npc.waypoint_add', 'Add an NPC patrol waypoint'),
      ('npc.waypoint_move', 'Move an NPC patrol waypoint'),
      ('npc.waypoint_reorder', 'Reorder an NPC patrol waypoint'),
      ('npc.waypoint_remove', 'Remove an NPC patrol waypoint'),
      ('npc.waypoint_clear', 'Clear NPC patrol waypoints'),
    ])
      semanticActionDescriptor(entry.$1, entry.$2),
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
    return List.unmodifiable([entity.pos, ...entity.npc!.movement.waypoints]);
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
      'entity.set_blocks_movement' => const {'entityId', 'blocksMovement'},
      'entity.patch_properties' => const {'entityId', 'patch'},
      'npc.set_facing' => const {'entityId', 'facing'},
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
            entity.copyWith(npc: null, sign: null, item: null, spawn: null),
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
          if (parameters.contains('loop')) {
            movement['loop'] = parameters.boolean('loop');
          }
          if (parameters.contains('pauseDurationMs')) {
            movement['pauseDurationMs'] = parameters.integer('pauseDurationMs');
          }
          if (parameters.contains('stepDurationMs')) {
            movement['stepDurationMs'] = parameters.integer('stepDurationMs');
          }
          updated = _patchNpcJson(
            context.map,
            entity.id,
            {'movement': movement},
          );
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

    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: changedItems,
    );
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
