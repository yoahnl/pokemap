import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';

const String mapEntityCollisionWidthProperty = 'collision.width';
const String mapEntityCollisionHeightProperty = 'collision.height';
const String mapEntityCollisionOffsetXProperty = 'collision.offsetX';
const String mapEntityCollisionOffsetYProperty = 'collision.offsetY';
const String _legacyCollisionWidthProperty = 'collisionWidth';
const String _legacyCollisionHeightProperty = 'collisionHeight';
const String _legacyCollisionOffsetXProperty = 'collisionOffsetX';
const String _legacyCollisionOffsetYProperty = 'collisionOffsetY';

MapRect resolveEntityCollisionFootprint(MapEntity entity) {
  final defaultSize = _defaultCollisionSize(entity);
  final width = _clampInt(
    (_readPositiveInt(entity.properties[mapEntityCollisionWidthProperty]) ??
            _readPositiveInt(
                entity.properties[_legacyCollisionWidthProperty])) ??
        defaultSize.width,
    min: 1,
    max: entity.size.width,
  );
  final height = _clampInt(
    (_readPositiveInt(entity.properties[mapEntityCollisionHeightProperty]) ??
            _readPositiveInt(
                entity.properties[_legacyCollisionHeightProperty])) ??
        defaultSize.height,
    min: 1,
    max: entity.size.height,
  );

  final defaultOffsetX = _defaultCollisionOffsetX(entity, width);
  final defaultOffsetY = _defaultCollisionOffsetY(entity, height);
  final maxOffsetX = entity.size.width - width;
  final maxOffsetY = entity.size.height - height;

  final offsetX = _clampInt(
    (_readInt(entity.properties[mapEntityCollisionOffsetXProperty]) ??
            _readInt(entity.properties[_legacyCollisionOffsetXProperty])) ??
        defaultOffsetX,
    min: 0,
    max: maxOffsetX,
  );
  final offsetY = _clampInt(
    (_readInt(entity.properties[mapEntityCollisionOffsetYProperty]) ??
            _readInt(entity.properties[_legacyCollisionOffsetYProperty])) ??
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
  if (entity.kind == MapEntityKind.npc) {
    // NPC default collision:
    // - on aligne désormais la hitbox sur toute la taille logique du sprite.
    //
    // Pourquoi:
    // - une collision "feet only" pour les NPC 2x2 laissait des zones
    //   traversables sur le haut du sprite (perçu comme traversée).
    // - en pratique produit, la règle la plus sûre et lisible est:
    //   hitbox par défaut = volume complet de l'entité.
    //
    // Les maps qui veulent un footprint plus fin peuvent toujours fournir des
    // propriétés explicites `collision.width/height/offset`.
    return entity.size;
  }
  return entity.size;
}

int _defaultCollisionOffsetX(MapEntity entity, int collisionWidth) {
  return (entity.size.width - collisionWidth) ~/ 2;
}

int _defaultCollisionOffsetY(MapEntity entity, int collisionHeight) {
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
