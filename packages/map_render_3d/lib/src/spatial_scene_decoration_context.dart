part of 'spatial_scene_decoration.dart';

typedef _DecorationNativeMap = ({
  MapData map,
  Offset offset,
  Set<(int, int)> excluded,
});

void _prepareDecorationNativeContexts(
  List<SpatialDecorationProjection> projections,
  List<({MapData map, Offset offset})> nativeMaps,
  Map<String, SpatialDecorationProjection> previous,
  Offset sceneOffset,
) {
  final playable = [...nativeMaps]
    ..sort((a, b) => a.map.id.compareTo(b.map.id));
  final sources = <_DecorationNativeMap>[
    for (final source in playable)
      (
        map: source.map,
        offset: source.offset + sceneOffset,
        excluded: const {},
      ),
    for (final projection in projections.where(
      (projection) => projection.renderTerrainBase,
    ))
      (
        map: projection.map,
        offset: projection.offset,
        excluded: projection.excludedCells,
      ),
  ];
  for (final projection in projections) {
    final bounds = Rect.fromLTWH(
      projection.offset.dx,
      projection.offset.dy,
      projection.sector.scene.width.toDouble(),
      projection.sector.scene.depth.toDouble(),
    ).inflate(1.001);
    final adjacent = [
      for (final source in sources)
        if (bounds.overlaps(
          Rect.fromLTWH(
            source.offset.dx,
            source.offset.dy,
            source.map.size.width.toDouble(),
            source.map.size.height.toDouble(),
          ),
        ))
          source,
    ];
    final signature = _decorationContextSignature(projection, adjacent);
    final prior = previous[projection.key];
    projection._nativeContextSignature = signature;
    if (prior != null && listEquals(prior._nativeContextSignature, signature)) {
      projection.cellContextResolvers = prior.cellContextResolvers;
      continue;
    }
    projection.cellContextResolvers = Map.unmodifiable({
      for (final layer in projection.map.layers.whereType<SmartTileLayer>())
        layer.id: ({
          required ProjectSmartTilePreset preset,
          required int x,
          required int y,
        }) => _decorationCellContext(projection, adjacent, layer, preset, x, y),
    });
  }
}

List<Object?> _decorationContextSignature(
  SpatialDecorationProjection projection,
  List<_DecorationNativeMap> sources,
) {
  final signature = <Object?>[];
  final layers = projection.map.layers.whereType<SmartTileLayer>().toList();
  for (final source in sources) {
    final size = source.map.size;
    final dx = projection.offset.dx - source.offset.dx;
    final dy = projection.offset.dy - source.offset.dy;
    if (dx != dx.roundToDouble() || dy != dy.roundToDouble()) continue;
    signature.add((source.map.id, source.offset, size));
    final own = identical(source.map, projection.map);
    final left = (projection.offset.dx - source.offset.dx - 1).ceil();
    final top = (projection.offset.dy - source.offset.dy - 1).ceil();
    final right =
        (projection.offset.dx + projection.map.size.width - source.offset.dx)
            .floor();
    final bottom =
        (projection.offset.dy + projection.map.size.height - source.offset.dy)
            .floor();
    if (right < 0 || bottom < 0 || left > size.width || top > size.height)
      continue;
    for (final layer in layers) {
      final match = source.map.layers
          .whereType<SmartTileLayer>()
          .where(
            (candidate) =>
                candidate.id == layer.id &&
                candidate.presetId == layer.presetId &&
                candidate.usage == layer.usage &&
                candidate.isVisible &&
                candidate.opacity > 0,
          )
          .firstOrNull;
      signature.add((layer.id, layer.presetId, layer.usage));
      if (own) {
        signature.add(match);
        signature.add(source.excluded);
        continue;
      }
      final topology = projection.source.project.smartTileCatalog.presets
          .where((preset) => preset.id == layer.presetId)
          .firstOrNull
          ?.topology;
      signature.add(topology);
      final cellTopology =
          topology == null ||
          topology == SmartTileTopology.uniform ||
          topology == SmartTileTopology.cardinal4 ||
          topology == SmartTileTopology.blob8;
      final edges = !cellTopology && topology != SmartTileTopology.wangCorner4;
      final corners = !cellTopology && topology != SmartTileTopology.wangEdge4;
      final hasHorizontal =
          match != null && smartTileHorizontalEdges(match).isNotEmpty;
      final hasVertical =
          match != null && smartTileVerticalEdges(match).isNotEmpty;
      final hasCorners = match != null && smartTileCorners(match).isNotEmpty;
      final width = projection.map.size.width,
          depth = projection.map.size.height;
      for (
        var y = top.clamp(0, size.height);
        y <= bottom.clamp(0, size.height);
        y++
      ) {
        for (
          var x = left.clamp(0, size.width);
          x <= right.clamp(0, size.width);
          x++
        ) {
          final px = x - dx, py = y - dy;
          final excluded = source.excluded.contains((
            x.clamp(0, size.width - 1),
            y.clamp(0, size.height - 1),
          ));
          if (x < size.width &&
              y < size.height &&
              (cellTopology ||
                  px >= 0 && px < width && py >= 0 && py < depth)) {
            signature.add((
              #cell,
              x,
              y,
              excluded,
              excluded || match == null
                  ? null
                  : smartTileMaterialIdAt(match, mapSize: size, x: x, y: y),
            ));
          }
          if (edges &&
              x < size.width &&
              px >= 0 &&
              px < width &&
              py >= 0 &&
              py <= depth) {
            signature.add((
              #horizontal,
              x,
              y,
              excluded,
              excluded || !hasHorizontal
                  ? null
                  : smartTileHorizontalEdgeMaterialIdAt(
                      match,
                      mapSize: size,
                      x: x,
                      y: y,
                    ),
            ));
          }
          if (edges &&
              y < size.height &&
              px >= 0 &&
              px <= width &&
              py >= 0 &&
              py < depth) {
            signature.add((
              #vertical,
              x,
              y,
              excluded,
              excluded || !hasVertical
                  ? null
                  : smartTileVerticalEdgeMaterialIdAt(
                      match,
                      mapSize: size,
                      x: x,
                      y: y,
                    ),
            ));
          }
          if (corners && px >= 0 && px <= width && py >= 0 && py <= depth) {
            signature.add((
              #corner,
              x,
              y,
              excluded,
              excluded || !hasCorners
                  ? null
                  : smartTileCornerMaterialIdAt(
                      match,
                      mapSize: size,
                      x: x,
                      y: y,
                    ),
            ));
          }
        }
      }
    }
  }
  return signature;
}

SmartTileCellContext _decorationCellContext(
  SpatialDecorationProjection projection,
  List<_DecorationNativeMap> sources,
  SmartTileLayer layer,
  ProjectSmartTilePreset preset,
  int x,
  int y,
) {
  SmartTileObservedSlot sample(
    int localX,
    int localY, [
    String lattice = 'cell',
  ]) {
    final worldX = projection.offset.dx + localX;
    final worldY = projection.offset.dy + localY;
    for (final source in sources) {
      final sourceX = worldX - source.offset.dx;
      final sourceY = worldY - source.offset.dy;
      if (sourceX != sourceX.roundToDouble() ||
          sourceY != sourceY.roundToDouble())
        continue;
      final sx = sourceX.toInt(), sy = sourceY.toInt();
      final width = source.map.size.width, depth = source.map.size.height;
      final valid = switch (lattice) {
        'horizontal' => sx >= 0 && sx < width && sy >= 0 && sy <= depth,
        'vertical' => sx >= 0 && sx <= width && sy >= 0 && sy < depth,
        'corner' => sx >= 0 && sx <= width && sy >= 0 && sy <= depth,
        _ => sx >= 0 && sx < width && sy >= 0 && sy < depth,
      };
      if (!valid ||
          source.excluded.contains((
            sx.clamp(0, width - 1),
            sy.clamp(0, depth - 1),
          )))
        continue;
      final match = source.map.layers
          .whereType<SmartTileLayer>()
          .where(
            (candidate) =>
                candidate.id == layer.id &&
                candidate.presetId == layer.presetId &&
                candidate.usage == layer.usage &&
                candidate.isVisible &&
                candidate.opacity > 0,
          )
          .firstOrNull;
      if (match == null) return const SmartTileObservedSlot.inside();
      final material = switch (lattice) {
        'horizontal' => smartTileHorizontalEdgeMaterialIdAt(
          match,
          mapSize: source.map.size,
          x: sx,
          y: sy,
        ),
        'vertical' => smartTileVerticalEdgeMaterialIdAt(
          match,
          mapSize: source.map.size,
          x: sx,
          y: sy,
        ),
        'corner' => smartTileCornerMaterialIdAt(
          match,
          mapSize: source.map.size,
          x: sx,
          y: sy,
        ),
        _ => smartTileMaterialIdAt(
          match,
          mapSize: source.map.size,
          x: sx,
          y: sy,
        ),
      };
      return SmartTileObservedSlot.inside(materialId: material);
    }
    return const SmartTileObservedSlot.outside();
  }

  final center = sample(x, y).materialId;
  return switch (preset.topology) {
    SmartTileTopology.uniform ||
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.blob8 => SmartTileCellContext(
      centerMaterialId: center,
      observed: SmartTileObservedSignature(
        northEdge: sample(x, y - 1),
        northEastCorner: sample(x + 1, y - 1),
        eastEdge: sample(x + 1, y),
        southEastCorner: sample(x + 1, y + 1),
        southEdge: sample(x, y + 1),
        southWestCorner: sample(x - 1, y + 1),
        westEdge: sample(x - 1, y),
        northWestCorner: sample(x - 1, y - 1),
      ),
    ),
    SmartTileTopology.wangEdge4 ||
    SmartTileTopology.wangCorner4 ||
    SmartTileTopology.wang8 => SmartTileCellContext(
      centerMaterialId: center,
      observed: SmartTileObservedSignature(
        northEdge: preset.topology == SmartTileTopology.wangCorner4
            ? const SmartTileObservedSlot.outside()
            : sample(x, y, 'horizontal'),
        northEastCorner: preset.topology == SmartTileTopology.wangEdge4
            ? const SmartTileObservedSlot.outside()
            : sample(x + 1, y, 'corner'),
        eastEdge: preset.topology == SmartTileTopology.wangCorner4
            ? const SmartTileObservedSlot.outside()
            : sample(x + 1, y, 'vertical'),
        southEastCorner: preset.topology == SmartTileTopology.wangEdge4
            ? const SmartTileObservedSlot.outside()
            : sample(x + 1, y + 1, 'corner'),
        southEdge: preset.topology == SmartTileTopology.wangCorner4
            ? const SmartTileObservedSlot.outside()
            : sample(x, y + 1, 'horizontal'),
        southWestCorner: preset.topology == SmartTileTopology.wangEdge4
            ? const SmartTileObservedSlot.outside()
            : sample(x, y + 1, 'corner'),
        westEdge: preset.topology == SmartTileTopology.wangCorner4
            ? const SmartTileObservedSlot.outside()
            : sample(x, y, 'vertical'),
        northWestCorner: preset.topology == SmartTileTopology.wangEdge4
            ? const SmartTileObservedSlot.outside()
            : sample(x, y, 'corner'),
      ),
    ),
  };
}
