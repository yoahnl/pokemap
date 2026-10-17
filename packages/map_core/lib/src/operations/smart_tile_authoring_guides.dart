import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';
import '../models/smart_tile.dart';

const smartTileAuthoringConnectionNames = [
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
  'Coin extérieur haut gauche',
  'Coin extérieur haut droit',
  'Coin extérieur bas gauche',
  'Coin extérieur bas droit',
];

SmartTileRule smartTileAuthoringOuterCornerRule(
  int index,
  SmartTileFrameRef? frame,
  String materialId,
) {
  if (index < 16 || index > 19) {
    throw RangeError.range(index, 16, 19);
  }
  SmartTileSlotMatch corner(int slot) => index == slot
      ? const SmartTileSlotMatch.empty()
      : const SmartTileSlotMatch.same();
  return SmartTileRule(
    id: 'connection-$index',
    centerMatch: SmartTileSlotMatch.material(materialId),
    signature: SmartTileSignature(
      northEdge: const SmartTileSlotMatch.same(),
      eastEdge: const SmartTileSlotMatch.same(),
      southEdge: const SmartTileSlotMatch.same(),
      westEdge: const SmartTileSlotMatch.same(),
      northWestCorner: corner(16),
      northEastCorner: corner(17),
      southWestCorner: corner(18),
      southEastCorner: corner(19),
    ),
    candidates: frame == null
        ? []
        : [
            SmartTileCandidate(
              id: 'piece-$index',
              label: smartTileAuthoringConnectionNames[index],
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(frame: frame),
                ),
              ],
            ),
          ],
  );
}

SmartTileRule smartTileAuthoringConnectionRule(
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
              label: smartTileAuthoringConnectionNames[mask],
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(frame: frame),
                ),
              ],
            ),
          ],
  );
}

ProjectSmartTileAtlas smartTileAuthoringAtlas(
  ProjectTilesetEntry tileset,
  String id,
) {
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

String? recognizeSmartTileAuthoringGuide(
  ProjectManifest manifest,
  ProjectSmartTileAuthoringDraft draft,
) {
  final extended =
      draft.topology == SmartTileTopology.blob8 &&
      draft.templateHint == SmartTileTemplateHint.blob47 &&
      draft.rules.length == 20;
  final cardinal =
      draft.topology == SmartTileTopology.cardinal4 &&
      draft.templateHint == SmartTileTemplateHint.edge16 &&
      draft.rules.length == 16;
  if (!(cardinal || extended) ||
      draft.boundaryPolicy != SmartTileBoundaryPolicy.empty ||
      draft.transformPolicy != const SmartTileTransformPolicy() ||
      draft.coverageProfile !=
          const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ) ||
      draft.fallbackRuleId != null ||
      draft.animations.isNotEmpty ||
      draft.atlases.length != 1 ||
      draft.materials.length != 1 ||
      draft.materials.single.isEmpty ||
      draft.materials.single.id != draft.defaultMaterialId ||
      draft.allowedMaterialIds.length != 1 ||
      draft.allowedMaterialIds.single != draft.defaultMaterialId) {
    return null;
  }
  final atlas = draft.atlases.single;
  if (draft.primaryAtlasId != atlas.id ||
      draft.sourceTilesetIds.length != 1 ||
      draft.sourceTilesetIds.single != atlas.tilesetId) {
    return null;
  }
  final source = manifest.tilesets
      .where((t) => t.id == atlas.tilesetId)
      .firstOrNull;
  if (source == null) {
    return null;
  }
  final grid = source.source;
  if (grid is! ProjectRegularAtlasTilesetSource ||
      grid.tileWidth <= 0 ||
      grid.tileHeight <= 0 ||
      grid.spacingX < 0 ||
      grid.spacingY < 0 ||
      grid.columns <= 0 ||
      grid.rows <= 0)
    return null;
  if (smartTileAuthoringAtlas(source, atlas.id).copyWith(name: atlas.name) !=
      atlas) {
    return null;
  }
  for (var mask = 0; mask < 16; mask++) {
    final rule = draft.rules[mask];
    final part = rule.candidates.firstOrNull?.parts.firstOrNull?.source;
    final frame = part is SmartTileFrameSource ? part.frame : null;
    if (frame != null &&
        (frame.atlasId != atlas.id ||
            frame.columnSpan != 1 ||
            frame.rowSpan != 1 ||
            frame.column < 0 ||
            frame.row < 0 ||
            frame.column >= atlas.columns ||
            frame.row >= atlas.rows)) {
      return null;
    }
    if (rule !=
        smartTileAuthoringConnectionRule(
          mask,
          frame,
          draft.defaultMaterialId!,
        )) {
      return null;
    }
  }
  if (extended) {
    for (var index = 16; index < 20; index++) {
      final rule = draft.rules[index];
      final part = rule.candidates.firstOrNull?.parts.firstOrNull?.source;
      final frame = part is SmartTileFrameSource ? part.frame : null;
      if (frame != null &&
          (frame.atlasId != atlas.id ||
              frame.columnSpan != 1 ||
              frame.rowSpan != 1 ||
              frame.column < 0 ||
              frame.row < 0 ||
              frame.column >= atlas.columns ||
              frame.row >= atlas.rows)) {
        return null;
      }
      if (rule !=
          smartTileAuthoringOuterCornerRule(
            index,
            frame,
            draft.defaultMaterialId!,
          )) {
        return null;
      }
    }
  }
  return extended ? 'avelune-path20-v1' : 'avelune-cardinal4-v1';
}
