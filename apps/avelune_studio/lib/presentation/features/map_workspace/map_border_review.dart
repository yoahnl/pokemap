import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/map_border_drawing_draft.dart';
import '../../../features/map_workspace/application/map_border_editing_commands.dart';

final class MapBorderProfileChoices {
  const MapBorderProfileChoices(this.ready, this.drafts);
  final List<BorderBlueprintRecord> ready, drafts;
}

MapBorderProfileChoices mapBorderProfileChoices(ProjectManifest project) {
  final ready = MapBorderEditingCommands.publishedLines(project);
  final readyIds = ready.map((record) => record.id).toSet();
  final spatial = project.settings.dimension == ProjectDimension.threeD;
  final drafts = [
    for (final record in project.borderCatalog.records)
      if (!record.isDeprecated &&
          !readyIds.contains(record.id) &&
          record.latestPublished == null &&
          record.draft.definition.isSpatial == spatial &&
          borderTemplateUsesStrokeGeometry(record.draft.definition.template))
        record,
  ];
  return MapBorderProfileChoices(ready, drafts);
}

String _count(int value, String singular, String plural) =>
    '$value ${value > 1 ? plural : singular}';

String mapBorderProfilePieces(BorderBlueprintPublishedDefinition definition) {
  int count(BorderPrimitiveRole role) =>
      definition.primitives.where((primitive) => primitive.role == role).length;
  return 'Pièces : ${_count(count(BorderPrimitiveRole.lineStraight), 'segment', 'segments')} · '
      '${_count(count(BorderPrimitiveRole.lineCorner), 'coin', 'coins')} · '
      '${_count(count(BorderPrimitiveRole.lineCap), 'extrémité', 'extrémités')}';
}

String mapBorderTraversal(BorderBlueprintPublishedDefinition definition) {
  if (definition.jumpBehavior != null) {
    return 'Passage : franchissable à sens unique, par un saut.';
  }
  final open = definition.primitives
      .where((primitive) => !primitive.blocksMovement)
      .length;
  if (open == 0) {
    return 'Passage : la paroi bloque le joueur sur tout le tracé.';
  }
  return 'Passage : $open ${open > 1 ? 'pièces laissent' : 'pièce laisse'} passer le joueur ; les autres bloquent.';
}

String? mapBorderGround(BorderBlueprintPublishedDefinition definition) {
  if (definition.replacesGround) {
    return 'Sol : le modèle remplace le sol sous le tracé.';
  }
  if (definition.masksGroundCells) {
    return 'Sol : les cases sous le tracé sont masquées par la paroi ; l’aperçu montre tout trou laissé par une pièce trop étroite.';
  }
  return null;
}

final class MapBorderReview {
  const MapBorderReview(this.facts, this.warnings);
  final List<String> facts, warnings;
}

BorderCardinalDirection? _direction(GridPos from, GridPos to) {
  final dx = to.x - from.x, dy = to.y - from.y;
  if (dx != 0 && dy != 0) return null;
  if (dx > 0) return BorderCardinalDirection.east;
  if (dx < 0) return BorderCardinalDirection.west;
  if (dy > 0) return BorderCardinalDirection.south;
  if (dy < 0) return BorderCardinalDirection.north;
  return null;
}

MapBorderReview mapBorderDraftReview(
  MapBorderDrawingDraft draft,
  BorderBlueprintPublishedDefinition definition,
) {
  final points = draft.anchors;
  final closed = draft.closed;
  final angles = closed ? points.length : (points.length - 2).clamp(0, 1 << 30);
  final facts = <String>[
    closed
        ? 'Contour fermé · aucune extrémité · ${_count(angles, 'angle', 'angles')}'
        : 'Contour ouvert · 2 extrémités · ${_count(angles, 'angle', 'angles')}',
    mapBorderProfilePieces(definition),
    if (definition.followContourDirection) 'Ce modèle suit le sens du tracé : tracer dans l’autre sens retourne la paroi.',
    mapBorderTraversal(definition),
    ?mapBorderGround(definition),
  ];
  final warnings = <String>[];
  bool has(BorderPrimitiveRole role, [BorderCornerTurn? turn]) =>
      definition.primitives.any(
        (primitive) =>
            primitive.role == role &&
            (turn == null || primitive.cornerTurn == turn),
      );
  if (!closed && points.length > 1 && !has(BorderPrimitiveRole.lineCap)) {
    warnings.add(
      'Ce modèle n’a pas de pièce d’extrémité : les deux bouts du tracé s’arrêteront net.',
    );
  }
  if (angles > 0 && !has(BorderPrimitiveRole.lineCorner)) {
    warnings.add(
      'Ce modèle n’a aucune pièce de coin : chaque angle du tracé restera sans raccord.',
    );
  } else if (angles > 0 && definition.followContourDirection) {
    final ring = closed ? [...points, points.first, points[1]] : points;
    final missing = <BorderCornerTurn>{};
    for (var index = 1; index < ring.length - 1; index++) {
      final incoming = _direction(ring[index - 1], ring[index]);
      final outgoing = _direction(ring[index], ring[index + 1]);
      if (incoming == null || outgoing == null || incoming == outgoing) {
        continue;
      }
      final turn =
          (borderCardinalDirectionV1Rank(outgoing) -
                      borderCardinalDirectionV1Rank(incoming) +
                      4) %
                  4 ==
              1
          ? BorderCornerTurn.right
          : BorderCornerTurn.left;
      if (!has(BorderPrimitiveRole.lineCorner, turn)) missing.add(turn);
    }
    for (final turn in missing) {
      warnings.add(
        'Ce modèle n’a pas de coin tournant à ${turn == BorderCornerTurn.right ? 'droite' : 'gauche'} : tracez dans l’autre sens ou complétez le modèle dans l’atelier.',
      );
    }
  }
  return MapBorderReview(facts, warnings);
}

ProjectBorderCatalog? _pieceCatalog;
Set<String> _pieceIdentities = const {};

Set<String> mapBorderPieceIdentities(ProjectManifest project) {
  final catalog = project.borderCatalog;
  if (identical(catalog, _pieceCatalog)) return _pieceIdentities;
  final identities = <String>{};
  void add(String? modelId, String? elementId) {
    if (modelId != null) identities.add('model3d:$modelId');
    if (elementId != null) identities.add('element:$elementId');
  }

  for (final record in catalog.records) {
    if (record.isDeprecated) continue;
    for (final primitive in record.draft.definition.primitives) {
      add(primitive.sourceModelId, primitive.sourceElementId);
    }
    for (final primitive
        in record.latestPublished?.definition.primitives ??
            const <BorderPublishedPrimitive>[]) {
      add(primitive.sourceModelId, primitive.sourceElementId);
    }
  }
  _pieceCatalog = catalog;
  return _pieceIdentities = identities;
}
