import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

final class SourceEncounterTerrainBindingResult {
  SourceEncounterTerrainBindingResult._(
      Map<int, List<MapGameplayZone>> zones, Map<String, Object?> evidence)
      : zonesBySourceMapId = Map.unmodifiable(zones.map((id, values) =>
            MapEntry(id, List<MapGameplayZone>.unmodifiable(values)))),
        evidence = Map.unmodifiable(evidence);

  final Map<int, List<MapGameplayZone>> zonesBySourceMapId;
  final Map<String, Object?> evidence;
}

final class SourceEncounterTerrainBinding {
  const SourceEncounterTerrainBinding();

  SourceEncounterTerrainBindingResult bind({
    required NormalizedSourceProject source,
    required Map<int, String> nativeMapIds,
    required Map<int, Map<String, String>> tableIdsBySourceMethod,
    Sha256Hash? expectedSourceSelectionHash,
  }) {
    final semantic = SourceSemanticResolver.forProject(source);
    if (!semantic.profile.isQualified ||
        (expectedSourceSelectionHash != null &&
            expectedSourceSelectionHash != source.canonicalHash)) {
      throw const FormatException(
          'Encounter terrain requires its attested source selection');
    }
    final maps = {for (final ir in source.maps) ir.map.sourceMapId: ir};
    if (nativeMapIds.isEmpty ||
        nativeMapIds.length > 2048 ||
        nativeMapIds.values.toSet().length != nativeMapIds.length ||
        nativeMapIds.entries.any((entry) =>
            !maps.containsKey(entry.key) ||
            entry.value.isEmpty ||
            entry.value.trim() != entry.value ||
            entry.value.length > 256) ||
        tableIdsBySourceMethod.keys
            .any((id) => !nativeMapIds.containsKey(id))) {
      throw const FormatException(
          'Encounter terrain requires bounded unique selected map identities');
    }
    final resolver = SourceEncounterTerrainResolver(resolver: semantic);
    final allZones = <int, List<MapGameplayZone>>{};
    final evidenceMaps = <Map<String, Object?>>[];
    final interactiveMethods = <Map<String, Object?>>[];
    final sortedIds = nativeMapIds.keys.toList()..sort();
    for (final id in sortedIds) {
      final sourceMap = maps[id]!.map;
      final methods = tableIdsBySourceMethod[id] ?? const <String, String>{};
      for (final method in methods.entries) {
        if (const {'LandDay', 'LandNight', 'LandMorning'}
            .contains(method.key)) {
          throw ContractError(
              'source_encounter_terrain.time_method_unqualified',
              '\$.tableIdsBySourceMethod.$id.${method.key}',
              'Time-specific encounter methods require qualified time conditions');
        }
        final identity = SourcePbsIdentity(
            namespace: source.snapshot.logicalProjectNamespace,
            family: SourcePbsFamily.encounters,
            sourceMapId: id);
        final expected = 'source-native-encounter-${canonicalHashOf({
              'sourceIdentity': identity.toJson(),
              'method': method.key,
            }).value.substring(0, 24)}';
        if ((!_kinds.containsKey(method.key) && method.key != 'RockSmash') ||
            method.value != expected) {
          throw const FormatException(
              'Encounter table is not bound to its source map and method');
        }
        if (method.key == 'RockSmash') {
          interactiveMethods.add({
            'sourceMapId': id,
            'nativeMapId': nativeMapIds[id],
            'method': method.key,
            'nativeTableId': method.value
          });
        }
      }
      final land = <GridPos>[];
      final cave = <GridPos>[];
      final water = <GridPos>[];
      final surfRequiredCells = <GridPos>[];
      final unknown = <GridPos>[];
      final terrainCounts = <String, int>{};
      var rawWater = 0;
      for (var y = 0; y < sourceMap.height; y++) {
        for (var x = 0; x < sourceMap.width; x++) {
          final cell = semantic.cellAt(id, x, y);
          final tag = resolver.resolveTerrainTag(cell);
          final key = tag?.toString() ?? 'unknown';
          terrainCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
          final pos = GridPos(x: x, y: y);
          if (tag == null) {
            unknown.add(pos);
            continue;
          }
          final walk = semantic.resolveConnectionEntryTile(cell);
          final nonempty = cell.stack.any((tile) => tile.tileId > 0);
          if (_landTags.contains(tag) && walk.isPassable == true) land.add(pos);
          if (!_waterTags.contains(tag) &&
              tag != 8 &&
              tag != 9 &&
              nonempty &&
              walk.isPassable == true) {
            cave.add(pos);
          }
          if (_waterTags.contains(tag)) {
            rawWater++;
            if (resolver.resolveSurfEntryTile(cell).isPassable == true) {
              if (walk.isPassable == true &&
                  semantic.resolveCell(cell).directions.any((direction) {
                    final surf = resolver
                        .resolveSurfDirection(cell, direction.direction)
                        .isPassable;
                    return direction.isPassable == null ||
                        surf == null ||
                        direction.isPassable != surf;
                  })) {
                throw ContractError(
                    'source_encounter_terrain.mode_specific_passage_unqualified',
                    '\$.maps.$id.cells[$y][$x]',
                    'Walking and Surf directional passage differ at map $id ($x,$y)');
              }
              water.add(pos);
              if (walk.isPassable == false) surfRequiredCells.add(pos);
            }
          }
        }
      }
      final zones = <MapGameplayZone>[];
      final zoneRows = <Map<String, Object?>>[];
      final binding = <String, Object?>{
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'sourceSelectionHash': source.canonicalHash.value,
        'sourceMapId': id,
        'sourceMapHash': canonicalHashOf(_inert(sourceMap.toJson())).value,
        'nativeMapId': nativeMapIds[id],
      };
      final sortedMethods = methods.keys.where(_kinds.containsKey).toList()
        ..sort();
      for (final method in sortedMethods) {
        final cells = method.startsWith('Land')
            ? land
            : method == 'Cave'
                ? cave
                : water;
        if (cells.isEmpty) continue;
        final area = _bounds(cells);
        final identity = {
          ...binding,
          'method': method,
          'nativeTableId': methods[method],
          'cells': _positions(cells)
        };
        final zone = MapGameplayZone(
            id:
                'source-encounter-terrain-${canonicalHashOf(identity).value.substring(0, 24)}',
            name: '${sourceMap.name} · $method',
            kind: GameplayZoneKind.encounter,
            area: area,
            cellMask: paintedEncounterMask(cells, area),
            encounter: EncounterZonePayload(
                encounterTableId: methods[method],
                encounterKind: _kinds[method]!));
        zones.add(zone);
        zoneRows.add({...identity, 'zone': _inert(zone.toJson())});
      }
      final rectangles =
          _rectangles(surfRequiredCells, sourceMap.width, sourceMap.height);
      for (final area in rectangles) {
        final identity = {
          ...binding,
          'requiredMode': 'surf',
          'area': _inert(area.toJson())
        };
        final zone = MapGameplayZone(
            id:
                'source-surf-terrain-${canonicalHashOf(identity).value.substring(0, 24)}',
            name: '${sourceMap.name} · Surf',
            kind: GameplayZoneKind.movement,
            area: area,
            movement:
                const MovementZonePayload(requiredMode: MovementMode.surf));
        zones.add(zone);
      }
      allZones[id] = zones;
      evidenceMaps.add({
        ...binding,
        'terrainCounts': terrainCounts,
        'landCells': _rowRuns(land),
        'caveCells': _rowRuns(cave),
        'rawWaterCellCount': rawWater,
        'waterCells': _rowRuns(water),
        'unqualifiedTerrainCells': _rowRuns(unknown),
        'encounterZones': zoneRows,
        'surfRectangles':
            rectangles.map((area) => _inert(area.toJson())).toList(),
        'zonesHash':
            canonicalHashOf(zones.map((zone) => _inert(zone.toJson())).toList())
                .value,
      });
    }
    return SourceEncounterTerrainBindingResult._(allZones, {
      'kind': 'sourceEncounterTerrainBinding',
      'version': 2,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'sourceSelectionHash': source.canonicalHash.value,
      'profile': semantic.profile.toJson(),
      'scope': 'staticTilesInactiveBridgeNoEvents',
      'oracle': {
        'Game_Map': {
          'sectionIndex': 42,
          'sha256':
              '2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9',
          'terrainLines': [302, 314],
          'surfLines': [222, 247]
        },
        'TerrainTag': {
          'sectionIndex': 113,
          'sha256':
              '6bcfb146b4ec27576d2c616392e4aa14f1f9baa135db85ac02b33e0139e7382e',
          'lines': [79, 205]
        },
      },
      'excludedTerrainTags': [8, 9],
      'ignoredInteractiveMethods': interactiveMethods,
      'maps': evidenceMaps,
    });
  }

  static const _kinds = {
    'Land': EncounterKind.walk,
    'Cave': EncounterKind.walk,
    'Water': EncounterKind.surf,
    'OldRod': EncounterKind.oldRod,
    'GoodRod': EncounterKind.goodRod,
    'SuperRod': EncounterKind.superRod,
  };
}

final class SourceEncounterTerrainResolver {
  const SourceEncounterTerrainResolver({required this.resolver});
  final SourceSemanticResolver resolver;

  int? resolveTerrainTag(SourceSemanticCell cell,
      {SourceSemanticContext context = const SourceSemanticContext()}) {
    if (!resolver.profile.isQualified ||
        !context.isQualified ||
        !cell.isInBounds) {
      return null;
    }
    for (final tile in cell.stack) {
      if (tile.tileId == 0) continue;
      final tag = tile.terrainTag;
      if (tile.tileId < 0 || tag == null || tag < 0 || tag > 17) return null;
      if (tag == 0 || tag == 13 || tag == 15) continue;
      return tag;
    }
    return 0;
  }

  SourceDirectionPassage resolveSurfDirection(
          SourceSemanticCell cell, SourceCardinalDirection direction,
          {SourceSemanticContext context = const SourceSemanticContext()}) =>
      _surfDirection(cell, direction, context, stationary: false);

  SourceConnectionEntryTilePassage resolveSurfEntryTile(SourceSemanticCell cell,
      {SourceSemanticContext context = const SourceSemanticContext()}) {
    final result = _surfDirection(cell, SourceCardinalDirection.down, context,
        stationary: true);
    return SourceConnectionEntryTilePassage(
        cell: cell,
        profile: resolver.profile,
        context: context,
        status: result.status,
        reason: result.reason,
        trace: result.trace);
  }

  SourceDirectionPassage _surfDirection(SourceSemanticCell cell,
      SourceCardinalDirection direction, SourceSemanticContext context,
      {required bool stationary}) {
    final trace = <SourceTilePassageTrace>[];
    SourceDirectionPassage result(
            SourcePassageStatus status, SourcePassageReason reason) =>
        SourceDirectionPassage(
            direction: direction, status: status, reason: reason, trace: trace);
    if (!resolver.profile.isQualified) {
      return result(SourcePassageStatus.unqualified,
          SourcePassageReason.unqualifiedProfile);
    }
    if (!context.isQualified) {
      return result(SourcePassageStatus.unqualified,
          SourcePassageReason.unsupportedContext);
    }
    if (!cell.isInBounds) {
      return result(
          SourcePassageStatus.blocked, SourcePassageReason.outOfBounds);
    }
    for (final tile in cell.stack) {
      SourceDirectionPassage decided(
          SourcePassageStatus status, SourcePassageReason reason) {
        trace.add(SourceTilePassageTrace(tile: tile, reason: reason));
        return result(status, reason);
      }

      if (tile.tileId == 0) {
        trace.add(SourceTilePassageTrace(
            tile: tile, reason: SourcePassageReason.emptyTile));
        continue;
      }
      final tag = tile.terrainTag,
          passage = tile.passage,
          priority = tile.priority;
      if (tile.tileId < 0 ||
          tag == null ||
          tag < 0 ||
          passage == null ||
          passage < 0 ||
          passage > 255 ||
          priority == null ||
          priority < 0 ||
          priority > 5) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.missingMetadata);
      }
      if (tag > 17) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.unknownTerrainTag);
      }
      if (tag == 13 || tag == 15) {
        trace.add(SourceTilePassageTrace(
            tile: tile,
            reason: tag == 13
                ? SourcePassageReason.ignoredTerrain
                : SourcePassageReason.inactiveBridge));
        continue;
      }
      if (_waterTags.contains(tag)) {
        return decided(
            SourcePassageStatus.allowed, SourcePassageReason.groundAllows);
      }
      if (passage & 15 == 15) {
        return decided(SourcePassageStatus.blocked,
            SourcePassageReason.allDirectionsBlocked);
      }
      if (!stationary && passage & direction.bit != 0) {
        return decided(
            SourcePassageStatus.blocked, SourcePassageReason.directionBlocked);
      }
      if (!stationary && tag == 1) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.ledgeRequiresGameplay);
      }
      if (priority == 0) {
        return decided(
            SourcePassageStatus.allowed, SourcePassageReason.groundAllows);
      }
      trace.add(SourceTilePassageTrace(
          tile: tile, reason: SourcePassageReason.raisedTileContinues));
    }
    return result(
        SourcePassageStatus.allowed, SourcePassageReason.stackExhausted);
  }

  SourceConnectionEntryTilePassage resolveWalkSurfEntryTile(
      SourceSemanticCell cell,
      {SourceSemanticContext context = const SourceSemanticContext()}) {
    final walk = resolver.resolveConnectionEntryTile(cell, context: context);
    if (walk.isPassable == true ||
        !_waterTags.contains(resolveTerrainTag(cell, context: context))) {
      return walk;
    }
    return resolveSurfEntryTile(cell, context: context);
  }

  SourceTransitionPassage resolveWalkSurfTransition(SourceSemanticCell from,
      SourceSemanticCell to, SourceCardinalDirection direction,
      {SourceSemanticContext context = const SourceSemanticContext()}) {
    final walk =
        resolver.resolveTransition(from, to, direction, context: context);
    if (walk.isPassable == true ||
        !resolver.profile.isQualified ||
        !context.isQualified ||
        from.sourceMapId != to.sourceMapId ||
        !from.isInBounds ||
        !to.isInBounds ||
        from.width != to.width ||
        from.height != to.height ||
        to.x != from.x + direction.dx ||
        to.y != from.y + direction.dy ||
        ![
          _waterTags.contains(resolveTerrainTag(from, context: context)),
          _waterTags.contains(resolveTerrainTag(to, context: context))
        ].any((value) => value)) {
      return walk;
    }
    if (const {8, 9}.contains(resolveTerrainTag(from, context: context)) ||
        const {8, 9}.contains(resolveTerrainTag(to, context: context))) {
      return walk;
    }
    final exit = resolveSurfDirection(from, direction, context: context);
    final entry = resolveSurfDirection(to, direction.reverse, context: context);
    final status = exit.status == SourcePassageStatus.unqualified ||
            entry.status == SourcePassageStatus.unqualified
        ? SourcePassageStatus.unqualified
        : exit.status == SourcePassageStatus.blocked ||
                entry.status == SourcePassageStatus.blocked
            ? SourcePassageStatus.blocked
            : SourcePassageStatus.allowed;
    final reason = exit.status == status ? exit.reason : entry.reason;
    return SourceTransitionPassage(
        status: status,
        reason: reason,
        exit: exit,
        entry: entry,
        from: from,
        to: to,
        profile: resolver.profile,
        context: context);
  }
}

const _waterTags = {5, 6, 7};
const _landTags = {2, 10, 11, 14};

Object? _inert(Object? value) => jsonDecode(jsonEncode(value));
List<Map<String, int>> _positions(List<GridPos> cells) =>
    cells.map((cell) => {'x': cell.x, 'y': cell.y}).toList(growable: false);

Map<String, Object?> _rowRuns(List<GridPos> cells) {
  final runs = <List<int>>[];
  for (final cell in cells) {
    if (runs.isNotEmpty &&
        runs.last[0] == cell.y &&
        runs.last[1] + runs.last[2] == cell.x) {
      runs.last[2]++;
    } else {
      runs.add([cell.y, cell.x, 1]);
    }
  }
  return {'encoding': 'rowRuns', 'count': cells.length, 'runs': runs};
}

MapRect _bounds(List<GridPos> cells) {
  var x0 = cells.first.x, x1 = x0, y0 = cells.first.y, y1 = y0;
  for (final cell in cells.skip(1)) {
    if (cell.x < x0) x0 = cell.x;
    if (cell.x > x1) x1 = cell.x;
    if (cell.y < y0) y0 = cell.y;
    if (cell.y > y1) y1 = cell.y;
  }
  return MapRect(
      pos: GridPos(x: x0, y: y0),
      size: GridSize(width: x1 - x0 + 1, height: y1 - y0 + 1));
}

List<MapRect> _rectangles(List<GridPos> cells, int width, int height) {
  final occupied = cells.map((cell) => cell.y * width + cell.x).toSet();
  var active = <(int, int), MapRect>{};
  final result = <MapRect>[];
  for (var y = 0; y < height; y++) {
    final next = <(int, int), MapRect>{};
    for (var x = 0; x < width; x++) {
      if (!occupied.contains(y * width + x)) continue;
      final x0 = x;
      while (x + 1 < width && occupied.contains(y * width + x + 1)) {
        x++;
      }
      final key = (x0, x - x0 + 1);
      final previous = active.remove(key);
      next[key] = previous == null
          ? MapRect(
              pos: GridPos(x: x0, y: y),
              size: GridSize(width: key.$2, height: 1))
          : previous.copyWith(
              size: previous.size.copyWith(height: previous.size.height + 1));
    }
    result.addAll(active.values);
    active = next;
  }
  result.addAll(active.values);
  result.sort((a, b) => a.pos.y != b.pos.y
      ? a.pos.y.compareTo(b.pos.y)
      : a.pos.x.compareTo(b.pos.x));
  return result;
}
