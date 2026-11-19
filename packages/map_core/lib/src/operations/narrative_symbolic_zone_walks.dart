part of 'narrative_symbolic_reachability_solver.dart';

typedef _SymbolicZoneMove = ({
  GridPos cell,
  List<NarrativeEventSourceRef> entered,
});

GridPos? _symbolicZoneSpawnCell(MapData map, String? preferredSpawnId) {
  final preferred = preferredSpawnId?.trim();
  final spawnId = preferred != null && preferred.isNotEmpty
      ? preferred
      : map.mapMetadata.defaultSpawnId?.trim();
  final spawns = map.entities.where(
    (entity) => entity.kind == MapEntityKind.spawn,
  );
  if (spawnId != null && spawnId.isNotEmpty) {
    return spawns.where((entity) => entity.id == spawnId).firstOrNull?.pos;
  }
  final playerStarts =
      spawns
          .where((entity) => entity.spawn?.role == EntitySpawnRole.playerStart)
          .toList()
        ..sort((left, right) => left.id.compareTo(right.id));
  if (playerStarts.isNotEmpty) return playerStarts.first.pos;
  final spatial = map.spatialScene?.navigation.spawn;
  return spatial == null
      ? null
      : GridPos(x: spatial.x.floor(), y: spatial.z.floor());
}

Map<NarrativeEventSourceRef, _SymbolicZoneWalk> _symbolicZoneWalks(
  MapData map,
  Map<NarrativeEventSourceRef, MapRect> areas,
) {
  final remaining = areas.keys.toSet();
  final walks = <NarrativeEventSourceRef, _SymbolicZoneWalk>{};
  _SymbolicZoneCollisions? collisions;
  while (remaining.isNotEmpty) {
    final first = remaining.first;
    remaining.remove(first);
    final cluster = [first];
    for (var i = 0; i < cluster.length; i++) {
      final area = areas[cluster[i]]!;
      final connected = remaining
          .where((source) => _zonesOverlap(area, areas[source]!))
          .toList();
      cluster.addAll(connected);
      remaining.removeAll(connected);
    }
    if (cluster.every((source) => areas[source] == areas[first])) continue;
    cluster.sort(
      (left, right) =>
          compareNarrativeEventUtf16(_triggerId(left), _triggerId(right)),
    );
    final walk = _SymbolicZoneWalk(map, {
      for (final source in cluster) source: areas[source]!,
    }, collisions ??= _SymbolicZoneCollisions(map));
    for (final source in cluster) {
      walks[source] = walk;
    }
  }
  return walks;
}

bool _zonesOverlap(MapRect a, MapRect b) =>
    a.pos.x < b.pos.x + b.size.width &&
    b.pos.x < a.pos.x + a.size.width &&
    a.pos.y < b.pos.y + b.size.height &&
    b.pos.y < a.pos.y + a.size.height;

bool _zoneContains(MapRect area, GridPos position) =>
    position.x >= area.pos.x &&
    position.x < area.pos.x + area.size.width &&
    position.y >= area.pos.y &&
    position.y < area.pos.y + area.size.height;

bool _zoneHasExteriorCell(MapData map, MapRect area) =>
    !_zoneContains(area, const GridPos(x: 0, y: 0)) ||
    !_zoneContains(
      area,
      GridPos(x: map.size.width - 1, y: map.size.height - 1),
    );

final class _SymbolicZoneCollisions {
  _SymbolicZoneCollisions(MapData map) : _width = map.size.width {
    if (map.spatialScene != null) return;
    final cells = _width * map.size.height;
    for (final layer in map.layers.whereType<CollisionLayer>()) {
      final mask = layer.collisions;
      for (var i = 0; i < cells && i < mask.length; i++) {
        if (mask[i]) _blocked.add(i);
      }
    }
    for (final index in _blocked) {
      final x = index % _width;
      final y = index ~/ _width;
      if (x == 0 || !_blocked.contains(index - 1)) xCuts.add(x);
      if (x + 1 == _width || !_blocked.contains(index + 1)) xCuts.add(x + 1);
      if (!_blocked.contains(index - _width)) yCuts.add(y);
      if (!_blocked.contains(index + _width)) yCuts.add(y + 1);
    }
  }

  final int _width;
  final _blocked = <int>{};
  final xCuts = <int>{};
  final yCuts = <int>{};

  bool blocks(GridPos cell) => _blocked.contains(cell.y * _width + cell.x);
}

final class _SymbolicZoneWalk {
  _SymbolicZoneWalk(this.map, this.areas, this._collisions)
    : _x = _cuts(
        map.size.width,
        areas.values,
        _collisions.xCuts,
        horizontal: true,
      ),
      _y = _cuts(
        map.size.height,
        areas.values,
        _collisions.yCuts,
        horizontal: false,
      );

  final MapData map;
  final Map<NarrativeEventSourceRef, MapRect> areas;
  final _SymbolicZoneCollisions _collisions;
  final List<int> _x;
  final List<int> _y;
  final _coverage = <GridPos, List<NarrativeEventSourceRef>>{};
  final _moves = <GridPos?, List<_SymbolicZoneMove>>{};

  String get footprintKey => '${map.id}:${_triggerId(areas.keys.first)}';

  bool fitsExplorationBudget(int budget) =>
      (_x.length - 1) * (_y.length - 1) <= budget;

  List<_SymbolicZoneMove> movesFrom(GridPos? cell) {
    final start = cell == null || !_isCellInMap(map, cell)
        ? null
        : GridPos(
            x: _x.lastIndexWhere((edge) => edge <= cell.x),
            y: _y.lastIndexWhere((edge) => edge <= cell.y),
          );
    return _moves.putIfAbsent(start, () => _findMoves(start));
  }

  List<_SymbolicZoneMove> _findMoves(GridPos? start) {
    if (start != null && _collisions.blocks(_anchor(start))) return const [];
    final previous = start == null
        ? const <NarrativeEventSourceRef>[]
        : _zonesAt(start);
    final pending = start == null ? _outsideRegions() : [start];
    final seen = pending.toSet();
    final moves = <_SymbolicZoneMove>[];
    for (var i = 0; i < pending.length; i++) {
      for (final adjacent in _neighbors(pending[i])) {
        if (_collisions.blocks(_anchor(adjacent)) || !seen.add(adjacent)) {
          continue;
        }
        final targets = _zonesAt(adjacent);
        final entered = targets
            .where((target) => !previous.contains(target))
            .toList();
        if (entered.isEmpty && targets.length == previous.length) {
          pending.add(adjacent);
        } else {
          moves.add((cell: _anchor(adjacent), entered: entered));
        }
      }
    }
    return moves;
  }

  List<GridPos> _outsideRegions() => [
    for (var x = 0; x < _x.length - 1; x++)
      for (var y = 0; y < _y.length - 1; y++)
        if (x == 0 || y == 0 || x == _x.length - 2 || y == _y.length - 2)
          if (_zonesAt(GridPos(x: x, y: y)).isEmpty &&
              !_collisions.blocks(_anchor(GridPos(x: x, y: y))))
            GridPos(x: x, y: y),
  ];

  Iterable<GridPos> _neighbors(GridPos region) sync* {
    final GridPos(:x, :y) = region;
    if (x > 0) yield GridPos(x: x - 1, y: y);
    if (x < _x.length - 2) yield GridPos(x: x + 1, y: y);
    if (y > 0) yield GridPos(x: x, y: y - 1);
    if (y < _y.length - 2) yield GridPos(x: x, y: y + 1);
  }

  GridPos _anchor(GridPos region) => GridPos(x: _x[region.x], y: _y[region.y]);

  List<NarrativeEventSourceRef> _zonesAt(GridPos region) =>
      _coverage.putIfAbsent(region, () {
        final anchor = _anchor(region);
        return [
          for (final entry in areas.entries)
            if (_zoneContains(entry.value, anchor)) entry.key,
        ];
      });

  static List<int> _cuts(
    int mapLength,
    Iterable<MapRect> areas,
    Iterable<int> collisionCuts, {
    required bool horizontal,
  }) {
    final edges = <int>{0, mapLength, ...collisionCuts};
    for (final area in areas) {
      final left = horizontal ? area.pos.x : area.pos.y;
      final span = horizontal ? area.size.width : area.size.height;
      edges.add(left.clamp(0, mapLength));
      edges.add((left + span).clamp(0, mapLength));
    }
    return edges.toList()..sort();
  }
}
