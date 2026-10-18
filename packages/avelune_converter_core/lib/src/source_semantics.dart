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
  SourceSemanticProfile(
      {required this.scriptsArchiveHash,
      required this.sourceSnapshotHash,
      required this.sourceSelectionHash,
      this.interpretationProfile});

  final SourceInterpretationProfile? interpretationProfile;
  final Sha256Hash? scriptsArchiveHash;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash sourceSelectionHash;
  bool get isQualified =>
      interpretationProfile?.supports('walking') == true &&
      interpretationProfile!.matchesArchive(scriptsArchiveHash);
  Sha256Hash get canonicalHash => canonicalHashOf(toJson());
  Map<String, Object?> toJson() => {
        'profile': 'rmxp-static-player-walk-v1',
        'interpretationProfile': interpretationProfile?.toJson(),
        'scriptsArchiveHash': scriptsArchiveHash?.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'sourceSelectionHash': sourceSelectionHash.value,
        'qualified': isQualified,
        'qualificationScope':
            'declaredStaticContractAndRecognizedCommandStructure',
        'oracle':
            interpretationProfile?.walkingOracles ?? const <String, Object?>{},
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

final class SourceConnectionEntryTilePassage {
  SourceConnectionEntryTilePassage({
    required this.cell,
    required this.profile,
    required this.context,
    required this.status,
    required this.reason,
    required List<SourceTilePassageTrace> trace,
  }) : trace = List.unmodifiable(trace);

  final SourceSemanticCell cell;
  final SourceSemanticProfile profile;
  final SourceSemanticContext context;
  final SourcePassageStatus status;
  final SourcePassageReason reason;
  final List<SourceTilePassageTrace> trace;

  bool? get isPassable => switch (status) {
        SourcePassageStatus.allowed => true,
        SourcePassageStatus.blocked => false,
        SourcePassageStatus.unqualified => null,
      };

  Map<String, Object?> toJson() => {
        'kind': 'sourceConnectionEntryTilePassage',
        'version': 1,
        'scope': 'destinationStaticTiles',
        'sourceDirection': 0,
        'directionBit': 0,
        'profile': profile.toJson(),
        'context': context.toJson(),
        'cell': cell.toJson(),
        'status': status.name,
        'reason': reason.name,
        'trace': trace.map((step) => step.toJson()).toList(),
        'eventStateQualified': false,
        'oracle': {
          'Game_Map': {
            'sectionIndex': 42,
            'sha256':
                '2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9',
            'lines': [142, 158, 222, 247],
          },
          'PokemonMapFactory': {
            'sectionIndex': 43,
            'sha256':
                'bba3deeae94afff918edfcde6d251748498f44f59655fc9ce32aa42f304d98c6',
            'lines': [149, 176],
          },
        },
      };
}

enum SourceEventTouchKind { enter, front, unqualified }

final class SourceEventTouchResolution {
  SourceEventTouchResolution(
      {required this.kind,
      required this.reason,
      List<SourceTilePassageTrace> trace = const []})
      : trace = List.unmodifiable(trace);
  final SourceEventTouchKind kind;
  final String reason;
  final List<SourceTilePassageTrace> trace;
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'reason': reason,
        'sourceDirection': 0,
        'directionBit': 0,
        'trace': trace.map((step) => step.toJson()).toList(),
        'oracle': {
          'sectionIndex': 45,
          'lines': [133, 139]
        },
      };
}

final class SourceSemanticResolver {
  const SourceSemanticResolver({required this.profile})
      : _maps = const {},
        _eventFiles = const {};

  SourceSemanticResolver._(
      {required this.profile,
      required Map<int, _SourceSemanticMap> maps,
      required Map<ConverterId, SourceArchivedFile> eventFiles})
      : _maps = Map.unmodifiable(maps),
        _eventFiles = Map.unmodifiable(eventFiles);

  factory SourceSemanticResolver.forProject(NormalizedSourceProject project) {
    final scriptEntries = project.snapshot.entries
        .where((entry) =>
            entry.kind == SourceNodeKind.file &&
            sourcePathCollisionKey(entry.relativePath) == 'data/scripts.rxdata')
        .toList();
    final profile = SourceSemanticProfile(
      interpretationProfile: project.interpretationProfile,
      scriptsArchiveHash:
          scriptEntries.length == 1 ? scriptEntries.single.sha256 : null,
      sourceSnapshotHash: project.snapshot.canonicalHash,
      sourceSelectionHash: project.canonicalHash,
    );
    final tilesets = {
      for (final tileset in project.tilesets) tileset.sourceTilesetId: tileset
    };
    return SourceSemanticResolver._(
        profile: profile,
        eventFiles: project.archive.files,
        maps: {
          for (final source in project.maps)
            source.map.sourceMapId: _SourceSemanticMap(
                source.map, tilesets[source.map.sourceTilesetId]),
        });
  }

  final SourceSemanticProfile profile;
  final Map<int, _SourceSemanticMap> _maps;
  final Map<ConverterId, SourceArchivedFile> _eventFiles;

  bool _plainTouchPage(SourceEventPageAnalysis page) {
    final raw = page.rawDataRef;
    final file = raw == null ? null : _eventFiles[raw.fileId];
    if (raw == null || file == null || file.contentHash != raw.contentHash) {
      return false;
    }
    final doc = file.document;
    bool plain(MarshalNode node) =>
        node.extensions.isEmpty &&
        node.userClass == null &&
        node.instanceVariables.isEmpty;
    Map<String, int> fields(int id, String className, Set<String> names) {
      final node = doc.node(id);
      final values = _eventFields(doc, id, className);
      if (values.length != names.length ||
          !names.containsAll(values.keys) ||
          node.instanceVariables.any((pair) => !plain(doc.node(pair.key)))) {
        throw const FormatException();
      }
      return values;
    }

    void scalar(int id) {
      final node = doc.node(id);
      if (plain(node)) {
        return;
      }
      if (node.kind != MarshalKind.string ||
          node.instanceVariables.length > 1) {
        throw const FormatException();
      }
      _eventLiteralText(doc, id);
    }

    try {
      for (final node in doc.nodes) {
        if (node.kind == MarshalKind.symbol &&
            const {
              'RPG::Event::Page',
              'RPG::Event::Page::Graphic',
              'RPG::Event::Page::Condition'
            }.contains(node.name) &&
            !plain(node)) {
          return false;
        }
      }
      final value = fields(raw.nodeId, 'RPG::Event::Page', const {
        '@condition',
        '@graphic',
        '@move_type',
        '@move_speed',
        '@move_frequency',
        '@move_route',
        '@walk_anime',
        '@step_anime',
        '@direction_fix',
        '@through',
        '@always_on_top',
        '@trigger',
        '@list'
      });
      final graphic =
          fields(value['@graphic']!, 'RPG::Event::Page::Graphic', const {
        '@tile_id',
        '@character_name',
        '@character_hue',
        '@direction',
        '@pattern',
        '@opacity',
        '@blend_type'
      });
      final condition =
          fields(value['@condition']!, 'RPG::Event::Page::Condition', const {
        '@switch1_valid',
        '@switch2_valid',
        '@variable_valid',
        '@self_switch_valid',
        '@switch1_id',
        '@switch2_id',
        '@variable_id',
        '@variable_value',
        '@self_switch_ch'
      });
      for (final entry in value.entries) {
        if (!const {'@condition', '@graphic', '@move_route', '@list'}
            .contains(entry.key)) {
          scalar(entry.value);
        }
      }
      for (final id in [...graphic.values, ...condition.values]) {
        scalar(id);
      }
      return true;
    } on FormatException {
      return false;
    }
  }

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

  SourceDirectedJumpPassage resolveDirectedJump(
    SourceSemanticCell from,
    SourceSemanticCell via,
    SourceSemanticCell landing,
    SourceCardinalDirection direction, {
    SourceSemanticContext context = const SourceSemanticContext(),
  }) =>
      _resolveSourceDirectedJump(this, from, via, landing, direction, context);

  SourceConnectionEntryTilePassage resolveConnectionEntryTile(
    SourceSemanticCell cell, {
    SourceSemanticContext context = const SourceSemanticContext(),
  }) =>
      _resolveStationaryPlayerTiles(cell, context: context);

  SourceEventTouchResolution resolveEventTouch({
    required SourceSemanticCell cell,
    required SourceEventDefinition event,
    required SourceEventPageAnalysis page,
    required Iterable<SourceEventDefinition> mapEvents,
    SourceSemanticContext context = const SourceSemanticContext(),
  }) {
    SourceEventTouchResolution result(SourceEventTouchKind kind, String reason,
            [List<SourceTilePassageTrace> trace = const []]) =>
        SourceEventTouchResolution(kind: kind, reason: reason, trace: trace);
    if (!profile.isQualified ||
        !context.isQualified ||
        page.isQuarantined ||
        !page.condition.isQualified ||
        !_plainTouchPage(page)) {
      return result(
          SourceEventTouchKind.unqualified, 'sourceContextUnqualified');
    }
    if (cell.sourceMapId != event.sourceMapId ||
        cell.x != event.x ||
        cell.y != event.y ||
        !cell.isInBounds ||
        !event.pages.contains(page)) {
      return result(SourceEventTouchKind.unqualified, 'eventCellBinding');
    }
    bool unitFootprint(SourceEventDefinition value) {
      final size = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .firstMatch(value.name);
      return size == null ||
          (int.tryParse(size.group(1)!) == 1 &&
              int.tryParse(size.group(2)!) == 1);
    }

    final graphic = page.graphic;
    if (graphic == null ||
        !unitFootprint(event) ||
        graphic.tileId != 0 ||
        graphic.moveType != 0) {
      return result(SourceEventTouchKind.unqualified,
          'eventGraphicOrFootprintUnqualified');
    }
    if (graphic.characterName.isNotEmpty && !graphic.through) {
      return result(SourceEventTouchKind.front, 'blockingCharacter');
    }
    if (RegExp('hiddenitem', caseSensitive: false).hasMatch(event.name)) {
      return result(SourceEventTouchKind.front, 'hiddenItem');
    }
    final candidates = mapEvents
        .where((value) => value.sourceMapId == event.sourceMapId)
        .toList();
    if (candidates.where((value) => value.identity == event.identity).length !=
        1) {
      return result(SourceEventTouchKind.unqualified, 'eventSetBinding');
    }
    for (final candidate in candidates) {
      for (final other in candidate.pages) {
        final image = other.graphic;
        if (image == null || !_plainTouchPage(other)) {
          return result(
              SourceEventTouchKind.unqualified, 'tileEventStateUnqualified');
        }
        if (image.tileId <= 0 || image.through) {
          continue;
        }
        if (image.moveType != 0 ||
            !unitFootprint(candidate) ||
            (candidate.x == event.x && candidate.y == event.y)) {
          return result(
              SourceEventTouchKind.unqualified, 'tileEventStateUnqualified');
        }
      }
    }
    final passage = _resolveStationaryPlayerTiles(cell, context: context);
    return switch (passage.status) {
      SourcePassageStatus.allowed => result(
          SourceEventTouchKind.enter, 'stationaryTilesAllowed', passage.trace),
      SourcePassageStatus.blocked => result(
          SourceEventTouchKind.front, 'stationaryTilesBlocked', passage.trace),
      SourcePassageStatus.unqualified => result(
          SourceEventTouchKind.unqualified, passage.reason.name, passage.trace),
    };
  }

  SourceEventTouchResolution resolveStaticActionFootprint({
    required SourceEventDefinition event,
    required SourceEventPageAnalysis page,
    required Iterable<SourceEventDefinition> mapEvents,
    required int width,
    required int height,
    SourceSemanticContext context = const SourceSemanticContext(),
  }) => _resolveStaticFrontFootprint(event: event, page: page,
      mapEvents: mapEvents, width: width, height: height, context: context,
      expectedTriggerCode: 0);

  SourceEventTouchResolution resolveStaticBumpFootprint({
    required SourceEventDefinition event,
    required SourceEventPageAnalysis page,
    required Iterable<SourceEventDefinition> mapEvents,
    required int width,
    required int height,
    SourceSemanticContext context = const SourceSemanticContext(),
  }) => _resolveStaticFrontFootprint(event: event, page: page,
      mapEvents: mapEvents, width: width, height: height, context: context,
      expectedTriggerCode: 1);

  SourceEventTouchResolution _resolveStaticFrontFootprint({
    required int expectedTriggerCode,
    required SourceEventDefinition event,
    required SourceEventPageAnalysis page,
    required Iterable<SourceEventDefinition> mapEvents,
    required int width,
    required int height,
    SourceSemanticContext context = const SourceSemanticContext(),
  }) {
    SourceEventTouchResolution refused(String reason,
            [List<SourceTilePassageTrace> trace = const []]) =>
        SourceEventTouchResolution(
            kind: SourceEventTouchKind.unqualified, reason: reason, trace: trace);
    if (!profile.isQualified || !context.isQualified ||
        event.isQuarantined || event.pages.length != 1 ||
        !event.pages.contains(page) || page.triggerCode != expectedTriggerCode ||
        page.condition.kind != SourceEventConditionKind.always ||
        !_plainTouchPage(page)) {
      return refused('sourceContextUnqualified');
    }
    final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
        .allMatches(event.name).toList();
    if (width < 1 || width > 2 || height != 1 || sizes.length > 1 ||
        (sizes.isEmpty ? width != 1 :
            int.tryParse(sizes.single.group(1)!) != width ||
            int.tryParse(sizes.single.group(2)!) != height)) {
      return refused('eventFootprintUnqualified');
    }
    final map = _maps[event.sourceMapId];
    final graphic = page.graphic;
    if (map == null || event.x < 0 || event.y < 0 ||
        event.x + width > map.width || event.y + height > map.height ||
        graphic == null || graphic.tileId != 0 ||
        graphic.characterName.isNotEmpty || graphic.moveType != 0 ||
        graphic.through || graphic.directionFix || graphic.stepAnime ||
        graphic.alwaysOnTop || graphic.hue != 0 || graphic.opacity != 255 ||
        graphic.blendType != 0 ||
        page.rawDataRef?.fileId != event.sourceFileId) {
      return refused('eventGraphicOrFootprintUnqualified');
    }
    final candidates = mapEvents.where((candidate) =>
        candidate.sourceMapId == event.sourceMapId).toList();
    if (candidates.where((candidate) => candidate.identity == event.identity)
            .length != 1) {
      return refused('eventSetBinding');
    }
    for (final candidate in candidates) {
      final otherSizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .allMatches(candidate.name).toList();
      final otherWidth = otherSizes.isEmpty ? 1 :
          int.tryParse(otherSizes.first.group(1)!);
      final otherHeight = otherSizes.isEmpty ? 1 :
          int.tryParse(otherSizes.first.group(2)!);
      if (otherSizes.length > 1 || otherWidth == null ||
          otherWidth < 1 || otherWidth > 2 || otherHeight != 1) {
        return refused('eventFootprintUnqualified');
      }
      if (candidate.identity != event.identity &&
          candidate.x < event.x + width &&
          candidate.x + otherWidth > event.x &&
          candidate.y == event.y) {
        return refused('overlappingEventFootprint');
      }
      for (final other in candidate.pages) {
        final image = other.graphic;
        if (image == null || !_plainTouchPage(other)) {
          return refused('tileEventStateUnqualified');
        }
        if (image.tileId <= 0 || image.through) continue;
        if (image.moveType != 0 || otherWidth != 1) {
          return refused('tileEventStateUnqualified');
        }
      }
    }
    final trace = <SourceTilePassageTrace>[];
    for (var dx = 0; dx < width; dx++) {
      final passage = _resolveStationaryPlayerTiles(
          map.cellAt(event.x + dx, event.y), context: context);
      trace.addAll(passage.trace);
      if (passage.status != SourcePassageStatus.blocked) {
        return refused('footprintTilePassageUnqualified', trace);
      }
    }
    return SourceEventTouchResolution(
        kind: SourceEventTouchKind.front,
        reason: 'stationaryFootprintTilesBlocked', trace: trace);
  }

  SourceConnectionEntryTilePassage _resolveStationaryPlayerTiles(
    SourceSemanticCell cell, {
    SourceSemanticContext context = const SourceSemanticContext(),
  }) {
    final trace = <SourceTilePassageTrace>[];
    SourceConnectionEntryTilePassage result(
            SourcePassageStatus status, SourcePassageReason reason) =>
        SourceConnectionEntryTilePassage(
          cell: cell,
          profile: profile,
          context: context,
          status: status,
          reason: reason,
          trace: trace,
        );
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
      SourceConnectionEntryTilePassage decided(
          SourcePassageStatus status, SourcePassageReason reason) {
        trace.add(SourceTilePassageTrace(tile: tile, reason: reason));
        return result(status, reason);
      }

      if (tile.tileId == 0) {
        trace.add(SourceTilePassageTrace(
            tile: tile, reason: SourcePassageReason.emptyTile));
        continue;
      }
      final terrainTag = tile.terrainTag;
      if (tile.tileId < 0 || terrainTag == null || terrainTag < 0) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.missingMetadata);
      }
      if (terrainTag > 17) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.unknownTerrainTag);
      }
      if (terrainTag == 15 || terrainTag == 13) {
        trace.add(SourceTilePassageTrace(
            tile: tile,
            reason: terrainTag == 15
                ? SourcePassageReason.inactiveBridge
                : SourcePassageReason.ignoredTerrain));
        continue;
      }
      final passage = tile.passage;
      if (passage == null || passage < 0 || passage > 255) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.missingMetadata);
      }
      if (passage & 15 == 15) {
        return decided(SourcePassageStatus.blocked,
            SourcePassageReason.allDirectionsBlocked);
      }
      final priority = tile.priority;
      if (priority == null || priority < 0 || priority > 5) {
        return decided(SourcePassageStatus.unqualified,
            SourcePassageReason.missingMetadata);
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

  SourceDirectionPassage _resolveDirection(SourceSemanticCell cell,
      SourceCardinalDirection direction, SourceSemanticContext context,
      {bool allowLedgeGameplay = false}) {
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
      if (passage & 15 == 15) {
        return decided(SourcePassageStatus.blocked,
            SourcePassageReason.allDirectionsBlocked);
      }
      if (passage & direction.bit != 0) {
        return decided(
            SourcePassageStatus.blocked, SourcePassageReason.directionBlocked);
      }
      if (terrainTag == 1 && !allowLedgeGameplay) {
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
