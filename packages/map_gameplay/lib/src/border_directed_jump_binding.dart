import 'package:map_core/map_core.dart';

import 'collision/border_collision_geometry.dart';
import 'direction.dart';

final class BorderDirectedJumpBinding {
  const BorderDirectedJumpBinding._({
    required this.mapId,
    required this.owner,
    required this.faceKey,
    required this.carrierCell,
    required this.carrierArea,
    required this.physicalNormal,
    required this.allowedDirection,
    required this.inputFingerprint,
    required this.outputFingerprint,
    required this.durationMs,
    required this.peakHeightPx,
  });

  final String mapId;
  final BorderCollisionOwner owner;
  final String faceKey;
  final GridPos carrierCell;
  final PixelRect carrierArea;
  final BorderCardinalDirection physicalNormal;
  final Direction allowedDirection;
  final String inputFingerprint;
  final String outputFingerprint;
  final int durationMs;
  final int peakHeightPx;
}

List<BorderDirectedJumpBinding> bindMaterializedBorderJumpFaces({
  required MapData map,
  required ProjectManifest project,
  required PixelSize tileSize,
}) {
  ProjectValidator.validate(project, maps: [map]);
  MapValidator.validate(map, projectDialogueContext: project);
  if (map.spatialScene != null ||
      tileSize.width != project.settings.tileWidth ||
      tileSize.height != project.settings.tileHeight) {
    throw const ValidationException('Border jump context is not canonical 2D');
  }
  final contactsByOwner = <BorderCollisionOwner, List<PixelRect>>{};
  for (final contact in resolveMaterializedBorderCollisions(
    map: map,
    project: project,
    tileSize: tileSize,
  )) {
    (contactsByOwner[contact.owner] ??= []).add(contact.rect);
  }
  final bindings = <BorderDirectedJumpBinding>[];
  final ownerIdentities = <BorderCollisionOwner>{};
  final carriers = <GridPos>{};
  for (final layer in map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      final revision = project.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      if (revision == null) {
        throw const ValidationException('Border jump blueprint is unavailable');
      }
      final behavior = revision.definition.jumpBehavior;
      if (behavior == null) continue;
      if (revision.definition.template != BorderBlueprintTemplate.ledgeLine ||
          project.borderCatalog.formatVersion != 7) {
        throw const ValidationException(
            'Border jump template is not qualified');
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
      final resolved = resolveLedgeLineBorderWithEvidence(request);
      if (!resolved.result.canApply ||
          resolved.result.materialization != feature.materialization) {
        throw const ValidationException(
            'Border jump materialization is not canonical');
      }
      final facesByEdgeAndCarrier =
          <(int, int, int, int, int, int), List<BorderJumpFaceCandidate>>{};
      for (final face in deriveBorderJumpFaceCandidates(request)) {
        if (face.kind != BorderJumpFaceKind.gridEdge) continue;
        for (final cell in face.potentialCarrierCells.toSet()) {
          final key = (
            face.startWorldPx.x,
            face.startWorldPx.y,
            face.endWorldPx.x,
            face.endWorldPx.y,
            cell.x,
            cell.y,
          );
          (facesByEdgeAndCarrier[key] ??= []).add(face);
        }
      }
      for (final edge in resolved.edges) {
        final matching = facesByEdgeAndCarrier[(
              edge.edgeStart.x * tileSize.width,
              edge.edgeStart.y * tileSize.height,
              edge.edgeEnd.x * tileSize.width,
              edge.edgeEnd.y * tileSize.height,
              edge.expectedCarrierCell.x,
              edge.expectedCarrierCell.y,
            )] ??
            const <BorderJumpFaceCandidate>[];
        final owner = BorderCollisionOwner(
          layerId: layer.id,
          featureId: feature.id,
          placementId: edge.finalPlacement.id,
        );
        final cell = edge.expectedCarrierCell;
        final area = PixelRect(
          leftPx: cell.x * tileSize.width,
          topPx: cell.y * tileSize.height,
          widthPx: tileSize.width,
          heightPx: tileSize.height,
        );
        if (matching.length != 1 ||
            !ownerIdentities.add(owner) ||
            !carriers.add(cell) ||
            !_coversExactCell(contactsByOwner[owner] ?? const [], area)) {
          throw const ValidationException(
              'Border jump carrier is incomplete or ambiguous');
        }
        final physical = _direction(edge.physicalNormal);
        final allowed = behavior.side == BorderLineSide.inverted
            ? _opposite(physical)
            : physical;
        if (_direction(matching.single.topologicalNormal) != allowed) {
          throw const ValidationException(
              'Border jump topology and placement disagree');
        }
        final receipt = resolved.result.materialization!.receipt;
        bindings.add(BorderDirectedJumpBinding._(
          mapId: map.id,
          owner: owner,
          faceKey: matching.single.key,
          carrierCell: cell,
          carrierArea: area,
          physicalNormal: edge.physicalNormal,
          allowedDirection: allowed,
          inputFingerprint: receipt.inputFingerprint,
          outputFingerprint: receipt.outputFingerprint,
          durationMs: behavior.durationMs,
          peakHeightPx: behavior.peakHeightPx,
        ));
      }
    }
  }
  return List.unmodifiable(bindings);
}

bool _coversExactCell(List<PixelRect> contacts, PixelRect cell) {
  if (contacts.isEmpty) return false;
  final right = cell.leftPx + cell.widthPx;
  final bottom = cell.topPx + cell.heightPx;
  for (final contact in contacts) {
    if (contact.widthPx <= 0 ||
        contact.heightPx <= 0 ||
        contact.leftPx < cell.leftPx ||
        contact.topPx < cell.topPx ||
        contact.leftPx + contact.widthPx > right ||
        contact.topPx + contact.heightPx > bottom) {
      return false;
    }
  }
  for (var y = cell.topPx; y < bottom; y++) {
    final intervals = [
      for (final contact in contacts)
        if (y >= contact.topPx && y < contact.topPx + contact.heightPx)
          (contact.leftPx, contact.leftPx + contact.widthPx),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    var cursor = cell.leftPx;
    for (final interval in intervals) {
      if (interval.$1 > cursor) return false;
      if (interval.$2 > cursor) cursor = interval.$2;
    }
    if (cursor != right) return false;
  }
  return true;
}

Direction _direction(BorderCardinalDirection direction) => switch (direction) {
      BorderCardinalDirection.north => Direction.north,
      BorderCardinalDirection.south => Direction.south,
      BorderCardinalDirection.east => Direction.east,
      BorderCardinalDirection.west => Direction.west,
    };

Direction _opposite(Direction direction) => switch (direction) {
      Direction.north => Direction.south,
      Direction.south => Direction.north,
      Direction.east => Direction.west,
      Direction.west => Direction.east,
    };
