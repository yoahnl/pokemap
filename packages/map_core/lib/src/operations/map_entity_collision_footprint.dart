import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

const String mapEntityCollisionWidthProperty = 'collision.width';
const String mapEntityCollisionHeightProperty = 'collision.height';
const String mapEntityCollisionOffsetXProperty = 'collision.offsetX';
const String mapEntityCollisionOffsetYProperty = 'collision.offsetY';

MapRect resolveEntityCollisionFootprint(MapEntity entity) {
  final defaultSize = _defaultCollisionSize(entity);
  final width = _clampInt(
    _readPositiveInt(entity.properties[mapEntityCollisionWidthProperty]) ??
        defaultSize.width,
    min: 1,
    max: entity.size.width,
  );
  final height = _clampInt(
    _readPositiveInt(entity.properties[mapEntityCollisionHeightProperty]) ??
        defaultSize.height,
    min: 1,
    max: entity.size.height,
  );

  final defaultOffsetX = _defaultCollisionOffsetX(entity, width);
  final defaultOffsetY = _defaultCollisionOffsetY(entity, height);
  final maxOffsetX = entity.size.width - width;
  final maxOffsetY = entity.size.height - height;

  final offsetX = _clampInt(
    _readInt(entity.properties[mapEntityCollisionOffsetXProperty]) ??
        defaultOffsetX,
    min: 0,
    max: maxOffsetX,
  );
  final offsetY = _clampInt(
    _readInt(entity.properties[mapEntityCollisionOffsetYProperty]) ??
        defaultOffsetY,
    min: 0,
    max: maxOffsetY,
  );

  return MapRect(
    pos: GridPos(
      x: entity.pos.x + offsetX,
      y: entity.pos.y + offsetY,
    ),
    size: GridSize(width: width, height: height),
  );
}

Iterable<GridPos> resolveEntityCollisionCells(MapEntity entity) sync* {
  final footprint = resolveEntityCollisionFootprint(entity);
  for (var dy = 0; dy < footprint.size.height; dy++) {
    for (var dx = 0; dx < footprint.size.width; dx++) {
      yield GridPos(
        x: footprint.pos.x + dx,
        y: footprint.pos.y + dy,
      );
    }
  }
}

GridSize _defaultCollisionSize(MapEntity entity) {
  return switch (entity.kind) {
    MapEntityKind.npc => const GridSize(width: 1, height: 1),
    _ => entity.size,
  };
}

int _defaultCollisionOffsetX(MapEntity entity, int collisionWidth) {
  if (entity.kind != MapEntityKind.npc) {
    return 0;
  }
  return (entity.size.width - collisionWidth) ~/ 2;
}

int _defaultCollisionOffsetY(MapEntity entity, int collisionHeight) {
  if (entity.kind != MapEntityKind.npc) {
    return 0;
  }
  return entity.size.height - collisionHeight;
}

int _clampInt(
  int value, {
  required int min,
  required int max,
}) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

int? _readPositiveInt(String? raw) {
  if (raw == null) return null;
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

int? _readInt(String? raw) {
  if (raw == null) return null;
  return int.tryParse(raw.trim());
}
