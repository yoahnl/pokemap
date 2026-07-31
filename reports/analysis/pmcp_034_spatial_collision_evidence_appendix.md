# PMCP-034 — Annexe des fichiers créés

Cette annexe reproduit intégralement les fichiers source et test créés par le lot.

## `packages/map_authoring/lib/src/domains/maps/collision_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';

enum CollisionProvenanceKind {
  collisionLayer,
  placedElementProfile,
  placedElementPixelMask,
  blockingEntity,
}

final class CollisionContribution {
  const CollisionContribution({
    required this.kind,
    required this.sourceId,
    this.layerId,
    this.elementId,
  });

  final CollisionProvenanceKind kind;
  final String sourceId;
  final String? layerId;
  final String? elementId;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'sourceId': sourceId,
        if (layerId != null) 'layerId': layerId,
        if (elementId != null) 'elementId': elementId,
      };
}

final class EffectiveCollisionCell {
  EffectiveCollisionCell({
    required this.pos,
    required Iterable<CollisionContribution> contributions,
  }) : contributions = List.unmodifiable(contributions);

  final GridPos pos;
  final List<CollisionContribution> contributions;

  bool get isBlocked => contributions.isNotEmpty;

  Map<String, Object?> toJson() => {
        'x': pos.x,
        'y': pos.y,
        'isBlocked': isBlocked,
        'contributions': contributions.map((value) => value.toJson()).toList(),
      };
}

final class EffectiveCollisionRegion {
  EffectiveCollisionRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required Iterable<EffectiveCollisionCell> cells,
  }) : cells = List.unmodifiable(cells);

  final int x;
  final int y;
  final int width;
  final int height;
  final List<EffectiveCollisionCell> cells;

  int get blockedCellCount => cells.where((cell) => cell.isBlocked).length;
}

final class CollisionReachabilityReport {
  CollisionReachabilityReport({
    required this.start,
    required this.reachableCellCount,
    required Iterable<GridPos> unreachableExits,
    required Iterable<GridPos> reachableExits,
  })  : unreachableExits = List.unmodifiable(unreachableExits),
        reachableExits = List.unmodifiable(reachableExits);

  final GridPos start;
  final int reachableCellCount;
  final List<GridPos> unreachableExits;
  final List<GridPos> reachableExits;

  bool get isValid => unreachableExits.isEmpty;

  Map<String, Object?> toJson() => {
        'start': {'x': start.x, 'y': start.y},
        'reachableCellCount': reachableCellCount,
        'isValid': isValid,
        'reachableExits': [
          for (final pos in reachableExits) {'x': pos.x, 'y': pos.y},
        ],
        'unreachableExits': [
          for (final pos in unreachableExits) {'x': pos.x, 'y': pos.y},
        ],
      };
}

final class CollisionWalkabilityReport {
  CollisionWalkabilityReport({
    required this.walkableCellCount,
    required Iterable<int> componentSizes,
  }) : componentSizes = List.unmodifiable(componentSizes);

  final int walkableCellCount;
  final List<int> componentSizes;

  int get componentCount => componentSizes.length;
  bool get isFullyConnected => componentCount <= 1;

  Map<String, Object?> toJson() => {
        'walkableCellCount': walkableCellCount,
        'componentCount': componentCount,
        'componentSizes': componentSizes,
        'isFullyConnected': isFullyConnected,
      };
}

/// Computes the same cell-level collision sources consumed by gameplay.
final class EffectiveCollisionInspector {
  const EffectiveCollisionInspector();

  EffectiveCollisionCell queryAt({
    required ProjectManifest manifest,
    required MapData map,
    required GridPos pos,
  }) {
    _requireInBounds(map, pos);
    final contributions = _buildIndex(manifest, map)[pos] ?? const [];
    return EffectiveCollisionCell(pos: pos, contributions: contributions);
  }

  EffectiveCollisionCell explainProvenance({
    required ProjectManifest manifest,
    required MapData map,
    required GridPos pos,
  }) =>
      queryAt(manifest: manifest, map: map, pos: pos);

  EffectiveCollisionRegion queryRegion({
    required ProjectManifest manifest,
    required MapData map,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    _requireRegion(map, x: x, y: y, width: width, height: height);
    final index = _buildIndex(manifest, map);
    return EffectiveCollisionRegion(
      x: x,
      y: y,
      width: width,
      height: height,
      cells: [
        for (var row = y; row < y + height; row++)
          for (var column = x; column < x + width; column++)
            EffectiveCollisionCell(
              pos: GridPos(x: column, y: row),
              contributions: index[GridPos(x: column, y: row)] ?? const [],
            ),
      ],
    );
  }

  EffectiveCollisionRegion previewPlayerHitbox({
    required ProjectManifest manifest,
    required MapData map,
    required MapRect hitbox,
  }) =>
      queryRegion(
        manifest: manifest,
        map: map,
        x: hitbox.pos.x,
        y: hitbox.pos.y,
        width: hitbox.size.width,
        height: hitbox.size.height,
      );

  CollisionWalkabilityReport validateWalkability({
    required ProjectManifest manifest,
    required MapData map,
  }) {
    final blocked = _buildIndex(manifest, map).keys.toSet();
    final remaining = <GridPos>{
      for (var y = 0; y < map.size.height; y++)
        for (var x = 0; x < map.size.width; x++)
          if (!blocked.contains(GridPos(x: x, y: y))) GridPos(x: x, y: y),
    };
    final sizes = <int>[];
    while (remaining.isNotEmpty) {
      final start = remaining.reduce((left, right) {
        final byY = left.y.compareTo(right.y);
        return byY < 0 || (byY == 0 && left.x <= right.x) ? left : right;
      });
      final queue = <GridPos>[start];
      remaining.remove(start);
      var cursor = 0;
      while (cursor < queue.length) {
        final current = queue[cursor++];
        for (final next in <GridPos>[
          GridPos(x: current.x, y: current.y - 1),
          GridPos(x: current.x - 1, y: current.y),
          GridPos(x: current.x + 1, y: current.y),
          GridPos(x: current.x, y: current.y + 1),
        ]) {
          if (remaining.remove(next)) queue.add(next);
        }
      }
      sizes.add(queue.length);
    }
    sizes.sort((left, right) => right.compareTo(left));
    return CollisionWalkabilityReport(
      walkableCellCount: sizes.fold(0, (sum, value) => sum + value),
      componentSizes: sizes,
    );
  }

  CollisionReachabilityReport validateReachability({
    required ProjectManifest manifest,
    required MapData map,
    required GridPos start,
    required List<GridPos> exits,
  }) {
    _requireInBounds(map, start);
    for (final exit in exits) {
      _requireInBounds(map, exit);
    }
    final blocked = _buildIndex(manifest, map).keys.toSet();
    final visited = <GridPos>{};
    final queue = <GridPos>[];
    if (!blocked.contains(start)) {
      visited.add(start);
      queue.add(start);
    }
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      for (final next in <GridPos>[
        GridPos(x: current.x, y: current.y - 1),
        GridPos(x: current.x - 1, y: current.y),
        GridPos(x: current.x + 1, y: current.y),
        GridPos(x: current.x, y: current.y + 1),
      ]) {
        if (next.x < 0 ||
            next.y < 0 ||
            next.x >= map.size.width ||
            next.y >= map.size.height ||
            blocked.contains(next) ||
            !visited.add(next)) {
          continue;
        }
        queue.add(next);
      }
    }
    return CollisionReachabilityReport(
      start: start,
      reachableCellCount: visited.length,
      reachableExits: [
        for (final exit in exits)
          if (visited.contains(exit)) exit
      ],
      unreachableExits: [
        for (final exit in exits)
          if (!visited.contains(exit)) exit,
      ],
    );
  }

  Map<GridPos, List<CollisionContribution>> _buildIndex(
    ProjectManifest manifest,
    MapData map,
  ) {
    final mutable = <GridPos, List<CollisionContribution>>{};
    void add(GridPos pos, CollisionContribution contribution) {
      if (pos.x < 0 ||
          pos.y < 0 ||
          pos.x >= map.size.width ||
          pos.y >= map.size.height) {
        return;
      }
      mutable.putIfAbsent(pos, () => []).add(contribution);
    }

    for (final layer in map.layers.whereType<CollisionLayer>()) {
      final cellCount = map.size.width * map.size.height;
      final limit = layer.collisions.length < cellCount
          ? layer.collisions.length
          : cellCount;
      for (var index = 0; index < limit; index++) {
        if (!layer.collisions[index]) continue;
        add(
          GridPos(x: index % map.size.width, y: index ~/ map.size.width),
          CollisionContribution(
            kind: CollisionProvenanceKind.collisionLayer,
            sourceId: layer.id,
            layerId: layer.id,
          ),
        );
      }
    }

    final elementById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    for (final instance in map.placedElements) {
      if (!instance.applyCollision) continue;
      final element = elementById[instance.elementId];
      final profile = element?.collisionProfile;
      if (element == null || profile == null) continue;
      final footprint = resolveMapPlacedElementFootprint(
        instance: instance,
        element: element,
      );
      final mask = profile.collisionMask;
      final sourceCells = mask == null
          ? profile.cells
          : ElementCollisionMaskCodec.cellsFromPixelMask(
              mask: mask,
              tileWidth: manifest.settings.tileWidth,
              tileHeight: manifest.settings.tileHeight,
              sourceWidthInTiles: footprint.sourceSize.width,
              sourceHeightInTiles: footprint.sourceSize.height,
            );
      for (final sourceCell in sourceCells) {
        final destination = footprint.sourceToDestination(sourceCell);
        add(
          GridPos(
            x: instance.pos.x + destination.x,
            y: instance.pos.y + destination.y,
          ),
          CollisionContribution(
            kind: mask == null
                ? CollisionProvenanceKind.placedElementProfile
                : CollisionProvenanceKind.placedElementPixelMask,
            sourceId: instance.id,
            layerId: instance.layerId,
            elementId: instance.elementId,
          ),
        );
      }
    }

    for (final entity in map.entities) {
      if (!entity.blocksMovement || entity.kind == MapEntityKind.spawn) {
        continue;
      }
      for (final cell in resolveEntityCollisionCells(entity)) {
        add(
          cell,
          CollisionContribution(
            kind: CollisionProvenanceKind.blockingEntity,
            sourceId: entity.id,
          ),
        );
      }
    }
    final immutable = <GridPos, List<CollisionContribution>>{};
    for (final entry in mutable.entries) {
      entry.value.sort((left, right) {
        final byKind = left.kind.index.compareTo(right.kind.index);
        return byKind != 0 ? byKind : left.sourceId.compareTo(right.sourceId);
      });
      immutable[entry.key] = List.unmodifiable(entry.value);
    }
    return Map.unmodifiable(immutable);
  }
}

final class CollisionActions {
  const CollisionActions({
    EffectiveCollisionInspector inspector = const EffectiveCollisionInspector(),
  }) : _inspector = inspector;

  final EffectiveCollisionInspector _inspector;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor(
      'collision_layer.paint',
      'Paint a collision-layer region',
    ),
    semanticActionDescriptor(
      'collision_layer.erase',
      'Erase a collision-layer region',
    ),
    semanticActionDescriptor(
      'collision_layer.fill',
      'Fill an entire collision layer',
    ),
    semanticActionDescriptor(
      'collision_layer.clear',
      'Clear an entire collision layer',
    ),
    semanticActionDescriptor(
      'collision_layer.invert',
      'Invert an entire collision layer',
    ),
    semanticActionDescriptor(
      'collision_layer.replace_region',
      'Replace a collision-layer region from typed booleans',
    ),
    semanticActionDescriptor(
      'collision_layer.generate_from_elements_apply',
      'Generate collision-layer truth from placed elements and entities',
    ),
    semanticActionDescriptor(
      'collision_layer.merge_apply',
      'Merge collision layers atomically',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'collision_layer.paint' || 'collision_layer.erase' => const {
          'layerId',
          'x',
          'y',
          'width',
          'height',
        },
      'collision_layer.fill' ||
      'collision_layer.clear' ||
      'collision_layer.invert' ||
      'collision_layer.generate_from_elements_apply' =>
        const {'layerId'},
      'collision_layer.replace_region' => const {
          'layerId',
          'x',
          'y',
          'width',
          'height',
          'values',
        },
      'collision_layer.merge_apply' => const {
          'layerId',
          'sourceLayerIds',
          'mode',
        },
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested collision action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    final layerId = parameters.string('layerId');
    late MapData updated;
    var changedItems = context.map.size.width * context.map.size.height;

    switch (actionId) {
      case 'collision_layer.paint':
      case 'collision_layer.erase':
        final width = parameters.integer('width');
        final height = parameters.integer('height');
        updated = actionId == 'collision_layer.paint'
            ? paintCollisionPatternOnLayer(
                context.map,
                layerId: layerId,
                pos: GridPos(
                  x: parameters.integer('x'),
                  y: parameters.integer('y'),
                ),
                patternSize: GridSize(width: width, height: height),
                clipToMapBounds: false,
              )
            : eraseCollisionPatternOnLayer(
                context.map,
                layerId: layerId,
                pos: GridPos(
                  x: parameters.integer('x'),
                  y: parameters.integer('y'),
                ),
                patternSize: GridSize(width: width, height: height),
                clipToMapBounds: false,
              );
        changedItems = width * height;
      case 'collision_layer.fill':
      case 'collision_layer.clear':
      case 'collision_layer.invert':
        final layer = _collisionLayer(context.map, layerId);
        final value = actionId == 'collision_layer.fill';
        final collisions = switch (actionId) {
          'collision_layer.invert' => [
              for (final cell in _normalizedCells(context.map, layer)) !cell,
            ],
          _ => List<bool>.filled(
              context.map.size.width * context.map.size.height,
              value,
            ),
        };
        updated = _replaceCollisionLayer(context.map, layer, collisions);
      case 'collision_layer.replace_region':
        final layer = _collisionLayer(context.map, layerId);
        final x = parameters.integer('x');
        final y = parameters.integer('y');
        final width = parameters.integer('width');
        final height = parameters.integer('height');
        _requireRegion(
          context.map,
          x: x,
          y: y,
          width: width,
          height: height,
        );
        final raw = parameters.list('values');
        if (raw.length != width * height ||
            raw.any((value) => value is! bool)) {
          throw invalidSemanticField(
            'values',
            'exactly width * height booleans',
          );
        }
        final collisions = _normalizedCells(context.map, layer);
        for (var row = 0; row < height; row++) {
          for (var column = 0; column < width; column++) {
            collisions[(y + row) * context.map.size.width + x + column] =
                raw[row * width + column]! as bool;
          }
        }
        updated = _replaceCollisionLayer(context.map, layer, collisions);
        changedItems = width * height;
      case 'collision_layer.generate_from_elements_apply':
        final layer = _collisionLayer(context.map, layerId);
        final collisions = List<bool>.filled(
          context.map.size.width * context.map.size.height,
          false,
        );
        final region = _inspector.queryRegion(
          manifest: context.manifest,
          map: context.map,
          x: 0,
          y: 0,
          width: context.map.size.width,
          height: context.map.size.height,
        );
        for (final cell in region.cells) {
          collisions[cell.pos.y * context.map.size.width + cell.pos.x] =
              cell.contributions.any(
            (source) => source.kind != CollisionProvenanceKind.collisionLayer,
          );
        }
        updated = _replaceCollisionLayer(context.map, layer, collisions);
      case 'collision_layer.merge_apply':
        final target = _collisionLayer(context.map, layerId);
        final rawIds = parameters.list('sourceLayerIds');
        if (rawIds.isEmpty || rawIds.any((value) => value is! String)) {
          throw invalidSemanticField('sourceLayerIds', 'nonempty layer IDs');
        }
        final sources = [
          for (final id in rawIds.cast<String>())
            _normalizedCells(context.map, _collisionLayer(context.map, id)),
        ];
        final mode = parameters.string('mode');
        if (!const {'union', 'intersection', 'replace'}.contains(mode)) {
          throw invalidSemanticField(
            'mode',
            '"union", "intersection", or "replace"',
          );
        }
        final current = _normalizedCells(context.map, target);
        final merged = List<bool>.generate(current.length, (index) {
          return switch (mode) {
            'union' => current[index] || sources.any((source) => source[index]),
            'intersection' =>
              current[index] && sources.every((source) => source[index]),
            'replace' => sources.any((source) => source[index]),
            _ => false,
          };
        });
        updated = _replaceCollisionLayer(context.map, target, merged);
      default:
        throw StateError('unreachable collision action');
    }
    return context.draftMap(
      after: updated,
      operation: actionId,
      changedItems: changedItems,
      layerId: layerId,
    );
  }
}

CollisionLayer _collisionLayer(MapData map, String layerId) {
  final layer =
      map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
  if (layer is! CollisionLayer) {
    throw semanticFailure(
      'collision.layer_missing',
      'The requested layer is missing or is not a Collision layer.',
      details: {'layerId': layerId},
    );
  }
  return layer;
}

List<bool> _normalizedCells(MapData map, CollisionLayer layer) {
  final cells = List<bool>.filled(map.size.width * map.size.height, false);
  for (var index = 0;
      index < cells.length && index < layer.collisions.length;
      index++) {
    cells[index] = layer.collisions[index];
  }
  return cells;
}

MapData _replaceCollisionLayer(
  MapData map,
  CollisionLayer target,
  List<bool> collisions,
) =>
    map.copyWith(
      layers: [
        for (final layer in map.layers)
          if (identical(layer, target))
            target.copyWith(collisions: collisions)
          else
            layer,
      ],
    );

void _requireInBounds(MapData map, GridPos pos) {
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= map.size.width ||
      pos.y >= map.size.height) {
    throw semanticFailure(
      'collision.position_out_of_bounds',
      'The collision query position is outside map bounds.',
      details: {'x': pos.x, 'y': pos.y},
    );
  }
}

void _requireRegion(
  MapData map, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  if (x < 0 ||
      y < 0 ||
      width <= 0 ||
      height <= 0 ||
      x + width > map.size.width ||
      y + height > map.size.height) {
    throw semanticFailure(
      'collision.region_out_of_bounds',
      'The collision region is outside map bounds.',
      details: {'x': x, 'y': y, 'width': width, 'height': height},
    );
  }
}
```

## `packages/map_authoring/lib/src/domains/maps/entity_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/maps/trigger_zone_actions.dart`

```dart
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
```

## `packages/map_authoring/test/domains/maps/effective_collision_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EffectiveCollisionInspector', () {
    test('explains layer, placed-element profile and entity provenance', () {
      final fixture = _collisionFixture();
      const inspector = EffectiveCollisionInspector();

      expect(
        inspector
            .queryAt(
              manifest: fixture.manifest,
              map: fixture.map,
              pos: const GridPos(x: 0, y: 0),
            )
            .contributions
            .single
            .kind,
        CollisionProvenanceKind.collisionLayer,
      );
      expect(
        inspector
            .queryAt(
              manifest: fixture.manifest,
              map: fixture.map,
              pos: const GridPos(x: 1, y: 0),
            )
            .contributions
            .single
            .kind,
        CollisionProvenanceKind.placedElementProfile,
      );
      expect(
        inspector
            .queryAt(
              manifest: fixture.manifest,
              map: fixture.map,
              pos: const GridPos(x: 2, y: 0),
            )
            .contributions
            .single
            .kind,
        CollisionProvenanceKind.blockingEntity,
      );
    });

    test('reachability reports an exit isolated by effective collision', () {
      final collisions = <bool>[
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
      ];
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: [
          MapLayer.collision(
            id: 'walls',
            name: 'Walls',
            collisions: collisions,
          ),
        ],
      );

      final report = const EffectiveCollisionInspector().validateReachability(
        manifest: _manifest(),
        map: map,
        start: const GridPos(x: 0, y: 0),
        exits: const [GridPos(x: 2, y: 2)],
      );

      expect(report.isValid, isFalse);
      expect(report.unreachableExits, const [GridPos(x: 2, y: 2)]);
      expect(report.reachableCellCount, 3);

      final walkability =
          const EffectiveCollisionInspector().validateWalkability(
        manifest: _manifest(),
        map: map,
      );
      expect(walkability.isFullyConnected, isFalse);
      expect(walkability.componentCount, 2);
      expect(walkability.componentSizes, const [3, 3]);
    });
  });
}

({ProjectManifest manifest, MapData map}) _collisionFixture() {
  final manifest = _manifest(
    elements: const [
      ProjectElementEntry(
        id: 'rock',
        name: 'Rock',
        tilesetId: 'nature',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
        collisionProfile: ElementCollisionProfile(
          cells: [GridPos(x: 0, y: 0)],
        ),
      ),
    ],
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 3),
    layers: [
      MapLayer.collision(
        id: 'manual',
        name: 'Manual',
        collisions: const [
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'rock-instance',
        layerId: 'decor',
        elementId: 'rock',
        pos: GridPos(x: 1, y: 0),
      ),
    ],
    entities: const [
      MapEntity(
        id: 'blocker',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 0),
      ),
    ],
  );
  return (manifest: manifest, map: map);
}

ProjectManifest _manifest({
  List<ProjectElementEntry> elements = const [],
}) =>
    ProjectManifest(
      name: 'Collision test',
      maps: const [],
      tilesets: const [],
      elements: elements,
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );
```

## `packages/map_authoring/test/domains/maps/spatial_object_contract_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('spatial object contracts', () {
    test('entity payload incompatible with kind is refused', () {
      const entity = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 0, y: 0),
        sign: MapEntitySignData(plainText: 'wrong payload'),
      );

      expect(
        () => const EntityActions().create(_emptyMap(), entity),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'entity.payload_kind_mismatch',
          ),
        ),
      );
    });

    test('batch move is atomic when one entity would leave map bounds', () {
      final map = _emptyMap().copyWith(
        entities: const [
          MapEntity(
            id: 'first',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 0, y: 0),
          ),
          MapEntity(
            id: 'second',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      expect(
        () => const EntityActions().moveBatch(
          map,
          const {
            'first': GridPos(x: 1, y: 1),
            'second': GridPos(x: 4, y: 4),
          },
        ),
        throwsA(isA<MapAuthoringException>()),
      );
      expect(map.entities[0].pos, const GridPos(x: 0, y: 0));
      expect(map.entities[1].pos, const GridPos(x: 2, y: 2));
    });

    test('dispatcher exposes placed, entity, NPC, trigger and zone actions',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'placed_element.place',
          'placed_element.move',
          'placed_element.delete',
          'entity.create',
          'entity.batch_move',
          'entity.delete',
          'npc.set_dialogue',
          'npc.set_visibility_rule',
          'npc.set_movement_mode',
          'npc.waypoint_add',
          'trigger.create',
          'trigger.delete_apply',
          'gameplay_zone.create',
          'gameplay_zone.set_hazard_payload',
          'gameplay_zone.delete',
        }),
      );
    });
  });
}

MapData _emptyMap() => const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 4, height: 4),
    );
```
