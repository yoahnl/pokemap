import 'package:map_core/map_core_domain.dart';

const terrainConnectionNames = [
  'Îlot isolé',
  'Extrémité vers le haut',
  'Extrémité vers la droite',
  'Angle haut · droite',
  'Extrémité vers le bas',
  'Passage vertical',
  'Angle droite · bas',
  'Bord gauche',
  'Extrémité vers la gauche',
  'Angle gauche · haut',
  'Passage horizontal',
  'Bord bas',
  'Angle bas · gauche',
  'Bord droit',
  'Bord haut',
  'Centre',
];

SmartTileRule terrainConnectionRule(
  int mask,
  SmartTileFrameRef? frame,
  String materialId,
) {
  SmartTileSlotMatch match(int bit) => mask & bit != 0
      ? const SmartTileSlotMatch.same()
      : const SmartTileSlotMatch.empty();
  return SmartTileRule(
    id: 'connection-$mask',
    centerMatch: SmartTileSlotMatch.material(materialId),
    signature: SmartTileSignature(
      northEdge: match(1),
      eastEdge: match(2),
      southEdge: match(4),
      westEdge: match(8),
    ),
    candidates: frame == null
        ? []
        : [
            SmartTileCandidate(
              id: 'piece-$mask',
              label: terrainConnectionNames[mask],
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(frame: frame),
                ),
              ],
            ),
          ],
  );
}

ProjectSmartTileAtlas terrainAtlas(ProjectTilesetEntry tileset, String id) {
  final source = tileset.source;
  if (source is! ProjectRegularAtlasTilesetSource) {
    throw StateError(
      'Cette source ne propose pas encore de grille de terrain éditable.',
    );
  }
  return ProjectSmartTileAtlas(
    id: id,
    name: tileset.name,
    tilesetId: tileset.id,
    cellWidth: source.tileWidth,
    cellHeight: source.tileHeight,
    columns:
        (source.pixelWidth - source.marginX * 2 + source.spacingX) ~/
        (source.tileWidth + source.spacingX),
    rows:
        (source.pixelHeight - source.marginY * 2 + source.spacingY) ~/
        (source.tileHeight + source.spacingY),
    marginX: source.marginX,
    marginY: source.marginY,
    spacingX: source.spacingX,
    spacingY: source.spacingY,
    pixelOffsetX: source.pixelOffsetX,
    pixelOffsetY: source.pixelOffsetY,
  );
}
