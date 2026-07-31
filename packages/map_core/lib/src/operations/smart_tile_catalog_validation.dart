import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';
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
  late final Set<String> _categoryIds =
      catalog.categories.map((item) => item.id).toSet();

  List<SmartTileDiagnostic> validate() {
    _validateDuplicateIds();
    _validateAtlases();
    _validateAnimations();
    _validatePresets();
    return List<SmartTileDiagnostic>.unmodifiable(_diagnostics);
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

  void _validatePresets() {
    for (var presetIndex = 0;
        presetIndex < catalog.presets.length;
        presetIndex += 1) {
      final preset = catalog.presets[presetIndex];
      final presetPath = r'$.smartTileCatalog.presets[' '$presetIndex]';
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
    final compatible = switch (preset.usage) {
      SmartTileUsage.terrain => preset.topology == SmartTileTopology.cardinal4,
      SmartTileUsage.path || SmartTileUsage.forestSurface => true,
    };
    if (!compatible) {
      _error(
        code: 'smart_tiles.topology.usage_mismatch',
        path: '$path.topology',
        message: 'Topology "${preset.topology.name}" is incompatible with '
            '"${preset.usage.name}".',
      );
    }
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
    if (preset.usage == SmartTileUsage.terrain &&
        (preset.allowedMaterialIds.length != 1 ||
            preset.allowedMaterialIds.singleOrNull !=
                preset.defaultMaterialId)) {
      _error(
        code: 'smart_tiles.terrain.material_count',
        path: '$path.allowedMaterialIds',
        message: 'Terrain presets require exactly their default material.',
      );
    }
  }

  void _validateRules(ProjectSmartTilePreset preset, String presetPath) {
    _duplicates(
      preset.rules,
      (item) => item.id,
      '$presetPath.rules',
    );
    _validateRuleCoverage(preset, presetPath);
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
      _validateSignature(rule.signature, '$rulePath.signature');
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
      for (var candidateIndex = 0;
          candidateIndex < rule.candidates.length;
          candidateIndex += 1) {
        final candidate = rule.candidates[candidateIndex];
        final candidatePath = '$rulePath.candidates[$candidateIndex]';
        if (candidate.weight <= 0) {
          _error(
            code: 'smart_tiles.weight.invalid',
            path: '$candidatePath.weight',
            message: 'Candidate weight must be positive.',
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
          final sourcePath = '$candidatePath.parts[$partIndex].source';
          part.source.when(
            frame: (frame) => _validateFrameRef(
              frame,
              path: '$sourcePath.frame',
            ),
            animation: (animationId) {
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

  void _validateRuleCoverage(
    ProjectSmartTilePreset preset,
    String presetPath,
  ) {
    final expected = smartTileCanonicalMasks(preset.templateHint);
    if (expected.isEmpty) {
      return;
    }
    final firstRuleByMask = <int, SmartTileRule>{};
    for (var ruleIndex = 0; ruleIndex < preset.rules.length; ruleIndex += 1) {
      final rule = preset.rules[ruleIndex];
      final mask = smartTileMaskForSignature(
        rule.signature,
        topology: preset.topology,
      );
      if (mask == null) {
        continue;
      }
      final previous = firstRuleByMask[mask];
      if (previous != null) {
        _publicationDiagnostic(
          preset: preset,
          code: 'smart_tiles.rules.ambiguous',
          path: '$presetPath.rules[$ruleIndex].signature',
          message: 'Rules "${previous.id}" and "${rule.id}" both map to '
              'canonical mask $mask.',
          ruleId: rule.id,
          mask: mask,
        );
      } else {
        firstRuleByMask[mask] = rule;
      }
    }
    final missing = <int>[
      for (final mask in expected)
        if (!firstRuleByMask.containsKey(mask)) mask,
    ];
    if (missing.isNotEmpty) {
      _publicationDiagnostic(
        preset: preset,
        code: 'smart_tiles.coverage.incomplete',
        path: '$presetPath.rules',
        message: 'Preset "${preset.id}" is missing ${missing.length} '
            'canonical mapping(s).',
        missingMasks: missing,
      );
    }
  }

  void _validateSignature(SmartTileSignature signature, String path) {
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
      final materialId = slot.value.materialId;
      if (materialId != null && !_materialsById.containsKey(materialId)) {
        _missingMaterial(materialId, '$path.${slot.key}.materialId');
      }
    }
  }

  void _validateFrameRef(SmartTileFrameRef frame, {required String path}) {
    final atlas = _atlasesById[frame.atlasId];
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

extension<T> on List<T> {
  T? get singleOrNull => length == 1 ? single : null;
}
