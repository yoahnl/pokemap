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

const terrainConnectionNames = smartTileAuthoringConnectionNames;

int terrainRuleAt(
  Set<GridPos> cells,
  GridPos position, {
  required bool withOuterCorners,
}) {
  final x = position.x, y = position.y;
  final mask =
      (cells.contains(GridPos(x: x, y: y - 1)) ? 1 : 0) |
      (cells.contains(GridPos(x: x + 1, y: y)) ? 2 : 0) |
      (cells.contains(GridPos(x: x, y: y + 1)) ? 4 : 0) |
      (cells.contains(GridPos(x: x - 1, y: y)) ? 8 : 0);
  if (mask != 15 || !withOuterCorners) return mask;
  final missing = <int>[
    if (!cells.contains(GridPos(x: x - 1, y: y - 1))) 16,
    if (!cells.contains(GridPos(x: x + 1, y: y - 1))) 17,
    if (!cells.contains(GridPos(x: x - 1, y: y + 1))) 18,
    if (!cells.contains(GridPos(x: x + 1, y: y + 1))) 19,
  ];
  return missing.length == 1 ? missing.single : mask;
}

SmartTileRule terrainOuterCornerRule(
  int index,
  SmartTileFrameRef? frame,
  String materialId,
) => smartTileAuthoringOuterCornerRule(index, frame, materialId);

SmartTileRule terrainConnectionRule(
  int mask,
  SmartTileFrameRef? frame,
  String materialId,
) => smartTileAuthoringConnectionRule(mask, frame, materialId);

ProjectSmartTileAtlas terrainAtlas(ProjectTilesetEntry tileset, String id) =>
    smartTileAuthoringAtlas(tileset, id);
