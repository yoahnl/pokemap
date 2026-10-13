import 'dart:convert' show jsonEncode;

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_geometry.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_linear_lattice.dart';
import 'border_region_contours.dart';
import 'border_template_capabilities.dart';

enum BorderJumpFaceKind { region, cellCenter, gridEdge }

@immutable
final class BorderJumpFaceCandidate {
  BorderJumpFaceCandidate._({
    required this.key,
    required this.kind,
    required this.topologicalNormal,
    required this.startWorldPx,
    required this.endWorldPx,
    required Iterable<GridPos> potentialCarrierCells,
  }) : potentialCarrierCells = List<GridPos>.unmodifiable(
         potentialCarrierCells,
       );

  final String key;
  final BorderJumpFaceKind kind;
  final BorderCardinalDirection topologicalNormal;
  final BorderPixelPos startWorldPx;
  final BorderPixelPos endWorldPx;
  final List<GridPos> potentialCarrierCells;
}

List<BorderJumpFaceCandidate> deriveBorderJumpFaceCandidates(
  BorderResolutionRequest request,
) {
  final definition = request.blueprintRevision?.definition;
  if (definition == null) {
    throw const ValidationException(
      'Border jump candidates require a published blueprint',
    );
  }
  final behavior = definition.jumpBehavior;
  if (behavior == null) {
    return const [];
  }
  if (definition.isSpatial) {
    throw const ValidationException(
      'Border jump face candidates support only two-dimensional blueprints',
    );
  }
  _requirePortableCanvas(request);
  final template = definition.template;
  if (request.feature.lineSide == BorderLineSide.inverted &&
      !borderTemplateSupportsLineSide(template)) {
    throw const ValidationException(
      'Border jump feature side is unsupported by its template',
    );
  }
  final inverted =
      (request.feature.lineSide == BorderLineSide.inverted) !=
      (behavior.side == BorderLineSide.inverted);
  final geometry = request.feature.geometry;
  if (geometry is BorderRegionGeometry) {
    if (borderTemplateUsesStrokeGeometry(template) ||
        geometry.width != request.mapSize.width ||
        geometry.height != request.mapSize.height) {
      throw const ValidationException(
        'Border jump region must match its template and map dimensions',
      );
    }
    return _regionCandidates(request, geometry, inverted: inverted);
  }
  if (geometry is! BorderStrokeGeometry ||
      !borderTemplateUsesStrokeGeometry(template) ||
      geometry.alignment != borderTemplateStrokeAlignment(template)) {
    throw const ValidationException(
      'Border jump stroke must match its template and alignment',
    );
  }
  final gridEdges = geometry.alignment == BorderStrokeAlignment.gridEdges;
  for (final stroke in geometry.strokes) {
    for (final point in stroke.points) {
      if (point.x < 0 ||
          point.y < 0 ||
          point.x >= request.mapSize.width + (gridEdges ? 1 : 0) ||
          point.y >= request.mapSize.height + (gridEdges ? 1 : 0)) {
        throw const ValidationException(
          'Border jump stroke points must be inside the map geometry domain',
        );
      }
    }
  }
  final candidates = <BorderJumpFaceCandidate>[];
  for (final stroke in geometry.strokes) {
    final lattice = buildBorderLinearLatticeV1(
      stroke: stroke,
      tileSizePx: request.tileSizePx,
    );
    if (gridEdges) {
      for (final edge in lattice.edges) {
        candidates.add(
          BorderJumpFaceCandidate._(
            key: _key(request, BorderJumpFaceKind.gridEdge, [
              lattice.persistedStrokeId,
              edge.startCell.x,
              edge.startCell.y,
              edge.endCell.x,
              edge.endCell.y,
            ]),
            kind: BorderJumpFaceKind.gridEdge,
            topologicalNormal: _normal(edge.direction, inverted: inverted),
            startWorldPx: _vertexWorldPx(request, edge.startCell),
            endWorldPx: _vertexWorldPx(request, edge.endCell),
            potentialCarrierCells: _edgeCarriers(edge).where(
              (cell) =>
                  cell.x >= 0 &&
                  cell.y >= 0 &&
                  cell.x < request.mapSize.width &&
                  cell.y < request.mapSize.height,
            ),
          ),
        );
      }
    } else {
      for (final node in lattice.nodes) {
        if (node.kind == BorderLinearNodeKind.corner) {
          continue;
        }
        final tangent = node.outgoingDirection ?? node.incomingDirection!;
        final cellOrigin = _vertexWorldPx(request, node.cell);
        final centerX = cellOrigin.x + request.tileSizePx.width ~/ 2;
        final centerY = cellOrigin.y + request.tileSizePx.height ~/ 2;
        final horizontal =
            tangent == BorderCardinalDirection.east ||
            tangent == BorderCardinalDirection.west;
        candidates.add(
          BorderJumpFaceCandidate._(
            key: _key(request, BorderJumpFaceKind.cellCenter, [
              lattice.persistedStrokeId,
              node.cell.x,
              node.cell.y,
            ]),
            kind: BorderJumpFaceKind.cellCenter,
            topologicalNormal: _normal(tangent, inverted: inverted),
            startWorldPx: BorderPixelPos(
              x: horizontal ? cellOrigin.x : centerX,
              y: horizontal ? centerY : cellOrigin.y,
            ),
            endWorldPx: BorderPixelPos(
              x: horizontal ? cellOrigin.x + request.tileSizePx.width : centerX,
              y: horizontal
                  ? centerY
                  : cellOrigin.y + request.tileSizePx.height,
            ),
            potentialCarrierCells: [node.cell],
          ),
        );
      }
    }
  }
  return List<BorderJumpFaceCandidate>.unmodifiable(candidates);
}

List<BorderJumpFaceCandidate> _regionCandidates(
  BorderResolutionRequest request,
  BorderRegionGeometry region, {
  required bool inverted,
}) {
  final edges = extractCanonicalBorderRegionContours(
    region: region,
    tileSizePx: request.tileSizePx,
  ).expand((contour) => contour.edges).toList(growable: false);
  final normalsByCell = <GridPos, Set<BorderCardinalDirection>>{};
  for (final edge in edges) {
    (normalsByCell[edge.interiorCell] ??= {}).add(edge.outwardSide);
  }
  return List<BorderJumpFaceCandidate>.unmodifiable([
    for (final edge in edges)
      if (normalsByCell[edge.interiorCell]!.length == 1)
        BorderJumpFaceCandidate._(
          key: _key(request, BorderJumpFaceKind.region, [
            edge.startVertex.x,
            edge.startVertex.y,
            edge.endVertex.x,
            edge.endVertex.y,
          ]),
          kind: BorderJumpFaceKind.region,
          topologicalNormal: inverted
              ? _opposite(edge.outwardSide)
              : edge.outwardSide,
          startWorldPx: edge.startWorldPx,
          endWorldPx: edge.endWorldPx,
          potentialCarrierCells: [edge.interiorCell],
        ),
  ]);
}

List<GridPos> _edgeCarriers(BorderLinearEdge edge) {
  final x = edge.startCell.x;
  final y = edge.startCell.y;
  return switch (edge.direction) {
    BorderCardinalDirection.east => [
      GridPos(x: x, y: y),
      GridPos(x: x, y: y - 1),
    ],
    BorderCardinalDirection.south => [
      GridPos(x: x - 1, y: y),
      GridPos(x: x, y: y),
    ],
    BorderCardinalDirection.west => [
      GridPos(x: x - 1, y: y - 1),
      GridPos(x: x - 1, y: y),
    ],
    BorderCardinalDirection.north => [
      GridPos(x: x, y: y - 1),
      GridPos(x: x - 1, y: y - 1),
    ],
  };
}

BorderCardinalDirection _normal(
  BorderCardinalDirection tangent, {
  required bool inverted,
}) {
  final right = switch (tangent) {
    BorderCardinalDirection.east => BorderCardinalDirection.south,
    BorderCardinalDirection.south => BorderCardinalDirection.west,
    BorderCardinalDirection.west => BorderCardinalDirection.north,
    BorderCardinalDirection.north => BorderCardinalDirection.east,
  };
  return inverted ? _opposite(right) : right;
}

BorderCardinalDirection _opposite(BorderCardinalDirection direction) =>
    switch (direction) {
      BorderCardinalDirection.east => BorderCardinalDirection.west,
      BorderCardinalDirection.south => BorderCardinalDirection.north,
      BorderCardinalDirection.west => BorderCardinalDirection.east,
      BorderCardinalDirection.north => BorderCardinalDirection.south,
    };

String _key(
  BorderResolutionRequest request,
  BorderJumpFaceKind kind,
  List<Object> topology,
) => jsonEncode([request.feature.id, kind.name, topology]);

BorderPixelPos _vertexWorldPx(BorderResolutionRequest request, GridPos point) =>
    BorderPixelPos(
      x: (BigInt.from(point.x) * BigInt.from(request.tileSizePx.width)).toInt(),
      y: (BigInt.from(point.y) * BigInt.from(request.tileSizePx.height))
          .toInt(),
    );

void _requirePortableCanvas(BorderResolutionRequest request) {
  final maximum = BigInt.parse('9007199254740991');
  if (BigInt.from(request.mapSize.width) *
              BigInt.from(request.tileSizePx.width) >
          maximum ||
      BigInt.from(request.mapSize.height) *
              BigInt.from(request.tileSizePx.height) >
          maximum) {
    throw const ValidationException(
      'Border jump canvas exceeds the portable integer range',
    );
  }
}
