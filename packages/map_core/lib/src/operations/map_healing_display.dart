import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/map_spatial_scene.dart';
import '../models/map_data.dart';
import '../models/narrative_map_view.dart';
import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';
import 'project_tileset_visual_resolver.dart';

MapEntity? resolveHealingDisplayEntity(NarrativeMapView map, String entityId) {
  if (entityId.isEmpty ||
      entityId.trim() != entityId ||
      map.spatialScene != null ||
      map.version == ProjectVersion.v9) {
    return null;
  }
  final matches = map.entities
      .where((entity) => entity.id == entityId)
      .toList();
  if (matches.length != 1) return null;
  final entity = matches.single;
  if (entity.healingDisplay == null ||
      entity.kind != MapEntityKind.custom ||
      entity.blocksMovement ||
      entity.size.width != 1 ||
      entity.size.height != 1 ||
      entity.npc != null ||
      entity.sign != null ||
      entity.item != null ||
      entity.spawn != null ||
      entity.fieldObstacle != null ||
      entity.editorVisual != null ||
      entity.pos.x < 0 ||
      entity.pos.y < 0 ||
      entity.pos.x >= map.size.width ||
      entity.pos.y >= map.size.height ||
      healingDisplayHasCollisionOverride(entity)) {
    return null;
  }
  return entity;
}

bool healingDisplayHasCollisionOverride(MapEntity entity) =>
    entity.properties.keys.any(
      (key) =>
          key.startsWith('collision.') ||
          const {
            'collisionWidth',
            'collisionHeight',
            'collisionOffsetX',
            'collisionOffsetY',
          }.contains(key),
    );

void assertHealingDisplayVisualsAgainstProject(
  MapEntity entity,
  ProjectManifest project,
) {
  final display = entity.healingDisplay;
  if (display == null) return;
  if (project.settings.dimension != ProjectDimension.twoD) {
    throw const ValidationException('Healing displays require a 2D project.');
  }
  int? width;
  int? height;
  for (final id in display.variantElementIds) {
    final elements = project.elements
        .where((element) => element.id == id)
        .toList();
    if (elements.length != 1 ||
        elements.single.frames.isEmpty ||
        elements.single.collisionProfile != null) {
      throw ValidationException(
        'Healing display ${entity.id} requires a unique noncolliding native element: $id',
      );
    }
    final element = elements.single;
    for (final frame in element.frames) {
      final tilesetId = frame.tilesetId.isEmpty
          ? element.tilesetId
          : frame.tilesetId;
      final tilesets = project.tilesets
          .where((tileset) => tileset.id == tilesetId)
          .toList();
      if (tilesets.length != 1 ||
          tilesets.single.source is! ProjectRegularAtlasTilesetSource ||
          (frame.durationMs != null && frame.durationMs! <= 0)) {
        throw ValidationException(
          'Healing display ${entity.id} references an invalid native frame.',
        );
      }
      final source =
          tilesets.single.source! as ProjectRegularAtlasTilesetSource;
      final ProjectTilesetVisualResolution resolved;
      try {
        resolved = const ProjectTilesetVisualResolver().resolve(
          source: source,
          selection: ProjectTilesetVisualSelection.regularAtlas(
            source: frame.source,
          ),
          cellWidth: source.tileWidth,
          cellHeight: source.tileHeight,
        );
      } on ProjectTilesetVisualResolutionException {
        throw ValidationException(
          'Healing display ${entity.id} references an out-of-bounds native frame.',
        );
      }
      final bounds = resolved.animationBounds;
      if (bounds.width > 512 ||
          bounds.height > 512 ||
          (width != null && width != bounds.width) ||
          (height != null && height != bounds.height)) {
        throw ValidationException(
          'Healing display ${entity.id} requires bounded equal-sized native frames.',
        );
      }
      width = bounds.width;
      height = bounds.height;
    }
  }
}
