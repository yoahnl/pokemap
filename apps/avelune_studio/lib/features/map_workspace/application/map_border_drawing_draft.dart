import 'package:map_core/map_core_domain.dart';

final class MapBorderDrawingDraft {
  MapBorderDrawingDraft._({
    required this.mapId,
    required this.mapSize,
    required this.blueprintId,
    required this.alignment,
    required List<GridPos> anchors,
    required this.hover,
    required this.closed,
  }) : anchors = List.unmodifiable(anchors);

  factory MapBorderDrawingDraft.start({
    required String mapId,
    required GridSize mapSize,
    required String blueprintId,
    BorderStrokeAlignment alignment = BorderStrokeAlignment.cellCenters,
    required GridPos origin,
  }) {
    _requireInside(origin, mapSize, alignment);
    return MapBorderDrawingDraft._(
      mapId: mapId,
      mapSize: mapSize,
      blueprintId: blueprintId,
      alignment: alignment,
      anchors: [origin],
      hover: null,
      closed: false,
    );
  }

  final String mapId;
  final GridSize mapSize;
  final String blueprintId;
  final BorderStrokeAlignment alignment;
  final List<GridPos> anchors;
  final GridPos? hover;
  final bool closed;

  MapBorderDrawingDraft addAngle(GridPos point) {
    _requireInside(point, mapSize, alignment);
    if (closed || point == anchors.last) return this;
    final closes = point == anchors.first && anchors.length >= 3;
    final next = closes ? anchors : [...anchors, point];
    if (next.length > 1) {
      canonicalizeBorderStrokeV1(
        id: 'trait',
        sampledPoints: closes ? [...next, point] : next,
        closed: closes,
      );
    }
    return MapBorderDrawingDraft._(
      mapId: mapId,
      mapSize: mapSize,
      blueprintId: blueprintId,
      alignment: alignment,
      anchors: next,
      hover: null,
      closed: closes,
    );
  }

  MapBorderDrawingDraft pointAt(GridPos? point) => MapBorderDrawingDraft._(
    mapId: mapId,
    mapSize: mapSize,
    blueprintId: blueprintId,
    alignment: alignment,
    anchors: anchors,
    hover: point != null && _inside(point, mapSize, alignment) && !closed
        ? point
        : null,
    closed: closed,
  );

  MapBorderDrawingDraft? removeLastAngle() {
    if (anchors.length == 1) return null;
    return MapBorderDrawingDraft._(
      mapId: mapId,
      mapSize: mapSize,
      blueprintId: blueprintId,
      alignment: alignment,
      anchors: anchors.sublist(0, anchors.length - 1),
      hover: null,
      closed: false,
    );
  }

  List<GridPos> get anchoredCells =>
      _rasterize(closed ? [...anchors, anchors.first] : anchors);

  List<GridPos> get previewCells => hover == null || hover == anchors.last
      ? anchoredCells
      : _rasterize([...anchors, hover!]);

  BorderStroke get stroke => canonicalizeBorderStrokeV1(
    id: 'trait',
    sampledPoints: closed ? [...anchors, anchors.first] : anchors,
    closed: closed,
  );

  bool get canFinish {
    try {
      stroke;
      return true;
    } on ValidationException {
      return false;
    }
  }
}

List<GridPos> _rasterize(List<GridPos> points) {
  final result = <GridPos>[points.first];
  for (var index = 1; index < points.length; index++) {
    final segment = rasterizeBorderStrokePairV1(
      points[index - 1],
      points[index],
    );
    result.addAll(segment.skip(1));
  }
  return result;
}

bool _inside(GridPos point, GridSize size, BorderStrokeAlignment alignment) =>
    point.x >= 0 &&
    point.y >= 0 &&
    point.x <
        size.width + (alignment == BorderStrokeAlignment.gridEdges ? 1 : 0) &&
    point.y <
        size.height + (alignment == BorderStrokeAlignment.gridEdges ? 1 : 0);

void _requireInside(
  GridPos point,
  GridSize size,
  BorderStrokeAlignment alignment,
) {
  if (!_inside(point, size, alignment)) {
    throw const ValidationException('La bordure sort de la carte.');
  }
}
