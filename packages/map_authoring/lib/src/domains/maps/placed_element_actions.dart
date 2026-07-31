import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

final class PlacedElementActions {
  const PlacedElementActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const <(String, String)>[
      ('placed_element.place', 'Place a project element instance'),
      ('placed_element.batch_place', 'Place element instances atomically'),
      ('placed_element.update', 'Replace a placed element instance'),
      ('placed_element.clone', 'Clone a placed element instance'),
      ('placed_element.move', 'Move a placed element instance'),
      ('placed_element.rotate', 'Rotate a placed element instance'),
      ('placed_element.delete', 'Delete a placed element instance'),
      (
        'placed_element.replace_for_layer',
        'Replace all placed elements projected on one layer',
      ),
      ('placed_element.set_collision', 'Set instance collision participation'),
      ('placed_element.set_opacity', 'Set instance opacity'),
      ('placed_element.set_shadow_override', 'Set a shadow override'),
      ('placed_element.clear_shadow_override', 'Clear a shadow override'),
      ('placed_element.set_animation', 'Set instance animation'),
      ('placed_element.reset_animation', 'Reset instance animation'),
      ('placed_element.behavior_add', 'Add an instance behavior'),
      ('placed_element.behavior_update', 'Update an instance behavior'),
      ('placed_element.behavior_enable', 'Enable an instance behavior'),
      ('placed_element.behavior_disable', 'Disable an instance behavior'),
      ('placed_element.behavior_remove', 'Remove an instance behavior'),
      ('placed_element.patch_properties', 'Patch instance properties'),
      (
        'placed_element.detach_from_tile_projection',
        'Mark an instance as explicitly authored',
      ),
    ])
      semanticActionDescriptor(entry.$1, entry.$2),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'placed_element.place' || 'placed_element.update' => const {
          'instance',
          'instanceId',
        },
      'placed_element.batch_place' ||
      'placed_element.replace_for_layer' =>
        const {'instances', 'layerId'},
      'placed_element.clone' => const {'instanceId', 'newId', 'x', 'y'},
      'placed_element.move' => const {'instanceId', 'x', 'y'},
      'placed_element.rotate' => const {'instanceId', 'deltaQuarterTurns'},
      'placed_element.delete' ||
      'placed_element.clear_shadow_override' ||
      'placed_element.reset_animation' ||
      'placed_element.detach_from_tile_projection' =>
        const {'instanceId'},
      'placed_element.set_collision' => const {
          'instanceId',
          'applyCollision',
        },
      'placed_element.set_opacity' => const {'instanceId', 'opacity'},
      'placed_element.set_shadow_override' => const {
          'instanceId',
          'shadowOverride',
        },
      'placed_element.set_animation' => const {'instanceId', 'animation'},
      'placed_element.behavior_add' => const {'instanceId', 'behavior'},
      'placed_element.behavior_update' => const {
          'instanceId',
          'behaviorIndex',
          'behavior',
        },
      'placed_element.behavior_enable' ||
      'placed_element.behavior_disable' ||
      'placed_element.behavior_remove' =>
        const {
          'instanceId',
          'behaviorIndex',
        },
      'placed_element.patch_properties' => const {'instanceId', 'patch'},
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested placed-element action is unsupported.',
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
        case 'placed_element.place':
          final instance = _instance(parameters.object('instance'));
          if (context.map.placedElements
              .any((value) => value.id == instance.id)) {
            throw semanticFailure(
              'placed_element.exists',
              'A placed element already uses this ID.',
              details: {'instanceId': instance.id},
            );
          }
          _validateFootprint(context.manifest, context.map, instance);
          updated = upsertMapPlacedElement(context.map, instance: instance);
        case 'placed_element.batch_place':
          final instances = _instances(parameters.list('instances'));
          final ids = <String>{};
          for (final instance in instances) {
            if (!ids.add(instance.id) ||
                context.map.placedElements.any(
                  (value) => value.id == instance.id,
                )) {
              throw semanticFailure(
                'placed_element.batch_duplicate',
                'A batch instance ID is duplicated or already exists.',
                details: {'instanceId': instance.id},
              );
            }
            _validateFootprint(context.manifest, context.map, instance);
          }
          updated = context.map;
          for (final instance in instances) {
            updated = upsertMapPlacedElement(updated, instance: instance);
          }
          changedItems = instances.length;
        case 'placed_element.update':
          final instanceId = parameters.string('instanceId');
          _instanceById(context.map, instanceId);
          final replacement = _instance(parameters.object('instance'));
          _validateFootprint(context.manifest, context.map, replacement);
          final without = removeMapPlacedElement(
            context.map,
            instanceId: instanceId,
          );
          if (without.placedElements.any(
            (value) => value.id == replacement.id,
          )) {
            throw semanticFailure(
              'placed_element.exists',
              'A placed element already uses the replacement ID.',
            );
          }
          updated = upsertMapPlacedElement(without, instance: replacement);
        case 'placed_element.clone':
          final source = _instanceById(
            context.map,
            parameters.string('instanceId'),
          );
          final clone = source.copyWith(
            id: parameters.string('newId'),
            pos: GridPos(
              x: parameters.integer('x'),
              y: parameters.integer('y'),
            ),
          );
          _validateFootprint(context.manifest, context.map, clone);
          if (context.map.placedElements.any((value) => value.id == clone.id)) {
            throw semanticFailure(
              'placed_element.exists',
              'A placed element already uses the clone ID.',
            );
          }
          updated = upsertMapPlacedElement(context.map, instance: clone);
        case 'placed_element.move':
          final source = _instanceById(
            context.map,
            parameters.string('instanceId'),
          );
          final moved = source.copyWith(
            pos: GridPos(
              x: parameters.integer('x'),
              y: parameters.integer('y'),
            ),
          );
          _validateFootprint(context.manifest, context.map, moved);
          updated = upsertMapPlacedElement(context.map, instance: moved);
        case 'placed_element.rotate':
          updated = rotateMapPlacedElement(
            context.map,
            instanceId: parameters.string('instanceId'),
            deltaQuarterTurns: parameters.integer('deltaQuarterTurns'),
          );
          _validateFootprint(
            context.manifest,
            updated,
            _instanceById(updated, parameters.string('instanceId')),
          );
        case 'placed_element.delete':
          updated = removeMapPlacedElement(
            context.map,
            instanceId: parameters.string('instanceId'),
          );
        case 'placed_element.replace_for_layer':
          final layerId = parameters.string('layerId');
          final instances = _instances(parameters.list('instances'));
          if (instances.any((instance) => instance.layerId != layerId)) {
            throw semanticFailure(
              'placed_element.layer_mismatch',
              'Every replacement instance must target the requested layer.',
            );
          }
          for (final instance in instances) {
            _validateFootprint(context.manifest, context.map, instance);
          }
          updated = replaceMapPlacedElementsForLayer(
            context.map,
            layerId: layerId,
            instances: instances,
          );
          changedItems = instances.length;
        case 'placed_element.set_collision':
          updated = setMapPlacedElementCollisionApplied(
            context.map,
            instanceId: parameters.string('instanceId'),
            applyCollision: parameters.boolean('applyCollision'),
          );
        case 'placed_element.set_opacity':
          final opacity = parameters.value('opacity');
          if (opacity is! num || !opacity.isFinite) {
            throw invalidSemanticField('opacity', 'a finite number');
          }
          updated = setMapPlacedElementOpacity(
            context.map,
            instanceId: parameters.string('instanceId'),
            opacity: opacity.toDouble(),
          );
        case 'placed_element.set_shadow_override':
          updated = _replaceFromJsonPatch(
            context.map,
            parameters.string('instanceId'),
            {'shadowOverride': parameters.object('shadowOverride')},
          );
        case 'placed_element.clear_shadow_override':
          updated = setMapPlacedElementShadowOverride(
            context.map,
            instanceId: parameters.string('instanceId'),
            shadowOverride: null,
          );
        case 'placed_element.set_animation':
          updated = setMapPlacedElementAnimation(
            context.map,
            instanceId: parameters.string('instanceId'),
            animation: MapPlacedElementAnimation.fromJson(
              parameters.object('animation').cast<String, dynamic>(),
            ),
          );
        case 'placed_element.reset_animation':
          updated = resetMapPlacedElementAnimation(
            context.map,
            instanceId: parameters.string('instanceId'),
          );
        case 'placed_element.behavior_add':
          updated = addMapPlacedElementBehavior(
            context.map,
            instanceId: parameters.string('instanceId'),
            behavior: MapPlacedElementBehavior.fromJson(
              parameters.object('behavior').cast<String, dynamic>(),
            ),
          );
        case 'placed_element.behavior_update':
          updated = updateMapPlacedElementBehaviorAt(
            context.map,
            instanceId: parameters.string('instanceId'),
            behaviorIndex: parameters.integer('behaviorIndex'),
            behavior: MapPlacedElementBehavior.fromJson(
              parameters.object('behavior').cast<String, dynamic>(),
            ),
          );
        case 'placed_element.behavior_enable':
        case 'placed_element.behavior_disable':
          updated = setMapPlacedElementBehaviorEnabledAt(
            context.map,
            instanceId: parameters.string('instanceId'),
            behaviorIndex: parameters.integer('behaviorIndex'),
            enabled: actionId == 'placed_element.behavior_enable',
          );
        case 'placed_element.behavior_remove':
          updated = removeMapPlacedElementBehaviorAt(
            context.map,
            instanceId: parameters.string('instanceId'),
            behaviorIndex: parameters.integer('behaviorIndex'),
          );
        case 'placed_element.patch_properties':
          final instance = _instanceById(
            context.map,
            parameters.string('instanceId'),
          );
          updated = upsertMapPlacedElement(
            context.map,
            instance: instance.copyWith(
              properties: _patchProperties(
                instance.properties,
                parameters.object('patch'),
              ),
            ),
          );
        case 'placed_element.detach_from_tile_projection':
          final instance = _instanceById(
            context.map,
            parameters.string('instanceId'),
          );
          updated = upsertMapPlacedElement(
            context.map,
            instance: instance.copyWith(
              properties: {
                ...instance.properties,
                'pokemapPlacementOrigin': 'authored',
              },
            ),
          );
        default:
          throw StateError('unreachable placed-element action');
      }
    } on MapAuthoringException {
      rethrow;
    } on Object catch (error) {
      throw semanticFailure(
        'placed_element.mutation_invalid',
        'The placed-element mutation is invalid.',
        details: {'validationType': error.runtimeType.toString()},
      );
    }

    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: changedItems,
    );
  }
}

MapPlacedElement _instance(Map<String, Object?> value) {
  try {
    return MapPlacedElement.fromJson(value.cast<String, dynamic>());
  } on Object catch (error) {
    throw semanticFailure(
      'placed_element.payload_invalid',
      'The placed-element payload is invalid.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

List<MapPlacedElement> _instances(List<Object?> raw) {
  final result = <MapPlacedElement>[];
  for (var index = 0; index < raw.length; index++) {
    final value = raw[index];
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw invalidSemanticField('instances[$index]', 'a JSON object');
    }
    result.add(_instance(Map<String, Object?>.from(value)));
  }
  return result;
}

MapPlacedElement _instanceById(MapData map, String instanceId) {
  final instance = map.placedElements
      .where((candidate) => candidate.id == instanceId)
      .firstOrNull;
  if (instance == null) {
    throw semanticFailure(
      'placed_element.not_found',
      'The requested placed element does not exist.',
      details: {'instanceId': instanceId},
    );
  }
  return instance;
}

void _validateFootprint(
  ProjectManifest manifest,
  MapData map,
  MapPlacedElement instance,
) {
  final element = manifest.elements
      .where((candidate) => candidate.id == instance.elementId)
      .firstOrNull;
  if (element == null) {
    throw semanticFailure(
      'placed_element.element_missing',
      'The placed element references a missing project element.',
      details: {'elementId': instance.elementId},
    );
  }
  final footprint = resolveMapPlacedElementFootprint(
    instance: instance,
    element: element,
  );
  if (instance.pos.x < 0 ||
      instance.pos.y < 0 ||
      instance.pos.x + footprint.destinationSize.width > map.size.width ||
      instance.pos.y + footprint.destinationSize.height > map.size.height) {
    throw semanticFailure(
      'placed_element.footprint_out_of_bounds',
      'The placed-element footprint is outside map bounds.',
      details: {
        'instanceId': instance.id,
        'x': instance.pos.x,
        'y': instance.pos.y,
        'width': footprint.destinationSize.width,
        'height': footprint.destinationSize.height,
      },
    );
  }
}

MapData _replaceFromJsonPatch(
  MapData map,
  String instanceId,
  Map<String, Object?> patch,
) {
  final instance = _instanceById(map, instanceId);
  final json = instance.toJson()..addAll(patch);
  return upsertMapPlacedElement(
    map,
    instance: MapPlacedElement.fromJson(json),
  );
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
