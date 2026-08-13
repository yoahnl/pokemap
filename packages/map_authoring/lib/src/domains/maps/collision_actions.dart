import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../support/authoring_performance_observer.dart';
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
  const EffectiveCollisionInspector({this.performanceObserver});

  final AuthoringPerformanceObserver? performanceObserver;

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
      if (mask != null) {
        performanceObserver?.incrementCounter(
          AuthoringPerformanceCounterName.base64Decode,
        );
      }
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
