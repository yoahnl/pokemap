import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

final class TriggerZoneActions {
  const TriggerZoneActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const <(String, String)>[
      ('trigger.create', 'Create a map trigger'),
      ('trigger.update', 'Replace a map trigger'),
      ('trigger.move', 'Move a map trigger'),
      ('trigger.resize', 'Resize a map trigger'),
      ('trigger.clone', 'Clone a map trigger'),
      ('trigger.delete_apply', 'Delete a map trigger'),
      ('trigger.patch_properties', 'Patch trigger properties'),
      ('gameplay_zone.create', 'Create a typed gameplay zone'),
      (
        'gameplay_zone.smart_tile.sync',
        'Synchronize gameplay zones generated from one Smart Tile binding',
      ),
      ('gameplay_zone.update', 'Replace a typed gameplay zone'),
      ('gameplay_zone.move', 'Move a gameplay zone'),
      ('gameplay_zone.resize', 'Resize a gameplay zone'),
      ('gameplay_zone.clone', 'Clone a gameplay zone'),
      ('gameplay_zone.delete', 'Delete a gameplay zone'),
      (
        'gameplay_zone.set_encounter_payload',
        'Set a typed encounter-zone payload',
      ),
      (
        'gameplay_zone.set_movement_payload',
        'Set a typed movement-zone payload',
      ),
      (
        'gameplay_zone.set_movement_effect_payload',
        'Set a typed movement-effect payload',
      ),
      (
        'gameplay_zone.set_hazard_payload',
        'Set a typed hazard-zone payload',
      ),
      (
        'gameplay_zone.set_special_payload',
        'Set a typed special-zone payload',
      ),
      ('gameplay_zone.clear_payload', 'Clear a gameplay-zone payload'),
      ('gameplay_zone.set_priority', 'Set gameplay-zone priority'),
    ])
      semanticActionDescriptor(entry.$1, entry.$2),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'trigger.create' => const {'trigger'},
      'trigger.update' => const {'triggerId', 'trigger'},
      'trigger.move' => const {'triggerId', 'x', 'y'},
      'trigger.resize' => const {'triggerId', 'width', 'height'},
      'trigger.clone' => const {'triggerId', 'newId', 'x', 'y'},
      'trigger.delete_apply' => const {'triggerId'},
      'trigger.patch_properties' => const {'triggerId', 'patch'},
      'gameplay_zone.create' => const {'zone'},
      'gameplay_zone.smart_tile.sync' => const {'zones'},
      'gameplay_zone.update' => const {'zoneId', 'zone'},
      'gameplay_zone.move' => const {'zoneId', 'x', 'y'},
      'gameplay_zone.resize' => const {'zoneId', 'width', 'height'},
      'gameplay_zone.clone' => const {'zoneId', 'newId', 'x', 'y'},
      'gameplay_zone.delete' || 'gameplay_zone.clear_payload' => const {
          'zoneId',
        },
      'gameplay_zone.set_encounter_payload' ||
      'gameplay_zone.set_movement_payload' ||
      'gameplay_zone.set_movement_effect_payload' ||
      'gameplay_zone.set_hazard_payload' ||
      'gameplay_zone.set_special_payload' =>
        const {'zoneId', 'payload'},
      'gameplay_zone.set_priority' => const {'zoneId', 'priority'},
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested trigger or gameplay-zone action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    late MapData updated;

    try {
      switch (actionId) {
        case 'trigger.create':
          updated = addTriggerToMap(
            context.map,
            trigger: _trigger(parameters.object('trigger')),
          );
        case 'trigger.update':
          final replacement = _trigger(parameters.object('trigger'));
          updated = updateTriggerOnMap(
            context.map,
            triggerId: parameters.string('triggerId'),
            id: replacement.id,
            name: replacement.name,
            type: replacement.type,
            area: replacement.area,
            properties: replacement.properties,
          );
        case 'trigger.move':
          updated = moveTriggerOnMap(
            context.map,
            triggerId: parameters.string('triggerId'),
            pos: GridPos(
              x: parameters.integer('x'),
              y: parameters.integer('y'),
            ),
          );
        case 'trigger.resize':
          updated = resizeTriggerOnMap(
            context.map,
            triggerId: parameters.string('triggerId'),
            size: GridSize(
              width: parameters.integer('width'),
              height: parameters.integer('height'),
            ),
          );
        case 'trigger.clone':
          final source = _triggerById(
            context.map,
            parameters.string('triggerId'),
          );
          updated = addTriggerToMap(
            context.map,
            trigger: source.copyWith(
              id: parameters.string('newId'),
              area: source.area.copyWith(
                pos: GridPos(
                  x: parameters.integer('x'),
                  y: parameters.integer('y'),
                ),
              ),
            ),
          );
        case 'trigger.delete_apply':
          updated = removeTriggerFromMap(
            context.map,
            triggerId: parameters.string('triggerId'),
          );
        case 'trigger.patch_properties':
          final trigger = _triggerById(
            context.map,
            parameters.string('triggerId'),
          );
          updated = updateTriggerOnMap(
            context.map,
            triggerId: trigger.id,
            properties: _patchProperties(
              trigger.properties,
              parameters.object('patch'),
            ),
          );
        case 'gameplay_zone.create':
          final zone = _zone(parameters.object('zone'));
          _assertStrictZonePayload(zone);
          updated = addGameplayZoneToMap(context.map, zone: zone);
        case 'gameplay_zone.smart_tile.sync':
          final zones = _zones(parameters.list('zones'));
          for (final zone in zones) {
            _assertStrictZonePayload(zone);
          }
          updated = synchronizeSmartTileGameplayZones(
            context.map,
            generatedZones: zones,
          ).map;
        case 'gameplay_zone.update':
          final zone = _zone(parameters.object('zone'));
          _assertStrictZonePayload(zone);
          updated = updateGameplayZoneOnMap(
            context.map,
            zoneId: parameters.string('zoneId'),
            id: zone.id,
            name: zone.name,
            kind: zone.kind,
            area: zone.area,
            priority: zone.priority,
            encounter: zone.encounter,
            movement: zone.movement,
            movementEffect: zone.movementEffect,
            hazard: zone.hazard,
            special: zone.special,
            smartTileProvenance: zone.smartTileProvenance,
          );
        case 'gameplay_zone.move':
          updated = moveGameplayZoneOnMap(
            context.map,
            zoneId: parameters.string('zoneId'),
            pos: GridPos(
              x: parameters.integer('x'),
              y: parameters.integer('y'),
            ),
          );
        case 'gameplay_zone.resize':
          updated = resizeGameplayZoneOnMap(
            context.map,
            zoneId: parameters.string('zoneId'),
            size: GridSize(
              width: parameters.integer('width'),
              height: parameters.integer('height'),
            ),
          );
        case 'gameplay_zone.clone':
          final source = _zoneById(
            context.map,
            parameters.string('zoneId'),
          );
          updated = addGameplayZoneToMap(
            context.map,
            zone: source.copyWith(
              id: parameters.string('newId'),
              smartTileProvenance: null,
              area: source.area.copyWith(
                pos: GridPos(
                  x: parameters.integer('x'),
                  y: parameters.integer('y'),
                ),
              ),
            ),
          );
        case 'gameplay_zone.delete':
          updated = removeGameplayZoneFromMap(
            context.map,
            zoneId: parameters.string('zoneId'),
          );
        case 'gameplay_zone.set_encounter_payload':
          updated = _setZonePayload(
            context.map,
            parameters.string('zoneId'),
            GameplayZoneKind.encounter,
            parameters.object('payload'),
          );
        case 'gameplay_zone.set_movement_payload':
          updated = _setZonePayload(
            context.map,
            parameters.string('zoneId'),
            GameplayZoneKind.movement,
            parameters.object('payload'),
          );
        case 'gameplay_zone.set_movement_effect_payload':
          updated = _setZonePayload(
            context.map,
            parameters.string('zoneId'),
            GameplayZoneKind.movementEffect,
            parameters.object('payload'),
          );
        case 'gameplay_zone.set_hazard_payload':
          updated = _setZonePayload(
            context.map,
            parameters.string('zoneId'),
            GameplayZoneKind.hazard,
            parameters.object('payload'),
          );
        case 'gameplay_zone.set_special_payload':
          final zone = _zoneById(
            context.map,
            parameters.string('zoneId'),
          );
          if (zone.kind != GameplayZoneKind.special &&
              zone.kind != GameplayZoneKind.custom) {
            throw _zoneKindFailure(zone, 'special/custom');
          }
          updated = updateGameplayZoneOnMap(
            context.map,
            zoneId: zone.id,
            special: SpecialZonePayload.fromJson(
              parameters.object('payload').cast<String, dynamic>(),
            ),
          );
        case 'gameplay_zone.clear_payload':
          final zone = _zoneById(
            context.map,
            parameters.string('zoneId'),
          );
          updated = updateGameplayZoneOnMap(
            context.map,
            zoneId: zone.id,
            kind: zone.kind == GameplayZoneKind.movementEffect
                ? GameplayZoneKind.custom
                : zone.kind,
            encounter: null,
            movement: null,
            movementEffect: null,
            hazard: null,
            special: null,
          );
        case 'gameplay_zone.set_priority':
          updated = updateGameplayZoneOnMap(
            context.map,
            zoneId: parameters.string('zoneId'),
            priority: parameters.integer('priority'),
          );
        default:
          throw StateError('unreachable trigger/zone action');
      }
    } on MapAuthoringException {
      rethrow;
    } on Object catch (error) {
      throw semanticFailure(
        'spatial_object.mutation_invalid',
        'The trigger or gameplay-zone mutation is invalid.',
        details: {'validationType': error.runtimeType.toString()},
      );
    }

    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: 1,
    );
  }
}

MapTrigger _trigger(Map<String, Object?> value) {
  try {
    return MapTrigger.fromJson(value.cast<String, dynamic>());
  } on Object catch (error) {
    throw semanticFailure(
      'trigger.payload_invalid',
      'The trigger payload is invalid.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

MapGameplayZone _zone(Map<String, Object?> value) {
  try {
    return MapGameplayZone.fromJson(value.cast<String, dynamic>());
  } on Object catch (error) {
    throw semanticFailure(
      'gameplay_zone.payload_invalid',
      'The gameplay-zone payload is invalid.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

List<MapGameplayZone> _zones(List<Object?> values) {
  if (values.isEmpty) {
    throw invalidSemanticField('zones', 'a non-empty list');
  }
  return List<MapGameplayZone>.unmodifiable(
    values.indexed.map((entry) {
      final (index, value) = entry;
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw invalidSemanticField('zones[$index]', 'an object');
      }
      return _zone(value.cast<String, Object?>());
    }),
  );
}

MapTrigger _triggerById(MapData map, String id) {
  final trigger = findTriggerById(map, id);
  if (trigger == null) {
    throw semanticFailure(
      'trigger.not_found',
      'The requested trigger does not exist.',
      details: {'triggerId': id},
    );
  }
  return trigger;
}

MapGameplayZone _zoneById(MapData map, String id) {
  final zone = findGameplayZoneById(map, id);
  if (zone == null) {
    throw semanticFailure(
      'gameplay_zone.not_found',
      'The requested gameplay zone does not exist.',
      details: {'zoneId': id},
    );
  }
  return zone;
}

void _assertStrictZonePayload(MapGameplayZone zone) {
  final matches = switch (zone.kind) {
    GameplayZoneKind.encounter => zone.movement == null &&
        zone.movementEffect == null &&
        zone.hazard == null &&
        zone.special == null,
    GameplayZoneKind.movement => zone.encounter == null &&
        zone.movementEffect == null &&
        zone.hazard == null &&
        zone.special == null,
    GameplayZoneKind.movementEffect => zone.encounter == null &&
        zone.movement == null &&
        zone.hazard == null &&
        zone.special == null &&
        zone.movementEffect != null,
    GameplayZoneKind.hazard => zone.encounter == null &&
        zone.movement == null &&
        zone.movementEffect == null &&
        zone.special == null,
    GameplayZoneKind.special ||
    GameplayZoneKind.custom =>
      zone.encounter == null &&
          zone.movement == null &&
          zone.movementEffect == null &&
          zone.hazard == null,
  };
  if (!matches) throw _zoneKindFailure(zone, zone.kind.name);
}

MapAuthoringException _zoneKindFailure(
  MapGameplayZone zone,
  String expected,
) =>
    semanticFailure(
      'gameplay_zone.payload_kind_mismatch',
      'The typed gameplay-zone payload is incompatible with the zone kind.',
      details: {
        'zoneId': zone.id,
        'actualKind': zone.kind.name,
        'expectedKind': expected,
      },
    );

MapData _setZonePayload(
  MapData map,
  String zoneId,
  GameplayZoneKind expected,
  Map<String, Object?> raw,
) {
  final zone = _zoneById(map, zoneId);
  if (zone.kind != expected) throw _zoneKindFailure(zone, expected.name);
  return switch (expected) {
    GameplayZoneKind.encounter => updateGameplayZoneOnMap(
        map,
        zoneId: zoneId,
        encounter: EncounterZonePayload.fromJson(raw.cast<String, dynamic>()),
      ),
    GameplayZoneKind.movement => updateGameplayZoneOnMap(
        map,
        zoneId: zoneId,
        movement: MovementZonePayload.fromJson(raw.cast<String, dynamic>()),
      ),
    GameplayZoneKind.movementEffect => updateGameplayZoneOnMap(
        map,
        zoneId: zoneId,
        movementEffect:
            MovementEffectZonePayload.fromJson(raw.cast<String, dynamic>()),
      ),
    GameplayZoneKind.hazard => updateGameplayZoneOnMap(
        map,
        zoneId: zoneId,
        hazard: HazardZonePayload.fromJson(raw.cast<String, dynamic>()),
      ),
    GameplayZoneKind.special ||
    GameplayZoneKind.custom =>
      throw _zoneKindFailure(zone, expected.name),
  };
}

Map<String, String> _patchProperties(
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
