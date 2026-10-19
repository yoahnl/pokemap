import '../collision/pixel_rect.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_placed_element_origin.dart';
import '../models/moving_prop.dart';
import '../models/project_manifest.dart';

MovingPropWorldState initializeMovingPropWorldState({
  required MapData map,
  required MovingPropWorldState worldState,
}) {
  final ids = map.movingProps.map((prop) => prop.id).toSet();
  final placements = map.movingProps
      .map((prop) => prop.placedElementId)
      .toSet();
  if (map.movingProps.length > 256 ||
      ids.length != map.movingProps.length ||
      placements.length != map.movingProps.length ||
      map.movingPlatforms.any(
        (platform) => placements.contains(platform.placedElementId),
      ) ||
      (worldState.propsByMap[map.id]?.keys.any((id) => !ids.contains(id)) ??
          false)) {
    throw const FormatException('Moving prop state does not match the map.');
  }
  var initialized = worldState;
  for (final prop in map.movingProps) {
    if (initialized.prop(map.id, prop.id) == null) {
      initialized = initialized.withProp(
        mapId: map.id,
        propId: prop.id,
        state: prop.initialState,
      );
    }
  }
  return initialized;
}

void validateMovingPropDefinitions({
  required MapData map,
  required ProjectManifest project,
  required PixelSize tileSize,
}) {
  initializeMovingPropWorldState(
    map: map,
    worldState: const MovingPropWorldState.empty(),
  );
  if (map.movingProps.isEmpty) return;
  if (map.spatialScene != null ||
      map.version == ProjectVersion.v9 ||
      tileSize.width <= 0 ||
      tileSize.height <= 0) {
    throw const FormatException('Moving props require a 2D pixel map.');
  }
  final mapWidth = map.size.width * tileSize.width;
  final mapHeight = map.size.height * tileSize.height;
  for (final prop in map.movingProps) {
    final placements = map.placedElements
        .where((placement) => placement.id == prop.placedElementId)
        .toList();
    if (placements.length != 1 ||
        !isAuthoredMapPlacedElement(placements.single)) {
      throw const FormatException(
        'A moving prop requires one authored placed visual.',
      );
    }
    final placement = placements.single;
    final visuals = project.elements
        .where((element) => element.id == placement.elementId)
        .toList();
    if (visuals.length != 1 ||
        visuals.single.frames.isEmpty ||
        visuals.single.collisionProfile?.occlusionMask != null ||
        placement.quarterTurns < 0 ||
        placement.quarterTurns > 3 ||
        !placement.opacity.isFinite ||
        placement.opacity < 0 ||
        placement.opacity > 1) {
      throw const FormatException('Moving prop visual is missing or invalid.');
    }
    for (final frame in visuals.single.frames) {
      final source = frame.source;
      final size = placement.pixelSize;
      var width = size?.width ?? source.width * tileSize.width;
      var height = size?.height ?? source.height * tileSize.height;
      if (placement.quarterTurns.isOdd) {
        (width, height) = (height, width);
      }
      if (source.x < 0 ||
          source.y < 0 ||
          source.width <= 0 ||
          source.height <= 0 ||
          width <= 0 ||
          height <= 0 ||
          prop.collisionRect.leftPx + prop.collisionRect.widthPx > width ||
          prop.collisionRect.topPx + prop.collisionRect.heightPx > height) {
        throw const FormatException(
          'Moving prop footprint exceeds its visual.',
        );
      }
      for (final position in [prop.closedPositionPx, prop.openPositionPx]) {
        if (position.x + width > mapWidth ||
            position.y + height > mapHeight ||
            position.x +
                    prop.collisionRect.leftPx +
                    prop.collisionRect.widthPx >
                mapWidth ||
            position.y +
                    prop.collisionRect.topPx +
                    prop.collisionRect.heightPx >
                mapHeight) {
          throw const FormatException('Moving prop pose exceeds the map.');
        }
      }
    }
  }
}

void validateMovingPropWorldState({
  required ProjectManifest project,
  required Iterable<MapData> maps,
  required MovingPropWorldState worldState,
}) {
  final byId = <String, MapData>{};
  for (final map in maps) {
    if (byId.containsKey(map.id)) {
      throw const FormatException(
        'Moving prop maps require unique identities.',
      );
    }
    byId[map.id] = map;
  }
  if (worldState.propsByMap.keys.any((id) => !byId.containsKey(id))) {
    throw const FormatException('Saved moving prop map is missing.');
  }
  final tileSize = PixelSize(
    width: project.settings.tileWidth,
    height: project.settings.tileHeight,
  );
  for (final map in byId.values) {
    validateMovingPropDefinitions(
      map: map,
      project: project,
      tileSize: tileSize,
    );
    initializeMovingPropWorldState(map: map, worldState: worldState);
  }
}

MapData applyMovingPropWorldStateToMap({
  required MapData map,
  required MovingPropWorldState worldState,
  required PixelSize tileSize,
  Map<String, PixelOffset> positions = const {},
}) {
  if (tileSize.width <= 0 || tileSize.height <= 0) {
    throw const FormatException('Moving prop tile size must be positive.');
  }
  final resolved = _positions(map, worldState, positions);
  if (map.movingProps.isEmpty) return map;
  final byPlacement = {
    for (final prop in map.movingProps)
      prop.placedElementId: resolved[prop.id]!,
  };
  return map.copyWith(
    placedElements: map.placedElements.map((placement) {
      final position = byPlacement[placement.id];
      if (position == null) return placement;
      return placement.copyWith(
        pos: GridPos(
          x: position.x ~/ tileSize.width,
          y: position.y ~/ tileSize.height,
        ),
        pixelOffset: PixelOffset(
          x: position.x % tileSize.width,
          y: position.y % tileSize.height,
        ),
        applyCollision: false,
      );
    }).toList(),
  );
}

Iterable<PixelRect> movingPropCollisionRects({
  required MapData map,
  required MovingPropWorldState worldState,
  Map<String, PixelOffset> positions = const {},
}) sync* {
  final resolved = _positions(map, worldState, positions);
  for (final prop in map.movingProps) {
    final position = resolved[prop.id]!;
    final rect = prop.collisionRect;
    yield PixelRect(
      leftPx: position.x + rect.leftPx,
      topPx: position.y + rect.topPx,
      widthPx: rect.widthPx,
      heightPx: rect.heightPx,
    );
  }
}

Map<String, PixelOffset> _positions(
  MapData map,
  MovingPropWorldState worldState,
  Map<String, PixelOffset> positions,
) {
  final initialized = initializeMovingPropWorldState(
    map: map,
    worldState: worldState,
  );
  final ids = map.movingProps.map((prop) => prop.id).toSet();
  if (positions.keys.any((id) => !ids.contains(id))) {
    throw const FormatException(
      'Moving prop position references a missing prop.',
    );
  }
  final result = <String, PixelOffset>{};
  for (final prop in map.movingProps) {
    final position =
        positions[prop.id] ??
        (initialized.prop(map.id, prop.id) == MovingPropState.open
            ? prop.openPositionPx
            : prop.closedPositionPx);
    final closed = prop.closedPositionPx;
    final open = prop.openPositionPx;
    if (!_between(position.x, closed.x, open.x) ||
        !_between(position.y, closed.y, open.y)) {
      throw const FormatException('Moving prop position is outside its rail.');
    }
    result[prop.id] = position;
  }
  return result;
}

bool _between(int value, int a, int b) =>
    value >= (a < b ? a : b) && value <= (a > b ? a : b);
