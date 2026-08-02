import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';
import 'smart_tile_cell_context.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_templates.dart';

const int _maximumCoverageScenarioCount = 4096;

enum SmartTileCoverageStatus {
  exact,
  fallback,
  missing,
  ambiguous,
  noCandidate,
  missingVisualSource,
  outOfAtlasGrid,
}

@immutable
final class SmartTileCoverageDiagnostic {
  const SmartTileCoverageDiagnostic({
    required this.code,
    required this.message,
    this.scenarioId,
  });

  final String code;
  final String message;
  final String? scenarioId;
}

@immutable
final class SmartTileCoverageCase {
  const SmartTileCoverageCase({
    required this.id,
    required this.context,
    required this.status,
    this.ruleIds = const <String>[],
  });

  final String id;
  final SmartTileCellContext context;
  final SmartTileCoverageStatus status;
  final List<String> ruleIds;
}

@immutable
final class SmartTileCoverageReport {
  const SmartTileCoverageReport({
    required this.cases,
    this.diagnostics = const <SmartTileCoverageDiagnostic>[],
  });

  final List<SmartTileCoverageCase> cases;
  final List<SmartTileCoverageDiagnostic> diagnostics;

  int get exactCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.exact)
      .length;
  int get fallbackCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.fallback)
      .length;
  int get missingCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.missing)
      .length;
  int get ambiguousCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.ambiguous)
      .length;
  int get noCandidateCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.noCandidate)
      .length;
  int get missingVisualSourceCount => cases
      .where(
        (item) => item.status == SmartTileCoverageStatus.missingVisualSource,
      )
      .length;
  int get outOfAtlasGridCount => cases
      .where((item) => item.status == SmartTileCoverageStatus.outOfAtlasGrid)
      .length;
  bool get isExact =>
      diagnostics.isEmpty && cases.isNotEmpty && exactCount == cases.length;
}

SmartTileCoverageReport analyzeSmartTileCoverage({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required Iterable<ProjectSmartTileAtlas> atlases,
  required Iterable<ProjectSmartTileAnimation> animations,
}) {
  final materialList = List<ProjectSmartTileMaterial>.unmodifiable(materials);
  final materialById = <String, ProjectSmartTileMaterial>{
    for (final material in materialList) material.id: material,
  };
  final atlasById = <String, ProjectSmartTileAtlas>{
    for (final atlas in atlases) atlas.id: atlas,
  };
  final animationById = <String, ProjectSmartTileAnimation>{
    for (final animation in animations) animation.id: animation,
  };
  final diagnostics = <SmartTileCoverageDiagnostic>[];

  if (preset.templateHint == SmartTileTemplateHint.legacy20) {
    diagnostics.add(
      const SmartTileCoverageDiagnostic(
        code: 'smart_tiles.coverage.legacy20_unsupported',
        message: 'Legacy 20 is not a native Smart Tile coverage template.',
      ),
    );
    return _report(diagnostics: diagnostics);
  }

  final explicit = _explicitCoverageInputs(
    preset.coverageProfile.requiredScenarios,
    diagnostics: diagnostics,
  );
  if (explicit == null) {
    return _report(diagnostics: diagnostics);
  }

  final requiresExplicit = preset.templateHint == SmartTileTemplateHint.free;
  if (requiresExplicit &&
      (preset.coverageProfile.mode == SmartTileCoverageMode.template ||
          explicit.isEmpty)) {
    diagnostics.add(
      const SmartTileCoverageDiagnostic(
        code: 'smart_tiles.coverage.explicit_scenarios_required',
        message: 'Free Smart Tile coverage requires an explicit scenario.',
      ),
    );
    return _report(diagnostics: diagnostics);
  }

  final exactWangMaterialSets = _multiMaterialExactWangMaterialSets(preset);
  if (exactWangMaterialSets.isNotEmpty &&
      !_hasEveryRequiredCrossedScenario(
        preset,
        explicit,
        requiredMaterialSets: exactWangMaterialSets,
      )) {
    diagnostics.add(
      const SmartTileCoverageDiagnostic(
        code: 'smart_tiles.coverage.explicit_scenarios_required',
        message: 'Multi-material exact Wang coverage requires a crossed '
            'explicit scenario.',
      ),
    );
  }

  List<_CoverageInput>? selected;
  switch (preset.coverageProfile.mode) {
    case SmartTileCoverageMode.template:
      selected = _templateCoverageInputs(
        preset: preset,
        materialById: materialById,
        diagnostics: diagnostics,
      );
    case SmartTileCoverageMode.explicit:
      selected = explicit;
    case SmartTileCoverageMode.templateAndExplicit:
      final template = _templateCoverageInputs(
        preset: preset,
        materialById: materialById,
        diagnostics: diagnostics,
      );
      if (template == null) {
        return _report(diagnostics: diagnostics);
      }
      selected = _unionCoverageInputs(
        template,
        explicit,
        diagnostics: diagnostics,
      );
  }
  if (selected == null) {
    return _report(diagnostics: diagnostics);
  }
  if (selected.length > _maximumCoverageScenarioCount) {
    diagnostics.add(
      const SmartTileCoverageDiagnostic(
        code: 'smart_tiles.coverage.too_many_scenarios',
        message: 'Smart Tile coverage supports at most 4096 scenarios.',
      ),
    );
    return _report(diagnostics: diagnostics);
  }

  final cases = <SmartTileCoverageCase>[];
  for (var index = 0; index < selected.length; index += 1) {
    final input = selected[index];
    final resolution = resolveSmartTile(
      preset: preset,
      materials: materialList,
      context: input.context,
      x: index,
      y: 0,
      mapId: 'smart_tile_coverage',
      layerId: preset.id,
    );
    final status = _coverageStatus(
      resolution,
      atlasById: atlasById,
      animationById: animationById,
    );
    final ruleIds = List<String>.unmodifiable(resolution.matchingRuleIds);
    cases.add(
      SmartTileCoverageCase(
        id: input.id,
        context: input.context,
        status: status,
        ruleIds: ruleIds,
      ),
    );
    final code = _diagnosticCode(
      status,
      allowFallback: preset.coverageProfile.allowFallback,
    );
    if (code != null) {
      diagnostics.add(
        SmartTileCoverageDiagnostic(
          code: code,
          message: _diagnosticMessage(status, input.id),
          scenarioId: input.id,
        ),
      );
    }
  }

  return _report(cases: cases, diagnostics: diagnostics);
}

SmartTileCoverageReport _report({
  List<SmartTileCoverageCase> cases = const <SmartTileCoverageCase>[],
  List<SmartTileCoverageDiagnostic> diagnostics =
      const <SmartTileCoverageDiagnostic>[],
}) {
  return SmartTileCoverageReport(
    cases: List<SmartTileCoverageCase>.unmodifiable(cases),
    diagnostics: List<SmartTileCoverageDiagnostic>.unmodifiable(diagnostics),
  );
}

final class _CoverageInput {
  const _CoverageInput({
    required this.id,
    required this.context,
    required this.contentKey,
  });

  final String id;
  final SmartTileCellContext context;
  final String contentKey;
}

List<_CoverageInput>? _templateCoverageInputs({
  required ProjectSmartTilePreset preset,
  required Map<String, ProjectSmartTileMaterial> materialById,
  required List<SmartTileCoverageDiagnostic> diagnostics,
}) {
  final masks = smartTileCanonicalMasks(preset.templateHint);
  if (masks.isEmpty) return const <_CoverageInput>[];
  final maximumMaterialCount = _maximumCoverageScenarioCount ~/ masks.length;
  final seenMaterialIds = <String>{};
  final materialIds = <String>[];
  for (final rawId in preset.allowedMaterialIds) {
    final id = rawId.trim();
    final material = materialById[id];
    if (id.isEmpty ||
        material == null ||
        material.isEmpty && !_hasExplicitCenterMaterialRule(preset, id) ||
        !seenMaterialIds.add(id)) {
      continue;
    }
    if (materialIds.length >= maximumMaterialCount) {
      diagnostics.add(
        const SmartTileCoverageDiagnostic(
          code: 'smart_tiles.coverage.too_many_scenarios',
          message: 'Smart Tile coverage supports at most 4096 scenarios.',
        ),
      );
      return null;
    }
    materialIds.add(id);
  }
  materialIds.sort();

  return <_CoverageInput>[
    for (final materialId in materialIds)
      for (final mask in masks)
        _templateCoverageInput(
          mask: mask,
          topology: preset.topology,
          materialId: materialId,
        ),
  ];
}

bool _hasExplicitCenterMaterialRule(
  ProjectSmartTilePreset preset,
  String materialId,
) =>
    preset.rules.any(
      (rule) =>
          rule.centerMatch.kind == SmartTileMatchKind.material &&
          rule.centerMatch.materialId == materialId,
    );

_CoverageInput _templateCoverageInput({
  required int mask,
  required SmartTileTopology topology,
  required String materialId,
}) {
  final canonical = smartTileTemplateCaseForMask(
    mask: mask,
    topology: topology,
    materialId: materialId,
  );
  final id = 'template:$materialId:${smartTileCanonicalRuleId(canonical.mask)}';
  return _CoverageInput(
    id: id,
    context: canonical.context,
    contentKey: _contextKey(canonical.context),
  );
}

List<_CoverageInput>? _explicitCoverageInputs(
  Iterable<SmartTileCoverageScenario> scenarios, {
  required List<SmartTileCoverageDiagnostic> diagnostics,
}) {
  final result = <_CoverageInput>[];
  final seenIds = <String>{};
  for (final scenario in scenarios) {
    if (!seenIds.add(scenario.id)) {
      diagnostics.add(
        SmartTileCoverageDiagnostic(
          code: 'smart_tiles.coverage.duplicate_scenario_id',
          message: 'Coverage scenario id "${scenario.id}" is duplicated.',
          scenarioId: scenario.id,
        ),
      );
      return null;
    }
    if (result.length >= _maximumCoverageScenarioCount) {
      diagnostics.add(
        const SmartTileCoverageDiagnostic(
          code: 'smart_tiles.coverage.too_many_scenarios',
          message: 'Smart Tile coverage supports at most 4096 scenarios.',
        ),
      );
      return null;
    }
    final context = _contextForScenario(scenario);
    result.add(
      _CoverageInput(
        id: scenario.id,
        context: context,
        contentKey: _contextKey(context),
      ),
    );
  }
  return result;
}

List<_CoverageInput>? _unionCoverageInputs(
  Iterable<_CoverageInput> template,
  Iterable<_CoverageInput> explicit, {
  required List<SmartTileCoverageDiagnostic> diagnostics,
}) {
  final result = <_CoverageInput>[];
  final byId = <String, _CoverageInput>{};
  for (final input in template) {
    byId[input.id] = input;
    result.add(input);
  }
  for (final input in explicit) {
    final previous = byId[input.id];
    if (previous == null) {
      if (result.length >= _maximumCoverageScenarioCount) {
        diagnostics.add(
          const SmartTileCoverageDiagnostic(
            code: 'smart_tiles.coverage.too_many_scenarios',
            message: 'Smart Tile coverage supports at most 4096 scenarios.',
          ),
        );
        return null;
      }
      byId[input.id] = input;
      result.add(input);
      continue;
    }
    if (previous.contentKey == input.contentKey) continue;
    diagnostics.add(
      SmartTileCoverageDiagnostic(
        code: 'smart_tiles.coverage.scenario_id_collision',
        message: 'Coverage scenario id "${input.id}" has conflicting '
            'content.',
        scenarioId: input.id,
      ),
    );
    return null;
  }
  return result;
}

SmartTileCellContext _contextForScenario(SmartTileCoverageScenario scenario) {
  final signature = scenario.signature;
  SmartTileObservedSlot exact(String? materialId) =>
      SmartTileObservedSlot.inside(materialId: materialId);

  return SmartTileCellContext(
    centerMaterialId: scenario.centerMaterialId,
    observed: SmartTileObservedSignature(
      northEdge: exact(signature.northEdge),
      northEastCorner: exact(signature.northEastCorner),
      eastEdge: exact(signature.eastEdge),
      southEastCorner: exact(signature.southEastCorner),
      southEdge: exact(signature.southEdge),
      southWestCorner: exact(signature.southWestCorner),
      westEdge: exact(signature.westEdge),
      northWestCorner: exact(signature.northWestCorner),
    ),
  );
}

String _contextKey(SmartTileCellContext context) {
  final slots = <SmartTileObservedSlot>[
    context.observed.northEdge,
    context.observed.northEastCorner,
    context.observed.eastEdge,
    context.observed.southEastCorner,
    context.observed.southEdge,
    context.observed.southWestCorner,
    context.observed.westEdge,
    context.observed.northWestCorner,
  ];
  String value(SmartTileObservedSlot slot) =>
      '${slot.isInsideMap ? 'inside' : 'outside'}:${slot.materialId ?? '<null>'}';
  return <String>[
    context.centerMaterialId ?? '<null>',
    for (final slot in slots) value(slot),
  ].join('|');
}

List<Set<String>> _multiMaterialExactWangMaterialSets(
  ProjectSmartTilePreset preset,
) {
  if (preset.topology != SmartTileTopology.wangEdge4 &&
      preset.topology != SmartTileTopology.wangCorner4 &&
      preset.topology != SmartTileTopology.wang8) {
    return const <Set<String>>[];
  }
  final result = <Set<String>>[];
  for (final rule in preset.rules) {
    if (rule.id == preset.fallbackRuleId) continue;
    final materials = <String>{};
    for (final match
        in _activeSignatureMatches(rule.signature, preset.topology)) {
      final materialId = match.materialId;
      if (match.kind == SmartTileMatchKind.material && materialId != null) {
        materials.add(materialId);
      }
    }
    if (materials.length > 1) {
      result.add(Set<String>.unmodifiable(materials));
    }
  }
  return List<Set<String>>.unmodifiable(result);
}

bool _hasEveryRequiredCrossedScenario(
  ProjectSmartTilePreset preset,
  Iterable<_CoverageInput> scenarios, {
  required Iterable<Set<String>> requiredMaterialSets,
}) {
  if (preset.coverageProfile.mode == SmartTileCoverageMode.template) {
    return false;
  }
  final scenarioMaterialSets = <Set<String>>[];
  for (final scenario in scenarios) {
    final materialIds = scenario.context.observed
        .activeSlots(preset.topology)
        .map((slot) => slot.materialId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    if (materialIds.length > 1) {
      scenarioMaterialSets.add(materialIds);
    }
  }
  return requiredMaterialSets.every(
    (required) => scenarioMaterialSets.any(
      (observed) =>
          observed.length == required.length && observed.containsAll(required),
    ),
  );
}

Iterable<SmartTileSlotMatch> _activeSignatureMatches(
  SmartTileSignature signature,
  SmartTileTopology topology,
) {
  return switch (topology) {
    SmartTileTopology.uniform => const <SmartTileSlotMatch>[],
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.wangEdge4 =>
      <SmartTileSlotMatch>[
        signature.northEdge,
        signature.eastEdge,
        signature.southEdge,
        signature.westEdge,
      ],
    SmartTileTopology.wangCorner4 => <SmartTileSlotMatch>[
        signature.northEastCorner,
        signature.southEastCorner,
        signature.southWestCorner,
        signature.northWestCorner,
      ],
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => <SmartTileSlotMatch>[
        signature.northEdge,
        signature.northEastCorner,
        signature.eastEdge,
        signature.southEastCorner,
        signature.southEdge,
        signature.southWestCorner,
        signature.westEdge,
        signature.northWestCorner,
      ],
  };
}

SmartTileCoverageStatus _coverageStatus(
  SmartTileResolution resolution, {
  required Map<String, ProjectSmartTileAtlas> atlasById,
  required Map<String, ProjectSmartTileAnimation> animationById,
}) {
  if (resolution.status == SmartTileResolutionStatus.ambiguousRule) {
    return SmartTileCoverageStatus.ambiguous;
  }
  if (resolution.status == SmartTileResolutionStatus.noCandidate ||
      resolution.status == SmartTileResolutionStatus.invalidRule) {
    return SmartTileCoverageStatus.noCandidate;
  }
  if (resolution.status != SmartTileResolutionStatus.resolved) {
    return SmartTileCoverageStatus.missing;
  }
  final candidate = resolution.candidate;
  if (candidate == null || candidate.parts.isEmpty) {
    return SmartTileCoverageStatus.noCandidate;
  }

  var outOfAtlasGrid = false;
  for (final part in candidate.parts) {
    final result = part.source.when(
      frame: (frame) => _validateFrame(
        frame,
        atlasById: atlasById,
      ),
      animation: (animationId) {
        final animation = animationById[animationId];
        if (animation == null || animation.frames.isEmpty) {
          return _VisualValidation.missingSource;
        }
        var animationOutOfGrid = false;
        for (final frame in animation.frames) {
          final result = _validateFrame(
            frame.frame,
            atlasById: atlasById,
          );
          if (result == _VisualValidation.missingSource) return result;
          if (result == _VisualValidation.outOfAtlasGrid) {
            animationOutOfGrid = true;
          }
        }
        return animationOutOfGrid
            ? _VisualValidation.outOfAtlasGrid
            : _VisualValidation.valid;
      },
    );
    if (result == _VisualValidation.missingSource) {
      return SmartTileCoverageStatus.missingVisualSource;
    }
    if (result == _VisualValidation.outOfAtlasGrid) {
      outOfAtlasGrid = true;
    }
  }
  if (outOfAtlasGrid) return SmartTileCoverageStatus.outOfAtlasGrid;
  return resolution.usedFallback
      ? SmartTileCoverageStatus.fallback
      : SmartTileCoverageStatus.exact;
}

enum _VisualValidation { valid, missingSource, outOfAtlasGrid }

_VisualValidation _validateFrame(
  SmartTileFrameRef frame, {
  required Map<String, ProjectSmartTileAtlas> atlasById,
}) {
  final atlas = atlasById[frame.atlasId];
  if (atlas == null) return _VisualValidation.missingSource;
  if (frame.column < 0 ||
      frame.row < 0 ||
      frame.columnSpan <= 0 ||
      frame.rowSpan <= 0 ||
      frame.column + frame.columnSpan > atlas.columns ||
      frame.row + frame.rowSpan > atlas.rows) {
    return _VisualValidation.outOfAtlasGrid;
  }
  return _VisualValidation.valid;
}

String? _diagnosticCode(
  SmartTileCoverageStatus status, {
  required bool allowFallback,
}) {
  return switch (status) {
    SmartTileCoverageStatus.exact => null,
    SmartTileCoverageStatus.fallback =>
      allowFallback ? null : 'smart_tiles.coverage.fallback_only',
    SmartTileCoverageStatus.missing => 'smart_tiles.coverage.incomplete',
    SmartTileCoverageStatus.ambiguous => 'smart_tiles.rules.ambiguous',
    SmartTileCoverageStatus.noCandidate => 'smart_tiles.visual.no_candidate',
    SmartTileCoverageStatus.missingVisualSource =>
      'smart_tiles.visual.source_missing',
    SmartTileCoverageStatus.outOfAtlasGrid =>
      'smart_tiles.visual.out_of_atlas_grid',
  };
}

String _diagnosticMessage(SmartTileCoverageStatus status, String scenarioId) {
  return switch (status) {
    SmartTileCoverageStatus.exact =>
      'Coverage scenario "$scenarioId" resolves exactly.',
    SmartTileCoverageStatus.fallback =>
      'Coverage scenario "$scenarioId" resolves only through fallback.',
    SmartTileCoverageStatus.missing =>
      'Coverage scenario "$scenarioId" has no matching rule.',
    SmartTileCoverageStatus.ambiguous =>
      'Coverage scenario "$scenarioId" matches ambiguous rules.',
    SmartTileCoverageStatus.noCandidate =>
      'Coverage scenario "$scenarioId" has no usable visual candidate.',
    SmartTileCoverageStatus.missingVisualSource =>
      'Coverage scenario "$scenarioId" references a missing visual source.',
    SmartTileCoverageStatus.outOfAtlasGrid =>
      'Coverage scenario "$scenarioId" references a frame outside its '
          'atlas grid.',
  };
}
