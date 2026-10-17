import '../collision/pixel_rect.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/moving_platform.dart';
import '../models/project_manifest.dart';
import '../models/map_placed_element_origin.dart';

const maxMovingPlatformTranslationPixels = 1024;

MovingPlatformWorldState initializeMovingPlatformWorldState({
  required MapData map,
  required MovingPlatformWorldState worldState,
}) {
  var result = worldState;
  final ids = map.movingPlatforms.map((platform) => platform.id).toSet();
  if (ids.length != map.movingPlatforms.length ||
      (worldState.platformsByMap[map.id]?.keys.any((id) => !ids.contains(id)) ??
          false)) {
    throw const FormatException(
      'Moving platform state does not match the map.',
    );
  }
  for (final platform in map.movingPlatforms) {
    if (platform.translationDistanceCells * platform.lattice.widthPx >
            maxMovingPlatformTranslationPixels ||
        platform.translationDistanceCells * platform.lattice.heightPx >
            maxMovingPlatformTranslationPixels) {
      throw const FormatException(
        'Moving platform translation exceeds the pixel motion budget.',
      );
    }
    if (result.platform(map.id, platform.id) == null) {
      result = result.withPlatform(
        mapId: map.id,
        platformId: platform.id,
        pose: platform.initialPose,
      );
    }
  }
  return result;
}

void validateMovingPlatformDefinitions({
  required MapData map,
  required ProjectManifest project,
  required PixelSize tileSize,
}) {
  if (map.movingPlatforms.isEmpty) return;
  if (map.spatialScene != null || tileSize.width <= 0 || tileSize.height <= 0) {
    throw const FormatException('Moving platforms require a 2D pixel map.');
  }
  final visualIds = <String>{};
  final terrainOwners = <String, MovingPlatformDefinition>{};
  initializeMovingPlatformWorldState(
    map: map,
    worldState: const MovingPlatformWorldState.empty(),
  );
  for (final platform in map.movingPlatforms) {
    if (!visualIds.add(platform.placedElementId)) {
      throw const FormatException(
        'A platform visual cannot belong to two platforms.',
      );
    }
    final placed = map.placedElements
        .where((element) => element.id == platform.placedElementId)
        .toList();
    if (placed.length != 1 ||
        placed.single.applyCollision ||
        !isAuthoredMapPlacedElement(placed.single)) {
      throw const FormatException(
        'A moving platform requires one nonblocking placed visual.',
      );
    }
    for (final layerId in platform.terrainLayerIds) {
      final layers = map.layers.where((layer) => layer.id == layerId).toList();
      if (layers.length != 1 ||
          !switch (layers.single) {
            TileLayer(:final purpose) => purpose == MapLayerPurpose.visual,
            SmartTileLayer() => true,
            _ => false,
          }) {
        throw const FormatException(
          'Platform support requires visual tile or Smart Tile terrain layers.',
        );
      }
      final cells = platform.terrainCellsByLayer[layerId];
      if (cells != null && layers.single is! SmartTileLayer) {
        throw const FormatException(
          'Explicit terrain cells require a Smart Tile layer.',
        );
      }
      final owner = terrainOwners[layerId];
      if (owner != null) {
        final other = owner.terrainCellsByLayer[layerId];
        if ((cells == null) != (other == null) ||
            cells != null &&
                (owner.lattice != platform.lattice ||
                    cells.length != other!.length ||
                    !cells.toSet().containsAll(other))) {
          throw const FormatException(
            'Platforms must agree on shared terrain collision geometry.',
          );
        }
      }
      terrainOwners[layerId] = platform;
      for (final cell in cells ?? const <GridPos>[]) {
        final rect = movingPlatformTerrainCellRect(platform: platform, cell: cell);
        if (rect.leftPx < 0 ||
            rect.topPx < 0 ||
            rect.leftPx + rect.widthPx > map.size.width * tileSize.width ||
            rect.topPx + rect.heightPx > map.size.height * tileSize.height) {
          throw const FormatException('Platform terrain cells exceed the map.');
        }
      }
    }
    for (final variant in platform.variants) {
      final elements = project.elements
          .where((element) => element.id == variant.elementId)
          .toList();
      if (elements.length != 1 || elements.single.frames.isEmpty) {
        throw const FormatException(
          'Platform visual element is missing or has no frames.',
        );
      }
      if (elements.single.collisionProfile?.occlusionMask != null) {
        throw const FormatException(
          'Moving platform variants cannot author static foreground occlusion.',
        );
      }
      if (elements.single.frames.any(
        (frame) =>
            variant.anchorOffsetPx.x > frame.source.width * tileSize.width ||
            variant.anchorOffsetPx.y > frame.source.height * tileSize.height,
      )) {
        throw const FormatException(
          'Platform anchor exceeds its visual frame.',
        );
      }
    }
    for (final cell in platform.travelCells) {
      final lattice = platform.lattice;
      final x =
          lattice.originLeftPx +
          lattice.cellOffsetLeftPx +
          cell.x * lattice.widthPx;
      final y =
          lattice.originTopPx +
          lattice.cellOffsetTopPx +
          cell.y * lattice.heightPx;
      if (x.round() < 0 ||
          y.round() < 0 ||
          (x + lattice.widthPx).round() > map.size.width * tileSize.width ||
          (y + lattice.heightPx).round() > map.size.height * tileSize.height) {
        throw const FormatException(
          'Platform travel cells must project inside the map.',
        );
      }
    }
  }
}

void validateMovingPlatformWorldState({
  required ProjectManifest project,
  required Iterable<MapData> maps,
  required MovingPlatformWorldState worldState,
}) {
  final byId = {for (final map in maps) map.id: map};
  for (final mapId in worldState.platformsByMap.keys) {
    if (!byId.containsKey(mapId)) {
      throw const FormatException('Saved moving platform map is missing.');
    }
  }
  final tile = PixelSize(
    width: project.settings.tileWidth,
    height: project.settings.tileHeight,
  );
  for (final map in byId.values) {
    validateMovingPlatformMapState(
      map: map,
      project: project,
      worldState: worldState,
      tileSize: tile,
      requireSettled: true,
    );
  }
}

void validateMovingPlatformMapState({
  required MapData map,
  required ProjectManifest project,
  required MovingPlatformWorldState worldState,
  required PixelSize tileSize,
  bool requireSettled = false,
}) {
  validateMovingPlatformDefinitions(
    map: map,
    project: project,
    tileSize: tileSize,
  );
  final initialized = initializeMovingPlatformWorldState(
    map: map,
    worldState: worldState,
  );
  for (final platform in map.movingPlatforms) {
    final pose = initialized.platform(map.id, platform.id)!;
    final variant = platform.variants[pose.quarterTurns];
    final lattice = platform.lattice;
    final travel = platform.travelCells.map((cell) => (cell.x, cell.y)).toSet();
    final pivot = (
      ((pose.leftPx - lattice.originLeftPx) / lattice.widthPx + 1e-8).floor(),
      ((pose.topPx - lattice.originTopPx) / lattice.heightPx + 1e-8).floor(),
    );
    if (!travel.contains(pivot)) {
      throw const FormatException(
        'Moving platform pivot is outside its travel lattice.',
      );
    }
    if (requireSettled) {
      final x =
          (pose.leftPx - platform.initialPose.leftPx) /
          (lattice.widthPx * platform.translationDistanceCells);
      final y =
          (pose.topPx - platform.initialPose.topPx) /
          (lattice.heightPx * platform.translationDistanceCells);
      if ((x - x.round()).abs() > 1e-7 || (y - y.round()).abs() > 1e-7) {
        throw const FormatException(
          'Saved moving platform motion is unfinished.',
        );
      }
    }
    for (final cell in variant.supportCells) {
      final rect = movingPlatformCellRect(
        platform: platform,
        pose: pose,
        cell: cell,
      );
      if (rect.leftPx < 0 ||
          rect.topPx < 0 ||
          rect.leftPx + rect.widthPx > map.size.width * tileSize.width ||
          rect.topPx + rect.heightPx > map.size.height * tileSize.height) {
        throw const FormatException(
          'Moving platform support exceeds the map bounds.',
        );
      }
    }
    final element = project.elements.singleWhere(
      (element) => element.id == variant.elementId,
    );
    final x = (pose.leftPx - variant.anchorOffsetPx.x).round();
    final y = (pose.topPx - variant.anchorOffsetPx.y).round();
    if (x < 0 ||
        y < 0 ||
        element.frames.any(
          (frame) =>
              x + frame.source.width * tileSize.width >
                  map.size.width * tileSize.width ||
              y + frame.source.height * tileSize.height >
                  map.size.height * tileSize.height,
        )) {
      throw const FormatException(
        'Moving platform visual exceeds the map bounds.',
      );
    }
  }
}

MapData applyMovingPlatformWorldStateToMap({
  required MapData map,
  required MovingPlatformWorldState worldState,
  required PixelSize tileSize,
}) {
  if (map.movingPlatforms.isEmpty) return map;
  if (tileSize.width <= 0 || tileSize.height <= 0) {
    throw const FormatException('Platform tile size must be positive.');
  }
  final initialized = initializeMovingPlatformWorldState(
    map: map,
    worldState: worldState,
  );
  final byPlacement = {
    for (final platform in map.movingPlatforms)
      platform.placedElementId: platform,
  };
  return map.copyWith(
    placedElements: map.placedElements.map((placement) {
      final platform = byPlacement[placement.id];
      if (platform == null) return placement;
      final pose = initialized.platform(map.id, platform.id)!;
      final variant = platform.variants[pose.quarterTurns];
      final x = (pose.leftPx - variant.anchorOffsetPx.x).round();
      final y = (pose.topPx - variant.anchorOffsetPx.y).round();
      return placement.copyWith(
        elementId: variant.elementId,
        pos: GridPos(
          x: (x / tileSize.width).floor(),
          y: (y / tileSize.height).floor(),
        ),
        pixelOffset: PixelOffset(x: x % tileSize.width, y: y % tileSize.height),
        pixelSize: null,
        quarterTurns: 0,
      );
    }).toList(),
  );
}

Iterable<PixelRect> movingPlatformSupportRects({
  required MapData map,
  required MovingPlatformWorldState worldState,
  required PixelSize tileSize,
  String? terrainLayerId,
}) sync* {
  final initialized = initializeMovingPlatformWorldState(
    map: map,
    worldState: worldState,
  );
  for (final platform in map.movingPlatforms) {
    if (terrainLayerId != null &&
        !platform.terrainLayerIds.contains(terrainLayerId)) {
      continue;
    }
    final pose = initialized.platform(map.id, platform.id)!;
    for (final cell in platform.variants[pose.quarterTurns].supportCells) {
      yield movingPlatformCellRect(platform: platform, pose: pose, cell: cell);
    }
  }
}

PixelRect movingPlatformCellRect({
  required MovingPlatformDefinition platform,
  required MovingPlatformPose pose,
  required GridPos cell,
}) => _movingPlatformLatticeRect(
  platform.lattice,
  pose.leftPx,
  pose.topPx,
  cell,
);

PixelRect movingPlatformTerrainCellRect({
  required MovingPlatformDefinition platform,
  required GridPos cell,
}) => _movingPlatformLatticeRect(
  platform.lattice,
  platform.lattice.originLeftPx,
  platform.lattice.originTopPx,
  cell,
);

PixelRect _movingPlatformLatticeRect(
  MovingPlatformLattice lattice,
  double leftPx,
  double topPx,
  GridPos cell,
) {
  final left =
      leftPx + lattice.cellOffsetLeftPx + cell.x * lattice.widthPx;
  final top = topPx + lattice.cellOffsetTopPx + cell.y * lattice.heightPx;
  return PixelRect(
    leftPx: left.round(),
    topPx: top.round(),
    widthPx: (left + lattice.widthPx).round() - left.round(),
    heightPx: (top + lattice.heightPx).round() - top.round(),
  );
}
