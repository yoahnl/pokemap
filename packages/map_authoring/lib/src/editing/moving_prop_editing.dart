import 'package:map_core/map_core.dart';

final class MovingPropEditing {
  const MovingPropEditing();

  MovingPropDefinition definition({
    required MapData map,
    required ProjectManifest project,
    required String placedElementId,
    required EntityFacing direction,
    required int distancePx,
    required PixelRect collisionRect,
    MovingPropState initialState = MovingPropState.closed,
  }) {
    if (distancePx < 1 || distancePx > 1024) {
      throw const FormatException(
          'Moving prop distance must be 1..1024 pixels.');
    }
    final placement =
        map.placedElements.singleWhere((value) => value.id == placedElementId);
    final previous = map.movingProps
        .where((value) => value.placedElementId == placedElementId)
        .firstOrNull;
    var id = previous?.id ?? 'prop-$placedElementId';
    if (previous == null) {
      var suffix = 2;
      while (map.movingProps.any((prop) => prop.id == id)) {
        id = 'prop-$placedElementId-${suffix++}';
      }
    }
    final closed = previous?.closedPositionPx ??
        PixelOffset(
            x: placement.pos.x * project.settings.tileWidth +
                placement.pixelOffset.x,
            y: placement.pos.y * project.settings.tileHeight +
                placement.pixelOffset.y);
    final (dx, dy) = switch (direction) {
      EntityFacing.north => (0, -distancePx),
      EntityFacing.south => (0, distancePx),
      EntityFacing.east => (distancePx, 0),
      EntityFacing.west => (-distancePx, 0),
    };
    return MovingPropDefinition(
        id: id,
        placedElementId: placedElementId,
        closedPositionPx: closed,
        openPositionPx: PixelOffset(x: closed.x + dx, y: closed.y + dy),
        collisionRect: collisionRect,
        initialState: initialState);
  }

  MapData upsert(
      {required MapData map,
      required ProjectManifest project,
      required MovingPropDefinition prop}) {
    final after = map.copyWith(movingProps: [
      for (final existing in map.movingProps)
        if (existing.id != prop.id) existing,
      prop,
    ]);
    validateMovingPropDefinitions(
        map: after,
        project: project,
        tileSize: PixelSize(
            width: project.settings.tileWidth,
            height: project.settings.tileHeight));
    return _projectInitialState(after, project);
  }

  MapData reconcilePlacementChanges(
      {required MapData before,
      required MapData after,
      required ProjectManifest project}) {
    if (after.movingProps.isEmpty) return after;
    final tile = PixelSize(
        width: project.settings.tileWidth, height: project.settings.tileHeight);
    final props = <MovingPropDefinition>[];
    for (final prop in after.movingProps) {
      final previousProp =
          before.movingProps.where((value) => value.id == prop.id).firstOrNull;
      final previous = before.placedElements
          .where((value) => value.id == prop.placedElementId)
          .firstOrNull;
      final placement = after.placedElements
          .where((value) => value.id == prop.placedElementId)
          .firstOrNull;
      if (previousProp != prop || previous == null || placement == null) {
        props.add(prop);
        continue;
      }
      final dx = (placement.pos.x - previous.pos.x) * tile.width +
          placement.pixelOffset.x -
          previous.pixelOffset.x;
      final dy = (placement.pos.y - previous.pos.y) * tile.height +
          placement.pixelOffset.y -
          previous.pixelOffset.y;
      props.add(dx == 0 && dy == 0
          ? prop
          : MovingPropDefinition(
              id: prop.id,
              placedElementId: prop.placedElementId,
              closedPositionPx: PixelOffset(
                  x: prop.closedPositionPx.x + dx,
                  y: prop.closedPositionPx.y + dy),
              openPositionPx: PixelOffset(
                  x: prop.openPositionPx.x + dx, y: prop.openPositionPx.y + dy),
              collisionRect: prop.collisionRect,
              initialState: prop.initialState));
    }
    final result = after.copyWith(movingProps: props);
    validateMovingPropDefinitions(
        map: result, project: project, tileSize: tile);
    return _projectInitialState(result == after ? after : result, project);
  }

  MapData _projectInitialState(MapData map, ProjectManifest project) {
    final collisions = {
      for (final placement in map.placedElements)
        placement.id: placement.applyCollision
    };
    final projected = applyMovingPropWorldStateToMap(
        map: map,
        worldState: const MovingPropWorldState.empty(),
        tileSize: PixelSize(
            width: project.settings.tileWidth,
            height: project.settings.tileHeight));
    final result = projected.copyWith(placedElements: [
      for (final placement in projected.placedElements)
        placement.copyWith(applyCollision: collisions[placement.id]!)
    ]);
    return result == map ? map : result;
  }

  MapData delete(
      {required MapData map,
      required ProjectManifest project,
      required String propId}) {
    if (!map.movingProps.any((prop) => prop.id == propId)) {
      throw const FormatException('The moving prop does not exist.');
    }
    final dependencies =
        buildNarrativeDependencyIndex(project: project, maps: [map]);
    if (dependencies
        .usagesFor(NarrativeDependencyKey.mapSource(
            mapId: map.id, sourceKind: 'movingProp', sourceId: propId))
        .isNotEmpty) {
      throw const FormatException('The prop is used by a Scene.');
    }
    return map.copyWith(movingProps: [
      for (final prop in map.movingProps)
        if (prop.id != propId) prop
    ]);
  }
}
