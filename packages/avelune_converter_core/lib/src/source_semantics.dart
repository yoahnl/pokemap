part of '../avelune_converter_core.dart';

enum SourceCardinalDirection {
  down(2, 1, 0, 1),
  left(4, 2, -1, 0),
  right(6, 4, 1, 0),
  up(8, 8, 0, -1);

  const SourceCardinalDirection(this.sourceValue, this.bit, this.dx, this.dy);

  final int sourceValue;
  final int bit;
  final int dx;
  final int dy;

  SourceCardinalDirection get reverse => switch (this) {
        down => up,
        left => right,
        right => left,
        up => down,
      };
}

enum SourceMovementMode {
  playerWalk,
  strict,
  npc,
  follower,
  surf,
  cycling,
  jump,
  custom
}

enum SourcePassageStatus { allowed, blocked, unqualified }

enum SourcePassageReason {
  emptyTile,
  inactiveBridge,
  ignoredTerrain,
  directionBlocked,
  allDirectionsBlocked,
  groundAllows,
  raisedTileContinues,
  stackExhausted,
  missingMetadata,
  unknownTerrainTag,
  ledgeRequiresGameplay,
  unqualifiedProfile,
  unsupportedContext,
  outOfBounds,
  nonAdjacentCell,
  crossMapTransition,
}

final class SourceSemanticContext {
  const SourceSemanticContext({
    this.mode = SourceMovementMode.playerWalk,
    this.bridgeLevel = 0,
    this.actorWidth = 1,
    this.actorHeight = 1,
  });

  final SourceMovementMode mode;
  final int bridgeLevel;
  final int actorWidth;
  final int actorHeight;

  bool get isQualified =>
      mode == SourceMovementMode.playerWalk &&
      bridgeLevel == 0 &&
      actorWidth == 1 &&
      actorHeight == 1;

  Map<String, Object?> toJson() => {
        'mode': mode.name,
        'bridgeLevel': bridgeLevel,
        'actorWidth': actorWidth,
        'actorHeight': actorHeight,
        'scope': 'staticMapTiles',
      };
}

final class SourceSemanticProfile {
  SourceSemanticProfile.kantoPlayerWalk({
    required this.scriptsArchiveHash,
    required this.sourceSnapshotHash,
    required this.sourceSelectionHash,
  });

  static const kantoScriptsArchiveSha256 =
      '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

  final Sha256Hash? scriptsArchiveHash;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash sourceSelectionHash;

  bool get isQualified =>
      scriptsArchiveHash?.value == kantoScriptsArchiveSha256;
  Sha256Hash get canonicalHash => canonicalHashOf(toJson());

  Map<String, Object?> toJson() => {
        'profile': 'kanto-player-walk-static-v1',
        'scriptsArchiveHash': scriptsArchiveHash?.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'sourceSelectionHash': sourceSelectionHash.value,
        'qualified': isQualified,
        'oracle': {
          'Game_Map': {
            'sectionIndex': 42,
            'sha256':
                '2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9',
            'lines': [142, 247],
          },
          'Game_Character': {
            'sectionIndex': 44,
            'sha256':
                '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9',
            'lines': [237, 257],
          },
          'TerrainTag': {
            'sectionIndex': 113,
            'sha256':
                '6bcfb146b4ec27576d2c616392e4aa14f1f9baa135db85ac02b33e0139e7382e',
            'lines': [27, 205],
          },
        },
      };
}

final class SourceSemanticTile {
  const SourceSemanticTile({
    required this.sourceZ,
    required this.tileId,
    this.passage,
    this.priority,
    this.terrainTag,
  });

  final int sourceZ;
  final int tileId;
  final int? passage;
  final int? priority;
  final int? terrainTag;

  Map<String, Object?> toJson() => {
        'sourceZ': sourceZ,
        'tileId': tileId,
        'passage': passage,
        'priority': priority,
        'terrainTag': terrainTag,
      };
}

final class SourceSemanticCell {
  SourceSemanticCell({
    required this.sourceMapId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required List<SourceSemanticTile> stack,
  }) : stack = List.unmodifiable(
            stack.toList()..sort((a, b) => b.sourceZ.compareTo(a.sourceZ))) {
    _require(
        width > 0 && height > 0 && sourceMapId >= 0,
        'source_semantics.cell',
        r'$',
        'Source map dimensions and identity must be valid');
    _require(
        stack.length == 3 &&
            stack.map((tile) => tile.sourceZ).toSet().containsAll([0, 1, 2]),
        'source_semantics.stack',
        r'$',
        'Source cells require exactly layers Z0, Z1 and Z2');
  }

  final int sourceMapId;
  final int x;
  final int y;
  final int width;
  final int height;
  final List<SourceSemanticTile> stack;

  bool get isInBounds => x >= 0 && y >= 0 && x < width && y < height;

  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'stack': stack.map((tile) => tile.toJson()).toList(),
      };
}

final class SourceTilePassageTrace {
  const SourceTilePassageTrace({required this.tile, required this.reason});
  final SourceSemanticTile tile;
  final SourcePassageReason reason;

  Map<String, Object?> toJson() => {...tile.toJson(), 'reason': reason.name};
}

final class SourceDirectionPassage {
  SourceDirectionPassage({
    required this.direction,
    required this.status,
    required this.reason,
    required List<SourceTilePassageTrace> trace,
  }) : trace = List.unmodifiable(trace);

  final SourceCardinalDirection direction;
  final SourcePassageStatus status;
  final SourcePassageReason reason;
  final List<SourceTilePassageTrace> trace;

  bool? get isPassable => switch (status) {
        SourcePassageStatus.allowed => true,
        SourcePassageStatus.blocked => false,
        SourcePassageStatus.unqualified => null,
      };

  Map<String, Object?> toJson() => {
        'direction': direction.sourceValue,
        'status': status.name,
        'reason': reason.name,
        'trace': trace.map((step) => step.toJson()).toList(),
      };
}

final class SourceCellPassage {
  SourceCellPassage({
    required this.cell,
    required this.profile,
    required this.context,
    required List<SourceDirectionPassage> directions,
  }) : directions = List.unmodifiable(directions);

  final SourceSemanticCell cell;
  final SourceSemanticProfile profile;
  final SourceSemanticContext context;
  final List<SourceDirectionPassage> directions;

  int get allowedMask => _mask(SourcePassageStatus.allowed);
  int get blockedMask => _mask(SourcePassageStatus.blocked);
  int get unqualifiedMask => _mask(SourcePassageStatus.unqualified);
  bool get bush => cell.stack.any((tile) =>
      tile.tileId != 0 && tile.passage != null && tile.passage! & 0x40 != 0);
  bool get counter => cell.stack.any((tile) =>
      tile.tileId != 0 && tile.passage != null && tile.passage! & 0x80 != 0);
  List<int> get rawTerrainTags => List.unmodifiable(cell.stack
      .where((tile) => tile.tileId != 0 && tile.terrainTag != null)
      .map((tile) => tile.terrainTag!));

  SourceDirectionPassage inDirection(SourceCardinalDirection direction) =>
      directions.singleWhere((item) => item.direction == direction);
  int _mask(SourcePassageStatus status) => directions
      .where((item) => item.status == status)
      .fold(0, (mask, item) => mask | item.direction.bit);

  Map<String, Object?> toJson() => {
        'profile': profile.toJson(),
        'context': context.toJson(),
        'cell': cell.toJson(),
        'allowedMask': allowedMask,
        'blockedMask': blockedMask,
        'unqualifiedMask': unqualifiedMask,
        'bush': bush,
        'counter': counter,
        'rawTerrainTags': rawTerrainTags,
        'directions': directions.map((item) => item.toJson()).toList(),
      };
}

final class SourceTransitionPassage {
  const SourceTransitionPassage(
      {required this.status,
      required this.reason,
      required this.exit,
      required this.entry,
      required this.from,
      required this.to,
      required this.profile,
      required this.context});
  final SourcePassageStatus status;
  final SourcePassageReason reason;
  final SourceDirectionPassage exit;
  final SourceDirectionPassage entry;
  final SourceSemanticCell from;
  final SourceSemanticCell to;
  final SourceSemanticProfile profile;
  final SourceSemanticContext context;
  bool? get isPassable => status == SourcePassageStatus.unqualified
      ? null
      : status == SourcePassageStatus.allowed;

  Map<String, Object?> toJson() => {
        'status': status.name,
        'reason': reason.name,
        'from': from.toJson(),
        'to': to.toJson(),
        'profile': profile.toJson(),
        'context': context.toJson(),
        'exit': exit.toJson(),
        'entry': entry.toJson()
      };
}

final class SourceSemanticResolver {
  const SourceSemanticResolver({required this.profile}) : _maps = const {};

  SourceSemanticResolver._(
      {required this.profile, required Map<int, _SourceSemanticMap> maps})
      : _maps = Map.unmodifiable(maps);

  factory SourceSemanticResolver.forProject(NormalizedSourceProject project) {
    final scriptEntries = project.snapshot.entries
        .where((entry) =>
            entry.kind == SourceNodeKind.file &&
            sourcePathCollisionKey(entry.relativePath) == 'data/scripts.rxdata')
        .toList();
    final profile = SourceSemanticProfile.kantoPlayerWalk(
      scriptsArchiveHash:
          scriptEntries.length == 1 ? scriptEntries.single.sha256 : null,
      sourceSnapshotHash: project.snapshot.canonicalHash,
      sourceSelectionHash: project.canonicalHash,
    );
    final tilesets = {
      for (final tileset in project.tilesets) tileset.sourceTilesetId: tileset
    };
    return SourceSemanticResolver._(profile: profile, maps: {
      for (final source in project.maps)
        source.map.sourceMapId: _SourceSemanticMap(
            source.map, tilesets[source.map.sourceTilesetId]),
    });
  }

  final SourceSemanticProfile profile;
  final Map<int, _SourceSemanticMap> _maps;

  SourceSemanticCell cellAt(int sourceMapId, int x, int y) {
    final map = _maps[sourceMapId];
    _require(map != null, 'source_semantics.map_missing', '$sourceMapId',
        'Source map is outside the normalized selection');
    return map!.cellAt(x, y);
  }

  SourceCellPassage resolveCell(SourceSemanticCell cell,
          {SourceSemanticContext context = const SourceSemanticContext()}) =>
      SourceCellPassage(
        cell: cell,
        profile: profile,
        context: context,
        directions: [
          for (final direction in SourceCardinalDirection.values)
            _resolveDirection(cell, direction, context)
        ],
      );

  SourceDirectionPassage _resolveDirection(SourceSemanticCell cell,
      SourceCardinalDirection direction, SourceSemanticContext context) {
    final trace = <SourceTilePassageTrace>[];
    SourceDirectionPassage result(
            SourcePassageStatus status, SourcePassageReason reason) =>
        SourceDirectionPassage(
            direction: direction, status: status, reason: reason, trace: trace);
    if (!profile.isQualified) {
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
      final passage = tile.passage;
      final priority = tile.priority;
      final terrainTag = tile.terrainTag;
      if (tile.tileId < 0 ||
          passage == null ||
          passage < 0 ||
          passage > 255 ||
          priority == null ||
          priority < 0 ||
          priority > 5 ||
          terrainTag == null ||
          terrainTag < 0) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.missingMetadata);
      }
      if (terrainTag > 17) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.unknownTerrainTag);
      }
      if (terrainTag == 13) {
        trace.add(SourceTilePassageTrace(
            tile: tile, reason: SourcePassageReason.ignoredTerrain));
        continue;
      }
      if (terrainTag == 15) {
        trace.add(SourceTilePassageTrace(
            tile: tile, reason: SourcePassageReason.inactiveBridge));
        continue;
      }
      if (terrainTag == 1) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.ledgeRequiresGameplay);
      }
      if (passage & 15 == 15) {
        return decided(SourcePassageStatus.blocked,
            SourcePassageReason.allDirectionsBlocked);
      }
      if (passage & direction.bit != 0) {
        return decided(
            SourcePassageStatus.blocked, SourcePassageReason.directionBlocked);
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

  SourceTransitionPassage resolveTransition(SourceSemanticCell from,
      SourceSemanticCell to, SourceCardinalDirection direction,
      {SourceSemanticContext context = const SourceSemanticContext()}) {
    final exit = _resolveDirection(from, direction, context);
    final entry = _resolveDirection(to, direction.reverse, context);
    SourceTransitionPassage result(
            SourcePassageStatus status, SourcePassageReason reason) =>
        SourceTransitionPassage(
            status: status,
            reason: reason,
            exit: exit,
            entry: entry,
            from: from,
            to: to,
            profile: profile,
            context: context);
    if (!profile.isQualified) {
      return result(SourcePassageStatus.unqualified,
          SourcePassageReason.unqualifiedProfile);
    }
    if (!context.isQualified) {
      return result(SourcePassageStatus.unqualified,
          SourcePassageReason.unsupportedContext);
    }
    if (from.sourceMapId != to.sourceMapId) {
      return result(SourcePassageStatus.unqualified,
          SourcePassageReason.crossMapTransition);
    }
    if (!from.isInBounds || !to.isInBounds) {
      return result(
          SourcePassageStatus.blocked, SourcePassageReason.outOfBounds);
    }
    if (to.x != from.x + direction.dx ||
        to.y != from.y + direction.dy ||
        from.width != to.width ||
        from.height != to.height) {
      return result(
          SourcePassageStatus.unqualified, SourcePassageReason.nonAdjacentCell);
    }
    if (exit.status == SourcePassageStatus.blocked) {
      return result(SourcePassageStatus.blocked, exit.reason);
    }
    if (entry.status == SourcePassageStatus.blocked) {
      return result(SourcePassageStatus.blocked, entry.reason);
    }
    if (exit.status == SourcePassageStatus.unqualified) {
      return result(SourcePassageStatus.unqualified, exit.reason);
    }
    if (entry.status == SourcePassageStatus.unqualified) {
      return result(SourcePassageStatus.unqualified, entry.reason);
    }
    return result(SourcePassageStatus.allowed, entry.reason);
  }
}

final class _SourceSemanticMap {
  _SourceSemanticMap(SourceMapData source, this.tileset)
      : sourceMapId = source.sourceMapId,
        width = source.width,
        height = source.height,
        layers = Map.unmodifiable(
            {for (final layer in source.layers) layer.sourceZ: layer.cells});

  final int sourceMapId;
  final int width;
  final int height;
  final Map<int, List<int>> layers;
  final NormalizedTileset? tileset;

  SourceSemanticCell cellAt(int x, int y) {
    final inBounds = x >= 0 && y >= 0 && x < width && y < height;
    final tiles = <SourceSemanticTile>[];
    for (final z in [2, 1, 0]) {
      final cells = layers[z];
      final tileId = inBounds && cells != null ? cells[x + y * width] : 0;
      int? metadata(SourceTable? table) =>
          table == null || tileId < 0 || tileId >= table.cellCount
              ? null
              : table.valueAt(tileId, 0, 0);
      tiles.add(SourceSemanticTile(
          sourceZ: z,
          tileId: tileId,
          passage: metadata(tileset?.passages),
          priority: metadata(tileset?.priorities),
          terrainTag: metadata(tileset?.terrainTags)));
    }
    return SourceSemanticCell(
        sourceMapId: sourceMapId,
        x: x,
        y: y,
        width: width,
        height: height,
        stack: tiles);
  }
}
