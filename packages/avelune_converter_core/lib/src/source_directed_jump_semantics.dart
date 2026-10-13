part of '../avelune_converter_core.dart';

enum SourceDirectedJumpReason {
  allowed,
  exitBlocked,
  exitUnqualified,
  entryBlocked,
  entryUnqualified,
  landingBlocked,
  landingUnqualified,
  terrainUnqualified,
  notLedge,
  unqualifiedProfile,
  unsupportedContext,
  crossMapJump,
  invalidGeometry,
  outOfBounds,
}

enum SourceTerrainTagReason {
  emptyTile,
  noTerrain,
  ignoredTerrain,
  inactiveBridge,
  effectiveTerrain,
  missingMetadata,
  unknownTerrainTag,
}

final class SourceTerrainTagTrace {
  const SourceTerrainTagTrace({required this.tile, required this.reason});

  final SourceSemanticTile tile;
  final SourceTerrainTagReason reason;

  Map<String, Object?> toJson() => {...tile.toJson(), 'reason': reason.name};
}

final class SourceDirectedJumpPassage {
  SourceDirectedJumpPassage({
    required this.status,
    required this.reason,
    required this.direction,
    required this.from,
    required this.via,
    required this.landing,
    required this.profile,
    required this.context,
    required this.exit,
    required this.entry,
    required this.landingPassage,
    required this.effectiveTerrainTag,
    required List<SourceTerrainTagTrace> terrainTrace,
  }) : terrainTrace = List.unmodifiable(terrainTrace);

  final SourcePassageStatus status;
  final SourceDirectedJumpReason reason;
  final SourceCardinalDirection direction;
  final SourceSemanticCell from;
  final SourceSemanticCell via;
  final SourceSemanticCell landing;
  final SourceSemanticProfile profile;
  final SourceSemanticContext context;
  final SourceDirectionPassage exit;
  final SourceDirectionPassage entry;
  final SourceConnectionEntryTilePassage landingPassage;
  final int? effectiveTerrainTag;
  final List<SourceTerrainTagTrace> terrainTrace;

  bool? get isPassable => switch (status) {
        SourcePassageStatus.allowed => true,
        SourcePassageStatus.blocked => false,
        SourcePassageStatus.unqualified => null,
      };

  Map<String, Object?> toJson() => {
        'kind': 'sourceDirectedJumpPassage',
        'version': 1,
        'scope': 'staticMapTiles',
        'status': status.name,
        'reason': reason.name,
        'direction': direction.sourceValue,
        'distanceCells': 2,
        'from': from.toJson(),
        'via': via.toJson(),
        'landing': landing.toJson(),
        'profile': profile.toJson(),
        'context': context.toJson(),
        'exit': exit.toJson(),
        'entry': entry.toJson(),
        'landingPassage': landingPassage.toJson(),
        'effectiveTerrainTag': effectiveTerrainTag,
        'terrainTrace': terrainTrace.map((step) => step.toJson()).toList(),
        'eventStateQualified': false,
        'runtimeJourneyQualified': false,
        'oracle': {
          'Game_Map': {
            'sectionIndex': 42,
            'sha256':
                '2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9',
            'lines': [222, 247, 302, 316],
          },
          'Game_Character': {
            'sectionIndex': 44,
            'sha256':
                '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9',
            'lines': [237, 257, 767, 801],
          },
          'Game_Player': {
            'sectionIndex': 46,
            'sha256':
                '7159cc172004da46b72a51b7d009df24de7a297bdb09599de31a4b5116dab373',
            'lines': [141, 153],
          },
        },
      };
}

SourceDirectedJumpPassage _resolveSourceDirectedJump(
  SourceSemanticResolver resolver,
  SourceSemanticCell from,
  SourceSemanticCell via,
  SourceSemanticCell landing,
  SourceCardinalDirection direction,
  SourceSemanticContext context,
) {
  final exit = resolver._resolveDirection(from, direction, context,
      allowLedgeGameplay: true);
  final entry = resolver._resolveDirection(via, direction.reverse, context,
      allowLedgeGameplay: true);
  final landingPassage =
      resolver.resolveConnectionEntryTile(landing, context: context);
  final terrainTrace = <SourceTerrainTagTrace>[];
  int? effectiveTerrainTag;
  SourceDirectedJumpPassage result(
          SourcePassageStatus status, SourceDirectedJumpReason reason) =>
      SourceDirectedJumpPassage(
        status: status,
        reason: reason,
        direction: direction,
        from: from,
        via: via,
        landing: landing,
        profile: resolver.profile,
        context: context,
        exit: exit,
        entry: entry,
        landingPassage: landingPassage,
        effectiveTerrainTag: effectiveTerrainTag,
        terrainTrace: terrainTrace,
      );
  if (!resolver.profile.isQualified) {
    return result(SourcePassageStatus.unqualified,
        SourceDirectedJumpReason.unqualifiedProfile);
  }
  if (!context.isQualified) {
    return result(SourcePassageStatus.unqualified,
        SourceDirectedJumpReason.unsupportedContext);
  }
  if (from.sourceMapId != via.sourceMapId ||
      from.sourceMapId != landing.sourceMapId) {
    return result(
        SourcePassageStatus.unqualified, SourceDirectedJumpReason.crossMapJump);
  }
  if (from.width != via.width ||
      from.height != via.height ||
      from.width != landing.width ||
      from.height != landing.height ||
      via.x != from.x + direction.dx ||
      via.y != from.y + direction.dy ||
      landing.x != from.x + 2 * direction.dx ||
      landing.y != from.y + 2 * direction.dy) {
    return result(SourcePassageStatus.unqualified,
        SourceDirectedJumpReason.invalidGeometry);
  }
  if (!from.isInBounds || !via.isInBounds || !landing.isInBounds) {
    return result(
        SourcePassageStatus.blocked, SourceDirectedJumpReason.outOfBounds);
  }
  if (exit.status == SourcePassageStatus.blocked) {
    return result(
        SourcePassageStatus.blocked, SourceDirectedJumpReason.exitBlocked);
  }
  if (exit.status == SourcePassageStatus.unqualified) {
    return result(SourcePassageStatus.unqualified,
        SourceDirectedJumpReason.exitUnqualified);
  }
  if (entry.status == SourcePassageStatus.blocked) {
    return result(
        SourcePassageStatus.blocked, SourceDirectedJumpReason.entryBlocked);
  }
  if (entry.status == SourcePassageStatus.unqualified) {
    return result(SourcePassageStatus.unqualified,
        SourceDirectedJumpReason.entryUnqualified);
  }
  for (final tile in via.stack) {
    final tag = tile.terrainTag;
    SourceTerrainTagReason reason;
    if (tile.tileId == 0) {
      reason = SourceTerrainTagReason.emptyTile;
    } else if (tile.tileId < 0 || tag == null || tag < 0) {
      reason = SourceTerrainTagReason.missingMetadata;
    } else if (tag > 17) {
      reason = SourceTerrainTagReason.unknownTerrainTag;
    } else if (tag == 0) {
      reason = SourceTerrainTagReason.noTerrain;
    } else if (tag == 13) {
      reason = SourceTerrainTagReason.ignoredTerrain;
    } else if (tag == 15) {
      reason = SourceTerrainTagReason.inactiveBridge;
    } else {
      reason = SourceTerrainTagReason.effectiveTerrain;
    }
    terrainTrace.add(SourceTerrainTagTrace(tile: tile, reason: reason));
    if (reason == SourceTerrainTagReason.missingMetadata ||
        reason == SourceTerrainTagReason.unknownTerrainTag) {
      return result(SourcePassageStatus.unqualified,
          SourceDirectedJumpReason.terrainUnqualified);
    }
    if (reason == SourceTerrainTagReason.effectiveTerrain) {
      effectiveTerrainTag = tag;
      break;
    }
  }
  effectiveTerrainTag ??= 0;
  if (effectiveTerrainTag != 1) {
    return result(
        SourcePassageStatus.blocked, SourceDirectedJumpReason.notLedge);
  }
  if (landingPassage.status == SourcePassageStatus.blocked) {
    return result(
        SourcePassageStatus.blocked, SourceDirectedJumpReason.landingBlocked);
  }
  if (landingPassage.status == SourcePassageStatus.unqualified) {
    return result(SourcePassageStatus.unqualified,
        SourceDirectedJumpReason.landingUnqualified);
  }
  return result(SourcePassageStatus.allowed, SourceDirectedJumpReason.allowed);
}
