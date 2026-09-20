import 'package:map_core/map_core_domain.dart';

import 'terrain_connections.dart';

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
    guideId: 'avelune-cardinal4-v1',
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
  if (draft.guideId != 'avelune-cardinal4-v1' ||
      draft.topology != SmartTileTopology.cardinal4 ||
      draft.templateHint != SmartTileTemplateHint.edge16 ||
      draft.boundaryPolicy != SmartTileBoundaryPolicy.empty ||
      draft.transformPolicy != const SmartTileTransformPolicy() ||
      draft.coverageProfile !=
          const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ) ||
      draft.fallbackRuleId != null ||
      draft.animations.isNotEmpty ||
      draft.rules.length != 16 ||
      draft.atlases.length != 1 ||
      draft.materials.length != 1 ||
      draft.materials.single.isEmpty ||
      draft.materials.single.id != draft.defaultMaterialId ||
      draft.allowedMaterialIds.length != 1 ||
      draft.allowedMaterialIds.single != draft.defaultMaterialId) {
    return advancedTerrainPreparationMessage;
  }
  final atlas = draft.atlases.single;
  if (draft.primaryAtlasId != atlas.id ||
      draft.sourceTilesetIds.length != 1 ||
      draft.sourceTilesetIds.single != atlas.tilesetId) {
    return advancedTerrainPreparationMessage;
  }
  final source = manifest.tilesets
      .where((t) => t.id == atlas.tilesetId)
      .firstOrNull;
  if (source == null) {
    return 'L’image source de ce terrain est absente du projet.';
  }
  final problem = terrainSourceCompatibilityProblem(source);
  if (problem != null) return problem;
  if (terrainAtlas(source, atlas.id).copyWith(name: atlas.name) != atlas) {
    return advancedTerrainPreparationMessage;
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
      return advancedTerrainPreparationMessage;
    }
    if (rule != terrainConnectionRule(mask, frame, draft.defaultMaterialId!)) {
      return advancedTerrainPreparationMessage;
    }
  }
  return null;
}
