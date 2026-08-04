import 'package:map_core/map_core.dart';

final class ImageCollectionPropPreviewItem {
  const ImageCollectionPropPreviewItem({
    required this.tileId,
    required this.displayName,
    required this.visual,
  });

  final int tileId;
  final String displayName;
  final ProjectTilesetVisualResolution visual;

  bool get isAnimated => visual.isAnimated;
  int get frameCount => visual.frames.length;

  String get pixelSizeLabel {
    final bounds = visual.animationBounds;
    return '${bounds.width} × ${bounds.height} px';
  }
}

/// Builds the no-code prop library while hiding animation-only source frames.
///
/// A referenced frame remains visible when it owns metadata, collision or its
/// own animation. That keeps independently authored props discoverable while
/// avoiding a gallery full of implementation frames.
List<ImageCollectionPropPreviewItem> buildImageCollectionPropPreviewItems({
  required ProjectImageCollectionTilesetSource source,
  required int cellWidth,
  required int cellHeight,
}) {
  final referencedFrameIds = <int>{
    for (final tile in source.tileDefinitions)
      for (final frame in tile.animation) frame.tileId,
  };
  final definitions = source.tileDefinitions
      .where(
        (tile) =>
            !referencedFrameIds.contains(tile.tileId) ||
            tile.animation.isNotEmpty ||
            tile.properties.isNotEmpty ||
            tile.collisionObjects.isNotEmpty,
      )
      .toList(growable: false)
    ..sort((left, right) => left.tileId.compareTo(right.tileId));
  const resolver = ProjectTilesetVisualResolver();
  return List<ImageCollectionPropPreviewItem>.unmodifiable(
    <ImageCollectionPropPreviewItem>[
      for (var index = 0; index < definitions.length; index += 1)
        ImageCollectionPropPreviewItem(
          tileId: definitions[index].tileId,
          displayName: _displayName(definitions[index], index),
          visual: resolver.resolve(
            source: source,
            selection: ProjectTilesetVisualSelection.imageCollection(
              tileId: definitions[index].tileId,
            ),
            cellWidth: cellWidth,
            cellHeight: cellHeight,
          ),
        ),
    ],
  );
}

String _displayName(ProjectImageCollectionTileDefinition tile, int index) {
  const preferredNames = <String>{'displayname', 'name', 'label'};
  for (final property in tile.properties) {
    if (property.type != ProjectTilesetPropertyType.string ||
        !preferredNames.contains(property.name.trim().toLowerCase())) {
      continue;
    }
    final value = property.value;
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return 'Élément ${index + 1}';
}
