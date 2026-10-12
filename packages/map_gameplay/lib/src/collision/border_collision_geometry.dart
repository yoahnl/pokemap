import 'package:map_core/map_core.dart';

Iterable<PixelRect> resolveMaterializedBorderCollisionRects({
  required MapData map,
  required ProjectManifest project,
  required PixelSize tileSize,
}) sync* {
  if (map.spatialScene != null) return;
  final elements = {
    for (final element in project.elements) element.id: element
  };
  final prepared = <String, List<PixelRect>>{};
  for (final layer in map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      final revision = project.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      final output = feature.materialization;
      if (revision == null ||
          revision.definition.isSpatial ||
          output == null ||
          output.targetsSpatialScene) {
        throw ValidationException(
            'Border collision requires published 2D materialization: ${map.id}/${layer.id}/${feature.id}');
      }
      final request = BorderResolutionRequest(
        mapSize: map.size,
        tileSizePx: GridSize(width: tileSize.width, height: tileSize.height),
        blueprintId: feature.blueprintId,
        blueprintRevision: revision,
        feature: feature,
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      final components = computeBorderInputFingerprints(request);
      final input = computeBorderAggregateInputFingerprint(
        resolverVersion: request.resolverVersion,
        blueprintRevision: revision.revision,
        components: components,
      );
      if (output.receipt.resolverVersion != request.resolverVersion ||
          output.receipt.blueprintRevision != revision.revision ||
          output.receipt.components != components ||
          output.receipt.inputFingerprint != input ||
          output.receipt.outputFingerprint !=
              computeBorderOutputFingerprint(
                  ground: output.ground, placements: output.placements)) {
        throw ValidationException(
            'Border collision materialization is stale or altered: ${map.id}/${layer.id}/${feature.id}');
      }
      final primitives = {
        for (final primitive in revision.definition.primitives)
          primitive.id: primitive
      };
      for (final placement in output.placements) {
        final primitive = primitives[placement.primitiveId];
        final element =
            primitive == null ? null : elements[primitive.sourceElementId];
        final snapshot = project.borderCatalog
            .visualSnapshotById(placement.visualSnapshotId);
        if (primitive == null ||
            primitive.isSpatial ||
            element == null ||
            snapshot == null ||
            placement.visualSnapshotId != primitive.visualSnapshotId) {
          throw ValidationException(
              'Border collision source is unavailable: ${feature.id}/${placement.primitiveId}');
        }
        final sourceSize = primitive.publishedMetrics.pixelSize;
        if (element.frames.isEmpty ||
            element.frames.any((frame) =>
                frame.source.width * tileSize.width != sourceSize.width ||
                frame.source.height * tileSize.height != sourceSize.height) ||
            snapshot.frames.any((frame) =>
                frame.sourceRectPx.width != sourceSize.width ||
                frame.sourceRectPx.height != sourceSize.height)) {
          throw ValidationException(
              'Border collision source dimensions diverged: ${element.id}');
        }
        final localGeometry = resolveBorderSpriteGeometry(
          metrics: primitive.publishedMetrics,
          sourceAnchorPx: primitive.anchorPx,
          transform: placement.transform,
          targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
        );
        final bounds = localGeometry.opaqueWorldBoundsPx;
        if (placement.opaqueWorldBoundsPx !=
            BorderPixelRect(
              x: _sum(placement.topLeftWorldPx.x,
                  bounds.x - localGeometry.topLeftWorldPx.x),
              y: _sum(placement.topLeftWorldPx.y,
                  bounds.y - localGeometry.topLeftWorldPx.y),
              width: bounds.width,
              height: bounds.height,
            )) {
          throw ValidationException(
              'Border collision output geometry diverged: ${placement.id}');
        }
        final profile = element.collisionProfile;
        if (profile == null) continue;
        final localRects = prepared.putIfAbsent(
            element.id,
            () => resolveMapPlacedElementCollisionRects(
                  instance: MapPlacedElement(
                      id: element.id,
                      layerId: layer.id,
                      elementId: element.id,
                      pos: const GridPos(x: 0, y: 0)),
                  element: element,
                  tileSize: tileSize,
                ).toList(growable: false));
        final transform = QuarterTurnPixelTransform(
          sourcePixelSize: sourceSize,
          destinationPixelSize: localGeometry.transformedPixelSize,
          quarterTurns: placement.transform.quarterTurns,
        );
        for (final rect in localRects) {
          final flipped = placement.transform.flipX
              ? PixelRect(
                  leftPx: sourceSize.width - rect.leftPx - rect.widthPx,
                  topPx: rect.topPx,
                  widthPx: rect.widthPx,
                  heightPx: rect.heightPx,
                )
              : rect;
          final rotated =
              transform.sourcePixelRectToDestinationPixelRect(flipped);
          yield PixelRect(
            leftPx: _sum(placement.topLeftWorldPx.x, rotated.leftPx),
            topPx: _sum(placement.topLeftWorldPx.y, rotated.topPx),
            widthPx: rotated.widthPx,
            heightPx: rotated.heightPx,
          );
        }
      }
    }
  }
}

int _sum(int origin, int offset) {
  final value = BigInt.from(origin) + BigInt.from(offset);
  if (value.abs() > BigInt.from(9007199254740991)) {
    throw const ValidationException(
        'Border collision geometry exceeds exact integer representation');
  }
  return value.toInt();
}
