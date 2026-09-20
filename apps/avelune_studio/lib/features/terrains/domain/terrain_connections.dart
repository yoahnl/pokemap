import 'package:map_core/map_core_domain.dart';

ProjectSmartTileAuthoringDraft createTerrainDraft(
  ProjectSmartTileAtlas atlas,
  String id,
  String name,
) => ProjectSmartTileAuthoringDraft(
  id: 'draft-$id',
  targetPresetId: id,
  name: name,
  usage: SmartTileUsage.path,
  lastStage: SmartTileAuthoringStage.connections,
  guideId: 'avelune-cardinal4-v1',
  topology: SmartTileTopology.cardinal4,
  templateHint: SmartTileTemplateHint.edge16,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  sourceTilesetIds: [atlas.tilesetId],
  atlases: [atlas],
  primaryAtlasId: atlas.id,
  materials: [
    ProjectSmartTileMaterial(
      id: 'material-$id',
      name: name,
      connectionGroupId: 'connection-$id',
    ),
  ],
  defaultMaterialId: 'material-$id',
  allowedMaterialIds: ['material-$id'],
  rules: List.generate(
    16,
    (mask) => terrainConnectionRule(mask, null, 'material-$id'),
  ),
);

ProjectSmartTilePreset terrainDraftPreset(
  ProjectSmartTileAuthoringDraft draft,
) => ProjectSmartTilePreset(
  id: draft.targetPresetId,
  name: draft.name,
  categoryId: draft.categoryId,
  usage: draft.usage,
  topology: draft.topology,
  templateHint: draft.templateHint,
  boundaryPolicy: draft.boundaryPolicy,
  status: SmartTilePresetStatus.published,
  coveragePolicy: draft.coveragePolicy,
  coverageProfile: draft.coverageProfile,
  transformPolicy: draft.transformPolicy,
  defaultMaterialId: draft.defaultMaterialId!,
  allowedMaterialIds: draft.allowedMaterialIds,
  rules: draft.rules,
  tags: draft.tags,
  sortOrder: draft.sortOrder,
  seedSalt: draft.seedSalt,
  fallbackRuleId: draft.fallbackRuleId,
);

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
