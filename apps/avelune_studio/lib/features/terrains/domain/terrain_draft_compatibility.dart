import 'package:map_core/map_core_domain.dart';

import 'terrain_connections.dart';
import 'terrain_spatial_draft.dart';

const advancedTerrainPreparationMessage =
    'Ce terrain utilise une préparation avancée, conservée et utilisable sur la carte.';

ProjectSmartTileAuthoringDraft? terrainDraftForPreset(
  ProjectManifest manifest,
  ProjectSmartTilePreset preset,
) {
  if (manifest.smartTileCatalog.drafts.any(
    (draft) =>
        draft.id == 'draft-${preset.id}' && draft.targetPresetId != preset.id,
  )) {
    return null;
  }
  if (preset.rules.any(
    (rule) => rule.candidates.any(
      (candidate) =>
          candidate.parts.any((part) => part.source is SmartTileModel3dSource),
    ),
  )) {
    return spatialTerrainDraftForPreset(manifest, preset);
  }
  final atlasIds = <String>{};
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        if (part.source case SmartTileFrameSource(:final frame)) {
          atlasIds.add(frame.atlasId);
        } else {
          return null;
        }
      }
    }
  }
  if (atlasIds.length != 1) return null;
  final atlas = manifest.smartTileCatalog.atlases
      .where((a) => a.id == atlasIds.single)
      .firstOrNull;
  final material = manifest.smartTileCatalog.materials
      .where((m) => m.id == preset.defaultMaterialId)
      .firstOrNull;
  if (atlas == null || material == null) return null;
  final draft = ProjectSmartTileAuthoringDraft(
    id: 'draft-${preset.id}',
    targetPresetId: preset.id,
    sourcePresetId: preset.id,
    name: preset.name,
    categoryId: preset.categoryId,
    usage: preset.usage,
    lastStage: SmartTileAuthoringStage.connections,
    guideId: preset.topology == SmartTileTopology.blob8
        ? 'avelune-path20-v1'
        : 'avelune-cardinal4-v1',
    sourceTilesetIds: [atlas.tilesetId],
    atlases: [atlas],
    primaryAtlasId: atlas.id,
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
  return terrainDraftCompatibilityProblem(manifest, draft) == null &&
          terrainDraftPreset(draft) == preset
      ? draft
      : null;
}

String? terrainPresetCompatibilityProblem(
  ProjectManifest manifest,
  ProjectSmartTilePreset preset,
) => terrainDraftForPreset(manifest, preset) == null
    ? advancedTerrainPreparationMessage
    : null;

ProjectSmartTileAuthoringDraft? editableTerrainDraft(
  ProjectManifest manifest,
  ProjectSmartTilePreset preset, {
  Iterable<ProjectSmartTileAuthoringDraft> localDrafts = const [],
}) {
  final reconstructed = terrainDraftForPreset(manifest, preset);
  if (reconstructed == null) return null;
  final drafts = [...localDrafts, ...manifest.smartTileCatalog.drafts];
  final candidate =
      drafts.where((draft) => draft.targetPresetId == preset.id).firstOrNull ??
      reconstructed;
  if (drafts.any(
    (draft) =>
        draft.id == candidate.id &&
        draft.targetPresetId != candidate.targetPresetId,
  )) {
    return null;
  }
  return terrainDraftCompatibilityProblem(manifest, candidate) == null
      ? candidate
      : null;
}

String? terrainSourceCompatibilityProblem(ProjectTilesetEntry tileset) {
  final source = tileset.source;
  if (source is! ProjectRegularAtlasTilesetSource) {
    return 'Cette image ne déclare pas de grille de tuiles compatible.';
  }
  if (source.tileWidth <= 0 ||
      source.tileHeight <= 0 ||
      source.columns <= 0 ||
      source.rows <= 0) {
    return 'La grille déclarée ne contient aucune case entière.';
  }
  return null;
}

String? terrainDraftCompatibilityProblem(
  ProjectManifest manifest,
  ProjectSmartTileAuthoringDraft draft,
) {
  if (terrainDraftIsSpatial(draft)) {
    return spatialTerrainCompatibilityProblem(manifest, draft);
  }
  final guide = recognizeSmartTileAuthoringGuide(manifest, draft);
  if (guide != null && guide == draft.guideId) return null;
  if (draft.atlases.length == 1) {
    final source = manifest.tilesets
        .where((tile) => tile.id == draft.atlases.single.tilesetId)
        .firstOrNull;
    if (source == null) {
      return 'L’image source de ce terrain est absente du projet.';
    }
    final problem = terrainSourceCompatibilityProblem(source);
    if (problem != null) return problem;
  }
  return advancedTerrainPreparationMessage;
}
