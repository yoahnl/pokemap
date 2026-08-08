part of '../map_canvas.dart';

/// Visual-only first-level preview of maps connected to the active map.
///
/// Neighbor painters deliberately opt out of editor chrome, overlays and
/// pointer handling. The active map remains the sole interaction surface.
class MapConnectionContextLayer extends StatelessWidget {
  const MapConnectionContextLayer({
    super.key,
    required this.context,
    required this.selectedDirection,
    required this.zoom,
    required this.offset,
    required this.tileWidth,
    required this.tileHeight,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.tilesetImagesById,
    required this.tilesPerRowById,
    required this.project,
    this.shadowLightPreviewPreset,
    this.animationClock,
  });

  static const double inactiveOpacity = 0.36;
  static const double selectedOpacity = 0.62;

  final WorldMapConnectionContext context;
  final MapConnectionDirection selectedDirection;
  final double zoom;
  final Offset offset;
  final double tileWidth;
  final double tileHeight;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final Map<String, ui.Image?> tilesetImagesById;
  final Map<String, int> tilesPerRowById;
  final ProjectManifest? project;
  final EditorShadowLightPreviewPreset? shadowLightPreviewPreset;
  final EditorCanvasRepaintClock? animationClock;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final neighbor in this.context.neighbors.values)
            Positioned.fill(
              child: IgnorePointer(
                key: ValueKey<String>(
                  'map-connection-context-ignore-pointer-'
                  '${neighbor.direction.name}',
                ),
                ignoring: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        key: ValueKey<String>(
                          'map-connection-context-opacity-'
                          '${neighbor.direction.name}',
                        ),
                        opacity: neighbor.direction == selectedDirection
                            ? selectedOpacity
                            : inactiveOpacity,
                        child: CustomPaint(
                          key: ValueKey<String>(
                            'map-connection-context-painter-'
                            '${neighbor.direction.name}',
                          ),
                          painter: MapGridPainter(
                            map: neighbor.map,
                            zoom: zoom,
                            offset: _neighborOffset(neighbor),
                            tileWidth: tileWidth,
                            tileHeight: tileHeight,
                            tilesetImagesById: tilesetImagesById,
                            sourceTileWidth: sourceTileWidth,
                            sourceTileHeight: sourceTileHeight,
                            tilesPerRowById: tilesPerRowById,
                            warps: neighbor.map.warps,
                            gameplayZones: neighbor.map.gameplayZones,
                            connectionLabelsByDirection:
                                resolveMapConnectionLabels(
                              neighbor.map,
                              project,
                            ),
                            project: project,
                            shadowLightPreviewPreset: shadowLightPreviewPreset,
                            animationClock: animationClock,
                            showGrid: false,
                            showEntityEditorChrome: false,
                            showEditorOverlays: false,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _neighborLabelOffset(neighbor).dx,
                      top: _neighborLabelOffset(neighbor).dy,
                      child: PokeMapBadge(
                        key: ValueKey<String>(
                          'map-connection-context-label-'
                          '${neighbor.direction.name}',
                        ),
                        label: '${neighbor.entry.name} · '
                            '${_directionLabel(neighbor.direction)}',
                        variant: neighbor.direction == selectedDirection
                            ? PokeMapBadgeVariant.mapAccent
                            : PokeMapBadgeVariant.neutral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (final issue in this.context.issues.values)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MapConnectionIssueOutlinePainter(
                          direction: issue.direction,
                          mapSize: this.context.sourceMap.size,
                          zoom: zoom,
                          offset: offset,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          color: colors.errorBorder,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _issueLabelOffset(issue.direction).dx,
                      top: _issueLabelOffset(issue.direction).dy,
                      child: PokeMapBadge(
                        key: ValueKey<String>(
                          'map-connection-context-issue-'
                          '${issue.direction.name}',
                        ),
                        label: '${_directionLabel(issue.direction)} · '
                            '${issue.message}',
                        variant: PokeMapBadgeVariant.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Offset _neighborOffset(WorldMapConnectionNeighbor neighbor) => Offset(
        offset.dx + neighbor.tileBounds.left * tileWidth * zoom,
        offset.dy + neighbor.tileBounds.top * tileHeight * zoom,
      );

  Offset _neighborLabelOffset(WorldMapConnectionNeighbor neighbor) {
    final origin = _neighborOffset(neighbor);
    return origin + const Offset(8, 8);
  }

  Offset _issueLabelOffset(MapConnectionDirection direction) {
    final width = context.sourceMap.size.width * tileWidth * zoom;
    final height = context.sourceMap.size.height * tileHeight * zoom;
    return switch (direction) {
      MapConnectionDirection.north => offset + const Offset(8, 8),
      MapConnectionDirection.east => offset + Offset(width - 8, 8),
      MapConnectionDirection.south => offset + Offset(8, height - 8),
      MapConnectionDirection.west => offset + const Offset(8, 8),
    };
  }

  static String _directionLabel(MapConnectionDirection direction) =>
      switch (direction) {
        MapConnectionDirection.north => 'Nord',
        MapConnectionDirection.east => 'Est',
        MapConnectionDirection.south => 'Sud',
        MapConnectionDirection.west => 'Ouest',
      };
}

Map<MapConnectionDirection, String> resolveMapConnectionLabels(
  MapData? map,
  ProjectManifest? project,
) {
  final result = <MapConnectionDirection, String>{};
  if (map == null || project == null) return result;
  final projectMapById = <String, ProjectMapEntry>{
    for (final mapEntry in project.maps) mapEntry.id: mapEntry,
  };
  for (final connection in map.connections) {
    final mapEntry = projectMapById[connection.targetMapId];
    result[connection.direction] = mapEntry?.name ?? connection.targetMapId;
  }
  return result;
}

class _MapConnectionIssueOutlinePainter extends CustomPainter {
  const _MapConnectionIssueOutlinePainter({
    required this.direction,
    required this.mapSize,
    required this.zoom,
    required this.offset,
    required this.tileWidth,
    required this.tileHeight,
    required this.color,
  });

  final MapConnectionDirection direction;
  final GridSize mapSize;
  final double zoom;
  final Offset offset;
  final double tileWidth;
  final double tileHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = mapSize.width * tileWidth * zoom;
    final height = mapSize.height * tileHeight * zoom;
    final (start, end) = switch (direction) {
      MapConnectionDirection.north => (
          offset,
          offset + Offset(width, 0),
        ),
      MapConnectionDirection.east => (
          offset + Offset(width, 0),
          offset + Offset(width, height),
        ),
      MapConnectionDirection.south => (
          offset + Offset(0, height),
          offset + Offset(width, height),
        ),
      MapConnectionDirection.west => (
          offset,
          offset + Offset(0, height),
        ),
    };
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_MapConnectionIssueOutlinePainter oldDelegate) =>
      direction != oldDelegate.direction ||
      mapSize != oldDelegate.mapSize ||
      zoom != oldDelegate.zoom ||
      offset != oldDelegate.offset ||
      tileWidth != oldDelegate.tileWidth ||
      tileHeight != oldDelegate.tileHeight ||
      color != oldDelegate.color;
}
