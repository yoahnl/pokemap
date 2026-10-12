import 'package:map_core/map_core.dart';

import 'terrain_connections.dart';
import 'terrain_draft_compatibility.dart';

bool terrainDraftIsSpatial(ProjectSmartTileAuthoringDraft draft) =>
    draft.atlases.isEmpty &&
    (draft.guideId?.startsWith('avelune-spatial-') == true ||
        draft.rules.any(
          (rule) => rule.candidates.any(
            (candidate) => candidate.parts.any(
              (part) => part.source is SmartTileModel3dSource,
            ),
          ),
        ));

SmartTileRule spatialTerrainRule(
  int index,
  SmartTileVisualPart? part,
  String materialId, {
  required bool uniform,
}) {
  final base = uniform
      ? SmartTileRule(
          id: 'uniform',
          centerMatch: SmartTileSlotMatch.material(materialId),
          signature: const SmartTileSignature(),
        )
      : index < 16
      ? terrainConnectionRule(index, null, materialId)
      : terrainOuterCornerRule(index, null, materialId);
  return base.copyWith(
    candidates: part == null
        ? []
        : [
            SmartTileCandidate(
              id: 'piece-$index',
              label: uniform ? 'Pièce unitaire' : terrainConnectionNames[index],
              parts: [part],
            ),
          ],
  );
}

ProjectSmartTileAuthoringDraft createSpatialTerrainDraft(
  ProjectModel3dEntry model,
  String id,
) => ProjectSmartTileAuthoringDraft(
  id: 'draft-$id',
  targetPresetId: id,
  name: model.name,
  usage: SmartTileUsage.path,
  lastStage: SmartTileAuthoringStage.connections,
  guideId: 'avelune-spatial-uniform-v1',
  materials: [
    ProjectSmartTileMaterial(
      id: 'material-$id',
      name: model.name,
      connectionGroupId: 'connection-$id',
    ),
  ],
  defaultMaterialId: 'material-$id',
  allowedMaterialIds: ['material-$id'],
  rules: [
    spatialTerrainRule(
      0,
      SmartTileVisualPart(
        source: SmartTileVisualSource.model3d(modelId: model.id),
      ),
      'material-$id',
      uniform: true,
    ),
  ],
);

ProjectSmartTileAuthoringDraft? spatialTerrainDraftForPreset(
  ProjectManifest manifest,
  ProjectSmartTilePreset preset,
) {
  final material = manifest.smartTileCatalog.materials
      .where((material) => material.id == preset.defaultMaterialId)
      .firstOrNull;
  if (material == null) return null;
  final draft = ProjectSmartTileAuthoringDraft(
    id: 'draft-${preset.id}',
    targetPresetId: preset.id,
    sourcePresetId: preset.id,
    name: preset.name,
    categoryId: preset.categoryId,
    usage: preset.usage,
    lastStage: SmartTileAuthoringStage.connections,
    guideId: preset.topology == SmartTileTopology.uniform
        ? 'avelune-spatial-uniform-v1'
        : preset.topology == SmartTileTopology.blob8
        ? 'avelune-spatial-path20-v1'
        : 'avelune-spatial-cardinal4-v1',
    materials: [material],
    defaultMaterialId: preset.defaultMaterialId,
    allowedMaterialIds: preset.allowedMaterialIds,
    topology: preset.topology,
    templateHint: preset.templateHint,
    boundaryPolicy: preset.boundaryPolicy,
    coveragePolicy: preset.coveragePolicy,
    coverageProfile: preset.coverageProfile,
    transformPolicy: preset.transformPolicy,
    rules: preset.rules,
    fallbackRuleId: preset.fallbackRuleId,
    tags: preset.tags,
    sortOrder: preset.sortOrder,
    seedSalt: preset.seedSalt,
  );
  return spatialTerrainCompatibilityProblem(manifest, draft) == null &&
          terrainDraftPreset(draft) == preset
      ? draft
      : null;
}

String? spatialTerrainCompatibilityProblem(
  ProjectManifest manifest,
  ProjectSmartTileAuthoringDraft draft,
) {
  final uniform =
      draft.topology == SmartTileTopology.uniform && draft.rules.length == 1;
  final cardinal =
      draft.topology == SmartTileTopology.cardinal4 && draft.rules.length == 16;
  final extended =
      draft.topology == SmartTileTopology.blob8 && draft.rules.length == 20;
  if (manifest.settings.dimension != ProjectDimension.threeD ||
      !(uniform || cardinal || extended) ||
      draft.primaryAtlasId != null ||
      draft.sourceTilesetIds.isNotEmpty ||
      draft.atlases.isNotEmpty ||
      draft.animations.isNotEmpty ||
      draft.materials.length != 1 ||
      draft.defaultMaterialId != draft.materials.single.id ||
      draft.allowedMaterialIds.length != 1 ||
      draft.allowedMaterialIds.single != draft.defaultMaterialId ||
      draft.fallbackRuleId != null ||
      draft.transformPolicy.allowHFlip ||
      draft.transformPolicy.allowVFlip ||
      !draft.transformPolicy.preferUntransformed ||
      draft.boundaryPolicy != SmartTileBoundaryPolicy.empty) {
    return advancedTerrainPreparationMessage;
  }
  final owner = manifest.resourceLibraryCatalog
      .entryFor('smartTilePreset', draft.targetPresetId)
      ?.mapId;
  for (var index = 0; index < draft.rules.length; index++) {
    final rule = draft.rules[index];
    final candidates = rule.candidates;
    if (candidates.length > 1 ||
        candidates.any((candidate) => candidate.parts.length != 1)) {
      return advancedTerrainPreparationMessage;
    }
    final part = candidates.firstOrNull?.parts.firstOrNull;
    if (part != null) {
      final source = part.source;
      if (source is! SmartTileModel3dSource ||
          !source.scale.isFinite ||
          source.scale <= 0 ||
          !source.offsetY.isFinite ||
          part.transform.flipX ||
          !manifest.models3d.any((model) => model.id == source.modelId) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            source.modelId,
            owner ?? '',
          )) {
        return advancedTerrainPreparationMessage;
      }
    }
    final expected = spatialTerrainRule(
      index,
      part,
      draft.defaultMaterialId!,
      uniform: uniform,
    );
    if (rule.signature != expected.signature ||
        rule.centerMatch != expected.centerMatch ||
        candidates.any((candidate) => candidate.parts.single != part)) {
      return advancedTerrainPreparationMessage;
    }
  }
  return null;
}
