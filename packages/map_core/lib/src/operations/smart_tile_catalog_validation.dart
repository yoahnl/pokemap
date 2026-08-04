import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';
import 'smart_tile_coverage.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_sprite_geometry.dart';
import 'smart_tile_templates.dart';

enum SmartTileDiagnosticSeverity { info, warning, error }

@immutable
final class SmartTileDiagnostic {
  const SmartTileDiagnostic({
    required this.code,
    required this.severity,
    required this.path,
    required this.message,
    this.presetId,
    this.ruleId,
    this.mask,
    this.missingMasks = const <int>[],
  });

  final String code;
  final SmartTileDiagnosticSeverity severity;
  final String path;
  final String message;
  final String? presetId;
  final String? ruleId;
  final int? mask;
  final List<int> missingMasks;

  bool get isError => severity == SmartTileDiagnosticSeverity.error;
}

List<SmartTileDiagnostic> validateProjectSmartTileCatalog({
  required ProjectSmartTileCatalog catalog,
  required Iterable<String> projectTilesetIds,
}) {
  final validator = _SmartTileCatalogValidator(
    catalog: catalog,
    projectTilesetIds: projectTilesetIds.toSet(),
  );
  return validator.validate();
}

final class _SmartTileCatalogValidator {
  _SmartTileCatalogValidator({
    required this.catalog,
    required this.projectTilesetIds,
  });

  final ProjectSmartTileCatalog catalog;
  final Set<String> projectTilesetIds;
  final List<SmartTileDiagnostic> _diagnostics = <SmartTileDiagnostic>[];

  late final Map<String, ProjectSmartTileAtlas> _atlasesById =
      _firstById(catalog.atlases, (item) => item.id);
  late final Map<String, ProjectSmartTileMaterial> _materialsById =
      _firstById(catalog.materials, (item) => item.id);
  late final Map<String, ProjectSmartTileAnimation> _animationsById =
      _firstById(catalog.animations, (item) => item.id);
  late final Map<String, ProjectSmartTilePreset> _presetsById =
      _firstById(catalog.presets, (item) => item.id);
  late final Set<String> _categoryIds =
      catalog.categories.map((item) => item.id).toSet();

  List<SmartTileDiagnostic> validate() {
    _validateFormatVersion();
    _validateCanonicalTopLevelFields();
    _validateDuplicateIds();
    _validateAtlases();
    _validateAnimations();
    _validatePatterns();
    _validatePresets();
    _validateDrafts();
    return List<SmartTileDiagnostic>.unmodifiable(_diagnostics);
  }

  void _validateCanonicalTopLevelFields() {
    for (var index = 0; index < catalog.categories.length; index += 1) {
      final category = catalog.categories[index];
      final path = r'$.smartTileCatalog.categories[' '$index]';
      _validateCanonicalId(category.id, '$path.id');
      _validateCanonicalName(category.name, '$path.name');
    }
    for (var index = 0; index < catalog.atlases.length; index += 1) {
      final atlas = catalog.atlases[index];
      final path = r'$.smartTileCatalog.atlases[' '$index]';
      _validateCanonicalId(atlas.id, '$path.id');
      _validateCanonicalName(atlas.name, '$path.name');
      _validateCanonicalId(atlas.tilesetId, '$path.tilesetId');
      if (atlas.cellWidth <= 0 ||
          atlas.cellHeight <= 0 ||
          atlas.originX < 0 ||
          atlas.originY < 0 ||
          atlas.marginX < 0 ||
          atlas.marginY < 0 ||
          atlas.spacingX < 0 ||
          atlas.spacingY < 0 ||
          atlas.columns <= 0 ||
          atlas.rows <= 0) {
        _error(
          code: 'smart_tiles.atlas.invalid',
          path: path,
          message: 'Atlas geometry must use positive cells/grid dimensions '
              'and non-negative origins, margins, and spacing.',
        );
      }
    }
    for (var index = 0; index < catalog.materials.length; index += 1) {
      final material = catalog.materials[index];
      final path = r'$.smartTileCatalog.materials[' '$index]';
      _validateCanonicalId(material.id, '$path.id');
      _validateCanonicalName(material.name, '$path.name');
      _validateCanonicalId(
        material.connectionGroupId,
        '$path.connectionGroupId',
      );
      if (material.categoryId.isNotEmpty) {
        _validateCanonicalId(material.categoryId, '$path.categoryId');
        if (!_categoryIds.contains(material.categoryId)) {
          _error(
            code: 'smart_tiles.reference.category_missing',
            path: '$path.categoryId',
            message: 'Material "${material.id}" references missing category '
                '"${material.categoryId}".',
          );
        }
      }
    }
    for (var index = 0; index < catalog.animations.length; index += 1) {
      final animation = catalog.animations[index];
      final path = r'$.smartTileCatalog.animations[' '$index]';
      _validateCanonicalId(animation.id, '$path.id');
      _validateCanonicalName(animation.name, '$path.name');
    }
    for (var index = 0; index < catalog.patterns.length; index += 1) {
      final pattern = catalog.patterns[index];
      final path = r'$.smartTileCatalog.patterns[' '$index]';
      _validateCanonicalId(pattern.id, '$path.id');
      _validateCanonicalName(pattern.name, '$path.name');
      if (pattern.categoryId.isNotEmpty) {
        _validateCanonicalId(pattern.categoryId, '$path.categoryId');
        if (!_categoryIds.contains(pattern.categoryId)) {
          _error(
            code: 'smart_tiles.reference.category_missing',
            path: '$path.categoryId',
            message: 'Pattern "${pattern.id}" references missing category '
                '"${pattern.categoryId}".',
          );
        }
      }
    }
  }

  void _validateFormatVersion() {
    if (catalog.formatVersion != ProjectSmartTileCatalog.currentFormatVersion) {
      _error(
        code: 'smart_tile_catalog_version_unsupported',
        path: r'$.smartTileCatalog.formatVersion',
        message: 'Smart Tile catalog format ${catalog.formatVersion} is not '
            'the current format '
            '${ProjectSmartTileCatalog.currentFormatVersion}.',
      );
    }
  }

  void _validateDuplicateIds() {
    _duplicates(
      catalog.categories,
      (item) => item.id,
      r'$.smartTileCatalog.categories',
    );
    _duplicates(
      catalog.atlases,
      (item) => item.id,
      r'$.smartTileCatalog.atlases',
    );
    _duplicates(
      catalog.materials,
      (item) => item.id,
      r'$.smartTileCatalog.materials',
    );
    _duplicates(
      catalog.animations,
      (item) => item.id,
      r'$.smartTileCatalog.animations',
    );
    _duplicates(
      catalog.presets,
      (item) => item.id,
      r'$.smartTileCatalog.presets',
    );
    _duplicates(
      catalog.patterns,
      (item) => item.id,
      r'$.smartTileCatalog.patterns',
    );
    _duplicates(
      catalog.drafts,
      (item) => item.id,
      r'$.smartTileCatalog.drafts',
    );
  }

  void _validateDrafts() {
    final targetPresetIds = <String>{};
    for (var draftIndex = 0;
        draftIndex < catalog.drafts.length;
        draftIndex += 1) {
      final draft = catalog.drafts[draftIndex];
      final draftPath = r'$.smartTileCatalog.drafts[' '$draftIndex]';
      _validateCanonicalId(draft.id, '$draftPath.id');
      _validateCanonicalId(draft.targetPresetId, '$draftPath.targetPresetId');
      _validateCanonicalName(draft.name, '$draftPath.name');
      if (!targetPresetIds.add(draft.targetPresetId)) {
        _error(
          code: 'smart_tiles.draft.target_in_use',
          path: '$draftPath.targetPresetId',
          message: 'Another Smart Tile draft already targets preset '
              '"${draft.targetPresetId}".',
        );
      }
      if (draft.sourcePresetId case final sourcePresetId?) {
        _validateCanonicalId(sourcePresetId, '$draftPath.sourcePresetId');
        if (!_presetsById.containsKey(sourcePresetId)) {
          _error(
            code: 'smart_tiles.reference.preset_missing',
            path: '$draftPath.sourcePresetId',
            message: 'Draft "${draft.id}" references missing source preset '
                '"$sourcePresetId".',
          );
        }
      }
      if (draft.guideId case final guideId?) {
        _validateCanonicalId(guideId, '$draftPath.guideId');
      }
      if (draft.categoryId.isNotEmpty) {
        _validateCanonicalId(draft.categoryId, '$draftPath.categoryId');
        if (!_categoryIds.contains(draft.categoryId)) {
          _error(
            code: 'smart_tiles.reference.category_missing',
            path: '$draftPath.categoryId',
            message: 'Draft "${draft.id}" references missing category '
                '"${draft.categoryId}".',
          );
        }
      }

      final sourceTilesetIds = <String>{};
      for (var index = 0; index < draft.sourceTilesetIds.length; index += 1) {
        final tilesetId = draft.sourceTilesetIds[index];
        _validateCanonicalId(
          tilesetId,
          '$draftPath.sourceTilesetIds[$index]',
        );
        if (!sourceTilesetIds.add(tilesetId)) {
          _error(
            code: 'smart_tiles.id.duplicate',
            path: '$draftPath.sourceTilesetIds[$index]',
            message: 'Duplicate Smart Tile tileset id "$tilesetId".',
          );
        }
        if (!projectTilesetIds.contains(tilesetId)) {
          _error(
            code: 'smart_tiles.reference.tileset_missing',
            path: '$draftPath.sourceTilesetIds[$index]',
            message: 'Draft "${draft.id}" references missing tileset '
                '"$tilesetId".',
          );
        }
      }

      _duplicates(draft.atlases, (item) => item.id, '$draftPath.atlases');
      _duplicates(
        draft.materials,
        (item) => item.id,
        '$draftPath.materials',
      );
      _duplicates(
        draft.animations,
        (item) => item.id,
        '$draftPath.animations',
      );
      _duplicates(draft.rules, (item) => item.id, '$draftPath.rules');

      final draftAtlases = <String, ProjectSmartTileAtlas>{
        ..._atlasesById,
        for (final atlas in draft.atlases) atlas.id: atlas,
      };
      for (var index = 0; index < draft.atlases.length; index += 1) {
        final atlas = draft.atlases[index];
        final path = '$draftPath.atlases[$index]';
        _validateCanonicalId(atlas.id, '$path.id');
        _validateCanonicalName(atlas.name, '$path.name');
        _validateCanonicalId(atlas.tilesetId, '$path.tilesetId');
        if (!projectTilesetIds.contains(atlas.tilesetId)) {
          _error(
            code: 'smart_tiles.reference.tileset_missing',
            path: '$path.tilesetId',
            message: 'Draft atlas "${atlas.id}" references missing tileset '
                '"${atlas.tilesetId}".',
          );
        }
        if (atlas.cellWidth <= 0 ||
            atlas.cellHeight <= 0 ||
            atlas.originX < 0 ||
            atlas.originY < 0 ||
            atlas.marginX < 0 ||
            atlas.marginY < 0 ||
            atlas.spacingX < 0 ||
            atlas.spacingY < 0 ||
            atlas.columns <= 0 ||
            atlas.rows <= 0) {
          _error(
            code: 'smart_tiles.atlas.invalid',
            path: path,
            message: 'Draft atlas geometry is invalid.',
          );
        }
      }
      if (draft.primaryAtlasId case final primaryAtlasId?) {
        _validateCanonicalId(primaryAtlasId, '$draftPath.primaryAtlasId');
        if (!draftAtlases.containsKey(primaryAtlasId)) {
          _error(
            code: 'smart_tiles.draft.atlas_missing',
            path: '$draftPath.primaryAtlasId',
            message: 'Draft "${draft.id}" references missing primary atlas '
                '"$primaryAtlasId".',
          );
        }
      }

      final draftMaterials = <String, ProjectSmartTileMaterial>{
        ..._materialsById,
        for (final material in draft.materials) material.id: material,
      };
      for (var index = 0; index < draft.materials.length; index += 1) {
        final material = draft.materials[index];
        final path = '$draftPath.materials[$index]';
        _validateCanonicalId(material.id, '$path.id');
        _validateCanonicalName(material.name, '$path.name');
        _validateCanonicalId(
          material.connectionGroupId,
          '$path.connectionGroupId',
        );
        if (material.categoryId.isNotEmpty) {
          _validateCanonicalId(material.categoryId, '$path.categoryId');
          if (!_categoryIds.contains(material.categoryId)) {
            _error(
              code: 'smart_tiles.reference.category_missing',
              path: '$path.categoryId',
              message: 'Draft material "${material.id}" references missing '
                  'category "${material.categoryId}".',
            );
          }
        }
      }
      final allowedMaterialIds = <String>{};
      for (var index = 0; index < draft.allowedMaterialIds.length; index += 1) {
        final materialId = draft.allowedMaterialIds[index];
        _validateCanonicalId(
          materialId,
          '$draftPath.allowedMaterialIds[$index]',
        );
        if (!allowedMaterialIds.add(materialId)) {
          _error(
            code: 'smart_tiles.id.duplicate',
            path: '$draftPath.allowedMaterialIds[$index]',
            message: 'Duplicate allowed material id "$materialId".',
          );
        }
        if (!draftMaterials.containsKey(materialId)) {
          _missingMaterial(
            materialId,
            '$draftPath.allowedMaterialIds[$index]',
          );
        }
      }

      if (!_templateMatchesTopologyValues(
        topology: draft.topology,
        template: draft.templateHint,
      )) {
        _error(
          code: 'smart_tiles.topology.template_mismatch',
          path: '$draftPath.topology',
          message: 'Draft template ${draft.templateHint.name} is not '
              'compatible with topology ${draft.topology.name}.',
        );
      }
      if (draft.fallbackRuleId case final fallbackRuleId?) {
        _validateCanonicalId(fallbackRuleId, '$draftPath.fallbackRuleId');
        if (!draft.rules.any((rule) => rule.id == fallbackRuleId)) {
          _error(
            code: 'smart_tiles.reference.fallback_rule_missing',
            path: '$draftPath.fallbackRuleId',
            message: 'Draft "${draft.id}" references missing fallback rule '
                '"$fallbackRuleId".',
          );
        }
      }
      if (draft.defaultMaterialId case final defaultMaterialId?) {
        _validateCanonicalId(
          defaultMaterialId,
          '$draftPath.defaultMaterialId',
        );
        if (!draftMaterials.containsKey(defaultMaterialId)) {
          _error(
            code: 'smart_tiles.draft.default_material_missing',
            path: '$draftPath.defaultMaterialId',
            message: 'Draft "${draft.id}" references missing default '
                'material "$defaultMaterialId".',
          );
        }
        if (!draft.allowedMaterialIds.contains(defaultMaterialId)) {
          _error(
            code: 'smart_tiles.reference.material_missing',
            path: '$draftPath.defaultMaterialId',
            message: 'Draft default material "$defaultMaterialId" is not '
                'allowed.',
          );
        }
      }

      final draftAnimations = <String, ProjectSmartTileAnimation>{
        ..._animationsById,
        for (final animation in draft.animations) animation.id: animation,
      };
      for (var animationIndex = 0;
          animationIndex < draft.animations.length;
          animationIndex += 1) {
        final animation = draft.animations[animationIndex];
        final animationPath = '$draftPath.animations[$animationIndex]';
        _validateCanonicalId(animation.id, '$animationPath.id');
        _validateCanonicalName(animation.name, '$animationPath.name');
        for (var frameIndex = 0;
            frameIndex < animation.frames.length;
            frameIndex += 1) {
          final frame = animation.frames[frameIndex];
          final framePath = '$animationPath.frames[$frameIndex]';
          if (frame.durationMs <= 0) {
            _error(
              code: 'smart_tiles.animation.invalid',
              path: '$framePath.durationMs',
              message: 'Animation frame duration must be positive.',
            );
          }
          _validateFrameRefAgainst(
            frame.frame,
            path: '$framePath.frame',
            atlasesById: draftAtlases,
          );
        }
      }

      for (var ruleIndex = 0; ruleIndex < draft.rules.length; ruleIndex += 1) {
        final rule = draft.rules[ruleIndex];
        final rulePath = '$draftPath.rules[$ruleIndex]';
        _validateCanonicalId(rule.id, '$rulePath.id');
        final centerMaterialId = rule.centerMatch.materialId;
        if (centerMaterialId != null &&
            (!draftMaterials.containsKey(centerMaterialId) ||
                !allowedMaterialIds.contains(centerMaterialId))) {
          _error(
            code: 'smart_tiles.reference.material_not_allowed',
            path: '$rulePath.centerMatch.materialId',
            message: 'Material "$centerMaterialId" is not available to '
                'draft "${draft.id}".',
          );
        }
        _duplicates(
          rule.candidates,
          (item) => item.id,
          '$rulePath.candidates',
        );
        for (var candidateIndex = 0;
            candidateIndex < rule.candidates.length;
            candidateIndex += 1) {
          final candidate = rule.candidates[candidateIndex];
          final candidatePath = '$rulePath.candidates[$candidateIndex]';
          _validateCanonicalId(candidate.id, '$candidatePath.id');
          for (var partIndex = 0;
              partIndex < candidate.parts.length;
              partIndex += 1) {
            final part = candidate.parts[partIndex];
            final sourcePath = '$candidatePath.parts[$partIndex].source';
            part.source.when(
              frame: (frame) => _validateFrameRefAgainst(
                frame,
                path: '$sourcePath.frame',
                atlasesById: draftAtlases,
              ),
              animation: (animationId) {
                _validateCanonicalId(
                  animationId,
                  '$sourcePath.animationId',
                );
                if (!draftAnimations.containsKey(animationId)) {
                  _error(
                    code: 'smart_tiles.reference.animation_missing',
                    path: '$sourcePath.animationId',
                    message: 'Missing Smart Tile animation "$animationId".',
                  );
                }
              },
            );
          }
        }
      }
    }
  }

  void _validateAtlases() {
    for (var index = 0; index < catalog.atlases.length; index += 1) {
      final atlas = catalog.atlases[index];
      if (!projectTilesetIds.contains(atlas.tilesetId)) {
        _error(
          code: 'smart_tiles.reference.tileset_missing',
          path: r'$.smartTileCatalog.atlases['
              '$index].tilesetId',
          message: 'Atlas "${atlas.id}" references missing tileset '
              '"${atlas.tilesetId}".',
        );
      }
    }
  }

  void _validateAnimations() {
    for (var animationIndex = 0;
        animationIndex < catalog.animations.length;
        animationIndex += 1) {
      final animation = catalog.animations[animationIndex];
      final animationPath =
          r'$.smartTileCatalog.animations[' '$animationIndex]';
      if (animation.frames.isEmpty) {
        _error(
          code: 'smart_tiles.animation.invalid',
          path: '$animationPath.frames',
          message: 'Animation "${animation.id}" must contain a frame.',
        );
      }
      for (var frameIndex = 0;
          frameIndex < animation.frames.length;
          frameIndex += 1) {
        final frame = animation.frames[frameIndex];
        final framePath = '$animationPath.frames[$frameIndex]';
        if (frame.durationMs <= 0) {
          _error(
            code: 'smart_tiles.animation.invalid',
            path: '$framePath.durationMs',
            message: 'Animation frame duration must be positive.',
          );
        }
        _validateFrameRef(frame.frame, path: '$framePath.frame');
      }
    }
  }

  void _validatePatterns() {
    for (var patternIndex = 0;
        patternIndex < catalog.patterns.length;
        patternIndex += 1) {
      final pattern = catalog.patterns[patternIndex];
      final patternPath = r'$.smartTileCatalog.patterns[' '$patternIndex]';
      if (pattern.cells.isEmpty) {
        _error(
          code: 'smart_tiles.pattern.cells_missing',
          path: '$patternPath.cells',
          message: 'Pattern "${pattern.id}" must contain at least one cell.',
        );
      }
      final coordinates = <(int, int)>{};
      for (var cellIndex = 0;
          cellIndex < pattern.cells.length;
          cellIndex += 1) {
        final cell = pattern.cells[cellIndex];
        final cellPath = '$patternPath.cells[$cellIndex]';
        if (cell.x < 0 ||
            cell.y < 0 ||
            cell.x >= pattern.width ||
            cell.y >= pattern.height) {
          _error(
            code: 'smart_tiles.pattern.cell_out_of_bounds',
            path: cellPath,
            message: 'Pattern cell (${cell.x}, ${cell.y}) is outside the '
                '${pattern.width}×${pattern.height} pattern.',
          );
        }
        if (!coordinates.add((cell.x, cell.y))) {
          _error(
            code: 'smart_tiles.pattern.cell_duplicate',
            path: cellPath,
            message: 'Pattern cell (${cell.x}, ${cell.y}) is duplicated.',
          );
        }
        if (cell.parts.isEmpty &&
            !cell.eraseMaterial &&
            cell.collision == SmartTilePatternCollision.inherit) {
          _error(
            code: 'smart_tiles.pattern.cell_empty',
            path: cellPath,
            message: 'A pattern cell must draw, erase a material, or set '
                'collision.',
          );
        }
        for (var partIndex = 0; partIndex < cell.parts.length; partIndex += 1) {
          final part = cell.parts[partIndex];
          final partPath = '$cellPath.parts[$partIndex]';
          if (part.footprintWidth <= 0 || part.footprintHeight <= 0) {
            _error(
              code: 'smart_tiles.visual.footprint_invalid',
              path: partPath,
              message: 'Visual part footprints must be positive.',
            );
          }
          final sourcePath = '$partPath.source';
          part.source.when(
            frame: (frame) => _validateFrameRef(
              frame,
              path: '$sourcePath.frame',
            ),
            animation: (animationId) {
              _validateCanonicalId(animationId, '$sourcePath.animationId');
              if (!_animationsById.containsKey(animationId)) {
                _error(
                  code: 'smart_tiles.reference.animation_missing',
                  path: '$sourcePath.animationId',
                  message: 'Missing Smart Tile animation "$animationId".',
                );
              }
            },
          );
        }
      }
    }
  }

  void _validatePresets() {
    for (var presetIndex = 0;
        presetIndex < catalog.presets.length;
        presetIndex += 1) {
      final preset = catalog.presets[presetIndex];
      final presetPath = r'$.smartTileCatalog.presets[' '$presetIndex]';
      _validateCanonicalId(preset.id, '$presetPath.id');
      _validateCanonicalName(preset.name, '$presetPath.name');
      _validateCanonicalId(
        preset.defaultMaterialId,
        '$presetPath.defaultMaterialId',
      );
      for (var materialIndex = 0;
          materialIndex < preset.allowedMaterialIds.length;
          materialIndex += 1) {
        _validateCanonicalId(
          preset.allowedMaterialIds[materialIndex],
          '$presetPath.allowedMaterialIds[$materialIndex]',
        );
      }
      if (preset.fallbackRuleId case final fallbackRuleId?) {
        _validateCanonicalId(fallbackRuleId, '$presetPath.fallbackRuleId');
      }
      _validatePresetCategory(preset, presetPath);
      _validatePresetTopology(preset, presetPath);
      _validatePresetMaterials(preset, presetPath);
      _validateRules(preset, presetPath);
    }
  }

  void _validatePresetCategory(
    ProjectSmartTilePreset preset,
    String path,
  ) {
    if (preset.categoryId.isNotEmpty) {
      _validateCanonicalId(preset.categoryId, '$path.categoryId');
    }
    if (preset.categoryId.isNotEmpty &&
        !_categoryIds.contains(preset.categoryId)) {
      _error(
        code: 'smart_tiles.reference.category_missing',
        path: '$path.categoryId',
        message: 'Preset "${preset.id}" references missing category '
            '"${preset.categoryId}".',
      );
    }
  }

  void _validatePresetTopology(
    ProjectSmartTilePreset preset,
    String path,
  ) {
    if (!_templateMatchesTopology(preset)) {
      final expected = smartTileTopologyForTemplate(preset.templateHint);
      final expectedLabel = preset.templateHint == SmartTileTemplateHint.edge16
          ? 'cardinal4 or wangEdge4'
          : expected.name;
      _error(
        code: 'smart_tiles.topology.template_mismatch',
        path: '$path.topology',
        message: 'Template ${preset.templateHint.name} requires topology '
            '$expectedLabel, not ${preset.topology.name}.',
        presetId: preset.id,
      );
    }
    _validateCoverageProfile(preset, path);
  }

  void _validatePresetMaterials(
    ProjectSmartTilePreset preset,
    String path,
  ) {
    for (var materialIndex = 0;
        materialIndex < preset.allowedMaterialIds.length;
        materialIndex += 1) {
      final materialId = preset.allowedMaterialIds[materialIndex];
      if (!_materialsById.containsKey(materialId)) {
        _missingMaterial(
          materialId,
          '$path.allowedMaterialIds[$materialIndex]',
        );
      }
    }
    if (!_materialsById.containsKey(preset.defaultMaterialId)) {
      _missingMaterial(preset.defaultMaterialId, '$path.defaultMaterialId');
    }
    if (!preset.allowedMaterialIds.contains(preset.defaultMaterialId)) {
      _error(
        code: 'smart_tiles.reference.material_missing',
        path: '$path.defaultMaterialId',
        message: 'Default material "${preset.defaultMaterialId}" is not in '
            'the preset allowed-material list.',
      );
    }
  }

  void _validateRules(ProjectSmartTilePreset preset, String presetPath) {
    final allowedMaterialIds = preset.allowedMaterialIds.toSet();
    _duplicates(
      preset.rules,
      (item) => item.id,
      '$presetPath.rules',
    );
    final fallbackRuleId = preset.fallbackRuleId;
    if (fallbackRuleId != null &&
        !preset.rules.any((rule) => rule.id == fallbackRuleId)) {
      _error(
        code: 'smart_tiles.reference.fallback_rule_missing',
        path: '$presetPath.fallbackRuleId',
        message: 'Preset "${preset.id}" references missing fallback rule '
            '"$fallbackRuleId".',
        presetId: preset.id,
      );
    }
    for (var ruleIndex = 0; ruleIndex < preset.rules.length; ruleIndex += 1) {
      final rule = preset.rules[ruleIndex];
      final rulePath = '$presetPath.rules[$ruleIndex]';
      _validateCanonicalId(rule.id, '$rulePath.id');
      _validateCenterMatch(
        rule.centerMatch,
        '$rulePath.centerMatch',
        allowedMaterialIds: allowedMaterialIds,
        presetId: preset.id,
      );
      _validateSignature(
        rule.signature,
        '$rulePath.signature',
        topology: preset.topology,
        allowedMaterialIds: allowedMaterialIds,
        presetId: preset.id,
      );
      _duplicates(
        rule.candidates,
        (item) => item.id,
        '$rulePath.candidates',
      );
      if (rule.candidates.isEmpty) {
        _publicationDiagnostic(
          preset: preset,
          code: 'smart_tiles.visual.candidates_missing',
          path: '$rulePath.candidates',
          message: 'Rule "${rule.id}" has no visual candidate.',
          ruleId: rule.id,
        );
      }
      if (!rule.candidates.any((candidate) => candidate.weight > 0)) {
        final isFallback = rule.id == preset.fallbackRuleId;
        if (isFallback) {
          _error(
            code: 'smart_tiles.rule.no_positive_candidate',
            path: '$rulePath.candidates',
            message: 'Fallback rule "${rule.id}" must contain at least one '
                'positive-weight candidate.',
            presetId: preset.id,
            ruleId: rule.id,
          );
        } else {
          _publicationDiagnostic(
            preset: preset,
            code: 'smart_tiles.rule.no_positive_candidate',
            path: '$rulePath.candidates',
            message: 'Published rule "${rule.id}" must contain at least one '
                'positive-weight candidate.',
            ruleId: rule.id,
          );
        }
      }
      for (var candidateIndex = 0;
          candidateIndex < rule.candidates.length;
          candidateIndex += 1) {
        final candidate = rule.candidates[candidateIndex];
        final candidatePath = '$rulePath.candidates[$candidateIndex]';
        _validateCanonicalId(candidate.id, '$candidatePath.id');
        if (candidate.weight < 0) {
          _error(
            code: 'smart_tiles.candidate.negative_weight',
            path: '$candidatePath.weight',
            message: 'Candidate weight must not be negative.',
          );
        }
        if (candidate.parts.isEmpty) {
          _publicationDiagnostic(
            preset: preset,
            code: 'smart_tiles.visual.parts_missing',
            path: '$candidatePath.parts',
            message: 'Candidate "${candidate.id}" has no visual part.',
            ruleId: rule.id,
          );
        }
        for (var partIndex = 0;
            partIndex < candidate.parts.length;
            partIndex += 1) {
          final part = candidate.parts[partIndex];
          final partPath = '$candidatePath.parts[$partIndex]';
          if (!smartTileTransformPolicyAllows(
            preset.transformPolicy,
            part.transform,
          )) {
            _publicationDiagnostic(
              preset: preset,
              code: 'smart_tiles.transforms.not_allowed',
              path: '$partPath.transform',
              message: 'Visual transform (${part.transform.quarterTurns}, '
                  '${part.transform.flipX}) is outside the preset transform '
                  'policy.',
              ruleId: rule.id,
            );
          }
          if (part.footprintWidth <= 0 || part.footprintHeight <= 0) {
            _error(
              code: 'smart_tiles.visual.footprint_invalid',
              path: partPath,
              message: 'Visual part footprints must be positive.',
            );
          }
          final sourcePath = '$partPath.source';
          part.source.when(
            frame: (frame) => _validateFrameRef(
              frame,
              path: '$sourcePath.frame',
            ),
            animation: (animationId) {
              _validateCanonicalId(animationId, '$sourcePath.animationId');
              if (!_animationsById.containsKey(animationId)) {
                _error(
                  code: 'smart_tiles.reference.animation_missing',
                  path: '$sourcePath.animationId',
                  message: 'Missing Smart Tile animation "$animationId".',
                );
              }
            },
          );
        }
      }
    }
    if (_templateMatchesTopology(preset)) {
      _validateNativeCoverage(preset, presetPath);
    }
  }

  void _validateCoverageProfile(
    ProjectSmartTilePreset preset,
    String presetPath,
  ) {
    final allowedMaterialIds = preset.allowedMaterialIds.toSet();
    final scenarios = preset.coverageProfile.requiredScenarios;
    for (var index = 0; index < scenarios.length; index++) {
      final scenario = scenarios[index];
      final path = '$presetPath.coverageProfile.requiredScenarios[$index]';
      _validateCanonicalId(scenario.id, '$path.id');
      if (scenario.id.trim().isEmpty) {
        _error(
          code: 'smart_tiles.coverage.scenario_id_invalid',
          path: '$path.id',
          message: 'Coverage scenario ids must be non-empty.',
        );
      }
      final centerMaterialId = scenario.centerMaterialId;
      if (centerMaterialId != null) {
        _validateAllowedMaterialReference(
          centerMaterialId,
          '$path.centerMaterialId',
          allowedMaterialIds: allowedMaterialIds,
          presetId: preset.id,
        );
      }
      _validateExactSignature(
        scenario.signature,
        '$path.signature',
        topology: preset.topology,
        allowedMaterialIds: allowedMaterialIds,
        presetId: preset.id,
      );
    }
  }

  void _validateNativeCoverage(
    ProjectSmartTilePreset preset,
    String presetPath,
  ) {
    final report = analyzeSmartTileCoverage(
      preset: preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );
    final codes = report.diagnostics.map((item) => item.code).toSet();

    if (codes.contains('smart_tiles.coverage.incomplete')) {
      final missingCases = report.cases
          .where((item) => item.status == SmartTileCoverageStatus.missing)
          .toList(growable: false);
      _publicationDiagnostic(
        preset: preset,
        code: 'smart_tiles.coverage.incomplete',
        path: '$presetPath.rules',
        message: 'Preset "${preset.id}" does not resolve '
            '${missingCases.length} required coverage scenario(s).',
        missingMasks: _coverageMasks(preset, missingCases),
      );
    }
    if (codes.contains('smart_tiles.coverage.fallback_only')) {
      final fallbackCases = report.cases
          .where((item) => item.status == SmartTileCoverageStatus.fallback)
          .toList(growable: false);
      _publicationDiagnostic(
        preset: preset,
        code: 'smart_tiles.coverage.fallback_only',
        path: '$presetPath.rules',
        message: 'Preset "${preset.id}" resolves '
            '${fallbackCases.length} required scenario(s) only through its '
            'fallback rule.',
      );
    }
    for (final coverageCase in report.cases) {
      final code = switch (coverageCase.status) {
        SmartTileCoverageStatus.ambiguous => 'smart_tiles.rules.ambiguous',
        SmartTileCoverageStatus.noCandidate =>
          'smart_tiles.visual.no_candidate',
        SmartTileCoverageStatus.missingVisualSource =>
          'smart_tiles.visual.source_missing',
        SmartTileCoverageStatus.outOfAtlasGrid =>
          'smart_tiles.visual.out_of_atlas_grid',
        SmartTileCoverageStatus.exact ||
        SmartTileCoverageStatus.transformed ||
        SmartTileCoverageStatus.fallback ||
        SmartTileCoverageStatus.missing =>
          null,
      };
      if (code == null) continue;
      _publicationDiagnostic(
        preset: preset,
        code: code,
        path: '$presetPath.rules',
        message: 'Coverage scenario "${coverageCase.id}" has status '
            '${coverageCase.status.name}.',
        ruleId: coverageCase.ruleIds.isEmpty ? null : coverageCase.ruleIds.last,
        mask: _coverageMask(preset, coverageCase),
      );
    }

    const structuralCodes = <String>{
      'smart_tiles.coverage.explicit_scenarios_required',
      'smart_tiles.coverage.too_many_scenarios',
      'smart_tiles.coverage.duplicate_scenario_id',
      'smart_tiles.coverage.scenario_id_collision',
    };
    for (final diagnostic in report.diagnostics) {
      if (!structuralCodes.contains(diagnostic.code)) continue;
      _error(
        code: diagnostic.code,
        path: '$presetPath.coverageProfile',
        message: diagnostic.message,
        presetId: preset.id,
      );
    }
  }

  List<int> _coverageMasks(
    ProjectSmartTilePreset preset,
    Iterable<SmartTileCoverageCase> cases,
  ) {
    final masks = <int>{
      for (final coverageCase in cases) _coverageMask(preset, coverageCase),
    }.toList(growable: false)
      ..sort();
    return masks;
  }

  int _coverageMask(
    ProjectSmartTilePreset preset,
    SmartTileCoverageCase coverageCase,
  ) {
    return smartTileConnectivityMask(
      topology: preset.topology,
      boundaryPolicy: preset.boundaryPolicy,
      materials: catalog.materials,
      context: coverageCase.context,
    );
  }

  void _validateCenterMatch(
    SmartTileSlotMatch match,
    String path, {
    required Set<String> allowedMaterialIds,
    required String presetId,
  }) {
    _validateSlotMatchShape(match, path);
    if (match.kind == SmartTileMatchKind.same ||
        match.kind == SmartTileMatchKind.different) {
      _error(
        code: 'smart_tiles.rules.center_match_invalid',
        path: path,
        message: 'Center matches cannot use same/different.',
      );
    }
    final materialId = match.materialId;
    if (materialId != null) {
      _validateAllowedMaterialReference(
        materialId,
        '$path.materialId',
        allowedMaterialIds: allowedMaterialIds,
        presetId: presetId,
      );
    }
  }

  void _validateSignature(
    SmartTileSignature signature,
    String path, {
    required SmartTileTopology topology,
    required Set<String> allowedMaterialIds,
    required String presetId,
  }) {
    final slots = <MapEntry<String, SmartTileSlotMatch>>[
      MapEntry<String, SmartTileSlotMatch>(
        'northWestCorner',
        signature.northWestCorner,
      ),
      MapEntry<String, SmartTileSlotMatch>('northEdge', signature.northEdge),
      MapEntry<String, SmartTileSlotMatch>(
        'northEastCorner',
        signature.northEastCorner,
      ),
      MapEntry<String, SmartTileSlotMatch>('eastEdge', signature.eastEdge),
      MapEntry<String, SmartTileSlotMatch>(
        'southEastCorner',
        signature.southEastCorner,
      ),
      MapEntry<String, SmartTileSlotMatch>('southEdge', signature.southEdge),
      MapEntry<String, SmartTileSlotMatch>(
        'southWestCorner',
        signature.southWestCorner,
      ),
      MapEntry<String, SmartTileSlotMatch>('westEdge', signature.westEdge),
    ];
    for (final slot in slots) {
      _validateSlotMatchShape(slot.value, '$path.${slot.key}');
      if (!_slotIsActive(topology, slot.key) &&
          slot.value.kind != SmartTileMatchKind.any) {
        _error(
          code: 'smart_tiles.rules.inactive_slot',
          path: '$path.${slot.key}',
          message: 'Inactive topology slots must use any.',
        );
      }
      final materialId = slot.value.materialId;
      if (materialId != null) {
        _validateAllowedMaterialReference(
          materialId,
          '$path.${slot.key}.materialId',
          allowedMaterialIds: allowedMaterialIds,
          presetId: presetId,
        );
      }
    }
  }

  void _validateExactSignature(
    SmartTileExactSignature signature,
    String path, {
    required SmartTileTopology topology,
    required Set<String> allowedMaterialIds,
    required String presetId,
  }) {
    final slots = <MapEntry<String, String?>>[
      MapEntry<String, String?>('northEdge', signature.northEdge),
      MapEntry<String, String?>(
        'northEastCorner',
        signature.northEastCorner,
      ),
      MapEntry<String, String?>('eastEdge', signature.eastEdge),
      MapEntry<String, String?>(
        'southEastCorner',
        signature.southEastCorner,
      ),
      MapEntry<String, String?>('southEdge', signature.southEdge),
      MapEntry<String, String?>(
        'southWestCorner',
        signature.southWestCorner,
      ),
      MapEntry<String, String?>('westEdge', signature.westEdge),
      MapEntry<String, String?>(
        'northWestCorner',
        signature.northWestCorner,
      ),
    ];
    for (final slot in slots) {
      final materialId = slot.value;
      if (!_slotIsActive(topology, slot.key) && materialId != null) {
        _error(
          code: 'smart_tiles.coverage.inactive_slot',
          path: '$path.${slot.key}',
          message: 'Inactive topology slots must be absent.',
        );
      }
      if (materialId != null) {
        _validateAllowedMaterialReference(
          materialId,
          '$path.${slot.key}',
          allowedMaterialIds: allowedMaterialIds,
          presetId: presetId,
        );
      }
    }
  }

  void _validateAllowedMaterialReference(
    String materialId,
    String path, {
    required Set<String> allowedMaterialIds,
    required String presetId,
  }) {
    _validateCanonicalId(materialId, path);
    if (!_materialsById.containsKey(materialId)) {
      _missingMaterial(materialId, path);
      return;
    }
    if (!allowedMaterialIds.contains(materialId)) {
      _error(
        code: 'smart_tiles.reference.material_not_allowed',
        path: path,
        message: 'Material "$materialId" is not allowed by preset '
            '"$presetId".',
        presetId: presetId,
      );
    }
  }

  void _validateFrameRef(SmartTileFrameRef frame, {required String path}) {
    _validateFrameRefAgainst(
      frame,
      path: path,
      atlasesById: _atlasesById,
    );
  }

  void _validateFrameRefAgainst(
    SmartTileFrameRef frame, {
    required String path,
    required Map<String, ProjectSmartTileAtlas> atlasesById,
  }) {
    _validateCanonicalId(frame.atlasId, '$path.atlasId');
    if (frame.column < 0 ||
        frame.row < 0 ||
        frame.columnSpan <= 0 ||
        frame.rowSpan <= 0) {
      _error(
        code: 'smart_tiles.frame.invalid',
        path: path,
        message: 'Frame coordinates must be non-negative and spans must be '
            'positive.',
      );
      return;
    }
    final atlas = atlasesById[frame.atlasId];
    if (atlas == null) {
      _error(
        code: 'smart_tiles.reference.atlas_missing',
        path: '$path.atlasId',
        message: 'Missing Smart Tile atlas "${frame.atlasId}".',
      );
      return;
    }
    if (frame.column + frame.columnSpan > atlas.columns ||
        frame.row + frame.rowSpan > atlas.rows) {
      _error(
        code: 'smart_tiles.atlas.frame_out_of_bounds',
        path: path,
        message: 'Frame exceeds atlas "${atlas.id}" bounds.',
      );
    }
  }

  void _validateSlotMatchShape(SmartTileSlotMatch match, String path) {
    final materialId = match.materialId;
    final valid = match.kind == SmartTileMatchKind.material
        ? materialId != null &&
            materialId.isNotEmpty &&
            materialId == materialId.trim()
        : materialId == null;
    if (!valid) {
      _error(
        code: 'smart_tiles.rules.match_invalid',
        path: path,
        message: 'materialId is required only for a canonical material '
            'match.',
      );
    }
  }

  void _validateCanonicalId(String value, String path) {
    if (value.trim().isEmpty || value != value.trim()) {
      _error(
        code: 'smart_tiles.id.invalid',
        path: path,
        message: 'Smart Tile identifiers must be non-blank and canonical.',
      );
    }
  }

  void _validateCanonicalName(String value, String path) {
    if (value.trim().isEmpty || value != value.trim()) {
      _error(
        code: 'smart_tiles.name.invalid',
        path: path,
        message: 'Smart Tile names must be non-blank and canonical.',
      );
    }
  }

  void _missingMaterial(String materialId, String path) {
    _error(
      code: 'smart_tiles.reference.material_missing',
      path: path,
      message: 'Missing Smart Tile material "$materialId".',
    );
  }

  void _duplicates<T>(
    List<T> items,
    String Function(T) idOf,
    String path,
  ) {
    final seen = <String>{};
    for (var index = 0; index < items.length; index += 1) {
      final id = idOf(items[index]);
      if (!seen.add(id)) {
        _error(
          code: 'smart_tiles.id.duplicate',
          path: '$path[$index].id',
          message: 'Duplicate Smart Tile id "$id".',
        );
      }
    }
  }

  void _error({
    required String code,
    required String path,
    required String message,
    String? presetId,
    String? ruleId,
    int? mask,
    List<int> missingMasks = const <int>[],
  }) {
    _diagnostics.add(
      SmartTileDiagnostic(
        code: code,
        severity: SmartTileDiagnosticSeverity.error,
        path: path,
        message: message,
        presetId: presetId,
        ruleId: ruleId,
        mask: mask,
        missingMasks: List<int>.unmodifiable(missingMasks),
      ),
    );
  }

  void _publicationDiagnostic({
    required ProjectSmartTilePreset preset,
    required String code,
    required String path,
    required String message,
    String? ruleId,
    int? mask,
    List<int> missingMasks = const <int>[],
  }) {
    _diagnostics.add(
      SmartTileDiagnostic(
        code: code,
        severity: preset.status == SmartTilePresetStatus.published
            ? SmartTileDiagnosticSeverity.error
            : SmartTileDiagnosticSeverity.warning,
        path: path,
        message: message,
        presetId: preset.id,
        ruleId: ruleId,
        mask: mask,
        missingMasks: List<int>.unmodifiable(missingMasks),
      ),
    );
  }
}

bool _templateMatchesTopology(ProjectSmartTilePreset preset) {
  return _templateMatchesTopologyValues(
    topology: preset.topology,
    template: preset.templateHint,
  );
}

bool _templateMatchesTopologyValues({
  required SmartTileTopology topology,
  required SmartTileTemplateHint template,
}) {
  if (template == SmartTileTemplateHint.free) {
    return true;
  }
  if (template == SmartTileTemplateHint.edge16) {
    return topology == SmartTileTopology.cardinal4 ||
        topology == SmartTileTopology.wangEdge4;
  }
  return topology == smartTileTopologyForTemplate(template);
}

Map<String, T> _firstById<T>(
  Iterable<T> items,
  String Function(T) idOf,
) {
  final result = <String, T>{};
  for (final item in items) {
    result.putIfAbsent(idOf(item), () => item);
  }
  return result;
}

bool _slotIsActive(SmartTileTopology topology, String slotName) {
  final isCorner = slotName.endsWith('Corner');
  return switch (topology) {
    SmartTileTopology.uniform => false,
    SmartTileTopology.cardinal4 || SmartTileTopology.wangEdge4 => !isCorner,
    SmartTileTopology.wangCorner4 => isCorner,
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => true,
  };
}
